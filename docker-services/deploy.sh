#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[DEPLOY]${NC} $1"; }
error() { echo -e "${RED}[DEPLOY]${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_connection_info() {
    read -p "Proxmox IP: " PROXMOX_IP
    [ -z "$PROXMOX_IP" ] && error "IP required"
    
    read -p "SSH username [root]: " SSH_USER
    SSH_USER=${SSH_USER:-root}
    
    log "Connecting to: $SSH_USER@$PROXMOX_IP"
}

select_service() {
    echo "Available services:"
    SERVICES=()
    for dir in "$SCRIPT_DIR"/*/; do
        [ -d "$dir" ] && SERVICES+=("$(basename "$dir")")
    done
    
    [ ${#SERVICES[@]} -eq 0 ] && error "No services found"
    
    for i in "${!SERVICES[@]}"; do
        echo "$((i+1)). ${SERVICES[i]}"
    done
    
    read -p "Select service: " choice
    [ -z "$choice" ] && error "Selection required"
    [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "${#SERVICES[@]}" ] || error "Invalid selection"
    
    SERVICE_NAME="${SERVICES[$((choice-1))]}"
    SERVICE_DIR="$SCRIPT_DIR/$SERVICE_NAME"
    log "Selected service: $SERVICE_NAME"
}

establish_ssh() {
    SSH_SOCKET="/tmp/ssh-deploy-$$"
    SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_SOCKET -o ControlPersist=60"
    
    log "Testing SSH connection..."
    if ! ssh $SSH_OPTS -o ConnectTimeout=10 "$SSH_USER@$PROXMOX_IP" "echo 'Connected'"; then
        error "SSH connection failed"
    fi
    log "SSH connection established"
}

cleanup_ssh() {
    ssh $SSH_OPTS -O exit "$SSH_USER@$PROXMOX_IP" 2>/dev/null || true
    rm -f "$SSH_SOCKET"
}

get_container_info() {
    read -p "Container ID: " CONTAINER_ID
    [ -z "$CONTAINER_ID" ] && error "Container ID required"
    
    read -p "Container name [$SERVICE_NAME]: " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-$SERVICE_NAME}
}

select_template() {
    log "Fetching available templates..."
    TEMPLATES=$(ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "pveam list local | grep -E '\.tar\.(gz|xz|zst)' | awk '{print \$1}' | grep -v '^NAME'")
    
    if [ -z "$TEMPLATES" ]; then
        error "No templates found. Run 'pveam update && pveam download local <template>' on Proxmox first"
    fi
    
    echo "Available templates:"
    TEMPLATE_ARRAY=()
    i=1
    while IFS= read -r template; do
        TEMPLATE_ARRAY+=("$template")
        echo "$i. $(basename "$template" | sed 's/\.tar\.[gx]z$//' | sed 's/\.tar\.zst$//')"
        i=$((i+1))
    done <<< "$TEMPLATES"
    
    read -p "Select template: " choice
    [ -z "$choice" ] && error "Selection required"
    [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "${#TEMPLATE_ARRAY[@]}" ] || error "Invalid selection"
    
    SELECTED_TEMPLATE="${TEMPLATE_ARRAY[$((choice-1))]}"
    log "Selected template: $SELECTED_TEMPLATE"
}

create_lxc_container() {
    log "Creating LXC container $CONTAINER_ID..."
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "
        # Check if container exists and remove if needed
        if pct status $CONTAINER_ID >/dev/null 2>&1; then
            echo 'Container $CONTAINER_ID already exists, stopping and removing...'
            pct stop $CONTAINER_ID 2>/dev/null || true
            sleep 2
            pct destroy $CONTAINER_ID || true
        fi
        
        # Create new container
        pct create $CONTAINER_ID $SELECTED_TEMPLATE \\
            --hostname $CONTAINER_NAME \\
            --memory 2048 \\
            --cores 1 \\
            --rootfs local-lvm:8 \\
            --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp \\
            --features nesting=1 \\
            --unprivileged 1
        
        pct start $CONTAINER_ID
        
        # Wait for container to be ready
        for i in {1..30}; do
            if pct exec $CONTAINER_ID -- test -d /root 2>/dev/null; then
                break
            fi
            sleep 2
        done
    "
    log "Container ready"
}

setup_container_access() {
    log "Setting up container access..."
    echo ""
    echo "🔐 Setting password for container root user..."
    echo "   (You'll need this password to SSH into the container)"
    echo ""
    
    # First, enable SSH service in container
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "
        pct exec $CONTAINER_ID -- bash -c '
            # Install and enable SSH if not present
            apt update >/dev/null 2>&1
            apt install -y openssh-server >/dev/null 2>&1
            systemctl enable ssh >/dev/null 2>&1
            systemctl start ssh >/dev/null 2>&1
            
            # Enable root login with password
            sed -i \"s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g\" /etc/ssh/sshd_config
            sed -i \"s/PermitRootLogin prohibit-password/PermitRootLogin yes/g\" /etc/ssh/sshd_config
            
            # Enable password authentication
            sed -i \"s/#PasswordAuthentication yes/PasswordAuthentication yes/g\" /etc/ssh/sshd_config
            sed -i \"s/PasswordAuthentication no/PasswordAuthentication yes/g\" /etc/ssh/sshd_config
            systemctl restart ssh >/dev/null 2>&1
        '
    "
    
    # Set password
    ssh $SSH_OPTS -t "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- passwd root"
    
    echo ""
    log "Container access configured"
}

install_docker() {
    log "Installing Docker in container..."
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "
        pct exec $CONTAINER_ID -- bash -c '
            # Fix locale issues
            export DEBIAN_FRONTEND=noninteractive
            export LC_ALL=C
            export LANG=C
            
            if ! command -v docker >/dev/null 2>&1; then
                apt update
                apt install -y curl locales
                
                # Generate proper locales
                echo \"en_US.UTF-8 UTF-8\" >> /etc/locale.gen
                locale-gen
                update-locale LANG=en_US.UTF-8
                
                curl -fsSL https://get.docker.com | sh
                systemctl enable docker
                systemctl start docker
            fi
            docker --version
        '
    "
}

deploy_service() {
    TEMP_DIR="/tmp/deploy-$SERVICE_NAME-$(date +%s)"
    
    log "Copying service files..."
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "mkdir -p $TEMP_DIR"
    rsync -avz -e "ssh $SSH_OPTS" "$SERVICE_DIR/" "$SSH_USER@$PROXMOX_IP:$TEMP_DIR/"
    
    log "Installing service in container..."
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "
        # Clean up any existing service directory
        pct exec $CONTAINER_ID -- rm -rf /opt/$SERVICE_NAME
        
        # Create directory in container
        pct exec $CONTAINER_ID -- mkdir -p /opt/$SERVICE_NAME
        
        # Copy files into container using tar
        cd $TEMP_DIR
        tar czf service.tar.gz .
        pct push $CONTAINER_ID service.tar.gz /tmp/service.tar.gz
        pct exec $CONTAINER_ID -- tar xzf /tmp/service.tar.gz -C /opt/$SERVICE_NAME
        pct exec $CONTAINER_ID -- rm /tmp/service.tar.gz
        
        # Cleanup temp directory
        rm -rf $TEMP_DIR
    "
    
    log "Verifying installation..."
    ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- ls -la /opt/$SERVICE_NAME/"
    
    if ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- test -f /opt/$SERVICE_NAME/deploy.sh"; then
        log "Making deploy.sh executable..."
        ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- chmod +x /opt/$SERVICE_NAME/deploy.sh"
        
        log "Running service deployment script..."
        ssh $SSH_OPTS -t "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- bash -c 'cd /opt/$SERVICE_NAME && ./deploy.sh'"
    else
        warn "No deploy.sh found after installation"
    fi
}

# Main execution
trap cleanup_ssh EXIT

get_connection_info
select_service
establish_ssh
get_container_info
select_template
create_lxc_container
setup_container_access
install_docker
deploy_service

# Get container IP address
log "Getting container IP address..."
CONTAINER_IP=$(ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "pct exec $CONTAINER_ID -- hostname -I | awk '{print \$1}'")

log "Deployment complete!"
echo ""
echo "🎉 Successfully deployed $SERVICE_NAME!"
echo "📦 Container ID: $CONTAINER_ID"
echo "🌐 Container IP: $CONTAINER_IP"
echo ""
echo "🔗 Ready-to-use SSH command:"
echo "   ssh root@$CONTAINER_IP"
echo ""
