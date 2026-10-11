"""Original-body-preserving face albedo graft; never install service geometry.
Usage: original-body head-input retexture output.glb mask-dir report.json
Reject changed service UV topology. All decoded pixels outside safe mask match.
"""
import copy,io,json,sys
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
from npc_material_common import read_glb,single_primitive,uv_triangles,albedo,write_glb

body,head,ret,dest,maskdir,report=map(Path,sys.argv[1:7]);assert not dest.exists(),'Preserve previous candidate'
conservative='--conservative-blend' in sys.argv[7:]
g,b=read_glb(body);original=copy.deepcopy(g);hg,hb=read_glb(head);rg,rb=read_glb(ret)
assert uv_triangles(hg,hb)==uv_triangles(rg,rb),'FAIL original head UV/triangle mapping changed'
p,_,_,_=single_primitive(g,b);rp,_,_,_=single_primitive(rg,rb)
old,mat,tex,img=albedo(g,b,p);new,_,_,_=albedo(rg,rb,rp)
mask=Image.open(maskdir/'face-mask.png').convert('L');assert mask.size==old.size
assert np.array_equal(np.asarray(Image.open(maskdir/'original-albedo.png').convert('RGBA')),np.asarray(old)),'FAIL mask was prepared against a different installed albedo'
protected=Image.open(maskdir/'protected-uv-coverage.png').convert('L')
safe=np.asarray(mask)>0;assert safe.sum()>100 and not np.any(safe&(np.asarray(protected)>0))
new=new.resize(old.size,Image.Resampling.LANCZOS) if new.size!=old.size else new
oldpix=np.asarray(old);newpix=np.asarray(new)
# Feather only inward. Outside-mask RGBA bytes remain precisely original.
alpha=np.asarray(mask.filter(ImageFilter.GaussianBlur(24.0 if conservative else 1.0))).astype(float)/255
alpha[~safe]=0
if conservative:
 # Retexture skin tone is stronger than the installed identity palette.
 # Keep the same ownership mask, softly attenuate its edges and bound changes.
 alpha*=0.5
 newpix=np.clip(newpix.astype(float),oldpix.astype(float)-18,oldpix.astype(float)+18)
pixels=np.rint(oldpix.astype(float)*(1-alpha[:,:,None])+newpix.astype(float)*alpha[:,:,None]).astype('uint8')
pixels[:,:,3]=oldpix[:,:,3]
assert np.array_equal(pixels[~safe],oldpix[~safe]),'FAIL protected pixels changed'
changed=np.any(pixels!=oldpix,axis=2);assert changed.sum()>100 and not np.any(changed&~safe)
buf=io.BytesIO();Image.fromarray(pixels).save(buf,format='PNG');payload=buf.getvalue()
binary=bytearray(b);binary.extend(b'\0'*((-len(binary))%4));vi=len(g['bufferViews'])
g['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(payload)});binary.extend(payload)
ii=len(g['images']);g['images'].append({'name':'NativeFaceSkinAlbedo','mimeType':'image/png','bufferView':vi})
tt=copy.deepcopy(g['textures'][tex]);tt['source']=ii;ti=len(g['textures']);g['textures'].append(tt)
g['materials'][mat]['pbrMetallicRoughness']['baseColorTexture']['index']=ti
for name in ['meshes','nodes','skins','animations','accessors','samplers']:assert g.get(name)==original.get(name),name
assert g['bufferViews'][:len(original['bufferViews'])]==original['bufferViews']
assert bytes(binary[:len(b)])==b
materials=copy.deepcopy(g['materials']);materials[mat]['pbrMetallicRoughness']['baseColorTexture']['index']=tex;assert materials==original['materials']
write_glb(dest,g,binary)
# Verify the actual written candidate, not merely intermediate arrays.
check,cb=read_glb(dest);cp,_,_,_=single_primitive(check,cb);actual,_,_,_=albedo(check,cb,cp)
assert np.array_equal(np.asarray(actual)[~safe],oldpix[~safe])
assert cb[:len(b)]==b
for name in ['meshes','nodes','skins','animations','accessors','samplers']:assert check.get(name)==original.get(name)
albedo_output=dest.parent/(dest.stem+'-albedo.png');assert not albedo_output.exists(),'Preserve earlier albedo proof'
albedo_output.write_bytes(payload)
report.write_text(json.dumps({'scope':'Original installed NPC; only safe facial-skin albedo pixels changed','candidate_enabled':False,'service_head_triangle_uv_mapping_unchanged':True,'installed_geometry_uv_weights_nodes_skin_clips_unchanged':True,'original_binary_prefix_preserved':True,'original_material_parameters_normal_roughness_metallic_unchanged':True,'decoded_rgba_outside_face_mask_identical':True,'protected_uv_overlap_excluded':True,'changed_pixels':int(changed.sum()),'safe_pixels':int(safe.sum()),'image_size':list(old.size),'clips':len(g.get('animations',[])),'blend':'Inward 24-pixel Gaussian attenuation, half strength, service RGBA delta bounded to 18/255 before blending' if conservative else 'Inward 1-pixel feather with full service skin colour','requires_native_face_finish_identity_and_seam_review':True,'full_art_gate':False},indent=2)+'\n')
print('PASS original body/UV/rig/clips and protected pixels unchanged; face skin only; OFF')
