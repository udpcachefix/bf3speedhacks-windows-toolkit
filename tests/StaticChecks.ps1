[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$scriptDirectory = Join-Path $repositoryRoot 'scripts'
$failures = [System.Collections.Generic.List[string]]::new()
$scriptFiles = @(Get-ChildItem -Path $scriptDirectory -Filter '*.ps1' -File)

if ($scriptFiles.Count -eq 0) {
    $failures.Add('No maintained PowerShell scripts were found.')
}

foreach ($file in $scriptFiles) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )

    foreach ($parseError in @($parseErrors)) {
        $failures.Add("$($file.Name): PowerShell parse error: $($parseError.Message)")
    }
}

$prohibitedPatterns = [ordered]@{
    'Delete all shadow copies'   = 'vssadmin\s+delete\s+shadows\s+/all'
    'Disable Defender'           = 'DisableAntiSpyware'
    'Delete Defender services'   = 'Services\\(Sense|SecurityHealthService).*delete'
    'Disable CPU mitigations'    = 'FeatureSettingsOverride'
    'Rename protected binaries'  = 'ren\s+(smartscreen|RuntimeBroker|SearchUI|StartMenuExperienceHost|ShellExperienceHost)\.exe'
    'Move NVIDIA system DLL'     = 'Move-Item.*nvapi64\.dll'
    'Execute downloaded script'  = 'Invoke-Expression|\biex\b'
}

foreach ($file in $scriptFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($entry in $prohibitedPatterns.GetEnumerator()) {
        if ($content -match $entry.Value) {
            $failures.Add("$($file.Name): prohibited behavior detected: $($entry.Key)")
        }
    }
}

$xmlPath = Join-Path $repositoryRoot 'configs\OpenShell-StartMenu.xml'
try {
    [xml](Get-Content -LiteralPath $xmlPath -Raw) | Out-Null
}
catch {
    $failures.Add("OpenShell XML is invalid: $($_.Exception.Message)")
}

$manifestPath = Join-Path $repositoryRoot 'packages\chocolatey-packages.txt'
$packages = @(
    Get-Content -LiteralPath $manifestPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
)
if ($packages.Count -ne @($packages | Sort-Object -Unique).Count) {
    $failures.Add('Chocolatey package manifest contains duplicates.')
}

$requiredFiles = @(
    'README.md',
    'LICENSE',
    'LICENSING.md',
    'SECURITY.md',
    'docs\WINDOWS_WORKAROUNDS.md',
    'docs\BIOS_CONFIGURATION.md',
    'docs\BITLOCKER_TPM_PIN.md',
    'docs\SAFETY_NOTES.md',
    'docs\SAFETY_AUDIT.md',
    'docs\SCRIPT_REFERENCE.md',
    'archive\README.md',
    'archive\wfiles-original\README.md',
    'archive\legacy-workarounds\README.md'
)

foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $relativePath))) {
        $failures.Add("Required file missing: $relativePath")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Static checks failed with $($failures.Count) issue(s)."
}

Write-Host "Static checks passed for $($scriptFiles.Count) maintained scripts and $($packages.Count) package entries."
