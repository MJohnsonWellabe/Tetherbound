param([switch]$CpuStagePreflightFixture,[switch]$CpuPacketFixture)
$ErrorActionPreference = 'Stop'
$ArtifactDir = $PSScriptRoot
$JobPath = Join-Path $ArtifactDir 'native-job.json'
$AdmissionPath = Join-Path $ArtifactDir 'native-admission.json'
$Stage = 'C:\CodexTemp\tetherbound-native-service'
$OutputRoot = 'D:\tetherbound\.artifacts\s'
$OwnerPath = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource = '868a7b5c8c4d89483a85f2ce0f6c7c7bb2c558ee'
$ExpectedParent = '13e5bdfcf2156b9af8b5bee4ff1276b59515a79a'
$ExpectedBase = 'b9d7edeb7f18d7ca2192f018016d4126f1910f91'
$Engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$EngineSha = 'b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8'
$Git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\mingw64\bin\git.exe'
$CAdmissionFloor = 10.5GB
$CStopFloor = 10GB
$DAdmissionFloor = 21GB
$DStopFloor = 20GB
$MemoryFloor = 2GB
$CombinedLogsCap = 20MB
$OutputCap = 50MB
$PacketCap = 16MB
$script:OwnerLock = $null
$script:Proc = $null
$script:ProcId = $null
$script:ProcStartUtc = $null
$script:RunnerPid = [Diagnostics.Process]::GetCurrentProcess().Id
$script:CommandLine = $null
$script:OutStream = $null
$script:ErrStream = $null
$script:OutTask = $null
$script:ErrTask = $null
$script:LogCancellation = $null
$script:StepTimer = $null
$script:LeaseOwned = $false
$script:LeaseRun = $null
$script:LeasePid = 0
$script:CurrentStepId = $null
$script:ObservedStopReason = $null
$script:StepReceipts = @()
$script:LogPaths = @()
$script:MinPhysical = [long]::MaxValue
$script:MinCommit = [long]::MaxValue
$script:MinC = [long]::MaxValue
$script:MinD = [long]::MaxValue

function Read-Json([string]$Path) { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
function Write-JsonAtomic([string]$Path, $Value) {
    $Temp = "$Path.$([Guid]::NewGuid().ToString('N')).tmp"
    $Value | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $Temp -Encoding utf8
    [IO.File]::Move($Temp, $Path, $true)
}
function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Pinned file is missing: $Path" }
    if ((Hash-File $Path) -cne $Expected.ToLowerInvariant()) { throw "SHA-256 mismatch: $Path" }
}
function Invoke-Git([string[]]$GitArgs) {
    $OldLazy=$env:GIT_NO_LAZY_FETCH; $OldOptional=$env:GIT_OPTIONAL_LOCKS; $OldPrompt=$env:GIT_TERMINAL_PROMPT
    try { $env:GIT_NO_LAZY_FETCH='1'; $env:GIT_OPTIONAL_LOCKS='0'; $env:GIT_TERMINAL_PROMPT='0'; $Text=@(& $Git -C $Stage -c gc.auto=0 -c maintenance.auto=false -c gc.auto=0 -c maintenance.auto=false -c core.fsmonitor=false -c core.preloadindex=false @GitArgs 2>&1); $Code=$LASTEXITCODE }
    finally {
        if ($null -eq $OldLazy) { Remove-Item Env:GIT_NO_LAZY_FETCH -ErrorAction SilentlyContinue } else { $env:GIT_NO_LAZY_FETCH=$OldLazy }
        if ($null -eq $OldOptional) { Remove-Item Env:GIT_OPTIONAL_LOCKS -ErrorAction SilentlyContinue } else { $env:GIT_OPTIONAL_LOCKS=$OldOptional }
    }
    if ($null -eq $OldPrompt) { Remove-Item Env:GIT_TERMINAL_PROMPT -ErrorAction SilentlyContinue } else { $env:GIT_TERMINAL_PROMPT=$OldPrompt }
    if ($Code -ne 0) { throw "No-lazy-fetch Git command failed: $($GitArgs -join ' ')" }
    return $Text
}
function Get-FreeBytes([string]$Drive) {
    $Info=[IO.DriveInfo]::new("$Drive`:\")
    if (-not $Info.IsReady) { throw "Drive $Drive`: unavailable" }
    return [long]$Info.AvailableFreeSpace
}
function Get-Memory {
    $Os=Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $Mem=Get-CimInstance Win32_PerfRawData_PerfOS_Memory -ErrorAction Stop
    if ($null -eq $Os.FreePhysicalMemory -or $null -eq $Mem.CommitLimit -or $null -eq $Mem.CommittedBytes) { throw 'Physical or commit counters unavailable' }
    return @{physical=[long]$Os.FreePhysicalMemory*1024;commit=[long]$Mem.CommitLimit-[long]$Mem.CommittedBytes}
}
function Assert-Resources([bool]$Admission=$false) {
    $C=Get-FreeBytes 'C'; $D=Get-FreeBytes 'D'; $M=Get-Memory
    $script:MinC=[Math]::Min($script:MinC,$C); $script:MinD=[Math]::Min($script:MinD,$D)
    $script:MinPhysical=[Math]::Min($script:MinPhysical,[long]$M.physical); $script:MinCommit=[Math]::Min($script:MinCommit,[long]$M.commit)
    if ($script:CurrentStepKind -eq 'allocation-diagnostic' -and $script:CommandLine) { Write-ProcessMemorySample 'running' $M }
    if ($Admission -and $C -lt $CAdmissionFloor) { throw 'C: below 10.5 GiB admission reserve' }
    if ($C -lt $CStopFloor) { throw 'C: below 10 GiB stop floor' }
    if ($Admission -and $D -lt $DAdmissionFloor) { throw 'D: below 21 GiB admission reserve' }
    if ($D -lt $DStopFloor) { throw 'D: below 20 GiB stop floor' }
    if ($M.physical -lt $MemoryFloor) { throw 'Available physical memory below 2 GiB' }
    if ($M.commit -lt $MemoryFloor) { throw 'Commit headroom below 2 GiB' }
    return $M
}
function Get-EngineRows {
    return @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\.exe$' })
}
function Assert-NoForeignEngine([int]$AllowedPid=0) {
    $Rows=@(Get-EngineRows | Where-Object { [int]$_.ProcessId -ne $AllowedPid })
    if ($Rows.Count -gt 0) { throw ('Other engine process active: ' + (($Rows | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', ')) }
}
function Get-RunBytes([string]$Path) {
    [long]$Total=0
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    foreach ($File in Get-ChildItem -LiteralPath $Path -File -Force -Recurse) { $Total += [long]$File.Length }
    return $Total
}
function Get-CombinedLogBytes {
    [long]$Total=0
    foreach ($Path in $script:LogPaths) { if (Test-Path -LiteralPath $Path -PathType Leaf) { $Total += [long](Get-Item -LiteralPath $Path).Length } }
    return $Total
}
function Assert-CanonicalText([string]$Path,[string]$Expected) {
    if((Hash-File $Path) -ceq $Expected) { return }
    $Text=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false,$true)).Replace("`r`n","`n")
    $Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
    if($Hash -cne $Expected) { throw "Canonical source hash mismatch: $Path" }
}
function Assert-BoundFile($Binding,[string]$Root) {
    $Path=Join-Path $Root ([string]$Binding.path)
    if ($Binding.kind -ceq 'binary' -or $Binding.path -ceq 'addons/terrain_3d/bin/libterrain.windows.debug.x86_64.dll') {
        Assert-Hash $Path ([string]$Binding.sha256)
        if ((Get-Item -LiteralPath $Path).Length -ne [long]$Binding.bytes) { throw "Binary byte length differs: $Path" }
    } else { Assert-CanonicalText $Path ([string]$Binding.sha256) }
}
function Initialize-PreflightReader {
 if (-not ('MeadowsCappedReader' -as [type])) {
 Add-Type -TypeDefinition @"
using System; using System.IO; using System.Text; using System.Threading.Tasks;
public static class MeadowsCappedReader {
 public static async Task<string> Read(StreamReader reader, int cap) {
  var text = new StringBuilder(); var buffer = new char[4096]; int n;
  while ((n = await reader.ReadAsync(buffer,0,buffer.Length).ConfigureAwait(false)) != 0) {
   if (text.Length+n > cap) throw new IOException("Preflight output cap exceeded");
   text.Append(buffer,0,n);
  }
  return text.ToString();
 }
}
"@
 }
}
function Invoke-BoundedSourceProcess([string]$Program,[string[]]$Arguments,[int]$WallMs=45000) {
 Initialize-PreflightReader
 $Info=[Diagnostics.ProcessStartInfo]::new();$Info.FileName=$Program;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true
 $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
 foreach($Arg in $Arguments){$Info.ArgumentList.Add($Arg)}
 $P=[Diagnostics.Process]::new();$P.StartInfo=$Info;$Clock=[Diagnostics.Stopwatch]::StartNew();$Out=$null;$Err=$null
 try {
  if(-not $P.Start()){throw 'Preflight process start failed'}
  $Out=[MeadowsCappedReader]::Read($P.StandardOutput,1048576);$Err=[MeadowsCappedReader]::Read($P.StandardError,1048576)
  while(-not $P.HasExited){
   if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
   if($Out.IsFaulted -or $Err.IsFaulted){throw 'Preflight output reader failed or cap exceeded'}
   [Threading.Thread]::Sleep(20)
  }
  $Remaining=[int]($WallMs-$Clock.ElapsedMilliseconds)
  if($Remaining -le 0){throw 'Source preflight deadline exceeded'}
  if(-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($Out,$Err),[Math]::Min(2000,$Remaining))){throw 'Source preflight drain timeout'}
  if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
  $Stdout=$Out.Result;$Stderr=$Err.Result
  if($P.ExitCode -ne 0){throw ('Source preflight failed: '+$Stderr)}
  return $Stdout
 } finally {
  if($P.Id -and -not $P.HasExited){$P.Kill($true);$null=$P.WaitForExit(1000)}
  if($null -ne $Out -and $null -ne $Err){try{$null=[Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($Out,$Err),250)}catch{}}
  if($null -ne $Out){$P.StandardOutput.Close();$P.StandardError.Close()}
  $P.Dispose()
 }
}
function Assert-Source {
 Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Job.source_preflight.helper_sha256
 Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Job.source_preflight.contract_sha256
 $Text=Invoke-BoundedSourceProcess 'C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' @((Join-Path $ArtifactDir 'source_preflight.py'),$Stage,$JobPath,(Join-Path $ArtifactDir 'source-contract.json'))
 $Contract=Read-Json (Join-Path $ArtifactDir 'source-contract.json')
 $Result=$Text|ConvertFrom-Json
 if($Result.status -cne 'PASS' -or $Result.source -cne $ExpectedSource -or $Result.index_paths -ne $Contract.full_index_paths -or $Result.bindings -ne @($Job.source_bindings).Count -or $Result.materialized_files -lt @($Contract.materialize).Count){throw 'Incomplete bounded source audit'}
 $script:LastSourceAudit=$Result
}

function Read-Owner { Read-Json $OwnerPath }
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='stormwood_868a7b5c8c_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='stormwood_868a7b5c8c_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Stormwood scoped validation; process starting'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='stormwood_868a7b5c8c_capture_child'
    $Owner.processes=@(@{pid=$PidValue;kind='stormwood_868a7b5c8c_capture_child';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Stormwood scoped validation; owned child recorded'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeasePid=$PidValue
}
function Update-Owner([bool]$Release,[int]$PidValue=0,[string]$RunId='') {
    $Owner=Read-Owner
    if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) { throw 'Exact native lease authorization changed' }
    if ($Release) {
        if ([int]$Owner.active_process_id -ne $PidValue -or $Owner.run_id -cne $RunId) { throw 'Refusing to release another run lease' }
        $Owner.active_process_id=$null; $Owner.active_session_id=$null; $Owner.active_kind=$null; $Owner.processes=@(); $Owner.run_directory=$null; $Owner.run_id=$null
        $Owner.purpose='Service lane reserved; no native writer'; $Owner.source=$ExpectedSource
    } else {
        if ($Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Root lease is not idle' }
        $Owner.active_process_id=$PidValue; $Owner.active_session_id=$null; $Owner.active_kind='stormwood_868a7b5c8c_capture_child'
        $Owner.processes=@(@{pid=$PidValue;kind='stormwood_868a7b5c8c_capture_child'}); $Owner.run_id=$RunId
        $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Stormwood scoped validation'
    }
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o')
    Write-JsonAtomic $OwnerPath $Owner
}
function Assert-OwnedCim {
    if (-not $script:Proc) { throw 'No owned process handle' }
    if ($script:Proc.HasExited) { return $null }
    $Rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Rows.Count -ne 1) { $script:Proc.Refresh(); if ($script:Proc.HasExited) { return $null }; throw 'Owned live process CIM identity unavailable' }
    $Row=$Rows[0]
    if ([string]::IsNullOrWhiteSpace([string]$Row.ExecutablePath)) {
        $script:Proc.Refresh()
        if ($script:Proc.HasExited) { return $null }
        throw 'Owned live process executable identity unavailable; refusing termination'
    }
    if ([int]$Row.ParentProcessId -ne $script:RunnerPid -or [IO.Path]::GetFullPath([string]$Row.ExecutablePath) -cne [IO.Path]::GetFullPath($Engine) -or [string]$Row.CommandLine -cne $script:CommandLine) { throw 'Owned process parent, image or full command line changed; refusing termination' }
    $Creation=if ($Row.CreationDate -is [DateTime]) {$Row.CreationDate.ToUniversalTime()} else {[Management.ManagementDateTimeConverter]::ToDateTime([string]$Row.CreationDate).ToUniversalTime()}
    if ([Math]::Abs(($Creation-$script:ProcStartUtc).TotalSeconds) -gt 1.0) { throw 'Owned process creation time changed; refusing termination' }
    return $Row
}
function Stop-OwnedProcess([string]$Reason,[switch]$InjectFailureForCpuFixture) {
    if (-not $script:Proc -or $script:Proc.HasExited) { return }
    if ($InjectFailureForCpuFixture) { throw 'Injected Stop-OwnedProcess failure (CPU fixture only)' }
    # Before CIM readiness the held Process handle is the only trustworthy
    # identity; it came directly from this supervisor's Process.Start call.
    if (-not [string]::IsNullOrWhiteSpace([string]$script:CommandLine)) { $null=Assert-OwnedCim }
    if ($script:Proc.HasExited) { return }
    $script:Proc.Kill()
    if (-not $script:Proc.WaitForExit(10000) -and -not $script:Proc.HasExited) { throw "Owned process did not stop after $Reason" }
}
function Read-TerminalMetrics {
    $Snapshot=[ordered]@{observed_utc=[DateTime]::UtcNow.ToString('o')}
    try {
        $Snapshot.C_free_bytes=Get-FreeBytes 'C'; $Snapshot.D_free_bytes=Get-FreeBytes 'D'
        $M=Get-Memory; $Snapshot.physical_free_bytes=[long]$M.physical; $Snapshot.commit_headroom_bytes=[long]$M.commit
        $script:MinC=[Math]::Min($script:MinC,[long]$Snapshot.C_free_bytes)
        $script:MinD=[Math]::Min($script:MinD,[long]$Snapshot.D_free_bytes)
        $script:MinPhysical=[Math]::Min($script:MinPhysical,[long]$Snapshot.physical_free_bytes)
        $script:MinCommit=[Math]::Min($script:MinCommit,[long]$Snapshot.commit_headroom_bytes)
    } catch { $Snapshot.telemetry_error=$_.Exception.Message }
    return $Snapshot
}
function Write-FailedStepReceipt([string]$StepId,[string]$Kind,[int]$ExitCode,[string]$StopReason,$TerminalMetrics) {
    $StepReceipt=[ordered]@{id=$StepId;kind=$Kind;status='FAILED';pid=$script:ProcId;created_utc=if($script:ProcStartUtc){$script:ProcStartUtc.ToString('o')}else{$null};observed_command_line=$script:CommandLine;exit_code=$ExitCode;stop_reason=$StopReason;terminal_metrics=$TerminalMetrics;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD}
    if ($script:OutPath -and (Test-Path -LiteralPath $script:OutPath -PathType Leaf)) { $StepReceipt.stdout=$script:OutPath; $StepReceipt.stdout_sha256=Hash-File $script:OutPath }
    if ($script:ErrPath -and (Test-Path -LiteralPath $script:ErrPath -PathType Leaf)) { $StepReceipt.stderr=$script:ErrPath; $StepReceipt.stderr_sha256=Hash-File $script:ErrPath }
    $script:StepReceipts+=,$StepReceipt
    $Receipt.failed_step=$StepId; $Receipt.stop_reason=$StopReason; $Receipt.terminal_metrics=$TerminalMetrics
    $Receipt.failed_step_exit_code=$ExitCode; $Receipt.steps=@($script:StepReceipts); $Receipt.status='FAILED'
    $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
    try { $Receipt.total_output_bytes=Get-RunBytes $RunDir } catch { $Receipt.output_size_error=$_.Exception.Message }
    Write-JsonAtomic $ReceiptPath $Receipt
}
function Assert-TestOutput([string]$Stdout,$Step) {
    $Summaries=[regex]::Matches($Stdout,'(?m)^(\d+) test\(s\), (\d+) failed\r?$')
    if($Summaries.Count -ne 1 -or [int]$Summaries[0].Groups[1].Value -ne [int]$Step.expected_test_methods -or [int]$Summaries[0].Groups[2].Value -ne 0) { throw 'Single-file totals mismatch' }
    $Names=@([regex]::Matches($Stdout,'(?m)^  ok    (test_\w+)\r?$') | ForEach-Object {$_.Groups[1].Value})
    if($Names.Count -ne [int]$Step.expected_test_methods -or (($Names | Sort-Object) -join ',') -cne (($Step.expected_test_names | Sort-Object) -join ',') -or $Stdout -match '(?m)^\s*FAIL\s') { throw 'Missing, duplicate, extra or failing named method' }
    return @{tests=$Names.Count;failures=0;methods=$Names}
}
function Assert-TraceInteger($Value,[string]$Label) {
    if ($null -eq $Value -or $Value -is [bool] -or $Value -is [string] -or $Value -is [array]) { throw "Invalid integer: $Label" }
    $D=[double]$Value
    if ([double]::IsNaN($D) -or [double]::IsInfinity($D) -or $D -lt 0 -or $D -gt [long]::MaxValue -or [Math]::Floor($D) -ne $D) { throw "Invalid integer: $Label" }
}
function Assert-MemoryOutput([string]$Stdout,$Step) {
    $TraceMatches=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY (\{[^\r\n]*\})\r?$')
    $Lines=@($TraceMatches | ForEach-Object {$_.Groups[1].Value})
    $Prefixes=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY ').Count
    if ($Lines.Count -ne $Prefixes -or $Lines.Count -lt $Step.required_boundaries.Count -or $Lines.Count -gt 102) { throw 'Missing, malformed or excessive memory trace rows' }
    $Seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $Order=[Collections.Generic.List[string]]::new();$PreviousTicks=-1L
    for ($I=0;$I -lt $Lines.Count;$I++) {
        $Row=$Lines[$I] | ConvertFrom-Json
        if ($Row.source_commit -cne $ExpectedSource -or $Row.pid -ne $script:ProcId -or $Row.sequence -ne $I) { throw 'Trace source/PID/sequence mismatch' }
        foreach($Key in @('sequence','pid','ticks_ms','static_bytes','peak_static_bytes','objects','resources','nodes','render_video_bytes','render_texture_bytes','render_buffer_bytes')) { Assert-TraceInteger $Row.$Key $Key }
        if ($Row.ticks_ms -lt $PreviousTicks -or $Row.peak_static_bytes -lt $Row.static_bytes) { throw 'Trace time or static peak is inconsistent' }
        $PreviousTicks=[long]$Row.ticks_ms
        if ($null -eq $Row.unix_seconds -or $Row.unix_seconds -is [bool] -or $Row.unix_seconds -is [string] -or [double]::IsNaN([double]$Row.unix_seconds) -or [double]::IsInfinity([double]$Row.unix_seconds) -or [double]$Row.unix_seconds -le 0) { throw 'Invalid trace UTC epoch' }
        if ($null -eq $Row.system -or $Row.system -isnot [pscustomobject] -or @($Row.system.PSObject.Properties).Count -eq 0) { throw 'Missing system memory observation' }
        if ([string]::IsNullOrWhiteSpace([string]$Row.boundary) -or -not $Seen.Add([string]$Row.boundary)) { throw 'Duplicate/empty memory boundary' }
        if ($Row.boundary -cnotlike 'enter:*' -and $Row.boundary -cnotin @('before_mount','mount_returned','post_draw_1','post_draw_30','post_draw_60','quit_scheduled')) { throw 'Unknown completion boundary' }
        $Order.Add([string]$Row.boundary)
    }
    $Previous=-1
    foreach($Boundary in $Step.required_boundaries) {
        $At=$Order.IndexOf([string]$Boundary)
        if ($At -le $Previous) { throw 'Required production boundaries missing or reordered' }
        $Previous=$At
    }
    if ($Order[0] -cne 'before_mount' -or $Order[$Order.Count-1] -cne 'quit_scheduled') { throw 'Trace endpoints differ' }
    $MountReturned=$Order.IndexOf('mount_returned')
    for($I=0;$I -lt $Order.Count;$I++){if($Order[$I] -clike 'enter:*' -and ($I -le 0 -or $I -ge $MountReturned)){throw 'Entry outside mount interval'}}
    $Markers=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY_COMPLETE source=([^\r\n]+)\r?$')
    if($Markers.Count -ne 1 -or $Markers[0].Groups[1].Value -cne $ExpectedSource) { throw 'Completion marker missing or duplicated' }
    if($Markers[0].Index -le $TraceMatches[$TraceMatches.Count-1].Index){throw 'Completion marker precedes final trace boundary'}
    return @{rows=$Lines.Count;ordered_boundaries=$Order.ToArray();meaning='observations only; no allocation causation or visual acceptance'}
}
function Write-ProcessMemorySample([string]$Phase,$Memory) {
    if ($script:CurrentStepKind -ne 'allocation-diagnostic') { return }
    $Private=$null;$Working=$null;$Owned=0
    if ($Phase -eq 'running') {
        if ($script:Proc.HasExited) { $Phase='exit_observed' } else {
            $script:Proc.Refresh();$Private=[long]$script:Proc.PrivateMemorySize64;$Working=[long]$script:Proc.WorkingSet64
        }
        $Owned=[int]$script:ProcId
    }
    $Elapsed=if($script:StepTimer){[long]$script:StepTimer.ElapsedMilliseconds}else{0L}
    $Sample=[ordered]@{source_commit=$ExpectedSource;observed_utc=[DateTime]::UtcNow.ToString('o');elapsed_ms=$Elapsed;phase=$Phase;pid=$Owned;private_bytes=$Private;working_set_bytes=$Working;physical_free_bytes=[long]$Memory.physical;commit_headroom_bytes=[long]$Memory.commit}
    [IO.File]::AppendAllText($script:MemorySamplesPath,(($Sample|ConvertTo-Json -Compress)+"`n"),[Text.UTF8Encoding]::new($false))
}
function Assert-ExternalMemorySamples([string]$Path) {
    $Rows=@([IO.File]::ReadAllLines($Path)|ForEach-Object{$_|ConvertFrom-Json})
    if ($Rows.Count -lt 2 -or $Rows.Count -gt 512 -or $Rows[0].phase -cne 'pre_launch' -or $Rows[0].pid -ne 0) { throw 'Missing external prelaunch/process samples' }
    $Last=-1L;$Running=0;$Index=0;$Exited=$false
    foreach($Row in $Rows) {
        if($Row.source_commit -cne $ExpectedSource) { throw 'External sample source mismatch' }
        foreach($Key in @('elapsed_ms','pid','physical_free_bytes','commit_headroom_bytes')){Assert-TraceInteger $Row.$Key $Key}
        if([long]$Row.elapsed_ms -lt $Last) { throw 'External sample timer went backwards' };$Last=[long]$Row.elapsed_ms
        $Timestamp=[DateTimeOffset]::Parse([string]$Row.observed_utc)
        if ($Row.phase -eq 'running') {
            if($Exited){throw 'Live sample after exit observation'}
            if ($Row.pid -ne $script:ProcId) { throw 'External sample owned PID mismatch' }
            Assert-TraceInteger $Row.private_bytes 'private_bytes';Assert-TraceInteger $Row.working_set_bytes 'working_set_bytes';$Running++
        } elseif ($Row.phase -ceq 'pre_launch') {
            if($Index -ne 0 -or $Row.pid -ne 0 -or $null -ne $Row.private_bytes -or $null -ne $Row.working_set_bytes){throw 'Invalid repeated baseline'}
        } elseif ($Row.phase -ceq 'exit_observed') {
            if($Row.pid -ne $script:ProcId -or $null -ne $Row.private_bytes -or $null -ne $Row.working_set_bytes){throw 'Invalid exit sample'}
            $Exited=$true
        } else { throw 'Unknown external sample phase' }
        $Index++
    }
    if ($Running -lt 1) { throw 'No live owned-process memory sample' }
    return @{path=$Path;sha256=(Hash-File $Path);samples=$Rows.Count;running_samples=$Running;private_and_working_set='observed process counters; no causation inferred'}
}
function Assert-TerminalResources($Snapshot) {
    if($Snapshot.telemetry_error){throw 'Terminal resource telemetry unavailable'}
    foreach($Key in @('C_free_bytes','D_free_bytes','physical_free_bytes','commit_headroom_bytes')){Assert-TraceInteger $Snapshot.$Key $Key}
    if($Snapshot.C_free_bytes -lt $CStopFloor -or $Snapshot.D_free_bytes -lt $DStopFloor -or $Snapshot.physical_free_bytes -lt $MemoryFloor -or $Snapshot.commit_headroom_bytes -lt $MemoryFloor){throw 'Terminal resource floor breached'}
}

function Assert-StepIds($Steps) {
    $Seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($Item in $Steps) {
        if ([string]$Item.id -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
        if (-not $Seen.Add([string]$Item.id)) { throw 'Duplicate step id' }
    }
}
function Wait-BoundedTasks([Threading.Tasks.Task[]]$Tasks,[int]$TimeoutMs) {
    if ($TimeoutMs -lt 0) { throw 'Negative task wait budget' }
    if ($Tasks.Count -eq 0) { return }
    if (-not [Threading.Tasks.Task]::WaitAll($Tasks,$TimeoutMs)) { throw 'Bounded asynchronous log operation timed out' }
}
function Assert-StepDeadline([double]$ElapsedSeconds,[double]$CapSeconds) {
    if (-not [double]::IsFinite($ElapsedSeconds) -or -not [double]::IsFinite($CapSeconds) -or $ElapsedSeconds -lt 0 -or $CapSeconds -le 0 -or $ElapsedSeconds -ge $CapSeconds) {
        throw 'Terminal wall-clock cap reached'
    }
}
function Complete-LogDrain([int]$BudgetMs,[switch]$Cancel) {
    if ($BudgetMs -lt 0 -or $BudgetMs -gt 5000) { throw 'Log drain budget outside bounded range' }
    $DrainTimer=[Diagnostics.Stopwatch]::StartNew()
    if ($Cancel -and $script:LogCancellation) { $script:LogCancellation.Cancel() }
    $Tasks=@($script:OutTask,$script:ErrTask | Where-Object { $null -ne $_ })
    $DrainFailure=$null
    try { Wait-BoundedTasks $Tasks $BudgetMs } catch { $DrainFailure=$_.Exception.Message }
    # DisposeAsync never waits synchronously for a pending writer. All cleanup
    # operations share the same deadline, including failed/cancelled copies.
    $Disposals=@()
    foreach ($Stream in @($script:OutStream,$script:ErrStream)) {
        if ($Stream) { $Disposals+=,$Stream.DisposeAsync().AsTask() }
    }
    $Remaining=[Math]::Max(0,$BudgetMs-[int][Math]::Ceiling($DrainTimer.Elapsed.TotalMilliseconds))
    Wait-BoundedTasks $Disposals $Remaining
    $script:OutStream=$null; $script:ErrStream=$null
    if ($Tasks.Where({-not $_.IsCompleted}).Count -gt 0) { throw 'Log copies remain incomplete after bounded drain' }
    $script:OutTask=$null; $script:ErrTask=$null
    if ($script:LogCancellation) { $script:LogCancellation.Dispose(); $script:LogCancellation=$null }
    if ($DrainFailure) { throw $DrainFailure }
}

function Run-Step($Step) {
    $script:OutPath=$null; $script:ErrPath=$null; $script:CurrentStepId=[string]$Step.id; $script:CurrentStepKind=[string]$Step.kind; $script:ObservedStopReason=$null
    Assert-Resources
    Assert-NoForeignEngine
    $StepStartBytes=Get-RunBytes $RunDir
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir 'h0'
    if ($StepId -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
    New-Item -ItemType Directory -Path $HomeDir | Out-Null
    if ($Step.kind -eq 'allocation-diagnostic') {
    $ProjectText=[IO.File]::ReadAllText((Join-Path $Stage 'project.godot'))
    $ProjectNameMatch=[regex]::Match($ProjectText,'(?m)^config/name="([^"]+)"\s*$')
    if (-not $ProjectNameMatch.Success -or $ProjectNameMatch.Groups[1].Value -cne [string]$Job.graphics_overrides.project_name) { throw 'Pinned project name does not match isolated user:// plan' }
    if ($ProjectText -match '(?m)^config/use_custom_user_dir\s*=\s*true\s*$') { throw 'Custom Godot user directory is unsupported by this isolated override plan' }
    $GraphicsText=[IO.File]::ReadAllText((Join-Path $Stage 'scripts/ui/graphics_prefs.gd'))
    if ($GraphicsText -notmatch '(?m)^const OVERRIDE_PATH := "user://graphics_override\.cfg"\s*$') { throw 'Pinned graphics preferences do not use the expected graphics_override.cfg path' }
    if ([string]$Job.graphics_overrides.user_data_path_rule -cne '%APPDATA%\Godot\app_userdata\Tetherbound\graphics_override.cfg') { throw 'Job user-data override path rule changed' }
    $Profile=$Job.graphics_overrides.profiles.PSObject.Properties[[string]$Step.preset].Value
    if ($null -eq $Profile) { throw "No pinned graphics profile for $($Step.preset)" }
    $UserDataDir=Join-Path (Join-Path (Join-Path $HomeDir 'Godot') 'app_userdata') ([string]$Job.graphics_overrides.project_name)
    New-Item -ItemType Directory -Path $UserDataDir -Force | Out-Null
    $script:GraphicsOverridePath=Join-Path $UserDataDir 'graphics_override.cfg'
    if (Test-Path -LiteralPath $script:GraphicsOverridePath) { throw 'Isolated graphics override unexpectedly exists before provisioning' }
    Assert-Hash ([string]$Profile.source) ([string]$Profile.sha256)
    $OverrideText=[IO.File]::ReadAllText([string]$Profile.source)
    if ($OverrideText -notmatch ('(?m)^preset="'+[regex]::Escape([string]$Step.preset)+'"\s*$') -or $OverrideText -notmatch '(?m)^renderer/rendering_method="forward_plus"\s*$') { throw 'Pinned graphics override does not match requested preset and renderer' }
    Copy-Item -LiteralPath ([string]$Profile.source) -Destination $script:GraphicsOverridePath
    Assert-Hash $script:GraphicsOverridePath ([string]$Profile.sha256)
    }
    $OutPath=Join-Path $RunDir ($StepId+'.stdout.log'); $ErrPath=Join-Path $RunDir ($StepId+'.stderr.log')
    $script:OutPath=$OutPath; $script:ErrPath=$ErrPath
    $script:LogPaths+=@($OutPath,$ErrPath)
    $StepArgs=@($Step.args | ForEach-Object { [string]$_ })
    $StartInfo=[Diagnostics.ProcessStartInfo]::new(); $StartInfo.FileName=$Engine; $StartInfo.WorkingDirectory=$Stage
    $StartInfo.UseShellExecute=$false; $StartInfo.CreateNoWindow=$true; $StartInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $StartInfo.RedirectStandardOutput=$true; $StartInfo.RedirectStandardError=$true
    foreach ($Arg in $StepArgs) { $StartInfo.ArgumentList.Add($Arg) }
    foreach ($Name in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','TEMP','TMP')) { $StartInfo.Environment[$Name]=$HomeDir }
    $Proc=[Diagnostics.Process]::new(); $Proc.StartInfo=$StartInfo
    Claim-Owner $StepId
    $script:MemorySamplesPath=Join-Path $RunDir 'memory-samples.jsonl'
    if($Step.kind -eq 'allocation-diagnostic') { Write-ProcessMemorySample 'pre_launch' (Get-Memory) }
    $Timer=[Diagnostics.Stopwatch]::StartNew(); $script:StepTimer=$Timer
    if (-not $Proc.Start()) { throw "Godot failed to start $StepId" }
    $script:Proc=$Proc
    $script:ProcId=$Proc.Id; $script:ProcStartUtc=$Proc.StartTime.ToUniversalTime()
    Record-OwnedChild $script:ProcId $script:ProcStartUtc $StepId
    $OutStream=[IO.File]::Open($OutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:OutStream=$OutStream
    $ErrStream=[IO.File]::Open($ErrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:ErrStream=$ErrStream
    $script:LogCancellation=[Threading.CancellationTokenSource]::new()
    $OutTask=$Proc.StandardOutput.BaseStream.CopyToAsync($OutStream,81920,$script:LogCancellation.Token); $ErrTask=$Proc.StandardError.BaseStream.CopyToAsync($ErrStream,81920,$script:LogCancellation.Token)
    $script:OutTask=$OutTask; $script:ErrTask=$ErrTask
    $Initial=$null
    for ($Try=0; $Try -lt 20 -and -not $Initial; $Try++) {
        if ($Proc.HasExited) { break }
        $Rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
        if ($Rows.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace([string]$Rows[0].ExecutablePath) -and -not [string]::IsNullOrWhiteSpace([string]$Rows[0].CommandLine) -and $Rows[0].CreationDate) { $Initial=$Rows[0] } else { Start-Sleep -Milliseconds 100 }
    }
    if (-not $Initial) { Stop-OwnedProcess 'initial CIM readiness failed'; throw 'No complete initial CIM identity before startup timeout/exit' }
    $ObservedCommand=[string]$Initial.CommandLine
    $ExpectedSuffix=$StepArgs -join ' '
    $QuotedPrefix='"'+$Engine+'" '
    $PlainPrefix=$Engine+' '
    $ArgvMatches=($ObservedCommand.StartsWith($QuotedPrefix,[StringComparison]::Ordinal) -and $ObservedCommand.Substring($QuotedPrefix.Length) -ceq $ExpectedSuffix) -or ($ObservedCommand.StartsWith($PlainPrefix,[StringComparison]::Ordinal) -and $ObservedCommand.Substring($PlainPrefix.Length) -ceq $ExpectedSuffix)
    if ([int]$Initial.ParentProcessId -ne $script:RunnerPid -or [IO.Path]::GetFullPath([string]$Initial.ExecutablePath) -cne [IO.Path]::GetFullPath($Engine) -or -not $ArgvMatches) { Stop-OwnedProcess 'identity or argv verification failed'; throw 'Initial process parent, image or exact argv differs from job' }
    $InitTime=if ($Initial.CreationDate -is [DateTime]) {$Initial.CreationDate.ToUniversalTime()} else {[Management.ManagementDateTimeConverter]::ToDateTime([string]$Initial.CreationDate).ToUniversalTime()}
    if ([Math]::Abs(($InitTime-$script:ProcStartUtc).TotalSeconds) -gt 1.0) { Stop-OwnedProcess 'creation-time verification failed'; throw 'Initial CIM creation time differs from owned process handle' }
    $script:CommandLine=[string]$Initial.CommandLine
    $Before=Assert-Resources
    $StopReason=$null
    while (-not $Proc.HasExited) {
        try {
            Assert-Resources
            Assert-NoForeignEngine $script:ProcId
            $null=Assert-OwnedCim
            if ($Timer.Elapsed.TotalSeconds -ge [int]$Step.wall_seconds) { $StopReason='wall-clock cap reached'; break }
            $OutStream.Flush(); $ErrStream.Flush()
            if (((Get-RunBytes $RunDir)-$StepStartBytes) -gt [long]$Step.max_output_bytes) { $StopReason='step output/home cap reached'; break }
            $ActualLogBytes=Get-CombinedLogBytes
            if ($ActualLogBytes -gt $CombinedLogsCap) { $StopReason='stdout/stderr cap reached'; break }
            if ((Get-RunBytes $RunDir) -gt $OutputCap) { $StopReason='output/home cap reached'; break }
      } catch { $StopReason=$_.Exception.Message; $script:ObservedStopReason=$StopReason; break }
        Start-Sleep -Milliseconds 1000
    }
    if ($StopReason) { $script:ObservedStopReason=[string]$StopReason }
    if ($StopReason) { Stop-OwnedProcess $StopReason }
    if (-not $Proc.HasExited) { throw 'Owned process remained live after stop path' }
    Assert-StepDeadline $Timer.Elapsed.TotalSeconds ([double]$Step.wall_seconds)
    $DrainBudget=[int][Math]::Max(0,[Math]::Min(5000,[Math]::Floor(([double]$Step.wall_seconds-$Timer.Elapsed.TotalSeconds)*1000)))
    Complete-LogDrain $DrainBudget
    Assert-StepDeadline $Timer.Elapsed.TotalSeconds ([double]$Step.wall_seconds)
    $Exit=[int]$Proc.ExitCode
    $TerminalMetrics=Read-TerminalMetrics
    try { Assert-TerminalResources $TerminalMetrics } catch { if(-not $StopReason){$StopReason=$_.Exception.Message} }
    if ($Exit -ne 0 -or $StopReason) {
        $FailedReason=if($StopReason){[string]$StopReason}else{"process exited with code $Exit; stop cause not observed"}
        Write-FailedStepReceipt $StepId ([string]$Step.kind) $Exit $FailedReason $TerminalMetrics
        throw "Godot step $StepId failed: $FailedReason"
    }
    if ((Get-CombinedLogBytes) -gt $CombinedLogsCap) { throw 'Combined stdout/stderr exceeded cap after exit' }
    if ((Get-RunBytes $RunDir) -gt $OutputCap) { throw 'Run output exceeded cap after exit' }
    if (((Get-RunBytes $RunDir)-$StepStartBytes) -gt [long]$Step.max_output_bytes) { throw 'Step output/home cap exceeded after exit' }
    $Stdout=[IO.File]::ReadAllText($OutPath); $Stderr=[IO.File]::ReadAllText($ErrPath)
    if (($Stdout+"`n"+$Stderr) -match '(?im)SCRIPT ERROR|Parse Error:') { throw "Godot step $StepId emitted script/parse errors" }
    if (($Stdout+"`n"+$Stderr) -match '(?m)^(WARNING|ERROR):') { throw "Godot step $StepId emitted unexpected warning/error diagnostics" }
    if ($Stderr.Length -ne 0) { throw "Godot step $StepId emitted nonempty stderr" }
    $TestResult=if($Step.kind -eq 'single-file-tests'){Assert-TestOutput $Stdout $Step}else{Assert-MemoryOutput $Stdout $Step}
    $ExternalMemory=if($Step.kind -eq 'allocation-diagnostic'){Assert-ExternalMemorySamples $script:MemorySamplesPath}else{$null}
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    Assert-StepDeadline $Timer.Elapsed.TotalSeconds ([double]$Step.wall_seconds)
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD;actual_result=$TestResult;external_memory=$ExternalMemory}
    $script:StepReceipts+=,$StepReceipt
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}

$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
if($CpuStagePreflightFixture -or $CpuPacketFixture) {
 if($Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false -or $Admission.job_sha256 -cne (Hash-File $JobPath)){throw 'CPU fixture requires exact unadmitted bytes'}
} elseif($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.job_sha256 -cne (Hash-File $JobPath)){throw 'Exact root admission is required'}
$PacketDir=Split-Path -Parent $ArtifactDir
if($Job.supervisor_sha256 -cne (Hash-File $PSCommandPath)){throw 'Supervisor hash differs'}
if($Job.source_commit -cne $ExpectedSource -or $Job.source_parent -cne $ExpectedParent -or $Job.staging_base -cne $ExpectedBase -or $Job.native_transition_from -cne $ExpectedBase -or $Job.stage -cne $Stage -or $Job.job_id -cne 'sw868v-r3' -or $Admission.job_id -cne 'sw868v-r3' -or $Admission.schema -cne 'codex.stormwood-scoped-admission.v1' -or $Job.output_directory -cne 'D:\tetherbound\.artifacts\s\run-sw868v-r3'){throw 'Exact source/job/stage identity differs'}
if($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha){throw 'Engine pin differs'}
if([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.packet_bytes -ne $PacketCap){throw 'Resource caps differ'}
Assert-Hash (Join-Path $ArtifactDir 'request.json') '3f2934c0c7740b90efdc1a1333f5ada9424ffca404e45e4e834ac80c055e5866'
Assert-Hash (Join-Path $PacketDir 'source-bindings.json') 'c63448e19ec0fd0509fddbde0a039115fe16c276f95c33f67fd278005a869d65'
Assert-Hash (Join-Path $PacketDir 'transition-inventory.json') 'e5c7c3701bf0e8d811eabb10d2b51a50b3241385cf3b57ae97fb33247593461d'
Assert-Hash (Join-Path $PacketDir 'source.pack') '94fd634931f27acdeb2425d5a21e6899bf15706c407e4e6fc0ae8d78df69e1d7'
Assert-Hash (Join-Path $PacketDir 'Medium-graphics_override.cfg') 'c26dcc5ce03748427a34d3212a9d47b59afa7a55a334f66e447338e25cc55473'
$Bound=Read-Json (Join-Path $PacketDir 'source-bindings.json')
if(@($Job.source_bindings).Count -ne 794 -or ($Job.source_bindings|ConvertTo-Json -Depth 20 -Compress) -cne ($Bound.source_bindings|ConvertTo-Json -Depth 20 -Compress)){throw 'Exact source bindings differ'}
$Inventory=Read-Json (Join-Path $PacketDir 'transition-inventory.json')
if(($Job.changed_source_paths|ConvertTo-Json -Compress) -cne (@($Inventory.transition_delta|ForEach-Object{$_.path})|ConvertTo-Json -Compress)){throw 'Exact source delta differs'}
$Request=Read-Json (Join-Path $ArtifactDir 'request.json')
if($Request.source -cne $ExpectedSource -or $Request.parent -cne $ExpectedParent -or $Request.base -cne $ExpectedBase -or @($Job.steps).Count -ne 1 -or ($Job.steps|ConvertTo-Json -Depth 20 -Compress) -cne ($Request.steps|ConvertTo-Json -Depth 20 -Compress) -or ($Job.source_preflight|ConvertTo-Json -Compress) -cne ($Request.source_preflight|ConvertTo-Json -Compress)){throw 'Exact request differs'}
Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Request.source_preflight.helper_sha256
Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Request.source_preflight.contract_sha256
Assert-StepIds $Job.steps
if($Job.graphics_overrides.project_name -cne 'Tetherbound' -or $Job.graphics_overrides.profiles.Medium.source -cne (Join-Path $PacketDir 'Medium-graphics_override.cfg') -or $Job.graphics_overrides.profiles.Medium.sha256 -cne 'c26dcc5ce03748427a34d3212a9d47b59afa7a55a334f66e447338e25cc55473' -or $Job.graphics_overrides.user_data_path_rule -cne '%APPDATA%\Godot\app_userdata\Tetherbound\graphics_override.cfg'){throw 'Isolated profile differs'}
if($CpuPacketFixture){'CPU packet PASS; unadmitted; no native access';exit 0}
Assert-Hash $Engine $EngineSha
Assert-Source
if((Read-Json (Join-Path $Stage 'data/config/stormwood_look.json')).enabled -ne $false){throw 'Stormwood look must remain OFF'}
if($CpuStagePreflightFixture){'CPU stage preflight PASS; no engine';exit 0}
Assert-Hash ([string]$Admission.prerequisite_review_path) ([string]$Admission.prerequisite_review_sha256)
$Proof=Read-Json ([string]$Admission.prerequisite_review_path)
if($Proof.status -cne 'ROOT_REVIEWED_FOR_SCOPED_VALIDATION' -or $Proof.source_commit -cne $ExpectedSource -or $Proof.transition_from -cne $ExpectedBase -or $Proof.job_sha256 -cne (Hash-File $JobPath) -or $Proof.source_and_transition_reviewed -ne $true -or $Proof.imports_ready -ne $true -or $Proof.execution_contract_reviewed -ne $true -or $Proof.terrain_dll_sha256 -cne '5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306'){throw 'Exact root execution review required'}
Assert-Resources $true
Assert-NoForeignEngine
if ((Get-RunBytes $PacketDir) -gt $PacketCap) { throw 'Packet exceeds 16 MiB' }
$RunDir=[string]$Job.output_directory
$ExpectedRunDir=Join-Path $OutputRoot ('run-'+$Job.job_id)
if ([IO.Path]::GetFullPath($RunDir) -cne [IO.Path]::GetFullPath($ExpectedRunDir) -or (Test-Path -LiteralPath $RunDir)) { throw 'Output directory must be the declared fresh path' }
if (-not (Test-Path -LiteralPath $OwnerLockPath -PathType Leaf)) { throw 'Native owner lock file missing' }
$script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$Owner=Read-Owner
if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved' }
Assert-NoForeignEngine; Assert-Resources $true
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $RunDir) | Out-Null
New-Item -ItemType Directory -Path $RunDir | Out-Null
$ReceiptPath=Join-Path $RunDir 'receipt.json'
$Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;engine_sha256=$EngineSha;started_utc=[DateTime]::UtcNow.ToString('o');isolated_home=$Job.isolated_home;steps=@();limits=@{C_admission_bytes=$CAdmissionFloor;C_stop_bytes=$CStopFloor;D_admission_bytes=$DAdmissionFloor;D_stop_bytes=$DStopFloor;memory_floor_bytes=$MemoryFloor;combined_logs_bytes=$CombinedLogsCap;output_bytes=$OutputCap}}
Write-JsonAtomic $ReceiptPath $Receipt
try {
    foreach ($Step in $Job.steps) {
        Run-Step $Step
        $Receipt.steps=@($script:StepReceipts); Write-JsonAtomic $ReceiptPath $Receipt
    }
    $Receipt.status='EXITED_ZERO_AWAITING_REVIEW'; $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o'); $Receipt.total_output_bytes=Get-RunBytes $RunDir
    Write-JsonAtomic $ReceiptPath $Receipt
} catch {
    if ($script:CurrentStepId -and -not $Receipt.failed_step) {
        try {
            $FailExit=if($script:Proc -and $script:Proc.HasExited){[int]$script:Proc.ExitCode}else{-1}
            $FailReason=if($script:ObservedStopReason){[string]$script:ObservedStopReason}else{$_.Exception.Message}
            Write-FailedStepReceipt $script:CurrentStepId 'unknown' $FailExit $FailReason (Read-TerminalMetrics)
        } catch { $Receipt.failed_step=$script:CurrentStepId; $Receipt.stop_reason=$_.Exception.Message }
    }
    $Receipt.status='FAILED'; $Receipt.failure=$_.Exception.Message; $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o'); $Receipt.steps=@($script:StepReceipts)
    try { $Receipt.total_output_bytes=Get-RunBytes $RunDir; Write-JsonAtomic $ReceiptPath $Receipt } catch {}
    throw
} finally {
    if ($script:Proc -and -not $script:Proc.HasExited) {
        try { Stop-OwnedProcess 'failure cleanup' } catch { $Receipt.cleanup_blocked=$_.Exception.Message }
    }
    try { Complete-LogDrain 5000 -Cancel } catch {
        $Receipt.cleanup_blocked=$_.Exception.Message; $Receipt.status='FAILED'
        try { Write-JsonAtomic $ReceiptPath $Receipt } catch {}
    }
    if ($script:LeaseOwned -and ((-not $script:Proc) -or $script:Proc.HasExited)) {
        try { Assert-NoForeignEngine; Update-Owner $true $script:LeasePid $script:LeaseRun; $script:LeaseOwned=$false } catch { $Receipt.cleanup_blocked=$_.Exception.Message; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    }
    if ($script:LeaseOwned) { $Receipt.lease_retained_for_live_or_unverified_child=$true; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    if ($script:Proc) { $script:Proc.Dispose() }
    if ($script:OwnerLock) { $script:OwnerLock.Dispose() }
}


