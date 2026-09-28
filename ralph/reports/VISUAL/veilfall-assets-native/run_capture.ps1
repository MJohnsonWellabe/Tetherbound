param([Parameter(Mandatory=$true)][string]$Variant)
$ErrorActionPreference = 'Stop'
$project = 'D:/tetherbound/asset-validation'
$evidence = "$project/ralph/reports/VISUAL/veilfall-assets-native"
$outDir = "$evidence/$Variant"
New-Item -ItemType Directory -Force $outDir | Out-Null
$engine = 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64.exe'
$arguments = @('--path', $project, '--rendering-driver', 'opengl3', '--resolution', '1920x1080', '--script', 'res://tools/capture_veilfall_interior.gd', '--', "--out=res://ralph/reports/VISUAL/veilfall-assets-native/$Variant")
$captureProcess = Start-Process -FilePath $engine -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$outDir/stdout.log" -RedirectStandardError "$outDir/stderr.log"
Write-Output "Capture PID $($captureProcess.Id)"
$resized = $false
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 500
    $result = & 'C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'D:/tetherbound/gpu-run-service/native_window.py' $captureProcess.Id
    if ($LASTEXITCODE -eq 0) {
        $result | Set-Content "$outDir/native-window.json"
        $resized = $true
        break
    }
    if ($captureProcess.HasExited) { break }
}
if (-not $resized) { throw 'Native viewport resize failed' }
$captureProcess.WaitForExit()
Write-Output "Capture exit $($captureProcess.ExitCode)"
exit $captureProcess.ExitCode
