param([Parameter(Mandatory=$true)][string]$PacketPath)
$ErrorActionPreference = 'Stop'

# Four-leg native capture launcher. The external admission record is deliberately false.
$Packet = Get-Content -LiteralPath $PacketPath -Raw | ConvertFrom-Json
if ($Packet.admission -ne $true) {
    Write-Output 'NOT ADMITTED: no lease, filesystem, engine, or receipt side effects were attempted.'
    exit 0
}
. (Join-Path $PSScriptRoot 'capture_cloudreach_p2_021_paths.ps1')

$NativeStage = 'C:\CodexTemp\tetherbound-native-service'
$ExpectedThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$OwnerFile = 'C:\CodexTemp\tetherbound-native-owner.json'
$OwnerLockPath = 'C:\CodexTemp\tetherbound-native-owner.lock'
$Engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$Git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$OutputRoot = [string]$Packet.output_root
$ArtifactRoot = [string]$Packet.artifact_root
$Python = [string]$Packet.python
$SourceCommit = [string]$Packet.source_commit
$WallLimitSeconds = 1200
$PerLegOutputLimit = 1610612736
$StdoutLogLimit = 67108864
$CStopBytes = 10GB
$DStopBytes = 20GB
$MinFreeMemoryBytes = 2GB
$LeaseLock = $null
$Owned = $null
$LeaseClaimed = $false
$PrimaryError = $null
$ActiveLeg = $null
$Result = [ordered]@{status='NOT_ADMITTED'; source_commit=$SourceCommit; legs=@(); primary_error=$null; cleanup_error=$null}

function Write-AtomicJson([string]$Path, $Value, [bool]$Replace=$false) {
    $tempPath = "$Path.$PID.tmp"
    $Value | ConvertTo-Json -Depth 24 | Set-Content -LiteralPath $tempPath -Encoding utf8NoBOM
    if (Test-Path -LiteralPath $Path) {
        if (-not $Replace) { throw "Refusing to replace receipt $Path" }
        [IO.File]::Move($tempPath, $Path, $true)
    } else { [IO.File]::Move($tempPath, $Path) }
}
function Get-FreeBytes([string]$Drive) {
    $driveInfo = [IO.DriveInfo]::new("$Drive`:\")
    if (-not $driveInfo.IsReady) { throw "Drive $Drive`: is not ready" }
    return [long]$driveInfo.AvailableFreeSpace
}
function Assert-Resources([bool]$Admission=$false) {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 5 -ErrorAction Stop
    $freePhysical = [long]$os.FreePhysicalMemory * 1KB
    $freeCommit = [long]$os.FreeVirtualMemory * 1KB
    $c = Get-FreeBytes 'C'; $d = Get-FreeBytes 'D'
    if ($freePhysical -lt $MinFreeMemoryBytes -or $freeCommit -lt $MinFreeMemoryBytes) {
        throw 'Free physical or commit memory fell below 2 GiB'
    }
    if ($Admission -and ($c -lt 13GB -or $d -lt 20.5GB)) { throw 'Admission requires C: >=13 GiB and D: >=20.5 GiB free' }
    if (-not $Admission -and ($c -lt $CStopBytes -or $d -lt $DStopBytes)) { throw 'Disk stop floor reached (C:10 GiB, D:20 GiB)' }
}
function Get-TreeBytes([string[]]$Paths) {
    [long]$total = 0
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $item = Get-Item -LiteralPath $path -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Unexpected reparse point $path" }
        if ($item.PSIsContainer) {
            foreach ($file in Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop) {
                if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Unexpected reparse file $($file.FullName)" }
                $total += [long]$file.Length
            }
        } else { $total += [long]$item.Length }
    }
    return $total
}
function Invoke-Git([string[]]$GitArgs) {
    $lines = @(& $Git -C $NativeStage @GitArgs 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git read failed: $($GitArgs -join ' ') :: $($lines -join ' ')" }
    return $lines
}
function Assert-PinnedSource {
    $head = ((Invoke-Git @('rev-parse','HEAD')) | Select-Object -First 1).Trim()
    if ($head -ne $SourceCommit) { throw "Native checkout HEAD $head differs from pinned $SourceCommit" }
    if (@(Invoke-Git @('status','--porcelain','--untracked-files=no')).Count -gt 0) { throw 'Native tracked source is dirty' }
    foreach ($entry in $Packet.source_files.PSObject.Properties) {
        $relative = [string]$entry.Name
        $path = Join-Path $NativeStage $relative.Replace('/','\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Pinned source file missing: $relative" }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
        if ($actual -ne [string]$entry.Value.sha256) { throw "Pinned file hash mismatch: $relative" }
        $blob = ((Invoke-Git @('hash-object',$path)) | Select-Object -First 1).Trim()
        $pinnedBlob = ((Invoke-Git @('rev-parse',"${SourceCommit}:$relative")) | Select-Object -First 1).Trim()
        if ($blob -ne $pinnedBlob -or $blob -ne [string]$entry.Value.git_blob) { throw "Pinned Git blob mismatch: $relative" }
    }
    foreach ($resource in $Packet.resource_dependencies) {
        if (-not (Test-Path -LiteralPath (Join-Path $NativeStage ([string]$resource).Replace('/','\')) -PathType Leaf)) {
            throw "Required pinned resource dependency is absent: $resource"
        }
    }
}
function Assert-NoForeignWriter {
    $rows = @(Get-CimInstance -ClassName Win32_Process -OperationTimeoutSec 5 -ErrorAction Stop | Where-Object {
        $_.Name -match '^(Godot.*|Blender.*)\.exe$'
    })
    if ($rows.Count) { throw ('Godot/Blender writer is active: ' + (($rows | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ', ')) }
}
function Read-Owner {
    if (-not (Test-Path -LiteralPath $OwnerFile -PathType Leaf)) { throw 'Root native owner lease is missing' }
    return Get-Content -LiteralPath $OwnerFile -Raw | ConvertFrom-Json
}
function Assert-IdleOwner($owner) {
    if ($owner.thread -ne $ExpectedThread -or $owner.reserved -ne $true -or $owner.allow_native_launch -ne $true) {
        throw 'Native lease identity or launch authorization differs'
    }
    if ($owner.active_process_id -or $owner.active_session_id -or $owner.run_id -or $owner.active_kind -or
        $owner.run_directory -or @($owner.processes).Count -gt 0) { throw 'Root native lease is occupied' }
}
function Set-OwnedLease([bool]$Active) {
    $owner = Read-Owner
    if ($owner.thread -ne $ExpectedThread -or $owner.reserved -ne $true) { throw 'Root lease identity changed' }
    if ($Active) {
        Assert-IdleOwner $owner
        $owner.active_process_id = $Owned.Id
        $owner.processes = @(@{kind='f40_p2_021_matrix';pid=$Owned.Id})
        $owner.active_kind = 'f40_p2_021_matrix'
        $owner.run_id = 'f40-p2-021-four-leg-r1'
        $owner.run_directory = $OutputRoot
        $owner.source = $SourceCommit
        $owner.purpose = 'F40 P2-021 baseline and candidate High/Medium matrix'
    } else {
        if ($owner.active_process_id -ne $Owned.Id -or $owner.run_id -ne 'f40-p2-021-four-leg-r1' -or
            $owner.run_directory -ne $OutputRoot -or $owner.source -ne $SourceCommit) {
            throw 'Refusing to clear a native lease not owned by this supervisor'
        }
        $owner.active_process_id = $null; $owner.processes = @(); $owner.active_kind = $null
        $owner.run_id = $null; $owner.run_directory = $null
        $owner.purpose = 'Service lane reserved; no native writer'
    }
    $owner.updated_utc = [DateTime]::UtcNow.ToString('o')
    Write-AtomicJson $OwnerFile $owner $true
}
function Get-ExactLiveIdentity($Leg) {
    if (-not $Owned -or $Owned.HasExited) { return $null }
    $row = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($Owned.Id)" -OperationTimeoutSec 5 -ErrorAction Stop
    if (-not $row) { return $null }
    if ([IO.Path]::GetFullPath([string]$row.ExecutablePath) -ne [IO.Path]::GetFullPath($Engine)) { throw 'Owned PID executable changed; refusing to signal' }
    $created = if ($row.CreationDate -is [DateTime]) { $row.CreationDate.ToUniversalTime() } else { [Management.ManagementDateTimeConverter]::ToDateTime([string]$row.CreationDate).ToUniversalTime() }
    if ([Math]::Abs(($created - $Owned.StartTime.ToUniversalTime()).TotalSeconds) -gt 1) { throw 'Owned PID creation time changed; refusing to signal' }
    $cmd = [string]$row.CommandLine
    foreach ($needle in @('--path',$NativeStage,(Join-Path $NativeStage 'tools/capture_cloudreach_f40_matrix.gd'),
            "--source-commit=$SourceCommit",("--preset=" + $Leg.preset),("--biome=cloudreach"),$Leg.output_argument)) {
        if (-not $cmd.Contains($needle,[StringComparison]::OrdinalIgnoreCase)) { throw "Owned PID argv missing '$needle'; refusing to signal" }
    }
    return $row
}
function Stop-ExactOwnedProcess([string]$Reason, $Leg) {
    if (-not $Owned -or $Owned.HasExited) { return }
    $null = Get-ExactLiveIdentity $Leg
    $Owned.Kill()
    if (-not $Owned.WaitForExit(5000)) { throw 'Retained Godot handle did not stop; preserve lease for manual recovery' }
    $Leg.stop_reason = $Reason
}
function Invoke-Leg($Leg) {
    $script:ActiveLeg = $Leg
    $out = [string]$Leg.output_dir
    $homeDir = [string]$Leg.home_dir
    foreach ($path in @($out,$homeDir)) { if (Test-Path -LiteralPath $path) { throw "Fresh isolated path required: $path" } }
    Initialize-F40CapturePaths -OutputPath $out -HomePath $homeDir
    foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_DATA_HOME','HOME','TEMP','TMP')) {
        $subdir = Join-Path $homeDir $name
        New-Item -ItemType Directory -Path $subdir -Force | Out-Null
        Set-F40CaptureLegValue $Leg "env_$name" $subdir
    }
    $scriptPath = Join-Path $NativeStage 'tools/capture_cloudreach_f40_matrix.gd'
    Set-F40CaptureLegValue $Leg 'output_argument' ('--output=' + $out.Replace('\','/'))
    $args = @('--path',$NativeStage,'--rendering-method','forward_plus','--rendering-driver','vulkan',
        '--resolution','1920x1080','--audio-driver','Dummy','--script',$scriptPath,'--',
        '--biome=cloudreach',("--preset=" + $Leg.preset),("--source-commit=" + $SourceCommit),
        $Leg.output_argument)
    if ($Leg.variant -eq 'p2_021_candidate') { $args += '--f40-open-terrain-candidate' }
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$Engine; $info.WorkingDirectory=$NativeStage; $info.UseShellExecute=$false
    $info.CreateNoWindow=$true; $info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    foreach ($arg in $args) { $info.ArgumentList.Add([string]$arg) }
    foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_DATA_HOME','HOME','TEMP','TMP')) { $info.Environment[$name]=$Leg["env_$name"] }
    $stdoutPath=Join-Path $ArtifactRoot ("$($Leg.name).stdout.log")
    $stderrPath=Join-Path $ArtifactRoot ("$($Leg.name).stderr.log")
    foreach ($path in @($stdoutPath,$stderrPath)) { if (Test-Path -LiteralPath $path) { throw "Fresh log path required: $path" } }
    $outStream=[IO.File]::Open($stdoutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $errStream=[IO.File]::Open($stderrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:Owned=[Diagnostics.Process]::new(); $Owned.StartInfo=$info
    if (-not $Owned.Start()) { throw 'Godot process did not start' }
    $leg.pid=$Owned.Id; $leg.creation_utc=$Owned.StartTime.ToUniversalTime().ToString('o')
    $leg.started_utc=[DateTime]::UtcNow.ToString('o'); $leg.status='RUNNING'
    Set-OwnedLease $true; $script:LeaseClaimed=$true
    $stdoutTask=$Owned.StandardOutput.BaseStream.CopyToAsync($outStream)
    $stderrTask=$Owned.StandardError.BaseStream.CopyToAsync($errStream)
    $clock=[Diagnostics.Stopwatch]::StartNew(); $stopReason=$null
    while (-not $Owned.HasExited) {
        if ($clock.Elapsed.TotalSeconds -ge $WallLimitSeconds) { $stopReason='leg wall time exceeded 1200 seconds'; break }
        Assert-Resources
        $outStream.Flush(); $errStream.Flush()
        $bytes=Get-TreeBytes @($out,$homeDir,$stdoutPath,$stderrPath)
        if ($bytes -gt $PerLegOutputLimit) { $stopReason='leg output exceeded 1.5 GiB'; break }
        if ((Get-Item -LiteralPath $stdoutPath).Length -gt $StdoutLogLimit -or
            (Get-Item -LiteralPath $stderrPath).Length -gt $StdoutLogLimit) { $stopReason='stdout/stderr exceeded 64 MiB'; break }
        Start-Sleep -Seconds 2
    }
    if ($stopReason) { Stop-ExactOwnedProcess $stopReason $Leg }
    $Owned.WaitForExit()
    $null=$stdoutTask.GetAwaiter().GetResult(); $null=$stderrTask.GetAwaiter().GetResult()
    $outStream.Dispose(); $errStream.Dispose()
    $leg.exit_code=$Owned.ExitCode; $leg.ended_utc=[DateTime]::UtcNow.ToString('o')
    $leg.output_bytes=Get-TreeBytes @($out,$homeDir,$stdoutPath,$stderrPath)
    $leg.status=if ($stopReason) {'STOPPED_BY_GUARD'} elseif ($Owned.ExitCode -eq 0) {'EXITED_ZERO'} else {'ENGINE_FAILED'}
    if ($stopReason) { throw "$($Leg.name): $stopReason" }
    if ($Owned.ExitCode -ne 0) { throw "$($Leg.name): Godot exit code $($Owned.ExitCode); see $stderrPath" }
    $manifest=Join-Path $out 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "$($Leg.name): successful process emitted no manifest" }
    $Leg.manifest=$manifest
    Set-OwnedLease $false; $script:LeaseClaimed=$false
    $script:Owned.Dispose(); $script:Owned=$null
}

try {
    if ($Packet.schema -ne 'cloudreach-p2-021-capture-packet-v1' -or $Packet.status -ne 'PREPARED_ONLY_NOT_EXECUTED') { throw 'Packet schema/status is not prepared-only' }
    if ($SourceCommit -notmatch '^[0-9a-f]{40}$' -or -not (Test-Path -LiteralPath $Engine) -or -not (Test-Path -LiteralPath $Git)) { throw 'Pinned source or runtime is invalid/unavailable' }
    $expectedLegs = @('baseline/High','baseline/Medium','p2_021_candidate/High','p2_021_candidate/Medium')
    if (@($Packet.legs).Count -ne 4) { throw 'Packet must declare exactly four capture legs' }
    $actualLegs = @($Packet.legs | ForEach-Object { "$($_.variant)/$($_.preset)" })
    if (($actualLegs -join '|') -ne ($expectedLegs -join '|')) { throw 'Packet leg order/semantics differ from baseline High/Medium then P2-021 candidate High/Medium' }
    $requiredFiles = @('tools/capture_cloudreach_f40_matrix.gd','tools/capture_lookdev_catalogue.gd',
        'tools/lookdev_capture_bootstrap.gd','tools/validate_cloudreach_p2_021_pair.py',
        'tools/rescore_cloudreach_f40.py','tools/capture_cloudreach_p2_021_paths.ps1',
        'scripts/world/cloudreach_route_verges.gd',
        'data/config/cloudreach_f40_visual.json','data/config/cloudreach_open_terrain_candidate.json',
        'data/config/art.json','data/config/debug_teleport_spots.json')
    foreach ($relative in $requiredFiles) {
        if (-not $Packet.source_files.PSObject.Properties.Name.Contains($relative)) { throw "Packet omits required pinned source $relative" }
    }
    $allPaths = @($Packet.legs | ForEach-Object { [string]$_.output_dir; [string]$_.home_dir })
    if (@($allPaths | Select-Object -Unique).Count -ne 8) { throw 'Each leg needs a unique output directory and isolated home' }
    if (-not (Test-Path -LiteralPath (Join-Path $ArtifactRoot '.') -PathType Container)) { throw 'Artifact root must already exist' }
    foreach ($leg in $Packet.legs) { if (Test-Path -LiteralPath $leg.output_dir) { throw "Output directory is not fresh: $($leg.output_dir)" } }
    Assert-PinnedSource
    Assert-Resources $true
    Assert-NoForeignWriter
    $LeaseLock=[IO.File]::Open($OwnerLockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    Assert-IdleOwner (Read-Owner)
    Assert-NoForeignWriter
    foreach ($leg in $Packet.legs) {
        Assert-PinnedSource
        Assert-Resources
        Invoke-Leg $leg
        $Result.legs += $leg
    }
    $validator=Join-Path $NativeStage 'tools/validate_cloudreach_p2_021_pair.py'
    $audit=[string]$Packet.audit_path
    $vargs=@($validator,'--project-root',$NativeStage,'--source-commit',$SourceCommit,'--output',$audit)
    foreach ($leg in $Packet.legs) { $vargs += [string]$leg.manifest }
    $validation=@(& $Python @vargs 2>&1); $code=$LASTEXITCODE
    if ($code -ne 0) { throw "Four-leg validator failed ($code): $($validation -join ' ')" }
    $Result.status='CAPTURED_AND_VALIDATED'; $Result.validation=$validation -join "`n"
} catch {
    $PrimaryError=$_.Exception.ToString()
    $Result.status='FAILED'; $Result.primary_error=$PrimaryError
} finally {
    if ($Owned -and -not $Owned.HasExited) {
        try { Stop-ExactOwnedProcess 'supervisor cleanup after primary error' $ActiveLeg }
        catch { $Result.cleanup_error=$_.Exception.ToString() }
    }
    if ($Owned) { try {$Owned.Dispose()} catch {} }
    if ($LeaseClaimed -and -not $Result.cleanup_error) {
        try { Set-OwnedLease $false } catch { $Result.cleanup_error=$_.Exception.ToString() }
    }
    if ($LeaseLock) { $LeaseLock.Dispose() }
    if ($PrimaryError) { $Result.primary_error=$PrimaryError }
    $receipt=[string]$Packet.result_receipt
    try { Write-AtomicJson $receipt $Result } catch {
        if (-not $Result.cleanup_error) { $Result.cleanup_error="receipt write failed: $($_.Exception.ToString())" }
        if (-not $Result.primary_error) { $Result.primary_error=$Result.cleanup_error }
    }
}
if ($PrimaryError) { throw $PrimaryError }
