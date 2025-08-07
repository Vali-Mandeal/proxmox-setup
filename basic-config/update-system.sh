#!/bin/bash

# Update Proxmox System
set -e

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[UPDATE]${NC} $1"
}

print_status "Updating package lists"
apt update

print_status "Upgrading system packages"
apt upgrade -y
