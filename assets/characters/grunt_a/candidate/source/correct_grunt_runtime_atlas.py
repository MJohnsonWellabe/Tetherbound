import copy,io,json,shutil
from pathlib import Path
import numpy as np
from PIL import Image
from npc_material_common import read_glb,single_primitive,albedo,write_glb
base=Path(__file__).parent;root=Path('C:/CodexTemp/tetherbound-native-service')
cfg=json.loads((root/'data/config/art.json').read_text())
for subject in ['grunt','grunt_a','grunt_b','grunt_c']:
 out=base/subject;asset=root/f'assets/characters/{subject}/candidate'
 backup=out/'candidate-before-runtime-atlas-correction';assert not backup.exists();shutil.copytree(asset,backup)
 original=root/cfg[subject]['model'].removeprefix('res://');g,b=read_glb(original);original_g=copy.deepcopy(g)
 p,*_=single_primitive(g,b);embedded,mat,tex,img=albedo(g,b,p)
 runtime=Image.open(original.with_name(original.stem+'_texture_0.png')).convert('RGBA')
 vg,vb=read_glb(out/'native-face-material-v1.glb');vp,*_=single_primitive(vg,vb);vi,*_=albedo(vg,vb,vp)
 generation=json.loads((out/'face-material-generation.json').read_text());mask=np.asarray(Image.open(out/generation['mask_directory']/'face-mask.png').convert('L'))>0
 ep=np.asarray(embedded).astype(int);rp=np.asarray(runtime).astype(int);delta=np.asarray(vi).astype(int)-ep
 assert not np.any(np.any(delta!=0,axis=2)&~mask)
 result=np.clip(rp+delta,0,255).astype('uint8');result[:,:,3]=rp[:,:,3].astype('uint8')
 assert np.array_equal(result[~mask],rp[~mask])
 payload=io.BytesIO();Image.fromarray(result).save(payload,format='PNG');png=payload.getvalue()
 binary=bytearray(b);binary.extend(b'\0'*((-len(binary))%4));view=len(g['bufferViews']);g['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(png)});binary.extend(png)
 imidx=len(g['images']);g['images'].append({'name':'NativeFaceSkinRuntimeAlbedoV2','mimeType':'image/png','bufferView':view})
 texture=copy.deepcopy(g['textures'][tex]);texture['source']=imidx;ti=len(g['textures']);g['textures'].append(texture);g['materials'][mat]['pbrMetallicRoughness']['baseColorTexture']['index']=ti
 for key in ['meshes','nodes','skins','animations','accessors','samplers']:assert g.get(key)==original_g.get(key)
 dest=out/'native-face-material-v2.glb';assert not dest.exists();write_glb(dest,g,binary)
 cg,cb=read_glb(dest);cp,*_=single_primitive(cg,cb);ci,*_=albedo(cg,cb,cp);assert np.array_equal(np.asarray(ci)[~mask],rp[~mask]) and cb[:len(b)]==b
 (out/'native-face-material-v2-albedo.png').write_bytes(png)
 proof=json.loads((out/'face-material-preservation-v1.json').read_text());proof.update(scope='Same installed NPC geometry and material parameters; source albedo is the authored runtime extracted PNG, not its older embedded GLB image',protected_pixels_basis='Current-main authored '+original.with_name(original.stem+'_texture_0.png').relative_to(root).as_posix(),runtime_atlas_outside_face_mask_identical=True,original_embedded_albedo_matches_runtime=False,original_embedded_albedo_max_difference=int(np.max(np.abs(ep-rp))),local_correction='Reapply the same guarded service task conservative face-only delta to the current authored runtime atlas. No additional generation.',changed_pixels=int(np.any(result!=rp,axis=2).sum()))
 (out/'face-material-preservation-v2.json').write_text(json.dumps(proof,indent=2)+'\n')
 (out/'face-material-selection.json').write_text(json.dumps({'selected':'native-face-material-v2.glb','proof':'face-material-preservation-v2.json','before_evidence_version':'v1','after_evidence_version':'v2','rejected_v1_reason':'Embedded GLB atlas differed from current-main extracted runtime PNG; v1 reset authored clothing palette outside face mask. Preserve v1 evidence outside Git; select corrected authored atlas.', 'additional_submissions':0},indent=2)+'\n')
 shutil.copy2(dest,asset/f'models/{subject}_native_face.glb');shutil.copy2(out/'face-material-preservation-v2.json',asset/'source/preservation.json');shutil.copy2(Path(__file__),asset/'source'/Path(__file__).name)
 print(subject,'runtime atlas protection restored, OFF, no new submission')
