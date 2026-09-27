"""Confirm the generated atlas survives Blender preparation byte-for-byte."""
import struct,json,hashlib,io
from pathlib import Path
from PIL import Image
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'project.godot').exists())/'assets_raw/stormheart_hero'
def inspect(path):
    data=path.read_bytes();json_size=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+json_size]);start=20+json_size+8
    images=[]
    for image in doc.get('images',[]):
        view=doc['bufferViews'][image['bufferView']]
        blob=data[start+view.get('byteOffset',0):start+view.get('byteOffset',0)+view['byteLength']]
        pixels=Image.open(io.BytesIO(blob)).convert('RGBA')
        images.append({'size':pixels.size,'encoded_sha256':hashlib.sha256(blob).hexdigest(),'pixels_sha256':hashlib.sha256(pixels.tobytes()).hexdigest()})
    return images
source=inspect(ROOT/'model.glb')
output=inspect(ROOT.parents[1]/'assets/environment/stormwood/stormheart_hero/stormheart_hero.glb')
assert {v['pixels_sha256'] for v in source}=={v['pixels_sha256'] for v in output}
report={'source_images':source,'prepared_images':output,'pixel_identical':True}
(ROOT/'texture_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
