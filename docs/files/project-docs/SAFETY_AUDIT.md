# Safety and correctness audit

Audit date: 7 September 2026.

## Result

The original collection should not be published as a current Windows optimization pack. It mixes cosmetic changes with system-wide security reductions, unsupported version-specific service profiles, machine-specific registry paths, contradictory commands, and irreversible operations. No malware payload or embedded credential was found in the supplied files. That statement is based on source inspection, not execution or antivirus analysis.

## Critical findings

| Finding | Source | Actual consequence |
| --- | --- | --- |
| Security controls disabled together | `Windows 10 All-in-One.bat`, `Windows 1709 - BTM.reg`, several files under `Files [OLD]` | Disables or damages Defender, SmartScreen, Security Center, Firewall, Windows Update, UAC, DEP configuration, or CPU vulnerability mitigations. This increases compromise risk. |
| Core services broadly disabled | `Windows 10 1909.ps1`, `Windows 10 2004.ps1`, `Windows 1709 - RIPPER.reg`, service `.reg` files | Any service not explicitly allowlisted may be disabled, including hardware, networking, installation, security, backup, Store, and third-party services. The result depends on the exact machine. |
| Recovery data deleted | `Windows Restore Point.bat` | `vssadmin delete shadows /all /quiet` deletes all Volume Shadow Copy snapshots before attempting to make one restore point. If creation fails, recovery is worse than before. |
| Fake update servers configured | `Windows 1709 - BTM.reg`, `Files [OLD]/Disable Windows Update.reg`, general-tweak instructions | Enables WSUS policy while pointing at non-Microsoft placeholder or offensive URLs, preventing normal update discovery and leaving stale policy behind. |
| OS executables renamed | `Disable Extras.bat` | Renames SmartScreen, RuntimeBroker, SearchUI, StartMenuExperienceHost, ShellExperienceHost, and other protected binaries. This can break sign-in, shell, search, app isolation, servicing, and system-file integrity. |
| Security mitigation disabled | `BCD Edit.cmd`, `Windows 7 - Allrounder.bat`, `Disable Spectre Meltdown.reg` | Uses `nx optout` or `AlwaysOff` and registry flags that disable speculative-execution mitigations. The expected performance benefit is unproven and hardware/workload dependent. |

## Correctness defects

### `Windows 10 2004.ps1`

The script first assigns selected services to Automatic or Manual. It then sets every service outside those lists to Automatic and immediately loops over the same set again to set it to Disabled. The first bulk loop has no lasting purpose. The final result is a small allowlist plus every other discoverable service disabled.

### `RAM SplitThreshold.bat`

The 16 GB and 32 GB values are expressed in KiB as 16,777,216 and 33,554,432. The 4 GB and 8 GB branches use 68,689,924 and 137,779,208, approximately 64 GB and 128 GB rather than 4 GB and 8 GB. All branches write `ControlSet001` instead of the active `CurrentControlSet`, so behavior can also differ across boot configurations.

### `Windows Restore Point.bat`

The script checks `%errorlevel%` after `wmic ... Call CreateRestorePoint`. That value indicates whether WMIC launched successfully, not necessarily whether the WMI method returned a successful restore-point result. It also waits five minutes after destroying all existing snapshots for no demonstrated reason.

### `block_KB5063878.ps1`

The filename names one KB, but the array targets two. It permanently changes PSGallery trust to `Trusted`, installs a third-party module globally if absent, deletes the Windows Update download cache, and does not restore the prior repository trust policy. Hiding a superseded KB is not a durable update-management strategy.

### `firewall_toggle_registry.bat`

Unquoted input comparisons such as `if %choice%==1` can produce malformed commands on empty or special-character input. It writes implementation registry keys directly instead of using `Set-NetFirewallProfile`. Turning the firewall off for all profiles is offered as a routine menu action.

### `Take Ownership.reg` and `Get full Admin.bat`

Both add shell commands that recursively replace ownership and grant Full Control. The `.reg` version grants to SID `S-1-3-4`, the Owner Rights SID, rather than the Administrators group used by the batch variant. Recursive ACL changes can destroy inherited permissions and Windows servicing assumptions.

### `Set PowerMizer to Max Performance.reg`

The key contains one captured display-adapter GUID. It is machine-specific and is not portable to another GPU installation. Applying it elsewhere may do nothing or modify the wrong stale device instance.

## Unsupported performance claims

The original README describes several settings as latency or performance improvements without benchmarks, hardware scope, rollback data, or supported Microsoft guidance. Examples include forced platform timers, disabled dynamic ticks, fixed TCP tuning, disabled prefetch/SysMain, multimedia scheduler registry values, service-host splitting, and mass service changes.

Microsoft documents `useplatformclock` and `useplatformtick` as debugging options. They are not general gaming presets. This rebuild therefore does not reproduce them as maintained tools.

## Preservation policy

All original files are retained in `archive/original/` without normalization, renaming, or line-ending conversion. They are quarantined by documentation and directory placement rather than modified, so future reviewers can reproduce every finding.

## Migration decisions

| Original capability | Decision |
| --- | --- |
| State inspection | Rebuilt as one read-only PowerShell report |
| Restore-point creation | Rebuilt without deleting snapshots |
| Hibernation control | Rebuilt with explicit enable/disable state and `-WhatIf` |
| Firewall control | Rebuilt with supported cmdlets; disabling requires `-Force` |
| Driver-update exclusion | Rebuilt as one reversible policy value |
| Defender, SmartScreen, UAC, mitigation, and update shutdown | Archive only |
| Broad service profiles | Archive only |
| Timer and network presets | Archive only pending a measured, machine-specific use case |
| Cosmetic cursor, flyout, Photo Viewer, and context-menu tweaks | Archive only because they target obsolete shell behavior or embed broad ACL operations |
