function Get-SldShortcutIconPath {
    param([Parameter(Mandatory)][string]$Path)

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        if ($shortcut.IconLocation) {
            return ($shortcut.IconLocation -split ',')[0]
        }
        if ($shortcut.TargetPath) {
            return $shortcut.TargetPath
        }
    }
    catch {
        return $null
    }
}

function Get-SldImageSource {
    param([string]$IconPath)

    if (-not $IconPath -or -not (Test-Path -LiteralPath $IconPath)) {
        return $null
    }

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($IconPath)
        if (-not $icon) {
            return $null
        }
        $bitmap = $icon.ToBitmap()
        $stream = New-Object System.IO.MemoryStream
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        $stream.Position = 0

        $image = New-Object System.Windows.Media.Imaging.BitmapImage
        $image.BeginInit()
        $image.StreamSource = $stream
        $image.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $image.EndInit()
        $image.Freeze()
        $stream.Dispose()
        $bitmap.Dispose()
        $icon.Dispose()
        $image
    }
    catch {
        $null
    }
}
