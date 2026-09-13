extends "res://tests/test_case.gd"
## N03-CREATURE-BODY-0905: `creature_body.gd::play_rest()`, the creature-bed
## pose, on a REAL body -- `scenes/creatures/creature.tscn` with the species'
## shipped GLB fitted under its pivot, the same node `creature_bed.gd` spawns
## as `RestingCreature`.
##
## Detached, for the same reason `test_companion_presence.gd` is: the runner
## has no live SceneTree, so the body's `@onready` fields are pointed at its
## scene children by hand and `_ready()` is called directly.
##
## What is pinned is the GROUNDING of the roll. Rolling a standing model about
## the pivot at its own feet swings its low side down by about
## `radius * |sin(roll)|` whichever way it tips, so the correction that puts
## it back on the bed is a LIFT in both directions. Written signed, a negative
## `rest_roll_deg` (Trailpup carries -45; Terrapup now uses its authored
## prone pose) turns that lift into a dip
## and buries the sleeper most of a body-height under the bed. W12's
## companion layer fixed its own copy of this arithmetic and reported the bed
## copy for routing (ralph/reports/W12-COMPANION-0904/REPORT.md §6); this is
## that routing.
##
## Seen red first: with the signed form, `test_negative_roll_lifts_not_dips`
## fails at terrapup with the low side 1.36m under the bed line.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var _root: Node3D = null
var _body: Node3D = null


func before_each() -> void:
	_root = Node3D.new()
	_root.name = "World"


func after_each() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null
	_body = null


func _make_body(species_id: String) -> Node3D:
	var body := CREATURE_SCENE.instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	body.name = "RestingCreature"
	_root.add_child(body)
	for field: String in ["_collision:Collision", "_model:Model", "_body:Body", "_head:Head"]:
		var pair: PackedStringArray = field.split(":")
		body.set(pair[0], body.get_node(NodePath(pair[1])))
	body.set("species_id", species_id)
	body.call("_ready")
	assert_true(bool(body.call("has_model")), "%s's shipped model loaded under the pivot" % species_id)
	return body


func _pivot() -> Node3D:
	return _body.call("model_pivot") as Node3D


func _skeleton() -> Skeleton3D:
	var skeletons := _body.find_children("*", "Skeleton3D", true, false)
	return skeletons[0] as Skeleton3D if not skeletons.is_empty() else null


## How far below the bed line the rolled model's low side reaches, ignoring
## the deliberate `rest_sink_extra`/REST_SINK_METERS sink: the pivot's lift
## minus the swing the roll itself produces. Zero or above means "on the bed".
func _low_side_above_bed(sink: float) -> float:
	var radius := float(_body.call("body_radius"))
	var swing_down := radius * absf(sin(_pivot().rotation.z))
	return (_pivot().position.y + sink) - swing_down


func _rest_data(species_id: String) -> Dictionary:
	var look: Dictionary = SPECIES.placeholder(species_id)
	return {
		"roll": float(look.get("rest_roll_deg", CREATURE_BODY.DEFAULT_REST_ROLL_DEG)),
		"sink": float(look.get("rest_sink_extra", CREATURE_BODY.REST_SINK_METERS)),
	}


func test_negative_roll_lifts_not_dips() -> void:
	for species_id in ["trailpup"]:
		_body = _make_body(species_id)
		var data := _rest_data(species_id)
		assert_true(data["roll"] < 0.0, "%s's rest_roll_deg is negative (%.1f); if it is not, this test has lost its subject" % [species_id, data["roll"]])
		_body.call("play_rest")
		assert_almost_eq(_pivot().rotation.z, deg_to_rad(data["roll"]), 0.001,
			"%s rolled by its own rest_roll_deg" % species_id)
		var radius := float(_body.call("body_radius"))
		var lift := _pivot().position.y + float(data["sink"])
		assert_true(lift > 0.0,
			"%s: a roll grounds by LIFTING the pivot; it dipped %.3fm instead" % [species_id, -lift])
		assert_almost_eq(lift, radius * absf(sin(deg_to_rad(data["roll"]))), 0.001,
			"%s: the lift is radius * |sin(roll)|" % species_id)
		var above := _low_side_above_bed(float(data["sink"]))
		assert_true(above >= -0.01,
			"%s: the rolled model's low side is %.3fm under the bed line (roll %.1f deg, pivot y %.3f)" % [
				species_id, -above, data["roll"], _pivot().position.y])
		# The sideways re-centre keeps its sign: which way the body fell is
		# exactly what that term says, so a negative roll re-centres the
		# other way. Only the vertical term is unsigned.
		var height_half := 0.5 * float(_body.call("body_height"))
		assert_almost_eq(_pivot().position.x, height_half * sin(deg_to_rad(data["roll"])), 0.001,
			"%s: the sideways re-centre follows the roll's own direction" % species_id)
		_body.free()
		_body = null


func test_positive_roll_is_unchanged() -> void:
	# A species on the positive default roll: the fix must be byte-for-byte a
	# no-op for it (|sin| == sin when roll > 0). mudsnout has no rest_roll_deg
	# of its own, so it takes DEFAULT_REST_ROLL_DEG.
	_body = _make_body("mudsnout")
	var data := _rest_data("mudsnout")
	assert_true(data["roll"] > 0.0, "mudsnout rests on a positive roll (%.1f)" % data["roll"])
	_body.call("play_rest")
	var radius := float(_body.call("body_radius"))
	assert_almost_eq(_pivot().position.y, radius * sin(deg_to_rad(data["roll"])) - float(data["sink"]), 0.001,
		"the positive-roll lift is exactly what it was before the sign fix")
	assert_true(_low_side_above_bed(float(data["sink"])) >= -0.01, "and its low side sits on the bed")


func test_terrapup_authored_prone_rest_is_idempotent_and_reversible() -> void:
	_body = _make_body("terrapup")
	var pivot_before := _pivot().transform
	var skeleton := _skeleton()
	assert_true(skeleton != null, "Terrapup exposes its installed skeleton")
	if skeleton == null:
		return
	var names: Array[String] = ["pelvis", "spine", "neck", "head", "front_upper_l",
		"front_lower_l", "front_upper_r", "front_lower_r", "rear_upper_l",
		"rear_lower_l", "rear_upper_r", "rear_lower_r"]
	var before: Dictionary = {}
	for bone_name: String in names:
		var bone := skeleton.find_bone(bone_name)
		assert_true(bone >= 0, "Terrapup rig retains %s" % bone_name)
		if bone >= 0:
			before[bone_name] = skeleton.get_bone_pose(bone)
	_body.call("play_rest")
	assert_true(bool(_body.call("rest_pose_pending")),
		"play_rest waits for the installed faint clip before adding the prone finish")
	var players: Array[Node] = _body.find_children("*", "AnimationPlayer", true, false)
	assert_true(not players.is_empty(), "Terrapup exposes its shipped AnimationPlayer")
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	player.seek(player.current_animation_length, true)
	_body.call("_on_rest_animation_finished", &"faint")
	assert_true(bool(_body.call("rest_pose_active")),
		"the completed authored motion receives the prone finish")
	assert_false(bool(_body.call("rest_pose_pending")),
		"the finished prone rest is no longer pending")
	var receipt := _body.call("rest_pose_receipt") as Dictionary
	var config := receipt.get("config", {}) as Dictionary
	assert_eq(str(config.get("mode", "")), "authored", "receipt identifies the skeleton pose path")
	assert_eq((receipt.get("bones", []) as Array).size(), names.size(),
		"the pose covers torso, head chain and all four legs")
	assert_true(_pivot().transform.basis.is_equal_approx(pivot_before.basis),
		"the complete fitted model is neither tipped nor scaled")
	var model_offset := _body.call("_rest_vector", config.get("model_position_offset", [])) as Vector3
	assert_almost_eq(model_offset.y, 1.355, 0.001,
		"the production-measured lift targets -0.120m of bedding compression")
	var pelvis := (config.get("bones", {}) as Dictionary).get("pelvis", {}) as Dictionary
	var pelvis_offset := _body.call("_rest_vector", pelvis.get("position_offset", [])) as Vector3
	assert_true(pelvis_offset.y <= -0.35 and pelvis_offset.z <= -0.40,
		"hips and rump settle into the prone contact plane")
	var neck := (config.get("bones", {}) as Dictionary).get("neck", {}) as Dictionary
	var head := (config.get("bones", {}) as Dictionary).get("head", {}) as Dictionary
	assert_true(absf((_body.call("_rest_vector", neck.get("rotation_deg", [])) as Vector3).y) >= 12.0
		and absf((_body.call("_rest_vector", head.get("rotation_deg", [])) as Vector3).y) >= 16.0,
		"the cheek turns toward a forepaw instead of holding an alert square gaze")
	var applied_spine := skeleton.get_bone_pose(skeleton.find_bone("spine"))
	_body.call("request_move", Vector3.ZERO, 0.0)
	assert_true(bool(_body.call("rest_pose_active")),
		"a controller's stationary request does not wake the resting creature")
	_body.call("play_rest")
	assert_true(skeleton.get_bone_pose(skeleton.find_bone("spine")).is_equal_approx(applied_spine),
		"repeated play_rest is idempotent")
	_body.call("stop_rest")
	assert_false(bool(_body.call("rest_pose_active")), "stop_rest clears the cosmetic pose")
	assert_true(_pivot().transform.is_equal_approx(pivot_before), "stop_rest restores the model pivot")
	for bone_name: String in names:
		var bone := skeleton.find_bone(bone_name)
		assert_true(skeleton.get_bone_pose(bone).is_equal_approx(before[bone_name]),
			"stop_rest restores %s exactly" % bone_name)


func test_authored_rest_model_rotation_is_relative_idempotent_and_reversible() -> void:
	_body = _make_body("terrapup")
	var pivot_before := _pivot().transform
	var fixture := JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/terrapup_rest_candidates_r29.json")) as Dictionary
	var config := ((fixture.get("candidates", []) as Array)[0] as Dictionary).get(
		"config", {}) as Dictionary
	_body.call("_begin_authored_rest_pose", config, SPECIES.placeholder("terrapup"))
	var player := (_body.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer)
	player.seek(player.current_animation_length, true)
	_body.call("_on_rest_animation_finished", &"faint")
	var expected := pivot_before.basis * Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(-78.0)))
	assert_true(_pivot().basis.is_equal_approx(expected),
		"R29 rotates the fitted model -78 degrees relative to its saved basis")
	var applied := _pivot().transform
	_body.call("play_rest")
	assert_true(_pivot().transform.is_equal_approx(applied),
		"repeated play_rest cannot compound the authored model rotation")
	_body.call("stop_rest")
	assert_true(_pivot().transform.is_equal_approx(pivot_before),
		"stop_rest restores the exact pre-rotation fitted pivot")


func test_authored_rest_isolated_torso_deform_preserves_children_and_restores_exactly() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/creatures/creature_body.gd")
	assert_true(source.contains("func _apply_rest_torso_contact_deform()")
		and source.contains("set_bone_pose_scale(bone, base_scale * local_scale)")
		and source.contains("set_bone_global_pose(bone, wanted_global)"),
		"R37 scales the torso chain once and restores descendant globals")
	var preserve_names: Array[String] = ["tail_1", "rear_upper_l", "rear_upper_r",
		"front_upper_l", "front_upper_r", "neck"]
	var fixture := JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/terrapup_rest_candidates_r37.json")) as Dictionary
	var config := ((fixture.get("candidates", []) as Array)[0] as Dictionary).get(
		"config", {}) as Dictionary
	# Establish the exact completed R35-B finish that R37 must preserve outside
	# the torso, rather than comparing against stale globals from before its
	# ordinary authored offsets were applied.
	var control_config := config.duplicate(true)
	control_config.erase("torso_contact_deform")
	var control := _make_body("terrapup")
	control.call("_begin_authored_rest_pose", control_config, SPECIES.placeholder("terrapup"))
	var control_player := (control.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer)
	control_player.seek(control_player.current_animation_length, true)
	control.call("_on_rest_animation_finished", &"faint")
	var control_skeleton := (control.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D)
	control_skeleton.force_update_all_bone_transforms()
	var control_pelvis_scale := control_skeleton.get_bone_pose(
		control_skeleton.find_bone("pelvis")).basis.get_scale()
	var control_preserved_globals: Dictionary = {}
	for bone_name: String in preserve_names:
		control_preserved_globals[bone_name] = control_skeleton.get_bone_global_pose(
			control_skeleton.find_bone(bone_name))

	_body = _make_body("terrapup")
	var skeleton := (_body.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D)
	var pelvis_bone := skeleton.find_bone("pelvis")
	var spine_bone := skeleton.find_bone("spine")
	var pelvis_before := skeleton.get_bone_pose(pelvis_bone)
	var spine_before := skeleton.get_bone_pose(spine_bone)
	var preserve_before: Dictionary = {}
	for bone_name: String in preserve_names:
		preserve_before[bone_name] = skeleton.get_bone_pose(skeleton.find_bone(bone_name))
	_body.call("_begin_authored_rest_pose", config, SPECIES.placeholder("terrapup"))
	var player := (_body.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer)
	player.seek(player.current_animation_length, true)
	assert_true(bool(_body.call("rest_pose_pending")),
		"seeking the completed clip does not apply R37 before the explicit finish callback")
	_body.call("_on_rest_animation_finished", &"faint")
	var pelvis_applied_scale := skeleton.get_bone_pose(pelvis_bone).basis.get_scale()
	assert_true(pelvis_applied_scale.is_equal_approx(
		control_pelvis_scale * Vector3(0.20, 1.0, 1.0)),
		"R37 genuinely deforms the pelvis/spine torso chain once on imported local X")
	assert_eq(skeleton.get_bone_parent(spine_bone), pelvis_bone,
		"the spine-weighted torso inherits the single pelvis deformation")
	for bone_name: String in preserve_names:
		assert_true(skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).is_equal_approx(
			control_preserved_globals[bone_name] as Transform3D),
			"R37 preserves R35-B's completed global pose of %s" % bone_name)
	assert_true(_pivot().basis.get_scale().is_equal_approx(Vector3.ONE),
		"isolated torso deformation never scales the complete model pivot")
	var applied_spine := skeleton.get_bone_pose(spine_bone)
	_body.call("play_rest")
	assert_true(skeleton.get_bone_pose(spine_bone).is_equal_approx(applied_spine),
		"repeated play_rest cannot compound the R37 deformation")
	_body.call("stop_rest")
	assert_true(skeleton.get_bone_pose(pelvis_bone).is_equal_approx(pelvis_before),
		"stop_rest restores the exact cached pelvis transform")
	assert_true(skeleton.get_bone_pose(spine_bone).is_equal_approx(spine_before),
		"stop_rest restores the exact cached spine transform")
	for bone_name: String in preserve_names:
		assert_true(skeleton.get_bone_pose(skeleton.find_bone(bone_name)).is_equal_approx(
			preserve_before[bone_name] as Transform3D),
			"stop_rest restores the exact cached %s transform" % bone_name)


func test_authored_rest_lower_shell_mesh_deform_is_isolated_and_reversible() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/creatures/creature_body.gd")
	assert_true(source.contains("func _apply_rest_torso_vertex_contact_deform()")
		and source.contains("torso_weight / total < torso_weight_min")
		and source.contains("if height >= blend_height")
		and source.contains("desired = minimum + target_span * lower_t"),
		"R38 selects only the measured lower pelvis/spine shell and maps its quartile to contact")
	assert_true(source.contains("_rest_pose_meshes_before[instance] = source")
		and source.contains("instance.mesh = _rest_pose_meshes_before[raw_instance] as Mesh"),
		"R38 owns a per-rest mesh copy and restores the exact installed Mesh reference")
	var fixture := JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/terrapup_rest_candidates_r38.json")) as Dictionary
	var config := ((fixture.get("candidates", []) as Array)[0] as Dictionary).get(
		"config", {}) as Dictionary
	_body = _make_body("terrapup")
	var skeleton := _skeleton()
	var pelvis := skeleton.find_bone("pelvis")
	var spine := skeleton.find_bone("spine")
	var body_transform_before := _body.transform
	var collision_shape_before := (_body.get_node("Collision") as CollisionShape3D).shape
	var original_meshes: Dictionary = {}
	for raw: Node in _pivot().find_children("*", "MeshInstance3D", true, false):
		var instance := raw as MeshInstance3D
		original_meshes[instance] = instance.mesh
	_body.call("_begin_authored_rest_pose", config, SPECIES.placeholder("terrapup"))
	var player := (_body.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer)
	player.seek(player.current_animation_length, true)
	_body.call("_on_rest_animation_finished", &"faint")
	var deformed_count := 0
	for raw_instance: Variant in original_meshes:
		var instance := raw_instance as MeshInstance3D
		if instance.mesh != (original_meshes[raw_instance] as Mesh):
			deformed_count += 1
	assert_true(deformed_count > 0,
		"R38 replaces at least one live Terrapup surface with its private rest-only copy")
	var receipt := _body.call("rest_pose_receipt") as Dictionary
	var vertex_receipt := receipt.get("vertex_contact_deform", {}) as Dictionary
	assert_true(int(vertex_receipt.get("selected_torso_vertices", 0)) > 0
		and int(vertex_receipt.get("moved_lower_torso_vertices", 0)) > 0
		and is_equal_approx(float(vertex_receipt.get("lower_quartile_span_target_m", 0.0)), 0.14),
		"R38 reports the selected/moved population and exact contact target")
	assert_true(skeleton.get_bone_pose(pelvis).basis.get_scale().is_equal_approx(Vector3.ONE)
		and skeleton.get_bone_pose(spine).basis.get_scale().is_equal_approx(Vector3.ONE),
		"R38 does not reintroduce the R36/R37 hierarchy scale failure")
	assert_true(_body.transform.is_equal_approx(body_transform_before)
		and (_body.get_node("Collision") as CollisionShape3D).shape == collision_shape_before,
		"R38 never changes the gameplay body or collider")
	_body.call("play_rest")
	var repeated_meshes: Dictionary = {}
	for raw_instance: Variant in original_meshes:
		repeated_meshes[raw_instance] = (raw_instance as MeshInstance3D).mesh
	_body.call("play_rest")
	for raw_instance: Variant in repeated_meshes:
		assert_true((raw_instance as MeshInstance3D).mesh == (repeated_meshes[raw_instance] as Mesh),
			"repeated play_rest cannot compound or replace the private R38 mesh")
	_body.call("stop_rest")
	for raw_instance: Variant in original_meshes:
		assert_true((raw_instance as MeshInstance3D).mesh == (original_meshes[raw_instance] as Mesh),
			"stop_rest restores the exact pre-rest Mesh reference")


func test_galecrest_zero_roll_keeps_its_existing_faint_only_path() -> void:
	_body = _make_body("galecrest")
	var data := _rest_data("galecrest")
	assert_almost_eq(data["roll"], 0.0, 0.001,
		"Galecrest remains the existing faint-only zero-roll case")
	var before := _pivot().transform
	_body.call("play_rest")
	assert_true(_pivot().transform.is_equal_approx(before),
		"Galecrest is not tipped as one rigid prop")
	assert_false(bool(_body.call("rest_pose_pending")),
		"Galecrest's faint-only path has no delayed rest finish")
	var players: Array[Node] = _body.find_children("*", "AnimationPlayer", true, false)
	assert_true(not players.is_empty(), "Galecrest exposes its shipped AnimationPlayer")
	if not players.is_empty():
		var expected := str(SPECIES.placeholder("galecrest").get("animations", {}).get("faint", ""))
		assert_eq((players[0] as AnimationPlayer).current_animation, expected,
			"Galecrest still rests in its authored faint clip")
