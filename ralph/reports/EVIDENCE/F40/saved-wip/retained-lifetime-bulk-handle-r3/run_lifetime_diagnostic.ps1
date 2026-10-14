#requires -Version 7.0
[CmdletBinding()] param([ValidateSet('bulk')][string]$Case='bulk',[switch]$RootAuthorized,[switch]$CpuPreflightFixture)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$Packet=$PSScriptRoot;$RunnerPath=$PSCommandPath;$JobPath=Join-Path $Packet 'diagnostic-request.json'
$PriorPacket=Join-Path (Split-Path -Parent $Packet) 'retained-lifetime-audit'
$PriorJobHash='40e0555c99b44872c0429cbdcf599e621dfa6f4bd462ae6fcc19c933788fea8f'
$PriorRunnerHash='60d5fc3fb49f701fb31ce031b9562aca42a755ca2502b8812031c1a34ddf8394'
$RootThread='01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource='645fd85aaf8e8341ddcedd6d3799600d3c7a2d9a'
$ExpectedDigest='755c6d60862dcef06337c93f085e8477645a3be9bba4b1a5b048ccc5e8b8c514'
$Engine='C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$EngineHash='b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8'
$OwnerPath='C:\CodexTemp\tetherbound-native-owner.json';$LockPath='C:\CodexTemp\tetherbound-native-owner.lock'
$Phases=@('baseline','submitted_inputs_live','callers_released','readback_live','readback_released','scalar_read_retained','resource_released')
$Job=Get-Content -LiteralPath $JobPath -Raw|ConvertFrom-Json -AsHashtable
# Verify all executable support bytes before dot-sourcing/compiling anything.
if($Job.schema -cne 'codex.cloudreach-lifetime.v1' -or $Job.source_under_audit -cne $ExpectedSource -or $Job.owner_thread -cne $RootThread -or $Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false){throw 'Frozen request identity mismatch'}
if($Job.runner_sha256 -cne (Get-FileHash -LiteralPath $RunnerPath -Algorithm SHA256).Hash.ToLowerInvariant()){throw 'Runner binding mismatch'}
$required=@('probe/project.godot','probe/lifetime_probe.gd','inherited_guards.ps1','lifetime_guards.ps1','owned_image.cs','watchdog_candidate.cs','identity_observation.ps1','identity_candidate.ps1','lifecycle_guards.ps1')
if($Job.files.Count -ne 9 -or (@($Job.files.path|Sort-Object) -join '|') -cne (@($required|Sort-Object) -join '|')){throw 'Executable binding list mismatch'}
foreach($binding in $Job.files){
 $boundPath=Join-Path $Packet $binding.path
 if((Get-FileHash -LiteralPath $boundPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $binding.sha256){throw 'Executable payload hash mismatch'}
}
. (Join-Path $Packet 'inherited_guards.ps1')
. (Join-Path $Packet 'lifetime_guards.ps1')
. (Join-Path $Packet 'identity_observation.ps1')
. (Join-Path $Packet 'lifecycle_guards.ps1')
NoReparse $Packet
foreach($binding in $Job.files){NoReparse (Join-Path $Packet $binding.path)}
AssertNoReservedAssignments ([IO.File]::ReadAllText($RunnerPath))
AssertNoReservedAssignments ([IO.File]::ReadAllText((Join-Path $Packet 'lifetime_guards.ps1')))
if($Job.engine_sha256 -cne $EngineHash -or $Job.engine_path.Replace('/','\') -cne $Engine -or $Job.max_wall_seconds_per_process -ne 60 -or $Job.maximum_processes_serial -ne 1 -or $Job.automatic_retries -ne 0 -or $Job.count -ne 135000 -or $Job.buffer_bytes -ne 6480000 -or $Job.verified_floats -ne 1620000 -or $Job.expected_digest -cne $ExpectedDigest -or ($Job.phases -join '|') -cne ($Phases -join '|')){throw 'Measurement constants changed'}
$caps=@{C_admission_bytes=10.5GB;C_stop_bytes=10GB;D_admission_bytes=21GB;D_stop_bytes=20GB;memory_floor_bytes=2GB;combined_logs_bytes=32MB;output_bytes=1GB}
Assert-Keys $Job.guards @($caps.Keys)
foreach($key in $caps.Keys){if($Job.guards[$key] -ne $caps[$key]){throw 'Resource caps changed'}}
if($Job.cases.Count -ne 1 -or ($Job.cases.id -join ',') -cne 'bulk'){throw 'Serial case order changed'}
foreach($spec in $Job.cases){
 $wantTarget='D:/CodexTemp/cloudreach-lifetime-645-'+$spec.id+'-r3'
 $wantRun=(Join-Path $Packet ('run-'+$spec.id+'-r3')).Replace('\','/')
 $wantArgs=@('--audio-driver','Dummy','--resolution','64x64','--rendering-method','forward_plus','--path',$wantTarget,'--script','lifetime_probe.gd','--',('--mode='+$spec.id))
 if($spec.project_directory -cne $wantTarget -or $spec.output_directory -cne $wantRun -or ($spec.args -join '|') -cne ($wantArgs -join '|')){throw 'Case path/argv changed'}
}
$CaseSpec=$Job.cases[0]
$Target=[string]$CaseSpec.project_directory;$Run=[string]$CaseSpec.output_directory
$AdmissionPath=Join-Path $Packet ('admission-'+$Case+'.json')
if($Job.predecessor_job_sha256 -cne $PriorJobHash -or $Job.predecessor_runner_sha256 -cne $PriorRunnerHash){throw 'Predecessor identity changed'}
$requiredPrior=@('diagnostic-request.json','run_lifetime_diagnostic.ps1','run-bulk-r1/receipt.json','run-setters-r1/receipt.json','run-setters-r1/independent-review.json','run-setters-r1/independent-agent-review.json')
if($Job.predecessor_bindings.Count -ne 6 -or (@($Job.predecessor_bindings.path|Sort-Object) -join '|') -cne (@($requiredPrior|Sort-Object) -join '|')){throw 'Predecessor binding list mismatch'}
foreach($binding in $Job.predecessor_bindings){$path=SafeChild $PriorPacket $binding.path;if((Hash $path) -cne $binding.sha256){throw 'Preserved predecessor evidence changed'}}
if($Job.mechanism_review_sha256 -cne 'bd680c80b498ca2f5b18152eeeeef8aec23a5bad803cfab3493bd5da78ecdadf'){throw 'Mechanism review binding differs'}
foreach($binding in $Job.additional_evidence_bindings){NoReparse $binding.path;if((Hash $binding.path) -cne $binding.sha256){throw 'Frozen R2/mechanism evidence differs'}}
if($CpuPreflightFixture){
 $a=Read-StrictJson $AdmissionPath
 if($a.status -cne 'NOT_ADMITTED' -or $a.launch_allowed -ne $false -or $a.job_sha256 -cne (Hash $JobPath) -or $a.runner_sha256 -cne (Hash $RunnerPath)){throw 'CPU preflight requires frozen unadmitted packet'}
 Write-Output "CPU_PACKET_PASS ${Case}: executable hashes, fixed argv, caps, count and phase order; no native paths accessed"
 exit 0
}
if(-not $RootAuthorized){throw 'Explicit root grant required'}
$a=Read-StrictJson $AdmissionPath;Assert-Admission $a $Case $CaseSpec
$prior=$null;if($Case -eq 'bulk'){$prior=Assert-Prior $a}
if((Hash $Engine) -cne $EngineHash){throw 'Locked engine hash mismatch'}
NoReparse $Target;NoReparse $Run;NoReparse $OwnerPath;NoReparse $LockPath
if((Test-Path -LiteralPath $Target) -or (Test-Path -LiteralPath $Run)){throw 'Fresh project/output required; no retries'}
if(-not(Test-Path -LiteralPath $LockPath -PathType Leaf)){throw 'Existing root owner lock required'}
Add-Type -Path @((Join-Path $Packet 'owned_image.cs'),(Join-Path $Packet 'watchdog_candidate.cs'))
. (Join-Path $Packet 'identity_candidate.ps1')
$lock=[IO.File]::Open($LockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$ImageLease=$null;$ChildStarted=$false;$OwnedExitConfirmed=$false;$OwnerBeforeBytes=$null;$OwnerBeforeText=$null
$proc=$null;$watchdog=$null;$claimed=$false;$receipt=$null;$failure=$null;$started=$null;$timer=$null
$script:OutStream=$null;$script:ErrStream=$null;$script:OutTask=$null;$script:ErrTask=$null;$script:LogCancellation=$null
function Check-Live {
 Assert-Deadline $timer.Elapsed.TotalMilliseconds
 if($watchdog.Expired){throw 'Independent 60 second watchdog expired'}
 $proc.Refresh();$exitedBeforeQuery=$proc.HasExited
 $imageProof=$null;$imageCallError=''
 try{$imageProof=$watchdog.QueryOwnedImage((Remaining-Ms $timer 1000))}catch{$imageCallError=$_.Exception.ToString()}
 $rows=@();$queryError=''
 try{$rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -OperationTimeoutSec 1)}catch{$queryError=$_.Exception.ToString()}
 $proc.Refresh()
 $observation=New-OwnedIdentityObservation $rows $proc.Id $started $PID $arguments $queryError ($exitedBeforeQuery -or $proc.HasExited) $imageProof
 $observation.owned_image_call_error=$imageCallError
 $observation.elapsed_ms=$timer.Elapsed.TotalMilliseconds
 $observation.process_has_exited_before_query=$exitedBeforeQuery
 Save-IdentityObservation $observation $IdentityDirectory $receipt (Join-Path $Run 'receipt.json')
 $receipt.observed_command_line=$rows[0].CommandLine
 Assert-NoForeign $proc.Id
 Assert-Deadline $timer.Elapsed.TotalMilliseconds
}
function Check-Bounds {
 if((Get-Item -LiteralPath $stdout).Length+(Get-Item -LiteralPath $stderr).Length -gt 32MB){throw '32 MiB log cap'}
 $bytes=0L
 foreach($directory in @($Run,$Target)){
  foreach($entry in Get-ChildItem -LiteralPath $directory -Recurse -Force){
   if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Output reparse entry'}
   if(-not $entry.PSIsContainer){$bytes+=$entry.Length}
  }
 }
 if($bytes -gt 1GB){throw '1 GiB combined output/project cap'}
}
function Take-Sample([int]$Index) {
 Check-Live
 $m=Metrics;$proc.Refresh()
 if($proc.HasExited){throw 'Sampler child exited'}
 $m.private_bytes=$proc.PrivateMemorySize64;$m.working_set_bytes=$proc.WorkingSet64
 $m.elapsed_ms=$timer.Elapsed.TotalMilliseconds;$m.pid=$proc.Id;$m.mode=$Case;$m.sequence=$Index
 $m.phase=if($Index -ge 0){$Phases[$Index]}else{'between-checkpoints'}
 AssertMetrics $m $false;Check-Bounds;Assert-Deadline $timer.Elapsed.TotalMilliseconds
 $receipt.samples+=,$m
 return $m
}
try{
 $OwnerBeforeBytes=[IO.File]::ReadAllBytes($OwnerPath);$OwnerBeforeText=[IO.File]::ReadAllText($OwnerPath)
 $owner=$OwnerBeforeText|ConvertFrom-Json;AssertIdle $owner;AssertMetrics (Metrics) $true
 $null=New-Item -ItemType Directory -Path $Target,$Run
 foreach($name in @('project.godot','lifetime_probe.gd')){
  $sourcePath=Join-Path $Packet ('probe/'+$name);$path=SafeChild $Target $name
  [IO.File]::WriteAllBytes($path,[IO.File]::ReadAllBytes($sourcePath))
  if((Hash $path) -cne (Hash $sourcePath)){throw 'Extracted payload changed'}
 }
 $IsolatedRunHome=Join-Path $Run 'home';$null=New-Item -ItemType Directory -Path $IsolatedRunHome
 $PhaseDirectory=Join-Path $IsolatedRunHome 'Godot/app_userdata/Cloudreach retained storage lifetime diagnostic/lifetime'
 $MeasurementDirectory=Join-Path $Run 'measurements';$null=New-Item -ItemType Directory -Path $MeasurementDirectory
 $IdentityDirectory=Join-Path $Run 'identity';$null=New-Item -ItemType Directory -Path $IdentityDirectory
 $stdout=Join-Path $Run 'stdout.log';$stderr=Join-Path $Run 'stderr.log'
 $receipt=@{status='RUNNING';case=$Case;source=$ExpectedSource;started_utc=[DateTime]::UtcNow.ToString('o');engine_sha256=$EngineHash;job_sha256=(Hash $JobPath);runner_sha256=(Hash $RunnerPath);project=$Target;isolated_home=$IsolatedRunHome;phase_directory=$PhaseDirectory;stdout=$stdout;stderr=$stderr;limits=$Job.guards;samples=@();checkpoints=@();identity_observations=@();scope=$Job.purpose;cleanup='PENDING';wall_seconds=$null;exit_code=$null}
 $receipt.owner_before_sha256=BytesHash $OwnerBeforeBytes
 [IO.File]::WriteAllBytes((Join-Path $Run 'owner-before.json'),$OwnerBeforeBytes)
 Replace-AtomicJson (Join-Path $Run 'receipt.json') $receipt
 $ImageLease=[CloudreachOwnedImage.ExecutableLease]::new($Engine,$EngineHash)
 $receipt.prelaunch_executable=@{path=$ImageLease.Path;sha256=$ImageLease.Sha256;file_lease_active=$ImageLease.Active}
 $owner.active_process_id=$PID;$owner.active_kind='isolated-cloudreach-lifetime';$owner.run_id="cloudreach-lifetime-$Case-r3";$owner.run_directory=$Run;$owner.processes=@();$owner.updated_utc=[DateTime]::UtcNow.ToString('o')
 Replace-AtomicJson $OwnerPath $owner;$claimed=$true
 $psi=[Diagnostics.ProcessStartInfo]::new($Engine);$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden;$psi.WorkingDirectory=$Target
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $arguments=[string[]]$CaseSpec.args;foreach($arg in $arguments){$psi.ArgumentList.Add($arg)}
 foreach($key in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','TEMP','TMP')){$psi.Environment[$key]=$IsolatedRunHome}
 $script:OutStream=[IO.File]::Open($stdout,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
 $script:ErrStream=[IO.File]::Open($stderr,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
 $script:LogCancellation=[Threading.CancellationTokenSource]::new()
 $timer=[Diagnostics.Stopwatch]::StartNew();$proc=[Diagnostics.Process]::Start($psi);$ChildStarted=$true
 $started=$proc.StartTime.ToUniversalTime();$receipt.pid=$proc.Id;$receipt.created_utc=$started.ToString('o');$receipt.arguments=$arguments
 $watchdog=[CloudreachHandleDeadline]::new($proc,(Remaining-Ms $timer 60000))
 $watchdog.BindImageLease($ImageLease)
 $script:OutTask=$proc.StandardOutput.BaseStream.CopyToAsync($script:OutStream,$script:LogCancellation.Token)
 $script:ErrTask=$proc.StandardError.BaseStream.CopyToAsync($script:ErrStream,$script:LogCancellation.Token)
 $owner.processes=@(@{pid=$proc.Id;created_utc=$started.ToString('o');engine=$Engine});Replace-AtomicJson $OwnerPath $owner
 $next=0
 while(-not $proc.HasExited){
  if($next -eq 7){
   if($watchdog.WaitOwnedExit(100)){break}
   Assert-Deadline $timer.Elapsed.TotalMilliseconds
   if($watchdog.Expired){throw 'Independent watchdog expired before exit'}
   AssertMetrics (Metrics) $false;Check-Bounds
   continue
  }
  Check-Live;Assert-CompletedFiles $PhaseDirectory $next $receipt.checkpoints
  $phasePath=Join-Path $PhaseDirectory ('{0:00}.json' -f $next)
  if($next -lt 7 -and (Test-Path -LiteralPath $phasePath)){
   $phaseTimer=[Diagnostics.Stopwatch]::StartNew()
   $record=Read-StrictJson $phasePath;Assert-Phase $record $next $proc.Id $Case
   $phaseInfo=Get-Item -LiteralPath $phasePath
   if($phaseInfo.LastWriteTimeUtc -lt $started -or $phaseInfo.LastWriteTimeUtc -gt [DateTime]::UtcNow.AddSeconds(1)){throw 'Stale/future phase file'}
   if($next -gt 0 -and $record.ticks_ms -le $receipt.checkpoints[-1].record.ticks_ms){throw 'Nonmonotonic phase clock'}
   $phaseHash=Hash $phasePath;$held=@()
   for($sampleIndex=0;$sampleIndex -lt 3;$sampleIndex++){
    if($sampleIndex -gt 0){Start-Sleep -Milliseconds 100}
    Assert-Deadline $phaseTimer.Elapsed.TotalMilliseconds 4500
    $held+=,(Take-Sample $next)
    if((Hash $phasePath) -cne $phaseHash){throw 'Phase changed during hold'}
    Assert-CompletedFiles $PhaseDirectory $next $receipt.checkpoints
   }
   Assert-Samples $held $next $proc.Id $Case
   Assert-Deadline $phaseTimer.Elapsed.TotalMilliseconds 4500
   $measurementPath=Join-Path $MeasurementDirectory ('{0:00}.samples.json' -f $next)
   Write-AtomicJson $measurementPath @{samples=$held;phase_sha256=$phaseHash;process_created_utc=$started.ToString('o');observed_command_line=$receipt.observed_command_line}
   Check-Live
   $ack=@{pid=$proc.Id;sequence=$next;mode=$Case};Assert-Ack $ack $next $proc.Id $Case
   $ackPath=Join-Path $PhaseDirectory ('{0:00}.ack.json' -f $next)
   Assert-Deadline $phaseTimer.Elapsed.TotalMilliseconds 4500
   Write-AtomicJson $ackPath $ack
   $receipt.checkpoints+=,@{record=$record;phase=@{path=$phasePath;sha256=$phaseHash};ack=@{path=$ackPath;sha256=(Hash $ackPath)};measurements=@{path=$measurementPath;sha256=(Hash $measurementPath)}}
   $next++
   Replace-AtomicJson (Join-Path $Run 'receipt.json') $receipt
  }else{
   $null=Take-Sample -1
   Start-Sleep -Milliseconds 100
  }
  $proc.Refresh()
 }
 if($next -ne 7){throw 'Missing checkpoint or ACK before exit'}
 Assert-CompletedFiles $PhaseDirectory 7 $receipt.checkpoints
 $OwnedExitConfirmed=$watchdog.WaitOwnedExit((Remaining-Ms $timer))
 if(-not $OwnedExitConfirmed -or $proc.ExitCode -ne 0 -or $watchdog.Expired){throw 'No timely natural zero exit'}
 Complete-Logs (Remaining-Ms $timer)
 Assert-Deadline $timer.Elapsed.TotalMilliseconds
 $receipt.wall_seconds=$timer.Elapsed.TotalSeconds;$receipt.exit_code=$proc.ExitCode
 if(-not $receipt.ContainsKey('observed_command_line')){throw 'No live process identity observation'}
 AssertMetrics (Metrics) $false
 if((Get-Item $stdout).Length+(Get-Item $stderr).Length -gt 32MB){throw 'Final log cap'}
 if((Get-Item $stderr).Length -ne 0){throw 'Nonempty stderr'}
 $receipt.storage=Assert-Storage ([IO.File]::ReadAllText($stdout)) $proc.Id $Case $receipt.checkpoints
 Check-Bounds;Assert-Deadline $timer.Elapsed.TotalMilliseconds
 foreach($name in @('project.godot','lifetime_probe.gd')){if((Hash (Join-Path $Target $name)) -cne (Hash (Join-Path $Packet ('probe/'+$name)))){throw 'Payload changed during execution'}}
 foreach($entry in Get-ChildItem -LiteralPath $Target -Recurse -Force){
  if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Project reparse entry'}
  $relative=[IO.Path]::GetRelativePath($Target,$entry.FullName).Replace('\','/')
  if(-not $entry.PSIsContainer -and $relative -notin @('project.godot','lifetime_probe.gd') -and -not $relative.StartsWith('.godot/')){throw 'Unexpected isolated project file'}
 }
 if($Case -eq 'bulk'){
  if($receipt.storage.buffer_sha256 -cne $prior.storage.buffer_sha256){throw 'Case digest mismatch'}
  $receipt.setters_receipt_sha256=$a.setters_receipt_sha256;$receipt.setters_review_sha256=$a.setters_review_sha256
 }
 $receipt.memory_scope='Held samples only, not exact peaks. Allocator/driver retention or reuse can make private/working-set deltas inconclusive; a flat getter delta does not disprove a CPU cache. No full-world headroom or finishing-subphase attribution.'
 $receipt.status='EXITED_ZERO_AWAITING_REVIEW'
}catch{
 $failure=$_.Exception.Message
 if($receipt){$receipt.status='FAILED';$receipt.failure=$failure}
}finally{
 $cleanupProblem=$null
 # Only an explicit wait on the started child's owned handle establishes exit.
 # Neither Process.HasExited nor Dispose is used as release authorization.
 try{
  if($ChildStarted){
   if($watchdog){
    $OwnedExitConfirmed=$watchdog.WaitOwnedExit(0)
    if(-not $OwnedExitConfirmed){
     $receipt.owned_stop_requested=$true
     $receipt.owned_stop_api_success=$watchdog.RequestOwnedStop()
     $OwnedExitConfirmed=$watchdog.WaitOwnedExit(5000)
    }
   }else{
    # Constructor/startup failure before watchdog attachment: Process.Start's
    # original process object still owns the handle; never reopen a PID.
    $OwnedExitConfirmed=$proc.WaitForExit(0)
    if(-not $OwnedExitConfirmed){$proc.Kill();$OwnedExitConfirmed=$proc.WaitForExit(5000)}
   }
  }
 }catch{$cleanupProblem=$_.Exception.Message}
 if($ChildStarted -and -not $OwnedExitConfirmed){
  $failure='Owned exit not confirmed after bounded stop; safety hold requires root attention'
  $receipt.status='QUARANTINED_EXIT_UNCONFIRMED';$receipt.failure=$failure
  $receipt.cleanup='Executable file lock, owner lease and original watchdog retained'
  $receipt.owned_exit_confirmed=$false
  # Reporting failures cannot unwind the hold and implicitly close live leases.
  try{Replace-AtomicJson (Join-Path $Run 'receipt.json') $receipt}catch{$cleanupProblem=$_.Exception.Message}
  try{Write-Output 'QUARANTINED_EXIT_UNCONFIRMED: root attention required; executable lock and owner lease retained; no retry'}catch{$cleanupProblem=$_.Exception.Message}
  # This exceptional safety hold is deliberately not a successful bounded run.
  # Returning would close the executable file lock without exit proof. Keep the
  # original deadline armed; no image-query retry, new process or stage action.
  # Root can inspect/terminate the owned child; each observation waits <=1s.
  while(-not $OwnedExitConfirmed){
   try{
    if($watchdog){$OwnedExitConfirmed=$watchdog.WaitOwnedExit(1000)}else{$OwnedExitConfirmed=$proc.WaitForExit(1000)}
   }catch{Start-Sleep -Milliseconds 1000}
  }
  $receipt.safety_hold_exit_confirmed_utc=[DateTime]::UtcNow.ToString('o')
 }
 if($receipt){$receipt.owned_exit_confirmed=$OwnedExitConfirmed;$receipt.child_started=$ChildStarted;$receipt.dispose_is_exit_evidence=$false}
 try{
  Assert-ExplicitOwnedExit $ChildStarted $OwnedExitConfirmed
  if($script:OutStream -or $script:ErrStream){Complete-Logs 5000 -Cancel}
 }catch{$cleanupProblem=$_.Exception.Message}
 # Disposal can retain references on timeout. It grants no release authority.
 if($watchdog -and $OwnedExitConfirmed){
  if($receipt){$receipt.watchdog_expired=$watchdog.Expired;$receipt.watchdog_termination_attempted=$watchdog.TerminationAttempted}
  $watchdog.Dispose()
 }
 if($ImageLease){
  Assert-ExplicitOwnedExit $ChildStarted $OwnedExitConfirmed
  $ImageLease.Dispose()
  if($receipt){$receipt.executable_lease_released_after_exit_or_no_child=$true}
 }
 if($receipt){
  if($timer){$receipt.total_supervisor_seconds=$timer.Elapsed.TotalSeconds}
  if($OwnedExitConfirmed){$receipt.exit_code=$proc.ExitCode}
  $receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
  foreach($name in @('stdout','stderr')){if(Test-Path -LiteralPath $receipt[$name]){$receipt[$name+'_sha256']=Hash $receipt[$name]}}
 }
 if($claimed){
  try{
   Assert-ExplicitOwnedExit $ChildStarted $OwnedExitConfirmed
   $foreign=@(Get-CimInstance Win32_Process -OperationTimeoutSec 1|Where-Object {$_.Name -match '^(Godot.*|Blender.*)\.exe$'}).Count -gt 0
   Assert-Releasable ($ChildStarted -and -not $OwnedExitConfirmed) $foreign $true
   $currentOwner=[IO.File]::ReadAllText($OwnerPath)
   Assert-OwnerRestoration $OwnerBeforeText $currentOwner "cloudreach-lifetime-$Case-r3" $PID
   if($cleanupProblem){throw $cleanupProblem}
   Restore-OwnerBytes $OwnerPath $OwnerBeforeBytes $ChildStarted $OwnedExitConfirmed
   $receipt.owner_after_sha256=Hash $OwnerPath;$receipt.owner_restored_byte_identical=$true
   $receipt.cleanup='Owned exit confirmed; original current-stage owner restored byte-identically'
  }catch{$cleanupProblem=$_.Exception.Message}
 }
 if($cleanupProblem){$failure=$cleanupProblem;if($receipt){$receipt.status='FAILED';$receipt.cleanup_blocked=$cleanupProblem}}
 if($failure -and $receipt){$receipt.status='FAILED';$receipt.failure=$failure}
 if($receipt){Replace-AtomicJson (Join-Path $Run 'receipt.json') $receipt}
 $lock.Dispose()
 if($proc -and $OwnedExitConfirmed){$proc.Dispose()}
}
if($failure){throw $failure}
