param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('High', 'Medium')]
    [string]$Preset
)

$ErrorActionPreference = 'Stop'
$ExpectedSourceCommit = '06bedfa5082e6ea5dd425c9fc04ffd1d5ace84eb'
$ArtifactDir = 'D:\tetherbound\.artifacts\codex-service-meadows\p2-006-baseline'
$PacketFile = Join-Path $ArtifactDir 'capture-packet.json'
$AdmissionFile = Join-Path $ArtifactDir 'admission.json'
$NativeStage = 'C:\CodexTemp\tetherbound-native-service'
$OutputRoot = 'C:\CodexTemp\codex-service-catalog'
$OutputDir = Join-Path $OutputRoot "p2-006-baseline-$($Preset.ToLowerInvariant())"
$UserDataDir = "$OutputDir-home"
$OwnerFile = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockFile = 'C:\CodexTemp\tetherbound-native-owner.lock'
$RunReceipt = Join-Path $ArtifactDir "$($Preset.ToLowerInvariant()).run-result.json"
$FailureReceipt = Join-Path $ArtifactDir "$($Preset.ToLowerInvariant()).run-failure.json"
$ActiveReceipt = Join-Path $ArtifactDir 'active-capture.json'
$StdoutFile = Join-Path $ArtifactDir "$($Preset.ToLowerInvariant()).stdout.log"
$StderrFile = Join-Path $ArtifactDir "$($Preset.ToLowerInvariant()).stderr.log"
$OutputManifest = Join-Path $OutputDir 'manifest.json'
$OwnedPid = $null
$OwnedCreatedUtc = $null
$OwnedProcess = $null
$LeaseLock = $null
$LeaseClaimed = $false
$StopReason = $null
$WallLimitSeconds = 1200
$OutputLimitBytes = 512MB
$MinimumMemoryBytes = 2GB

function Write-Json([string]$Path, $Value) {
    [System.IO.File]::WriteAllText($Path, (ConvertTo-Json -InputObject $Value -Depth 24) + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-GitRead([string[]]$GitArgs) {
    $OldLazy = $env:GIT_NO_LAZY_FETCH; $OldOptional = $env:GIT_OPTIONAL_LOCKS
    try {
        $env:GIT_NO_LAZY_FETCH = '1'; $env:GIT_OPTIONAL_LOCKS = '0'
        $Result = @(& $Git -C $NativeStage @GitArgs 2>&1); $Code = $LASTEXITCODE
    } finally { $env:GIT_NO_LAZY_FETCH = $OldLazy; $env:GIT_OPTIONAL_LOCKS = $OldOptional }
    if ($Code -ne 0) { throw "Read-only Git command failed: $($GitArgs -join ' ') ($($Result -join ' '))" }
    return $Result
}

function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file is missing: $Path" }
    $Actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($Actual -ne $Expected) { throw "SHA-256 mismatch for $Path : $Actual" }
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $Hasher = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($Hasher.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $Hasher.Dispose() }
}

function Get-GodotTextSha256([string]$Path) {
    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    $Offset = if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) { 3 } else { 0 }
    $Utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $Text = $Utf8.GetString($Bytes, $Offset, $Bytes.Length - $Offset)
    return Get-Sha256Bytes ($Utf8.GetBytes($Text))
}

function Assert-Source($Packet) {
    $Head = (Invoke-GitRead @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    if ($Head -ne $Packet.source_commit) { throw "Native HEAD must be $($Packet.source_commit), found $Head" }
    $Changes = @(Invoke-GitRead @('status', '--porcelain'))
    if ($Changes.Count -ne 0) { throw "Native source tree must be clean: $($Changes -join '; ')" }
    foreach ($Entry in $Packet.canonical_blobs) {
        if ([System.IO.Path]::IsPathRooted($Entry.path) -or $Entry.path.Contains('..') -or $Entry.path.Contains('\')) { throw "Unsafe packet path: $($Entry.path)" }
        $HeadBlob = (Invoke-GitRead @('rev-parse', "HEAD:$($Entry.path)") | Select-Object -First 1).Trim()
        if ($HeadBlob -ne $Entry.blob) { throw "HEAD blob mismatch for $($Entry.path): $HeadBlob" }
        $WorkBlob = (Invoke-GitRead @('hash-object', "--path=$($Entry.path)", '--', $Entry.path) | Select-Object -First 1).Trim()
        if ($WorkBlob -ne $Entry.blob) { throw "Working-tree canonical blob mismatch for $($Entry.path): $WorkBlob" }
    }
}

function Get-FreeBytes([string]$Drive) {
    $Info = [System.IO.DriveInfo]::new("$Drive`:\")
    if (-not $Info.IsReady) { throw "Drive $Drive`: is not ready" }
    return [long]$Info.AvailableFreeSpace
}

function Get-Headroom {
    $Os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $Counters = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop
    if (-not $Counters -or $null -eq $Counters.CommitLimit -or $null -eq $Counters.CommittedBytes) { throw 'Windows commit counters unavailable' }
    return @{ physical_free_bytes=([long]$Os.FreePhysicalMemory * 1KB); commit_free_bytes=([long]$Counters.CommitLimit - [long]$Counters.CommittedBytes) }
}

function Assert-Resources {
    if ((Get-FreeBytes 'C') -lt 12GB -or (Get-FreeBytes 'D') -lt 20GB) { throw 'Admission requires C: >=12 GiB and D: >=20 GiB free' }
    $Memory = Get-Headroom
    if ($Memory.physical_free_bytes -lt $MinimumMemoryBytes -or $Memory.commit_free_bytes -lt $MinimumMemoryBytes) { throw 'Admission requires >=2 GiB free physical memory and commit' }
    return $Memory
}

function Assert-NoForeignEngine {
    $Foreign = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
        $_.Name -match '^(Godot.*|Blender.*)\.exe$' -and [int]$_.ProcessId -ne $OwnedPid
    })
    if ($Foreign.Count) { throw ('Another Godot/Blender process is present: ' + (($Foreign | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', ')) }
}

function Get-TreeBytes([string[]]$Paths) {
    [long]$Total = 0
    foreach ($Path in $Paths) {
        if (-not (Test-Path -LiteralPath $Path)) { continue }
        $Item = Get-Item -LiteralPath $Path -Force
        if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Unexpected reparse point: $Path" }
        $Entries = if ($Item.PSIsContainer) { Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop } else { @($Item) }
        foreach ($Entry in $Entries) {
            if (($Entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Unexpected reparse point: $($Entry.FullName)" }
            if (-not $Entry.PSIsContainer) { $Total += [long]$Entry.Length }
        }
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

function Read-Owner {
    if (-not (Test-Path -LiteralPath $OwnerFile -PathType Leaf)) { throw 'Root native owner lease file is missing' }
    return (Get-Content -LiteralPath $OwnerFile -Raw | ConvertFrom-Json)
}

function Assert-IdleOwner($Owner, $Packet) {
    if ($Owner.thread -ne $Packet.expected_lease_thread -or $Owner.reserved -ne $true -or $Owner.allow_native_launch -ne $true) { throw 'Root native lease identity/reservation/launch authorization does not match' }
    if ($Owner.active_process_id -or $Owner.active_session_id -or $Owner.run_id -or $Owner.active_kind -or $Owner.run_directory -or @($Owner.processes).Count -gt 0) { throw 'Root native owner lease is occupied' }
}

function Set-OwnedLease([bool]$Active, $Packet) {
    $Owner = Read-Owner
    if ($Owner.thread -ne $Packet.expected_lease_thread -or $Owner.reserved -ne $true) { throw 'Native lease identity changed during capture' }
    if ($Active) {
        Assert-IdleOwner $Owner $Packet
        $Owner.active_process_id = $OwnedPid
        $Owner.processes = @(@{ kind='p2_006_exact_baseline'; pid=$OwnedPid })
        $Owner.active_kind = 'p2_006_exact_baseline'; $Owner.run_id = "p2-006-$($Preset.ToLowerInvariant())"
        $Owner.run_directory = $OutputDir; $Owner.source = $Packet.source_commit
    } else {
        if ($Owner.active_process_id -ne $OwnedPid -or $Owner.run_directory -ne $OutputDir) { throw 'Refusing to clear a lease not owned by this process' }
        $Owner.active_process_id = $null; $Owner.processes = @(); $Owner.active_kind = $null
        $Owner.run_id = $null; $Owner.run_directory = $null; $Owner.purpose = 'Service lane reserved; no native writer'
    }
    $Owner.updated_utc = [DateTime]::UtcNow.ToString('o')
    Write-Json $OwnerFile $Owner
}

function Get-ExactLiveProcess($Engine) {
    if (-not $OwnedPid) { return $null }
    $Proc = Get-CimInstance Win32_Process -Filter "ProcessId = $OwnedPid" -ErrorAction SilentlyContinue
    if (-not $Proc) { return $null }
    if ([IO.Path]::GetFullPath([string]$Proc.ExecutablePath) -ne [IO.Path]::GetFullPath($Engine)) { throw 'Owned PID belongs to another executable; refusing to signal it' }
    $Created = if ($Proc.CreationDate -is [DateTime]) { $Proc.CreationDate.ToUniversalTime() } else { [Management.ManagementDateTimeConverter]::ToDateTime([string]$Proc.CreationDate).ToUniversalTime() }
    if ([Math]::Abs(($Created - $OwnedCreatedUtc).TotalSeconds) -gt 1.0) { throw 'Owned PID creation identity changed; refusing to signal it' }
    $Cmd = [string]$Proc.CommandLine
    foreach ($Needle in @($NativeStage, 'tools/phase2_capture_locations.gd', $OutputDir.Replace('\','/'), "--preset=$Preset")) {
        if (-not $Cmd.Contains($Needle, [StringComparison]::OrdinalIgnoreCase)) { throw "Owned PID command line lost '$Needle'; refusing to signal it" }
    }
    return $Proc
}

function Stop-Owned([string]$Reason, $Engine) {
    if (-not $OwnedProcess -or $OwnedProcess.HasExited) { return }
    if (-not (Get-ExactLiveProcess $Engine)) { throw 'Exact owned process identity unavailable; lease retained for recovery' }
    $OwnedProcess.Kill()
    if (-not $OwnedProcess.WaitForExit(5000)) { throw 'Owned Godot did not stop within five seconds; lease retained' }
    $script:StopReason = $Reason
}

function Assert-Manifest($Packet, $Engine) {
    if (-not (Test-Path -LiteralPath $OutputManifest -PathType Leaf)) { throw 'Capture manifest missing' }
    $Manifest = Get-Content -LiteralPath $OutputManifest -Raw | ConvertFrom-Json
    $Expected = @($Packet.capture.expected_frame_ids | Sort-Object)
    $Planned = @($Manifest.planned_frame_ids | Sort-Object)
    if ($Manifest.complete -ne $true -or @($Manifest.failures).Count -ne 0 -or $Manifest.seed -ne 2042 -or
        ($Manifest.requested_times -join ',') -ne 'day' -or ($Manifest.requested_views -join ',') -ne 'close' -or
        $Expected.Count -ne 4 -or ($Expected -join "`n") -ne ($Planned -join "`n") -or @($Manifest.frames).Count -ne 4) {
        throw 'Manifest completion, exact planned IDs, seed, time, view, or frame count mismatch'
    }
    $Graphics = $Manifest.graphics_capture
    if ($Graphics.source_commit -ne $Packet.source_commit -or $Graphics.preset -ne $Preset -or
        $Graphics.renderer -ne 'forward_plus' -or [int]$Graphics.resolution[0] -ne 1920 -or [int]$Graphics.resolution[1] -ne 1080 -or
        [string]$Graphics.graphics_config_sha256 -ne $ExpectedArtSha) { throw 'Graphics source/preset/renderer/resolution/art.json text hash mismatch' }
    $Images = @(Get-ChildItem -LiteralPath $OutputDir -Filter '*.jpg' -File -ErrorAction Stop)
    if ($Images.Count -ne 4) { throw "Expected exactly four JPEGs; found $($Images.Count)" }
    foreach ($Id in $Expected) {
        $Image = Join-Path $OutputDir "$Id.jpg"
        if (-not (Test-Path -LiteralPath $Image -PathType Leaf) -or (Get-Item -LiteralPath $Image).Length -le 0) { throw "Missing/empty image: $Id.jpg" }
        $Dimensions = Get-JpegDimensions $Image
        if ($Dimensions.width -ne 1920 -or $Dimensions.height -ne 1080) { throw "JPEG dimensions mismatch in $Id.jpg : $($Dimensions.width)x$($Dimensions.height)" }
        $Rows = @($Manifest.frames | Where-Object { $_.frame_id -eq $Id })
        if ($Rows.Count -ne 1) { throw "Missing/duplicated frame record: $Id" }
        $Frame = $Rows[0]
        if ($Frame.time -ne 'day' -or $Frame.view -ne 'close' -or $Frame.camera_purpose -ne 'close' -or
            $Frame.observed_clock.requested -ne 'day' -or $Frame.observed_clock.time_of_day -ne 'day') { throw "Frame context mismatch: $Id" }
        foreach ($Field in @('selected_stand_xz','selected_stand_offset_m','selected_stand_lateral_m','player_position','camera_position','view_heading_xz','camera_rig_transform','camera_rig_spring_length','camera_transform')) {
            if ($null -eq $Frame.$Field) { throw "Production camera/stand receipt missing $Field : $Id" }
        }
    }
    return $Manifest
}

function Assert-MatchedHighMedium($MediumManifestPath, $HighManifestPath, $Packet) {
    if ($Preset -ne 'Medium') { return }
    if (-not (Test-Path -LiteralPath $HighManifestPath -PathType Leaf)) { throw 'Run and validate High first; the retained High manifest is required for pair checks' }
    $High = Get-Content -LiteralPath $HighManifestPath -Raw | ConvertFrom-Json
    $Medium = Get-Content -LiteralPath $MediumManifestPath -Raw | ConvertFrom-Json
    foreach ($Id in $Packet.capture.expected_frame_ids) {
        $A = @($High.frames | Where-Object { $_.frame_id -eq $Id }); $B = @($Medium.frames | Where-Object { $_.frame_id -eq $Id })
        if ($A.Count -ne 1 -or $B.Count -ne 1) { throw "Matched High/Medium record missing: $Id" }
        foreach ($Field in @('selected_stand_xz','selected_stand_offset_m','selected_stand_lateral_m','player_position','camera_position','view_heading_xz','camera_rig_transform','camera_rig_spring_length','camera_transform')) {
            $Left = ConvertTo-Json -InputObject $A[0].$Field -Compress -Depth 16
            $Right = ConvertTo-Json -InputObject $B[0].$Field -Compress -Depth 16
            if ($Left -ne $Right) { throw "High/Medium production stand/camera mismatch for $Id field $Field" }
        }
    }
}

if (-not (Test-Path -LiteralPath $PacketFile -PathType Leaf) -or -not (Test-Path -LiteralPath $AdmissionFile -PathType Leaf)) { throw 'Packet or explicit admission file is missing' }
$Packet = Get-Content -LiteralPath $PacketFile -Raw | ConvertFrom-Json
$Admission = Get-Content -LiteralPath $AdmissionFile -Raw | ConvertFrom-Json
$SourceCommit = [string]$Packet.source_commit
$Engine = [string]$Packet.engine.path
$Git = [string]$Packet.git
$Receipt = [ordered]@{
    status='NOT_ADMITTED'; run_id="p2-006-$($Preset.ToLowerInvariant())"; preset=$Preset; source_commit=$SourceCommit
    engine=$Engine; output_dir=$OutputDir; user_data_dir=$UserDataDir; started_utc=$null; ended_utc=$null
    pid=$null; exit_code=$null; stop_reason=$null; exit_observed_without_supervisor_stop=$false
    limits=$Packet.limits; frame_receipts=@()
}

try {
    if ($SourceCommit -ne $ExpectedSourceCommit) { throw "Packet must remain pinned to exact baseline $ExpectedSourceCommit" }
    if ($Packet.status -ne 'PREPARED_ONLY_NOT_EXECUTED' -or $Packet.supervisor_sha256 -eq 'PENDING') { throw 'Packet is not finalized for supervised use' }
    Assert-Hash $PSCommandPath $Packet.supervisor_sha256
    Assert-Hash $Engine $Packet.engine.sha256
    if (-not (Test-Path -LiteralPath $Git -PathType Leaf)) { throw 'Pinned Git executable missing' }
    if ($Admission.admitted -ne $true -or $Admission.source_commit -ne $SourceCommit -or $Admission.preset -ne $Preset) { throw 'Root admission is false or does not match this source/preset' }
    if ($Admission.expected_lease_thread -ne $Packet.expected_lease_thread) { throw 'Admission lease thread mismatch' }
    Assert-Source $Packet
    $ExpectedArtSha = Get-GodotTextSha256 (Join-Path $NativeStage 'data/config/art.json')
    $Receipt.art_json_text_sha256 = $ExpectedArtSha
    $InitialMemory = Assert-Resources
    $Receipt.memory_admission = $InitialMemory
    foreach ($Path in @($OutputDir,$UserDataDir,$RunReceipt,$FailureReceipt,$ActiveReceipt,$StdoutFile,$StderrFile,(Join-Path $ArtifactDir "$($Preset).manifest.json"))) {
        if (Test-Path -LiteralPath $Path) { throw "Fresh run path required; refusing reuse: $Path" }
    }
    if ($Preset -eq 'Medium' -and -not (Test-Path -LiteralPath (Join-Path $ArtifactDir 'High.manifest.json') -PathType Leaf)) { throw 'Validated High manifest must be retained before Medium' }
    Assert-NoForeignEngine
    $LeaseLock = [IO.File]::Open($OwnerLockFile, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    Assert-IdleOwner (Read-Owner) $Packet
    New-Item -ItemType Directory -Path $ArtifactDir -Force | Out-Null
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    New-Item -ItemType Directory -Path $UserDataDir | Out-Null
    $StdoutStream = [IO.File]::Open($StdoutFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $StderrStream = [IO.File]::Open($StderrFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    Assert-Source $Packet; Assert-NoForeignEngine; $Receipt.memory_admission = Assert-Resources

    $EngineArgs = @('--path',$NativeStage,'--rendering-method','forward_plus','--resolution','1920x1080','--audio-driver','Dummy',
        '--script','tools/phase2_capture_locations.gd','--','--biome=meadows','--seed=2042','--character=trainer',
        '--times=day','--views=close',"--preset=$Preset", "--source-commit=$SourceCommit")
    foreach ($Subset in $Packet.capture.subset_ids) { $EngineArgs += "--subset=$Subset" }
    $EngineArgs += '--output=' + $OutputDir.Replace('\','/')
    $StartInfo = [Diagnostics.ProcessStartInfo]::new()
    $StartInfo.FileName = $Engine; $StartInfo.WorkingDirectory = $NativeStage; $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true; $StartInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $StartInfo.RedirectStandardOutput = $true; $StartInfo.RedirectStandardError = $true
    foreach ($Arg in $EngineArgs) { $StartInfo.ArgumentList.Add($Arg) }
    foreach ($EnvName in @('APPDATA','LOCALAPPDATA','XDG_DATA_HOME')) { $StartInfo.Environment[$EnvName] = $UserDataDir }

    $Receipt.status = 'STARTING'; $Receipt.argv = @($EngineArgs); $Receipt.started_utc = [DateTime]::UtcNow.ToString('o')
    $OwnedProcess = [Diagnostics.Process]::new(); $OwnedProcess.StartInfo = $StartInfo
    if (-not $OwnedProcess.Start()) { throw 'Godot did not start' }
    $OwnedPid = $OwnedProcess.Id; $OwnedCreatedUtc = $OwnedProcess.StartTime.ToUniversalTime()
    $Receipt.pid = $OwnedPid; $Receipt.process_creation_utc = $OwnedCreatedUtc.ToString('o')
    Set-OwnedLease $true $Packet; $LeaseClaimed = $true
    $Receipt.status = 'RUNNING'; Write-Json $ActiveReceipt $Receipt
    $StdoutTask = $OwnedProcess.StandardOutput.BaseStream.CopyToAsync($StdoutStream)
    $StderrTask = $OwnedProcess.StandardError.BaseStream.CopyToAsync($StderrStream)
    $Timer = [Diagnostics.Stopwatch]::StartNew(); $LastGuard = [TimeSpan]::Zero
    while (-not $OwnedProcess.HasExited) {
        if ($Timer.Elapsed.TotalSeconds -ge $WallLimitSeconds) { $StopReason = '1200-second wall limit'; break }
        if ((Get-FreeBytes 'C') -lt 11GB) { $StopReason = 'C: free space below 11 GiB'; break }
        if ((Get-FreeBytes 'D') -lt 20GB) { $StopReason = 'D: free space below 20 GiB'; break }
        try { $CurrentMemory = Get-Headroom; if ($CurrentMemory.physical_free_bytes -lt $MinimumMemoryBytes -or $CurrentMemory.commit_free_bytes -lt $MinimumMemoryBytes) { throw '2 GiB physical/commit floor crossed' } }
        catch { $StopReason = $_.Exception.Message; break }
        if (($Timer.Elapsed - $LastGuard).TotalSeconds -ge 5) { try { Assert-NoForeignEngine } catch { $StopReason = 'foreign Godot/Blender process appeared'; break }; $LastGuard = $Timer.Elapsed }
        $StdoutStream.Flush(); $StderrStream.Flush()
        if ((Get-TreeBytes @($OutputDir,$UserDataDir,$StdoutFile,$StderrFile)) -gt $OutputLimitBytes) { $StopReason = 'combined output/home/log cap exceeded'; break }
        Start-Sleep -Milliseconds 500
    }
    if ($StopReason) { Stop-Owned $StopReason $Engine }
    if (-not $OwnedProcess.HasExited) { throw 'Owned Godot remains live; native lease retained for recovery' }
    $OwnedProcess.WaitForExit(); $null = $StdoutTask.GetAwaiter().GetResult(); $null = $StderrTask.GetAwaiter().GetResult()
    $StdoutStream.Dispose(); $StdoutStream=$null; $StderrStream.Dispose(); $StderrStream=$null
    $Receipt.exit_observed_without_supervisor_stop = -not [bool]$StopReason
    $Receipt.exit_code = $OwnedProcess.ExitCode; $Receipt.stop_reason = $StopReason
    $Receipt.output_home_logs_bytes = Get-TreeBytes @($OutputDir,$UserDataDir,$StdoutFile,$StderrFile)
    $Receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
    if ($Receipt.exit_code -ne 0 -or $StopReason -or $Receipt.output_home_logs_bytes -gt $OutputLimitBytes) { throw 'Capture failed or supervisor limit was crossed' }
    Assert-Source $Packet
    $Manifest = Assert-Manifest $Packet $Engine
    $ManifestCopy = Join-Path $ArtifactDir "$($Preset).manifest.json"
    Copy-Item -LiteralPath $OutputManifest -Destination $ManifestCopy
    $Receipt.manifest_sha256 = (Get-FileHash -LiteralPath $OutputManifest -Algorithm SHA256).Hash.ToLowerInvariant()
    $Receipt.manifest_copy = $ManifestCopy
    $Receipt.frame_receipts = @($Manifest.frames | ForEach-Object { $Image = Join-Path $OutputDir ([string]$_.frame_id + '.jpg'); @{ frame_id=$_.frame_id; sha256=(Get-FileHash -LiteralPath $Image -Algorithm SHA256).Hash.ToLowerInvariant(); bytes=(Get-Item -LiteralPath $Image).Length } })
    if ($Preset -eq 'Medium') { Assert-MatchedHighMedium $ManifestCopy (Join-Path $ArtifactDir 'High.manifest.json') $Packet; $Receipt.paired_high_medium_stands='MATCH' }
    $Receipt.status = 'BASELINE_CAPTURE_COMPLETE_REQUIRES_BLIND_REVIEW'
    Write-Json $RunReceipt $Receipt
    Set-OwnedLease $false $Packet; $LeaseClaimed = $false
} catch {
    $PrimaryException = $_.Exception
    $Receipt.primary_exception = @{ type=$PrimaryException.GetType().FullName; message=$PrimaryException.Message }
    $Receipt.failure = $PrimaryException.Message; $Receipt.stop_reason = $StopReason
    $Receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
    if ($OwnedProcess -and -not $OwnedProcess.HasExited) { try { Stop-Owned 'supervisor exception' $Engine } catch { $Receipt.cleanup_failure = $_.Exception.Message } }
    if ($OwnedProcess -and $OwnedProcess.HasExited) { $Receipt.exit_code = $OwnedProcess.ExitCode }
    if ($StdoutStream) { $StdoutStream.Dispose(); $StdoutStream=$null }; if ($StderrStream) { $StderrStream.Dispose(); $StderrStream=$null }
    if ($LeaseClaimed -and $OwnedProcess -and $OwnedProcess.HasExited) { try { Set-OwnedLease $false $Packet; $LeaseClaimed=$false } catch { $Receipt.lease_cleanup_failure = $_.Exception.Message } }
    try { New-Item -ItemType Directory -Path $ArtifactDir -Force | Out-Null; Write-Json $FailureReceipt $Receipt } catch { }
    throw
} finally {
    if ($OwnedProcess -and -not $OwnedProcess.HasExited) { try { Stop-Owned 'finally cleanup' $Engine } catch { } }
    if ($StdoutStream) { $StdoutStream.Dispose() }; if ($StderrStream) { $StderrStream.Dispose() }
    if ($LeaseLock) { $LeaseLock.Dispose() }
}
