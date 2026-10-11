"""Prepare the pinned reviewed F17 village regional-bake source receipt."""
import hashlib,json,subprocess
from pathlib import Path
BASELINE = 'b2ea1455abdda7f2a7078ed1f148d5c40952c9fc'
ORIGINAL_APPROVED = '8ee152a47ee90f430a3e8aafb13d2b0d9c9ad1ea'
REVIEWED = 'd5ab7d73b31cdd5a24cd45501c980bd4aa553687'
INPUTS = ['data/config/terrain_playground.json', 'data/config/vegetation.json', 'data/config/bands/band1_lower_meadows/vegetation.json', 'data/config/bands/band2_stone_and_root/vegetation.json', 'data/config/bands/band3_the_river_lock/vegetation.json', 'data/config/bands/band4_upper_meadows_ironwood/vegetation.json', 'data/config/bands/band5_stronghold_approach/vegetation.json']

def git_source(ref,path):
 return subprocess.check_output(['git','show',ref+':'+path]).replace(b'\r\n',b'\n')

def git_json(ref,path):
 return json.loads(git_source(ref,path))

def reviewed_source(path):
 live=Path(path).read_bytes().replace(b'\r\n',b'\n')
 if live!=git_source(REVIEWED,path):raise SystemExit('Refused source outside reviewed shipping snapshot: '+path)
 return live

def verify_berry_anchor(original,reviewed):
 old_rows=[r for r in original['layer_anchors']['bushes'] if r.get('at')==[-8.5,-25]]
 new_rows=[r for r in reviewed['layer_anchors']['bushes'] if r.get('at')==[-8.5,-25]]
 if len(old_rows)!=1 or len(new_rows)!=1:raise SystemExit('Berry Field anchor identity refused')
 old=old_rows[0];new=new_rows[0]
 shrub='res://assets/environment/stylized_nature/Bush_Common.gltf'
 fern='res://assets/environment/stylized_nature/Fern_1.gltf'
 if old.get('models')!=[shrub] or old.get('model_scale')!={shrub:0.4} or new.get('models')!=[fern] or new.get('model_scale')!={fern:0.4}:raise SystemExit('Berry Field model/scale change refused')
 for row in [old,new]:
  if row.get('radius')!=3.2 or row.get('count')!=10 or row.get('cleared_by_clearings') is not False:raise SystemExit('Berry Field placement/count change refused')
  if not isinstance(row.get('_why'),str):raise SystemExit('Berry Field rationale missing')
 # Restore only the three reviewed fields, then compare the ENTIRE source.
 # No ignored keys, anchor reordering, new models, or other placement edits.
 for field in ['models','model_scale','_why']:new[field]=old[field]
 if original!=reviewed:raise SystemExit('Foreign vegetation change outside reviewed Berry Field anchor')

def main():
 inputs={}
 for path in INPUTS:
  live=Path(path).read_bytes().replace(b'\r\n',b'\n')
  band1=path=='data/config/bands/band1_lower_meadows/vegetation.json'
  expected=git_source(REVIEWED if band1 else ORIGINAL_APPROVED,path)
  if live != expected: raise SystemExit('Refused source outside approved village snapshot: '+path)
  if band1:verify_berry_anchor(git_json(ORIGINAL_APPROVED,path),json.loads(live))
  if path not in ['data/config/terrain_playground.json','data/config/bands/band1_lower_meadows/vegetation.json']:
   if git_json(BASELINE,path) != json.loads(live): raise SystemExit('Foreign source change: '+path)
  inputs['res://'+path]=hashlib.sha256(live).hexdigest()
 # Retain the original approval's pose-only audits against its exact snapshot.
 # Current shipping sources are separately byte-pinned to the reviewed commit;
 # their already reviewed visual/input edits are not recast as pose-only edits.
 non_generator_sources={}
 harvest='data/config/bands/band1_lower_meadows/harvest.json'
 non_generator_sources['res://'+harvest]=hashlib.sha256(reviewed_source(harvest)).hexdigest()
 old=git_json(BASELINE,harvest);new=git_json(ORIGINAL_APPROVED,harvest)
 old_row=[r for r in old['nodes'] if r['order']==1031];new_row=[r for r in new['nodes'] if r['order']==1031]
 if len(old_row)!=1 or len(new_row)!=1 or old_row[0]['at']!=[28,6] or new_row[0]['at']!=[30,8]:raise SystemExit('Berry tuple/identity refused')
 new_row[0]['at']=old_row[0]['at']
 if old!=new:raise SystemExit('Harvest non-pose change refused')
 objectives='data/progression/objectives.json'
 non_generator_sources['res://'+objectives]=hashlib.sha256(reviewed_source(objectives)).hexdigest()
 old=git_json(BASELINE,objectives);new=git_json(ORIGINAL_APPROVED,objectives)
 changed=[]
 for index,(before,after) in enumerate(zip(old['main'],new['main'])):
  if before!=after:
   changed.append(index)
   after['beacon']['position']=before['beacon']['position']
 if changed!=[0,1,2,5,7,12,13,14,15,27] or old!=new:raise SystemExit('Objective non-pose change refused')
 receipt={'kind':'F17_reviewed_village_only','baseline':BASELINE,'approved_source':REVIEWED,'original_approved_source':ORIGINAL_APPROVED,'regions':[[-1,-1],[-1,0],[0,-1],[0,0]],'inputs':inputs,'berry_field_change':'Only the anchor at [-8.5,-25]: Bush_Common -> Fern_1, matching 0.4 scale key and authored rationale; all other vegetation fields unchanged.','non_generator_sources':non_generator_sources,'original_harvest_order1031':'Original approval: position only [28,6] -> [30,8]; current shipping harvest is separately pinned in full.','original_objective_position_only_indices':changed}
 output=Path('ralph/reports/HUB/f17/village-bake-scope.json')
 output.parent.mkdir(parents=True,exist_ok=True)
 output.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('Approved village-only input snapshot; receipt: '+str(output))
if __name__=='__main__':main()
