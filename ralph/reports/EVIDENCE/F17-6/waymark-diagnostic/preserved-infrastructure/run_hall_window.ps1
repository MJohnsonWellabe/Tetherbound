param([switch]$CpuStagePreflightFixture,[switch]$CpuPacketFixture)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run this supervisor with PowerShell 7 or newer' }
$ArtifactDir = $PSScriptRoot
$JobPath = Join-Path $ArtifactDir 'native-job.json'
$AdmissionPath = Join-Path $ArtifactDir 'native-admission.json'
$Stage = 'C:\CodexTemp\tetherbound-native-service'
$OutputRoot = 'D:\tetherbound\.artifacts\s'
$OwnerPath = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource = '5650c507e69ed0a7b6feaf72d1f345e406c98109'
$Engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$EngineSha = 'b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8'
$Git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$CAdmissionFloor = 10.5GB
$CStopFloor = 10GB
$DAdmissionFloor = 21GB
$DStopFloor = 20GB
$MemoryFloor = 2GB
$CombinedLogsCap = 32MB
$OutputCap = 160MB
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
    if (Test-Path -LiteralPath $Path -PathType Leaf) { $Backup="$Path.$([Guid]::NewGuid().ToString('N')).bak"; [IO.File]::Replace($Temp, $Path, $Backup); Remove-Item -LiteralPath $Backup -Force } else { [IO.File]::Move($Temp, $Path) }
}
function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Get-CanonicalSourceHash([string]$Path,[string]$Mode) {
    if ($Mode -ceq 'binary') { return Hash-File $Path }
    if ($Mode -cne 'utf8_lf') { throw 'Unknown source binding hash mode' }
    $Text=[IO.File]::ReadAllText($Path).Replace("`r`n","`n")
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Pinned file is missing: $Path" }
    if ((Hash-File $Path) -cne $Expected.ToLowerInvariant()) { throw "SHA-256 mismatch: $Path" }
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
function Initialize-PreflightReader {
 if (-not ('HallCappedReader' -as [type])) {
 Add-Type -TypeDefinition @"
using System; using System.IO; using System.Text; using System.Threading.Tasks;
public static class HallCappedReader {
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
function Invoke-BoundedSourceProcess([string]$Program,[string[]]$Arguments,[int]$WallMs=120000) {
 Initialize-PreflightReader
 $Info=[Diagnostics.ProcessStartInfo]::new();$Info.FileName=$Program;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true
 $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
 foreach($Arg in $Arguments){$Info.ArgumentList.Add($Arg)}
 $P=[Diagnostics.Process]::new();$P.StartInfo=$Info;$Clock=[Diagnostics.Stopwatch]::StartNew();$Out=$null;$Err=$null
 try {
  if(-not $P.Start()){throw 'Preflight process start failed'}
  $Out=[HallCappedReader]::Read($P.StandardOutput,1048576);$Err=[HallCappedReader]::Read($P.StandardError,1048576)
  while(-not $P.HasExited){
   if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
   if($Out.IsFaulted -or $Err.IsFaulted){throw 'Preflight output reader failed or cap exceeded'}
   [Threading.Thread]::Sleep(20)
  }
  $Remaining=[int]($WallMs-$Clock.ElapsedMilliseconds)
  if($Remaining -le 0){throw 'Source preflight deadline exceeded'}
  if(-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($Out,$Err),[Math]::Min(2000,$Remaining))){throw 'Source preflight drain timeout'}
  if($Clock.ElapsedMilliseconds -ge $WallMs){throw 'Source preflight deadline exceeded'}
  $Stdout=$Out.GetAwaiter().GetResult();$Stderr=$Err.GetAwaiter().GetResult()
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
 if($Result.status -cne 'PASS' -or $Result.source -cne $ExpectedSource -or $Result.index_paths -ne 49363 -or $Result.bindings -ne 105 -or $Result.materialized_files -lt 12911){throw 'Incomplete bounded source audit'}
 $script:LastSourceAudit=$Result
}

function Read-Owner { Read-Json $OwnerPath }
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.source -cne $ExpectedSource -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='hall_night_medium_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='hall_night_medium_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Hall rebound window-led daylight comparison; process starting'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.source -cne $ExpectedSource -or $Owner.reserved -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='hall_night_medium_witness'
    $Owner.processes=@(@{pid=$PidValue;kind='hall_night_medium_witness';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Hall rebound window-led daylight comparison; owned child recorded'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeasePid=$PidValue
}
function Update-Owner([bool]$Release,[int]$PidValue=0,[string]$RunId='') {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.source -cne $ExpectedSource -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) { throw 'Exact native lease authorization changed' }
    if ($Release) {
        if ([int]$Owner.active_process_id -ne $PidValue -or $Owner.run_id -cne $RunId) { throw 'Refusing to release another run lease' }
        $Owner.active_process_id=$null; $Owner.active_session_id=$null; $Owner.active_kind=$null; $Owner.processes=@(); $Owner.run_directory=$null; $Owner.run_id=$null
        $Owner.purpose='Service lane reserved; no native writer'; $Owner.source=$ExpectedSource
    } else {
        if ($Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Root lease is not idle' }
        $Owner.active_process_id=$PidValue; $Owner.active_session_id=$null; $Owner.active_kind='hall_night_medium_witness'
        $Owner.processes=@(@{pid=$PidValue;kind='hall_night_medium_witness'}); $Owner.run_id=$RunId
        $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Hall rebound window-led daylight comparison'
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

function Read-PngInfo([string]$Path) {
    $Stream=[IO.File]::OpenRead($Path)
    try {
        $Bytes=[byte[]]::new(24); $Offset=0
        while ($Offset -lt 24) { $Read=$Stream.Read($Bytes,$Offset,24-$Offset); if ($Read -le 0) { throw 'PNG header is truncated' }; $Offset += $Read }
    } finally { $Stream.Dispose() }
    $Signature=[byte[]]@(137,80,78,71,13,10,26,10)
    for ($i=0; $i -lt 8; $i++) { if ($Bytes[$i] -ne $Signature[$i]) { throw 'Capture output is not a PNG file' } }
    if ([Text.Encoding]::ASCII.GetString($Bytes,12,4) -cne 'IHDR') { throw 'PNG first chunk is not IHDR' }
    return @{width=[Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($Bytes,16));height=[Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($Bytes,20))}
}
function Get-CaptureResults($Step,[string]$GraphicsOverridePath) {
    $Dir=Split-Path -Parent ([string]$Step.expected_images[0].path)
    if (@(Get-ChildItem -LiteralPath $Dir -File).Count -ne 2 -or @(Get-ChildItem -LiteralPath $Dir -Directory).Count) { throw 'Exactly two fresh PNGs required per arm' }
    $Results=@()
    foreach ($ExpectedImage in $Step.expected_images) {
        $ImagePath=[string]$ExpectedImage.path
        if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) { throw "Expected capture PNG missing: $ImagePath" }
        $Info=Read-PngInfo $ImagePath
        if ([int]$Info.width -ne 1280 -or [int]$Info.height -ne 720) { throw "Capture dimensions mismatch: $ImagePath $($Info.width)x$($Info.height)" }
        $Results+=,[ordered]@{png=$ImagePath;sha256=(Hash-File $ImagePath);width=[int]$Info.width;height=[int]$Info.height;view=[string]$ExpectedImage.view;preset=[string]$Step.preset;arm=[string]$Step.arm;renderer='forward_plus';user_data_override=$GraphicsOverridePath;user_data_override_sha256=(Hash-File $GraphicsOverridePath)}
    }
    if ($Results.Count -ne @($Step.expected_images).Count -or $Results.Count -eq 0) { throw 'Capture output count differs from expected image set' }
    return ,$Results
}
function Assert-StepDeadline($Timer,[double]$WallSeconds) {
    if ($Timer.Elapsed.TotalSeconds -ge $WallSeconds) { throw 'wall-clock cap reached at terminal validation' }
}
function Wait-OutputDrain($StdoutTask,$StderrTask,[int]$TimeoutMilliseconds=2000) {
    if ($TimeoutMilliseconds -le 0) { throw 'stdout/stderr drain has no remaining time' }
    $Tasks=[Threading.Tasks.Task[]]@(@($StdoutTask,$StderrTask) | Where-Object { $null -ne $_ })
    if ($Tasks.Count -eq 0) { return }
    if (-not [Threading.Tasks.Task]::WaitAll($Tasks,$TimeoutMilliseconds)) { throw 'stdout/stderr drain timeout' }
    # Both tasks completed or WaitAll threw, so GetResult cannot block here.
    foreach($Task in $Tasks) { $null=$Task.GetAwaiter().GetResult() }
}
function Complete-StepOutput($Proc,$Timer,[double]$WallSeconds,$StdoutTask,$StderrTask) {
    if (-not $Proc.HasExited -or -not $Proc.WaitForExit(0)) { throw 'Owned process remained live at terminal validation' }
    Assert-StepDeadline $Timer $WallSeconds
    $RemainingMs=[int][Math]::Floor(($WallSeconds-$Timer.Elapsed.TotalSeconds)*1000.0)
    Wait-OutputDrain $StdoutTask $StderrTask ([Math]::Min(2000,$RemainingMs))
    Assert-StepDeadline $Timer $WallSeconds
}

function Reset-StepState($Step) {
    # Never discard ownership of a previous live child or an unreleased lease.
    if ($script:Proc -and -not $script:Proc.HasExited) { throw 'Previous owned process still live before next step' }
    if ($script:LeaseOwned) { throw 'Previous native lease still owned before next step' }
    if ($script:Proc) { $script:Proc.Dispose() }
    if ($script:OutStream) { $script:OutStream.Dispose() }
    if ($script:ErrStream) { $script:ErrStream.Dispose() }
    $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
    $script:OutPath=$null; $script:ErrPath=$null; $script:GraphicsOverridePath=$null
    $script:OutTask=$null; $script:ErrTask=$null; $script:OutStream=$null; $script:ErrStream=$null
    $script:ObservedStopReason=$null
    $script:MinPhysical=[long]::MaxValue; $script:MinCommit=[long]::MaxValue
    $script:MinC=[long]::MaxValue; $script:MinD=[long]::MaxValue
    $script:CurrentStepId=[string]$Step.id; $script:CurrentStepKind=[string]$Step.kind
    # LogPaths and StepReceipts are job-wide: retain combined caps and arm-one evidence.
}

function Run-Step($Step) {
    Reset-StepState $Step
    Assert-Source
    Assert-Hash $Engine $EngineSha
    Assert-Resources $true
    Assert-NoForeignEngine
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir ('h'+[array]::IndexOf($Job.steps,$Step))
    if ($StepId -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
    New-Item -ItemType Directory -Path $HomeDir | Out-Null
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
    $OutPath=Join-Path $RunDir ($StepId+'.stdout.log'); $ErrPath=Join-Path $RunDir ($StepId+'.stderr.log')
    $script:OutPath=$OutPath; $script:ErrPath=$ErrPath
    $script:LogPaths+=@($OutPath,$ErrPath)
    $CaptureResult=$null
    $StepArgs=@($Step.args | ForEach-Object { [string]$_ })
    $StartInfo=[Diagnostics.ProcessStartInfo]::new(); $StartInfo.FileName=$Engine; $StartInfo.WorkingDirectory=$Stage
    $StartInfo.UseShellExecute=$false; $StartInfo.CreateNoWindow=$true; $StartInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $StartInfo.RedirectStandardOutput=$true; $StartInfo.RedirectStandardError=$true
    foreach ($Arg in $StepArgs) { $StartInfo.ArgumentList.Add($Arg) }
    foreach ($Name in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','TEMP','TMP')) { $StartInfo.Environment[$Name]=$HomeDir }
    $Proc=[Diagnostics.Process]::new(); $Proc.StartInfo=$StartInfo
    Claim-Owner $StepId
    $Timer=[Diagnostics.Stopwatch]::StartNew()
    if (-not $Proc.Start()) { throw "Godot failed to start $StepId" }
    $script:Proc=$Proc
    $script:ProcId=$Proc.Id; $script:ProcStartUtc=$Proc.StartTime.ToUniversalTime()
    Record-OwnedChild $script:ProcId $script:ProcStartUtc $StepId
    $OutStream=[IO.File]::Open($OutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:OutStream=$OutStream
    $ErrStream=[IO.File]::Open($ErrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:ErrStream=$ErrStream
    $OutTask=$Proc.StandardOutput.BaseStream.CopyToAsync($OutStream); $ErrTask=$Proc.StandardError.BaseStream.CopyToAsync($ErrStream)
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
            $ActualLogBytes=Get-CombinedLogBytes
            if ($ActualLogBytes -gt $CombinedLogsCap) { $StopReason='stdout/stderr cap reached'; break }
            if ((Get-RunBytes $RunDir) -gt $OutputCap) { $StopReason='output/home cap reached'; break }
      } catch { $StopReason=$_.Exception.Message; $script:ObservedStopReason=$StopReason; break }
        Start-Sleep -Milliseconds 1000
    }
    if ($StopReason) { $script:ObservedStopReason=[string]$StopReason }
    if ($StopReason) { Stop-OwnedProcess $StopReason }
    if (-not $Proc.HasExited) { throw 'Owned process remained live after stop path' }
    try { Complete-StepOutput $Proc $Timer ([double]$Step.wall_seconds) $OutTask $ErrTask }
    catch { $script:ObservedStopReason=$_.Exception.Message; throw }
    $OutStream.Dispose(); $ErrStream.Dispose(); $script:OutStream=$null; $script:ErrStream=$null; $script:OutTask=$null; $script:ErrTask=$null
    $Exit=[int]$Proc.ExitCode
    $TerminalMetrics=Read-TerminalMetrics
    if ($Exit -ne 0 -or $StopReason) {
        $FailedReason=if($StopReason){[string]$StopReason}else{"process exited with code $Exit; stop cause not observed"}
        Write-FailedStepReceipt $StepId ([string]$Step.kind) $Exit $FailedReason $TerminalMetrics
        throw "Godot step $StepId failed: $FailedReason"
    }
    if ((Get-CombinedLogBytes) -gt $CombinedLogsCap) { throw 'Combined stdout/stderr exceeded cap after exit' }
    if ((Get-RunBytes $RunDir) -gt $OutputCap) { throw 'Run output exceeded cap after exit' }
    $Stdout=[IO.File]::ReadAllText($OutPath); $Stderr=[IO.File]::ReadAllText($ErrPath)
    if (-not [string]::IsNullOrWhiteSpace($Stderr)) { throw "Hall capture stderr must be empty" }
    if (($Stdout+([Environment]::NewLine)+$Stderr) -match '(?i)velocity.{0,100}exceeded.{0,40}ceiling|falling trainer') { throw 'Diagnostic trainer velocity/fall warning found in process logs' }
    if (($Stdout+"`n"+$Stderr) -match '(?im)SCRIPT ERROR|Parse Error:|^(WARNING|ERROR):|missing asset') { throw "Godot step $StepId emitted script/engine errors" }
    if ($Step.kind -eq 'parser') {
        if (-not [string]::IsNullOrWhiteSpace($Stderr)) { throw 'Parser stderr must be empty' }
    } elseif ($Step.kind -eq 'tests') {
        $ExpectedTests=[int]$Step.expected_test_methods
        $Summary=[regex]::Match($Stdout,'(?m)^(\d+) tests, (\d+) assertions, (\d+) failed\r?$')
        if (-not $Summary.Success -or [int]$Summary.Groups[1].Value -ne $ExpectedTests -or [int]$Summary.Groups[2].Value -le 0 -or [int]$Summary.Groups[3].Value -ne 0) { throw "Test totals mismatch for $StepId" }
        if ($Stdout -notmatch [regex]::Escape([string]$Step.expected_selector_summary)) { throw "Test selector summary missing for $StepId" }
    } else {
        foreach ($Marker in $Step.required_output_markers) { if ($Stdout -notmatch [regex]::Escape([string]$Marker)) { throw "Required Hall night capture output marker missing for $StepId" } }
        $GodotLogs=@(Get-ChildItem -LiteralPath $HomeDir -File -Force -Recurse | Where-Object { $_.Name -eq 'godot.log' })
        foreach ($Log in $GodotLogs) { $LogText=[IO.File]::ReadAllText($Log.FullName); if ($LogText -match '(?i)velocity.{0,100}exceeded.{0,40}ceiling|falling trainer') { throw "Diagnostic trainer velocity/fall warning found in $($Log.FullName)" } }
    }
    if ($Step.kind -eq 'capture') {
        $CaptureResult=Get-CaptureResults $Step $script:GraphicsOverridePath
    }
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    Assert-StepDeadline $Timer ([double]$Step.wall_seconds)
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);capture=$CaptureResult;source_preflight=$script:LastSourceAudit;stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD}
    $script:StepReceipts+=,$StepReceipt
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}


$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
if ($Job.schema -cne 'codex.visual-hall-night-native-run.v1' -or $Job.job_id -cne 'hallwindow565-r3' -or $Job.source_commit -cne $ExpectedSource -or $Job.supervisor_sha256 -cne (Hash-File $PSCommandPath) -or $Admission.job_sha256 -cne (Hash-File $JobPath)) { throw 'Exact source/job/supervisor admission binding required' }
Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Job.source_preflight.helper_sha256
Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Job.source_preflight.contract_sha256
if($Job.source_preflight.wall_seconds -ne 120 -or $Job.source_preflight.inner_seconds -ne 115 -or $Job.source_preflight.git_seconds -ne 30){throw 'Source audit caps differ'}
Assert-Hash $Job.manifest_binding.path $Job.manifest_binding.sha256
Assert-Hash $Job.pack_binding.path $Job.pack_binding.sha256
Assert-Hash $Job.pack_binding.preflight_path $Job.pack_binding.preflight_sha256
$Manifest=Read-Json $Job.manifest_binding.path
if ($Manifest.source -cne $ExpectedSource -or $Job.source_bindings.Count -ne 105 -or $Job.steps.Count -ne 2 -or (($Job.steps | ForEach-Object id) -join ',') -cne 'frame-lantern-lit-Medium-diagnostic,frame-window-lit-Medium-diagnostic') { throw 'Exact two-arm diagnostic required' }
for($i=0;$i -lt 2;$i++) {
    $S=$Job.steps[$i]; $C=$Manifest.commands[$i]
    $Dest=([string]$Job.output_directory).Replace('\','/')+'/images/'+[string]$S.id
    $ExpectedArgs=@($C.args | ForEach-Object { if($_ -like '--out=*') {'--out='+$Dest} else {[string]$_} })
    if (($S.args -join "`n") -cne ($ExpectedArgs -join "`n") -or $S.kind -cne 'capture' -or $S.preset -cne 'Medium' -or $S.arm -cne $C.arm -or $S.wall_seconds -ne 120 -or $S.expected_images.Count -ne 2) { throw 'Exact bounded capture arguments differ' }
    for($v=0;$v -lt 2;$v++) {
        $Name=[IO.Path]::GetFileName([string]$C.expected_images[$v]); $Image=$S.expected_images[$v]
        if ([IO.Path]::GetFullPath([string]$Image.path) -cne [IO.Path]::GetFullPath(($Dest+'/'+$Name)) -or $Image.view -cne [IO.Path]::GetFileNameWithoutExtension($Name)) { throw 'Expected image path/view differs' }
    }
}
$DllPath='addons/terrain_3d/bin/libterrain.windows.debug.x86_64.dll'
$DllHash='5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306'
$DllBindings=@($Job.source_bindings | Where-Object path -CEQ $DllPath)
if ($DllBindings.Count -ne 1 -or $DllBindings[0].hash_mode -cne 'binary' -or $DllBindings[0].sha256 -cne $DllHash -or $Job.runtime_dll.sha256 -cne $DllHash -or $Job.runtime_dll.path -cne $DllPath) { throw 'Accepted binary Terrain DLL pin required' }
foreach($Binding in $Job.source_bindings) {
    $ExpectedMode=if([IO.Path]::GetExtension([string]$Binding.path).ToLowerInvariant() -in @('.glb','.bin','.dll','.png','.jpg','.webp','.exe')){'binary'}else{'utf8_lf'}
    if($Binding.hash_mode -cne $ExpectedMode){throw 'Source binding hash mode differs'}
}
if ($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha) { throw 'Engine pin differs' }
Assert-Hash $Engine $EngineSha
foreach($Profile in $Job.graphics_overrides.profiles.PSObject.Properties.Value) { Assert-Hash $Profile.source $Profile.sha256 }
if ([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.packet_bytes -ne $PacketCap) { throw 'Resource caps differ' }
if ($CpuStagePreflightFixture -or $CpuPacketFixture) {
    if ($Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false) { throw 'CPU mode requires NOT_ADMITTED packet' }
    if($CpuStagePreflightFixture) { Assert-Source }
    'CPU Hall night packet validation PASS; no engine launch.'; exit 0
}
if ($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.reviewed_by_thread -cne $ExpectedThread) { throw 'Explicit root admission required' }
Assert-Resources $true
Assert-NoForeignEngine
if ((Get-RunBytes $ArtifactDir) -gt $PacketCap) { throw 'Packet exceeds16MiB' }
$RunDir=[string]$Job.output_directory
$ExpectedRunDir=Join-Path $OutputRoot ('run-'+$Job.job_id)
if ([IO.Path]::GetFullPath($RunDir) -cne [IO.Path]::GetFullPath($ExpectedRunDir) -or (Test-Path -LiteralPath $RunDir)) { throw 'Output directory must be the declared fresh path' }
if (-not (Test-Path -LiteralPath $OwnerLockPath -PathType Leaf)) { throw 'Native owner lock file missing' }
$script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$Owner=Read-Owner
if ($Owner.thread -cne $ExpectedThread -or $Owner.source -cne $ExpectedSource -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved' }
try { Assert-NoForeignEngine; Assert-Resources $true; Assert-Source } catch { $script:OwnerLock.Dispose(); $script:OwnerLock=$null; throw }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $RunDir) | Out-Null
New-Item -ItemType Directory -Path $RunDir | Out-Null
$ReceiptPath=Join-Path $RunDir 'receipt.json'
$Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;engine_sha256=$EngineSha;started_utc=[DateTime]::UtcNow.ToString('o');capture_manifest=$Job.manifest_binding;source_preflight=$script:LastSourceAudit;steps=@();limits=@{C_admission_bytes=$CAdmissionFloor;C_stop_bytes=$CStopFloor;D_admission_bytes=$DAdmissionFloor;D_stop_bytes=$DStopFloor;memory_floor_bytes=$MemoryFloor;combined_logs_bytes=$CombinedLogsCap;output_bytes=$OutputCap}}
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
            Write-FailedStepReceipt $script:CurrentStepId $script:CurrentStepKind $FailExit $FailReason (Read-TerminalMetrics)
        } catch { $Receipt.failed_step=$script:CurrentStepId; $Receipt.stop_reason=$_.Exception.Message }
    }
    $Receipt.status='FAILED'; $Receipt.failure=$_.Exception.Message; $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o'); $Receipt.steps=@($script:StepReceipts)
    try { $Receipt.total_output_bytes=Get-RunBytes $RunDir; Write-JsonAtomic $ReceiptPath $Receipt } catch {}
    throw
} finally {
    if ($script:Proc -and -not $script:Proc.HasExited) {
        try { Stop-OwnedProcess 'failure cleanup'; $script:Proc.WaitForExit(10000) | Out-Null } catch { $Receipt.cleanup_blocked=$_.Exception.Message }
    }
    if ($script:LeaseOwned -and ((-not $script:Proc) -or $script:Proc.HasExited)) {
        try { Assert-NoForeignEngine; Update-Owner $true $script:LeasePid $script:LeaseRun; $script:LeaseOwned=$false } catch { $Receipt.cleanup_blocked=$_.Exception.Message; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    }
    if ($script:LeaseOwned) { $Receipt.lease_retained_for_live_or_unverified_child=$true; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    if ($script:Proc -and $script:Proc.HasExited) {
        try { Wait-OutputDrain $script:OutTask $script:ErrTask 2000 }
        catch {
            $Receipt.cleanup_output_drain_failure=$_.Exception.Message
            try { $script:Proc.StandardOutput.Close(); $script:Proc.StandardError.Close() } catch {}
            try { Write-JsonAtomic $ReceiptPath $Receipt } catch {}
        }
    }
    if ($script:OutStream) { $script:OutStream.Dispose() }; if ($script:ErrStream) { $script:ErrStream.Dispose() }
    if ($script:Proc) { $script:Proc.Dispose() }
    if ($script:OwnerLock) { $script:OwnerLock.Dispose() }
}

