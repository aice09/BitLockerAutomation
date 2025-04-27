# BitLocker Readiness Check Script

Write-Host "=== BitLocker Readiness Check ===" -ForegroundColor Cyan

# 1. Check if running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    $adminStatus = "Admin Privileges: OK"
    $adminColor = "Green"
} else {
    $adminStatus = "Admin Privileges: FAIL (Run as Administrator)"
    $adminColor = "Red"
}

# 2. Check Windows Edition
$edition = (Get-WmiObject -Class Win32_OperatingSystem).Caption
if ($edition -match "Pro|Enterprise|Education") {
    $editionStatus = "Windows Edition ($edition): OK"
    $editionColor = "Green"
} else {
    $editionStatus = "Windows Edition ($edition): FAIL (BitLocker not supported natively)"
    $editionColor = "Red"
}

# 3. Check TPM presence and status
$tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
if ($tpm -and $tpm.IsEnabled().IsEnabled -and $tpm.IsActivated().IsActivated) {
    $tpmStatus = "TPM: OK (TPM $($tpm.SpecVersion))"
    $tpmColor = "Green"
} else {
    $tpmStatus = "TPM: FAIL (No TPM or not ready)"
    $tpmColor = "Red"
}

# 4. Check Secure Boot
try {
    $secureBoot = Confirm-SecureBootUEFI
    if ($secureBoot) {
        $secureBootStatus = "Secure Boot: Enabled"
        $secureBootColor = "Green"
    } else {
        $secureBootStatus = "Secure Boot: Disabled"
        $secureBootColor = "Yellow"
    }
} catch {
    $secureBootStatus = "Secure Boot: Cannot detect (likely Legacy BIOS)"
    $secureBootColor = "Yellow"
}

# 5. Check if booted in UEFI mode
$firmwareType = (Get-CimInstance -ClassName Win32_ComputerSystem).BootROMSupported
if ($firmwareType) {
    $bootModeStatus = "Boot Mode: UEFI"
    $bootModeColor = "Green"
} else {
    $bootModeStatus = "Boot Mode: Legacy BIOS"
    $bootModeColor = "Red"
}

# 6. Check Disk Partition Style
$osDrive = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty SystemDrive
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq "GPT" -and $_.OperationalStatus -eq "Online" }
if ($disk) {
    $partitionStyleStatus = "Disk Partition Style: GPT"
    $partitionStyleColor = "Green"
} else {
    $partitionStyleStatus = "Disk Partition Style: MBR or unknown (Not ideal)"
    $partitionStyleColor = "Red"
}

# Output individual results with color
Write-Host $adminStatus -ForegroundColor $adminColor
Write-Host $editionStatus -ForegroundColor $editionColor
Write-Host $tpmStatus -ForegroundColor $tpmColor
Write-Host $secureBootStatus -ForegroundColor $secureBootColor
Write-Host $bootModeStatus -ForegroundColor $bootModeColor
Write-Host $partitionStyleStatus -ForegroundColor $partitionStyleColor

Write-Host "=== Check Complete ===" -ForegroundColor Cyan

# Calculate overall status and return reason
$failures = 0
$returnReason = ""

$failures += if ($adminColor -eq "Red") { $returnReason += "Admin Privileges, "; 1 } else { 0 }
$failures += if ($editionColor -eq "Red") { $returnReason += "Windows Edition, "; 1 } else { 0 }
$failures += if ($tpmColor -eq "Red") { $returnReason += "TPM, "; 1 } else { 0 }
$failures += if ($secureBootColor -eq "Red" -or $secureBootColor -eq "Yellow") { $returnReason += "Secure Boot, "; 1 } else { 0 }
$failures += if ($bootModeColor -eq "Red") { $returnReason += "Boot Mode, "; 1 } else { 0 }
$failures += if ($partitionStyleColor -eq "Red") { $returnReason += "Disk Partition Style, "; 1 } else { 0 }

# Trim the last comma and space
$returnReason = $returnReason.TrimEnd(", ")

# Overall status
if ($failures -gt 0) {
    $overallStatus = "NOT CAPABLE"
    $overallColor = "Red"
} else {
    $overallStatus = "CAPABLE"
    $overallColor = "Green"
}

# Display overall status with color
Write-Host "Overall Status: $overallStatus" -ForegroundColor $overallColor
Write-Host "Return Reason: $returnReason" -ForegroundColor $overallColor
