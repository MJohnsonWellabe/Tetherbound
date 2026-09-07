extends "res://scripts/combat/cloudreach_encounter_director.gd"

## Water content over the shared production combat pipeline. Residency is the
## union of occupied Water peer neighborhoods, including a remote island when
## this world's local rig is only a host simulation. Story bosses stay external.
const WATER_DATA := preload("res://scripts/world/water_encounter_runtime_data.gd")
const RANKS := preload("res://scripts/characters/npc_ranks.gd")
const INTERACTION := preload("res://scripts/world/interactable.gd")
var _wanted_sites: Dictionary = {}

func setup(world: Node, bodies: Dictionary = {}, data: Dictionary = {}) -> void:
	realm_world = world
	reused_npcs = bodies
	default_starter = ""
	var translated := WATER_DATA.build(world.get("config"),
		read_json("res://data/config/water_characters.json"),
		read_json("res://data/config/water_encounters.json"),
		Callable(world, "ground_height_at"), data)
	if not bool(translated.ok):
		push_error("Water encounters: " + str(translated.errors))
		return
	chapter = translated.chapter
	encounter_config = translated.encounter_config
	trainer_specs = translated.trainer_specs

func occupied_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	var game := get_node_or_null("/root/Game")
	if game != null and str(game.get("current_realm")) == "water" and is_instance_valid(_player) \
			and not bool(realm_world.get("simulation_only")):
		result.append(_player.global_position)
	for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
		if proxy is Node3D and str(proxy.get("net_realm")) == "water":
			result.append(proxy.global_position)
	return result

## Stable nearest-site selection independently budgets each island neighborhood.
## Combining the points into an average would leave both distant peers empty.
static func select_sites(sites: Array, positions: Array[Vector3], radius: float, cap: int) -> Dictionary:
	var result: Dictionary = {}
	for point: Vector3 in positions:
		var candidates: Array = []
		for site: Dictionary in sites:
			var xyz: Array = site.position
			var distance := point.distance_to(Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2])))
			if distance <= radius:
				candidates.append({"distance": distance, "site": site})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.site.id) < str(b.site.id) if is_equal_approx(a.distance, b.distance) else a.distance < b.distance)
		var count := 0
		for entry: Dictionary in candidates:
			var amount := int(entry.site.get("count", 1))
			if count + amount > cap:
				continue
			count += amount
			result[str(entry.site.id)] = entry.site
	return result

func _spawn_available_sites() -> void:
	var eligible: Array = []
	for site: Dictionary in encounter_config.get("wild_sites", []):
		var table := find_id(chapter.get("encounter_tables", []), str(site.table_id))
		var flags: Array = site.get("requires_flags", []).duplicate()
		var gate := str(table.get("requires_unlock", ""))
		if not gate.is_empty():
			flags.append(gate)
		if not table.is_empty() and _flags_hold(flags):
			eligible.append(site)
	_wanted_sites = select_sites(eligible, occupied_positions(),
		float(encounter_config.get("activation_distance_m", 100)),
		int(encounter_config.get("active_wild_cap_per_peer", 16)))
	for id: String in _wanted_sites:
		if _site_spawned.has(id) or _site_failures.has(id):
			continue
		var site: Dictionary = _wanted_sites[id]
		var table := find_id(chapter.get("encounter_tables", []), str(site.table_id))
		var centre := _vector3_of(site.position)
		var members: Array = []
		for index in int(site.get("count", 1)):
			var selected := roll_wild(table, world_seed(), hash(id) + index)
			if selected.is_empty():
				continue
			var wild := spawn_wild(str(selected.species), centre, {"name": "%s_%d" % [id, index],
				"site_anchor": centre, "level": selected.level, "aggressive": false,
				"wander_radius": float(site.get("radius_m", 4))})
			if wild != null:
				wild.set_meta("water_site_id", id)
				members.append(wild)
				_wild_respawn[wild] = float(encounter_config.get("wild_respawn_seconds", 240))
		_site_members[id] = members
		if members.size() == int(site.get("count", 1)):
			_site_spawned[id] = true
		else:
			_site_failures[id] = true
			push_warning("Water site lacks supported creature footing: " + id)

func _build_trainers() -> void:
	for placement: Dictionary in encounter_config.get("trainers", []):
		var id := str(placement.id)
		var spec: Dictionary = trainer_specs[id]
		var body: Node3D = reused_npcs.get(str(placement.get("reuse_npc_id", "")))
		if body == null:
			body = NPC_BODY.new()
			body.name = id
			get_parent().add_child(body)
			var rank := str(spec.rank)
			var model := RANKS.config_for(rank, str(spec.config_key)) if rank in ["grunt", "officer", "captain"] else NPC_MODEL.config_for(str(spec.config_key))
			if not body.call("setup_from_config", model, _player):
				body.queue_free()
				continue
			var at := _vector3_of(spec.position)
			if not body.call("stand_at", at.x, at.z, at.y):
				push_error("Water trainer lacks physical floor: " + id)
				body.queue_free()
				continue
		trainer_nodes[id] = body
		var prompt := INTERACTION.new()
		prompt.name = "WaterChallenge"
		prompt.configure("Challenge " + str(spec.name), float(encounter_config.get("trainer_prompt_radius_m", 4.2)), false)
		body.add_child(prompt)
		prompt.top_level = true
		prompt.global_position = body.global_position + Vector3(1.5, 1.05, 0)
		prompt.activated.connect(_challenge.bind(id))
		trainer_prompts[id] = prompt

func _process(delta: float) -> void:
	super._process(delta)
	for wild: Node3D in _wild_creatures:
		if is_instance_valid(wild) and wild.visible and wild != _engaged_with and not bool(wild.get("engaged")):
			_set_wild_active(wild, _wanted_sites.has(str(wild.get_meta("water_site_id", ""))))
	for id: String in trainer_prompts:
		var prompt: Node3D = trainer_prompts[id]
		prompt.global_position = trainer_nodes[id].global_position + Vector3(1.5, 1.05, 0)
		if bool(realm_world.get("simulation_only")):
			prompt.enabled = false

# Terrain3D owns its RID directly; retain all footprint rays and slope checks.
func _wild_support_impl(at: Vector3, radius: float, wild: Node3D, query_proxy: Object = null) -> Vector3:
	if not at.is_finite() or not is_instance_valid(realm_world) \
			or not realm_world.has_method("ground_height_near") or not realm_world.is_inside_tree():
		return Vector3.INF
	var ground := float(realm_world.call("ground_height_near", at))
	if not is_finite(ground) or absf(ground - at.y) > WILD_STRATUM_TOLERANCE:
		return Vector3.INF
	var exclusions: Array[RID] = []
	for actor: Variant in [_player, _ally_body, _trainer_body, wild] + _wild_creatures:
		if is_instance_valid(actor) and actor is CollisionObject3D:
			exclusions.append(actor.get_rid())
	var highest := ground
	var query_space: Object = query_proxy if query_proxy != null else (realm_world as Node3D).get_world_3d().direct_space_state
	for i in 9:
		var offset := Vector3.ZERO if i == 0 else Vector3(cos((i-1)*TAU/8.0), 0, sin((i-1)*TAU/8.0)) * radius
		var sample := Vector3(at.x + offset.x, ground, at.z + offset.z)
		var expected := float(realm_world.call("ground_height_near", sample))
		if not is_finite(expected) or absf(expected - ground) > radius * 0.8 + 0.3:
			return Vector3.INF
		var ray := PhysicsRayQueryParameters3D.create(sample + Vector3.UP * 1.6, sample - Vector3.UP * 1.6)
		ray.exclude = exclusions
		var hit: Dictionary = query_space.intersect_ray(ray)
		if hit.is_empty() or (not hit.collider is StaticBody3D and hit.collider != realm_world.get_node("Terrain")) \
				or hit.normal.y < 0.7 or absf(hit.position.y - expected) > 0.35:
			return Vector3.INF
		highest = maxf(highest, float(hit.position.y))
	return Vector3(at.x, highest, at.z)



