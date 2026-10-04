"""Non-engine F45 catalogue, shared-contract and grammar check. No Godot."""
import hashlib, json, os, pathlib, re, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0, str(pathlib.Path(os.environ['TEMP']) / 'tb-f45-gdtoolkit'))
from gdtoolkit.parser import parser
parser.disable_grammar_caching()
def read(path):
    return json.loads((root / path).read_text(encoding='utf-8-sig'))
def old(path):
    return json.loads(subprocess.check_output(['git', 'show', 'HEAD:' + path], cwd=root))
cfg = read('data/config/research.json')
base = read('data/creatures/species.json')['species']
water = read('data/config/water_roster.json')['species']
roster = dict(base, **{'water_' + k: v for k, v in water.items()})
assert set(cfg['species']) == set(roster)
assert cfg['runtime_enabled'] is False
assert cfg['maximum_transaction_receipts'] <= read('data/config/essence.json')['maximum_transaction_receipts']
types = {r['type']: r['id'] for r in read('data/schema/essences.json')}
count = 0
for species, row in cfg['species'].items():
    assert row['biome'] in cfg['biomes'] and len(row['tasks']) >= 3
    assert len({t['id'] for t in row['tasks']}) == len(row['tasks'])
    assert roster[species]['type'] in types
    for task in row['tasks']:
        assert task['kind'] in {'sight', 'cast', 'catch', 'defeat'}
        assert 5 <= task['reward_count'] <= 15 and 1 <= task['required'] <= 999
        if 'move' in task: assert task['move'] in roster[species]['moves'].values()
        count += 1
for path in ['data/schema/character_state.json', 'data/schema/character_state.schema.json']:
    before, after = old(path), read(path)
    if path.endswith('.schema.json'):
        assert before['required'] == after['required']
        before, after = before['properties'], after['properties']
    assert {k: after[k] for k in before} == before, 'existing F43/F44 carrier changed'
assert read('data/schema/character_state.json')['research'] == {'species': {}, 'event_receipts': [], 'titles': []}
assert 'redesign_character.research' in read('data/progression/flag_scopes.json')['durable_fields']
paths = [
 'scripts/creatures/research_log.gd', 'scripts/creatures/research_actions.gd',
 'scripts/ui/research_log_panel.gd', 'scripts/ui/tab_quest_log.gd',
 'scripts/data/redesign_state.gd', 'scripts/net/character_action_rules.gd',
 'scripts/net/character_action_delivery.gd', 'scripts/net/session.gd',
 'scripts/combat/encounter_director.gd', 'tests/test_research_log.gd']
for path in paths:
    text = (root / path).read_text(encoding='utf-8-sig')
    parser.parse(text)
    for target in re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)', text):
        assert (root / target).exists(), target
record_source = (root / 'scripts/net/character_record_rules.gd').read_text()
assert 'static func errors(' in record_source
adapter = (root / 'scripts/creatures/research_actions.gd').read_text()
for method in ['_game', '_authority_character', 'admitted_character_state', '_retained_host_wild_source']:
    assert 'func ' + method + '(' in (root / 'scripts/net/session.gd').read_text()
assert 'commit_host_action' in adapter
assert 'save_character_prepared' not in adapter and 'inventory.add' not in adapter
result = {'kind': 'non_engine_source_only', 'species': len(roster), 'tasks': count,
          'parsed_scripts': paths, 'runtime_enabled': False, 'checks': 'PASS',
          'limits': 'Pure Lark grammar only; no Godot type resolution, execution, persistence or ACK proof.'}
(root / 'ralph/reports/R3-F45/source-check.json').write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps(result))
