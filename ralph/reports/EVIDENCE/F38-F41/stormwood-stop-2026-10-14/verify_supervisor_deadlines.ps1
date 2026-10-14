$ErrorActionPreference='Stop'
$Packet=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'packet.json') -Raw|ConvertFrom-Json
$Positive=0;$Negative=0;$Supervisors=0
foreach($Entry in $Packet.jobs){
    $Tokens=$null;$Errors=$null
    $Ast=[Management.Automation.Language.Parser]::ParseFile($Entry.supervisor,[ref]$Tokens,[ref]$Errors)
    if($Errors.Count){throw ($Errors.Message -join ';')}
    foreach($Name in @('Wait-BoundedTasks','Assert-StepDeadline','Complete-LogDrain')){
        $Function=$Ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name},$true)
        if(-not $Function){throw "Missing bounded function $Name"}
        . ([scriptblock]::Create($Function.Extent.Text))
    }
    $Text=Get-Content -LiteralPath $Entry.supervisor -Raw
    if($Text -match '\.GetAwaiter\(\)|\.WaitForExit\(\)|\$(OutStream|ErrStream|script:OutStream|script:ErrStream)\.Dispose\(\)'){throw 'Unbounded completion or synchronous stream cleanup remains'}
    $RunStep=$Ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Run-Step'},$true).Extent.Text
    if([regex]::Matches($RunStep,'Assert-StepDeadline \$Timer.Elapsed.TotalSeconds').Count -ne 3){throw 'Three terminal deadline checks required'}
    if($RunStep.IndexOf('Complete-LogDrain $DrainBudget') -lt $RunStep.IndexOf('Assert-StepDeadline')){throw 'Pre-drain terminal gate missing'}
    if($RunStep.LastIndexOf('Assert-StepDeadline') -gt $RunStep.IndexOf("status='PASSED'")){throw 'PASS precedes final deadline gate'}
    if($Text -notmatch 'Complete-LogDrain 5000 -Cancel' -or $Text -notmatch 'CopyToAsync\(\$OutStream,81920,\$script:LogCancellation.Token\)' -or $Text -notmatch 'CopyToAsync\(\$ErrStream,81920,\$script:LogCancellation.Token\)'){throw 'Bounded cancellable cleanup missing'}
    Assert-StepDeadline 599.999 600;Assert-StepDeadline 359.999 360;Assert-StepDeadline 89.999 90;Assert-StepDeadline 119.999 120;$Positive+=4
    foreach($Case in @(@(600.0,600.0),@(600.001,600.0),@(360.0,360.0),@(360.001,360.0),@(90.0,90.0),@(120.0,120.0),@([double]::NaN,360.0),@([double]::PositiveInfinity,360.0),@(-1.0,360.0),@(0.0,0.0))){
        $Rejected=$false;try{Assert-StepDeadline $Case[0] $Case[1]}catch{$Rejected=$true}
        if(-not $Rejected){throw 'Invalid terminal time accepted'};$Negative++
    }
    Wait-BoundedTasks @([Threading.Tasks.Task]::CompletedTask) 0;$Positive++
    $Pending=[Threading.Tasks.TaskCompletionSource[bool]]::new()
    $Clock=[Diagnostics.Stopwatch]::StartNew();$Rejected=$false
    try{Wait-BoundedTasks @($Pending.Task) 30}catch{$Rejected=$true}
    if(-not $Rejected -or $Clock.Elapsed.TotalSeconds -gt 2){throw 'Pending task did not reject within bounded time'};$Negative++
    $Pending.SetResult($true)
    $Fault=[Threading.Tasks.TaskCompletionSource[bool]]::new();$Fault.SetException([InvalidOperationException]::new('fixture fault'))
    $Cancelled=[Threading.Tasks.TaskCompletionSource[bool]]::new();$Cancelled.SetCanceled()
    foreach($Task in @($Fault.Task,$Cancelled.Task)){
        $Rejected=$false;try{Wait-BoundedTasks @($Task) 30}catch{$Rejected=$true}
        if(-not $Rejected){throw 'Failed asynchronous task accepted'};$Negative++
    }
    $script:OutTask=[Threading.Tasks.Task]::CompletedTask;$script:ErrTask=[Threading.Tasks.Task]::CompletedTask
    $script:OutStream=[IO.MemoryStream]::new();$script:ErrStream=[IO.MemoryStream]::new();$script:LogCancellation=[Threading.CancellationTokenSource]::new()
    Complete-LogDrain 100
    if($script:OutStream -or $script:ErrStream -or $script:OutTask -or $script:ErrTask -or $script:LogCancellation){throw 'Completed drain retained state'};$Positive++
    # Simulate EOF withheld after an exited child. Both normal and cleanup paths
    # must return within their single budget even if cancellation is ignored.
    foreach($Cleanup in @($false,$true)){
        $Pending=[Threading.Tasks.TaskCompletionSource[bool]]::new()
        $script:OutTask=$Pending.Task;$script:ErrTask=[Threading.Tasks.Task]::CompletedTask
        $script:OutStream=[IO.MemoryStream]::new();$script:ErrStream=[IO.MemoryStream]::new();$script:LogCancellation=[Threading.CancellationTokenSource]::new()
        $Clock=[Diagnostics.Stopwatch]::StartNew();$Rejected=$false
        try{Complete-LogDrain 30 -Cancel:$Cleanup}catch{$Rejected=$true}
        if(-not $Rejected -or $Clock.Elapsed.TotalSeconds -gt 2){throw 'Incomplete log copy was not bounded'}
        if($Cleanup -and -not $script:LogCancellation.IsCancellationRequested){throw 'Cleanup did not request cancellation'}
        $Negative++;$Pending.SetResult($true);Complete-LogDrain 100 -Cancel
    }
    # Real asynchronous pipe-to-file copy with EOF withheld; no child process.
    $PipeName='stormwood-cpu-'+[Guid]::NewGuid().ToString('N')
    $Server=[IO.Pipes.NamedPipeServerStream]::new($PipeName,[IO.Pipes.PipeDirection]::InOut,1,[IO.Pipes.PipeTransmissionMode]::Byte,[IO.Pipes.PipeOptions]::Asynchronous)
    $Client=[IO.Pipes.NamedPipeClientStream]::new('.',$PipeName,[IO.Pipes.PipeDirection]::InOut,[IO.Pipes.PipeOptions]::Asynchronous)
    $Temp=Join-Path $PSScriptRoot ('cpu-drain-'+$Entry.kind+'.bin')
    try {
        $Connect=$Server.WaitForConnectionAsync();$Client.Connect(1000);Wait-BoundedTasks @($Connect) 1000
        $script:OutStream=[IO.File]::Open($Temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $script:ErrStream=[IO.MemoryStream]::new();$script:LogCancellation=[Threading.CancellationTokenSource]::new()
        $script:OutTask=$Server.CopyToAsync($script:OutStream,81920,$script:LogCancellation.Token)
        $script:ErrTask=[Threading.Tasks.Task]::CompletedTask
        $Clock=[Diagnostics.Stopwatch]::StartNew();$Rejected=$false
        try { Complete-LogDrain 250 -Cancel } catch { $Rejected=$true }
        if(-not $Rejected -or $Clock.Elapsed.TotalSeconds -gt 2){throw 'Real withheld-EOF copy cancellation failed its bounded cleanup'}
        if($script:OutTask -or $script:OutStream){throw 'Cancelled real pipe copy retained unfinished state'}
        $Negative++
    } finally {
        $Client.Dispose();$Server.Dispose()
        if(Test-Path -LiteralPath $Temp){Remove-Item -LiteralPath $Temp}
    }
    $Supervisors++
}
$Result=@{status='PASS_CPU_ONLY';source=$Packet.source;supervisors=$Supervisors;positive_cases=$Positive;negative_cases=$Negative;normal_and_cleanup_pending_copy_rejected=$true;exact_terminal_cap_rejected=$true;native_stage_written=$false;engine_processes_launched=0}
$Result|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'cpu-deadline-verification.json') -Encoding utf8
$Result|ConvertTo-Json -Depth 8
