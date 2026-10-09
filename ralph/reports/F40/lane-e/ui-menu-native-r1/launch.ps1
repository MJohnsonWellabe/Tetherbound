param([ValidateSet('Import','Capture')][string]$Mode='Import')
$ErrorActionPreference='Stop'
$taskFrozen='D:/CodexTemp/tetherbound-native/d-e2d54b40aa'
$taskPacket='C:/CodexTemp/tetherbound-proof/native-e-9a359dfd5c-ui-menu-r1'
$taskSource='9a359dfd5c545aa471f9dbe317ef063e0408dc1d'
$taskRecipe=Get-Content -LiteralPath ($taskPacket+'/original-recipe.json') -Raw|ConvertFrom-Json
$taskApproval=@($taskRecipe.native_command_binding_reviews)[1]
if($taskApproval.source -ne $taskSource -or $taskApproval.verdict -ne 'APPROVE applicability only'){throw 'Exact original updated native applicability absent'}
if([IO.DriveInfo]::new('D:').AvailableFreeSpace -lt 536870912 -or [IO.DriveInfo]::new('C:').AvailableFreeSpace -lt 2147483648){throw 'Confirmationcapacitychanged'}
if((git -C $taskFrozen rev-parse HEAD).Trim() -ne $taskSource){throw 'Pin mismatch'}
function Write-TaskSource([string]$Phase){
 git -C $taskFrozen diff --quiet; if($LASTEXITCODE){throw 'Tracked source dirty'}
 git -C $taskFrozen diff --cached --quiet; if($LASTEXITCODE){throw 'Index dirty'}
 @{source=$taskSource;head_tree=(git -C $taskFrozen rev-parse 'HEAD^{tree}').Trim();index_tree=(git -C $taskFrozen write-tree).Trim();tracked_clean=$true;status=@(git -C $taskFrozen status --porcelain --untracked-files=normal);checked_utc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath ($taskPacket+'/source-'+$Phase+'-'+$Mode.ToLower()+'.json') -Encoding utf8
}
if(Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue){throw 'Engine running'}
$taskSteam=Get-ItemProperty -LiteralPath 'HKCU:/Software/Valve/Steam' -ErrorAction SilentlyContinue
if($taskSteam.RunningAppID -gt 0){throw 'Owner game running'}
$taskPrefix=$Mode.ToLower()
if($Mode -eq 'Import'){
 $taskArgs=@('--headless','--path',$taskFrozen,'--editor','--import','--quit');$taskDeadline=15
}else{
 $taskImport=Get-Content -LiteralPath ($taskPacket+'/import-terminal.json') -Raw|ConvertFrom-Json
 if($taskImport.exit_code -ne 0 -or $taskImport.reason -ne 'process_exit' -or $taskImport.source -ne $taskSource){throw 'Exact import required'}
 $taskOutput=$taskFrozen+'/'+(@($taskApproval.argv|Where-Object{$_ -like '--output=res://*'})[0].Substring('--output=res://'.Length))
 if(Test-Path -LiteralPath $taskOutput){throw 'Output exists'}
 $taskArgs=@($taskApproval.argv|ForEach-Object{if($_ -eq '<ROOT-scheduled D/E exact checkout>'){$taskFrozen}else{$_}});$taskDeadline=45
}
$taskUser=$taskPacket+'/'+$taskPrefix+'-home'
if(Test-Path -LiteralPath $taskUser){throw 'Fresh home required'}
$taskRoaming=$taskUser+'/AppData/Roaming';$taskLocal=$taskUser+'/AppData/Local'
New-Item -ItemType Directory -Path $taskRoaming,$taskLocal -Force|Out-Null
Write-TaskSource 'before'
$taskStarted=[DateTime]::UtcNow
$taskProc=Start-Process -FilePath 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' -ArgumentList @($taskArgs | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }) -WorkingDirectory $taskFrozen -WindowStyle Hidden -Environment @{APPDATA=$taskRoaming;LOCALAPPDATA=$taskLocal;USERPROFILE=$taskUser} -RedirectStandardOutput ($taskPacket+'/'+$taskPrefix+'.stdout.log') -RedirectStandardError ($taskPacket+'/'+$taskPrefix+'.stderr.log') -PassThru
$taskHandle=$taskProc.Handle
@{source=$taskSource;mode=$Mode;pid=$taskProc.Id;started_utc=$taskStarted.ToString('o');args=$taskArgs;fresh_user_directory=$taskUser;deadline_minutes=$taskDeadline}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath ($taskPacket+'/'+$taskPrefix+'-start.json') -Encoding utf8
$taskReason='process_exit'
while(-not $taskProc.HasExited){
 $taskSteam=Get-ItemProperty -LiteralPath 'HKCU:/Software/Valve/Steam' -ErrorAction SilentlyContinue
 if($taskSteam.RunningAppID -gt 0){$taskReason='owner_game_started';taskkill /PID $taskProc.Id /T /F|Out-Null;break}
 if(([DateTime]::UtcNow-$taskStarted).TotalMinutes -gt $taskDeadline){$taskReason='outer_deadline';taskkill /PID $taskProc.Id /T /F|Out-Null;break}
 if(Select-String -LiteralPath ($taskPacket+'/'+$taskPrefix+'.stderr.log') -Pattern '^SCRIPT ERROR:' -Quiet){$taskReason='fatal_script_error';taskkill /PID $taskProc.Id /T /F|Out-Null;break}
 Start-Sleep -Seconds 3;$taskProc.Refresh()
}
$taskProc.WaitForExit()
@{source=$taskSource;mode=$Mode;pid=$taskProc.Id;exit_code=$taskProc.ExitCode;reason=$taskReason;ended_utc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content -LiteralPath ($taskPacket+'/'+$taskPrefix+'-terminal.json') -Encoding utf8
Get-Content -LiteralPath ($taskPacket+'/'+$taskPrefix+'-terminal.json')
Write-TaskSource 'after'
exit $taskProc.ExitCode




