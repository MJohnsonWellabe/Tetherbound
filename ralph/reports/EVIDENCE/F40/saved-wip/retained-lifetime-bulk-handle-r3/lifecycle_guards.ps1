function Assert-ExplicitOwnedExit([bool]$ChildStarted,[bool]$OwnedExitConfirmed) {
 if($ChildStarted -and -not $OwnedExitConfirmed){throw 'Owned exit unconfirmed: executable and owner leases must remain held'}
}
function Owner-ImmutableRecord([string]$Json) {
 $value=$Json|ConvertFrom-Json
 foreach($key in @('active_process_id','active_session_id','active_kind','run_id','run_directory','processes','updated_utc')){$value.PSObject.Properties.Remove($key)}
 return $value|ConvertTo-Json -Depth 30 -Compress
}
function Assert-OwnerRestoration([string]$Before,[string]$Current,[string]$RunId,[int]$RunnerPid) {
 $value=$Current|ConvertFrom-Json
 if($value.thread -cne $RootThread -or $value.run_id -cne $RunId -or $value.active_process_id -ne $RunnerPid){throw 'Owner lease identity changed: retain lease'}
 if((Owner-ImmutableRecord $Before) -cne (Owner-ImmutableRecord $Current)){throw 'Stage/owner metadata changed: refuse restoration'}
}
function Restore-OwnerBytes([string]$Path,[byte[]]$BeforeBytes,[bool]$ChildStarted,[bool]$OwnedExitConfirmed) {
 Assert-ExplicitOwnedExit $ChildStarted $OwnedExitConfirmed
 NoReparse $Path
 $temp=$Path+'.lifetime-restore.tmp';if(Test-Path -LiteralPath $temp){throw 'Stale owner restore temporary'}
 $stream=[IO.File]::Open($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($BeforeBytes);$stream.Flush($true)}finally{$stream.Dispose()}
 [IO.File]::Move($temp,$Path,$true)
 if((Hash $Path) -cne (BytesHash $BeforeBytes)){throw 'Owner bytes did not restore exactly'}
}
