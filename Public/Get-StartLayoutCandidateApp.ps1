function Get-StartLayoutCandidateApp {
    [CmdletBinding()]
    param(
        [switch]$IncludePackagedApps,
        [switch]$IncludeDesktopShortcuts,
        [switch]$IncludeCommonWindowsApps
    )

    if (-not $IncludePackagedApps -and -not $IncludeDesktopShortcuts -and -not $IncludeCommonWindowsApps) {
        $IncludePackagedApps = $true
        $IncludeDesktopShortcuts = $true
        $IncludeCommonWindowsApps = $true
    }

    Get-SldCandidateApps `
        -IncludePackagedApps:$IncludePackagedApps `
        -IncludeDesktopShortcuts:$IncludeDesktopShortcuts `
        -IncludeCommonWindowsApps:$IncludeCommonWindowsApps
}
