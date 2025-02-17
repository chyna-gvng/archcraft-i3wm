# Archcraftify

This repository contains a script to automate the setup of Archcraft repositories and essential packages on a clean Arch Linux installation. The script handles the configuration of package repositories, installation of `yay` AUR helper, and automated installation of both official and AUR packages.

## Prerequisites

- A clean installation of Arch Linux
- `sudo` privileges
- Internet connection
- Basic knowledge of Arch Linux system administration

## Required Files

Before running the script, ensure you have the following files in your working directory:

1. `setup.sh` - The main setup script
2. `archcraft-mirrorlist` - Contains Archcraft repository mirrors
3. `packages.txt` - List of official packages to install
4. `packages-aur.txt` - List of AUR packages to install

### File Structure
```
.
├── setup.sh
├── archcraft-mirrorlist
├── packages.txt
└── packages-aur.txt
```

## Installation Steps

1. First, ensure your Arch Linux system is up to date:
   ```bash
   sudo pacman -Syu
   ```

2. Clone this repository or download the files:
   ```bash
   git clone https://github.com/yourusername/archcraft-setup.git
   cd archcraft-setup
   ```

3. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

4. Run the script with sudo:
   ```bash
   sudo ./setup.sh
   ```

## What the Script Does

1. **Initial Setup**
   - Validates root privileges
   - Checks for required files
   - Sets up error handling and logging

2. **Mirrorlist Configuration**
   - Copies the Archcraft mirrorlist to `/etc/pacman.d/`
   - Creates backups of existing configuration files

3. **Repository Configuration**
   - Adds the Archcraft repository to `/etc/pacman.conf`
   - Sets appropriate repository settings

4. **YAY Installation**
   - Installs git if not present
   - Clones and builds yay from AUR
   - Sets up yay for AUR package management

5. **Package Installation**
   - Installs official packages from `packages.txt`
   - Installs AUR packages from `packages-aur.txt`

## Configuration Files

### packages.txt
List your official repository packages in this file, one per line:
```
base-devel
firefox
neovim
# Comments are supported
```

### packages-aur.txt
List your AUR packages in this file, one per line:
```
visual-studio-code-bin
spotify
# Comments are supported
```

### archcraft-mirrorlist
Contains the Archcraft repository mirrors. Example:
```
Server = https://mirror1.archcraft.io/$repo/$arch
Server = https://mirror2.archcraft.io/$repo/$arch
```

## Error Handling

The script includes comprehensive error handling:
- Creates backups of modified system files
- Validates all required files before starting
- Provides detailed error messages with line numbers
- Color-coded output for better readability

## Troubleshooting

### Common Issues

1. **Script fails to run with sudo**
   ```bash
   # Solution: Ensure script is executable
   chmod +x setup.sh
   ```

2. **Package installation fails**
   ```bash
   # Check internet connection
   ping -c 3 archlinux.org
   
   # Update package databases
   sudo pacman -Sy
   ```

3. **YAY installation fails**
   ```bash
   # Remove existing yay directory if present
   rm -rf ~/yay
   
   # Ensure base-devel is installed
   sudo pacman -S base-devel
   ```

### Logs

The script provides detailed logging with different levels:
- INFO: Normal operation messages
- WARN: Warning messages (non-fatal issues)
- ERROR: Error messages (fatal issues)

## Safety Features

- Creates backups of all modified system files
- Validates required files before starting
- Checks for existing configurations
- Uses `--needed` flag to prevent unnecessary reinstallation
- Filters empty lines and comments from package lists

## Contributing

Feel free to submit issues and enhancement requests!
