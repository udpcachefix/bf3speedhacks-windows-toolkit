# Changelog

## 2.1.0 - 2026-09-07

* Added all 30 files from `Amin.7z`, `Cleanup.7z`, `Network reset.7z`, and `nvidia.7z` under a function-based `toolbox/` structure without modifying their bytes.
* Added per-file behavior, usage, limitations, and risk documentation.
* Added SHA-256 import manifests and preserved the four original 7z files under `source-archives/`.
* Added detailed NVIDIA Inspector profile documentation including every supplied Setting ID and raw value.
* Added a complete static GitHub Pages site under `docs/`, including searchable Toolbox, Network, NVIDIA, Cleanup, BIOS, Legacy, Safety, and Files pages.
* Added a self-contained Pages download mirror under `docs/files/` so every toolbox/archive file is accessible from the website.
* Added `docs/CNAME` for `project.bf3speedhacks.com` and `.nojekyll`.
* Expanded licensing scope notes for imported and third-party material.

## 2.0.0 - 2026-09-07

* Consolidated the Windows Workarounds / BIOS repository and WFiles into one project.
* Unified maintained PowerShell utilities under `scripts/`.
* Deduplicated the restore-point utility and generalized its default description.
* Unified documentation under `docs/`.
* Moved both historical collections under `archive/` while preserving their internal contents.
* Added a repository-level MIT License with explicit archive licensing scope.
* Combined static validation and GitHub Actions checks.

## 1.0.0 - 2026-09-07

### Windows Workarounds / BIOS

* Converted the Windows Workarounds and BIOS Configuration pages into a structured repository.
* Added corrected, parameterized PowerShell tools for MTU, restore points, event exports, package installation, Windows feature targeting, and BitLocker inspection.
* Added the complete OpenShell profile.
* Quarantined destructive memory, NVIDIA DLL, and update-blocking examples.
* Corrected the BitLocker `-TPMAndPIN` syntax and the meaning of Windows target-release policy.
* Added BIOS compatibility and security annotations.

### WFiles

* Rebuilt the repository around maintained PowerShell tools.
* Added a complete source inventory and safety audit.
* Preserved the supplied historical collection under the archive.
* Replaced destructive restore-point behavior with `Checkpoint-Computer`.
* Replaced direct firewall registry edits with `NetSecurity` cmdlets.
* Added reversible hibernation and driver-update policy tools.
