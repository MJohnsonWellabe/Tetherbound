extends SceneTree

## One full production scene per --realm invocation, simulation_only=false.
## DISCLOSED setup: direct realm/scene boot, private save directory, and an
## isolated physics body copied from the real Player capsule. Only that probe
## is placed at solver candidates. No player pose, camera, grants, flags,
## permissions or durable arrival writers are changed by this harness.
## Geometry evidence only: not earned play, touch/save/reload/co-op acceptance
## or readable/rendered presentation proof. Run all four realms for all 19.
const STONES := preload("res://scripts/world/waystone.gd")
const ARRIVAL := preload("res://scripts/net/foundation_portal_arrival.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const DIAGNOSTIC := preload("res://tests/helpers/f18_capsule_diagnostic.gd")
const SCENES := {"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn"}
const IDS := {
	"meadows": ["meadows_trail_camp", "meadows_ranger_camp", "meadows_riverwatch", "meadows_highfield", "meadows_sigil_waystop"],
	"water": ["tidewake_first_shore", "tidewake_shellwatch", "tidewake_tidal_cradle", "tidewake_salt_crown", "tidewake_sluice_isle"],
	"cloudreach": ["cloudreach_galefoot_waycamp", "cloudreach_windscar_flight_aerie_camp", "cloudreach_cliffhold_commons", "cloudreach_summit_bivouac"],
	"stormwood": ["stormwood_ashfoot_waycamp", "stormwood_lantern_pools_camp", "stormwood_still_grove_shelter", "stormwood_lantern_hollow_waycamp", "stormwood_ember_bivouac"]}
const TOTAL_BUDGET_MSEC := 300000
const SETTLE_FRAMES := 60

class ProbeBody extends CharacterBody3D:
	var gravity := 26.0
	var consecutive_floor_frames := 0
	func _physics_process(delta: float) -> void:
		velocity.y -= gravity * delta
		move_and_slide()
		consecutive_floor_frames = consecutive_floor_frames + 1 if is_on_floor() else 0

var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var entries: Array[Dictionary] = []
var realm := ""
var _deadline := 0

func _initialize() -> void: _run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("F18 NATIVE STONES FAIL: " + label)

func _finish(world: Node3D = null) -> void:
	print("F18_NATIVE_STONES " + JSON.stringify({"realm": realm, "checks": checks,
		"failures": failures, "stones": records, "portal_entries": entries, "simulation_only": false,
		"fixture": "direct realm/scene, private save, isolated copy of actual Player capsule and probe candidate poses",
		"player_teleports": false, "camera_changes": false, "grants": false, "permission_bypass": false,
		"earned_play": false, "touch_save_reload": false, "co_op": false, "readable_presentation": false,
		"total_budget_msec": TOTAL_BUDGET_MSEC, "settle_frames_per_stone": SETTLE_FRAMES}))
	if world != null:
		current_scene = null
		world.queue_free()
		await process_frame
		await process_frame
	quit(0 if failures.is_empty() else 1)

func _probe(world: Node3D, player: CharacterBody3D, source: CollisionShape3D) -> ProbeBody:
	var body := ProbeBody.new()
	body.name = "F18IsolatedCapsuleProbe"
	# Layer 0 keeps this fixture out of world actors' queries. Its actual player
	# mask still tests every shipping floor/wall/body; only its own RID is excluded.
	body.collision_layer = 0
	body.collision_mask = player.collision_mask
	body.safe_margin = player.safe_margin
	body.floor_max_angle = player.floor_max_angle
	body.floor_snap_length = player.floor_snap_length
	body.floor_stop_on_slope = player.floor_stop_on_slope
	body.floor_constant_speed = player.floor_constant_speed
	body.up_direction = player.up_direction
	body.motion_mode = player.motion_mode
	body.gravity = float(player.get("_gravity"))
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = source.shape.duplicate() as CapsuleShape3D
	collision.transform = source.transform
	body.add_child(collision)
	world.add_child(body)
	body.set_physics_process(false)
	body.global_transform = player.global_transform
	return body

func _clear_at(probe: ProbeBody, at: Vector3) -> bool:
	var collision := probe.get_node(^"Collision") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	var pose := probe.global_transform
	pose.origin = at
	query.transform = pose * collision.transform
	query.collision_mask = probe.collision_mask
	query.exclude = [probe.get_rid()]
	return probe.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _registered_shrine(body: StaticBody3D, mask: int) -> bool:
	if body == null or not body.is_inside_tree(): return false
	var collision := body.get_child(0) as CollisionShape3D if body.get_child_count() == 1 else null
	if collision == null or collision.disabled or not collision.shape is BoxShape3D: return false
	var shape := collision.shape as BoxShape3D
	if not shape.size.is_finite() or shape.size.x <= 0 or shape.size.y <= 0 or shape.size.z <= 0: return false
	var query := PhysicsShapeQueryParameters3D.new()
	var sample := SphereShape3D.new()
	sample.radius = .01
	query.shape = sample
	query.transform.origin = collision.global_position
	query.collision_mask = mask
	for hit: Dictionary in body.get_world_3d().direct_space_state.intersect_shape(query, 32):
		if hit.get("rid") == body.get_rid(): return true
	return false

func _stone(world: Node3D, player: CharacterBody3D, probe: ProbeBody, arrival: Node, row: Dictionary, model_path: String) -> void:
	var id: String = row.id
	var node := world.get_node_or_null("Waystones/" + id) as Node3D
	var shrine := node.get_node_or_null(^"ShrineCollision") as StaticBody3D if node != null else null
	var model: Node3D = null
	if node != null:
		for child: Node in node.get_children():
			if child is Node3D and child.scene_file_path == model_path: model = child
	var has_mesh := false
	if model != null:
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh != null and mesh.is_visible_in_tree() and mesh.get_aabb().size.length_squared() > 0: has_mesh = true
	var canonical := STONES.resolve_position(world, row)
	var target := STONES.resolve_position(world, row, true)
	_check(node != null and node.get_script() == STONES and node.get("waystone_id") == id
		and node.get("realm_id") == realm and node.get("_presentation_enabled") == true, id + " actual production presentation mount")
	_check(model != null and model.is_visible_in_tree() and has_mesh, id + " installed shrine model has visible real mesh")
	_check(_registered_shrine(shrine, probe.collision_mask), id + " real shrine box registered in physics")
	_check(canonical.is_finite() and node != null and node.global_position.distance_to(canonical) < .01, id + " exact canonical supported shrine position")
	_check(target.is_finite(), id + " authored dry arrival footprint")
	var record := await _geometry(world, player, probe, arrival, target, id)
	record["shrine"] = DIAGNOSTIC.vector(canonical)
	records.append(record)

func _geometry(world: Node3D, player: CharacterBody3D, probe: ProbeBody, arrival: Node, target: Vector3, id: String) -> Dictionary:
	var collision := probe.get_node(^"Collision") as CollisionShape3D
	var radius: float = (collision.shape as CapsuleShape3D).radius
	var before := probe.global_transform
	var player_before := player.global_transform
	var landing: Vector3 = arrival.call("_capsule_landing", world, probe, target, radius)
	_check(probe.global_transform == before and player.global_transform == player_before, id + " solver changes neither probe nor Player pose")
	_check(landing.is_finite(), id + " production full-capsule landing accepted")
	_check(landing.is_finite() and _clear_at(probe, landing), id + " complete candidate capsule clear")
	if not landing.is_finite() and target.is_finite(): DIAGNOSTIC.report(arrival, world, probe, target, radius, id)
	var final_supported := false
	var stable := false
	var untouched := false
	var supported_settle_frames := 0
	var settle_queries_untouched := true
	if landing.is_finite() and Time.get_ticks_msec() < _deadline:
		# Disclosed probe pose setup only. Actual move_and_slide produces floor.
		probe.global_position = landing
		probe.velocity = Vector3.ZERO
		probe.consecutive_floor_frames = 0
		probe.set_physics_process(true)
		for frame in SETTLE_FRAMES:
			if Time.get_ticks_msec() >= _deadline: break
			await physics_frame
			await process_frame
			if frame >= SETTLE_FRAMES - 12:
				var sample_before := probe.global_transform
				var real_before := player.global_transform
				if arrival.call("_supported_capsule", world, probe, target, radius) == true: supported_settle_frames += 1
				settle_queries_untouched = settle_queries_untouched and probe.global_transform == sample_before and player.global_transform == real_before
		probe.set_physics_process(false)
		before = probe.global_transform
		player_before = player.global_transform
		final_supported = arrival.call("_supported_capsule", world, probe, target, radius) == true
		untouched = settle_queries_untouched and probe.global_transform == before and player.global_transform == player_before
		stable = Time.get_ticks_msec() < _deadline and probe.is_on_floor() and probe.consecutive_floor_frames >= 12 \
			and supported_settle_frames == 12 \
			and probe.global_position.is_finite() and probe.global_position.distance_to(landing) <= radius \
			and probe.get_floor_normal().angle_to(probe.up_direction) <= probe.floor_max_angle
		if not final_supported: DIAGNOSTIC.report(arrival, world, probe, target, radius, id + " settled")
	_check(stable, id + " actual move_and_slide stable walkable contact")
	_check(final_supported, id + " production final five-floor/full-capsule guard")
	_check(untouched, id + " final support observes without actor writes")
	return {"id": id, "target": DIAGNOSTIC.vector(target),
		"landing": DIAGNOSTIC.vector(landing), "settled": DIAGNOSTIC.vector(probe.global_position),
		"shape_radius": radius, "shape_height": (collision.shape as CapsuleShape3D).height,
		"safe_margin": probe.safe_margin, "mask": probe.collision_mask,
		"consecutive_floor_frames": probe.consecutive_floor_frames, "stable_contact": stable, "final_supported": final_supported}

func _entry(world: Node3D, player: CharacterBody3D, arrival: Node, game: Node) -> void:
	var config: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var entry_id := ""
	for arch: Dictionary in config.arches:
		var destination: String = "water" if arch.biome == "tidewake" else str(arch.biome)
		if arch.kind == "live" and destination == realm: entry_id = str(arch.entry_id)
	var session: Node = game.get("session")
	var runtime: Node = session.get_node_or_null(^"FoundationComposition/PortalArrival") if session != null else null
	_check(runtime != null and not entry_id.is_empty(), "actual portal service and canonical first-entry ID")
	# Observe the real resolver's exact permit destination without issuing a
	# permit or travel. The canonical realm entry differs from its first stone.
	var target := Vector3(INF, INF, INF)
	if runtime != null and not entry_id.is_empty():
		target = runtime.call("_arrival_target", world, {"realm": realm, "entry_id": entry_id})
	_check(target.is_finite(), entry_id + " actual first-portal arrival target")
	# The production scene already places its real Player at the first entry.
	# A second probe there would test collision with that Player. Observe the
	# ACTUAL body instead: its query excludes only its own RID, and this harness
	# never assigns it the proposed landing or changes its controller state.
	var collision := player.get_node(^"Collision") as CollisionShape3D
	var radius: float = (collision.shape as CapsuleShape3D).radius
	var before := player.global_transform
	var landing: Vector3 = arrival.call("_capsule_landing", world, player, target, radius)
	_check(player.global_transform == before, entry_id + " solver observes actual Player without pose writes")
	_check(landing.is_finite(), entry_id + " actual Player full-capsule landing accepted")
	var clear := false
	if landing.is_finite():
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision.shape
		var pose := player.global_transform
		pose.origin = landing
		query.transform = pose * collision.transform
		query.collision_mask = player.collision_mask
		query.exclude = [player.get_rid()]
		clear = player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
	_check(clear, entry_id + " actual Player complete candidate capsule clear")
	if not landing.is_finite() and target.is_finite(): DIAGNOSTIC.report(arrival, world, player, target, radius, entry_id)
	var floor_streak := 0
	var supported_frames := 0
	var queries_untouched := true
	for frame in SETTLE_FRAMES:
		if Time.get_ticks_msec() >= _deadline: break
		await physics_frame
		await process_frame
		floor_streak = floor_streak + 1 if player.is_on_floor() else 0
		if frame >= SETTLE_FRAMES - 12:
			before = player.global_transform
			if arrival.call("_supported_capsule", world, player, target, radius) == true: supported_frames += 1
			queries_untouched = queries_untouched and player.global_transform == before
	before = player.global_transform
	var final_supported: bool = arrival.call("_supported_capsule", world, player, target, radius) == true
	queries_untouched = queries_untouched and player.global_transform == before
	var stable: bool = Time.get_ticks_msec() < _deadline and landing.is_finite() and player.is_on_floor() \
		and floor_streak >= 12 and supported_frames == 12 and player.global_position.distance_to(landing) <= radius \
		and player.get_floor_normal().angle_to(player.up_direction) <= player.floor_max_angle
	_check(stable, entry_id + " actual existing Player controller stable walkable contact")
	_check(final_supported, entry_id + " actual Player final five-floor/full-capsule guard")
	_check(queries_untouched, entry_id + " actual Player support queries have no pose writes")
	if not final_supported and target.is_finite(): DIAGNOSTIC.report(arrival, world, player, target, radius, entry_id + " actual Player settled")
	entries.append({"id": entry_id, "target": DIAGNOSTIC.vector(target), "landing": DIAGNOSTIC.vector(landing),
		"settled": DIAGNOSTIC.vector(player.global_position), "shape_radius": radius, "safe_margin": player.safe_margin,
		"mask": player.collision_mask, "stable_contact": stable, "final_supported": final_supported,
		"consecutive_floor_frames": floor_streak, "fixture": "direct scene boot; observe existing actual Player; no harness pose writes or controller changes"})

func _run() -> void:
	_deadline = Time.get_ticks_msec() + TOTAL_BUDGET_MSEC
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--realm="): realm = arg.trim_prefix("--realm=")
	_check(SCENES.has(realm), "requires one --realm=meadows|water|cloudreach|stormwood")
	if not SCENES.has(realm): await _finish(); return
	await process_frame
	var game: Node = root.get_node(^"Game")
	game.set("save_system", SAVE.new("user://f18_native_stones_%s_%d/" % [realm, Time.get_ticks_usec()]))
	game.set("current_realm", realm) # Disclosed direct scene/realm fixture.
	var packed := load(SCENES[realm]) as PackedScene
	_check(packed != null, "production scene loads")
	if packed == null: await _finish(); return
	var world := packed.instantiate() as Node3D
	if world == null:
		_check(false, "production scene root must be Node3D")
		await _finish()
		return
	world.set("simulation_only", false)
	root.add_child(world)
	current_scene = world
	while world.call("shell_build_complete") != true and Time.get_ticks_msec() < _deadline: await process_frame
	_check(world.call("shell_build_complete") == true and world.get("simulation_only") == false, "full production world ready")
	# Observe the real Session component's mount poll; do not call mount here.
	while not world.has_node(^"Waystones") and Time.get_ticks_msec() < _deadline: await process_frame
	_check(world.has_node(^"Waystones"), "production Session mounted collection")
	# Physics must observe the real collection's newly registered shapes.
	await physics_frame
	await physics_frame
	await process_frame
	var config: Dictionary = STONES.load_config()
	var rows: Array[Dictionary] = []
	var configured: Array[String] = []
	for row: Dictionary in config.get("waystones", []):
		if row.realm_id == realm: rows.append(row); configured.append(str(row.id))
	_check(config.get("waystones", []).size() == 19, "all19 configured stones retained")
	_check(configured == IDS[realm] and rows.size() >= 3 and rows.size() <= 5, "exact authored realm IDs and count")
	var actual_ids: Array[String] = []
	var collection := world.get_node_or_null(^"Waystones")
	if collection != null:
		for child: Node in collection.get_children(): actual_ids.append(str(child.name))
	_check(actual_ids == IDS[realm], "no missing or extra production stone mounts")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var source := player.get_node_or_null(^"Collision") as CollisionShape3D if player != null else null
	_check(player != null and source != null and not source.disabled and source.shape is CapsuleShape3D, "actual Player capsule available")
	if source == null or source.disabled or not source.shape is CapsuleShape3D:
		await _finish(world)
		return
	var probe := _probe(world, player, source)
	var copied := probe.get_node(^"Collision") as CollisionShape3D
	_check((copied.shape as CapsuleShape3D).radius == (source.shape as CapsuleShape3D).radius \
		and (copied.shape as CapsuleShape3D).height == (source.shape as CapsuleShape3D).height \
		and copied.transform == source.transform and probe.safe_margin == player.safe_margin \
		and probe.collision_mask == player.collision_mask and probe.floor_max_angle == player.floor_max_angle \
		and probe.floor_snap_length == player.floor_snap_length, "isolated probe uses actual stored Player collision dimensions/settings")
	await physics_frame
	await physics_frame
	await process_frame
	var arrival := ARRIVAL.new()
	await _entry(world, player, arrival, game)
	for row: Dictionary in rows:
		await _stone(world, player, probe, arrival, row, str(config.presentation.model))
	_check(records.size() == IDS[realm].size(), "every configured stone checked without skipped counts")
	_check(Time.get_ticks_msec() < _deadline, "bounded native geometry probe completed")
	probe.queue_free()
	arrival.free()
	await _finish(world)
