"""Prepare the sole approved F17 village regional-bake source receipt."""
import hashlib,json,subprocess
from pathlib import Path
BASELINE = 'b2ea1455abdda7f2a7078ed1f148d5c40952c9fc'
APPROVED = '8ee152a47ee90f430a3e8aafb13d2b0d9c9ad1ea'
INPUTS = ['data/config/terrain_playground.json', 'data/config/vegetation.json', 'data/config/bands/band1_lower_meadows/vegetation.json', 'data/config/bands/band2_stone_and_root/vegetation.json', 'data/config/bands/band3_the_river_lock/vegetation.json', 'data/config/bands/band4_upper_meadows_ironwood/vegetation.json', 'data/config/bands/band5_stronghold_approach/vegetation.json']
def git_json(ref,path):
 return json.loads(subprocess.check_output(['git','show',ref+':'+path]))
def main():
 inputs={}
 for path in INPUTS:
  live=Path(path).read_bytes().replace(b'\r\n',b'\n')
  expected=subprocess.check_output(['git','show',APPROVED+':'+path]).replace(b'\r\n',b'\n')
  if live != expected: raise SystemExit('Refused source outside approved village snapshot: '+path)
  if path not in ['data/config/terrain_playground.json','data/config/bands/band1_lower_meadows/vegetation.json']:
   if git_json(BASELINE,path) != json.loads(live): raise SystemExit('Foreign source change: '+path)
  inputs['res://'+path]=hashlib.sha256(live).hexdigest()
 # These non-generator pose edits are also narrowly evidenced, never silently
 # rewriting quest transactions, harvest identities or counts.
 harvest='data/config/bands/band1_lower_meadows/harvest.json'
 old=git_json(BASELINE,harvest);new=json.loads(Path(harvest).read_text(encoding='utf-8'))
 old_row=[r for r in old['nodes'] if r['order']==1031];new_row=[r for r in new['nodes'] if r['order']==1031]
 if len(old_row)!=1 or len(new_row)!=1 or old_row[0]['at']!=[28,6] or new_row[0]['at']!=[30,8]:raise SystemExit('Berry tuple/identity refused')
 new_row[0]['at']=old_row[0]['at']
 if old!=new:raise SystemExit('Harvest non-pose change refused')
 objectives='data/progression/objectives.json'
 old=git_json(BASELINE,objectives);new=json.loads(Path(objectives).read_text(encoding='utf-8'))
 approved=git_json(APPROVED,objectives)
 if new!=approved:raise SystemExit('Objective source outside approved pose snapshot')
 changed=[]
 for index,(before,after) in enumerate(zip(old['main'],new['main'])):
  if before!=after:
   changed.append(index)
   after['beacon']['position']=before['beacon']['position']
 if changed!=[0,1,2,5,7,12,13,14,15,27] or old!=new:raise SystemExit('Objective non-pose change refused')
 receipt={'kind':'F17_reviewed_village_only','baseline':BASELINE,'approved_source':APPROVED,'regions':[[-1,-1],[-1,0],[0,-1],[0,0]],'inputs':inputs,'harvest_order1031':'position only [28,6] -> [30,8]','objective_position_only_indices':changed}
 output=Path('ralph/reports/HUB/f17/village-bake-scope.json')
 output.parent.mkdir(parents=True,exist_ok=True)
 output.write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
 print('Approved village-only input snapshot; receipt: '+str(output))
if __name__=='__main__':main()
