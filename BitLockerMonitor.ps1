# BitLockerMonitor.ps1
# This script monitors all drives that need encryption or decryption
# Displays live feedback on progress for all relevant drives

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " BitLocker Encryption/Decryption Monitoring" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan

# Get a list of all drives that are currently encrypted or need encryption
$drivesToMonitor = Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq 'On' -or $_.ProtectionStatus -eq 'Off' }

if ($drivesToMonitor.Count -eq 0) {
    Write-Host "No drives to monitor. All drives are either already encrypted or do not require encryption." -ForegroundColor Red
    exit
}

Write-Host "The following drives are currently being monitored:" -ForegroundColor Green
$drivesToMonitor | ForEach-Object {
    Write-Host "Drive $($_.MountPoint) - Protection Status: $($_.ProtectionStatus)" -ForegroundColor Yellow
}

# Monitor the encryption/decryption status of each drive
foreach ($drive in $drivesToMonitor) {
    $driveLetter = $drive.MountPoint
    Write-Host "`nMonitoring drive: $driveLetter" -ForegroundColor Cyan

    if ($drive.ProtectionStatus -eq 'Off') {
        Write-Host "Drive $driveLetter is not encrypted. Please run BitLocker encryption first." -ForegroundColor Red
        continue
    }

    # Monitor the encryption/decryption progress for each drive
    while ($drive.EncryptionPercentage -lt 100) {
        $encryptionPercentage = $drive.EncryptionPercentage
        $statusMessage = $drive.VolumeStatus
        $operation = if ($drive.VolumeStatus -eq 'Encryption in Progress') { 'Encrypting' } elseif ($drive.VolumeStatus -eq 'Decryption in Progress') { 'Decrypting' } else { 'Unknown' }

        Write-Host "Drive $driveLetter - $operation: $encryptionPercentage% Complete - Status: $statusMessage" -ForegroundColor Yellow

        # Wait for 30 seconds before checking the status again
        Start-Sleep -Seconds 30

        # Recheck the status of the drive
        $drive = Get-BitLockerVolume -MountPoint $driveLetter
    }

    Write-Host "Drive $driveLetter - Operation Complete!" -ForegroundColor Green
    Write-Host "Final Status: $statusMessage" -ForegroundColor Green
    Write-Host "Encryption/Decryption completed successfully." -ForegroundColor Green
}

Write-Host "`nAll drives monitoring completed!" -ForegroundColor Green
