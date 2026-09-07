# Security policy

## Maintained scope

Only files under `scripts/`, together with the supporting documentation and tests, are maintained as current project material. Files under `archive/` are historical reference material. Files under `experimental/` require machine-specific testing and a documented rollback.

## Reporting

When reporting a defect, include the script name, Windows edition and build, PowerShell version, exact command, output, and whether a restore point or full backup exists.

Never include passwords, BitLocker recovery passwords, startup PINs, access tokens, account credentials, private package-source credentials, or exported logs/registry data containing personal information.

## Operating principle

A proposed performance or system tweak should document the affected setting, prerequisites, supported Windows and hardware scope, security impact, verification method, rollback procedure, and reproducible benefit.

Changes that weaken platform security by default are not accepted into the maintained toolset.
