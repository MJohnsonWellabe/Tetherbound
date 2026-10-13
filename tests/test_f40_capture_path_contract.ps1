$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\capture_cloudreach_p2_021_paths.ps1')
$scratch = Join-Path (Split-Path -Parent $PSScriptRoot) ("tmp\f40-path-contract-" + [guid]::NewGuid().ToString('N'))
$output = Join-Path $scratch 'capture\frames'
$homePath = Join-Path $scratch 'home'
try {
    $supervisorPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\run_cloudreach_p2_021_capture.ps1'
    $supervisor = Get-Content -LiteralPath $supervisorPath -Raw
    if ($supervisor -match '(?im)^\s*param\s*\([^)]*\$PID') { throw 'Supervisor attempts to bind the reserved $PID variable' }
    if ($supervisor -notmatch '\[IO\.FileShare\]::None') { throw 'Supervisor lacks the exclusive root lock' }
    if ($supervisor -match 'Stop-Process|Start-Process') { throw 'Supervisor bypasses the retained Process handle' }
    $invokeStart = $supervisor.IndexOf('function Invoke-Leg(')
    $waitExit = $supervisor.IndexOf('$Owned.WaitForExit()', $invokeStart)
    $releaseLease = $supervisor.IndexOf('Set-OwnedLease $false', $waitExit)
    if ($invokeStart -lt 0 -or $waitExit -lt 0 -or $releaseLease -lt $waitExit) {
        throw 'Supervisor releases the lease before the owned process is confirmed exited'
    }
    if ($supervisor -match 'Assert-NoForeignWriter\s*(?=\$stopReason|\$Owned\.Start)') {
        throw 'Supervisor may reject its own active capture process'
    }
    $leg = '{"env_APPDATA":null,"output_argument":null}' | ConvertFrom-Json
    Set-F40CaptureLegValue $leg 'env_APPDATA' $scratch
    Set-F40CaptureLegValue $leg 'output_argument' '--output=C:/fixture/out'
    if ($leg.env_APPDATA -ne $scratch -or $leg.output_argument -ne '--output=C:/fixture/out') {
        throw 'Packet leg values were not assigned through declared JSON properties'
    }
    Initialize-F40CapturePaths -OutputPath $output -HomePath $homePath
    if (Test-Path -LiteralPath $output) { throw 'Supervisor prepared the runner-owned output directory too early' }
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $output) -PathType Container)) { throw 'Output parent was not created' }
    if (-not (Test-Path -LiteralPath $homePath -PathType Container)) { throw 'Isolated home was not created' }

    # Harmless stand-in for capture_lookdev_bootstrap: it owns creating output.
    if (Test-Path -LiteralPath $output) { throw 'Stub capture rejected an already-existing output directory' }
    New-Item -ItemType Directory -Path $output | Out-Null
    Set-Content -LiteralPath (Join-Path $output 'manifest.stub') -Value 'created-by-capture-stub'
    if (-not (Test-Path -LiteralPath (Join-Path $output 'manifest.stub') -PathType Leaf)) { throw 'Stub capture did not create output' }

    $rejected = $false
    try { Initialize-F40CapturePaths -OutputPath $output -HomePath (Join-Path $scratch 'home-again') }
    catch { $rejected = $_.Exception.Message.Contains('must be absent before runner start') }
    if (-not $rejected) { throw 'Fresh-path helper did not reject a pre-existing runner output directory' }
    'F40 capture path contract PASS'
} finally {
    $resolvedScratch = [IO.Path]::GetFullPath($scratch)
    $allowedRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $PSScriptRoot) 'tmp'))
    if (-not $resolvedScratch.StartsWith($allowedRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean test path outside workspace tmp: $resolvedScratch"
    }
    if (Test-Path -LiteralPath $resolvedScratch) { Remove-Item -LiteralPath $resolvedScratch -Recurse -Force }
}
