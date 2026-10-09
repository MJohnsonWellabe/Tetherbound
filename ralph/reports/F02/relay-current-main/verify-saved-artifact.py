import hashlib, json, math, struct, zipfile, subprocess
from pathlib import Path

import argparse
parser=argparse.ArgumentParser()
parser.add_argument('archive')
parser.add_argument('--source',required=True)
parser.add_argument('--main',required=True)
parser.add_argument('--run',required=True,type=int)
parser.add_argument('--artifact',required=True,type=int)
parser.add_argument('--output',required=True)
parser.add_argument('--repo',required=True)
args=parser.parse_args()
SOURCE=args.source
ARCHIVE=Path(args.archive)

def decode(value):
    if isinstance(value, list): return [decode(v) for v in value]
    if not isinstance(value, dict): return value
    if '$tb_float64' in value:
        assert len(value) == 1 and len(value['$tb_float64']) == 16
        result = struct.unpack('<d', bytes.fromhex(value['$tb_float64']))[0]
        assert math.isfinite(result)
        return result
    if '$tb_int64' in value:
        assert len(value) == 1
        return int(value['$tb_int64'])
    if '$tb_dictionary' in value:
        return {k: decode(v) for k, v in value['$tb_dictionary']}
    return {k: decode(v) for k, v in value.items()}

def document(raw):
    outer = json.loads(raw)
    if outer.get('format') == 'tetherbound-save':
        assert outer['codec_version'] == 1 and len(outer) == 3
        return decode(outer['payload'])
    return outer

with zipfile.ZipFile(ARCHIVE) as z:
    paths=[name for name in z.namelist() if name.endswith('/relay/receipt.json')]
    assert len(paths)==1
    base=paths[0][:-len('relay/receipt.json')]
    setup_paths=[name for name in z.namelist() if name.endswith('_generated_input/GENERATED_SETUP.json')]
    assert len(setup_paths)==1
    generated=setup_paths[0][:-len('GENERATED_SETUP.json')]
    relay = document(z.read(base + 'relay/receipt.json'))
    predecessor = document(z.read(base + 'warrens/receipt.json'))
    setup = document(z.read(generated + 'GENERATED_SETUP.json'))
    assert relay['commit'] == predecessor['commit'] == setup['source'] == SOURCE
    assert relay['boundary'] == 'relay' and predecessor['boundary'] == 'warrens'
    assert relay['input_mode'] == predecessor['input_mode'] == 'generated_fixture'
    assert relay['generated_origin'] == predecessor['generated_origin']
    assert relay['generated_origin']['provenance']['prior_earned_play'] is False
    assert relay['continuous_fresh_save'] is predecessor['continuous_fresh_save'] is False
    assert predecessor['kind'] == 'f49_generated_fixture_handoff'
    assert 'piece_proof' not in predecessor
    assert z.read(base + 'warrens/receipt.json') == z.read(generated + 'warrens/receipt.json')
    assert relay['predecessors'] == [{'boundary': 'warrens', 'receipt_sha256': hashlib.sha256(z.read(base + 'warrens/receipt.json')).hexdigest()}]
    files = 0
    for directory, receipt in [('relay', relay), ('warrens', predecessor)]:
        for name, expected in receipt['files_sha256'].items():
            assert hashlib.sha256(z.read(base + directory + '/save/' + name)).hexdigest() == expected
            files += 1
    before, after = predecessor['state'], relay['state']
    for key in ['character_id', 'world_id', 'reward_delivery_namespace', 'world_seed']:
        assert before[key] == after[key]
    assert len(before['party']) == len(after['party']) == 5
    assert [p['uid'] for p in before['party']] == [p['uid'] for p in after['party']]
    assert len({p['uid'] for p in after['party']}) == 5
    proof = relay['piece_proof']
    assert proof['passed'] is True and proof['failures'] == []
    assert proof['prior_earned_play'] is False and proof['free_build'] is False
    assert proof['world_seed_env'] == '' and proof['saved_world_seed'] == 59015681
    helper = proof['helper_receipts'][0]
    assert helper['passed'] is True
    beats = {p['beat']: p for p in helper['receipts']}
    captain = beats['relay_captain_defeated']
    assert captain['rounds'] == captain['wins'] == 5
    assert captain['items_before'] == {'coin': 200, 'orb_greater': 2, 'revive': 9}
    assert captain['items_after'] == {'coin': 260, 'orb_greater': 5, 'revive': 10}
    for key, expected in captain['expected_xp'].items():
        assert captain['xp_after'][key] - captain['xp_before'][key] == expected
    assert beats['captive_rescued']['gear'] == 1
    assert beats['relay_disabled']['lit_before'] == 18 and beats['relay_disabled']['lit_after'] == 0
    mill = beats['mill_crossing_restored']
    assert mill['gear_before'] == 1 and mill['gear_after'] == 0 and mill['depth'] >= 9
    required_flags = {'captive_rescued', 'mill_crossing_restored', 'relay_captain_defeated', 'relay_disabled'}
    gained_flags = set(proof['flags_gained'])
    assert required_flags <= gained_flags
    optional_flags = gained_flags - required_flags
    assert optional_flags <= {'wild_once_3100'}
    assert gained_flags == set(after['flags']) - set(before['flags'])
    assert set(before['flags']) <= set(after['flags'])
    for boundary, receipt in [('warrens', predecessor), ('relay', relay)]:
        world = document(z.read(base + boundary + '/save/worlds/slot-0/world.json'))
        slot = document(z.read(base + boundary + '/save/slot_0.json'))
        saved_flags = set(world['flags']['flags']) | set(slot['progression']['flags'])
        assert saved_flags <= set(receipt['state']['flags'])
        if boundary == 'relay':
            assert gained_flags <= saved_flags
        else:
            assert gained_flags.isdisjoint(saved_flags)
    if optional_flags:
        # Accept only this source-authored optional alpha, whose weather-dependent
        # appearance is allowed by the route. This adds no extra criterion claim.
        raw = subprocess.check_output(['git', '-C', args.repo, 'show', SOURCE + ':data/config/bands/band3_the_river_lock/spawns.json'])
        authored = json.loads(raw)
        def rows(value):
            if isinstance(value, dict):
                if value.get('order') == 3100:
                    yield value
                for child in value.values():
                    yield from rows(child)
            elif isinstance(value, list):
                for child in value:
                    yield from rows(child)
        matches = list(rows(authored))
        assert len(matches) == 1
        alpha = matches[0]
        assert alpha['species'] == 'stormtrail' and alpha['alpha']
        assert alpha['weather'] == ['rain'] and alpha['centre'] == [318.0, 0.0, 3830.0]
        assert 'completion_reward' not in alpha['alpha']
    log = z.read('run.log').decode()
    assert 'SCRIPT ERROR' not in log and not any(l.startswith('ERROR:') for l in log.splitlines())
    result = {'source': SOURCE, 'main': args.main, 'run': args.run, 'artifact': args.artifact, 'reviewer': 'lane B artifact verifier (independent approval still required)', 'criterion': 'F02#2', 'verdict': 'PASS', 'optional_authored_flags': sorted(optional_flags), 'flags_gained': sorted(gained_flags), 'archive_sha256': hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(), 'checked_saved_files': files, 'party_count': 5, 'captain_rounds': 5, 'captain_hits': captain['hits'], 'mill_depth_m': mill['depth'], 'seconds': proof['wall_seconds'], 'prior_earned_play': False, 'continuous_fresh_save': False, 'excluded_claims': ['F02#3', 'F02#4', 'F02#6', 'F02#7', 'continuous earned prefix']}
    Path(args.output).write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
