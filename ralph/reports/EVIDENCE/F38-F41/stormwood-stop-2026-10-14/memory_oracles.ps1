function Assert-TraceInteger($Value,[string]$Label) {
    if ($null -eq $Value -or $Value -is [bool] -or $Value -is [string] -or $Value -is [array]) { throw "Invalid integer: $Label" }
    $D=[double]$Value
    if ([double]::IsNaN($D) -or [double]::IsInfinity($D) -or $D -lt 0 -or $D -gt [long]::MaxValue -or [Math]::Floor($D) -ne $D) { throw "Invalid integer: $Label" }
}
function Assert-MemoryOutput([string]$Stdout,$Step) {
    $TraceMatches=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY (\{[^\r\n]*\})\r?$')
    $Lines=@($TraceMatches | ForEach-Object {$_.Groups[1].Value})
    $Prefixes=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY ').Count
    if ($Lines.Count -ne $Prefixes -or $Lines.Count -lt $Step.required_boundaries.Count -or $Lines.Count -gt 102) { throw 'Missing, malformed or excessive memory trace rows' }
    $Seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $Order=[Collections.Generic.List[string]]::new();$PreviousTicks=-1L
    for ($I=0;$I -lt $Lines.Count;$I++) {
        $Row=$Lines[$I] | ConvertFrom-Json
        if ($Row.source_commit -cne $ExpectedSource -or $Row.pid -ne $script:ProcId -or $Row.sequence -ne $I) { throw 'Trace source/PID/sequence mismatch' }
        foreach($Key in @('sequence','pid','ticks_ms','static_bytes','peak_static_bytes','objects','resources','nodes','render_video_bytes','render_texture_bytes','render_buffer_bytes')) { Assert-TraceInteger $Row.$Key $Key }
        if ($Row.ticks_ms -lt $PreviousTicks -or $Row.peak_static_bytes -lt $Row.static_bytes) { throw 'Trace time or static peak is inconsistent' }
        $PreviousTicks=[long]$Row.ticks_ms
        if ($null -eq $Row.unix_seconds -or $Row.unix_seconds -is [bool] -or $Row.unix_seconds -is [string] -or [double]::IsNaN([double]$Row.unix_seconds) -or [double]::IsInfinity([double]$Row.unix_seconds) -or [double]$Row.unix_seconds -le 0) { throw 'Invalid trace UTC epoch' }
        if ($null -eq $Row.system -or $Row.system -isnot [pscustomobject] -or @($Row.system.PSObject.Properties).Count -eq 0) { throw 'Missing system memory observation' }
        if ([string]::IsNullOrWhiteSpace([string]$Row.boundary) -or -not $Seen.Add([string]$Row.boundary)) { throw 'Duplicate/empty memory boundary' }
        if ($Row.boundary -cnotlike 'enter:*' -and $Row.boundary -cnotin @('before_mount','mount_returned','post_draw_1','post_draw_30','post_draw_60','quit_scheduled')) { throw 'Unknown completion boundary' }
        $Order.Add([string]$Row.boundary)
    }
    $Previous=-1
    foreach($Boundary in $Step.required_boundaries) {
        $At=$Order.IndexOf([string]$Boundary)
        if ($At -le $Previous) { throw 'Required production boundaries missing or reordered' }
        $Previous=$At
    }
    if ($Order[0] -cne 'before_mount' -or $Order[$Order.Count-1] -cne 'quit_scheduled') { throw 'Trace endpoints differ' }
    $MountReturned=$Order.IndexOf('mount_returned')
    for($I=0;$I -lt $Order.Count;$I++){if($Order[$I] -clike 'enter:*' -and ($I -le 0 -or $I -ge $MountReturned)){throw 'Entry outside mount interval'}}
    $Markers=[regex]::Matches($Stdout,'(?m)^STORMWOOD_LOAD_MEMORY_COMPLETE source=([^\r\n]+)\r?$')
    if($Markers.Count -ne 1 -or $Markers[0].Groups[1].Value -cne $ExpectedSource) { throw 'Completion marker missing or duplicated' }
    if($Markers[0].Index -le $TraceMatches[$TraceMatches.Count-1].Index){throw 'Completion marker precedes final trace boundary'}
    return @{rows=$Lines.Count;ordered_boundaries=$Order.ToArray();meaning='observations only; no allocation causation or visual acceptance'}
}
function Write-ProcessMemorySample([string]$Phase,$Memory) {
    if ($script:CurrentStepKind -ne 'allocation-diagnostic') { return }
    $Private=$null;$Working=$null;$Owned=0
    if ($Phase -eq 'running') {
        if ($script:Proc.HasExited) { $Phase='exit_observed' } else {
            $script:Proc.Refresh();$Private=[long]$script:Proc.PrivateMemorySize64;$Working=[long]$script:Proc.WorkingSet64
        }
        $Owned=[int]$script:ProcId
    }
    $Elapsed=if($script:StepTimer){[long]$script:StepTimer.ElapsedMilliseconds}else{0L}
    $Sample=[ordered]@{source_commit=$ExpectedSource;observed_utc=[DateTime]::UtcNow.ToString('o');elapsed_ms=$Elapsed;phase=$Phase;pid=$Owned;private_bytes=$Private;working_set_bytes=$Working;physical_free_bytes=[long]$Memory.physical;commit_headroom_bytes=[long]$Memory.commit}
    [IO.File]::AppendAllText($script:MemorySamplesPath,(($Sample|ConvertTo-Json -Compress)+"`n"),[Text.UTF8Encoding]::new($false))
}
function Assert-ExternalMemorySamples([string]$Path) {
    $Rows=@([IO.File]::ReadAllLines($Path)|ForEach-Object{$_|ConvertFrom-Json})
    if ($Rows.Count -lt 2 -or $Rows.Count -gt 512 -or $Rows[0].phase -cne 'pre_launch' -or $Rows[0].pid -ne 0) { throw 'Missing external prelaunch/process samples' }
    $Last=-1L;$Running=0;$Index=0;$Exited=$false
    foreach($Row in $Rows) {
        if($Row.source_commit -cne $ExpectedSource) { throw 'External sample source mismatch' }
        foreach($Key in @('elapsed_ms','pid','physical_free_bytes','commit_headroom_bytes')){Assert-TraceInteger $Row.$Key $Key}
        if([long]$Row.elapsed_ms -lt $Last) { throw 'External sample timer went backwards' };$Last=[long]$Row.elapsed_ms
        $Timestamp=[DateTimeOffset]::Parse([string]$Row.observed_utc)
        if ($Row.phase -eq 'running') {
            if($Exited){throw 'Live sample after exit observation'}
            if ($Row.pid -ne $script:ProcId) { throw 'External sample owned PID mismatch' }
            Assert-TraceInteger $Row.private_bytes 'private_bytes';Assert-TraceInteger $Row.working_set_bytes 'working_set_bytes';$Running++
        } elseif ($Row.phase -ceq 'pre_launch') {
            if($Index -ne 0 -or $Row.pid -ne 0 -or $null -ne $Row.private_bytes -or $null -ne $Row.working_set_bytes){throw 'Invalid repeated baseline'}
        } elseif ($Row.phase -ceq 'exit_observed') {
            if($Row.pid -ne $script:ProcId -or $null -ne $Row.private_bytes -or $null -ne $Row.working_set_bytes){throw 'Invalid exit sample'}
            $Exited=$true
        } else { throw 'Unknown external sample phase' }
        $Index++
    }
    if ($Running -lt 1) { throw 'No live owned-process memory sample' }
    return @{path=$Path;sha256=(Hash-File $Path);samples=$Rows.Count;running_samples=$Running;private_and_working_set='observed process counters; no causation inferred'}
}
function Assert-TerminalResources($Snapshot) {
    if($Snapshot.telemetry_error){throw 'Terminal resource telemetry unavailable'}
    foreach($Key in @('C_free_bytes','D_free_bytes','physical_free_bytes','commit_headroom_bytes')){Assert-TraceInteger $Snapshot.$Key $Key}
    if($Snapshot.C_free_bytes -lt $CStopFloor -or $Snapshot.D_free_bytes -lt $DStopFloor -or $Snapshot.physical_free_bytes -lt $MemoryFloor -or $Snapshot.commit_headroom_bytes -lt $MemoryFloor){throw 'Terminal resource floor breached'}
}
