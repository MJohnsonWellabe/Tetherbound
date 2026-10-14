param([switch]$CpuPacketFixture,[switch]$CpuStagePreflightFixture)
$ErrorActionPreference = 'Stop'
$ArtifactDir = $PSScriptRoot
$JobPath = Join-Path $ArtifactDir 'native-job.json'
$AdmissionPath = Join-Path $ArtifactDir 'native-admission.json'
$Stage = 'C:\CodexTemp\tetherbound-native-service'
$OutputRoot = 'D:\tetherbound\.artifacts\s'
$OwnerPath = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$ExpectedSource = 'd36d754d93bf56414d9b954b31d896476c580c5d'
$ExpectedParent = 'a68604c0253fde9fd04cc8fba6379885c90b7bc4'
$ExpectedBase = 'b6f19b4da9d6f2a9761708aa95ffb12c0244d41c'
if ($CpuCleanupFixture) {
    $FixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('systems-lease-fixture-'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $FixtureRoot | Out-Null
    $FixtureHome=Join-Path $FixtureRoot 'home-step'; New-Item -ItemType Directory -Path $FixtureHome | Out-Null
    if (-not (Test-Path -LiteralPath $FixtureHome -PathType Container)) { throw 'CPU fixture failed to create isolated step home' }
    $OwnerPath=Join-Path $FixtureRoot 'owner.json'; $OwnerLockPath=Join-Path $FixtureRoot 'owner.lock'
    [IO.File]::WriteAllText($OwnerLockPath,'fixture')
    @{thread=$ExpectedThread;reserved=$true;allow_native_launch=$true;active_process_id=$null;active_session_id=$null;active_kind=$null;processes=@();run_directory=$null;run_id=$null;source=$ExpectedSource;purpose='fixture';updated_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath $OwnerPath -Encoding utf8
}
$Engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$EngineSha = 'b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8'
$Git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$CAdmissionFloor = 10.5GB
$CStopFloor = 10GB
$DAdmissionFloor = 21GB
$DStopFloor = 20GB
$MemoryFloor = 2GB
$CombinedLogsCap = 32MB
$OutputCap = 1GB
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
    [IO.File]::Move($Temp, $Path, $true)
}
function Hash-File([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Hash([string]$Path,[string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Pinned file is missing: $Path" }
    if ((Hash-File $Path) -cne $Expected.ToLowerInvariant()) { throw "SHA-256 mismatch: $Path" }
}
function Invoke-Git([string[]]$GitArgs) {
    $OldLazy=$env:GIT_NO_LAZY_FETCH; $OldOptional=$env:GIT_OPTIONAL_LOCKS
    try { $env:GIT_NO_LAZY_FETCH='1'; $env:GIT_OPTIONAL_LOCKS='0'; $Text=@(& $Git -C $Stage -c core.fsmonitor=false -c core.preloadindex=false @GitArgs 2>&1); $Code=$LASTEXITCODE }
    finally {
        if ($null -eq $OldLazy) { Remove-Item Env:GIT_NO_LAZY_FETCH -ErrorAction SilentlyContinue } else { $env:GIT_NO_LAZY_FETCH=$OldLazy }
        if ($null -eq $OldOptional) { Remove-Item Env:GIT_OPTIONAL_LOCKS -ErrorAction SilentlyContinue } else { $env:GIT_OPTIONAL_LOCKS=$OldOptional }
    }
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
function Assert-Source {
    $null=Invoke-Git @('cat-file','-e',($ExpectedSource+'^{commit}') )
    $null=Invoke-Git @('cat-file','-e',($ExpectedParent+'^{commit}') )
    $null=Invoke-Git @('cat-file','-e',($ExpectedBase+'^{commit}') )
    $Head=(Invoke-Git @('rev-parse','HEAD') | Select-Object -First 1).Trim()
    if ($Head -cne $ExpectedSource) { throw "Native HEAD must be $ExpectedSource (found $Head)" }
    if (@(Invoke-Git @('status','--porcelain','--untracked-files=no')).Count -gt 0) { throw 'Tracked native source is dirty' }
    $Parent=(Invoke-Git @('rev-parse',($ExpectedSource+'^')) | Select-Object -First 1).Trim()
    if ($Parent -cne $ExpectedParent) { throw 'Pinned source immediate parent differs' }
    $Diff=@(Invoke-Git @('diff','--name-only',$ExpectedBase,$ExpectedSource) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Replace('\','/').Trim() } | Sort-Object -Unique)
    $Bound=@($Job.changed_source_paths | ForEach-Object { ([string]$_).Replace('\','/').Trim() } | Sort-Object -Unique)
    if (($Diff -join "`n") -cne ($Bound -join "`n")) { throw 'Changed source path binding differs from parent-to-source diff' }
    foreach ($Binding in $Job.source_bindings) {
        $Blob=(Invoke-Git @('rev-parse',($ExpectedSource+':'+[string]$Binding.path)) | Select-Object -First 1).Trim()
        if ($Blob -cne [string]$Binding.blob) { throw "Git blob mismatch: $($Binding.path)" }
        $FileText=[IO.File]::ReadAllText((Join-Path $Stage ([string]$Binding.path))).Replace("`r`n","`n")
        $Actual=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($FileText))).ToLowerInvariant()
        if ($Actual -cne [string]$Binding.sha256) { throw "Canonical source SHA mismatch: $($Binding.path)" }
    }
}
function Normalize-Lf([string]$Text) { return $Text.Replace("`r`n","`n").Replace("`r","`n") }
function Assert-ExpectedResearchDiagnostics([string]$Stdout,[string]$Stderr) {
    $ExpectedText=Normalize-Lf([IO.File]::ReadAllText([string]$Job.expected_research_diagnostics.path))
    $ExpectedBlocks=[Collections.Generic.List[string]]::new(); $Current=[Collections.Generic.List[string]]::new()
    foreach($Line in ($ExpectedText -split "`n")) {
        if ($Line -match '^(WARNING|ERROR):' -and $Current.Count -gt 0) { $ExpectedBlocks.Add(($Current -join "`n").TrimEnd()); $Current.Clear() }
        if ($Current.Count -gt 0 -or $Line -match '^(WARNING|ERROR):') { $Current.Add($Line) }
    }
    if ($Current.Count -gt 0) { $ExpectedBlocks.Add(($Current -join "`n").TrimEnd()) }
    $All=Normalize-Lf($Stdout+"`n"+$Stderr)
    if ($All -match '(?im)SCRIPT ERROR|Parse Error:') { throw 'Home Key/research fixture emitted a script or parse error' }
    if ($All -match '(?i)detached|previously freed|not inside tree|ObjectDB instances leaked') { throw 'Portal fixture emitted a detached/freed-node diagnostic' }
    $ActualHeaders=@([regex]::Matches($All,'(?m)^(WARNING|ERROR):.*$') | ForEach-Object { $_.Value })
    $ExpectedHeaders=@($ExpectedBlocks | ForEach-Object { ($_ -split "`n")[0] })
    if ($ExpectedBlocks.Count -ne 3 -or @($ExpectedHeaders | Where-Object { $_ -match '^WARNING:' }).Count -ne [int]$Job.expected_research_diagnostics.warning_blocks -or @($ExpectedHeaders | Where-Object { $_ -match '^ERROR:' }).Count -ne [int]$Job.expected_research_diagnostics.error_blocks) { throw 'Pinned expected research diagnostic packet is malformed' }
    if ($ActualHeaders.Count -ne $ExpectedHeaders.Count -or (($ActualHeaders | Sort-Object) -join "`n") -cne (($ExpectedHeaders | Sort-Object) -join "`n")) { throw 'Unexpected, missing, or duplicated warning/error header in Home Key/research batch' }
    foreach($Block in $ExpectedBlocks) {
        if ([regex]::Matches($All,[regex]::Escape($Block)).Count -ne 1) { throw 'A pinned research diagnostic block is missing, duplicated, or different' }
        if ($Block -notmatch [regex]::Escape([string]$Job.expected_research_diagnostics.match_all_backtraces_to)) { throw 'Expected research diagnostic lacks the named test backtrace' }
    }
    if ($All -notmatch [regex]::Escape([string]$Job.expected_research_diagnostics.warning_xp_mismatch)) { throw 'Expected research diagnostic lacks the pinned XP conflict path' }
}
function Read-Owner { Read-Json $OwnerPath }
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='systems_d36d754d93_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='systems_d36d754d93_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Systems focused fixture batches; process starting'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='systems_d36d754d93_test_child'
    $Owner.processes=@(@{pid=$PidValue;kind='systems_d36d754d93_test_child';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Systems focused fixture batches; owned child recorded'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeasePid=$PidValue
}
function Update-Owner([bool]$Release,[int]$PidValue=0,[string]$RunId='') {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) { throw 'Exact native lease authorization changed' }
    if ($Release) {
        if ([int]$Owner.active_process_id -ne $PidValue -or $Owner.run_id -cne $RunId) { throw 'Refusing to release another run lease' }
        $Owner.active_process_id=$null; $Owner.active_session_id=$null; $Owner.active_kind=$null; $Owner.processes=@(); $Owner.run_directory=$null; $Owner.run_id=$null
        $Owner.purpose='Service lane reserved; no native writer'; $Owner.source=$ExpectedSource
    } else {
        if ($Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Root lease is not idle' }
        $Owner.active_process_id=$PidValue; $Owner.active_session_id=$null; $Owner.active_kind='systems_d36d754d93_test_child'
        $Owner.processes=@(@{pid=$PidValue;kind='systems_d36d754d93_test_child'}); $Owner.run_id=$RunId
        $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Systems focused fixture batches'
    }
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o')
    Write-JsonAtomic $OwnerPath $Owner
}
function Assert-OwnedCim {
    if (-not $script:Proc) { throw 'No owned process handle' }
    if ($script:Proc.HasExited) { return $null }
    $Rows=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Rows.Count -ne 1) { throw 'Owned process CIM identity unavailable' }
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
    $script:Proc.Refresh()
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
function Assert-Predecessor {
    $P=$Job.predecessor
    foreach($Name in @('receipt','stdout','stderr','review')) { $Path=[string]$P.($Name+'_path'); $Expected=[string]$P.($Name+'_sha256'); Assert-Hash $Path $Expected }
    $R=Read-Json ([string]$P.receipt_path); $V=Read-Json ([string]$P.review_path)
    if ($R.job_id -cne [string]$P.job_id -or $R.status -cne [string]$P.expected_status -or $R.failed_step -cne [string]$P.expected_failed_step -or [int]$R.failed_step_exit_code -ne [int]$P.expected_failed_exit_code -or $R.stop_reason -cne [string]$P.expected_failure_reason) { throw 'Preserved predecessor receipt is not the pinned postprocess-only first-step failure' }
    if ($R.steps.Count -ne 1 -or $R.steps[0].id -cne [string]$P.expected_failed_step -or [int]$R.steps[0].exit_code -ne 0 -or [string]$R.steps[0].stdout -cne [string]$P.stdout_path -or [string]$R.steps[0].stderr -cne [string]$P.stderr_path -or [string]$R.steps[0].stdout_sha256 -cne [string]$P.stdout_sha256 -or [string]$R.steps[0].stderr_sha256 -cne [string]$P.stderr_sha256) { throw 'Predecessor step receipt does not bind the pinned raw logs and natural exit' }
    $Out=[IO.File]::ReadAllText([string]$P.stdout_path); $Err=[IO.File]::ReadAllText([string]$P.stderr_path)
    $Summary=[regex]::Match($Out,'(?m)^(\d+) tests, (\d+) assertions, (\d+) failed\r?$')
    if (-not $Summary.Success -or [int]$Summary.Groups[1].Value -ne [int]$P.expected_tests -or [int]$Summary.Groups[2].Value -ne [int]$P.expected_assertions -or [int]$Summary.Groups[3].Value -ne 0 -or $Out -notmatch [regex]::Escape([string]$P.expected_selector_summary)) { throw 'Predecessor raw output test totals or selectors differ' }
    Assert-ExpectedResearchDiagnostics $Out $Err
    if ($V.status -cne 'TEST_BATCH_VERIFIED_POSTPROCESS_SENTINEL_CORRECTION' -or $V.job_id -cne [string]$P.job_id -or $V.step -cne [string]$P.expected_failed_step -or [int]$V.godot_exit_code -ne 0 -or [int]$V.tests -ne [int]$P.expected_tests -or [int]$V.assertions -ne [int]$P.expected_assertions -or [int]$V.failures -ne 0 -or $V.stdout_sha256 -cne [string]$P.stdout_sha256 -or $V.stderr_sha256 -cne [string]$P.stderr_sha256 -or $V.original_receipt_sha256 -cne [string]$P.receipt_sha256 -or $V.diagnostic_blocks.injected_unexpected_block_rejected -ne $true) { throw 'Independent predecessor review does not bind passing test totals and diagnostics' }
    return [ordered]@{job_id=$P.job_id;step=$P.expected_failed_step;tests=[int]$Summary.Groups[1].Value;assertions=[int]$Summary.Groups[2].Value;failures=[int]$Summary.Groups[3].Value;stdout_sha256=$P.stdout_sha256;stderr_sha256=$P.stderr_sha256;receipt_sha256=$P.receipt_sha256;review_sha256=$P.review_sha256;status='TEST_BATCH_VERIFIED_POSTPROCESS_SENTINEL_CORRECTION'}
}
if ($CpuCleanupFixture) {
    $RunDir=$FixtureRoot
    $script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    Claim-Owner 'cpu-pre-cim-stop-failure'
    $psi=[Diagnostics.ProcessStartInfo]::new(); $psi.FileName=(Get-Command powershell.exe).Source; $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
    $psi.ArgumentList.Add('-NoProfile'); $psi.ArgumentList.Add('-Command'); $psi.ArgumentList.Add('Start-Sleep -Seconds 30')
    $child=[Diagnostics.Process]::Start($psi)
    $script:Proc=$child; $script:ProcId=$child.Id; $script:ProcStartUtc=$child.StartTime.ToUniversalTime()
    Record-OwnedChild $child.Id $script:ProcStartUtc 'cpu-pre-cim-stop-failure'
    $failed=$false
    try { throw 'Injected pre-CIM readiness failure' } catch { $failed=$true }
    try { Stop-OwnedProcess 'CPU fixture pre-CIM failure' -InjectFailureForCpuFixture } catch {}
    $check=Read-Owner
    if (-not $failed -or [int]$check.active_process_id -ne $child.Id -or $check.run_id -cne 'cpu-pre-cim-stop-failure' -or @($check.processes).Count -ne 1) { throw 'CPU failure fixture did not retain the live child lease' }
    $child.Kill(); $child.WaitForExit(10000) | Out-Null
    Update-Owner $true $child.Id 'cpu-pre-cim-stop-failure'; $script:LeaseOwned=$false
    $script:ReceiptPath=Join-Path $FixtureRoot 'failure-receipt.json'
    $script:Receipt=[ordered]@{status='RUNNING';steps=@()}
    $fixtureMetrics=@{physical_free_bytes=2147483000;commit_headroom_bytes=3000000000;C_free_bytes=15000000000;D_free_bytes=30000000000;observed_utc=[DateTime]::UtcNow.ToString('o')}
    Write-FailedStepReceipt 'cpu-fixture-step' 'cpu-fixture' 1 'Injected CPU fixture memory guard stop reason' $fixtureMetrics
    $saved=Read-Json $script:ReceiptPath
    if ($saved.failed_step -cne 'cpu-fixture-step' -or $saved.stop_reason -cne 'Injected CPU fixture memory guard stop reason' -or [long]$saved.terminal_metrics.physical_free_bytes -ne 2147483000 -or [int]$saved.failed_step_exit_code -ne 1) { throw 'CPU fixture failed to persist the stop reason and terminal metrics' }
    $child.Dispose(); $script:Proc=$null; $script:OwnerLock.Dispose(); $script:OwnerLock=$null
    Remove-Item -LiteralPath $FixtureRoot -Recurse -Force
    'CPU cleanup/receipt fixture PASS: lease retained on stop failure; failed-step reason and terminal metrics persisted.'
    exit 0
}
function Run-Step($Step) {
    $script:CurrentStepId=[string]$Step.id; $script:ObservedStopReason=$null
    Assert-Resources
    Assert-NoForeignEngine
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir ($(if ($StepId -eq 'affected-volunteer-witness') {'h2'} else {'h1'}))
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
    $ProcessTimer=[Diagnostics.Stopwatch]::StartNew()
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
    $Timer=$ProcessTimer; $Before=Assert-Resources
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
    $null=$OutTask.GetAwaiter().GetResult(); $null=$ErrTask.GetAwaiter().GetResult()
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
    if (($Stdout+"`n"+$Stderr) -match '(?im)SCRIPT ERROR|Parse Error:') { throw "Godot step $StepId emitted script/parse errors" }
    if ($StepId -eq 'home-key-and-research') { Assert-ExpectedResearchDiagnostics $Stdout $Stderr } elseif (($Stdout+"`n"+$Stderr) -match '(?m)^(WARNING|ERROR):') { throw "Godot step $StepId emitted unexpected warning/error diagnostics" }
    $TestResult=$null
    if ($Step.kind -eq 'tests') {
        $ExpectedTests=[int]$Step.expected_test_methods
        $Summary=[regex]::Match($Stdout,'(?m)^(\d+) tests, (\d+) assertions, (\d+) failed\r?$')
        if (-not $Summary.Success -or [int]$Summary.Groups[1].Value -ne $ExpectedTests -or [int]$Summary.Groups[2].Value -le 0 -or [int]$Summary.Groups[3].Value -ne 0) { throw "Test totals mismatch for $StepId" }
        if ($null -ne $Step.expected_assertions -and [int]$Summary.Groups[2].Value -ne [int]$Step.expected_assertions) { throw "Assertion total differs from corrected fixture contract for $StepId" }
        if ($Stdout -notmatch [regex]::Escape([string]$Step.expected_selector_summary)) { throw "Test selector summary missing for $StepId" }
        $TestResult=[ordered]@{tests=[int]$Summary.Groups[1].Value;assertions=[int]$Summary.Groups[2].Value;failures=[int]$Summary.Groups[3].Value;selector_summary=[string]$Step.expected_selector_summary}
    } else {
        foreach ($Marker in $Step.required_output_markers) { if ($Stdout -notmatch [regex]::Escape([string]$Marker)) { throw "Required Hall smoke output marker missing for $StepId" } }
    }
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD;actual_test_result=$TestResult}
    $script:StepReceipts+=,$StepReceipt
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}


function Assert-Packet {
    if ($Job.schema -cne 'codex.systems-native-run.v1' -or $Job.job_id -cne $ExpectedJob -or $Job.source_commit -cne $ExpectedSource -or $Job.source_parent -cne $ExpectedParent -or $Job.staging_base -cne $ExpectedBase) { throw 'Exact job/source/parent/base required' }
    if ($Job.supervisor_sha256 -cne (Hash-File $PSCommandPath) -or $Admission.job_sha256 -cne (Hash-File $JobPath)) { throw 'Supervisor/job/admission hashes differ' }
    if ($CpuPacketFixture -or $CpuStagePreflightFixture) {
        if ($Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false) { throw 'CPU validation requires NOT_ADMITTED packet' }
    } elseif ($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true) { throw 'Exact root admission required' }
    if ([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.packet_bytes -ne $PacketCap) { throw 'Resource caps differ' }
    if ($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha) { throw 'Engine pin differs' }
    Assert-Hash $Engine $EngineSha
    foreach($B in $Job.request_bindings) { Assert-Hash ([string]$B.path) ([string]$B.sha256) }
    $Request=Read-Json ([string]$Job.request_path)
    if ($Request.source -cne $ExpectedSource -or [int]$Request.wall_cap_seconds -ne $ExpectedWall -or ($Request.argv -join "`n") -cne ($Job.steps[0].args -join "`n")) { throw 'Request/argv/wall binding differs' }
    if ($Job.steps.Count -ne $(if($ExpectedKind -eq 'tests'){2}else{1}) -or $Job.steps[0].id -cne $ExpectedStep -or $Job.steps[0].kind -cne $ExpectedKind -or [int]$Job.steps[0].wall_seconds -ne $ExpectedWall) { throw 'Exact single step required' }
    if ($ExpectedKind -eq 'tests' -and ([int]$Job.steps[0].expected_test_methods -ne 4 -or [int]$Request.expected_tests -ne 4)) { throw 'Exactly four focused methods required' }
    if ($ExpectedKind -eq 'tests') {
        $Extra=Read-Json (Join-Path (Split-Path -Parent $ArtifactDir) 'affected-volunteer-request.json')
        if ($Job.steps[1].id -cne 'affected-volunteer-witness' -or $Job.steps[1].kind -cne 'tests' -or [int]$Job.steps[1].expected_test_methods -ne 2 -or [int]$Job.steps[1].wall_seconds -ne 180 -or ($Job.steps[1].args -join "`n") -cne ($Extra.argv -join "`n")) { throw 'Affected two-method volunteer batch differs' }
    }
    if ($Job.pack_chain.Count -ne 1) { throw 'One dependency pack required' }
    $Chain=$Job.pack_chain[0]; $Manifest=Read-Json ([string]$Chain.manifest_path)
    foreach($Name in @('pack','objects','manifest')) { Assert-Hash ([string]$Chain.($Name+'_path')) ([string]$Chain.($Name+'_sha256')) }
    if ($Chain.from_commit -cne $ExpectedBase -or $Chain.to_commit -cne $ExpectedSource -or $Manifest.source -cne $ExpectedSource -or $Manifest.base -cne $ExpectedBase -or $Manifest.pack_sha256 -cne $Chain.pack_sha256 -or [long]$Manifest.pack_bytes -ne [long]$Chain.pack_bytes -or (Get-Item -LiteralPath $Chain.pack_path).Length -ne [long]$Chain.pack_bytes -or @(Get-Content -LiteralPath $Chain.objects_path | Where-Object { $_ -match '^[0-9a-f]{40}$' }).Count -ne [int]$Chain.object_count) { throw 'Dependency pack binding differs' }
    foreach($B in $Job.prior_evidence_bindings) { Assert-Hash ([string]$B.path) ([string]$B.sha256) }
    if ((Get-RunBytes (Split-Path -Parent $ArtifactDir)) -gt $PacketCap) { throw 'Packet cap exceeded' }
}
function Assert-FocusedPassed {
    $Gate=$Job.continuation_gate
    if (-not $Gate) { throw 'Guardian requires new focused4 gate' }
    $J=Read-Json ([string]$Gate.job_path); $A=Read-Json ([string]$Gate.admission_path); $R=Read-Json ([string]$Gate.receipt_path); $V=Read-Json ([string]$Gate.review_path)
    if ($J.job_id -cne 'd36f6-r1' -or $J.source_commit -cne $ExpectedSource -or $J.status -cne 'ROOT_ADMITTED' -or $J.launch_allowed -ne $true -or $A.status -cne 'ROOT_ADMITTED' -or $A.launch_allowed -ne $true -or $A.job_sha256 -cne (Hash-File ([string]$Gate.job_path))) { throw 'Focused4 admission differs' }
    Assert-Hash ([string]$Gate.supervisor_path) ([string]$J.supervisor_sha256)
    if ($R.source_commit -cne $ExpectedSource -or $R.job_id -cne 'd36f6-r1' -or $R.status -cne 'EXITED_ZERO_AWAITING_REVIEW' -or $R.steps.Count -ne 2 -or $R.failed_step -or $R.cleanup_blocked -or $R.lease_retained_for_live_or_unverified_child) { throw 'Focused4 receipt not clean PASS' }

    for($Index=0;$Index -lt 2;$Index++) {
        $Step=$R.steps[$Index]; $ExpectedCount=@(4,2)[$Index]; $ExpectedId=@('guardian-defeat-focused','affected-volunteer-witness')[$Index]
        if ($Step.id -cne $ExpectedId -or $Step.status -cne 'PASSED' -or [int]$Step.exit_code -ne 0 -or $Step.stop_reason -or [int]$Step.actual_test_result.tests -ne $ExpectedCount -or [int]$Step.actual_test_result.failures -ne 0) { throw 'Focused required step did not pass' }
        foreach($Name in @('stdout','stderr')) { Assert-Hash ([string]$Step.$Name) ([string]$Step.($Name+'_sha256')) }
        $Text=[IO.File]::ReadAllText([string]$Step.stdout); $Err=[IO.File]::ReadAllText([string]$Step.stderr)
        if ($Text -notmatch "(?m)^$ExpectedCount tests, [1-9][0-9]* assertions, 0 failed\r?$" -or ($Text+"`n"+$Err) -match '(?im)SCRIPT ERROR|Parse Error:|^(WARNING|ERROR):' -or $Text -notmatch [regex]::Escape([string]$J.steps[$Index].expected_selector_summary)) { throw 'Focused raw proof differs' }
    }
    if ($V.status -cne 'VERIFIED' -or $V.source_commit -cne $ExpectedSource -or [int]$V.tests -ne 6 -or [int]$V.failures -ne 0 -or $V.receipt_sha256 -cne (Hash-File ([string]$Gate.receipt_path))) { throw 'Root independent six-method review required' }
    return @{receipt_path=$Gate.receipt_path;receipt_sha256=(Hash-File ([string]$Gate.receipt_path));review_path=$Gate.review_path;review_sha256=(Hash-File ([string]$Gate.review_path))}
}

$ExpectedJob='d36f6-r1'; $ExpectedStep='guardian-defeat-focused'; $ExpectedKind='tests'; $ExpectedWall=180
$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
Assert-Packet
if ($CpuPacketFixture) { 'CPU packet validation PASS; no native stage touched, no engine launched.'; exit 0 }
Assert-Source
if ($CpuStagePreflightFixture) { 'CPU staged-source validation PASS; no engine launched.'; exit 0 }
$ContinuationEvidence=$null
if ($ExpectedKind -eq 'mechanics-smoke') { $ContinuationEvidence=Assert-FocusedPassed }
Assert-Resources $true
Assert-NoForeignEngine
$RunDir=[string]$Job.output_directory
$ExpectedRunDir=Join-Path $OutputRoot ('run-'+$Job.job_id)
if ([IO.Path]::GetFullPath($RunDir) -cne [IO.Path]::GetFullPath($ExpectedRunDir) -or (Test-Path -LiteralPath $RunDir)) { throw 'Output directory must be the declared fresh path' }
if (-not (Test-Path -LiteralPath $OwnerLockPath -PathType Leaf)) { throw 'Native owner lock file missing' }
$script:OwnerLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$Owner=Read-Owner
if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved' }
Assert-NoForeignEngine; Assert-Resources $true
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $RunDir) | Out-Null
New-Item -ItemType Directory -Path $RunDir | Out-Null
$ReceiptPath=Join-Path $RunDir 'receipt.json'
$Receipt=[ordered]@{status='RUNNING';job_id=$Job.job_id;source_commit=$ExpectedSource;engine_sha256=$EngineSha;started_utc=[DateTime]::UtcNow.ToString('o');continuation_prerequisite=$ContinuationEvidence;prior_proof_scope=$Job.prior_proof_scope;isolated_home=$Job.isolated_home;steps=@();limits=@{C_admission_bytes=$CAdmissionFloor;C_stop_bytes=$CStopFloor;D_admission_bytes=$DAdmissionFloor;D_stop_bytes=$DStopFloor;memory_floor_bytes=$MemoryFloor;combined_logs_bytes=$CombinedLogsCap;output_bytes=$OutputCap}}
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
        try { $script:Proc.WaitForExit(); if ($script:OutTask) { $null=$script:OutTask.GetAwaiter().GetResult() }; if ($script:ErrTask) { $null=$script:ErrTask.GetAwaiter().GetResult() } } catch {}
    }
    if ($script:OutStream) { $script:OutStream.Dispose() }; if ($script:ErrStream) { $script:ErrStream.Dispose() }
    if ($script:Proc) { $script:Proc.Dispose() }
    if ($script:OwnerLock) { $script:OwnerLock.Dispose() }
}

