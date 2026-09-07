#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$MountPoint = 'C:'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ReadinessQuery {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Query
    )

    try {
        & $Query
    }
    catch {
        [pscustomobject]@{
            Status = 'Unavailable'
            Error  = $_.Exception.Message
        }
    }
}

$tpm = Invoke-ReadinessQuery {
    Get-Tpm | Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated, ManufacturerVersion
}

$bitLocker = Invoke-ReadinessQuery {
    $volume = Get-BitLockerVolume -MountPoint $MountPoint
    [pscustomobject]@{
        MountPoint           = $volume.MountPoint
        VolumeStatus         = $volume.VolumeStatus
        EncryptionPercentage = $volume.EncryptionPercentage
        ProtectionStatus     = $volume.ProtectionStatus
        EncryptionMethod     = $volume.EncryptionMethod
        ProtectorTypes       = @($volume.KeyProtector | ForEach-Object { $_.KeyProtectorType })
    }
}

$secureBoot = Invoke-ReadinessQuery {
    [pscustomobject]@{
        Enabled = [bool](Confirm-SecureBootUEFI)
    }
}

[pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    MountPoint   = $MountPoint
    TPM          = $tpm
    BitLocker    = $bitLocker
    SecureBoot   = $secureBoot
}
