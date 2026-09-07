# This script configures the Receive Side Scaling (RSS) settings
# for a specified network adapter.

# --- Configuration Variables ---

# Specify the name of your network adapter.
# You can find the correct name by running the command: Get-NetAdapter
$adapterName = "Ethernet" # <-- IMPORTANT: Change "Ethernet" if your adapter has a different name

# Set the number of receive queues for RSS.
$numberOfQueues = 4

# Set the maximum number of processors RSS is allowed to use.
$maxProcessors = 4

# Set the base logical processor number for RSS.
# RSS will start using processors from this number within the defined range.
$baseProcessor = 4

# Set the maximum logical processor number in the range that RSS can use.
# RSS will distribute traffic across processors from $baseProcessor up to $maxProcessorRange,
# utilizing up to $maxProcessors within this range.
$maxProcessorRange = 10

# Set the RSS profile. Common profiles include NUMAStatic, ClosestStatic, NUMA, Closest, Conservative.
$rssProfile = "NUMAStatic"

# --- RSS Configuration Commands ---

Write-Host "Configuring RSS for network adapter: $($adapterName)"

# Set the number of receive queues
Write-Host "Setting NumberOfReceiveQueues to $($numberOfQueues)..."
Set-NetAdapterRss -Name $adapterName -NumberOfReceiveQueues $numberOfQueues -ErrorAction Stop

# Set the maximum number of processors RSS can use
Write-Host "Setting MaxProcessors to $($maxProcessors)..."
Set-NetAdapterRss -Name $adapterName -MaxProcessors $maxProcessors -ErrorAction Stop

# Set the RSS profile
Write-Host "Setting RSS Profile to $($rssProfile)..."
Set-NetAdapterRss -Name $adapterName -Profile $rssProfile -ErrorAction Stop

# Set the base logical processor number for RSS
Write-Host "Setting BaseProcessorNumber to $($baseProcessor)..."
Set-NetAdapterRss -Name $adapterName -BaseProcessorNumber $baseProcessor -ErrorAction Stop

# Set the maximum logical processor number in the RSS range
Write-Host "Setting MaxProcessorNumber to $($maxProcessorRange)..."
Set-NetAdapterRss -Name $adapterName -MaxProcessorNumber $maxProcessorRange -ErrorAction Stop

Write-Host "RSS configuration commands executed."

# --- Action Required ---

Write-Host "`n--------------------------------------------------"
Write-Host "ACTION REQUIRED:"
Write-Host "You MUST restart your computer for these changes to take full effect."
Write-Host "--------------------------------------------------"

# --- Verification (Optional) ---
# After restarting, you can open PowerShell as Administrator and run:
# Get-NetAdapterRss -Name $($adapterName)
# to verify the settings.