# Local inventory/process fixtures only; never launches Godot.
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '../tools/owner/kickoff.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($name in @('Get-SegmentVerdict', 'Run-Segment', 'Phase-Chain', 'Run-Phase')) {
  $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
  . ([scriptblock]::Create($node.Extent.Text))
}
$script:Checks = 0
function Check([bool]$ok, [string]$why) { $script:Checks++; if (-not $ok) { throw $why } }
function Log([string]$msg) {}
function Save-Phases {}
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('tetherbound-segment-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
function Clean-Inventory {
  return @{ complete = $true; blocked = ''; derailed = ''; derails = @(); harness_errors = @(); uncommittable = @(); steps = @{ total = 3; ran = 3; pass = 2; delegated = 1; fail = 0; skipped = 0; refused = 0 } }
}
function Write-Inventory([string]$dir, $inventory) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $inventory | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $dir 'INVENTORY.json')
}
$dir = Join-Path $fixtureRoot 'verdict'
Write-Inventory $dir (Clean-Inventory)
Check ((Get-SegmentVerdict $dir 0).effective_exit -eq 0) 'Complete delegated lane must pass'
# Legitimate skip_if is an executed PASS in the inventory, not a SKIP verdict.
'skipped press: skip_if already holds' | Set-Content (Join-Path $dir 'notes.md')
Check ((Get-SegmentVerdict $dir 0).effective_exit -eq 0) 'Authored conditional no-op must remain allowed'
Check ((Get-SegmentVerdict $dir 124).effective_exit -eq 124) 'Raw timeout must remain a failure despite complete inventory'
foreach ($field in @('fail', 'refused', 'skipped')) {
  $inventory = Clean-Inventory; $inventory.steps[$field] = 1
  Write-Inventory $dir $inventory
  $result = Get-SegmentVerdict $dir 0
  Check ($result.effective_exit -ne 0 -and $result.process_exit -eq 0) "steps.$field must fail even if complete is true and process exited 0"
}
$inventory = Clean-Inventory; $inventory.complete = $false; $inventory.steps.fail = 1; $inventory.steps.skipped = 541; $inventory.steps.ran = 26; $inventory.steps.total = 567
$inventory.derailed = 'no narrative modal'; $inventory.derails = @(@{ at = 'S03-25'; resynced_at = $null; skipped = 541 })
Write-Inventory $dir $inventory
$result = Get-SegmentVerdict $dir 0
Check ($result.effective_exit -ne 0 -and $result.reasons -contains 'steps.skipped=541') 'Measured zero-exit S03 derail must fail with diagnostic counts'
foreach ($field in @('blocked', 'derailed', 'derails', 'harness_errors', 'uncommittable')) {
  $inventory = Clean-Inventory; $inventory[$field] = 'problem'
  Write-Inventory $dir $inventory
  Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) "$field must fail closed"
}
$inventory = Clean-Inventory; $inventory.steps.ran = 2
Write-Inventory $dir $inventory
Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) 'Incomplete step execution must fail'
foreach ($value in @($false, 'true', $null)) {
  $inventory = Clean-Inventory; $inventory.complete = $value
  Write-Inventory $dir $inventory
  Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) 'Missing, false or non-boolean complete must fail'
}
$inventory = Clean-Inventory; $inventory.steps.Remove('fail')
Write-Inventory $dir $inventory
Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) 'Missing verdict counters must fail'
Write-Inventory $dir (Clean-Inventory)
foreach ($marker in @('INCOMPLETE.md', 'BLOCKER.md')) {
  $markerPath = Join-Path $dir $marker
  'blocked' | Set-Content $markerPath
  Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) "$marker must override an apparently clean inventory"
  Remove-Item -LiteralPath $markerPath
}
'not json' | Set-Content (Join-Path $dir 'INVENTORY.json')
Check ((Get-SegmentVerdict $dir 0).effective_exit -ne 0) 'Malformed inventory must fail'
Check ((Get-SegmentVerdict (Join-Path $fixtureRoot 'missing') 0).effective_exit -ne 0) 'Missing inventory must fail'

# Exercise Run-Segment and Phase-Chain through a fake process boundary.
$script:Calls = 0; $script:NextExit = 0; $script:NextInventory = Clean-Inventory
$script:Repo = $fixtureRoot; $script:Sha = 'fixture'; $script:Stamp = 'fixture'
$script:Res = '1280x800'; $script:SegmentTimeoutMinutes = 1
$script:Journey = @('S99'); $script:CaptureLanes = @()
function Invoke-GodotRender([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec, [string[]]$EngineFlags = @()) {
  $outputDir = Split-Path -Parent $LogFile
  if ($ScriptAndArgs -contains 'tools/capture_diag_minimal.gd') {
    'smoke fixture' | Set-Content (Join-Path $outputDir 'capture_smoke.png')
    return 0
  }
  $script:Calls++
  Write-Inventory $outputDir $script:NextInventory
  return $script:NextExit
}
function New-Run([string]$name) {
  $script:GateRun = Join-Path $fixtureRoot $name
  New-Item -ItemType Directory -Path $script:GateRun | Out-Null
  $script:SegmentResults = @(); $script:Calls = 0
}
New-Run 'failed-chain'
$script:NextInventory = Clean-Inventory; $script:NextInventory.steps.fail = 1
$caught = ''
try { Phase-Chain } catch { $caught = $_.Exception.Message }
Check ($caught -match 'journey segments.*FAILED: S99') 'Phase-Chain must fail a zero-exit failed expectation'
Check ($script:SegmentResults[0].exit -eq 0 -and $script:SegmentResults[0].effective_exit -eq 1) 'Raw and effective exits must be distinct in memory'
$saved = Get-Content (Join-Path $script:GateRun 'S99/SEGMENT_RESULT.json') -Raw | ConvertFrom-Json
Check ($saved.process_exit -eq 0 -and $saved.effective_exit -eq 1) 'Persist both exits and verdict diagnostics'
$chainRow = (Get-Content (Join-Path $script:GateRun 'CHAIN_LOG.tsv'))[-1] -split "`t"
Check ($chainRow[3] -eq '0') 'CHAIN_LOG must retain the original raw process exit'
$script:NextInventory = Clean-Inventory
Run-Segment 'S99' $false $false
Check ($script:Calls -eq 2) 'Failed expectation without INCOMPLETE marker must rerun'
Check (Test-Path (Join-Path $script:GateRun 'S99-superseded-1/INVENTORY.json')) 'Rerun must retain prior diagnostics'
Run-Segment 'S99' $false $false
Check ($script:Calls -eq 2 -and $script:SegmentResults[-1].skipped) 'Clean inventory must be reused'
New-Run 'clean-chain'
Phase-Chain
Check ($script:SegmentResults[0].effective_exit -eq 0) 'Genuinely complete chain must pass'
New-Run 'historical-incomplete'
$inventory = Clean-Inventory; $inventory.complete = $false
Write-Inventory (Join-Path $script:GateRun 'S99') $inventory
Run-Segment 'S99' $false $false
Check ($script:Calls -eq 1) 'Historical incomplete inventory without markers must rerun'
New-Run 'nonzero-process'
Write-Inventory (Join-Path $script:GateRun 'S99') (Clean-Inventory)
'{"process_exit":124,"effective_exit":124}' | Set-Content (Join-Path $script:GateRun 'S99/SEGMENT_RESULT.json')
Run-Segment 'S99' $false $false
Check ($script:Calls -eq 1) 'Known nonzero process exit must rerun even with clean inventory'
New-Run 'failed-capture'
$script:Journey = @(); $script:CaptureLanes = @('S99C')
New-Item -ItemType Directory -Force -Path (Join-Path $script:Repo 'tools/gate_f/segments') | Out-Null
'{}' | Set-Content (Join-Path $script:Repo 'tools/gate_f/segments/S99C.json')
$script:NextInventory = Clean-Inventory; $script:NextInventory.steps.fail = 1
$caught = ''
try { Phase-Chain } catch { $caught = $_.Exception.Message }
Check ($caught -match '1 of 1 capture lanes FAILED: S99C') 'Capture lane expectations must fail the chain too'
$script:Phases = @{ chain = @{status='ok'}; package = @{status='ok'} }
$script:SegmentResults = @(@{ skipped = $true; effective_exit = 0 })
$script:Only = ''; $script:Quick = $false; $script:Resume = 'historical'; $script:Rechecked = 0
Run-Phase 'chain' { $script:Rechecked++ }
Run-Phase 'package' { $script:Rechecked++ }
Check ($script:Rechecked -eq 1) 'Clean no-op resume must revalidate chain and may reuse its package'
$script:SegmentResults = @(@{ skipped = $false; effective_exit = 0 })
Run-Phase 'chain' { $script:Rechecked++ }
Run-Phase 'package' { $script:Rechecked++ }
Check ($script:Rechecked -eq 3) 'A rerun segment must invalidate the previous package summary'
$script:Phases.package = @{ status = 'ok' }
$script:SegmentResults = @(@{ skipped = $true; effective_exit = 1 })
Run-Phase 'chain' { throw 'inventory failed' }
Check (-not $script:Phases.ContainsKey('package')) 'Failed revalidation must invalidate previous package summary'
Write-Host "PASS: $script:Checks segment verdict and chain/resume checks. Fixtures: $fixtureRoot"
