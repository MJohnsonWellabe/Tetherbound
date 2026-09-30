"""Pinned source only; no Godot, capture request or acceptance verdict."""
from pathlib import Path
from collections import Counter
import hashlib, io, json, subprocess, tarfile

repo = Path('D:/tetherbound/redesign-lookdev')
pin = '5f4093ad54e4675b782ab1f04129e1047c0977df'
paths = [
    'scripts/world/playground_world.gd', 'scripts/world/village.gd', 'scripts/world/crossing_hall.gd',
    'scripts/world/building_prefabs.gd', 'scripts/world/stronghold.gd', 'scripts/world/vegetation.gd',
    'scripts/world/structure_visibility_range.gd', 'scripts/world/cloudreach_world.gd',
    'scripts/world/cloudreach_world_runtime.gd', 'scripts/world/cloudreach_environment_materials.gd',
    'scripts/world/cloudreach_ground_cover.gd', 'scripts/world/tether_sigil.gd',
    'data/config/village.json', 'data/config/crossing_hall.json', 'data/config/building_prefabs.json',
    'data/config/stronghold.json', 'data/config/terrain_playground.json', 'data/config/grass_field.json',
    'data/config/cloudreach_world.json', 'data/config/cloudreach_visual.json', 'data/config/performance.json',
    'shaders/cloudreach_cliff.gdshader', 'shaders/cloudreach_rock.gdshaderinc',
    'shaders/cloudreach_turf.gdshaderinc', 'shaders/cloudreach_surface.gdshader',
    'shaders/cloudreach_trail.gdshader', 'shaders/cloudreach_ground_cover.gdshader',
    'shaders/cloudreach_cloud_deck.gdshader', 'shaders/cloudreach_timber.gdshader',
    'shaders/cloudreach_worn_ground.gdshader', 'assets/environment/team_tether/hall/hall_stone.gdshader',
    'assets/environment/team_tether/hall/banner_cloth.gdshader',
]
data = subprocess.check_output(['git', 'archive', pin, '--', *paths], cwd=repo)
with tarfile.open(fileobj=io.BytesIO(data)) as archive:
    blobs = {path: archive.extractfile(path).read() for path in paths}
configs = {path: json.loads(blob) for path, blob in blobs.items() if path.endswith('.json')}
village, crossing, hall, cloud, visual = [configs['data/config/'+name+'.json']
    for name in ['village', 'crossing_hall', 'stronghold', 'cloudreach_world', 'cloudreach_visual']]

def row(name, selectors, source, required, limits, mode='initial-production'):
    return dict(family=name, node_selector_hints=selectors, source_owner=source, mode=mode,
                required_binding_semantics=required, limits=limits)

stone = {
    'shader': 'res://assets/environment/team_tether/hall/hall_stone.gdshader',
    'albedo_tex': 'res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png',
    'normal_tex': 'res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png',
    'rough_tex': 'res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png'}
meadows = [
    row('terrain', ['Terrain'], 'playground_world.gd::_apply_ground_materials/_build_texture_list',
        {'texture_slots': configs['data/config/terrain_playground.json']['textures'],
         'gpu_arrays': ['_height_maps', '_control_maps', '_color_maps', '_texture_array_albedo', '_texture_array_normal']},
        'An enabled aerial override requires its actual shader child/code and stored params/direct GPU evidence. Builtin uniform names alone are not override proof.'),
    row('scatter_and_grass', ['Terrain descendants/assets', 'GrassField'], 'vegetation.gd::build/_register_mesh_assets; playground_world.gd::_stand_up_the_grass_field',
        ['Each mounted or stored Terrain3DMeshAsset PackedScene retains its active imported material graph; actual grass shader samplers use direct map RIDs when object getters are null.'],
        'Terrain scatter and grass are camera/region dependent. Stored serialized resources do not prove every remote mesh submitted to GPU. Preserve container truncation and streamed omissions.'),
    row('grandpa_house', ['GrandpaHouse'], 'playground_world.gd::_build_settlement; grandpa_house.gd',
        ['Installed civilian-family shell, interior/door and explicit authored finish retain their bound materials.'],
        'Separate house entry and interior player paths are not earned by this Village view; hidden template resources do not certify visible placements.'),
    row('village_prefabs', ['Village/<prefab>_<placement number>', 'Village/PrefabTemplates'], 'village.gd::build/_place; building_prefabs.gd::_build_template/_apply_retint',
        {'configured_structure_count': len(village['structures']),
         'configured_prefab_counts': dict(Counter(str(raw.get('prefab', raw.get('model', 'unknown'))) for raw in village['structures'])),
         'binding_rule': 'Imported Medieval Village trim-texture family remains on active surfaces. Retint duplicates colour while retaining albedo; explicit texture swaps must exist/bind. Dimensional cloth source_texture is required when that profile is selected.'},
        'Village/PrefabTemplates is deliberately hidden. Match actual placed siblings and inherited active materials rather than treating hidden cached templates as the finished settlement. Missing recipe/module/ground failures can omit structures; count/material graph alone cannot excuse loader warnings.'),
    row('crossing_hall', ['Village/crossing_hall_shell_*', '.../Arch_<id>/PortalSurface', '.../Pedestal_<biome>', '.../RoadFacingFrontage'],
        'village.gd::_exterior_identity; crossing_hall.gd::build/_build_arch/_build_pedestal/_build_frontage',
        {'arch_ids': [raw['id'] for raw in crossing['arches']],
         'pedestal_biomes': [raw['biome'] for raw in crossing['pedestals']],
         'installed_models': ['res://assets/buildings/quaternius_medieval/Wall_Arch.gltf',
            'res://assets/props/quaternius_fantasy/BookStand.gltf', 'res://assets/props/quaternius_fantasy/Lantern_Wall.gltf'],
         'portal_finish': 'Every PortalSurface receives an explicit StandardMaterial3D, with state colour/emission. No albedo texture is authored for these sealed/open membranes.'},
        'This is the village Crossing Hall, distinct from the remote Meadows Stronghold/Hall. Eight arches and eight pedestals are logical configured objects, not total binding counts. Fresh state does not open future arches. Identity root may have autogenerated name; match owning building + child family.'),
    row('meadows_hall_stone', ['Stronghold chamber surfaces', 'Stronghold/HallMassing'],
        'playground_world.gd::_build_stronghold; stronghold.gd::build/_stone_shader_material/_weather_hall_massing',
        {'required_stone_material': stone, 'configured_chamber_ids': [raw['id'] for raw in hall['chambers']],
         'mount_rule': 'All configured chambers, HallMassing, approach, trim, exterior/interior dressing and machine build before Stronghold.build returns and the world shell marks ready.'},
        'No proximity visit required to mount Hall. Village pixels do not expose remote Hall; reuse its actual historical original endpoints. Deliberately untextured iron/timber/glow receives explicit material and does not require stone maps.'),
    row('meadows_hall_prefabs_and_cloth', ['Stronghold/HallMassing', 'Stronghold/HallDressing', 'Stronghold/...Banner...', 'Stronghold/HallPrefabTemplates'],
        'stronghold.gd::_build_hall_massing/_build_hall_dressing/_banner_cloth_material; building_prefabs.gd',
        ['Imported kit non-stone surfaces preserve actual installed albedo/normal bindings as declared by their source materials.',
         'Weathered stone slots use the Hall stone three samplers; banner_cloth.gdshader device_tex comes from tether_sigil.texture and may be generated with no external filepath.'],
        'HallPrefabTemplates hidden cache does not count as placed art. State-closed blast shutters are explicitly finished surfaces. Clothing/glow without texture is not automatically missing material.'),
    row('meadows_hall_machine', ['Stronghold/TetherMachine', 'Stronghold/TetherMachinePlaceholder'],
        'stronghold.gd::_build_machine/machine_is_placeholder',
        {'configured_machine': hall.get('machine', {}),
         'binding_rule': 'Check actual installed model mesh/material graph. The imported machine path is a declared asset; an authored fallback can remain fully bound and still fail to prove the model loaded.'},
        'Node name alone is insufficient: source picks its name from placeholder configuration before the model-load branch. A fallback with no missing active surface is not proof of the intended installed model. No occupant/Legendary/progression approval.'),
    row('other_initial_meadows_families', ['Props', 'StonewaterReach', 'HighfieldPastureIdentity', 'VillageNPCs', 'RelayNPCs', 'PondNPCs', 'Trainers', 'SouthBridge', 'MillCrossing', 'SeveredSpokes', 'BurrowWarrens', 'Water'],
        'playground_world.gd::_build_settlement/_build_water',
        ['Retain actual active imported/material override resources and explicit sampler declarations for each mounted family, with all warnings and nulls.'],
        'Some NPC/reward/story/dungeon occupant state is gated. This source inventory only maps initial material families; no transactions, encounter phase or future state claim.'),
]
geo = visual.get('geology', {})
cloud_rows = [
    row('cloud_cliffs_regions_horizon', ['CliffRegions', 'DistantHighlandRanges', 'DistantLowerRelief', 'RealmTransitionLedges'],
        'cloudreach_world.gd::_build_materials/_build_regions/_build_horizon_ranges/_visual_rock_mass',
        {'shader': 'res://shaders/cloudreach_cliff.gdshader',
         'samplers': {'rock_texture': geo.get('albedo', 'res://assets/environment/terrain/Rock030_Color.jpg'),
            'rock_normal': geo.get('normal', 'res://assets/environment/terrain/Rock030_NormalGL.jpg')},
         'region_ids': [raw['id'] for raw in cloud['regions']]},
        'Near and hazed variants share rock maps; colour uniforms/distant no-normal response are authored. Flag-off rock-section or imported buttress candidates do not earn approval by preloading.'),
    row('cloud_crowns_trails_and_cover', ['CliffRegions crown caps', 'AuthoredRoutes', 'ProceduralGroundCover'],
        'cloudreach_environment_materials.gd::ground/turf_parameters; cloudreach_world.gd::_build_materials; cloudreach_ground_cover.gd::build',
        {'surface_shader': 'res://shaders/cloudreach_surface.gdshader',
         'trail_shader': 'res://shaders/cloudreach_trail.gdshader',
         'cover_shader': 'res://shaders/cloudreach_ground_cover.gdshader',
         'required_turf_textures': ['res://assets/environment/terrain/stylised/meadow_grass_Color.png',
            'res://assets/environment/terrain/stylised/verge_grass_Color.png'],
         'trail_dirt_texture': visual.get('surface', {}).get('path', {}).get('albedo', 'res://assets/environment/terrain/stylised/dirt_path_Color.png'),
         'sampler_names': ['grass_texture', 'dirt_texture', 'rock_texture', 'rock_normal'],
         'binding_rule': 'Apply sampler requirements to the actual source-selected material role. Grass/dry-grass cover receives grass_texture through ground_cover_parameters; flower/bush cover shares the shader but keeps procedural tint and default turf_match, without that texture assignment. Shared sampler declarations alone do not make inactive optional flower/bush textures required.'},
        'Cover is per-patch mounted MultiMesh with distance fade; region render visibility is not completeness of submitted pixels. Logical patch counts differ from surface counts.'),
    row('cloud_landmarks_and_bridges', ['Landmarks', 'SuspendedBridges', 'TraversalGates', 'AuthoredRouteDetails', 'CloudreachResources'],
        'cloudreach_world.gd::_build_landmarks/_build_bridges/_build_progression_gates/_build_authored_route_details',
        {'landmark_ids': [raw['id'] for raw in cloud['landmarks']],
         'binding_rule': 'All authored solo landmarks build before shell-ready. Installed tree/prop/bridge material graphs remain active; plain rope/copper/key glow are explicit solid finishes.'},
        'Uses_multiplayer_staging false for fresh solo; multiplayer placeholders are a different scope. Story-built bridges can be mounted but hidden. Preserve route-headroom exclusions and skipped-loader warnings; do not force spawn them.'),
    row('cloud_architecture_masonry', ['Landmarks settlements/aviary', 'SummitArenaPresentation', 'CloudreachBattleYards'],
        'cloudreach_environment_materials.gd::masonry/aviary_masonry; cloudreach_world_runtime.gd::build_environment/mount',
        {'masonry': stone,
         'timber_shader': 'res://shaders/cloudreach_timber.gdshader',
         'timber_rule': 'Weathered timber shader is procedural: no albedo sampler declared. Ordinary imported wooden kit surfaces still retain their installed texture materials.'},
        'Every actor/material must be checked on its active surface graph. Texture-free procedural wood/metal does not imply a missing material, but full art bar is not certified.'),
    row('cloud_banners_and_worn_ground', ['SummitArenaPresentation banners', 'Landmarks banners/activity patches'],
        'cloudreach_environment_materials.gd::banner/worn_ground',
        {'cloth_shader': 'res://assets/environment/team_tether/hall/banner_cloth.gdshader',
         'cloth_sampler': 'device_tex -> tether_sigil.texture generated texture',
         'worn_ground_shader': 'res://shaders/cloudreach_worn_ground.gdshader',
         'soil_tex': 'res://assets/environment/terrain/stylised/dirt_path_Color.png'},
        'Generated sigil resource path may be empty by construction. Inline/generated shaders require nonempty code, not an external path for every ShaderMaterial.'),
    row('cloud_backdrop_and_atmosphere', ['CloudBanks', 'CloudDecks', 'CloudBillows', 'CloudreachAtmosphere', 'CloudreachWorldPayoffs'],
        'cloudreach_world.gd::_build_cloud_sea/_build_cloud_decks; cloudreach_world_runtime.gd::mount',
        {'cloud_deck_shader': 'res://shaders/cloudreach_cloud_deck.gdshader',
         'binding_rule': 'Procedural cloud deck math and coloured cloud/wind veil material are intentionally untextured. Active materials/shader code still must exist.'},
        'Fresh ambient/default effects differ from return-traveler/payoff/progression phases. No new weather, night, phase or earned route capture is requested.', mode='initial-production plus state-dependent payoffs'),
]
output = dict(source_commit=pin, scope='Source-only family maps authored by census tool/source-map helper; not an independent acceptance verdict or actual mounted result.',
    canonical_git_blob_hashes={path: hashlib.sha256(blob).hexdigest() for path, blob in blobs.items()},
    meadows_families=meadows, cloudreach_families=cloud_rows,
    general_rules=['Child meshes often have no owner_script; match full node path, ancestor owner and actual active material graph.',
        'Null mesh_source plus nonnull active override is normal; null active requires exact source/visibility triage.',
        'Optional albedo on authored solid colour is not a declared missing sampler. Source-assigned imported/sampler textures require actual resource binding; uniform declarations for unused/default-disabled roles alone do not make an optional texture required.',
        'No missing source path, no empty shader and valid RIDs cannot alone certify texture pixels, earlier silent substitutions or full visual quality.',
        'Preserve actual flags, culling/streaming, warnings, hidden caches/placeholders and resource container truncations.',
        'No further native capture requested. Wait for actual new dictionaries/family inventory; a concrete required absence must be assessed first.',
        'The separate final strict non-author reviewer reads ACCEPTANCE F26#0 and archived original evidence against main.'])
out = repo / '.tmp/f26-meadows-cloud-source-family-maps.json'
out.write_text(json.dumps(output, indent=2)+'\n')
print(json.dumps(dict(output=out.as_posix(), source_commit=pin, pinned_files=len(blobs),
    meadows_rows=len(meadows), cloud_rows=len(cloud_rows), village_structures=len(village['structures']),
    crossing_arches=len(crossing['arches']), crossing_pedestals=len(crossing['pedestals']),
    hall_chambers=len(hall['chambers']), cloud_regions=len(cloud['regions']), cloud_landmarks=len(cloud['landmarks'])), indent=2))
