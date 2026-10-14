$ErrorActionPreference='Stop'
$Supervisor=Join-Path $PSScriptRoot 'supervisor/run_isolation.ps1'
$Tokens=$null;$ParseErrors=$null
$Ast=[Management.Automation.Language.Parser]::ParseFile($Supervisor,[ref]$Tokens,[ref]$ParseErrors)
if($ParseErrors.Count){throw ($ParseErrors | Out-String)}
# Only lease helpers; no supervisor top level, OS process, real lease or stage.
$Names=@('Write-JsonAtomic','Hash-File','Read-Owner','Assert-IdleOwner','Capture-LeaseSource','Assert-LeaseSource','Write-OwnerChecked','Claim-Owner','Record-OwnedChild','Update-Owner')
foreach($Name in $Names){
 $Definition=@($Ast.FindAll({param($Node) $Node -is [Management.Automation.Language.FunctionDefinitionAst]},$true) | Where-Object Name -CEQ $Name)
 if($Definition.Count -ne 1){throw "Missing helper $Name"}
 Invoke-Expression $Definition[0].Extent.Text
}
$RunDir=Join-Path $PSScriptRoot 'cpu-evidence/lease-fixture'
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$OwnerPath=Join-Path $RunDir 'owner.json'
$ExpectedThread='fixture-root-thread'
$ExpectedSource='bf81ab6255b0b49a639bb39477e8009cb1b06793'
$script:RunnerPid=9000
$script:Checks=0
$Phases=@()
function Check([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message};$script:Checks++}
function MustFail([scriptblock]$Action,[string]$Pattern){$Failed=$false;try{& $Action | Out-Null}catch{$Failed=$_.Exception.Message -match $Pattern};Check $Failed "Expected failure: $Pattern"}
function Reset-Fixture {
 $script:LeaseSourceCaptured=$false;$script:IncomingLeaseSource=$null;$script:OwnerReadHash=$null
 $script:LeaseOwned=$false;$script:LeasePid=0;$script:LeaseRun=$null
 Write-JsonAtomic $OwnerPath ([pscustomobject]@{source='287';thread=$ExpectedThread;reserved=$true;allow_native_launch=$true;active_process_id=$null;active_session_id=$null;active_kind=$null;processes=@();run_id=$null;run_directory=$null;purpose='fixture';updated_utc='fixture'})
}
Reset-Fixture
Capture-LeaseSource (Read-Owner)
foreach($Step in @('parser','component')){
 Claim-Owner $Step
 $Owner=Read-Owner
 Check ($Owner.source -ceq '287' -and $Owner.isolated_source -ceq $ExpectedSource -and $Owner.active_process_id -eq 9000) 'Claim preserves source and records isolated source'
 $Phases+=@{step=$Step;phase='claim';owner=$Owner}
 Record-OwnedChild 9001 ([DateTime]'2026-10-14T10:00:00Z') $Step
 $Owner=Read-Owner
 Check ($Owner.source -ceq '287' -and $Owner.isolated_source -ceq $ExpectedSource -and $Owner.active_process_id -eq 9001) 'Child update preserves source and records isolated source'
 $Phases+=@{step=$Step;phase='child';owner=$Owner}
 Update-Owner $true 9001 $Step
 $Owner=Read-Owner
 Check ($Owner.source -ceq '287' -and $Owner.isolated_source -ceq $ExpectedSource -and -not $Owner.active_process_id -and -not $Owner.run_id -and @($Owner.processes).Count -eq 0) 'Release preserves source and isolated evidence, returning idle'
 $Phases+=@{step=$Step;phase='release';owner=$Owner}
}
# Invalid admission metadata must fail without changing the local lease fixture.
foreach($Case in @(@{field='thread';value='foreign'},@{field='reserved';value=$false},@{field='allow_native_launch';value=$false},@{field='active_process_id';value=42},@{field='active_session_id';value='foreign'},@{field='run_id';value='foreign'},@{field='processes';value=@(@{pid=42})})){
 Reset-Fixture;$Owner=Read-Owner;$Owner.($Case.field)=$Case.value;Write-JsonAtomic $OwnerPath $Owner
 $Before=Hash-File $OwnerPath
 MustFail {Capture-LeaseSource (Read-Owner)} 'not idle/reserved'
 Check ((Hash-File $OwnerPath) -ceq $Before) 'Rejected admission leaves fixture unchanged'
}
# A source change at any mutation boundary cannot be silently adopted or overwritten.
foreach($Boundary in @('claim','child','release','next-step')){
 Reset-Fixture;Capture-LeaseSource (Read-Owner)
 if($Boundary -ne 'claim'){Claim-Owner 'parser'}
 if($Boundary -in @('release','next-step')){Record-OwnedChild 9001 ([DateTime]::UtcNow) 'parser'}
 if($Boundary -eq 'next-step'){Update-Owner $true 9001 'parser'}
 $Owner=Read-Owner;$Owner.source='changed';Write-JsonAtomic $OwnerPath $Owner;$Before=Hash-File $OwnerPath
 switch($Boundary){
  'claim' {MustFail {Claim-Owner 'parser'} 'source changed'}
  'child' {MustFail {Record-OwnedChild 9001 ([DateTime]::UtcNow) 'parser'} 'source changed'}
  'release' {MustFail {Update-Owner $true 9001 'parser'} 'source changed'}
  'next-step' {MustFail {Claim-Owner 'component'} 'source changed'}
 }
 Check ((Hash-File $OwnerPath) -ceq $Before) 'Source conflict leaves fixture unchanged'
}
# Release must still compare root authorization and the exact owning child/run.
foreach($Case in @(@{field='thread';value='foreign'},@{field='reserved';value=$false},@{field='allow_native_launch';value=$false},@{field='active_process_id';value=42},@{field='run_id';value='foreign'},@{field='isolated_source';value='foreign'})){
 Reset-Fixture;Capture-LeaseSource (Read-Owner);Claim-Owner 'parser';Record-OwnedChild 9001 ([DateTime]::UtcNow) 'parser'
 $Owner=Read-Owner;$Owner.($Case.field)=$Case.value;Write-JsonAtomic $OwnerPath $Owner;$Before=Hash-File $OwnerPath
 MustFail {Update-Owner $true 9001 'parser'} 'authorization changed|another run lease'
 Check ((Hash-File $OwnerPath) -ceq $Before) 'Release conflict leaves fixture unchanged'
}
Reset-Fixture;Capture-LeaseSource (Read-Owner)
$Stale=Read-Owner
$Changed=$Stale.PSObject.Copy();$Changed.purpose='concurrent edit';Write-JsonAtomic $OwnerPath $Changed
$Before=Hash-File $OwnerPath
MustFail {Write-OwnerChecked $Stale} 'snapshot changed'
Check ((Hash-File $OwnerPath) -ceq $Before) 'Stale snapshot cannot overwrite concurrent edit'
MustFail {Update-Owner $false 9001 'parser'} 'alternate claim path disabled'
Write-JsonAtomic (Join-Path $RunDir 'verification.json') @{status='CPU_LEASE_PASS';checks=$script:Checks;incoming_source='287';isolated_source=$ExpectedSource;phases=$Phases;real_lease_accessed=$false;engine_launched=$false;shared_stage_accessed=$false;scope='Synthetic 287 source label, fake PIDs, local fixture only; exact helpers extracted from supervisor AST'}
"CPU lease checks PASS: $script:Checks; source287 preserved through claim/child/release for both job steps; no real lease/stage/process operations."
