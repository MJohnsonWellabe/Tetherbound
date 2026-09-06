# Tetherbound multiplayer session launcher. Started by MULTIPLAYER_KICKOFF.cmd.
#
# What it is for: getting a real multiplayer session in front of a human with
# one double-click, because everything below it is proven by two headless
# processes in CI and none of that tells you whether playing together is any
# good. See docs/acceptance/MULTIPLAYER_ACCEPTANCE.md -- the owner column of
# that table is the half no smoke can supply.
#
# What it does NOT do, deliberately: it does not build, bake, render, judge or
# push anything. tools/owner/KICKOFF.cmd is the evidence run; this is the play
# session. Keeping them apart means this one starts in seconds.
#
# The four-windows-on-one-PC default is a convenience, not a test of the
# network: those peers share a CPU and talk over loopback. The configuration
# that matters for the acceptance table is a host on the ROG Ally joined from a
# PC over a real LAN (-HostOnly here, -Join there).

param(
  # How many client windows to launch beside the host on THIS machine.
  # The session cap is four players total (data/config/multiplayer.json:
  # session.max_peers), so 3 is the maximum that can connect.
  [int]$Clients = 3,
  # Launch only the host and print the address other machines should join.
  [switch]$HostOnly,
  # Join a host running on another machine: -Join 192.168.1.42 (or with :port).
  [string]$Join = "",
  # Overridden only if the default port is already taken on this machine.
  [int]$Port = 0,
  # Where the game is. Defaults to the repo this script sits in.
  [string]$ProjectPath = "",
  [string]$Res = "1280x800"
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjectPath) { $ProjectPath = (Resolve-Path (Join-Path $Here "..\..")).Path }
$Stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$RunDir = Join-Path $env:LOCALAPPDATA "Tetherbound\mp-runs\$Stamp"
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$Log = Join-Path $RunDir "kickoff.log"

function Say([string]$m) {
  $line = "[{0}] {1}" -f (Get-Date).ToUniversalTime().ToString("HH:mm:ss"), $m
  Write-Host $line
  Add-Content -Path $Log -Value $line
}

Say "run directory: $RunDir"
Say "project: $ProjectPath"

# --- the port, read from the game's own config rather than hardcoded ----------
# One source of truth: if the owner changes the port in multiplayer.json, this
# script follows rather than silently disagreeing with the game.
if ($Port -le 0) {
  $Port = 27015
  $cfg = Join-Path $ProjectPath "data\config\multiplayer.json"
  if (Test-Path $cfg) {
    try {
      $json = Get-Content $cfg -Raw | ConvertFrom-Json
      if ($json.session.port) { $Port = [int]$json.session.port }
    } catch { Say "could not read $cfg, using default port $Port" }
  }
}
Say "port: $Port"

# --- Godot ---------------------------------------------------------------------
# The same pinned version and the same install location tools/owner/kickoff.ps1
# uses, so an owner who has already run the evidence kit does not download it
# twice.
$GodotVersion = "4.7-stable"
$ToolsDir = Join-Path $env:LOCALAPPDATA "Tetherbound\tools"
$Godot = Get-ChildItem -Path $ToolsDir -Filter "Godot_v$GodotVersion*.exe" -Recurse -ErrorAction SilentlyContinue |
         Select-Object -First 1 -ExpandProperty FullName
if (-not $Godot) {
  $Godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
}
if (-not $Godot) {
  Say "Godot $GodotVersion was not found."
  Say "Run tools\owner\KICKOFF.cmd once (it installs the pinned Godot), or put godot.exe on PATH."
  exit 3
}
Say "godot: $Godot"

# --- launching ------------------------------------------------------------------
# Every window is the ordinary game. The flags route through exactly the same
# Session.host()/Session.join() the title screen uses (lane 2.B) -- there is no
# second code path for the kit, which is why the kit cannot pass while the game
# fails.
function Start-Peer([string]$label, [string[]]$extra) {
  $peerLog = Join-Path $RunDir "$label.log"
  $args = @("--path", $ProjectPath, "--resolution", $Res) + $extra
  Say "launching $label : godot $($args -join ' ')"
  $p = Start-Process -FilePath $Godot -ArgumentList $args -PassThru `
       -RedirectStandardOutput $peerLog -RedirectStandardError "$peerLog.err"
  Say "  $label pid=$($p.Id) log=$peerLog"
  return $p
}

$started = @()

if ($Join) {
  $target = $Join
  if ($target -notmatch ":") { $target = "${target}:${Port}" }
  Say "joining $target"
  $started += Start-Peer "client" @("--mp-join", $target)
} else {
  Say "hosting on port $Port"
  $started += Start-Peer "host" @("--mp-host", "$Port", "--mp-fps-json", (Join-Path $RunDir "fps.json"))

  # Addresses other machines should use. Printed rather than guessed at: a
  # machine usually has several and only the owner knows which network the
  # other player is on.
  Say "other machines join one of these addresses:"
  foreach ($ip in (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                   Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" })) {
    Say "    $($ip.IPAddress):$Port    (on $($ip.InterfaceAlias))"
  }

  if (-not $HostOnly) {
    $cap = [Math]::Min($Clients, 3)
    if ($cap -lt $Clients) { Say "capped clients at $cap -- the session holds four players in total" }
    # The host needs to be listening before anyone dials it. Five seconds is a
    # guess that has been generous in practice; a client that arrives early
    # simply fails to connect and can be relaunched, which is why this is a
    # sleep and not a handshake.
    Say "waiting 5s for the host to bind before dialling it"
    Start-Sleep -Seconds 5
    for ($i = 1; $i -le $cap; $i++) {
      $started += Start-Peer "client$i" @("--mp-join", "127.0.0.1:$Port")
      Start-Sleep -Seconds 2
    }
  }
}

Say ""
Say "$($started.Count) window(s) launched. Play. Close the windows when you are done."
Say ""
Say "When you have finished, fill in the owner column of"
Say "  docs\acceptance\MULTIPLAYER_ACCEPTANCE.md"
Say "The rows that need a person are the ones about how it FEELS -- whether a"
Say "shared fight is legible, whether a friend's creature reads as theirs, and"
Say "the frame time on the Ally with someone else connected. No smoke can"
Say "answer those, which is why they have their own column."

foreach ($p in $started) { $p.WaitForExit() }

$fps = Join-Path $RunDir "fps.json"
if (Test-Path $fps) {
  Say "host frame-time record: $fps"
} else {
  Say "no fps.json was written -- if the host window ran, --mp-fps-json is not implemented yet;"
  Say "note the frame time by hand in the acceptance table instead."
}
Say "logs: $RunDir"
exit 0
