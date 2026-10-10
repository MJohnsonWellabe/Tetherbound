"""Non-engine F40 risk checks. Does not certify rendering, play or acceptance."""
from pathlib import Path
import importlib.util
import json
import math
import re
import ast

ROOT = Path(__file__).resolve().parents[1]
base = json.loads((ROOT / 'data/config/cloudreach_aviary.json').read_text())
candidate = json.loads((ROOT / 'data/config/cloudreach_f40_visual.json').read_text())
visual = json.loads((ROOT / 'data/config/cloudreach_visual.json').read_text())
# Owner flip list (F40): every presentation candidate below is live.
assert candidate['enabled'] is True
assert base['crown_arcade']['enabled'] is True
assert base['towers']['enabled'] is True
assert visual['skyline_profile']['enabled'] is True
assert visual['settlement']['occupied_terrace']['enabled'] is True
assert candidate['aviary']['towers']['enabled'] is True
assert candidate['visual']['settlement']['occupied_terrace']['enabled'] is True

arcade = candidate['aviary']['crown_arcade']
radius = min(base['drum']['radius_x_m'], base['drum']['radius_z_m']) - arcade['radial_inset_m']
spacing = 2 * radius * math.sin(math.pi / arcade['bay_count'])
assert abs(spacing - arcade['width_m']) < arcade['post_width_m'], 'continuous supported bay rhythm'
assert base['drum']['height_m'] + arcade['base_offset_m'] - .2 > base['throat']['required_clear_height_m']
assert arcade['clear_height_m'] > (arcade['width_m'] - 2 * arcade['post_width_m']) / 2
assert math.ceil(arcade['bay_count'] / arcade['lantern_every']) <= 5

middle = candidate['look']['route_verges']['middle_ground']
assert middle['offset_m'] - middle['support_radius_m'] > 2.1 + 1.2
assert middle['support_radius_m'] >= middle['stone_scale'][1] / 2
catalogue = json.loads((ROOT / 'data/config/debug_teleport_spots.json').read_text())
biome = next(row for row in catalogue['biomes'] if row['id'] == 'cloudreach')
destinations = sum(len(row['spots']) for row in biome['bands'])
capture = candidate['capture']
planned = destinations * len(capture['times']) * len(capture['weather']) * len(capture['views'])
assert destinations == 12 and planned >= capture['minimum_frames'] >= 200
assert set(capture['times']) <= set(json.loads((ROOT / 'data/config/art.json').read_text())['times'])
assert set(capture['weather']) <= set(json.loads((ROOT / 'data/config/weather.json').read_text())['presets'])

scripts = [
    'scripts/world/cloudreach_visual_candidate.gd',
    'scripts/world/cloudreach_aviary_crown.gd',
    'scripts/world/cloudreach_aviary_sanctuary.gd',
    'scripts/world/cloudreach_route_verges.gd',
    'tools/capture_cloudreach_f40_matrix.gd',
    'tools/capture_cloudreach_f40_fight.gd',
    'tests/test_cloudreach_f40_presentation.gd',
]
for relative in scripts:
    text = (ROOT / relative).read_text()
    for resource in re.findall(r'(?:preload|load)\("res://([^\"]+)"\)', text):
        assert (ROOT / resource).is_file(), (relative, resource)
    if relative.startswith('scripts/'):
        for forbidden in ['StaticBody3D.new', 'CollisionShape3D.new', 'Area3D.new', 'rpc(', 'set_flag(', 'SaveGame']:
            assert forbidden not in text, (relative, forbidden)

print(f'PASS: production candidates live (owner flip list); {destinations} destinations/{planned} planned frames per preset; '
      'crown clearance/spacing/light budget, middle-ground offset/support budget, resource paths, no new state/collision API.')
if importlib.util.find_spec('gdtoolkit'):
    from gdtoolkit.parser import parser
    for relative in scripts + ['scripts/world/cloudreach_world.gd', 'scripts/world/cloudreach_look.gd']:
        parser.parse((ROOT / relative).read_text())
    print('PASS: gdtoolkit syntax parse (not Godot type/import/runtime validation).')
else:
    print('PENDING: GDScript parser unavailable; Godot type/import/runtime checks reserved for shared queue.')
for relative in ['tools/check_cloudreach_f40_source.py', 'tools/rescore_cloudreach_f40.py']:
    ast.parse((ROOT / relative).read_text())
print('PASS: Python static utility syntax.')
