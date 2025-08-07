#!/bin/bash

# Remote Proxmox Setup Runner
# Usage: bash run-setup.sh
# See README.md for details

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[REMOTE]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[REMOTE]${NC} $1"
}

print_error() {
    echo -e "${RED}[REMOTE]${NC} $1"
}

echo "================================"
echo "Remote Proxmox Setup Runner"
echo "================================"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required scripts
REQUIRED_SCRIPTS=(
    "basic-config/configure-proxmox.sh"
    "basic-config/fix-repositories.sh"
    "basic-config/fix-locale.sh"
    "basic-config/update-system.sh"
    "basic-config/setup-powertop.sh"
    "basic-config/setup-wol.sh"
    "downloads/download-templates.sh"
)

# Check if all required scripts exist
print_status "Checking for required scripts..."
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        print_error "Required script not found: $script"
        exit 1
    fi
done
print_status "All scripts found"

# Get Proxmox server info
echo ""
read -p "Enter Proxmox server IP address: " PROXMOX_IP
if [ -z "$PROXMOX_IP" ]; then
    print_error "IP address cannot be empty"
    exit 1
fi

read -p "Enter SSH username [root]: " SSH_USER
SSH_USER=${SSH_USER:-root}

print_status "Connecting to: $SSH_USER@$PROXMOX_IP"

# Create SSH control socket for connection reuse
SSH_SOCKET="/tmp/ssh-socket-$$"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$SSH_SOCKET -o ControlPersist=60"

# Test SSH connection and establish control socket
print_status "Testing SSH connection..."
if ! ssh $SSH_OPTS -o ConnectTimeout=10 "$SSH_USER@$PROXMOX_IP" "echo 'Connection OK'"; then
    print_error "SSH connection failed"
    exit 1
fi

# Create temporary directory
TEMP_DIR="/tmp/proxmox-setup-$(date +%s)"
print_status "Creating temp directory: $TEMP_DIR"
ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "mkdir -p $TEMP_DIR"

# Copy files using rsync (preserving directory structure)
print_status "Copying setup scripts..."
rsync -avz -e "ssh $SSH_OPTS" "$SCRIPT_DIR"/basic-config "$SCRIPT_DIR"/downloads "$SSH_USER@$PROXMOX_IP:$TEMP_DIR/"

# Make all scripts executable
print_status "Making scripts executable..."
ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "find $TEMP_DIR -name '*.sh' -exec chmod +x {} \;"

# Execute main script
print_status "Executing Proxmox configuration..."
print_warning "This may take several minutes..."
echo ""

if ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "cd $TEMP_DIR/basic-config && bash configure-proxmox.sh"; then
    print_status "Configuration completed successfully!"
else
    print_error "Configuration failed!"
    print_warning "Debug: SSH to $SSH_USER@$PROXMOX_IP and check $TEMP_DIR"
    # Don't cleanup on failure so user can debug
    ssh $SSH_OPTS -O exit "$SSH_USER@$PROXMOX_IP" 2>/dev/null || true
    exit 1
fi

# Cleanup
print_status "Cleaning up..."
ssh $SSH_OPTS "$SSH_USER@$PROXMOX_IP" "rm -rf $TEMP_DIR"

# Close SSH control socket
ssh $SSH_OPTS -O exit "$SSH_USER@$PROXMOX_IP" 2>/dev/null || true
rm -f "$SSH_SOCKET"

print_status "Proxmox setup complete!"
