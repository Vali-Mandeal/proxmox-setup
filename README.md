# Proxmox Setup Scripts

This collection of scripts helps configure a freshly installed Proxmox system by automating common setup tasks.

## Features

- **Idempotent**: All scripts are safe to run multiple times without causing issues
- **Modular**: Each component can be run independently 
- **Remote execution**: Configure servers via SSH without manual file copying
- **Error handling**: Comprehensive error checking and recovery guidance
- **Progress tracking**: Clear visual feedback during execution

## Scripts Overview

### Directory Structure
- **`basic-config/`** - Core Proxmox configuration scripts
- **`downloads/`** - OS template and ISO download scripts
- **`run-setup.sh`** - Remote execution script (in root)

### Remote Runner
- **`run-setup.sh`** - Remotely executes the entire setup process via SSH (recommended)

### Main Script
- **`basic-config/configure-proxmox.sh`** - Main orchestrator script that runs all individual scripts in sequence

### Basic Configuration Scripts
- **`basic-config/fix-repositories.sh`** - Disables enterprise repositories to avoid subscription warnings
- **`basic-config/fix-locale.sh`** - Fixes SSH locale warnings by generating proper UTF-8 locales
- **`basic-config/update-system.sh`** - Performs full system update (apt update && apt upgrade)
- **`basic-config/setup-powertop.sh`** - Installs and configures PowerTOP for automatic power optimization
- **`basic-config/setup-wol.sh`** - Sets up Wake-on-LAN functionality

### Download Scripts
- **`downloads/download-templates.sh`** - Downloads common OS templates and ISOs (Ubuntu, Debian)

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
sudo bash basic-config/configure-proxmox.sh
```

### Run Individual Scripts
You can also run individual scripts if you only need specific functionality:

```bash
# Fix repositories only
sudo bash basic-config/fix-repositories.sh

# Fix locale warnings only
sudo bash basic-config/fix-locale.sh

# Update system only
sudo bash basic-config/update-system.sh

# Setup PowerTOP only
sudo bash basic-config/setup-powertop.sh

# Setup Wake-on-LAN only
sudo bash basic-config/setup-wol.sh

# Download OS templates and ISOs only
sudo bash downloads/download-templates.sh
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

### download-templates.sh
- Updates Proxmox template database with `pveam update`
- Downloads Ubuntu 24.04 LTS container template (25.04 when available)
- Downloads Debian 12 container template
- Downloads Ubuntu 24.04 Desktop ISO for VMs
- Downloads Debian 12 netinstall ISO for VMs
- Provides instructions for manually adding Windows ISOs

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
