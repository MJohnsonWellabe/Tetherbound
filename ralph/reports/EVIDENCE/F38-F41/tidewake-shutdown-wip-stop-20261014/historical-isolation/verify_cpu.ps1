$ErrorActionPreference='Stop'
$Supervisor=Join-Path $PSScriptRoot 'supervisor/run_isolation.ps1'
$Tokens=$null;$ParseErrors=$null
$Ast=[Management.Automation.Language.Parser]::ParseFile($Supervisor,[ref]$Tokens,[ref]$ParseErrors)
if($ParseErrors.Count){throw ($ParseErrors | Out-String)}
# Load only named helpers. Never evaluate supervisor top level or Run-Step.
$Names=@('Write-JsonAtomic','Hash-File','Assert-Hash','Assert-Source','Complete-LogDrain','Assert-TerminalElapsed','Record-IdentityFailure','Assert-OwnedCim','Stop-OwnedProcess','Read-IsolationPhases','Assert-Resources')
foreach($Name in $Names){
 $Definition=@($Ast.FindAll({param($Node) $Node -is [Management.Automation.Language.FunctionDefinitionAst]},$true) | Where-Object Name -CEQ $Name)
 if($Definition.Count -ne 1){throw "Missing helper $Name"}
 Invoke-Expression $Definition[0].Extent.Text
}
$script:Checks=0
function Check([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message};$script:Checks++}
function MustFail([scriptblock]$Action,[string]$Pattern){$Failed=$false;try{& $Action | Out-Null}catch{$Failed=$_.Exception.Message -match $Pattern};Check $Failed "Expected failure: $Pattern"}
Assert-TerminalElapsed 60 60; Check $true 'boundary'
MustFail {Assert-TerminalElapsed 60.001 60} 'Terminal observed elapsed'
MustFail {Assert-TerminalElapsed ([double]::NaN) 60} 'Terminal observed elapsed'
$script:OutTask=[Threading.Tasks.Task]::CompletedTask;$script:ErrTask=[Threading.Tasks.Task]::CompletedTask
$script:DrainAttempted=$false;$script:DrainComplete=$false
Complete-LogDrain;Check $script:DrainComplete 'Completed streams drain'
$Pending=[Threading.Tasks.TaskCompletionSource[object]]::new()
$script:OutTask=$Pending.Task;$script:ErrTask=[Threading.Tasks.Task]::CompletedTask
$script:DrainAttempted=$false;$script:DrainComplete=$false
$Watch=[Diagnostics.Stopwatch]::StartNew()
MustFail {Complete-LogDrain} '5s bound';Check ($Watch.Elapsed.TotalSeconds -lt 7) 'Drain has finite deadline'
$Watch.Restart();MustFail {Complete-LogDrain} 'no unbounded/repeated retry';Check ($Watch.Elapsed.TotalSeconds -lt 1) 'Failed drain cannot restart timeout'
$Pending.SetResult($null)
$RunDir=Join-Path $PSScriptRoot 'cpu-evidence';New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$Engine='C:\pinned\Godot.exe';$script:RunnerPid=9000;$script:ProcId=9001;$script:ProcStartUtc=[DateTime]::UtcNow
$script:CommandLine='C:\pinned\Godot.exe --path isolated --script res://probe.gd';$script:ExpectedArgs=@('--path','isolated','--script','res://probe.gd')
$script:CurrentStepId='cpu-identity';$script:IdentityRejected=$false;$script:KillCalls=0
$script:Proc=[pscustomobject]@{HasExited=$false};$script:Proc | Add-Member ScriptMethod Kill {$script:KillCalls++}
$script:FixtureRows=@([pscustomobject]@{ProcessId=9001;ParentProcessId=9000;ExecutablePath=$Engine;CommandLine=$script:CommandLine;CreationDate=$script:ProcStartUtc})
function Get-CimInstance {param($ClassName,$Filter,$ErrorAction) return $script:FixtureRows}
$null=Assert-OwnedCim;Check (-not $script:IdentityRejected) 'Valid identity accepted'
$script:FixtureRows[0].CommandLine='changed command line'
MustFail {Assert-OwnedCim} 'command line changed'
$Evidence=Get-Content -LiteralPath (Join-Path $RunDir 'cpu-identity.identity-failure.json') -Raw | ConvertFrom-Json
Check ($Evidence.actual[0].command_line -ceq 'changed command line' -and $Evidence.expected.established_command_line -ceq $script:CommandLine) 'Actual and expected identity recorded'
MustFail {Stop-OwnedProcess 'fixture'} 'Identity rejected';Check ($script:KillCalls -eq 0) 'Mismatch refuses ambiguous termination'
$Expected=@('rendered_live_component','quit_requested','cover_tree_exited_before_delete','terrain_tree_exited_before_delete','root_tree_exited_before_delete','root_deleted_and_queue_flushed')
$Records=@();for($i=0;$i -lt $Expected.Count;$i++){$Records+=@{phase=$Expected[$i];ticks_usec=$i+1;regions=1;collision_shapes=1;map_rids_valid=$true;renderer='forward_plus';setup_failed=$false;explicit_free=$false;cover_alive_in_tree=$true;terrain_alive_in_tree=$true;rig_alive_in_tree=$true;cover=@{ready=$true;bound=$true;materials=4;map_bindings_match=$true;tile_nodes=148;grass_instances=32748;instances=47612}}}
$Lines=@($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)})
$Parsed=@(Read-IsolationPhases ($Lines -join "`n"));Check ($Parsed.Count -eq 6) 'Complete lifecycle accepted'
MustFail {Read-IsolationPhases ($Lines[0..4] -join "`n")} 'incomplete or duplicated'
$Records[0].cover.map_bindings_match=$false
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'Ground cover'
$Records[0].cover.map_bindings_match=$true
$Records[0].cover.instances=$Records[0].cover.grass_instances
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'Ground cover'
$Records[0].cover.instances=47612
$Records[1].cover_alive_in_tree=$false
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'still alive'
$Records[1].cover_alive_in_tree=$true
$Records[0].cover.tile_nodes=147
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'population differs'
$Records[0].cover.tile_nodes=148
$Records[2].Remove('ticks_usec')
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'timestamp missing'
$Records[2].ticks_usec=0
MustFail {Read-IsolationPhases (($Records | ForEach-Object {'TERRAIN DELETE ISOLATION '+($_ | ConvertTo-Json -Depth 8 -Compress)}) -join "`n")} 'timestamps reversed'
$Payload=Join-Path $RunDir 'payload';New-Item -ItemType Directory -Force -Path $Payload | Out-Null
[IO.File]::WriteAllText((Join-Path $Payload 'probe.txt'),'pinned')
$Job=[pscustomobject]@{project_template=$Payload;project_bindings=@([pscustomobject]@{path='probe.txt';sha256=(Hash-File (Join-Path $Payload 'probe.txt'))})};$Stage=Join-Path $RunDir 'absent-runtime'
Assert-Source;Check $true 'Pinned payload accepted'
[IO.File]::WriteAllText((Join-Path $Payload 'probe.txt'),'tampered')
MustFail {Assert-Source} 'SHA-256 mismatch'
$Job.project_bindings[0].path='../escape';MustFail {Assert-Source} 'escapes isolated root'
$CAdmissionFloor=10.5GB;$CStopFloor=10GB;$DAdmissionFloor=21GB;$DStopFloor=20GB;$MemoryFloor=2GB
$script:MinC=[long]::MaxValue;$script:MinD=[long]::MaxValue;$script:MinPhysical=[long]::MaxValue;$script:MinCommit=[long]::MaxValue
$script:FreeC=11GB;$script:FreeD=22GB;$script:Mem=@{physical=3GB;commit=3GB}
function Get-FreeBytes([string]$Drive){if($Drive -eq 'C'){return $script:FreeC};return $script:FreeD}
function Get-Memory {return $script:Mem}
$null=Assert-Resources $true;Check $true 'Healthy resources accepted'
$script:FreeD=20.99GB;MustFail {Assert-Resources $true} '21 GiB admission';$script:FreeD=22GB
$script:Mem.physical=1.99GB;MustFail {Assert-Resources $true} 'physical memory';$script:Mem.physical=3GB
$script:Mem.commit=1.99GB;MustFail {Assert-Resources $true} 'Commit headroom'
@{status='CPU_HELPERS_PASS';checks=$script:Checks;engine_launched=$false;scope='Helper logic only: terminal elapsed, bounded one-shot drain, actual/expected identity mismatch, fail-closed termination, lifecycle order, hash/path rejection, resource floors';independent_review='Pending root review; this is lane source/CPU verification'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $RunDir 'verification.json') -Encoding utf8
"CPU helper checks PASS: $script:Checks; no engine or OS process operations."
