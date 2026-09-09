param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("meadows", "cloudreach", "stormwood", "water")]
    [string]$Biome,
    [string]$Godot = "godot",
    [string]$Output = "",
    [string[]]$Subset = @(),
    [ValidateSet("day,night", "day", "night")]
    [string]$Times = "day,night"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Output)) {
    $roundStamp = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
    $Output = "res://shots/catalogue/$Biome/$roundStamp"
}
$isolatedRoot = Join-Path $repoRoot ".artifacts/catalogue-survey-userdata/$Biome"
$appData = Join-Path $isolatedRoot "AppData/Roaming"
$localAppData = Join-Path $isolatedRoot "AppData/Local"
New-Item -ItemType Directory -Force -Path $appData, $localAppData | Out-Null
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$env:APPDATA = $appData
$env:LOCALAPPDATA = $localAppData
try {
    $userArgs = @("--biome=$Biome", "--output=$Output", "--times=$Times")
    foreach ($part in $Subset) {
        $userArgs += "--subset=$part"
    }
    Push-Location $repoRoot
    try {
        if ($Output.StartsWith("res://")) {
            $outputPath = Join-Path $repoRoot $Output.Substring(6).Replace('/', [IO.Path]::DirectorySeparatorChar)
        } else {
            $outputPath = $Output
        }
        New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
        $engineLog = Join-Path $outputPath "engine.log"
        & $Godot --path . --rendering-driver opengl3 --resolution 1280x800 --position -10000,-10000 --log-file $engineLog --script tools/catalogue_survey.gd -- @userArgs
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
