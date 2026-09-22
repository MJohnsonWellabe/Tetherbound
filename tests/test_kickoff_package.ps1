# Run with Windows PowerShell; uses disposable local repositories, never Godot/network.
$ErrorActionPreference = 'Continue'
$source = Join-Path $PSScriptRoot '../tools/owner/kickoff.ps1'
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$function = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Publish-Evidence' }, $true)
. ([scriptblock]::Create($function.Extent.Text))
$script:Messages = @()
function Log([string]$msg) { $script:Messages += $msg }
function Fixture-Git([string[]]$Arguments) {
  $output = & git.exe -C $script:Repo @Arguments 2>&1
  if ($LASTEXITCODE -ne 0) { throw "Fixture git failed: $Arguments : $output" }
  return $output
}
function Check([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('tetherbound-evidence-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'
function Setup([string]$name) {
  $script:Repo = Join-Path $fixtureRoot $name
  New-Item -ItemType Directory -Path $script:Repo | Out-Null
  Fixture-Git @('init', '-q', '-b', 'main') | Out-Null
  Fixture-Git @('config', 'user.name', 'Evidence Test') | Out-Null
  Fixture-Git @('config', 'user.email', 'test@localhost') | Out-Null
  New-Item -ItemType Directory -Path "$script:Repo/tools" | Out-Null
  'original' | Set-Content "$script:Repo/tools/unrelated.gdshader"
  '*.log', 'logs/', '*.uid', 'ralph/reports/OWNER-*/**/[!_]*.png', 'ralph/reports/**/*.jsonl', 'ralph/reports/**/*.csv' | Set-Content "$script:Repo/.gitignore"
  Fixture-Git @('add', '--', '.gitignore', 'tools/unrelated.gdshader') | Out-Null
  Fixture-Git @('commit', '-q', '-m', 'base') | Out-Null
  $script:Base = Fixture-Git @('rev-parse', 'HEAD')
  Fixture-Git @('sparse-checkout', 'set', 'tools') | Out-Null
  $remotePath = Join-Path $fixtureRoot "$name.git"
  & git.exe init --bare -q $remotePath
  if ($LASTEXITCODE) { throw 'Fixture bare init failed' }
  Fixture-Git @('remote', 'add', 'origin', $remotePath) | Out-Null
  $script:Stamp = $name
  $script:Evidence = Join-Path $script:Repo "ralph/reports/OWNER-KICKOFF-$Stamp"
  $script:GateRun = Join-Path $script:Repo "ralph/reports/gate-f-run-$Stamp-owner"
  New-Item -ItemType Directory -Force -Path "$script:Evidence/logs", "$script:Evidence/frames", "$script:GateRun/S01/shots" | Out-Null
  'report' | Set-Content "$script:Evidence/RUN_SUMMARY.md"
  'diagnostic' | Set-Content "$script:Evidence/kickoff.log"
  'diagnostic' | Set-Content "$script:Evidence/logs/import.log"
  'sheet' | Set-Content "$script:Evidence/frames/_sheet_example.png"
  'payload' | Set-Content "$script:Evidence/frames/frame.png"
  'report' | Set-Content "$script:GateRun/S01/result.md"
  'telemetry' | Set-Content "$script:GateRun/S01/events.jsonl"
  'route' | Set-Content "$script:GateRun/S01/route.csv"
  'sheet' | Set-Content "$script:GateRun/S01/_sheet_example.png"
  'payload' | Set-Content "$script:GateRun/S01/shots/frame.png"
  'unrelated change' | Set-Content "$script:Repo/tools/unrelated.gdshader"
  'uid' | Set-Content "$script:Repo/tools/generated.uid"
  $script:Messages = @()
  $script:FullPayload = $false
}
function Expect-Failure([string]$pattern) {
  $caught = ''
  try { Publish-Evidence } catch { $caught = $_.Exception.Message }
  Check ($caught -match $pattern) "Expected $pattern, got: $caught"
  Check (-not ($script:Messages -match '^PUSHED:')) 'Failure must never claim published evidence'
  Check ((Fixture-Git @('ls-remote', 'origin') | Out-String).Trim() -eq '') 'Failure must not publish a ref'
}
Setup 'sparse-success'
Publish-Evidence
$remoteSha = ((Fixture-Git @('ls-remote', 'origin', "refs/heads/owner-run/$Stamp")) -split '\s+')[0]
Check ($remoteSha -ne $script:Base) 'Remote must advance beyond code-only SHA'
$files = @(Fixture-Git @('diff-tree', '--no-commit-id', '--name-only', '-r', $remoteSha))
Check ($files.Count -eq 8) "Expected exactly eight report/telemetry/sheet files, got $($files.Count): $files"
Check (-not ($files -match 'frame.png|generated.uid|unrelated.gdshader')) 'Payload or unrelated change leaked into evidence'
Check (($files -match 'events.jsonl').Count -eq 1) 'Ignored protocol telemetry must be committed'
Check ((Fixture-Git @('branch', '--show-current')) -eq 'main') 'Original branch must be restored'
Check ((Get-Content "$script:Repo/tools/unrelated.gdshader") -eq 'unrelated change') 'Unrelated modification must survive'
Check (Test-Path "$script:Repo/tools/generated.uid") 'Unrelated generated file must survive'
Setup 'staged-unrelated'
Fixture-Git @('add', '--', 'tools/unrelated.gdshader') | Out-Null
Expect-Failure 'empty index'
Check ((Fixture-Git @('diff', '--cached', '--name-only')) -eq 'tools/unrelated.gdshader') 'Existing staged change must survive'
Setup 'commit-failure'
$hook = Join-Path $script:Repo '.git/hooks/pre-commit'
[IO.File]::WriteAllText($hook, "#!/bin/sh`nexit 1`n", (New-Object Text.UTF8Encoding($false)))
Expect-Failure 'Evidence commit failed'
Check ((Fixture-Git @('rev-parse', 'HEAD')) -eq $script:Base) 'Commit failure must not advance HEAD'
Setup 'staging-failure'
Remove-Item -LiteralPath (Join-Path $script:Evidence 'kickoff.log')
Expect-Failure 'Failed to stage intended evidence files'
Check ((Fixture-Git @('rev-parse', 'HEAD')) -eq $script:Base) 'Staging failure must not create a commit'
Setup 'empty-evidence'
$reportPaths = @(
  "ralph/reports/OWNER-KICKOFF-$Stamp/RUN_SUMMARY.md",
  "ralph/reports/OWNER-KICKOFF-$Stamp/kickoff.log",
  "ralph/reports/OWNER-KICKOFF-$Stamp/logs/import.log",
  "ralph/reports/OWNER-KICKOFF-$Stamp/frames/_sheet_example.png",
  "ralph/reports/gate-f-run-$Stamp-owner/S01/result.md",
  "ralph/reports/gate-f-run-$Stamp-owner/S01/events.jsonl",
  "ralph/reports/gate-f-run-$Stamp-owner/S01/route.csv",
  "ralph/reports/gate-f-run-$Stamp-owner/S01/_sheet_example.png"
)
Fixture-Git (@('add', '--sparse', '-f', '--') + $reportPaths) | Out-Null
Fixture-Git @('commit', '-q', '-m', 'existing evidence') | Out-Null
Fixture-Git @('sparse-checkout', 'disable') | Out-Null
$script:Base = Fixture-Git @('rev-parse', 'HEAD')
Expect-Failure 'No evidence changes staged'
Check ((Fixture-Git @('rev-parse', 'HEAD')) -eq $script:Base) 'Empty evidence must not create a commit'
Setup 'branch-collision'
Fixture-Git @('branch', "owner-run/$Stamp") | Out-Null
Expect-Failure 'Cannot create evidence branch'
Check ((Fixture-Git @('branch', '--show-current')) -eq 'main') 'Branch creation failure must leave main checked out'
Write-Host "PASS: sparse publication, payload policy, unrelated work preservation, staging failure, commit failure, empty evidence and branch collision. Fixtures: $fixtureRoot"




