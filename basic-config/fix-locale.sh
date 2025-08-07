#!/bin/bash

# Fix SSH Locale Warnings
set -e

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[LOCALE]${NC} $1"
}

generate_and_configure_locales() {
    if [ ! -f "/etc/locale.gen" ]; then
        print_status "Locale generation not available on this system"
        return
    fi
    
    print_status "Generating locales"
    
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
    
    locale-gen
    
    print_status "Setting system locale"
    update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
    
    echo "LANG=en_US.UTF-8" > /etc/default/locale
    echo "LC_CTYPE=en_US.UTF-8" >> /etc/default/locale
    
    print_status "Locale configuration complete"
    print_status "SSH locale warnings should be fixed after next login"
}

generate_and_configure_locales
