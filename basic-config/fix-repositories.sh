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

disable_enterprise_repo() {
    local repo_file=$1
    local display_name=$2
    
    if [ -f "$repo_file" ]; then
        mv "$repo_file" "$repo_file.disabled"
        print_status "Disabled $display_name"
    elif [ -f "$repo_file.disabled" ]; then
        print_status "$display_name already disabled"
    else
        print_warning "$display_name not found"
    fi
}

disable_enterprise_repo "/etc/apt/sources.list.d/pve-enterprise.sources" "pve-enterprise.sources"
disable_enterprise_repo "/etc/apt/sources.list.d/ceph.sources" "ceph.sources"


print_status "Updating package list"
apt update
