$ErrorActionPreference = 'Stop'
$waterOwnerUserData = Join-Path $env:APPDATA 'Godot/app_userdata/Tetherbound'
$waterEvidence = 'C:/Projects/Tetherbound/.artifacts'
function Get-WaterOwnerSaveFingerprint {
    $waterRows = @()
    foreach ($waterCategory in @('saves', 'worlds', 'characters')) {
        $waterDirectory = Join-Path $waterOwnerUserData $waterCategory
        if (Test-Path -LiteralPath $waterDirectory) {
            foreach ($waterFile in (Get-ChildItem -LiteralPath $waterDirectory -File -Recurse | Sort-Object FullName)) {
                $waterRows += [ordered]@{ path=$waterFile.FullName; length=$waterFile.Length; hash=(Get-FileHash -LiteralPath $waterFile.FullName -Algorithm SHA256).Hash }
            }
        }
    }
    return ConvertTo-Json -InputObject @($waterRows) -Depth 4 -Compress
}
$waterBefore = Get-WaterOwnerSaveFingerprint
Set-Content -LiteralPath "$waterEvidence/wave6-cloudreach-before-owner-before.json" -Value $waterBefore
$env:APPDATA = 'C:/Projects/Tetherbound/.artifacts/wave6-cloudreach-before-profile'
if (Test-Path -LiteralPath $env:APPDATA) { throw 'Refuse reused Water profile' }
if (Get-Process *godot* -ErrorAction SilentlyContinue) { throw 'Godot already active' }
New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
$ErrorActionPreference = 'Continue'
& 'C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe' --rendering-method gl_compatibility --resolution 1280x800 --path 'C:/Projects/Tetherbound' --log-file "$waterEvidence/wave6-cloudreach-before-engine.log" --script res://.artifacts/wave6_cloudreach_visual.gd -- --out=res://.artifacts/wave6-cloudreach-before --only=01-arrival,04-high-roost,05-upper --profile-realm-load *> "$waterEvidence/wave6-cloudreach-before.log"
$waterExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
$waterAfter = Get-WaterOwnerSaveFingerprint
Set-Content -LiteralPath "$waterEvidence/wave6-cloudreach-before-owner-after.json" -Value $waterAfter
if ($waterBefore -cne $waterAfter) { throw 'Owner save fingerprint changed during isolated Water diagnostic' }
Write-Output "Water terminal exit=$waterExit; owner saves fingerprint unchanged"
exit $waterExit
