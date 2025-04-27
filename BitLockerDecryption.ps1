# Multi-Drive BitLocker Decryption Script
# This script will list all drives with BitLocker protection and allow the user to choose which drives to decrypt

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Multi-Drive BitLocker Decryption Script" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "This script will decrypt selected BitLocker encrypted drives." -ForegroundColor Yellow
Write-Host "If no drives are encrypted, the script will exit." -ForegroundColor Red
Write-Host ""

# === Get all drives with BitLocker protection ===
$bitLockerDrives = Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq "On" }

# Check if there are any drives with BitLocker enabled
if ($bitLockerDrives.Count -eq 0) {
    Write-Host "No BitLocker encrypted drives found." -ForegroundColor Red
    Write-Host "Exiting script." -ForegroundColor Yellow
    exit
}

# === Display drives with BitLocker encryption enabled ===
Write-Host "The following drives are encrypted with BitLocker:" -ForegroundColor Yellow
$bitLockerDrives | ForEach-Object {
    Write-Host "$($_.MountPoint) - $($_.VolumeStatus) - Encryption: $($_.EncryptionPercentage)% Complete" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Please choose the drives to decrypt (e.g., C, D, E, etc.). Enter 'All' to decrypt all encrypted drives, or 'Exit' to quit." -ForegroundColor Yellow
$driveChoice = Read-Host "Enter your choice"

# === Validate the user input ===
if ($driveChoice -eq "Exit") {
    Write-Host "Exiting script." -ForegroundColor Yellow
    exit
}

# If user chooses 'All', decrypt all encrypted drives
if ($driveChoice -eq "All") {
    $selectedDrives = $bitLockerDrives
} else {
    $selectedDrives = $bitLockerDrives | Where-Object { $_.MountPoint -in $driveChoice.Split(",") }
}

# === Confirm decryption of selected drives ===
if ($selectedDrives.Count -eq 0) {
    Write-Host "No valid drives selected. Exiting script." -ForegroundColor Red
    exit
}

Write-Host "The following drives will be decrypted:" -ForegroundColor Yellow
$selectedDrives | ForEach-Object { Write-Host "$($_.MountPoint)" -ForegroundColor Green }

Write-Host "Do you want to proceed with decryption?" -ForegroundColor Yellow
Write-Host "[1] - Yes, decrypt selected drives" -ForegroundColor Cyan
Write-Host "[2] - No, exit" -ForegroundColor Cyan
$decryptionChoice = Read-Host "Enter your choice"

if ($decryptionChoice -ne "1") {
    Write-Host "Exiting script." -ForegroundColor Yellow
    exit
}

# === Start decryption for selected drives ===
foreach ($drive in $selectedDrives) {
    Write-Host "Starting decryption for drive $($drive.MountPoint)..." -ForegroundColor Cyan
    Disable-BitLocker -MountPoint $drive.MountPoint

    # === Monitor the decryption progress for each drive ===
    function Monitor-DecryptionProgress {
        $status = Get-BitLockerVolume -MountPoint $drive.MountPoint
        while ($status.ProtectionStatus -eq "On" -or $status.EncryptionPercentage -lt 100) {
            $progress = $status.EncryptionPercentage
            $statusMessage = $status.VolumeStatus
            Write-Host "Drive $($drive.MountPoint) Decryption Progress: $progress%" -ForegroundColor Yellow
            Write-Host "Status: $statusMessage" -ForegroundColor Yellow

            Start-Sleep -Seconds 30

            $status = Get-BitLockerVolume -MountPoint $drive.MountPoint
        }
    }

    # Begin monitoring decryption progress for the current drive
    Monitor-DecryptionProgress

    # === Decryption complete ===
    Write-Host "Decryption complete for drive $($drive.MountPoint)!" -ForegroundColor Green
}

Write-Host ""
Write-Host "All selected drives have been decrypted." -ForegroundColor Green
Write-Host "Process complete." -ForegroundColor Green
