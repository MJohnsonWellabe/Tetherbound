extends "res://scripts/combat/cloudreach_encounter_director.gd"

## Water content over the shared production combat pipeline. Residency is the
## union of occupied Water peer neighborhoods, including a remote island when
## this world's local rig is only a host simulation. Story bosses stay external.
const WATER_PERF := preload("res://scripts/world/performance_config.gd")
const REMOTE_CREATURE_BODY := preload("res://scripts/creatures/remote_creature.gd")
const WATER_DATA := preload("res://scripts/world/water_encounter_runtime_data.gd")
const RANKS := preload("res://scripts/characters/npc_ranks.gd")
const INTERACTION := preload("res://scripts/world/interactable.gd")
var _wanted_sites: Dictionary = {}
var _restoring_surface_position := Vector3.INF
## Reused NPC bodies whose Greet prompt this director switched off for their
## own trainer fight, so only those are switched back on afterwards.
var _muted_greetings: Dictionary = {}
## New surface bodies wait unpublished with the same card while a ring occupies
## their authored site. This is transient residency, never a durable generation.
var _water_surface_pending: Dictionary = {}
var _water_site_arena_retry_ms: Dictionary = {}
var _water_arena_admission_wild: Node3D = null

func _host_commit_encounter(intent: Dictionary, peer_id: int) -> Dictionary:
	var service := get_parent().get_node_or_null("RippletWaterService")
	if service != null and service.is_submerged(peer_id) and str(intent.get("kind", "")) in ["engage","move_start","strike_intent","catch_attempt"]:
		return {"ok":false,"kind":str(intent.kind),"peer":peer_id,"code":"submerged",
			"reason":"Surface before fighting or catching.","pending":false,"delta":{}}
	return super._host_commit_encounter(intent,peer_id)

func _start_fight(wild: Node3D, opponent_owned: bool = false) -> void:
	var riding := get_parent().get_node_or_null("RidingController")
	if riding != null and bool(riding.diving): return
	var previous := _water_arena_admission_wild
	_water_arena_admission_wild = wild
	super._start_fight(wild, opponent_owned)
	_water_arena_admission_wild = previous

func can_challenge(spec: Dictionary) -> bool:
	var riding := get_parent().get_node_or_null("RidingController")
	return not (riding != null and bool(riding.diving)) and super.can_challenge(spec)

func join_encounter(encounter_id: String) -> bool:
	var riding := get_parent().get_node_or_null("RidingController")
	return not (riding != null and bool(riding.diving)) and super.join_encounter(encounter_id)


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
		"combat_camera": (named.combat_camera as Dictionary).duplicate(true) if named.get("combat_camera") is Dictionary else {},
		"opts": {"name": id, "once_id": str(named.get("completion_flag", "")),
			"level": int(named.get("level", 1)), "aggressive": false,
			"wander_radius": float(site.get("roam_radius_m", site.get("radius_m", 4))),
			"combat": (named.combat as Dictionary).duplicate(true) if named.get("combat") is Dictionary else {}}}


## One selector owns both authored named replacements and ordinary table rolls.
## A site that names a replacement fails closed when its two authored references
## disagree; it must never silently turn back into a random wild population.
static func site_spawn_plans(site: Dictionary, table: Dictionary,
		named_encounters: Array, seed_value: int) -> Array[Dictionary]:
	var named_id := str(site.get("named_replacement_id", ""))
	if not named_id.is_empty():
		var named := named_spawn_plan(site, named_encounters)
		if named.is_empty() or int(site.get("count", 1)) != 1:
			return []
		named["member_index"] = 0
		return [named]
	var plans: Array[Dictionary] = []
	var member_anchors: Array = site.get("member_anchors", [])
	var rest_yaws: Array = site.get("rest_yaw_deg", [])
	if not member_anchors.is_empty() and member_anchors.size() != int(site.get("count", 1)):
		return []
	if not rest_yaws.is_empty() and rest_yaws.size() != int(site.get("count", 1)):
		return []
	for index in int(site.get("count", 1)):
		var selected := roll_wild(table, seed_value, hash(str(site.get("id", ""))) + index)
		if selected.is_empty():
			continue
		var member_position: Array = member_anchors[index].duplicate() if not member_anchors.is_empty() \
			else site.get("position", []).duplicate()
		var options := {"name": "%s_%d" % [str(site.get("id", "")), index],
			"level": int(selected.level), "aggressive": false,
			"wander_radius": float(site.get("radius_m", 4.0))}
		if not rest_yaws.is_empty():
			var heading := float(rest_yaws[index])
			if not is_finite(heading):
				return []
			options["initial_yaw_deg"] = heading
		plans.append({
			"id": "",
			"species": str(selected.species),
			"position": member_position,
			"display_name": "",
			"reward_role": "",
			"member_index": index,
			"opts": options,
		})
	return plans

## Rebuild the saved owner's existing party member through the deployment seam.
## A surface swimmer must not be placed on the seabed by the land spawn helper.
func restore_swim_mount(saved: Dictionary) -> bool:
	var party := _party()
	var index := preload("res://scripts/save/water_traversal_save.gd").mount_index(saved, party.members()) if party != null else -1
	var creature: RefCounted = party.at(index) if party != null and index >= 0 else null
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
	if not party.set_active(index):
		return false
	var raw: Array = saved.position
	_restoring_surface_position = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	# Submerged reconnects always use the validated surface, preserving the
	# creature's existing stamina. Never let an old dive pose seat it in terrain.
	if saved.has("dive"): _restoring_surface_position.y = realm_world.field.water_level() - 0.7
	var spawned := await _spawn_ally_body(creature)
	_restoring_surface_position = Vector3.INF
	if not spawned:
		return false
	# No frame advances between revealing the body and attaching its rider.
	_player.global_position = _ally_body.global_position + Vector3.UP
	_ally_body.velocity = Vector3.ZERO
	var mounted: bool = riding.mount()
	if not mounted and str(creature.species_id) == "ripplet":
		for attempt in 120:
			await get_tree().physics_frame
			if not is_instance_valid(_ally_body): return false
			if riding.is_mounted(): return true
	return mounted

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

## F14#0 C3 (Tidecoil): WATER named encounters authored `arena_mode:
## "shallow_surface"` ("sweeps the visible surface at the reef edge") keep their
## fight ring small, so it stays in the shallows where both fighters show above
## the water. Without it the ring's 11 m drifted down the reef slope: Tidecoil
## fought 5 m under the surface, hidden by it, for most of a captured fight
## (r8tidecoil: enemy y -5.4 on the seabed). CombatManager asks every sibling
## of the player for `combat_arena_bounds_at`, as the Warrens and stronghold
## answer for their rooms; -1 means no opinion.
func combat_arena_bounds_at(x: float, z: float) -> float:
	var actor := _water_arena_admission_wild if is_instance_valid(_water_arena_admission_wild) else _engaged_with
	var context := authored_named_wild_arena_context(actor)
	if context.is_empty(): return -1.0
	var centre: Vector3 = context.centre
	if Vector2(x, z).distance_to(Vector2(centre.x, centre.z)) <= float(context.capture_radius_m):
		return float(context.radius)
	return -1.0


## Only the actual resident named actor can supply its authored arena. A nearby
## ordinary wild never borrows the named bay's cap. The manager independently
## validates this mounted producer and both rendered footprints before seating.
func authored_named_wild_arena_context(wild: Node3D) -> Dictionary:
	if not is_instance_valid(wild) or not wild.is_inside_tree() or not wild.visible \
			or wild.is_queued_for_deletion() or bool(wild.get("trainer_owned")) \
			or not _wild_creatures.has(wild) or wild.get_parent() != get_parent(): return {}
	var id := str(wild.get_meta(&"water_named_encounter", ""))
	var named := find_id(encounter_config.get("named_encounters", []), id)
	if named.is_empty() or not named.has("arena_radius_m") or bool(named.get("trainer_owned", true)): return {}
	var site := find_id(encounter_config.get("wild_sites", []), str(named.get("replaces_wild_site_id", "")))
	if site.is_empty() or str(site.get("named_replacement_id", "")) != id \
			or not (_site_members.get(str(site.id), []) as Array).has(wild): return {}
	var plan := named_spawn_plan(site, encounter_config.get("named_encounters", []))
	var instance: RefCounted = wild.get("instance")
	if plan.is_empty() or instance == null or str(instance.get("species_id")) != str(plan.species): return {}
	var centre := _vector3_of(named.position)
	var radius := float(named.arena_radius_m)
	var capture := float(named.get("arena_capture_radius_m", 16.0))
	if not centre.is_finite() or not is_finite(radius) or radius <= 0.0 \
			or not is_finite(capture) or capture <= 0.0: return {}
	var support := str(site.get("placement_mode", "ground"))
	if (support == "water_surface") != (wild is SurfaceWild): return {}
	var context := {"source": self, "wild": wild, "named_encounter_id": id,
		"species_id": str(plan.species), "centre": centre, "radius": radius,
		"capture_radius_m": capture, "arena_mode": str(named.get("arena_mode", "")), "support_mode": support}
	if wild is SurfaceWild: context["surface_origin_y"] = (wild as SurfaceWild).surface_origin_y()
	return context


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
	_clear_stale_surface_spawns()
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
		if Time.get_ticks_msec() < int(_water_site_arena_retry_ms.get(id, 0)): continue
		var site: Dictionary = _wanted_sites[id]
		var table := find_id(chapter.get("encounter_tables", []), str(site.table_id))
		var centre := _vector3_of(site.position)
		var members: Array = []
		for resident: Variant in _site_members.get(id, []):
			if is_instance_valid(resident) and not (resident as Node).is_queued_for_deletion(): members.append(resident)
		var arena_deferred := false
		var plans := site_spawn_plans(site, table,
			encounter_config.get("named_encounters", []), world_seed())
		var authored_members: Array = site.get("member_anchors", [])
		if plans.size() == 1 and not str(plans[0].id).is_empty():
			var cycle := foundation_alpha_cycle(str(plans[0].id))
			# Alpha cycles are host truth (foundation_alpha_cycle is {} on a
			# client). A client follows its mirror of the host's cycle, as
			# encounter_director does: the live generation's packet, nothing
			# while it waits, and no body before the mirror arrives (retried).
			if _is_guest() and _session != null and preload("res://scripts/repeatables/alpha_respawns.gd").config().get("runtime_enabled") == true \
				and not preload("res://scripts/repeatables/alpha_respawns.gd").site(str(plans[0].id)).is_empty():
				cycle = get_node("/root/Game").world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(str(plans[0].id), {}).duplicate(true)
				if cycle.is_empty(): continue
			if cycle.is_empty() and _is_host() and not _once_cleared(str(plans[0].opts.get("once_id", ""))) \
				and _session != null and preload("res://scripts/repeatables/alpha_respawns.gd").config().get("runtime_enabled") == true \
				and not preload("res://scripts/repeatables/alpha_respawns.gd").site(str(plans[0].id)).is_empty():
				var first_packet: Dictionary = _session.call("foundation_alpha_first_spawn", self, str(plans[0].id))
				if first_packet.is_empty(): continue
				cycle = foundation_alpha_cycle(str(plans[0].id))
			if cycle.get("status") == "waiting":
				_site_members[id] = members
				_site_spawned[id] = true
				continue
			if cycle.get("status") == "active":
				var packet := preload("res://scripts/repeatables/alpha_respawns.gd").retained_spawn(get_node("/root/Game").world.redesign_world, str(plans[0].id))
				foundation_publish_alpha(str(plans[0].id), packet)
				# Successful publication installs the actual member. Failed footing
				# stays retryable through the existing alpha service.
				if not _site_members.get(id, []).is_empty(): _site_spawned[id] = true
				continue
		# A valid named reservation whose once flag already fired is complete,
		# not a broken spawn. Settle it as intentionally absent so returning to
		# the island (or loading a completed save) stays quiet and deterministic.
		if plans.size() == 1 and not str(plans[0].id).is_empty() \
				and _once_cleared(str(plans[0].opts.get("once_id", ""))):
			_site_members[id] = members
			_site_spawned[id] = true
			continue
		for plan: Dictionary in plans:
			var index := int(plan.member_index)
			var already_admitted := false
			for resident: Node3D in members:
				if int(resident.get_meta(&"water_member_index", -1)) == index: already_admitted = true
			if already_admitted: continue
			var opts: Dictionary = plan.opts.duplicate(true)
			opts["water_pending_site"] = id
			opts.ordinary_trait_alpha = not str(plan.id).is_empty()
			var spawn_at := _vector3_of(plan.position)
			if not authored_members.is_empty():
				spawn_at.y = float(realm_world.call("ground_height_at", spawn_at.x, spawn_at.z))
				if not spawn_at.is_finite():
					continue
			opts["site_anchor"] = spawn_at if not authored_members.is_empty() else centre
			var wild: Node3D
			if str(site.get("placement_mode", "ground")) == "water_surface":
				var member_at := _surface_member_position(spawn_at, int(site.get("count", 1)), index,
					float(site.get("radius_m", 4.0)))
				wild = _spawn_surface_wild(str(plan.species), member_at, opts,
					float(site.get("surface_y_m", spawn_at.y)),
					float(site.get("surface_submerge_fraction", 0.28)))
			else:
				wild = spawn_wild(str(plan.species), spawn_at, opts)
			if wild == null and _wild_spawn_arena_blocked: arena_deferred = true
			if wild != null:
				settle_spawn_transform(wild)
				var initial_yaw := float(opts.get("initial_yaw_deg", NAN))
				if is_finite(initial_yaw):
					wild.rotation.y = deg_to_rad(initial_yaw)
					wild.set_meta("water_authored_rest_yaw_deg", initial_yaw)
				wild.set_meta("water_site_id", id)
				wild.set_meta(&"water_member_index", index)
				wild.set_meta("water_placement_mode", str(site.get("placement_mode", "ground")))
				# ROAD pairs are authored sightline ecology, not combat gates. Water
				# owns this admission loop instead of Cloudreach's, so carry over the
				# same narrow player/wild exception here; terrain, other wild bodies,
				# attacks and named encounters retain their normal collisions.
				if str(plan.id).is_empty() \
						and not str(site.get("_why_road_visibility_0907", "")).is_empty() \
						and wild is CollisionObject3D and _player is CollisionObject3D:
					keep_trainer_corridor_clear(wild as CollisionObject3D,
						_player as CollisionObject3D)
				if not str(plan.id).is_empty():
					foundation_register_alpha(wild, str(plan.id))
					# Named identity has to reach both the exploration prompt (the
					# body) and combat/catch presentation (the live instance).
					wild.set("display_name", str(plan.display_name))
					var instance: Variant = wild.get("instance")
					if instance != null:
						(instance as RefCounted).set("display_name", str(plan.display_name))
					wild.set_meta("water_named_encounter", str(plan.id))
					wild.set_meta("water_reward_role", str(plan.reward_role))
					# F14#0: an authored fight-camera block (framing/tracking/
					# profile parts), read by CombatManager._opponent_camera exactly
					# as WaterAlpha passes Aquaryn's. Presentation only.
					if plan.get("combat_camera") is Dictionary and not (plan.combat_camera as Dictionary).is_empty():
						wild.set_meta("combat_camera", (plan.combat_camera as Dictionary).duplicate(true))
				members.append(wild)
				_wild_respawn[wild] = float(encounter_config.get("wild_respawn_seconds", 240))
		_site_members[id] = members
		if plans.size() == int(site.get("count", 1)) and members.size() == plans.size():
			_site_spawned[id] = true
			_water_site_arena_retry_ms.erase(id)
		elif not arena_deferred:
			_site_failures[id] = true
			push_warning("Water site lacks a valid authored encounter or supported creature footing: " + id)
		else:
			_water_site_arena_retry_ms[id] = Time.get_ticks_msec() + 500

func foundation_publish_alpha(site_id: String, packet: Dictionary) -> void:
	# A connected guest publishes only its mirror's retained packet (checked
	# below), so a client never invents or advances a generation.
	if not (_is_host() or _is_guest()) or preload("res://scripts/repeatables/alpha_respawns.gd").config().get("runtime_enabled") != true: return
	var game := get_node_or_null("/root/Game")
	if game == null or preload("res://scripts/repeatables/alpha_respawns.gd").retained_spawn(game.world.redesign_world, site_id) != packet: return
	for wild: Node3D in _wild_creatures:
		if is_instance_valid(wild) and wild.get_meta("foundation_alpha_site", "") == site_id \
			and wild.get_meta("foundation_alpha_generation", 0) == packet.captured_from.spawn_generation: return
	for site: Dictionary in _wanted_sites.values():
		if site.get("named_replacement_id") != site_id: continue
		var plan := named_spawn_plan(site, encounter_config.get("named_encounters", []))
		if plan.is_empty(): return
		var original_once := str(plan.opts.get("once_id", ""))
		var opts: Dictionary = plan.opts.duplicate(true)
		opts.retained_alpha_pending = true
		opts["water_pending_site"] = str(site.id)
		opts["water_retained_packet"] = packet.duplicate(true)
		# The original once flag continues to suppress first rewards. The new
		# durable generation admits only this fresh authored body and UID.
		if int(packet.captured_from.spawn_generation) > 1: opts.once_id = ""
		opts.name = "%s_generation_%d" % [site_id, packet.captured_from.spawn_generation]
		var at := _vector3_of(plan.position)
		opts.site_anchor = at
		var wild: Node3D
		if str(site.get("placement_mode", "ground")) == "water_surface":
			wild = _spawn_surface_wild(str(plan.species), at, opts, float(site.get("surface_y_m", at.y)), float(site.get("surface_submerge_fraction", 0.28)))
		else: wild = spawn_wild(str(plan.species), at, opts)
		if wild == null: return
		wild.visible = false
		if not foundation_register_alpha(wild, site_id, packet):
			_wild_creatures.erase(wild)
			wild.queue_free()
			return
		wild.display_name = str(plan.display_name)
		wild.get("instance").set("display_name", str(plan.display_name))
		wild.set_meta("water_named_encounter", site_id)
		if int(packet.captured_from.spawn_generation) == 1: wild.set_meta("water_reward_role", str(plan.reward_role))
		wild.set_meta("water_site_id", str(site.id))
		wild.set_meta(&"water_member_index", int(plan.get("member_index", 0)))
		wild.set_meta("water_placement_mode", str(site.get("placement_mode", "ground")))
		if plan.get("combat_camera") is Dictionary and not plan.combat_camera.is_empty(): wild.set_meta("combat_camera", plan.combat_camera.duplicate(true))
		_once_only[wild] = original_once
		settle_spawn_transform(wild)
		wild.visible = true
		_site_members[str(site.id)] = [wild]
		return


## A wild body enters the tree at the origin and is placed afterwards. For a
## kinematic body the physics server reads that placement as one step of
## motion and sweeps the body's shape AABB across every metre in between; the
## body's first `move_and_slide()` then culls Terrain3D's heightmap under that
## whole sweep. Measured on the host when a remote peer reached Deep Watch,
## ~3.5 km from the origin: 3.1-3.4 s per spawned body, back to back, with no
## heartbeat. Committing the placed transform as a static body and handing it
## back as kinematic makes the placement a teleport instead of a motion.
static func settle_spawn_transform(wild: Node3D) -> void:
	if wild is PhysicsBody3D and wild.is_inside_tree():
		REMOTE_CREATURE_BODY.teleport_body(wild as PhysicsBody3D, wild.global_position)


static func _surface_member_position(centre: Vector3, count: int, index: int, radius: float) -> Vector3:
	if count <= 1:
		return centre
	var angle := TAU * float(index) / float(count)
	var spread := minf(maxf(radius * 0.55, 2.0), 4.0)
	return centre + Vector3(cos(angle) * spread, 0.0, sin(angle) * spread)


func _spawn_surface_wild(species: String, spot: Vector3, opts: Dictionary,
		surface_y: float, submerge_fraction: float) -> Node3D:
	_wild_spawn_arena_blocked = false
	if not SPECIES.has(species):
		push_error("spawn_surface_wild('%s') names a species that is not in species.json" % species)
		return null
	var once_id := str(opts.get("once_id", ""))
	var key := str(opts.get("name", "SurfaceWild_%s_%d" % [species, _wild_creatures.size() + 1]))
	if _once_cleared(once_id):
		_discard_pending_surface(key)
		return null
	var pending: Dictionary = _water_surface_pending.get(key, {})
	if not pending.is_empty() and (not _pending_surface_current(pending) \
			or pending.get("species") != species or pending.get("spot") != spot \
			or pending.get("opts") != opts or pending.get("surface_y") != surface_y \
			or pending.get("submerge") != submerge_fraction):
		_discard_pending_surface(key)
		_wild_spawn_arena_blocked = true
		return null # Retire stale unpublished context; the next poll uses its new source.
	var wild: Node3D = pending.get("body")
	if not is_instance_valid(wild):
		wild = CREATURE_SCENE.instantiate()
		wild.set_script(SurfaceWild)
		wild.name = key
		wild.visible = false
		wild.process_mode = Node.PROCESS_MODE_DISABLED
		var parent: Node = opts.get("parent", null) as Node
		if not is_instance_valid(parent): parent = get_parent()
		parent.add_child(wild)
		if not bool(wild.call("populate", species, _player)):
			wild.free()
			return null
		var opt_combat: Variant = opts.get("combat", {})
		if opt_combat is Dictionary and not opt_combat.is_empty():
			wild.set("combat_override", opt_combat.duplicate(true))
		var level := int(opts.get("level", 0))
		if level > 0: _set_fixed_level(wild, species, level)
		if opts.has("aggressive"): wild.set("aggressive", bool(opts.aggressive))
		var wild_cfg: Dictionary = MATH.config().get("wild", {}).duplicate()
		if opts.has("wander_radius"): wild_cfg["wander_radius"] = opts.wander_radius
		wild.call("configure", wild_cfg)
		wild.call("configure_water_surface", surface_y, submerge_fraction)
		if not bool(wild.call("place_on_ground", spot)):
			wild.free()
			return null
		wild.set("home", wild.global_position)
		wild.set("_target", wild.global_position)
		var game := get_node_or_null("/root/Game")
		pending = {"body": wild, "once_id": once_id,
			"world": weakref(game.world) if game != null else null,
			"epoch": str(_session.call("_altar_current_epoch")) if _session != null else "",
			"generation": _population_generation, "species": species, "spot": spot,
			"opts": opts.duplicate(true), "surface_y": surface_y, "submerge": submerge_fraction,
			"site": str(opts.get("water_pending_site", "")),
			"packet": opts.get("water_retained_packet", {}).duplicate(true)}
		_water_surface_pending[key] = pending
	# The same unpublished body/card waits at the same authored placement.
	# No traits/once receipt/ecology publication happens on an occupied ring.
	if not _active_arena_clear(wild.global_position, _ambient_render_radius(wild), wild):
		_wild_spawn_arena_blocked = true
		return null
	_water_surface_pending.erase(key)
	_wild_homes[wild] = wild.global_position
	wild.call("set_clearance_check", Callable(self, "_placed_wild_target_clear").bind(wild))
	wild.call("set_arena_clearance_check", Callable(self, "_arena_wander_guard").bind(wild))
	wild.connect("wants_to_engage", _on_wild_wants_to_engage.bind(wild))
	if not bool(opts.get("retained_alpha_pending", false)):
		_initialize_wild_traits(wild, bool(opts.get("ordinary_trait_alpha", false)))
	_wild_creatures.append(wild)
	if not once_id.is_empty():
		_once_only[wild] = once_id
	wild.process_mode = Node.PROCESS_MODE_INHERIT
	wild.visible = not bool(opts.get("retained_alpha_pending", false))
	return wild


func _pending_surface_current(pending: Dictionary) -> bool:
	var body: Node3D = pending.get("body")
	if not is_instance_valid(body) or body.is_queued_for_deletion(): return false
	if pending.get("generation") != _population_generation: return false
	if _site_failures.has(str(pending.get("site", ""))): return false
	var game := get_node_or_null("/root/Game")
	var owner: WeakRef = pending.get("world")
	if owner != null and (game == null or owner.get_ref() != game.world): return false
	if str(pending.epoch) != (str(_session.call("_altar_current_epoch")) if _session != null else ""): return false
	if _once_cleared(str(pending.once_id)): return false
	var packet: Dictionary = pending.packet
	if not packet.is_empty() and (game == null or preload("res://scripts/repeatables/alpha_respawns.gd").retained_spawn(
			game.world.redesign_world, str(packet.get("captured_from", {}).get("spawn_id", ""))) != packet): return false
	return true


func _discard_pending_surface(key: String) -> void:
	var pending: Dictionary = _water_surface_pending.get(key, {})
	var body: Node3D = pending.get("body")
	if is_instance_valid(body):
		_ambient_render_bounds_cache.erase(body.get_instance_id())
		body.queue_free()
	_water_surface_pending.erase(key)


func _clear_stale_surface_spawns() -> void:
	for key: String in _water_surface_pending.keys():
		if not _pending_surface_current(_water_surface_pending[key]): _discard_pending_surface(key)

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
		preload("res://scripts/world/water_named_grass_clearance.gd").apply(body, realm_world)
		var prompt := INTERACTION.new()
		prompt.name = "WaterChallenge"
		prompt.configure("Challenge " + str(spec.name), float(encounter_config.get("trainer_prompt_radius_m", 4.2)), false)
		body.add_child(prompt)
		prompt.top_level = true
		prompt.global_position = body.global_position + Vector3(1.5, 1.05, 0)
		prompt.activated.connect(_challenge.bind(id))
		trainer_prompts[id] = prompt

## F26 performance (`performance.json` water_wild_activity): the full
## activity pass -- including `_set_wild_active`'s below-ground reground query
## for every active wild -- runs every `recheck_s`; between passes a wild is
## only touched when its wanted state and its physics state disagree, so a
## site entering or leaving range still switches it on the same frame.
var _wild_activity_left := 0.0


func _process(delta: float) -> void:
	super._process(delta)
	var activity: Dictionary = WATER_PERF.config().get("water_wild_activity", {})
	_wild_activity_left -= delta
	var full_pass := not bool(activity.get("enabled", false)) or _wild_activity_left <= 0.0
	if full_pass:
		_wild_activity_left = float(activity.get("recheck_s", 1.0))
	for wild: Node3D in _wild_creatures:
		if is_instance_valid(wild) and wild.visible and wild != _engaged_with and not bool(wild.get("engaged")):
			_set_wild_active(wild, _wanted_sites.has(str(wild.get_meta("water_site_id", ""))))
	# F26 (`performance.json` water_trainer_prompt_follow): a top-level prompt
	# write pushes a transform update every frame for every trainer, though
	# trainers stand still; move it only when its trainer has moved.
	var follow_only_moved := bool(WATER_PERF.config().get("water_trainer_prompt_follow", {}).get("enabled", false))
	var simulation_only := bool(realm_world.get("simulation_only"))
	for id: String in trainer_prompts:
		var prompt: Node3D = trainer_prompts[id]
		var at: Vector3 = trainer_nodes[id].global_position + Vector3(1.5, 1.05, 0)
		if not follow_only_moved or not prompt.global_position.is_equal_approx(at):
			prompt.global_position = at
		if simulation_only:
			prompt.enabled = false
	_mute_greeting_during_own_fight()

## A reused story NPC keeps its Greet prompt beside the separate challenge.
## During that trainer's own fight, F14#1's fight-camera capture showed
## "Greet Officer Venn" drawn over the fight. Switch it off for the fight
## and restore it when the fight ends.
func _mute_greeting_during_own_fight() -> void:
	var fighting := trainer_battle_active() and trainer_nodes.has(trainer_battle_id())
	var body: Node3D = trainer_nodes.get(trainer_battle_id()) if fighting else null
	var greeting: Node3D = body.call("prompt_node") if body != null and body.has_method("prompt_node") else null
	if greeting != null and bool(greeting.get("enabled")) and not _muted_greetings.has(greeting):
		greeting.set("enabled", false)
		_muted_greetings[greeting] = true
	for muted: Variant in _muted_greetings.keys():
		if not is_instance_valid(muted):
			_muted_greetings.erase(muted)
		elif muted != greeting:
			(muted as Node).set("enabled", true)
			_muted_greetings.erase(muted)

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
