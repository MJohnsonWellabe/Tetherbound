#requires -Version 7.0
param(
    [Parameter(Mandatory)][ValidateSet('training', 'loaner')][string]$Batch,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
    [Parameter(Mandatory)][string]$Project,
    [Parameter(Mandatory)][string]$Godot,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$GodotSha256,
    [Parameter(Mandatory)][string]$Output,
    [ValidateRange(30, 180)][int]$MaxSeconds = 180,
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
function Assert-Source {
    $head = & git -c gc.auto=0 -c maintenance.auto=false -C $Project rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $head -cne $SourceCommit) { throw 'Source HEAD differs from admitted commit' }
    $dirty = & git -c gc.auto=0 -c maintenance.auto=false -C $Project status --porcelain
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Source checkout is dirty or unverifiable' }
}
function Read-Capacity {
    $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 2
    $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -OperationTimeoutSec 2
    return [ordered]@{ physical_bytes=([long]$os.FreePhysicalMemory * 1KB);
        commit_free_bytes=([long]$memory.CommitLimit - [long]$memory.CommittedBytes);
        c_bytes=(Get-PSDrive C).Free; d_bytes=(Get-PSDrive D).Free }
}
function Assert-Capacity($capacity) {
    if ($capacity.physical_bytes -lt 2GB -or $capacity.commit_free_bytes -lt 2GB -or
        $capacity.c_bytes -lt 10GB -or $capacity.d_bytes -lt 20GB) { throw 'Capacity floor: physical/commit2GiB, C10GiB, D20GiB' }
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
Assert-Source
if (Test-Path -LiteralPath $Output) { throw 'Output already exists; preserving evidence' }
if ((Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant() -cne $GodotSha256) { throw 'Engine hash differs from admitted runtime' }
if (Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\.exe$' }) { throw 'Native writer slot occupied' }
$capacity = Read-Capacity
Assert-Capacity $capacity
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
public sealed class RoutesCheckDeadline : IDisposable {
    readonly object gate = new object();
    readonly Process process;
    readonly Timer timer;
    bool cancelled;
    public bool TimedOut { get; private set; }
    public string Error { get; private set; }
    public RoutesCheckDeadline(Process target, int milliseconds) {
        process = target;
        timer = new Timer(_ => {
            lock(gate) {
                if(cancelled) return;
                try {
                    if(!process.HasExited) { TimedOut = true; process.Kill(true); }
                } catch(Exception error) { Error = error.ToString(); }
            }
        }, null, milliseconds, Timeout.Infinite);
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
    if (-not $process.Start()) { throw 'Engine failed to start' }
    $result.pid = $process.Id
    $deadline = [RoutesCheckDeadline]::new($process, $MaxSeconds * 1000)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
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
            $process.Kill($true)
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
    try { $process.Dispose() } catch { $result.errors += 'Process dispose: ' + $_.Exception.Message }
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
