# Deliver a finished kickoff run. One script, no questions worth answering.
#
# It is written for the ROG Ally, where typing is the expensive part. Every
# decision it can make for itself, it makes: it finds the run, it finds the
# branch, it installs and authenticates the GitHub CLI if it has to, and it
# pushes. It is safe to run twice.
#
# ORDER MATTERS: the small text zip is built FIRST, before anything that can
# fail. A run that cannot be pushed still ends with something attachable on the
# Desktop, because the 2026-09-07 run proved the push is the step that breaks.

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$env:GIT_TERMINAL_PROMPT = "0"

function Say([string]$m) { Write-Host $m }
function Banner([string]$m) {
  Write-Host ""
  Write-Host ("=" * 64)
  Write-Host "  $m"
  Write-Host ("=" * 64)
}

# --- 1. find the checkout -----------------------------------------------------
$repo = $null
foreach ($c in @((Join-Path $env:LOCALAPPDATA "Tetherbound\repo"), (Get-Location).Path)) {
  if ($c -and (Test-Path (Join-Path $c ".git")) -and (Test-Path (Join-Path $c "project.godot"))) { $repo = $c; break }
}
if (-not $repo) {
  Banner "NO CHECKOUT FOUND"
  Say "Looked in $env:LOCALAPPDATA\Tetherbound\repo and the current folder."
  Say "Run this from inside your Tetherbound clone instead."
  Read-Host "Press Enter to close"; exit 1
}
Say "repo:   $repo"

$reports = Join-Path $repo "ralph\reports"
$owner = (Get-ChildItem -Path $reports -Directory -Filter "OWNER-KICKOFF-*" -ErrorAction SilentlyContinue |
          Sort-Object Name | Select-Object -Last 1)
if (-not $owner) {
  Banner "NO KICKOFF RUN FOUND"
  Say "Nothing matching OWNER-KICKOFF-* under $reports."
  Read-Host "Press Enter to close"; exit 1
}
$stamp = $owner.Name -replace "^OWNER-KICKOFF-", ""
$gate = Join-Path $reports "gate-f-run-$stamp-owner"
Say "run:    $stamp"

# --- 2. the small zip, built before anything that can fail --------------------
Banner "STEP 1 of 2  --  packing the text evidence"
$TEXT = @(".md", ".json", ".tsv", ".csv", ".jsonl", ".txt", ".log", ".sha256")
$stage = Join-Path $env:TEMP "kickoff-text-$stamp"
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue }
$n = 0
foreach ($pair in @(@($owner.FullName, "OWNER"), @($gate, "GATEF"))) {
  $root = $pair[0]; $label = $pair[1]
  if (-not (Test-Path $root)) { continue }
  # Structure is preserved on purpose: a flat copy would collide on the dozens
  # of same-named SUMMARY.json files, one per segment.
  foreach ($f in (Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $TEXT -contains $_.Extension })) {
    $rel = $f.FullName.Substring($root.Length).TrimStart("\")
    $dest = Join-Path (Join-Path $stage $label) $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Copy-Item $f.FullName $dest -Force
    $n++
  }
}
$zip = Join-Path ([Environment]::GetFolderPath("Desktop")) "kickoff-text-$stamp.zip"
if (Test-Path $zip) { Remove-Item -Force $zip -ErrorAction SilentlyContinue }
if ($n -gt 0) {
  Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -Force
  Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
  Say "packed $n files -> $zip  ($([int]((Get-Item $zip).Length / 1KB)) KB)"
} else {
  Say "no text evidence found to pack"
}

# --- 3. the branch ------------------------------------------------------------
Banner "STEP 2 of 2  --  pushing to GitHub"
$branch = (& git -C $repo branch --list "owner-run/*" --format "%(refname:short)" 2>$null | Select-Object -Last 1)
if ($branch) { $branch = $branch.Trim() }
if (-not $branch) {
  Say "No owner-run/* branch exists locally, so there is nothing to push."
  Say "The zip above is the whole deliverable. Attach it and you are done."
  Read-Host "Press Enter to close"; exit 0
}
Say "branch: $branch"

# --- 4. push, authenticating only if the push actually needs it ---------------
function Try-Push {
  $out = (& git -C $repo push -u origin $branch 2>&1)
  $out | ForEach-Object { Say "  git: $_" }
  return ($LASTEXITCODE -eq 0)
}

Say "trying the push (this is ~170 MB and will look frozen while it compresses)..."
$ok = Try-Push

if (-not $ok) {
  Banner "NEEDS A GITHUB LOGIN"
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Say "Installing the GitHub CLI..."
    & winget install --id GitHub.cli -e --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    foreach ($c in @("$env:ProgramFiles\GitHub CLI", "$env:LOCALAPPDATA\Programs\GitHub CLI")) {
      if (Test-Path (Join-Path $c "gh.exe")) { $env:Path = "$c;$env:Path" }
    }
  }
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Say "The GitHub CLI would not install. Attach the zip instead:"
    Say "  $zip"
    Read-Host "Press Enter to close"; exit 1
  }

  Say ""
  Say "A browser is about to open with a one-time code on screen."
  Say "Type the code into the browser, approve, then come back here."
  Say ""
  # --web with the host and protocol given skips every menu: the only
  # interaction left is the code and the browser approval.
  & gh auth login --hostname github.com --git-protocol https --web
  & gh auth setup-git 2>&1 | Out-Null

  Say ""
  Say "retrying the push..."
  $ok = Try-Push
  if (-not $ok) { Start-Sleep -Seconds 4; $ok = Try-Push }
}

# --- 5. say exactly what happened and exactly what to do ---------------------
if ($ok) {
  Banner "DONE  --  PUSHED"
  Say "The evidence is on GitHub as: $branch"
  Say "https://github.com/MJohnsonWellabe/Tetherbound/tree/$branch"
  Say ""
  Say "Nothing else to do. You can tell Claude the branch is up."
} else {
  Banner "PUSH DID NOT WORK  --  BUT NOTHING IS LOST"
  Say "The full evidence is still here, on this machine:"
  Say "  branch: $branch"
  Say "  zip:    Tetherbound-evidence-$stamp.zip on the Desktop"
  Say ""
  Say "ATTACH THIS ONE FILE TO THE CHAT AND YOU ARE DONE:"
  Say "  $zip"
  Say ""
  Say "It is a few hundred KB and holds the whole written verdict."
}
Say ""
Read-Host "Press Enter to close"
