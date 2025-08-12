#!/bin/bash

set -e

log() { echo "[CF-TUNNEL] $1"; }
error() { echo "[CF-TUNNEL] ERROR: $1"; exit 1; }

log "Setting up Cloudflare Tunnel..."

read -p "Cloudflare Tunnel Token: " TUNNEL_TOKEN
[ -z "$TUNNEL_TOKEN" ] && error "Tunnel token required"

cd /opt/cloudflare-tunnel

log "Configuring tunnel with token..."
export TUNNEL_TOKEN

log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create symlink for compatibility
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

log "Starting Cloudflare Tunnel..."
/usr/local/bin/docker-compose up -d

# Wait a moment for container to initialize
sleep 3

log "Cloudflare Tunnel deployed successfully!"
log "Container status:"
/usr/local/bin/docker-compose ps

log "Recent logs:"
/usr/local/bin/docker-compose logs --tail=10

log ""
log "✅ Deployment complete! Your Cloudflare Tunnel is now running."
log "💡 To check logs: docker-compose logs -f"
log "💡 To restart: docker-compose restart"
log "💡 To stop: docker-compose down"
