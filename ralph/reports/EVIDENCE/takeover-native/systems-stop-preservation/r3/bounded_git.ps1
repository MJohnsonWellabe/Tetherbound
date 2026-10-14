function Invoke-Git([string[]]$GitArgs) {
    Assert-OperationBudget $script:SourceBudget
    $Info=[Diagnostics.ProcessStartInfo]::new()
    $Info.FileName=$Git;$Info.UseShellExecute=$false;$Info.CreateNoWindow=$true;$Info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $Info.RedirectStandardOutput=$true;$Info.RedirectStandardError=$true
    foreach($Item in @('-C',$Stage,'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false','-c','core.preloadindex=false','-c','core.quotepath=false')+$GitArgs){$Info.ArgumentList.Add($Item)}
    $Info.Environment['GIT_NO_LAZY_FETCH']='1';$Info.Environment['GIT_OPTIONAL_LOCKS']='0';$Info.Environment['GIT_TERMINAL_PROMPT']='0'
    $GitProcess=[Diagnostics.Process]::new();$GitProcess.StartInfo=$Info
    $OutputTask=$null;$ErrorTask=$null;$GitStarted=$false;$GitFinished=$false
    try{
        Assert-OperationBudget $script:SourceBudget
        if(-not $GitProcess.Start()){throw 'Pinned Git failed to start'}
        $GitStarted=$true
        $OutputTask=$GitProcess.StandardOutput.ReadToEndAsync();$ErrorTask=$GitProcess.StandardError.ReadToEndAsync()
        while(-not $GitProcess.HasExited){
            $null=Assert-Resources
            $null=$GitProcess.WaitForExit((Get-OperationWaitMs $script:SourceBudget 250))
        }
        Assert-OperationBudget $script:SourceBudget
        Wait-OutputDrain $OutputTask $ErrorTask (Get-OperationWaitMs $script:SourceBudget 2000)
        Assert-OperationBudget $script:SourceBudget
        if($GitProcess.ExitCode -ne 0){throw ('Pinned Git verification failed: '+$ErrorTask.Result)}
        $GitFinished=$true
        return @($OutputTask.Result -split '\r?\n'|Where-Object {$_ -ne ''})
    }finally{
        if($GitStarted -and -not $GitProcess.HasExited){$GitProcess.Kill($true)}
        if(-not $GitFinished){
            $null=Start-OperationCleanup $script:SourceBudget
            if($GitStarted -and -not $GitProcess.HasExited -and -not $GitProcess.WaitForExit((Get-OperationWaitMs $script:SourceBudget 5000 -Cleanup))){throw 'Owned Git helper did not stop within aggregate cleanup'}
            if($OutputTask -and $ErrorTask){Wait-OutputDrain $OutputTask $ErrorTask (Get-OperationWaitMs $script:SourceBudget 2000 -Cleanup)}
            Assert-OperationBudget $script:SourceBudget -Cleanup
        }
        if($OutputTask -and $OutputTask.IsCompleted -and $ErrorTask -and $ErrorTask.IsCompleted){$GitProcess.Dispose()}
    }
}
