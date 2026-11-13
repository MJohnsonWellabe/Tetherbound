param(
    [Parameter(Mandatory)] [ValidateSet("Low","Medium","High")] [string] $Preset,
    [Parameter(Mandatory)] [string] $Script,      # res:// path or absolute local wrapper
    [Parameter(Mandatory)] [string] $OutDir,      # run folder; frames go to <OutDir>\frames
    [string[]] $UserArgs = @(),                   # tool args; "{FRAMES}" is replaced by the frame dir
    [switch] $PositionalOut,                      # tool takes the frame dir as its first positional arg
    [string] $Resolution = "1280x720",
    [string] $ProjectPath = "D:\tb-gpu-pass",       # Godot project (checkout or worktree) to render
    [string[]] $GodotArgs = @()                     # extra engine args before --script, e.g. "--fixed-fps","20"
)
# Local GPU-pass generic runner (never committed). One Godot process; real GPU.
$env:APPDATA = "D:\tb-gpu-runs\appdata-$Preset"
$godot = "C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe"
New-Item -ItemType Directory -Force $OutDir | Out-Null
$frameDir = (Join-Path $OutDir "frames") -replace '\\', '/'
$ua = @($UserArgs | ForEach-Object { $_.Replace("{FRAMES}", $frameDir) })
if ($PositionalOut) { $ua = @($frameDir) + $ua }
$rm = if ($Preset -eq "Low") { @("--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3") } else { @("--rendering-method", "forward_plus", "--rendering-driver", "vulkan") }
$a = @("--path", $ProjectPath) + $rm + @("--resolution", $Resolution) + $GodotArgs + @("--script", $Script, "--") + $ua
"godot " + ($a -join " ") | Set-Content -Encoding utf8 (Join-Path $OutDir "_command.txt")
$t = Get-Date
$argLine = ($a | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
$proc = Start-Process -FilePath $godot -ArgumentList $argLine -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $OutDir "_run.log") -RedirectStandardError (Join-Path $OutDir "_run.err.log")
$null = $proc.Handle  # cache the handle so ExitCode is readable in PS 5.1
$limit = if ($env:TB_RUN_TIMEOUT_MIN) { [int]$env:TB_RUN_TIMEOUT_MIN } else { 45 }
# Optional stall watchdog (TB_STALL_MIN): kill when neither log has grown for that many minutes. 31 Oct: Tidewake commands at High
# sometimes hang right after "CATALOGUE BOOT water attached" and only the 30-min limit caught them; a retry then passes in ~1 min.
$stallFile = "D:\tb-gpu-runs\stall_min.txt"   # read per call, so a running queue picks up a change
$stall = if ($env:TB_STALL_MIN) { [double]$env:TB_STALL_MIN } elseif (Test-Path $stallFile) { [double](Get-Content $stallFile -Raw).Trim() } else { 0 }
$logs = @((Join-Path $OutDir "_run.log"), (Join-Path $OutDir "_run.err.log"))
$deadline = (Get-Date).AddMinutes($limit); $lastSize = -1; $lastGrow = Get-Date; $why = ""
while (-not $proc.WaitForExit(15000)) {
    if ((Get-Date) -gt $deadline) { $why = "killed after $limit min"; break }
    if ($stall -gt 0) {
        $size = ($logs | ForEach-Object { if (Test-Path $_) { (Get-Item $_).Length } else { 0 } } | Measure-Object -Sum).Sum
        if ($size -ne $lastSize) { $lastSize = $size; $lastGrow = Get-Date }
        elseif (((Get-Date) - $lastGrow).TotalMinutes -ge $stall) { $why = "killed: logs unchanged for $stall min (stall)"; break }
    }
}
if ($why) {
    Get-CimInstance Win32_Process -Filter "ParentProcessId=$($proc.Id)" | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    $null = $proc.WaitForExit(15000); Start-Sleep 3   # let Windows release the run folder before the caller moves it
    # The killed process can still hold _run.log open, so record the watchdog in its own file.
    "WATCHDOG: $why" | Set-Content -Encoding ascii (Join-Path $OutDir "_watchdog.txt")
}
$LASTEXITCODE = $proc.ExitCode
$code = $LASTEXITCODE
$frames = (Get-ChildItem $frameDir -Recurse -Filter *.png -ErrorAction SilentlyContinue | Measure-Object).Count
"exit=$code frames=$frames sec=$([int]((Get-Date)-$t).TotalSeconds) out=$OutDir"
