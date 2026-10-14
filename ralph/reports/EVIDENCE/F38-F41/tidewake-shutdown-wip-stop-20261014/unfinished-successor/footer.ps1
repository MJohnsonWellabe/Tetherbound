$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
$ExpectedSource=[string]$Job.source_commit
if($Job.schema -cne 'codex.tidewake-full-scene-shutdown.v2' -or $Job.job_id -cne 'twshutdown-successor-r1' -or $Job.supervisor_sha256 -cne (Hash-File $PSCommandPath) -or $Admission.job_sha256 -cne (Hash-File $JobPath)){throw 'Exact job/supervisor binding required'}
foreach($Binding in $Job.packet_bindings){Assert-Hash $Binding.path $Binding.sha256}
if($Job.steps.Count -ne 2){throw 'Exactly one parser and one capture required'}
$ExpectedParser=@('--headless','--path',$Stage,'--check-only','--script','tools/capture_tidewake_f13_5.gd')
$ExpectedOutput=Join-Path $OutputRoot ('run-'+$Job.job_id)
$CaptureDir=($ExpectedOutput.Replace('\','/')+'/images/off-shore-diagnostic')
$ExpectedCapture=@('--path',$Stage,'--rendering-method','forward_plus','--resolution','1920x1080','--script','tools/capture_tidewake_f13_5.gd','--','--preset=Medium',('--source-sha='+$ExpectedSource),'--camera-set=res://tools/visual_judge/camera_sets/F39-look.json','--views=shore-day',('--out='+$CaptureDir),'--capture-size=1920x1080','--trace-native-teardown')
if($Job.steps[0].kind -cne 'parser' -or $Job.steps[0].wall_seconds -ne 60 -or ($Job.steps[0].args -join "`n") -cne ($ExpectedParser -join "`n")){throw 'Exact parser60s required'}
if($Job.steps[1].kind -cne 'capture' -or $Job.steps[1].wall_seconds -ne 180 -or ($Job.steps[1].args -join "`n") -cne ($ExpectedCapture -join "`n") -or $Job.steps[1].capture_directory -cne $CaptureDir){throw 'Exact one-view capture180s required'}
if($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha){throw 'Engine pin differs'}
if([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.packet_bytes -ne $PacketCap){throw 'Resource caps differ'}
if($CpuPacketFixture){
    if($Job.status -cne 'BASELINE_DEFERRED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false){throw 'CPU fixture requires disabled admission'}
    'CPU packet structure PASS; no engine, stage or lease accessed.'
    exit 0
}
if($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.reviewed_by_thread -cne $ExpectedThread){throw 'Explicit root admission required'}
Assert-CollectorReady
if($ExpectedSource -cnotmatch '^[0-9a-f]{40}$'){throw 'Final baseline not bound'}
Assert-Source; Assert-Hash $Engine $EngineSha
Assert-Resources $true; Assert-NoForeignEngine
if((Get-RunBytes $ArtifactDir) -gt $PacketCap){throw 'Packet exceeds16MiB'}
$RunDir=[string]$Job.output_directory
if([IO.Path]::GetFullPath($RunDir) -cne [IO.Path]::GetFullPath($ExpectedOutput) -or (Test-Path -LiteralPath $RunDir)){throw 'Output must be exact fresh path'}
if(-not (Test-Path -LiteralPath $OwnerLockPath -PathType Leaf)){throw 'Owner lock file missing'}
# The outer finally owns lock release even when preflight fails before a child exists.
$Receipt=$null;$ReceiptPath=$null
try {
    $script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    Capture-LeaseSource (Read-Owner)
    Assert-Source;Assert-NoForeignEngine;Assert-Resources $true
    New-Item -ItemType Directory -Path $RunDir | Out-Null
    $ReceiptPath=Join-Path $RunDir 'receipt.json'
    $Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;incoming_owner_source=$script:IncomingLeaseSource;engine_sha256=$EngineSha;started_utc=[DateTime]::UtcNow.ToString('o');steps=@();limits=$Job.caps}
    Write-JsonAtomic $ReceiptPath $Receipt
    foreach($Step in $Job.steps){Run-Step $Step;$Receipt.steps=@($script:StepReceipts);Write-JsonAtomic $ReceiptPath $Receipt}
    $Receipt.status='EXITED_ZERO_AWAITING_REVIEW';$Receipt.ended_utc=[DateTime]::UtcNow.ToString('o');$Receipt.total_output_bytes=Get-RunBytes $RunDir
    Write-JsonAtomic $ReceiptPath $Receipt
} catch {
    $FailureMessage=$_.Exception.Message
    if($Receipt){
        if($script:CurrentStepId -and -not $Receipt.failed_step){
            try {
                $FailExit=if($script:Proc -and $script:Proc.HasExited){[int]$script:Proc.ExitCode}else{-1}
                $FailReason=if($script:ObservedStopReason){[string]$script:ObservedStopReason}else{$FailureMessage}
                Write-FailedStepReceipt $script:CurrentStepId 'unknown' $FailExit $FailReason (Read-TerminalMetrics)
            }catch{$Receipt.failed_step=$script:CurrentStepId;$Receipt.stop_reason=$_.Exception.Message}
        }
        $Receipt.status='FAILED';$Receipt.failure=$FailureMessage;$Receipt.steps=@($script:StepReceipts);$Receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
        try{Write-JsonAtomic $ReceiptPath $Receipt}catch{}
    }
    throw
} finally {
    if($script:Proc -and -not $script:Proc.HasExited){
        try{Stop-OwnedProcess 'failure cleanup'}catch{if($Receipt){$Receipt.cleanup_blocked=$_.Exception.Message}}
    }
    # Preserve a mismatch lease even if its original process happened to exit.
    if($script:LeaseOwned -and -not $script:IdentityRejected -and ((-not $script:Proc) -or $script:Proc.HasExited)){
        try{Assert-NoForeignEngine;Update-Owner $true $script:LeasePid $script:LeaseRun;$script:LeaseOwned=$false}catch{if($Receipt){$Receipt.cleanup_blocked=$_.Exception.Message}}
    }
    if($script:LeaseOwned -and $Receipt){$Receipt.lease_retained_for_live_or_unverified_child=$true}
    if($script:Proc -and $script:Proc.HasExited -and -not $script:DrainAttempted){
        try{Complete-LogDrain}catch{if($Receipt){$Receipt.cleanup_blocked=$_.Exception.Message}}
    }
    if($script:DrainCancellation){$script:DrainCancellation.Cancel();$script:DrainCancellation.Dispose()}
    if($script:OutStream){$script:OutStream.Dispose()};if($script:ErrStream){$script:ErrStream.Dispose()}
    if($script:Proc){$script:Proc.Dispose()}
    if($Receipt){try{Write-JsonAtomic $ReceiptPath $Receipt}catch{}}
    if($script:OwnerLock){$script:OwnerLock.Dispose()}
}
