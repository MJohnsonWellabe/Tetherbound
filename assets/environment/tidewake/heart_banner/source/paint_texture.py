"""Derive muted blue cloth from installed Quaternius cloth; draw board crest.
Run with Python + Pillow/numpy from any checkout. No reference pixels copied.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / 'project.godot').exists())
src = ROOT / 'assets/props/quaternius_fantasy/T_Trim_Cloth_BaseColor.png'
im = Image.open(src).convert('RGB')
# Plain installed teal fabric field only; exclude all pictograms/trim.
w,h=im.size
field=im.crop((int(w*.27),int(h*.018),int(w*.58),int(h*.225)))
field=field.resize((1024,2048),Image.Resampling.BICUBIC)
lum=np.asarray(field,dtype=float).mean(axis=2)
lum=np.clip(lum/max(lum.mean(),1),.76,1.18)
y,x=np.indices(lum.shape)
weave=1+.016*np.sin(x*np.pi/2)+.013*np.sin(y*np.pi/3)
lum*=weave
mask=Image.new('L',(1024,2048),0);d=ImageDraw.Draw(mask)
# Large diamond, paired arms and lower diamond: the inspected board identity.
def polygon(points): d.polygon([(int(a*1024),int(b*2048)) for a,b in points],fill=255)
polygon([(0.50,.225),(.615,.38),(.50,.472),(.385,.38)])
polygon([(.29,.368),(.425,.482),(.375,.525),(.245,.418)])
polygon([(.71,.368),(.755,.418),(.625,.525),(.575,.482)])
polygon([(.50,.496),(.57,.552),(.50,.605),(.43,.552)])
blue=np.array([38,72,111.]);cream=np.array([226,214,183.])
m=np.asarray(mask,dtype=float)[...,None]/255
rgb=(blue*(1-m)+cream*m)*lum[...,None]
Image.fromarray(np.uint8(np.clip(rgb,0,255))).save(HERE.parent/'heart_banner_albedo.png')
(HERE/'texture_provenance.json').write_text(json.dumps({'source':str(src.relative_to(ROOT)).replace('\\','/'),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'method':'Plain teal fabric field crop [.27,.018,.58,.225], luminance retained, blue/cream recolour plus restrained original weave. New vector crest interprets inspected Veilfall banner and title mark. Reference pixels not copied.','texture_size':[1024,2048]},indent=2))
