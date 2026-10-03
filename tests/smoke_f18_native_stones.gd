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

class ProbeBody extends "res://scripts/player/player_controller.gd":
	var gravity := 26.0
	var consecutive_floor_frames := 0
	# Suppress gameplay registration, stats/torch/tool children and input.
	# Only the shipping collision-skin helper below runs on this isolated RID.
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func _physics_process(delta: float) -> void:
		velocity.y -= gravity * delta
		move_and_slide()
		_settle_skin_overlap()
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
		"probe_controller": "isolated gravity/move_and_slide plus inherited unchanged shipping _settle_skin_overlap; not full Player input/vitals/idle policy",
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

func _transition_topology(world: Node3D, entry_id: String) -> void:
	var label: String = world.call("_safe_name", entry_id)
	var pad := world.get_node_or_null("RealmTransitionLedges/" + label) as Node3D
	var mesh := pad.get_node_or_null(^"StratifiedCliffBody") as MeshInstance3D if pad != null else null
	var body := pad.get_node_or_null(^"Collision") as StaticBody3D if pad != null else null
	var collision := body.get_child(0) as CollisionShape3D if body != null and body.get_child_count() == 1 else null
	_check(mesh != null and mesh.mesh != null and collision != null and collision.shape is ConcavePolygonShape3D,
		entry_id + " actual transition render and concave collision")
	if mesh == null or mesh.mesh == null or collision == null or not collision.shape is ConcavePolygonShape3D: return
	var top: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var faces := (collision.shape as ConcavePolygonShape3D).get_faces()
	# The canonical 50-sided flat entry retains 48 top triangles and its same
	# 100-triangle shallow skirt. Compare the ACTUAL visible/collision vertices.
	_check(top.size() == 48 * 3 and faces.size() == top.size() + 100 * 3,
		entry_id + " perimeter triangulation and original skirt triangle counts")
	var identical := faces.size() >= top.size()
	var flat := true
	var upward := true
	var boundary: Array[Vector3] = []
	for i in top.size():
		identical = identical and i < faces.size() and faces[i] == top[i]
		flat = flat and top[i].y == Vector3(0, 8.03, 0).y
		if not boundary.has(top[i]): boundary.append(top[i])
	for i in range(0, top.size(), 3):
		upward = upward and (top[i + 2] - top[i]).cross(top[i + 1] - top[i]).y > 0.0
	_check(identical and flat and upward, entry_id + " exact shared flat upward render/collision top")
	var rim: Array[Vector3] = []
	for i in range(top.size(), faces.size()):
		if faces[i].y == Vector3(0, 8.03, 0).y and not rim.has(faces[i]): rim.append(faces[i])
	var same_perimeter := boundary.size() == 50 and rim.size() == 50
	for point: Vector3 in boundary: same_perimeter = same_perimeter and rim.has(point)
	_check(same_perimeter and not boundary.has(Vector3(0, 8.03, 0)),
		entry_id + " original skirt perimeter vertices with no central contact hub")
	print("F18_TRANSITION_TOPOLOGY " + JSON.stringify({"entry_id": entry_id, "top_vertices": top.size(),
		"collision_vertices": faces.size(), "boundary_vertices": boundary.size(), "rim_vertices": rim.size(),
		"identical_top": identical, "flat": flat, "upward": upward, "same_perimeter": same_perimeter}))
	_transition_route_union(world, pad, top)

func _transition_route_union(world: Node3D, pad: Node3D, transition_top: PackedVector3Array) -> void:
	var route := world.get_node_or_null(^"AuthoredRoutes/ArrivalGateRoad_Ledge0") as Node3D
	var mesh := route.get_node_or_null(^"StratifiedCliffBody") as MeshInstance3D if route != null else null
	var body := route.get_node_or_null(^"Collision") as StaticBody3D if route != null else null
	var shape := body.get_child(0) as CollisionShape3D if body != null and body.get_child_count() == 1 else null
	_check(mesh != null and mesh.mesh != null and shape != null and shape.shape is ConcavePolygonShape3D,
		"arrival road retains actual visible geology and outer collision")
	if mesh == null or mesh.mesh == null or shape == null or not shape.shape is ConcavePolygonShape3D: return
	var top: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var faces := (shape.shape as ConcavePolygonShape3D).get_faces()
	var hub_triangles := 0
	for i in range(0, top.size(), 3):
		if top[i].x != 0.0 or top[i].z != 0.0: break
		hub_triangles += 1
	var removed := hub_triangles * 3
	var same_outer := hub_triangles >= 48 and faces.size() == top.size() - removed + hub_triangles * 6
	for i in range(removed, top.size()):
		var j := i - removed
		same_outer = same_outer and j < faces.size() and faces[j] == top[i].snapped(Vector3.ONE * .0001)
	_check(same_outer, "only hub collision omitted; outer strips unchanged and skirt triangle count retained")
	var plane := pad.to_global(transition_top[0]).y
	var coplanar := true
	var centroids_supported := true
	var native_hits := 0
	for i in range(0, removed, 3):
		var centre := Vector3.ZERO
		for j in 3:
			var point := route.to_global(top[i + j])
			coplanar = coplanar and point.y == plane
			centre += point / 3.0
		var hit := _union_floor_ray(world, centre)
		centroids_supported = centroids_supported and not hit.is_empty() \
			and hit.get("collider") == pad.get_node(^"Collision") \
			and absf(hit.position.y - plane) <= (world.get_node(^"Player") as CharacterBody3D).safe_margin
		if not hit.is_empty(): native_hits += 1
	_check(coplanar and world.call("_transition_covers_arrival_hub", route, top[0], _route_hub_ring(top, removed)) == true,
		"actual omitted hub fully contained on exactly coplanar transition triangles")
	_check(centroids_supported, "every removed triangle centroid still has actual transition support")
	var seam_supported := true
	for radius: float in [1.75, 2.0, 2.25, 12.8, 13.12, 13.4]:
		for i in 16:
			var angle := TAU * float(i) / 16.0
			var hit := _union_floor_ray(world, Vector3(pad.global_position.x + cos(angle) * radius, plane,
				pad.global_position.z + sin(angle) * radius))
			seam_supported = seam_supported and not hit.is_empty()
	_check(seam_supported, "native floor union covers hub seam and retained route rim")
	var approach_supported := true
	var direction := Vector3(-80.0, 0, 300.0).normalized()
	for distance: float in [0.0, 1.9, 2.0, 2.1, 6.0, 6.56, 10.0, 13.12, 14.0, 16.0, 18.0, 22.0, 28.0]:
		var centre := Vector3(pad.global_position.x, plane, pad.global_position.z) + direction * distance
		for offset: Vector2 in [Vector2.ZERO, Vector2(-.4, 0), Vector2(.4, 0), Vector2(0, -.4), Vector2(0, .4)]:
			var hit := _union_floor_ray(world, centre + Vector3(offset.x, 0, offset.y))
			approach_supported = approach_supported and not hit.is_empty()
	_check(approach_supported, "native complete-footprint floor union continues across transition boundary onto rising road")
	print("F18_TRANSITION_ROUTE_UNION " + JSON.stringify({"hub_triangles": hub_triangles, "visible_top_vertices": top.size(),
		"collision_vertices": faces.size(), "same_outer": same_outer, "coplanar": coplanar, "centroid_hits": native_hits,
		"centroids_supported": centroids_supported, "seam_supported": seam_supported, "approach_supported": approach_supported,
		"fixture": "read-only actual geometry and native rays; no Player pose writes or traversal acceptance claim"}))

func _route_hub_ring(top: PackedVector3Array, removed: int) -> Array:
	var ring: Array[Vector3] = []
	# Submitted fan is crown, inner[i], inner[next]; remove the shared lift.
	for i in range(0, removed, 3): ring.append(top[i + 1] - Vector3.UP * .03)
	return ring

func _union_floor_ray(world: Node3D, at: Vector3) -> Dictionary:
	var player := world.get_node(^"Player") as CharacterBody3D
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at - Vector3.UP * 3.0, player.collision_mask)
	ray.exclude = [player.get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or not hit.get("collider") is StaticBody3D: return {}
	var point: Vector3 = hit.position
	var normal: Vector3 = hit.normal
	if not point.is_finite() or not normal.is_finite() or normal.length_squared() <= 0.0: return {}
	if normal.angle_to(Vector3.UP) > player.floor_max_angle: return {}
	return hit

func _entry(world: Node3D, player: CharacterBody3D, probe: ProbeBody, arrival: Node, game: Node) -> void:
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
	# Direct Meadows scene boot starts at the village opening, away from the
	# Hall portal fallback. Use the disclosed isolated candidate/controller
	# fixture there; observing the remote Player cannot prove entry contact.
	if realm == "meadows" and target.is_finite() and player.global_position.distance_to(target) > radius:
		var record := await _geometry(world, player, probe, arrival, target, entry_id)
		record["fixture"] = "direct Meadows scene boot at village; isolated actual-capsule candidate/controller fixture at Hall portal fallback; no Player pose writes"
		entries.append(record)
		return
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
	if target.is_finite() and (not landing.is_finite() or realm == "cloudreach"):
		DIAGNOSTIC.report(arrival, world, player, target, radius, entry_id)
	if target.is_finite() and realm == "water" and not landing.is_finite():
		DIAGNOSTIC.terrain_seam_report(arrival, world, player, target, radius)
	if realm == "cloudreach": _transition_topology(world, entry_id)
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
	await _entry(world, player, probe, arrival, game)
	for row: Dictionary in rows:
		await _stone(world, player, probe, arrival, row, str(config.presentation.model))
	_check(records.size() == IDS[realm].size(), "every configured stone checked without skipped counts")
	_check(Time.get_ticks_msec() < _deadline, "bounded native geometry probe completed")
	probe.queue_free()
	arrival.free()
	await _finish(world)
