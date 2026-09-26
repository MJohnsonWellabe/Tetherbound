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

# Safety tolerances, not encounter-density or difficulty tuning. The complete
# capsule footprint must fit the real collision floor of the authored stratum.
const WILD_FOOT_MARGIN := 0.25
const WILD_PATH_STEP := 0.5
const WILD_STRATUM_TOLERANCE := 4.0
const AIR_PATROL_AUTHORITY_ID := 1
# F06 #4: a summoned companion stands on the trainer's own level. Its floor is
# within RECALL_LEVEL_M of the trainer's, and so is the floor every
# RECALL_PATH_STEP_M on the straight line between them.
const RECALL_LEVEL_M := 1.2
const RECALL_PATH_STEP_M := 0.4
const RECALL_MIN_NORMAL_Y := 0.7
## The companion put on the trainer's own footprint (the last rung) ignores the
## trainer's capsule until they are this far apart, then collides as before.
const RECALL_SHARED_CLEAR_M := 0.6


var _recall_shared_footprint: WeakRef


class CliffWild:
	extends "res://scripts/creatures/wild_creature.gd"
	const PEACEFUL_LEASH_MARGIN_M := 2.0
	var _peaceful_leash_recoveries := 0

	# Main intentionally accepts its last random candidate when all eight
	# clearance attempts fail. On a cliff, that fallback is a fall, not roaming.
	# Keep this stricter contract local; all combat/catch/health remains inherited.
	func _pick_destination() -> Vector3:
		var candidate := super._pick_destination()
		return checked_destination(candidate, global_position, _clearance_check)

	static func checked_destination(candidate: Vector3, current: Vector3, clearance: Callable) -> Vector3:
		if not candidate.is_finite() or (clearance.is_valid() and not bool(clearance.call(candidate))):
			return current
		return candidate

	func _wander(delta: float) -> void:
		super._wander(delta)
		# A safe endpoint is not permission to coast across a corner. Validate
		# the next short movement with the full capsule margin, then brake when
		# collisions or a changed starting point invalidate the original segment.
		if _requested.length_squared() > 0.001 and _clearance_check.is_valid():
			var next := global_position + _requested.normalized() * maxf(0.35, _wander_speed * delta * 2.0)
			if not bool(_clearance_check.call(next)):
				_requested = Vector3.ZERO
				velocity.x = 0.0
				velocity.z = 0.0
				_target = global_position
				_pause_left = 0.3

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		# Endpoint/path validation constrains requested wandering, but physics can
		# still slide a peaceful body off its high-roost shelf. Once it lands on
		# another valid lower stratum, the director's below-ground recovery quite
		# correctly leaves it there; over sustained play that carried one roost
		# creature ~1.5 km into the authored summit road. Its already-validated
		# home is the residency contract. Re-seat only nonaggressive, noncombat
		# bodies that physics has carried beyond their small wander disc.
		if engaged or aggressive or not is_alive() or not home.is_finite() \
				or global_position.distance_to(home) <= _wander_radius + PEACEFUL_LEASH_MARGIN_M:
			return
		if place_on_ground(home):
			_target = home
			_returning_home = false
			_stuck_frames = 0
			_peaceful_leash_recoveries += 1

	func peaceful_leash_recoveries() -> int:
		return _peaceful_leash_recoveries


## The chain bridge is intentionally narrower than the oversized Air roster's
## full capsule. These are authored wildlife silhouettes above that crossing,
## not ground bodies allowed to overhang it. They retain the real creature
## prefab, presentation scale and idle animation, but stay at one deterministic
## host-owned formation point instead of running ground wander/gravity.
class AirPatrolWild:
	extends "res://scripts/creatures/wild_creature.gd"
	var patrol_anchor := Vector3.ZERO
	var patrol_facing := Vector3.FORWARD

	func configure_air_patrol(at: Vector3, facing: Vector3) -> void:
		patrol_anchor = at
		patrol_facing = facing.normalized() if facing.length_squared() > 0.001 else Vector3.FORWARD
		global_position = patrol_anchor
		rotation.y = atan2(patrol_facing.x, patrol_facing.z)
		velocity = Vector3.ZERO

	func _physics_process(_delta: float) -> void:
		if not is_multiplayer_authority():
			return
		global_position = patrol_anchor
		rotation.y = atan2(patrol_facing.x, patrol_facing.z)
		velocity = Vector3.ZERO

var realm_world: Node
var chapter: Dictionary = {}
var encounter_config: Dictionary = {}
var reused_npcs: Dictionary = {}
var trainer_specs: Dictionary = {}
var trainer_nodes: Dictionary = {}
var trainer_prompts: Dictionary = {}
var _site_spawned: Dictionary = {}
var _surface_nodes: Dictionary = {}
var _site_members: Dictionary = {}
var _site_failures: Dictionary = {}
var _wild_homes: Dictionary = {}

# Default-off, read-only diagnostics for the active-roaming probe. No clock or
# counter work is performed by the normal path. The proxy counts actual rays,
# including short-circuited footprints, without branches inside the ray loop.
class WildRayCounter:
	extends RefCounted
	var world: Node3D
	var rays := 0
	func intersect_ray(query: PhysicsRayQueryParameters3D) -> Dictionary:
		rays += 1
		return world.get_world_3d().direct_space_state.intersect_ray(query)

var _wild_diagnostics_enabled := false
var _wild_support_calls := 0
var _wild_support_usec := 0
var _wild_ray_counter := WildRayCounter.new()


func set_wild_diagnostics_enabled(enabled: bool) -> void:
	_wild_diagnostics_enabled = enabled
	_wild_ray_counter.world = realm_world as Node3D


func reset_wild_diagnostics() -> void:
	_wild_support_calls = 0
	_wild_support_usec = 0
	_wild_ray_counter.rays = 0


func wild_diagnostics_snapshot() -> Dictionary:
	return {"enabled": _wild_diagnostics_enabled, "support_calls": _wild_support_calls,
		"rays": _wild_ray_counter.rays, "support_usec": _wild_support_usec}


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


static func air_patrol_member_plan(site: Dictionary, index: int) -> Dictionary:
	var count := maxi(1, int(site.get("count", 1)))
	if index < 0 or index >= count:
		return {}
	var raw_centre: Array = site.get("position", [])
	var raw_axis: Array = site.get("corridor_axis", [1.0, 0.0, 0.0])
	if raw_centre.size() < 3 or raw_axis.size() < 3:
		return {}
	var centre := Vector3(float(raw_centre[0]), float(raw_centre[1]), float(raw_centre[2]))
	var axis := Vector3(float(raw_axis[0]), float(raw_axis[1]), float(raw_axis[2]))
	axis.y = 0.0
	axis = axis.normalized() if axis.length_squared() > 0.001 else Vector3.RIGHT
	var spacing := maxf(0.0, float(site.get("formation_spacing_m", 7.0)))
	var offset := (float(index) - float(count - 1) * 0.5) * spacing
	return {
		"id": "AirPatrol_%s_%d" % [str(site.get("id", "unknown")), index],
		"position": centre + axis * offset,
		"facing": axis,
		"authority_id": AIR_PATROL_AUTHORITY_ID,
	}


static func site_needs_spawn(spawned: Dictionary, failures: Dictionary, id: String) -> bool:
	return not spawned.has(id) and not failures.has(id)


static func keep_trainer_corridor_clear(wild: CollisionObject3D,
		trainer: CollisionObject3D) -> void:
	if wild == null or trainer == null:
		return
	# ROAD pairs are sightline ecology on Cloudreach's narrow ribbons. Their
	# large silhouettes still collide with terrain, attacks and every other
	# gameplay body; only the trainer/wild pair is exempt so a peaceful animal
	# repaired onto the ribbon cannot seal the one authored walking lane.
	wild.add_collision_exception_with(trainer)
	trainer.add_collision_exception_with(wild)


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
	_release_shared_footprint()
	_spawn_available_sites()
	for id: String in trainer_prompts:
		var prompt: Node = trainer_prompts[id]
		prompt.set("enabled", can_challenge(trainer_specs[id]))
	# Inherited streaming only tracks Meadows clusters. Our small authored sites
	# use full 3D distance, so a body stacked far above the player stays asleep.
	for wild: Node3D in _wild_creatures:
		if not is_instance_valid(wild) or _player == null or not wild.visible \
				or wild == _engaged_with or bool(wild.get("engaged")):
			continue
		# A fallen body must not freeze forever outside the activation sphere.
		# Its validated home owns residency; inherited guards own fights, gates,
		# faint timers and respawns, including the recovery hook before wake-up.
		var resident: Vector3 = _wild_homes.get(wild, wild.global_position)
		var active := minf(resident.distance_to(_player.global_position),
			wild.global_position.distance_to(_player.global_position)) \
			<= float(encounter_config.get("activation_distance_m", 130.0))
		_set_wild_active(wild, active)


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
		if not site_needs_spawn(_site_spawned, _site_failures, id):
			continue
		var table := find_id(chapter.get("encounter_tables", []), str(site["table_id"]))
		var gate := str(table.get("requires_unlock", ""))
		if table.is_empty() or (not gate.is_empty() and not _flags_hold([gate])):
			continue
		var centre := _vector3_of(site["position"])
		if _player == null or centre.distance_to(_player.global_position) > float(encounter_config.get("activation_distance_m", 130.0)):
			continue
		var members: Array = []
		var complete := true
		for index in int(site.get("count", 1)):
			var selected := roll_wild(table, world_seed(), hash(id) + index)
			if selected.is_empty():
				complete = false
				continue
			var wild: Node3D
			if str(site.get("placement_mode", "ground")) == "air_patrol":
				wild = _spawn_air_patrol(str(selected["species"]), site, index, int(selected["level"]))
			else:
				var angle := index * TAU / maxi(1, int(site.get("count", 1)))
				var at := centre + Vector3(cos(angle), 0, sin(angle)) * float(site.get("radius_m", 4.0)) * 0.5
				wild = spawn_wild(str(selected["species"]), at, {"name": "%s_%d" % [id, index],
					"site_anchor": centre,
					"level": selected["level"], "aggressive": false, "wander_radius": float(site.get("radius_m", 4.0)),
					"combat": encounter_config.get("behavior_profiles", {}).get("scout", {})})
			if wild != null:
				if not str(site.get("_why_road_visibility_0907", "")).is_empty() \
						and wild is CollisionObject3D and _player is CollisionObject3D:
					keep_trainer_corridor_clear(wild as CollisionObject3D,
						_player as CollisionObject3D)
				members.append(wild)
				_wild_respawn[wild] = float(encounter_config.get("wild_respawn_seconds", 180.0))
				if not gate.is_empty():
					_wild_gates[wild] = {"cloudreach_requires_flags": [gate]}
			else:
				complete = false
		_site_members[id] = members
		if complete:
			_site_spawned[id] = true
		else:
			# Fail closed once, visibly. Never mark an unsupported population as
			# valid or roll replacements every idle frame for a partial site.
			_site_failures[id] = true
			push_warning("Cloudreach wild site has unsupported placements: " + id)


func _spawn_air_patrol(species: String, site: Dictionary, index: int, level: int) -> Node3D:
	if not SPECIES.has(species) or str(SPECIES.definition(species).get("type", "")) != "air":
		push_error("Cloudreach air patrol requires an existing Air species: " + species)
		return null
	var plan := air_patrol_member_plan(site, index)
	if plan.is_empty():
		return null
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(AirPatrolWild)
	wild.name = str(plan.id)
	# Peer 1 is the listen host in a live session and the ordinary offline
	# authority in solo. Every peer builds the same fixed presentation node, but
	# no client can acquire simulation authority or manufacture a second ID.
	wild.set_multiplayer_authority(int(plan.authority_id), true)
	get_parent().add_child(wild)
	wild.call("populate", species, _player)
	_set_fixed_level(wild, species, level)
	wild.set("aggressive", false)
	var wild_cfg: Dictionary = MATH.config().get("wild", {}).duplicate()
	wild_cfg["wander_radius"] = 0.0
	wild.call("configure", wild_cfg)
	wild.call("configure_air_patrol", plan.position, plan.facing)
	wild.set("home", plan.position)
	wild.set_meta("cloudreach_site_id", str(site.id))
	wild.set_meta("placement_mode", "air_patrol")
	_wild_homes[wild] = plan.position
	_wild_creatures.append(wild)
	return wild


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
	if not SPECIES.has(species):
		push_error("spawn_wild('%s') names a species that is not in species.json" % species)
		return null
	var once_id := str(opts.get("once_id", ""))
	if _once_cleared(once_id):
		return null
	# Same construction contract as main spawn_wild: canonical prefab,
	# populate/instance roll, combat override, fixed level, config, signal and
	# once-only registration. Only the script's peaceful fallback and admission
	# grounding differ. Trainer bodies still use the untouched main pipeline.
	var wild: Node3D = CREATURE_SCENE.instantiate()
	wild.set_script(CliffWild)
	wild.name = str(opts.get("name", "Wild_%s_%d" % [species, _wild_creatures.size() + 1]))
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
	_surface_for(wild, spot)
	var anchor: Vector3 = opts.get("site_anchor", spot)
	var safe := _find_wild_spawn(wild, spot, anchor)
	if not safe.is_finite() or not bool(wild.call("place_on_ground", safe)):
		_surface_nodes.erase(wild.get_instance_id())
		wild.free()
		return null
	wild.set("home", wild.global_position)
	wild.set("_target", wild.global_position)
	_wild_homes[wild] = wild.global_position
	wild.call("set_clearance_check", Callable(self, "_wild_destination_supported").bind(wild))
	wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
	_wild_creatures.append(wild)
	if not once_id.is_empty():
		_once_only[wild] = once_id
	return wild


## Real collision AND the intended analytic stratum must agree. An enclosing
## mesa, a different stacked deck or a ray hitting another creature is not floor.
func _wild_support(at: Vector3, radius: float, wild: Node3D) -> Vector3:
	if _wild_diagnostics_enabled:
		var started := Time.get_ticks_usec()
		_wild_support_calls += 1
		var result := _wild_support_impl(at, radius, wild, _wild_ray_counter)
		_wild_support_usec += Time.get_ticks_usec() - started
		return result
	return _wild_support_impl(at, radius, wild)


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
		if hit.is_empty() or not hit.collider is StaticBody3D \
				or hit.normal.y < 0.7 or absf(hit.position.y - expected) > 0.35:
			return Vector3.INF
		highest = maxf(highest, float(hit.position.y))
	return Vector3(at.x, highest, at.z)


func _wild_path_supported(from: Vector3, to: Vector3, radius: float, wild: Node3D) -> bool:
	if not from.is_finite() or not to.is_finite() or from.distance_to(to) > 24.0:
		return false
	var steps := maxi(1, ceili(Vector2(to.x-from.x, to.z-from.z).length() / WILD_PATH_STEP))
	for i in steps + 1:
		if not _wild_support(from.lerp(to, float(i)/steps), radius, wild).is_finite():
			return false
	return true


func _find_wild_spawn(wild: Node3D, requested: Vector3, centre: Vector3) -> Vector3:
	var radius := float(wild.call("body_radius")) + WILD_FOOT_MARGIN
	# Stable order and no random draws: repair an edge-biased generic resource
	# anchor, then validate each actual body and the short connection to it.
	var anchors: Array[Vector3] = [centre]
	for ring in [1.0, 2.0, 3.0]:
		for i in 8:
			anchors.append(centre + Vector3(cos(i*TAU/8.0), 0, sin(i*TAU/8.0)) * ring)
	for raw_anchor in anchors:
		var anchor := _wild_support(raw_anchor, radius, wild)
		if not anchor.is_finite() or not _wild_path_supported(centre, anchor, 0.05, wild):
			continue
		var candidates: Array[Vector3] = [requested, anchor]
		for ring in [1.5, 3.0, 4.5]:
			for i in 8:
				candidates.append(anchor + Vector3(cos(i*TAU/8.0), 0, sin(i*TAU/8.0)) * ring)
		for candidate in candidates:
			var safe := _wild_support(candidate, radius, wild)
			if not safe.is_finite() or not _wild_path_supported(anchor, safe, radius, wild):
				continue
			var occupied := false
			for other: Node3D in _wild_creatures:
				if other != wild and is_instance_valid(other) and other.global_position.distance_to(safe) \
						< radius + float(other.call("body_radius")) + WILD_FOOT_MARGIN:
					occupied = true
			if not occupied:
				return safe
	return Vector3.INF


func _wild_destination_supported(candidate: Vector3, wild: Node3D) -> bool:
	if not is_instance_valid(wild):
		return false
	return _wild_path_supported(wild.global_position, candidate,
		float(wild.call("body_radius")) + WILD_FOOT_MARGIN, wild)


func _stand_on_ground(body: Node3D, spot: Vector3) -> bool:
	if body == _ally_body and is_instance_valid(_player):
		return await _stand_ally_on_trainer_level(body, spot)
	_surface_for(body, spot)
	return await super._stand_on_ground(body, spot)


## F06 #4 (CLOUDREACH-LANE open finding): the base puts a summoned companion
## 2.4 m behind and 1.2 m right of the trainer and seats it on the analytic
## surface under that XZ. Beside a narrow Cloudreach road the surface index
## still reports road height a little past the collider's lip, so the body was
## set down in the air and fell to the valley floor (y 83.9 below the arrival
## terrace road at y 105), and the trainer walked off the edge after it.
## Here the spot is chosen on real collision on the trainer's own level: the
## requested spot first, then the other seven directions around the trainer,
## then closer rings, and last the trainer's own footprint (a following body is
## on no physics layer, so sharing it walls nobody in). Never below a drop.
func _stand_ally_on_trainer_level(body: Node3D, requested: Vector3) -> bool:
	var level := _recall_floor(_player.global_position, _player.global_position.y + 0.5, body)
	if is_nan(level):
		level = _player.global_position.y
	var spot := _recall_spot(body, requested, level)
	_surface_for(body, spot)
	if not await super._stand_on_ground(body, spot):
		return false
	# The analytic seat can sit under or over the collider top it was verified
	# on (the arrival road: collider 106.08 m, surface index 105.00 m). The
	# verified collision floor is the one the body will stand on.
	body.global_position = spot
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO
	return true


## A verified spot for `body` on the trainer's level `level`, or the trainer's
## own footprint when no ring spot verifies.
func _recall_spot(body: Node3D, requested: Vector3, level: float) -> Vector3:
	var origin := _player.global_position
	var offset := Vector3(requested.x - origin.x, 0.0, requested.z - origin.z)
	var reach := offset.length()
	var radius := float(body.call("body_radius")) if body.has_method("body_radius") else 0.5
	var first := offset.normalized() if reach > 0.01 else Vector3.BACK
	var directions: Array[Vector3] = []
	for i in 8:
		directions.append(first.rotated(Vector3.UP, i * TAU / 8.0))
	# Nearest-to-requested first: the requested direction, its neighbours, then
	# round to the opposite side.
	var order := [0, 1, 7, 2, 6, 3, 5, 4]
	var near := maxf(radius + 0.6, 1.2)
	var rings: Array[float] = [reach]
	if reach > near + 0.1:
		rings.append_array([(reach + near) * 0.5, near])
	for ring: float in rings:
		for index: int in order:
			var candidate := origin + directions[index] * ring
			var floor_y := _recall_footprint_floor(candidate, level, radius, body)
			if is_nan(floor_y):
				continue
			var spot := Vector3(candidate.x, floor_y, candidate.z)
			if _recall_path_on_level(origin, spot, level, body) and _recall_body_fits(spot, body):
				return spot
	# Last rung: the trainer's own footprint. The follower's mask still meets
	# the trainer's capsule and would climb onto the trainer's head, so the two
	# ignore each other until the trainer walks clear.
	if body is PhysicsBody3D:
		(body as PhysicsBody3D).add_collision_exception_with(_player)
		_recall_shared_footprint = weakref(body)
	return Vector3(origin.x, level, origin.z)


## The last rung's exception ends once the trainer has walked clear of the
## companion (or the companion is gone).
func _release_shared_footprint() -> void:
	if _recall_shared_footprint == null:
		return
	var body := _recall_shared_footprint.get_ref() as PhysicsBody3D
	if body == null or not is_instance_valid(_player):
		_recall_shared_footprint = null
		return
	var apart := Vector2(body.global_position.x - _player.global_position.x,
		body.global_position.z - _player.global_position.z).length()
	if apart >= float(body.call("body_radius")) + RECALL_SHARED_CLEAR_M:
		body.remove_collision_exception_with(_player)
		_recall_shared_footprint = null


## Walkable collision under the body's centre and around its footprint, all
## within RECALL_LEVEL_M of `level`: the highest of them, or NAN.
func _recall_footprint_floor(at: Vector3, level: float, radius: float, body: Node3D) -> float:
	var centre := _recall_floor(at, level, body)
	if is_nan(centre):
		return NAN
	var highest := centre
	for i in 8:
		var angle := i * TAU / 8.0
		var sample := at + Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.9
		var y := _recall_floor(sample, level, body)
		if is_nan(y):
			return NAN
		highest = maxf(highest, y)
	return highest


## Top of walkable collision under `at`, within RECALL_LEVEL_M of `level`.
func _recall_floor(at: Vector3, level: float, body: Node3D) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, level + RECALL_LEVEL_M + 0.8, at.z), Vector3(at.x, level - RECALL_LEVEL_M, at.z),
		_player.collision_mask, _recall_exclusions(body))
	var hit: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider is StaticBody3D or (hit.normal as Vector3).y < RECALL_MIN_NORMAL_Y:
		return NAN
	var y := (hit.position as Vector3).y
	return y if absf(y - level) <= RECALL_LEVEL_M else NAN


## Floor on the level every step from the trainer to the spot, and nothing
## solid across the line at knee and chest height: no drop, no wall between.
func _recall_path_on_level(from: Vector3, to: Vector3, level: float, body: Node3D) -> bool:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var steps := maxi(1, ceili(flat.length() / RECALL_PATH_STEP_M))
	for i in range(1, steps + 1):
		var p := from + flat * (float(i) / steps)
		if is_nan(_recall_floor(p, level, body)):
			return false
	var space := _player.get_world_3d().direct_space_state
	for lift: float in [0.6, 1.2]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(from.x, level + lift, from.z),
			Vector3(to.x, to.y + lift, to.z), _player.collision_mask, _recall_exclusions(body))
		if not space.intersect_ray(query).is_empty():
			return false
	return true


## The body's own collision shape at `spot` touches no world geometry.
func _recall_body_fits(spot: Vector3, body: Node3D) -> bool:
	var collision := body.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.shape == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.collision_mask = _player.collision_mask
	query.transform = Transform3D(collision.global_basis,
		spot + Vector3.UP * 0.05 + (collision.global_position - body.global_position))
	query.exclude = _recall_exclusions(body)
	for hit: Dictionary in _player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		if hit.collider is StaticBody3D:
			return false
	return true


func _recall_exclusions(body: Node3D) -> Array[RID]:
	var exclude: Array[RID] = [_player.get_rid()]
	if body is CollisionObject3D:
		exclude.append((body as CollisionObject3D).get_rid())
	return exclude


func _start_fight(wild: Node3D, opponent_owned: bool = false) -> void:
	if wild == _engaged_with or (_manager != null and bool(_manager.call("is_fighting"))):
		return
	if not _rider_off_for_admission():
		return
	_surface_for(wild, Vector3(wild.global_position.x, _player.global_position.y, wild.global_position.z))
	super._start_fight(wild, opponent_owned)


## SYSTEMS §8 "Combat admission dismounts safely first. No mounted
## catch/combat." A rider comes off onto verified ground BEFORE the manager
## places fighters and takes the camera; with nowhere verified to stand the
## admission is refused and the rider told why
## (`cloudreach_riding_controller.gd::dismount_for_admission`).
func _rider_off_for_admission() -> bool:
	var riding := get_parent().get_node_or_null(^"RidingController") if get_parent() != null else null
	if riding == null or not riding.has_method("dismount_for_admission"):
		return true
	return bool(riding.call("dismount_for_admission"))


func _reground_if_fallen(wild: Node3D) -> void:
	if not is_instance_valid(wild) or not _wild_homes.has(wild) or wild == _engaged_with \
			or bool(wild.get("engaged")) or not bool(wild.call("is_alive")) \
			or _faint_timers.has(wild) or _respawn_timers.has(wild):
		return
	var home: Vector3 = _wild_homes[wild]
	var at := wild.global_position
	var ground := float(realm_world.call("ground_height_near", Vector3(at.x, home.y, at.z))) if at.is_finite() else NAN
	if is_finite(ground) and at.y >= ground - REGROUND_DEPTH_M:
		return
	var safe := _wild_support(home, float(wild.call("body_radius")) + WILD_FOOT_MARGIN, wild)
	if safe.is_finite():
		# Recover this same body/instance, never a new population roll. The last
		# falling Y cannot choose a lower stacked road. Combat remains untouched.
		_surface_for(wild, safe)
		wild.call("place_on_ground", safe)
		wild.set("_target", safe)


func begin_trainer_battle(spec: Dictionary, trainer: Node3D = null) -> bool:
	if not _rider_off_for_admission():
		return false
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
		# The canonical chapter adapter recorded the win (solo: locally; host:
		# its `set_world_flag` committed synchronously). Still pay the ordinary
		# trainer reward once; the initial durable guard prevents repeat payouts.
		#
		# ROADMAP F08 / MULTIPLAYER per-participant rewards: in a session this
		# must be the base's §7 path, not a local payout. On the host it submits
		# the world facts (the ledger answers the already-committed flag with
		# `noop`) and one `reward_grant` per component addressed to every
		# participant, each guarded per character per source, so a guest who
		# fought Veyra is paid exactly once and the host's own share arrives as
		# a ledger delivery rather than a second local `inventory.add()`. Solo
		# and a client running its own fight get `false` here and keep the
		# unchanged self-payout below, as the base's client path does.
		if _record_trainer_defeat_for_the_session(spec):
			return
		_pay_trainer_reward(spec)
	else:
		# Flag not yet local (a client's pending intent, or no adapter write):
		# the base already routes this through the same session path first.
		super._record_trainer_defeat(spec)
