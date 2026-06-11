function Set-SldPolicyRegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][ValidateSet('DWord', 'String', 'ExpandString')][string]$Type
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        [void](New-Item -Path $Path -Force)
    }

    if (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue) {
        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value
    }
    else {
        [void](New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type)
    }
}

function Get-SldPolicyDeploymentFolder {
    $folder = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'StartLayoutDesigner\Policy'
    if (-not (Test-Path -LiteralPath $folder)) {
        [void](New-Item -ItemType Directory -Path $folder -Force)
    }

    $folder
}

function Get-SldPolicyDeploymentFolder {
    $folder = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'StartLayoutDesigner\Policy'
    if (-not (Test-Path -LiteralPath $folder)) {
        [void](New-Item -ItemType Directory -Path $folder -Force)
    }

    $folder
}

function New-SldPolicyDeploymentPath {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string]$Extension
    )

    $folder = Get-SldPolicyDeploymentFolder
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    Join-Path $folder ('{0}-{1}.{2}' -f $FileName, $timestamp, $Extension)
}

function Set-SldStartPinsPolicy {
    param([Parameter(Mandatory)][string]$Json)

    $folder = Get-SldPolicyDeploymentFolder
    $path   = Join-Path $folder 'StartLayout.json'
    Set-Content -LiteralPath $path -Value $Json -Encoding UTF8

    $hkcu = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
    Set-SldPolicyRegistryValue -Path $hkcu -Name 'ConfigureStartPins'     -Value 1     -Type DWord
    Set-SldPolicyRegistryValue -Path $hkcu -Name 'ConfigureStartPinsJSON' -Value $path -Type ExpandString

    [pscustomobject]@{ Policy = 'Configure Start Pins'; Scope = 'Current user'; Path = $path }
}

function Set-SldTaskbarLayoutPolicy {
    param([Parameter(Mandatory)][string]$Xml)

    $folder = Get-SldPolicyDeploymentFolder
    $path   = Join-Path $folder 'TaskbarLayout.xml'
    Set-Content -LiteralPath $path -Value $Xml -Encoding UTF8

    # Write to HKCU
    $hkcu = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
    Set-SldPolicyRegistryValue -Path $hkcu -Name 'LockedStartLayout' -Value 1     -Type DWord
    Set-SldPolicyRegistryValue -Path $hkcu -Name 'StartLayoutFile'   -Value $path -Type ExpandString

    # HKLM overrides HKCU — if it exists, update it too (requires elevation)
    $hklm = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer'
    if (Test-Path $hklm) {
        try {
            Set-SldPolicyRegistryValue -Path $hklm -Name 'LockedStartLayout' -Value 1     -Type DWord
            Set-SldPolicyRegistryValue -Path $hklm -Name 'StartLayoutFile'   -Value $path -Type ExpandString
            Write-Warning "HKLM\Explorer key was updated — it was overriding HKCU"
        }
        catch {
            Write-Warning "HKLM\Explorer exists and overrides HKCU but could not be updated (run as Administrator): $_"
        }
    }

    [pscustomobject]@{ Policy = 'Start Layout'; Scope = 'Current user'; Path = $path }
}