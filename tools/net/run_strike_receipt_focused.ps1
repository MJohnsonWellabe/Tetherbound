param(
    [string]$Godot = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe'
)

$ErrorActionPreference = 'Stop'

$activeGodot = @(Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue)
if ($activeGodot.Count -gt 0) {
    $ids = ($activeGodot | Select-Object -ExpandProperty Id) -join ', '
    Write-Error "Native lease is occupied by Godot PID(s): $ids"
    exit 73
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    Write-Error "Godot executable is missing: $Godot"
    exit 74
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $env:TEMP "tetherbound-strike-receipt-focused-$stamp.log"

& $Godot --headless --path $repoRoot --log-file $logPath `
    --script res://tests/run_tests.gd -- `
    --only=test_encounter_host_rejects_friendly_strike.gd
$testExit = $LASTEXITCODE

$badLines = @(Select-String -LiteralPath $logPath `
    -Pattern 'SCRIPT ERROR','ERROR:','WARNING:','FAIL:' -SimpleMatch)
if ($testExit -ne 0 -or $badLines.Count -gt 0) {
    Write-Output "Focused receipt fixture failed; exit=$testExit log=$logPath"
    $badLines | ForEach-Object { Write-Output $_.Line }
    exit 1
}

Write-Output "Focused receipt fixture passed; log=$logPath"
exit 0
