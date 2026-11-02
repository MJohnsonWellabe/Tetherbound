# crosscut.py <producer_dir> <consumer_input_dir> <out.json> [reasons.json]
# Cross-cut seam diff (owner, 31 Oct: an earned piece whose input changes is not re-run; a reviewed
# manifest lists every field that differs and why). Reads both SAVE TREES directly (not receipts,
# whose shapes differ between runners): producer = the earned predecessor's committed end save;
# consumer input = the save the already-passing successor actually loaded. Prints field diffs and
# sha256 of every save file. Reasons come from reasons.json ({field: reason}); a field without a
# reason is UNEXPLAINED.
import json, sys, glob, hashlib, struct, os
def f64(v):
    if isinstance(v, dict) and '$tb_float64' in v: return struct.unpack('<d', bytes.fromhex(v['$tb_float64']))[0]
    return v
def tree_sha(d):
    out = {}
    for p in sorted(glob.glob(d + '/save/**/*.json', recursive=True)):
        out[os.path.relpath(p, d)] = hashlib.sha256(open(p, 'rb').read()).hexdigest()
    return out
def state(d):
    s = json.load(open(d + '/save/slot_0.json'))['payload']
    c = json.load(open(glob.glob(d + '/save/characters/*/character.json')[0]))['payload']
    w = json.load(open(d + '/save/worlds/slot-0/world.json'))['payload']
    rc = c['redesign_character']
    inv = {}
    for st in c.get('inventory') or s.get('inventory') or []:
        if st: inv[st['id']] = inv.get(st['id'], 0) + int(f64(st['n']))
    party = []
    for m in c['party']:
        rec = rc['creatures'].get(m['uid'], {})
        party.append({'uid': m['uid'], 'species': m.get('species_id'), 'level': int(f64(m['level'])), 'xp': int(f64(m.get('xp', 0))),
                      'cap_level': int(f64(rec.get('cap_level', 0))), 'breakthroughs': [int(f64(x)) for x in rec.get('breakthroughs', [])]})
    pos = [round(f64(x), 2) for x in (c.get('player_pose') or {}).get('position', [])]
    wf = w.get('flags'); pf = c.get('flags')
    def flagset(x):
        if isinstance(x, dict) and isinstance(x.get('flags'), list): return sorted(x['flags'])
        if isinstance(x, dict): return sorted(k for k, v in x.items() if v)
        return sorted(x or [])
    return {'realm': c.get('realm') or s.get('current_realm'), 'position': pos, 'day': int(f64(w.get('day', 0))),
            'party': party, 'master_wins': sorted(rc.get('master_wins', [])), 'feast_recipes': sorted(rc.get('feast_recipes', [])),
            'relics_held': rc.get('relics_held', []), 'relics_hung': rc.get('relics_hung', []), 'portal_unlocks': rc.get('portal_unlocks', []),
            'world_flags': flagset(wf), 'personal_flags': flagset(pf), 'inventory': dict(sorted(inv.items())),
            'buildings': sorted(b['id'] for b in w.get('placed_buildings', []))}
a, b = sys.argv[1].rstrip('/'), sys.argv[2].rstrip('/')
reasons = json.load(open(sys.argv[4])) if len(sys.argv) > 4 else {}
A, B = state(a), state(b)
diffs = []
for k in A:
    if A[k] == B[k]: continue
    row = {'field': k}
    if isinstance(A[k], list) and k.endswith('flags') or k == 'buildings':
        row['only_producer'] = sorted(set(A[k]) - set(B[k])); row['only_consumer_input'] = sorted(set(B[k]) - set(A[k]))
        if k == 'buildings':
            from collections import Counter
            ca, cb = Counter(A[k]), Counter(B[k]); row['only_producer'] = sorted((ca - cb).elements()); row['only_consumer_input'] = sorted((cb - ca).elements())
    elif k == 'inventory':
        row['delta'] = {i: [A[k].get(i, 0), B[k].get(i, 0)] for i in sorted(set(A[k]) | set(B[k])) if A[k].get(i, 0) != B[k].get(i, 0)}
    else:
        row['producer'] = A[k]; row['consumer_input'] = B[k]
    row['reason'] = reasons.get(k, 'UNEXPLAINED')
    diffs.append(row)
out = {'kind': 'f49_cross_cut_seam_manifest', 'producer_dir': a, 'consumer_input_dir': b,
       'producer_save_sha256': tree_sha(a), 'consumer_input_save_sha256': tree_sha(b),
       'producer_end_state': A, 'differences': diffs,
       'unexplained': [d['field'] for d in diffs if d['reason'] == 'UNEXPLAINED']}
json.dump(out, open(sys.argv[3], 'w'), indent=1)
print(sys.argv[3].split('/')[-1], 'fields differ:', [d['field'] for d in diffs], 'unexplained:', out['unexplained'])
