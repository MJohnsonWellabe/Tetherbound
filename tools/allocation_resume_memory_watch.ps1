param(
    [Parameter(Mandatory=$true)][int]$TargetProcessId,
    [Parameter(Mandatory=$true)][string]$Output,
    [int]$MaximumSeconds = 600
)
$ErrorActionPreference = 'Stop'
# Observe the real Godot child, not Godot's tiny console wrapper. No mutations.
$deadline = (Get-Date).AddSeconds($MaximumSeconds)
'utc,pid,private_bytes,peak_paged_bytes,working_set_bytes,peak_working_set_bytes,system_commit_bytes,system_commit_limit_bytes,process_count' | Set-Content -LiteralPath $Output
while ((Get-Date) -lt $deadline) {
    $target = Get-Process -Id $TargetProcessId -ErrorAction SilentlyContinue
    if ($null -eq $target) { break }
    $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
    $count = (Get-Process | Measure-Object).Count
    '{0},{1},{2},{3},{4},{5},{6},{7},{8}' -f [DateTime]::UtcNow.ToString('o'), $target.Id, $target.PrivateMemorySize64, $target.PeakPagedMemorySize64, $target.WorkingSet64, $target.PeakWorkingSet64, $memory.CommittedBytes, $memory.CommitLimit, $count | Add-Content -LiteralPath $Output
    Start-Sleep -Seconds 2
}
