param([switch]$RootAuthorized)
$ErrorActionPreference='Stop'
if(-not $RootAuthorized){throw 'Explicit root lease authorization required; preparation only'}
# Python holds the actual exclusive root-owner lock through preservation,
# source transition and final raw lease/source CAS, even if called directly.
if(@(Get-CimInstance Win32_Process|Where-Object {$_.Name -like '*godot*' -or ($_.Name -eq 'git.exe' -and $_.CommandLine -like '*tetherbound-native-service*')}).Count){throw 'Native stage process exists'}
& 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' (Join-Path $PSScriptRoot 'swap_stage.py') --root-authorized
if($LASTEXITCODE){throw 'Stage swap failed; preserve verified backup and intermediate state for diagnosis'}
& 'C:\Users\mattj\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe' -NoProfile -File (Join-Path $PSScriptRoot 'shared/run_validation.ps1') -CpuStagePreflightFixture
if($LASTEXITCODE){throw 'CPU stage preflight failed'}
