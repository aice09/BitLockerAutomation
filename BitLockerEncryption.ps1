# BitLocker Encryption Automator
# WARNING: Machine will restart after starting encryption

Clear-Host
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host " IMPORTANT WARNING" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Please SAVE all your work NOW." -ForegroundColor Yellow
Write-Host "This script will automatically RESTART your machine to start encryption." -ForegroundColor Red
Write-Host ""
Pause

# Check if BitLocker is already enabled
$OSDrive = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

if ($OSDrive.ProtectionStatus -eq "On") {
    Write-Host "BitLocker is already ENABLED on C:. Exiting..." -ForegroundColor Green
    exit
} else {
    Write-Host "BitLocker is NOT enabled. Running requirements check..." -ForegroundColor Yellow
}

# === Run BitLocker Requirements Checker ===
function Check-BitLockerRequirements {
    $result = @{
        Capable = $true
        Reasons = @()
    }

    # Check Admin
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $result.Capable = $false
        $result.Reasons += "Not running as Administrator."
    }

    # Check Secure Boot
    try {
        if (-not (Confirm-SecureBootUEFI)) {
            $result.Capable = $false
            $result.Reasons += "Secure Boot is not enabled."
        }
    } catch {
        $result.Capable = $false
        $result.Reasons += "Cannot confirm Secure Boot (maybe Legacy BIOS)."
    }

    # Check Boot Mode (must be UEFI)
    $firmwareType = (Get-CimInstance -ClassName Win32_ComputerSystem).BootROMSupported
    if (-not $firmwareType) {
        $result.Capable = $false
        $result.Reasons += "Legacy BIOS detected, UEFI required."
    }

    # Check TPM
    $tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    if (-not $tpm -or -not $tpm.IsEnabled().IsEnabled -or -not $tpm.IsActivated().IsActivated -or $tpm.SpecVersion -notlike "*2.0*") {
        $result.Capable = $false
        $result.Reasons += "TPM 2.0 not found or not enabled."
    }

    # Check Partition Style
    $disk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" -and $_.PartitionStyle -eq "GPT" }
    if (-not $disk) {
        $result.Capable = $false
        $result.Reasons += "System drive is not using GPT partition style."
    }

    return $result
}

$checkResult = Check-BitLockerRequirements

if (-not $checkResult.Capable) {
    Write-Host "System FAILED BitLocker requirements check:" -ForegroundColor Red
    foreach ($reason in $checkResult.Reasons) {
        Write-Host " - $reason" -ForegroundColor Red
    }
    exit
} else {
    Write-Host "System PASSED all BitLocker requirements!" -ForegroundColor Green
}

# === Select Encryption Option ===
Write-Host ""
Write-Host "Choose encryption type:" -ForegroundColor Cyan
Write-Host "[ENTER] - Encrypt entire drive (Recommended)"
Write-Host "[1]     - Encrypt used disk space only (Faster)"
Write-Host "[2]     - Encrypt entire drive"
$encryptionChoice = Read-Host "Enter your choice"

switch ($encryptionChoice) {
    "1" { $EncryptionMethod = "UsedSpaceOnly" }
    "2" { $EncryptionMethod = "Full" }
    default { $EncryptionMethod = "Full" }
}

# === Choose Recovery Key Save Option ===
Write-Host ""
Write-Host "Choose recovery key save option:" -ForegroundColor Cyan
Write-Host "[1] - Save to network share"
Write-Host "[2] - Save to OneDrive"
Write-Host "[3] - Print the recovery key"
$saveChoice = Read-Host "Enter your choice"

$RecoveryKeyPath = ""

if ($saveChoice -eq "1") {
    $RecoveryKeyPath = Read-Host "Enter network path (e.g. \\server\share)"
} elseif ($saveChoice -eq "2") {
    Write-Host "Saving to OneDrive is currently manual. Script will prompt save file dialog after encryption." -ForegroundColor Yellow
} elseif ($saveChoice -eq "3") {
    Write-Host "Recovery key will be displayed for you to print." -ForegroundColor Yellow
} else {
    Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
    exit
}

# === Start BitLocker Encryption ===
Write-Host ""
Write-Host "Starting BitLocker encryption..." -ForegroundColor Cyan

# Backup Recovery Key
$protector = Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector

if ($saveChoice -eq "1" -and $RecoveryKeyPath) {
    Backup-BitLockerKeyProtector -MountPoint "C:" -RecoveryKeyPath $RecoveryKeyPath
    Write-Host "Recovery Key saved to network share." -ForegroundColor Green
} elseif ($saveChoice -eq "3") {
    $key = (Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
    Write-Host "Recovery Key: $($key.RecoveryPassword)" -ForegroundColor Yellow
    Pause
}

# Start Encryption
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly:($EncryptionMethod -eq "UsedSpaceOnly") -TpmProtector

Write-Host ""
Write-Host "Encryption started successfully." -ForegroundColor Green
Write-Host "Restarting the machine to complete encryption process..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Restart-Computer
