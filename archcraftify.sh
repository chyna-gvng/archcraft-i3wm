#!/bin/bash

# Check for root privileges
if [[ $UID -ne 0 ]]; then
  echo "Error: This script must be run with sudo."
  exit 1
fi

# Mirrorlist file (adjust path if needed)
mirrorlist_source="./archcraft-mirrorlist"
mirrorlist_dest="/etc/pacman.d/archcraft-mirrorlist"

# Check if the source mirrorlist file exists
if [ ! -f "$mirrorlist_source" ]; then
  echo "Error: Mirrorlist file '$mirrorlist_source' not found."
  exit 1
fi

# Copy the mirrorlist file
sudo cp "$mirrorlist_source" "$mirrorlist_dest"
echo "Mirrorlist file copied to $mirrorlist_dest"

# Define the archcraft repo section
archcraft_repo="
[archcraft]
SigLevel = Optional TrustAll
Include = /etc/pacman.d/archcraft-mirrorlist
"

# Use sed to insert the archcraft section *before* the [core] section
sed -i -e "/^\[core\]/i \"$archcraft_repo\"" -e 's/\n\[core\]/\n&/' /etc/pacman.conf

echo "Archcraft repository section added before [core] in /etc/pacman.conf"

# Git installation and yay cloning
home_dir="$HOME"

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Installing..."
  sudo pacman -S git  # Install git (no --noconfirm)
else
  echo "Git is already installed."
fi

# Clone yay in the home directory
git clone https://aur.archlinux.org/yay.git "$home_dir/yay"
if [[ $? -eq 0 ]]; then
  echo "Yay cloned to $home_dir/yay"

  # Build and install yay
  cd "$home_dir/yay" || { echo "Error: Could not cd to $home_dir/yay"; exit 1; }
  makepkg -si  # Build and install yay (no --noconfirm)
  if [[ $? -eq 0 ]]; then
    echo "Yay installed successfully."
  else
    echo "Error: Yay installation failed."
    exit 1
  fi
else
  echo "Error: Yay cloning failed."
  exit 1
fi

# Package installation from list
packages_file="./packages.txt"

# Check if the packages file exists
if [ ! -f "$packages_file" ]; then
  echo "Error: Packages file '$packages_file' not found."
  exit 1
fi

# Install packages from the list
echo "Installing packages from $packages_file..."
sudo pacman -S - < "$packages_file"  # Install from stdin (no --noconfirm)

if [[ $? -eq 0 ]]; then
  echo "Packages installed successfully."
else
  echo "Error: Package installation failed."
  exit 1
fi

exit 0