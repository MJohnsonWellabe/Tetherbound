extends "res://tests/test_case.gd"

## Static contract for the OWNER-0912 riding visual repair.  Runtime geometry
## remains owned by smoke_riding.gd and the native final-riding capture; this
## file prevents either receipt from being made green by adding a fake saddle,
## moving the physical seat, or directly staging the trainer pose in a tool.

const BARE_BODY := preload("res://scripts/creatures/meadowhart_bare_body.gd")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _species() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_source("res://data/creatures/species.json"))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_meadowhart_source_repair_strips_baked_tack_and_follows_the_real_rig() -> void:
	var helper := _source("res://scripts/creatures/meadowhart_bare_body.gd")
	for required: String in ["_strip_tack_components", "surface_get_arrays",
			"component_sums", "kept_indices", "BoneAttachment3D.new()",
			"get_bone_global_rest", 'const TORSO_NODE := "MeadowhartBareTorso"']:
		assert_true(helper.contains(required), "bare-body repair omits %s" % required)
	for forbidden: String in ["assets/props/riding_saddle", "AnimationPlayer", ".seek(", "set_riding("]:
		assert_false(helper.contains(forbidden), "bare-body repair creates/stages forbidden state: %s" % forbidden)
	var body := _source("res://scripts/creatures/creature_body.gd")
	assert_true(body.contains('if species_id == "meadowhart"')
		and body.contains("MEADOWHART_BARE_BODY.apply(art")
		and body.contains("meadowhart_bare_body_present"))


func test_installed_meadowhart_mesh_rebuilds_and_binds_without_rendering() -> void:
	assert_true(CREATURE_BODY != null, "production creature body did not parse")
	var table: Dictionary = _species().get("species", {})
	var look: Dictionary = (table.get("meadowhart", {}) as Dictionary).get("placeholder", {})
	var repair: Dictionary = look.get("bare_body_repair", {})
	var packed := load(str(look.get("model", ""))) as PackedScene
	assert_true(packed != null, "installed Meadowhart GLB did not load")
	if packed == null:
		return
	var art := packed.instantiate() as Node3D
	var meshes := art.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1, "installed Meadowhart source shape changed")
	if meshes.size() != 1:
		art.free()
		return
	var source := (meshes[0] as MeshInstance3D).mesh as ArrayMesh
	assert_true(source != null and source.get_blend_shape_count() == 0,
		"source gained morph targets the bounded repair cannot preserve")
	var before: PackedInt32Array = source.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	assert_true(BARE_BODY.apply(art, repair), "installed source tack strip failed")
	var rebuilt := (meshes[0] as MeshInstance3D).mesh as ArrayMesh
	var after: PackedInt32Array = rebuilt.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	assert_true(after.size() > 0 and after.size() < before.size(),
		"source repair did not remove a bounded set of indexed triangles")
	assert_true(BARE_BODY.bind_torso_to_rig(art, repair),
		"replacement torso did not bind to the production pelvis")
	var torso := art.find_child(BARE_BODY.TORSO_NODE, true, false)
	assert_true(torso != null and torso.get_parent() is BoneAttachment3D,
		"replacement torso is not following the production skeleton")
	art.free()


func test_repeated_installed_meadowhart_instances_share_one_stable_bare_mesh() -> void:
	var table: Dictionary = _species().get("species", {})
	var look: Dictionary = (table.get("meadowhart", {}) as Dictionary).get("placeholder", {})
	var repair: Dictionary = look.get("bare_body_repair", {})
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
		assert_true(BARE_BODY.apply(art, repair),
			"installed Meadowhart cycle %d did not strip tack" % cycle)
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
		assert_true(BARE_BODY.bind_torso_to_rig(art, repair),
			"installed Meadowhart cycle %d did not bind its torso" % cycle)
		art.free()
	assert_true(shared_bare_id != 0, "no reusable bare mesh was measured")


func test_meadowhart_authors_bare_torso_and_leg_clearance_without_moving_the_seat() -> void:
	var table: Dictionary = _species().get("species", {})
	var meadowhart: Dictionary = table.get("meadowhart", {})
	var rideable: Dictionary = meadowhart.get("rideable", {})
	var look: Dictionary = meadowhart.get("placeholder", {})
	var repair: Dictionary = look.get("bare_body_repair", {})
	assert_eq(rideable.get("mount_offset", []), [0.0, 2.187805, -0.252439],
		"visual repair moved the already-passing physical seat")
	var spread := float(rideable.get("rider_thigh_spread_deg", 0.0))
	assert_true(spread >= 55.0 and spread <= 70.0,
		"Meadowhart near leg no longer has bounded flank clearance")
	assert_eq(str(repair.get("follow_bone", "")), "pelvis")
	assert_eq((repair.get("torso_center", []) as Array).size(), 3)
	assert_eq((repair.get("torso_half_extents", []) as Array).size(), 3)
	assert_eq((repair.get("component_centroid_min", []) as Array).size(), 3)
	assert_eq((repair.get("component_centroid_max", []) as Array).size(), 3)
	var leg_fit: Dictionary = rideable.get("rider_leg_fit", {})
	assert_between(float(leg_fit.get("outset_m", 0.0)), 0.42, 0.55,
		"riding gaiters no longer clear the Meadowhart flank")
	assert_between(float(leg_fit.get("stirrup_drop_m", 0.0)), 0.52, 0.66,
		"boot no longer reaches the fitted saddle stirrup height")
	assert_eq((leg_fit.get("boot_size_m", []) as Array).size(), 3)


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
	var riding := _source("res://scripts/world/riding_controller.gd")
	var player := _source("res://scripts/player/player_controller.gd")
	var trainer := _source("res://scripts/player/trainer_model.gd")
	var remote := _source("res://scripts/net/remote_trainer.gd")
	for source: String in [riding, remote]:
		assert_true(source.contains('"rider_thigh_spread_deg"')
			and source.contains('"rider_leg_fit"') and source.contains("-1.0"),
			"production rider path omitted the species leg clearance")
	assert_true(player.contains("rider_thigh_spread_deg: float = -1.0")
		and player.contains("rider_leg_fit: Dictionary = {}")
		and player.contains('call("set_riding", node != null, rider_thigh_spread_deg, rider_leg_fit)'))
	assert_true(trainer.contains("thigh_spread_override_deg: float = -1.0")
		and trainer.contains("var spread_deg := thigh_spread_override_deg")
		and trainer.contains("_build_riding_leg_fit(skeleton_node, rider_leg_fit)")
		and trainer.contains("func riding_leg_fit_present()"))
	# Hips still land by the live-rig measurement; spread changes only the pose.
	assert_true(trainer.contains("_seat_drop = _measured_seat_drop(skeleton_node)")
		and trainer.contains("_seat_drop_target.position.y -= _seat_drop"))


func test_native_receipt_fails_closed_on_bare_body_and_records_near_leg_joints() -> void:
	var capture := _source("res://tools/_capture_riding.gd")
	for required: String in ["production Meadowhart did not apply its bare-body source repair",
			"unfitted production mount already carries a RideSaddle",
			'"meadowhart_bare_body_present"', "_rider_limb_receipt",
			'"hip_world"', '"knee_world"', '"ankle_world"',
			'"production_riding_leg_fit_present"', "riding_leg_fit_present",
			"RidingController.mount()"]:
		assert_true(capture.contains(required), "riding receipt omits %s" % required)
	for forbidden: String in ["reparent(player", "player.reparent", "set_rider_pose", ".seek("]:
		assert_false(capture.contains(forbidden), "riding receipt stages forbidden state: %s" % forbidden)
