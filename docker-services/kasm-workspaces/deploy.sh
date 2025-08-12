#!/bin/bash

set -e

log() { echo "[KASM] $1"; }
error() { echo "[KASM] ERROR: $1"; exit 1; }

log "Setting up Kasm Desktop..."

# Get configuration values
read -p "Kasm Web Port [6901]: " KASM_PORT
KASM_PORT=${KASM_PORT:-6901}

read -p "VNC Password [password]: " VNC_PW
VNC_PW=${VNC_PW:-password}

cd /opt/kasm-workspaces

log "Configuring Kasm Desktop..."
export KASM_PORT
export VNC_PW

log "Installing Docker Compose..."
if ! command -v docker-compose >/dev/null 2>&1; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

log "Starting Kasm Desktop..."
/usr/local/bin/docker-compose up -d

# Wait for container to initialize
sleep 10

log "Kasm Desktop deployed successfully!"
log "Container status:"
/usr/local/bin/docker-compose ps

log "Recent logs:"
/usr/local/bin/docker-compose logs --tail=10

log ""
log "✅ Deployment complete! Your Kasm Desktop is now running."
log "🌐 Access Kasm at: https://$(hostname -I | awk '{print $1}'):$KASM_PORT"
log "� User: kasm_user"
log "🔐 Password: $VNC_PW"
log ""
log "💡 To check logs: docker-compose logs -f"
log "💡 To restart: docker-compose restart"
log "💡 To stop: docker-compose down"
