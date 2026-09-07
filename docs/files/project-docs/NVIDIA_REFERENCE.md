# NVIDIA Inspector reference

The supplied profiles change the NVIDIA `Base Profile`, so their scope is global rather than game-specific. Raw numeric values are preserved exactly because NVIDIA driver enums can vary by Inspector/driver version.

> Export the current driver profiles before importing a preset. The supplied empty `NVIDIA_Inspector_Default.nip` is not a snapshot of the user's prior configuration.

## Imported legacy Base Profile

File: `toolbox/nvidia/profiles/Base Profile.nip`  
Profile: `Base Profile`  
SHA-256: `dc379e6d4c7e22262cc6803e7564e51bc8ad8b1a7ada22fd49204f06cb03fa11`

| Setting | ID | Raw value | Type |
| --- | ---: | --- | --- |
| (unnamed / unknown) | `390467` | `0` | `Dword` |
| (unnamed / unknown) | `983226` | `1` | `Dword` |
| Texture filtering - Negative LOD bias | `1686376` | `0` | `Dword` |
| Texture filtering - Trilinear optimization | `3066610` | `0` | `Dword` |
| Preferred refresh rate | `6600001` | `1` | `Dword` |
| Maximum pre-rendered frames | `8102046` | `0` | `Dword` |
| Texture filtering - Anisotropic filter optimization | `8703344` | `0` | `Dword` |
| Vertical Sync | `11041231` | `138504007` | `Dword` |
| Sharpening Value for NIS 2.0 | `11250465` | `50` | `Dword` |
| Enable NIS 2.0 | `11250721` | `0` | `Dword` |
| Enable NIS2 App Count | `11250737` | `0` | `Dword` |
| Shader disk cache maximum size | `11306135` | `102400` | `Dword` |
| (unnamed / unknown) | `12991097` | `1` | `Dword` |
| Texture filtering - Quality | `13510289` | `10` | `Dword` |
| (unnamed / unknown) | `14366808` | `32` | `Dword` |
| Texture filtering - Anisotropic sample optimization | `15151633` | `1` | `Dword` |
| Enable NIS 2.0 KMD NOTIFICATION | `28027939` | `0` | `Dword` |
| Display the VRR Indicator | `268604728` | `1` | `Dword` |
| Virtual Reality pre-rendered frames | `269553971` | `0` | `Dword` |
| Anisotropic filtering setting | `270426537` | `1` | `Dword` |
| NVIDIA Predefined Ansel Usage | `271965065` | `0` | `Dword` |
| No override of Anisotropic filtering | `272354485` | `1` | `Dword` |
| NVIDIA Quality upscaling | `272909380` | `1` | `Dword` |
| Power management mode | `274197361` | `5` | `Dword` |
| Antialiasing - Gamma correction | `276652957` | `0` | `Dword` |
| Antialiasing - Mode | `276757595` | `1` | `Dword` |
| FRL Low Latency | `277041152` | `0` | `Dword` |
| Frame Rate Limiter | `277041154` | `0` | `Dword` |
| Frame Rate Limiter for NVCPL | `277041162` | `251` | `Dword` |
| VRR requested state | `278196727` | `2` | `Dword` |
| Anisotropic filtering mode | `282245910` | `1` | `Dword` |
| Antialiasing - Setting | `282555346` | `0` | `Dword` |
| Enable G-SYNC globally | `294973784` | `2` | `Dword` |
| (unnamed / unknown) | `540508738` | `128` | `Dword` |
| (unnamed / unknown) | `543266006` | `128` | `Dword` |
| Threaded optimization | `549528094` | `2` | `Dword` |
| Preferred OpenGL GPU | `550564838` | `id,2.0:1B8010DE,00002A00,GF - (304,4,161,8192) @ (0)` | `String` |
| (unnamed / unknown) | `1343646814` | `0` | `Dword` |

## Current NVIDIA Inspector Settings

File: `toolbox/nvidia/inspector/NVIDIA_Inspector_Settings.nip`  
Profile: `Base Profile`  
SHA-256: `c717864e816292ca0f79e0c0ad4146ad2600cca626a5377c1cfbf293d3d25cf1`

| Setting | ID | Raw value | Type |
| --- | ---: | --- | --- |
| Frame Rate Limiter V3 | `277041154` | `0` | `Dword` |
| GSYNC - Application Mode | `294973784` | `0` | `Dword` |
| GSYNC - Application State | `279476687` | `4` | `Dword` |
| GSYNC - Global Feature | `278196567` | `0` | `Dword` |
| GSYNC - Global Mode | `278196727` | `0` | `Dword` |
| GSYNC - Indicator Overlay | `268604728` | `0` | `Dword` |
| Maximum Pre-Rendered Frames | `8102046` | `1` | `Dword` |
| Preferred Refresh Rate | `6600001` | `1` | `Dword` |
| Ultra Low Latency - CPL State | `390467` | `2` | `Dword` |
| Ultra Low Latency - Enabled | `277041152` | `1` | `Dword` |
| Vertical Sync | `11041231` | `138504007` | `Dword` |
| Vertical Sync - Smooth AFR Behavior | `270198627` | `0` | `Dword` |
| Vertical Sync - Tear Control | `5912412` | `2525368439` | `Dword` |
| Vulkan/OpenGL Present Method | `550932728` | `0` | `Dword` |
| Antialiasing - Gamma Correction | `276652957` | `0` | `Dword` |
| Antialiasing - Mode | `276757595` | `1` | `Dword` |
| Antialiasing - Setting | `282555346` | `0` | `Dword` |
| Anisotropic Filter - Optimization | `8703344` | `1` | `Dword` |
| Anisotropic Filter - Sample Optimization | `15151633` | `1` | `Dword` |
| Anisotropic Filtering - Mode | `282245910` | `1` | `Dword` |
| Anisotropic Filtering - Setting | `270426537` | `1` | `Dword` |
| Texture Filtering - Negative LOD Bias | `1686376` | `0` | `Dword` |
| Texture Filtering - Quality | `13510289` | `20` | `Dword` |
| Texture Filtering - Trilinear Optimization | `3066610` | `0` | `Dword` |
| CUDA - Force P2 State | `1343646814` | `0` | `Dword` |
| CUDA - Sysmem Fallback Policy | `283962569` | `1` | `Dword` |
| Power Management - Mode | `274197361` | `1` | `Dword` |
| Shader Cache - Cache Size | `11306135` | `4294967295` | `Dword` |
| Threaded Optimization | `549528094` | `1` | `Dword` |
| OpenGL GDI Compatibility | `544392611` | `0` | `Dword` |
| Preferred OpenGL GPU | `550564838` | `id,2.0:268410DE,00000100,GF - (400,2,161,24564) @ (0)` | `String` |

## Empty revert profile

File: `toolbox/nvidia/inspector/NVIDIA_Inspector_Default.nip`  
Profile: `Base Profile`  
SHA-256: `adb3886750108addeea8165ecee1ba056a6a98e1f0e7344dab7c1bf7a51dbc54`

No `ProfileSetting` entries are present. Importing this file therefore does not constitute a captured backup of earlier values.

## Supplied executable

`toolbox/nvidia/inspector/inspector.exe` is a Windows PE32 .NET executable identifying itself as NVIDIA Profile Inspector. It was not executed during preparation. SHA-256: `7d5510deeaacb50c88a49bbf1d894dae44c5ce58c00d5a88392346646b14e8f3`.

The supplied archive does not establish a license for this binary. The repository-level MIT license does not relicense it. The two CMD wrappers contain a fallback download URL pointing to `FR33THYFR33THY/Ultimate-Files`; they do not verify a pinned cryptographic hash before running the downloaded file.
