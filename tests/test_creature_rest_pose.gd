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
## `rest_roll_deg` (Trailpup still carries -45; Terrapup moved to its authored
## faint pose after the 2026-09-12 visual repro) turns that lift into a dip
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
	# Trailpup remains a negative-roll species. Terrapup intentionally moved
	# to its authored faint pose after the 2026-09-12 visual repro showed this
	# procedural roll balancing the new rig on two feet.
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


func test_terrapup_authored_rest_pose_is_additive_idempotent_and_reversible() -> void:
	_body = _make_body("terrapup")
	var pivot_before := _pivot().transform
	var skeleton := _skeleton()
	assert_true(skeleton != null, "Terrapup exposes its installed skeleton")
	if skeleton == null:
		return
	var names: Array[String] = ["spine", "neck", "head", "front_upper_l",
		"front_lower_l", "front_upper_r", "front_lower_r"]
	var before: Dictionary = {}
	for bone_name: String in names:
		var bone := skeleton.find_bone(bone_name)
		assert_true(bone >= 0, "Terrapup rig retains %s" % bone_name)
		if bone >= 0:
			before[bone_name] = skeleton.get_bone_pose(bone)

	_body.call("play_rest")
	assert_true(bool(_body.call("rest_pose_pending")),
		"play_rest waits for the shipped faint clip before adding the authored finish")
	var players: Array[Node] = _body.find_children("*", "AnimationPlayer", true, false)
	assert_true(not players.is_empty(), "Terrapup exposes its shipped AnimationPlayer")
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	player.seek(player.current_animation_length, true)
	_body.call("_on_rest_animation_finished", &"faint")
	assert_true(bool(_body.call("rest_pose_active")),
		"the completed clip receives Terrapup's authored rest finish")
	var receipt := _body.call("rest_pose_receipt") as Dictionary
	var config := receipt.get("config", {}) as Dictionary
	var expected_pivot_position: Vector3 = pivot_before.origin \
		+ _body.call("_rest_vector", config.get("model_position_offset", []))
	assert_true(_pivot().transform.basis.is_equal_approx(pivot_before.basis),
		"the authored rest does not tip or scale the complete model as a rigid prop")
	assert_true(_pivot().position.is_equal_approx(expected_pivot_position),
		"the authored translation is exactly the measured bed-grounding correction")
	assert_eq((receipt.get("bones", []) as Array).size(), names.size(),
		"the receipt covers the torso, head chain and paired forelegs")
	for bone_name: String in names:
		var bone := skeleton.find_bone(bone_name)
		assert_false(skeleton.get_bone_pose(bone).is_equal_approx(before[bone_name]),
			"%s receives a visible authored rest offset" % bone_name)

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
		"Terrapup's authored finish does not spread to other species")
	var players: Array[Node] = _body.find_children("*", "AnimationPlayer", true, false)
	assert_true(not players.is_empty(), "Galecrest exposes its shipped AnimationPlayer")
	if not players.is_empty():
		var expected := str(SPECIES.placeholder("galecrest").get("animations", {}).get("faint", ""))
		assert_eq((players[0] as AnimationPlayer).current_animation, expected,
			"Galecrest still rests in its authored faint clip")
