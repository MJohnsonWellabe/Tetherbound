"""Cheap named content/source-risk check. Does not run or certify Godot."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[1]
cfg = json.loads(ROOT.joinpath('data/config/traits.json').read_text(encoding='utf-8'))
assert type(cfg.get('runtime_enabled')) is bool and cfg['runtime_enabled'] is False
assert len(cfg['traits']) == 30
counts = {rarity:0 for rarity in cfg['rarities']}
effects = set()
for id,row in cfg['traits'].items():
    assert row['rarity'] in counts
    assert 0 < abs(row['magnitude']) <= cfg['rarities'][row['rarity']]
    assert math.isfinite(row['magnitude'])
    assert row['seed_item'] == 'trait_seed_'+id
    assert bool(row['description'])
    counts[row['rarity']] += 1
    effects.add(row['effect'])
assert counts == {'common':12,'rare':10,'epic':8}
expectations = {}
for name,row in cfg['profiles'].items():
    weights = row['count_weights']
    assert len(weights) == 4 and all(w > 0 for w in weights)
    rarity_weights = row['rarity_weights']
    expectations[name] = {
        'expected_rolled_count':sum(i*w for i,w in enumerate(weights))/sum(weights),
        'expected_epic_fraction':rarity_weights[2]/sum(rarity_weights)}
names = ['ordinary','unusual','alpha','alpha_unusual']
for low,high in zip(names,names[1:]):
    assert expectations[low]['expected_rolled_count'] < expectations[high]['expected_rolled_count']
    assert expectations[low]['expected_epic_fraction'] < expectations[high]['expected_epic_fraction']
shared = ROOT/'.tmp/f30-authority'
manifest = json.loads(shared.joinpath('source-cut.json').read_text(encoding='utf-8'))
for row in manifest:
    for side in ['before','after']:
        source = shared.joinpath(side,row['path']).read_bytes()
        assert hashlib.sha256(source).hexdigest() == row[side+'_sha256']
    assert row['path'] == 'scripts/ui/altar_panel.gd' or ROOT.joinpath(row['path']).read_text(encoding='utf-8').encode('utf-8') == shared.joinpath('before',row['path']).read_bytes()
# Freeze the actual dispatched keys and source targets, preventing a data row
# from silently introducing an unimplemented scalar.
dispatch = ROOT.joinpath('scripts/combat/trait_effects.gd').read_text(encoding='utf-8')+ROOT.joinpath('scripts/world/trait_traversal.gd').read_text(encoding='utf-8')
for effect in effects: assert '"'+effect+'"' in dispatch, effect
patch_paths = {row['path'] for row in manifest}
assert {'scripts/creatures/creature_instance.gd','scripts/combat/combat_manager.gd',
        'scripts/player/fly_controller.gd','scripts/world/riding_controller.gd',
        'scripts/world/water_mounted_swim.gd','scripts/ui/combat_hud.gd',
        'scripts/ui/tab_creatures.gd','scripts/ui/altar_panel.gd'} <= patch_paths
test_source = ROOT.joinpath('tests/test_f30_traits.gd').read_text(encoding='utf-8')
assert 'extends "res://tests/test_case.gd"' in test_source and 'assert(' not in test_source
owned = [p for parent in ['scripts/creatures','scripts/combat','scripts/world','scripts/ui','data/config','tests','tools'] for p in ROOT.joinpath(parent).glob('*') if p.is_file() and ('trait' in p.name or p.name.startswith('f30_')) and p.suffix in ['.gd','.py','.json']]
output = {'check':'f30_source_check','result':'PASS','engine_executed':False,
          'rarity_counts':counts,'profiles':expectations,'shared_paths':len(manifest),
          'owned_hashes':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in owned}}
shared.joinpath('source-check.json').write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in output.items() if k!='owned_hashes'},indent=2))
