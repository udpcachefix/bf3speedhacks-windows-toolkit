#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 8760)]
    [int]$Hours = 24,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Join-Path $env:USERPROFILE 'Downloads')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$startTime = (Get-Date).AddHours(-$Hours)
$applicationPath = Join-Path $OutputDirectory 'eventlog_application_errors_warnings.txt'
$criticalPath = Join-Path $OutputDirectory 'eventlog_system_critical.txt'

function Export-EventSelection {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Filter,

        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $events = @(Get-WinEvent -FilterHashtable $Filter -ErrorAction Stop)
    }
    catch {
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
            $events = @()
        }
        else {
            throw "Event query for '$($Filter.LogName)' failed: $($_.Exception.Message)"
        }
    }

    if ($events.Count -eq 0) {
        "No matching events found since $startTime." | Set-Content -LiteralPath $Path -Encoding UTF8
    }
    else {
        $events |
            Sort-Object TimeCreated -Descending |
            Format-List TimeCreated, LevelDisplayName, ProviderName, Id, RecordId, Message |
            Out-File -LiteralPath $Path -Encoding UTF8 -Width 4096
    }

    [pscustomobject]@{
        Path  = $Path
        Count = $events.Count
    }
}

$applicationResult = Export-EventSelection -Filter @{
    LogName   = 'Application'
    Level     = @(2, 3)
    StartTime = $startTime
} -Path $applicationPath

$criticalResult = Export-EventSelection -Filter @{
    LogName   = 'System'
    Level     = 1
    StartTime = $startTime
} -Path $criticalPath

$applicationResult
$criticalResult
