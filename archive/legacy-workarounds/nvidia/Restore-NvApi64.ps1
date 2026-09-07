#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param()

$source = Join-Path ([Environment]::GetFolderPath('Desktop')) 'nvapi64.dll'
$destination = Join-Path $env:windir 'System32\nvapi64.dll'

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Saved NVIDIA NVAPI library was not found at '$source'."
}

if (Test-Path -LiteralPath $destination) {
    throw "Destination already exists: '$destination'. No file was overwritten."
}

if ($PSCmdlet.ShouldProcess($source, "Restore driver library to '$destination'")) {
    Move-Item -LiteralPath $source -Destination $destination
}
