# Read-only: report new gpu_queue.json entry ids on the coordinator branch, then exit so the session wakes.
$ref = "origin/ccr-99b76ce0-imf8zn:ralph/reports/COORDINATOR/gpu_queue.json"
$q0 = (git -C D:\tb-gpu-pass show $ref) -join "`n" | ConvertFrom-Json
$known = @($q0.entries | ForEach-Object { $_.id })
"watching $($known.Count) known entries"
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep 600
    git -C D:\tb-gpu-pass fetch -q origin ccr-99b76ce0-imf8zn
    $q = (git -C D:\tb-gpu-pass show $ref) -join "`n" | ConvertFrom-Json
    "check $i at $(Get-Date -Format 'HH:mm'): $(@($q.entries).Count) entries"
    $new = @($q.entries | Where-Object { $known -notcontains $_.id } | ForEach-Object { $_.id })
    if ($new.Count -gt 0) { "NEW ENTRIES: $($new -join ', ')"; "watch ended at check $i"; break }
}
