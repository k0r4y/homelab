# prep-fw01.ps1
# Creates fw01 VM, adds Lab-Internal adapter, sets boot order, then provisions.
# Run from E:\homelab\vagrant\gateway

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$vmName = "fw01"
$switchName = "Lab-Internal"

Write-Host "==> Destroying existing VM if present..." -ForegroundColor Cyan
vagrant destroy -f

Write-Host "==> Booting VM without provisioning..." -ForegroundColor Cyan
vagrant up --no-provision

Write-Host "==> Adding Lab-Internal network adapter..." -ForegroundColor Cyan
Add-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
Write-Host "    Adapter added. Waiting 5 seconds for Hyper-V to settle..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Host "==> Setting boot order to disk first (skip PXE)..." -ForegroundColor Cyan
$hd = Get-VMHardDiskDrive -VMName $vmName
Set-VMFirmware -VMName $vmName -FirstBootDevice $hd

Write-Host "==> Running provisioner..." -ForegroundColor Cyan
vagrant provision

Write-Host "✅ fw01 is ready." -ForegroundColor Green