# Proxmox Setup Scripts

This collection of scripts helps configure a freshly installed Proxmox system by automating common setup tasks.

## Features

- **Idempotent**: All scripts are safe to run multiple times without causing issues
- **Modular**: Each component can be run independently 
- **Remote execution**: Configure servers via SSH without manual file copying
- **Error handling**: Comprehensive error checking and recovery guidance
- **Progress tracking**: Clear visual feedback during execution

## Scripts Overview

### Remote Runner
- **`run-setup.sh`** - Remotely executes the entire setup process via SSH (recommended)

### Main Script
- **`configure-proxmox.sh`** - Main orchestrator script that runs all individual scripts in sequence

### Individual Scripts
- **`fix-repositories.sh`** - Disables enterprise repositories to avoid subscription warnings
- **`fix-locale.sh`** - Fixes SSH locale warnings by generating proper UTF-8 locales
- **`update-system.sh`** - Performs full system update (apt update && apt upgrade)
- **`setup-powertop.sh`** - Installs and configures PowerTOP for automatic power optimization
- **`setup-wol.sh`** - Sets up Wake-on-LAN functionality

## Usage

### Remote Setup (Recommended)
Run this from your local machine to configure a remote Proxmox server:
```bash
bash run-setup.sh
```
You'll be prompted for:
- Proxmox server IP address
- SSH username (defaults to root)

The script will automatically:
1. Copy all setup scripts to the remote server
2. Execute the configuration process
3. Clean up temporary files

### Direct Setup on Proxmox Server
If you're already on the Proxmox server, run:
```bash
sudo bash configure-proxmox.sh
```

### Run Individual Scripts
You can also run individual scripts if you only need specific functionality:

```bash
# Fix repositories only
sudo bash fix-repositories.sh

# Fix locale warnings only
sudo bash fix-locale.sh

# Update system only
sudo bash update-system.sh

# Setup PowerTOP only
sudo bash setup-powertop.sh

# Setup Wake-on-LAN only
sudo bash setup-wol.sh
```

## What Each Script Does

### fix-repositories.sh
- Disables `pve-enterprise.sources` by renaming it to `.disabled`
- Disables `ceph.sources` by renaming it to `.disabled`
- Updates the package list with `apt update`

### fix-locale.sh
- Generates missing UTF-8 locales (en_US.UTF-8, en_GB.UTF-8)
- Sets system locale to en_US.UTF-8
- Eliminates SSH locale warning messages

### update-system.sh
- Updates package lists with `apt update`
- Upgrades all system packages with `apt upgrade -y`
- Provides progress feedback during the upgrade process

### setup-powertop.sh
- Installs the `powertop` package
- Creates a systemd service to run PowerTOP auto-tune on boot
- Enables and starts the service
- Shows service status

### setup-wol.sh
- Installs `ethtool` package
- Detects the main network interface automatically
- Enables Wake-on-LAN for the detected interface
- Shows MAC address for remote wake commands
- Provides instructions for using `wakeonlan` from other machines

## Requirements

### For Remote Setup
- SSH access to the Proxmox server (root or sudo user)
- SCP/SSH client on your local machine
- All setup scripts in the same directory

### For Direct Setup
- Fresh Proxmox installation
- Root privileges (run with `sudo`)
- Internet connection for package installation

## Notes

- **PowerTOP**: Power optimizations will be applied automatically on each system boot
- **Wake-on-LAN**: Remember to enable WOL in your BIOS/UEFI settings as well
- **Repositories**: Enterprise repositories are disabled to prevent subscription warnings

## Troubleshooting

If any script fails:
1. Check that you're running with sudo privileges
2. Ensure you have internet connectivity
3. Verify that this is a Proxmox system
4. Check the error messages for specific issues

Each script can be run independently, so if one fails, you can fix the issue and run just that specific script again.
