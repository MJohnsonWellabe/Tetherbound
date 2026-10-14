$ErrorActionPreference='Stop'
$Runner=Join-Path $PSScriptRoot 'run_meadows_look.ps1';$Tokens=$null;$Errors=$null
$Ast=[Management.Automation.Language.Parser]::ParseFile($Runner,[ref]$Tokens,[ref]$Errors)
if($Errors.Count){throw ($Errors|Out-String)}
$Names=@('Initialize-PreflightReader','Invoke-BoundedSourceProcess')
$Nodes=$Ast.FindAll({param($N) $N -is [Management.Automation.Language.FunctionDefinitionAst] -and $N.Name -in $Names},$true)
foreach($Node in $Nodes){Invoke-Expression $Node.Extent.Text}
$Python='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$Results=[Collections.Generic.List[object]]::new()
function Reject([string]$Name,[string]$Code,[int]$Budget,[string]$Expected) {
 $Clock=[Diagnostics.Stopwatch]::StartNew();$Failure=$null
 try{$null=Invoke-BoundedSourceProcess $Python @('-c',$Code) $Budget}catch{$Failure=$_.Exception.Message}
 if(-not $Failure -or $Failure -notlike ('*'+$Expected+'*')){throw "$Name failed to reject: $Failure"}
 if($Clock.ElapsedMilliseconds -gt 4000){throw "$Name cleanup exceeded bounded fixture allowance"}
 $Results.Add(@{case=$Name;status='PASS_REJECTED';elapsed_ms=$Clock.ElapsedMilliseconds;reason=$Failure})
}
Initialize-PreflightReader
$Text=Invoke-BoundedSourceProcess $Python @('-c','print("ok")') 3000
if($Text.Trim() -cne 'ok'){throw 'Successful child output differs'}
$Results.Add(@{case='successful bounded child';status='PASS'})
Reject 'stalled checker' 'import time;time.sleep(10)' 100 'deadline'
Reject 'late zero exit' 'import time;time.sleep(.3)' 80 'deadline'
Reject 'output cap' 'import sys;sys.stdout.write("x"*2000000);sys.stdout.flush()' 3000 'cap'
Reject 'nonzero checker' 'import sys;print("fixture failure",file=sys.stderr);sys.exit(3)' 3000 'fixture failure'
# Bounded drain when a descendant inherits the child's redirected handles.
Reject 'inherited pipe never closes' 'import subprocess,sys;subprocess.Popen([sys.executable,"-c","import time;time.sleep(2.8)"]);print("parent exits")' 150 'drain timeout'
# Descendant self-exits within 2.8 seconds; no orphan long-lived fixture.
$Receipt=@{status='PASS';stage_access=$false;engine_launch=$false;cases=$Results.ToArray()}
$Receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'cpu-bounded-source-results.json') -Encoding utf8
$Receipt|ConvertTo-Json -Depth 8
