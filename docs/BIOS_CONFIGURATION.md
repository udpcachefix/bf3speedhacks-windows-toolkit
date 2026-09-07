# BIOS Configuration Reference

This is the complete configuration published on the BIOS Configuration page, reorganized without silently converting it into a universal recommendation.

## Compatibility boundary

The menu vocabulary indicates an ASUS ROG Intel platform. Exact names, available values, defaults, and effects vary by motherboard model and BIOS version. Capture current settings or save a BIOS profile before changing anything. Change one category at a time and confirm boot, temperatures, storage, networking, USB, audio, BitLocker, virtualization, and sleep behavior.

The source contains apparent typographical errors: "Speed Shit" is interpreted as Intel Speed Shift, "Bandwith" as Bandwidth, "Tcc Offset Time Windows" may be a board-specific TCC time-window label, "AVX ICRN Offset" may refer to an AVX instruction-core-ratio negative offset, and the VT-d value lacks a closing quotation mark. The original wording is noted where interpretation is uncertain.

## Advanced > APM Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| ErP Ready | Disabled | Allows standby power features that ErP mode may restrict. Higher off-state power consumption is possible. |
| Restore AC Power Loss | Power Off | The machine remains off after utility power returns. |
| Power On By PCI-E/PCI | Disabled | Disables wake/power-on from supported PCIe devices, including Wake-on-LAN paths on some boards. |
| Power On By RTC | Disabled | Disables scheduled firmware power-on by real-time clock. |

## Advanced > CPU Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Active Processor Cores | All | Exposes all enabled physical cores. |
| Intel Virtualization Technology | Disabled | Disables VT-x. Hyper-V, WSL 2, Windows Sandbox, many virtual machines, and virtualization-based security may not work. |
| Hardware Prefetcher | Enabled | Allows the CPU to prefetch predicted memory data. Normally appropriate. |
| Adjacent Cache Line Prefetch | Enabled | Allows adjacent-line prefetching. Workload-dependent but normally left at default. |
| Boot Performance | Max Non-Turbo Performance | Requests the highest non-turbo performance state during boot. Firmware-specific. |
| SW Guard Extensions (SGX) | Disabled | Disables Intel SGX. SGX is unavailable or deprecated on many newer client platforms. |
| Tcc Offset Time Windows | Auto | Preserves automatic firmware handling of this board-specific thermal-control value. |
| Execute Disable Bit | Disabled | Disables CPU NX/XD support required for hardware-enforced DEP. Security regression. Recommended repository baseline: Enabled. |

## Advanced > CPU Configuration > CPU Power Management Control

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Intel SpeedStep | Disabled | Prevents traditional OS-controlled performance-state scaling. Can increase idle power/heat or alter boost behavior. |
| Turbo Mode | Enabled | Allows operation above base frequency within firmware power, current, and thermal limits. |
| CPU C-states | Disabled | Prevents deep idle states. May reduce some wake latency but increases idle power and temperature. Benefit must be measured. |
| CFG Lock | Disabled | Leaves the relevant model-specific register writable. Needed by some low-level configurations, but not a general performance setting. |
| Intel Speed Shift Technology | Disabled | Source says "Speed Shit." Disabling Speed Shift prevents hardware-directed performance-state selection and may worsen responsiveness or efficiency on supported CPUs. |

## Advanced > Onboard Devices Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| HD Audio Controller | Enabled | Enables onboard audio. |
| PCIEX4_3 | X4 Mode | Allocates four lanes to the named slot; may share or disable other ports depending on the board. |
| M.2_1 Configuration | Auto | Lets firmware select the mode for the first M.2 slot. |
| M.2_2 PCIe Bandwidth Configuration | X4 | Allocates four PCIe lanes to the second M.2 slot; board-specific lane sharing applies. |
| ASMedia Back USB 3.1 Controller | Disabled | Disables rear ports attached to that controller. |
| ASMedia Front USB 3.1 Controller | Disabled | Disables front-panel ports attached to that controller. |
| RGB when working | Off | Turns board lighting off while running. |
| RGB during sleep, hibernate, or soft off | Off | Turns board lighting off in low-power/off states. |
| Intel LAN Controller | Enabled | Enables onboard Intel Ethernet. |
| Intel LAN PXE Option ROM | Disabled | Disables network boot ROM. Normal local networking remains available. |

## Advanced > PCH Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| IOAPIC 24-119 Entries | Disabled | Restricts extended I/O APIC entries. This can impair modern PCIe device interrupt routing or compatibility. Leave at firmware default unless a specific legacy requirement exists. |

## Advanced > PCH Configuration > PCI Express Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| PCIe Speed | Gen3 | Forces Gen3 instead of automatic or newer generations. May improve stability on an older platform but caps capable devices. |

## Advanced > Platform Misc Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| PCI Express Native Power Management | Disabled | Disables OS-native PCIe power management. |
| PCH DMI ASPM | Disabled | Disables Active State Power Management on the chipset link. |
| ASPM | Disabled | Disables PCIe link power-saving states globally or for the selected scope. |
| DMI Link ASPM Control | Disabled | Disables DMI link power saving. |
| PEG ASPM | Disabled | Disables ASPM for PCIe graphics. These settings increase idle power and can increase temperature. |

## Advanced > ROG Effects

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Onboard LED | Enabled | Enables board status lighting. |
| Q-Code LED Function | POST Code Only | Displays diagnostic POST codes during startup rather than another runtime value. |

## Advanced > System Agent Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| VT-d | Disabled | Disables I/O virtualization and DMA remapping. Device passthrough and some Windows hardware-security protections may not work. |

## Graphics Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Primary Display | Auto | Lets firmware select the initial graphics device. |
| iGPU Multi-Monitor | Disabled | Disables keeping the integrated GPU active alongside a discrete GPU for additional displays/features. |

## DMI/OPI Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| DMI Max Link Speed | Gen3 | Forces or caps the CPU-chipset link at Gen3 on the source platform. |

## PEG Port Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| PCIEX16/X8_1 Link Speed | Gen3 | Forces the first graphics slot link to Gen3. |
| PCIEX8_2 Link Speed | Gen3 | Forces the second graphics slot link to Gen3. |
| PCIe Spread Spectrum Clocking | Disabled | Disables small clock modulation used to reduce electromagnetic interference. Can increase EMI. |

## Boot

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Fast Boot | Disabled | Performs a more complete boot initialization. Firmware boot may take longer. |
| Above 4G Decoding | Disabled | Disables allocation of PCIe MMIO above 4 GiB. This can prevent Resizable BAR, large multi-device configurations, and some modern GPU/device layouts. |
| CSM | Disabled | Uses UEFI-only boot. Appropriate for modern Windows when the OS disk uses GPT and devices have UEFI support. Verify before changing on an existing installation. |

## Boot > Boot Configuration

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Boot Logo Display | Disabled | Hides the vendor logo. |
| POST Report | 5 seconds | Displays POST information for five seconds. |
| Boot Up NumLock State | Disabled | Starts with Num Lock off. |
| Wait for F1 If Error | Enabled | Stops for acknowledgement when firmware reports an error. |
| Option ROM Messages | Enabled | Shows expansion-device firmware messages. |
| Interrupt 19 Capture | Disabled | Prevents add-in option ROMs from capturing the legacy boot interrupt. |
| Setup Mode | EZ Mode | Personal interface preference; no runtime performance effect. |

## Extreme Tweaker

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| XMP profile | Set your profile | Applies memory vendor timings/voltage beyond base JEDEC settings. This is overclocking and requires stability testing. |
| MultiCore Enhancement | Auto | Lets ASUS firmware decide whether to apply vendor multi-core turbo behavior. Exact limits depend on BIOS and CPU generation. |
| SVID Behavior | Best-Case Scenario | Uses an optimistic voltage/current behavior preset. Can reduce requested voltage but may cause instability on a CPU that needs more voltage. |
| AVX ICRN Offset | Auto | Source spelling retained; likely an AVX ratio-offset control. Automatic firmware behavior. |
| CPU Core Ratio | Auto | Leaves CPU ratios under automatic firmware control. |
| DRAM Odd Ratio Mode | Enabled | Allows odd memory ratio steps where supported. |
| Xtreme Tweaking | Disabled | Disables ASUS's specialized benchmark-oriented mode. |
| TPU | Keep Current Settings | Does not apply a new TPU automatic tuning profile. |
| CPU SVID Support | Auto | Leaves CPU voltage-identification signaling under firmware control. |

## Tools

| Setting | Source value | Effect and caution |
| --- | --- | --- |
| Setup Animator | Disabled | Disables BIOS interface animations. |
| Armoury Crate | Disabled | Prevents firmware-assisted Armoury Crate installation/integration where supported. |

## Recommended security corrections

For a current Windows 11 baseline, keep Execute Disable Bit enabled. Enable Intel Virtualization Technology and VT-d when using Hyper-V, WSL 2, Windows Sandbox, virtualization-based security, Memory Integrity, Credential Guard, device passthrough, or DMA remapping. Treat C-state, ASPM, SpeedStep, Speed Shift, Gen3 forcing, IOAPIC, and Above 4G settings as machine-specific experiments rather than latency axioms.

The source page displays a content update date of 4 September 2026 and the donation addresses reproduced in the repository README.
