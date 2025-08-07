#!/bin/bash

# Setup Wake on LAN
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[WOL]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WOL]${NC} $1"
}

install_ethtool() {
    if command -v ethtool >/dev/null 2>&1; then
        print_status "ethtool already installed"
    else
        print_status "Installing ethtool"
        apt install -y ethtool
    fi
}

configure_wake_on_lan() {
    print_status "Available network interfaces:"
    ip a

    # Find physical ethernet interface (enp*, eth*, ens*)
    INTERFACE=$(ip link show | grep -E '^[0-9]+: (enp|eth|ens)' | head -n1 | cut -d: -f2 | tr -d ' ')

    if [ -z "$INTERFACE" ]; then
        print_warning "No physical ethernet interface found"
        print_warning "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' '
        return
    fi
    
    print_status "Detected physical interface: $INTERFACE"
    
    print_status "Current ethtool status for $INTERFACE:"
    ethtool $INTERFACE | grep -i wake || print_warning "No Wake-on-LAN info available"
    
    print_status "Enabling Wake-on-LAN for $INTERFACE"
    if ethtool -s $INTERFACE wol g; then
        print_status "Wake-on-LAN enabled"
        
        print_status "New status:"
        ethtool $INTERFACE | grep -i wake
    else
        print_warning "Failed to enable Wake-on-LAN (hardware may not support it)"
    fi
    
    MAC_ADDRESS=$(ip link show $INTERFACE | awk '/ether/ {print $2}')
    print_status "MAC address: $MAC_ADDRESS"
    print_status "To wake remotely: wakeonlan $MAC_ADDRESS"
}

install_ethtool
configure_wake_on_lan
