function New-TaskbarLayoutXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [psobject[]]$App,

        [switch]$Replace,

        [string]$Region,

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
        $xml = ConvertTo-SldTaskbarLayoutXml -App $items -Replace:$Replace -Region $Region
        if ($Path) {
            $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            Set-Content -LiteralPath $resolvedPath -Value $xml -Encoding UTF8
        }
        $xml
    }
}
