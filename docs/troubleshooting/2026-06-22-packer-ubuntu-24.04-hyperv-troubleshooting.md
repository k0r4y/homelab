# Ubuntu 24.04 Hyper-V Golden Image: Comprehensive Troubleshooting Guide

This document chronicles the debugging journey to create a fully automated, unattended Ubuntu 24.04 LTS golden image using Packer on Windows 11 with Hyper-V.

---

## Problem Statement

The goal was to build a reusable Ubuntu 24.04 LTS base image for Hyper-V + Vagrant using Packer's `hyperv-iso` builder with autoinstall (cloud-init). The build kept failing with various errors, preventing the unattended installation from completing.

---

## Issue 1: Wrong Hyper-V Switch Name

### Symptom

Error getting host adapter ip address: No ip address.

### Investigation

The build script was using `External Virtual Switch` as the default switch name, but Hyper-V had a different switch configured.

Run this command to check:

Get-VMSwitch | Format-Table Name, SwitchType -AutoSize

Revealed that the actual switch was named `External Switch VMs`.

### Resolution

Updated the default switch name in `build.ps1`:

$defaultSwitchName = "External Switch VMs"

### Impact

This allowed Packer to correctly attach the VM to the network.

---

## Issue 2: HTTP Server IP Detection Failure

### Symptom

Error getting host adapter ip address: No ip address.

### Investigation

Packer couldn't automatically detect the host's IP address on the Hyper-V External switch. This prevented the HTTP server from starting.

### Attempted Solutions

- http_bind_address = var.host_ip -> Failed
- $env:PACKER_HTTP_IP = "0.0.0.0" -> Failed
- http_bind_address = "0.0.0.0" -> Failed

### Resolution

The `host_ip` parameter is not supported in the `hyperv-iso` source block. The correct approach is to set `http_bind_address` to the specific host IP and pass it via `-var`:

http_bind_address = var.host_ip

Then in `build.ps1`:

packer build -var "host_ip=$hostIP" ...

### Impact

The HTTP server successfully bound to the host IP and became accessible from the VM.

---

## Issue 3: GRUB Boot Command Truncation

### Symptom

The VM booted to the language selection screen instead of starting the autoinstall.

### Investigation

When examining the VM console during boot, the kernel command line showed:

BOOT_IMAGE=/casper/vmlinuz autoinstall ds=nocloud-net

The `seedfrom` parameter was missing. GRUB was truncating everything after the semicolon.

### Attempted Solution

autoinstall ds=nocloud-net\;seedfrom=http://${var.host_ip}:8100/

**Result**: The semicolon caused truncation. `seedfrom` was dropped.

### Resolution

Use `url=` instead of `ds=nocloud-net` with `seedfrom`. The `url=` parameter uses a space (not a semicolon) and points directly to the `user-data` file:

autoinstall url=http://${var.host_ip}:8100/user-data

### Impact

The `url=` parameter was passed to the kernel correctly.

---

## Issue 4: `url=` Deprecation

### Symptom

After fixing the `url=` parameter, the VM still showed the language selection screen.

### Investigation

Cloud-init logs revealed:

WARNING: The kernel command line key `url` is deprecated in 22.3 and scheduled to be removed in 27.3. Please use `cloud-config-url` kernel command line parameter instead

### Resolution

Replace `url=` with `cloud-config-url=`:

autoinstall cloud-config-url=http://${var.host_ip}:8100/user-data

### Impact

The kernel parameter was now using the officially supported syntax.

---

## Issue 5: Cloud-Init Fetching Before Network Ready

### Symptom

The VM booted to the language selection screen. Cloud-init logs showed:

retrieving url 'http://192.168.178.61:8100/user-data' failed: Network is unreachable
DataSourceNoCloud [seed=/var/lib/cloud/seed/nocloud]

### Investigation

Cloud-init was attempting to fetch `user-data` before the network interface was fully configured. It gave up and fell back to the empty local seed directory.

### Resolution

Add `cloud-init.network.wait=1` to force cloud-init to wait for the network:

autoinstall cloud-config-url=http://${var.host_ip}:8100/user-data ip=192.168.178.100::192.168.178.1:255.255.255.0::: cloud-init.network.wait=1

### Impact

Cloud-init waited for the network to be ready before fetching `user-data`.

---

## Issue 6: `user-data` Encoding Issues

### Symptom

Cloud-init logs showed:

contents of 'http://192.168.178.61:8100/user-data' did not start with b'#cloud-config'

### Investigation

The `user-data` file had Windows line endings (`\r\n`) or a BOM (Byte Order Mark), causing cloud-init to fail parsing.

### Resolution

Convert to Unix line endings and remove BOM:

[System.IO.File]::WriteAllText("E:\homelab\packer\http\user-data", ((Get-Content "E:\homelab\packer\http\user-data" -Raw) -replace "`r`n", "`n"), [System.Text.UTF8Encoding]::new($false))

### Impact

The `user-data` file was correctly detected as cloud-config.

---

## Final Working Configuration

### ubuntu24.pkr.hcl
```
# =============================================================================
# Ubuntu 24.04 Hyper-V Golden Image
# =============================================================================

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso"
}

variable "switch_name" {
  type = string
}

variable "output_dir" {
  type    = string
  default = "output-ubuntu"
}

variable "host_ip" {
  type = string
}

packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = ">= 1.0.0"
    }
  }
}

source "hyperv-iso" "ubuntu" {

  vm_name = "packer-ubuntu-24-04"

  iso_url      = var.iso_url
  iso_checksum = "file:https://releases.ubuntu.com/noble/SHA256SUMS"

  generation = 2
  cpus       = 2
  memory     = 4096
  disk_size  = 20480

  switch_name        = var.switch_name
  enable_secure_boot = false

  output_directory = var.output_dir

  # HTTP server
  http_directory    = "http"
  http_port_min     = 8100
  http_port_max     = 8100
  http_bind_address = var.host_ip

  # SSH - static IP
  ssh_host     = "192.168.178.100"
  ssh_port     = 22
  communicator = "ssh"
  ssh_username = "ansible"
  ssh_password = "ansible"
  ssh_timeout  = "60m"

  # Working boot command
  boot_wait = "10s"
  boot_command = [
    "e<wait3>",
    "<down><down><down><end>",
    " autoinstall cloud-config-url=http://${var.host_ip}:8100/user-data ip=192.168.178.100::192.168.178.1:255.255.255.0::: net.ifnames=0 biosdevname=0 cloud-init.network.wait=1",
    "<f10>"
  ]

  shutdown_command = "echo 'ansible' | sudo -S shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -qq",
      "sudo apt-get upgrade -y -qq",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo systemctl enable ssh",
      "sudo dd if=/dev/zero of=/tmp/zeros bs=1M || true",
      "sudo rm -f /tmp/zeros"
    ]
  }
}
```


### build.ps1
```
Clear-Host
Write-Host "=== Packer Ubuntu 24.04 Build ==="
Write-Host ""

$defaultIsoPath = "E:\Downloads\ubuntu-24.04.4-live-server-amd64.iso"
$defaultSwitchName = "External Switch VMs"
$defaultHostIP = "192.168.178.61"

Write-Host "ISO source (default: $defaultIsoPath)"
$isoInput = Read-Host "Enter ISO path"

if ([string]::IsNullOrWhiteSpace($isoInput)) {
    $isoPath = $defaultIsoPath
    $useLocalIso = $true
} elseif ($isoInput -eq "download") {
    $useLocalIso = $false
    $isoPath = ""
} else {
    $isoPath = $isoInput
    $useLocalIso = $true
}

if ($useLocalIso -and -not (Test-Path $isoPath)) {
    Write-Error "ISO file not found: $isoPath"
    exit 1
}

Write-Host ""
Get-VMSwitch | Format-Table Name, SwitchType -AutoSize
Write-Host ""
$switchName = Read-Host "Enter switch name"

if ([string]::IsNullOrWhiteSpace($switchName)) {
    $switchName = $defaultSwitchName
}

$switchExists = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (-not $switchExists) {
    Write-Error "Switch '$switchName' not found."
    exit 1
}

Write-Host ""
$hostIP = Read-Host "Enter your host IP"

if ([string]::IsNullOrWhiteSpace($hostIP)) {
    $hostIP = $defaultHostIP
}

Write-Host ""
Write-Host "Configuration:"
Write-Host "  ISO: $isoPath"
Write-Host "  Switch: $switchName"
Write-Host "  Host IP: $hostIP"
Write-Host ""

$confirm = Read-Host "Proceed? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    exit 0
}

$isoArg = @()
if ($useLocalIso) {
    $isoArg = @("-var", "iso_url=file:///$isoPath")
}

packer build -force -var "switch_name=$switchName" -var "host_ip=$hostIP" $isoArg ubuntu24.pkr.hcl
```
---

## Diagnostic Commands Used

When the VM booted to the language selection screen, the following commands helped identify issues:

### Kernel Command Line

cat /proc/cmdline

### Cloud-Init Errors

grep -E "retrieving|Network is unreachable|url" /var/log/cloud-init.log | tail -20
grep -i autoinstall /var/log/cloud-init.log | tail -20

### Subiquity (Installer) Logs

tail -50 /var/log/installer/subiquity.log
head -20 /var/log/installer/autoinstall-user-data

### Cloud-Init Status

cloud-init status --long

### HTTP Server Reachability

curl -s -o /dev/null -w "%{http_code}" http://192.168.178.61:8100/user-data

### User-Data Existence

ls -la /run/cloud-init/user-data
head -5 /run/cloud-init/user-data

---

## Lessons Learned

- Check logs early: Cloud-init logs provide the exact reason for failure.
- `url=` is deprecated: Use `cloud-config-url=` on newer Ubuntu versions.
- Network needs to be ready: Use `cloud-init.network.wait=1` to ensure the network is up.
- Hyper-V switch names matter: Always verify the exact switch name in Hyper-V Manager.
- File encoding breaks cloud-init: Use Unix line endings and no BOM for `user-data`.
- No semicolons in `boot_command`: GRUB truncates kernel parameters after `;`.
- `ssh_host` needs a static IP: Use `ip=` kernel parameter and `ssh_host` to ensure Packer can connect.

---

## References

- Packer hyperv-iso Documentation: https://developer.hashicorp.com/packer/plugins/builders/hyperv-iso
- Ubuntu Autoinstall Reference: https://ubuntu.com/server/docs/install/autoinstall-reference
- Cloud-init Documentation: https://cloudinit.readthedocs.io/
