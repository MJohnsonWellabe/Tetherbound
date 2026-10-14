$ErrorActionPreference = 'Stop'

# Prepared supervisor only. Root must explicitly launch after reviewing this file.
$source = '1f6d7e210888244d544ea4290770cb844ca21a66'
$expectedLeaseThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$stage = 'C:\CodexTemp\tetherbound-native-service'
$artifactRoot = 'D:\tetherbound\.artifacts\codex-service-creatures\stormursa-f36-sidefaint'
$outputRoot = 'C:\CodexTemp\codex-service-creatures'
$leasePath = 'C:\CodexTemp\tetherbound-native-owner.json'
$engine = 'C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64.exe'
$runner = Join-Path $artifactRoot 'capture_stormursa_f36_sidefaint.gd'
$git = 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
$script:activeCapturePid = $null
$script:leaseCapturePid = $null
$script:leaseHeldByThisSupervisor = $false

function Write-Receipt([string]$Path, $Value) {
    $Value | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Assert-Source {
    $head = (& $git -C $stage rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $head -ne $source) { throw "Native checkout must remain at reviewed source $source (found $head)" }
    $status = & $git -C $stage status --porcelain --untracked-files=no
    if ($LASTEXITCODE -ne 0 -or $status) { throw 'Native source has tracked modifications' }
}
function Assert-Quiet {
    $running = @(Get-Process -Name 'Godot*','blender*' -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw ('Unowned Godot/Blender process present: ' + (($running | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join ', ')) }
}
function Get-OutputBytes([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return [long]0 }
    $m = Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    if ($null -eq $m.Sum) { return [long]0 }
    return [long]$m.Sum
}
function Get-PairOutputBytes([string]$CurrentPath) {
    $total = Get-OutputBytes $CurrentPath
    $baseline = Join-Path $outputRoot 'stormursa-sidefaint-baseline'
    if ($CurrentPath -ne $baseline) { $total += Get-OutputBytes $baseline }
    return [long]$total
}
function Set-OwnedLease([int]$CapturePid, [string]$Purpose, [string]$RunDirectory) {
    $lease = Get-Content -LiteralPath $leasePath -Raw | ConvertFrom-Json
    if ($lease.thread -ne $expectedLeaseThread -or -not $lease.reserved -or -not $lease.allow_native_launch) { throw 'Exact native lease identity/reservation/launch permission changed' }
    if ($CapturePid -gt 0) {
        if ($lease.active_process_id -or @($lease.processes).Count -gt 0) { throw 'Lease is already occupied' }
        $lease.active_process_id = $CapturePid
        $lease.processes = @(@{ kind = 'stormursa_sidefaint_capture'; pid = $CapturePid })
        $lease.purpose = $Purpose
        $lease.run_directory = $RunDirectory
        $lease.source = $source
    } else {
        if ($lease.active_process_id -and $lease.active_process_id -ne $script:leaseCapturePid) { throw 'Refusing to clear a lease owned by another PID' }
        $lease.active_process_id = $null
        $lease.processes = @()
        $lease.purpose = 'Service lane reserved; no native writer'
        $lease.run_directory = $null
        $lease.source = $source
    }
    $lease.updated_utc = [DateTime]::UtcNow.ToString('o')
    Write-Receipt $leasePath $lease
}
function Invoke-CaptureArm([string]$Arm, [bool]$Candidate) {
    Assert-Quiet
    Assert-Source
    if ((Get-PSDrive C).Free -lt 14GB) { throw 'Admission requires at least 14 GiB free on C:' }
    $out = Join-Path $outputRoot "stormursa-sidefaint-$Arm"
    $captureHome = Join-Path $outputRoot "stormursa-sidefaint-$Arm-home"
    if (Test-Path -LiteralPath $out) { throw "Output must be fresh: $out" }
    if (Test-Path -LiteralPath $captureHome) { throw "Capture home must be fresh: $captureHome" }
    New-Item -ItemType Directory -Path $captureHome | Out-Null

    $outputArg = '--out=' + $out.Replace('\','/')
    $args = @('--path',$stage,'--rendering-method','gl_compatibility','--resolution','1280x800','--audio-driver','Dummy','--script',$runner,'--', '--species=stormursa','--whole-body',"--source-commit=$source", $outputArg)
    if ($Candidate) { $args += '--candidate' }
    $previousEnv = @{}
    foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_DATA_HOME')) { $previousEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
    $env:APPDATA = $captureHome
    $env:LOCALAPPDATA = $captureHome
    $env:XDG_DATA_HOME = $captureHome
    $receipt = [ordered]@{
        status='PREPARED_NOT_LAUNCHED'; arm=$Arm; candidate=$Candidate; source=$source
        renderer='gl_compatibility'; resolution='1280x800'; planned_frames=5; phases=@(0.0,0.25,0.5,0.75,1.0)
        output=$out; capture_home=$captureHome; engine=$engine; args=$args; runner=$runner
        started_utc=$null; ended_utc=$null; pid=$null; exit_code=$null; stop_reason=$null
        hard_limits=@{ wall_seconds=300; output_bytes=268435456; c_admit_bytes=15032385536; c_stop_bytes=11811160064 }
        scope='One Stormursa faint stage capture, no GLB export or gameplay/evolution validation.'
    }
    try {
        Write-Receipt (Join-Path $artifactRoot "${Arm}-launch.json") $receipt
        Write-Receipt (Join-Path $artifactRoot 'active-capture.json') $receipt
        $receipt.status = 'RUNNING'
        $receipt.started_utc = [DateTime]::UtcNow.ToString('o')
        Write-Receipt (Join-Path $artifactRoot "${Arm}-launch.json") $receipt
        Write-Receipt (Join-Path $artifactRoot 'active-capture.json') $receipt
        $stdout = Join-Path $artifactRoot "${Arm}.stdout.log"
        $stderr = Join-Path $artifactRoot "${Arm}.stderr.log"
        $proc = Start-Process -FilePath $engine -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $script:activeCapturePid = $proc.Id
        $script:leaseCapturePid = $proc.Id
        Set-OwnedLease $proc.Id "Stormursa F36 side-faint $Arm capture" $out
        $script:leaseHeldByThisSupervisor = $true
        $receipt.pid = $proc.Id
        Write-Receipt (Join-Path $artifactRoot "${Arm}-launch.json") $receipt
        Write-Receipt (Join-Path $artifactRoot 'active-capture.json') $receipt
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $stopReason = $null
        while ($true) {
            $owned = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
            if (-not $owned) { break }
            if ($timer.Elapsed.TotalSeconds -ge 300) { $stopReason = '300-second wall limit'; break }
            if ((Get-PSDrive C).Free -lt 11GB) { $stopReason = 'C: free space below 11 GiB'; break }
            if ((Get-PairOutputBytes $out) -gt 256MB) { $stopReason = 'Matched-pair output exceeded 256 MiB'; break }
            Start-Sleep -Seconds 5
        }
        if ($stopReason) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Wait-Process -Id $proc.Id -ErrorAction SilentlyContinue
        }
        $proc.WaitForExit()
        $proc.Refresh()
        $receipt.status = if ($stopReason) { 'FAILED_STOPPED' } elseif ($proc.ExitCode -eq 0) { 'EXITED_ZERO_NEEDS_RECEIPT_AUDIT' } else { 'FAILED_EXIT' }
        $receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
        $receipt.exit_code = $proc.ExitCode
        $receipt.stop_reason = $stopReason
        $receipt.output_bytes = Get-OutputBytes $out
        $receipt.pair_output_bytes = Get-PairOutputBytes $out
        $receipt.stdout = $stdout
        $receipt.stderr = $stderr
        Write-Receipt (Join-Path $artifactRoot "${Arm}-result.json") $receipt
        Write-Receipt (Join-Path $artifactRoot 'active-capture.json') $receipt
        $script:activeCapturePid = $null
        if ($stopReason -or $proc.ExitCode -ne 0) { throw "$Arm capture did not exit successfully" }
        Set-OwnedLease 0 '' ''
        $script:leaseHeldByThisSupervisor = $false
    } catch {
        $receipt.status = 'FAILED'
        $receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
        $receipt.failure = $_.Exception.Message
        if ($null -ne $proc) {
            $receipt.pid = $proc.Id
            try { $proc.Refresh(); $receipt.exit_code = $proc.ExitCode } catch { }
        }
        Write-Receipt (Join-Path $artifactRoot "${Arm}-result.json") $receipt
        Write-Receipt (Join-Path $artifactRoot 'active-capture.json') $receipt
        throw
    } finally {
        foreach ($name in @('APPDATA','LOCALAPPDATA','XDG_DATA_HOME')) { [Environment]::SetEnvironmentVariable($name, $previousEnv[$name], 'Process') }
    }
}

New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
Assert-Quiet
Assert-Source
if (-not (Test-Path -LiteralPath $engine) -or -not (Test-Path -LiteralPath $runner)) { throw 'Engine or reviewed stage runner is missing' }
$lease = Get-Content -LiteralPath $leasePath -Raw | ConvertFrom-Json
if ($lease.thread -ne $expectedLeaseThread -or -not $lease.reserved -or -not $lease.allow_native_launch -or $lease.active_process_id -or @($lease.processes).Count -gt 0) { throw 'Exact native launch lease is not idle/reserved' }
if ((Get-PSDrive C).Free -lt 14GB) { throw 'Admission requires at least 14 GiB free on C:' }
foreach ($suffix in @('baseline','candidate')) {
    foreach ($kind in @('','-home')) {
        $path = Join-Path $outputRoot "stormursa-sidefaint-$suffix$kind"
        if (Test-Path -LiteralPath $path) { throw "Fresh path required: $path" }
    }
}

try {
    Invoke-CaptureArm 'baseline' $false
    Assert-Quiet
    Assert-Source
    Invoke-CaptureArm 'candidate' $true
} finally {
    if ($script:activeCapturePid -and (Get-Process -Id $script:activeCapturePid -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $script:activeCapturePid -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $script:activeCapturePid -ErrorAction SilentlyContinue
    }
    if ($script:activeCapturePid) {
        $script:activeCapturePid = $null
    }
    if ($script:leaseHeldByThisSupervisor) {
        Set-OwnedLease 0 '' ''
        $script:leaseHeldByThisSupervisor = $false
    }
}
