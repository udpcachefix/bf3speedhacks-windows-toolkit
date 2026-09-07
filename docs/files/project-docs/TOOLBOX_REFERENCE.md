# Toolbox reference

This reference documents the 30 files imported from the supplied auxiliary archives. Descriptions are based on static inspection of the supplied bytes. No executable was launched during preparation.

Risk describes the likely impact of applying the file on a current Windows system. It is not a malware verdict.

| Risk | Meaning |
| --- | --- |
| Low | Narrow, usually reversible user/system change |
| Medium | Administrative, compatibility-sensitive, or broader change |
| High | Broad system, network, permission, power, or global driver-profile change |
| Third-party | Binary or material whose provenance/license must be verified separately |

## Admin & permissions

### `admin-context/AddAdminPS_SFA.reg`

**Risk:** Medium  
**Purpose:** Adds the same elevated PowerShell action through SystemFileAssociations\.ps1, covering systems where the primary PowerShell file-class registration differs.

Functionally overlaps the other admin PowerShell context-menu file. It launches arbitrary selected scripts elevated.

**Usage:** Import only if the other PowerShell context-menu registration does not appear on the target system.

### `admin-context/AddAdminPowerShellContextMenu.reg`

**Risk:** Medium  
**Purpose:** Adds “Run with PowerShell (Admin)” under the PowerShell script file class and launches the selected .ps1 in an elevated PowerShell process.

This is a convenience launcher, not a safety boundary. Any selected script receives administrator rights. Review the script before launching it.

**Usage:** Import the .reg file, then right-click a PowerShell script associated with Microsoft.PowerShellScript.1.

### `admin-context/Add Take Ownership to Context menu.reg`

**Risk:** High  
**Purpose:** Adds an Explorer “Take Ownership” command for files and folders. It runs takeown and then grants the local Administrators group Full Control; folder changes recurse through descendants.

Useful when recovering access to files you legitimately administer. It changes ownership and ACLs, so applying it to Windows, Program Files, component-store, or application folders can break inherited permissions and servicing. The file itself credits Walter Glenn / How-To Geek and is treated as third-party material rather than MIT-licensed project code.

**Usage:** Import the .reg file as an administrator, then use the new Explorer context-menu entry only on paths whose permissions you intentionally want to replace.

## Cleanup

### `cleanup/Windows-Orphan-Cleanup-Audit.ps1`

**Risk:** Medium  
**Purpose:** Audits selected application-data directories against installed programs, paths, running processes, services and scheduled tasks, then reports possible orphaned folders. Default execution is read-only.

Deletion occurs only with explicit switches. -CleanTempFiles can remove unlocked Temp files; -DeleteConfirmedUnused can delete folders the user explicitly marked unused after a second confirmation. The script intentionally treats every candidate as a review hint rather than proof. GUI mode enables the deletion-capable paths but still requires explicit confirmation.

**Usage:** Start with the default read-only run. Use -MeasureFolderSizes for sizing and only enable cleanup switches after reviewing generated reports.

### `cleanup/Start-Windows-Cleanup-GUI.cmd`

**Risk:** Medium  
**Purpose:** Checks for elevation, self-elevates when needed and launches Windows-Orphan-Cleanup-Audit.ps1 in STA GUI mode.

GUI mode enables folder-size measurement, interactive review, temp cleanup and deletion of explicitly confirmed unused folders. The underlying script still presents separate deletion plans and typed confirmations.

**Usage:** Keep this CMD next to Windows-Orphan-Cleanup-Audit.ps1 and run it when interactive GUI review is wanted.

## Gaming

### `gaming/Battlefield6 high.reg`

**Risk:** Medium  
**Purpose:** Creates an Image File Execution Options PerfOptions entry for bf6.exe and sets CpuPriorityClass to 3 (High).

Every matching bf6.exe launch is affected. High priority can reduce scheduling headroom for background, audio, capture, networking or system work under load. It does not guarantee lower latency or higher FPS.

**Usage:** Import only if bf6.exe is the intended executable and benchmark before/after behavior.

### `gaming/Disable Gamebar fixed.reg`

**Risk:** Medium  
**Purpose:** Disables Game Bar presence writing and Game DVR/capture through machine and per-user values while leaving AutoGameModeEnabled set to 1. It also writes fullscreen-optimization related GameConfigStore values.

Can affect Win+G, background capture and Xbox gaming overlays. The “fixed” variant differs from Disable Gamebar.reg by keeping Game Mode enabled and adding more GameDVR/FSE policy values.

**Usage:** Import for the intended user and system. Sign out or reboot before judging the result.

### `gaming/Disable Gamebar.reg`

**Risk:** Medium  
**Purpose:** Disables Game Bar presence writing, Game DVR/capture and Auto Game Mode through machine and current-user registry values.

Can disable Win+G and capture features. It also disables Game Mode for the current user, so it should not be described as a pure Game Bar toggle.

**Usage:** Import for the intended user and reboot or sign out.

### `gaming/Windows Gaming Performance & Scheduler Tweaks.reg`

**Risk:** Medium  
**Purpose:** Removes two explicit timer/power-throttling overrides, sets core-parking ValueMax to 100, disables multimedia network throttling, sets SystemResponsiveness=10, raises Games task priorities and writes Win32PrioritySeparation=0x26.

Also restores DisablePagingExecutive and LargeSystemCache to 0. These are machine-wide scheduler and multimedia settings; claimed gaming benefits depend on workload and are not guaranteed.

**Usage:** Record the original values first and test with repeatable frametime/latency measurements.

## Input

### `input/Windows_10+8.x_MouseFix_ItemsSize=100%_Scale=1-to-1_@6-of-11.reg`

**Risk:** Medium  
**Purpose:** Writes MouseSensitivity=10 and custom SmoothMouseXCurve/SmoothMouseYCurve values, plus disables default-user mouse acceleration thresholds.

The filename indicates a 100% display-scale 1:1 mouse-fix profile. Games using Raw Input bypass the classic Windows pointer acceleration path, so this may not affect them. Applying a curve designed for another scaling/input configuration can change desktop pointer behavior.

**Usage:** Use only for the matching Windows scaling/pointer setup and keep the previous mouse registry values for rollback.

### `input/KeyboardDataQueueSize.reg`

**Risk:** Low  
**Purpose:** Sets kbdclass\Parameters\KeyboardDataQueueSize to 0x64 (100 decimal).

Changes the keyboard class driver's input queue capacity. A larger or smaller queue is not a direct input-latency control, and 100 is already a common/default value on many systems.

**Usage:** Benchmark only if you know the current value and have a concrete reason to override it.

### `input/MouseDataQueueSize.reg`

**Risk:** Low  
**Purpose:** Sets mouclass\Parameters\MouseDataQueueSize to 0x64 (100 decimal).

Changes mouse class-driver queue capacity. Queue size is not equivalent to USB polling rate or render/input latency and may be a no-op relative to the existing default.

**Usage:** Benchmark before and after instead of assuming a latency improvement.

## NVIDIA

### `nvidia/inspector/Apply_NVIDIA_Inspector_Settings.cmd`

**Risk:** High  
**Purpose:** Imports NVIDIA_Inspector_Settings.nip with inspector.exe. If inspector.exe is missing, it downloads a binary from the FR33THY/Ultimate-Files GitHub path embedded in the CMD.

The import targets the NVIDIA Base Profile, so effects are global rather than game-specific. The downloader does not pin a version or verify a cryptographic hash before execution. The supplied repo copy of inspector.exe is therefore documented with its SHA-256 separately.

**Usage:** Prefer using the included, hash-documented binary or independently verified NVIDIA Profile Inspector release. Export current profiles before applying.

### `nvidia/inspector/NVIDIA_Inspector_Default.nip`

**Risk:** Medium  
**Purpose:** Contains an empty Base Profile with no settings.

The paired revert CMD imports this file. It is not a captured snapshot of the user's pre-change NVIDIA settings, so it should not be treated as a guaranteed byte-for-byte rollback of every previous profile value.

**Usage:** Use only after understanding NVIDIA Profile Inspector import behavior. A real backup exported before applying changes is safer.

### `nvidia/profiles/Base Profile.nip`

**Risk:** High  
**Purpose:** Imports 38 Base Profile values into NVIDIA Profile Inspector, including refresh-rate, G-SYNC/VRR, pre-rendered-frame, filtering, power-management, NIS, V-Sync, cache and OpenGL-GPU fields.

Several entries use raw numeric driver enums and five have no human-readable setting name. The Preferred OpenGL GPU string contains a captured GPU identifier, making the profile hardware-specific. Treat this as a legacy reference profile, not a universal preset.

**Usage:** Inspect in NVIDIA Profile Inspector before importing. Export the current driver profiles first.

### `nvidia/inspector/NVIDIA_Inspector_Settings.nip`

**Risk:** High  
**Purpose:** Imports 31 NVIDIA Base Profile settings covering frame limiter, G-SYNC/VRR, pre-rendered frames, refresh rate, low-latency mode, V-Sync, filtering, CUDA, power management, shader cache, threaded optimization and OpenGL behavior.

Many values are NVIDIA raw enum values. The Preferred OpenGL GPU entry contains a captured device identifier, so it is not hardware-neutral. Global Base Profile changes can affect all games and applications using the NVIDIA driver.

**Usage:** Export current profiles first, inspect each setting in the matching NVIDIA Profile Inspector version and test per workload.

### `nvidia/inspector/inspector.exe`

**Risk:** Third-party  
**Purpose:** Windows PE32 .NET executable identifying itself as NVIDIA Profile Inspector. SHA-256: 7d5510deeaacb50c88a49bbf1d894dae44c5ce58c00d5a88392346646b14e8f3.

This is a third-party binary supplied inside the uploaded archive. It was not executed during repository preparation. Its license/provenance is not established by the archive itself, so the repository-level MIT license explicitly does not relicense it.

**Usage:** Verify provenance and hash before execution. The project documentation records the exact supplied hash so replacements are detectable.

### `nvidia/inspector/Revert_NVIDIA_Inspector_Settings_Only.cmd`

**Risk:** Medium  
**Purpose:** Imports NVIDIA_Inspector_Default.nip using inspector.exe and uses the same GitHub fallback downloader if the executable is missing.

The supplied default .nip is an empty Base Profile, not a backup taken before modification. Therefore this script is a convenience reset attempt, not a guaranteed restoration of the user's previous custom settings.

**Usage:** Prefer restoring an exported pre-change NVIDIA profile backup when one exists.

## Network

### `network/DisableNdu.reg`

**Risk:** Medium  
**Purpose:** Sets the Ndu service Start value to 4 in ControlSet001, disabling the Windows Network Data Usage Monitoring component for that control set.

Can affect Windows network-usage accounting and diagnostics. Because it targets ControlSet001 rather than CurrentControlSet, behavior depends on which control set is active.

**Usage:** Do not apply as a generic latency tweak without a specific reason and rollback plan.

### `network/DisableNetBT.reg`

**Risk:** High  
**Purpose:** Sets the NetBT service Start value to 4, disabling the NetBIOS over TCP/IP driver/service.

Can break legacy name resolution, discovery or applications/environments that still depend on NetBIOS. Modern networks may not need it, but disabling the service is broader than disabling NetBIOS per individual adapter.

**Usage:** Use only when legacy NetBIOS functionality is known to be unnecessary.

### `network/Ethernet RSS affinities.ps1`

**Risk:** High  
**Purpose:** Configures adapter “Ethernet” for four RSS queues, MaxProcessors=4, NUMAStatic profile, BaseProcessorNumber=4 and MaxProcessorNumber=10.

The values are CPU-topology and adapter-specific. On another system the adapter may have a different name, fewer queues, different NUMA layout or different optimal processor placement. Wrong affinity choices can reduce throughput or increase latency rather than improve it.

**Usage:** Edit the adapter name and derive CPU/RSS topology first with Get-NetAdapterRss and system CPU information.

### `network/reset/Run-Universal-Network-Reset-MTU1492.cmd`

**Risk:** High  
**Purpose:** Runs Universal-Network-Reset-MTU1492.ps1 with PowerShell execution-policy bypass and pauses at completion.

The actual changes are performed by the paired PowerShell script. This wrapper is intentionally one-click and therefore should only be used after reading the reset documentation.

**Usage:** Keep both files together. Run the CMD when the fixed MTU 1492 reset is actually desired.

### `network/reset/Universal-Network-Reset-MTU1492.ps1`

**Risk:** High  
**Purpose:** Selects the active physical Ethernet/WLAN adapter, records before/after state, resets exposed advanced NIC properties to driver defaults, normalizes selected TCP globals, enables RSS/RSC where supported, forces IPv4 and IPv6 MTU 1492 and restarts only that adapter.

It deliberately does not remove VPN/Hyper-V bindings, DNS settings or IP addressing. TCP changes include RSS on, autotuning normal, ECN off, InitialRTO 3000, RSC on, Fast Open on and supplemental congestion provider reset to default. MTU 1492 is persistent and is not the normal Ethernet default of 1500; it is appropriate only where the path requires it, such as many PPPoE links.

**Usage:** Use when the goal is to undo prior NIC/TCP tuning and intentionally force MTU 1492. For automatic path-MTU discovery, use a separate MTU test tool instead.

## Power

### `power/power plan.ps1`

**Risk:** High  
**Purpose:** Modifies the current power plan: CPU EPP/boost/core parking and thresholds, USB selective suspend/LPM, PCIe ASPM, disk idle, sleep, display timeout, multimedia playback bias and detected SATA HIPM/DIPM settings.

It writes both AC and DC values, including EPP=0, core parking minimum/maximum=100, USB and PCIe power saving off, sleep off and disk idle off. This can materially increase idle power, heat and battery drain. Several CPU aliases are hardware/Windows-build dependent.

**Usage:** Run as administrator only after exporting the current power plan or otherwise recording its values. Avoid as a generic laptop preset.

### `power/Disable Powersaving in Device Manager.ps1`

**Risk:** High  
**Purpose:** Attempts to set MSPower_DeviceEnable.Enable to False through WMI/CIM for USB-root related devices.

The implementation enumerates MSPower_DeviceEnable repeatedly and then filters using PNPDeviceID even though the WMI class commonly identifies devices through InstanceName. It may behave differently from the apparent intent or fail to target the expected devices. Do not treat it as a verified universal replacement for Device Manager power-management checkboxes.

**Usage:** Review and test on a non-critical machine before use. A maintained device-specific implementation should identify exact instances first.

### `power/Disable FastBoot.reg`

**Risk:** Low  
**Purpose:** Sets HiberbootEnabled to 0 under Session Manager\Power, disabling Windows Fast Startup.

This does not necessarily remove hiberfil.sys or disable full hibernation. Boot behavior may become more predictable at the cost of slower cold startup on some systems.

**Usage:** Import as administrator and reboot.

## System

### `system/Windows UI, Power, Driver & Display Tweaks.reg`

**Risk:** High  
**Purpose:** Sets instant menu/hover timings, disables hibernation/Fast Startup, blocks automatic driver delivery, writes NVIDIA/graphics-related registry values, sets DWM OverlayTestMode=5 and disables Notification Center.

This is a mixed preset rather than one tweak. The RMHdcpKeyglobZero and OverlayTestMode values are hardware/driver-sensitive and may affect DRM, overlays, MPO behavior or display compatibility. The display-adapter path ending in 0000 is not guaranteed to identify the intended GPU on every system.

**Usage:** Prefer applying narrowly scoped components individually. Create a restore point and export affected keys first.

## UI

### `ui/Disable_Notification_Center_for_all_users.reg`

**Risk:** Low  
**Purpose:** Writes DisableNotificationCenter=1 in current-user and machine policy locations.

Suppresses the Notification Center/Action Center interface. The HKCU value applies only to the user importing it; the HKLM policy provides machine scope where honored.

**Usage:** Import as administrator if machine-wide policy is intended.

## Windows Update

### `windows-update/Disable Automatic Driver Updates.reg`

**Risk:** Medium  
**Purpose:** Excludes drivers from Windows quality updates, blocks device metadata retrieval from Microsoft and sets driver-search order to avoid Windows Update.

Useful when maintaining vendor drivers manually, but it can also prevent security, compatibility or hardware fixes from arriving automatically.

**Usage:** Import as administrator. Revert the policy values before relying on Windows Update for drivers again.

### `windows-update/Disable Win11 Edition Upgrade.ps1`

**Risk:** Medium  
**Purpose:** Sets TargetReleaseVersion=1 and TargetReleaseVersionInfo to the currently installed DisplayVersion, then restarts Windows Update.

Despite its filename, this targets the Windows feature release, not Home/Pro/Enterprise edition licensing. It also omits ProductVersion, which newer Windows policy guidance commonly pairs with these values. The maintained Set-WindowsFeatureTarget.ps1 is preferred.

**Usage:** Prefer scripts/Set-WindowsFeatureTarget.ps1. Use this preserved variant only when you understand the policy behavior.
