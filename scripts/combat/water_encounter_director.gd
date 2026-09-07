extends "res://scripts/combat/cloudreach_encounter_director.gd"

## Water content over the shared production combat pipeline. Residency is the
## union of occupied Water peer neighborhoods, including a remote island when
## this world's local rig is only a host simulation. Story bosses stay external.
const WATER_DATA := preload("res://scripts/world/water_encounter_runtime_data.gd")
const RANKS := preload("res://scripts/characters/npc_ranks.gd")
const INTERACTION := preload("res://scripts/world/interactable.gd")
var _wanted_sites: Dictionary = {}
var _restoring_surface_position := Vector3.INF


## Surface sites are explicit open-water ecology, never land bodies with their Y
## spoofed once at spawn. CreatureBody still owns all horizontal peace/combat
## movement; this Water-only subtype replaces ground seating and clamps its
## origin after inherited physics so gravity cannot sink it toward the seabed.
class SurfaceWild:
	extends "res://scripts/creatures/wild_creature.gd"
	var water_surface_y := 0.0
	var surface_submerge_fraction := 0.28

	func configure_water_surface(surface_y: float, submerge_fraction: float) -> void:
		water_surface_y = surface_y
		surface_submerge_fraction = clampf(submerge_fraction, 0.0, 0.5)

	func surface_origin_y() -> float:
		return water_surface_y - float(call("body_height")) * surface_submerge_fraction

	func place_on_ground(target: Vector3) -> bool:
		global_position = Vector3(target.x, surface_origin_y(), target.z)
		velocity = Vector3.ZERO
		return true

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		var at := global_position
		at.y = surface_origin_y()
		global_position = at
		velocity.y = 0.0

## Resolve a reserved site without rolling its random table. The two authored
## references must agree; a missing/mismatched named row never becomes a random
## substitute. This plan is also the integration seam for host-owned spawning.
static func named_spawn_plan(site: Dictionary, named_encounters: Array) -> Dictionary:
	var id := str(site.get("named_replacement_id", ""))
	if id.is_empty():
		return {}
	var named := find_id(named_encounters, id)
	if named.is_empty() or str(named.get("replaces_wild_site_id", "")) != str(site.get("id", "")) \
			or bool(named.get("trainer_owned", true)) or not bool(named.get("catchable", false)):
		return {}
	return {"id": id, "species": str(named.get("species", "")),
		"position": named.get("position", []).duplicate(),
		"display_name": str(named.get("display_name", id)),
		"reward_role": str(named.get("reward_role", "")),
		"opts": {"name": id, "once_id": str(named.get("completion_flag", "")),
			"level": int(named.get("level", 1)), "aggressive": false,
			"wander_radius": float(site.get("roam_radius_m", site.get("radius_m", 4)))}}

## Rebuild the saved owner's existing party member through the deployment seam.
## A surface swimmer must not be placed on the seabed by the land spawn helper.
func restore_swim_mount(saved: Dictionary) -> bool:
	var party := _party()
	var creature: RefCounted = party.at(int(saved.party_index)) if party != null else null
	if creature == null or str(creature.species_id) != str(saved.species_id) \
			or creature.fainted or creature.resting:
		return false
	var definition: Dictionary = preload("res://scripts/creatures/creature_species.gd").definition(str(creature.species_id))
	if not bool(definition.get("swim_mount", {}).get("compatible", false)):
		return false
	var riding: Node = get_parent().get_node("RidingController")
	if not riding._has_tack(str(creature.species_id)):
		return false
	if riding.is_mounted():
		riding.dismount()
	if is_instance_valid(_ally_body) and not dismiss_active_creature():
		return false
	if not party.set_active(int(saved.party_index)):
		return false
	var raw: Array = saved.position
	_restoring_surface_position = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var spawned := await _spawn_ally_body(creature)
	_restoring_surface_position = Vector3.INF
	if not spawned:
		return false
	# No frame advances between revealing the body and attaching its rider.
	_player.global_position = _ally_body.global_position + Vector3.UP
	_ally_body.velocity = Vector3.ZERO
	return riding.mount()

func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	if _restoring_surface_position.is_finite() and body == _ally_body:
		body.global_position = _restoring_surface_position
		return true
	return await super._stand_on_ground(body, spot)

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
			var opts := {"name": "%s_%d" % [id, index],
				"site_anchor": centre, "level": selected.level, "aggressive": false,
				"wander_radius": float(site.get("radius_m", 4))}
			var wild: Node3D
			if str(site.get("placement_mode", "ground")) == "water_surface":
				var member_at := _surface_member_position(centre, int(site.get("count", 1)), index,
					float(site.get("radius_m", 4.0)))
				wild = _spawn_surface_wild(str(selected.species), member_at, opts,
					float(site.get("surface_y_m", centre.y)),
					float(site.get("surface_submerge_fraction", 0.28)))
			else:
				wild = spawn_wild(str(selected.species), centre, opts)
			if wild != null:
				wild.set_meta("water_site_id", id)
				wild.set_meta("water_placement_mode", str(site.get("placement_mode", "ground")))
				members.append(wild)
				_wild_respawn[wild] = float(encounter_config.get("wild_respawn_seconds", 240))
		_site_members[id] = members
		if members.size() == int(site.get("count", 1)):
			_site_spawned[id] = true
		else:
			_site_failures[id] = true
			push_warning("Water site lacks supported creature footing: " + id)


static func _surface_member_position(centre: Vector3, count: int, index: int, radius: float) -> Vector3:
	if count <= 1:
		return centre
	var angle := TAU * float(index) / float(count)
	var spread := minf(maxf(radius * 0.55, 2.0), 4.0)
	return centre + Vector3(cos(angle) * spread, 0.0, sin(angle) * spread)


func _spawn_surface_wild(species: String, spot: Vector3, opts: Dictionary,
		surface_y: float, submerge_fraction: float) -> Node3D:
	if not SPECIES.has(species):
		push_error("spawn_surface_wild('%s') names a species that is not in species.json" % species)
		return null
	var once_id := str(opts.get("once_id", ""))
	if _once_cleared(once_id):
		return null
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(SurfaceWild)
	wild.name = str(opts.get("name", "SurfaceWild_%s_%d" % [species, _wild_creatures.size() + 1]))
	var parent: Node = opts.get("parent", null) as Node
	if not is_instance_valid(parent):
		parent = get_parent()
	parent.add_child(wild)
	wild.call("populate", species, _player)
	var opt_combat: Variant = opts.get("combat", {})
	if opt_combat is Dictionary and not opt_combat.is_empty():
		wild.set("combat_override", opt_combat.duplicate(true))
	var level := int(opts.get("level", 0))
	if level > 0:
		_set_fixed_level(wild, species, level)
	if opts.has("aggressive"):
		wild.set("aggressive", bool(opts.aggressive))
	var wild_cfg: Dictionary = MATH.config().get("wild", {}).duplicate()
	if opts.has("wander_radius"):
		wild_cfg["wander_radius"] = opts.wander_radius
	wild.call("configure", wild_cfg)
	wild.call("configure_water_surface", surface_y, submerge_fraction)
	if not bool(wild.call("place_on_ground", spot)):
		wild.free()
		return null
	wild.set("home", wild.global_position)
	wild.set("_target", wild.global_position)
	_wild_homes[wild] = wild.global_position
	wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
	_wild_creatures.append(wild)
	if not once_id.is_empty():
		_once_only[wild] = once_id
	return wild

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
