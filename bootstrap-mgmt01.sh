#!/bin/bash
# Run this once on a fresh mgmt01 before running rebuild-mgmt01.yml
# Requires sudo password just this one time

set -e

echo "=== Bootstrapping mgmt01 ==="

# Passwordless sudo for k0r4y
echo "k0r4y ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/k0r4y
sudo chmod 0440 /etc/sudoers.d/k0r4y

# Base dependencies
sudo apt update
sudo apt install -y git ansible python3

echo "=== Bootstrap complete. Run rebuild-mgmt01.yml next ==="
