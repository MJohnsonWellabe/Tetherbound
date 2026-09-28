"""Restore portable glTF factors/primary vertex wear after Blender 4.2 export.

The Blender MixRGB/Vertex Color combination exported white COLOR_0 and actual
wear as COLOR_1, while dropping constant base colours. glTF uses COLOR_0 only.
This repairs JSON references and factors without touching geometry or buffers.
"""
import json, struct
from pathlib import Path

FACTORS={
 'Installed_Quaternius_WoodTrim':[1,1,1,1],
 'Weathered_bronze':[.24,.155,.078,1],
 'Worn_bronze_edges':[.29,.245,.16,1],
 'Dark_wet_iron':[.065,.095,.099,1],
 'Recessed_bronze_patina':[.07,.19,.17,1],
}

def repair(path):
    path=Path(path); raw=path.read_bytes()
    length=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+length]); tail=raw[20+length:]
    for material in data['materials']:
        material['pbrMetallicRoughness']['baseColorFactor']=FACTORS[material['name']]
    for mesh in data['meshes']:
        for primitive in mesh['primitives']:
            attrs=primitive['attributes']
            if 'COLOR_1' in attrs:
                attrs['COLOR_0']=attrs.pop('COLOR_1')
    payload=json.dumps(data,separators=(',',':')).encode()
    payload+=b' '*((-len(payload))%4)
    path.write_bytes(struct.pack('<III',0x46546c67,2,20+len(payload)+len(tail))+
                    struct.pack('<II',len(payload),0x4e4f534a)+payload+tail)
    return path.name

if __name__=='__main__':
    for path in Path(__file__).resolve().parents[1].glob('*.glb'):
        print(repair(path))
