function ConvertTo-SldStartPin {
    param([Parameter(Mandatory)]$App)

    $sourceType = if ($App.StartSourceType) { $App.StartSourceType } else { $App.SourceType }
    $value = if ($App.StartValue) { $App.StartValue } else { $App.Value }

    switch ($sourceType) {
        'DesktopAppLink' { [ordered]@{ desktopAppLink = $value } }
        'PackagedAppId' { [ordered]@{ packagedAppId = $value } }
        'DesktopApplicationId' { [ordered]@{ desktopAppId = $value } }
        default { throw "Unsupported Start pin type: $sourceType" }
    }
}

function New-SldImportedAppCandidate {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DesktopAppLink', 'PackagedAppId', 'DesktopApplicationId')][string]$SourceType,
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][ValidateSet('Start', 'Taskbar')][string]$Mode
    )

    $startSourceType = if ($Mode -eq 'Start') { $SourceType } else { $null }
    $startValue = if ($Mode -eq 'Start') { $Value } else { $null }
    $taskbarSourceType = if ($Mode -eq 'Taskbar') { $SourceType } else { $null }
    $taskbarValue = if ($Mode -eq 'Taskbar') { $Value } else { $null }

    [pscustomobject]@{
        Name              = $Name
        SourceType        = $SourceType
        Value             = $Value
        IconPath          = $null
        Category          = 'Imported'
        PinSummary        = "Imported $SourceType"
        StartSourceType   = $startSourceType
        StartValue        = $startValue
        TaskbarSourceType = $taskbarSourceType
        TaskbarValue      = $taskbarValue
        AlternatePins     = @()
    }
}

function Get-SldImportedPinName {
    param(
        [Parameter(Mandatory)][string]$SourceType,
        [Parameter(Mandatory)][string]$Value
    )

    if ($SourceType -eq 'DesktopAppLink') {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($Value)
        if ($fileName) {
            return $fileName
        }
    }

    if ($Value -match '^([^_!]+)') {
        return $matches[1]
    }

    $Value
}

function Find-SldAppByPin {
    param(
        [Parameter(Mandatory)][object[]]$AvailableApp,
        [Parameter(Mandatory)][ValidateSet('Start', 'Taskbar')][string]$Mode,
        [Parameter(Mandatory)][string]$SourceType,
        [Parameter(Mandatory)][string]$Value
    )

    foreach ($app in $AvailableApp) {
        $modeSourceType = if ($Mode -eq 'Start') { $app.StartSourceType } else { $app.TaskbarSourceType }
        $modeValue = if ($Mode -eq 'Start') { $app.StartValue } else { $app.TaskbarValue }

        if ($modeSourceType -eq $SourceType -and $modeValue -eq $Value) {
            return $app
        }

        foreach ($pin in @($app.AlternatePins)) {
            if ($pin.SourceType -eq $SourceType -and $pin.Value -eq $Value) {
                return $app
            }
        }
    }

    $null
}

function Copy-SldAppWithImportedPin {
    param(
        [Parameter(Mandatory)]$App,
        [Parameter(Mandatory)][ValidateSet('Start', 'Taskbar')][string]$Mode,
        [Parameter(Mandatory)][string]$SourceType,
        [Parameter(Mandatory)][string]$Value
    )

    [pscustomobject]@{
        Name              = $App.Name
        SourceType        = $App.SourceType
        Value             = $App.Value
        IconPath          = $App.IconPath
        IconSource        = $App.IconSource
        Category          = $App.Category
        PinSummary        = "Imported $SourceType"
        StartSourceType   = if ($Mode -eq 'Start') { $SourceType } else { $App.StartSourceType }
        StartValue        = if ($Mode -eq 'Start') { $Value } else { $App.StartValue }
        TaskbarSourceType = if ($Mode -eq 'Taskbar') { $SourceType } else { $App.TaskbarSourceType }
        TaskbarValue      = if ($Mode -eq 'Taskbar') { $Value } else { $App.TaskbarValue }
        AlternatePins     = @($App.AlternatePins)
    }
}

function ConvertFrom-SldStartLayoutJson {
    param(
        [Parameter(Mandatory)][string]$Json,
        [object[]]$AvailableApp = @()
    )

    $layout = $Json | ConvertFrom-Json
    $selected = [System.Collections.ObjectModel.ObservableCollection[object]]::new()

    foreach ($pin in @($layout.pinnedList)) {
        $sourceType = $null
        $value = $null

        if ($pin.desktopAppLink) {
            $sourceType = 'DesktopAppLink'
            $value = [string]$pin.desktopAppLink
        }
        elseif ($pin.packagedAppId) {
            $sourceType = 'PackagedAppId'
            $value = [string]$pin.packagedAppId
        }
        elseif ($pin.desktopAppId) {
            $sourceType = 'DesktopApplicationId'
            $value = [string]$pin.desktopAppId
        }
        else {
            continue
        }

        $match = Find-SldAppByPin -AvailableApp $AvailableApp -Mode Start -SourceType $sourceType -Value $value
        if ($match) {
            [void]$selected.Add((Copy-SldAppWithImportedPin -App $match -Mode Start -SourceType $sourceType -Value $value))
        }
        else {
            $name = Get-SldImportedPinName -SourceType $sourceType -Value $value
            [void]$selected.Add((New-SldImportedAppCandidate -Name $name -SourceType $sourceType -Value $value -Mode Start))
        }
    }

    [pscustomobject]@{
        ApplyOnce = [bool]$layout.applyOnce
        Apps      = $selected
    }
}

function ConvertTo-SldStartLayoutJson {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$App,
        [bool]$ApplyOnce = $false
    )

    $pins = foreach ($entry in $App) {
        ConvertTo-SldStartPin -App $entry
    }

    [ordered]@{
        applyOnce  = $ApplyOnce
        pinnedList = @($pins)
    } | ConvertTo-Json -Depth 10
}

function New-SldXmlAttribute {
    param(
        [Parameter(Mandatory)][xml]$Document,
        [Parameter(Mandatory)][System.Xml.XmlElement]$Element,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $attribute = $Document.CreateAttribute($Name)
    $attribute.Value = $Value
    [void]$Element.Attributes.Append($attribute)
}

function New-SldTaskbarPinElement {
    param(
        [Parameter(Mandatory)][xml]$Document,
        [Parameter(Mandatory)]$App
    )

    $taskbarNamespace = 'http://schemas.microsoft.com/Start/2014/TaskbarLayout'

    $sourceType = if ($App.TaskbarSourceType) { $App.TaskbarSourceType } else { $App.SourceType }
    $value = if ($App.TaskbarValue) { $App.TaskbarValue } else { $App.Value }

    switch ($sourceType) {
        'PackagedAppId' {
            $element = $Document.CreateElement('taskbar', 'UWA', $taskbarNamespace)
            New-SldXmlAttribute -Document $Document -Element $element -Name 'AppUserModelID' -Value $value
            $element
        }
        'DesktopApplicationId' {
            $element = $Document.CreateElement('taskbar', 'DesktopApp', $taskbarNamespace)
            New-SldXmlAttribute -Document $Document -Element $element -Name 'DesktopApplicationID' -Value $value
            $element
        }
        'DesktopAppLink' {
            $element = $Document.CreateElement('taskbar', 'DesktopApp', $taskbarNamespace)
            New-SldXmlAttribute -Document $Document -Element $element -Name 'DesktopApplicationLinkPath' -Value $value
            $element
        }
        default {
            throw "Unsupported taskbar pin type: $sourceType"
        }
    }
}

function ConvertTo-SldTaskbarLayoutXml {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$App,
        [switch]$Replace,
        [string]$Region
    )

    $layoutNamespace = 'http://schemas.microsoft.com/Start/2014/LayoutModification'
    $defaultLayoutNamespace = 'http://schemas.microsoft.com/Start/2014/FullDefaultLayout'
    $startNamespace = 'http://schemas.microsoft.com/Start/2014/StartLayout'
    $taskbarNamespace = 'http://schemas.microsoft.com/Start/2014/TaskbarLayout'

    $doc = New-Object System.Xml.XmlDocument
    $declaration = $doc.CreateXmlDeclaration('1.0', 'utf-8', $null)
    [void]$doc.AppendChild($declaration)

    $root = $doc.CreateElement('LayoutModificationTemplate', $layoutNamespace)
    New-SldXmlAttribute -Document $doc -Element $root -Name 'xmlns:defaultlayout' -Value $defaultLayoutNamespace
    New-SldXmlAttribute -Document $doc -Element $root -Name 'xmlns:start' -Value $startNamespace
    New-SldXmlAttribute -Document $doc -Element $root -Name 'xmlns:taskbar' -Value $taskbarNamespace
    New-SldXmlAttribute -Document $doc -Element $root -Name 'Version' -Value '1'
    [void]$doc.AppendChild($root)

    $collection = $doc.CreateElement('CustomTaskbarLayoutCollection', $layoutNamespace)
    if ($Replace) {
        New-SldXmlAttribute -Document $doc -Element $collection -Name 'PinListPlacement' -Value 'Replace'
    }
    [void]$root.AppendChild($collection)

    $layout = $doc.CreateElement('defaultlayout', 'TaskbarLayout', $defaultLayoutNamespace)
    if ($Region) {
        New-SldXmlAttribute -Document $doc -Element $layout -Name 'Region' -Value $Region
    }
    [void]$collection.AppendChild($layout)

    $pinList = $doc.CreateElement('taskbar', 'TaskbarPinList', $taskbarNamespace)
    [void]$layout.AppendChild($pinList)

    foreach ($entry in $App) {
        [void]$pinList.AppendChild((New-SldTaskbarPinElement -Document $doc -App $entry))
    }

    $memoryStream = New-Object System.IO.MemoryStream
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $writer = [System.Xml.XmlWriter]::Create($memoryStream, $settings)
    $doc.Save($writer)
    $writer.Close()
    $xmlString = [System.Text.Encoding]::UTF8.GetString($memoryStream.ToArray())
    $memoryStream.Dispose()
    return $xmlString
}

function ConvertFrom-SldTaskbarLayoutXml {
    param(
        [Parameter(Mandatory)][string]$Xml,
        [object[]]$AvailableApp = @()
    )

    [xml]$document = $Xml
    $selected = [System.Collections.ObjectModel.ObservableCollection[object]]::new()

    $collection = $document.SelectNodes("//*[local-name()='CustomTaskbarLayoutCollection']") | Select-Object -First 1
    $replace = $false
    if ($collection -and $collection.PinListPlacement -eq 'Replace') {
        $replace = $true
    }

    foreach ($node in $document.SelectNodes("//*[local-name()='DesktopApp']")) {
        $sourceType = $null
        $value = $null

        if ($node.DesktopApplicationID) {
            $sourceType = 'DesktopApplicationId'
            $value = [string]$node.DesktopApplicationID
        }
        elseif ($node.DesktopApplicationLinkPath) {
            $sourceType = 'DesktopAppLink'
            $value = [string]$node.DesktopApplicationLinkPath
        }

        if (-not $sourceType) {
            continue
        }

        $match = Find-SldAppByPin -AvailableApp $AvailableApp -Mode Taskbar -SourceType $sourceType -Value $value
        if ($match) {
            [void]$selected.Add((Copy-SldAppWithImportedPin -App $match -Mode Taskbar -SourceType $sourceType -Value $value))
        }
        else {
            $name = Get-SldImportedPinName -SourceType $sourceType -Value $value
            [void]$selected.Add((New-SldImportedAppCandidate -Name $name -SourceType $sourceType -Value $value -Mode Taskbar))
        }
    }

    foreach ($node in $document.SelectNodes("//*[local-name()='UWA']")) {
        if (-not $node.AppUserModelID) {
            continue
        }

        $sourceType = 'PackagedAppId'
        $value = [string]$node.AppUserModelID
        $match = Find-SldAppByPin -AvailableApp $AvailableApp -Mode Taskbar -SourceType $sourceType -Value $value
        if ($match) {
            [void]$selected.Add((Copy-SldAppWithImportedPin -App $match -Mode Taskbar -SourceType $sourceType -Value $value))
        }
        else {
            $name = Get-SldImportedPinName -SourceType $sourceType -Value $value
            [void]$selected.Add((New-SldImportedAppCandidate -Name $name -SourceType $sourceType -Value $value -Mode Taskbar))
        }
    }

    [pscustomobject]@{
        Replace = $replace
        Apps    = $selected
    }
}
