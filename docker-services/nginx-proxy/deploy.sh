#!/bin/bash

set -e

log() { echo "[NGINX] $1"; }
error() { echo "[NGINX] ERROR: $1"; exit 1; }

log "Setting up Nginx Proxy..."

read -p "Domain name: " DOMAIN_NAME
[ -z "$DOMAIN_NAME" ] && error "Domain name required"

read -p "Backend service IP: " BACKEND_IP
[ -z "$BACKEND_IP" ] && error "Backend IP required"

read -p "Backend port [80]: " BACKEND_PORT
BACKEND_PORT=${BACKEND_PORT:-80}

cd /opt/nginx-proxy

log "Creating proxy configuration..."
sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" nginx.conf
sed -i "s/BACKEND_IP/$BACKEND_IP/g" nginx.conf
sed -i "s/BACKEND_PORT/$BACKEND_PORT/g" nginx.conf

log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log "Starting Nginx Proxy..."
docker-compose up -d

log "Nginx Proxy deployed successfully!"
docker-compose ps
