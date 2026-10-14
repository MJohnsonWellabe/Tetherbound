#requires -Version 7.0
param(
    [Parameter(Mandatory)][ValidateSet('training', 'loaner')][string]$Batch,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$Godot,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$GodotSha256,
    [Parameter(Mandatory)][string]$Output,
    [ValidateRange(30, 180)][int]$MaxSeconds = 180,
    [string]$SourceManifest,
    [string]$Admission,
    [switch]$RootAuthorized,
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
# One coordinator-granted batch; no staging/import, retries, save injection or successors.
$Project = [IO.Path]::GetFullPath($Project)
$Godot = [IO.Path]::GetFullPath($Godot)
$Output = [IO.Path]::GetFullPath($Output)
[string[]]$files = if ($Batch -eq 'training') {
    @('test_altar_training_piece.gd', 'test_chapter_homestead.gd', 'test_f49_training_prefix.gd', 'test_training_handoff.gd')
} else { @('test_cloudreach_fly_loaner_end.gd') }
$engineArgs = @('--headless', '--path', $Project, '--script', 'tests/run_tests.gd', '--', ('--only=' + ($files -join ',')))
$plan = [ordered]@{ batch=$Batch; source=$SourceCommit; project=$Project; engine=$Godot; engine_sha256=$GodotSha256;
    arguments=$engineArgs; files=$files; output=$Output; max_seconds=$MaxSeconds; execute=[bool]$Execute;
    scope='Focused source regression tests only; no earned chain, paid gameplay, terrain or criterion closure' }
if (-not $Execute) { $plan | ConvertTo-Json -Depth 8; exit 0 }
function Hash-File([string]$path) { return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert-Source {
    $clock = [Diagnostics.Stopwatch]::StartNew()
    if ((Hash-File $SourceManifest) -cne $script:ManifestHash) { throw 'Source manifest changed' }
    foreach ($file in $script:Manifest.files) {
        if ($clock.Elapsed.TotalSeconds -gt 10) { throw 'Bounded source verification exceeded10seconds' }
        $path = [IO.Path]::GetFullPath((Join-Path $Project $file.path))
        if (-not $path.StartsWith($Project.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Source path escapes project' }
        Assert-NoReparse $path
        $item = Get-Item -LiteralPath $path
        if ($item.Length -ne $file.bytes) { throw "Source size differs: $($file.path)" }
        $read = [IO.File]::ReadAllBytesAsync($path)
        $remaining = [Math]::Max(1, 10000 - [int]$clock.ElapsedMilliseconds)
        if (-not $read.Wait($remaining)) { throw 'Source read exceeded verification budget' }
        $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($read.GetAwaiter().GetResult())).ToLowerInvariant()
        if ($clock.Elapsed.TotalSeconds -gt 10 -or $hash -cne $file.sha256) { throw "Source bytes differ or verification deadline exceeded: $($file.path)" }
    }
}
function Assert-NoReparse([string]$path) {
    $cursor = [IO.Path]::GetFullPath($path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse path refused' }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}
function Assert-IdleOwner($owner) {
    if ($owner.thread -cne $script:RootThread -or $owner.reserved -isnot [bool] -or $owner.allow_native_launch -isnot [bool] -or $owner.reserved -ne $true -or $owner.allow_native_launch -ne $true -or
        $owner.active_process_id -or $owner.active_session_id -or $owner.run_id -or @($owner.processes).Count) { throw 'Exact root owner is not idle and launch-authorized' }
}
function Write-Owner($owner) {
    if ((Hash-File $script:OwnerPath) -cne $script:OwnerHash) { throw 'Owner compare-and-swap failed' }
    $owner.updated_utc = [DateTime]::UtcNow.ToString('o')
    $temporary = $script:OwnerPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temporary, ($owner | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))
    [IO.File]::Move($temporary, $script:OwnerPath, $true)
    $script:OwnerHash = Hash-File $script:OwnerPath
}
function Assert-Admission {
    if ((Hash-File $Admission) -cne $script:AdmissionHash) { throw 'Admission changed' }
    $grant = Get-Content -LiteralPath $Admission -Raw | ConvertFrom-Json -AsHashtable
    $age = ([DateTimeOffset]::UtcNow - [DateTimeOffset]::Parse($grant.admitted_utc)).TotalSeconds
    if ($age -lt 0 -or $age -gt 300 -or $grant.status -cne 'ROOT_ADMITTED' -or $grant.launch_allowed -isnot [bool] -or $grant.launch_allowed -ne $true -or
        $grant.root_thread -cne $script:RootThread -or $grant.runner_sha256 -cne (Hash-File $PSCommandPath) -or
        $grant.manifest_sha256 -cne $script:ManifestHash -or $grant.source_commit -cne $SourceCommit -or
        $grant.batch -cne $Batch -or $grant.project -ine $Project -or $grant.output -ine $Output -or
        $grant.engine -ine $Godot -or $grant.engine_sha256 -cne $GodotSha256 -or $grant.max_seconds -ne $MaxSeconds -or
        ($grant.arguments | ConvertTo-Json -Compress) -cne ($engineArgs | ConvertTo-Json -Compress)) { throw 'Exact fresh root launch admission missing' }
}
function Read-Capacity {
    $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 2
    $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -OperationTimeoutSec 2
    return [ordered]@{ physical_bytes=([long]$os.FreePhysicalMemory * 1KB);
        commit_free_bytes=([long]$memory.CommitLimit - [long]$memory.CommittedBytes);
        c_bytes=(Get-PSDrive C).Free; d_bytes=(Get-PSDrive D).Free }
}
function Assert-Capacity($capacity, [bool]$admitting = $false) {
    $cFloor = if ($admitting) { 10.5GB } else { 10GB }
    $dFloor = if ($admitting) { 21GB } else { 20GB }
    if ($capacity.physical_bytes -lt 2GB -or $capacity.commit_free_bytes -lt 2GB -or
        $capacity.c_bytes -lt $cFloor -or $capacity.d_bytes -lt $dFloor) { throw 'Capacity floor: physical/commit2GiB; admit C10.5/D21GiB, stop C10/D20GiB' }
}
function Get-RunVerdict([string]$outText, [string]$errText, [string[]]$expected) {
    $actual = @([regex]::Matches($outText, '(?m)^\s*ok\s+(\S+\.gd :: test_[A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
    $summary = [regex]::Matches($outText, '(?m)^(\d+) tests, (\d+) assertions, (\d+) failed\s*$')
    $passed = $expected.Count -gt 0 -and ($outText + $errText) -notmatch '(?im)SCRIPT ERROR|Parse Error|^\s*(ERROR|WARNING):' -and
        $summary.Count -eq 1 -and [int]$summary[0].Groups[1].Value -eq $expected.Count -and
        [int]$summary[0].Groups[2].Value -gt 0 -and [int]$summary[0].Groups[3].Value -eq 0 -and
        $actual.Count -eq $expected.Count -and -not (Compare-Object ($expected | Sort-Object) ($actual | Sort-Object))
    return @{ passed=[bool]$passed; actual_tests=$actual }
}
if (-not $RootAuthorized -or -not $SourceManifest -or -not $Admission) { throw 'Execute requires root authorization, source manifest and fresh admission' }
$script:RootThread = '01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$script:OwnerPath = 'C:/CodexTemp/tetherbound-native-owner.json'
$lockPath = 'C:/CodexTemp/tetherbound-native-owner.lock'
foreach ($path in @($Project, $Godot, $Output, $SourceManifest, $Admission, $script:OwnerPath, $lockPath)) { Assert-NoReparse $path }
$script:ManifestHash = Hash-File $SourceManifest
$script:AdmissionHash = Hash-File $Admission
if ((Get-Item -LiteralPath $SourceManifest).Length -gt 4MB -or (Get-Item -LiteralPath $Admission).Length -gt 4MB) { throw 'Admission/manifest exceeds4MiB' }
$script:Manifest = Get-Content -LiteralPath $SourceManifest -Raw | ConvertFrom-Json -AsHashtable
if ($script:Manifest.source_commit -cne $SourceCommit -or $script:Manifest.scope -cne 'reviewed_runtime_projection' -or
    $script:Manifest.files -isnot [array] -or $script:Manifest.files.Count -lt 1 -or $script:Manifest.files.Count -gt 4096 -or
    ($script:Manifest.files | Measure-Object bytes -Sum).Sum -gt 256MB) { throw 'Source projection manifest outside bounded contract' }
$uniquePaths = @{}
foreach ($file in $script:Manifest.files) {
    if ($file.path -isnot [string] -or [IO.Path]::IsPathRooted($file.path) -or $file.path.Contains(':') -or $file.path -match '(^|[\\/])\.\.?([\\/]|$)' -or
        $file.bytes -isnot [long] -and $file.bytes -isnot [int] -or $file.bytes -lt 0 -or
        $file.sha256 -cnotmatch '^[0-9a-f]{64}$' -or $uniquePaths.ContainsKey($file.path)) { throw 'Malformed/duplicate source binding' }
    $uniquePaths[$file.path] = $true
}
foreach ($required in @('project.godot', 'tests/run_tests.gd') + @($files | ForEach-Object { 'tests/' + $_ })) {
    if (-not $uniquePaths.ContainsKey($required)) { throw "Source manifest omits $required" }
}
Assert-Admission
$ownerLock = $null
$leaseOwned = $false
$leaseId = 'routes-' + $Batch + '-' + [Guid]::NewGuid().ToString('N')
try {
$ownerLock = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$script:OwnerHash = Hash-File $script:OwnerPath
$owner = Get-Content -LiteralPath $script:OwnerPath -Raw | ConvertFrom-Json -AsHashtable
Assert-IdleOwner $owner
Assert-Source
if (Test-Path -LiteralPath $Output) { throw 'Output already exists; preserving evidence' }
if ((Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant() -cne $GodotSha256) { throw 'Engine hash differs from admitted runtime' }
if (Get-CimInstance Win32_Process -OperationTimeoutSec 2 | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\.exe$' }) { throw 'Native writer slot occupied' }
$capacity = Read-Capacity
Assert-Capacity $capacity $true
$expected = @()
$sourceHashes = [ordered]@{}
foreach ($file in $files) {
    $path = Join-Path $Project "tests/$file"
    $body = Get-Content -LiteralPath $path -Raw
    $methods = [regex]::Matches($body, '(?m)^func (test_[A-Za-z0-9_]+)\(')
    if ($methods.Count -eq 0) { throw "No test methods in $file" }
    foreach ($method in $methods) { $expected += "$file :: $($method.Groups[1].Value)" }
    $sourceHashes[$file] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}
$sourceHashes['tests/run_tests.gd'] = (Get-FileHash -LiteralPath (Join-Path $Project 'tests/run_tests.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.Directory]::CreateDirectory($Output) | Out-Null
$start = [Diagnostics.ProcessStartInfo]::new()
$start.FileName = $Godot
$start.WorkingDirectory = $Project
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
foreach ($argument in $engineArgs) { $start.ArgumentList.Add($argument) }
$start.Environment['GIT_CONFIG_COUNT'] = '2'
$start.Environment['GIT_CONFIG_KEY_0'] = 'gc.auto'
$start.Environment['GIT_CONFIG_VALUE_0'] = '0'
$start.Environment['GIT_CONFIG_KEY_1'] = 'maintenance.auto'
$start.Environment['GIT_CONFIG_VALUE_1'] = 'false'
$start.Environment['TB_COMMIT_SHA'] = $SourceCommit
# Independent managed timer enforces the engine deadline even if CIM stalls.
if (-not ('RoutesCheckDeadline' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Threading;
using System.Runtime.InteropServices;
public sealed class RoutesCheckDeadline : IDisposable {
    [DllImport("shell32.dll", SetLastError=true)] static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)] string command, out int count);
    [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr pointer);
    public static string[] SplitCommandLine(string command) {
        int count; var pointer = CommandLineToArgvW(command, out count);
        if(pointer == IntPtr.Zero) throw new InvalidOperationException("Cannot inspect process argv");
        try {
            var result = new string[count];
            for(int i=0; i<count; i++) result[i] = Marshal.PtrToStringUni(Marshal.ReadIntPtr(pointer, i*IntPtr.Size));
            return result;
        } finally { LocalFree(pointer); }
    }
    readonly object gate = new object();
    readonly Process process;
    readonly Timer timer;
    readonly long createdTicks;
    readonly string executable;
    bool cancelled;
    public bool TimedOut { get; private set; }
    public string Error { get; private set; }
    public RoutesCheckDeadline(Process target, int milliseconds, string engine) {
        process = target;
        createdTicks = target.StartTime.ToUniversalTime().Ticks;
        executable = engine;
        timer = new Timer(_ => {
            lock(gate) {
                if(cancelled) return;
                try {
                    if(!process.HasExited) { TimedOut = true; StopOwned(); }
                } catch(Exception error) { Error = error.ToString(); }
            }
        }, null, milliseconds, Timeout.Infinite);
    }
    public void StopOwned() {
        if(process.HasExited) return;
        if(process.StartTime.ToUniversalTime().Ticks != createdTicks ||
            !String.Equals(process.MainModule.FileName, executable, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Owned process creation/executable mismatch; refusing kill");
        process.Kill(true);
    }
    public void Dispose() { lock(gate) { cancelled = true; timer.Dispose(); } }
}
'@
}
$process = [Diagnostics.Process]::new()
$process.StartInfo = $start
$watch = [Diagnostics.Stopwatch]::StartNew()
$result = [ordered]@{ plan=$plan; started_utc=[DateTime]::UtcNow.ToString('o'); initial_capacity=$capacity;
    source_files_sha256=$sourceHashes; expected_tests=$expected; pid=$null; natural_exit=$false; exit_code=$null; passed=$false; errors=@() }
$deadline = $null
$stdout = $null
$stderr = $null
try {
    Assert-Source
    Assert-Admission
    $owner.active_process_id = $PID
    $owner.run_id = $leaseId
    $owner.active_kind = 'routes-scoped-checks'
    $owner.run_directory = $Output
    $owner.processes = @()
    Write-Owner $owner
    $leaseOwned = $true
    if (-not $process.Start()) { throw 'Engine failed to start' }
    $result.pid = $process.Id
    $result.created_utc = $process.StartTime.ToUniversalTime().ToString('o')
    $deadline = [RoutesCheckDeadline]::new($process, $MaxSeconds * 1000, $Godot)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $result.supervisor_pid = $PID
    $result.admission_sha256 = $script:AdmissionHash
    $result.source_manifest_sha256 = $script:ManifestHash
    $owner.processes = @(@{ pid=$process.Id; created_utc=$result.created_utc; engine=$Godot })
    Write-Owner $owner
    $observed = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -OperationTimeoutSec 2
    if (-not $observed -or $observed.ExecutablePath -ine $Godot -or $observed.ParentProcessId -ne $PID -or
        [Math]::Abs(($observed.CreationDate.ToUniversalTime() - $process.StartTime.ToUniversalTime()).TotalSeconds) -gt 1) { throw 'Owned PID/path/parent/creation observation mismatch' }
    $actualArgv = [RoutesCheckDeadline]::SplitCommandLine($observed.CommandLine)
    if ($actualArgv.Count -ne $engineArgs.Count + 1 -or $actualArgv[0] -ine $Godot) { throw 'Observed argv differs' }
    for ($index = 0; $index -lt $engineArgs.Count; $index++) { if ($actualArgv[$index + 1] -cne $engineArgs[$index]) { throw 'Observed argv differs' } }
    $result.observed_command_line = $observed.CommandLine
    while (-not $process.WaitForExit(1000)) {
        if ($watch.Elapsed.TotalSeconds -ge $MaxSeconds) { throw 'Wall-time ceiling reached' }
        $result.last_capacity = Read-Capacity
        Assert-Capacity $result.last_capacity
    }
    $result.natural_exit = $true
    $result.exit_code = $process.ExitCode
    Assert-Source
} catch { $result.errors += $_.Exception.Message }
finally {
    try {
        if ($null -ne $deadline) {
            $deadline.Dispose()
            if ($deadline.TimedOut) { $result.errors += 'Independent engine deadline reached'; $result.natural_exit = $false }
            if ($deadline.Error) { $result.errors += $deadline.Error }
        }
    } catch { $result.errors += 'Deadline cleanup: ' + $_.Exception.Message }
    try {
        if ($result.pid -and -not $process.HasExited) {
            if ($null -eq $deadline) { throw 'Owned process identity guard missing; root must inspect live process' }
            $deadline.StopOwned()
            if (-not $process.WaitForExit(10000)) { $result.errors += 'Killed process did not exit within10seconds; root must inspect' }
        }
    } catch { $result.errors += 'Process cleanup failed: ' + $_.Exception.Message }
    foreach ($stream in @(@('stdout', $stdout), @('stderr', $stderr))) {
        $task = $stream[1]
        if ($null -ne $task) {
            try {
                if ($task.Wait(10000)) { [IO.File]::WriteAllText((Join-Path $Output ($stream[0] + '.log')), $task.GetAwaiter().GetResult()) }
                else { $result.errors += 'Output drain exceeded10seconds; root must inspect' }
            } catch { $result.errors += 'Output drain failed: ' + $_.Exception.Message }
        }
    }
    $result.elapsed_seconds = $watch.Elapsed.TotalSeconds
    $result.finished_utc = [DateTime]::UtcNow.ToString('o')

}
try {
    $outText = Get-Content -LiteralPath (Join-Path $Output 'stdout.log') -Raw
    $errText = Get-Content -LiteralPath (Join-Path $Output 'stderr.log') -Raw
    $verdict = Get-RunVerdict $outText $errText $expected
    $result.actual_tests = $verdict.actual_tests
    $result.passed = $result.errors.Count -eq 0 -and $result.natural_exit -and $result.exit_code -eq 0 -and $verdict.passed
    foreach ($name in @('stdout.log', 'stderr.log')) {
        $result[$name + '_sha256'] = (Get-FileHash -LiteralPath (Join-Path $Output $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    }
} catch { $result.errors += $_.Exception.Message; $result.passed = $false }
$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Output 'supervisor.json') -Encoding utf8
(Get-FileHash -LiteralPath (Join-Path $Output 'supervisor.json') -Algorithm SHA256).Hash.ToLowerInvariant() | Set-Content -LiteralPath (Join-Path $Output 'supervisor.sha256') -Encoding ascii
$result | ConvertTo-Json -Depth 12
if (-not $result.passed) { exit 1 }

} finally {
    try {
    if ($leaseOwned) {
        try {
            if ($result.pid -and -not $process.HasExited) { throw 'Live child: retain root lease' }
            if (Get-CimInstance Win32_Process -OperationTimeoutSec 2 | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\.exe$' }) { throw 'Native process remains: retain root lease' }
            $current = Get-Content -LiteralPath $script:OwnerPath -Raw | ConvertFrom-Json -AsHashtable
            if ((Hash-File $script:OwnerPath) -cne $script:OwnerHash -or $current.thread -cne $script:RootThread -or
                $current.active_process_id -ne $PID -or $current.run_id -cne $leaseId) { throw 'Owner identity changed: retain lease' }
            $current.active_process_id = $null; $current.active_session_id = $null; $current.run_id = $null
            $current.active_kind = $null; $current.run_directory = $null; $current.processes = @()
            Write-Owner $current
        } catch {
            if ($result) {
                $result.passed = $false; $result.errors += 'Lease retained: ' + $_.Exception.Message
                $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $Output 'supervisor.json') -Encoding utf8
                (Hash-File (Join-Path $Output 'supervisor.json')) | Set-Content -LiteralPath (Join-Path $Output 'supervisor.sha256') -Encoding ascii
            }
            throw
        }
    }
    } finally {
        if ($ownerLock) { $ownerLock.Dispose() }
        if ($process) { $process.Dispose() }
    }
}
