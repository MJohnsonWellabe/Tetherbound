"""Build bounded shared-owner proposals in ignored .tmp; never edit shared files."""
from pathlib import Path
import difflib
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.tmp/f30-authority'
OUT.mkdir(parents=True, exist_ok=True)
changes = {}
baseline = {}
groups = {}

def read(path):
    return ROOT.joinpath(path).read_text(encoding='utf-8')

def edit(path, old, new, group='runtime'):
    source = changes.get(path, read(path))
    assert source.count(old) == 1, f'Changed shared anchor: {path}: {old!r}'
    baseline.setdefault(path, read(path))
    changes[path] = source.replace(old,new,1)
    groups[path] = group

def replace_json(path, value, group='schema'):
    baseline[path] = read(path)
    changes[path] = json.dumps(value,indent=2)+'\n'
    groups[path] = group

cfg = json.loads(read('data/config/traits.json'))
ids = list(cfg['traits'])
# Expand Foundation's strict schema catalogue; each id retains exact
# effect/rarity/magnitude linkage. Unknown or missing ids continue failing.
traits = [{'id':id,'rarity':r['rarity'],'effect':r['effect'],
           'magnitude':abs(r['magnitude'])} for id,r in cfg['traits'].items()]
replace_json('data/schema/traits.json',traits)
trait_schema = json.loads(read('data/schema/traits.schema.json'))
item = trait_schema['items']
item['properties']['id']['enum'] = ids
item['properties']['effect']['enum'] = list(dict.fromkeys(r['effect'] for r in traits))
item['oneOf'] = [{'properties':{k:{'const':r[k]} for k in ['id','rarity','effect','magnitude']}} for r in traits]
trait_schema['minItems'] = len(traits)
trait_schema['maxItems'] = len(traits)
replace_json('data/schema/traits.schema.json',trait_schema)
character_schema = json.loads(read('data/schema/character_state.schema.json'))
record = character_schema['properties']['creatures']['additionalProperties']
record['properties']['rolled_traits']['items']['enum'] = ids
record['properties']['rolled_traits']['maxItems'] = 3
for slot in record['properties']['taught_traits']['properties'].values(): slot['enum'] = ids
record['properties']['traits_initialized'] = {'type':'boolean'}
record['properties']['captured_from'] = {
    'type':'object','properties': {
        'kind':{'type':'string','const':'wild'},
        'world_namespace':{'type':'string','minLength':1},
        'spawn_id':{'type':'string','minLength':1},
        'spawn_generation':{'type':'integer','minimum':1,'maximum':2147483647}},
    'required':['kind','world_namespace','spawn_id','spawn_generation'],
    'additionalProperties':False}
replace_json('data/schema/character_state.schema.json',character_schema)
scopes = json.loads(read('data/progression/flag_scopes.json'))
fields = scopes.get('fields',scopes.get('scopes',scopes))
# Current registry contains dotted field keys; preserve its actual container.
for container in scopes.values():
    if isinstance(container,dict) and 'redesign_character.creatures.<uid>.rolled_traits' in container:
        fields = container
for field in ['traits_initialized','captured_from']:
    source = fields['redesign_character.creatures.<uid>.rolled_traits'].copy()
    source['transaction'] = 'Host spawn/catch admission; exact stable-character/current-generation same-record CAS; portable bool-save ACK; release removes UID atomically with F27 essence and one seed.'
    fields['redesign_character.creatures.<uid>.'+field] = source
replace_json('data/progression/flag_scopes.json',scopes)

# Frozen F18 item catalogue: proposals only. No icons/assets created.
items = json.loads(read('data/items/items.json'))
for id,row in cfg['traits'].items():
    items['items'][row['seed_item']] = {
        'name':row['display_name']+' Trait Seed','kind':'trait_seed','stack':99,
        'trait_id':id,'rarity':row['rarity'],'sellable':False,
        'colour':{'common':'#b7c9aa','rare':'#91bedb','epic':'#bfacd9'}[row['rarity']],
        'icon':'res://assets/ui/icons/items/stone.png',
        'blurb':row['description'],
        'description':row['description']+' Teach at the Altar in a slot unlocked by an L10, L30 or L50 breakthrough; costs type essence.'}
replace_json('data/items/items.json',items,'items')

# Existing eight use same names/descriptions; avoids old trait-db flavor
# claiming mechanics differ from the unified inspect/effect pool.
legacy = json.loads(read('data/traits/traits.json'))
legacy['traits'] = {id:{'display_name':cfg['traits'][id]['display_name'],'description':cfg['traits'][id]['description']} for id in legacy['traits']}
legacy['_comment'] = 'F30 unified trait display pool. Numeric rules are owned by data/config/traits.json.'
replace_json('data/traits/traits.json',legacy,'runtime')

edit('scripts/creatures/creature_instance.gd',
     'const TRAIT_DB := preload("res://scripts/creatures/trait_db.gd")',
     'const TRAIT_DB := preload("res://scripts/creatures/trait_db.gd")\nconst TRAITS := preload("res://scripts/creatures/traits.gd")')
edit('scripts/creatures/creature_instance.gd','var trait_secondary: String = ""',
     'var trait_secondary: String = ""\n## Runtime projections of the one canonical redesign_character UID row.\nvar traits_initialized := false\nvar rolled_traits: Array = []\nvar taught_traits: Dictionary = {}')
edit('scripts/creatures/creature_instance.gd',
     '\tdefence = PROGRESSION.stat_at_level(base_defence, level, float(growth.get("defence", 0.0)))',
     '\tmax_hp = TRAITS.apply_value(self,"max_hp",max_hp)\n\tdefence = PROGRESSION.stat_at_level(base_defence, level, float(growth.get("defence", 0.0)))')
edit('scripts/creatures/creature_instance.gd','\treturn scaled\n\n\n## --- tonics:',
     '\treturn TRAITS.apply_value(self,"defence",scaled)\n\n\n## --- tonics:')
edit('scripts/creatures/creature_instance.gd',
     '\thp = clampf(hp + maxf(0.0, amount), 0.0, max_hp)',
     '\thp = clampf(hp + TRAITS.apply_value(self,"healing",maxf(0.0,amount)), 0.0, max_hp)')
edit('scripts/save/save_game.gd','\t\tcreature.trait_secondary = str(d.get("trait_secondary", ""))',
     '\t\tcreature.trait_secondary = str(d.get("trait_secondary", ""))\n\t\tvar trait_record: Variant = character.get("creatures",{}).get(creature.uid)\n\t\tif trait_record is Dictionary:\n\t\t\tvar normalized := preload("res://scripts/creatures/traits.gd").initialize_legacy_record(d,trait_record)\n\t\t\tif not preload("res://scripts/creatures/traits.gd").project_instance(creature,normalized): return\n\t\t\tcharacter.creatures[creature.uid] = normalized')
# Exact host admission normalizes only legitimate missing v28 fields, with
# all present values validated strictly; no catch provenance is invented.
edit('scripts/net/character_authority.gd',
     'func seed_admitted_character(raw: Dictionary, character_id: String) -> Dictionary:\n',
     '''func seed_admitted_character(raw: Dictionary, character_id: String) -> Dictionary:
\traw = raw.duplicate(true)
\tif raw.get("party") is Array and raw.get("redesign_character") is Dictionary and raw.redesign_character.get("creatures") is Dictionary:
\t\tfor owned: Variant in raw.party:
\t\t\tif owned is Dictionary and raw.redesign_character.creatures.get(owned.get("uid")) is Dictionary:
\t\t\t\traw.redesign_character.creatures[owned.uid] = preload("res://scripts/creatures/traits.gd").initialize_legacy_record(owned,raw.redesign_character.creatures[owned.uid])
''','foundation-admission')
edit('scripts/net/character_authority.gd',
     '\tvar failures := TEACHING.admitted_party_errors(raw.party, raw.redesign_character)',
     '\traw = preload("res://scripts/creatures/traits.gd").normalize_admitted(raw)\n\tvar failures := TEACHING.admitted_party_errors(raw.party, raw.redesign_character)','foundation-admission')
edit('scripts/net/character_authority.gd',
     '\tvar candidate := raw.duplicate(true)',
     '\tvar candidate := preload("res://scripts/creatures/traits.gd").normalize_admitted(raw)','foundation-admission')
edit('scripts/net/character_authority.gd',
     '\treturn {"character_id": personal.get("character_id"), "party": personal.get("party"),',
     '\treturn preload("res://scripts/creatures/traits.gd").normalize_admitted({"character_id": personal.get("character_id"), "party": personal.get("party"),','foundation-admission')
edit('scripts/net/character_authority.gd',
     '\t\t"realm_hearts": personal.get("realm_hearts", {"active_id": ""})}',
     '\t\t"realm_hearts": personal.get("realm_hearts", {"active_id": ""})})','foundation-admission')
edit('scripts/net/character_authority.gd',
     '\tfailures.append_array(REDESIGN.validate("character", raw.redesign_character, REDESIGN.uids(raw.party)))',
     '\tfailures.append_array(REDESIGN.validate("character", raw.redesign_character, REDESIGN.uids(raw.party)))\n\tfor uid: String in raw.redesign_character.get("creatures",{}):\n\t\tfailures.append_array(preload("res://scripts/creatures/traits.gd").trait_state_errors(raw.redesign_character.creatures[uid]))','foundation-admission')

# Formula dispatch. Host damage override is never multiplied a second time.
edit('scripts/combat/combat_manager.gd','const CATCH := preload("res://scripts/combat/catch_math.gd")',
     'const CATCH := preload("res://scripts/combat/catch_math.gd")\nconst TRAIT_EFFECTS := preload("res://scripts/combat/trait_effects.gd")')
edit('scripts/combat/combat_manager.gd',
     '\t\tkilled = _enemy.take_damage(damage)',
     '\t\tdamage = TRAIT_EFFECTS.damage(creature,"quick" if is_quick else "charged",damage)\n\t\tkilled = _enemy.take_damage(damage)')
edit('scripts/combat/combat_manager.gd',
     '\treturn maxf(1.0, float(_poise_config().get("max", 40.0)))\n\n\nfunc _enemy_poise_max',
     '\treturn TRAIT_EFFECTS.stat(active_creature(),"poise",maxf(1.0, float(_poise_config().get("max", 40.0))))\n\n\nfunc _enemy_poise_max')
edit('scripts/combat/combat_manager.gd',
     '\treturn maxf(0.0, float(_wind_config().get(key, 0.0))) if key != "" else 0.0',
     '\treturn TRAIT_EFFECTS.wind_cost(active_creature(),slot,maxf(0.0,float(_wind_config().get(key,0.0)))) if key != "" else 0.0')
edit('scripts/combat/combat_manager.gd',
     '\tif speed_scale != 1.0 and _ally_body.has_method("base_speed"):',
     '\tspeed_scale = TRAIT_EFFECTS.stat(creature_for_speed,"combat_speed",speed_scale)\n\tif speed_scale != 1.0 and _ally_body.has_method("base_speed"):')
edit('scripts/combat/combat_manager.gd',
     '\treturn with_cooldown_multiplier(profile, active_move_cooldown_multiplier())',
     '\treturn TRAIT_EFFECTS.move_profile(active_creature(),with_cooldown_multiplier(profile, active_move_cooldown_multiplier()))')
# Host wind stat-card includes trait projection. Same call serves local wind.
source = changes['scripts/combat/combat_manager.gd']
needle = '"wind_regen_scale": float(creature.call("buff_scale", "wind_regen")) if creature.has_method("buff_scale") else 1.0,'
assert source.count(needle) == 2
changes['scripts/combat/combat_manager.gd'] = source.replace(needle,
    '"wind_regen_scale": TRAIT_EFFECTS.stat(creature,"wind_regen",float(creature.call("buff_scale", "wind_regen")) if creature.has_method("buff_scale") else 1.0),')

# Host cards get effective IDs ONLY from admitted canonical projection.
# No client sends numeric multipliers; Foundation must rebuild this card.
edit('scripts/combat/encounter_director.gd',
     '\t\t"level": int(creature.get("level")),\n\t\t"attack": float(creature.call("effective_attack", cfg)),',
     '\t\t"traits_initialized": true,\n\t\t"rolled_traits": preload("res://scripts/creatures/traits.gd").effective_ids(creature),\n\t\t"taught_traits": {},\n\t\t"level": int(creature.get("level")),\n\t\t"attack": float(creature.call("effective_attack", cfg)),','host-card')
# Effective IDs may exceed the 3 wild cap, so retain actual canonical shape
# instead of flattening into rolled traits. Secondary requires real counters.
changes['scripts/combat/encounter_director.gd'] = changes['scripts/combat/encounter_director.gd'].replace(
    '\t\t"traits_initialized": true,\n\t\t"rolled_traits": preload("res://scripts/creatures/traits.gd").effective_ids(creature),\n\t\t"taught_traits": {},',
    '\t\t"traits_initialized": creature.get("traits_initialized"),\n\t\t"rolled_traits": creature.get("rolled_traits"),\n\t\t"taught_traits": creature.get("taught_traits"),\n\t\t"trait_primary": creature.get("trait_primary"),\n\t\t"trait_secondary": creature.get("trait_secondary"),\n'+
    ''.join(f'\t\t"{m["task"]}": creature.get("{m["task"]}"),\n' for m in json.loads(read('data/config/bond_milestones.json'))['milestones']).rstrip('\n'))
edit('scripts/combat/encounter_director.gd',
     '\t\t"wind_regen_scale": float(creature.call("buff_scale", "wind_regen")),',
     '\t\t"wind_regen_scale": preload("res://scripts/combat/trait_effects.gd").stat(creature,"wind_regen",float(creature.call("buff_scale", "wind_regen"))),','host-card')
edit('scripts/combat/encounter_director.gd',
     '\thost_card_cooldown_multiplier(card), CONTACT_SPACING.pair_reach_need(striker, wild))',
     '\thost_card_cooldown_multiplier(card), CONTACT_SPACING.pair_reach_need(striker, wild))\n\tmove = preload("res://scripts/combat/trait_effects.gd").move_profile(card,move)','host-card')
edit('scripts/combat/encounter_director.gd',
     '\t\tfloat(wind.get("burst_cost", 30.0)), Time.get_ticks_msec(),',
     '\t\tpreload("res://scripts/combat/trait_effects.gd").wind_cost(card,"burst",float(wind.get("burst_cost", 30.0))), Time.get_ticks_msec(),','host-card')
# This patch replaces client-trusted stat cards ONLY when running host combat;
# the existing Session admission method establishes current identity first.
edit('scripts/combat/encounter_director.gd',
     'func _creature_card_for(peer_id: int) -> Dictionary:\n',
     '''func _creature_card_for(peer_id: int) -> Dictionary:
\tif _is_host():
\t\tvar game := get_node_or_null(^"/root/Game")
\t\tvar session: Node = game.get("session") if game != null else null
\t\tif session == null or not session.has_method("admitted_character_state"): return {}
\t\tvar admitted: Dictionary = session.call("admitted_character_state",peer_id)
\t\tvar actor_uid := str(_ally.get("uid")) if peer_id == _local_peer_id() and _ally != null else str(_deployed_by.get(peer_id,{}).get("card",{}).get("creature_uid",""))
\t\tvar canonical: RefCounted = preload("res://scripts/creatures/trait_actor_projection.gd").creature(admitted,actor_uid)
\t\tif canonical == null: return {}
\t\tvar output := _creature_card(canonical)
\t\tvar is_best: bool = admitted.redesign_character.creatures.get(actor_uid,{}).get("best",false)
\t\tvar ability := SPECIES.best_creature_ability(str(canonical.get("species_id"))) if is_best else {}
\t\toutput.defence = canonical.call("effective_defence",PROGRESSION.config(),is_best,ability)
\t\toutput.active_relic_id = admitted.get("realm_hearts",{}).get("active_id","")
\t\treturn output
''','host-card')
edit('scripts/combat/water_alpha.gd',
     '\tvar killed: bool = enemy.take_damage(damage)',
     '\tdamage = preload("res://scripts/combat/trait_effects.gd").damage(card,slot,damage)\n\tvar killed: bool = enemy.take_damage(damage)','water-alpha')
edit('scripts/combat/water_alpha.gd',
     '\t\t1.0, CONTACT_SPACING.pair_reach_need(striker, body))',
     '\t\t1.0, CONTACT_SPACING.pair_reach_need(striker, body))\n\tmove = preload("res://scripts/combat/trait_effects.gd").move_profile(card,move)','water-alpha')
# Host utility receipt uses the same admitted actor trait projection supplied
# in the host-only view. No RPC/client trait-card field is allowed to fill it.
# The current shared caller is not wired yet; Foundation must pass this field.
edit('scripts/net/encounter_host.gd',
     '\tmove = MATH.with_player_pace(move, "player_utility")\n\tvar state:',
     '''\tmove = MATH.with_player_pace(move, "player_utility")
\tvar trait_row: Variant = view.get("host_trait_row")
\tif not trait_row is Dictionary or not preload("res://scripts/creatures/traits.gd").trait_state_errors(trait_row).is_empty():
\t\treturn {"ok":false,"code":"trait_projection_required"}
\tmove = preload("res://scripts/combat/trait_effects.gd").move_profile(trait_row,move)
\tmove.utility.max_hp_fraction = minf(1.0,preload("res://scripts/combat/trait_effects.gd").stat(trait_row,"healing",float(move.utility.max_hp_fraction)))
\tvar state:''','host-heal')

# Host damage resolver uses same row; card.attack already has IV/bond.
edit('scripts/combat/combat_manager.gd',
     '\tvar stagger_crit := false\n\tif _wild != null and _wild.has_method("consume_stagger_critical"):',
     '\tvar move_slot: String = str(_moves.call("move",move_id).get("slot","quick"))\n\tdamage = TRAIT_EFFECTS.damage(card,move_slot,damage)\n\tvar stagger_crit := false\n\tif _wild != null and _wild.has_method("consume_stagger_critical"):')

edit('scripts/world/riding_controller.gd',
     '\treturn _ride_speed_for(str(_mount.get("species_id")))',
     '\tvar rider: RefCounted = _encounter.call("ally_instance") if _encounter != null else null\n\treturn preload("res://scripts/world/trait_traversal.gd").speed(rider,"ride",_ride_speed_for(str(_mount.get("species_id"))))','traversal')
edit('scripts/player/fly_controller.gd',
     'direction * float(config.get("speed_mps", 16.0))',
     'direction * preload("res://scripts/world/trait_traversal.gd").speed(_creature,"fly",float(config.get("speed_mps", 16.0)))','traversal')
edit('scripts/world/water_mounted_swim.gd',
     'direction, delta, float(_species.speed_mps), fighting)',
     'direction, delta, preload("res://scripts/world/trait_traversal.gd").speed(_instance,"swim",float(_species.speed_mps)), fighting)','traversal')
edit('scripts/world/water_riding_controller.gd',
     '\t\treturn float(SPECIES.definition(str(mount_body().species_id)).get("swim_mount", {}).get("speed_mps", 0.0))',
     '\t\tvar swimmer: RefCounted = _encounter.call("ally_instance") if _encounter != null else null\n\t\treturn preload("res://scripts/world/trait_traversal.gd").speed(swimmer,"swim",float(SPECIES.definition(str(mount_body().species_id)).get("swim_mount", {}).get("speed_mps", 0.0)))','traversal')

# Existing inspect labels get unified effects (new owned readout can be used
# by F42); no legacy raw hidden-secondary reads added.
path = 'scripts/ui/tab_creatures.gd'
source = read(path)
start = source.index('\tvar primary := str(creature.get("trait_primary"))')
end = source.index('\t# An untraited creature collapses both lines',start)
baseline[path] = source
changes[path] = source[:start] + '''\tvar trait_rows := preload("res://scripts/creatures/traits.gd").rows(creature)
\tvar trait_names: Array[String] = []
\tvar trait_effects: Array[String] = []
\tfor row: Dictionary in trait_rows:
\t\ttrait_names.append("%s (%s)" % [row.display_name,row.rarity])
\t\ttrait_effects.append(row.description)
\t_detail_traits.text = "Traits: " + ", ".join(trait_names) if not trait_names.is_empty() else "No active traits"
\t_detail_trait_desc.text = "\\n".join(trait_effects)

''' + source[end:]
groups[path] = 'readout'

# Actual lawful catch aim readout, populated from the manager's host-backed
# wild instance. Reused widget only rebuilds when its trait rows change.
edit('scripts/ui/combat_hud.gd',
     'func _update_capture_reticle() -> void:\n',
     '''var _f30_catch_traits: VBoxContainer

func _update_capture_reticle() -> void:
\tif _f30_catch_traits == null:
\t\t_f30_catch_traits = preload("res://scripts/ui/creature_trait_readout.gd").new()
\t\t_f30_catch_traits.position = Vector2(36,430)
\t\t_f30_catch_traits.custom_minimum_size.x = 440
\t\t_f30_catch_traits.mouse_filter = Control.MOUSE_FILTER_IGNORE
\t\t$Root.add_child(_f30_catch_traits)
\t_f30_catch_traits.visible = _manager != null and bool(_manager.call("is_aiming")) and not bool(_manager.get("_enemy_owned"))
\tif _f30_catch_traits.visible:
\t\t_f30_catch_traits.call("show_creature",_manager.call("enemy"))
''','readout')

# Existing F27 Altar source is a frozen dependency cut absent from this
# branch. Its bounded patch is based on the current producer worktree only.
altar_path = 'scripts/ui/altar_panel.gd'
altar_source = ROOT.parent/'redesign-training'/altar_path
if altar_source.exists():
    source = altar_source.read_text(encoding='utf-8')
    anchor = '\t_label(layout, "A Choose / Raise level · B Leave")'
    assert source.count(anchor) == 1, 'F27 Altar source cut changed'
    baseline[altar_path] = source
    changes[altar_path] = source.replace(anchor,
        '\tvar trait_button := _button(layout,"Traits and Trait Seeds",_open_traits)\n'+
        '\ttrait_button.disabled = not _pending_id.is_empty()\n'+
        '\tpayment_buttons.append(trait_button)\n'+anchor,1) + '''

func _open_traits() -> void:
\tif not _pending_id.is_empty(): return
\tvar key := _station_key
\tvar game := get_node_or_null(^"/root/Game")
\tvar traits_service: Node = preload("res://scripts/ui/altar_traits_service.gd").attach(game)
\tif traits_service == null: return
\tclose()
\ttraits_service.call("open",key)
'''
    groups[altar_path] = 'altar-F27-cut'

hashes = []
for group in sorted(set(groups.values())):
    diff = []
    for path in sorted(changes):
        if groups[path] != group: continue
        diff.extend(difflib.unified_diff(baseline[path].splitlines(True),changes[path].splitlines(True),fromfile='a/'+path,tofile='b/'+path))
        dest = OUT/'after'/path
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(changes[path].encode('utf-8'))
        before = OUT/'before'/path
        before.parent.mkdir(parents=True,exist_ok=True)
        before.write_bytes(baseline[path].encode('utf-8'))
        hashes.append({'path':path,'group':group,'before_sha256':hashlib.sha256(baseline[path].encode()).hexdigest(),
                       'after_sha256':hashlib.sha256(changes[path].encode()).hexdigest()})
    (OUT/(group+'.patch')).write_bytes(''.join(diff).encode('utf-8'))
(OUT/'source-cut.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
print(f'F30 generated {len(hashes)} isolated shared-owner file proposals in {OUT}')
