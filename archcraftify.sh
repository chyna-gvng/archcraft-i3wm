#!/bin/bash

# Check for root privileges
if [[ $UID -ne 0 ]]; then
  echo "Error: This script must be run with sudo."
  exit 1
fi

# Mirrorlist file (adjust path if needed)
mirrorlist_source="./archcraft-mirrorlist"  # Path to the mirrorlist file you want to copy
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

exit 0