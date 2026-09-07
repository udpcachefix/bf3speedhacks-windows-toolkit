# Windows Workarounds

This document carries over every topic from the source page and distinguishes the original intent from verified behavior. Commands under `legacy/` are preserved for inspection, not routine execution.

## 1. Install Chocolatey

### Source procedure

The page installs Chocolatey by downloading and immediately executing `install.ps1` with PowerShell execution policy bypassed for the current process. It offers equivalent PowerShell and Command Prompt forms, followed by one large unattended package installation.

The original bootstrap forms are preserved under `legacy/chocolatey/`. They execute code fetched from the internet and should be compared with Chocolatey's current official instructions before use.

### Repository implementation

Install Chocolatey using the current [official Chocolatey instructions](https://chocolatey.org/install), inspect `packages/chocolatey-packages.txt`, then run:

```powershell
.\scripts\Install-ChocolateyPackages.ps1 -WhatIf
.\scripts\Install-ChocolateyPackages.ps1
```

The repository does not pipe an unaudited network response directly into `iex`. The maintained installer verifies that `choco.exe` exists, ignores blank lines and comments, shows the package set, supports `-WhatIf`, and checks the exit code.

The source package list contains browsers, media tools, runtimes, development tools, security utilities, hardware tools, launchers, remote-access software, VPN clients, NVIDIA software, communication clients, and productivity applications. Package availability and names can change; a manifest is not a guarantee that every item still exists or is suitable.

## 2. MTU change

### Source procedure

The page displays IPv4 subinterfaces and persistently assigns MTU 1492 to an interface literally named `Ethernet`:

```text
netsh interface ipv4 show subinterface
netsh interface ipv4 set subinterface "Ethernet" mtu=1492 store=persistent
```

### Actual behavior

MTU is the maximum IP packet size for that interface before fragmentation or path handling. `1492` commonly accommodates PPPoE overhead, but ordinary Ethernet normally uses `1500`. A value that is too high can create path-MTU black holes; one that is unnecessarily low adds overhead.

### Repository implementation

`scripts/Set-NetworkMtu.ps1` requires an existing IPv4 interface alias, validates a range of 576 through 9,000 bytes, records the previous MTU, uses `Set-NetIPInterface`, and reports the final value.

## 3. Memory cleaner

### Source procedure

The page provides an infinite batch loop. Every ten minutes it reads `\Memory\Cache Bytes`; if the value exceeds 8 GiB, it calls:

```text
wmic.exe /Namespace:\\root\cimv2 Path Win32_PerfFormattedData_PerfOS_Memory Call EmptyWorkingSet
```

It suggests running the task hidden as `SYSTEM` with highest privileges.

### Actual behavior and status

`Cache Bytes` is not free memory. Windows uses standby and file cache memory to improve performance and reclaims it under pressure. The specified WMI performance-data class exposes counters, not a documented `EmptyWorkingSet` method. WMIC is deprecated/removed on newer systems. The example is therefore preserved as `legacy/memory/MemoryCleaner.bat` and not presented as a functional maintained tool.

The page separately mentions EmptyStandbyList/ISLC-style tools. Those third-party executables are not included.

## 4. Automated restore points

### Source procedure

The original batch file deletes all shadow copies with `vssadmin delete shadows /all /quiet`, then invokes the WMI SystemRestore method. The page recommends scheduling it daily as `SYSTEM`.

### Actual behavior and replacement

Deleting all snapshots destroys existing restore points and potentially other VSS-dependent recovery data before replacement succeeds. `scripts/New-SystemRestorePoint.ps1` calls the supported `Checkpoint-Computer` cmdlet without deleting anything. Starting with Windows 8, PowerShell normally refuses to create more than one restore point inside 24 hours.

The source version remains at `legacy/restore/AutomatedRestorePoints.bat`.

## 5. OpenShell settings

`configs/OpenShell-StartMenu.xml` preserves the complete `StartMenu` configuration for OpenShell 4.4.142 shown on the page. Major effects:

* Selects one-column Classic style and maps the Windows key to the Classic menu.
* Hides Documents, user folders, recent programs, jump lists, web search, update checks, menu shadow, and glass effects.
* Uses the Classic Skin without a user image or user name.
* Opens directly to the desktop instead of the Start screen.
* Adds short custom entries for Services, Device Manager, Registry Editor, Task Scheduler, Command Prompt, and PowerShell.
* Keeps Computer, Control Panel, PC Settings, Run, shutdown controls, and a search box.

The custom labels `SERV`, `DM`, `REG`, `TS`, `CMD`, and `PS` and absolute Windows paths are intentional carryovers.

## 6. Disable automatic microphone volume gain

### Source procedure

The page links to an archive containing `hide_cmd_window2.vbs`, `lock_mic_vol.bat`, `start_lock_mic_vol.bat`, and `nircmdc.exe`. It says to place files in `C:\Windows`, set an audio endpoint scalar where `65536` represents 100 percent and `32768` represents 50 percent, then optionally start the lock script from the all-users Startup folder.

Source links:

* [Referenced download](https://sethioz.com/forum/download/file.php?id=1527)
* [Referenced Reddit discussion](https://www.reddit.com/r/Windows10/comments/prxl6d/microphone_volume_keeps_auto_adjusting)

### Status

The archive is third-party binary content and is not mirrored here. Copying utilities into `C:\Windows` and continuously overriding endpoint volume is intrusive. The source URL included a session-like `sid` parameter; this repository deliberately omits that parameter. Prefer disabling automatic gain control in the responsible application or using a reviewed per-device solution.

## 7. NVIDIA driver-version-check bypass

### Source procedure

The page moves `%windir%\System32\nvapi64.dll` to the desktop to prevent an application from detecting the installed NVIDIA driver version, then provides a reverse move. It explicitly notes that OBS will stop working without the DLL.

### Actual behavior and status

`nvapi64.dll` is NVIDIA's 64-bit NVAPI library. Removing it from System32 can break every application relying on NVAPI, not only the version check. Windows or driver servicing may restore or replace it. The two examples are preserved under `legacy/nvidia/` with safer collision checks and `-WhatIf`, but remain unsupported workarounds.

## 8. Remove drivers installed by Windows Update

The source section contains only an image showing how to identify drivers in the Windows Update history; it provides no removal command or selection criteria. The repository does not invent a removal procedure. Use Settings, Device Manager's driver rollback where available, `pnputil /enum-drivers`, or vendor-supported cleanup only after identifying the exact package.

The embedded image remains visible on the [source page](https://project.bf3speedhacks.com/home/windows-workarounds).

## 9. Debugging made easy

The page provides two independent examples:

1. `Get-EventLog -LogName Application -EntryType Error, Warning`, formatted into `Downloads\eventlog_errors.txt`.
2. `Get-WinEvent -FilterHashTable @{LogName='System'; Level=1}`, formatted into `Downloads\eventlog_critical_errors.txt`.

The first uses the older `Get-EventLog` cmdlet and queries all matching Application entries without a time limit. The second catches every error, then reports "no critical errors," which can hide access, API, or I/O failures.

`scripts/Export-WindowsEvents.ps1` uses `Get-WinEvent` for both logs, defaults to the previous 24 hours, distinguishes an empty result from a query failure, validates the output directory, and writes UTF-8.

## 10. Block Windows updates KB5063878 and KB5062660

The page's script:

1. Stops `wuauserv` and BITS.
2. recursively deletes `C:\Windows\SoftwareDistribution\Download` contents.
3. Restarts the services.
4. Changes PSGallery to `Trusted` and installs the third-party `PSWindowsUpdate` module if needed.
5. Hides `KB5063878` and `KB5062660` and enumerates hidden updates.

The page describes the block as permanent and reliable. That is too strong: update metadata, supersedence, servicing-stack behavior, module compatibility, and organizational policy can change. The script also does not restore PSGallery's previous trust state. It is preserved under `legacy/updates/Block-SpecificUpdates.ps1` and is not part of the maintained toolset.

## 11. Windows 11 Enterprise energy-profile workaround

The page reports that, after startup, the UI can show High Performance while another energy mode remains internally selected. Its proposed sequence is:

```text
powercfg /setactive SCHEME_MIN
```

plus two registry values under `HKLM\SYSTEM\CurrentControlSet\Control\Power\EnergyMode`, both set to zero.

The repository carries this under `experimental/power/` because no affected build, reproduction procedure, measurements, or Microsoft reference is supplied. `Apply-EnergyModeWorkaround.reg` reproduces the values, `Restore-EnergyModeDefaults.reg` deletes them, and `Set-HighPerformance.cmd` activates the built-in High Performance alias.

## 12. Windows 11 TPM and BitLocker startup PIN

The page explains how to:

1. Confirm a 48-digit Numerical Password recovery protector.
2. Confirm full encryption and protection status.
3. Enable "Require additional authentication at startup" in Group Policy.
4. Require a startup PIN with TPM and apply policy.
5. Add a TPM-and-PIN protector.
6. Verify and remove a separate TPM-only protector if present.
7. Fully shut down and test preboot PIN entry.
8. Verify UEFI and Secure Boot in `msinfo32`.
9. Change the PIN later.
10. Understand the protection and remaining physical-access limits.

The site's command `manage-bde -protectors -add C: -TPM and PIN` is malformed. The documented switch is `-TPMAndPIN`. The corrected full procedure is in `docs/BITLOCKER_TPM_PIN.md`.

## 13. Enable BitLocker with TPM and a startup PIN

This is the heading used inside the preceding BitLocker section rather than a separate implementation. The goal is to prevent offline modification of the encrypted Windows partition, including replacement of accessibility executables to obtain a pre-login command prompt.

TPM plus PIN does not prevent disk destruction, hardware replacement, an already-unlocked session from being used, physical keylogging, or someone observing the PIN. The recovery password must remain available outside the encrypted machine.

## 14. "Disable Windows 11 Edition Upgrade"

### Source procedure

The script creates `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`, sets `TargetReleaseVersion=1`, copies the current `DisplayVersion` into `TargetReleaseVersionInfo`, and restarts `wuauserv`.

### Actual behavior and replacement

This targets a feature release, not a Windows edition. It can keep the device on a release until that release reaches end of service or policy changes. Current Microsoft policy documentation also requires the product version to be specified. `scripts/Set-WindowsFeatureTarget.ps1` therefore sets:

* `ProductVersion="Windows 11"`
* `TargetReleaseVersion=1`
* `TargetReleaseVersionInfo=<current DisplayVersion>`

`-Mode Remove` deletes all three local values. Domain or MDM policy may still apply. Pinning an unsupported release is not a substitute for security updates.

## Source-page metadata

The Windows Workarounds page displays a content update date of 4 September 2026 and the donation addresses reproduced in the repository README.
