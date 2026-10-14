param([string]$JobFile = 'job.json')

$ErrorActionPreference = 'Stop'

# F39 Tidewake-specific root admission supervisor. Jobs remain disabled until
# root reviews and admits the selected baseline or fight job explicitly.
$jobPath = if ([IO.Path]::IsPathRooted($JobFile)) { $JobFile } else {
    $candidate = Join-Path $PSScriptRoot $JobFile
    if (Test-Path -LiteralPath $candidate) { $candidate }
    else { Join-Path 'D:\tetherbound\.artifacts\codex-service-catalog\tidewake-capture-prepared-job' $JobFile }
}
$script:preparedRoot = Split-Path -Parent $jobPath
$job = Get-Content -LiteralPath $jobPath -Raw | ConvertFrom-Json
$git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$expectedSource = '3cd97b93ff51d8226b9e97a75dc642d49388f735'
$expectedFixtureSha = '43d95aac222887c73b394da1ec71b33939900247e2dcf14ea4418249b072db00'
$expectedLeaseThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$engineName = [IO.Path]::GetFileName([string]$job.runtime.engine)
$script:ownedPid = $null
$script:ownedCreated = $null
$script:leaseStream = $null
$script:leaseClaimed = $false
$script:leaseJson = $null
$script:leasePid = $null
$script:expectedCommandLine = $null
$script:peakWorkingSetBytes = 0L
$script:workingSetSampleCount = 0
$script:ownedIdentityVerified = $false
$script:preserveLeaseForRecovery = $false
$script:leaseRecoveryPreserved = $false
$script:unownedNativeEngines = @()

function Save-Json([string]$Path, $Value) {
    $Value | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Get-TreeBytes([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return [long]0 }
    $sum = Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
        Measure-Object -Property Length -Sum
    if ($null -eq $sum.Sum) { return [long]0 }
    return [long]$sum.Sum
}
function Get-FreeBytes([string]$Drive) {
    $driveName=$Drive.TrimEnd(':')
    return [long](Get-PSDrive -Name $driveName).Free
}
function Get-AvailableMemory {
    $mem = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory -OperationTimeoutSec 5
    if ($null -eq $mem -or $null -eq $mem.AvailableMBytes -or $null -eq $mem.CommitLimit -or $null -eq $mem.CommittedBytes) {
        throw 'Windows physical/commit memory telemetry unavailable.'
    }
    return [pscustomobject]@{
        physical_available_bytes = [long]$mem.AvailableMBytes * 1MB
        commit_headroom_bytes = [long]$mem.CommitLimit - [long]$mem.CommittedBytes
        commit_limit_bytes = [long]$mem.CommitLimit
        committed_bytes = [long]$mem.CommittedBytes
    }
}
function Get-ProcessCreationUtc($Process) {
    $creation = $Process.CreationDate
    if ($creation -is [DateTime]) { return $creation.ToUniversalTime() }
    return [Management.ManagementDateTimeConverter]::ToDateTime([string]$creation).ToUniversalTime()
}
function Get-ExactProcess([int]$ProcessId, [string]$Created) {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
    if (-not $p) { return $null }
    $createdUtc = Get-ProcessCreationUtc $p
    $recordedUtc = [DateTime]::Parse($Created).ToUniversalTime()
    if ([math]::Abs(($createdUtc - $recordedUtc).TotalSeconds) -gt 1.0) {
        throw "Owned PID $ProcessId creation time differs from its recorded launch identity; refusing to signal it."
    }
    $actualCmd = ([string]$p.CommandLine).Replace('"','').Trim()
    $expectedCmd = ([string]$script:expectedCommandLine).Replace('"','').Trim()
    if ($p.Name -cne $engineName -or $p.ExecutablePath -cne [string]$job.runtime.engine -or $actualCmd -cne $expectedCmd) {
        throw "Owned PID $ProcessId no longer matches the exact engine image/creation identity; refusing to signal it."
    }
    return $p
}
function Assert-Quiet {
    $busy = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot*' -or $_.Name -like 'blender*' })
    if ($busy.Count) {
        if ($script:leaseStream) {
            $script:unownedNativeEngines = @($busy | ForEach-Object { [ordered]@{name=$_.Name;process_id=[int]$_.ProcessId;executable_path=$_.ExecutablePath} })
            $script:preserveLeaseForRecovery = $true
        }
        throw ('Native process already active: ' + (($busy | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', '))
    }
}
function Test-ExactOwnedRecord($Process) {
    if (-not $script:ownedIdentityVerified -or -not $Process -or [int]$Process.ProcessId -ne [int]$script:ownedPid) { return $false }
    try {
        $createdUtc=Get-ProcessCreationUtc $Process
        $recordedUtc=[DateTime]::Parse($script:ownedCreated).ToUniversalTime()
        $actualCommand=([string]$Process.CommandLine).Replace('"','').Trim()
        $expectedCommand=([string]$script:expectedCommandLine).Replace('"','').Trim()
        return ($Process.Name -ceq $engineName -and $Process.ExecutablePath -ceq [string]$job.runtime.engine -and [math]::Abs(($createdUtc-$recordedUtc).TotalSeconds) -le 1.0 -and $actualCommand -ceq $expectedCommand)
    } catch { return $false }
}
function Invoke-TidewakeCleanupCapture([string]$Name, [scriptblock]$Action) {
    try {
        & $Action
        return $null
    } catch {
        return [pscustomobject]@{ name=$Name; error=$_.Exception.Message }
    }
}
function Get-TidewakeCanonicalPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'An approved output path is empty.' }
    $full = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    if ($full.Length -gt $root.Length) { $full = $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar) }
    return $full
}
function Assert-TidewakeNoReparseAncestors([string]$Path) {
    $cursor = Get-TidewakeCanonicalPath $Path
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Output path traverses a reparse point: $cursor" }
        }
        $parent = [IO.Directory]::GetParent($cursor)
        if ($null -eq $parent) { break }
        $cursor = $parent.FullName
    }
}
function Assert-TidewakeOutputPlanBinding([string]$PreparedRoot, $Job, $Plan) {
    $prepared = Get-TidewakeCanonicalPath $PreparedRoot
    if ((Get-TidewakeCanonicalPath ([string]$Job.paths.prepared_root)) -ine $prepared) { throw 'Prepared root differs from the supervisor-owned artifact root.' }
    $suffix = if ($Job.runtime.capture_set -ceq 'baseline') { 'runs' } elseif ($Job.runtime.capture_set -ceq 'fight') { 'fight-runs' } else { throw 'Unknown Tidewake output capture set.' }
    $approvedRoot = Get-TidewakeCanonicalPath (Join-Path $prepared $suffix)
    $outputRoot = Get-TidewakeCanonicalPath ([string]$Job.paths.output_root)
    if ($outputRoot -ine $approvedRoot) { throw 'Output root is outside the approved Tidewake capture root.' }
    foreach ($preset in @('High','Medium')) {
        $key = "$($preset.ToLowerInvariant())_output"
        $output = Get-TidewakeCanonicalPath ([string]$Job.paths.$key)
        $approved = Get-TidewakeCanonicalPath (Join-Path $approvedRoot $preset.ToLowerInvariant())
        if ($output -ine $approved) { throw "$preset output is outside the approved Tidewake capture root." }
        $matching = @($Plan.presets | Where-Object { $_.name -ceq $preset })
        if ($matching.Count -ne 1) { throw "Plan must contain exactly one $preset output row." }
        if ((Get-TidewakeCanonicalPath ([string]$matching[0].output)) -ine $approved) { throw "$preset plan output does not match the supervisor-approved output." }
        Assert-TidewakeNoReparseAncestors $approved
    }
    return $true
}
function Protect-LeaseForRecovery {
    if (-not $script:leaseStream) { throw 'Cannot preserve the Tidewake lease without its exclusive lock.' }
    $current = Get-Content -LiteralPath $job.native_lease.lease_path -Raw | ConvertFrom-Json
    if ($current.thread -cne $expectedLeaseThread) { throw 'Lease changed owner while preserving it for an unowned native process.' }
    if ($current.active_process_id) {
        if (-not $script:leaseClaimed -or $current.active_process_id -ne $script:leasePid -or $current.run_directory -cne $script:activeRunPath) {
            throw 'Active lease changed owner while preserving it for an unowned native process.'
        }
    } elseif ($script:leaseClaimed -or $current.run_directory) {
        throw 'Idle lease state changed while preserving it for an unowned native process.'
    }
    $current.active_process_id=$null; $current.active_session_id=$null; $current.active_kind=$null
    $current.processes=@(); $current.run_directory=$null
    $current.reserved=$true; $current.allow_native_launch=$false
    $current | Add-Member -NotePropertyName 'unowned_native_processes' -NotePropertyValue @($script:unownedNativeEngines) -Force
    $current.purpose='Tidewake capture stopped; unexpected unowned native process requires root recovery'
    $current.updated_utc=[DateTime]::UtcNow.ToString('o')
    $current | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $job.native_lease.lease_path -Encoding UTF8
    $script:leaseClaimed=$false; $script:leasePid=$null; $script:activeRunPath=$null
    $script:leaseRecoveryPreserved=$true
}
function Assert-OnlyOwnedNativeEngine {
    $busy = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object { $_.Name -like 'Godot*' -or $_.Name -like 'blender*' })
    $unexpected = @($busy | Where-Object { -not (Test-ExactOwnedRecord $_) })
    if ($unexpected.Count) {
        $script:unownedNativeEngines = @($unexpected | ForEach-Object { [ordered]@{name=$_.Name;process_id=[int]$_.ProcessId;executable_path=$_.ExecutablePath} })
        $script:preserveLeaseForRecovery = $true
        throw ('Unexpected concurrent native process; no ownership or stop authority: ' + (($unexpected | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', '))
    }
}
function Assert-DriveBudget([long]$RemainingDBytes) {
    $cUsed=Get-TreeBytes ([string]$job.paths.run_root)
    $cRemaining=[math]::Max(0,[long]$job.runtime.storage_budget_bytes_total_on_C-$cUsed)
    $dUsed=Get-TreeBytes ([string]$job.paths.output_root)
    $dRemaining=[math]::Max(0,$RemainingDBytes-$dUsed)
    $cNeed = [long]$job.runtime.drive_free_floor_bytes.'C:' + [long]$job.runtime.drive_extra_reserve_bytes.'C:' + $cRemaining
    $dNeed = [long]$job.runtime.drive_free_floor_bytes.'D:' + [long]$job.runtime.drive_extra_reserve_bytes.'D:' + $dRemaining
    if ((Get-FreeBytes 'C:') -lt $cNeed) { throw 'C: free-space floor plus 256 MiB reserve is not available.' }
    if ((Get-FreeBytes 'D:') -lt $dNeed) { throw "D: free-space floor plus reserve and remaining output budget ($RemainingDBytes bytes) is not available." }
}
function Assert-InputsAndSource {
    if ($job.schema -ne 'codex.native-job.v1' -or $job.job_id -notmatch '^F39-Tidewake-(baseline|fight)-v2-High-Medium$') { throw 'Unexpected job schema or identity.' }
    if ($job.capture_split_status -ne 'v2-scenic-and-fight-separated') { throw 'Root-reviewed v2 scenic/fight separation is required.' }
    if ($job.status -ne 'admitted' -or $job.launch_allowed -ne $true -or $job.root_admitted -ne $true -or $job.root_reviewed -ne $true) {
        throw 'Root admission is required; this prepared packet remains launch-disabled.'
    }
    if ($job.source.repo -cne 'C:\CodexTemp\tetherbound-native-service' -or $job.source.commit -cne $expectedSource -or $job.source.fixture_sha256 -cne $expectedFixtureSha) { throw 'Pinned native checkout/source/fixture identity differs from the reviewed F39 v2 packet.' }
    if (-not (Test-Path -LiteralPath $job.runtime.engine) -or -not (Test-Path -LiteralPath $git)) { throw 'Pinned Godot engine or git runtime is missing.' }
    if ((Get-FileHash -LiteralPath $job.runtime.engine -Algorithm SHA256).Hash.ToLowerInvariant() -cne $job.runtime.engine_sha256) { throw 'Pinned Godot executable SHA-256 differs.' }
    foreach ($entry in @(@{ path=$job.inputs.paired_jobs; sha=$job.inputs.paired_jobs_sha256 }, @{ path=$job.inputs.source_fingerprints; sha=$job.inputs.source_fingerprints_sha256 })) {
        if ((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.sha) { throw "Pinned input hash mismatch: $($entry.path)" }
    }
    $repo = [string]$job.source.repo
    $head = (& $git -C $repo rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -cne $expectedSource) { throw "Capture checkout HEAD mismatch: $head" }
    if (& $git -C $repo status --porcelain --untracked-files=no) { throw 'Capture checkout has tracked modifications.' }
    $fingerprints = Get-Content -LiteralPath $job.inputs.source_fingerprints -Raw | ConvertFrom-Json
    foreach ($entry in $fingerprints.capture_fixture_hashes) {
        $file = Join-Path $repo ([string]$entry.path)
        if (-not (Test-Path -LiteralPath $file) -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.sha256) { throw "Pinned capture fixture hash mismatch: $($entry.path)" }
    }
    $plan = Get-Content -LiteralPath $job.inputs.paired_jobs -Raw | ConvertFrom-Json
    Assert-TidewakeOutputPlanBinding $script:preparedRoot $job $plan | Out-Null
    $requiredCount = if ($job.runtime.capture_set -eq 'baseline') { 200 } elseif ($job.runtime.capture_set -eq 'fight') { 8 } else { throw 'Unknown v2 capture set.' }
    if ($plan.packet_schema -ne 'tidewake-f39-separated-capture-jobs-v2' -or $plan.capture_set -ne $job.runtime.capture_set -or $plan.status -ne 'planned' -or $plan.minimum_valid_actual_frames_per_preset -ne $requiredCount) { throw 'Separated capture plan is not the pinned v2 row contract.' }
    $expectedCli = @{
        High = @('--path',[string]$job.source.repo,'--rendering-method','forward_plus','--resolution','1920x1080','--script','tools/capture_f39_tidewake_matrix.gd','--',('--job-manifest='+([string]$job.inputs.paired_jobs).Replace('\','/')),'--preset=High',('--capture-set='+[string]$job.runtime.capture_set),('--source-commit='+$expectedSource),('--out='+([string]$job.paths.high_output).Replace('\','/')))
        Medium = @('--path',[string]$job.source.repo,'--rendering-method','forward_plus','--resolution','1920x1080','--script','tools/capture_f39_tidewake_matrix.gd','--',('--job-manifest='+([string]$job.inputs.paired_jobs).Replace('\','/')),'--preset=Medium',('--capture-set='+[string]$job.runtime.capture_set),('--source-commit='+$expectedSource),('--out='+([string]$job.paths.medium_output).Replace('\','/')))
    }
    foreach ($preset in @('High','Medium')) {
        if ((@($job.preset_args.$preset) -join "`n") -cne ($expectedCli[$preset] -join "`n")) { throw "Exact Godot argv mismatch for $preset." }
    }
}
function Enter-NativeLease {
    $lock = [string]$job.native_lease.lock_path
    if (-not (Test-Path -LiteralPath $lock) -or -not (Test-Path -LiteralPath $job.native_lease.lease_path)) { throw 'Root native lease or its lock file is unavailable.' }
    $script:leaseStream = [IO.File]::Open($lock, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $script:leaseJson = Get-Content -LiteralPath $job.native_lease.lease_path -Raw | ConvertFrom-Json
    if ($script:leaseJson.thread -cne $expectedLeaseThread -or $script:leaseJson.reserved -ne $true -or $script:leaseJson.allow_native_launch -ne $true -or $script:leaseJson.active_process_id -or @($script:leaseJson.processes).Count) {
        throw 'Exact root native lease is not admitted and idle for this task.'
    }
}
function Save-Lease {
    $script:leaseJson | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $job.native_lease.lease_path -Encoding UTF8
}
function Release-NativeLease {
    if ($script:leaseClaimed) {
        $current = Get-Content -LiteralPath $job.native_lease.lease_path -Raw | ConvertFrom-Json
        if ($current.thread -cne $expectedLeaseThread -or $current.active_process_id -ne $script:leasePid -or $current.run_directory -cne $script:activeRunPath) {
            throw 'Lease changed owner during capture; preserving it for root recovery.'
        }
        $current.active_process_id=$null; $current.active_session_id=$null; $current.active_kind=$null
        $current.processes=@(); $current.run_directory=$null; $current.purpose='Tidewake paired capture process exited; root review pending'
        $current.updated_utc=[DateTime]::UtcNow.ToString('o')
        $current | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $job.native_lease.lease_path -Encoding UTF8
        $script:leaseClaimed=$false
        $script:leasePid=$null
    }
    # Enter-NativeLease acquires one lock for the whole High/Medium transaction.
    # The outer finally owns its disposal after both presets have completed.
}
function Stop-OwnedProcess([string]$Reason) {
    if (-not $script:ownedPid) { return }
    $proc = Get-ExactProcess $script:ownedPid $script:ownedCreated
    if ($proc) { Stop-Process -Id $script:ownedPid -Force }
    $script:ownedPid=$null
    $script:ownedIdentityVerified=$false
    $script:stopReason=$Reason
}
function Invoke-Preset([string]$Preset, [long]$RemainingDBytes) {
    Assert-DriveBudget $RemainingDBytes
    Assert-Quiet
    $memory=Get-AvailableMemory
    if ($memory.physical_available_bytes -lt [long]$job.runtime.minimum_free_physical_memory_bytes) { throw 'Available physical memory is below the 2 GiB admission floor.' }
    if ($memory.commit_headroom_bytes -lt [long]$job.runtime.minimum_commit_headroom_bytes) { throw 'Windows commit headroom is below the 2 GiB admission floor.' }
    $outputKey = "$($Preset.ToLowerInvariant())_output"
    $runKey = "$($Preset.ToLowerInvariant())_run"
    $output = [string]$job.paths.$outputKey
    $run = [string]$job.paths.$runKey
    if ((Test-Path -LiteralPath $output) -or (Test-Path -LiteralPath $run)) { throw "$Preset output/run path is not fresh." }
    New-Item -ItemType Directory -Path $output,$run | Out-Null
    $home = Join-Path $run 'isolated-home'
    New-Item -ItemType Directory -Path $home | Out-Null
    $stdout = Join-Path $run 'engine.stdout.log'; $stderr = Join-Path $run 'engine.stderr.log'
    $previous = @{}
    foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','USERPROFILE','TEMP','TMP')) { $previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
    foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','USERPROFILE','TEMP','TMP')) { [Environment]::SetEnvironmentVariable($name,$home,'Process') }
    $args = @($job.preset_args.$Preset)
    $script:expectedCommandLine=([string]$job.runtime.engine)+' '+($args -join ' ')
    $script:peakWorkingSetBytes=0L
    $script:workingSetSampleCount=0
    $receiptPath = Join-Path $run 'launch-receipt.json'
    $receipt = [ordered]@{ status='RUNNING'; job_id=$job.job_id; preset=$Preset; source_commit=$expectedSource; fixture_sha256=$job.source.fixture_sha256; engine_sha256=$job.runtime.engine_sha256; argv=@([string]$job.runtime.engine)+$args; started_utc=[DateTime]::UtcNow.ToString('o'); pid=$null; image=$null; creation_utc=$null; stop_reason=$null }
    $primaryError = $null
    $cleanupFailures = [Collections.Generic.List[object]]::new()
    try {
        $p = Start-Process -FilePath $job.runtime.engine -ArgumentList $args -WorkingDirectory $job.source.repo -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $script:ownedPid=$p.Id
        $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $($p.Id)"
        $actualCommand=([string]$cim.CommandLine).Replace('"','').Trim()
        $expectedCommand=$script:expectedCommandLine.Replace('"','').Trim()
        if (-not $cim -or $cim.Name -cne $engineName -or $cim.ExecutablePath -cne [string]$job.runtime.engine -or $actualCommand -cne $expectedCommand) { throw 'Started PID does not identify the exact pinned Godot image and argv.' }
        $script:ownedCreated=(Get-ProcessCreationUtc $cim).ToString('o')
        $script:ownedIdentityVerified=$true
        $script:activeRunPath=$run
        $receipt.pid=$p.Id; $receipt.image=$cim.ExecutablePath; $receipt.creation_utc=$script:ownedCreated
        Save-Json $receiptPath $receipt
            $script:leaseJson.active_process_id=$p.Id; $script:leaseJson.active_session_id=$null; $script:leaseJson.active_kind='f39_tidewake_capture'
        $script:leaseJson.processes=@(@{pid=$p.Id;kind='f39_tidewake_capture';preset=$Preset})
        $script:leaseJson.run_directory=$run; $script:leaseJson.purpose="F39 Tidewake $($job.runtime.capture_set) $Preset capture"; $script:leaseJson.source=$expectedSource
        $script:leaseJson.updated_utc=[DateTime]::UtcNow.ToString('o'); Save-Lease; $script:leaseClaimed=$true; $script:leasePid=$p.Id
        Assert-OnlyOwnedNativeEngine
        $watch=[Diagnostics.Stopwatch]::StartNew(); $reason=$null
        while ($true) {
            Assert-OnlyOwnedNativeEngine
            $proc=Get-ExactProcess $p.Id $script:ownedCreated
            if (-not $proc) { break }
            Assert-DriveBudget $RemainingDBytes
            $memory=Get-AvailableMemory
            $freeMemory=[long]$memory.physical_available_bytes
            $commitHeadroom=[long]$memory.commit_headroom_bytes
            $workingSet=[long]$proc.WorkingSetSize
            $script:peakWorkingSetBytes=[math]::Max([long]$script:peakWorkingSetBytes,$workingSet)
            $script:workingSetSampleCount++
            $outBytes=Get-TreeBytes $output
            $runBytes=Get-TreeBytes $run
            $guard=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');preset=$Preset;pid=$p.Id;image=$cim.ExecutablePath;creation_utc=$script:ownedCreated;elapsed_seconds=[math]::Round($watch.Elapsed.TotalSeconds,2);free_physical_bytes=$freeMemory;commit_headroom_bytes=$commitHeadroom;working_set_bytes=$workingSet;peak_working_set_bytes=$script:peakWorkingSetBytes;working_set_sample_count=$script:workingSetSampleCount;output_bytes=$outBytes;run_bytes=$runBytes}
            Save-Json (Join-Path $run 'latest-resource-guard.json') $guard
            if ($freeMemory -lt [long]$job.runtime.minimum_free_physical_memory_bytes) { $reason='available_memory_below_2GiB'; break }
            if ($commitHeadroom -lt [long]$job.runtime.minimum_commit_headroom_bytes) { $reason='commit_headroom_below_2GiB'; break }
            if ($null -ne $job.runtime.maximum_engine_working_set_bytes -and $workingSet -gt [long]$job.runtime.maximum_engine_working_set_bytes) { $reason='engine_working_set_over_configured_cap'; break }
            if ($outBytes -gt [long]$job.runtime.storage_budget_bytes_per_preset) { $reason='output_over_1GiB'; break }
            if ($runBytes -gt ([long]$job.runtime.log_budget_bytes_per_preset+[long]$job.runtime.isolated_home_budget_bytes_per_preset)) { $reason='run_logs_or_isolated_home_over_192MiB'; break }
            if ($watch.Elapsed.TotalSeconds -ge [long]$job.runtime.wall_cap_seconds_per_preset) { $reason='wall_cap_10800_seconds'; break }
            Start-Sleep -Seconds 3
        }
        if ($reason) { Stop-OwnedProcess $reason; $p.WaitForExit() }
        else { $p.WaitForExit() }
        $p.Refresh()
        $receipt.status=if ($reason) {'STOPPED_BY_SUPERVISOR'} elseif ($p.ExitCode -eq 0) {'ENGINE_EXITED_ZERO_AWAITING_RESULT_REVIEW'} else {'ENGINE_FAILED'}
        $receipt.exit_code=$p.ExitCode; $receipt.stop_reason=$reason; $receipt.peak_working_set_bytes=$script:peakWorkingSetBytes
        $receipt.working_set_sample_count=$script:workingSetSampleCount; $receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
        Save-Json (Join-Path $run 'supervisor-result.json') $receipt
        Release-NativeLease
        if ($reason -or $p.ExitCode -ne 0) { throw "$Preset capture ended without clean completion ($($receipt.status))." }
    } catch {
        $primaryError=$_.Exception
        $receipt.status='FAILED'; $receipt.failure=$primaryError.Message; $receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
        if ($script:ownedPid) {
            $failure = Invoke-TidewakeCleanupCapture 'stop_owned_process_after_primary_failure' { Stop-OwnedProcess 'supervisor_exception' }
            if ($failure) { $cleanupFailures.Add($failure) }
        }
    } finally {
        foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_CONFIG_HOME','XDG_DATA_HOME','USERPROFILE','TEMP','TMP')) {
            $capturedName=$name; $capturedValue=$previous[$name]
            $failure = Invoke-TidewakeCleanupCapture "restore_environment_$capturedName" { [Environment]::SetEnvironmentVariable($capturedName,$capturedValue,'Process') }
            if ($failure) { $cleanupFailures.Add($failure) }
        }
        if ($script:ownedPid) {
            $failure = Invoke-TidewakeCleanupCapture 'stop_owned_process_in_finally' { Stop-OwnedProcess 'finally_cleanup' }
            if ($failure) { $cleanupFailures.Add($failure) }
        }
        if ($script:leaseClaimed) {
            if ($script:preserveLeaseForRecovery) { $action = { Protect-LeaseForRecovery } }
            else { $action = { Release-NativeLease } }
            $failure = Invoke-TidewakeCleanupCapture 'release_or_preserve_native_lease' $action
            if ($failure) { $cleanupFailures.Add($failure) }
        }
        if ($cleanupFailures.Count) {
            $receipt.cleanup_failures=@($cleanupFailures)
            if (-not $primaryError) { $receipt.status='FAILED_CLEANUP' }
        }
        if (Test-Path -LiteralPath $run) {
            $failure = Invoke-TidewakeCleanupCapture 'write_supervisor_result_receipt' { Save-Json (Join-Path $run 'supervisor-result.json') $receipt }
            if ($failure) {
                $cleanupFailures.Add($failure)
                if ($primaryError) { $receipt.failure_receipt_write_failure=$failure.error }
            }
        }
    }
    if ($primaryError) { throw $primaryError }
    if ($cleanupFailures.Count) { throw [InvalidOperationException]::new('Tidewake capture cleanup failed: ' + (($cleanupFailures | ForEach-Object { "$($_.name): $($_.error)" }) -join '; ')) }
}

Assert-InputsAndSource
Assert-Quiet
$memory=Get-AvailableMemory
if ($memory.physical_available_bytes -lt [long]$job.runtime.minimum_free_physical_memory_bytes) { throw 'Available physical memory is below the 2 GiB admission floor.' }
if ($memory.commit_headroom_bytes -lt [long]$job.runtime.minimum_commit_headroom_bytes) { throw 'Windows commit headroom is below the 2 GiB admission floor.' }
$totalCap=[long]$job.runtime.storage_budget_bytes_total
Assert-DriveBudget $totalCap
$outerError = $null
$outerCleanupFailure = $null
try {
    Enter-NativeLease
    Invoke-Preset 'High' $totalCap
    Invoke-Preset 'Medium' $totalCap
} catch {
    $outerError=$_.Exception
} finally {
    if ($script:preserveLeaseForRecovery -and -not $script:leaseRecoveryPreserved -and $script:leaseStream) {
        $failure=Invoke-TidewakeCleanupCapture 'preserve_idle_native_lease_for_recovery' { Protect-LeaseForRecovery }
        if ($failure) {
            if ($outerCleanupFailure) { Write-Warning "Additional cleanup failure: $($failure.error)" }
            else { $outerCleanupFailure=$failure }
        }
    }
    if ($script:leaseStream) {
        $stream=$script:leaseStream
        $failure=Invoke-TidewakeCleanupCapture 'dispose_outer_native_lease_lock' { $stream.Dispose(); $script:leaseStream=$null }
        if ($failure) {
            if ($outerCleanupFailure) { Write-Warning "Additional cleanup failure: $($failure.error)" }
            else { $outerCleanupFailure=$failure }
        }
    }
}
if ($outerError) {
    if ($outerCleanupFailure) { Write-Warning "Secondary cleanup failure: $($outerCleanupFailure.error)" }
    throw $outerError
}
if ($outerCleanupFailure) { throw [InvalidOperationException]::new("Tidewake outer cleanup failed: $($outerCleanupFailure.error)") }
$validator = if ($job.runtime.capture_set -eq 'baseline') { 'validate_results.py' } else { 'validate_fight_results.py' }
Write-Host "Both bounded preset processes exited zero. Run $validator before treating the capture as complete."
