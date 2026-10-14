$ErrorActionPreference='Stop'
$Results=[Collections.Generic.List[object]]::new()
$FixtureJob=Join-Path $PSScriptRoot 'cpu-gate-job.json';$FixtureAdmission=Join-Path $PSScriptRoot 'cpu-gate-admission.json'
$Pwsh='C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe'
foreach($Folder in @('shared','visibility','palette','memory')){
 $Runner=Join-Path $PSScriptRoot "$Folder/run_validation.ps1"
 $Output=& $Pwsh -NoProfile -File $Runner -CpuPacketFixture 2>&1
 if($LASTEXITCODE -ne 0 -or ($Output -join "`n") -notmatch 'CPU packet PASS'){throw "Packet check failed: $Output"}
 $Results.Add(@{job=$Folder;case='actual unadmitted CPU packet';status='PASS'})
 $Output=& $Pwsh -NoProfile -File $Runner 2>&1
 if($LASTEXITCODE -eq 0 -or ($Output -join "`n") -notmatch 'Exact root admission is required'){throw "Launch did not reject at admission: $Output"}
 $Results.Add(@{job=$Folder;case='actual native invocation rejects before stage/engine access';status='PASS_REJECTED'})
 $Raw=[IO.File]::ReadAllText($Runner)
 $Start=$Raw.IndexOf('$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath')
 $End=$Raw.IndexOf('Assert-Hash $Engine $EngineSha',$Start)
 if($Start -lt 0 -or $End -le $Start){throw 'Unable to bound admission-only fixture'}
 $FixtureRunner=$Runner
 $Gate=[scriptblock]::Create($Raw.Substring($Start,$End-$Start).Replace('$PSCommandPath','$FixtureRunner'))
 # Initialization defines constants/functions only. The gate is cut BEFORE the
 # first engine hash or stage audit; gate fixtures cannot reach those operations.
 $ArtifactDir=Join-Path $PSScriptRoot $Folder
 $Initialization=$Raw.Substring($Raw.IndexOf("$"+'ErrorActionPreference'),$Start-$Raw.IndexOf("$"+'ErrorActionPreference')).Replace('$ArtifactDir = $PSScriptRoot','')
 . ([scriptblock]::Create($Initialization))
 $ArtifactDir=Join-Path $PSScriptRoot $Folder;$JobPath=$FixtureJob;$AdmissionPath=$FixtureAdmission;$PSCommandPath=$Runner
 $CpuStagePreflightFixture=$false;$CpuPacketFixture=$false
 foreach($Case in @('baseline','changed wall budget','changed source binding','changed source identity','changed profile','changed cap')){
  $JobValue=Get-Content (Join-Path $ArtifactDir 'native-job.json') -Raw|ConvertFrom-Json
  $AdmissionValue=Get-Content (Join-Path $ArtifactDir 'native-admission.json') -Raw|ConvertFrom-Json
  $JobValue.status='ROOT_ADMITTED';$JobValue.launch_allowed=$true;$AdmissionValue.status='ROOT_ADMITTED';$AdmissionValue.launch_allowed=$true
  switch($Case){
   'changed wall budget'{$JobValue.steps[0].wall_seconds++}
   'changed source binding'{$JobValue.source_bindings[0].sha256='0'*64}
   'changed source identity'{$JobValue.source_commit='0'*40}
   'changed profile'{$JobValue.graphics_overrides.profiles.Medium.source='D:/invalid.cfg'}
   'changed cap'{$JobValue.caps.physical_and_commit_bytes=1}
  }
  $JobValue|ConvertTo-Json -Depth 30|Set-Content $FixtureJob -Encoding utf8
  $AdmissionValue.job_sha256=Hash-File $FixtureJob
  $AdmissionValue|ConvertTo-Json -Depth 30|Set-Content $FixtureAdmission -Encoding utf8
  $Failure=$null;try{& $Gate}catch{$Failure=$_.Exception.Message}
  if(($Case -eq 'baseline') -ne [string]::IsNullOrEmpty($Failure)){throw "Admission gate $Folder / $Case unexpected: $Failure"}
  $Results.Add(@{job=$Folder;case="paired job/admission $Case";status=if($Failure){'PASS_REJECTED'}else{'PASS_GATE_ONLY'};reason=$Failure})
 }
}
@{status='PASS';native_access=$false;cases=$Results}|ConvertTo-Json -Depth 10|Set-Content (Join-Path $PSScriptRoot 'cpu-launch-gates.json') -Encoding utf8
"PASS $($Results.Count) launch-gate cases; no stage/engine access"
