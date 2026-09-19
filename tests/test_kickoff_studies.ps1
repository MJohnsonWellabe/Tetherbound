# Execute production scheduling functions with fake segment boundaries; no Godot.
$ErrorActionPreference = 'Stop'
$tokens = $null; $errors = $null
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'tools/owner/kickoff.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
foreach ($name in @('Get-SegmentVerdict','Get-StudySchedule','Test-StudySplitCoverage','Get-StudyCheckpoint','Phase-Studies','Start-FrozenStudies')) {
  $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
  . ([scriptblock]::Create($node.Extent.Text))
}
$script:Checks = 0
function Check([bool]$ok, [string]$why) { $script:Checks++; if (-not $ok) { throw $why } }
function Log([string]$text) {}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('tetherbound-study-schedule-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
$script:Repo = $repo
$script:Sha = 'fixture-study-revision'
function Write-Provider([string]$Name, [string[]]$Saves, [bool]$Failed = $false) {
  $folder = Join-Path $script:GateRun $Name
  New-Item -ItemType Directory -Force -Path (Join-Path $folder 'saves') | Out-Null
  @{ segment=$Name; sha='inherited-fixture-prefix'; complete=$true;
    steps=@{total=1;ran=1;fail=$(if ($Failed) {1} else {0});skipped=0;refused=0} } |
    ConvertTo-Json -Depth 5 | Set-Content (Join-Path $folder 'INVENTORY.json')
  @{process_exit=0;effective_exit=$(if ($Failed) {1} else {0})} | ConvertTo-Json | Set-Content (Join-Path $folder 'SEGMENT_RESULT.json')
  foreach ($save in $Saves) { @{fixture=$Name;save=$save} | ConvertTo-Json | Set-Content (Join-Path $folder "saves/$save") }
}
function New-Run([string]$Name) {
  $script:GateRun = Join-Path $fixture $Name
  New-Item -ItemType Directory -Path $script:GateRun | Out-Null
  $script:Order = @(); $script:SegmentResults = @(); $script:Fail = ''
  foreach ($n in 2..9) { Write-Provider "S0$n" @("S0$n-exit.json") }
  Write-Provider 'S10e' @('S10-exit.json')
}
function Run-Segment([string]$Seg, [bool]$Capture, [bool]$Movie, [bool]$RequireCurrentRevision) {
  Check (-not $Movie) 'Studies must preserve real renderer cadence without Movie Maker'
  Check $RequireCurrentRevision 'Study reuse requires the current frozen revision and evidence lane'
  Check ($Capture -eq $Seg.EndsWith('C')) 'Only actual capture twins get capture mode'
  $script:Order += $Seg
  $definition = Get-Content (Join-Path $script:Repo "tools/gate_f/segments/$Seg.json") -Raw | ConvertFrom-Json
  $saves = @($definition.steps | Where-Object { $_.action -eq 'save_out' } | ForEach-Object { $_.args.name })
  Write-Provider $Seg $saves ($script:Fail -eq $Seg)
  $script:SegmentResults += @{seg=$Seg;effective_exit=$(if ($script:Fail -eq $Seg) {1} else {0});reasons=@();skipped=$false;capture=$Capture}
}
try {
  $schedule = @(Get-StudySchedule)
  Check ($schedule.Count -eq 16) 'Full studies require ten logic executions plus six actual capture twins'
  Check (($schedule.segment -join ',') -eq 'X01,X02,X03,X04,X06a,X06b,X06c,X05,X07,X08,X01C,X02C,X03C,X04C,X05C,X07C') 'X06 save producers must precede X05 consumers'
  $coverage = Test-StudySplitCoverage
  Check ($coverage.original_steps -eq 317 -and $coverage.repeated_load_steps -eq 10) 'Split must preserve all canonical X06 work plus exact load preamble'
  New-Run 'clean'
  $terminal = Get-StudyCheckpoint 'S10-exit.json'
  Check ($terminal.provider -eq 'S10e' -and $terminal.sha256.Length -eq 64) 'Canonical S10 save is owned by S10e and hashed'
  Phase-Studies
  Check (($script:Order -join ',') -eq ($schedule.segment -join ',')) 'All eligible studies and capture twins execute in explicit order'
  $receipt = Get-Content (Get-ChildItem $script:GateRun -Filter 'STUDY_SCHEDULE-*.json').FullName -Raw | ConvertFrom-Json
  Check ($receipt.complete -eq $true) 'Only clean individual verdicts complete the study schedule'
  Check (-not (Test-Path (Join-Path $script:GateRun 'X06/INVENTORY.json'))) 'No fake canonical X06 parent PASS is published'
  $x05 = @($receipt.results | Where-Object { $_.segment -eq 'X05' })[0]
  Check (@($x05.prerequisites | Where-Object { $_.provider -like 'X06*' }).Count -eq 5) 'X05 proves all five successful awkward save providers'

  New-Run 'failed-producer'
  $script:Fail = 'X06b'
  $failure = ''
  try { Phase-Studies } catch { $failure = $_.Exception.Message }
  Check ($failure -match 'incomplete') 'Failed studies must fail the phase'
  Check ($script:Order -notcontains 'X05') 'X05 must never launch from failed awkward-save producer'
  Check ($script:Order -contains 'X07C') 'Independent eligible capture lanes still execute'

  New-Run 'failed-journey'
  Write-Provider 'S03' @('S03-exit.json') $true
  try { Phase-Studies } catch {}
  Check ($script:Order -notcontains 'X01' -and $script:Order -notcontains 'X02' -and $script:Order -notcontains 'X06a') 'Failed checkpoint blocks every dependent study'
  Check ($script:Order -contains 'X03' -and $script:Order -contains 'X08') 'Unrelated valid checkpoints and DIAG remain independently schedulable'

  New-Run 'missing-save'
  Remove-Item -LiteralPath (Join-Path $script:GateRun 'S08/saves/S08-exit.json')
  $blocked = ''
  try { Get-StudyCheckpoint 'S08-exit.json' } catch { $blocked = $_.Exception.Message }
  Check ($blocked -match 'did not export') 'A successful inventory without actual save cannot seed studies'
  $blocked = ''
  try { Get-StudyCheckpoint 'arbitrary-fresh-save.json' } catch { $blocked = $_.Exception.Message }
  Check ($blocked -match 'No approved') 'No guessed fresh-save fallback'

  foreach ($case in @(
    @{name='root-shadow'; filename='S10-exit.json'; provider='S10e'; shadow='saves'},
    @{name='owner-shadow'; filename='S10-exit.json'; provider='S10e'; shadow='S10/saves'},
    @{name='fallback-shadow'; filename='S10-exit.json'; provider='S10e'; shadow='other/saves'},
    @{name='awkward-owner'; filename='X06-awkward-on-the-bridge.json'; provider='X06a'; shadow='X06-awkward-on-the-bridge/saves'},
    @{name='awkward-fallback'; filename='X06-awkward-on-the-bridge.json'; provider='X06a'; shadow='other/saves'},
    @{name='awkward-root'; filename='X06-awkward-on-the-bridge.json'; provider='X06a'; shadow='saves'}
  )) {
    New-Run $case.name
    if ($case.provider -eq 'X06a') { Write-Provider $case.provider @($case.filename) }
    $shadowDir = Join-Path $script:GateRun $case.shadow
    New-Item -ItemType Directory -Force -Path $shadowDir | Out-Null
    $shadow = Join-Path $shadowDir $case.filename
    'wrong bytes from another attempt' | Set-Content -LiteralPath $shadow
    $blocked = ''
    try { Get-StudyCheckpoint $case.filename } catch { $blocked = $_.Exception.Message }
    Check ($blocked -match 'Seed resolution conflict') "$($case.name) must reject different reachable seed bytes"
    Copy-Item -LiteralPath (Join-Path $script:GateRun "$($case.provider)/saves/$($case.filename)") -Destination $shadow
    $verified = Get-StudyCheckpoint $case.filename
    Check ($verified.resolution_candidates -contains $shadow) "$($case.name) must record the actual reachable candidate"
    Check ($verified.resolution_sha256 -ceq $verified.sha256) "$($case.name) identical bytes remain valid"
  }
  New-Run 'ignored-superseded'
  foreach ($folder in @('S10e-superseded-1', '.hidden')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $script:GateRun "$folder/saves") | Out-Null
    'rejected historical bytes' | Set-Content (Join-Path $script:GateRun "$folder/saves/S10-exit.json")
  }
  $verified = Get-StudyCheckpoint 'S10-exit.json'
  Check ($verified.resolution_candidates.Count -eq 1) 'Harness-excluded historical folders must not poison active fallback'

  $realRepo = $script:Repo
  $script:Repo = Join-Path $fixture 'wrong-provider-definition'
  New-Item -ItemType Directory -Force -Path (Join-Path $script:Repo 'tools/gate_f/segments') | Out-Null
  @{steps=@(@{action='save_out';args=@{name='different-exit.json'}})} | ConvertTo-Json -Depth 5 |
    Set-Content (Join-Path $script:Repo 'tools/gate_f/segments/S10e.json')
  $blocked = ''
  try { Get-StudyCheckpoint 'S10-exit.json' } catch { $blocked = $_.Exception.Message }
  finally { $script:Repo = $realRepo }
  Check ($blocked -match 'does not declare') 'Provider mapping must agree with actual authored save_out'

  $frozen = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Start-FrozenStudies' }, $true)
  $commands = @($frozen.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst]}, $true) | ForEach-Object { $_.GetCommandName() })
  foreach ($forbidden in @('Ensure-Repo','Import-Project','Publish-Evidence','Phase-Package','Ensure-Godot')) {
    Check ($commands -notcontains $forbidden) "Frozen studies must not run $forbidden"
  }
  Check ($frozen.Extent.Text -notmatch '& git .* (fetch|checkout|pull|reset|push)') 'Frozen path must not reflash or publish source'
  $script:FrozenRepo = Join-Path $fixture 'frozen-checkout'
  New-Item -ItemType Directory -Force -Path (Join-Path $script:FrozenRepo '.godot/imported') | Out-Null
  'fixture project source' | Set-Content (Join-Path $script:FrozenRepo 'project.godot')
  $sourceHash = (Get-FileHash (Join-Path $script:FrozenRepo 'project.godot')).Hash
  $script:FrozenRun = $script:GateRun
  $script:FrozenCalls = 0
  function git { $script:GitArgs = @($args); $global:LASTEXITCODE = 0; return 'frozen-fixture-sha' }
  function Phase-Studies {
    $script:FrozenCalls++
    Check ($script:Repo -eq $script:FrozenRepo) 'Frozen mode retains the explicit imported checkout'
    Check ($script:GateRun -eq $script:FrozenRun) 'Frozen mode retains the explicit existing GateRun'
    Check ($script:Sha -eq 'frozen-fixture-sha') 'Frozen studies record the read-only HEAD identity'
  }
  $oldGodot = $env:GODOT
  try {
    # Executable existence is checked, but this fake renderer is never launched.
    $env:GODOT = (Get-Process -Id $PID).Path
    Start-FrozenStudies $script:FrozenRun $script:FrozenRepo
    Check ($script:FrozenCalls -eq 1) 'Frozen entrypoint reaches only the study phase boundary'
    Check (($script:GitArgs -join ' ') -eq "-C $script:FrozenRepo rev-parse HEAD") 'Frozen entrypoint only reads git HEAD'
    Check ((Get-FileHash (Join-Path $script:FrozenRepo 'project.godot')).Hash -eq $sourceHash) 'Frozen source bytes remain unchanged'
  } finally { $env:GODOT = $oldGodot }
  Write-Output "PASS: $script:Checks study scheduler fixture assertions; no engine executed"
} finally {
  $resolved = [IO.Path]::GetFullPath($fixture)
  $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped temp root' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
}
