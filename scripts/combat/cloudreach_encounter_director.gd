extends "res://scripts/combat/encounter_director.gd"

## Realm-specific content and placement over the production Meadows combat path.
## The root world supplies paths and setup BEFORE adding this node to the tree.
## No default starter, species stat fork, capture rule fork or sixth party slot.
signal trainer_started(id: String)
signal trainer_opposition_changed(id: String, remaining: int, initial: int)
signal trainer_victory(id: String)
signal trainer_lost(id: String)
signal population_ready()

const SURFACE := preload("res://scripts/combat/cloudreach_combat_surface.gd")
const NPC_BODY := preload("res://scripts/npc/npc_body.gd")
const NPC_MODEL := preload("res://scripts/characters/character_model.gd")
const CONFIG_PATH := "res://data/config/cloudreach_encounters.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const PAYOFF_PATH := "res://data/config/cloudreach_npc_runtime.json"

var realm_world: Node
var chapter: Dictionary = {}
var encounter_config: Dictionary = {}
var reused_npcs: Dictionary = {}
var trainer_specs: Dictionary = {}
var trainer_nodes: Dictionary = {}
var trainer_prompts: Dictionary = {}
var _site_spawned: Dictionary = {}
var _surface_nodes: Dictionary = {}


static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}


static func find_id(entries: Array, id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func trainer_spec(authored: Dictionary, placement: Dictionary, data: Dictionary) -> Dictionary:
	var spec := authored.duplicate(true)
	spec["config_key"] = authored.get("body_profile", "")
	spec["chapter_rank"] = authored.get("rank", "local")
	# Rank names in this chapter are gameplay tiers, not NPC_RANKS palette keys.
	spec["rank"] = ""
	spec["rechallenge"] = false
	spec["requires_flags"] = placement.get("requires_flags", [])
	spec["position"] = placement.get("position", [])
	spec["reward"] = data.get("reward_tiers", {}).get(spec["chapter_rank"], {}).duplicate(true)
	var team: Array = []
	var profiles: Array = placement.get("behavior_sequence", [])
	for slot: Dictionary in authored.get("team_contract", {}).get("slots", []):
		var entry := {"species": slot.get("placeholder_species", ""), "level": slot.get("level", 1)}
		if team.size() < profiles.size():
			entry["combat"] = data.get("behavior_profiles", {}).get(str(profiles[team.size()]), {}).duplicate(true)
		team.append(entry)
	spec["team"] = team
	return spec


static func roll_wild(table: Dictionary, seed_value: int, ordinal: int) -> Dictionary:
	var entries: Array = table.get("entries", [])
	var total := 0
	for entry: Dictionary in entries:
		total += maxi(0, int(entry.get("weight", 0)))
	if total <= 0:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [table.get("selection_key", ""), seed_value, ordinal])
	var pick := rng.randi_range(1, total)
	for entry: Dictionary in entries:
		pick -= maxi(0, int(entry.get("weight", 0)))
		if pick <= 0:
			var levels: Array = table.get("level_range", [1, 1])
			return {"species": entry["placeholder_species"],
				"level": rng.randi_range(int(levels[0]), int(levels[1]))}
	return {}


func setup(world: Node, bodies: Dictionary = {}, data: Dictionary = {}) -> void:
	realm_world = world
	reused_npcs = bodies
	chapter = read_json(CHAPTER_PATH)
	encounter_config = read_json(CONFIG_PATH) if data.is_empty() else data.duplicate(true)
	default_starter = ""
	for placement: Dictionary in encounter_config.get("trainers", []):
		var authored := find_id(chapter.get("trainer_ladder", []), str(placement["id"]))
		if not authored.is_empty():
			trainer_specs[str(placement["id"])] = trainer_spec(authored, placement, encounter_config)
	_install_circuit_rematch()


## A separate saved encounter, not an endlessly rechallengeable first fight.
## It shares Tavi's existing body and normal round/reward pipeline.
func _install_circuit_rematch() -> void:
	var rematch: Dictionary = read_json(PAYOFF_PATH).get("world_payoffs", {}).get("tavi_rematch", {})
	var base_id := str(rematch.get("base_id", ""))
	var id := str(rematch.get("id", ""))
	if id.is_empty() or trainer_specs.has(id) or not trainer_specs.has(base_id):
		return
	var base := find_id(encounter_config.get("trainers", []), base_id)
	var placement := base.duplicate(true)
	placement["id"] = id
	placement["requires_flags"] = rematch.get("requires_flags", []).duplicate()
	var spec := trainer_specs[base_id].duplicate(true) as Dictionary
	spec["id"] = id
	spec["name"] = rematch["name"]
	spec["defeat_flag"] = rematch["defeat_flag"]
	spec["requires_flags"] = placement["requires_flags"]
	spec["rechallenge"] = false
	spec["reward"] = encounter_config.get("reward_tiers", {}).get(rematch.get("reward_tier", "ace"), {}).duplicate(true)
	for member: Dictionary in spec["team"]:
		member["level"] = int(member["level"]) + int(rematch.get("level_bonus", 3))
	trainer_specs[id] = spec
	encounter_config["trainers"].append(placement)


func _spawn_creatures() -> void:
	# Deliberately never calls the Meadows population or default-starter builder.
	await get_tree().physics_frame
	_build_trainers()
	_spawn_available_sites()
	population_ready.emit()


func _flags_hold(flags: Array) -> bool:
	var progression := _progression()
	if progression == null:
		return flags.is_empty()
	for flag: String in flags:
		if not bool(progression.call("has", flag)):
			return false
	return true


func can_challenge(spec: Dictionary) -> bool:
	return trainer_specs.has(str(spec.get("id", ""))) \
		and _flags_hold(spec.get("requires_flags", [])) and super.can_challenge(spec)


func _process(delta: float) -> void:
	super._process(delta)
	_spawn_available_sites()
	for id: String in trainer_prompts:
		var prompt: Node = trainer_prompts[id]
		prompt.set("enabled", can_challenge(trainer_specs[id]))
	# Inherited streaming only tracks Meadows clusters. Our small authored sites
	# use full 3D distance, so a body stacked far above the player stays asleep.
	for wild: Node3D in _wild_creatures:
		if not is_instance_valid(wild) or wild == _engaged_with or not wild.visible:
			continue
		var active := wild.global_position.distance_to(_player.global_position) \
			<= float(encounter_config.get("activation_distance_m", 130.0))
		wild.set_physics_process(active)


func _build_trainers() -> void:
	for placement: Dictionary in encounter_config.get("trainers", []):
		var id := str(placement["id"])
		if not trainer_specs.has(id):
			continue
		var spec: Dictionary = trainer_specs[id]
		var npc: Node3D = reused_npcs.get(str(placement.get("reuse_npc_id", ""))) as Node3D
		if npc == null:
			npc = NPC_BODY.new()
			npc.name = id
			get_parent().add_child(npc)
			npc.call("setup_from_config", NPC_MODEL.config_for(str(spec["config_key"])), _player)
			var spot := _vector3_of(spec["position"])
			if not bool(npc.call("stand_at", spot.x, spot.z, spot.y)):
				push_error("Cloudreach trainer has no authored floor: " + id)
				npc.queue_free()
				continue
		trainer_nodes[id] = npc
		var prompt: Node = npc.call("add_prompt", "Challenge %s" % spec["name"],
			float(encounter_config.get("trainer_prompt_radius_m", 4.2)))
		prompt.connect("activated", _challenge.bind(id))
		trainer_prompts[id] = prompt


func _challenge(id: String) -> void:
	if not trainer_specs.has(id) or not trainer_nodes.has(id):
		return
	var prompt: Node = trainer_prompts[id]
	if prompt.call("interaction_offer", _player.global_position).is_empty():
		return
	begin_trainer_battle(trainer_specs[id], trainer_nodes[id])


func _spawn_available_sites() -> void:
	for site: Dictionary in encounter_config.get("wild_sites", []):
		var id := str(site["id"])
		if _site_spawned.has(id):
			continue
		var table := find_id(chapter.get("encounter_tables", []), str(site["table_id"]))
		var gate := str(table.get("requires_unlock", ""))
		if table.is_empty() or (not gate.is_empty() and not _flags_hold([gate])):
			continue
		var centre := _vector3_of(site["position"])
		if _player == null or centre.distance_to(_player.global_position) > float(encounter_config.get("activation_distance_m", 130.0)):
			continue
		_site_spawned[id] = true
		for index in int(site.get("count", 1)):
			var selected := roll_wild(table, world_seed(), hash(id) + index)
			if selected.is_empty():
				continue
			var angle := index * TAU / maxi(1, int(site.get("count", 1)))
			var at := centre + Vector3(cos(angle), 0, sin(angle)) * float(site.get("radius_m", 4.0)) * 0.5
			var wild := spawn_wild(str(selected["species"]), at, {"name": "%s_%d" % [id, index],
				"level": selected["level"], "aggressive": false, "wander_radius": float(site.get("radius_m", 4.0)),
				"combat": encounter_config.get("behavior_profiles", {}).get("scout", {})})
			if wild != null:
				_wild_respawn[wild] = float(encounter_config.get("wild_respawn_seconds", 180.0))
				if not gate.is_empty():
					_wild_gates[wild] = {"cloudreach_requires_flags": [gate]}


func _gate_active(gate: Dictionary) -> bool:
	return _flags_hold(gate.get("cloudreach_requires_flags", [])) and super._gate_active(gate)


func _surface_for(body: Node3D, spot: Vector3) -> void:
	if not _surface_nodes.has(body.get_instance_id()):
		var surface := SURFACE.new()
		surface.world = realm_world
		surface.body = body
		surface.reference_y = spot.y
		body.add_child(surface)
		_surface_nodes[body.get_instance_id()] = weakref(surface)
		body.set("_ground_source", surface)
	# Set the correct stratum BEFORE production place_on_ground/footprint queries.
	body.global_position = spot


func spawn_wild(species: String, spot: Vector3, opts: Dictionary = {}) -> Node3D:
	var wild := super.spawn_wild(species, spot, opts)
	if wild != null:
		_surface_for(wild, spot)
		wild.call("place_on_ground", spot)
		wild.set("home", wild.global_position)
	return wild


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	_surface_for(body, spot)
	return await super._stand_on_ground(body, spot)


func _start_fight(wild: Node3D, opponent_owned: bool = false) -> void:
	_surface_for(wild, Vector3(wild.global_position.x, _player.global_position.y, wild.global_position.z))
	super._start_fight(wild, opponent_owned)


func _reground_if_fallen(wild: Node3D) -> void:
	if not is_instance_valid(realm_world) or not realm_world.has_method("ground_height_near"):
		return
	var at := wild.global_position
	var ground := float(realm_world.call("ground_height_near", at))
	if not is_nan(ground) and at.y < ground - REGROUND_DEPTH_M:
		wild.call("place_on_ground", Vector3(at.x, ground, at.z))


func begin_trainer_battle(spec: Dictionary, trainer: Node3D = null) -> bool:
	var started := super.begin_trainer_battle(spec, trainer)
	if started:
		trainer_started.emit(str(spec["id"]))
		trainer_opposition_changed.emit(str(spec["id"]), TRAINERS.team_of(spec).size(), TRAINERS.team_of(spec).size())
	return started


func _on_trainer_round_ended(outcome: String) -> void:
	var id := trainer_battle_id()
	var total := TRAINERS.team_of(_trainer_spec).size()
	if outcome == "won":
		trainer_opposition_changed.emit(id, _trainer_queue.size(), total)
	super._on_trainer_round_ended(outcome)


func _finish_trainer_battle(won: bool) -> void:
	var id := trainer_battle_id()
	super._finish_trainer_battle(won)
	if not won and not id.is_empty():
		trainer_lost.emit(id)


func _record_trainer_defeat(spec: Dictionary) -> void:
	var progression := _progression()
	if progression == null or bool(progression.call("has", str(spec.get("defeat_flag", "")))):
		return
	# Emitted only from inherited final-round victory. A finale subscriber can
	# dispatch its canonical chapter event before the defeat marker is written.
	trainer_victory.emit(str(spec["id"]))
	if bool(progression.call("has", str(spec["defeat_flag"]))):
		# The canonical chapter adapter recorded the win. Still pay its ordinary
		# trainer reward once; the initial durable guard prevents repeat payouts.
		_pay_trainer_reward(spec)
	else:
		super._record_trainer_defeat(spec)
