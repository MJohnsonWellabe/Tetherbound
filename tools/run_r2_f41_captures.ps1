param(
    [Parameter(Mandatory=$true)][string]$GodotExe,
    [ValidateSet('baseline','candidate')][string]$Variant = 'baseline',
    [Parameter(Mandatory=$true)][string]$RunId
)
# PREPARED ONLY: ROOT must grant the serialized engine queue before invoking.
# Local reversible config staging, never a shipping flag enable or acceptance.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($repoRoot -ne 'D:\tetherbound\r2-f41') { throw 'Capture staging is scoped to r2-f41 only.' }
if ($RunId -notmatch '^[a-zA-Z0-9_-]+$') { throw 'RunId must be a simple fresh capture label.' }
$configNames = @('stormheart_presentation','stormwood_road_current','stormwood_ground_finish','stormwood_glass_field')
$originals = @{}
Push-Location -LiteralPath $repoRoot
try {
    $sourceCommit = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve capture source.' }
    foreach ($name in $configNames) {
        $path = Join-Path $repoRoot "data/config/$name.json"
        & git diff --quiet HEAD -- "data/config/$name.json"
        if ($LASTEXITCODE -ne 0) { throw "Commit config changes before capture: $name" }
        $originals[$path] = [IO.File]::ReadAllBytes($path)
    }
    if ($Variant -eq 'candidate') {
        foreach ($name in $configNames) {
            $path = Join-Path $repoRoot "data/config/$name.json"
            $cfg = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            switch ($name) {
                'stormheart_presentation' {
                    $cfg.enabled = $true
                    foreach ($part in @('ancient_trunk','built_detail','branching_crown','canopy_atlas','core_finish')) {
                        $cfg.$part.enabled = $true
                    }
                }
                'stormwood_road_current' { $cfg.finish_candidate.enabled = $true }
                'stormwood_ground_finish' { $cfg.enabled = $true }
                'stormwood_glass_field' { $cfg.scorched_scars = $true }
            }
            [IO.File]::WriteAllText($path, ($cfg | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
        }
    }
    foreach ($preset in @('High','Medium')) {
        $output = "res://ralph/reports/R2-F41/native/$RunId/$Variant/$preset"
        & $GodotExe --path $repoRoot --rendering-method forward_plus --resolution 1920x1080 --script tools/capture_r2_f41_matrix.gd -- "--preset=$preset" "--source-commit=$sourceCommit" "--out=$output/matrix" "--label=$Variant"
        if ($LASTEXITCODE -ne 0) { throw "F41 $Variant $preset matrix failed." }
        & $GodotExe --path $repoRoot --rendering-method forward_plus --resolution 1920x1080 --script tools/phase2_capture_stormheart_decks.gd -- "--out=$output/decks" "--label=$Variant" --phases=calm,building,break,fading --hud
        if ($LASTEXITCODE -ne 0) { throw "F41 $Variant $preset interior failed." }
    }
} finally {
    foreach ($path in $originals.Keys) { [IO.File]::WriteAllBytes($path, $originals[$path]) }
    Pop-Location
}
