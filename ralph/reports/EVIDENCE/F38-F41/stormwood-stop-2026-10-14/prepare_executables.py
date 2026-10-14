from pathlib import Path
import copy,hashlib,json,re,ast
R=Path(__file__).resolve().parent
P=Path('D:/tetherbound/.artifacts/codex-look-meadows/medium-off-b9d7edeb7f-from-5650c507e6-r4')
S=Path('D:/tetherbound/.artifacts/codex-look-stormwood/native-287801583d/production-prerequisites/focused')
REPO=Path('D:/tetherbound/codex-look-stormwood')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_bytes())
def write(p,obj):p.write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8',newline='\n')
def text(p,s):p.write_text(s,encoding='utf-8',newline='\n')
B=read(R/'source-bindings.json');I=read(R/'transition-inventory.json')
assert (R/'cpu-source-closure.json').exists(),'Source closure must complete first'
target=B['source'];old=B['native_transition_from'];parent=B['parent'];n=len(B['source_bindings'])
(R/'Medium-graphics_override.cfg').write_bytes((P/'Medium-graphics_override.cfg').read_bytes())
template=(P/'off/run_meadows_look.ps1').read_text(encoding='utf-8-sig')
oldtests=(S/'run_validation.ps1').read_text(encoding='utf-8-sig')
testoracle=oldtests[oldtests.index('function Assert-TestOutput'):oldtests.index('function Assert-StepIds')]
common=template[:template.index('function Assert-FiniteNumber')]+testoracle+(R/'memory_oracles.ps1').read_text()+'\n'+template[template.index('function Assert-StepIds'):template.index('$Job=Read-Json $JobPath')]
# Preserve the reviewed runner's process/identity/deadline/drain code. Only
# provision a graphics override for the native memory diagnostic.
a=common.index('    $ProjectText=');b=common.index('    $OutPath=Join-Path',a)
common=common[:a]+"    if ($Step.kind -eq 'allocation-diagnostic') {\n"+common[a:b]+"    }\n"+common[b:]
common=common.replace("$script:CurrentStepId=[string]$Step.id;", "$script:CurrentStepId=[string]$Step.id; $script:CurrentStepKind=[string]$Step.kind;")
common=common.replace("    $Timer=[Diagnostics.Stopwatch]::StartNew();", "    $script:MemorySamplesPath=Join-Path $RunDir 'memory-samples.jsonl'\n    if($Step.kind -eq 'allocation-diagnostic') { Write-ProcessMemorySample 'pre_launch' (Get-Memory) }\n    $Timer=[Diagnostics.Stopwatch]::StartNew();")
# Record the failing physical/commit observation BEFORE the existing floor
# checks throw. Baseline is explicit; samples start only after CIM identity.
common=common.replace("    if ($Admission -and $C -lt $CAdmissionFloor)", "    if ($script:CurrentStepKind -eq 'allocation-diagnostic' -and $script:CommandLine) { Write-ProcessMemorySample 'running' $M }\n    if ($Admission -and $C -lt $CAdmissionFloor)")
common=common.replace("    $TestResult=Assert-CaptureOutput $Stdout $Step", "    $TestResult=if($Step.kind -eq 'single-file-tests'){Assert-TestOutput $Stdout $Step}else{Assert-MemoryOutput $Stdout $Step}\n    $ExternalMemory=if($Step.kind -eq 'allocation-diagnostic'){Assert-ExternalMemorySamples $script:MemorySamplesPath}else{$null}")
common=common.replace('actual_capture_result=$TestResult','actual_result=$TestResult;external_memory=$ExternalMemory')
common=common.replace(" $Result=$Text|ConvertFrom-Json", " $Contract=Read-Json (Join-Path $ArtifactDir 'source-contract.json')\n $Result=$Text|ConvertFrom-Json")
common=common.replace('$Result.index_paths -ne 49341 -or $Result.bindings -ne 63 -or $Result.materialized_files -lt 12887', '$Result.index_paths -ne $Contract.full_index_paths -or $Result.bindings -ne @($Job.source_bindings).Count -or $Result.materialized_files -lt @($Contract.materialize).Count')
common=common.replace('    $TerminalMetrics=Read-TerminalMetrics', '    $TerminalMetrics=Read-TerminalMetrics\n    try { Assert-TerminalResources $TerminalMetrics } catch { if(-not $StopReason){$StopReason=$_.Exception.Message} }')
common=common.replace("$Owner.thread -cne $ExpectedThread -or $Owner.reserved", "$Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved")
common=common.replace('Meadows Medium fixed-camera capture','Stormwood scoped validation').replace('meadows_b9d7edeb7f','stormwood_868a7b5c8c')
common=common.replace("$ExpectedSource = 'b9d7edeb7f18d7ca2192f018016d4126f1910f91'",f"$ExpectedSource = '{target}'")
common=common.replace("$ExpectedParent = 'edb413144b51c003e5c98fc144df82192871f158'",f"$ExpectedParent = '{parent}'")
common=common.replace("$ExpectedBase = 'e30b761bbe6f874df95c3b2153d9fcd7a7c8c6e7'",f"$ExpectedBase = '{old}'")
tail=template[template.index('Assert-Resources $true\nAssert-NoForeignEngine\nif ((Get-RunBytes $PacketDir)'):]
tail=tail.replace("$Owner.thread -cne $ExpectedThread -or $Owner.reserved", "$Owner.source -cne $ExpectedSource -or $Owner.thread -cne $ExpectedThread -or $Owner.reserved")
basejob=read(P/'off/native-job.json');jobs=[]
required=read(R.parent/'load-memory-discriminator/review-request.json')['required_trace_boundaries']
for folder,testfile,jobid in [('shared','test_vegetation_shared_retint.gd','sw868t-r3'),('visibility','test_foliage_camera_visibility.gd','sw868v-r3'),('palette','test_stormwood_vegetation_palette.gd','sw868p-r3'),('memory',None,'sw868mem-r3')]:
    d=R/folder
    if testfile:
        names=re.findall(r'^func (test_\w+)\(', (REPO/'tests'/testfile).read_text(),re.M)
        step={'id':folder,'kind':'single-file-tests','wall_seconds':120,'max_output_bytes':10485760,
          'args':['--headless','--path','C:/CodexTemp/tetherbound-native-service','--script','tools/run_one_test.gd','--','res://tests/'+testfile],
          'expected_test_methods':len(names),'expected_test_names':names}
    else:
        step={'id':'load-memory','kind':'allocation-diagnostic','wall_seconds':180,'max_output_bytes':52428800,'preset':'Medium',
          'args':['--path','C:/CodexTemp/tetherbound-native-service','--rendering-method','forward_plus','--resolution','1920x1080','--script','tools/probe_stormwood_load_memory.gd','--','--preset=Medium','--source-commit='+target,'--out=D:/tetherbound/.artifacts/s/run-'+jobid+'/unused-output'],
          'required_boundaries':required,'images_expected':0}
    preflight={'helper_sha256':sha(d/'source_preflight.py'),'contract_sha256':sha(d/'source-contract.json'),'wall_milliseconds':45000,'internal_seconds':40}
    request={'source':target,'parent':parent,'base':old,'steps':[step],'source_preflight':preflight}
    write(d/'request.json',request)
    job=copy.deepcopy(basejob)
    job.update(schema='codex.stormwood-scoped-successor.v1',job_id=jobid,status='PREPARED',launch_allowed=False,
      source_commit=target,source_parent=parent,staging_base=old,native_transition_from=old,
      changed_source_paths=[x['path'] for x in I['transition_delta']],source_bindings=B['source_bindings'],
      request_bindings=[{'path':str(d/'request.json'),'sha256':sha(d/'request.json')}],
      output_directory='D:\\tetherbound\\.artifacts\\s\\run-'+jobid,steps=[step],source_preflight=preflight,
      limits_and_scope={'max_wall_seconds_per_step':step['wall_seconds'],'scope':'One separately admitted piece; no automatic next job','runs_serially':True})
    job['graphics_overrides']['profiles']['Medium']['source']=str(R/'Medium-graphics_override.cfg')
    gate=f'''$Job=Read-Json $JobPath; $Admission=Read-Json $AdmissionPath
if($CpuStagePreflightFixture -or $CpuPacketFixture) {{
 if($Job.status -cne 'PREPARED' -or $Job.launch_allowed -ne $false -or $Admission.status -cne 'NOT_ADMITTED' -or $Admission.launch_allowed -ne $false -or $Admission.job_sha256 -cne (Hash-File $JobPath)){{throw 'CPU fixture requires exact unadmitted bytes'}}
}} elseif($Job.status -cne 'ROOT_ADMITTED' -or $Job.launch_allowed -ne $true -or $Admission.status -cne 'ROOT_ADMITTED' -or $Admission.launch_allowed -ne $true -or $Admission.job_sha256 -cne (Hash-File $JobPath)){{throw 'Exact root admission is required'}}
$PacketDir=Split-Path -Parent $ArtifactDir
if($Job.supervisor_sha256 -cne (Hash-File $PSCommandPath)){{throw 'Supervisor hash differs'}}
if($Job.source_commit -cne $ExpectedSource -or $Job.source_parent -cne $ExpectedParent -or $Job.staging_base -cne $ExpectedBase -or $Job.native_transition_from -cne $ExpectedBase -or $Job.stage -cne $Stage -or $Job.job_id -cne '{jobid}' -or $Admission.job_id -cne '{jobid}' -or $Admission.schema -cne 'codex.stormwood-scoped-admission.v1' -or $Job.output_directory -cne 'D:\\tetherbound\\.artifacts\\s\\run-{jobid}'){{throw 'Exact source/job/stage identity differs'}}
if($Job.engine.path -cne $Engine -or $Job.engine.sha256 -cne $EngineSha){{throw 'Engine pin differs'}}
if([long]$Job.caps.C_admission_bytes -ne $CAdmissionFloor -or [long]$Job.caps.C_stop_bytes -ne $CStopFloor -or [long]$Job.caps.D_admission_bytes -ne $DAdmissionFloor -or [long]$Job.caps.D_stop_bytes -ne $DStopFloor -or [long]$Job.caps.physical_and_commit_bytes -ne $MemoryFloor -or [long]$Job.caps.combined_stdout_stderr_bytes -ne $CombinedLogsCap -or [long]$Job.caps.run_output_and_isolated_homes_bytes -ne $OutputCap -or [long]$Job.caps.packet_bytes -ne $PacketCap){{throw 'Resource caps differ'}}
Assert-Hash (Join-Path $ArtifactDir 'request.json') '{sha(d/'request.json')}'
Assert-Hash (Join-Path $PacketDir 'source-bindings.json') '{sha(R/'source-bindings.json')}'
Assert-Hash (Join-Path $PacketDir 'transition-inventory.json') '{sha(R/'transition-inventory.json')}'
Assert-Hash (Join-Path $PacketDir 'source.pack') '{sha(R/'source.pack')}'
Assert-Hash (Join-Path $PacketDir 'Medium-graphics_override.cfg') '{sha(R/'Medium-graphics_override.cfg')}'
$Bound=Read-Json (Join-Path $PacketDir 'source-bindings.json')
if(@($Job.source_bindings).Count -ne {n} -or ($Job.source_bindings|ConvertTo-Json -Depth 20 -Compress) -cne ($Bound.source_bindings|ConvertTo-Json -Depth 20 -Compress)){{throw 'Exact source bindings differ'}}
$Inventory=Read-Json (Join-Path $PacketDir 'transition-inventory.json')
if(($Job.changed_source_paths|ConvertTo-Json -Compress) -cne (@($Inventory.transition_delta|ForEach-Object{{$_.path}})|ConvertTo-Json -Compress)){{throw 'Exact source delta differs'}}
$Request=Read-Json (Join-Path $ArtifactDir 'request.json')
if($Request.source -cne $ExpectedSource -or $Request.parent -cne $ExpectedParent -or $Request.base -cne $ExpectedBase -or @($Job.steps).Count -ne 1 -or ($Job.steps|ConvertTo-Json -Depth 20 -Compress) -cne ($Request.steps|ConvertTo-Json -Depth 20 -Compress) -or ($Job.source_preflight|ConvertTo-Json -Compress) -cne ($Request.source_preflight|ConvertTo-Json -Compress)){{throw 'Exact request differs'}}
Assert-Hash (Join-Path $ArtifactDir 'source_preflight.py') $Request.source_preflight.helper_sha256
Assert-Hash (Join-Path $ArtifactDir 'source-contract.json') $Request.source_preflight.contract_sha256
Assert-StepIds $Job.steps
if($Job.graphics_overrides.project_name -cne 'Tetherbound' -or $Job.graphics_overrides.profiles.Medium.source -cne (Join-Path $PacketDir 'Medium-graphics_override.cfg') -or $Job.graphics_overrides.profiles.Medium.sha256 -cne '{sha(R/'Medium-graphics_override.cfg')}' -or $Job.graphics_overrides.user_data_path_rule -cne '%APPDATA%\\Godot\\app_userdata\\Tetherbound\\graphics_override.cfg'){{throw 'Isolated profile differs'}}
if($CpuPacketFixture){{'CPU packet PASS; unadmitted; no native access';exit 0}}
Assert-Hash $Engine $EngineSha
Assert-Source
if((Read-Json (Join-Path $Stage 'data/config/stormwood_look.json')).enabled -ne $false){{throw 'Stormwood look must remain OFF'}}
if($CpuStagePreflightFixture){{'CPU stage preflight PASS; no engine';exit 0}}
Assert-Hash ([string]$Admission.prerequisite_review_path) ([string]$Admission.prerequisite_review_sha256)
$Proof=Read-Json ([string]$Admission.prerequisite_review_path)
if($Proof.status -cne 'ROOT_REVIEWED_FOR_SCOPED_VALIDATION' -or $Proof.source_commit -cne $ExpectedSource -or $Proof.transition_from -cne $ExpectedBase -or $Proof.job_sha256 -cne (Hash-File $JobPath) -or $Proof.source_and_transition_reviewed -ne $true -or $Proof.imports_ready -ne $true -or $Proof.execution_contract_reviewed -ne $true -or $Proof.terrain_dll_sha256 -cne '5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306'){{throw 'Exact root execution review required'}}
'''
    if not testfile:gate+="if($Proof.external_memory_sampling_reviewed -ne $true){throw 'External memory sampling review required'}\n"
    runner=common+gate+tail
    text(d/'run_validation.ps1',runner)
    job['supervisor_sha256']=sha(d/'run_validation.ps1');write(d/'native-job.json',job)
    write(d/'native-admission.json',{'schema':'codex.stormwood-scoped-admission.v1','job_id':jobid,'status':'NOT_ADMITTED','launch_allowed':False,'job_sha256':sha(d/'native-job.json'),'prerequisite_review_path':'','prerequisite_review_sha256':''})
    jobs.append({'id':jobid,'kind':'focused' if testfile else 'memory','job':str(d/'native-job.json'),'supervisor':str(d/'run_validation.ps1')})
# Rebind the reviewed preserving swap without altering guard function bodies.
swap=(P/'swap_stage.py').read_text(encoding='utf-8-sig')
replacements={str(P).replace('\\','/') :str(R).replace('\\','/'),
 "D:/tetherbound/.artifacts/codex-look-meadows/stage-swap-backup-meadows-565-to-b9-r4":"D:/tetherbound/.artifacts/codex-look-stormwood/stage-swap-backup-b9-to-868-r3",
 "OLD='5650c507e69ed0a7b6feaf72d1f345e406c98109'":f"OLD='{old}'",
 "TARGET='b9d7edeb7f18d7ca2192f018016d4126f1910f91'":f"TARGET='{target}'",
 "INDEX_SHA='ebf8bb610e5426bddc22000e84dd64da37117790aa6667f51e5bbcf196dfb408'":"INDEX_SHA='8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4'",
 "'off/":"'shared/",'else 63':'else 794','==63':'==794','Exact 63':'Exact 794',
 sha(P/'source-bindings.json'):sha(R/'source-bindings.json'),sha(P/'transition-inventory.json'):sha(R/'transition-inventory.json'),sha(P/'source.pack'):sha(R/'source.pack')}
for a,b in replacements.items():swap=swap.replace(a,b)
pins={f:sha(R/'shared'/f) for f in ('source_preflight.py','source-contract.json','source-contract-before.json','source-job-before.json')}
swap=re.sub(r' pins=\{[^\n]+\}', ' pins='+repr(pins),swap)
swap=swap.replace('preserving 565 -> b9 transition','preserving b9 -> 868 transition')
start=swap.index('def git(');end=swap.index('def tree(',start)
swap=swap[:start]+(R/'bounded_git.py').read_text()+'\n\n'+swap[end:]
text(R/'swap_stage.py',swap);ast.parse(swap)
wrapper=(P/'swap_stage.ps1').read_text(encoding='utf-8-sig').replace('off/run_meadows_look.ps1','shared/run_validation.ps1')
text(R/'swap_stage.ps1',wrapper)
for f in ('verify_transition_guards.py','verify_supervisor_deadlines.ps1'):(R/f).write_bytes((P/f).read_bytes())
write(R/'packet.json',{'source':target,'transition_from':old,'status':'DRAFT_NOT_ADMITTED','jobs':jobs,'automatic_sequence':False})
write(R/'preparation-provenance.json',{'guard_template':str(P),'source_preflight_sha256':sha(P/'off/source_preflight.py'),
 'swap_template_sha256':sha(P/'swap_stage.py'),'runner_template_sha256':sha(P/'off/run_meadows_look.ps1'),
 'altered_scope':['exact pins and four isolated single-step gates','named-test or ordered memory oracle','external PID memory samples','profile only for memory diagnostic','owner source match'],
 'before_index_sha256':'8564bb8b52f74c58803830eb8562798a00af80804039c1be217eea885cf096f4','native_executed':False})
print(json.dumps({'prepared_jobs':len(jobs),'methods':sum(read(Path(j['job']))['steps'][0].get('expected_test_methods',0) for j in jobs),'source':target,'native_executed':False}))
