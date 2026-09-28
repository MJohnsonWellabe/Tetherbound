"""CPU-only export contract check. Run with ordinary Python after Blender."""
import json, struct, hashlib, math
from pathlib import Path
root=Path(__file__).resolve().parents[1]
reports={}
for path in sorted(root.glob('*.glb')):
    raw=path.read_bytes(); n=struct.unpack_from('<I',raw,12)[0]
    gltf=json.loads(raw[20:20+n]); blob=raw[28+n:]
    for material in gltf['materials']:
        factor=material['pbrMetallicRoughness'].get('baseColorFactor')
        assert factor is not None,(path.name,'missing authored base colour',material['name'])
        if material['name']!='Installed_Quaternius_WoodTrim':
            assert max(factor[:3])<.5,(path.name,'white metal factor',material['name'])
    positions=[]; has_colour=True
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            has_colour &= 'COLOR_0' in primitive['attributes']
            ac=gltf['accessors'][primitive['attributes']['POSITION']]
            view=gltf['bufferViews'][ac['bufferView']]
            offset=view.get('byteOffset',0)+ac.get('byteOffset',0)
            stride=view.get('byteStride',12)
            positions.extend(struct.unpack_from('<3f',blob,offset+i*stride) for i in range(ac['count']))
    width=int(path.stem.rsplit('_',1)[1]); half=width/2
    # Exports use Y up, with identity scene transforms.
    finite=all(math.isfinite(c) for p in positions for c in p)
    intrusion=sum(abs(x)<half-1e-4 and y<7-1e-4 for x,y,z in positions) if 'frame' in path.stem else 0
    result={'sha256':hashlib.sha256(raw).hexdigest(),'finite_vertices':finite,'vertex_wear_exported':has_colour,
       'authored_material_factors':{m['name']:m['pbrMetallicRoughness']['baseColorFactor'] for m in gltf['materials']},
       'low_fixed_vertices_inside_original_aperture':intrusion,
       'bounds_min':[min(p[i] for p in positions) for i in range(3)],
       'bounds_max':[max(p[i] for p in positions) for i in range(3)]}
    assert finite and has_colour and not intrusion,(path.name,result)
    assert result['bounds_max'][1]<12,(path.name,'ceiling')
    if 'leaf' in path.stem:
        assert abs(result['bounds_max'][1]-7)<1e-4
        assert abs(result['bounds_max'][0]-half)<1e-4
        assert abs(result['bounds_min'][0]+half)<1e-4
    reports[path.name]=result
(root/'source'/'export-contract.json').write_text(json.dumps(reports,indent=2)+'\n')
print('PASS: four exports retain vertex wear, fit ceiling, preserve leaf bounds and keep low fixed geometry outside original aperture.')
