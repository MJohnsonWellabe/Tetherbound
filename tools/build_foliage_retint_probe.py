"""Build the bounded root-only retint proof. Never starts Godot or changes a stage."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

PRODUCTION = '717003216e'
METHODS = ['_retint', '_tint_for', '_adjusted_texture', '_global_retint']


def sha(data):
    return hashlib.sha256(data).hexdigest()


def extract_method(source, name):
    lines = source.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith('func ' + name + '(')]
    if len(starts) != 1:
        raise ValueError('Missing/ambiguous method: ' + name)
    start = starts[0]
    end = start + 1
    while end < len(lines) and (lines[end].startswith(('\t', ' ')) or not lines[end].strip()):
        end += 1
    return ''.join(lines[start:end]).rstrip() + '\n'


def checked_asset(stage, relative):
    path = (stage / relative).resolve()
    if not path.is_relative_to(stage.resolve()) or not path.is_file():
        raise ValueError('Missing/outside asset: ' + relative)
    return path.read_bytes()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--asset-stage', type=Path, required=True)
    ap.add_argument('--prior-packet', type=Path, required=True)
    args = ap.parse_args()
    repo = Path(__file__).resolve().parents[1]

    def git(*parts):
        return subprocess.check_output(['git', '-c', 'gc.auto=0', '-c', 'maintenance.auto=false', '-C', str(repo), *parts])

    production = git('rev-parse', PRODUCTION + '^{commit}').decode().strip()
    proof = git('rev-parse', 'HEAD').decode().strip()

    def blob(pin, path):
        return git('show', pin + ':' + path)

    if not args.out.is_absolute() or args.out.exists():
        raise ValueError('Output must be absent absolute directory')
    prior = json.loads(args.prior_packet.read_text(encoding='utf-8'))
    archive = Path(prior['archive'])
    assert sha(archive.read_bytes()) == prior['archive_sha256']
    with zipfile.ZipFile(archive) as z:
        payload = {name: z.read(name) for name in z.namelist()}
    assert {p: sha(b) for p, b in payload.items()} == prior['payload_sha256']
    payload.pop('tools/check_foliage_fight_fade_materials.gd')
    production_paths = ['scripts/world/foliage_standard_shader.gd', 'scripts/world/foliage_fight_fade.gd',
                        'scripts/world/imported_materials.gd', 'data/config/art.json',
                        'data/config/stormwood_vegetation.json', 'data/config/foliage_camera_visibility.json']
    for path in production_paths:
        payload[path] = blob(production, path)
    probe = 'tools/check_foliage_fight_fade_retint.gd'
    payload[probe] = blob(proof, probe)
    source = blob(production, 'scripts/world/vegetation.gd').decode('utf-8')
    methods = {name: extract_method(source, name) for name in METHODS}
    # This isolated binding follows the Stormwood branch, without Terrain3D/autoloads.
    assert 'if _realm_bake_name != BAKE_WORLD_NAME:\n\t\treturn {}' in source.replace('\r\n', '\n')
    adapter = '''extends RefCounted
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
var realm_config: Dictionary = {}
var _tints: Dictionary = {}
var _adjusted_textures: Dictionary = {}
func _vegetation_config() -> Dictionary:
	return realm_config
func _presentation_retint() -> Dictionary:
	return {} # Exact Stormwood branch; no Meadows overlay.

'''+ '\n'.join(methods.values())
    payload['tools/fixtures/pinned_vegetation_retint.gd'] = adapter.encode('utf-8')
    cfg = json.loads(payload['data/config/stormwood_vegetation.json'])
    los = json.loads(payload['data/config/foliage_camera_visibility.json'])['line_of_sight_fade']
    assert los['enabled'] is False
    rows = []
    for name in ['storm_canopy', 'giant_canopy', 'storm_deadwood', 'crown_canopy']:
        layer = cfg['layers'][name]
        assert not layer.get('retexture_adjust') and not layer.get('colour_jitter', 0)
        for swap in layer.get('retexture', {}).values():
            relative = swap.removeprefix('res://')
            payload[relative] = checked_asset(args.asset_stage, relative)
        for model in layer['models']:
            assert model in los['models']
            doc = json.loads(payload[model.removeprefix('res://')])
            for material in doc['materials']:
                rows.append({'layer': name, 'model': model, 'material': material['name'],
                             'expected_supported': True, 'native_verified': False})
    assert len(rows) == 12
    # CPU controls check extraction and package guards, not engine semantics.
    controls = {}
    for name, method in methods.items():
        assert method in source.replace('\r\n', '\n') or method in source
        controls[name + '_exact_extraction'] = True
    for bad in ['../outside.png', 'assets/missing-proof-control.png']:
        try:
            checked_asset(args.asset_stage, bad)
        except ValueError:
            controls[bad + '_rejected'] = True
        else:
            raise AssertionError('Asset guard did not reject')
    try:
        extract_method(source, '_missing_control')
    except ValueError:
        controls['missing_method_rejected'] = True
    try:
        extract_method(source + '\n' + methods['_retint'], '_retint')
    except ValueError:
        controls['duplicate_method_rejected'] = True
    assert len(controls) == 8
    args.out.mkdir()
    target = args.out / 'isolated-retint-probe.zip'
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, data in payload.items():
            z.writestr(name, data)
    with zipfile.ZipFile(target) as z:
        assert {name: sha(z.read(name)) for name in z.namelist()} == {p: sha(b) for p, b in payload.items()}
    stage = 'D:/CodexTemp/f10-retint-' + proof[:10]
    assert not Path(stage).exists()
    jobs = []
    for renderer in ['gl_compatibility', 'forward_plus']:
        output = args.out / ('run-' + renderer)
        jobs.append({'id': renderer, 'timeout_seconds': 60,
                     'arguments': ['--path', stage, '--rendering-method', renderer, '--resolution', '192x192', '--script', probe, '--', '--out=' + output.as_posix()],
                     'acceptance': 'Natural exit0; clean script/shader/compiler diagnostics; one F10_RETINT_MSAA_COMPLETE. Report actual requested renderer, msaa_3d=2 (4x), errors empty,12 inventory and12 case rows, all supported. Every equivalence max_error<=1/255+1e-6; normal controls>=16 changed pixels; cutout controls>=16 changed pixels on original nonopaque textures, or on explicit alpha-only witness for verified fully opaque textures (original no-op must remain within tolerance and witness conversion must match); every rejected ADD-detail fixture retains identity/exact raster. Preserve PNGs/report. No headless/software substitute.'})
    manifest = {'production_source': production, 'proof_source': proof, 'archive': str(target),
                'archive_bytes': target.stat().st_size, 'archive_sha256': sha(target.read_bytes()),
                'payload_sha256': {p: sha(b) for p, b in payload.items()},
                'extracted_methods_sha256': {n: sha(m.encode()) for n, m in methods.items()},
                'vegetation_source_sha256': sha(blob(production, 'scripts/world/vegetation.gd')),
                'cpu_controls': controls, 'inventory': rows, 'jobs': jobs,
                'preparation': 'Root-only extraction into absent '+stage+'. Verify hashes. Existing reviewed supervisor: one separately granted process; Compatibility first, stop on failure, then separately granted Forward+. No native process/stage created by builder.',
                'admission': {'free_ram_GiB': 2, 'free_C_GiB': 10, 'free_D_GiB': 20, 'output_stop_GiB': 1},
                'limits': 'Actual production retint methods extracted unchanged. Minimal config/Stormwood-empty-presentation bindings; raw runtime glTF and ImageTexture swap cache, not editor import. Lit quad 4x MSAA, no near-lens stage/detail look adapter/tree geometry/world integration/art acceptance. All12 support expected, not native verified. Production flags unchanged. Prior ad133 packet immutable.'}
    (args.out / 'isolated-retint-jobs.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'packet': str(args.out / 'isolated-retint-jobs.json'), 'bytes': target.stat().st_size, 'controls': len(controls)}, indent=2))


if __name__ == '__main__':
    main()
