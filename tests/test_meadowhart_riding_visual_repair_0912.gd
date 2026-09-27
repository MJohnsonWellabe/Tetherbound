extends "res://tests/test_case.gd"

## Static contract for the OWNER-0912 riding visual repair.  Runtime geometry
## remains owned by smoke_riding.gd and the native final-riding capture; this
## file prevents either receipt from being made green by adding a fake saddle,
## moving the physical seat, or directly staging the trainer pose in a tool.

const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _species() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_source("res://data/creatures/species.json"))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_installed_meadowhart_is_a_complete_skinned_bare_body() -> void:
	var look := SPECIES.placeholder("meadowhart")
	assert_false(look.has("bare_body_repair"), "destructive centroid-based repair returned")
	var art := (load(str(look.model)) as PackedScene).instantiate()
	var meshes := art.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1, "the animal must be one complete skin, without filler primitives")
	var mesh_instance := art.find_child("MeadowhartBareBody", true, false) as MeshInstance3D
	assert_true(mesh_instance != null and mesh_instance.skin != null,
		"complete authored bare skin is missing")
	if mesh_instance == null:
		art.free()
		return
	var mesh := mesh_instance.mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var used := {}
	for index: int in indices:
		used[index] = true
	var bounds := mesh.get_aabb()
	# Regression: the centroid strip retained hooves while deleting both
	# forelegs above them. Require active triangle vertices through each leg,
	# from shin to shoulder, normalized to the imported animal's full height.
	for side: float in [-1.0, 1.0]:
		for band: float in [0.16, 0.28, 0.40]:
			var count := 0
			for index: int in used:
				var point := vertices[index]
				var h := (point.y - bounds.position.y) / bounds.size.y
				if point.x * side > 0.04 and point.z > 0.05 and absf(h - band) < 0.035:
					count += 1
			assert_true(count >= 12, "foreleg %s loses geometry at height band %s" % [side, band])
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var invalid_weights := 0
	for index: int in used:
		var total := 0.0
		for influence in 4:
			total += weights[index * 4 + influence]
		if total <= 0.99 or total >= 1.01:
			invalid_weights += 1
	assert_eq(invalid_weights, 0, "unbound or unnormalized skin vertices")
	var player := art.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
		assert_true(player.has_animation(clip), "production clip missing: %s" % clip)
	art.free()


func test_repeated_installed_meadowhart_instances_share_one_stable_bare_mesh() -> void:
	var table: Dictionary = _species().get("species", {})
	var look: Dictionary = (table.get("meadowhart", {}) as Dictionary).get("placeholder", {})
	var packed := load(str(look.get("model", ""))) as PackedScene
	assert_true(packed != null, "installed Meadowhart GLB did not load")
	if packed == null:
		return
	var shared_bare_id := 0
	for cycle in 12:
		var art := packed.instantiate() as Node3D
		assert_true(art != null, "installed Meadowhart cycle %d did not instantiate" % cycle)
		if art == null:
			continue
		var skinned: MeshInstance3D = null
		for candidate: Node in art.find_children("*", "MeshInstance3D", true, false):
			var instance := candidate as MeshInstance3D
			if instance != null and instance.skin != null:
				skinned = instance
				break
		assert_true(skinned != null, "installed Meadowhart cycle %d lost its skin" % cycle)
		if skinned != null:
			var bare_id := skinned.mesh.get_instance_id()
			if shared_bare_id == 0:
				shared_bare_id = bare_id
			assert_eq(bare_id, shared_bare_id,
				"repeated installed Meadowhart setup retained another full bare mesh")
		art.free()
	assert_true(shared_bare_id != 0, "no reusable bare mesh was measured")


func test_meadowhart_preserves_rider_leg_clearance_without_moving_the_seat() -> void:
	var table: Dictionary = _species().get("species", {})
	var meadowhart: Dictionary = table.get("meadowhart", {})
	var rideable: Dictionary = meadowhart.get("rideable", {})
	var look: Dictionary = meadowhart.get("placeholder", {})
	assert_eq(rideable.get("mount_offset", []), [0.0, 2.187805, -0.252439],
		"visual repair moved the already-passing physical seat")
	var spread := float(rideable.get("rider_thigh_spread_deg", 0.0))
	assert_true(spread >= 55.0 and spread <= 70.0,
		"Meadowhart near leg no longer has bounded flank clearance")
	var leg_fit: Dictionary = rideable.get("rider_leg_fit", {})
	assert_between(float(leg_fit.get("outset_m", 0.0)), 0.42, 0.55,
		"riding gaiters no longer clear the Meadowhart flank")
	assert_between(float(leg_fit.get("stirrup_drop_m", 0.0)), 0.52, 0.66,
		"boot no longer reaches the fitted saddle stirrup height")
	assert_eq((leg_fit.get("boot_size_m", []) as Array).size(), 3)
	assert_eq(float(leg_fit.get("outset_m", 0.0)), 0.42,
		"boot no longer overlaps the production saddle's outer stirrup")
	assert_between(float(leg_fit.get("knee_forward_m", 0.0)), 0.18, 0.26,
		"riding leg lost the visible knee articulation required by R7 review")
	assert_eq(leg_fit.get("boot_size_m", []), [0.16, 0.16, 0.27],
		"the oversized rectangular R7 boot returned")


func test_rideable_accessor_preserves_the_authored_visual_fit() -> void:
	var resolved := SPECIES.rideable("meadowhart")
	assert_eq(float(resolved.get("rider_thigh_spread_deg", -1.0)), 62.0,
		"production accessor dropped Meadowhart's thigh spread")
	var leg_fit: Dictionary = resolved.get("rider_leg_fit", {})
	assert_false(leg_fit.is_empty(), "production accessor dropped Meadowhart's leg fit")
	assert_eq(float(leg_fit.get("outset_m", 0.0)), 0.42)


func test_alpha_size_path_resizes_fitted_art_without_a_second_skin_rebuild() -> void:
	var body := _source("res://scripts/creatures/creature_body.gd")
	var start := body.find("func apply_size_multiplier(")
	var finish := body.find("\nfunc ", start + 1)
	var resize_path := body.substr(start, finish - start)
	assert_true(resize_path.contains("_height *= multiplier")
		and resize_path.contains("_radius *= multiplier")
		and resize_path.contains("_collision.shape = shape"),
		"alpha size stopped moving gameplay body and collider together")
	assert_true(resize_path.contains("_resize_fitted_model(multiplier)"),
		"alpha size still lacks the crash-free fitted-art path")
	assert_false(resize_path.contains("_release_art("),
		"alpha size directly destroys the live skinned art")
	var helper_start := body.find("func _resize_fitted_model(")
	var helper_finish := body.find("\nfunc ", helper_start + 1)
	var helper := body.substr(helper_start, helper_finish - helper_start)
	assert_true(helper.contains("art.position *= multiplier")
		and helper.contains("art.scale *= multiplier"),
		"in-place alpha fit no longer preserves scale and ground/centre offset")


func test_species_leg_clearance_flows_through_local_and_remote_production_riders() -> void:
	var accessor := _source("res://scripts/creatures/creature_species.gd")
	var riding := _source("res://scripts/world/riding_controller.gd")
	var player := _source("res://scripts/player/player_controller.gd")
	var trainer := _source("res://scripts/player/trainer_model.gd")
	var remote := _source("res://scripts/net/remote_trainer.gd")
	for source: String in [riding, remote]:
		assert_true(source.contains('"rider_thigh_spread_deg"')
			and source.contains('"rider_leg_fit"') and source.contains("-1.0"),
			"production rider path omitted the species leg clearance")
	assert_true(remote.contains("var fit_missing := net_riding")
		and remote.contains("net_riding != _rode_last or fit_missing"),
		"late remote mount proxies no longer repair a missing real leg-fit node")
	assert_true(accessor.contains('"rider_thigh_spread_deg"')
		and accessor.contains('"rider_leg_fit": leg_fit'),
		"validated rideable accessor no longer returns the authored visual fit")
	assert_true(player.contains("rider_thigh_spread_deg: float = -1.0")
		and player.contains("rider_leg_fit: Dictionary = {}")
		and player.contains('call("set_riding", node != null, rider_thigh_spread_deg, rider_leg_fit)'))
	assert_true(trainer.contains("thigh_spread_override_deg: float = -1.0")
		and trainer.contains("var spread_deg := thigh_spread_override_deg")
		and trainer.contains("_build_riding_leg_fit(skeleton_node, rider_leg_fit)")
		and trainer.contains("func riding_leg_fit_present()")
		and trainer.contains("func riding_leg_fit_receipt()")
		and trainer.contains("var seat := Vector3.ZERO")
		and trainer.contains("var mesh := PrismMesh.new()"))
	# Hips still land by the live-rig measurement; spread changes only the pose.
	assert_true(trainer.contains("_seat_drop = _measured_seat_drop(skeleton_node)")
		and trainer.contains("_seat_drop_target.position.y -= _seat_drop"))


func test_capture_uses_the_production_practice_meadow_and_fails_on_occlusion() -> void:
	var capture := _source("res://tools/_capture_riding.gd")
	assert_true(capture.contains("const OPEN_RIDE_XZ := Vector2(30.0, -40.0)"))
	assert_true(capture.contains("const EYE_SIDE := 6.2")
		and capture.contains("const SIDE_EYE_SIDE := 6.6"),
		"R6 camera returned to R5's body-intersecting distance")
	assert_true(capture.contains("func _subject_sightline_clear")
		and capture.contains('"camera_subject_sightline_clear": true'),
		"native receipt no longer fails closed on a blocked subject")


func test_meadowhart_settled_companion_station_remains_mountable() -> void:
	var opening: Dictionary = JSON.parse_string(_source("res://data/config/opening.json"))
	var follower: Dictionary = opening.get("follower", {})
	var table: Dictionary = _species().get("species", {})
	var look: Dictionary = (table.get("meadowhart", {}) as Dictionary).get("placeholder", {})
	var height := float(look.get("height", 0.0))
	var radius := float(look.get("radius", 0.0))
	var side := float(follower.get("side_offset", 0.0)) + maxf(radius,
		height * float(follower.get("visual_clearance_height_ratio", 0.0)))
	var forward := height * float(follower.get("visual_lead_height_ratio", 0.0)) \
		- float(follower.get("back_offset", 0.0))
	var settled_station := Vector2(side, forward).length()
	var settled_surface := maxf(0.0, settled_station - radius)
	assert_true(settled_surface > RIDING.MOUNT_RADIUS,
		"fixture no longer reproduces R6's production proximity rejection")
	assert_true(settled_surface < RIDING.mount_reach_radius(
		RIDING.MOUNT_RADIUS, settled_station),
		"camera-safe production follower station remains outside Ride reach")
	var capture := _source("res://tools/_capture_riding.gd")
	assert_true(capture.contains('"production_mount_attempt"')
		and capture.contains('"allowed_surface_distance_m"')
		and capture.contains('"mountable_body_matches"')
		and capture.contains('"riding_allowed"'),
		"R7 cannot identify which real production mount gate rejected")


func test_native_receipt_fails_closed_on_bare_body_and_records_near_leg_joints() -> void:
	var capture := _source("res://tools/_capture_riding.gd")
	for required: String in ["production Meadowhart did not apply its bare-body source repair",
			"unfitted production mount already carries a RideSaddle",
			'"meadowhart_bare_body_present"', "_rider_limb_receipt",
			'"hip_world"', '"knee_world"', '"ankle_world"',
			'"production_riding_leg_fit_present"', "riding_leg_fit_present",
			'"production_riding_leg_fit"', "riding_leg_fit_receipt",
			"production riding leg/boot fit is discontinuous",
			"RidingController.mount()"]:
		assert_true(capture.contains(required), "riding receipt omits %s" % required)
	for forbidden: String in ["reparent(player", "player.reparent", "set_rider_pose", ".seek("]:
		assert_false(capture.contains(forbidden), "riding receipt stages forbidden state: %s" % forbidden)
