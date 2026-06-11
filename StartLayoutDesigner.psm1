$script:ModuleRoot = $PSScriptRoot

. "$script:ModuleRoot\Private\AppDiscovery.ps1"
. "$script:ModuleRoot\Private\LayoutExport.ps1"
. "$script:ModuleRoot\Private\IconTools.ps1"
. "$script:ModuleRoot\Private\PolicyDeploy.ps1"
. "$script:ModuleRoot\Private\Gui.ps1"
. "$script:ModuleRoot\Public\Get-StartLayoutCandidateApp.ps1"
. "$script:ModuleRoot\Public\New-StartLayoutJson.ps1"
. "$script:ModuleRoot\Public\New-TaskbarLayoutXml.ps1"
. "$script:ModuleRoot\Public\Show-StartLayoutDesigner.ps1"

Export-ModuleMember -Function @(
    'Get-StartLayoutCandidateApp',
    'New-StartLayoutJson',
    'New-TaskbarLayoutXml',
    'Show-StartLayoutDesigner'
)
