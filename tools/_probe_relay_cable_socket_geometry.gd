extends SceneTree

## Focused initialized geometry proof for the relay cable mounts. This runs as
## its own deferred SceneTree script because tests/run_tests.gd executes test
## methods synchronously inside `_init`, before an initialized scene hierarchy
## exists for reliable global-transform evidence.

const RELAY := preload("res://scripts/world/tether_relay.gd")
const CONFIG_PATH := "res://data/config/tether_relay.json"
const EPSILON := 0.001

var _failures: Array[String] = []
var _assertions := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var json := JSON.new()
	_check(json.parse(FileAccess.get_file_as_string(CONFIG_PATH)) == OK,
		"relay config parses")
	if not _failures.is_empty():
		_finish()
		return
	var config := json.data as Dictionary
	var apparatus := config.get("apparatus", {}) as Dictionary
	var links := config.get("cable_links", {}) as Dictionary
	var conduits := config.get("conduits", {}) as Dictionary
	var centre_values := apparatus.get("at", []) as Array
	var centre := Vector2(float(centre_values[0]), float(centre_values[1]))
	var deck_y := float(apparatus.get("deck_y", 0.0))
	var tall := float(apparatus.get("height", 0.0))
	var massing := apparatus.get("massing", {}) as Dictionary
	var grounding := massing.get("grounding_base", {}) as Dictionary
	var radius := float(grounding.get("radius", 0.0))
	var support_width := float(links.get("socket_support_width", 0.0))
	var support_depth := float(links.get("socket_support_depth", 0.0))
	var overlap := float(links.get("socket_support_overlap", 0.0))

	var initialized_parent := Node3D.new()
	initialized_parent.name = "InitializedRelayFixture"
	initialized_parent.position = Vector3(31.0, 7.0, -19.0)
	initialized_parent.rotation.y = deg_to_rad(23.0)
	root.add_child(initialized_parent)
	var holder := Node3D.new()
	holder.name = "CableLinks"
	initialized_parent.add_child(holder)
	await process_frame

	var stone := StandardMaterial3D.new()
	var wanted_runs := links.get("runs", []) as Array
	var built := 0
	for entry: Variant in conduits.get("runs", []) as Array:
		if not entry is Dictionary:
			continue
		var run := entry as Dictionary
		var run_id := str(run.get("id", ""))
		if not wanted_runs.has(run_id):
			continue
		var pylons := run.get("list", []) as Array
		if pylons.is_empty() or not pylons[-1] is Dictionary:
			continue
		var at_values := (pylons[-1] as Dictionary).get("at", []) as Array
		var pylon := Vector2(float(at_values[0]), float(at_values[1]))
		var direction := (pylon - centre).normalized()
		var landing := Vector3(centre.x + direction.x * radius,
			deck_y + tall * 0.5, centre.y + direction.y * radius)
		var mount := RELAY.build_cable_socket_mount(holder, run_id, landing,
			direction, deck_y, support_width, support_depth, overlap, stone)
		var support := mount.get("support") as MeshInstance3D
		var bracket := mount.get("bracket") as MeshInstance3D
		_check(support != null and bracket != null, "%s actual mount nodes exist" % run_id)
		if support == null or bracket == null:
			continue
		built += 1
		var support_bounds: AABB = support.global_transform * support.get_aabb()
		var bracket_bounds: AABB = bracket.global_transform * bracket.get_aabb()
		var global_deck_y := initialized_parent.to_global(Vector3(0.0, deck_y, 0.0)).y
		_check(absf(support_bounds.position.y - global_deck_y) <= EPSILON,
			"%s support bottom contacts global deck plane" % run_id)
		_check(absf((support_bounds.end.y - bracket_bounds.position.y) - overlap) <= EPSILON,
			"%s support has configured overlap into actual bracket underside" % run_id)
		_check(_xz_overlap(support_bounds, bracket_bounds),
			"%s support overlaps actual bracket in global XZ" % run_id)
		_check(absf(support.position.x - bracket.position.x) <= EPSILON
			and absf(support.position.z - bracket.position.z) <= EPSILON,
			"%s support is centered under bracket" % run_id)
		_check(absf(support.position.x - centre.x) + support_width * 0.5 <= 5.0
			and absf(support.position.z - centre.y) + support_depth * 0.5 <= 5.0,
			"%s support footprint stays inside unchanged 10x10 deck" % run_id)
		_check(support.find_children("*", "CollisionObject3D", true, false).is_empty(),
			"%s support adds no collision" % run_id)
	_check(built == wanted_runs.size(), "all three configured socket supports instantiate")
	initialized_parent.queue_free()
	await process_frame
	_finish()


func _xz_overlap(a: AABB, b: AABB) -> bool:
	return a.position.x <= b.end.x + EPSILON and a.end.x >= b.position.x - EPSILON \
		and a.position.z <= b.end.z + EPSILON and a.end.z >= b.position.z - EPSILON


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	for failure: String in _failures:
		print("FAIL: %s" % failure)
	print("relay cable socket geometry: %d assertions, %d failed" % [
		_assertions, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)
