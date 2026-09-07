param(
  [switch]$ActivateBalanced,
  [string]$ExportPath
)

# Admin prüfen
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  exit
}

if ($ActivateBalanced) { powercfg /setactive SCHEME_BALANCED | Out-Null }
$scheme = "SCHEME_CURRENT"

# Subgroup GUIDs und Aliase
$SUB_CPU_ALIAS   = "SUB_PROCESSOR"
$SUB_USB_GUID    = "2a737441-1930-4402-8d77-b2bebba308a3"
$SUB_PCI_GUID    = "501a4d13-42af-4429-9fd1-a8218c268e20"
$SUB_DISK_GUID   = "0012ee47-9041-4b5d-9b77-535fba8b1442"
$SUB_SLEEP_ALIAS = "SUB_SLEEP"
$SUB_VIDEO_ALIAS = "SUB_VIDEO"

# Setting GUIDs
$USB_SELECT_GUID = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"   # USB selective suspend
$USB3_LPM_GUID   = "d4e98f31-5ffe-4ce1-be31-1b38b384c009"   # USB 3 Link Power Management
$ASPM_GUID       = "ee12f906-d277-404b-b6da-e5fa1a576df5"   # PCIe ASPM
$DISK_IDLE_GUID  = "6738e2c4-e8a5-4a42-b16a-e040e769756e"   # Turn off hard disk after
$STANDBY_GUID    = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da"   # Sleep after
$VIDEO_IDLE_ALIAS= "VIDEOIDLE"                               # Display off
$MM_BIAS_GUID    = "10778347-1370-4ee0-8bbd-33bdacaade49"   # Video playback quality bias
$MM_PLAY_GUID    = "34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4"   # When playing video

# Helfer
function Get-Dump { (powercfg /qh $scheme) -join "`n" }
function ToInt($x){ if($x -is [int]){ $x } elseif($x -like '0x*'){ [Convert]::ToInt32($x.Substring(2),16) } else { [int]$x } }
function Find-BlockByAlias([string]$dump,[string]$alias){
  ($dump -split '(?=Power Setting GUID:)') | Where-Object { $_ -match ("GUID Alias:\s*"+[regex]::Escape($alias)+ "\b") } | Select-Object -First 1
}
function Find-BlockByGuid([string]$dump,[string]$guid){
  ($dump -split '(?=Power Setting GUID:)') | Where-Object { $_ -match ("Power Setting GUID:\s*"+[regex]::Escape($guid)) } | Select-Object -First 1
}
function Get-ACDC($block){
  if(-not $block){ return $null }
  $ac=([regex]::Match($block,'Current AC Power Setting Index:\s*(0x[0-9A-Fa-f]+|\d+)')).Groups[1].Value
  $dc=([regex]::Match($block,'Current DC Power Setting Index:\s*(0x[0-9A-Fa-f]+|\d+)')).Groups[1].Value
  @{ AC=(ToInt $ac); DC=(ToInt $dc) }
}
function Get-SubgroupForBlock($block){
  if(-not $block){ return $null }
  ([regex]::Match($block,'Subgroup GUID:\s*([0-9A-Fa-f-]{36})')).Groups[1].Value
}
function ShowFriendly($block,[int]$val){
  if(-not $block){ return "" }
  $opts=[regex]::Matches($block,'Possible Setting Index:\s*(\d+)[\s\S]*?Possible Setting Friendly Name:\s*(.+)')
  foreach($o in $opts){ if([int]$o.Groups[1].Value -eq $val){ return $o.Groups[2].Value.Trim() } }
  return ""
}

function Set-IfDifferentAlias([string]$subAlias,[string]$settingAlias,[int]$val,[ref]$chg,[ref]$ok){
  $d = Get-Dump
  $b = Find-BlockByAlias $d $settingAlias
  if(-not $b){ return }
  $cur = Get-ACDC $b
  if($cur.AC -ne $val){ & powercfg /setacvalueindex $scheme $subAlias $settingAlias $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  if($cur.DC -ne $val){ & powercfg /setdcvalueindex $scheme $subAlias $settingAlias $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  $ok.Value++
}
function Set-IfDifferentGuid([string]$sub,[string]$settingGuid,[int]$val,[ref]$chg,[ref]$ok){
  $d = Get-Dump
  $b = Find-BlockByGuid $d $settingGuid
  if(-not $b){ return }
  $cur = Get-ACDC $b
  if($cur.AC -ne $val){ & powercfg /setacvalueindex $scheme $sub $settingGuid $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  if($cur.DC -ne $val){ & powercfg /setdcvalueindex $scheme $sub $settingGuid $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  $ok.Value++
}

$changed = 0; $checked = 0

# CPU Zielwerte
$cpuTargets = @(
  @{ Alias="PROCTHROTTLEMIN";  Val=5   }
  @{ Alias="PROCTHROTTLEMAX";  Val=100 }
  @{ Alias="PERFEPP";          Val=0   }
  @{ Alias="CPMINCORES";       Val=100 }
  @{ Alias="CPMAXCORES";       Val=100 }
  @{ Alias="PERFBOOSTMODE";    Val=5   }
  @{ Alias="PERFINCTHRESHOLD"; Val=10  }
  @{ Alias="PERFDECTHRESHOLD"; Val=10  }
  @{ Alias="PERFINCTIME";      Val=15  }
  @{ Alias="PERFDECTIME";      Val=15  }
  @{ Alias="IDLEPROMOTE";      Val=60  }
  @{ Alias="IDLEDEMOTE";       Val=40  }
  @{ Alias="SYSCOOLPOL";       Val=1   }
  @{ Alias="PERFBOOSTPOL";     Val=100 }
)
foreach($t in $cpuTargets){ Set-IfDifferentAlias $SUB_CPU_ALIAS $t.Alias $t.Val ([ref]$changed) ([ref]$checked) }

# USB
Set-IfDifferentGuid $SUB_USB_GUID $USB_SELECT_GUID 0 ([ref]$changed) ([ref]$checked)
Set-IfDifferentGuid $SUB_USB_GUID $USB3_LPM_GUID   0 ([ref]$changed) ([ref]$checked)

# PCIe ASPM
Set-IfDifferentGuid $SUB_PCI_GUID $ASPM_GUID 0 ([ref]$changed) ([ref]$checked)

# Festplatte aus
Set-IfDifferentGuid $SUB_DISK_GUID $DISK_IDLE_GUID 0 ([ref]$changed) ([ref]$checked)

# Standby aus
Set-IfDifferentGuid $SUB_SLEEP_ALIAS $STANDBY_GUID 0 ([ref]$changed) ([ref]$checked)

# Display 15 Minuten
Set-IfDifferentAlias $SUB_VIDEO_ALIAS $VIDEO_IDLE_ALIAS 900 ([ref]$changed) ([ref]$checked)

# Multimedia
function Set-MM([string]$settingGuid,[int]$val,[ref]$chg,[ref]$ok){
  $d = Get-Dump
  $b = Find-BlockByGuid $d $settingGuid
  if(-not $b){ return }
  $sub = Get-SubgroupForBlock $b
  $cur = Get-ACDC $b
  if($cur.AC -ne $val){ & powercfg /setacvalueindex $scheme $sub $settingGuid $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  if($cur.DC -ne $val){ & powercfg /setdcvalueindex $scheme $sub $settingGuid $val 2>$null; if($LASTEXITCODE -eq 0){ $chg.Value++ } }
  $ok.Value++
}
Set-MM $MM_BIAS_GUID 1 ([ref]$changed) ([ref]$checked)
Set-MM $MM_PLAY_GUID 0 ([ref]$changed) ([ref]$checked)

# SATA HIPM DIPM aus
$dmp = Get-Dump
$diskSubBlock = (($dmp -split '(?=Subgroup GUID:)') | Where-Object { $_ -match [regex]::Escape($SUB_DISK_GUID) }) -join "`n"
$sataGuid = $null
if ($diskSubBlock) {
  $ps = ($diskSubBlock -split '(?=Power Setting GUID:)') | Where-Object { $_ -match '(AHCI|SATA).*(HIPM|DIPM)' } | Select-Object -First 1
  if ($ps) {
    $sataGuid = ([regex]::Match($ps,'Power Setting GUID:\s*([0-9A-Fa-f-]{36})')).Groups[1].Value
    $opts  = [regex]::Matches($ps,'Possible Setting Index:\s*(\d+)[\s\S]*?Possible Setting Friendly Name:\s*(.+)')
    $pick  = $opts | Where-Object { $_.Groups[2].Value -match '(Off|Disabled|Active)' } | Select-Object -First 1
    if ($pick) {
      $idx = [int]$pick.Groups[1].Value
      $cur = Get-ACDC $ps
      if(($cur.AC -ne $idx) -or ($cur.DC -ne $idx)){
        & powercfg /setacvalueindex $scheme $SUB_DISK_GUID $sataGuid $idx 2>$null
        & powercfg /setdcvalueindex $scheme $SUB_DISK_GUID $sataGuid $idx 2>$null
        if($LASTEXITCODE -eq 0){ $changed++ }
      }
      $checked++
    }
  }
}

# Plan anwenden
powercfg /setactive $scheme | Out-Null

# Optional Export
if ($ExportPath) {
  powercfg -export $ExportPath $scheme
  Write-Host "Exported: $ExportPath"
}

# Bericht
Write-Host ("Done. Checked {0}  Changed {1}" -f $checked,$changed)

function ShowValByAlias($label,$alias){
  $b = Find-BlockByAlias (Get-Dump) $alias
  if($b){ $v=Get-ACDC $b; "{0}: AC={1} DC={2}" -f $label,$v.AC,$v.DC } else { "{0}: not found" -f $label }
}
function ShowValByGuid($label,$guid){
  $b = Find-BlockByGuid (Get-Dump) $guid
  if($b){ $v=Get-ACDC $b; "{0}: AC={1} DC={2}" -f $label,$v.AC,$v.DC } else { "{0}: not found" -f $label }
}
function ShowValByGuidFriendly($label,$guid){
  $b = Find-BlockByGuid (Get-Dump) $guid
  if($b){
    $v=Get-ACDC $b
    $acName=ShowFriendly $b $v.AC
    $dcName=ShowFriendly $b $v.DC
    "{0}: AC={1} {2}  DC={3} {4}" -f $label,$v.AC,$acName,$v.DC,$dcName
  } else { "{0}: not found" -f $label }
}

Write-Host "=== CPU ==="
ShowValByAlias "EPP"             "PERFEPP"
ShowValByAlias "Boost Mode"      "PERFBOOSTMODE"
ShowValByAlias "System Cooling"  "SYSCOOLPOL"
ShowValByAlias "Min Processor"   "PROCTHROTTLEMIN"
ShowValByAlias "Max Processor"   "PROCTHROTTLEMAX"
ShowValByAlias "Core Parking Min" "CPMINCORES"
ShowValByAlias "Core Parking Max" "CPMAXCORES"
ShowValByAlias "Perf Inc Threshold" "PERFINCTHRESHOLD"
ShowValByAlias "Perf Dec Threshold" "PERFDECTHRESHOLD"
ShowValByAlias "Perf Inc Time"   "PERFINCTIME"
ShowValByAlias "Perf Dec Time"   "PERFDECTIME"
ShowValByAlias "Idle Promote"    "IDLEPROMOTE"
ShowValByAlias "Idle Demote"     "IDLEDEMOTE"
ShowValByAlias "Boost Policy"    "PERFBOOSTPOL"

Write-Host "=== USB ==="
ShowValByGuid  "Selective suspend" $USB_SELECT_GUID
ShowValByGuid  "USB 3 Link Power"  $USB3_LPM_GUID

Write-Host "=== PCIe ==="
ShowValByGuid  "Link State" $ASPM_GUID

Write-Host "=== Festplatte ==="
ShowValByGuid  "Abschalten nach Sekunden" $DISK_IDLE_GUID

Write-Host "=== Standby und Display ==="
ShowValByGuid  "Standby Sekunden" $STANDBY_GUID
ShowValByAlias "Display Sekunden" $VIDEO_IDLE_ALIAS

Write-Host "=== Multimedia ==="
ShowValByGuidFriendly "Video playback quality bias" $MM_BIAS_GUID
ShowValByGuidFriendly "When playing video"          $MM_PLAY_GUID

Write-Host "=== SATA ==="
if($sataGuid){
  ShowValByGuidFriendly "AHCI HIPM DIPM" $sataGuid
} else {
  "AHCI HIPM DIPM: not found"
}