# StartLayoutDesigner

StartLayoutDesigner is a PowerShell module with a WPF GUI for creating Windows 11 Start layout JSON and taskbar pinned app XML.

It follows the Microsoft Learn formats for:

- Start layout JSON: `applyOnce` and `pinnedList`
- Taskbar layout XML: `LayoutModificationTemplate`, `CustomTaskbarLayoutCollection`, `taskbar:UWA`, and `taskbar:DesktopApp`

## Run the GUI

From this repository:

```powershell
Import-Module .\StartLayoutDesigner\StartLayoutDesigner.psd1 -Force
Show-StartLayoutDesigner
```

The GUI has two tabs:

- **Start Layout** selects apps and exports `StartLayout.json`
- **Taskbar** selects apps and exports `TaskbarLayout.xml`

## Use from the command line

```powershell
Import-Module .\StartLayoutDesigner\StartLayoutDesigner.psd1 -Force

$apps = Get-StartLayoutCandidateApp
$selected = $apps | Where-Object Name -in 'Microsoft Edge', 'Settings', 'File Explorer'

$selected | New-StartLayoutJson -Path .\StartLayout.json
$selected | New-TaskbarLayoutXml -Replace -Path .\TaskbarLayout.xml
```

## Notes

- Desktop shortcuts are emitted as `desktopAppLink` for Start JSON and `DesktopApplicationLinkPath` for taskbar XML.
- Packaged apps are emitted as `packagedAppId` for Start JSON and `AppUserModelID` for taskbar XML.
- Common Windows apps are included even if automatic discovery misses them.
- Taskbar `PinGeneration` and region-specific layouts are planned follow-up options.
