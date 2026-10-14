$ErrorActionPreference='Stop'
$Results=[Collections.Generic.List[object]]::new()
function Check([string]$Name,[scriptblock]$Action,[bool]$Reject=$false){
 $Failure=$null;try{$null=& $Action}catch{$Failure=$_.Exception.Message}
 if($Reject -eq [string]::IsNullOrEmpty($Failure)){throw "Fixture $Name unexpected result: $Failure"}
 $Results.Add(@{case=$Name;status=if($Reject){'PASS_REJECTED'}else{'PASS'};reason=$Failure})
}
function Copy-Value($Value){$Value|ConvertTo-Json -Depth 30|ConvertFrom-Json}
$ExpectedSource='868a7b5c8c4d89483a85f2ce0f6c7c7bb2c558ee';$script:ProcId=12345
$CStopFloor=10GB;$DStopFloor=20GB;$MemoryFloor=2GB
$Texts=@{}
foreach($Folder in @('shared','visibility','palette','memory')){
 $ArtifactDir=Join-Path $PSScriptRoot $Folder;$JobPath=Join-Path $ArtifactDir 'native-job.json';$Stage='FIXTURE_NO_STAGE'
 $Runner=Join-Path $ArtifactDir 'run_validation.ps1';$Tokens=$null;$Errors=$null
 $Ast=[Management.Automation.Language.Parser]::ParseFile($Runner,[ref]$Tokens,[ref]$Errors)
 if($Errors.Count){throw ($Errors.Message -join ';')}
 foreach($Name in @('Read-Json','Hash-File','Assert-Hash','Assert-Source','Assert-TraceInteger','Assert-MemoryOutput','Assert-ExternalMemorySamples','Assert-TerminalResources')){
  $Node=$Ast.Find({param($N)$N -is [Management.Automation.Language.FunctionDefinitionAst] -and $N.Name -eq $Name},$true)
  if(-not $Node){throw "Missing $Name"};. ([scriptblock]::Create($Node.Extent.Text))
  if($Texts.ContainsKey($Name)){if($Texts[$Name] -cne $Node.Extent.Text){throw "Function differs across jobs: $Name"}}else{$Texts[$Name]=$Node.Extent.Text}
 }
 $Job=Read-Json $JobPath
 function Invoke-BoundedSourceProcess {return ($script:FixtureSource|ConvertTo-Json -Compress)}
 $GoodSource=@{status='PASS';source=$ExpectedSource;index_paths=49369;bindings=794;materialized_files=12888}
 $script:FixtureSource=Copy-Value $GoodSource;Check "$Folder source positive" {Assert-Source}
 foreach($Change in @(@('index_paths',49341),@('bindings',63),@('materialized_files',12887),@('source','bad'),@('status','FAIL'))){
  $script:FixtureSource=Copy-Value $GoodSource;$script:FixtureSource.($Change[0])=$Change[1]
  Check "$Folder source rejects $($Change[0])" {Assert-Source} $true
 }
 $RunStep=$Ast.Find({param($N)$N -is [Management.Automation.Language.FunctionDefinitionAst] -and $N.Name -eq 'Run-Step'},$true).Extent.Text
 if($RunStep.IndexOf('Assert-TerminalResources $TerminalMetrics') -lt 0 -or $RunStep.IndexOf('Assert-TerminalResources $TerminalMetrics') -gt $RunStep.IndexOf('if ($Exit -ne 0 -or $StopReason)')){throw 'Terminal resource failure not routed to failed receipt'}
}
$Step=(Read-Json (Join-Path $PSScriptRoot 'memory/native-job.json')).steps[0]
$GoodRows=@();$I=0
foreach($Boundary in $Step.required_boundaries){
 $GoodRows+=@{source_commit=$ExpectedSource;pid=12345;sequence=$I;ticks_ms=$I;boundary=$Boundary;unix_seconds=1790000000.5;static_bytes=10;peak_static_bytes=20;system=@{free=100};objects=1;resources=2;nodes=3;render_video_bytes=4;render_texture_bytes=5;render_buffer_bytes=6};$I++
}
function Trace($Rows){return ((@($Rows|ForEach-Object{'STORMWOOD_LOAD_MEMORY '+($_|ConvertTo-Json -Depth 10 -Compress)})+"STORMWOOD_LOAD_MEMORY_COMPLETE source=$ExpectedSource") -join "`n")}
Check 'memory ordered trace' {Assert-MemoryOutput (Trace $GoodRows) $Step}
foreach($Change in @(@('source_commit','bad'),@('pid',77),@('sequence',90),@('ticks_ms',-1),@('static_bytes',-2),@('peak_static_bytes',1),@('unix_seconds','NaN'),@('system',$null),@('nodes',1.5),@('resources',$true))){
 $Rows=Copy-Value $GoodRows;$Rows[2].($Change[0])=$Change[1];Check "trace rejects $($Change[0])" {Assert-MemoryOutput (Trace $Rows) $Step} $true
}
$Rows=Copy-Value $GoodRows;$Rows[2].boundary=$Rows[1].boundary;Check 'duplicate boundary' {Assert-MemoryOutput (Trace $Rows) $Step} $true
$Rows=Copy-Value $GoodRows;$Tmp=$Rows[2].boundary;$Rows[2].boundary=$Rows[3].boundary;$Rows[3].boundary=$Tmp;Check 'reordered entry' {Assert-MemoryOutput (Trace $Rows) $Step} $true
$Rows=Copy-Value $GoodRows;$Rows[2].boundary='enter:Unknown';Check 'missing required boundary' {Assert-MemoryOutput (Trace $Rows) $Step} $true
$Rows=Copy-Value $GoodRows;$Extra=Copy-Value $Rows[0];$Extra.boundary='enter:Late';$Rows=@($Rows[0..($Rows.Count-2)])+$Extra+@($Rows[-1]);for($I=0;$I -lt $Rows.Count;$I++){$Rows[$I].sequence=$I;$Rows[$I].ticks_ms=$I};Check 'entry after mount returned' {Assert-MemoryOutput (Trace $Rows) $Step} $true
$Trace=Trace $GoodRows;$Marker="STORMWOOD_LOAD_MEMORY_COMPLETE source=$ExpectedSource"
Check 'early completion marker' {Assert-MemoryOutput ($Marker+"`n"+$Trace.Replace($Marker,'')) $Step} $true
Check 'missing completion marker' {Assert-MemoryOutput ($Trace.Replace($Marker,'')) $Step} $true
Check 'duplicate completion marker' {Assert-MemoryOutput ($Trace+"`n"+$Marker) $Step} $true
$GoodTerminal=@{C_free_bytes=10GB;D_free_bytes=20GB;physical_free_bytes=2GB;commit_headroom_bytes=2GB}
Check 'terminal floors inclusive' {Assert-TerminalResources $GoodTerminal}
foreach($Key in $GoodTerminal.Keys){$T=Copy-Value $GoodTerminal;$T.$Key--;Check "terminal floor $Key" {Assert-TerminalResources $T} $true;$T.$Key=$null;Check "missing terminal $Key" {Assert-TerminalResources $T} $true}
$T=Copy-Value $GoodTerminal;$T|Add-Member telemetry_error 'fixture';Check 'terminal telemetry failure' {Assert-TerminalResources $T} $true
$SamplePath=Join-Path $PSScriptRoot 'cpu-synthetic-memory.jsonl'
$GoodSamples=@(@{source_commit=$ExpectedSource;observed_utc='2026-10-14T01:00:00Z';elapsed_ms=0;phase='pre_launch';pid=0;private_bytes=$null;working_set_bytes=$null;physical_free_bytes=3GB;commit_headroom_bytes=3GB},@{source_commit=$ExpectedSource;observed_utc='2026-10-14T01:00:01Z';elapsed_ms=1000;phase='running';pid=12345;private_bytes=100;working_set_bytes=200;physical_free_bytes=3GB;commit_headroom_bytes=3GB})
function Samples($Rows){[IO.File]::WriteAllLines($SamplePath,@($Rows|ForEach-Object{$_|ConvertTo-Json -Compress}));Assert-ExternalMemorySamples $SamplePath}
Check 'external baseline and live sample' {Samples $GoodSamples}
foreach($Change in @(@('source_commit','bad'),@('pid',88),@('elapsed_ms',-1),@('observed_utc','invalid'),@('private_bytes',$null),@('phase','unknown'))){$Rows=Copy-Value $GoodSamples;$Rows[1].($Change[0])=$Change[1];Check "external rejects $($Change[0])" {Samples $Rows} $true}
Check 'external missing baseline' {Samples @($GoodSamples[1])} $true
Check 'external repeated baseline' {Samples @($GoodSamples[0],$GoodSamples[0],$GoodSamples[1])} $true
$Exit=Copy-Value $GoodSamples[1];$Exit.phase='exit_observed';$Exit.private_bytes=$null;$Exit.working_set_bytes=$null
Check 'external exit observation' {Samples @($GoodSamples[0],$GoodSamples[1],$Exit)}
$Exit.pid=77;Check 'external exit PID mismatch' {Samples @($GoodSamples[0],$GoodSamples[1],$Exit)} $true
$Exit.pid=12345;Check 'external live after exit' {Samples @($GoodSamples[0],$GoodSamples[1],$Exit,$GoodSamples[1])} $true
$Report=@{status='PASS';native_access=$false;positive=@($Results|Where-Object status -eq 'PASS').Count;negative=@($Results|Where-Object status -eq 'PASS_REJECTED').Count;cases=$Results}
$Report|ConvertTo-Json -Depth 10|Set-Content (Join-Path $PSScriptRoot 'cpu-successor-oracles.json') -Encoding utf8
$Report|Select-Object status,positive,negative,native_access|ConvertTo-Json -Compress
