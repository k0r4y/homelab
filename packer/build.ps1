Clear-Host
Write-Host "=== Packer Ubuntu 24.04 Build ==="
Write-Host ""

# ---- Defaults ----
$defaultIsoPath = "E:\Downloads\ubuntu-24.04.4-live-server-amd64.iso"
$defaultSwitchName = "External Switch VMs"   # FIXED: Correct switch name!
$defaultHostIP = "192.168.178.61"

# ---- Step 1: ISO Path ----
Write-Host "ISO source (default: $defaultIsoPath)"
Write-Host "  - Press Enter for default"
Write-Host "  - Type 'download' to let Packer download it"
Write-Host "  - Type a custom path"
Write-Host ""
$isoInput = Read-Host "Enter ISO path"

if ([string]::IsNullOrWhiteSpace($isoInput)) {
    $isoPath = $defaultIsoPath
    $useLocalIso = $true
    Write-Host "Using default ISO: $isoPath"
} elseif ($isoInput -eq "download" -or $isoInput -eq "Download") {
    $useLocalIso = $false
    $isoPath = ""
    Write-Host "Packer will download the ISO from the internet."
} else {
    $isoPath = $isoInput
    $useLocalIso = $true
    Write-Host "Using custom ISO: $isoPath"
}

if ($useLocalIso -and -not (Test-Path $isoPath)) {
    Write-Error "ISO file not found: $isoPath"
    exit 1
}

Write-Host ""

# ---- Step 2: Hyper-V Switch Name ----
Write-Host "Available Hyper-V Switches:"
Get-VMSwitch | Format-Table Name, SwitchType -AutoSize
Write-Host ""
Write-Host "Switch name (default: $defaultSwitchName)"
$switchName = Read-Host "Enter switch name"

if ([string]::IsNullOrWhiteSpace($switchName)) {
    $switchName = $defaultSwitchName
    Write-Host "Using default switch: $switchName"
}

$switchExists = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (-not $switchExists) {
    Write-Error "Switch '$switchName' not found."
    exit 1
}

Write-Host ""

# ---- Step 3: Host IP Address ----
Write-Host "Available Network Adapters with IPs:"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Format-Table InterfaceAlias, IPAddress -AutoSize
Write-Host ""
Write-Host "Host IP (default: $defaultHostIP)"
$hostIP = Read-Host "Enter your host IP"

if ([string]::IsNullOrWhiteSpace($hostIP)) {
    $hostIP = $defaultHostIP
    Write-Host "Using default host IP: $hostIP"
}

if ($hostIP -notmatch "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}") {
    Write-Error "Invalid IP address format: $hostIP"
    exit 1
}

Write-Host ""

# ---- Step 4: Confirm ----
Write-Host "========================================"
Write-Host "   Build Configuration"
Write-Host "========================================"

if ($useLocalIso) {
    Write-Host "ISO Source   : $isoPath"
} else {
    Write-Host "ISO Source   : Download from internet"
}
Write-Host "Switch       : $switchName"
Write-Host "Host IP      : $hostIP"
Write-Host ""

$confirm = Read-Host "Proceed with build? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Build cancelled."
    exit 0
}

# ---- Step 5: Build ----
Write-Host ""
Write-Host "Starting Packer build..."
Write-Host ""

$isoArg = @()
if ($useLocalIso) {
    $isoArg = @("-var", "iso_url=file:///$isoPath")
}

packer build -force -var "switch_name=$switchName" -var "host_ip=$hostIP" $isoArg ubuntu24.pkr.hcl

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   BUILD COMPLETED SUCCESSFULLY!"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Golden image located at:"
    Write-Host "  E:\homelab\packer\output-ubuntu\"
    Write-Host ""
    Write-Host "To add to Vagrant:"
    Write-Host "  vagrant box add --name golden-ubuntu output-ubuntu/packer-ubuntu-24-04.box"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   BUILD FAILED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Check the output above for errors."
    Write-Host ""
}