from pathlib import Path
from collections import Counter
import hashlib, json, re, struct

prefix = Path('D:/tetherbound/f26-storm-medium-0620d57bad')
source = '0620d57bad036e52c88446fa1c04408b07cea909'
matrix = json.loads(Path('.tmp/f26-storm-expected-families.json').read_text())
manifest = json.loads((prefix / 'manifest.json').read_text())
native = json.loads(prefix.with_suffix('.native.json').read_text())
assert matrix['source_commit'] == native['source_commit'] == manifest['graphics_capture']['source_commit'] == source
assert native['native_exit'] == 0 and not native['timed_out'] and not native['errors']
assert manifest['complete'] and manifest['failures'] == []
assert manifest['planned_frame_count'] == manifest['captured_frame_count'] == 1
assert manifest['graphics_capture']['preset'] == 'Medium'
assert manifest['graphics_capture']['renderer'] == 'forward_plus'
log_path = prefix.with_suffix('.log')
log = log_path.read_text(errors='replace').splitlines()
assert not [line for line in log if re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:', line)]
census = manifest['material_census'][0]
bindings, resources = census['bindings'], census['resources']
assert len(bindings) == census['binding_count']
resource_ids = set(resources)
keys = ['active_material', 'mesh_source_material', 'material_override', 'material_overlay', 'resource', 'material', 'texture']
dangling = [(rid, name, child) for rid, resource in resources.items()
            for name, child in resource.get('children', {}).items() if child not in resource_ids]
dangling += [(binding['node'], key, binding[key]) for binding in bindings
             for key in keys if binding.get(key) and binding[key] not in resource_ids]
assert not dangling

def resource_paths(selected):
    visited, pending = set(), [b[key] for b in selected for key in keys if b.get(key)]
    while pending:
        rid = pending.pop()
        if rid in visited:
            continue
        visited.add(rid)
        pending.extend(resources[rid].get('children', {}).values())
    return sorted({resources[rid]['path'] for rid in visited if resources[rid]['path']})

families = {}
for row in matrix['rows']:
    if row.get('prefix_suffix'):
        selected = [b for b in bindings if '/' + row['prefix_suffix'] + '/' in b['node']]
    else:
        prefixes = row.get('prefixes', [row.get('prefix', '')])
        selected = [b for b in bindings if any(b['node'] == p or b['node'].startswith(p + '/') for p in prefixes)]
    if row['mode'] == 'candidate_off':
        families[row['family']] = {'status': 'candidate off; shared original-tree nodes do not establish candidate coverage', 'flags': row['flags']}
        continue
    families[row['family']] = {
        'mode': row['mode'], 'bindings': len(selected),
        'kind_counts': dict(Counter(b['kind'] for b in selected)),
        'first_nodes': [b['node'] for b in selected[:4]],
        'bound_resource_paths': resource_paths(selected), 'limit': row['limits']}

terrain_binding = next(b for b in bindings if b['kind'] == 'terrain_material')
terrain = resources[terrain_binding['resource']]
terrain_assets = [r for r in resources.values() if r['class'] == 'Terrain3DTextureAsset']
observed_texture_pairs = [(resources[r['children']['albedo_texture']]['path'],
                          resources[r['children']['normal_texture']]['path']) for r in terrain_assets]
expected_pairs = [(r['albedo'], r['normal']) for r in matrix['rows'][0]['required']]
assert Counter(observed_texture_pairs) == Counter(expected_pairs)
terrain_gpu = terrain.get('terrain_gpu_uniform_bindings', {})
required_arrays = ['_height_maps', '_control_maps', '_color_maps', '_texture_array_albedo', '_texture_array_normal']
for name in required_arrays:
    assert terrain_gpu[name] == {'material_rid_valid': True, 'value_type': 'RID', 'binding_rid_valid': True}
ground_gpu = [{ 'id': rid, 'bindings': r['null_getter_gpu_bindings'] }
              for rid, r in resources.items() if r.get('null_getter_gpu_bindings')]
for row in ground_gpu:
    for name in ['_height_maps', '_control_maps', '_color_maps']:
        assert row['bindings'][name]['binding_rid_valid']

unbound = [b for b in bindings if 'active_material' in b and not b['active_material']]
assert [(b['node'], b['visible_in_tree']) for b in unbound] == [('Player/Model/Body', False), ('Player/Model/Nose', False)]
missing = [{'id': rid, 'path': r['path']} for rid, r in resources.items() if r.get('source_exists') is False]
empty = [rid for rid, r in resources.items() if r.get('code_empty')]
truncated = [{'id': rid, 'paths': r['container_scan_truncated']} for rid, r in resources.items() if r.get('container_scan_truncated')]
assert not missing and not empty and not truncated
camp_heads = {b['node'].split('/')[1] for b in bindings if b['node'].startswith('StormwoodCamps/')}
camp_ids = next(row['configured_ids'] for row in matrix['rows'] if row['family'] == 'camps')
assert set(camp_ids) <= camp_heads
rod_paths = families['rod_line']['bound_resource_paths']
assert 'res://assets/environment/team_tether/tether_pylon_albedo.png' in rod_paths
tree_paths = families['stormheart_bark_and_crown']['bound_resource_paths']
assert 'res://assets/environment/stylized_nature/Bark_TwistedTree.png' in tree_paths
assert 'res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png' in tree_paths
for name in ['glass_field_legacy', 'crown_stones_and_records', 'dynamo_arena', 'capacitor_grove', 'sentinel', 'camps', 'pickups_and_shafts']:
    assert families[name]['bindings'] > 0

frame = manifest['frames'][0]
png_path = prefix / (census['frame_id'] + '.png')
png = png_path.read_bytes()
assert png[:8] == b'\x89PNG\r\n\x1a\n' and png[12:16] == b'IHDR'
dimensions = list(struct.unpack('>II', png[16:24]))
assert dimensions == [1920, 1080] and len(png) == frame['bytes']
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
output = {
    'source_commit': source, 'scope': 'Read-only actual mounted binding review by source-map/tool author. Final independent criterion gate must be another non-author session.',
    'native_receipt': native, 'manifest_sha256': sha(prefix/'manifest.json'), 'log_sha256': sha(log_path),
    'warnings': [line for line in log if 'WARNING:' in line], 'frame_id': census['frame_id'],
    'png': {'path': str(png_path), 'sha256': hashlib.sha256(png).hexdigest(), 'bytes': len(png), 'dimensions': dimensions},
    'binding_count': len(bindings), 'resource_count': len(resources), 'dangling_resource_ids': dangling,
    'missing_source_paths': missing, 'empty_shader_code': empty, 'container_scan_truncated': truncated,
    'unbound_active_surfaces': unbound,
    'unbound_triage': 'Only hidden imported-player fallback Body/Nose capsules. Source character_model.gd::_hide_placeholders hides them after the imported body is built.',
    'terrain_override_enabled': terrain.get('terrain_override_enabled'), 'terrain_gpu_uniform_bindings': terrain_gpu,
    'terrain_texture_pairs': observed_texture_pairs, 'ground_null_getter_actual_gpu_bindings': ground_gpu,
    'families': families, 'mounted_camps': camp_ids,
    'bounded_verdict': 'No concrete missing active material or required stored texture found in this mounted Stormwood frame. Five Terrain arrays and seven null-getter ground-cover shader resources hold valid direct GPU RID bindings. No material/art repair justified by these observations.',
    'limits': [
        'One Medium daytime catalogue stand at The Stormheart Tree, staged travel/clock and isolated user data; no earned campaign, High or whole visual matrix proof.',
        'Mounted bindings and visible_in_tree do not prove in-camera pixels, texture contents, absence of earlier silent loader substitutions or full-bar appearance.',
        'All current flag-off Stormheart/scorched-glass candidates remain off; shared nodes and preloads grant no candidate approval.',
        'Rain/ceiling/steam are mounted under StormwoodSurge. No transient StormwoodLightning binding observed: strike, phase transitions, aftermath and full Surge remain unproved.',
        'Actual pickups/arch presentation may be mounted through the catalogue state. This does not certify progression, construction, rewards or reload transactions.',
        'Raw warnings retain two canopy layer retint conflicts and three deterministic creature-spacing fallback warnings, plus one deprecation.',
        'F26#0 whole village/Hall/four-biomes/Low criterion is not closed by this supplement. Another non-author session performs the final strict criterion review.']}
out = Path('.tmp/f26-storm-actual-material-review.json')
out.write_text(json.dumps(output, indent=2)+'\n')
print(json.dumps({'output': str(out), 'counts': [len(bindings), len(resources)],
                  'families': {name: row.get('bindings', 'off') for name, row in families.items()},
                  'terrain_override_enabled': output['terrain_override_enabled'], 'null_getter_gpu_resources': len(ground_gpu),
                  'warnings': len(output['warnings']), 'missing': len(missing), 'truncated': len(truncated),
                  'png_sha256': output['png']['sha256']}, indent=2))
