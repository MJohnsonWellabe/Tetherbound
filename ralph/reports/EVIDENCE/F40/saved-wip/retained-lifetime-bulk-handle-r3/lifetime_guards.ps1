function Write-AtomicJson([string]$Path,$Value) {
 NoReparse $Path
 $temp=$Path+'.tmp'; if(Test-Path -LiteralPath $temp){throw 'Stale atomic temporary file'}
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Value|ConvertTo-Json -Depth 24 -Compress)+"`n")
 $stream=[IO.File]::Open($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($bytes);$stream.Flush($true)}finally{$stream.Dispose()}
 [IO.File]::Move($temp,$Path,$false)
}
function Replace-AtomicJson([string]$Path,$Value) {
 NoReparse $Path
 $temp=$Path+'.lifetime.tmp';if(Test-Path -LiteralPath $temp){throw 'Stale replacement temporary'}
 WriteJson $temp $Value;[IO.File]::Move($temp,$Path,$true)
}
function Read-StrictJson([string]$Path) {
 NoReparse $Path
 if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw 'Missing completed JSON file'}
 if((Get-Item -LiteralPath $Path).Length -gt 1MB){throw 'JSON file cap'}
 $raw=[IO.File]::ReadAllText($Path)
 return ConvertFrom-Json -InputObject $raw -AsHashtable -ErrorAction Stop
}
function Assert-Keys($Record,[string[]]$Keys) {
 if($Record -isnot [Collections.IDictionary] -or $Record.Count -ne $Keys.Count){throw 'Record schema mismatch'}
 foreach($key in $Keys){if(-not $Record.Contains($key)){throw "Missing key $key"}}
}
function Assert-Phase($Record,[int]$Index,[int]$ChildPid,[string]$Mode) {
 Assert-Keys $Record @('sequence','phase','mode','pid','ticks_ms','static_bytes','static_peak_bytes','resource_count','render_buffer_bytes','render_video_bytes')
 if($Index -lt 0 -or $Index -ge 7 -or $Record.sequence -ne $Index -or $Record.phase -cne $Phases[$Index] -or $Record.mode -cne $Mode -or $Record.pid -ne $ChildPid){throw 'Phase identity/order mismatch'}
 foreach($key in @('sequence','pid','ticks_ms','static_bytes','static_peak_bytes','resource_count','render_buffer_bytes','render_video_bytes')){
  $value=$Record[$key];if($value -isnot [ValueType] -or $value -is [bool] -or -not [double]::IsFinite([double]$value) -or [double]$value -lt 0 -or [double]$value -ne [math]::Floor([double]$value)){throw "Invalid phase number $key"}
 }
 if($Record.pid -le 0 -or $Record.static_peak_bytes -lt $Record.static_bytes){throw 'Invalid phase metrics'}
}
function Assert-Ack($Ack,[int]$Index,[int]$ChildPid,[string]$Mode) {
 Assert-Keys $Ack @('sequence','pid','mode')
 if($Ack.sequence -ne $Index -or $Ack.pid -ne $ChildPid -or $Ack.mode -cne $Mode){throw 'ACK identity mismatch'}
}
function Assert-Deadline([double]$Elapsed,[double]$Limit=60000) {
 if(-not [double]::IsFinite($Elapsed) -or $Elapsed -lt 0 -or $Elapsed -ge $Limit){throw 'Deadline exceeded'}
}
function Remaining-Ms($Timer,[int]$Maximum=5000) {
 Assert-Deadline $Timer.Elapsed.TotalMilliseconds
 return [int][math]::Max(0,[math]::Min($Maximum,[math]::Floor(60000-$Timer.Elapsed.TotalMilliseconds)))
}
function Assert-Identity($Row,[int]$ChildPid,[DateTime]$Started,[int]$ParentPid,[string[]]$Arguments) {
 if(-not $Row -or [int]$Row.ProcessId -ne $ChildPid -or $Row.ExecutablePath -ine $Engine -or [int]$Row.ParentProcessId -ne $ParentPid -or -not $Row.CreationDate){throw 'Owned process identity unavailable/mismatched'}
 if([math]::Abs(($Row.CreationDate.ToUniversalTime()-$Started).TotalMilliseconds) -gt 1000){throw 'Owned process start mismatch'}
 $tail=' '+($Arguments -join ' ')
 if($Row.CommandLine -cne ('"'+$Engine+'"'+$tail) -and $Row.CommandLine -cne ($Engine+$tail)){throw 'Observed argv mismatch'}
}
function Assert-CleanupIdentity([bool]$Live,[bool]$ExactHandle,[bool]$ExactStart,[bool]$ExactImage) {
 if($Live -and (-not $ExactHandle -or -not $ExactStart -or -not $ExactImage)){throw 'Refusing ambiguous live child cleanup; retain lease'}
}
function Assert-Releasable([bool]$Live,[bool]$Foreign,[bool]$LeaseMatches) {
 if($Live -or $Foreign -or -not $LeaseMatches){throw 'Cleanup uncertain; retain lease'}
}
function Assert-NoForeign([int]$ChildPid=0) {
 $native=@(Get-CimInstance Win32_Process -OperationTimeoutSec 1|Where-Object {$_.Name -match '^(Godot.*|Blender.*)\.exe$' -and $_.ProcessId -ne $ChildPid})
 if($native.Count){throw 'Foreign native process active'}
}
function Assert-CompletedFiles([string]$Directory,[int]$Next,$History) {
 if(-not(Test-Path -LiteralPath $Directory)){return}
 NoReparse $Directory
 foreach($item in Get-ChildItem -LiteralPath $Directory -Force){
  if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Invalid phase directory entry'}
  if($item.Name -notmatch '^(0[0-6])\.(json|tmp|ack\.json|ack\.json\.tmp)$'){throw 'Unknown/duplicate phase file'}
  $number=[int]$Matches[1];$suffix=$Matches[2]
  if($number -gt $Next -or ($number -eq $Next -and $suffix.StartsWith('ack'))){throw 'Out-of-order phase or unsolicited ACK'}
  if($number -lt $Next -and $suffix -notin @('json','ack.json')){throw 'Stale phase temporary'}
 }
 for($i=0;$i -lt $Next;$i++){
  foreach($field in @('phase','ack')){
   $binding=$History[$i][$field];if(-not(Test-Path -LiteralPath $binding.path) -or (Hash $binding.path) -cne $binding.sha256){throw 'Missing/modified completed phase or ACK'}
  }
 }
}
function Assert-Samples($Samples,[int]$Index,[int]$ChildPid,[string]$Mode) {
 if(@($Samples).Count -ne 3){throw 'Exactly three held samples required'}
 for($i=0;$i -lt 3;$i++){
  $s=$Samples[$i]
  if($s.sequence -ne $Index -or $s.pid -ne $ChildPid -or $s.mode -cne $Mode -or $s.phase -cne $Phases[$Index]){throw 'Held sample identity mismatch'}
  foreach($key in @('private_bytes','working_set_bytes','C','D','physical','commit','elapsed_ms')){
   if(-not $s.Contains($key) -or $s[$key] -isnot [ValueType] -or $s[$key] -is [bool] -or -not [double]::IsFinite([double]$s[$key]) -or [double]$s[$key] -lt 0){throw 'Missing/invalid sample metric'}
  }
  AssertMetrics $s $false
  if($i -gt 0 -and ($s.elapsed_ms-$Samples[$i-1].elapsed_ms) -lt 100){throw 'Held samples not separated by 100 ms'}
 }
}
function Assert-Storage([string]$Text,[int]$ChildPid,[string]$Mode,$History) {
 if($Text -match '(?im)WARNING:|ERROR:|SCRIPT ERROR|shader[^\r\n]*error|compilation failed|llvmpipe|swiftshader|Microsoft Basic Render|software raster|headless'){throw 'Forbidden diagnostics/software renderer'}
 if($Text -notmatch '(?im)(Vulkan|Direct3D)[^\r\n]*Using Device'){throw 'Actual hardware banner missing'}
 $records=[regex]::Matches($Text,'(?m)^CLOUDREACH_LIFETIME_RESULT (\{[^\r\n]+\})\r?$')
 if($records.Count -ne 1){throw 'Missing/duplicate lifetime result'}
 $r=$records[0].Groups[1].Value|ConvertFrom-Json -AsHashtable
 if($r.mode -cne $Mode -or $r.count -ne 135000 -or $r.buffer_bytes -ne 6480000 -or $r.verified_floats -ne 1620000 -or $r.buffer_sha256 -cne $ExpectedDigest){throw 'Lifetime count/digest mismatch'}
 if($r.elapsed_ms -lt 0 -or $r.elapsed_ms -gt 45000 -or $r.samples.Count -ne 7 -or @($History).Count -ne 7){throw 'Lifetime timing/checkpoint mismatch'}
 for($i=0;$i -lt 7;$i++){
  Assert-Phase $r.samples[$i] $i $ChildPid $Mode
  $stored=Read-StrictJson $History[$i].phase.path;Assert-Phase $stored $i $ChildPid $Mode
  foreach($key in $stored.Keys){if($r.samples[$i][$key] -cne $stored[$key]){throw 'Final result differs from held phase'}}
  Assert-Ack (Read-StrictJson $History[$i].ack.path) $i $ChildPid $Mode
  $held=Read-StrictJson $History[$i].measurements.path
  Assert-Samples $held.samples $i $ChildPid $Mode
  foreach($field in @('phase','ack','measurements')){if((Hash $History[$i][$field].path) -cne $History[$i][$field].sha256){throw 'Checkpoint binding changed'}}
 }
 return $r
}
function Assert-Admission($Admission,[string]$Mode,$CaseSpec) {
 if($Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.case -cne $Mode -or $Admission.root_thread -cne $RootThread -or $Admission.job_sha256 -cne (Hash $JobPath) -or $Admission.runner_sha256 -cne (Hash $RunnerPath) -or $Admission.actual_isolated_target -cne $CaseSpec.project_directory -or $Admission.actual_output_directory -cne $CaseSpec.output_directory){throw 'Exact case admission missing'}
 AssertFresh $Admission.admitted_utc
}
function Assert-Prior($Admission) {
 $priorDir=Join-Path $PriorPacket 'run-setters-r1'
 $priorPath=Join-Path $priorDir 'receipt.json';$reviewPath=Join-Path $priorDir 'independent-review.json'
 $prior=Read-StrictJson $priorPath;$review=Read-StrictJson $reviewPath
 if($Admission.setters_receipt_sha256 -cne (Hash $priorPath) -or $Admission.setters_review_sha256 -cne (Hash $reviewPath)){throw 'Separate bulk admission must pin reviewed setters receipt'}
 if($review.status -cne 'PASS_LIFETIME_SETTERS_ONLY' -or $review.reviewed_by_thread -cne $RootThread -or $review.receipt_sha256 -cne (Hash $priorPath)){throw 'Setters independent review missing'}
 if($prior.status -cne 'EXITED_ZERO_AWAITING_REVIEW' -or $prior.case -cne 'setters' -or $prior.source -cne $ExpectedSource -or $prior.job_sha256 -cne $PriorJobHash -or $prior.runner_sha256 -cne $PriorRunnerHash -or $prior.engine_sha256 -cne $EngineHash -or $prior.cleanup -cne 'Owned process drained; root lease idle' -or $prior.exit_code -ne 0 -or $prior.wall_seconds -ge 60){throw 'Setters receipt identity/result/cleanup mismatch'}
 foreach($name in @('stdout','stderr')){if((Hash $prior[$name]) -cne $prior[$name+'_sha256']){throw 'Setters log changed'}}
 if((Get-Item -LiteralPath $prior.stderr).Length -ne 0){throw 'Setters stderr nonempty'}
 $null=Assert-Storage ([IO.File]::ReadAllText($prior.stdout)) $prior.pid 'setters' $prior.checkpoints
 return $prior
}
function Complete-Logs([int]$BudgetMs,[switch]$Cancel) {
 if($BudgetMs -lt 0 -or $BudgetMs -gt 5000){throw 'Drain budget out of bounds'}
 $drain=[Diagnostics.Stopwatch]::StartNew()
 if($Cancel -and $script:LogCancellation){$script:LogCancellation.Cancel()}
 $tasks=@($script:OutTask,$script:ErrTask|Where-Object {$null -ne $_})
 $problem=$null
 try{if($tasks.Count -and -not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]$tasks,$BudgetMs)){throw 'Bounded log copy timeout'}}catch{$problem=$_.Exception.Message}
 $disposals=@();foreach($stream in @($script:OutStream,$script:ErrStream)){if($stream){$disposals+=,$stream.DisposeAsync().AsTask()}}
 $remaining=[int][math]::Max(0,$BudgetMs-[math]::Ceiling($drain.Elapsed.TotalMilliseconds))
 if($disposals.Count -and -not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]$disposals,$remaining)){throw 'Bounded log disposal timeout'}
 $script:OutStream=$null;$script:ErrStream=$null
 if(@($tasks|Where-Object {-not $_.IsCompleted}).Count){throw 'Log copies incomplete'}
 $script:OutTask=$null;$script:ErrTask=$null
 if($script:LogCancellation){$script:LogCancellation.Dispose();$script:LogCancellation=$null}
 if($problem){throw $problem}
}
