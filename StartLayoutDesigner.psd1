@{
    RootModule           = 'StartLayoutDesigner.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '7d269b1a-a145-48d2-8f9d-fbb9c7c16442'
    Author               = 'sucktravian'
    CompanyName          = 'sucktravian'
    Copyright            = '(c) 2026 sucktravian'
    Description          = 'Visual designer and PowerShell module for creating Windows 11 Start Menu and Taskbar layouts. Generate deployment-ready JSON and XML files for Intune, Group Policy, and provisioning packages.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop')
    FunctionsToExport    = @(
        'Get-StartLayoutCandidateApp',
        'New-StartLayoutJson',
        'New-TaskbarLayoutXml',
        'Show-StartLayoutDesigner'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'Windows11'
                'StartMenu'
                'Taskbar'
                'Intune'
                'GroupPolicy'
                'MDM'
                'WPF'
                'GUI'
                'PowerShell'
            )

            ProjectUri   = 'https://github.com/sucktravian/start_layout_designer'
            LicenseUri   = 'https://github.com/sucktravian/start_layout_designer/blob/main/LICENSE'
            ReleaseNotes = 'Initial public release.'
        }
    }
}
