param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Off', 'On')]
    [string]$Arm,

    [Parameter(Mandatory = $true)]
    [ValidateSet('High', 'Medium')]
    [string]$Preset
)

$ErrorActionPreference = 'Stop'
$ArmKey = $Arm.ToLowerInvariant()
$RunId = "p2-005-$ArmKey-$($Preset.ToLowerInvariant())"
$SourceCommit = '5bb435c2ded96ecbec6a4a762e231ef7d7fabac0'
$ExpectedLeaseThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$NativeStage = 'C:\CodexTemp\tetherbound-native-service'
$ArtifactDir = 'D:\tetherbound\.artifacts\codex-service-meadows\p2-005-capture'
$OutputDir = "C:\CodexTemp\codex-service-catalog\$RunId"
$UserDataDir = "C:\CodexTemp\codex-service-catalog\$RunId-home"
$OutputFile = Join-Path $OutputDir 'manifest.json'
$RunReceipt = Join-Path $ArtifactDir "$RunId.run-result.json"
$ActiveReceipt = Join-Path $ArtifactDir "$RunId.run-active.json"
$FailureReceipt = Join-Path $ArtifactDir "$RunId.run-failure.json"
$StdoutFile = Join-Path $ArtifactDir "$RunId.stdout.log"
$StderrFile = Join-Path $ArtifactDir "$RunId.stderr.log"
$AdmissionFile = Join-Path $ArtifactDir 'admission.json'
$PacketFile = Join-Path $ArtifactDir 'capture-packet.json'
$Supervisor = $PSCommandPath
$Engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$Git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$OwnerFile = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockFile = 'C:\CodexTemp\tetherbound-native-owner.lock'
$WallLimitSeconds = 1200
$OutputLimitBytes = 536870912
$MinimumMemoryBytes = 2GB
$OwnedProcess = $null
$OwnedGodotPid = $null
$OwnedCreationUtc = $null
$LeaseLock = $null
$LeaseClaimed = $false
$NaturalExitObserved = $false
$StopReason = $null
$StdoutStream = $null
$StderrStream = $null

function Write-Json([string]$Path, $Value) {
    $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $Json = ConvertTo-Json -InputObject $Value -Depth 20
    [System.IO.File]::WriteAllText($Path, $Json + [Environment]::NewLine, $Utf8NoBom)
}

function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file missing: $Path" }
    $Actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected.ToLowerInvariant()) { throw "SHA-256 mismatch: $Path ($Actual)" }
}

function Assert-Blob([string]$RelativePath, [string]$Expected) {
    $Actual = (Invoke-GitRead @('rev-parse',"HEAD:$RelativePath") | Select-Object -First 1).Trim()
    if ($Actual -ne $Expected.ToLowerInvariant()) { throw "Git blob mismatch: $RelativePath ($Actual)" }
}

function Invoke-GitRead([string[]]$GitArgs) {
    $OldLazy = $env:GIT_NO_LAZY_FETCH
    $OldOptional = $env:GIT_OPTIONAL_LOCKS
    try {
        $env:GIT_NO_LAZY_FETCH = '1'
        $env:GIT_OPTIONAL_LOCKS = '0'
        $GitOutput = @(& $Git -C $NativeStage @GitArgs 2>&1)
        $GitCode = $LASTEXITCODE
    } finally {
        $env:GIT_NO_LAZY_FETCH = $OldLazy
        $env:GIT_OPTIONAL_LOCKS = $OldOptional
    }
    if ($GitCode -ne 0) { throw "Git read failed: $($GitArgs -join ' ') : $($GitOutput -join ' ')" }
    return $GitOutput
}

function Get-FreeBytes([string]$Drive) {
    $Info = [System.IO.DriveInfo]::new("$Drive`:\")
    if (-not $Info.IsReady) { throw "Drive $Drive`: is not ready" }
    return [long]$Info.AvailableFreeSpace
}

function Get-TreeBytes([string[]]$Paths) {
    [long]$Total = 0
    foreach ($Path in $Paths) {
        if (-not (Test-Path -LiteralPath $Path)) { continue }
        $Item = Get-Item -LiteralPath $Path -Force
        if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Unexpected reparse point in owned output tree: $Path" }
        if ($Item.PSIsContainer) {
            $Entries = Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            foreach ($Entry in $Entries) {
                if (($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Unexpected reparse point in owned output tree: $($Entry.FullName)" }
                if (-not $Entry.PSIsContainer) { $Total += [long]$Entry.Length }
            }
        } else { $Total += [long]$Item.Length }
    }
    return $Total
}

function Get-JpegDimensions([string]$Path) {
    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($Bytes.Length -lt 4 -or $Bytes[0] -ne 255 -or $Bytes[1] -ne 216) { throw "Invalid JPEG SOI marker: $Path" }
    $SofMarkers = @(192,193,194,195,197,198,199,201,202,203,205,206,207)
    $Index = 2
    while ($Index -lt $Bytes.Length) {
        while ($Index -lt $Bytes.Length -and $Bytes[$Index] -ne 255) { $Index++ }
        while ($Index -lt $Bytes.Length -and $Bytes[$Index] -eq 255) { $Index++ }
        if ($Index -ge $Bytes.Length) { break }
        $Marker = [int]$Bytes[$Index]; $Index++
        if ($Marker -eq 216 -or $Marker -eq 217 -or ($Marker -ge 208 -and $Marker -le 215) -or $Marker -eq 1) { continue }
        if ($Index + 1 -ge $Bytes.Length) { break }
        $SegmentLength = ([int]$Bytes[$Index] * 256) + [int]$Bytes[$Index + 1]
        if ($SegmentLength -lt 2 -or $Index + $SegmentLength -gt $Bytes.Length) { throw "Invalid JPEG segment length: $Path" }
        if ($Marker -in $SofMarkers) {
            if ($SegmentLength -lt 7) { throw "Truncated JPEG frame header: $Path" }
            $Height = ([int]$Bytes[$Index + 3] * 256) + [int]$Bytes[$Index + 4]
            $Width = ([int]$Bytes[$Index + 5] * 256) + [int]$Bytes[$Index + 6]
            return @{ width=$Width; height=$Height }
        }
        if ($Marker -eq 218) { break }
        $Index += $SegmentLength
    }
    throw "JPEG frame dimensions not found: $Path"
}

function Get-MemoryHeadroom {
    $Os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $PhysicalFree = [long]$Os.FreePhysicalMemory * 1KB
    $MemoryCounters = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop
    if (-not $MemoryCounters -or $null -eq $MemoryCounters.CommitLimit -or $null -eq $MemoryCounters.CommittedBytes) {
        throw 'Windows commit counters unavailable; refusing to launch without the 2 GiB physical/commit guard'
    }
    $CommitFree = [long]$MemoryCounters.CommitLimit - [long]$MemoryCounters.CommittedBytes
    return @{ physical_free_bytes=$PhysicalFree; commit_free_bytes=$CommitFree }
}

function Assert-MemoryHeadroom {
    $Headroom = Get-MemoryHeadroom
    if ($Headroom.physical_free_bytes -lt $MinimumMemoryBytes) { throw 'Free physical memory fell below 2 GiB' }
    if ($Headroom.commit_free_bytes -lt $MinimumMemoryBytes) { throw 'Free commit fell below 2 GiB' }
    return $Headroom
}

function Assert-NoForeignEngine {
    $Foreign = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
        $_.Name -match '^(Godot.*|Blender.*)\.exe$' -and [int]$_.ProcessId -ne $OwnedGodotPid
    })
    if ($Foreign.Count -gt 0) { throw ('Another Godot/Blender process is present: ' + (($Foreign | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', ')) }
}

function Assert-SourceAndFiles($Packet) {
    $Head = (Invoke-GitRead @('rev-parse','HEAD') | Select-Object -First 1).Trim()
    if ($Head -ne $SourceCommit) { throw "Native HEAD must be $SourceCommit; found $Head" }
    $Changes = @(Invoke-GitRead @('status','--porcelain'))
    $ChangedPaths = @($Changes | ForEach-Object { $_.Substring(3).Trim() })
    if ($ArmKey -eq 'off' -and $ChangedPaths.Count -ne 0) { throw 'OFF capture requires a clean tracked source tree' }
    if ($ArmKey -eq 'on' -and ($ChangedPaths.Count -ne 1 -or $ChangedPaths[0] -ne 'data/config/props.json')) {
        throw 'ON capture allows exactly one tracked edit: data/config/props.json'
    }
    foreach ($Entry in $Packet.source_files) {
        Assert-Hash (Join-Path $NativeStage $Entry.path) $Entry.sha256
    }
    foreach ($Entry in $Packet.source_blobs) {
        Assert-Blob $Entry.path $Entry.blob
    }
    foreach ($Entry in $Packet.assets) {
        Assert-Hash (Join-Path $NativeStage $Entry.path) $Entry.sha256
        Assert-Blob $Entry.path $Entry.blob
    }
    Assert-Hash (Join-Path $NativeStage 'data/config/stronghold.json') $Packet.stronghold_sha256
    Assert-Hash (Join-Path $NativeStage 'data/config/props.json') $Packet.props_sha256_by_arm.$ArmKey
    $Props = Get-Content -LiteralPath (Join-Path $NativeStage 'data/config/props.json') -Raw | ConvertFrom-Json
    $ExpectedCandidate = $ArmKey -eq 'on'
    if ([bool]$Props.p2_005_groundcover_candidate_enabled -ne $ExpectedCandidate) {
        throw "P2-005 flag does not match requested arm $Arm"
    }
    $Stronghold = Get-Content -LiteralPath (Join-Path $NativeStage 'data/config/stronghold.json') -Raw | ConvertFrom-Json
    if ([bool]$Stronghold.p2_003_unlit_candidate_enabled -or [bool]$Stronghold.p2_003_training_dummy_candidate_enabled) {
        throw 'P2-003 candidate flags must remain false for both arms'
    }
}

function Read-Owner {
    if (-not (Test-Path -LiteralPath $OwnerFile -PathType Leaf)) { throw 'Root native owner lease file is missing' }
    return (Get-Content -LiteralPath $OwnerFile -Raw | ConvertFrom-Json)
}

function Assert-IdleOwner($Owner) {
    if ($Owner.thread -ne $ExpectedLeaseThread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) {
        throw 'Root native owner lease identity/reservation/launch authorization does not match'
    }
    if ($Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or $Owner.active_kind -or
        $Owner.run_directory -or @($Owner.processes).Count -gt 0) { throw 'Root native owner lease is occupied' }
}

function Set-OwnedLease([bool]$Active) {
    $Owner = Read-Owner
    if ($Owner.thread -ne $ExpectedLeaseThread -or $Owner.reserved -ne $true) { throw 'Native lease identity changed while capture ran' }
    if ($Active) {
        Assert-IdleOwner $Owner
        $Owner.active_process_id = $OwnedGodotPid
        $Owner.processes = @(@{ kind='p2_005_catalog_capture'; pid=$OwnedGodotPid })
        $Owner.active_kind = 'p2_005_catalog_capture'
        $Owner.run_id = $RunId
        $Owner.run_directory = $OutputDir
        $Owner.source = $SourceCommit
    } else {
        if ($Owner.active_process_id -ne $OwnedGodotPid -or $Owner.run_id -ne $RunId -or $Owner.run_directory -ne $OutputDir) {
            throw 'Refusing to clear a native lease not owned by this capture'
        }
        $Owner.active_process_id = $null
        $Owner.processes = @()
        $Owner.active_kind = $null
        $Owner.run_id = $null
        $Owner.run_directory = $null
        $Owner.purpose = 'Service lane reserved; no native writer'
    }
    $Owner.updated_utc = [DateTime]::UtcNow.ToString('o')
    Write-Json $OwnerFile $Owner
}

function Get-ExactLiveProcess {
    if (-not $OwnedGodotPid) { return $null }
    $Proc = Get-CimInstance Win32_Process -Filter "ProcessId = $OwnedGodotPid" -ErrorAction SilentlyContinue
    if (-not $Proc) { return $null }
    if ([IO.Path]::GetFullPath([string]$Proc.ExecutablePath) -ne [IO.Path]::GetFullPath($Engine)) { throw 'PID now belongs to another executable; refusing signal' }
    if ($Proc.CreationDate -is [DateTime]) { $Creation = $Proc.CreationDate.ToUniversalTime() }
    else { $Creation = [Management.ManagementDateTimeConverter]::ToDateTime([string]$Proc.CreationDate).ToUniversalTime() }
    if ([Math]::Abs(($Creation - $OwnedCreationUtc).TotalSeconds) -gt 1.0) { throw 'PID creation time changed; refusing signal' }
    $Cmd = [string]$Proc.CommandLine
    $OutputNeedle = $OutputDir.Replace('\','/')
    foreach ($Needle in @($NativeStage, 'tools/capture_f38_matrix.gd', $OutputNeedle, "--f38-preset=$Preset")) {
        if (-not $Cmd.Contains($Needle, [StringComparison]::OrdinalIgnoreCase)) { throw "Owned PID argv lost expected token '$Needle'; refusing signal" }
    }
    return $Proc
}

function Stop-ExactOwnedProcess([string]$Reason) {
    if (-not $OwnedGodotPid -or -not $OwnedProcess -or $OwnedProcess.HasExited) { return }
    $LiveIdentity = Get-ExactLiveProcess
    if (-not $LiveIdentity) { throw 'Exact live process identity unavailable; preserving native lease for manual recovery' }
    $OwnedProcess.Kill()
    if (-not $OwnedProcess.WaitForExit(5000)) { throw 'Exact owned Godot did not stop within 5 seconds; preserving lease' }
    $script:StopReason = $Reason
}

function Assert-Manifest($Packet) {
    if (-not (Test-Path -LiteralPath $OutputFile -PathType Leaf)) { throw 'Capture manifest missing' }
    $Manifest = Get-Content -LiteralPath $OutputFile -Raw | ConvertFrom-Json
    if ($Manifest.complete -ne $true -or @($Manifest.failures).Count -ne 0) { throw 'Manifest is incomplete or reports failures' }
    if ($Manifest.preset -ne $Preset -or $Manifest.renderer -ne 'forward_plus' -or
        [int]$Manifest.resolution[0] -ne 1920 -or [int]$Manifest.resolution[1] -ne 1080 -or
        [int]$Manifest.seed -ne 2042 -or [bool]$Manifest.candidate -ne ($ArmKey -eq 'on')) {
        throw 'Manifest preset/renderer/resolution/seed/candidate marker mismatch'
    }
    $ExpectedIds = @($Packet.expected_frame_ids | Sort-Object)
    $PlannedIds = @($Manifest.planned_frame_ids | Sort-Object)
    if ($ExpectedIds.Count -ne 16 -or $PlannedIds.Count -ne 16 -or ($ExpectedIds -join "`n") -ne ($PlannedIds -join "`n")) {
        throw 'Manifest does not contain the exact 16 expected village_road frame IDs'
    }
    if (@($Manifest.frames).Count -ne 16) { throw 'Manifest must record exactly 16 saved frames' }
    $Images = @(Get-ChildItem -LiteralPath $OutputDir -Filter '*.jpg' -File -ErrorAction Stop)
    if ($Images.Count -ne 16) { throw "Expected exactly 16 JPEGs, found $($Images.Count)" }
    foreach ($FrameId in $ExpectedIds) {
        $FramePath = Join-Path $OutputDir "$FrameId.jpg"
        if (-not (Test-Path -LiteralPath $FramePath -PathType Leaf) -or (Get-Item -LiteralPath $FramePath).Length -le 0) {
            throw "Expected image missing/empty: $FrameId.jpg"
        }
        $Dimensions = Get-JpegDimensions $FramePath
        if ($Dimensions.width -ne 1920 -or $Dimensions.height -ne 1080) { throw "JPEG dimensions mismatch in $FrameId.jpg : $($Dimensions.width)x$($Dimensions.height)" }
        $Record = @($Manifest.frames | Where-Object { $_.frame_id -eq $FrameId })
        if ($Record.Count -ne 1) { throw "Manifest frame record missing/duplicated: $FrameId" }
        $Frame = $Record[0]
        if ($Frame.observed_clock.requested -ne $Frame.time -or $Frame.observed_clock.time_of_day -ne $Frame.time -or
            $Frame.observed_clock.requested_weather -ne $Frame.weather -or $Frame.observed_clock.actual_weather -ne $Frame.weather) {
            throw "Observed time/weather mismatch in $FrameId"
        }
    }
    return $Manifest
}

$Receipt = [ordered]@{
    status='NOT_ADMITTED'; run_id=$RunId; arm=$Arm; preset=$Preset; source_commit=$SourceCommit
    engine=$Engine; output_dir=$OutputDir; manifest=$OutputFile; user_data_dir=$UserDataDir
    pid=$null; creation_utc=$null; exit_code=$null; exit_observed_without_supervisor_stop=$false
    stop_reason=$null; output_bytes=$null; started_utc=$null; ended_utc=$null
    hard_limits=@{ wall_seconds=$WallLimitSeconds; output_tree_bytes=$OutputLimitBytes; c_admit_gib=14; c_stop_gib=11; d_admit_gib=20; d_stop_gib=20; free_physical_gib=2; free_commit_gib=2 }
}

try {
    if (-not (Test-Path -LiteralPath $AdmissionFile -PathType Leaf)) { throw 'Explicit root admission file missing; launcher remains disabled' }
    $Admission = Get-Content -LiteralPath $AdmissionFile -Raw | ConvertFrom-Json
    if ($Admission.admitted -ne $true -or $Admission.source_commit -ne $SourceCommit -or
        $Admission.arm -ne $Arm -or $Admission.preset -ne $Preset) { throw 'Root admission is false or does not match this source/arm/preset' }
    if (-not (Test-Path -LiteralPath $PacketFile -PathType Leaf)) { throw 'Pinned capture-packet.json is missing' }
    $Packet = Get-Content -LiteralPath $PacketFile -Raw | ConvertFrom-Json
    if ($Packet.status -ne 'PREPARED_ONLY_NOT_EXECUTED' -or $Packet.source_commit -ne $SourceCommit) { throw 'Packet is not pinned or was already executed' }
    Assert-Hash $Supervisor $Packet.supervisor_sha256
    Assert-Hash $Engine $Packet.engine_sha256
    if (-not (Test-Path -LiteralPath $Git -PathType Leaf)) { throw 'Pinned Git runtime is missing' }
    Assert-SourceAndFiles $Packet
    $Receipt.head = $SourceCommit
    $Receipt.source_sha256 = @{}
    foreach ($Entry in $Packet.source_files) {
        $Receipt.source_sha256[$Entry.path] = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $NativeStage $Entry.path)).Hash.ToLowerInvariant()
    }
    $Receipt.source_sha256['data/config/props.json'] = $Packet.props_sha256_by_arm.$ArmKey.ToLowerInvariant()
    $Receipt.source_sha256['assets'] = @($Packet.assets | ForEach-Object { @{ path=$_.path; sha256=$_.sha256.ToLowerInvariant() } })
    if ((Get-FreeBytes 'C') -lt 14GB -or (Get-FreeBytes 'D') -lt 20GB) { throw 'Admission disk floors are C:14 GiB and D:20 GiB' }
    $InitialMemory = Assert-MemoryHeadroom
    $Receipt.memory_admission = $InitialMemory
    foreach ($Path in @($OutputDir,$UserDataDir,$RunReceipt,$ActiveReceipt,$FailureReceipt,$StdoutFile,$StderrFile)) {
        if (Test-Path -LiteralPath $Path) { throw "Fresh path required; refusing reuse: $Path" }
    }
    Assert-NoForeignEngine

    $LeaseLock = [IO.File]::Open($OwnerLockFile, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    Assert-IdleOwner (Read-Owner)
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    New-Item -ItemType Directory -Path $UserDataDir | Out-Null
    New-Item -ItemType Directory -Path $ArtifactDir -Force | Out-Null
    $StdoutStream = [IO.File]::Open($StdoutFile, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    $StderrStream = [IO.File]::Open($StderrFile, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
    Assert-SourceAndFiles $Packet
    Assert-NoForeignEngine
    $InitialMemory = Assert-MemoryHeadroom

    $PresetArg = "--f38-preset=$Preset"
    $OutputArg = '--output=' + $OutputDir.Replace('\','/')
    $MarkerArg = if ($ArmKey -eq 'off') { '--f38-baseline' } else { '--f38-candidate' }
    $EngineArgs = @(
        '--path', $NativeStage,
        '--rendering-method', 'forward_plus',
        '--resolution', '1920x1080',
        '--audio-driver', 'Dummy',
        '--script', 'tools/capture_f38_matrix.gd', '--',
        $PresetArg, '--biome=meadows', '--seed=2042', '--times=day,night',
        '--subset=village_road', $OutputArg, $MarkerArg
    )
    $StartInfo = [Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $Engine
    $StartInfo.WorkingDirectory = $NativeStage
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    foreach ($Arg in $EngineArgs) { $StartInfo.ArgumentList.Add($Arg) }
    $StartInfo.Environment['APPDATA'] = $UserDataDir
    $StartInfo.Environment['LOCALAPPDATA'] = $UserDataDir
    $StartInfo.Environment['XDG_DATA_HOME'] = $UserDataDir

    $Receipt.status = 'STARTING'
    $Receipt.started_utc = [DateTime]::UtcNow.ToString('o')
    $OwnedProcess = [Diagnostics.Process]::new()
    $OwnedProcess.StartInfo = $StartInfo
    if (-not $OwnedProcess.Start()) { throw 'Godot did not start' }
    $OwnedGodotPid = $OwnedProcess.Id
    $OwnedCreationUtc = $OwnedProcess.StartTime.ToUniversalTime()
    $Receipt.pid = $OwnedGodotPid
    $Receipt.creation_utc = $OwnedCreationUtc.ToString('o')
    Set-OwnedLease $true
    $LeaseClaimed = $true
    $Receipt.status = 'RUNNING'
    Write-Json $ActiveReceipt $Receipt
    $StdoutTask = $OwnedProcess.StandardOutput.BaseStream.CopyToAsync($StdoutStream)
    $StderrTask = $OwnedProcess.StandardError.BaseStream.CopyToAsync($StderrStream)
    $Timer = [Diagnostics.Stopwatch]::StartNew()
    $LastSupervisorCheck = [TimeSpan]::Zero
    while (-not $OwnedProcess.HasExited) {
        if ($Timer.Elapsed.TotalSeconds -ge $WallLimitSeconds) { $StopReason='1200-second wall limit'; break }
        if ((Get-FreeBytes 'C') -lt 11GB) { $StopReason='C: free space below 11 GiB'; break }
        if ((Get-FreeBytes 'D') -lt 20GB) { $StopReason='D: free space below 20 GiB'; break }
        try { $Headroom = Assert-MemoryHeadroom }
        catch { $StopReason=$_.Exception.Message; break }
        if (($Timer.Elapsed - $LastSupervisorCheck).TotalSeconds -ge 5) {
            try { Assert-NoForeignEngine }
            catch { $StopReason='foreign Godot/Blender process appeared'; break }
            $LastSupervisorCheck = $Timer.Elapsed
        }
        $StdoutStream.Flush(); $StderrStream.Flush()
        $Bytes = Get-TreeBytes @($OutputDir,$UserDataDir,$StdoutFile,$StderrFile)
        if ($Bytes -gt $OutputLimitBytes) { $StopReason='combined output/log/user-data cap exceeded'; break }
        Start-Sleep -Milliseconds 500
    }
    if ($StopReason) { Stop-ExactOwnedProcess $StopReason }
    if (-not $OwnedProcess.HasExited) { throw 'Owned Godot still live after bounded stop; preserve lease for manual recovery' }
    $OwnedProcess.WaitForExit()
    $null = $StdoutTask.GetAwaiter().GetResult(); $null = $StderrTask.GetAwaiter().GetResult()
    $StdoutStream.Dispose(); $StdoutStream=$null
    $StderrStream.Dispose(); $StderrStream=$null
    $NaturalExitObserved = -not [bool]$StopReason
    $Receipt.exit_observed_without_supervisor_stop = $NaturalExitObserved
    $Receipt.exit_code = $OwnedProcess.ExitCode
    $Receipt.stop_reason = $StopReason
    $Receipt.output_bytes = Get-TreeBytes @($OutputDir,$UserDataDir,$StdoutFile,$StderrFile)
    $Receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
    if ($Receipt.output_bytes -gt $OutputLimitBytes) { throw 'Combined output cap exceeded after process exit' }
    if ($Receipt.exit_code -ne 0 -or $StopReason) { throw 'Godot failed or supervisor stopped the exact owned process' }
    Assert-SourceAndFiles $Packet
    $Manifest = Assert-Manifest $Packet
    $Receipt.manifest_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputFile).Hash.ToLowerInvariant()
    $Receipt.frame_receipts = @($Manifest.frames | ForEach-Object {
        $FramePath = Join-Path $OutputDir ([string]$_.frame_id + '.jpg')
        @{ frame_id=$_.frame_id; sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $FramePath).Hash.ToLowerInvariant(); bytes=(Get-Item -LiteralPath $FramePath).Length }
    })
    $Receipt.status = 'CAPTURE_COMPLETE_REQUIRES_BLIND_REVIEW'
    Write-Json $RunReceipt $Receipt
    Set-OwnedLease $false
    $LeaseClaimed = $false
} catch {
    $PrimaryException = $_.Exception
    $Receipt.primary_exception = @{ type=$PrimaryException.GetType().FullName; message=$PrimaryException.Message }
    $Receipt.failure = $PrimaryException.Message
    if ($OwnedProcess -and -not $OwnedProcess.HasExited) {
        try { Stop-ExactOwnedProcess 'supervisor exception' } catch { $Receipt.cleanup_failure = $_.Exception.Message }
    }
    if ($OwnedProcess -and $OwnedProcess.HasExited) {
        $Receipt.exit_code = $OwnedProcess.ExitCode
        $Receipt.exit_observed_without_supervisor_stop = $NaturalExitObserved
    }
    $Receipt.stop_reason = $StopReason
    $Receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
    if ($StdoutStream) { $StdoutStream.Dispose(); $StdoutStream=$null }
    if ($StderrStream) { $StderrStream.Dispose(); $StderrStream=$null }
    if ($LeaseClaimed -and $OwnedProcess -and $OwnedProcess.HasExited) {
        try { Set-OwnedLease $false; $LeaseClaimed = $false } catch { $Receipt.lease_cleanup_failure = $_.Exception.Message }
    }
    try { Write-Json $FailureReceipt $Receipt } catch { }
    throw
} finally {
    if ($OwnedProcess -and -not $OwnedProcess.HasExited) {
        try { Stop-ExactOwnedProcess 'finally cleanup' } catch { }
    }
    if ($StdoutStream) { $StdoutStream.Dispose() }
    if ($StderrStream) { $StderrStream.Dispose() }
    if ($LeaseLock) { $LeaseLock.Dispose() }
}
