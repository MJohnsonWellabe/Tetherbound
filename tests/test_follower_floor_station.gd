extends "res://tests/test_case.gd"

## The shared follower keeps its companion on the trainer's floor
## (`follower_creature.gd`: `station_validator`, the leash snap guard).
##
## Reviewer findings (Cloudreach narrow roads): the leash snap seated the
## companion on the terrain HEIGHT ESTIMATE under its flank station -- beside
## a narrow road that is the floor below the drop -- and the walk to that flank
## station had no floor check. The unit runner has no tree, so the fixture is a
## detached real follower body (as tests/test_companion_presence.gd); the
## in-world behaviour is tests/smoke_cloudreach_follower_edge.gd.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")

const LEADER_AT := Vector3(60.0, 0.0, 0.0)
const VALLEY_Y := -20.0

var _root: Node3D = null
var _body: CharacterBody3D = null
var _leader: Node3D = null
var _calls: Array = []
var _answer: Vector3 = Vector3.INF


func before_each() -> void:
	_root = Node3D.new()
	# Stand-in trainer answering `is_on_floor` (a CharacterBody3D's is only set
	# by move_and_slide in a physics world, which the unit runner has not).
	var trainer := GDScript.new()
	trainer.source_code = "extends Node3D\nvar grounded := true\nfunc is_on_floor() -> bool:\n\treturn grounded\n"
	trainer.reload()
	_leader = trainer.new()
	_root.add_child(_leader)
	_leader.position = LEADER_AT
	_body = CREATURE_SCENE.instantiate()
	_body.set_script(FOLLOWER)
	_root.add_child(_body)
	for field: String in ["_collision:Collision", "_model:Model", "_body:Body", "_head:Head"]:
		var pair: PackedStringArray = field.split(":")
		_body.set(pair[0], _body.get_node(NodePath(pair[1])))
	_body.set("species_id", "terrapup")
	_body.call("_ready")
	_body.position = Vector3.ZERO
	_body.set("leader", _leader)
	_body.call("set_following", true)
	_calls.clear()
	_answer = Vector3.INF


func after_each() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func _validator(body: Node3D, trainer: Node3D, requested: Vector3, snap: bool) -> Vector3:
	_calls.append({"body": body, "trainer": trainer, "requested": requested, "snap": snap})
	return _answer


func test_default_snap_keeps_an_ordinary_seat() -> void:
	assert_true(FOLLOWER.snap_seat_acceptable(-3.5, 0.0), "a hillside flank a few metres down is kept")
	assert_true(FOLLOWER.snap_seat_acceptable(2.0, 0.0), "a flank above the trainer is kept")
	assert_false(FOLLOWER.snap_seat_acceptable(VALLEY_Y, 0.0), "a floor under a drop is refused")


func test_validator_places_the_leash_snap() -> void:
	_body.set("station_validator", _validator)
	_answer = LEADER_AT + Vector3(-2.0, 0.3, 0.0)
	_body.call("_tick_follow")
	assert_eq(_calls.size(), 1, "the snap asks the realm validator once")
	assert_true(bool(_calls[0]["snap"]) and _calls[0]["trainer"] == _leader,
		"as a snap, for this follower's own trainer")
	assert_true(_body.position.is_equal_approx(_answer),
		"the companion stands on the verified spot (%s)" % _body.position)


func test_validator_station_steers_and_is_not_rechecked_every_frame() -> void:
	_body.set("station_validator", _validator)
	_body.position = LEADER_AT + Vector3(0.0, 0.0, 10.0)
	_answer = LEADER_AT + Vector3(-3.0, 0.0, 0.0)
	for i in 5:
		_body.call("_tick_follow")
	assert_eq(_calls.size(), 1, "a standing trainer's unchanged station is verified once, not per frame")
	assert_false(bool(_calls[0]["snap"]), "as a walking station")
	var requested: Vector3 = _body.get("_requested")
	var want := (_answer - _body.position)
	want.y = 0.0
	assert_true(requested.normalized().dot(want.normalized()) > 0.99,
		"it walks toward the verified station, not the raw flank (%s vs %s)" % [requested, want])


func test_no_verified_station_closes_on_the_trainer_and_stops_clear() -> void:
	_body.set("station_validator", _validator)
	_answer = Vector3.INF
	_body.position = LEADER_AT + Vector3(0.0, 0.0, 10.0)
	_body.call("_tick_follow")
	var requested: Vector3 = _body.get("_requested")
	assert_true(requested.normalized().dot(Vector3.FORWARD) > 0.99,
		"with nowhere verified it heads for the trainer's own ground (%s)" % requested)
	var clear := float(_body.call("body_radius")) + FOLLOWER.TRAINER_FALLBACK_CLEARANCE_M
	_body.position = LEADER_AT + Vector3(0.0, 0.0, clear - 0.1)
	_body.set("_closing", false)
	_body.set("_requested", Vector3.ZERO)
	_body.call("_tick_follow")
	assert_true((_body.get("_requested") as Vector3).length() < 0.001,
		"and stands clear of the trainer's capsule instead of pushing into it")


func test_without_a_validator_the_station_is_unchanged() -> void:
	_body.position = LEADER_AT + Vector3(0.0, 0.0, 10.0)
	_body.call("_tick_follow")
	var requested: Vector3 = _body.get("_requested")
	var want: Vector3 = _body.call("formation_target") - _body.position
	want.y = 0.0
	assert_true(requested.normalized().dot(want.normalized()) > 0.999,
		"other realms keep the plain flank station (%s vs %s)" % [requested, want])


func test_airborne_trainer_snap_skips_the_floor_rules() -> void:
	# A trainer flying 20 m up is not standing on ground: its position is not a
	# floor level, so neither the validator's footprint rung nor the 6 m rule
	# may be measured from it (the companion would be set in mid-air).
	_body.set("station_validator", _validator)
	_leader.set("grounded", false)
	_leader.position = LEADER_AT + Vector3(0.0, 20.0, 0.0)
	_answer = _leader.position
	_body.call("_tick_follow")
	assert_eq(_calls.size(), 0, "an airborne trainer's snap does not ask the floor validator")
	assert_false(_body.position.is_equal_approx(_leader.position),
		"the companion is not put at the airborne trainer's position")


func test_stopping_following_releases_the_footprint_exception() -> void:
	var trainer := CharacterBody3D.new()
	_root.add_child(trainer)
	_body.add_collision_exception_with(trainer)
	_body.set("_footprint_exception", trainer)
	_body.call("set_following", false)
	assert_eq(_body.get("_footprint_exception"), null, "combat takes the body with no footprint exception left")
	assert_false(_body.get_collision_exceptions().has(trainer),
		"the companion collides with its trainer again")
