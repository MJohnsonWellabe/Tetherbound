"""Bounded source audit for the F36 priority roster; never claims visual PASS."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'ralph/reports/R2-F36'
CREATURES = ['terrapup', 'ripplet', 'galewisp', 'mudsnout', 'bramblebun', 'burrowback',
    'meadowhart', 'galecrest', 'mirejaw', 'riverdrake', 'cloudfang', 'aeriex', 'tanglevolt',
    'fulgocobra', 'tuskroot', 'ashtusk', 'cannonback', 'stormcapra', 'staticub', 'voltarach',
    'veridian', 'abyssal_guardian', 'solmane', 'stormursa']
NPCS = ['grandpa', 'wandering_trainer', 'grunt', 'young_trainer', 'trader', 'innkeeper']


def record(path):
    return {'path': path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    definitions = json.loads((ROOT / 'data/creatures/species.json').read_text())['species']
    config_sources = list((ROOT / 'data/config').glob('*.json'))
    corpus = [(path, path.read_text(encoding='utf-8')) for path in config_sources]
    rows = []
    for id in CREATURES + NPCS:
        folder = ROOT / 'assets/creatures/tetherbound' / id
        references = [record(path) for path in sorted((folder / 'reference').glob('*.png'))]
        if id in definitions:
            model = ROOT / definitions[id]['placeholder']['model'].replace('res://', '')
            models = [record(model)]
        elif id in NPCS:
            family = [id] if id != 'grunt' else ['grunt', 'grunt_a', 'grunt_b', 'grunt_c']
            models = [record(path) for member in family for path in sorted((ROOT / 'assets/characters' / member).glob('*.glb'))]
        else:
            models = []
        hits = {path.relative_to(ROOT).as_posix(): text.count('"' + id + '"') for path, text in corpus if '"' + id + '"' in text}
        rows.append({'id': id, 'kind': 'npc_family' if id in NPCS else 'creature', 'models': models,
                     'reference_inventory': references, 'reference_inventory_is_not_inspection': True,
                     'config_literal_occurrences': hits, 'status': 'source_audited_visual_proof_pending',
                     'candidate_enabled': False})
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'priority-source-audit.json').write_text(json.dumps({'subjects': rows, 'count': len(rows),
        'baseline': '7f18f5e75dc2744bb283bb1c3576da4e5d61b87d',
        'ranking_change': 'Fulgocobra replaces Sparkit in row14: settled Stormwood legendary; Sparkit remains in all-species pose pass.',
        'galecrest': 'retain rebuilt identity and scale; scoped historical PASS is not a current F36 PASS',
        'stormursa': 'reuse F29 candidate identity/4.10m target; no new roster or runtime activation',
        'reference_and_asset_confirmations': 'Pending drafted/inspected references and ROOT-queued native before/after code-blind verdicts. Inventory and source counts are not acceptance.'}, indent=2) + '\n')
    print(f'F36 source audit: {len(rows)} priority subjects, no visual acceptance claimed')


if __name__ == '__main__':
    main()
