# Collect the TEXT evidence of a kickoff run into one small zip.
#
# Why this exists. A finished kickoff leaves ~170 MB on the Desktop: video
# tiles, contact sheets and every captured frame. None of that is needed to
# answer the only question that matters first -- did the run pass, and if not,
# which phase failed and why. That answer is a few hundred KB of .md, .json,
# .tsv, .csv and .log, which is small enough to attach to a chat or drag into
# a browser.
#
# It reads only. Nothing is moved, deleted or committed.
#
# Usage (or just double-click COLLECT_EVIDENCE.cmd):
#   collect_evidence.ps1                 the newest run
#   collect_evidence.ps1 -Stamp 2026...  a named run

param([string]$Stamp = "")

$ErrorActionPreference = "Continue"
$State = Join-Path $env:LOCALAPPDATA "Tetherbound"
$Reports = Join-Path $State "repo\ralph\reports"

if (-not (Test-Path $Reports)) {
  Write-Host "No kickoff checkout at $Reports."
  Write-Host "If you ran KICKOFF from your own clone, run this from there instead:"
  Write-Host "  powershell -File tools\owner\collect_evidence.ps1"
  exit 1
}

# Newest OWNER-KICKOFF-* unless a stamp was named.
if ($Stamp) {
  $owner = Join-Path $Reports "OWNER-KICKOFF-$Stamp"
} else {
  $owner = (Get-ChildItem -Path $Reports -Directory -Filter "OWNER-KICKOFF-*" -ErrorAction SilentlyContinue |
            Sort-Object Name | Select-Object -Last 1)
  if ($owner) { $owner = $owner.FullName }
}
if (-not $owner -or -not (Test-Path $owner)) { Write-Host "No OWNER-KICKOFF-* run found under $Reports."; exit 1 }

$stampName = (Split-Path $owner -Leaf) -replace "^OWNER-KICKOFF-", ""
$gate = Join-Path $Reports "gate-f-run-$stampName-owner"
Write-Host "run:  $stampName"

# The written record only. Frames, sheets and video are deliberately excluded:
# they are the bulk, and they are already in the big Desktop zip.
$TEXT = @(".md", ".json", ".tsv", ".csv", ".jsonl", ".txt", ".log", ".sha256")
$files = @()
$files += Get-ChildItem -Path $owner -Recurse -File -ErrorAction SilentlyContinue |
          Where-Object { $TEXT -contains $_.Extension }
if (Test-Path $gate) {
  Write-Host "gate: $(Split-Path $gate -Leaf)"
  $files += Get-ChildItem -Path $gate -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $TEXT -contains $_.Extension }
} else {
  Write-Host "gate: none (no chain run for this stamp)"
}

if ($files.Count -eq 0) { Write-Host "Found no text evidence to collect."; exit 1 }

# Staged into a folder first so the zip keeps OWNER/ and GATEF/ apart; a flat
# Compress-Archive of many same-named SUMMARY.json files would collide.
$stage = Join-Path $env:TEMP "kickoff-text-$stampName"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
foreach ($f in $files) {
  $root = if ($f.FullName.StartsWith($owner)) { $owner } else { $gate }
  $sub = if ($f.FullName.StartsWith($owner)) { "OWNER" } else { "GATEF" }
  $rel = $f.FullName.Substring($root.Length).TrimStart("\")
  $dest = Join-Path (Join-Path $stage $sub) $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
  Copy-Item $f.FullName $dest -Force
}

$out = Join-Path ([Environment]::GetFolderPath("Desktop")) "kickoff-text-$stampName.zip"
if (Test-Path $out) { Remove-Item -Force $out }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $out -Force
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue

$kb = [int]((Get-Item $out).Length / 1KB)
Write-Host ""
Write-Host "WROTE: $out"
Write-Host "       $($files.Count) files, $kb KB"
Write-Host ""
Write-Host "That zip is small enough to attach to a chat message or drag into a browser."
Write-Host "RUN_SUMMARY.md inside it is the whole verdict: the phase table and the chain log."
