# Safety notes and source corrections

## Classification

| Topic | Status | Reason |
| --- | --- | --- |
| Chocolatey package installation | Maintained with review required | Large third-party package set; package names and licenses vary. |
| MTU configuration | Maintained | Narrow and reversible when applied to the correct interface. |
| Memory cleaner | Legacy only | Misidentifies cache as free memory and calls an undocumented/nonexistent WMI method through obsolete WMIC. |
| Restore points | Replaced | Source destroys all shadow copies first. |
| OpenShell profile | Preserved configuration | Application-specific and reversible through OpenShell settings. |
| Microphone-volume lock | Documentation only | Requires an external executable and persistent volume override. |
| NVIDIA DLL relocation | Legacy only | Breaks NVAPI consumers and tampers with a driver-installed system DLL. |
| Driver removal | Documentation only | Source supplies no exact removal steps or package identity. |
| Event-log export | Maintained | Read-only collection with bounded time range. |
| Specific KB blocking | Legacy only | Deletes update cache, modifies repository trust, installs a module, and makes time-sensitive claims. |
| Energy-mode registry change | Experimental | Insufficient reproduction/build scope; includes rollback. |
| BitLocker TPM plus PIN | Corrected documentation | High-value security configuration; protector deletion must remain deliberate and manual. |
| Feature-release target | Maintained | Corrected naming and complete policy values; reversible. |
| BIOS profile | Annotated reference | Hardware-specific and contains several security/compatibility regressions. |

## Material corrections

* The documented BitLocker protector switch is `-TPMAndPIN`, not `-TPM and PIN`.
* `TargetReleaseVersion` pins a Windows feature release. It does not disable edition upgrades between Home, Pro, Enterprise, and Education.
* Current Microsoft documentation says ProductVersion must be configured with TargetReleaseVersion.
* `Cache Bytes` is cached data, not free memory.
* The WMI performance counter class used by the memory loop does not provide the claimed standby-list-clearing method.
* Deleting all VSS shadows before creating a checkpoint is destructive and unnecessary.
* A generic MTU of 1492 is appropriate for some PPPoE paths, not all Ethernet connections.
* Moving `nvapi64.dll` affects every NVAPI-dependent application, not only one version check.
* Hiding a KB is not inherently permanent because updates can be revised or superseded.
* Disabling Execute Disable Bit disables the processor support Windows uses for hardware-enforced DEP.
* Disabling VT-x and VT-d is incompatible with several Windows virtualization and security capabilities.

## Validation boundary

The two source pages were fully read as rendered text on 7 September 2026. The repository does not include the third-party microphone utility archive or recreate the embedded driver-history screenshot. No firmware values were applied and no Windows-modifying script was executed in the build environment.
