function Add-SldSelectedApp {
    param(
        [Parameter(Mandatory)]$SourceList,
        [Parameter(Mandatory)]$TargetList
    )

    foreach ($item in @($SourceList.SelectedItems)) {
        if ($TargetList.ItemsSource.Value -notcontains $item.Value) {
            [void]$TargetList.ItemsSource.Add($item)
        }
    }
}

function Add-SldSuggestedApp {
    param(
        [Parameter(Mandatory)]$SourceList,
        [Parameter(Mandatory)]$TargetList
    )

    if ($SourceList.SelectedItems.Count -eq 0 -and $SourceList.Items.Count -gt 0) {
        $SourceList.SelectedIndex = 0
    }

    Add-SldSelectedApp -SourceList $SourceList -TargetList $TargetList
}

function Remove-SldSelectedApp {
    param([Parameter(Mandatory)]$List)

    foreach ($item in @($List.SelectedItems)) {
        $List.ItemsSource.Remove($item)
    }
}

function ConvertTo-SldFilteredCollection {
    param(
        [Parameter(Mandatory)][object[]]$App,
        [string]$Query
    )

    $collection = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
    $terms = @($Query -split '\s+' | Where-Object { $_ })

    foreach ($entry in $App) {
        $haystack = '{0} {1} {2} {3}' -f $entry.Name, $entry.SourceType, $entry.Value, $entry.Category
        $isMatch = $true
        foreach ($term in $terms) {
            if ($haystack.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
                $isMatch = $false
                break
            }
        }

        if ($isMatch) {
            [void]$collection.Add($entry)
        }
    }

    ,$collection
}

function Update-SldAvailableApps {
    param(
        [Parameter(Mandatory)]$List,
        [Parameter(Mandatory)]$Status,
        [Parameter(Mandatory)][object[]]$AllApps,
        [string]$Query
    )

    $filtered = ConvertTo-SldFilteredCollection -App $AllApps -Query $Query
    $List.ItemsSource = $filtered

    if ($filtered.Count -gt 0) {
        $List.SelectedIndex = 0
    }

    if ([string]::IsNullOrWhiteSpace($Query)) {
        $Status.Text = "$($filtered.Count) apps available"
    }
    else {
        $Status.Text = "$($filtered.Count) matches for '$Query'"
    }
}

function Move-SldSelectedApp {
    param(
        [Parameter(Mandatory)]$List,
        [Parameter(Mandatory)][ValidateSet('Up', 'Down')]$Direction
    )

    $index = $List.SelectedIndex
    if ($index -lt 0) {
        return
    }

    $newIndex = if ($Direction -eq 'Up') { $index - 1 } else { $index + 1 }
    if ($newIndex -lt 0 -or $newIndex -ge $List.ItemsSource.Count) {
        return
    }

    $item = $List.ItemsSource[$index]
    $List.ItemsSource.RemoveAt($index)
    $List.ItemsSource.Insert($newIndex, $item)
    $List.SelectedIndex = $newIndex
}

function Update-SldPreview {
    param(
        [Parameter(Mandatory)]$List,
        [Parameter(Mandatory)]$Preview,
        [ValidateSet('Start', 'Taskbar')][string]$Mode,
        [bool]$ApplyOnce,
        [bool]$Replace
    )

    try {
        if ($Mode -eq 'Start') {
            $Preview.Text = ConvertTo-SldStartLayoutJson -App @($List.ItemsSource) -ApplyOnce $ApplyOnce
        }
        else {
            $Preview.Text = ConvertTo-SldTaskbarLayoutXml -App @($List.ItemsSource) -Replace:$Replace
        }
    }
    catch {
        $Preview.Text = $_.Exception.Message
    }
}

function Show-SldErrorMessage {
    param(
        [Parameter(Mandatory)]$Window,
        [Parameter(Mandatory)][string]$Message
    )

    [void][System.Windows.MessageBox]::Show($Window, $Message, 'Start Layout Designer', 'OK', 'Error')
}

function Show-SldInfoMessage {
    param(
        [Parameter(Mandatory)]$Window,
        [Parameter(Mandatory)][string]$Message
    )

    [void][System.Windows.MessageBox]::Show($Window, $Message, 'Start Layout Designer', 'OK', 'Information')
}

function Show-SldWindow {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $xamlPath = Join-Path $script:ModuleRoot 'Views\MainWindow.xaml'
    [xml]$xaml = Get-Content -LiteralPath $xamlPath -Raw
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    $availableStartList = $window.FindName('AvailableStartList')
    $startSearchBox = $window.FindName('StartSearchBox')
    $startSearchStatus = $window.FindName('StartSearchStatus')
    $selectedStartList = $window.FindName('SelectedStartList')
    $startPreview = $window.FindName('StartPreview')
    $applyOnceCheck = $window.FindName('ApplyOnceCheck')
    $refreshStartButton = $window.FindName('RefreshStartButton')
    $addStartButton = $window.FindName('AddStartButton')
    $removeStartButton = $window.FindName('RemoveStartButton')
    $startUpButton = $window.FindName('StartUpButton')
    $startDownButton = $window.FindName('StartDownButton')
    $importStartButton = $window.FindName('ImportStartButton')
    $exportStartButton = $window.FindName('ExportStartButton')
    $deployStartButton = $window.FindName('DeployStartButton')

    $availableTaskbarList = $window.FindName('AvailableTaskbarList')
    $taskbarSearchBox = $window.FindName('TaskbarSearchBox')
    $taskbarSearchStatus = $window.FindName('TaskbarSearchStatus')
    $selectedTaskbarList = $window.FindName('SelectedTaskbarList')
    $taskbarPreview = $window.FindName('TaskbarPreview')
    $replaceTaskbarCheck = $window.FindName('ReplaceTaskbarCheck')
    $refreshTaskbarButton = $window.FindName('RefreshTaskbarButton')
    $addTaskbarButton = $window.FindName('AddTaskbarButton')
    $removeTaskbarButton = $window.FindName('RemoveTaskbarButton')
    $taskbarUpButton = $window.FindName('TaskbarUpButton')
    $taskbarDownButton = $window.FindName('TaskbarDownButton')
    $importTaskbarButton = $window.FindName('ImportTaskbarButton')
    $exportTaskbarButton = $window.FindName('ExportTaskbarButton')
    $deployTaskbarButton = $window.FindName('DeployTaskbarButton')

    $appState = [pscustomobject]@{
        AllApps = @()
    }
    $loadApps = {
        $loadedApps = New-Object System.Collections.Generic.List[object]
        foreach ($app in Get-SldCandidateApps -IncludeCommonWindowsApps -IncludeDesktopShortcuts -IncludePackagedApps) {
            if ($app.IconPath) {
                $app | Add-Member -NotePropertyName IconSource -NotePropertyValue (Get-SldImageSource -IconPath $app.IconPath) -Force
            }
            else {
                $app | Add-Member -NotePropertyName IconSource -NotePropertyValue $null -Force
            }
            [void]$loadedApps.Add($app)
        }

        $appState.AllApps = @($loadedApps.ToArray())
        Update-SldAvailableApps -List $availableStartList -Status $startSearchStatus -AllApps $appState.AllApps -Query $startSearchBox.Text
        Update-SldAvailableApps -List $availableTaskbarList -Status $taskbarSearchStatus -AllApps $appState.AllApps -Query $taskbarSearchBox.Text
    }

    $selectedStartList.ItemsSource = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
    $selectedTaskbarList.ItemsSource = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
    & $loadApps

    $refreshStartButton.Add_Click({ & $loadApps })
    $refreshTaskbarButton.Add_Click({ & $loadApps })

    $startSearchBox.Add_TextChanged({
        Update-SldAvailableApps -List $availableStartList -Status $startSearchStatus -AllApps $appState.AllApps -Query $startSearchBox.Text
    })
    $taskbarSearchBox.Add_TextChanged({
        Update-SldAvailableApps -List $availableTaskbarList -Status $taskbarSearchStatus -AllApps $appState.AllApps -Query $taskbarSearchBox.Text
    })
    $startSearchBox.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
            Add-SldSuggestedApp -SourceList $availableStartList -TargetList $selectedStartList
            Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
            $_.Handled = $true
        }
    })
    $taskbarSearchBox.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
            Add-SldSuggestedApp -SourceList $availableTaskbarList -TargetList $selectedTaskbarList
            Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
            $_.Handled = $true
        }
    })

    $availableStartList.Add_MouseDoubleClick({
        Add-SldSuggestedApp -SourceList $availableStartList -TargetList $selectedStartList
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $selectedStartList.Add_MouseDoubleClick({
        Remove-SldSelectedApp -List $selectedStartList
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $addStartButton.Add_Click({
        Add-SldSuggestedApp -SourceList $availableStartList -TargetList $selectedStartList
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $removeStartButton.Add_Click({
        Remove-SldSelectedApp -List $selectedStartList
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $startUpButton.Add_Click({
        Move-SldSelectedApp -List $selectedStartList -Direction Up
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $startDownButton.Add_Click({
        Move-SldSelectedApp -List $selectedStartList -Direction Down
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $applyOnceCheck.Add_Click({
        Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    })
    $importStartButton.Add_Click({
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        if ($dialog.ShowDialog()) {
            try {
                $json = Get-Content -LiteralPath $dialog.FileName -Raw
                $imported = ConvertFrom-SldStartLayoutJson -Json $json -AvailableApp $appState.AllApps
                $selectedStartList.ItemsSource = $imported.Apps
                $applyOnceCheck.IsChecked = $imported.ApplyOnce
                Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
            }
            catch {
                Show-SldErrorMessage -Window $window -Message "Could not import Start layout JSON.`r`n$($_.Exception.Message)"
            }
        }
    })
    $exportStartButton.Add_Click({
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
        $dialog.FileName = 'StartLayout.json'
        if ($dialog.ShowDialog()) {
            ConvertTo-SldStartLayoutJson -App @($selectedStartList.ItemsSource) -ApplyOnce $applyOnceCheck.IsChecked |
                Set-Content -LiteralPath $dialog.FileName -Encoding UTF8
        }
    })
    $deployStartButton.Add_Click({
        try {
            $json = ConvertTo-SldStartLayoutJson -App @($selectedStartList.ItemsSource) -ApplyOnce $applyOnceCheck.IsChecked
            $result = Set-SldStartPinsPolicy -Json $json
            $startPreview.Text = $json
            $applyOnceNote = if ($applyOnceCheck.IsChecked) { "`r`n`r`nNote: Apply once is enabled, so Windows may not reapply later changes after the first successful application." } else { "" }
            Show-SldInfoMessage -Window $window -Message "Start pins policy deployed for the current user.`r`n`r`nPolicy: $($result.Policy)`r`nFile: $($result.Path)`r`n`r`nSign out and sign in again for the Start layout to apply.$applyOnceNote"
        }
        catch {
            Show-SldErrorMessage -Window $window -Message "Could not deploy Start pins policy.`r`n$($_.Exception.Message)"
        }
    })

    $availableTaskbarList.Add_MouseDoubleClick({
        Add-SldSuggestedApp -SourceList $availableTaskbarList -TargetList $selectedTaskbarList
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $selectedTaskbarList.Add_MouseDoubleClick({
        Remove-SldSelectedApp -List $selectedTaskbarList
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $addTaskbarButton.Add_Click({
        Add-SldSuggestedApp -SourceList $availableTaskbarList -TargetList $selectedTaskbarList
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $removeTaskbarButton.Add_Click({
        Remove-SldSelectedApp -List $selectedTaskbarList
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $taskbarUpButton.Add_Click({
        Move-SldSelectedApp -List $selectedTaskbarList -Direction Up
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $taskbarDownButton.Add_Click({
        Move-SldSelectedApp -List $selectedTaskbarList -Direction Down
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $replaceTaskbarCheck.Add_Click({
        Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
    })
    $importTaskbarButton.Add_Click({
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Filter = 'XML files (*.xml)|*.xml|All files (*.*)|*.*'
        if ($dialog.ShowDialog()) {
            try {
                $xml = Get-Content -LiteralPath $dialog.FileName -Raw
                $imported = ConvertFrom-SldTaskbarLayoutXml -Xml $xml -AvailableApp $appState.AllApps
                $selectedTaskbarList.ItemsSource = $imported.Apps
                $replaceTaskbarCheck.IsChecked = $imported.Replace
                Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked
            }
            catch {
                Show-SldErrorMessage -Window $window -Message "Could not import taskbar XML.`r`n$($_.Exception.Message)"
            }
        }
    })
    $exportTaskbarButton.Add_Click({
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'XML files (*.xml)|*.xml|All files (*.*)|*.*'
        $dialog.FileName = 'TaskbarLayout.xml'
        if ($dialog.ShowDialog()) {
            ConvertTo-SldTaskbarLayoutXml -App @($selectedTaskbarList.ItemsSource) -Replace:$replaceTaskbarCheck.IsChecked |
                Set-Content -LiteralPath $dialog.FileName -Encoding UTF8
        }
    })
    $deployTaskbarButton.Add_Click({
        try {
            $xml = ConvertTo-SldTaskbarLayoutXml -App @($selectedTaskbarList.ItemsSource) -Replace:$replaceTaskbarCheck.IsChecked
            $result = Set-SldTaskbarLayoutPolicy -Xml $xml
            $taskbarPreview.Text = $xml
            Show-SldInfoMessage -Window $window -Message "Taskbar layout policy deployed for the current user.`r`n`r`nPolicy: $($result.Policy)`r`nFile: $($result.Path)`r`n`r`nSign out and sign in again for the taskbar layout to apply."
        }
        catch {
            Show-SldErrorMessage -Window $window -Message "Could not deploy taskbar layout policy.`r`n$($_.Exception.Message)"
        }
    })

    Update-SldPreview -List $selectedStartList -Preview $startPreview -Mode Start -ApplyOnce $applyOnceCheck.IsChecked
    Update-SldPreview -List $selectedTaskbarList -Preview $taskbarPreview -Mode Taskbar -Replace $replaceTaskbarCheck.IsChecked

    [void]$window.ShowDialog()
}
