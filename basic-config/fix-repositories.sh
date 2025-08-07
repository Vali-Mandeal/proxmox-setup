#!/bin/bash

# Fix Proxmox Enterprise Repositories
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[REPO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[REPO]${NC} $1"
}

# Disable pve-enterprise
if [ -f "/etc/apt/sources.list.d/pve-enterprise.sources" ]; then
    mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.disabled
    print_status "Disabled pve-enterprise.sources"
elif [ -f "/etc/apt/sources.list.d/pve-enterprise.sources.disabled" ]; then
    print_status "pve-enterprise.sources already disabled"
else
    print_warning "pve-enterprise.sources not found"
fi

# Disable ceph
if [ -f "/etc/apt/sources.list.d/ceph.sources" ]; then
    mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.disabled
    print_status "Disabled ceph.sources"
elif [ -f "/etc/apt/sources.list.d/ceph.sources.disabled" ]; then
    print_status "ceph.sources already disabled"
else
    print_warning "ceph.sources not found"
fi

# Update package list
print_status "Updating package list"
apt update
