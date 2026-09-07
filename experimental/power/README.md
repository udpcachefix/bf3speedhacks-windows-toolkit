# Windows 11 energy-mode workaround

The source page proposes disabling two `EnergyMode` registry values and then running `powercfg /setactive SCHEME_MIN` when Windows 11 Enterprise displays High Performance but appears to use Balanced or Power Saver internally.

This repository does not classify the change as a verified universal fix. Record the affected Windows build and current values first. Apply `Apply-EnergyModeWorkaround.reg`, then run `Set-HighPerformance.cmd` as administrator. Reboot and verify with `powercfg /getactivescheme` and workload measurements.

`Restore-EnergyModeDefaults.reg` deletes only the two values introduced by the source workaround. If either value existed before application with another value, export the key first and restore that export instead.
