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

## Why I Built This

I spend a lot of time deploying and customizing Windows environments, and one thing that always annoyed me was creating Start Menu and Taskbar layouts.

Microsoft provides the tools and documentation to do it properly, but the process usually involves reading multiple documents, editing JSON and XML files by hand, testing deployments, finding mistakes, fixing them, and starting over.

It works, but it isn't particularly enjoyable.

I wanted a simple visual way to build layouts, see the result immediately, and export the files needed for deployment.

So I built StartLayoutDesigner.

The goal of this project isn't to replace Microsoft's deployment methods. It simply makes the layout creation process easier.

Whether you're deploying layouts through Intune, Group Policy, provisioning packages, or another management solution, this tool helps generate the required configuration files without manually writing them yourself.

## Screenshot

![StartLayoutDesigner](screenshot/GUI.png)


## What It Does

StartLayoutDesigner helps you create and deploy Windows 11 Start Menu and Taskbar layouts.

Features:

- Discover pinnable applications automatically
- Build Start Menu layout JSON files
- Build Taskbar layout XML files
- Design layouts through a WPF graphical interface
- Export deployment-ready configuration files
- Deploy layouts

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

- Windows 11
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
