from pathlib import Path
import json,math,hashlib,subprocess,shutil
from PIL import Image
repo=Path('D:/tetherbound/stormheart-validation')
shots=repo/'shots/stormheart-hero'
baseline=json.loads((shots/'before1080/manifest.json').read_text())
candidate=json.loads((shots/'living-corrected1080/manifest.json').read_text())
assert baseline['complete'] and candidate['complete']
assert baseline['resolution']==candidate['resolution']==[1920,1080]
assert baseline['stormheart_runtime']==candidate['stormheart_runtime']
def delta(a,b):
    if isinstance(a,list):return max([delta(x,y) for x,y in zip(a,b)] or [0])
    if isinstance(a,dict):return max([delta(a[k],b[k]) for k in a] or [0])
    if isinstance(a,(int,float)):return abs(a-b)
    return 0 if a==b else float('inf')
rows=[]
for a,b in zip(baseline['frames'],candidate['frames']):
    assert a['frame_id']==b['frame_id']
    row={'frame':a['frame_id'],'player_position_delta_m':math.dist(a['player_position'],b['player_position']),
        'camera_position_delta_m':math.dist(a['camera_position'],b['camera_position']),
        'camera_transform_component_max_delta':delta(a['camera_transform'],b['camera_transform']),
        'before_phase':a['stormwood_presentation'],'after_phase':b['stormwood_presentation'],'images':[]}
    for label in ['before1080','living-corrected1080']:
        path=shots/label/(a['frame_id']+'.png')
        image=Image.open(path)
        assert image.size==(1920,1080)
        row['images'].append({'variant':label,'file':str(path.relative_to(shots)),'resolution':image.size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    assert row['player_position_delta_m']<.01
    assert row['camera_position_delta_m']<.01
    assert row['camera_transform_component_max_delta']<.01
    assert row['before_phase']==row['after_phase']=='calm'
    rows.append(row)
asset=repo/'assets/environment/stormwood/stormheart_hero/stormheart_hero.glb'
report={'baseline_commit':'f122f5b0d6f01f645cfed25d3d0bfe332142f971','scope':'Six matched before/after production-camera frames. Visual asset replacement only; no gameplay acceptance or performance claim.',
    'renderer':candidate['rendering_method'],'adapter':candidate['adapter'],'resolution':candidate['resolution'],
    'source_asset_sha256':hashlib.sha256(asset.read_bytes()).hexdigest(),'appearance_files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in asset.parent.iterdir() if p.suffix in ['.gd','.gdshader','.tscn']},'fixed_fps':60,'seed':44719,
    'tree_gameplay_contract_unchanged':True,'tree_gameplay_contract':candidate['stormheart_runtime'],'frames':rows,
    'operator_inspection':'All six corrected1920x1080 frames inspected individually. Split and root arch retained; bark warmer with clearer grain; living leaf masses are visible at320m andGlassField. Canopy remains pale/patchy and original angular crown fragments remain; close bark is still faceted and vertically streaked. Independent art judgment required. Existing pylon blocks120m centerline; verge exposes unchanged abstract dark rings. Lane architecture, electrical VFX and environment palette are unchanged.',
    'capture_correction':'Initial1920x1061 windowed baseline retained separately as diagnostic. Matched accepted-raster pair uses native fullscreen1920x1080; no image resizing.',
    'blind_visual_verdict':'Not yet performed by this preparation agent.'}
(shots/'living_finish_pair_audit.json').write_text(json.dumps(report,indent=2)+'\n')
patch=subprocess.check_output(['git','diff','--','scripts/world/stormheart_tree.gd'],cwd=repo)
(shots/'visual_overlay.patch').write_bytes(patch)
shutil.copy2(repo/'tools/_capture_stormheart_hero_compare.gd',shots/'capture_probe.gd')
print(json.dumps({'matched_frames':len(rows),'max_camera_delta_m':max(r['camera_position_delta_m'] for r in rows),'gameplay_contract':candidate['stormheart_runtime']},indent=2))
