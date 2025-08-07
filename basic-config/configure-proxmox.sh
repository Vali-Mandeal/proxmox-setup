#!/bin/bash

# Proxmox Fresh Installation Configuration Script
# Automates setup of fresh Proxmox installation
# Usage: sudo bash configure-proxmox.sh
# See README.md for details

set -e

echo "=========================================="
echo "Proxmox Setup Script"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[MAIN]${NC} $1"
}

print_error() {
    echo -e "${RED}[MAIN]${NC} $1"
}

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "Run as root or with sudo"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../downloads" && pwd)"

# Run script function
run_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"
    
    # Check if script is in downloads directory
    if [ ! -f "$script_path" ] && [ -f "$DOWNLOADS_DIR/$script_name" ]; then
        script_path="$DOWNLOADS_DIR/$script_name"
    fi
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        bash "$script_path" || exit 1
    else
        print_error "Script not found: $script_name"
        exit 1
    fi
}

# Fix repositories
print_status "Fixing enterprise repositories"
run_script "fix-repositories.sh"

# Fix locale warnings
print_status "Fixing SSH locale warnings"
run_script "fix-locale.sh"

# Update system
print_status "Updating system"
run_script "update-system.sh"

# Setup PowerTOP
print_status "Setting up PowerTOP"
run_script "setup-powertop.sh"

# Setup Wake-on-LAN
print_status "Setting up Wake-on-LAN"
run_script "setup-wol.sh"

# Download OS templates and ISOs
print_status "Downloading OS templates and ISOs"
run_script "download-templates.sh"

print_status "Proxmox setup complete!"


