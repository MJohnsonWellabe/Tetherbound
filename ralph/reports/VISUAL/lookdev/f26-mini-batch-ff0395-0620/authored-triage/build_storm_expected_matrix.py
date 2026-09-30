import subprocess, json, hashlib
from pathlib import Path

source='0620d57bad036e52c88446fa1c04408b07cea909'
def read(path):
    data=subprocess.check_output(['git','show',source+':'+path])
    return json.loads(data), hashlib.sha256(data).hexdigest()
paths=['stormheart_presentation','stormwood_glass_field','stormwood_dynamo','stormwood_camps',
       'stormwood_rod_line','stormwood_arches','terrain_playground','grass_field']
configs={}; hashes={}
for name in paths:
    path='data/config/'+name+'.json'; configs[name],hashes[path]=read(path)
tree=configs['stormheart_presentation']; glass=configs['stormwood_glass_field']; terrain=configs['terrain_playground']
rows=[
dict(family='terrain',prefix='Terrain',owner='stormwood_world.gd:361-385',mode='production_default',
     required=[dict(slot=i,name=t['name'],albedo=t['albedo'],normal=t['normal']) for i,t in enumerate(terrain['textures'])],
     limits='Use actual stored resources and direct GPU sampler RID metadata. Builtin uniform names alone are not active shader/array proof.'),
dict(family='ground_cover',prefix='StormwoodGroundCover',owner='stormwood_world.gd::_stand_up_ground_cover; grass_field.gd:1823-1865',
     mode='config_enabled' if configs['grass_field'].get('enabled',False) else 'config_disabled',
     required=['Existing grass_field/cover-tier shader families selected by actual config',
               'Direct _height_maps/_control_maps/_color_maps RID metadata when the Resource getter is null'],
     limits='Camera-relative tiers may omit visible tiles; identify mounted/disabled tiers separately. A valid RID proves a handle, not pixels.'),
dict(family='stormheart_bark_and_crown',prefix='StormheartTree',owner='stormheart_tree.gd:23-55,754-772',mode='production_default',
     required=['Bark_TwistedTree.png on wood and bark','Existing imported leaf surfaces',
               'Leaves_NormalTree_C_desat55.png replacement for Leaves_TwistedTree when canopy candidate disabled',
               'Plain-colour metal, cloth, energy seam/glow and installed lantern surface materials'],
     limits='Current presentation.enabled false does not mean the whole tree is absent. Original tree and documented fallback canopy remain live.'),
dict(family='stormheart_candidates',prefix='StormheartTree',owner='stormheart_tree.gd::_presentation_enabled/_green_canopy',
     mode='candidate_off' if not tree.get('enabled',False) else 'inspect_subflags',
     flags={k:bool(tree.get(k,{}).get('enabled',False)) for k in ['ancient_trunk','branching_crown','built_detail','canopy_atlas']},
     required_when_enabled=['stormheart_cut_wood.gdshader + T_WoodTrim_BaseColor.png for built_detail',
                            'stormheart_canopy.gdshader + original leaf_atlas for canopy_atlas'],
     limits='Do not count preloaded but unbound candidate shaders/textures as rendered. Do not require flag-off candidates in the current mounted family census.'),
dict(family='glass_field_legacy',prefix='GlassFieldPresentation',owner='stormwood_glass_field.gd:65-70,300-413',
     mode='legacy_default' if not glass.get('scorched_scars',False) else 'scorched_candidate',
     expected_authored_geometry={'clusters':len(glass['clusters']),'strike_scars':len(glass['clusters']),
                                'shards':sum(c['shards'] for c in glass['clusters']),
                                'fissures':3*len(glass['clusters']),'blasted_trees':len(glass['blasted_trees']),
                                'tether_standards':len(glass['tether_standards'])},
     required=['Bound plain-colour legacy fused_ground, alpha/glass and fissure glow',
               'Installed dead-tree and tether banner materials'],
     limits='Counts are source-authored logical meshes, not a guaranteed census surface count. Current scorched_scars false: no scorched-ground candidate, low smoked-glass variant or clearing approval.'),
dict(family='rod_line',prefix='StormwoodRodLine',owner='stormwood_rod_line.gd:143-178,229-237; tether_pylon_materials.gd:3-47',
     mode='production_default_state_dependent',aftermath_flag=configs['stormwood_rod_line'].get('aftermath_flag'),
     required=['tether_pylon_albedo.png override while long storm not ended; dead atlas after ended',
               'Plain copper cable material','Unshaded violet charge beads while lit'],
     limits='Imported pylon mesh-source null is intentional; active override null is not. Fresh reset does not earn aftermath; do not certify dead state if only live state is mounted.'),
dict(family='crown_stones_and_records',prefixes=['CrownHeartstone','CrownRecords'],owner='stormwood_crown.gd:12-30; stormwood_crown_records.gd:132-155',
     mode='production_default',required=['Rock_Medium_3 imported surface binding at Heartstone',
                                        'Installed record stones and plain-emissive RecordGlyph material'],
     limits='Reaching/story flags enable prompts; they do not demonstrate shader load. Scene visibility is not pixel exposure.'),
dict(family='dynamo_arena',prefix='StormwoodDynamo/DynamoArena',owner='stormwood_dynamo.gd::mount; stormwood_dynamo_arena.gd:12-96',
     mode='production_default',expected_authored_geometry={'banks':configs['stormwood_dynamo']['bank_count'],
                                                       'discharge_lanes':configs['stormwood_dynamo']['bank_count'],
                                                       'grounded_plates':len(configs['stormwood_dynamo']['plates'])},
     required=['Shared live pylon atlas override','Plain emissive lanes/plates','Plain metal deck infill'],
     limits='Dynamic phase changes charge/glow/readout; one default census is not overload/break/released phase proof.'),
dict(family='capacitor_grove',prefix_suffix='CapacitorGrovePresentation',owner='stormwood_arch_runtime.gd::_build_footings; stormwood_capacitor_grove.gd',
     mode='production_default_footing',required=['Installed pylon override','Plain metallic plinth/vane materials','Plain glowing rings/core'],
     limits='Grove is mounted from configured capacitor_grove footing. Built player-made arch pieces absent from fresh world do not become renderer proof.'),
dict(family='sentinel',prefix='StruckSentinelPresentation',owner='stormwood_world.gd::_build_landmark_masses; stormwood_struck_sentinel.gd',
     mode='production_default',required=['Imported dead-tree/rock surfaces','Plain char-colour scar/glow stroke materials'],
     limits='Prior entrance originals can be reused for pixel subset; a late stand census records the currently mounted sentinel even if outside camera.'),
dict(family='camps',prefix='StormwoodCamps',owner='stormwood_camps.gd:42-61,88-109',mode='production_default',
     configured_ids=[c['id'] for c in configs['stormwood_camps']['camps']],
     required=['Installed camp tent/fire/firewood assets as each camp config selects',
               'Dead pylon atlas on friendly lightning-rod props'],
     limits='Camps all build after config validation. Recovery unlocks differ from material mounting. Missing prop path emits ERROR and skips geometry; remaining props do not certify omitted props.'),
dict(family='pickups_and_shafts',prefix='StormwoodPickups',owner='stormwood_pickup_runtime.gd::sync_progression/shaft_material',
     mode='progression_and_taken_state_dependent',required=['Explicit six item metadata fallbacks use existing orb/potion assets',
                                                         'Inline procedural shaft shader and plain halos for current mounted rewards'],
     limits='Requires_unlock/taken-state can omit rewards. Empty inline shader path is expected. Do not grant unlocked/reload/reward art approval for absent nodes.'),
dict(family='surge_lightning',prefix='StormwoodLightning',owner='stormwood_lightning.gd',
     mode='transient_phase_event',required_when_mounted=['Actual bolt/corona/impact material resources'],
     limits='One daytime/default census may contain no current strike. Do not inject phase/flags or claim full Surge appearance; reuse any actual retained strike materials/images only at their precise source scope.')]
report=dict(scope='Ignored pinned source matrix only; no actual renderer/material/visual criterion verdict.',source_commit=source,
            canonical_git_config_hashes=hashes,production_assumption='Native production scene simulation_only false; actual catalogue reset and source pin must be retained.',
            flags={'stormheart_enabled':tree.get('enabled',False),'stormheart_ground_shell_base':tree.get('ground_shell_base'),
                   'glass_scorched_scars':glass.get('scorched_scars',False),'grass_field_enabled':configs['grass_field'].get('enabled',False)},
            rows=rows,limits=['No source-based global MET. Actual direct bindings, nulls, limits/truncations and native raw logs need independent review.',
                              'Current flag-off candidates remain off; no request to repair or enable them follows from this matrix.',
                              'Logical mesh counts differ from imported/multisurface binding counts; compare actual node prefixes and binding signatures.'])
out=Path('.tmp/f26-storm-expected-families.json')
out.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'output':str(out),'source_commit':source,'flags':report['flags'],'families':len(rows),
                  'terrain_texture_names':[t['name'] for t in terrain['textures']],
                  'glass_counts':rows[4]['expected_authored_geometry'],'camps':rows[10]['configured_ids']},indent=2))
