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
$ExpectedSource = 'c836df19793e420982bb4aa7b4a0428380126c82'
$ExpectedParent = 'b99c94092bd32fc9c0691868bdc1c63ecb984b06'
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
function New-OperationBudget {
    return [pscustomobject]@{Timer=[Diagnostics.Stopwatch]::StartNew();WorkSeconds=115.0;TotalSeconds=120.0;CleanupDeadline=$null}
}
function Get-OperationRemaining($Budget,[switch]$Cleanup) {
    if($null -eq $Budget){throw 'Shared operation budget missing'}
    $Deadline=$Budget.WorkSeconds
    if($Cleanup){$Deadline=$Budget.TotalSeconds;if($null -ne $Budget.CleanupDeadline){$Deadline=[Math]::Min($Deadline,$Budget.CleanupDeadline)}}
    $Remaining=$Deadline-$Budget.Timer.Elapsed.TotalSeconds
    if($Remaining -le 0){throw 'Aggregate operation deadline exceeded'}
    return [double]$Remaining
}
function Start-OperationCleanup($Budget) {
    if($null -eq $Budget.CleanupDeadline){$Budget.CleanupDeadline=[Math]::Min($Budget.TotalSeconds,$Budget.Timer.Elapsed.TotalSeconds+5.0)}
    return Get-OperationRemaining $Budget -Cleanup
}
function Assert-OperationBudget($Budget,[switch]$Cleanup) {$null=Get-OperationRemaining $Budget -Cleanup:$Cleanup}
function Get-OperationWaitMs($Budget,[int]$Ceiling=1000,[switch]$Cleanup) {
    $RemainingMs=[int][Math]::Floor((Get-OperationRemaining $Budget -Cleanup:$Cleanup)*1000)
    if($RemainingMs -le 0){throw 'Aggregate operation has no remaining wait time'}
    return [Math]::Min($Ceiling,$RemainingMs)
}

function Invoke-Git([string[]]$GitArgs) {
    Assert-OperationBudget $script:SourceBudget
    $Info=[Diagnostics.ProcessStartInfo]::new()
    $Info.FileName=$Git;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true;$Info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
    foreach($Item in @('-C',$Stage,'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false','-c','core.preloadindex=false','-c','core.quotepath=false')+$GitArgs){$Info.ArgumentList.Add($Item)}
    $Info.Environment['GIT_NO_LAZY_FETCH']='1';$Info.Environment['GIT_OPTIONAL_LOCKS']='0';$Info.Environment['GIT_TERMINAL_PROMPT']='0'
    $GitProcess=[Diagnostics.Process]::new();$GitProcess.StartInfo=$Info
    $OutputTask=$null;$ErrorTask=$null;$GitStarted=$false;$GitFinished=$false
    try{
        Assert-OperationBudget $script:SourceBudget
        if(-not $GitProcess.Start()){throw 'Pinned Git failed to start'}
        $GitStarted=$true
        $OutputTask=$GitProcess.StandardOutput.ReadToEndAsync();$ErrorTask=$GitProcess.StandardError.ReadToEndAsync()
        while(-not $GitProcess.HasExited){
            $null=Assert-Resources
            $null=$GitProcess.WaitForExit((Get-OperationWaitMs $script:SourceBudget 250))
        }
        Assert-OperationBudget $script:SourceBudget
        Wait-OutputDrain $OutputTask $ErrorTask (Get-OperationWaitMs $script:SourceBudget 2000)
        Assert-OperationBudget $script:SourceBudget
        if($GitProcess.ExitCode -ne 0){throw ('Pinned Git verification failed: '+$ErrorTask.Result)}
        $GitFinished=$true
        return @($OutputTask.Result -split '\r?\n'|Where-Object {$_ -ne ''})
    }finally{
        if($GitStarted -and -not $GitProcess.HasExited){$GitProcess.Kill($true)}
        if(-not $GitFinished){
            $null=Start-OperationCleanup $script:SourceBudget
            if($GitStarted -and -not $GitProcess.HasExited -and -not $GitProcess.WaitForExit((Get-OperationWaitMs $script:SourceBudget 5000 -Cleanup))){throw 'Owned Git helper did not stop within aggregate cleanup'}
            if($OutputTask -and $ErrorTask){Wait-OutputDrain $OutputTask $ErrorTask (Get-OperationWaitMs $script:SourceBudget 2000 -Cleanup)}
            Assert-OperationBudget $script:SourceBudget -Cleanup
        }
        if($OutputTask -and $OutputTask.IsCompleted -and $ErrorTask -and $ErrorTask.IsCompleted){$GitProcess.Dispose()}
    }
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
    Assert-OperationBudget $script:SourceBudget
    $Path=Join-Path $Root ([string]$Binding.path)
    if ($Binding.kind -ceq 'gitblob') {
        $Bytes=[IO.File]::ReadAllBytes($Path)
        $Hasher=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
        try{$Hasher.AppendData([Text.Encoding]::ASCII.GetBytes('blob '+$Bytes.Length+[char]0));$Hasher.AppendData($Bytes);$Actual=[Convert]::ToHexString($Hasher.GetHashAndReset()).ToLowerInvariant()}finally{$Hasher.Dispose()}
        if($Actual -cne $Binding.blob){throw 'Retained dependency Git blob differs'}
    } elseif ($Binding.kind -ceq 'binary') {
        Assert-Hash $Path ([string]$Binding.sha256)
        if ((Get-Item -LiteralPath $Path).Length -ne [long]$Binding.bytes) { throw "Binary byte length differs: $Path" }
    } else { Assert-CanonicalText $Path ([string]$Binding.sha256) }
}
function Get-GitBlobId([string]$Path) {
    Assert-OperationBudget $script:SourceBudget
    $File=Get-Item -LiteralPath $Path
    if(($File.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Materialized reparse file refused'}
    $Hasher=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
    $Stream=[IO.File]::OpenRead($Path)
    try{
        $Hasher.AppendData([Text.Encoding]::ASCII.GetBytes('blob '+$File.Length+[char]0))
        $Buffer=[byte[]]::new(1048576)
        while(($Count=$Stream.Read($Buffer,0,$Buffer.Length)) -gt 0){Assert-OperationBudget $script:SourceBudget;$Hasher.AppendData($Buffer,0,$Count)}
        Assert-OperationBudget $script:SourceBudget
        return [Convert]::ToHexString($Hasher.GetHashAndReset()).ToLowerInvariant()
    }finally{$Stream.Dispose();$Hasher.Dispose()}
}
function Assert-FullIndexAndMaterialized($Tree) {
    $Index=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    Assert-OperationBudget $script:SourceBudget
    foreach($Line in Invoke-Git @('ls-files','--stage')){
        Assert-OperationBudget $script:SourceBudget
        if($Line -notmatch '^([0-9]+) ([a-f0-9]{40}) 0\t(.+)$'){throw 'Nonzero index stage or unsupported index row'}
        $Index.Add($Matches[3],$Matches[1]+'/'+$Matches[2])
    }
    if($Index.Count -ne $Tree.Count){throw 'Full index entry count differs'}
    Assert-OperationBudget $script:SourceBudget
    foreach($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)){
        Assert-OperationBudget $script:SourceBudget
        if($Line -notmatch '^([0-9]+) blob ([a-f0-9]{40})\t(.+)$'){throw 'Unsupported target tree row'}
        if(-not $Index.ContainsKey($Matches[3]) -or $Index[$Matches[3]] -cne ($Matches[1]+'/'+$Matches[2])){throw 'Full index mode/blob differs'}
    }
    foreach($Entry in $Tree.GetEnumerator()){
        Assert-OperationBudget $script:SourceBudget
        $Path=Join-Path $Stage $Entry.Key
        if(-not (Test-Path -LiteralPath $Path)){continue}
        if((Get-GitBlobId $Path) -ceq $Entry.Value){continue}
        $TextSuffixes=@('.gd','.godot','.tscn','.tres','.json','.gdshader','.gdshaderinc','.gdextension','.gltf','.obj','.mtl','.svg','.import','.md','.txt','.py','.ps1','.yml','.yaml','.cfg','.ini','.csv','.sh','.bat','.gitignore','.gitattributes','.uid')
        if(-not @($TextSuffixes|Where-Object {$Path.EndsWith($_,[StringComparison]::OrdinalIgnoreCase)}).Count){throw 'Dirty binary materialized source'}
        $Raw=[IO.File]::ReadAllBytes($Path)
        $Text=[Text.UTF8Encoding]::new($false,$true).GetString($Raw).Replace("`r`n","`n")
        $Bytes=[Text.Encoding]::UTF8.GetBytes($Text)
        $Hasher=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
        try{$Hasher.AppendData([Text.Encoding]::ASCII.GetBytes('blob '+$Bytes.Length+[char]0));$Hasher.AppendData($Bytes);$Actual=[Convert]::ToHexString($Hasher.GetHashAndReset()).ToLowerInvariant()}finally{$Hasher.Dispose()}
        Assert-OperationBudget $script:SourceBudget
        if($Actual -cne $Entry.Value){throw 'Dirty canonical materialized source'}
    }
}

function Assert-Source {
    $script:SourceBudget=New-OperationBudget
    try {
    $null=Invoke-Git @('cat-file','-e',($ExpectedSource+'^{commit}') )
    $null=Invoke-Git @('cat-file','-e',($ExpectedParent+'^{commit}') )
    $null=Invoke-Git @('cat-file','-e',($ExpectedBase+'^{commit}') )
    $Head=(Invoke-Git @('rev-parse','HEAD') | Select-Object -First 1).Trim()
    if ($Head -cne $ExpectedSource) { throw "Native HEAD must be $ExpectedSource (found $Head)" }

    $Parent=(Invoke-Git @('rev-parse',($ExpectedSource+'^')) | Select-Object -First 1).Trim()
    if ($Parent -cne $ExpectedParent) { throw 'Pinned source immediate parent differs' }
    $Diff=@(Invoke-Git @('diff','--name-only',$ExpectedBase,$ExpectedSource) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Replace('\','/').Trim() } | Sort-Object -Unique)
    $Bound=@($Job.changed_source_paths | ForEach-Object { ([string]$_).Replace('\','/').Trim() } | Sort-Object -Unique)
    if (($Diff -join "`n") -cne ($Bound -join "`n")) { throw 'Changed source path binding differs from parent-to-source diff' }
    $Tree=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    Assert-OperationBudget $script:SourceBudget
    foreach ($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)) {
        Assert-OperationBudget $script:SourceBudget
        if ($Line -match '^\d+ blob ([0-9a-f]{40})\t(.+)$') { $Tree.Add($Matches[2],$Matches[1]) }
    }
    Assert-FullIndexAndMaterialized $Tree
    Assert-OperationBudget $script:SourceBudget
    foreach ($Binding in $Job.source_bindings) {
        Assert-OperationBudget $script:SourceBudget
        $Blob=$null
        if (-not $Tree.TryGetValue([string]$Binding.path,[ref]$Blob)) { throw "Pinned Git blob missing: $($Binding.path)" }
        if ($Blob -cne [string]$Binding.blob) { throw "Git blob mismatch: $($Binding.path)" }
        Assert-BoundFile $Binding $Stage
    }
    Assert-OperationBudget $script:SourceBudget
    } catch { $null=Start-OperationCleanup $script:SourceBudget;throw }
    finally {Assert-OperationBudget $script:SourceBudget -Cleanup}
}

function Read-Owner { Read-Json $OwnerPath }
function Claim-Owner([string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true -or $Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or @($Owner.processes).Count -gt 0) { throw 'Exact native lease is not idle/reserved for prelaunch claim' }
    $Owner.active_process_id=$script:RunnerPid; $Owner.active_session_id=$null; $Owner.active_kind='systems_c836_departure_starting'
    $Owner.processes=@(@{pid=$script:RunnerPid;kind='systems_c836_departure_supervisor'}); $Owner.run_id=$RunId
    $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Systems short departure; process starting'
    $Owner.updated_utc=[DateTime]::UtcNow.ToString('o'); Write-JsonAtomic $OwnerPath $Owner
    $script:LeaseOwned=$true; $script:LeaseRun=$RunId; $script:LeasePid=$script:RunnerPid
}
function Record-OwnedChild([int]$PidValue,[DateTime]$CreatedUtc,[string]$RunId) {
    $Owner=Read-Owner
    if ($Owner.thread -cne $ExpectedThread -or $Owner.reserved -ne $true -or $Owner.run_id -cne $RunId -or [int]$Owner.active_process_id -ne $script:RunnerPid) { throw 'Prelaunch lease changed before recording child identity' }
    $Owner.active_process_id=$PidValue; $Owner.active_kind='systems_c836_departure_test_child'
    $Owner.processes=@(@{pid=$PidValue;kind='systems_c836_departure_test_child';created_utc=$CreatedUtc.ToString('o')})
    $Owner.purpose='Systems short departure; owned child recorded'
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
        $Owner.active_process_id=$PidValue; $Owner.active_session_id=$null; $Owner.active_kind='systems_c836_departure_test_child'
        $Owner.processes=@(@{pid=$PidValue;kind='systems_c836_departure_test_child'}); $Owner.run_id=$RunId
        $Owner.run_directory=$RunDir; $Owner.source=$ExpectedSource; $Owner.purpose='Systems short departure'
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
    $script:Proc.Kill($true)
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
    $StepReceipt=[ordered]@{id=$StepId;kind=$Kind;status='FAILED';wall_cap_seconds=$script:CurrentWallSeconds;terminal_elapsed_seconds=if($script:StepTimer){$script:StepTimer.Elapsed.TotalSeconds}else{$null};pid=$script:ProcId;created_utc=if($script:ProcStartUtc){$script:ProcStartUtc.ToString('o')}else{$null};observed_command_line=$script:CommandLine;exit_code=$ExitCode;stop_reason=$StopReason;terminal_metrics=$TerminalMetrics;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD}
    if ($script:OutPath -and (Test-Path -LiteralPath $script:OutPath -PathType Leaf)) { $StepReceipt.stdout=$script:OutPath; $StepReceipt.stdout_sha256=Hash-File $script:OutPath }
    if ($script:ErrPath -and (Test-Path -LiteralPath $script:ErrPath -PathType Leaf)) { $StepReceipt.stderr=$script:ErrPath; $StepReceipt.stderr_sha256=Hash-File $script:ErrPath }
    $script:StepReceipts+=,$StepReceipt
    $Receipt.failed_step=$StepId; $Receipt.stop_reason=$StopReason; $Receipt.terminal_metrics=$TerminalMetrics
    $Receipt.failed_step_exit_code=$ExitCode; $Receipt.steps=@($script:StepReceipts); $Receipt.status='FAILED'
    $Receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
    try { $Receipt.total_output_bytes=Get-RunBytes $RunDir } catch { $Receipt.output_size_error=$_.Exception.Message }
    Write-JsonAtomic $ReceiptPath $Receipt
}
function Assert-Input {
    foreach($Entry in $Request.input.files.PSObject.Properties) {
        $File=Join-Path $Request.input.directory $Entry.Name
        Assert-Hash $File $Entry.Value.sha256
        if((Get-Item -LiteralPath $File).Length -ne $Entry.Value.bytes){throw 'Input byte length changed'}
    }
}
function Canonical-Value($Value) {
    if($null -eq $Value){return 'null'}
    if($Value -is [string]){return ConvertTo-Json -InputObject $Value -Compress}
    if($Value -is [bool]){return $Value.ToString().ToLowerInvariant()}
    if($Value -is [ValueType]){return ([double]$Value).ToString('R',[Globalization.CultureInfo]::InvariantCulture)}
    if($Value -is [array]){return '['+((@($Value|ForEach-Object {Canonical-Value $_})) -join ',')+']'}
    return '{'+((@($Value.PSObject.Properties|Sort-Object Name|ForEach-Object {(ConvertTo-Json -InputObject $_.Name -Compress)+':'+(Canonical-Value $_.Value)})) -join ',')+'}'
}
function Assert-WorldOutput([string]$Stdout) {
    Assert-Input
    $Rows=@([regex]::Matches($Stdout,'(?m)^TIDEWAKE HANDOFF (.+)\r?$'))
    if($Rows.Count -ne 1){throw 'Exactly one production Load handoff required'}
    $Checks=$Rows[0].Groups[1].Value|ConvertFrom-Json
    if(($Checks.PSObject.Properties.Name|Sort-Object) -join ',' -cne 'flags,inventory,realm,uids'){throw 'Handoff keys differ'}
    foreach($Property in $Checks.PSObject.Properties){if($Property.Value -isnot [bool] -or -not $Property.Value){throw 'Production handoff mismatch'}}
    $Rows=@([regex]::Matches($Stdout,'(?m)^TIDEWAKE PIECE RESULT (.+)\r?$'))
    if($Rows.Count -ne 1){throw 'Exactly one result required'}
    $Result=$Rows[0].Groups[1].Value|ConvertFrom-Json
    $Checkpoint=Join-Path $RunDir 'checkpoint'
    $Saved=Read-Json (Join-Path $Checkpoint 'receipt.json')
    if(Test-Path -LiteralPath (Join-Path $Checkpoint 'receipt.FAILED.json')){throw 'Failed receipt present'}
    foreach($Observed in @($Result,$Saved)){
        if($Observed.segment -cne '07a1_departure' -or $Observed.passed -ne $true -or @($Observed.failures).Count -ne 0 -or $Observed.wall_seconds -le 0 -or $Observed.wall_seconds -ge 300){throw 'Departure did not pass within bound'}
    }
    if($Saved.commit -cne $ExpectedSource -or $Saved.from -cne $Request.input.directory -or [IO.Path]::GetFullPath($Saved.out) -cne [IO.Path]::GetFullPath($Checkpoint)){throw 'Receipt source/path mismatch'}
    if($Saved.input_mode -cne 'generated_ancestry' -or $Saved.lineage.status -cne 'generated' -or $Saved.lineage.version -ne 1 -or $Saved.lineage.continuous_fresh_save -ne $false -or @($Saved.lineage.origins).Count -eq 0){throw 'Generated ancestry lost'}
    $Prior=Read-Json (Join-Path $Request.input.directory 'receipt.json')
    foreach($Key in @('uids','flags','items','realm')){
        if((Canonical-Value $Saved.before.$Key) -cne (Canonical-Value $Prior.after.$Key)){throw "Loaded receipt mismatch: $Key"}
    }
    [double]$DistanceSquared=0
    foreach($Point in @($Saved.before.player,$Saved.after.player,$Prior.after.player)){
        if($Point -isnot [array] -or $Point.Count -ne 3){throw 'Position missing'}
        foreach($Coordinate in $Point){if($Coordinate -is [string] -or $Coordinate -is [bool] -or $null -eq $Coordinate -or -not [double]::IsFinite([double]$Coordinate)){throw 'Position invalid'}}
    }
    for($Index=0;$Index -lt 3;$Index++){$DistanceSquared += [Math]::Pow(([double]$Saved.before.player[$Index]-[double]$Prior.after.player[$Index]),2)}
    if($DistanceSquared -gt 9){throw 'Production Load more than 3m from predecessor'}
    if($Saved.after.realm -cne 'water' -or @($Saved.after.uids).Count -ne 5 -or @($Saved.after.uids|Sort-Object -Unique).Count -ne 5 -or (Canonical-Value $Saved.after.uids) -cne (Canonical-Value $Request.input.ordered_uids) -or (Canonical-Value $Result.uids) -cne (Canonical-Value $Saved.after.uids)){throw 'Retained five differ'}
    if($null -eq $Saved.after.training -or @($Saved.after.training.PSObject.Properties).Count -eq 0){throw 'Current training snapshot absent'}
    foreach($Flag in $Request.forbidden_late_flags){if($Flag -cin $Saved.after.flags){throw "Late milestone precredited: $Flag"}}
    if(@($Saved.helper_receipts).Count -ne 1 -or $Saved.helper_receipts[0].passed -ne $true){throw 'Actual helper pass absent'}
    $Hashes=@()
    foreach($File in Get-ChildItem -LiteralPath $Checkpoint -Recurse -File){
        if(($File.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Output reparse file refused'}
        $Hashes+=@{path=[IO.Path]::GetRelativePath($Checkpoint,$File.FullName).Replace('\','/');bytes=$File.Length;sha256=Hash-File $File.FullName}
    }
    foreach($Relative in @($Request.input.files.PSObject.Properties.Name|Where-Object {$_ -like 'save/*'})){
        if($Relative -cnotin $Hashes.path){throw "Production save file absent: $Relative"}
    }
    foreach($Relative in @($Request.input.files.PSObject.Properties.Name|Where-Object {$_ -eq 'save/slot_0.json' -or $_ -like 'save/characters/*/character.json'})){
        $Document=Read-Json (Join-Path $Checkpoint $Relative)
        if($Document.format -cne 'tetherbound-save' -or $Document.codec_version -ne 1){throw 'Actual save codec differs'}
        $Payload=$Document.payload
        if((Canonical-Value @($Payload.party.uid)) -cne (Canonical-Value $Saved.after.uids)){throw 'Actual saved ordered roster differs from receipt'}
        if($Payload.player_pose.realm -cne 'water' -or $Payload.player_pose.traversal.mode -cne 'grounded'){throw 'Actual save is not a grounded Water boundary'}
        $Coordinates=@($Payload.player_pose.position)
        if($Coordinates.Count -ne 3){throw 'Actual save position missing'}
        [double]$SavedDistance=0
        for($Index=0;$Index -lt 3;$Index++){
            $Hex=$Coordinates[$Index].'$tb_float64'
            if($Hex -notmatch '^[0-9a-f]{16}$'){throw 'Actual save position codec invalid'}
            $Number=[BitConverter]::ToDouble([Convert]::FromHexString($Hex),0)
            if(-not [double]::IsFinite($Number)){throw 'Nonfinite actual saved position'}
            $SavedDistance += [Math]::Pow(($Number-[double]$Saved.after.player[$Index]),2)
        }
        if($SavedDistance -gt 0.01){throw 'Actual saved position differs from successor receipt'}
    }
    return @{segment='07a1_departure';input_files=$Request.input.files;output_files=$Hashes;input_mode=$Saved.input_mode;lineage=$Saved.lineage;before=$Saved.before;after=$Saved.after;production_reload_of_output='NOT_RUN';status='LOCAL_PASS_AWAITING_ROOT_REVIEW'}
}

function Assert-TestOutput([string]$Stdout,$Step) {
    if($Step.kind -ceq 'world'){return Assert-WorldOutput $Stdout}
    if($Step.kind -ceq 'check-only') { if($Stdout -notmatch '^Godot Engine v4\.7') {throw 'Locked engine banner absent'}; return $null }
    $Summaries=[regex]::Matches($Stdout,'(?m)^(\d+) tests, (\d+) assertions, (\d+) failed\r?$')
    if($Summaries.Count -ne 1 -or [int]$Summaries[0].Groups[1].Value -ne 4 -or [int]$Summaries[0].Groups[2].Value -le 0 -or [int]$Summaries[0].Groups[3].Value -ne 0) { throw 'Exact four method / positive assertion / zero failure totals required' }
    $Rows=@([regex]::Matches($Stdout,'(?m)^  ok    ([^\r\n]+) :: (test_\w+)\r?$') | ForEach-Object {$_.Groups[1].Value+'::'+$_.Groups[2].Value})
    if($Rows.Count -ne 4 -or (($Rows | Sort-Object) -join ',') -cne (($Step.expected_selectors | Sort-Object) -join ',') -or $Stdout -match '(?im)^\s*FAIL\s|unmatched selector|\bskipped\b') { throw 'Missing, extra, duplicate, skipped or failing selector' }
    return @{tests=4;assertions=[int]$Summaries[0].Groups[2].Value;failures=0;selectors=$Rows}
}
function Assert-StepIds($Steps) {
    $Seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($Item in $Steps) {
        if ([string]$Item.id -notmatch '^[A-Za-z0-9-]+$') { throw 'Unsafe step id for isolated home path' }
        if (-not $Seen.Add([string]$Item.id)) { throw 'Duplicate step id' }
    }
}
function Assert-StepDeadline($Timer,[double]$WallSeconds) {
    if($Timer.Elapsed.TotalSeconds -ge $WallSeconds){throw 'Wall-clock cap exceeded at terminal check'}
}
function Wait-OutputDrain($StdoutTask,$StderrTask,[int]$TimeoutMilliseconds=2000) {
    if($TimeoutMilliseconds -le 0){throw 'stdout/stderr drain has no remaining time'}
    $Tasks=[Threading.Tasks.Task[]]@(@($StdoutTask,$StderrTask)|Where-Object {$null -ne $_})
    if($Tasks.Count -eq 0){return}
    if(-not [Threading.Tasks.Task]::WaitAll($Tasks,$TimeoutMilliseconds)){throw 'stdout/stderr drain timeout'}
    foreach($Task in $Tasks){$null=$Task.GetAwaiter().GetResult()}
}
function Close-OutputStreamsBounded($StdoutStream,$StderrStream,[int]$TimeoutMilliseconds) {
    if($TimeoutMilliseconds -le 0){throw 'Output disposal has no remaining time'}
    $DisposeTasks=@()
    foreach($Stream in @($StdoutStream,$StderrStream)){
        if($null -ne $Stream){$DisposeTasks+=,$Stream.DisposeAsync().AsTask()}
    }
    if($DisposeTasks.Count -and -not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]$DisposeTasks,$TimeoutMilliseconds)){throw 'Output disposal timeout'}
    foreach($Task in $DisposeTasks){$null=$Task.GetAwaiter().GetResult()}
}
function Complete-StepOutput($Proc,$Timer,[double]$WallSeconds,$StdoutTask,$StderrTask,$StdoutStream,$StderrStream) {
    if(-not $Proc.HasExited -or -not $Proc.WaitForExit(0)){throw 'Owned process remained live at terminal validation'}
    Assert-StepDeadline $Timer $WallSeconds
    $DrainDeadline=[Math]::Min($WallSeconds,$Timer.Elapsed.TotalSeconds+2.0)
    $RemainingMs=[int][Math]::Floor(($DrainDeadline-$Timer.Elapsed.TotalSeconds)*1000)
    Wait-OutputDrain $StdoutTask $StderrTask $RemainingMs
    $RemainingMs=[int][Math]::Floor(($DrainDeadline-$Timer.Elapsed.TotalSeconds)*1000)
    Close-OutputStreamsBounded $StdoutStream $StderrStream $RemainingMs
    Assert-StepDeadline $Timer $WallSeconds
}
function Complete-CleanupOutput {
    $CleanupTimer=[Diagnostics.Stopwatch]::StartNew()
    Wait-OutputDrain $script:OutTask $script:ErrTask 2000
    $RemainingMs=2000-[int]$CleanupTimer.ElapsedMilliseconds
    Close-OutputStreamsBounded $script:OutStream $script:ErrStream $RemainingMs
    $script:OutTask=$null;$script:ErrTask=$null;$script:OutStream=$null;$script:ErrStream=$null
}

function Run-Step($Step) {
    $script:StepTimer=$null;$script:CurrentWallSeconds=[int]$Step.wall_seconds
    $script:OutPath=$null; $script:ErrPath=$null; $script:CurrentStepId=[string]$Step.id; $script:ObservedStopReason=$null
    Assert-Input
    Assert-Source
    Assert-Hash $Engine $EngineSha
    Assert-Resources
    Assert-NoForeignEngine
    $StepStartBytes=Get-RunBytes $RunDir
    $StepId=[string]$Step.id; $HomeDir=Join-Path $RunDir ('h-'+$StepId)
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
    $StartInfo.Environment['TB_COMMIT_SHA']=$ExpectedSource
    $null=$StartInfo.Environment.Remove('TB_WORLD_SEED')
    $Proc=[Diagnostics.Process]::new(); $Proc.StartInfo=$StartInfo
    Claim-Owner $StepId
    $Timer=[Diagnostics.Stopwatch]::StartNew();$script:StepTimer=$Timer
    if (-not $Proc.Start()) { throw "Godot failed to start $StepId" }
    $script:Proc=$Proc
    $script:ProcId=$Proc.Id; $script:ProcStartUtc=$Proc.StartTime.ToUniversalTime()
    Record-OwnedChild $script:ProcId $script:ProcStartUtc $StepId
    $OutStream=[IO.FileStream]::new($OutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read,65536,[IO.FileOptions]::Asynchronous)
    $script:OutStream=$OutStream
    $ErrStream=[IO.FileStream]::new($ErrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read,65536,[IO.FileOptions]::Asynchronous)
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
            # CopyToAsync owns output streams; inspect file lengths without synchronous Flush.
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
    Complete-StepOutput $Proc $Timer ([double]$Step.wall_seconds) $OutTask $ErrTask $OutStream $ErrStream
    $script:OutTask=$null; $script:ErrTask=$null; $script:OutStream=$null; $script:ErrStream=$null
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
    Assert-Input
    $TestResult=Assert-TestOutput $Stdout $Step
    Assert-StepDeadline $Timer ([double]$Step.wall_seconds)
    $Live=@(Get-CimInstance Win32_Process -Filter "ProcessId = $script:ProcId" -ErrorAction SilentlyContinue)
    if ($Live.Count -gt 0) { throw 'Godot process remains present after exit' }
    Assert-NoForeignEngine
    $StepReceipt=[ordered]@{id=$StepId;kind=$Step.kind;status='PASSED';pid=$script:ProcId;created_utc=$script:ProcStartUtc.ToString('o');observed_command_line=$script:CommandLine;expected_arguments=$StepArgs;exit_code=$Exit;stop_reason=$null;terminal_metrics=$TerminalMetrics;wall_seconds=[Math]::Round($Timer.Elapsed.TotalSeconds,3);stdout=$OutPath;stdout_sha256=(Hash-File $OutPath);stderr=$ErrPath;stderr_sha256=(Hash-File $ErrPath);stdout_stderr_bytes=([long](Get-Item $OutPath).Length+[long](Get-Item $ErrPath).Length);preflight_memory=$Before;minimum_physical_free_bytes=$script:MinPhysical;minimum_commit_headroom_bytes=$script:MinCommit;minimum_C_free_bytes=$script:MinC;minimum_D_free_bytes=$script:MinD;actual_test_result=$TestResult}
    $script:StepReceipts+=,$StepReceipt
    Update-Owner $true $script:ProcId $StepId; $script:LeaseOwned=$false; $script:LeaseRun=$null; $script:LeasePid=0
    $Proc.Dispose(); $script:Proc=$null; $script:ProcId=$null; $script:ProcStartUtc=$null; $script:CommandLine=$null
}

$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
if ($Job.schema -cne 'codex.systems-short-departure.v1' -or $Job.job_id -cne 'sysc836-departure-r3' -or $Job.source_commit -cne $ExpectedSource -or $Job.source_parent -cne $ExpectedParent -or $Job.staging_base -cne $ExpectedBase) { throw 'Exact Systems job binding required' }
if ($CpuStagePreflightFixture -or $CpuPacketFixture) {
    if ($Job.status -ne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -ne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false -or $Admission.job_sha256 -cne (Hash-File $JobPath)) { throw 'Stage-only CPU preflight requires the exact unadmitted job bytes' }
} elseif ($Job.status -ne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -ne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.job_sha256 -cne (Hash-File $JobPath)) { throw 'Exact root admission is required' }
if($Admission.job_id -cne $Job.job_id -or $Admission.source -cne $ExpectedSource -or $Admission.supervisor_sha256 -cne $Job.supervisor_sha256){throw 'Admission identity differs'}
if(-not ($CpuPacketFixture -or $CpuStagePreflightFixture) -and $Admission.reviewed_by_thread -cne $ExpectedThread){throw 'Exact root reviewer required'}
if ([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.packet_bytes -ne $PacketCap) { throw 'Job resource caps differ from supervisor constants' }
if ($Job.supervisor_sha256 -cne (Hash-File $PSCommandPath)) { throw 'Supervisor hash does not match job' }
if ($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha) { throw 'Engine runtime pin differs' }
Assert-Hash $Engine $EngineSha
$PacketDir=$ArtifactDir
foreach($Binding in $Job.request_bindings) { Assert-Hash ([string]$Binding.path) ([string]$Binding.sha256) }
$Request=Read-Json (Join-Path $ArtifactDir 'request.json')
if($Request.source -cne $ExpectedSource -or $Request.parent -cne $ExpectedParent -or $Request.base -cne $ExpectedBase -or $Job.steps.Count -ne 1 -or ($Job.steps | ConvertTo-Json -Depth 12 -Compress) -cne ($Request.steps | ConvertTo-Json -Depth 12 -Compress)) { throw 'Exact continuation request differs' }
Assert-StepIds $Job.steps
if($Job.steps[0].kind -cne 'world' -or $Job.steps[0].wall_seconds -ne 300){throw 'Only one 300s departure allowed'}
if ($CpuPacketFixture) { 'CPU current-source packet PASS; NOT_ADMITTED; no engine.'; exit 0 }
$ValidationPath='D:/tetherbound/.artifacts/s/run-sysc836-validation-r3/receipt.json'
if($Admission.validation_receipt_sha256 -notmatch '^[a-f0-9]{64}$'){throw 'Root-reviewed validation receipt hash required'}
Assert-Hash $ValidationPath $Admission.validation_receipt_sha256
$Validation=Read-Json $ValidationPath
if($Validation.status -cne 'EXITED_ZERO_AWAITING_REVIEW' -or $Validation.source_commit -cne $ExpectedSource -or $Validation.job_id -cne 'sysc836-validation-r3' -or @($Validation.steps).Count -ne 3 -or @($Validation.steps|Where-Object status -CNE 'PASSED').Count){throw 'Exact successful focused validation required'}
Assert-Source
if ($CpuStagePreflightFixture) { 'CPU staged-source preflight PASS: exact HEAD, parent, base diff, canonical file hashes; no engine launched.'; exit 0 }
Assert-Resources $true
Assert-NoForeignEngine
if ((Get-RunBytes $PacketDir) -gt $PacketCap) { throw 'Packet exceeds 16 MiB' }
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
    $CleanupErrors=@()
    if($script:Proc -and -not $script:Proc.HasExited){
        try{Stop-OwnedProcess 'failure cleanup'}catch{$CleanupErrors+=('Owned child cleanup: '+$_.Exception.Message)}
    }
    try{Complete-CleanupOutput}catch{$CleanupErrors+=('Output cleanup: '+$_.Exception.Message)}
    if($CleanupErrors.Count){
        $Receipt.status='FAILED';$Receipt.cleanup_failures=$CleanupErrors
        $Receipt.lease_retained_for_live_or_unverified_child=$script:LeaseOwned
        Write-JsonAtomic $ReceiptPath $Receipt
    } elseif($script:LeaseOwned -and ((-not $script:Proc) -or $script:Proc.HasExited)){
        try{Assert-NoForeignEngine;Update-Owner $true $script:LeasePid $script:LeaseRun;$script:LeaseOwned=$false}
        catch{$CleanupErrors+=('Lease cleanup: '+$_.Exception.Message);$Receipt.status='FAILED';$Receipt.cleanup_failures=$CleanupErrors;Write-JsonAtomic $ReceiptPath $Receipt}
    }
    if($script:LeaseOwned){$Receipt.lease_retained_for_live_or_unverified_child=$true;Write-JsonAtomic $ReceiptPath $Receipt}
    # Never synchronously dispose streams or process pipe readers with unfinished IO.
    if($script:Proc -and $script:Proc.HasExited -and -not $script:OutTask -and -not $script:ErrTask){$script:Proc.Dispose()}
    if($script:OwnerLock){$script:OwnerLock.Dispose()}
    if($CleanupErrors.Count){throw ('Cleanup failed: '+($CleanupErrors -join '; '))}
}
