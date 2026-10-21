# usage: cb_recipe.py out.json roll
import importlib.util, json, struct, hashlib, re, sys
spec=importlib.util.spec_from_file_location('au','tools/art_pipeline/author_f36_pose_profiles.py'); AU=importlib.util.module_from_spec(spec); spec.loader.exec_module(AU)
spec2=importlib.util.spec_from_file_location('pp','tools/art_pipeline/f36_pose_postpass.py'); PP=importlib.util.module_from_spec(spec2); spec2.loader.exec_module(PP)
out, roll = sys.argv[1], float(sys.argv[2])
model='res://assets/creatures/tetherbound/cannonback/candidate_regen/models/creature_cannonback_regen.glb'
path=model[6:]; raw=open(path,'rb').read()
uid=re.search(r'^uid="([^"]+)"$', open(path+'.import').read(), re.M).group(1)
n=struct.unpack_from('<I',raw,12)[0]; g=json.loads(raw[20:20+n]); b=raw[20+n+8:]
bones,rig,binds=AU.rig_contracts(g,b)
text=PP.LIVE.read_text(); live=json.loads(text); row=live['species']['cannonback']
row.update({'model':model,'source_sha256':hashlib.sha256(raw).hexdigest(),'resource_uid':uid,'rig_contract':rig,'bind_contract':binds,'bones':bones})
m=re.compile(r'\n    "cannonback": ').search(text, text.index('\n  "species": {'))
a,e=PP.value_span(text, m.end()); text=text[:a]+json.dumps(row)+text[e:]
PP.TOPPLE_ROLL['cannonback']=roll; PP.HIT_STYLE['cannonback']='recoil'
open(out,'w').write(PP.patch_topple(text,['cannonback'])); print('ok', out, len(bones))
