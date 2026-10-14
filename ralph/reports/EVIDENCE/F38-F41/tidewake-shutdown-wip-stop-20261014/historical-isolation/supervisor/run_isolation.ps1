param([switch]$CpuStagePreflightFixture,[switch]$CpuPacketFixture)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Run this supervisor with PowerShell 7 or newer' }
$ArtifactDir = $PSScriptRoot
$JobPath = Join-Path $ArtifactDir 'native-job.json'
$AdmissionPath = Join-Path $ArtifactDir 'native-admission.json'
$Stage = 'D:/tetherbound/.artifacts/s/run-twquit-isolation-bf81-r1/project'
$OutputRoot = 'D:\tetherbound\.artifacts\s'
$OwnerPath = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource = 'bf81ab6255b0b49a639bb39477e8009cb1b06793'
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
$script:IncomingLeaseSource = $null
$script:LeaseSourceCaptured = $false
$script:OwnerReadHash = $null
$script:CurrentStepId = $null
$script:ObservedStopReason = $null
$script:IdentityFailure = $null
$script:IdentityRejected = $false
$script:ExpectedArgs = @()
$script:TerminalElapsed = $null
$script:DrainAttempted = $false
$script:DrainComplete = $false
$script:StepReceipts = @()
$script:LogPaths = @()
$script:MinPhysical = [long]::MaxValue
$script:MinCommit = [long]::MaxValue
$script:MinC = [long]::MaxValue
$script:MinD = [long]::MaxValue

function Read-Json([string]$Path) { Get-Content -LiteralPath $Path -Raw -Encoding utf8 | ConvertFrom-Json }
function Write-JsonAtomic([string]$Path, $Value) {
    $Temp = "$Path.$([Guid]::NewGuid().ToString('N')).tmp"
    $Value | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $Temp -Encoding utf8
    if (Test-Path -LiteralPath $Path -PathType Leaf) { $Backup="$Path.$([Guid]::NewGuid().ToString('N')).bak"; [IO.File]::Replace($Temp, $Path, $Backup); Remove-Item -LiteralPath $Backup -Force } else { [IO.File]::Move($Temp, $Path) }
}
function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
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
function Assert-Source {
    foreach ($RootPath in @([string]$Job.project_template,$Stage)) {
        if ($RootPath -ceq $Stage -and -not (Test-Path -LiteralPath $Stage)) { continue }
        $RootFull=[IO.Path]::GetFullPath($RootPath).TrimEnd('\')+'\'
        foreach ($Binding in $Job.project_bindings) {
            $File=[IO.Path]::GetFullPath((Join-Path $RootPath ([string]$Binding.path)))
            if (-not $File.StartsWith($RootFull,[StringComparison]::OrdinalIgnoreCase)) { throw 'Project binding escapes isolated root' }
            Assert-Hash $File ([string]$Binding.sha256)
        }
    }
}
function Complete-LogDrain {
    if ($script:DrainAttempted) {
        if (-not $script:DrainComplete) { throw 'Previous log drain failed; no unbounded/repeated retry' }
        return
    }
    $script:DrainAttempted=$true
    $Tasks=[Threading.Tasks.Task[]]@(@($script:OutTask,$script:ErrTask) | Where-Object { $null -ne $_ })
    if ($Tasks.Count -gt 0) {
        $Combined=[Threading.Tasks.Task]::WhenAll($Tasks)
        if (-not $Combined.Wait(5000)) { throw 'stdout/stderr drain exceeded 5s bound' }
    }
    $script:DrainComplete=$true
}
function Assert-TerminalElapsed([double]$Elapsed,[int]$Cap) {
    if ([double]::IsNaN($Elapsed) -or [double]::IsInfinity($Elapsed) -or $Elapsed -lt 0 -or $Elapsed -gt $Cap) {
        throw "Terminal observed elapsed $Elapsed exceeds valid 0..$Cap seconds"
    }
}
function Record-IdentityFailure([string]$Reason,$Rows) {
    $Actual=@($Rows | ForEach-Object {
        @{pid=$_.ProcessId;parent_pid=$_.ParentProcessId;executable_path=$_.ExecutablePath;command_line=$_.CommandLine;created_utc=if($_.CreationDate -is [DateTime]){$_.CreationDate.ToUniversalTime().ToString('o')}else{[string]$_.CreationDate}}
    })
    $script:IdentityFailure=@{reason=$Reason;expected=@{pid=$script:ProcId;parent_pid=$script:RunnerPid;executable_path=$Engine;arguments=@($script:ExpectedArgs);established_command_line=$script:CommandLine;created_utc=if($script:ProcStartUtc){$script:ProcStartUtc.ToString('o')}else{$null}};actual=$Actual}
    $script:IdentityRejected=$true
    $script:ObservedStopReason=$Reason
    Write-JsonAtomic (Join-Path $RunDir ($script:CurrentStepId+'.identity-failure.json')) $script:IdentityFailure
}
function Read-Owner {
    $Bytes=[IO.File]::ReadAllBytes($OwnerPath)
    $script:OwnerReadHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
    [Text.Encoding]::UTF8.GetString($Bytes).TrimStart([char]0xFEFF) | ConvertFrom-Json
}
function Assert-IdleOwner($Owner) {
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
}
function Capture-LeaseSource($Owner) {
    Assert-IdleOwner $Owner
    if ($Owner.source -isnot [string] -or [string]::IsNullOrWhiteSpace($Owner.source)) { throw 'Incoming native lease source missing' }
    if ($script:LeaseSourceCaptured) { Assert-LeaseSource $Owner; return }
    # Capture once under the owner lock, for the entire parser/component job.
    # This is lease metadata; do not query or require a shared-stage checkout.
    $script:IncomingLeaseSource=$Owner.source
    $script:LeaseSourceCaptured=$true
}
function Assert-LeaseSource($Owner) {
    if (-not $script:LeaseSourceCaptured -or $Owner.source -isnot [string] -or $Owner.source -cne $script:IncomingLeaseSource) { throw 'Native lease source changed; refusing lease write' }
}
function Write-OwnerChecked($Owner) {
    Assert-LeaseSource $Owner
    # The exclusive owner lock spans the job. Also reject a replaced JSON
    # snapshot before writing, so an observed concurrent change is not lost.
    if (-not $script:OwnerReadHash -or (Hash-File $OwnerPath) -cne $script:OwnerReadHash) { throw 'Native lease snapshot changed; refusing lease write' }
    Write-JsonAtomic $OwnerPath $Owner
}
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    Assert-IdleOwner $Owner
    Assert-LeaseSource $Owner
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='tidewake_diagnostic_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='tidewake_diagnostic_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.purpose='Ground-cover/Terrain native deletion isolation; process starting'
    $Owner | Add-Member -NotePropertyName isolated_source -NotePropertyValue $ExpectedSource -Force
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-OwnerChecked $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    Assert-LeaseSource $Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid -or $Owner.isolated_source -cne $ExpectedSource) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='tidewake_diagnostic_witness'
    $Owner.processes=@(@{pid=$PidValue;kind='tidewake_diagnostic_witness';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Single-region Terrain native deletion isolation; owned child recorded'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-OwnerChecked $Owner
    $script:LeasePid=$PidValue
}
function Update-Owner([bool]$Release,[int]$PidValue=0,[string]$RunId='') {
    if (-not $Release) { throw 'Use Claim-Owner for an idle lease; alternate claim path disabled' }
    $Owner=Read-Owner
    Assert-LeaseSource $Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) { throw 'Exact native lease authorization changed' }
    if ([int]$Owner.active_process_id -ne $PidValue -or $Owner.run_id -cne $RunId -or $Owner.isolated_source -cne $ExpectedSource) { throw 'Refusing to release another run lease' }
    $Owner.active_process_id=$null; $Owner.active_session_id=$null; $Owner.active_kind=$null; $Owner.processes=@(); $Owner.run_directory=$null; $Owner.run_id=$null
    $Owner.purpose='Service lane reserved; no native writer'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o')
    Write-OwnerChecked $Owner
}
function Assert-OwnedCim {
    if (-not $script:Proc) { throw 'No owned process handle' }
    if ($script:Proc.HasExited) { return $null }
    $Rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Rows.Count -ne 1) { $script:Proc.Refresh(); if ($script:Proc.HasExited) { return $null }; Record-IdentityFailure 'Owned live process CIM identity unavailable' $Rows; throw 'Owned live process CIM identity unavailable' }
    $Row=$Rows[0]
    if ([string]::IsNullOrWhiteSpace([string]$Row.ExecutablePath)) {
        $script:Proc.Refresh()
        if ($script:Proc.HasExited) { return $null }
        Record-IdentityFailure 'Owned live process executable identity unavailable' $Rows; throw 'Owned live process executable identity unavailable; refusing termination'
    }
    if ([int]$Row.ParentProcessId -ne $script:RunnerPid -or [IO.Path]::GetFullPath([string]$Row.ExecutablePath) -cne [IO.Path]::GetFullPath($Engine) -or [string]$Row.CommandLine -cne $script:CommandLine) { Record-IdentityFailure 'Owned process parent, image or full command line changed' $Rows; throw 'Owned process parent, image or full command line changed; refusing termination' }
    $Creation=if ($Row.CreationDate -is [DateTime]) {$Row.CreationDate.ToUniversalTime()} else {[Management.ManagementDateTimeConverter]::ToDateTime([string]$Row.CreationDate).ToUniversalTime()}
    if ([Math]::Abs(($Creation-$script:ProcStartUtc).TotalSeconds) -gt 1.0) { Record-IdentityFailure 'Owned process creation time changed' $Rows; throw 'Owned process creation time changed; refusing termination' }
    return $Row
}
function Stop-OwnedProcess([string]$Reason,[switch]$InjectFailureForCpuFixture) {
    if (-not $script:Proc -or $script:Proc.HasExited) { return }
    if ($script:IdentityRejected) { throw 'Identity rejected; refusing ambiguous termination and retaining native lease' }
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
    $StepReceipt=[ordered]@{id=$StepId;kind=$Kind;status='FAILED';pid=$script:ProcId;created_utc=if($script:ProcStartUtc){$script:ProcStartUtc.ToString('o')}else{$null};observed_command_line=$script:CommandLine;exit_code=$ExitCode;stop_reason=$StopReason;identity_failure=$script:IdentityFailure;terminal_observed_wall_seconds=$script:TerminalElapsed;terminal_metrics=$TerminalMetrics;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD}
    if ($script:OutPath -and (Test-Path -LiteralPath $script:OutPath -PathType Leaf)) { $StepReceipt.stdout=$script:OutPath; $StepReceipt.stdout_sha256=Hash-File $script:OutPath }
    if ($script:ErrPath -and (Test-Path -LiteralPath $script:ErrPath -PathType Leaf)) { $StepReceipt.stderr=$script:ErrPath; $StepReceipt.stderr_sha256=Hash-File $script:ErrPath }
    $script:StepReceipts+=,$StepReceipt
    $Receipt.failed_step=$StepId; $Receipt.stop_reason=$StopReason; $Receipt.terminal_metrics=$TerminalMetrics
    $Receipt.failed_step_exit_code=$ExitCode; $Receipt.steps=@($script:StepReceipts); $Receipt.status='FAILED'
    $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
    try { $Receipt.total_output_bytes=Get-RunBytes $RunDir } catch { $Receipt.output_size_error=$_.Exception.Message }
    Write-JsonAtomic $ReceiptPath $Receipt
}

function Read-IsolationPhases([string]$Stdout) {
    $Prefix='TERRAIN DELETE ISOLATION '
    $Records=@($Stdout -split "`r?`n" | Where-Object { $_.StartsWith($Prefix,[StringComparison]::Ordinal) } | ForEach-Object { $_.Substring($Prefix.Length) | ConvertFrom-Json })
    $Expected=@('rendered_live_component','quit_requested','cover_tree_exited_before_delete','terrain_tree_exited_before_delete','root_tree_exited_before_delete','root_deleted_and_queue_flushed')
    if (($Records.phase -join ',') -cne ($Expected -join ',')) { throw 'Isolation lifecycle phase sequence incomplete or duplicated' }
    if ($Records[0].regions -ne 1 -or $Records[0].collision_shapes -le 0 -or $Records[0].map_rids_valid -ne $true -or $Records[0].renderer -cne 'forward_plus') { throw 'Live component did not meet isolation preconditions' }
    $Cover=$Records[0].cover
    if($null -eq $Cover -or $Cover.ready -ne $true -or $Cover.bound -ne $true -or $Cover.materials -ne 4 -or $Cover.map_bindings_match -ne $true -or $Cover.tile_nodes -le 0 -or $Cover.grass_instances -le 0 -or $Cover.instances -le $Cover.grass_instances){throw 'Ground cover did not meet binding/resource preconditions'}
    if($Cover.tile_nodes -ne 148 -or $Cover.grass_instances -ne 32748 -or $Cover.instances -ne 47612){throw 'Ground cover population differs from reviewed explicit-free baseline'}
    $Quit=$Records[1]
    if($Quit.explicit_free -ne $false -or $Quit.cover_alive_in_tree -ne $true -or $Quit.terrain_alive_in_tree -ne $true -or $Quit.rig_alive_in_tree -ne $true){throw 'Normal quit requires all components still alive in tree'}
    foreach($Record in $Records){if(($Record.ticks_usec -isnot [int] -and $Record.ticks_usec -isnot [long]) -or $Record.ticks_usec -lt 0){throw 'Lifecycle timestamp missing or invalid'}}
    for($i=1;$i -lt $Records.Count;$i++){ if([long]$Records[$i].ticks_usec -lt [long]$Records[$i-1].ticks_usec){throw 'Lifecycle timestamps reversed'} }
    if($Records[-1].setup_failed -ne $false){throw 'Probe setup failed'}
    return $Records
}
function Run-Step($Step) {
    $script:CurrentStepId=[string]$Step.id; $script:ObservedStopReason=$null; $script:OutPath=$null; $script:ErrPath=$null
    $script:IdentityFailure=$null; $script:IdentityRejected=$false; $script:TerminalElapsed=$null; $script:DrainAttempted=$false; $script:DrainComplete=$false
    Assert-Source
    Assert-Hash $Engine $EngineSha
    Assert-Resources $true
    Assert-NoForeignEngine
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir ('h'+[array]::IndexOf($Job.steps,$Step))
    if ($StepId -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
    New-Item -ItemType Directory -Path $HomeDir | Out-Null
    $OutPath=Join-Path $RunDir ($StepId+'.stdout.log'); $ErrPath=Join-Path $RunDir ($StepId+'.stderr.log')
    $script:OutPath=$OutPath; $script:ErrPath=$ErrPath
    $script:LogPaths+=@($OutPath,$ErrPath)
    $CaptureResult=$null
    $StepArgs=@($Step.args | ForEach-Object { [string]$_ })
    $script:ExpectedArgs=$StepArgs
    $StartInfo=[Diagnostics.ProcessStartInfo]::new(); $StartInfo.FileName=$Engine; $StartInfo.WorkingDirectory=$Stage
    $StartInfo.UseShellExecute=$false; $StartInfo.CreateNoWindow=$true; $StartInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $StartInfo.RedirectStandardOutput=$true; $StartInfo.RedirectStandardError=$true
    foreach ($Arg in $StepArgs) { $StartInfo.ArgumentList.Add($Arg) }
    foreach ($Name in @('USERPROFILE','HOME','APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','TEMP','TMP')) { $StartInfo.Environment[$Name]=$HomeDir }
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
    $Initial=$null; $Rows=@()
    for ($Try=0; $Try -lt 20 -and -not $Initial; $Try++) {
        if ($Proc.HasExited) { break }
        $Rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
        if ($Rows.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace([string]$Rows[0].ExecutablePath) -and -not [string]::IsNullOrWhiteSpace([string]$Rows[0].CommandLine) -and $Rows[0].CreationDate) { $Initial=$Rows[0] } else { Start-Sleep -Milliseconds 100 }
    }
    if (-not $Initial) { Record-IdentityFailure 'initial CIM readiness failed' $Rows; Stop-OwnedProcess 'initial CIM readiness failed'; throw 'No complete initial CIM identity before startup timeout/exit' }
    $ObservedCommand=[string]$Initial.CommandLine
    $ExpectedSuffix=$StepArgs -join ' '
    $QuotedPrefix='"'+$Engine+'" '
    $PlainPrefix=$Engine+' '
    $ArgvMatches=($ObservedCommand.StartsWith($QuotedPrefix,[StringComparison]::Ordinal) -and $ObservedCommand.Substring($QuotedPrefix.Length) -ceq $ExpectedSuffix) -or ($ObservedCommand.StartsWith($PlainPrefix,[StringComparison]::Ordinal) -and $ObservedCommand.Substring($PlainPrefix.Length) -ceq $ExpectedSuffix)
    if ([int]$Initial.ParentProcessId -ne $script:RunnerPid -or [IO.Path]::GetFullPath([string]$Initial.ExecutablePath) -cne [IO.Path]::GetFullPath($Engine) -or -not $ArgvMatches) { Record-IdentityFailure 'initial identity or argv verification failed' @($Initial); Stop-OwnedProcess 'identity or argv verification failed'; throw 'Initial process parent, image or exact argv differs from job' }
    $InitTime=if ($Initial.CreationDate -is [DateTime]) {$Initial.CreationDate.ToUniversalTime()} else {[Management.ManagementDateTimeConverter]::ToDateTime([string]$Initial.CreationDate).ToUniversalTime()}
    if ([Math]::Abs(($InitTime-$script:ProcStartUtc).TotalSeconds) -gt 1.0) { Record-IdentityFailure 'initial creation-time verification failed' @($Initial); Stop-OwnedProcess 'creation-time verification failed'; throw 'Initial CIM creation time differs from owned process handle' }
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
    $Proc.WaitForExit()
    $script:TerminalElapsed=$Timer.Elapsed.TotalSeconds
    try { Assert-TerminalElapsed $script:TerminalElapsed ([int]$Step.wall_seconds) }
    catch { $StopReason=$_.Exception.Message; $script:ObservedStopReason=$StopReason }
    Complete-LogDrain
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
    if (-not [string]::IsNullOrWhiteSpace($Stderr)) { throw "Isolation stderr must be empty" }
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
    if ($Step.kind -eq 'diagnostic') { $CaptureResult=@(Read-IsolationPhases $Stdout) }
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($script:TerminalElapsed,3);supervisor_elapsed_with_drain_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);identity_failure=$script:IdentityFailure;capture=$CaptureResult;stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD}
    $script:StepReceipts+=,$StepReceipt
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}


$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
if ($Job.schema -cne 'codex.tidewake-terrain-isolation-native-run.v1' -or $Job.job_id -cne 'twquit-isolation-bf81-r1' -or $Job.source_commit -cne $ExpectedSource -or $Job.supervisor_sha256 -cne (Hash-File $PSCommandPath) -or $Admission.job_sha256 -cne (Hash-File $JobPath)) { throw 'Exact source/job/supervisor admission binding required' }
foreach($Binding in $Job.packet_bindings){Assert-Hash $Binding.path $Binding.sha256}
if($Job.steps.Count -ne 2 -or $Job.project_bindings.Count -ne 21){throw 'Exact two-step 21-file isolated project required'}
$Parser=$Job.steps[0];$Diagnostic=$Job.steps[1]
$ExpectedParser=@('--headless','--path',$Stage,'--check-only','--script','res://probe.gd')
$ExpectedDiagnostic=@('--path',$Stage,'--rendering-method','forward_plus','--resolution','320x180','--script','res://probe.gd')
if($Parser.id -cne 'isolation-parser' -or $Parser.kind -cne 'parser' -or $Parser.wall_seconds -ne 60 -or ($Parser.args -join "`n") -cne ($ExpectedParser -join "`n")){throw 'Exact 60s isolated parser required'}
if($Diagnostic.id -cne 'normal-quit' -or $Diagnostic.kind -cne 'diagnostic' -or $Diagnostic.wall_seconds -ne 60 -or ($Diagnostic.args -join "`n") -cne ($ExpectedDiagnostic -join "`n")){throw 'Exact 60s single-region diagnostic required'}
if ($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha) { throw 'Engine pin differs' }
Assert-Hash $Engine $EngineSha
Assert-Source
if ([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.packet_bytes -ne $PacketCap) { throw 'Resource caps differ' }
if ($CpuStagePreflightFixture -or $CpuPacketFixture) {
    if ($Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false) { throw 'CPU mode requires NOT_ADMITTED packet' }
    if($CpuStagePreflightFixture) { Assert-Source }
    'CPU isolated Terrain packet PASS; parser60s + component60s; no engine launch.'; exit 0
}
if ($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.reviewed_by_thread -cne $ExpectedThread) { throw 'Explicit root admission required' }
Assert-Source
Assert-Resources $true
Assert-NoForeignEngine
if ((Get-RunBytes $ArtifactDir) -gt $PacketCap) { throw 'Packet exceeds16MiB' }
$RunDir=[string]$Job.output_directory
$ExpectedRunDir=Join-Path $OutputRoot ('run-'+$Job.job_id)
if ([IO.Path]::GetFullPath($RunDir) -cne [IO.Path]::GetFullPath($ExpectedRunDir) -or (Test-Path -LiteralPath $RunDir)) { throw 'Output directory must be the declared fresh path' }
if (-not (Test-Path -LiteralPath $OwnerLockPath -PathType Leaf)) { throw 'Native owner lock file missing' }
$script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$Owner=Read-Owner
Capture-LeaseSource $Owner
Assert-NoForeignEngine; Assert-Resources $true
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $RunDir) | Out-Null
New-Item -ItemType Directory -Path $RunDir | Out-Null
# Fresh isolated project copy only; shared native stage is never read or changed.
New-Item -ItemType Directory -Path $Stage | Out-Null
foreach($Binding in $Job.project_bindings){
    $Dest=Join-Path $Stage ([string]$Binding.path)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
    Copy-Item -LiteralPath (Join-Path ([string]$Job.project_template) ([string]$Binding.path)) -Destination $Dest
}
Assert-Source
$ReceiptPath=Join-Path $RunDir 'receipt.json'
$Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;isolated_source=$ExpectedSource;incoming_owner_source=$script:IncomingLeaseSource;engine_sha256=$EngineSha;started_utc=[DateTime]::UtcNow.ToString('o');capture_manifest=$Job.manifest_binding;steps=@();limits=@{C_admission_bytes=$CAdmissionFloor;C_stop_bytes=$CStopFloor;D_admission_bytes=$DAdmissionFloor;D_stop_bytes=$DStopFloor;memory_floor_bytes=$MemoryFloor;combined_logs_bytes=$CombinedLogsCap;output_bytes=$OutputCap}}
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
        try { Stop-OwnedProcess 'failure cleanup'; $script:Proc.WaitForExit(10000) | Out-Null } catch { $Receipt.cleanup_blocked=$_.Exception.Message }
    }
    if ($script:LeaseOwned -and ((-not $script:Proc) -or $script:Proc.HasExited)) {
        try { Assert-NoForeignEngine; Update-Owner $true $script:LeasePid $script:LeaseRun; $script:LeaseOwned=$false } catch { $Receipt.cleanup_blocked=$_.Exception.Message; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    }
    if ($script:LeaseOwned) { $Receipt.lease_retained_for_live_or_unverified_child=$true; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    if ($script:Proc -and $script:Proc.HasExited) {
        try { $script:Proc.WaitForExit(); Complete-LogDrain } catch { $Receipt.cleanup_blocked=$_.Exception.Message; try { Write-JsonAtomic $ReceiptPath $Receipt } catch {} }
    }
    if ($script:OutStream) { $script:OutStream.Dispose() }; if ($script:ErrStream) { $script:ErrStream.Dispose() }
    if ($script:Proc) { $script:Proc.Dispose() }
    if ($script:OwnerLock) { $script:OwnerLock.Dispose() }
}

