param(
    [Parameter(Mandatory)][ValidateSet('opening_team', 'camp_tournament', 'bridge', 'bridge_retry')][string]$Piece,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
    [string]$Project = 'C:/CodexTemp/tetherbound-native-service',
    [string]$ChainRoot = 'C:/CodexTemp/fights-chain',
    [string]$Godot = 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe',
    [ValidateRange(30, 900)][int]$MaxSeconds = 600,
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
# One explicitly granted piece per invocation. No checkout, import, deletion,
# save injection, retries or automatic advancement to another piece.
$Project = [IO.Path]::GetFullPath($Project)
$ChainRoot = [IO.Path]::GetFullPath($ChainRoot)
$segment = if ($Piece -eq 'bridge_retry') { 'bridge' } else { $Piece }
$outputRoot = Join-Path $ChainRoot $Piece
$outputBoundary = Join-Path $outputRoot $segment
$prior = switch ($Piece) {
    'camp_tournament' { Join-Path $ChainRoot 'opening_team/opening_team' }
    'bridge' { Join-Path $ChainRoot 'camp_tournament/camp_tournament' }
    'bridge_retry' { Join-Path $ChainRoot 'camp_tournament/camp_tournament' }
    default { '' }
}
$engineArgs = @('--headless', '--path', $Project, '--script', 'tools/earned_saves/earned_chain_runner.gd', '--',
    "--segment=$segment", "--save-dir=$outputBoundary/save", "--receipt=$outputBoundary/receipt.json")
if ($prior) { $engineArgs += "--handoff-from=$prior" }
$plan = [ordered]@{ piece=$Piece; source=$SourceCommit; project=$Project; engine=$Godot; arguments=$engineArgs;
    output_boundary=$outputBoundary; predecessor=$prior; max_seconds=$MaxSeconds; execute=[bool]$Execute }
if (-not $Execute) { $plan | ConvertTo-Json -Depth 6; exit 0 }

function Read-SourceIdentity {
    $head = & git -c gc.auto=0 -c maintenance.auto=false -C $Project rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify native source HEAD' }
    $dirty = & git -c gc.auto=0 -c maintenance.auto=false -C $Project status --porcelain
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Native source is dirty or cannot be verified' }
    if ($head -cne $SourceCommit) { throw "Expected $SourceCommit, found $head" }
}
function Read-Capacity {
    $free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB
    return [ordered]@{ physical_bytes=$free; c_bytes=(Get-PSDrive C).Free; d_bytes=(Get-PSDrive D).Free }
}
function Capacity-Allows($capacity) {
    return $capacity.physical_bytes -ge 2GB -and $capacity.c_bytes -ge 10GB -and $capacity.d_bytes -ge 20GB
}
Read-SourceIdentity
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Pinned engine is absent' }
if (Test-Path -LiteralPath $outputRoot) { throw 'Piece output root exists; preserving it' }
if (Test-Path -LiteralPath ($outputRoot + '_working_' + $segment)) { throw 'Piece scratch exists; preserving it' }
if (Test-Path Env:TB_WORLD_SEED) { throw 'Earned pieces must retain their actual population, without TB_WORLD_SEED' }
if ($prior) {
    $receiptPath = Join-Path $prior 'receipt.json'
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'Missing earned predecessor receipt' }
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if ($receipt.commit -cne $SourceCommit -or $receipt.kind -ne 'earned_meadows_piece' -or
        $receipt.piece_proof.passed -ne $true -or $receipt.input_mode -eq 'generated_fixture') {
        throw 'Predecessor is not a passing earned piece at the exact source commit'
    }
}
$otherEngines = Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(Godot.*|Blender.*)\.exe$' }
if ($otherEngines) { throw 'Another native engine exists; coordinator must serialize the slot' }
$initialCapacity = Read-Capacity
if (-not (Capacity-Allows $initialCapacity)) { throw 'Capacity below 2 GiB physical / 10 GiB C / 20 GiB D floor' }
$logRoot = Join-Path $ChainRoot 'logs'
[IO.Directory]::CreateDirectory($logRoot) | Out-Null
$supervisor = Join-Path $logRoot "$Piece.supervisor.json"
if (Test-Path -LiteralPath $supervisor) { throw 'Supervisor evidence already exists; preserving it' }
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $Godot
$startInfo.WorkingDirectory = $Project
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
foreach ($argument in $engineArgs) { $startInfo.ArgumentList.Add($argument) }
# Also cover Git invoked by the engine's existing source-identity reader.
$startInfo.Environment['GIT_CONFIG_COUNT'] = '2'
$startInfo.Environment['GIT_CONFIG_KEY_0'] = 'gc.auto'
$startInfo.Environment['GIT_CONFIG_VALUE_0'] = '0'
$startInfo.Environment['GIT_CONFIG_KEY_1'] = 'maintenance.auto'
$startInfo.Environment['GIT_CONFIG_VALUE_1'] = 'false'
$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
$watch = [Diagnostics.Stopwatch]::StartNew()
$result = [ordered]@{ plan=$plan; started_utc=[DateTime]::UtcNow.ToString('o'); initial_capacity=$initialCapacity;
    pid=$null; natural_exit=$false; exit_code=$null; stop_reason='not_started'; passed=$false }
try {
    if (-not $process.Start()) { throw 'Engine process did not start' }
    $result.pid = $process.Id
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    while (-not $process.WaitForExit(1000)) {
        if ($watch.Elapsed.TotalSeconds -ge $MaxSeconds) { $result.stop_reason='time_budget'; break }
        $capacity = Read-Capacity
        $result.last_capacity = $capacity
        if (-not (Capacity-Allows $capacity)) { $result.stop_reason='capacity_floor'; break }
    }
    if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
    else { $result.natural_exit=$true; $result.stop_reason='natural_exit' }
    $result.exit_code = $process.ExitCode
    $outText = $stdout.GetAwaiter().GetResult()
    $errText = $stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $logRoot "$Piece.stdout.log"), $outText)
    [IO.File]::WriteAllText((Join-Path $logRoot "$Piece.stderr.log"), $errText)
    Read-SourceIdentity
    $receiptPath = Join-Path $outputBoundary 'receipt.json'
    if ($result.natural_exit -and $result.exit_code -eq 0 -and
        ($outText + $errText) -notmatch 'SCRIPT ERROR|Parse Error' -and (Test-Path -LiteralPath $receiptPath)) {
        $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
        $result.passed = $receipt.commit -ceq $SourceCommit -and $receipt.kind -eq 'earned_meadows_piece' -and
            $receipt.piece_proof.passed -eq $true -and $receipt.input_mode -ne 'generated_fixture'
        $result.receipt_sha256 = (Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
} catch {
    $result.error = $_.Exception.Message
    if ($result.stop_reason -eq 'not_started') { $result.stop_reason='supervisor_error' }
} finally {
    if ($result.pid -and -not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
    $result.elapsed_seconds = $watch.Elapsed.TotalSeconds
    $result.finished_utc = [DateTime]::UtcNow.ToString('o')
    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $supervisor -Encoding utf8
    $process.Dispose()
}
$result | ConvertTo-Json -Depth 10
if (-not $result.passed) { exit 1 }
