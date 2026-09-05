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
## `rest_roll_deg` (terrapup and trailpup carry -45) turns that lift into a
## dip and buries the sleeper most of a body-height under the bed. W12's
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
	# terrapup and trailpup are the roster's two negative-roll species. Both
	# are checked, because a fix that only worked for one radius would pass a
	# single-species test.
	for species_id in ["terrapup", "trailpup"]:
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


func test_zero_roll_opts_out_to_faint() -> void:
	# galecrest's `rest_roll_deg: 0` routes through play_faint() and never
	# moves the pivot at all -- the one species whose faint clip already lies
	# down on its own.
	_body = _make_body("galecrest")
	var before := _pivot().transform
	_body.call("play_rest")
	assert_true(_pivot().transform.is_equal_approx(before), "a zero roll leaves the pivot where the fit put it")
