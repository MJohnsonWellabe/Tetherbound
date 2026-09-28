"""New-UV Galecrest colourways; writes only beside this script.

Use the repository's GLB/UV anatomy rasterizer directly, not its legacy species
lookup. No old texture, quantization, denoising, random noise or image API.
"""
from pathlib import Path
import hashlib
import io
import json
import sys
import numpy as np
from PIL import Image

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
ROOT = next(p for p in Path(__file__).resolve().parents if (p/'project.godot').is_file())
OUT = args.out.resolve()
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = args.source.resolve()
sys.path.insert(0, str(ROOT / 'tools'))
from creature_anatomy_maps import read_glb, accessor, mesh_arrays, rasterise
from repaint_creature_textures import rgb_to_hsv, hsv_to_rgb


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def smooth(lo, hi, values):
    t = np.clip((values-lo)/(hi-lo), 0, 1)
    return t*t*(3-2*t)


source_hash = digest(SOURCE)
gltf, binary = read_glb(str(SOURCE))
assert len(gltf['meshes']) == 1 and len(gltf['meshes'][0]['primitives']) == 1
primitive = gltf['meshes'][0]['primitives'][0]
material = gltf['materials'][primitive['material']]
image_idx = gltf['textures'][material['pbrMetallicRoughness']['baseColorTexture']['index']]['source']
view = gltf['bufferViews'][gltf['images'][image_idx]['bufferView']]
offset = view.get('byteOffset', 0)
embedded = binary[offset:offset+view['byteLength']]
(OUT / 'source_embedded.jpg').write_bytes(embedded)
source_image = Image.open(io.BytesIO(embedded)).convert('RGB')
source_image.save(OUT / 'ordinary.png')
assert source_image.width == source_image.height
size = source_image.width
source_pixels = np.asarray(source_image).copy()
rgb = source_pixels.astype(np.float32)/255
h, s, v = rgb_to_hsv(rgb)

positions, normals, uv, triangles = mesh_arrays(gltf, binary)
pos_map, nrm_map, valid = rasterise(positions, normals, uv, triangles, size)
lo, hi = positions.min(0), positions.max(0)
unit = np.clip((pos_map-lo)/(hi-lo), 0, 1)

# Read the NEW custom rig's influences. These supplement spatial predicates
# so a distal tail or foot cannot receive wing-tip colour through the UV atlas.
attrs = primitive['attributes']
joints = accessor(gltf, binary, attrs['JOINTS_0']).astype(int)
weights = accessor(gltf, binary, attrs['WEIGHTS_0'])
weight_type = gltf['accessors'][attrs['WEIGHTS_0']]['componentType']
if weight_type == 5121:
    weights /= 255
elif weight_type == 5123:
    weights /= 65535
joint_names = [gltf['nodes'][idx]['name'] for idx in gltf['skins'][0]['joints']]
channels = np.zeros((len(positions), 3))
for vertex in range(len(positions)):
    for index, weight in zip(joints[vertex], weights[vertex]):
        name = joint_names[index]
        if name.startswith('wing_'):
            channels[vertex, 0] += weight
        if name == 'head':
            channels[vertex, 1] += weight
        if name.startswith(('foot_', 'leg_lower_')):
            channels[vertex, 2] += weight
_, anatomy, valid_weights = rasterise(positions, channels, uv, triangles, size)
assert np.array_equal(valid, valid_weights)
wing, head, lower_leg = [anatomy[..., i] for i in range(3)]

# Source face/body axes are measured from this mesh; Y is glTF height.
lateral = np.abs(pos_map[..., 0]) / max(abs(lo[0]), abs(hi[0]))
height = unit[..., 1]
head_warm = (head > .15) & (h >= 12) & (h <= 66) & (s > .23) & (v > .12)
beak_and_eye_outline = (head > .20) & (v < .36)
feet = (lower_leg > .12) | (height < .25)
dark_detail = v < .14
face_guard = np.maximum(smooth(.02, .30, head),
    smooth(.56, .66, height) * (1-smooth(.18, .25, lateral)))
foot_guard = np.maximum(smooth(.10, .60, lower_leg), 1-smooth(.20, .36, height))
protected = valid & ((face_guard >= .999) | (foot_guard >= .999) | (v < .07))
feather = valid.astype(np.float32) * (1-face_guard) * (1-foot_guard) * smooth(.07, .17, v)
wing_anatomy = smooth(.08, .60, wing) * smooth(.30, .42, height)
tip_mask = feather * wing_anatomy * smooth(.48, .70, lateral)
alpha_mask = feather * wing_anatomy * smooth(.26, .50, lateral)

# Deep storm slate keeps a smooth monotonic luminance transfer. No pixel
# smoothing or banding; the source quills, feather edges and fine shadows remain.
slate_v = .66 * np.power(v, .78)
slate_rgb = hsv_to_rgb(np.full_like(h, 217), np.clip(.27 + s*.18, .27, .44), slate_v)
shiny_rgb = rgb*(1-feather[..., None]) + slate_rgb*feather[..., None]
# Electric cyan is spatially confined to distal wing feathers, preserving
# painted light/dark separation through a separate smooth value transfer.
cyan_rgb = hsv_to_rgb(np.full_like(h, 190), np.full_like(s, .57), .34 + .63*v)
shiny_rgb = shiny_rgb*(1-tip_mask[..., None]) + cyan_rgb*tip_mask[..., None]

# Alpha retains the ordinary ivory torso/crest and warm eye, deepening only
# the wing field. The alpha design's larger blue extent begins in the forewing.
alpha_rgb_target = hsv_to_rgb(np.full_like(h, 219), np.full_like(s, .68), v*.88)
alpha_rgb = rgb*(1-alpha_mask[..., None]) + alpha_rgb_target*alpha_mask[..., None]

# Four-pixel surface padding only outside covered UV triangles avoids
# old-colour gutters entering mipmaps. Surface pixels are never filtered.
outputs = {}
for label, candidate in [('shiny', shiny_rgb), ('alpha', alpha_rgb)]:
    pixels = np.clip(np.rint(candidate*255), 0, 255).astype(np.uint8)
    covered = valid.copy()
    for step in range(4):
        previous = np.pad(covered, 1)
        colour_previous = np.pad(pixels, ((1,1),(1,1),(0,0)), mode='edge')
        for dy, dx in [(0,-1),(0,1),(-1,0),(1,0),(-1,-1),(-1,1),(1,-1),(1,1)]:
            neighbour = previous[1+dy:1+dy+size,1+dx:1+dx+size]
            fill = ~covered & neighbour
            pixels[fill] = colour_previous[1+dy:1+dy+size,1+dx:1+dx+size][fill]
            covered[fill] = True
    pixels[protected] = source_pixels[protected]
    assert np.array_equal(pixels[protected], source_pixels[protected])
    Image.fromarray(pixels).save(OUT / (label+'.png'))
    outputs[label] = pixels

for name, mask in [('surface',valid), ('protected',protected), ('wing',wing_anatomy),
                   ('shiny_distal_tips',tip_mask), ('alpha_wings',alpha_mask)]:
    Image.fromarray(np.uint8(np.clip(mask,0,1)*255)).save(OUT / ('mask_'+name+'.png'))
np.savez_compressed(OUT/'new_uv_anatomy.npz', unit=unit.astype(np.float32),
    wing=wing.astype(np.float32),head=head.astype(np.float32),lower_leg=lower_leg.astype(np.float32),
    valid=valid,source_glb_sha256=source_hash)

stats = {}
for name, pixels in [('ordinary', source_pixels), *outputs.items()]:
    value = pixels.max(-1)/255
    stats[name] = {'sha256':digest(OUT/(name+'.png')),
        'surface_value_percentiles':np.percentile(value[valid],[10,50,90]).round(4).tolist(),
        'protected_pixels_changed':int(np.count_nonzero(np.any(pixels[protected] != source_pixels[protected],axis=-1))),
        'surface_pixels_changed':int(np.count_nonzero(np.any(pixels[valid] != source_pixels[valid],axis=-1)))}
assert digest(SOURCE) == source_hash, 'Source changed during preparation; rerun against current source.'
assert np.array_equal(np.asarray(Image.open(OUT/'ordinary.png')), source_pixels)
report = {'source_glb_sha256':source_hash,'source_embedded_sha256':digest(OUT/'source_embedded.jpg'),
    'dimensions':[size,size],'triangles':int(len(triangles)),
    'anatomy_source':'rigged.glb position, UV, JOINTS_0 and WEIGHTS_0; direct repository rasterise() call',
    'surface_pixels':int(valid.sum()),'protected_pixels':int(protected.sum()),
    'tip_pixels_above_half':int((tip_mask>.5).sum()),'alpha_pixels_above_half':int((alpha_mask>.5).sum()),
    'distal_tip_pixels_left':int(((tip_mask>.5)&(pos_map[...,0]<0)).sum()),
    'distal_tip_pixels_right':int(((tip_mask>.5)&(pos_map[...,0]>0)).sum()),
    'source_bounds':[lo.tolist(),hi.tolist()],'outputs':stats,
    'ordinary_decoded_pixels_identical':True,'source_glb_unchanged':True,
    'finish':'None. No quantization, posterization, denoising, resampling or noise added.',
    'validation_limit':'Texture-space inspection only. Native variant material routing and 3D day/night acceptance remain pending.'}
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
design = json.loads((ROOT/'data/creatures/shiny_colourways.json').read_text())['species']['galecrest']
(OUT/'established-design.json').write_text(json.dumps(design,indent=2)+'\n')
print(json.dumps(report,indent=2))
