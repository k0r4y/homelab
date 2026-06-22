# 2026-06-21: Packer SSH Timeout during Ubuntu Installation

## Symptom
Packer build hung at "Waiting for SSH to become available..."

## Investigation
- VM was successfully created in Hyper-V, but SSH was not reachable.
- Realized the official Ubuntu 24.04 Server ISO requires an `autoinstall` (cloud-init) configuration to proceed past the initial boot menu. Packer cannot interact with the installer UI by default.

## Resolution
- Must implement an `autoinstall` (cloud-init) configuration file.
- Must point the Packer `boot_command` to this configuration to automate the installer.

## Impact
- Build process is currently blocked until autoinstall automation is implemented.