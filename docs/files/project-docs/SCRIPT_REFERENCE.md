# Script reference

This reference describes behavior observed in the supplied source. "Risk" rates the likely effect of executing a file on a current Windows installation, not whether the file contains malware.

## Risk scale

| Level | Meaning |
| --- | --- |
| Read-only | Queries state and writes no system setting |
| Low | Narrow, reversible feature change |
| Medium | Administrative or compatibility-sensitive change |
| High | Can remove protection, updates, recovery data, permissions, or major functionality |
| Critical | Combines many high-impact changes or broadly rewrites services |

## Maintained scripts

### `scripts/Get-WindowsTweakState.ps1`

Read-only. Reports OS identity, elevation, firewall profiles, hibernation availability, the driver-update exclusion policy, selected BCD values, restore points, and selected service states. Individual unsupported queries are captured as warnings instead of terminating the report.

### `scripts/New-SystemRestorePoint.ps1`

Low risk. Requires elevation, confirms System Restore support, and calls `Checkpoint-Computer` with a caller-supplied description. It does not delete existing restore points.

### `scripts/Set-Hibernation.ps1`

Medium risk. Requires elevation and runs `powercfg.exe /hibernate on` or `off`. Supports `-WhatIf` and confirmation. Disabling hibernation also disables Fast Startup.

### `scripts/Set-FirewallProfileState.ps1`

Low risk when enabling; high risk when disabling. Requires elevation and uses `Set-NetFirewallProfile` for Domain, Private, Public, or all profiles. Disabling requires `-Force`. Supports `-WhatIf` and confirmation.

### `scripts/Set-DriverUpdatePolicy.ps1`

Medium risk. Requires elevation and creates, sets, or removes the `ExcludeWUDriversInQualityUpdate` policy value. "Excluded" prevents drivers from being included with Windows quality updates; "Included" removes the local override. Supports `-WhatIf` and confirmation.

## Original root files

These files are preserved under `archive/wfiles-original/`.

| File | What it actually does | Scope and side effects | Risk |
| --- | --- | --- | --- |
| `BCD Edit.cmd` | Deletes the explicit platform-clock selection; disables dynamic tick; forces platform tick; sets boot timeout to two seconds; sets DEP to opt-out; changes boot UI/menu flags; disables Hyper-V launch; disables TPM boot entropy; enables quiet boot; disables hibernation. | Boot configuration, virtualization, exploit mitigation, TPM-related boot behavior, and power state. Timer flags are documented for debugging, not as generic tuning. BitLocker may request recovery after BCD changes. | High |
| `Disable Extras.bat` | Renames eight protected binaries to `.old` and attempts to kill them: SmartScreen, RuntimeBroker, SearchUI/Cortana, StartMenuExperienceHost, ShellExperienceHost, CompPkgSrv, GameBarPresenceWriter, and `upfc.exe`. | Can break the shell, Start menu, search, app broker, reputation checks, gaming integration, component servicing, and system-file repair. It has no elevation/error handling or rollback. | Critical |
| `Disbale Updates.bat` | Stops BITS, Cryptographic Services, MSI Installer, Update Orchestrator, and Windows Update; disables two update services; writes numerous Windows Update, Delivery Optimization, speech, metadata, Store, driver, and upgrade policies. | Prevents or disrupts updates, app installation, certificate/catalog processing, Store updates, and drivers. Several policy locations are obsolete or duplicated. Filename contains the original typo. | High |
| `Get full Admin.bat` | Adds three Explorer context-menu actions for files, executables, and directories. They run `takeown` and grant the local Administrators group Full Control; directory changes are recursive. | Replaces ownership and ACLs. Can damage inherited permissions or servicing expectations. No uninstall counterpart. | High |
| `RAM SplitThreshold.bat` | Prompts for 4, 8, 16, or 32 GB and writes `SvcHostSplitThresholdInKB` under `ControlSet001`. | Alters when services split into separate `svchost.exe` processes. The 4 and 8 GB values correspond approximately to 64 and 128 GB, so those branches are numerically wrong. | High |
| `Take Ownership.reg` | Adds "Take Ownership" context-menu commands for files and directories. Runs elevated `takeown`, then recursively grants Full Control to SID `S-1-3-4` for directories. | `S-1-3-4` is Owner Rights, not the Administrators group. Recursive ACL changes can be difficult to restore. | High |
| `Windows 10 1909.ps1` | Sets 22 named services to Automatic, nine to Manual, then disables every other service returned by `Get-Service`. | Machine-wide service startup rewrite with no snapshot, compatibility checks, `ShouldProcess`, or rollback. Third-party services are affected. | Critical |
| `Windows 10 2004.ps1` | Sets nine services to Automatic and three to Manual; then sets all other services to Automatic; then immediately disables all those same other services. | The first bulk loop is contradicted by the second. Final behavior broadly disables services outside a very small list. | Critical |
| `Windows 10 All-in-One.bat` | Combines ownership context menus, deletion/duplication of power plans, fixed TCP globals, update-service shutdown and policies, BCD timer/security changes, hibernation shutdown, SmartScreen/Defender/Security Center disabling, service/key deletions, and a call to external `install_wim_tweak`. | Broad, partly irreversible system mutation. External command is not included. Disables several security and servicing layers simultaneously. | Critical |
| `Windows 1709 - BTM.reg` | Applies driver, UAC, sign-in, consumer-feature, maintenance, power, mitigation, scheduler, GameDVR, telemetry, search, OneDrive, lock-screen, SysMain, security, firewall, update, legacy UI, and Photo Viewer changes. It enables WSUS policy with invalid placeholder endpoints. | Despite the old README calling it safer, it disables UAC, firewall profiles, Security Center, updates, prefetch, CPU mitigations, and more. | Critical |
| `Windows 1709 - RIPPER.reg` | Writes startup values for a large Windows 10 1709-era service list, disabling most and retaining a small set. | Removes networking, firewall, event logging, installation, diagnostics, device, encryption, Store, Bluetooth, and other functionality depending on the machine. | Critical |
| `Windows Restore Point.bat` | Deletes every VSS shadow copy, waits 300 seconds, then invokes the legacy WMIC SystemRestore method to create one restore point. | Destroys existing recovery snapshots before knowing whether replacement succeeds. WMIC is obsolete on current Windows installations. | Critical |
| `block_KB5063878.ps1` | Targets `KB5063878` and `KB5062660`; stops update services; recursively clears the download cache; restarts services; trusts PSGallery; installs/imports `PSWindowsUpdate`; hides matching KBs; lists hidden updates. | Deletes cached update payloads, adds a third-party module, changes repository trust persistently, and blocks time-specific updates. | High |
| `firewall_toggle_registry.bat` | Menu that writes `EnableFirewall` directly for Domain, Standard/Private, and Public profiles. | Can disable the firewall globally. Empty or special input can break its unquoted `if` expressions. Uses registry implementation details rather than supported cmdlets. | High |
| `README.md` | Describes selected scripts and claims possible performance or latency benefits. | Omits many files, rollback instructions, compatibility boundaries, and evidence. Some descriptions understate security and breakage risks. | Documentation only |

## Original `Files [OLD]` files

| File | What it actually does | Risk |
| --- | --- | --- |
| `1709 default servies.reg` | Snapshot of `Start` values for 162 Windows 10 1709-era services. Importing it overwrites local service startup configuration with another machine/version's defaults. | Critical |
| `Backup Services.vbs` | Queries `Win32_Service`, writes each service startup mode to a dated `.reg` file on the desktop, then opens it in Notepad. It records only the `Start` value, not delayed-auto state, triggers, dependencies, failure actions, or per-user service details. | Medium |
| `Crosshair Cursor.reg` | Replaces the current user's cursor scheme values and creates a scheme named `best`, using expanded paths to Windows cursor files. | Low |
| `Disable Automatic Driver Updates.reg` | Prevents device metadata retrieval and excludes drivers from quality updates. | Medium |
| `Disable Driver via Windows Update.reg` | Excludes drivers through three policy/state locations and disables online driver searching. | Medium |
| `Disable Enable Prefetcher.reg` | Sets `EnablePrefetcher` to zero in both `ControlSet001` and `CurrentControlSet`. | Medium |
| `Disable GameDVR.reg` | Changes one per-user fullscreen/GameDVR value and disables GameDVR through two machine policy locations. | Low |
| `Disable Hibernate Enabled.reg` | Sets `HibernateEnabled` to zero in `ControlSet001` and `CurrentControlSet`. It does not use `powercfg` to manage `hiberfil.sys`. | Medium |
| `Disable Intel Transactional Synchronization Extensions TSX Default.reg` | Sets kernel `DisableTsx=1`, disabling Intel TSX where the OS/CPU recognizes the policy. | Medium |
| `Disable Power Throttling.reg` | Sets machine-wide `PowerThrottlingOff=1`. | Medium |
| `Disable Spectre Meltdown.reg` | Sets `FeatureSettingsOverride=3` and mask `3`, disabling Spectre variant 2 and Meltdown mitigations where applicable. | Critical |
| `Disable Spyware.reg` | Disables or limits Cortana/web search/location, sets telemetry to Security/zero, hides OneDrive from Explorer, and removes the lock screen. The filename is materially broader than the actual mixed settings. | Medium |
| `Disable Superfetch.reg` | Disables three Superfetch event channels and sets `EnableSuperfetch=0`. | Medium |
| `Disable Windows Security Center + Defender.reg` | Applies obsolete Defender policy, security-provider overrides, and disables SecurityHealthService and `wscsvc`. | Critical |
| `Disable Windows Update.reg` | Disables automatic updates, excludes drivers and MRT, enables WSUS use, and points update URLs at `disableupdateserver.com`. | Critical |
| `Disable Windows Version Upgrade.reg` | Sets four legacy OS-upgrade values to zero. | Medium |
| `GPD Edit Enable.bat` | Finds Group Policy Client package manifests in the component store, writes names to `List.txt`, and uses DISM to install each package. Commonly intended to expose Group Policy tools on editions where they are not supplied. | High |
| `Games.reg` | Writes Multimedia System Profile game-task priority, scheduling category, GPU priority, and SFIO priority values. | Medium |
| `Network Gaming.reg` | Disables multimedia network throttling and sets system responsiveness to zero. | Medium |
| `Network.cmd` | Applies fixed global TCP settings: RSS on, autotuning off, CTCP, ECN off, Initial RTO 2000, RSC off, non-SACK resilience off, two SYN retries, Fast Open/fallback on, HyStart on, and pacing off. ECN is set twice. | High |
| `OLD Windows Photo Viewer.reg` | Re-registers the legacy Windows Photo Viewer handlers, icons, drop targets, preview verb, capabilities, and associations for common image formats. | Medium |
| `Old Network Symbol.reg` | Sets the legacy network flyout switch `ReplaceVan=2`. | Low |
| `Old Volume Symbol.reg` | Sets `EnableMtcUvc=0` to request the legacy volume flyout. | Low |
| `One Drive Remove Quick Access.reg` | Sets the OneDrive CLSID's `System.IsPinnedToNameSpaceTree` to zero, hiding it from Explorer's navigation pane. | Low |
| `Pause Windows Updates.reg` | Disables Windows Update UI/access and automatic updates, defers feature updates 365 days and quality updates four days, disables restart notices, dual scan, previews, recommended updates, and driver searching. | High |
| `Power Plan Context Menu.reg` | Adds a desktop context submenu for Power Saver, Balanced, High Performance, Ultimate Performance, and Power Options using fixed built-in GUIDs. | Medium |
| `Processor Scheduling.reg` | Writes `Win32PrioritySeparation=0x16` under `ControlSet001`. | Medium |
| `Registry Tweaks (General).reg` | Mixed preset covering driver search, UAC, sign-in, consumer apps, Photo Viewer, scheduler/network values, maintenance, hibernation, power throttling, CPU mitigations, visual effects, GameDVR, OneDrive, lock screen, prefetch/SysMain, and manual instructions for breaking Windows Update. | Critical |
| `Remove Quick Access.reg` | Sets Explorer `HubMode=1`, historically used to hide Quick Access/Home. | Low |
| `Remove Windows Defender.bat` | Disables SmartScreen and Defender reporting, deletes Defender/Security Center service and startup keys, creates an IFEO debugger interception for `SecHealthUI.exe`, and invokes non-included `install_wim_tweak`. | Critical |
| `ReviOS U2.1 (final) Service backup.reg` | Snapshot of startup values for 160 services from a ReviOS-tuned machine. It is not a Windows default profile. | Critical |
| `Services Disable.reg` | Overwrites startup values for 244 service and driver keys, heavily disabling them. | Critical |
| `Services Restore.reg` | Overwrites startup values for the same 244 service and driver keys with a captured profile. "Restore" means restoring that snapshot, not detecting correct defaults for the current Windows build. | Critical |
| `Set CTCP.reg` | Writes opaque binary values `0200` and `1700` under an NSI registry key to influence TCP behavior. It is not self-documenting or portable. | High |
| `Set PowerMizer to Max Performance.reg` | Sets four NVIDIA PowerMizer values under one captured display-adapter GUID. The path is machine-specific. | High |
| `Windows 7 - Allrounder.bat` | Large preset that changes DEP/BCD, power plans, TCP/IP and AFD internals, memory, Explorer, NTFS, audio, UAC, dozens of services/drivers, IPv6 transition technologies, and other OS behavior. Some commands conflict, including `nx AlwaysOff` followed later by `nx optout`. | Critical |
| `Windows 7.reg` | Large mixed registry preset for driver updates, UAC, mitigations, maintenance, power, scheduler, UI, attachments, updates, telemetry, mouse/cursors, time sync, firewall rules, network visibility, sharing, and Windows 10 upgrade blocking. It deletes all configured firewall rules before recreating an empty rules key. | Critical |
| `Windows Cursor.reg` | Replaces the current user's cursor values with system cursor paths and selects a scheme named `best`. | Low |

## Notes on service snapshots

Registry `Start` values conventionally mean: `0` boot driver, `1` system driver, `2` automatic, `3` manual, and `4` disabled. A service's correct value depends on Windows build, installed roles, hardware, security configuration, and trigger-start behavior. Importing a captured list is not a valid way to restore another machine.

## Notes on registry files

A `.reg` import writes exactly the values present but usually does not capture previous values. Deleting the imported keys later is not necessarily a correct rollback because the prior value may have been different rather than absent. A system restore point is useful but is not a substitute for a tested full backup.
