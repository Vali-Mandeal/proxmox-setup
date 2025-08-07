#!/bin/bash

# Download OS Templates and ISOs for Proxmox
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[TEMPLATES]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[TEMPLATES]${NC} $1"
}

# Check if pveam (Proxmox template manager) is available
if ! command -v pveam >/dev/null 2>&1; then
    print_warning "pveam not found - this script needs to run on a Proxmox server"
    exit 1
fi

print_status "Updating template database..."
pveam update

print_status "Available storage locations:"
pvesm status | grep -E "(local|storage)" || true

# Set default storage location (usually 'local' for templates)
TEMPLATE_STORAGE="local"
ISO_STORAGE="local"

download_lxc_template() {
    local template_name=$1
    local template_var=$2
    
    print_status "Starting download: $template_name template..."
    if pveam available | grep -q "$template_var"; then
        TEMPLATE=$(pveam available | grep "$template_var" | head -n1 | awk '{print $2}')
        if ! pveam list $TEMPLATE_STORAGE | grep -q "$TEMPLATE"; then
            pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null 2>&1
            print_status "$template_name template downloaded successfully"
        else
            print_status "$template_name template already exists"
        fi
    else
        print_warning "$template_name template not available in repository"
    fi
}

download_latest_lxc_templates() {
    print_status "Starting LXC container template downloads..."
    
    # Get latest Ubuntu LTS template
    if pveam available | grep -q "ubuntu.*standard"; then
        UBUNTU_LTS=$(pveam available | grep "ubuntu.*standard" | grep -E "(22\.04|24\.04|26\.04)" | sort -V | tail -n1 | awk '{print $2}')
        if [ -n "$UBUNTU_LTS" ]; then
            UBUNTU_NAME=$(echo "$UBUNTU_LTS" | sed 's/.*ubuntu-\([0-9.]*\).*/Ubuntu \1 LTS/')
            nohup bash -c "$(declare -f download_lxc_template print_status print_warning); download_lxc_template '$UBUNTU_NAME' '$UBUNTU_LTS'" >/dev/null 2>&1 &
        fi
    fi
    
    # Get latest Debian stable template
    if pveam available | grep -q "debian.*standard"; then
        DEBIAN_LATEST=$(pveam available | grep "debian.*standard" | sort -V | tail -n1 | awk '{print $2}')
        if [ -n "$DEBIAN_LATEST" ]; then
            DEBIAN_NAME=$(echo "$DEBIAN_LATEST" | sed 's/.*debian-\([0-9]*\).*/Debian \1/')
            nohup bash -c "$(declare -f download_lxc_template print_status print_warning); download_lxc_template '$DEBIAN_NAME' '$DEBIAN_LATEST'" >/dev/null 2>&1 &
        fi
    fi
}

download_iso_silently() {
    local name=$1
    local url=$2
    local filename=$3
    local iso_path="$ISO_DIR/$filename"
    
    if [ ! -f "$iso_path" ]; then
        print_status "Starting download: $name..."
        wget -q -O "$iso_path" "$url" && \
        print_status "$name downloaded successfully" || \
        { print_warning "Failed to download $name"; rm -f "$iso_path"; }
    else
        print_status "$name already exists"
    fi
}

download_latest_iso_images() {
    print_status "Starting ISO downloads..."
    
    ISO_DIR="/var/lib/vz/template/iso"
    
    # Download latest Ubuntu LTS Desktop ISO
    nohup bash -c "$(declare -f download_iso_silently print_status print_warning); ISO_DIR='$ISO_DIR'; download_iso_silently 'Ubuntu LTS Desktop ISO' 'https://releases.ubuntu.com/24.04.1/ubuntu-24.04.1-desktop-amd64.iso' 'ubuntu-24.04.1-desktop-amd64.iso'" >/dev/null 2>&1 &
    
    # Download latest Debian stable netinst ISO  
    nohup bash -c "$(declare -f download_iso_silently print_status print_warning); ISO_DIR='$ISO_DIR'; download_iso_silently 'Debian Stable ISO' 'https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.11.0-amd64-netinst.iso' 'debian-12.11.0-amd64-netinst.iso'" >/dev/null 2>&1 &
}

download_latest_lxc_templates

download_latest_iso_images

print_status "All downloads started in background!"

print_status "Windows ISOs require manual download due to licensing..."
print_warning "For Windows ISOs, you need to:"
print_warning "1. Download Windows Server 2025 from Microsoft Volume Licensing"
print_warning "2. Download Windows 11 from https://www.microsoft.com/software-download/windows11"
print_warning "3. Upload them to Proxmox via web interface: Datacenter > Storage > local > ISO Images"

print_status "Downloads will continue in background while setup proceeds"
