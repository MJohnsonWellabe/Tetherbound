"""Read-only UV ownership mask for an installed NPC; never edits its image/body.
Usage: body.glb output-dir min-y max-y max-abs-x min-z
All protected UV coverage is excluded, including overlap with face islands.
"""
import json,sys
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFilter
from npc_material_common import read_glb,single_primitive,accessor,albedo

source=Path(sys.argv[1]);out=Path(sys.argv[2]);bounds=list(map(float,sys.argv[3:7]));assert len(bounds)==4
out.mkdir(parents=True,exist_ok=True);assert not (out/'face-mask.png').exists(),'Preserve previous mask'
g,b=read_glb(source);p,pos,uv,idx=single_primitive(g,b);original,mat,tex,img=albedo(g,b,p)
lo,hi,mx,mz=bounds;sk=g['skins'][0];head=next(i for i,n in enumerate(sk['joints']) if g['nodes'][n]['name']=='Head')
a=p['attributes'];weights=accessor(g,b,a['WEIGHTS_0']);joints=accessor(g,b,a['JOINTS_0'])
hw=(weights*(joints==head)).sum(axis=1)
region=(hw>.2)&(pos[:,1]>=lo)&(pos[:,1]<=hi)&(np.abs(pos[:,0])<=mx)&(pos[:,2]>=mz)
# A triangle crossing a wardrobe/neck boundary is protected in its entirety.
chosen=region[idx].all(axis=1);assert chosen.sum()>20,'Insufficient measured face coverage'
w,h=original.size;faces=Image.new('L',(w,h));protected=Image.new('L',(w,h));fd=ImageDraw.Draw(faces);pd=ImageDraw.Draw(protected)
assert uv.min()>=-.0001 and uv.max()<=1.0001,'Only unwrapped single-tile original UVs supported'
for selected,tri in zip(chosen,idx):
    points=[(float(uv[v,0]*(w-1)),float(uv[v,1]*(h-1))) for v in tri]
    (fd if selected else pd).polygon(points,fill=255)
rgba=np.asarray(original);rgb=rgba[:,:,:3].astype(float)
# Conservative original-skin eligibility; preserve eyes, hair/beard, mask and hat.
skin=(rgb[:,:,0]>135)&(rgb[:,:,1]>90)&(rgb[:,:,2]>65)&(rgb[:,:,2]>rgb[:,:,0]*.47)&(rgb[:,:,0]>rgb[:,:,1]*1.13)&(rgb[:,:,1]>rgb[:,:,2]*1.05)
safe=(np.asarray(faces)>0)&(np.asarray(protected)==0)&skin
mask=Image.fromarray((safe*255).astype('uint8')).filter(ImageFilter.MinFilter(5))
assert np.count_nonzero(np.asarray(mask))>100,'No safe facial-skin region'
assert not np.any((np.asarray(mask)>0)&(np.asarray(protected)>0))
mask.save(out/'face-mask.png');faces.save(out/'face-uv-coverage.png');protected.save(out/'protected-uv-coverage.png');original.save(out/'original-albedo.png')
(out/'face-mask-report.json').write_text(json.dumps({'source':source.name,'scope':'Conservative facial skin only; no geometry or source image modification','bounds_m':{'min_y':lo,'max_y':hi,'max_abs_x':mx,'min_z':mz},'selected_face_triangles':int(chosen.sum()),'protected_triangles':int((~chosen).sum()),'safe_pixels':int(np.count_nonzero(np.asarray(mask))),'original_image_size':[w,h],'protected_uv_overlap_excluded':True,'non_skin_pixels_and_boundary_inset_excluded':True,'candidate_enabled':False,'requires_native_identity_and_seam_review':True},indent=2)+'\n')
print('Prepared safe facial-skin ownership mask:',int(chosen.sum()),'triangles;',int(np.count_nonzero(np.asarray(mask))),'pixels')
