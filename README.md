# StartLayoutDesigner

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/StartLayoutDesigner.svg?label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/StartLayoutDesigner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

**StartLayoutDesigner** is a PowerShell module with a WPF GUI for designing Windows 11 Start Menu and Taskbar layouts — and exporting them as policy-ready JSON and XML files.

---

## ⚠️ Disclaimer

> ⚠️ **Warning:** This module can write registry values and deploy layout files that affect the Start Menu and Taskbar for the current user or all users. It is provided *as-is* with no warranties or guarantees. Use at your own risk.
>
> Always review generated layout files before deploying them, especially in production or managed environments. The author is **not responsible** for any unintended changes to user profiles or group policy.

---

## What It Does

Manually crafting Windows 11 Start Layout JSON and Taskbar Layout XML is error-prone and tedious. This module handles discovery, building, and deploying those files.

This module:

- Discovers installed apps eligible for pinning using `Get-StartLayoutCandidateApp` (packaged apps, desktop shortcuts, and common Windows apps)
- Generates a `LayoutModification.json` for the Windows 11 Start Menu via `New-StartLayoutJson`
- Generates a `TaskbarLayoutModification.xml` for Taskbar policy via `New-TaskbarLayoutXml`
- Provides an interactive WPF GUI designer via `Show-StartLayoutDesigner`
- Deploys layouts to the registry and policy folders automatically

---

## Installation

```powershell
Install-Module StartLayoutDesigner
```

## How to use

### Launch the GUI Designer

```powershell
Show-StartLayoutDesigner
```

The GUI has two tabs:

- **Start Layout** — select apps and export `StartLayout.json`
- **Taskbar** — select apps and export `TaskbarLayout.xml`

### From the command line

```powershell
Import-Module StartLayoutDesigner

$apps = Get-StartLayoutCandidateApp
$selected = $apps | Where-Object Name -in 'Microsoft Edge', 'Settings', 'File Explorer'

$selected | New-StartLayoutJson -Path .\StartLayout.json
$selected | New-TaskbarLayoutXml -Replace -Path .\TaskbarLayout.xml
```

### Examples

```powershell
# Discover all pinnable apps
Get-StartLayoutCandidateApp

# Discover only common built-in Windows apps
Get-StartLayoutCandidateApp -IncludeCommonWindowsApps

# Build a Start Layout JSON
$apps | New-StartLayoutJson -Path "$env:TEMP\StartLayout.json"

# Build a Start Layout JSON that applies once (not re-applied on every logon)
$apps | New-StartLayoutJson -ApplyOnce $true -Path "$env:TEMP\StartLayout.json"

# Build a Taskbar Layout XML (replace existing pins)
$apps | New-TaskbarLayoutXml -Replace -Path "$env:TEMP\TaskbarLayout.xml"

# Build a Taskbar Layout XML for a specific region
$apps | New-TaskbarLayoutXml -Region 'en-US' -Path "$env:TEMP\TaskbarLayout.xml"

# Open the interactive GUI to design and export layouts
Show-StartLayoutDesigner
```

---

## Requirements

- Windows 10 / Windows 11
- PowerShell 5.1+
- .NET Framework 4.5+ (for WPF GUI)
- Must be run as Administrator for policy deployment

---

## Testing

Run unit tests with Pester:

```powershell
Invoke-Pester -Path tests
```

---

## License

Licensed under the MIT License
