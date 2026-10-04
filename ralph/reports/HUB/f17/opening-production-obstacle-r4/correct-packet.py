from pathlib import Path
import shutil, hashlib, json, difflib
root=Path('D:/tetherbound/redesign-hub')
initial=root/'.tmp/opening-production-obstacle-r4'
corrected=root/'.tmp/opening-production-obstacle-r4-corrected'
assert not corrected.exists()
H=lambda b:hashlib.sha256(b).hexdigest()
manifest=json.loads((initial/'freeze.json').read_bytes())
for name,pin in manifest['files_sha256'].items(): assert H((initial/name).read_bytes())==pin,name
shutil.copytree(initial,corrected,ignore=lambda folder,names:['independent'] if Path(folder)==initial else [])
cause=json.loads((corrected/'cause-and-constraints.json').read_bytes())
patch=b''
for name in cause['owned_paths']:
    old=(corrected/'originals'/name).read_bytes()
    new=(corrected/'proposal'/name).read_bytes()
    patch+=''.join(difflib.unified_diff(old.decode('utf-8').splitlines(True),new.decode('utf-8').splitlines(True),fromfile='a/'+name,tofile='b/'+name)).encode('utf-8')
assert b'--- a/tests/helpers/gate_a_npc_gather_segment.gd' not in patch
(corrected/'opening-production-obstacle.patch').write_bytes(patch)
cause['evidence_patch_correction']={'initial_patch_sha256':manifest['patch_sha256'],'fault':'Original decoded with Windows default encoding while proposal used UTF8, producing spurious gather em-dash hunk. Source raw hashes unchanged.','corrected_patch_sha256':H(patch),'method':'Both original and proposal decoded explicitly as UTF8 from raw bytes, preserving line endings and source identity. Full initial packet and independent SOURCEFAIL report retained separately.'}
(corrected/'cause-and-constraints.json').write_text(json.dumps(cause,indent=2)+'\n',encoding='utf-8')
seal=(corrected/'seal.py').read_bytes().decode('utf-8')
assert ".read_text().splitlines(True)" in seal
seal=seal.replace("out=root/'.tmp/opening-production-obstacle-r4'", "out=root/'.tmp/opening-production-obstacle-r4-corrected'")
seal=seal.replace(".read_text().splitlines(True)", ".read_bytes().decode('utf-8').splitlines(True)")
(corrected/'seal.py').write_bytes(seal.encode('utf-8'))
shutil.copyfile(__file__,corrected/'correct-packet.py')
pins={p.relative_to(corrected).as_posix():H(p.read_bytes()) for p in corrected.rglob('*') if p.is_file() and p!=corrected/'freeze.json'}
(corrected/'freeze.json').write_text(json.dumps({'parent':manifest['parent'],'state':'FROZEN_SOURCE_CANDIDATE','patch_sha256':H(patch),'files_sha256':pins},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'source':cause['after_source_sha256'],'patch':H(patch),'frozen_files':len(pins),'source_unchanged':True}))
