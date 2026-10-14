$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'root-transition/operation_budget.ps1')
. (Join-Path $PSScriptRoot 'root-transition/owner_publication.ps1')
$Budget=[pscustomobject]@{Timer=[pscustomobject]@{Elapsed=[pscustomobject]@{TotalSeconds=60.0}};WorkSeconds=115.0;TotalSeconds=120.0;CleanupDeadline=$null}
if((Get-OperationWaitMs $Budget 120000) -ne 55000){throw 'Child was not limited to aggregate remaining'}
$Budget.Timer.Elapsed.TotalSeconds=114
if((Get-OperationWaitMs $Budget 120000) -ne 1000){throw 'Cumulative work remaining differs'}
$Budget.Timer.Elapsed.TotalSeconds=115
$Rejected=0
try{Assert-OperationBudget $Budget;throw 'Accepted expired work'}catch{if($_.Exception.Message -notlike '*Aggregate operation*'){throw};$Rejected++}
if((Start-OperationCleanup $Budget) -ne 5){throw 'Cleanup reserve differs'}
$Budget.Timer.Elapsed.TotalSeconds=119
if((Start-OperationCleanup $Budget) -ne 1){throw 'Cleanup timer reset'}
$Budget.Timer.Elapsed.TotalSeconds=120
try{$null=Get-OperationWaitMs $Budget 5000 -Cleanup;throw 'Accepted cleanup overrun'}catch{if($_.Exception.Message -notlike '*Aggregate operation*'){throw};$Rejected++}

$Directory=Join-Path $PSScriptRoot ('cpu-owner-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Directory|Out-Null
$Path=Join-Path $Directory 'owner.json';$Marker=Join-Path $Directory 'completed-stage-marker.txt'
[IO.File]::WriteAllText($Marker,'PRESERVE COMPLETED STAGE')
$Initial=@{source='BASE';thread='ROOT';reserved=$true;allow_native_launch=$false;active_process_id=$null;active_session_id=$null;run_id=$null;processes=@();purpose='idle';updated_utc='before';unrelated='keep'}|ConvertTo-Json
$ReadImplementation=(Get-Command Read-OwnerSnapshot).ScriptBlock
$script:PendingChange=$null;$script:ChangedBytes=$null
function Read-OwnerSnapshot([string]$Path,$Budget){
 if($script:PendingChange){
  $Value=[IO.File]::ReadAllText($Path)|ConvertFrom-Json
  & $script:PendingChange $Value $Path
  $script:ChangedBytes=[IO.File]::ReadAllBytes($Path);$script:PendingChange=$null
 }
 return & $ReadImplementation $Path $Budget
}
$OwnerCases=@{
 source={param($v,$p)$v.source='OTHER';$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 thread={param($v,$p)$v.thread='OTHER';$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 reservation={param($v,$p)$v.reserved=$false;$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 authorization={param($v,$p)$v.allow_native_launch=$true;$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 pid={param($v,$p)$v.active_process_id=42;$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 session={param($v,$p)$v.active_session_id='new';$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 run={param($v,$p)$v.run_id='new';$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 processes={param($v,$p)$v.processes=@(@{pid=42});$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 unrelated={param($v,$p)$v.unrelated='changed';$v|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $p}
 whitespace={param($v,$p)[IO.File]::AppendAllText($p,"`n")}
}
foreach($Case in $OwnerCases.Keys){
 [IO.File]::WriteAllText($Path,$Initial);$Budget=New-OperationBudget
 $Original=Read-OwnerSnapshot $Path $Budget
 $script:PendingChange=$OwnerCases[$Case]
 $DidReject=$false
 try{$null=Publish-OwnerSnapshot $Path $Original 'BASE' 'TARGET' 'ROOT' $false $Budget}catch{$DidReject=$true}
 if(-not $DidReject){throw "Accepted intervening $Case"}
 if([Convert]::ToHexString([IO.File]::ReadAllBytes($Path)) -cne [Convert]::ToHexString($script:ChangedBytes)){throw "Stale overwrite after $Case"}
 if([IO.File]::ReadAllText($Marker) -cne 'PRESERVE COMPLETED STAGE'){throw 'Completed stage marker modified'}
 $Rejected++
}
[IO.File]::WriteAllText($Path,$Initial);$Budget=New-OperationBudget;$Original=Read-OwnerSnapshot $Path $Budget
$Published=Publish-OwnerSnapshot $Path $Original 'BASE' 'TARGET' 'ROOT' $false $Budget
$Actual=Read-OwnerSnapshot $Path $Budget
if($Actual.Sha256 -cne $Published.published_sha256 -or $Actual.Owner.source -cne 'TARGET' -or $Actual.Owner.unrelated -cne 'keep'){throw 'Valid owner publication differs'}
@{status='PASS_CPU_ONLY';budget_failure_cases=2;owner_intervening_changes=10;positive_publication=$true;completed_stage_marker_preserved=$true;stage_access=$false;engine_launched=$false}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'generic-guards-results.json') -Encoding utf8
'PASS: shared deadline/cleanup limits and ten intervening owner changes; no stale overwrite.'
