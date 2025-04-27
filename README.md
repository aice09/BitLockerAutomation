# BitLockerAutomation

## Description
BitLockerAutomation is a collection of PowerShell scripts to automate and manage the encryption and decryption of drives using Microsoft's BitLocker. The repository contains scripts for checking the current BitLocker status, encrypting drives, decrypting drives, and ensuring that the system meets BitLocker requirements. Additionally, the repository includes a BitLocker monitoring script that provides real-time feedback on the encryption/decryption progress for all drives. Inspired by [Microsoft's Windows BitLocker Data Protection](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/).

## Features
- **BitLockerEncryption.ps1**: Encrypts a drive using BitLocker encryption with options to choose whether to encrypt the entire drive or just the used space.
- **BitLockerDecryption.ps1**: Decrypts a drive that has been encrypted with BitLocker, and monitors the decryption process.
- **BitLockerMonitor.ps1**: Monitors the progress of encryption or decryption on all relevant drives, providing live updates every 30 seconds.
- **BitLockerStatusCheck.ps1**: Checks if the system meets BitLocker's hardware requirements such as TPM, Secure Boot, and operating system edition.
  
## Requirements
- Windows 10 or later
- Administrator privileges
- BitLocker must be available and supported on your system
- PowerShell 5.0 or higher

## Installation

Clone this repository:

```bash
git clone https://github.com/yourusername/BitLockerAutomation.git
cd BitLockerAutomation
```
## Usage
### BitLocker Status Check
To check if your system meets the requirements for BitLocker, run:

Example Output from `.\BitLockerStatusCheck.ps1`
```plaintext
=== BitLocker Readiness Check ===
Admin Privileges: OK
Windows Edition (Microsoft Windows 10 Pro): OK
TPM: FAIL (No TPM or not ready)
Secure Boot: Disabled
Boot Mode: UEFI
Disk Partition Style: GPT
=== Check Complete ===
Overall Status: NOT CAPABLE
Return Reason: TPM, Secure Boot
```

Example Output from `.\BitLockerStatusCheckJSON.ps1`
```plaintext
{
    "returnCode":  1,
    "returnReason":  "TPM, Secure Boot, ",
    "returnResult":  "NOT CAPABLE",
    "requirements":  {
                         "AdminPrivileges":  "Running as administrator. PASS",
                         "WindowsEdition":  "Microsoft Windows 10 Pro. PASS",
                         "WindowsEditionStatus":  "Edition is supported. PASS",
                         "TPMStatus":  "Not Found or Not 2.0. FAIL",
                         "TPMSpecVersion":  "N/A",
                         "SecureBoot":  "Secure Boot not enabled. FAIL",
                         "BootMode":  "UEFI mode detected. PASS",
                         "DiskPartitionStyle":  "GPT partition style detected. PASS"
                     }
}
```
This will display the current status of BitLocker, including if the system has the necessary components such as TPM and Secure Boot.

### BitLocker Encryption
To encrypt a drive, run the `.\BitLockerEncryption.ps1`. Then once run the scrip will:
- Provides a warning to save any work, as the machine will restart once the encryption process starts.
- Checks if the system meets BitLocker's requirements (admin privileges, secure boot, TPM, GPT partition, etc.). In this case, the system passes all checks.
- Prompted the user to choose between encrypting used space only (faster) or the entire drive. The user chooses to encrypt the entire drive.
- The user selects to save the recovery key to a network share and provides the path.
- Then starts the BitLocker encryption and backs up the recovery key as specified by the user.
- The machine is scheduled for a restart to complete the encryption.
  
Sample output if system passes all the BitLocker requirements check:
```plaintext
==========================================
 IMPORTANT WARNING
==========================================
Please SAVE all your work NOW.
This script will automatically RESTART your machine to start encryption.

Press any key to continue . . .
Running BitLocker requirements check...
System PASSED all BitLocker requirements!
 
Choose encryption type:
[ENTER] - Encrypt entire drive (Recommended)
[1]     - Encrypt used disk space only (Faster)
[2]     - Encrypt entire drive
Enter your choice: 2

Choose recovery key save option:
[1] - Save to network share
[2] - Save to OneDrive
[3] - Print the recovery key
Enter your choice: 1
Enter network path (e.g. \\server\share): \\192.168.1.10\backup

Starting BitLocker encryption...
Recovery Key saved to network share.
Encryption started successfully.
Restarting the machine to complete encryption process...
```

If the system failed any of the BitLocker requirements (e.g., no TPM or legacy BIOS), the output would look like this:

```plaintext
==========================================
 IMPORTANT WARNING
==========================================
Please SAVE all your work NOW.
This script will automatically RESTART your machine to start encryption.

Press any key to continue . . .
Running BitLocker requirements check...
System FAILED BitLocker requirements check:
 - TPM 2.0 not found or not enabled.
 - Legacy BIOS detected, UEFI required.
Exiting...
```

### BitLocker Decryption
To decrypt a drive, use the decryption script:

Example Output from `.\BitLockerDecryption.ps1`

```plaintext
==========================================
 Multi-Drive BitLocker Decryption Script
==========================================
This script will decrypt selected BitLocker encrypted drives.
If no drives are encrypted, the script will exit.

The following drives are encrypted with BitLocker:
C: - Fully Decrypted - Encryption: 100% Complete
D: - Encrypting - Encryption: 75% Complete
E: - Fully Encrypted - Encryption: 100% Complete

Please choose the drives to decrypt (e.g., C, D, E, etc.). Enter 'All' to decrypt all encrypted drives, or 'Exit' to quit.
Enter your choice: All

The following drives will be decrypted:
C:
E:

Do you want to proceed with decryption?
[1] - Yes, decrypt selected drives
[2] - No, exit
Enter your choice: 1

Starting decryption for drive C...
Starting decryption for drive E...
Drive C Decryption Progress: 100%
Status: Fully Decrypted
Drive E Decryption Progress: 100%
Status: Fully Decrypted

Decryption complete for drive C!
Decryption complete for drive E!

All selected drives have been decrypted.
Process complete.
```
This script will:
- Allow you to select and decrypt whole drives (not just specific partitions or volumes). Once the drive is selected, the entire drive will be decrypted.
- Checks if the drives are fully encrypted (100% encryption). Only fully encrypted drives will be available for decryption.
- The user can choose either a specific drive (e.g., "C", "D", "E") or all drives ("All"). Drives that are still in the process of being encrypted will not be listed as eligible for decryption.
- If the drive is still encrypting (e.g., D: is at 75% encryption), the user cannot select it for decryption until it has reached 100% encryption.
- The script ensures that all drives marked as fully encrypted can be decrypted.
- It provides a visual status update, including decryption progress, for each drive selected.

### BitLocker Monitoring
To monitor the encryption or decryption progress of all relevant drives, run `.\BitLockerMonitor.ps1`
This script will:

1. Automatically detect all drives that need encryption or decryption.
2. Provide live updates on the encryption or decryption progress for each drive.
3. Display the current percentage of encryption/decryption every 30 seconds.
4. Show the final status once the operation completes for each drive.

The script will monitor all drives with either:
- ProtectionStatus as Off (drives that need to be encrypted).
- ProtectionStatus as On (drives that are being encrypted or decrypted).

Example Output from BitLocker Monitor:
```plaintext
==============================================
 BitLocker Encryption/Decryption Monitoring
==============================================
The following drives are currently being monitored:
Drive C: - Protection Status: On
Drive D: - Protection Status: Off

Monitoring drive: C:
Drive C: - Encrypting: 25% Complete - Status: Encryption in Progress
Drive C: - Encrypting: 50% Complete - Status: Encryption in Progress
Drive C: - Encrypting: 75% Complete - Status: Encryption in Progress
Drive C: - Operation Complete!
Final Status: Encryption in Progress
Encryption/Decryption completed successfully.

Monitoring drive: D:
Drive D: is not encrypted. Please run BitLocker encryption first.

All drives monitoring completed!
```

### License
This repository is licensed under the MIT License. See the LICENSE file for more details.

### Support
For any issues or suggestions, please feel free to open an issue on GitHub.

### Disclaimer
This is a personal project and is provided "as is" without warranty of any kind.

### Key Updates:
- Added **BitLocker monitoring** instructions under the **Usage** section.
- Included an **example output** of the monitoring process so users know what to expect.
- Mentioned that the **BitLockerMonitor.ps1** script monitors all drives that need encryption or decryption.

Let me know if you'd like me to tweak or add anything else!
