#requires -version 5.1
<#
.SYNOPSIS
    Read-only audit for possible remnants of software that is no longer installed.

.DESCRIPTION
    Inspects selected data directories and compares their top-level folders with
    installed applications, installation paths, running processes, Windows services,
    and scheduled tasks. The audit creates reports only. With the explicit
    -CleanTempFiles switch it can delete unlocked files inside the current user's
    Temp directory and Windows Temp. With -DeleteConfirmedUnused it can separately
    delete only folders explicitly marked as no longer used after a second deletion
    confirmation. It never edits the registry, stops services, changes tasks, or
    modifies Windows settings.

    A reported item is a review candidate, not proof that it is safe to delete.

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -MinimumAgeDays 180 -MeasureFolderSizes

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -AdditionalRoots "D:\OldAppData"

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -MeasureFolderSizes -KnownActiveNames 'Rufus','Geek Uninstaller'

    Adds portable or otherwise unregistered software to the active-software evidence.

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -MeasureFolderSizes -InteractiveReview

    Asks whether each unresolved older folder still belongs to software in use.

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -CleanTempFiles -PreviewTempCleanup

    Previews cleanup of the current user's Temp folder and Windows Temp.

.EXAMPLE
    .\Windows-Orphan-Cleanup-Audit.ps1 -InteractiveReview -CleanTempFiles -DeleteConfirmedUnused

    Reviews candidates, confirms Temp cleanup separately, then offers deletion of
    folders explicitly marked as no longer used.
#>

[CmdletBinding()]
param(
    [ValidateRange(1, 3650)]
    [int]$MinimumAgeDays = 120,

    [string[]]$AdditionalRoots = @(),

    [string[]]$KnownActiveNames = @(),

    [switch]$MeasureFolderSizes,

    [switch]$IncludeProbablyInUse,

    [switch]$InteractiveReview,

    [switch]$CleanTempFiles,

    [switch]$PreviewTempCleanup,

    [switch]$DeleteConfirmedUnused,

    [switch]$Gui,

    [string]$OutputDirectory = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Cleanup-Audit')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($Gui) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $MeasureFolderSizes = $true
    $InteractiveReview = $true
    $DeleteConfirmedUnused = $true
    $CleanTempFiles = $true
    if ($KnownActiveNames.Count -eq 0) {
        $KnownActiveNames = @('Rufus', 'Geek Uninstaller', 'NVIDIA Profile Inspector', 'yunzii driver')
    }
    [void][System.Windows.Forms.MessageBox]::Show(
        "The scan will now inspect installed software and application-data folders.`r`n`r`nNo deletion occurs until a separate deletion plan is displayed and explicitly confirmed.",
        'Windows Cleanup Audit',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

function Show-GuiTextConfirmation {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$PlanText,
        [Parameter(Mandatory)][string]$ConfirmationText
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(900, 680)
    $form.MinimumSize = New-Object System.Drawing.Size(760, 520)

    $info = New-Object System.Windows.Forms.Label
    $info.Text = "Review every entry. Type '$ConfirmationText' below to confirm. Closing this window cancels this deletion stage."
    $info.Dock = 'Top'
    $info.Height = 48
    $info.Padding = New-Object System.Windows.Forms.Padding(12, 12, 12, 4)

    $box = New-Object System.Windows.Forms.RichTextBox
    $box.Text = $PlanText
    $box.ReadOnly = $true
    $box.Font = New-Object System.Drawing.Font('Consolas', 9)
    $box.Dock = 'Fill'
    $box.BackColor = [System.Drawing.Color]::White

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = 'Bottom'
    $panel.Height = 72

    $confirmationInput = New-Object System.Windows.Forms.TextBox
    $confirmationInput.Location = New-Object System.Drawing.Point(14, 20)
    $confirmationInput.Size = New-Object System.Drawing.Size(390, 28)

    $confirm = New-Object System.Windows.Forms.Button
    $confirm.Text = 'Confirm deletion'
    $confirm.Location = New-Object System.Drawing.Point(420, 17)
    $confirm.Size = New-Object System.Drawing.Size(150, 34)
    $confirm.Enabled = $false
    $confirm.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.Location = New-Object System.Drawing.Point(582, 17)
    $cancel.Size = New-Object System.Drawing.Size(110, 34)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $textChangedHandler = {
        param($sender, $eventArgs)
        $confirm.Enabled = ([string]$sender.Text -ceq $ConfirmationText)
    }.GetNewClosure()
    $confirmationInput.Add_TextChanged($textChangedHandler)

    $panel.Controls.AddRange(@($confirmationInput, $confirm, $cancel))
    $form.Controls.Add($box)
    $form.Controls.Add($info)
    $form.Controls.Add($panel)
    $form.AcceptButton = $confirm
    $form.CancelButton = $cancel
    $dialogResult = $form.ShowDialog()
    $confirmed = ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK)
    $form.Dispose()
    return $confirmed
}

function Show-GuiCandidateDecision {
    param([Parameter(Mandatory)][object]$Item)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Cleanup candidate review'
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(780, 390)
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $Item.Folder
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
    $title.Location = New-Object System.Drawing.Point(22, 20)
    $title.Size = New-Object System.Drawing.Size(720, 38)

    $details = New-Object System.Windows.Forms.Label
    $sizeText = if ($null -ne $Item.SizeMiB) { "$($Item.SizeMiB) MiB" } else { 'unknown' }
    $details.Text = "Path: $($Item.FullPath)`r`nAge: $($Item.AgeDays) days`r`nSize: $sizeText`r`n$(Get-SuspectedAssociation -FolderName $Item.Folder -FullPath $Item.FullPath)"
    $details.Location = New-Object System.Drawing.Point(24, 72)
    $details.Size = New-Object System.Drawing.Size(710, 110)

    $question = New-Object System.Windows.Forms.Label
    $question.Text = 'Is the related software or game still used?'
    $question.Location = New-Object System.Drawing.Point(24, 190)
    $question.Size = New-Object System.Drawing.Size(710, 30)

    $script:guiCandidateAnswer = 'X'
    $buttons = @(
        @{ Text='Still used'; Value='1'; X=24 },
        @{ Text='No longer used'; Value='2'; X=202 },
        @{ Text='Unknown'; Value='3'; X=380 },
        @{ Text='Stop review'; Value='X'; X=558 }
    )
    foreach ($definition in $buttons) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $definition.Text
        $button.Tag = $definition.Value
        $button.Location = New-Object System.Drawing.Point($definition.X, 240)
        $button.Size = New-Object System.Drawing.Size(160, 48)
        $candidateClickHandler = {
            param($sender, $eventArgs)
            $script:guiCandidateAnswer = [string]$sender.Tag
            $form.Close()
        }.GetNewClosure()
        $button.Add_Click($candidateClickHandler)
        $form.Controls.Add($button)
    }
    $form.Controls.AddRange(@($title, $details, $question))
    [void]$form.ShowDialog()
    $answer = $script:guiCandidateAnswer
    Remove-Variable guiCandidateAnswer -Scope Script -ErrorAction SilentlyContinue
    $form.Dispose()
    return $answer
}

function ConvertTo-NormalizedName {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }

    $value = $Text.ToLowerInvariant()
    $value = $value -replace '(?i)\b(x64|x86|64-bit|32-bit|version|ver|setup|installer|update|updater)\b', ' '
    $value = $value -replace '[^a-z0-9]+', ''
    return $value
}

function ConvertTo-ExecutablePath {
    param([AllowNull()][string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $null }

    $expanded = [Environment]::ExpandEnvironmentVariables($CommandLine.Trim())
    if ($expanded -match '^\s*"([^"]+\.exe)"') { return $matches[1] }
    if ($expanded -match '^\s*([^,]+?\.exe)(?:\s|$)') { return $matches[1].Trim() }
    return $null
}

function Get-SafeDirectorySize {
    param([string]$Path)
    if (-not $MeasureFolderSizes) { return $null }

    try {
        $sum = [int64]0
        Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try { $sum += [int64]$_.Length } catch {}
        }
        return $sum
    }
    catch { return $null }
}

function Format-ByteSize {
    param([AllowNull()][Nullable[int64]]$Bytes)
    if ($null -eq $Bytes) { return 'unknown size' }
    if ($Bytes -ge 1GB) { return ('{0:N2} GiB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MiB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N2} KiB' -f ($Bytes / 1KB)) }
    return ("$Bytes bytes")
}

function Get-SuspectedAssociation {
    param(
        [Parameter(Mandatory)][string]$FolderName,
        [string]$FullPath
    )
    $name = ConvertTo-NormalizedName $FolderName
    $clues = $FolderName
    if ($FullPath -and (Test-Path -LiteralPath $FullPath -PathType Container)) {
        try {
            $entries = @(Get-ChildItem -LiteralPath $FullPath -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 400)
            $clues += ' ' + (($entries | ForEach-Object { $_.Name }) -join ' ')
            $versionClues = @($entries | Where-Object { -not $_.PSIsContainer -and $_.Extension -in @('.exe', '.dll') } | Select-Object -First 25 | ForEach-Object {
                try { "$($_.VersionInfo.ProductName) $($_.VersionInfo.CompanyName) $($_.VersionInfo.FileDescription)" } catch { '' }
            })
            $clues += ' ' + ($versionClues -join ' ')
        } catch {}
    }
    $normalizedClues = ConvertTo-NormalizedName $clues

    $contentRules = @(
        @{ Pattern='vrising'; Result='Assumption: likely belongs to the game V Rising (name found in folder contents)' },
        @{ Pattern='titanquest2'; Result='Assumption: likely belongs to the game Titan Quest II (name found in folder contents)' },
        @{ Pattern='tq2'; Result='Assumption: possibly belongs to the game Titan Quest II' },
        @{ Pattern='lastepoch'; Result='Assumption: likely belongs to the game Last Epoch' },
        @{ Pattern='splitgate'; Result='Assumption: likely belongs to the game Splitgate' },
        @{ Pattern='portalwars'; Result='Assumption: likely belongs to Splitgate, formerly called Portal Wars' },
        @{ Pattern='kovaak'; Result='Assumption: likely belongs to KovaaK FPS Aim Trainer' }
    )
    foreach ($rule in $contentRules) {
        if ($normalizedClues.Contains($rule.Pattern)) { return $rule.Result }
    }

    $map = @{
        'stunlockstudios' = 'Assumption: likely belongs to the game V Rising by Stunlock Studios'
        'eleventhhourgames' = 'Assumption: likely belongs to the game Last Epoch by Eleventh Hour Games'
        'tq2' = 'Assumption: likely belongs to the game Titan Quest II'
        'thqnordic' = 'Assumption: possibly belongs to Titan Quest II or another THQ Nordic game'
        'adobe' = 'Assumption: belongs to Adobe application data'
        'nomicai' = 'Assumption: likely belongs to Nomic AI or GPT4All'
        'cef' = 'Assumption: Chromium Embedded Framework data created by another application'
        'cc' = 'Assumption: possibly a game-client component; exact owner uncertain'
        'netease' = 'Assumption: likely belongs to a NetEase game or client'
        'unisdk' = 'Assumption: game SDK data, commonly bundled with a game client'
        'unisdkfirstopen' = 'Assumption: first-run data from a game SDK'
        'unicompactview' = 'Assumption: game-client or SDK component'
        'ngconsentmanager' = 'Assumption: likely a NetEase consent component'
        'nuget' = 'Assumption: belongs to .NET or NuGet configuration and cache data'
        'modio' = 'Assumption: belongs to mod.io game integration'
        'crashreportclient' = 'Assumption: Unreal Engine crash-report data'
        'vgnvhub' = 'Assumption: belongs to the VGN Hub updater'
        'godot' = 'Assumption: belongs to Godot Engine data'
        'portalwars2' = 'Assumption: likely belongs to Splitgate, formerly Portal Wars'
        'gamesfarm' = 'Assumption: belongs to a game developed by Games Farm'
        'moonstudios' = 'Assumption: belongs to a Moon Studios game'
        'savesdirmoonstudios' = 'Assumption: local save data from a Moon Studios game'
        'moonbeastproductions' = 'Assumption: belongs to a Moon Beast Productions game'
        'fpsaimtrainer' = 'Assumption: likely belongs to KovaaK FPS Aim Trainer'
        'squirreltemp' = 'Assumption: Squirrel application installer or updater remnants'
        'soliddocuments' = 'Assumption: belongs to a Solid Documents PDF component'
        'boostinterprocess' = 'Assumption: shared Boost interprocess data; exact owner uncertain'
        'redkard' = 'Assumption: unknown software or game component'
        'cppfps' = 'Assumption: unknown FPS game or Unreal project data'
        'alfabravoinc' = 'Assumption: game data from developer Alfa Bravo Inc'
        'crgab' = 'Assumption: game data from developer CRG AB'
        'activision' = 'Assumption: likely belongs to Call of Duty or another Activision game'
        'idsoftware' = 'Assumption: belongs to a game by id Software'
        'anticheatexpert' = 'Assumption: Anti-Cheat Expert component used by a game'
    }
    if ($map.ContainsKey($name)) { return $map[$name] }
    return ("Assumption: possibly related to '$FolderName'; exact owner uncertain")
}

function Get-SafeTreeInventory {
    param([Parameter(Mandatory)][string]$Root)

    $files = [System.Collections.Generic.List[object]]::new()
    $directories = [System.Collections.Generic.List[object]]::new()
    $links = [System.Collections.Generic.List[string]]::new()
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $links.Add($_.FullName)
                return
            }
            if ($_.PSIsContainer) {
                $directories.Add($_)
                $pending.Push($_.FullName)
            }
            else { $files.Add($_) }
        }
    }
    return [pscustomobject]@{ Files = $files; Directories = $directories; ReparsePoints = $links }
}

function Get-InventorySize {
    param([Parameter(Mandatory)][object]$Inventory)
    $total = [int64]0
    foreach ($file in $Inventory.Files) {
        try { $total += [int64]$file.Length } catch {}
    }
    return $total
}

function Remove-SafeInventory {
    param(
        [Parameter(Mandatory)][object]$Inventory,
        [switch]$RemoveRoot,
        [string]$Root
    )
    $deletedBytes = [int64]0
    $deletedFiles = 0
    $skippedFiles = 0
    foreach ($file in $Inventory.Files) {
        try {
            [IO.File]::Delete($file.FullName)
            $deletedBytes += [int64]$file.Length
            $deletedFiles++
        }
        catch { $skippedFiles++ }
    }
    $Inventory.Directories | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
        try { [IO.Directory]::Delete($_.FullName, $false) } catch {}
    }
    if ($RemoveRoot -and $Root) {
        try { [IO.Directory]::Delete($Root, $false) } catch {}
    }
    return [pscustomobject]@{ DeletedFiles = $deletedFiles; SkippedFiles = $skippedFiles; DeletedBytes = $deletedBytes }
}

function Test-FileUnlocked {
    param([Parameter(Mandatory)][string]$Path)

    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
        return $true
    }
    catch [System.UnauthorizedAccessException] { return $null }
    catch [System.IO.IOException] { return $false }
    catch { return $null }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Invoke-SafeTempCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(Mandatory)][string[]]$Roots)

    $cleanupResults = [System.Collections.Generic.List[object]]::new()
    $uniqueRoots = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $resolvedRoots = [System.Collections.Generic.List[string]]::new()

    foreach ($candidateRoot in $Roots) {
        if ([string]::IsNullOrWhiteSpace($candidateRoot)) { continue }
        try { $resolvedRoot = [IO.Path]::GetFullPath($candidateRoot).TrimEnd('\') } catch { continue }
        if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) { continue }
        if ($uniqueRoots.Add($resolvedRoot)) { $resolvedRoots.Add($resolvedRoot) }
    }

    Write-Host ''
    Write-Host 'TEMP DELETION PLAN' -ForegroundColor Yellow
    $tempPlanBuilder = [Text.StringBuilder]::new()
    [void]$tempPlanBuilder.AppendLine('TEMP DELETION PLAN')
    [void]$tempPlanBuilder.AppendLine('')
    $tempTotalBytes = [int64]0
    $tempTotalFiles = 0
    $tempTotalDirectories = 0
    foreach ($resolvedRoot in $resolvedRoots) {
        $inventory = Get-SafeTreeInventory -Root $resolvedRoot
        $rootBytes = Get-InventorySize -Inventory $inventory
        $rootFiles = @($inventory.Files).Count
        $rootDirectories = @($inventory.Directories).Count
        $tempTotalBytes += $rootBytes
        $tempTotalFiles += $rootFiles
        $tempTotalDirectories += $rootDirectories
        $association = if ($resolvedRoot -like "$env:SystemRoot\Temp*") { 'Windows and service temporary data' } else { 'temporary data for the logged-in user' }
        Write-Host ("{0} files | {1} subfolders | {2} | {3} ({4})" -f $rootFiles, $rootDirectories, (Format-ByteSize $rootBytes), $resolvedRoot, $association)
        [void]$tempPlanBuilder.AppendLine(("{0} files | {1} subfolders | {2} | {3}" -f $rootFiles, $rootDirectories, (Format-ByteSize $rootBytes), $resolvedRoot))
        [void]$tempPlanBuilder.AppendLine(("    ({0})" -f $association))
        [void]$tempPlanBuilder.AppendLine('')
    }
    Write-Host ("TOTAL: {0} files | {1} subfolders | {2}" -f $tempTotalFiles, $tempTotalDirectories, (Format-ByteSize $tempTotalBytes)) -ForegroundColor Yellow
    [void]$tempPlanBuilder.AppendLine(("TOTAL: {0} files | {1} subfolders | {2}" -f $tempTotalFiles, $tempTotalDirectories, (Format-ByteSize $tempTotalBytes)))

    if (-not $WhatIfPreference) {
        if ($Gui) {
            $confirmation = if (Show-GuiTextConfirmation -Title 'Confirm temporary-file deletion' -PlanText $tempPlanBuilder.ToString() -ConfirmationText 'DELETE TEMP') { 'DELETE TEMP' } else { '' }
        }
        else {
            $confirmation = Read-Host 'Type DELETE TEMP to continue, or press Enter to cancel'
        }
        if ($confirmation -cne 'DELETE TEMP') {
            Write-Host 'Temp deletion cancelled.' -ForegroundColor Yellow
            $cleanupResults.Add([pscustomobject]@{
                ItemType = 'Stage'
                Root = ($resolvedRoots -join '; ')
                Path = ''
                SizeBytes = [int64]0
                LastWriteTime = $null
                Status = 'Cancelled'
                Detail = 'The temporary-file deletion confirmation was not completed.'
            })
            return $cleanupResults
        }
    }
    else { Write-Host 'Preview mode: no Temp files will be deleted.' -ForegroundColor Cyan }

    foreach ($resolvedRoot in $resolvedRoots) {
        Write-Host ("Cleaning Temp contents: {0}" -f $resolvedRoot) -ForegroundColor Cyan
        $inventory = Get-SafeTreeInventory -Root $resolvedRoot
        $files = $inventory.Files
        $directories = $inventory.Directories

        foreach ($file in $files) {
            $status = 'Not processed'
            $detail = ''
            $unlocked = Test-FileUnlocked -Path $file.FullName

            if ($unlocked -eq $false) {
                $status = 'Skipped in use'
                $detail = 'Exclusive access could not be obtained.'
            }
            elseif ($null -eq $unlocked) {
                $status = 'Skipped access denied'
                $detail = 'The file could not be opened with sufficient access.'
            }
            elseif ($PSCmdlet.ShouldProcess($file.FullName, 'Delete temporary file')) {
                try {
                    [IO.File]::Delete($file.FullName)
                    $status = 'Deleted'
                }
                catch [System.IO.IOException] {
                    $status = 'Skipped in use'
                    $detail = 'The file became locked before deletion.'
                }
                catch [System.UnauthorizedAccessException] {
                    $status = 'Skipped access denied'
                    $detail = 'Windows denied deletion.'
                }
                catch {
                    $status = 'Failed'
                    $detail = $_.Exception.Message
                }
            }
            else {
                $status = 'Preview only'
                $detail = 'Deletion was previewed only.'
            }

            $cleanupResults.Add([pscustomobject]@{
                ItemType = 'File'
                Root = $resolvedRoot
                Path = $file.FullName
                SizeBytes = $file.Length
                LastWriteTime = $file.LastWriteTime
                Status = $status
                Detail = $detail
            })
        }

        # Remove empty subdirectories only. Reparse points and the Temp root itself
        # are never removed. Failures are expected for active directories and silent.
        $directories |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object {
                $directoryPath = $_.FullName
                $directoryStatus = 'Skipped non-empty or in use'
                $directoryDetail = 'The directory was not empty, was active, or Windows denied removal.'
                try {
                    if ($PSCmdlet.ShouldProcess($directoryPath, 'Remove empty temporary directory')) {
                        [IO.Directory]::Delete($directoryPath, $false)
                        $directoryStatus = 'Deleted empty directory'
                        $directoryDetail = ''
                    }
                    else {
                        $directoryStatus = 'Preview only'
                        $directoryDetail = 'Removal of this empty directory was previewed only.'
                    }
                }
                catch [System.IO.IOException] {}
                catch [System.UnauthorizedAccessException] {
                    $directoryStatus = 'Skipped access denied'
                    $directoryDetail = 'Windows denied removal of this directory.'
                }
                catch {
                    $directoryStatus = 'Failed directory'
                    $directoryDetail = $_.Exception.Message
                }

                $cleanupResults.Add([pscustomobject]@{
                    ItemType = 'Directory'
                    Root = $resolvedRoot
                    Path = $directoryPath
                    SizeBytes = [int64]0
                    LastWriteTime = $null
                    Status = $directoryStatus
                    Detail = $directoryDetail
                })
            }
    }

    if ($cleanupResults.Count -eq 0) {
        $cleanupResults.Add([pscustomobject]@{
            ItemType = 'Stage'
            Root = ($resolvedRoots -join '; ')
            Path = ''
            SizeBytes = [int64]0
            LastWriteTime = $null
            Status = 'Nothing to clean'
            Detail = 'No temporary files or removable subdirectories were found.'
        })
    }

    return $cleanupResults
}

function Add-EvidenceName {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [AllowNull()][string]$Name
    )
    $normalized = ConvertTo-NormalizedName $Name
    if ($normalized.Length -ge 3) { [void]$Set.Add($normalized) }
}

function Get-OptionalPropertyValue {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$PropertyName
    )
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-NameEvidence {
    param(
        [string]$Candidate,
        [System.Collections.Generic.HashSet[string]]$Evidence
    )
    $normalized = ConvertTo-NormalizedName $Candidate
    if ($normalized -eq 'ea') {
        foreach ($item in $Evidence) {
            if ($item -in @('electronicarts', 'eadesktop', 'eaapp', 'ealauncher')) { return $true }
        }
    }
    if ($normalized.Length -lt 3) { return $false }

    foreach ($item in $Evidence) {
        if ($item -eq $normalized) { return $true }
        if ($normalized.Length -ge 5 -and $item.Length -ge 5) {
            if ($item.Contains($normalized) -or $normalized.Contains($item)) { return $true }
        }
    }
    return $false
}

function Add-RelatedSoftwareEvidence {
    param([System.Collections.Generic.HashSet[string]]$Evidence)

    # A folder often uses a product, engine, former brand, or vendor name instead
    # of the installed application's DisplayName. Add aliases only when a current
    # member of the respective software family has actually been observed.
    $families = @(
        @('electronicarts', 'eadesktop', 'eaapp', 'ealauncher', 'origin', 'eaanticheat', 'eadpsdkerrorsdataclient', 'ealaunchhelper', 'frostbite'),
        @('epicgames', 'epicgameslauncher', 'epic', 'unrealengine', 'unrealenginelauncher', 'fabplugins'),
        @('samsung', 'ssscan'),
        @('buhldataservicegmbh', 'buhl'),
        @('teamspeak', 'rootcommunications', 'dotnetbrowser'),
        @('battle.net', 'battlenet', 'blizzard', 'blizzardentertainment'),
        @('foxit', 'foxitsoftware'),
        @('gog', 'gog.com'),
        @('netease', 'unisdk', 'unicompactview', 'ngconsentmanager')
    )

    foreach ($family in $families) {
        $present = $false
        foreach ($alias in $family) {
            $normalizedAlias = ConvertTo-NormalizedName $alias
            foreach ($known in $Evidence) {
                if ($known -eq $normalizedAlias -or
                    ($normalizedAlias.Length -ge 5 -and ($known.Contains($normalizedAlias) -or $normalizedAlias.Contains($known)))) {
                    $present = $true
                    break
                }
            }
            if ($present) { break }
        }
        if ($present) {
            foreach ($alias in $family) { Add-EvidenceName $Evidence $alias }
        }
    }
}

Write-Host 'Collecting read-only software evidence...'

$evidenceNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$evidencePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$installedApps = [System.Collections.Generic.List[object]]::new()

foreach ($knownActiveName in $KnownActiveNames) {
    Add-EvidenceName $evidenceNames $knownActiveName
}

$uninstallKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

foreach ($key in $uninstallKeys) {
    Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | ForEach-Object {
        $displayName = [string](Get-OptionalPropertyValue $_ 'DisplayName')
        $publisher = [string](Get-OptionalPropertyValue $_ 'Publisher')
        $installLocation = [string](Get-OptionalPropertyValue $_ 'InstallLocation')
        if (-not [string]::IsNullOrWhiteSpace($displayName)) {
            $installedApps.Add([pscustomobject]@{
                Name = $displayName
                Publisher = $publisher
                InstallLocation = $installLocation
            })
            Add-EvidenceName $evidenceNames $displayName
            Add-EvidenceName $evidenceNames $publisher
            if (-not [string]::IsNullOrWhiteSpace($installLocation)) {
                try { [void]$evidencePaths.Add([IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($installLocation)).TrimEnd('\')) } catch {}
            }
        }
    }
}

# Microsoft Store apps are read only. Failures are ignored on systems where the
# AppX cmdlets are unavailable or access is restricted.
try {
    Get-AppxPackage -ErrorAction SilentlyContinue | ForEach-Object {
        Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'Name'))
        Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'PackageFamilyName'))
        Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'PublisherDisplayName'))
        $appxLocation = [string](Get-OptionalPropertyValue $_ 'InstallLocation')
        if (-not [string]::IsNullOrWhiteSpace($appxLocation)) {
            try { [void]$evidencePaths.Add([IO.Path]::GetFullPath($appxLocation).TrimEnd('\')) } catch {}
        }
    }
} catch {}

Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
    Add-EvidenceName $evidenceNames $_.ProcessName
    try {
        if ($_.Path) {
            [void]$evidencePaths.Add((Split-Path -Parent $_.Path).TrimEnd('\'))
            Add-EvidenceName $evidenceNames (Split-Path -LeafBase $_.Path)
        }
    } catch {}
}

Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | ForEach-Object {
    Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'Name'))
    Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'DisplayName'))
    $exe = ConvertTo-ExecutablePath ([string](Get-OptionalPropertyValue $_ 'PathName'))
    if ($exe) {
        try { [void]$evidencePaths.Add((Split-Path -Parent $exe).TrimEnd('\')) } catch {}
    }
}

try {
    Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
        Add-EvidenceName $evidenceNames ([string](Get-OptionalPropertyValue $_ 'TaskName'))
        $actions = @(Get-OptionalPropertyValue $_ 'Actions')
        foreach ($action in $actions) {
            $execute = [string](Get-OptionalPropertyValue $action 'Execute')
            $exe = ConvertTo-ExecutablePath $execute
            if (-not $exe -and $execute) { $exe = [Environment]::ExpandEnvironmentVariables($execute) }
            if ($exe) {
                try { [void]$evidencePaths.Add((Split-Path -Parent $exe).TrimEnd('\')) } catch {}
            }
        }
    }
} catch {}

Add-RelatedSoftwareEvidence $evidenceNames

$roots = [System.Collections.Generic.List[object]]::new()
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
$roamingAppData = [Environment]::GetFolderPath('ApplicationData')
$userProfile = [Environment]::GetFolderPath('UserProfile')
$programData = [Environment]::GetFolderPath('CommonApplicationData')

$roots.Add([pscustomobject]@{ Path = $localAppData; Area = 'AppData Local' })
$roots.Add([pscustomobject]@{ Path = $roamingAppData; Area = 'AppData Roaming' })
$roots.Add([pscustomobject]@{ Path = (Join-Path $userProfile 'AppData\LocalLow'); Area = 'AppData LocalLow' })
$roots.Add([pscustomobject]@{ Path = $programData; Area = 'ProgramData' })
foreach ($root in $AdditionalRoots) {
    $roots.Add([pscustomobject]@{ Path = $root; Area = 'Additional root' })
}

# Windows and shared infrastructure folders are intentionally not treated as app remnants.
$excludedNames = @(
    'Application Data', 'Apps', 'ConnectedDevicesPlatform', 'CrashDumps', 'D3DSCache',
    'Comms', 'Diagnostics', 'Downloaded Installations', 'ElevatedDiagnostics', 'History', 'INetCache',
    'Microsoft', 'MicrosoftEdge', 'Packages', 'PeerDistRepub', 'PlaceholderTileLogoFolder',
    'Programs', 'Publishers', 'Temp', 'Temporary Internet Files', 'VirtualStore',
    'Windows', 'WindowsApps', 'Start Menu', 'Templates', 'Desktop', 'Documents'
)
$excluded = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$excludedNames | ForEach-Object { [void]$excluded.Add($_) }

$cutoff = (Get-Date).AddDays(-$MinimumAgeDays)
$results = [System.Collections.Generic.List[object]]::new()
$scannedRoots = [System.Collections.Generic.List[string]]::new()

foreach ($root in $roots) {
    if ([string]::IsNullOrWhiteSpace($root.Path) -or -not (Test-Path -LiteralPath $root.Path -PathType Container)) { continue }
    $scannedRoots.Add($root.Path)
    Write-Host ("Scanning {0}..." -f $root.Path)

    Get-ChildItem -LiteralPath $root.Path -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $folder = $_
        if ($excluded.Contains($folder.Name)) { return }

        # Protected/common Windows infrastructure. These names are evaluated with
        # their area because similarly named user folders can still be legitimate
        # review targets in a custom additional root.
        if ($root.Area -eq 'ProgramData' -and $folder.Name -in @(
            'USOShared', 'USOPrivate', 'Package Cache', 'ssh', 'Microsoft OneDrive',
            'Microsoft Visual Studio', 'Microsoft Help', 'WindowsHolographicDevices'
        )) { return }

        $hasNameEvidence = Test-NameEvidence $folder.Name $evidenceNames
        $hasPathEvidence = $false
        $folderFullPath = $folder.FullName.TrimEnd('\')
        foreach ($knownPath in $evidencePaths) {
            if ($knownPath.StartsWith($folderFullPath + '\', [StringComparison]::OrdinalIgnoreCase) -or
                $folderFullPath.StartsWith($knownPath + '\', [StringComparison]::OrdinalIgnoreCase) -or
                $knownPath.Equals($folderFullPath, [StringComparison]::OrdinalIgnoreCase)) {
                $hasPathEvidence = $true
                break
            }
        }

        $ageDays = [math]::Floor(((Get-Date) - $folder.LastWriteTime).TotalDays)
        $oldEnough = $folder.LastWriteTime -lt $cutoff
        $confidence = 'Do not flag'
        $reason = 'Current software evidence or recent activity was found.'

        if (-not $hasNameEvidence -and -not $hasPathEvidence -and $oldEnough) {
            $confidence = 'Review candidate'
            $reason = "No matching installed app, active process, service, or task was found; folder is at least $MinimumAgeDays days old."
        }
        elseif (-not $hasNameEvidence -and -not $hasPathEvidence) {
            $confidence = 'Low confidence'
            $reason = 'No matching software evidence was found, but the folder is too recent for the configured age threshold.'
        }
        elseif ($oldEnough) {
            $confidence = 'Probably in use'
            $reason = 'The folder is old, but matching current software evidence was found.'
        }

        if ($confidence -ne 'Do not flag' -and ($IncludeProbablyInUse -or $confidence -ne 'Probably in use')) {
            $bytes = Get-SafeDirectorySize $folder.FullName
            $results.Add([pscustomobject]@{
                Confidence = $confidence
                Area = $root.Area
                Folder = $folder.Name
                FullPath = $folder.FullName
                LastWriteTime = $folder.LastWriteTime
                AgeDays = $ageDays
                SizeBytes = $bytes
                SizeMiB = if ($null -eq $bytes) { $null } else { [math]::Round($bytes / 1MB, 2) }
                NameEvidence = $hasNameEvidence
                PathEvidence = $hasPathEvidence
                UserDecision = 'Not asked'
                Reason = $reason
            })
        }
    }
}

if ($InteractiveReview) {
    $reviewItems = @($results | Where-Object { $_.Confidence -in @('Review candidate', 'Low confidence') } | Sort-Object AgeDays -Descending)
    if ($reviewItems.Count -gt 0) {
        Write-Host ''
        Write-Host 'Interactive review of unresolved older folders' -ForegroundColor Cyan
        Write-Host '1 = still active, 2 = no longer used, 3 = unknown, X = stop asking'
        Write-Host 'A decision changes only the report. Nothing is deleted.'

        $stopReview = $false
        foreach ($item in $reviewItems) {
            if ($stopReview) { break }
            Write-Host ''
            Write-Host ("Folder : {0}" -f $item.Folder) -ForegroundColor Yellow
            Write-Host ("Path   : {0}" -f $item.FullPath)
            Write-Host ("Age    : {0} days" -f $item.AgeDays)
            if ($null -ne $item.SizeMiB) { Write-Host ("Size   : {0} MiB" -f $item.SizeMiB) }

            if ($Gui) {
                $answer = Show-GuiCandidateDecision -Item $item
            }
            else {
                do {
                    $answer = (Read-Host 'Selection [1 = still used; 2 = no longer used; 3 = unknown; X = stop review]').Trim().ToUpperInvariant()
                } while ($answer -notin @('1', '2', '3', 'X'))
            }

            switch ($answer) {
                '1' {
                    $item.UserDecision = 'Still active'
                    $item.Confidence = 'User confirmed active'
                    $item.Reason = 'The user confirmed that the related software or game is still used. Keep this folder.'
                }
                '2' {
                    $item.UserDecision = 'No longer used'
                    $item.Confidence = 'User confirmed unused'
                    $item.Reason = 'The user confirmed that the related software or game is no longer used. This is still not proof that deletion is safe; inspect contents and backups first.'
                }
                '3' {
                    $item.UserDecision = 'Unknown'
                    $item.Reason = $item.Reason + ' The user could not identify the folder.'
                }
                'X' {
                    $item.UserDecision = 'Review stopped'
                    $stopReview = $true
                }
            }
        }
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$csvPath = Join-Path $OutputDirectory "Cleanup-Audit-$stamp.csv"
$jsonPath = Join-Path $OutputDirectory "Cleanup-Audit-$stamp.json"
$htmlPath = Join-Path $OutputDirectory "Cleanup-Audit-$stamp.html"
$tempLogPath = Join-Path $OutputDirectory "Temp-Cleanup-$stamp.csv"
$softwareLogPath = Join-Path $OutputDirectory "Software-Deletion-$stamp.csv"

$softwareDeletionResults = [System.Collections.Generic.List[object]]::new()
if ($DeleteConfirmedUnused) {
    $confirmedUnused = @($results | Where-Object Confidence -eq 'User confirmed unused')
    $deletionPlan = [System.Collections.Generic.List[object]]::new()
    $planTotalBytes = [int64]0

    foreach ($item in $confirmedUnused) {
        $inventory = Get-SafeTreeInventory -Root $item.FullPath
        $sizeBytes = Get-InventorySize -Inventory $inventory
        $blockedReason = ''
        if (@($inventory.ReparsePoints).Count -gt 0) {
            $blockedReason = 'Blocked: contains a reparse point or symbolic link.'
        }
        else {
            foreach ($file in $inventory.Files) {
                $unlocked = Test-FileUnlocked -Path $file.FullName
                if ($unlocked -eq $false) { $blockedReason = 'Blocked: at least one file is currently in use.'; break }
                if ($null -eq $unlocked) { $blockedReason = 'Blocked: at least one file cannot be checked due to access restrictions.'; break }
            }
        }
        if (-not $blockedReason) { $planTotalBytes += $sizeBytes }
        $deletionPlan.Add([pscustomobject]@{
            Folder = $item.Folder
            FullPath = $item.FullPath
            SuspectedAssociation = Get-SuspectedAssociation -FolderName $item.Folder -FullPath $item.FullPath
            SizeBytes = $sizeBytes
            Eligible = [string]::IsNullOrWhiteSpace($blockedReason)
            BlockedReason = $blockedReason
            Inventory = $inventory
        })
    }

    Write-Host ''
    Write-Host 'SOFTWARE AND GAME DATA DELETION PLAN' -ForegroundColor Red
    $softwarePlanBuilder = [Text.StringBuilder]::new()
    [void]$softwarePlanBuilder.AppendLine('SOFTWARE AND GAME DATA DELETION PLAN')
    [void]$softwarePlanBuilder.AppendLine('')
    $index = 0
    foreach ($planItem in $deletionPlan) {
        $index++
        $state = if ($planItem.Eligible) { 'eligible' } else { $planItem.BlockedReason }
        Write-Host ("[{0}] {1} | {2}" -f $index, (Format-ByteSize $planItem.SizeBytes), $planItem.FullPath) -ForegroundColor Yellow
        Write-Host ("    ({0}) | {1}" -f $planItem.SuspectedAssociation, $state)
        [void]$softwarePlanBuilder.AppendLine(("[{0}] {1} | {2}" -f $index, (Format-ByteSize $planItem.SizeBytes), $planItem.FullPath))
        [void]$softwarePlanBuilder.AppendLine(("    ({0}) | {1}" -f $planItem.SuspectedAssociation, $state))
        [void]$softwarePlanBuilder.AppendLine('')
    }
    Write-Host ("TOTAL ELIGIBLE SIZE: {0}" -f (Format-ByteSize $planTotalBytes)) -ForegroundColor Red
    Write-Host 'Only the folders listed as eligible can be deleted.'
    [void]$softwarePlanBuilder.AppendLine(("TOTAL ELIGIBLE SIZE: {0}" -f (Format-ByteSize $planTotalBytes)))
    [void]$softwarePlanBuilder.AppendLine('Only folders listed as eligible can be deleted.')

    if ($deletionPlan.Count -eq 0) {
        $softwareConfirmation = ''
        if ($Gui) {
            [void][System.Windows.Forms.MessageBox]::Show(
                'No folder was marked as no longer used. The software-deletion stage will be skipped.',
                'No software folders selected',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else { Write-Host 'No folder was marked as no longer used. Software deletion skipped.' -ForegroundColor Cyan }
    }
    elseif ($Gui) {
        $softwareConfirmation = if (Show-GuiTextConfirmation -Title 'Confirm software and game data deletion' -PlanText $softwarePlanBuilder.ToString() -ConfirmationText 'DELETE SOFTWARE') { 'DELETE SOFTWARE' } else { '' }
    }
    else {
        $softwareConfirmation = Read-Host 'Type DELETE SOFTWARE to continue, or press Enter to cancel'
    }
    foreach ($planItem in $deletionPlan) {
        $status = 'Cancelled'
        $detail = 'Deletion was not confirmed.'
        $deletedFiles = 0
        $skippedFiles = 0
        $deletedBytes = [int64]0

        if (-not $planItem.Eligible) {
            $status = 'Blocked'
            $detail = $planItem.BlockedReason
        }
        elseif ($softwareConfirmation -ceq 'DELETE SOFTWARE') {
            $deleteResult = Remove-SafeInventory -Inventory $planItem.Inventory -RemoveRoot -Root $planItem.FullPath
            $deletedFiles = $deleteResult.DeletedFiles
            $skippedFiles = $deleteResult.SkippedFiles
            $deletedBytes = $deleteResult.DeletedBytes
            if (-not (Test-Path -LiteralPath $planItem.FullPath)) {
                $status = 'Deleted'
                $detail = 'Folder and its contents were removed.'
            }
            else {
                $status = 'Partial or skipped'
                $detail = 'The folder still exists because one or more items could not be removed.'
            }
        }

        $softwareDeletionResults.Add([pscustomobject]@{
            Folder = $planItem.Folder
            FullPath = $planItem.FullPath
            SuspectedAssociation = $planItem.SuspectedAssociation
            PlannedSizeBytes = $planItem.SizeBytes
            Status = $status
            DeletedFiles = $deletedFiles
            SkippedFiles = $skippedFiles
            DeletedBytes = $deletedBytes
            Detail = $detail
        })
    }
    $softwareDeletionResults | Export-Csv -LiteralPath $softwareLogPath -NoTypeInformation -Encoding UTF8
}

$tempCleanupResults = @()
if ($CleanTempFiles) {
    $tempRoots = @(
        [IO.Path]::GetTempPath(),
        (Join-Path $env:SystemRoot 'Temp')
    )
    $tempCleanupResults = @(Invoke-SafeTempCleanup -Roots $tempRoots -WhatIf:$PreviewTempCleanup)
    $tempCleanupResults | Export-Csv -LiteralPath $tempLogPath -NoTypeInformation -Encoding UTF8
}

$tempDeletedFiles = 0
$tempDeletedBytes = [int64]0
$tempSkippedInUse = 0
$tempSkippedAccessDenied = 0
$tempFailed = 0
$tempDeletedDirectories = 0
$tempSkippedDirectories = 0
$tempCleanupStage = 'Completed'
foreach ($tempResult in $tempCleanupResults) {
    switch ($tempResult.Status) {
        'Deleted' {
            if ($tempResult.ItemType -eq 'File' -or -not $tempResult.PSObject.Properties['ItemType']) {
                $tempDeletedFiles++
                try { $tempDeletedBytes += [int64]$tempResult.SizeBytes } catch {}
            }
        }
        'Skipped in use' { $tempSkippedInUse++ }
        'Skipped access denied' { $tempSkippedAccessDenied++ }
        'Failed' { $tempFailed++ }
        'Deleted empty directory' { $tempDeletedDirectories++ }
        'Skipped non-empty or in use' { $tempSkippedDirectories++ }
        'Failed directory' { $tempFailed++ }
        'Cancelled' { $tempCleanupStage = 'Cancelled by user' }
        'Nothing to clean' { $tempCleanupStage = 'Nothing to clean' }
    }
}

$softwareDeletedFolders = @($softwareDeletionResults | Where-Object Status -eq 'Deleted').Count
$softwareBlockedFolders = @($softwareDeletionResults | Where-Object Status -eq 'Blocked').Count
$softwarePartialFolders = @($softwareDeletionResults | Where-Object Status -eq 'Partial or skipped').Count

$ordered = $results | Sort-Object @{ Expression = {
    if ($_.Confidence -eq 'User confirmed unused') { 0 }
    elseif ($_.Confidence -eq 'Review candidate') { 1 }
    elseif ($_.Confidence -eq 'Low confidence') { 2 }
    elseif ($_.Confidence -eq 'User confirmed active') { 3 }
    else { 4 }
} }, AgeDays -Descending
$ordered | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
$ordered | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$summary = [pscustomobject]@{
    'Run time' = Get-Date
    'Computer' = $env:COMPUTERNAME
    'User' = $env:USERNAME
    'Minimum age in days' = $MinimumAgeDays
    'Roots scanned' = ($scannedRoots -join '; ')
    'Installed apps observed' = $installedApps.Count
    'Review candidates' = @($ordered | Where-Object Confidence -eq 'Review candidate').Count
    'User-confirmed unused' = @($ordered | Where-Object Confidence -eq 'User confirmed unused').Count
    'User-confirmed active' = @($ordered | Where-Object Confidence -eq 'User confirmed active').Count
    'Low-confidence items' = @($ordered | Where-Object Confidence -eq 'Low confidence').Count
    'Folder sizes measured' = [bool]$MeasureFolderSizes
    'Interactive review used' = [bool]$InteractiveReview
    'Temp cleanup requested' = [bool]$CleanTempFiles
    'Temp cleanup preview only' = [bool]$PreviewTempCleanup
    'Temp files deleted' = $tempDeletedFiles
    'Temp bytes deleted' = $tempDeletedBytes
    'Temp files skipped in use' = $tempSkippedInUse
    'Temp files skipped access denied' = $tempSkippedAccessDenied
    'Temp cleanup failures' = $tempFailed
    'Empty Temp folders removed' = $tempDeletedDirectories
    'Temp folders retained' = $tempSkippedDirectories
    'Temp cleanup outcome' = $tempCleanupStage
    'Software deletion requested' = [bool]$DeleteConfirmedUnused
    'Software folders deleted' = $softwareDeletedFolders
    'Software folders blocked' = $softwareBlockedFolders
    'Software folders partial or skipped' = $softwarePartialFolders
}

$style = @'
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:28px;color:#202124}h1{margin-bottom:4px}
.warning{padding:12px;background:#fff4ce;border-left:5px solid #d6a100;margin:18px 0}
table{border-collapse:collapse;width:100%;font-size:13px}th,td{border:1px solid #ddd;padding:7px;text-align:left;vertical-align:top}
th{background:#f2f2f2;position:sticky;top:0}tr:nth-child(even){background:#fafafa}
</style>
'@

$summaryHtml = $summary | ConvertTo-Html -Fragment
$resultHtml = $ordered | ConvertTo-Html -Fragment
$deletionNotice = if ($CleanTempFiles -or $DeleteConfirmedUnused) {
    '<div class="warning"><strong>Deletion features were requested.</strong> Review the Temp and software deletion logs for exact outcomes. Unconfirmed, locked, protected, or linked items were skipped.</div>'
} else {
    '<div class="warning"><strong>Nothing was deleted.</strong> A candidate is not proof that deletion is safe. Check the folder contents, search the exact folder and vendor name, and back up or rename the folder before any later manual removal.</div>'
}
$body = @"
<h1>Windows Cleanup Audit</h1>
<p>Read-only report created on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss').</p>
$deletionNotice
<h2>Summary</h2>
$summaryHtml
<h2>Findings</h2>
$resultHtml
"@

ConvertTo-Html -Title 'Windows Cleanup Audit' -Head $style -Body $body |
    Set-Content -LiteralPath $htmlPath -Encoding UTF8

Write-Host ''
if ($CleanTempFiles -or $DeleteConfirmedUnused) {
    Write-Host 'Audit complete. Requested deletion results are recorded in the cleanup logs.' -ForegroundColor Green
}
else {
    Write-Host 'Audit complete. No files or settings were changed.' -ForegroundColor Green
}
Write-Host ("HTML: {0}" -f $htmlPath)
Write-Host ("CSV:  {0}" -f $csvPath)
Write-Host ("JSON: {0}" -f $jsonPath)
if ($CleanTempFiles) { Write-Host ("Temp cleanup log: {0}" -f $tempLogPath) }
if ($DeleteConfirmedUnused) { Write-Host ("Software deletion log: {0}" -f $softwareLogPath) }

[pscustomobject]@{
    HtmlReport = $htmlPath
    CsvReport = $csvPath
    JsonReport = $jsonPath
    TempCleanupLog = if ($CleanTempFiles) { $tempLogPath } else { $null }
    SoftwareDeletionLog = if ($DeleteConfirmedUnused) { $softwareLogPath } else { $null }
    CandidateCount = @($ordered | Where-Object Confidence -eq 'Review candidate').Count
}

if ($Gui) {
    $completionText = @"
Cleanup finished.

Software folders deleted: $softwareDeletedFolders
Software folders blocked: $softwareBlockedFolders
Software folders partial/skipped: $softwarePartialFolders

Temp files deleted: $tempDeletedFiles
Temp data deleted: $(Format-ByteSize $tempDeletedBytes)
Temp files skipped because in use: $tempSkippedInUse
Temp files skipped because access was denied: $tempSkippedAccessDenied
Empty Temp folders removed: $tempDeletedDirectories
Temp folders retained (non-empty/in use): $tempSkippedDirectories
Temp cleanup failures: $tempFailed
Temp cleanup outcome: $tempCleanupStage

Reports:
$OutputDirectory
"@
    [void][System.Windows.Forms.MessageBox]::Show($completionText, 'Windows Cleanup Audit', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
