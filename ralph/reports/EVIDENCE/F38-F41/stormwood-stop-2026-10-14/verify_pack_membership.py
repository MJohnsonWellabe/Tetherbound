from pathlib import Path
import hashlib,json,struct
R=Path(__file__).resolve().parent
# Load only read/query function definitions and constants; never run preparation.
prefix=(R/'prepare_source.py').read_text().split('before,base_objects=tree(OLD)')[0]
scope={'__file__':str(R/'prepare_source.py')};exec(compile(prefix,'prepare_source_query_functions','exec'),scope)
tree,git=scope['tree'],scope['git'];old,target=scope['OLD'],scope['TARGET']
before,base=tree(old);after,required=tree(target)
oldmat=json.loads((R/'shared/source-contract-before.json').read_bytes())['materialize']
materialize=json.loads((R/'shared/source-contract.json').read_bytes())['materialize']
oldparent=git('rev-parse',old+'^').decode().strip();parent=git('rev-parse',target+'^').decode().strip()
base=(base-{oid for mode,oid in before.values()})|{before[p][1] for p in oldmat}|{old,oldparent}
required=(required-{oid for mode,oid in after.values()})|{after[p][1] for p in materialize}|{target,parent,old,oldparent}
expected=required-base
pack=(R/'source.pack').read_bytes();packsha=pack[-20:]
assert hashlib.sha1(pack[:-20]).digest()==packsha
idxpath=R/'offline-native.git/objects/pack'/('pack-'+packsha.hex()+'.idx');idx=idxpath.read_bytes()
assert idx[:8]==b'\xfftOc\x00\x00\x00\x02'
assert hashlib.sha1(idx[:-20]).digest()==idx[-20:]
assert idx[-40:-20]==packsha
count=struct.unpack('>I',idx[1028:1032])[0]
actual={idx[1032+20*i:1052+20*i].hex() for i in range(count)}
assert actual==expected and len(actual)==count==72
assert struct.unpack('>I',pack[8:12])[0]==count
report={'status':'PASS','expected_objects':len(expected),'packed_objects':count,'exact_object_set':True,'pack_sha256':hashlib.sha256(pack).hexdigest(),'index_sha256':hashlib.sha256(idx).hexdigest(),'expected_object_set_sha256':hashlib.sha256(('\n'.join(sorted(expected))+'\n').encode()).hexdigest(),'native_access':False,'limitation':'Delta closure relies on exact reviewed b9 baseline; no fresh native availability claim.'}
(R/'cpu-pack-membership.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
