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

print_status "Downloading LXC container templates..."

# Ubuntu 24.04 LTS (latest stable)
print_status "Downloading Ubuntu 24.04 LTS template..."
if pveam available | grep -q "ubuntu-24.04"; then
    UBUNTU_TEMPLATE=$(pveam available | grep "ubuntu-24.04" | head -n1 | awk '{print $2}')
    if ! pveam list $TEMPLATE_STORAGE | grep -q "$UBUNTU_TEMPLATE"; then
        pveam download $TEMPLATE_STORAGE $UBUNTU_TEMPLATE
        print_status "Ubuntu 24.04 LTS template downloaded"
    else
        print_status "Ubuntu 24.04 LTS template already exists"
    fi
else
    print_warning "Ubuntu 24.04 template not available in repository"
fi

# Ubuntu 25.04
print_status "Downloading Ubuntu 25.04 template..."
if pveam available | grep -q "ubuntu-25.04"; then
    UBUNTU_25_TEMPLATE=$(pveam available | grep "ubuntu-25.04" | head -n1 | awk '{print $2}')
    if ! pveam list $TEMPLATE_STORAGE | grep -q "$UBUNTU_25_TEMPLATE"; then
        pveam download $TEMPLATE_STORAGE $UBUNTU_25_TEMPLATE
        print_status "Ubuntu 25.04 template downloaded"
    else
        print_status "Ubuntu 25.04 template already exists"
    fi
else
    print_warning "Ubuntu 25.04 template not available in repository"
fi

# Debian 12 (Bookworm)
print_status "Downloading Debian 12 template..."
if pveam available | grep -q "debian-12"; then
    DEBIAN_TEMPLATE=$(pveam available | grep "debian-12" | head -n1 | awk '{print $2}')
    if ! pveam list $TEMPLATE_STORAGE | grep -q "$DEBIAN_TEMPLATE"; then
        pveam download $TEMPLATE_STORAGE $DEBIAN_TEMPLATE
        print_status "Debian 12 template downloaded"
    else
        print_status "Debian 12 template already exists"
    fi
else
    print_warning "Debian 12 template not found in repository"
fi

print_status "Downloading ISO images for VMs..."

# ISO directory should exist by default in Proxmox
ISO_DIR="/var/lib/vz/template/iso"

# Ubuntu 24.04 Desktop ISO (for VMs)
print_status "Downloading Ubuntu 24.04 Desktop ISO..."
UBUNTU_ISO="ubuntu-24.04.1-desktop-amd64.iso"
UBUNTU_URL="https://releases.ubuntu.com/24.04.1/$UBUNTU_ISO"
if [ ! -f "$ISO_DIR/$UBUNTU_ISO" ]; then
    wget -P "$ISO_DIR" "$UBUNTU_URL" || print_warning "Failed to download Ubuntu ISO"
    print_status "Ubuntu 24.04 Desktop ISO downloaded"
else
    print_status "Ubuntu Desktop ISO already exists"
fi

# Debian 12 ISO (for VMs)
print_status "Downloading Debian 12 ISO..."
DEBIAN_ISO="debian-12.8.0-amd64-netinst.iso"
DEBIAN_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$DEBIAN_ISO"
if [ ! -f "$ISO_DIR/$DEBIAN_ISO" ]; then
    wget -P "$ISO_DIR" "$DEBIAN_URL" || print_warning "Failed to download Debian ISO"
    print_status "Debian 12 ISO downloaded"
else
    print_status "Debian ISO already exists"
fi

print_status "Windows ISOs require manual download due to licensing..."
print_warning "For Windows ISOs, you need to:"
print_warning "1. Download Windows Server 2025 from Microsoft Volume Licensing"
print_warning "2. Download Windows 11 from https://www.microsoft.com/software-download/windows11"
print_warning "3. Upload them to Proxmox via web interface: Datacenter > Storage > local > ISO Images"

print_status "Showing downloaded templates and ISOs:"
echo ""
print_status "LXC Templates:"
pveam list $TEMPLATE_STORAGE | grep -E "(ubuntu|debian)" || echo "No templates found"

echo ""
print_status "ISO Images:"
ls -lh "$ISO_DIR"/*.iso 2>/dev/null || echo "No ISOs found"

print_status "Template and ISO download completed!"
print_status "You can now create containers and VMs using these templates"
