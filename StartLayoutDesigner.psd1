@{
    RootModule = 'StartLayoutDesigner.psm1'
    ModuleVersion = '0.1.0'
    GUID = '7d269b1a-a145-48d2-8f9d-fbb9c7c16442'
    Author = 'sucktravian'
    CompanyName = 'sucktravian'
    Copyright = '(c) 2026 sucktravian. All rights reserved.'
    Description = 'GUI and command helpers for creating Windows 11 Start layout JSON and taskbar pinned app XML.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
    FunctionsToExport = @(
        'Get-StartLayoutCandidateApp',
        'New-StartLayoutJson',
        'New-TaskbarLayoutXml',
        'Show-StartLayoutDesigner'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'StartMenu', 'Taskbar', 'Layout', 'GUI', 'WPF')
            ProjectUri = ''
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = 'Initial preview module.'
        }
    }
}
