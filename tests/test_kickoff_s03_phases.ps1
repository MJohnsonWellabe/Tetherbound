# Extract production functions without running kickoff preparation or Godot.
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$path = Join-Path $PSScriptRoot '../tools/owner/kickoff.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($name in @('Get-SegmentVerdict', 'Publish-SegmentPhases', 'Phase-Chain')) {
  $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
  . ([scriptblock]::Create($node.Extent.Text))
}
$journeyNode = $ast.Find({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$Journey' }, $true)
. ([scriptblock]::Create($journeyNode.Extent.Text))
$captureNode = $ast.Find({ param($n) $n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$CaptureLanes' }, $true)
. ([scriptblock]::Create($captureNode.Extent.Text))
$script:Checks = 0
function Check([bool]$ok, [string]$why) { $script:Checks++; if (-not $ok) { throw $why } }
function Log([string]$msg) {}
Check (($Journey -join ',') -eq 'S01,S02,S03p1,S03p2,S03p3,S04,S05,S06,S07,S08,S09,S10a,S10b,S10c,S10d,S10e') 'Production journey must use ordered S03 phases'
Check (($CaptureLanes -join ',') -eq 'S01C,S02C,S03Cp1,S03Cp2,S03Cp3,S04C,S05C,S06C,S07C,S08C,S09C,S10aC,S10bC,S10cC') 'Production capture schedule must use ordered S03C phases'
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('tetherbound-s03-chain-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
$script:Repo = $fixtureRoot
$script:Res = '1280x800'
$script:CaptureLanes = @('S03C')
New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'tools/gate_f/segments') -Force | Out-Null
'{}' | Set-Content (Join-Path $fixtureRoot 'tools/gate_f/segments/S03C.json')
$savedPython = $env:PYTHON
# Resolve an actual executable, but never execute it: Invoke-Proc is the fixture boundary.
$env:PYTHON = (Get-Process -Id $PID).Path
function New-Run([string]$name) {
  $script:GateRun = Join-Path $fixtureRoot $name
  New-Item -ItemType Directory -Path $script:GateRun | Out-Null
  $script:SegmentResults = @(); $script:Order = @(); $script:AggregateCalls = 0
  $script:AggregateExit = 0; $script:BadInventory = $false; $script:OmitPhaseSave = $false; $script:OmitCanonicalSave = $false; $script:FailedPhase = $false
  $script:ExpectedParent = 'S03'
}
function Run-Segment([string]$Seg, [bool]$Capture, [bool]$Movie) {
  Check (-not $Movie) 'Journey and capture scheduling must preserve existing no-movie policy'
  Check ($Capture -eq ($Seg -cmatch '^S\d+[a-z]?C')) 'Only capture lane gets capture mode'
  if ($Seg -eq 'S04') { Check (Test-Path (Join-Path $script:GateRun 'S03/saves/S03-exit.json')) 'S04 requires published canonical save' }
  $script:Order += $Seg
  $script:SegmentResults += @{ seg = $Seg; exit = 0; effective_exit = 0; capture = $Capture; skipped = $false }
  if ($script:FailedPhase -and $Seg -eq 'S03p2') { $script:SegmentResults[-1].exit = 124; $script:SegmentResults[-1].effective_exit = 124 }
  if ($script:FailedPhase -and $Seg -eq 'S03Cp2') { $script:SegmentResults[-1].exit = 124; $script:SegmentResults[-1].effective_exit = 124 }
  if ($Seg -eq 'S03p3' -and -not $script:OmitPhaseSave) {
    $saves = Join-Path $script:GateRun 'S03p3/saves'
    New-Item -ItemType Directory -Force -Path $saves | Out-Null
    'physical phase save' | Set-Content (Join-Path $saves 'S03-exit.json')
  }
}
function Invoke-GodotRender([string[]]$ScriptAndArgs, [string]$LogFile, [int]$TimeoutSec, [string[]]$EngineFlags = @()) {
  Check ($ScriptAndArgs -contains 'tools/capture_diag_minimal.gd') 'Only the smoke boundary may invoke the fake renderer'
  'fixture smoke' | Set-Content (Join-Path (Split-Path -Parent $LogFile) 'capture_smoke.png')
  return 0
}
function Invoke-Proc([string]$Exe, [string[]]$Arguments, [string]$LogFile, [int]$TimeoutSec, [string]$WorkDir) {
  $script:AggregateCalls++
  $parent = $script:ExpectedParent
  $script:Order += $(if ($parent -eq 'S03') { 'aggregate' } else { 'aggregate:S03C' })
  Check ($Arguments.Count -eq 4 -and $Arguments[0] -eq (Join-Path $script:Repo 'tools/gate_f/aggregate_segment_phases.py') -and $Arguments[1] -eq $script:GateRun -and $Arguments[2] -eq '--parent' -and $Arguments[3] -eq $parent) 'Must invoke the existing strict aggregator with the exact run and parent'
  Check ($TimeoutSec -eq 120) 'Aggregation process must have a wall-clock bound'
  Check (-not (Test-Path (Join-Path $script:GateRun $parent))) 'Resume must preserve and remove stale canonical evidence before strict publication'
  if ($script:AggregateExit -eq 0) {
    $out = Join-Path $script:GateRun $parent
    New-Item -ItemType Directory -Path $out -Force | Out-Null
    @{ complete = (-not $script:BadInventory); steps = @{ total = 10; ran = 10; fail = 0; skipped = 0; refused = 0 } } |
      ConvertTo-Json -Depth 4 | Set-Content (Join-Path $out 'INVENTORY.json')
    if ($parent -eq 'S03' -and -not $script:OmitCanonicalSave) {
      New-Item -ItemType Directory -Path (Join-Path $out 'saves') -Force | Out-Null
      'verified save' | Set-Content (Join-Path $out 'saves/S03-exit.json')
    }
  }
  return $script:AggregateExit
}
try {
  New-Run 'clean'
  Phase-Chain
  Check (($script:Order -join ',') -eq 'S01,S02,S03p1,S03p2,S03p3,aggregate,S04,S05,S06,S07,S08,S09,S10a,S10b,S10c,S10d,S10e,S03C') 'Aggregate must occur after p3 and before S04; capture schedule remains last'
  Check ($script:AggregateCalls -eq 1) 'Clean chain aggregates once'
  $script:Order = @(); $script:SegmentResults = @()
  Phase-Chain
  Check (Test-Path (Join-Path $script:GateRun 'S03-superseded-1/INVENTORY.json')) 'Resume preserves old canonical evidence'
  Check ($script:AggregateCalls -eq 2) 'Resume revalidates phases instead of trusting old canonical inventory'
  foreach ($fault in @('AggregateExit', 'BadInventory', 'OmitPhaseSave', 'OmitCanonicalSave', 'FailedPhase')) {
    New-Run $fault
    if ($fault -eq 'AggregateExit') { $script:AggregateExit = 7 } else { Set-Variable -Scope Script -Name $fault -Value $true }
    $caught = ''
    try { Phase-Chain } catch { $caught = $_.Exception.Message }
    Check ($caught -match 'journey segments.*FAILED: S03') "$fault must fail the existing final verdict"
    Check ($script:Order -notcontains 'S04') "$fault must block S04"
    Check ($script:Order[-1] -eq 'S03C') "$fault must preserve capture scheduling"
    $record = Get-Content (Join-Path $script:GateRun 'S03/SEGMENT_RESULT.json') -Raw | ConvertFrom-Json
    Check ($record.effective_exit -ne 0) "$fault must persist an effective failure"
    if ($fault -eq 'AggregateExit') { Check ($record.process_exit -eq 7) 'Raw aggregator process exit is preserved' }
    if ($fault -eq 'BadInventory') { Check ($record.process_exit -eq 0) 'Zero process exit does not hide failed inventory' }
    if ($fault -eq 'OmitPhaseSave') { Check ($script:AggregateCalls -eq 0) 'Wrong/missing p3 canonical filename fails before invocation' }
    if ($fault -eq 'FailedPhase') { Check ($script:AggregateCalls -eq 0) 'Failed phase process cannot publish even with complete receipts' }
  }
  foreach ($phase in @('S03p1', 'S03p2', 'S03p3')) {
    $definition = Get-Content (Join-Path $PSScriptRoot "../tools/gate_f/segments/$phase.json") -Raw | ConvertFrom-Json
    $loadActions = @($definition.steps | Where-Object { $_._phase_added.kind -eq 'load' } | ForEach-Object { $_.action })
    $saveActions = @($definition.steps | Where-Object { $_._phase_added.kind -eq 'save' } | ForEach-Object { $_.action })
    if ($phase -ne 'S03p1') { Check ($loadActions -contains 'boot' -and $loadActions -contains 'press') 'Later phases must use authored physical Load actions' }
    if ($phase -ne 'S03p3') { Check ($saveActions -contains 'open_menu' -and $saveActions -contains 'select_menu_tab' -and $saveActions -contains 'press') 'Earlier phases must use authored physical Save actions' }
  }
  $script:Journey = @()
  $script:CaptureLanes = @('S03Cp1', 'S03Cp2', 'S03Cp3', 'S04C')
  foreach ($seg in $script:CaptureLanes) { '{}' | Set-Content (Join-Path $fixtureRoot "tools/gate_f/segments/$seg.json") }
  foreach ($fault in @('clean', 'AggregateExit', 'BadInventory', 'FailedPhase')) {
    New-Run "capture-$fault"
    $script:ExpectedParent = 'S03C'
    if ($fault -eq 'AggregateExit') { $script:AggregateExit = 9 }
    elseif ($fault -ne 'clean') { Set-Variable -Scope Script -Name $fault -Value $true }
    $caught = ''
    try { Phase-Chain } catch { $caught = $_.Exception.Message }
    Check ($script:Order[-1] -eq 'S04C') 'Capture aggregation failure must retain independent later lanes'
    Check (-not (Test-Path (Join-Path $script:GateRun 'S03C/saves'))) 'Terminal capture publication must not invent a save'
    $record = Get-Content (Join-Path $script:GateRun 'S03C/SEGMENT_RESULT.json') -Raw | ConvertFrom-Json
    Check ($record.capture -eq $true) 'Capture aggregation must remain capture evidence'
    Check (@($script:SegmentResults | Where-Object { -not $_.capture }).Count -eq 0) 'Capture phases must not contaminate journey results'
    if ($fault -eq 'clean') {
      Check ($caught -eq '' -and $record.effective_exit -eq 0) 'Terminal capture succeeds without a canonical exit save'
      Check (($script:Order -join ',') -eq 'S03Cp1,S03Cp2,S03Cp3,aggregate:S03C,S04C') 'Capture aggregation follows phase three'
      $script:SegmentResults = @(); $script:Order = @()
      Phase-Chain
      Check (Test-Path (Join-Path $script:GateRun 'S03C-superseded-1/INVENTORY.json')) 'Capture resume preserves old parent and revalidates'
    } else {
      Check ($caught -match 'capture lanes FAILED: S03C' -and $record.effective_exit -ne 0) 'Capture failure must reach the separate capture verdict'
    }
  }
  Write-Host "PASS: $script:Checks S03/S03C phase kickoff checks. Fixtures: $fixtureRoot"
} finally { $env:PYTHON = $savedPython }
