param(
    [string]$Godot = 'C:/Users/mattj/AppData/Local/Temp/godot47-ci-diagnose/Godot_v4.7-stable_win64_console.exe',
    [string]$ArtifactName = 'realm-transition-adapter-20260909-v1',
    [int]$Port = 39679,
    [switch]$ObserveOnly,
    [switch]$Cancellation
)
$ErrorActionPreference = 'Stop'
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$artifactRoot = [System.IO.Path]::GetFullPath((Join-Path $workspace ('.artifacts/' + $ArtifactName)))
if (-not $artifactRoot.StartsWith(($workspace + [System.IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Artifact path must remain inside this workspace.'
}
if (Test-Path -LiteralPath $artifactRoot) { throw 'Artifact root already exists; preserve the first attempt.' }
New-Item -ItemType Directory -Path $artifactRoot | Out-Null
$ownedProcesses = @()
$savedAppData = $env:APPDATA
$watch = [Diagnostics.Stopwatch]::StartNew()
$finding = ''
$memorySamples = @()
$lastMemorySample = -1.0
$sourceHashes = foreach ($relativePath in @('autoload/game_state.gd', 'tools/run_realm_transition_adapter.ps1',
    'tools/probe_realm_transition_adapter.gd', 'tools/probe_realm_transition_adapter_peer.gd',
    'scripts/net/session.gd', 'scripts/net/realm_transition.gd', 'scripts/net/realm_replication_scope.gd',
    'scripts/net/realm_spawn_origins.gd', 'scripts/net/realm_receiver_history.gd', 'scripts/net/trainer_spawn.gd',
    'scripts/net/remote_trainer.gd', 'scripts/combat/encounter_director.gd')) {
    [PSCustomObject]@{ path = $relativePath; sha256 = (Get-FileHash -LiteralPath (Join-Path $workspace $relativePath) -Algorithm SHA256).Hash }
}
function Read-AdapterHeadroom {
    $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
    $processCount = @(Get-Process).Count
    $commitPercent = [double]$memory.PercentCommittedBytesInUse
    [PSCustomObject]@{ elapsed_seconds = $watch.Elapsed.TotalSeconds; commit_percent = $commitPercent;
        process_count = $processCount; allowed = ($commitPercent -lt 90.0 -and $processCount -lt 400) }
}
try {
    $initialHeadroom = Read-AdapterHeadroom
    $memorySamples += $initialHeadroom
    if (-not $initialHeadroom.allowed) { $finding = 'Resource guard: no headroom before native launch.' }
    foreach ($role in @('host', 'departing', 'staying')) {
        if ($finding) { break }
        $profile = Join-Path $artifactRoot ($role + '-profile')
        New-Item -ItemType Directory -Path $profile | Out-Null
        $env:APPDATA = $profile
        $stdout = Join-Path $artifactRoot ($role + '.stdout.log')
        $stderr = Join-Path $artifactRoot ($role + '.stderr.log')
        $arguments = @('--headless', '--path', $workspace,
            '--script', 'tools/probe_realm_transition_adapter.gd', '--', $role, $Port)
        if ($ObserveOnly) { $arguments += 'observe' }
        if ($Cancellation) { $arguments += 'cancel' }
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments `
            -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $env:APPDATA = $savedAppData
        $ownedProcesses += [PSCustomObject]@{ role = $role; process = $process; stdout = $stdout; stderr = $stderr;
            peak_mb = 0.0; children = @{} }
        if ($role -eq 'host') {
            while ($watch.Elapsed.TotalSeconds -lt 8 -and -not $process.HasExited) {
                if ((Test-Path -LiteralPath $stdout) -and (Select-String -LiteralPath $stdout -Pattern 'ADAPTER BOOT host' -Quiet)) { break }
                if ((Test-Path -LiteralPath $stderr) -and (Select-String -LiteralPath $stderr -Pattern 'ERROR:|SCRIPT ERROR:' -Quiet)) { break }
                Start-Sleep -Milliseconds 40
                $process.Refresh()
            }
            $firstError = Select-String -LiteralPath $stderr -Pattern '^(ERROR:|SCRIPT ERROR:|WARNING:)' | Select-Object -First 1
            if ($firstError) { $finding = 'host: ' + $firstError.Line; break }
            if ($process.HasExited -and $process.ExitCode -ne 0) { $finding = 'host: exited before client launch'; break }
        }
    }
    while ($watch.Elapsed.TotalSeconds -lt 90) {
        if ($finding) { break }
        if ($watch.Elapsed.TotalSeconds - $lastMemorySample -ge 1.0) {
            $headroom = Read-AdapterHeadroom
            $memorySamples += $headroom
            # Windows console launchers may own the real engine as a child.
            # Discover only our exact lineage and fixture command, never a
            # visual worker's unrelated Godot process.
            $godotProcesses = Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%'"
            foreach ($row in $ownedProcesses) {
                foreach ($child in $godotProcesses) {
                    if ($child.ParentProcessId -eq $row.process.Id -and
                        $child.CommandLine -match ('probe_realm_transition_adapter\.gd.*\s--\s+' +
                            [Regex]::Escape($row.role) + '\s+' + $Port + '(?:\s|$)')) {
                        $childId = [int]$child.ProcessId
                        if (-not $row.children.ContainsKey($childId)) {
                            $handle = Get-Process -Id $childId -ErrorAction SilentlyContinue
                            if ($handle) { $row.children[$childId] = [PSCustomObject]@{ process = $handle; peak_mb = 0.0 } }
                        }
                    }
                }
            }
            $lastMemorySample = $watch.Elapsed.TotalSeconds
            if (-not $headroom.allowed) { $finding = 'Resource guard: system commit >=90% or process count >=400'; break }
        }
        $running = $false
        foreach ($row in $ownedProcesses) {
            $row.process.Refresh()
            if (-not $row.process.HasExited) { $row.peak_mb = [Math]::Max($row.peak_mb, $row.process.PeakWorkingSet64 / 1MB) }
            foreach ($child in $row.children.Values) {
                $child.process.Refresh()
                if (-not $child.process.HasExited) { $child.peak_mb = [Math]::Max($child.peak_mb, $child.process.PeakWorkingSet64 / 1MB) }
            }
            foreach ($logPath in @($row.stdout, $row.stderr)) {
                if (Test-Path -LiteralPath $logPath) {
                    $bad = Select-String -LiteralPath $logPath -Pattern '^(ERROR:|SCRIPT ERROR:|WARNING:|ADAPTER FAIL |ADAPTER CHECK .* FAIL )' | Select-Object -First 1
                    if ($bad) { $finding = $row.role + ': ' + $bad.Line; break }
                }
            }
            if ($finding) { break }
            if (-not $row.process.HasExited) { $running = $true }
            elseif ($row.process.ExitCode -ne 0) { $finding = $row.role + ': process exited ' + $row.process.ExitCode; break }
        }
        if ($finding -or -not $running) { break }
        if ($ObserveOnly -and $ownedProcesses.Count -eq 3) {
            $observed = @($ownedProcesses | Where-Object {
                Select-String -LiteralPath $_.stdout -Pattern '^ADAPTER OBSERVATION END ' -Quiet
            })
            if ($observed.Count -eq 3) { $finding = 'Observation-only: all three final state dumps captured; no acceptance credit'; break }
        }
        Start-Sleep -Milliseconds 40
    }
    if (-not $finding -and $watch.Elapsed.TotalSeconds -ge 90) { $finding = '90-second runner deadline' }
} finally {
    $env:APPDATA = $savedAppData
    foreach ($row in $ownedProcesses) {
        $row.process.Refresh()
        if (-not $row.process.HasExited) { $row.process.Kill($true) }
        $row.process.WaitForExit()
        foreach ($child in $row.children.Values) {
            $child.process.Refresh()
            if (-not $child.process.HasExited) { $child.process.Kill() }
            $child.process.WaitForExit()
        }
    }
}
$results = foreach ($row in $ownedProcesses) {
    $children = foreach ($child in $row.children.Values) {
        [PSCustomObject]@{ pid = $child.process.Id; exit_code = $child.process.ExitCode; peak_working_set_mb = $child.peak_mb }
    }
    [PSCustomObject]@{ role = $row.role; launcher_pid = $row.process.Id; exit_code = $row.process.ExitCode;
        launcher_peak_working_set_mb = $row.peak_mb; engine_children = @($children);
        stdout = $row.stdout; stderr = $row.stderr }
}
$receipt = [PSCustomObject]@{ elapsed_seconds = $watch.Elapsed.TotalSeconds; finding = $finding;
    processes = $results; memory_samples = $memorySamples; source_hashes = $sourceHashes }
$receipt | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $artifactRoot 'receipt.json') -Encoding utf8
$receipt | ConvertTo-Json -Depth 5
if ($finding) { exit 1 }
