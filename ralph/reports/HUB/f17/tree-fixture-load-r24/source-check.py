"""SOURCE-only fixture delivery checks; no engine, GD parser, or unit execution."""
from pathlib import Path
import hashlib,json,re
P=Path(__file__).resolve().parent; W=P.parents[4]; R23=P.parent/'tree-corridor-r23'
test='tests/test_vegetation_human_prompt_height.gd'; fixture='tests/fixtures/scatter_tree_corridor_r23.json'
old=(P/'originals'/test).read_bytes(); new=(P/'proposal'/test).read_bytes(); raw=(P/'proposal'/fixture).read_bytes()
checks=[]
def check(name,condition):
 assert condition,name
 checks.append(name)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
previous=b'\tvar data: Variant = JSON.parse_string(FileAccess.get_file_as_string(\n\t\t"res://ralph/reports/HUB/f17/tree-corridor-r23/native-failed/tree-geometry.json"))'
replacement=b'\tvar text := FileAccess.get_file_as_string("res://tests/fixtures/scatter_tree_corridor_r23.json")\n\tif text.is_empty():\n\t\treturn {}\n\tvar data: Variant = JSON.parse_string(text)'
check('exact one loader-only source replacement',old.count(previous)==1 and new==old.replace(previous,replacement))
check('working test matches proposal bytes',(W/test).read_bytes()==new)
check('working fixture matches proposal bytes',(W/fixture).read_bytes()==raw)
original_geometry=(R23/'native-failed/tree-geometry.json').read_bytes()
check('only native final CRLF converted to repository LF',original_geometry.endswith(b'\r\n')
 and original_geometry.count(b'\n')==1 and raw==original_geometry[:-2]+b'\n')
check('known original native geometry SHA',hashlib.sha256(original_geometry).hexdigest()=='a2865c7c39c7be4d3b10d185f5ad90f1d9b81044df0ed7a1d53a8a086294073b')
check('all JSON payload bytes exact',raw.rstrip(b'\n')==original_geometry.rstrip(b'\r\n'))
check('valid UTF8 JSON without BOM',raw.startswith(b'{') and not raw.startswith(b'\xef\xbb\xbf'))
data=json.loads(raw.decode('utf-8'))
check('all parsed native JSON values exact',data==json.loads(original_geometry))
check('225 full-precision native vertices',len(data['mesh']['vertices'])==225)
check('392 original native triples',len(data['mesh']['triangle_indices'])==392)
check('capture complete and never acceptance',data['complete'] and not data['acceptance'])
check('registered full capsule unchanged',data['settled_start']['player']['shape_data']['radius']==.4000000059604645
 and data['settled_start']['player']['shape_data']['height']==1.7999999523162842)
check('same skin and floor angle',data['settled_start']['safe_margin']==.0010000000474974513
 and data['settled_start']['floor_max_angle']==.7853999733924866)
def functions(text):
 starts=list(re.finditer(rb'^func (test_[A-Za-z0-9_]+)\(',text,re.M))
 result={}
 for start in starts:
  next_function=re.search(rb'\nfunc ',text[start.end():])
  end=start.end()+next_function.start() if next_function else len(text)
  result[start.group(1).decode()]=text[start.start():end].rstrip()
 return result
original_cases=functions(old); current_cases=functions(new)
check('all original eight cases retained',len(original_cases)==len(current_cases)==8 and original_cases.keys()==current_cases.keys())
for name,body in original_cases.items():check('case byte-identical '+name,body==current_cases[name])
check('all assertions remain',len(re.findall(rb'\bassert_\w+\(',new))==len(re.findall(rb'\bassert_\w+\(',old)))
check('no evidence path runtime dependency',b'res://ralph/' not in new)
check('no new fallback mesh or native admission',new.count(b'"complete"')==old.count(b'"complete"')==3)
def read_model(content):
 # Offline model only of the loader guard and existing Dictionary result.
 if not content:return {}
 value=json.loads(content)
 return value if isinstance(value,dict) else {}
check('missing fixture model still fails complete assertion',not read_model(None).get('complete',False))
check('empty fixture model still fails complete assertion',not read_model(b'').get('complete',False))
check('non-Dictionary model still fails complete assertion',not read_model(b'[]').get('complete',False))
check('exact fixture model enables existing geometry assertions',read_model(raw)['complete'])
diagnosis=json.loads((P/'diagnosis.json').read_bytes())
check('actual ROOT skipped evidence fixture',diagnosis['runtime_fixture_missing']
 and diagnosis['tracked_root_fixture_flag'].startswith('S '))
check('actual ROOT checkout includes tests', 'tests' in diagnosis['root_sparse_checkout_paths'])
check('ROOT executes its physical project',diagnosis['root_unit_launcher_uses_root_project'])
ci=(W/'.github/workflows/ci.yml').read_text()
check('CI excludes ralph evidence', '!/ralph/' in ci)
check('CI retains tests runtime inputs','!/tests/' not in ci)
check('root JSON attrs preserve LF bytes','*.json text eol=lf' in (W/'.gitattributes').read_text())
check('raw actual failed unit log',digest(P/'unit-failed/tests.log')=='a23f60c833a370a36ae290a1ab086ce9ae4670af7c82e408e2b774ad281429e1')
failed=json.loads((P/'unit-failed/result.json').read_bytes())
check('actual failed unit summary',failed['exit']==1 and not failed['timed_out'] and '8 tests, 40 assertions, 3 failed' in failed['summary'])
check('no native walk after failed unit',diagnosis['actual_unit_result'].endswith('Walk not run.'))
for name,sha in json.loads((P/'unchanged-paths.json').read_bytes()).items():check('unchanged '+name,digest(W/name)==sha)
result={'scope':'AUTHOR SOURCE ONLY; native/GD unit UNRUN; F17#4 OPEN; R9 HOLD','checks_passed':len(checks),'checks':checks,
 'logical_changes':[test,fixture],'fixture_bytes':len(raw),'fixture_sha256':hashlib.sha256(raw).hexdigest(),
 'original_test_cases_preserved':8,'corridor_and_original180_native_conjunction':'UNCHANGED',
 'actual_latest_native':'ROOT8783105f selective unit FAIL8tests40assertions3failed; no corridor walk run',
 'native':'UNRUN locally; existing F29 SOURCE review and ROOT affected unit required'}
(P/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
print(json.dumps({k:v for k,v in result.items() if k!='checks'},indent=2))
