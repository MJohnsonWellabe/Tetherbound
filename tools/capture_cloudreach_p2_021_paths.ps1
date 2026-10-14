function Initialize-F40CapturePaths([string]$OutputPath, [string]$HomePath) {
    if (Test-Path -LiteralPath $OutputPath) { throw "Capture output must be absent before runner start: $OutputPath" }
    if (Test-Path -LiteralPath $HomePath) { throw "Per-leg home must be fresh: $HomePath" }
    $parent = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $homeParent = Split-Path -Parent $HomePath
    if (-not (Test-Path -LiteralPath $homeParent -PathType Container)) {
        New-Item -ItemType Directory -Path $homeParent -Force | Out-Null
    }
    New-Item -ItemType Directory -Path $HomePath | Out-Null
}

function Set-F40CaptureLegValue($Leg, [string]$Name, $Value) {
    $property = $Leg.PSObject.Properties[$Name]
    if ($null -eq $property) { throw "Capture packet leg lacks $Name field" }
    $property.Value = $Value
}
