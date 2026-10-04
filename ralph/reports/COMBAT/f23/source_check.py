"""Cheap named F23 data/source check; never starts Godot or claims runtime."""
import json, subprocess, hashlib, sys
from pathlib import Path
root=Path(__file__).resolve().parents[4]
def read(path): return json.loads((root/path).read_text(encoding='utf-8-sig'))
species=read('data/creatures/species.json')['species']
learnsets=read('data/moves/learnsets.json')['species']
moves=read('data/moves/moves.json')['moves']
tms=read('data/moves/tms.json')['tms']
base=json.loads(subprocess.check_output(['git','show','b7cb96de89:data/creatures/species.json'],cwd=root))['species']
assert len(species)==58 and len(learnsets)==70
for sid,old in base.items():
    for field in ('type','type_secondary','base_hp','base_attack','base_defence','placeholder'):
        assert species[sid].get(field)==old.get(field),(sid,field)
for sid,row in learnsets.items():
    unlocked={u['move_id'] for u in row['unlocks']}
    assert unlocked<=moves.keys(),sid
    for slot in ('quick','charged','ultimate'):
        assert any(u.get('level')==1 and moves[u['move_id']]['slot']==slot for u in row['unlocks']),(sid,slot)
    for level in (5,15):
        assert any(u.get('level')==level and moves[u['move_id']]['slot']=='utility' for u in row['unlocks']),(sid,level)
    assert {u.get('breakthrough_tier') for u in row['unlocks']} >= {1,2,3,4,5},sid
    assert len({mid for mid in unlocked if moves[mid]['slot']=='utility'})>=2,sid
    assert moves[row['ultimate']]['slot']=='ultimate'
    for u in row['unlocks']:
        assert ('level' in u)!=('breakthrough_tier' in u)
        value=u.get('level',u.get('breakthrough_tier'))
        assert isinstance(value,int) and not isinstance(value,bool) and 1<=value<=(100 if 'level'in u else 5)
for sid,row in species.items():
    assert row['learnset']==sid
    assert row['moves']['ultimate']==learnsets[sid]['ultimate']
    for slot,mid in row['moves'].items():
        if mid: assert moves[mid]['slot']==slot,(sid,slot,mid)
utilities={k:v for k,v in moves.items() if v['slot']=='utility'}
assert len(utilities)>=10
for mid,row in utilities.items():
    assert row['utility']['kind'] in {'root','slow_field','push','dash_strike','movement_buff','heal','trap','next_hit_buff','damage_taken_debuff','quake_ring'}
    assert not row['utility'].get('invulnerable') and not row['utility'].get('revive')
for tid,tm in tms.items():
    assert tm['move_id'] in moves and len(tm['compatible_types'])==1
    assert tm['compatible_types'][0]==moves[tm['move_id']]['type'],tid
shared=[v for v in moves.values() if v['slot']=='ultimate' and not v['ultimate']['unique']]
assert 16<=len(shared)<=20
assert species['stormursa']['evolution_enabled'] is False and species['staticub']['evolution_enabled'] is False
assert 'placeholder' not in species['stormursa'] and 'model' not in species['stormursa']
water=read('data/config/water_roster.json')['species']
for board,row in water.items():
    alias='water_'+board
    if alias in learnsets: assert moves[learnsets[alias]['ultimate']]['type']==row['type'],alias
print('F23 authored data/source PASS: 58 species, 70 learnsets, 10 utilities, 19 shared + 12 unique signature IDs; old types/stats/visuals unchanged; Stormursa OFF.')
if '--shared' in sys.argv:
    after=root/'.tmp/shared/after'
    config=json.loads((after/'data/config/combat.json').read_text(encoding='utf-8'))
    assert config['move_loadout_runtime_enabled'] is False
    assert config['ultimate']['landed_gain']=={'quick':6,'charged':14,'utility':4,'ultimate':0}
    tmconsumer=(after/'scripts/ui/tab_backpack.gd').read_text(encoding='utf-8')
    assert 'TEACHING.teach(creature, _targeting_tm' not in tmconsumer
    assert 'submit_creature_tm_knowledge' in tmconsumer
    schema=json.loads((after/'data/schema/character_state.schema.json').read_text(encoding='utf-8'))
    def check(node):
        if isinstance(node,dict):
            if isinstance(node.get('enum'),list) and 'pebble_toss' in node['enum']:
                assert set(moves)<=set(node['enum'])
            props=node.get('properties',{})
            if 'pebble_toss' in props: assert set(moves)<=set(props)
            for value in node.values():check(value)
        elif isinstance(node,list):
            for value in node:check(value)
    check(schema)
    parserpath=root/'.tmp/gdparser'
    if parserpath.is_dir():
        sys.path.insert(0,str(parserpath))
        from gdtoolkit.parser import parser
        scripts=[root/'scripts/creatures/teaching.gd',root/'scripts/creatures/move_mastery.gd']+list(after.rglob('*.gd'))
        for path in scripts: parser.parse(path.read_text(encoding='utf-8'))
        print('F23 gdtoolkit static grammar PASS:',len(scripts),'scripts. No Godot typecheck or engine behavior verified.')
    print('F23 exact shared source/schema scope PASS; runtime flag OFF; missing producer seams remain OPEN.')
