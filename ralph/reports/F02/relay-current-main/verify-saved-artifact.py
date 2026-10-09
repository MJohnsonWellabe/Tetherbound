import hashlib, json, math, struct, zipfile
from pathlib import Path

SOURCE = 'dc1140ecf4d6da6183050d48f395ba36d23f9384'
ARCHIVE = Path('C:/CodexTemp/root-review-37983413867-11643200232.zip')

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
    prefix = 'user/godot/app_userdata/Tetherbound/'
    base = prefix + 'owner-b-relay-only/'
    generated = prefix + 'owner-b-relay-only_generated_input/'
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
    assert set(proof['flags_gained']) == {'captive_rescued', 'mill_crossing_restored', 'relay_captain_defeated', 'relay_disabled'}
    log = z.read('run.log').decode()
    assert 'SCRIPT ERROR' not in log and not any(l.startswith('ERROR:') for l in log.splitlines())
    result = {'source': SOURCE, 'main': 'c927823d1b41e98b90d33181a07846e72dc6a27a', 'run': 37983413867, 'artifact': 11643200232, 'reviewer': '/root', 'criterion': 'F02#2', 'verdict': 'PASS', 'checked_saved_files': files, 'party_count': 5, 'captain_rounds': 5, 'captain_hits': captain['hits'], 'mill_depth_m': mill['depth'], 'seconds': proof['wall_seconds'], 'prior_earned_play': False, 'continuous_fresh_save': False, 'excluded_claims': ['F02#3', 'F02#4', 'F02#6', 'F02#7', 'continuous earned prefix']}
    Path('C:/CodexTemp/owner-b-root-relay-runtime-review.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
