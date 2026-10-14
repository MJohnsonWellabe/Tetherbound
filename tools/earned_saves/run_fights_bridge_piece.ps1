param(
    [Parameter(Mandatory)][ValidateSet('opening_team', 'camp_tournament', 'bridge', 'bridge_retry')][string]$Piece,
    [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
    [string]$Project = 'C:/CodexTemp/tetherbound-native-service',
    [string]$ChainRoot = 'D:/tetherbound/.artifacts/fights-chain',
    [string]$Godot = 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe',
    [ValidateRange(30, 900)][int]$MaxSeconds = 600,
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
# One explicitly granted piece per invocation. No checkout, import, deletion,
# save injection, retries or automatic advancement to another piece.
$Project = [IO.Path]::GetFullPath($Project)
$ChainRoot = [IO.Path]::GetFullPath($ChainRoot)
if ([IO.Path]::GetPathRoot($ChainRoot) -ine 'D:\') { throw 'Proof output must reside on D:' }
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
    output_boundary=$outputBoundary; predecessor=$prior; max_seconds=$MaxSeconds; output_cap_bytes=1GB; execute=[bool]$Execute }
if (-not $Execute) { $plan | ConvertTo-Json -Depth 6; exit 0 }

function Read-SourceIdentity {
    $head = & git -c gc.auto=0 -c maintenance.auto=false -C $Project rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify native source HEAD' }
    $dirty = & git -c gc.auto=0 -c maintenance.auto=false -C $Project status --porcelain
    if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Native source is dirty or cannot be verified' }
    if ($head -cne $SourceCommit) { throw "Expected $SourceCommit, found $head" }
}
function Test-EarnedReceipt($receipt, [string]$expectedSegment) {
    # Ordinary exported receipts omit top-level input_mode; the piece proof
    # explicitly identifies earned input. Diagnostics must never count as proof.
    return $null -ne $receipt -and $receipt.commit -ceq $SourceCommit -and
        $receipt.kind -ceq 'earned_meadows_piece' -and $receipt.boundary -ceq $expectedSegment -and
        $null -eq $receipt.evidence_status -and $null -eq $receipt.generated_origin -and
        $null -eq $receipt.input_mode -and $receipt.piece_proof.passed -is [bool] -and
        $receipt.piece_proof.passed -eq $true -and $receipt.piece_proof.segment -ceq $expectedSegment -and
        $receipt.piece_proof.mode -ceq 'new_order_meadows_piece' -and
        $receipt.piece_proof.input_mode -ceq 'earned' -and $null -eq $receipt.piece_proof.evidence_status
}
function Read-Capacity {
    $free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB
    return [ordered]@{ physical_bytes=$free; c_bytes=(Get-PSDrive C).Free; d_bytes=(Get-PSDrive D).Free }
}
function Capacity-Allows($capacity) {
    return $capacity.physical_bytes -ge 2GB -and $capacity.c_bytes -ge 10GB -and $capacity.d_bytes -ge 20GB
}
function Read-OutputBytes {
    if (-not (Test-Path -LiteralPath $ChainRoot)) { return 0L }
    $measure = Get-ChildItem -LiteralPath $ChainRoot -Recurse -File -Force -ErrorAction Stop | Measure-Object -Property Length -Sum
    return [long]$measure.Sum
}
Read-SourceIdentity
if ((Read-OutputBytes) -ge 1GB) { throw 'Series output already at 1 GiB limit' }
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Pinned engine is absent' }
if (Test-Path -LiteralPath $outputRoot) { throw 'Piece output root exists; preserving it' }
if (Test-Path -LiteralPath ($outputRoot + '_working_' + $segment)) { throw 'Piece scratch exists; preserving it' }
if (Test-Path Env:TB_WORLD_SEED) { throw 'Earned pieces must retain their actual population, without TB_WORLD_SEED' }
if ($prior) {
    $receiptPath = Join-Path $prior 'receipt.json'
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'Missing earned predecessor receipt' }
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if (-not (Test-EarnedReceipt $receipt (Split-Path $prior -Leaf))) {
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
$outStream = $null
$errStream = $null
$watch = [Diagnostics.Stopwatch]::StartNew()
$result = [ordered]@{ plan=$plan; started_utc=[DateTime]::UtcNow.ToString('o'); initial_capacity=$initialCapacity;
    pid=$null; natural_exit=$false; exit_code=$null; stop_reason='not_started'; passed=$false }
try {
    $outStream = [IO.File]::Open((Join-Path $logRoot "$Piece.stdout.log"), 'CreateNew', 'Write', 'ReadWrite')
    $errStream = [IO.File]::Open((Join-Path $logRoot "$Piece.stderr.log"), 'CreateNew', 'Write', 'ReadWrite')
    if (-not $process.Start()) { throw 'Engine process did not start' }
    $result.pid = $process.Id
    $stdout = $process.StandardOutput.BaseStream.CopyToAsync($outStream)
    $stderr = $process.StandardError.BaseStream.CopyToAsync($errStream)
    while (-not $process.WaitForExit(1000)) {
        if ($watch.Elapsed.TotalSeconds -ge $MaxSeconds) { $result.stop_reason='time_budget'; break }
        if ((Read-OutputBytes) -ge 1GB) { $result.stop_reason='output_cap'; break }
        $capacity = Read-Capacity
        $result.last_capacity = $capacity
        if (-not (Capacity-Allows $capacity)) { $result.stop_reason='capacity_floor'; break }
    }
    if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
    elseif ($result.stop_reason -eq 'not_started') { $result.natural_exit=$true; $result.stop_reason='natural_exit' }
    $result.exit_code = $process.ExitCode
    $stdout.GetAwaiter().GetResult()
    $stderr.GetAwaiter().GetResult()
    $outStream.Dispose(); $errStream.Dispose()
    $result.output_bytes = Read-OutputBytes
    if ($result.output_bytes -ge 1GB) { $result.natural_exit=$false; $result.stop_reason='output_cap' }
    $logErrors = Select-String -LiteralPath (Join-Path $logRoot "$Piece.stdout.log"),(Join-Path $logRoot "$Piece.stderr.log") -Pattern '^\s*(SCRIPT ERROR|ERROR|Parse Error|Shader compilation failed)\b' -Quiet
    Read-SourceIdentity
    $receiptPath = Join-Path $outputBoundary 'receipt.json'
    if ($result.natural_exit -and $result.exit_code -eq 0 -and
        (-not ($logErrors -contains $true)) -and (Test-Path -LiteralPath $receiptPath)) {
        $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
        $result.passed = Test-EarnedReceipt $receipt $segment
        $result.receipt_sha256 = (Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
} catch {
    $result.error = $_.Exception.Message
    if ($result.stop_reason -eq 'not_started') { $result.stop_reason='supervisor_error' }
} finally {
    if ($result.pid -and -not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
    if ($outStream) { $outStream.Dispose() }; if ($errStream) { $errStream.Dispose() }
    $result.elapsed_seconds = $watch.Elapsed.TotalSeconds
    $result.finished_utc = [DateTime]::UtcNow.ToString('o')
    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $supervisor -Encoding utf8
    $process.Dispose()
}
$result | ConvertTo-Json -Depth 10
if (-not $result.passed) { exit 1 }
