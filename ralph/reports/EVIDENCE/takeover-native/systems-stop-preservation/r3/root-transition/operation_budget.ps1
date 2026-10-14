function New-OperationBudget {
    return [pscustomobject]@{Timer=[Diagnostics.Stopwatch]::StartNew();WorkSeconds=115.0;TotalSeconds=120.0;CleanupDeadline=$null}
}
function Get-OperationRemaining($Budget,[switch]$Cleanup) {
    if($null -eq $Budget){throw 'Shared operation budget missing'}
    $Deadline=$Budget.WorkSeconds
    if($Cleanup){$Deadline=$Budget.TotalSeconds;if($null -ne $Budget.CleanupDeadline){$Deadline=[Math]::Min($Deadline,$Budget.CleanupDeadline)}}
    $Remaining=$Deadline-$Budget.Timer.Elapsed.TotalSeconds
    if($Remaining -le 0){throw 'Aggregate operation deadline exceeded'}
    return [double]$Remaining
}
function Start-OperationCleanup($Budget) {
    if($null -eq $Budget.CleanupDeadline){$Budget.CleanupDeadline=[Math]::Min($Budget.TotalSeconds,$Budget.Timer.Elapsed.TotalSeconds+5.0)}
    return Get-OperationRemaining $Budget -Cleanup
}
function Assert-OperationBudget($Budget,[switch]$Cleanup) {$null=Get-OperationRemaining $Budget -Cleanup:$Cleanup}
function Get-OperationWaitMs($Budget,[int]$Ceiling=1000,[switch]$Cleanup) {
    $RemainingMs=[int][Math]::Floor((Get-OperationRemaining $Budget -Cleanup:$Cleanup)*1000)
    if($RemainingMs -le 0){throw 'Aggregate operation has no remaining wait time'}
    return [Math]::Min($Ceiling,$RemainingMs)
}
