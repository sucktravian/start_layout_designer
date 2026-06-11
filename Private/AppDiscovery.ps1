function New-SldAppCandidate {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DesktopAppLink', 'PackagedAppId', 'DesktopApplicationId')][string]$SourceType,
        [Parameter(Mandatory)][string]$Value,
        [string]$IconPath,
        [string]$Category = 'Detected'
    )

    [pscustomobject]@{
        Name       = $Name
        SourceType = $SourceType
        Value      = $Value
        IconPath   = $IconPath
        Category   = $Category
        StartSourceType = $SourceType
        StartValue      = $Value
        TaskbarSourceType = $SourceType
        TaskbarValue      = $Value
        AlternatePins     = @()
    }
}

function Get-SldPreferredAppPin {
    param(
        [Parameter(Mandatory)][object[]]$App,
        [Parameter(Mandatory)][ValidateSet('Start', 'Taskbar')][string]$Mode
    )

    $priority = if ($Mode -eq 'Start') {
        @('DesktopAppLink', 'PackagedAppId', 'DesktopApplicationId')
    }
    else {
        @('DesktopApplicationId', 'DesktopAppLink', 'PackagedAppId')
    }

    foreach ($sourceType in $priority) {
        $match = $App | Where-Object { $_.SourceType -eq $sourceType -and $_.Value } | Select-Object -First 1
        if ($match) {
            return $match
        }
    }

    $App | Select-Object -First 1
}

function Merge-SldCandidateApps {
    param([Parameter(Mandatory)][object[]]$App)

    $merged = New-Object System.Collections.Generic.List[object]

    foreach ($group in ($App | Group-Object { $_.Name.Trim().ToLowerInvariant() })) {
        $items = @($group.Group)
        $display = $items | Where-Object IconPath | Select-Object -First 1
        if (-not $display) {
            $display = $items | Select-Object -First 1
        }

        $startPin = Get-SldPreferredAppPin -App $items -Mode Start
        $taskbarPin = Get-SldPreferredAppPin -App $items -Mode Taskbar
        $sourceTypes = @($items.SourceType | Sort-Object -Unique)
        $categories = @($items.Category | Sort-Object -Unique)
        $pinSummary = if ($sourceTypes.Count -gt 1) {
            'Start: {0} | Taskbar: {1}' -f $startPin.SourceType, $taskbarPin.SourceType
        }
        else {
            $display.SourceType
        }

        $merged.Add([pscustomobject]@{
            Name              = $display.Name
            SourceType        = if ($sourceTypes.Count -gt 1) { 'App' } else { $display.SourceType }
            Value             = $startPin.Value
            IconPath          = $display.IconPath
            Category          = if ($categories.Count -gt 1) { 'Detected app' } else { $display.Category }
            PinSummary        = $pinSummary
            StartSourceType   = $startPin.SourceType
            StartValue        = $startPin.Value
            TaskbarSourceType = $taskbarPin.SourceType
            TaskbarValue      = $taskbarPin.Value
            AlternatePins     = @($items | ForEach-Object {
                [pscustomobject]@{
                    SourceType = $_.SourceTypex
                    Value      = $_.Value
                    Category   = $_.Category
                }
            })
        })
    }

    $merged
}

function Get-SldCommonWindowsApps {
    $apps = @(
        @{ Name = 'Microsoft Edge'; SourceType = 'DesktopAppLink'; Value = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk' },
        @{ Name = 'Settings'; SourceType = 'PackagedAppId'; Value = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel' },
        @{ Name = 'File Explorer'; SourceType = 'DesktopAppLink'; Value = '%APPDATA%\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk' },
        @{ Name = 'Windows Terminal'; SourceType = 'PackagedAppId'; Value = 'Microsoft.WindowsTerminal_8wekyb3d8bbwe!App' },
        @{ Name = 'Paint'; SourceType = 'PackagedAppId'; Value = 'Microsoft.Paint_8wekyb3d8bbwe!App' },
        @{ Name = 'Photos'; SourceType = 'PackagedAppId'; Value = 'Microsoft.Windows.Photos_8wekyb3d8bbwe!App' },
        @{ Name = 'Quick Assist'; SourceType = 'PackagedAppId'; Value = 'MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe!App' },
        @{ Name = 'Sticky Notes'; SourceType = 'PackagedAppId'; Value = 'Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe!App' },
        @{ Name = 'Windows Security'; SourceType = 'PackagedAppId'; Value = 'Microsoft.SecHealthUI_8wekyb3d8bbwe!SecHealthUI' },
        @{ Name = 'Outlook for Windows'; SourceType = 'PackagedAppId'; Value = 'Microsoft.OutlookForWindows_8wekyb3d8bbwe!Microsoft.OutlookforWindows' },
        @{ Name = 'Command Prompt'; SourceType = 'DesktopAppLink'; Value = '%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk' },
        @{ Name = 'Windows PowerShell'; SourceType = 'DesktopAppLink'; Value = '%APPDATA%\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk' }
    )

    foreach ($app in $apps) {
        New-SldAppCandidate -Name $app.Name -SourceType $app.SourceType -Value $app.Value -Category 'Common'
    }
}

function ConvertTo-SldEnvironmentPath {
    param([Parameter(Mandatory)][string]$Path)

    $appData = [Environment]::GetFolderPath('ApplicationData')
    $programData = [Environment]::GetFolderPath('CommonApplicationData')

    if ($Path.StartsWith($appData, [StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Replace($appData, '%APPDATA%')
    }

    if ($Path.StartsWith($programData, [StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Replace($programData, '%ALLUSERSPROFILE%')
    }

    $Path
}

function Get-SldDesktopShortcutApps {
    $paths = @(
        [Environment]::GetFolderPath('Programs'),
        [Environment]::GetFolderPath('CommonPrograms')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    foreach ($path in $paths) {
        Get-ChildItem -LiteralPath $path -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            $linkPath = ConvertTo-SldEnvironmentPath -Path $_.FullName
            $iconPath = Get-SldShortcutIconPath -Path $_.FullName
            New-SldAppCandidate -Name $_.BaseName -SourceType 'DesktopAppLink' -Value $linkPath -IconPath $iconPath -Category 'Desktop shortcut'
        }
    }
}

function Get-SldPackagedApps {
    if (-not (Get-Command Get-StartApps -ErrorAction SilentlyContinue)) {
        return
    }

    Get-StartApps | Where-Object { $_.AppID -and $_.Name } | Sort-Object Name |
    ForEach-Object {

        $sourceType = if ($_.AppID -match '^.+_.+!.+$') { 'PackagedAppId' } else { 'DesktopApplicationId' }
        $category = if ($sourceType -eq 'PackagedAppId') { 'Packaged app' } else { 'Desktop app (AUMID)' }
        New-SldAppCandidate -Name $_.Name -SourceType $sourceType -Value $_.AppID -Category $category
    }
}

function Get-SldCandidateApps {
    param(
        [switch]$IncludePackagedApps,
        [switch]$IncludeDesktopShortcuts,
        [switch]$IncludeCommonWindowsApps
    )

    $seen = @{}
    $apps = New-Object System.Collections.Generic.List[object]

    foreach ($app in @(
            if ($IncludeCommonWindowsApps) { Get-SldCommonWindowsApps }
            if ($IncludeDesktopShortcuts) { Get-SldDesktopShortcutApps }
            if ($IncludePackagedApps) { Get-SldPackagedApps }
        )) {
        $key = '{0}|{1}' -f $app.SourceType, $app.Value
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            [void]$apps.Add($app)
        }
    }

    Merge-SldCandidateApps -App @($apps.ToArray()) | Sort-Object Category, Name
}
