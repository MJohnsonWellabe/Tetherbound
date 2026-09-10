param(
    [string]$Godot = "godot",
    [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Output)) {
    $stamp = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
    $Output = "res://shots/diagnostics/south-bridge-foliage-source/$stamp"
}
$isolatedRoot = Join-Path $repoRoot ".artifacts/catalogue-survey-userdata/meadows-foliage-source"
$appData = Join-Path $isolatedRoot "AppData/Roaming"
$localAppData = Join-Path $isolatedRoot "AppData/Local"
New-Item -ItemType Directory -Force -Path $appData, $localAppData | Out-Null
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = $appData
$env:LOCALAPPDATA = $localAppData
try {
    Push-Location $repoRoot
    try {
        if ($Output.StartsWith("res://")) {
            $outputPath = Join-Path $repoRoot $Output.Substring(6).Replace('/', [IO.Path]::DirectorySeparatorChar)
        } else {
            $outputPath = $Output
        }
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
        $engineLog = Join-Path $outputPath "engine.log"
        & $Godot --path . --rendering-driver opengl3 --resolution 1280x800 `
            --position -10000,-10000 --log-file $engineLog `
            --script tools/probe_south_bridge_foliage_source.gd -- `
            --biome=meadows --output=$Output --times=day `
            --subset=south_bridge --character=trainer
        exit $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
}
