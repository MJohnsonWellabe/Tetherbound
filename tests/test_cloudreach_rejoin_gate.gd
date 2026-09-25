extends "res://tests/test_case.gd"

## F06 rejoin gate: a trainer whose portable pose lies inside a region that a
## CLOSED ground gate protects in the current (host) world must be re-seated on
## that gate's legal side; an open gate leaves the loaded pose alone. Pure
## logic (this runner has no SceneTree): the world's own static
## `sealed_region_relocation()` -- the decision `enforce_sealed_placement()`
## acts on after every load/join/rejoin placement -- against a real
## ProgressionState and the shipped `data/config/cloudreach_world.json`. The
## live body move and Fly-anchor clear are proven by the two-peer F06 proof
## (ralph/reports/CLOUDREACH-LANE/f06-mounted-rejoin/PROOF.md, #27/#29/#40/#41).

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const MAP_STATE := preload("res://scripts/world/cloudreach_map_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const CONFIG_PATH := "res://data/config/cloudreach_world.json"
const UPPER_FLAG := "cloudreach_upper_route_unlocked"
const SEALED_POSE := Vector3(-400.0, 780.03, 3890.0)
const SUMMIT_POSE := Vector3(100.0, 1160.0, 5350.0)
const LEGAL_SIDE := Vector3(-104.0, 473.0, 2436.0)
const HIGH_ROOST_POSE := Vector3(1110.0, 1020.0, 2920.0)

var _config: Dictionary


func before_each() -> void:
	super.before_each()
	_config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


## The seat the world would choose for `at`, or {} when it keeps the pose.
func _relocation(at: Vector3, progression: RefCounted) -> Dictionary:
	var probe: Node = WORLD.new()
	if not probe.has_method("sealed_region_relocation"):
		probe.free()
		_fail("cloudreach_world.gd never re-validates a placed pose against a closed gate (no sealed_region_relocation)")
		return {"missing": true}
	var verdict: Dictionary = probe.call("sealed_region_relocation", _config, at, progression)
	probe.free()
	return verdict


func _xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func test_closed_gate_seats_a_sealed_pose_on_the_legal_side() -> void:
	var host_world: RefCounted = PROGRESSION.new()
	host_world.call("set_flag", "realm_key_cloudreach")
	host_world.call("set_flag", "fly_traversal_unlocked")
	var verdict := _relocation(SEALED_POSE, host_world)
	if verdict.has("missing"):
		return
	assert_false(verdict.is_empty(), "a pose in sealed Upper Cloudreach is kept under a closed gate")
	var seat: Vector3 = verdict.get("position", SEALED_POSE)
	assert_true(_xz(seat).distance_to(_xz(LEGAL_SIDE)) <= 20.0,
		"seat is not at the counterweight gate's legal side: %s" % seat)
	assert_eq(MAP_STATE.region_at(_config, seat), "windscar_ravine", "seated region")
	assert_eq(str(verdict.get("gate_id", "")), "upper_counterweight_gate")
	assert_eq(str(verdict.get("region_id", "")), "upper_cloudreach")
	assert_false(host_world.call("has", UPPER_FLAG), "judging a pose never writes the gate flag")


func test_closed_gate_also_seals_the_summit() -> void:
	var verdict := _relocation(SUMMIT_POSE, PROGRESSION.new())
	if verdict.has("missing"):
		return
	var seat: Vector3 = verdict.get("position", SUMMIT_POSE)
	assert_true(_xz(seat).distance_to(_xz(LEGAL_SIDE)) <= 20.0,
		"a summit pose under a closed gate is re-seated at the legal side: %s" % seat)


func test_open_gate_keeps_the_loaded_pose() -> void:
	var own_world: RefCounted = PROGRESSION.new()
	own_world.call("set_flag", UPPER_FLAG)
	var verdict := _relocation(SEALED_POSE, own_world)
	if verdict.has("missing"):
		return
	assert_true(verdict.is_empty(), "open gate relocates: %s" % str(verdict))


func test_legal_side_pose_is_kept_under_a_closed_gate() -> void:
	var verdict := _relocation(LEGAL_SIDE, PROGRESSION.new())
	if verdict.has("missing"):
		return
	assert_true(verdict.is_empty(), "legal-side pose relocated: %s" % str(verdict))


func test_fly_gate_region_is_left_to_fly_restrictions() -> void:
	var verdict := _relocation(HIGH_ROOST_POSE, PROGRESSION.new())
	if verdict.has("missing"):
		return
	assert_true(verdict.is_empty(), "the ground-gate rule touched the Fly-only High Roost: %s" % str(verdict))


func test_authored_approach_is_outside_every_region_its_gate_protects() -> void:
	for raw: Variant in _config.get("gates", []):
		var gate := raw as Dictionary
		if str(gate.get("required_traversal", "ground")) != "ground":
			continue
		var p: Array = gate.get("approach_position", [])
		assert_eq(p.size(), 3, "%s authors an approach_position" % gate.get("id"))
		if p.size() != 3:
			continue
		var region := MAP_STATE.region_at(_config, Vector3(float(p[0]), float(p[1]), float(p[2])))
		assert_false(region.is_empty(), "%s approach lies in no region" % gate.get("id"))
		assert_false((gate.get("protects_region_ids", []) as Array).has(region),
			"%s approach lies inside a region it protects (%s)" % [gate.get("id"), region])
