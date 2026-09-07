# Files OLD (folder)
Basically, something to ignore. Just a old backed up collection.

# BCD Edit
1. bcdedit /deletevalue useplatformclock
Change: Deletes the value for useplatformclock from the boot configuration.
Effect: This setting typically determines whether the system should use the platform clock (the hardware timer). Removing it allows the system to use the default timer instead, which may improve performance in certain scenarios.
3. bcdedit /set disabledynamictick yes
Change: Enables the disabledynamictick setting.
Effect: This prevents the system from dynamically adjusting the timer tick rate based on workload. Disabling dynamic ticks can reduce latency and improve performance for time-sensitive applications but might lead to increased power consumption.
5. bcdedit /set useplatformtick yes
Change: Forces the use of the platform clock as the timer for the system.
Effect: This can enhance timing accuracy, especially in virtualized environments, but might negatively affect performance in certain situations compared to other timer options.
7. bcdedit /timeout 2
Change: Sets the boot manager timeout to 2 seconds.
Effect: This reduces the time that the boot menu is displayed. If you have multiple operating systems installed, the menu will appear for only 2 seconds before booting the default OS. This is useful for speeding up the boot process if you don’t need to select an OS frequently.
9. bcdedit /set nx optout
Change: Sets the Data Execution Prevention (DEP) feature to opt-out.
Effect: DEP helps prevent malicious code from executing in certain regions of memory. Setting it to opt-out can lead to decreased security, as it may allow more types of executable code to run.
11. bcdedit /set bootux disabled
Change: Disables the boot user experience (boot UX).
Effect: This change removes graphical elements and animations during boot, leading to a more straightforward and potentially faster boot process.
13. bcdedit /set bootmenupolicy standard
Change: Sets the boot menu policy to standard mode.
Effect: This enables the classic boot menu rather than the newer graphical one.
15. bcdedit /set hypervisorlaunchtype off
Change: Disables the hypervisor from launching.
Effect: If you’re not using virtualization (e.g., Hyper-V), this can help improve system performance by preventing the overhead associated with the hypervisor.
17. bcdedit /set tpmbootentropy ForceDisable
Change: Disables the TPM (Trusted Platform Module) boot entropy.
Effect: This setting relates to how secure boot keys are generated. Disabling this might reduce security features related to boot integrity.
19. bcdedit /set quietboot yes
Change: Enables quiet boot mode.
Effect: This suppresses boot messages and graphical elements during startup, providing a cleaner boot experience. It might slightly improve boot speed.
21. powercfg -h off
Change: Disables the hibernation feature.
Effect: This will turn off hibernation, which can save disk space by removing the hiberfil.sys file used to store the system state during hibernation. This can also slightly improve boot time since the system will not need to load from hibernation.

# RAM Split Threshold allocation
The script adjusts how the Windows operating system allocates memory to system services based on the available RAM. By modifying the SvcHostSplitThresholdInKB value, the script ensures that services are better distributed across multiple processes, improving performance and reliability as the system's available memory increases.

# Windows 10 "1709-BTM.reg" & "1709-RIPPER.reg"
BTM is the safer and recommended version.
RIPPER will - yes will! - break a lot of things. Make sure you know what you're doing and have a few fixed at hand before applying.
Brief summary of what BTM does:
This registry file makes various changes to the Windows settings. Here's a brief summary of what it does:<br>
- Disables driver searching.<br>
- Disables User Account Control (UAC).<br>
- Disables automatic restart after updates.<br>
- Disables Windows consumer features.<br>
- Adjusts network throttling and system responsiveness settings.<br>
- Disables maintenance tasks.<br>
- Disables hibernate boot.<br>
- Disables power throttling.<br>
- Adjusts memory management settings.<br>
- Adjusts priority control settings.<br>
- Adjusts multimedia system profile settings for gaming.<br>
- Modifies visual effects settings.<br>
- Disables GameDVR features.<br>
- Disables GameDVR through policy settings.<br>
- Disables hibernation.<br>
- Modifies menu show delay.<br>
- Prevents device metadata retrieval from the network.<br>
- Excludes Windows Update drivers in quality updates.<br>
- Disables TSX (Transactional Synchronization Extensions) for certain Intel processors.<br>
- Modifies Ndu service startup.<br>
- Disables prefetcher.<br>
- Modifies Windows Search settings.<br>
- Disables telemetry data collection.<br>
- Modifies Windows Explorer settings for photo viewer.<br>
- Modifies Windows Update settings.<br>
- Modifies Windows activation settings.<br>
- Disables firewall and notification settings.<br>
- Disables Windows Update automatic updates.<br>
- Disables Windows Update reboot with logged-on users.<br>
- Modifies Windows Update URLs.<br>
- Disables minor updates installation.<br>
- Excludes recommended updates.<br>
- Disables Microsoft Removal Tool offers.<br>
- Disables OS upgrades.<br>
- Modifies network settings.<br>
- Disables MtcUvc service.<br>
- Modifies Photo Viewer file associations.<br>
- Disables Superfetch.<br>
- Modifies Security Health Service startup.<br>
- Modifies Windows Security Center service startup.<br>
- Modifies Windows Firewall settings.<br>

# Windows 10 1909 & Windows 10 2004 (1909.ps & 2004.ps)
This script sets the startup type of the services in the $automaticServices array to Automatic, the services in the $manualServices array to Manual, and all other services to Disabled. If a service is not found, Set-Service will throw an error, which you can ignore if the service is not installed on your system. If you want to suppress these errors, you can add -ErrorAction SilentlyContinue to the Set-Service commands.

# System Restore Point
In summary, this script will do the following, when set as task directly after system boot up, at least.. that's for what I've been using it.
- Deletes all existing system restore points.
- Waits for 5 minutes.
- Creates a new restore point named "Custom Restore Point."

# All-in-one Windows 10
Here's a breakdown of its main changes:
- It adds a "Grant Admin Full Control" option to the context menu for files (HKCR\*\shell\runas), executables (HKCR\exefile\shell\runas2), and directories (HKCR\Directory\shell\runas). This allows users to take ownership of files or folders and grant full control to administrators.
- Deletes certain power plans (381b4222, a1841308) and duplicates another (e9a42b02).
- Various TCP settings are modified to optimize network performance, including enabling rss, disabling autotuninglevel, setting the congestion provider to CTCP, and enabling fastopen.
- Stops and disables several services (UsoSvc, wuauserv, bits, cryptSvc, msiserver) related to Windows Update, MSI installer, and background intelligence services, effectively disabling automatic updates and related activities.
- Registry settings are added to disable automatic updates, defer upgrades, and modify Windows Update policies, including download modes and update scheduling.
- Adjusts bootloader settings (e.g., disabling dynamic tick, platform clock) to improve system performance and disable unnecessary boot features.
- Disables SmartScreen, Windows Defender features (including SpyNet and real-time protection), and removes some security features like SecurityHealthService.
- Hibernation is turned off to save disk space and optimize system performance.
- Modifies registry keys related to Microsoft Edge phishing filter and the EnableWebContentEvaluation setting in AppHost to disable security-related checks.
- Disables Windows Defender and various associated components like the SecurityHealthService, preventing Windows Defender from running.

# Not included
Files that arent included are either not important or do not need an explanation.
