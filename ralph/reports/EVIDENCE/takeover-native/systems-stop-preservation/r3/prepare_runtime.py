from pathlib import Path
import json,hashlib,re,shutil
P=Path(__file__).resolve().parent;F=P.with_name('executable-c836-from565-r2');Q=P.with_name('executable-c836-r3-preparation')
OLD='b9d7edeb7f18d7ca2192f018016d4126f1910f91';NEW='c836df19793e420982bb4aa7b4a0428380126c82'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8',newline='\n')
inventory=json.loads((P/'transport-inventory.json').read_bytes());jobs={}
budget=(Q/'generic/operation_budget.ps1').read_text()
for folder in ('native-supervisor','departure-supervisor'):
 n=P/folder;n.mkdir(exist_ok=True)
 s=(F/folder/'run_validation.ps1').read_text()
 s=s.replace('5650c507e69ed0a7b6feaf72d1f345e406c98109',OLD).replace('sysc836-validation-r2','sysc836-validation-r3').replace('sysc836-departure-r2','sysc836-departure-r3')
 a=s.index('function Invoke-Git(');b=s.index('function Get-FreeBytes',a)
 s=s[:a]+budget+'\n'+(P/'bounded_git.ps1').read_text()+'\n'+s[b:]
 a=s.index('function Assert-Source {');b=s.index('function Read-Owner',a)
 block=s[a:b]
 block=block.replace('function Assert-Source {','function Assert-Source {\n    $script:SourceBudget=New-OperationBudget\n    try {')
 last=block.rfind('}')
 block=block[:last]+'''    Assert-OperationBudget $script:SourceBudget
    } catch { $null=Start-OperationCleanup $script:SourceBudget;throw }
    finally {Assert-OperationBudget $script:SourceBudget -Cleanup}
}
'''+block[last+1:]
 # Check cumulative elapsed through every source-tree/binding loop.
 block=block.replace('    foreach (','    Assert-OperationBudget $script:SourceBudget\n    foreach (')
 block=block.replace('        $Blob=$null','        Assert-OperationBudget $script:SourceBudget\n        $Blob=$null')
 block=block.replace("foreach ($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)) {", "foreach ($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)) {\n        Assert-OperationBudget $script:SourceBudget")
 s=s[:a]+block+s[b:]
 a=s.index('function Get-GitBlobId(');b=s.index('function Assert-Source',a)
 block=s[a:b]
 block=block.replace("    $File=Get-Item", "    Assert-OperationBudget $script:SourceBudget\n    $File=Get-Item")
 block=block.replace('while(($Count=$Stream.Read($Buffer,0,$Buffer.Length)) -gt 0){$Hasher.AppendData($Buffer,0,$Count)}', 'while(($Count=$Stream.Read($Buffer,0,$Buffer.Length)) -gt 0){Assert-OperationBudget $script:SourceBudget;$Hasher.AppendData($Buffer,0,$Count)}\n        Assert-OperationBudget $script:SourceBudget')
 block=block.replace('    foreach($Entry in $Tree.GetEnumerator()){','    foreach($Entry in $Tree.GetEnumerator()){\n        Assert-OperationBudget $script:SourceBudget')
 block=block.replace('    foreach($Line in Invoke-Git','    Assert-OperationBudget $script:SourceBudget\n    foreach($Line in Invoke-Git')
 block=block.replace("foreach($Line in Invoke-Git @('ls-files','--stage')){", "foreach($Line in Invoke-Git @('ls-files','--stage')){\n        Assert-OperationBudget $script:SourceBudget")
 block=block.replace("foreach($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)){", "foreach($Line in Invoke-Git @('ls-tree','-r',$ExpectedSource)){\n        Assert-OperationBudget $script:SourceBudget")
 block=block.replace("        if($Actual -cne $Entry.Value)", "        Assert-OperationBudget $script:SourceBudget\n        if($Actual -cne $Entry.Value)")
 s=s[:a]+block+s[b:]
 s=s.replace('function Assert-BoundFile($Binding,[string]$Root) {','function Assert-BoundFile($Binding,[string]$Root) {\n    Assert-OperationBudget $script:SourceBudget')
 (n/'run_validation.ps1').write_text(s,encoding='utf-8',newline='\n')
 request=json.loads((F/folder/'request.json').read_bytes());request['base']=OLD
 for step in request['steps']:step['args']=[x.replace('sysc836-departure-r2','sysc836-departure-r3') for x in step['args']]
 save(n/'request.json',request)
 job=json.loads((F/folder/'native-job.json').read_bytes())
 job.update(job_id=job['job_id'].replace('-r2','-r3'),output_directory=job['output_directory'].replace('-r2','-r3'),staging_base=OLD,changed_source_paths=inventory['changed_paths'],steps=request['steps'],supervisor_sha256=sha(n/'run_validation.ps1'))
 for binding in job['request_bindings']:
  if binding['path']==(F/folder/'request.json').as_posix():binding.update(path=(n/'request.json').as_posix(),sha256=sha(n/'request.json'))
 if folder=='native-supervisor':job['pack_binding']=dict(path=(P/'transition.pack').as_posix(),bytes=(P/'transition.pack').stat().st_size,sha256=sha(P/'transition.pack'))
 assert job['caps']==json.loads((F/folder/'native-job.json').read_bytes())['caps']
 save(n/'native-job.json',job);jobs[folder]=sha(n/'native-job.json')
 admission=json.loads((F/folder/'native-admission.json').read_bytes());admission.update(job_id=job['job_id'],job_sha256=jobs[folder],supervisor_sha256=job['supervisor_sha256'])
 save(n/'native-admission.json',admission)
helper=P/'root-transition/transition_paths.py'
s=helper.read_text().replace('e8cdf40026b56432904a3524d4392b761305d10c5c06dca914b65307dbed5b12',jobs['native-supervisor'])
helper.write_text(s,encoding='utf-8',newline='\n')
w=(P/'wrapper_template.ps1').read_text()
for old,new in {'BUDGET_PS_HASH':sha(P/'root-transition/operation_budget.ps1'),'OWNER_PS_HASH':sha(P/'root-transition/owner_publication.ps1'),'BASE_COMMIT':OLD,'HELPER_HASH':sha(helper),'JOB_HASH':jobs['native-supervisor']}.items():w=w.replace(old,new)
(P/'root-transition/run_transition.ps1').write_text(w,encoding='utf-8',newline='\n')
save(P/'packet-manifest.json',dict(status='PREPARED_NOT_ADMITTED',source=NEW,base=OLD,jobs=jobs,transition_helper_sha256=sha(helper),transition_wrapper_sha256=sha(P/'root-transition/run_transition.ps1'),transition_checks_sha256=sha(P/'root-transition/transition_checks.py'),budget_python_sha256=sha(P/'root-transition/operation_budget.py'),budget_powershell_sha256=sha(P/'root-transition/operation_budget.ps1'),owner_publication_sha256=sha(P/'root-transition/owner_publication.ps1'),caps_unchanged=True,stage_access=False,engine_launched=False))
print((P/'packet-manifest.json').read_text())
