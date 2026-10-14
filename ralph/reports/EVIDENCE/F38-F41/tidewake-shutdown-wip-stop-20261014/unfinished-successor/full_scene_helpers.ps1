# Function definitions only; imported by generation, not executed during preparation.
function Invoke-Git([string[]]$GitArgs) {
    $Info=[Diagnostics.ProcessStartInfo]::new()
    $Info.FileName=$Git; $Info.UseShellExecute=$false; $Info.CreateNoWindow=$true
    $Info.RedirectStandardOutput=$true; $Info.RedirectStandardError=$true
    $Info.Environment['GIT_NO_LAZY_FETCH']='1'; $Info.Environment['GIT_OPTIONAL_LOCKS']='0'
    foreach($Arg in @('-C',$Stage,'-c','gc.auto=0','-c','maintenance.auto=false','-c','core.fsmonitor=false','-c','core.preloadindex=false')+$GitArgs){$Info.ArgumentList.Add($Arg)}
    $Child=[Diagnostics.Process]::new(); $Child.StartInfo=$Info
    try {
        if(-not $Child.Start()){throw 'Git preflight failed to start'}
        $Out=$Child.StandardOutput.ReadToEndAsync();$Err=$Child.StandardError.ReadToEndAsync()
        if(-not $Child.WaitForExit(10000)){$Child.Kill();$null=$Child.WaitForExit(1000);throw 'Git preflight exceeded10s'}
        if(-not ([Threading.Tasks.Task]::WhenAll([Threading.Tasks.Task[]]@($Out,$Err))).Wait(1000)){throw 'Git preflight streams exceeded1s'}
        if($Child.ExitCode -ne 0){throw ('Git preflight failed: '+$Err.Result)}
        return @($Out.Result -split '\r?\n' | Where-Object {$_ -ne ''})
    } finally {$Child.Dispose()}
}
function Assert-Source {
    if($ExpectedSource -cnotmatch '^[0-9a-f]{40}$'){throw 'Final baseline not bound'}
    $Head=@(Invoke-Git @('rev-parse','HEAD'))
    if($Head.Count -ne 1 -or $Head[0] -cne $ExpectedSource){throw 'Native HEAD differs from reviewed source'}
    if(@(Invoke-Git @('status','--porcelain','--untracked-files=no')).Count){throw 'Tracked native source dirty'}
    $AllBindings=@($Job.source_bindings)
    if($AllBindings.Count -lt 3){throw 'Source bindings incomplete'}
    $Tree=@{}
    foreach($Line in @(Invoke-Git (@('ls-tree','-r',$ExpectedSource,'--')+@($AllBindings | ForEach-Object {[string]$_.path})))){
        if($Line -notmatch '^100[0-7]{3} blob ([0-9a-f]{40})\t(.+)$'){throw 'Unexpected source tree entry'}
        if($Tree.ContainsKey($Matches[2])){throw 'Duplicate source tree binding'}
        $Tree[$Matches[2]]=$Matches[1]
    }
    if($Tree.Count -ne $AllBindings.Count){throw 'Source binding tree count differs'}
    $RootFull=[IO.Path]::GetFullPath($Stage).TrimEnd('\')+'\'
    foreach($Binding in $AllBindings){
        $File=[IO.Path]::GetFullPath((Join-Path $Stage ([string]$Binding.path)))
        if(-not $File.StartsWith($RootFull,[StringComparison]::OrdinalIgnoreCase)){throw 'Source binding escapes stage'}
        if($Tree[[string]$Binding.path] -cne [string]$Binding.blob){throw 'Source Git blob mismatch'}
        if($Binding.encoding -ceq 'bytes'){$Digest=Hash-File $File}
        elseif($Binding.encoding -ceq 'utf8-lf'){
            $Text=[IO.File]::ReadAllText($File).Replace("`r`n","`n")
            $Digest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
        }else{throw 'Explicit canonical source encoding required'}
        if($Digest -cne $Binding.sha256){throw ('Canonical source hash mismatch: '+$Binding.path)}
    }
}
function Require-Integer($Value,[long]$Minimum,[string]$Name) {
    if(($Value -isnot [int] -and $Value -isnot [long]) -or $Value -lt $Minimum){throw "Invalid integer readback: $Name"}
}
function Require-Finite($Value,[double]$Minimum,[string]$Name) {
    if(($Value -isnot [int] -and $Value -isnot [long] -and $Value -isnot [double] -and $Value -isnot [decimal]) -or [double]::IsNaN([double]$Value) -or [double]::IsInfinity([double]$Value) -or [double]$Value -lt $Minimum){throw "Invalid finite readback: $Name"}
}
function Read-ResourceSummary([string]$Stdout) {
    $Records=@();$Phases=@();$LineNumber=0
    foreach($Line in ($Stdout -split '\r?\n')){
        $LineNumber++
        if($Line.StartsWith('TIDEWAKE SHUTDOWN RESOURCES ',[StringComparison]::Ordinal)){
            $Records+=,@{line=$LineNumber;value=($Line.Substring(27) | ConvertFrom-Json)}
        }elseif($Line -cmatch '^TIDEWAKE SHUTDOWN phase=(\w+) ticks_ms=(\d+)$'){
            $Phases+=,@{phase=$Matches[1];ticks_ms=[long]$Matches[2];line=$LineNumber}
        }elseif($Line.StartsWith('TIDEWAKE SHUTDOWN phase=',[StringComparison]::Ordinal)){throw 'Malformed shutdown marker'}
    }
    if($Records.Count -ne 1){throw 'Exactly one resource readback required'}
    $R=$Records[0].value
    foreach($Name in @('ticks_ms','multimesh_nodes','multimesh_instances','msaa_3d')){Require-Integer $R.$Name 0 $Name}
    Require-Integer $R.terrain_regions 1 'terrain_regions (unknown is unavailable)'
    if($R.multimesh_nodes -lt 1 -or $R.multimesh_instances -lt 1){throw 'Full-scene configured MultiMesh scope missing'}
    if($R.renderer -cne 'forward_plus' -or $R.multimesh_scope -cne 'all world descendants; configured counts, not visible draws'){throw 'Renderer/count scope differs'}
    if(@($R.render_size).Count -ne 2){throw 'Render size missing'}
    foreach($N in $R.render_size){Require-Integer $N 1 'render_size'}
    if($R.render_size[0] -ne 1920 -or $R.render_size[1] -ne 1080){throw 'Render size differs'}
    if($R.environment_present -isnot [bool] -or -not $R.environment_present){throw 'Effective environment unavailable'}
    if($R.environment_source -cnotin @('camera','world','world_fallback')){throw 'Environment provenance missing'}
    Require-Finite $R.camera_far 0.00001 'camera_far'
    Require-Integer $R.background_mode 0 'background_mode'
    foreach($Name in @('ssao_enabled','ssil_enabled','glow_enabled','fog_enabled','volumetric_fog_enabled','sky_present')){
        if($R.$Name -isnot [bool]){throw "Boolean readback missing: $Name"}
    }
    foreach($Name in @('volumetric_fog_density','volumetric_fog_length')){Require-Finite $R.$Name 0 $Name}
    if(-not $R.sky_present -or $R.sky_material_class -isnot [string] -or [string]::IsNullOrWhiteSpace($R.sky_material_class)){throw 'Effective sky unavailable'}
    Require-Integer $R.sky_radiance_size 0 'sky_radiance_size';Require-Integer $R.sky_process_mode 0 'sky_process_mode'
    $Seen=@{};$Last=-1L
    foreach($Phase in $Phases){
        if($Seen.ContainsKey($Phase.phase) -or $Phase.ticks_ms -lt $Last){throw 'Duplicate/reversed shutdown phase'}
        $Seen[$Phase.phase]=$Phase;$Last=$Phase.ticks_ms
    }
    $Expected=@('fixed_views_returned','terrain_teardown_info_enabled','quit_requested','quit_returned','root_tree_exiting','root_tree_exited_before_delete','root_deleted_and_delete_queue_flushed')
    $LastLine=0
    foreach($Name in $Expected){
        if(-not $Seen.ContainsKey($Name) -or $Seen[$Name].line -le $LastLine){throw "Missing/reversed required boundary: $Name"}
        $LastLine=$Seen[$Name].line
    }
    if($Records[0].line -ge $Seen.quit_requested.line -or $R.ticks_ms -gt $Seen.quit_requested.ticks_ms){throw 'Resource readback after quit'}
    return @{resources=$R;phases=$Phases;scope='Configured descendants and effective settings only; no GPU bytes or teardown ownership inferred'}
}
function Assert-CollectorReady {
    # No adapter can be admitted merely by changing JSON. Discovery and a
    # harmless owned-process verification must precede implementing it.
    throw 'Collector unavailable/unverified; native launch blocked before stage or lease access'
}
