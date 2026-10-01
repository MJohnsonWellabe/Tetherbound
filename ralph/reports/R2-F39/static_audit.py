"""Non-engine source audit. Does not award runtime or visual acceptance."""
import csv
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / '.artifacts/f39-static-parser'))
from gdtoolkit.parser import parser

sources = [
    'scripts/world/water_current_flow_view.gd',
    'scripts/world/water_veilfall_falls.gd',
    'tools/capture_f39_catalogue.gd',
]
checks = []
for name in sources:
    parser.parse((ROOT / name).read_text(encoding='utf-8'))
    checks.append({'check': 'GDScript grammar only', 'file': name, 'result': 'PASS'})

for config, shader in [
    ('water_current_flow_visual', 'water_current_flow'),
    ('water_veilfall_falls_visual', 'water_veilfall_fall'),
]:
    cfg = json.loads((ROOT / f'data/config/{config}.json').read_text())
    assert cfg['enabled'] is False
    if 'ridges_enabled' in cfg:
        assert cfg['ridges_enabled'] is False
    text = (ROOT / f'shaders/{shader}.gdshader').read_text()
    uniforms = set(re.findall(r'uniform\s+\w+\s+(\w+)', text))
    assert set(cfg['shader']).issubset(uniforms)
    assert all(isinstance(v, (int, float)) for v in cfg['shader'].values())
    checks.append({'check': 'JSON, false gates and shader uniform links', 'config': config, 'result': 'PASS'})

catalogue = json.loads((ROOT / 'data/config/debug_teleport_spots.json').read_text(encoding='utf-8'))
water = next(b for b in catalogue['biomes'] if b['id'] == 'water')
spots = sum(len(b['spots']) for b in water['bands'])
assert spots * 2 * 5 >= 200
checks.append({'check': 'Static full recapture plan', 'destinations': spots,
               'planned_frames_per_preset_weather_pack': spots * 2 * 5,
               'result': 'PASS', 'captured_frames': 0})

diff = subprocess.run(['git', 'diff', '--check'], cwd=ROOT, capture_output=True, text=True)
assert diff.returncode == 0, diff.stdout + diff.stderr
checks.append({'check': 'git diff --check', 'result': 'PASS'})

catalog_path = Path('D:/tetherbound/redesign-board/ralph/reports/VISUAL/phase2/catalog.csv')
rows = list(csv.DictReader(catalog_path.open(encoding='utf-8-sig', newline='')))
rows = [r for r in rows if 'tidewake' in r['biome(s)'].split(';')]
for row in rows:
    item = row['item_id']
    if item == 'P2-008':
        disposition = 'Owner stop retained; shore source untouched'
    elif item in ('P2-010', 'P2-066', 'P2-067'):
        disposition = 'F39 shader candidate implemented OFF; native/blind proof pending'
    elif item in ('P2-115', 'P2-116'):
        disposition = 'F34 camp dependency'
    elif item in ('P2-071', 'P2-072', 'P2-108', 'P2-109'):
        disposition = 'F37 traversal / F36 pose dependency'
    elif row['fix_class'] == 'ui':
        disposition = 'F42 dependency; not repaired by F39'
    elif row['fix_class'] in ('animation', 'mesh') or item == 'P2-030':
        disposition = 'F36 creature / shared pickup asset dependency; audit exact row at consolidation'
    elif row['fix_class'] == 'camera' or item == 'P2-060':
        disposition = 'Shared combat/camera/VFX dependency; F39 matrix must rejudge'
    else:
        disposition = 'Existing source/capture audit only; fresh production sightings required before repair'
    row['r2_f39_disposition'] = disposition
with (REPORT / 'catalog-source-audit.csv').open('w', encoding='utf-8', newline='') as stream:
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)

files = sources + ['data/config/water_current_flow_visual.json',
                   'data/config/water_veilfall_falls_visual.json',
                   'shaders/water_current_flow.gdshader', 'shaders/water_veilfall_fall.gdshader']
receipt = {
    'scope': 'Source/static evidence only; all F39 criteria remain OPEN',
    'base_sha': '7f18f5e75dc2744bb283bb1c3576da4e5d61b87d',
    'checks': checks,
    'historical_catalog_source': str(catalog_path),
    'historical_catalog_sha256': hashlib.sha256(catalog_path.read_bytes()).hexdigest(),
    'tidewake_rows': len(rows),
    'tidewake_impact_over_12': sum(int(r['impact']) > 12 for r in rows),
    'source_sha256': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in files},
    'runtime_executed': False,
    'native_frames_captured': 0,
    'code_blind_judge': 'PENDING',
    'multiplayer': 'No durable mutation/RPC/identity/transaction added. Existing world flag drives every peer current look on build/poll; rejoin proof pending.',
    'preserved': 'P2-008 shore, physical terrain/route/ribbons/current strength, F37 dive, creature assets, renderer default, saves, global STATE, dashboard and CI',
}
(REPORT / 'static-checks.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'checks': len(checks), 'planned_frames': spots * 2 * 5,
                  'catalog_rows': len(rows), 'runtime': 'PENDING'}, indent=2))
