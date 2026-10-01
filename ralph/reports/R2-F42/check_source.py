"""Non-engine F42 grammar/preload/config checks; never runtime acceptance."""
import hashlib
import json
import re
import sys
from importlib.metadata import version
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).parent / '.tools'))
from gdtoolkit.parser import parser

FILES = [
    'scripts/ui/system_screen.gd', 'scripts/ui/companion_details_panel.gd',
    'scripts/ui/bounty_board_panel.gd', 'scripts/ui/research_log_panel.gd',
    'scripts/ui/combat_system_overlay.gd', 'scripts/ui/altar_panel.gd',
    'scripts/ui/altar_service.gd', 'scripts/ui/altar_traits_panel.gd',
    'scripts/ui/altar_traits_service.gd', 'scripts/ui/combat_hud.gd',
    'scripts/ui/craft_panel.gd', 'scripts/ui/game_menu.gd',
    'scripts/ui/tab_creatures.gd', 'scripts/ui/tab_quest_log.gd',
    'scripts/ui/tether_command_meter.gd', 'tests/smoke_f42_system_screen.gd',
    'tools/capture_f42_layout_fixtures.gd',
]
rows = []
for relative in FILES:
    path = ROOT / relative
    source = path.read_text(encoding='utf-8')
    parser.parse(source)
    preloads = re.findall(r'preload\("res://([^\"]+)"\)', source)
    assert all((ROOT / preload).is_file() for preload in preloads), relative
    assert all(line == line.rstrip() for line in source.splitlines()), relative
    rows.append({'path': relative, 'sha256': hashlib.sha256(source.encode('utf-8')).hexdigest(),
                 'grammar': 'pass', 'preload_paths': 'pass'})
    print('GRAMMAR/PRELOAD PASS', relative)

hud = json.loads((ROOT / 'data/config/hud.json').read_text(encoding='utf-8'))
contexts = json.loads((ROOT / 'data/config/input_contexts.json').read_text(encoding='utf-8'))
assert hud['new_system_screens']['enabled'] is False
assert hud['new_system_screens']['row_height'] >= 66
for name in ['altar', 'station', 'gear', 'research', 'bounty_board']:
    assert name in contexts['contexts']
result = {'evidence_kind': 'non-engine grammar/preload/config only',
          'hash_basis': 'UTF-8 with LF newlines (Git canonical source)',
          'gdtoolkit_version': version('gdtoolkit'), 'files': rows,
          'json': 'pass', 'candidate_default_off': True, 'engine_run': False,
          'runtime_service_save_coop_device_visual_acceptance': False}
(Path(__file__).parent / 'source-check.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(f'PASS: {len(rows)} GDScript files, two JSON files; no engine/runtime acceptance.')
