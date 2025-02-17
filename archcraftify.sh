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
    log "ERROR" "Script failed at line $1"
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Get the actual user who ran sudo
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

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
    fi

    # Create a temporary file with the current content
    cp "$pacman_conf" "/tmp/pacman.conf.temp"
    
    # Find the line number where [core] appears
    core_line=$(grep -n '^\[core\]' "/tmp/pacman.conf.temp" | cut -d: -f1)
    
    if [ -n "$core_line" ]; then
        # Split the file at [core] line
        head -n $((core_line-1)) "/tmp/pacman.conf.temp" > "/tmp/pacman.conf.new"
        
        # Add archcraft repository
        echo -e "\n[archcraft]" >> "/tmp/pacman.conf.new"
        echo "SigLevel = Optional TrustAll" >> "/tmp/pacman.conf.new"
        echo -e "Include = /etc/pacman.d/archcraft-mirrorlist\n" >> "/tmp/pacman.conf.new"
        
        # Add the rest of the original file
        tail -n "+$core_line" "/tmp/pacman.conf.temp" >> "/tmp/pacman.conf.new"
        
        # Replace the original file
        mv "/tmp/pacman.conf.new" "$pacman_conf"
        rm -f "/tmp/pacman.conf.temp"
        
        log "INFO" "Archcraft repository section added to pacman.conf"
    else
        log "ERROR" "Could not find [core] section in pacman.conf"
        rm -f "/tmp/pacman.conf.temp"
        exit 1
    fi
}

# Update package databases
update_databases() {
    log "INFO" "Updating package databases..."
    pacman -Syy
}

# Install git and yay
install_yay() {
    # Update package databases first
    update_databases

    # Install git if not present
    if ! command -v git &> /dev/null; then
        log "INFO" "Installing git..."
        pacman -S --noconfirm git
    fi

    # Install base-devel and go if not present
    log "INFO" "Installing base-devel and go..."
    pacman -S --needed --noconfirm base-devel go

    # Remove existing yay directory if present
    if [[ -d "$ACTUAL_HOME/yay" ]]; then
        log "WARN" "Removing existing yay directory..."
        rm -rf "$ACTUAL_HOME/yay"
    fi

    # Clone and build yay as the actual user
    log "INFO" "Cloning yay..."
    cd "$ACTUAL_HOME"
    sudo -u "$ACTUAL_USER" git clone https://aur.archlinux.org/yay.git "$ACTUAL_HOME/yay"
    cd "$ACTUAL_HOME/yay" || exit 1
    log "INFO" "Building yay..."
    sudo -u "$ACTUAL_USER" makepkg -si --noconfirm
    log "INFO" "Yay installed successfully"
}

# Install packages from official repositories
install_official_packages() {
    log "INFO" "Installing official packages..."
    # Read packages and filter empty lines and comments
    mapfile -t packages < <(grep -v '^#\|^$' "./packages.txt")
    pacman -S --needed --noconfirm "${packages[@]}"
    log "INFO" "Official packages installed successfully"
}

# Install AUR packages
install_aur_packages() {
    log "INFO" "Installing AUR packages..."
    while IFS= read -r package || [[ -n "$package" ]]; do
        # Skip comments and empty lines
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "${package// }" ]] && continue
        
        package=$(echo "$package" | tr -d '\r')
        log "INFO" "Installing AUR package: $package"
        sudo -u "$ACTUAL_USER" yay -S --needed --noconfirm "$package"
    done < "./packages-aur.txt"
    log "INFO" "AUR packages installed successfully"
}

# Main execution
main() {
    log "INFO" "Starting Archcraft setup..."
    
    setup_mirrorlist
    setup_repo
    update_databases
    install_yay
    install_official_packages
    install_aur_packages
    
    log "INFO" "Archcraft setup completed successfully"
}

main "$@"