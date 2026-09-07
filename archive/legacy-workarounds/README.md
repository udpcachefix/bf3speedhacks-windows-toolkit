# Legacy source procedures

These files preserve procedures from the source page that are destructive, obsolete, dependent on external code, or insufficiently verified. They are excluded from maintained-script guarantees.

| Path | Reason for quarantine |
| --- | --- |
| `chocolatey/Original-Install.ps1` | Downloads a remote script and immediately executes it with process-scope policy bypass. |
| `chocolatey/Original-Install.cmd` | Starts the same network bootstrap through Windows PowerShell from Command Prompt. |
| `memory/MemoryCleaner.bat` | Uses obsolete WMIC and calls an unsupported method on a performance-counter class. |
| `restore/AutomatedRestorePoints.bat` | Deletes every shadow copy before requesting a new restore point. |
| `nvidia/Move-NvApi64.ps1` | Removes a driver DLL used by OBS and other NVAPI consumers. |
| `nvidia/Restore-NvApi64.ps1` | Restores the moved DLL only when no destination collision exists. |
| `updates/Block-SpecificUpdates.ps1` | Clears update cache, changes PSGallery trust, installs an external module, and targets time-specific KBs. |
| `updates/Original-TargetCurrentRelease.ps1` | Uses incomplete target-release policy and restarts Windows Update. |
