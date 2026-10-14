param([switch]$RootAuthorized)
$ErrorActionPreference='Stop'
$EnvelopeTimer=[Diagnostics.Stopwatch]::StartNew()
if(-not $RootAuthorized){throw 'Root authorization required; no mutation'}
foreach($Binding in @(@{file='operation_budget.ps1';sha='BUDGET_PS_HASH'},@{file='owner_publication.ps1';sha='OWNER_PS_HASH'})){
    $Module=Join-Path $PSScriptRoot $Binding.file
    if((Get-FileHash -LiteralPath $Module -Algorithm SHA256).Hash.ToLowerInvariant() -cne $Binding.sha){throw 'Guard module changed'}
    . $Module
}
$Budget=New-OperationBudget;$Budget.Timer=$EnvelopeTimer
Assert-OperationBudget $Budget
$OwnerPath='C:/CodexTemp/tetherbound-native-owner.json'
$Thread='01a13307-fea3-7ae0-a0cf-ecd8f0e0d502'
$Base='BASE_COMMIT';$Target='c836df19793e420982bb4aa7b4a0428380126c82'
$Lock=$null;$Child=$null;$ChildStarted=$false;$OutTask=$null;$ErrTask=$null;$Failure=$null
$Transcript=Join-Path (Split-Path -Parent $PSScriptRoot) ('transition-wrapper-'+[Guid]::NewGuid().ToString('N')+'.json')
$Record=[ordered]@{status='STARTING';base=$Base;target=$Target;work_seconds=115;aggregate_seconds=120;stage_preserved_on_failure=$true}
try{
    $Lock=[IO.File]::Open('C:/CodexTemp/tetherbound-native-owner.lock',[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    Assert-OperationBudget $Budget
    $Original=Read-OwnerSnapshot $OwnerPath $Budget
    $Authorization=[bool]$Original.Owner.allow_native_launch
    Assert-OwnerIdentity $Original.Owner $Base $Thread $Authorization
    $Record.original_owner_sha256=$Original.Sha256
    $Record.original_owner_raw_base64=[Convert]::ToBase64String($Original.Raw)
    if(@(Get-CimInstance Win32_Process -OperationTimeoutSec 3|Where-Object {$_.Name -match '^(Godot.*|Blender.*)\.exe$' -or ($_.Name -eq 'git.exe' -and $_.CommandLine -like '*tetherbound-native-service*')}).Count){throw 'Native writer active'}
    Assert-OperationBudget $Budget
    $Os=Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 3
    $Mem=Get-CimInstance Win32_PerfRawData_PerfOS_Memory -OperationTimeoutSec 3
    Assert-OperationBudget $Budget
    if($null -eq $Os.FreePhysicalMemory -or $null -eq $Mem.CommitLimit -or $null -eq $Mem.CommittedBytes){throw 'Memory metrics unavailable'}
    if(([IO.DriveInfo]::new('C:\')).AvailableFreeSpace -lt 10.5GB -or ([IO.DriveInfo]::new('D:\')).AvailableFreeSpace -lt 21GB -or [long]$Os.FreePhysicalMemory*1024 -lt 2GB -or ([long]$Mem.CommitLimit-[long]$Mem.CommittedBytes) -lt 2GB){throw 'Admission resource floor failed'}
    $Helper=Join-Path $PSScriptRoot 'transition_paths.py'
    $Job=Join-Path $PSScriptRoot '../native-supervisor/native-job.json'
    if((Get-FileHash -LiteralPath $Helper -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'HELPER_HASH'){throw 'Helper changed'}
    if((Get-FileHash -LiteralPath $Job -Algorithm SHA256).Hash.ToLowerInvariant() -cne 'JOB_HASH'){throw 'Job changed'}
    Assert-OperationBudget $Budget
    $Info=[Diagnostics.ProcessStartInfo]::new()
    $Info.FileName='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    $Info.UseShellExecute=$false;$Info.CreateNoWindow=$true;$Info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
    $WorkLeft=Get-OperationRemaining $Budget
    $TotalLeft=Get-OperationRemaining $Budget -Cleanup
    foreach($Argument in @($Helper,'--root-authorized-under-lock','--work-seconds',$WorkLeft.ToString('R',[Globalization.CultureInfo]::InvariantCulture),'--total-seconds',$TotalLeft.ToString('R',[Globalization.CultureInfo]::InvariantCulture))){$Info.ArgumentList.Add($Argument)}
    $Child=[Diagnostics.Process]::new();$Child.StartInfo=$Info
    if(-not $Child.Start()){throw 'Transition helper did not start'}
    $ChildStarted=$true;$Record.helper_pid=$Child.Id;$Record.helper_created_utc=$Child.StartTime.ToUniversalTime().ToString('o')
    $OutTask=$Child.StandardOutput.ReadToEndAsync();$ErrTask=$Child.StandardError.ReadToEndAsync()
    while(-not $Child.HasExited){$null=$Child.WaitForExit((Get-OperationWaitMs $Budget 250))}
    Assert-OperationBudget $Budget
    if(-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($OutTask,$ErrTask),(Get-OperationWaitMs $Budget 2000))){throw 'Helper output drain timeout'}
    $Record.stdout=$OutTask.GetAwaiter().GetResult();$Record.stderr=$ErrTask.GetAwaiter().GetResult();$Record.exit_code=$Child.ExitCode
    Assert-OperationBudget $Budget
    if($Child.ExitCode -ne 0){throw 'Transition failed; preserve complete/intermediate stage and journal'}
    if($Record.stderr.Length){throw 'Transition helper emitted stderr; preserve stage without owner publication'}
    $Record.publication=Publish-OwnerSnapshot $OwnerPath $Original $Base $Target $Thread $Authorization $Budget
    Assert-OperationBudget $Budget
    $Record.status='SOURCE_PREPARED_NOT_ADMITTED'
}catch{
    $Failure=$_.Exception.Message;$Record.status='FAILED_PRESERVE_STAGE';$Record.failure=$Failure
}finally{
    try{
        if($ChildStarted -and -not $Child.HasExited){
            # Only the process tree created by this held Process handle is eligible.
            $Child.Kill($true)
        }
        if($Failure){$null=Start-OperationCleanup $Budget}
        if($ChildStarted -and -not $Child.HasExited){
            if(-not $Child.WaitForExit((Get-OperationWaitMs $Budget 5000 -Cleanup))){throw 'Owned transition helper cleanup timeout'}
        }
        if($OutTask -and $ErrTask){
            $WaitMs=Get-OperationWaitMs $Budget 2000 -Cleanup
            if(-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($OutTask,$ErrTask),$WaitMs)){throw 'Cleanup helper drain timeout'}
            $Record.stdout=$OutTask.GetAwaiter().GetResult();$Record.stderr=$ErrTask.GetAwaiter().GetResult()
        }
        Assert-OperationBudget $Budget -Cleanup
    }catch{$Record.cleanup_failure=$_.Exception.Message;$Record.status='FAILED_PRESERVE_STAGE';$Failure='Cleanup failed: '+$_.Exception.Message}
    $Record.elapsed_seconds=$Budget.Timer.Elapsed.TotalSeconds
    try{
        Assert-OperationBudget $Budget -Cleanup
        [IO.File]::WriteAllText($Transcript,($Record|ConvertTo-Json -Depth 24)+"`n",[Text.UTF8Encoding]::new($false))
        Assert-OperationBudget $Budget -Cleanup
    }catch{$Failure='Aggregate deadline/evidence write failed: '+$_.Exception.Message}
    if($Child -and $ChildStarted -and $Child.HasExited -and $OutTask.IsCompleted -and $ErrTask.IsCompleted){$Child.Dispose()}
    if($Lock){$Lock.Dispose()}
}
if($Failure){throw $Failure}
Assert-OperationBudget $Budget -Cleanup
'READY_NOT_ADMITTED: shared aggregate deadline, resource budget and final owner snapshot CAS passed'
