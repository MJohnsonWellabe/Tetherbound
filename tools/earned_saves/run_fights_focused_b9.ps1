param([switch]$CpuPacketFixture)
$ErrorActionPreference = 'Stop'
$ArtifactDir = $PSScriptRoot
$JobPath = Join-Path $ArtifactDir 'native-job.json'
$AdmissionPath = Join-Path $ArtifactDir 'native-admission.json'
$Stage = 'C:\CodexTemp\tetherbound-native-service'
$OutputRoot = 'D:\tetherbound\.artifacts\fights-focused-b9'
$OwnerPath = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource = 'b9d7edeb7f18d7ca2192f018016d4126f1910f91'
$ExpectedParent = 'edb413144b51c003e5c98fc144df82192871f158'
$ExpectedBase = 'e30b761bbe6f874df95c3b2153d9fcd7a7c8c6e7'
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
$script:OverallTimer=[Diagnostics.Stopwatch]::StartNew()
$script:OverallCapMs=300000
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
 $WallMs=[Math]::Min($WallMs,(Get-RemainingBudget))
 Initialize-PreflightReader
 $Info=[Diagnostics.ProcessStartInfo]::new();$Info.FileName=$Program;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true
 $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
 foreach($Arg in $Arguments){$Info.ArgumentList.Add($Arg)}
 $P=[Diagnostics.Process]::new();$P.StartInfo=$Info;$Clock=[Diagnostics.Stopwatch]::StartNew();$Out=$null;$Err=$null
 try {
  if(-not $P.Start()){throw 'Preflight process start failed'}
  $Out=[MeadowsCappedReader]::Read($P.StandardOutput,1048576);$Err=[MeadowsCappedReader]::Read($P.StandardError,1048576)
  $ResourceTick=0L
  while(-not $P.HasExited){
   if($Clock.ElapsedMilliseconds-$ResourceTick -ge 500){$null=Assert-Resources;$ResourceTick=$Clock.ElapsedMilliseconds}
   $null=Get-RemainingBudget
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
 $Result=$Text|ConvertFrom-Json
 if($Result.index_sha256 -cne '8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4'){throw 'Confirmed b9 index hash changed'}
 if($Result.status -cne 'PASS' -or $Result.source -cne $ExpectedSource -or $Result.index_paths -ne 49341 -or $Result.bindings -ne 63 -or $Result.materialized_files -lt 12887){throw 'Incomplete bounded source audit'}
 $script:LastSourceAudit=$Result
}

function Read-Owner { Read-Json $OwnerPath }
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='fights_b9_focused_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='fights_b9_focused_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Fights focused logic regressions; process starting'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='fights_b9_focused_capture_child'
    $Owner.processes=@(@{pid=$PidValue;kind='fights_b9_focused_capture_child';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Fights focused logic regressions; owned child recorded'
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
        $Owner.active_process_id=$PidValue; $Owner.active_session_id=$null; $Owner.active_kind='fights_b9_focused_capture_child'
        $Owner.processes=@(@{pid=$PidValue;kind='fights_b9_focused_capture_child'}); $Owner.run_id=$RunId
        $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Fights focused logic regressions'
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
function Get-RemainingBudget {
 $Left=$script:OverallCapMs-$script:OverallTimer.ElapsedMilliseconds
 if($Left -le 0){throw 'Aggregate supervisor deadline exceeded'}
 return [int]$Left
}
function Assert-Payload {
 foreach($Binding in $Request.external_bindings){Assert-Hash ([string]$Binding.path) ([string]$Binding.sha256)}
}
function Assert-TestOutput([string]$Stdout,$Step) {
 if($Stdout -match '(?m)^\s*FAIL\b'){throw 'Test failure output'}
 $Found=@([regex]::Matches($Stdout,'(?m)^\s*ok[ \t]+(test_\w+)[ \t]*\r?$')|ForEach-Object{$_.Groups[1].Value})
 $Expected=@($Step.methods)
 if($Found.Count -ne $Expected.Count -or @($Found|Select-Object -Unique).Count -ne $Expected.Count -or (Compare-Object ($Found|Sort-Object) ($Expected|Sort-Object))){throw 'Missing, duplicate or unexpected test method'}
 $Summaries=@([regex]::Matches($Stdout,'(?m)^(\d+) test\(s\), (\d+) failed[ \t]*\r?$'))
 if($Summaries.Count -ne 1 -or [int]$Summaries[0].Groups[1].Value -ne $Expected.Count -or $Summaries[0].Groups[2].Value -cne '0'){throw 'Exact successful test summary missing'}
 return @{methods=$Found;failed=0}
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
    $script:OutPath=$null; $script:ErrPath=$null; $script:CurrentStepId=[string]$Step.id; $script:ObservedStopReason=$null
    $null=Get-RemainingBudget
    Assert-Resources
    Assert-NoForeignEngine
    $StepStartBytes=Get-RunBytes $RunDir
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir 'h0'
    if ($StepId -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
    New-Item -ItemType Directory -Path $HomeDir | Out-Null
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
            $null=Get-RemainingBudget
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
    $TestResult=Assert-TestOutput $Stdout $Step
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    Assert-StepDeadline $Timer.Elapsed.TotalSeconds ([double]$Step.wall_seconds)
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD;actual_test_result=$TestResult}
    $script:StepReceipts+=,$StepReceipt
    Assert-Source
    Assert-Payload
    $null=Get-RemainingBudget
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}

$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
$RequestPath=Join-Path $ArtifactDir 'request.json'
Assert-Hash $RequestPath $Job.request_sha256
$Request=Read-Json $RequestPath
if($Job.source_commit -cne $ExpectedSource -or $Job.source_parent -cne $ExpectedParent -or $Job.staging_base -cne $ExpectedBase -or $Job.stage -cne $Stage){throw 'Source identity differs'}
if($Job.supervisor_sha256 -cne (Hash-File $PSCommandPath)){throw 'Supervisor hash differs'}
if(($Job.steps|ConvertTo-Json -Depth 12 -Compress) -cne ($Request.steps|ConvertTo-Json -Depth 12 -Compress) -or $Job.steps.Count -ne 1){throw 'One exact requested test step required'}
if(($Job.source_bindings|ConvertTo-Json -Depth 12 -Compress) -cne ($Request.source_bindings|ConvertTo-Json -Depth 12 -Compress) -or ($Job.source_preflight|ConvertTo-Json -Compress) -cne ($Request.source_preflight|ConvertTo-Json -Compress)){throw 'Source pins differ'}
Assert-Payload
Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Job.source_preflight.helper_sha256
Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Job.source_preflight.contract_sha256
if($Admission.job_sha256 -cne (Hash-File $JobPath)){throw 'Admission is bound to other job bytes'}
if($CpuPacketFixture){
 if($Job.status -cne 'PREPARED' -or $Admission.status -cne 'NOT_ADMITTED' -or $Job.launch_allowed -ne $false -or $Admission.launch_allowed -ne $false){throw 'CPU fixture must remain unadmitted'}
 'CPU packet PASS; no engine, source audit or lease write.';exit 0
}
if($Job.status -cne 'ROOT_ADMITTED' -or $Admission.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.launch_allowed -ne $true){throw 'Root admission required'}
Assert-Hash $Admission.review_path $Admission.review_sha256
$Review=Read-Json $Admission.review_path
if($Review.status -cne 'ROOT_REVIEWED_FOR_FOCUSED' -or $Review.job_sha256 -cne (Hash-File $JobPath) -or $Review.source_commit -cne $ExpectedSource -or $Review.external_rebinding_reviewed -ne $true -or $Review.full_project_imports_ready -ne $true){throw 'Exact independent root review required'}
Assert-Hash $Engine $EngineSha
$RunDir=Join-Path $OutputRoot ([string]$Job.job_id)
if($Job.job_id -notmatch '^fights-b9-(selection|altar)-r1$' -or $Job.output_directory -cne $RunDir -or (Test-Path -LiteralPath $RunDir)){throw 'Expected fresh bounded output'}
if((Get-RunBytes $ArtifactDir) -gt $PacketCap){throw 'Packet cap exceeded'}
$null=Assert-Resources $true;Assert-NoForeignEngine
$script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
 $Owner=Read-Owner
 if($Owner.thread -cne $ExpectedThread -or $Owner.source -cne $ExpectedSource -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0){throw 'Root b9 lease is not idle/reserved'}
 Assert-Source
 $null=Assert-Resources $true;Assert-NoForeignEngine;Assert-Payload
 New-Item -ItemType Directory -Force -Path $OutputRoot|Out-Null
 New-Item -ItemType Directory -Path $RunDir|Out-Null
 $ReceiptPath=Join-Path $RunDir 'receipt.json'
 $Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;steps=@();started_utc=[DateTime]::UtcNow.ToString('o')}
 Write-JsonAtomic $ReceiptPath $Receipt
 Run-Step $Job.steps[0]
 $Receipt.steps=@($script:StepReceipts);$Receipt.status='PASSED_FOCUSED_LOGIC_NOT_EARNED';$Receipt.source_audit=$script:LastSourceAudit
 Write-JsonAtomic $ReceiptPath $Receipt
} catch {
 if($ReceiptPath -and $Receipt){$Receipt.status='FAILED';$Receipt.failure=$_.Exception.Message;$Receipt.steps=@($script:StepReceipts);Write-JsonAtomic $ReceiptPath $Receipt}
 throw
} finally {
 if($script:Proc -and -not $script:Proc.HasExited){try{Stop-OwnedProcess 'failure cleanup'}catch{}}
 try{Complete-LogDrain 5000 -Cancel}catch{}
 if($script:LeaseOwned -and ((-not $script:Proc) -or $script:Proc.HasExited)){
  try{Assert-NoForeignEngine;Update-Owner $true $script:LeasePid $script:LeaseRun;$script:LeaseOwned=$false}catch{}
 }
 if($ReceiptPath -and $Receipt){$Receipt.lease_retained=$script:LeaseOwned;$Receipt.elapsed_seconds=$script:OverallTimer.Elapsed.TotalSeconds;Write-JsonAtomic $ReceiptPath $Receipt}
 if($script:Proc){$script:Proc.Dispose()}
 if($script:OwnerLock){$script:OwnerLock.Dispose()}
}
