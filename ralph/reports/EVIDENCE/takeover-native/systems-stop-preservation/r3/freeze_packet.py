from pathlib import Path
import hashlib,json
P=Path(__file__).resolve().parent;F=P.with_name('executable-c836-from565-r2')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
review=Path('D:/tetherbound/.artifacts/systems-c836-r2-independent-cpu/independent-prepared-review.json')
assert sha(review)=='add8ee5c6cfc88870068d05a56ef843bcd9a5730eace49922cde1dcbb646df91'
old=json.loads(review.read_bytes())['hashes'];assert all(sha(F/name)==digest for name,digest in old.items())
for name in ('cpu-transition-results.json','cpu-aggregate-integration.json','cpu-output-results.json','cpu-source-results.json','cpu-source-aggregate.json','cpu-world-fixture.json','cpu-runtime-fixture.json','generic-budget-results.json','generic-guards-results.json'):
 result=json.loads((P/name).read_bytes().decode('utf-8-sig'));assert result['status'].startswith('PASS'),(name,result)
files=[]
for path in sorted(P.rglob('*')):
 if not path.is_file():continue
 rel=path.relative_to(P)
 if any(part.startswith(('offline.git','__pycache__','cpu-world-fixture-','cpu-source-','cpu-owner-','cpu-async-output-')) for part in rel.parts):continue
 if rel.as_posix()=='frozen-inventory.json':continue
 files.append(dict(path=rel.as_posix(),sha256=sha(path),bytes=path.stat().st_size))
(P/'frozen-inventory.json').write_text(json.dumps(dict(status='FROZEN_NOT_ADMITTED',source='c836df19793e420982bb4aa7b4a0428380126c82',base='b9d7edeb7f18d7ca2192f018016d4126f1910f91',r2_unchanged=True,r2_hashes=old,files=files,stage_access=False,engine_launched=False),indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(dict(status='FROZEN_NOT_ADMITTED',inventory_sha256=sha(P/'frozen-inventory.json'),files=len(files),r2_unchanged=True)))
