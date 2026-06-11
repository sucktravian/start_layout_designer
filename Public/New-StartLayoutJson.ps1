function New-StartLayoutJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [psobject[]]$App,

        [bool]$ApplyOnce = $false,

        [string]$Path
    )

    begin {
        $items = New-Object System.Collections.Generic.List[object]
    }

    process {
        foreach ($entry in $App) {
            $items.Add($entry)
        }
    }

    end {
        $json = ConvertTo-SldStartLayoutJson -App $items -ApplyOnce $ApplyOnce
        if ($Path) {
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            Set-Content -LiteralPath $resolvedPath -Value $json -Encoding UTF8
        }
        $json
    }
}
