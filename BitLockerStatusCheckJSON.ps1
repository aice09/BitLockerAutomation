# BitLocker Requirements Checker

$requirements = [ordered]@{}
$returnReason = @()
$returnCode = 0

# 1. Check Admin Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) {
    $requirements.AdminPrivileges = "Running as administrator. PASS"
} else {
    $requirements.AdminPrivileges = "Not running as administrator. FAIL"
    $returnReason += "AdminPrivileges, "
    $returnCode = 1
}

# 2. Check Windows Edition
$edition = (Get-WmiObject -Class Win32_OperatingSystem).Caption
if ($edition -match "Pro|Enterprise|Education") {
    $requirements.WindowsEdition = "$edition. PASS"
    $requirements.WindowsEditionStatus = "Edition is supported. PASS"
} else {
    $requirements.WindowsEdition = "$edition. FAIL"
    $requirements.WindowsEditionStatus = "Edition not supported for BitLocker. FAIL"
    $returnReason += "WindowsEdition, "
    $returnCode = 1
}

# 3. Check TPM
$tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
if ($tpm -and $tpm.IsEnabled().IsEnabled -and $tpm.IsActivated().IsActivated -and $tpm.SpecVersion -like "*2.0*") {
    $requirements.TPMStatus = "TPM 2.0 found and enabled. PASS"
    $requirements.TPMSpecVersion = $tpm.SpecVersion
} else {
    $requirements.TPMStatus = "Not Found or Not 2.0. FAIL"
    $requirements.TPMSpecVersion = "N/A"
    $returnReason += "TPM, "
    $returnCode = 1
}

# 4. Check Secure Boot
try {
    $secureBoot = Confirm-SecureBootUEFI
    if ($secureBoot) {
        $requirements.SecureBoot = "Secure Boot is enabled. PASS"
    } else {
        $requirements.SecureBoot = "Secure Boot not enabled. FAIL"
        $returnReason += "Secure Boot, "
        $returnCode = 1
    }
} catch {
    $requirements.SecureBoot = "Secure Boot status unknown. FAIL"
    $returnReason += "Secure Boot, "
    $returnCode = 1
}

# 5. Check Boot Mode (UEFI)
$firmwareType = (Get-CimInstance -ClassName Win32_ComputerSystem).BootROMSupported
if ($firmwareType) {
    $requirements.BootMode = "UEFI mode detected. PASS"
} else {
    $requirements.BootMode = "Legacy BIOS detected. FAIL"
    $returnReason += "BootMode, "
    $returnCode = 1
}

# 6. Check Disk Partition Style (GPT)
$disk = Get-Disk | Where-Object { $_.OperationalStatus -eq "Online" -and $_.PartitionStyle -eq "GPT" }
if ($disk) {
    $requirements.DiskPartitionStyle = "GPT partition style detected. PASS"
} else {
    $requirements.DiskPartitionStyle = "MBR or unknown partition style. FAIL"
    $returnReason += "DiskPartitionStyle, "
    $returnCode = 1
}

# Build final JSON
$finalResult = [ordered]@{
    returnCode    = $returnCode
    returnReason  = ($returnReason -join "")
    returnResult  = if ($returnCode -eq 0) { "CAPABLE" } else { "NOT CAPABLE" }
    requirements  = $requirements
}

# Convert to pretty JSON
$JsonOutput = $finalResult | ConvertTo-Json -Depth 3 -Compress:$false

# Save JSON to file
$OutputPath = ".\BitLockerRequirements.json"
$JsonOutput | Out-File -FilePath $OutputPath -Encoding utf8

# Display JSON in terminal
Write-Host $JsonOutput
