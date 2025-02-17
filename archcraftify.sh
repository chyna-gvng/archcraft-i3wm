#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logger function
log() {
    local level=$1
    shift
    case "$level" in
        "INFO") echo -e "${GREEN}[INFO]${NC} $*" ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
    esac
}

# Error handler
error_handler() {
    local line_num=$1
    log "ERROR" "Script failed at line ${line_num}"
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    log "ERROR" "This script must be run with sudo."
    exit 1
fi

# Validate required files exist
required_files=("./archcraft-mirrorlist" "./packages.txt" "./packages-aur.txt")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        log "ERROR" "Required file '$file' not found."
        exit 1
    fi
done

# Function to backup configuration files
backup_config() {
    local file=$1
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log "INFO" "Backup created for $file"
    fi
}

# Setup mirrorlist
setup_mirrorlist() {
    local mirrorlist_source="./archcraft-mirrorlist"
    local mirrorlist_dest="/etc/pacman.d/archcraft-mirrorlist"
    
    backup_config "$mirrorlist_dest"
    cp "$mirrorlist_source" "$mirrorlist_dest"
    log "INFO" "Mirrorlist file copied to $mirrorlist_dest"
}

# Setup Archcraft repository
setup_repo() {
    local pacman_conf="/etc/pacman.conf"
    backup_config "$pacman_conf"
    
    # Check if repo already exists
    if grep -q '^\[archcraft\]' "$pacman_conf"; then
        log "WARN" "Archcraft repository already exists in pacman.conf"
        return
    }

    local archcraft_repo="
[archcraft]
SigLevel = Optional TrustAll
Include = /etc/pacman.d/archcraft-mirrorlist
"
    # Insert before [core] section
    sed -i "/^\[core\]/i ${archcraft_repo}" "$pacman_conf"
    log "INFO" "Archcraft repository section added to pacman.conf"
}

# Install git and yay
install_yay() {
    local home_dir=$HOME
    
    # Install git if not present
    if ! command -v git &> /dev/null; then
        log "INFO" "Installing git..."
        pacman -S --noconfirm git
    fi

    # Remove existing yay directory if present
    if [[ -d "$home_dir/yay" ]]; then
        log "WARN" "Removing existing yay directory..."
        rm -rf "$home_dir/yay"
    fi

    # Clone and build yay
    log "INFO" "Cloning yay..."
    git clone https://aur.archlinux.org/yay.git "$home_dir/yay"
    cd "$home_dir/yay" || exit 1
    makepkg -si --noconfirm
    log "INFO" "Yay installed successfully"
}

# Install packages from official repositories
install_official_packages() {
    log "INFO" "Installing official packages..."
    # Update package database first
    pacman -Sy
    # Read packages and filter empty lines and comments
    mapfile -t packages < <(grep -v '^#\|^$' "./packages.txt")
    pacman -S --needed --noconfirm "${packages[@]}"
    log "INFO" "Official packages installed successfully"
}

# Install AUR packages
install_aur_packages() {
    log "INFO" "Installing AUR packages..."
    # Read packages and filter empty lines and comments
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "${package// }" ]] && continue
        
        package=$(echo "$package" | tr -d '\r')
        log "INFO" "Installing AUR package: $package"
        yay -S --needed --noconfirm "$package"
    done < "./packages-aur.txt"
    log "INFO" "AUR packages installed successfully"
}

# Main execution
main() {
    log "INFO" "Starting Archcraft setup..."
    
    setup_mirrorlist
    setup_repo
    install_yay
    install_official_packages
    install_aur_packages
    
    log "INFO" "Archcraft setup completed successfully"
}

main "$@"