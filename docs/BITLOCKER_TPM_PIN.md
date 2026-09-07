# BitLocker with TPM and a startup PIN

This procedure protects an encrypted Windows installation against offline file modification and common pre-login password-reset techniques. It applies primarily to Windows 11 Pro, Enterprise, and Education. Confirm edition support before changing protectors.

## Preconditions

* The operating-system drive is already encrypted or ready for BitLocker.
* TPM is present, ready, and enabled in UEFI.
* Windows boots in UEFI mode.
* Secure Boot is enabled where supported.
* A verified 48-digit recovery password is stored outside this computer.
* You can physically test a reboot and retrieve the recovery password if required.

Run the read-only report first:

```powershell
.\scripts\Get-BitLockerReadiness.ps1
```

## 1. Verify the recovery protector

Open Windows Terminal or Command Prompt as administrator:

```text
manage-bde -protectors -get C:
```

Confirm an entry named `Numerical Password` exists. Store its 48-digit value outside the encrypted Windows partition, for example in an independently protected password manager, a printed secure record, a separate secured USB device, or the Microsoft account you alone control.

Do not continue if the only recovery-key copy is on drive C.

## 2. Verify encryption and protection

```text
manage-bde -status C:
```

Expected state for an already encrypted drive:

```text
Conversion Status: Fully Encrypted
Percentage Encrypted: 100%
Protection Status: Protection On
```

The drive appearing unlocked while Windows is running is normal.

## 3. Require startup authentication through policy

Press `Win + R`, enter `gpedit.msc`, then open:

```text
Computer Configuration
  Administrative Templates
    Windows Components
      BitLocker Drive Encryption
        Operating System Drives
          Require additional authentication at startup
```

Set the policy to `Enabled` and configure:

| Option | Value |
| --- | --- |
| Allow BitLocker without a compatible TPM | Unchecked |
| Configure TPM startup | Allow TPM |
| Configure TPM startup PIN | Require startup PIN with TPM |
| Startup-key options | Disabled unless a USB startup key is specifically required |

Apply the policy:

```text
gpupdate /force
```

If Windows still returns policy error `0x80310060`, restart once and verify the policy again.

## 4. Add the TPM-and-PIN protector

Use the documented single switch. The spaces shown on the original page are invalid.

```text
manage-bde -protectors -add C: -TPMAndPIN
```

Enter and confirm a startup PIN when prompted. Use a PIN different from Windows Hello and the Windows password. Avoid birthdays, repeated digits, and simple sequences.

Do not place the PIN in a script, command-line argument, issue, screenshot, or repository.

## 5. Verify protectors

```text
manage-bde -protectors -get C:
```

Confirm both:

```text
Numerical Password
TPM And PIN
```

The Numerical Password is the recovery protector. Do not delete it.

## 6. Handle a separate TPM-only protector

If a distinct protector named only `TPM` remains, Windows may still unlock through that protector without asking for the PIN. Each protector has its own GUID.

Identify the GUID from the `manage-bde -protectors -get C:` output. Delete only the GUID belonging to the plain TPM protector:

```text
manage-bde -protectors -delete C: -id {GUID-OF-PLAIN-TPM-PROTECTOR}
```

Before pressing Enter, verify that the selected GUID is not the `TPM And PIN` protector and not the `Numerical Password` protector. Deleting the wrong protector can cause recovery lockout.

Re-run the protector listing. The intended final set normally contains at least:

```text
Numerical Password
TPM And PIN
```

## 7. Test a full boot

Perform a complete shutdown:

```text
shutdown /s /t 0
```

Power the system on. BitLocker should request the startup PIN before Windows loads. After the PIN, Windows should continue to the normal sign-in screen. Browser tabs and website sessions normally remain stored; a standard shutdown does not inherently sign out websites.

## 8. Verify the final state

After signing in:

```text
manage-bde -status C:
manage-bde -protectors -get C:
```

Verify full encryption, 100 percent encrypted, protection on, a recovery Numerical Password, and a TPM And PIN protector.

Open `msinfo32` and verify:

```text
BIOS Mode: UEFI
Secure Boot State: On
```

Secure Boot strengthens boot integrity but does not replace BitLocker.

## 9. Change the startup PIN later

```text
manage-bde -changepin C:
```

## Security result and limits

With the machine fully shut down, the Windows volume fully encrypted, and TPM plus PIN enforced, an attacker normally cannot modify encrypted Windows files offline to replace `utilman.exe` or perform similar local-password-reset techniques.

This does not prevent an attacker with physical access from destroying the partition, replacing hardware, installing a physical keylogger, observing the PIN, or using Windows while it is already unlocked.

Official reference: [Microsoft `manage-bde on`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/manage-bde-on).
