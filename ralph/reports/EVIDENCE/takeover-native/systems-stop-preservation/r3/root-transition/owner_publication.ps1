function Read-OwnerSnapshot([string]$Path,$Budget) {
    Assert-OperationBudget $Budget
    $Raw=[IO.File]::ReadAllBytes($Path)
    $Hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Raw)).ToLowerInvariant()
    $Owner=[Text.UTF8Encoding]::new($false,$true).GetString($Raw).TrimStart([char]0xfeff)|ConvertFrom-Json
    Assert-OperationBudget $Budget
    return [pscustomobject]@{Raw=$Raw;Sha256=$Hash;Owner=$Owner}
}
function Assert-OwnerIdentity($Owner,[string]$Base,[string]$Thread,[bool]$Authorization) {
    foreach($Name in @('source','thread','reserved','allow_native_launch','active_process_id','active_session_id','run_id','processes')){
        if($Name -cnotin $Owner.PSObject.Properties.Name){throw "Owner field absent: $Name"}
    }
    if($Owner.source -cne $Base -or $Owner.thread -cne $Thread -or $Owner.reserved -isnot [bool] -or $Owner.reserved -ne $true){throw 'Owner source/thread/reservation changed'}
    if($Owner.allow_native_launch -isnot [bool] -or $Owner.allow_native_launch -ne $Authorization){throw 'Owner authorization changed'}
    if($null -ne $Owner.active_process_id -or $null -ne $Owner.active_session_id -or $null -ne $Owner.run_id -or $Owner.processes -isnot [array] -or $Owner.processes.Count -ne 0){throw 'Owner PID/session/run/process state not idle'}
}
function Assert-OwnerSnapshot($Current,$Original,[string]$Base,[string]$Thread,[bool]$Authorization) {
    Assert-OwnerIdentity $Original.Owner $Base $Thread $Authorization
    Assert-OwnerIdentity $Current.Owner $Base $Thread $Authorization
    if($Current.Sha256 -cne $Original.Sha256){throw 'Owner raw snapshot changed; completed stage preserved, publication refused'}
}
function Publish-OwnerSnapshot([string]$Path,$Original,[string]$Base,[string]$Target,[string]$Thread,[bool]$Authorization,$Budget) {
    # Caller holds the exclusive native-owner lock for the entire operation.
    Assert-OperationBudget $Budget
    Assert-OwnerIdentity $Original.Owner $Base $Thread $Authorization
    $Next=[Text.UTF8Encoding]::new($false,$true).GetString($Original.Raw).TrimStart([char]0xfeff)|ConvertFrom-Json
    $Next.source=$Target;$Next.purpose='Exact short-piece source prepared; NOT_ADMITTED';$Next.updated_utc=[DateTime]::UtcNow.ToString('o')
    $NextBytes=[Text.Encoding]::UTF8.GetBytes(($Next|ConvertTo-Json -Depth 24)+"`n")
    $Temp=$Path+'.'+[Guid]::NewGuid().ToString('N')+'.tmp'
    [IO.File]::WriteAllBytes($Temp,$NextBytes)
    Assert-OperationBudget $Budget
    # Nothing that can perform unrelated work occurs between this reread/CAS and replacement.
    $Current=Read-OwnerSnapshot $Path $Budget
    Assert-OwnerSnapshot $Current $Original $Base $Thread $Authorization
    [IO.File]::Move($Temp,$Path,$true)
    Assert-OperationBudget $Budget
    return [pscustomobject]@{original_sha256=$Original.Sha256;published_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($NextBytes)).ToLowerInvariant();source=$Target}
}
