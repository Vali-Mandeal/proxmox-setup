#!/bin/bash

# Setup PowerTOP Auto-tune
set -e

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[POWER]${NC} $1"
}

# Install powertop
if command -v powertop >/dev/null 2>&1; then
    print_status "PowerTOP already installed"
else
    print_status "Installing PowerTOP"
    apt install -y powertop
fi

# Create/configure service
if [ -f "/etc/systemd/system/powertop.service" ]; then
    print_status "PowerTOP service already exists"
else
    print_status "Creating PowerTOP service"
    cat > /etc/systemd/system/powertop.service << 'EOF'
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
fi

# Enable and start service
if systemctl is-enabled powertop.service >/dev/null 2>&1; then
    print_status "PowerTOP service already enabled"
else
    print_status "Enabling PowerTOP service"
    systemctl enable powertop.service
fi

if systemctl is-active powertop.service >/dev/null 2>&1; then
    print_status "PowerTOP service already running"
else
    print_status "Starting PowerTOP service"
    systemctl start powertop.service
fi
