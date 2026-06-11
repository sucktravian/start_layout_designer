#Requires -Modules Pester

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModuleRoot\StartLayoutDesigner.psd1" -Force
}

# ---------------------------------------------------------------------------
# Get-StartLayoutCandidateApp
# ---------------------------------------------------------------------------
Describe 'Get-StartLayoutCandidateApp' {

    It 'Returns objects with required properties' {
        $apps = Get-StartLayoutCandidateApp
        $apps | Should -Not -BeNullOrEmpty
        $apps[0].PSObject.Properties.Name | Should -Contain 'Name'
        $apps[0].PSObject.Properties.Name | Should -Contain 'SourceType'
        $apps[0].PSObject.Properties.Name | Should -Contain 'Value'
        $apps[0].PSObject.Properties.Name | Should -Contain 'Category'
    }

    It 'Returns only packaged apps when -IncludePackagedApps is specified' {
        $apps = Get-StartLayoutCandidateApp -IncludePackagedApps
        $apps | Should -Not -BeNullOrEmpty
        $apps.SourceType | ForEach-Object {
            $_ | Should -BeIn @('PackagedAppId', 'DesktopApplicationId', 'App')
        }
    }

    It 'Returns only desktop shortcuts when -IncludeDesktopShortcuts is specified' {
        $apps = Get-StartLayoutCandidateApp -IncludeDesktopShortcuts
        $apps | Should -Not -BeNullOrEmpty
    }

    It 'Returns common Windows apps when -IncludeCommonWindowsApps is specified' {
        $apps = Get-StartLayoutCandidateApp -IncludeCommonWindowsApps
        $apps | Should -Not -BeNullOrEmpty
        $apps.Category | Should -Contain 'Common'
    }

    It 'Does not return duplicate entries by SourceType + Value' {
        $apps = Get-StartLayoutCandidateApp
        $keys = $apps | ForEach-Object { '{0}|{1}' -f $_.SourceType, $_.Value }
        ($keys | Sort-Object -Unique).Count | Should -Be $keys.Count
    }

    It 'Name property is never null or empty' {
        $apps = Get-StartLayoutCandidateApp
        $apps | ForEach-Object { $_.Name | Should -Not -BeNullOrEmpty }
    }
}

# ---------------------------------------------------------------------------
# New-StartLayoutJson
# ---------------------------------------------------------------------------
Describe 'New-StartLayoutJson' {

    BeforeAll {
        $sampleApps = @(
            [pscustomobject]@{
                Name              = 'Microsoft Edge'
                SourceType        = 'DesktopAppLink'
                Value             = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
                StartSourceType   = 'DesktopAppLink'
                StartValue        = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
                TaskbarSourceType = 'DesktopAppLink'
                TaskbarValue      = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
            },
            [pscustomobject]@{
                Name              = 'Settings'
                SourceType        = 'PackagedAppId'
                Value             = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
                StartSourceType   = 'PackagedAppId'
                StartValue        = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
                TaskbarSourceType = 'PackagedAppId'
                TaskbarValue      = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
            }
        )
    }

    It 'Returns valid JSON' {
        $json = $sampleApps | New-StartLayoutJson
        { $json | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'Output contains pinnedList array' {
        $json = $sampleApps | New-StartLayoutJson
        $parsed = $json | ConvertFrom-Json
        $parsed.PSObject.Properties.Name | Should -Contain 'pinnedList'
        $parsed.pinnedList | Should -HaveCount 2
    }

    It 'applyOnce defaults to false' {
        $json = $sampleApps | New-StartLayoutJson
        $parsed = $json | ConvertFrom-Json
        $parsed.applyOnce | Should -Be $false
    }

    It 'applyOnce can be set to true' {
        $json = $sampleApps | New-StartLayoutJson -ApplyOnce $true
        $parsed = $json | ConvertFrom-Json
        $parsed.applyOnce | Should -Be $true
    }

    It 'DesktopAppLink apps emit desktopAppLink key' {
        $json = @($sampleApps[0]) | New-StartLayoutJson
        $parsed = $json | ConvertFrom-Json
        $parsed.pinnedList[0].PSObject.Properties.Name | Should -Contain 'desktopAppLink'
    }

    It 'PackagedAppId apps emit packagedAppId key' {
        $json = @($sampleApps[1]) | New-StartLayoutJson
        $parsed = $json | ConvertFrom-Json
        $parsed.pinnedList[0].PSObject.Properties.Name | Should -Contain 'packagedAppId'
    }

    It 'Writes output to file when -Path is specified' {
        $tmpFile = Join-Path $TestDrive 'StartLayout.json'
        $sampleApps | New-StartLayoutJson -Path $tmpFile
        Test-Path $tmpFile | Should -Be $true
        $content = Get-Content $tmpFile -Raw
        { $content | ConvertFrom-Json } | Should -Not -Throw
    }

    It 'Handles an empty app list without throwing' {
        { @() | New-StartLayoutJson } | Should -Not -Throw
    }

    It 'Empty app list produces an empty pinnedList' {
        $json = @() | New-StartLayoutJson
        $parsed = $json | ConvertFrom-Json
        @($parsed.pinnedList).Count | Should -Be 0
    }
}

# ---------------------------------------------------------------------------
# New-TaskbarLayoutXml
# ---------------------------------------------------------------------------
Describe 'New-TaskbarLayoutXml' {

    BeforeAll {
        $sampleApps = @(
            [pscustomobject]@{
                Name              = 'Microsoft Edge'
                SourceType        = 'DesktopAppLink'
                Value             = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
                StartSourceType   = 'DesktopAppLink'
                StartValue        = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
                TaskbarSourceType = 'DesktopAppLink'
                TaskbarValue      = '%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk'
            },
            [pscustomobject]@{
                Name              = 'Settings'
                SourceType        = 'PackagedAppId'
                Value             = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
                StartSourceType   = 'PackagedAppId'
                StartValue        = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
                TaskbarSourceType = 'PackagedAppId'
                TaskbarValue      = 'windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel'
            }
        )
    }

    It 'Returns valid XML' {
        $xml = $sampleApps | New-TaskbarLayoutXml
        { [xml]$xml } | Should -Not -Throw
    }

    It 'Root element is LayoutModificationTemplate' {
        $xml = $sampleApps | New-TaskbarLayoutXml
        ([xml]$xml).DocumentElement.LocalName | Should -Be 'LayoutModificationTemplate'
    }

    It 'Contains CustomTaskbarLayoutCollection element' {
        $xml = $sampleApps | New-TaskbarLayoutXml
        ([xml]$xml).SelectNodes("//*[local-name()='CustomTaskbarLayoutCollection']").Count |
        Should -BeGreaterThan 0
    }

    It 'PinListPlacement is absent without -Replace' {
        $xml = $sampleApps | New-TaskbarLayoutXml
        $collection = ([xml]$xml).SelectNodes("//*[local-name()='CustomTaskbarLayoutCollection']") | Select-Object -First 1
        $collection.PinListPlacement | Should -BeNullOrEmpty
    }

    It 'PinListPlacement is Replace when -Replace is specified' {
        $xml = $sampleApps | New-TaskbarLayoutXml -Replace
        $collection = ([xml]$xml).SelectNodes("//*[local-name()='CustomTaskbarLayoutCollection']") | Select-Object -First 1
        $collection.PinListPlacement | Should -Be 'Replace'
    }

    It 'PackagedAppId apps emit UWA element with AppUserModelID' {
        $xml = @($sampleApps[1]) | New-TaskbarLayoutXml
        $uwa = ([xml]$xml).SelectNodes("//*[local-name()='UWA']") | Select-Object -First 1
        $uwa | Should -Not -BeNullOrEmpty
        $uwa.AppUserModelID | Should -Not -BeNullOrEmpty
    }

    It 'DesktopAppLink apps emit DesktopApp element with DesktopApplicationLinkPath' {
        $xml = @($sampleApps[0]) | New-TaskbarLayoutXml
        $desktop = ([xml]$xml).SelectNodes("//*[local-name()='DesktopApp']") | Select-Object -First 1
        $desktop | Should -Not -BeNullOrEmpty
        $desktop.DesktopApplicationLinkPath | Should -Not -BeNullOrEmpty
    }

    It 'Region attribute is set when -Region is specified' {
        $xml = $sampleApps | New-TaskbarLayoutXml -Region 'en-US'
        $layout = ([xml]$xml).SelectNodes("//*[local-name()='TaskbarLayout']") | Select-Object -First 1
        $layout.Region | Should -Be 'en-US'
    }

    It 'Writes output to file when -Path is specified' {
        $tmpFile = Join-Path $TestDrive 'TaskbarLayout.xml'
        $sampleApps | New-TaskbarLayoutXml -Path $tmpFile
        Test-Path $tmpFile | Should -Be $true
        { [xml](Get-Content $tmpFile -Raw) } | Should -Not -Throw
    }

    It 'Handles an empty app list without throwing' {
        { @() | New-TaskbarLayoutXml } | Should -Not -Throw
    }
}
