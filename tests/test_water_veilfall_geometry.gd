extends "res://tests/test_case.gd"
## Generated collision geometry and authority guards only; this is not a rendered
## cave acceptance or a CharacterBody traversal/transport integration test.
const VEILFALL := preload("res://scripts/world/water_veilfall.gd")

class Flags extends RefCounted:
	var revision := 0
	var values: Dictionary = {}
	func has(id: String) -> bool:
		return values.has(id)
	func set_flag(id: String) -> void:
		values[id] = true
		revision += 1

class Ledger extends Node:
	var flags: Flags
	var submitted: Array = []
	func submit(intent: Dictionary) -> Dictionary:
		submitted.append(intent.duplicate(true))
		flags.set_flag(str(intent.id))
		return {"ok": true}

class GameFixture extends Node:
	var world: Dictionary
	var ledger: Ledger
	var authority := true
	func is_host() -> bool:
		return authority

class WorldFixture extends Node3D:
	var simulation_only := true
	func ground_height_at(_x: float, _z: float) -> float:
		return 12.0

func _case_generated_geometry_and_controls() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var original := tree.root.get_node_or_null("Game")
	if original != null: original.name = "OriginalGameForVeilfallTest"
	var game := GameFixture.new()
	game.name = "Game"
	var flags := Flags.new()
	game.world = {"flags": flags}
	game.ledger = Ledger.new()
	game.ledger.flags = flags
	game.add_child(game.ledger)
	var transport := Node.new()
	transport.name = "WaterVeilfallTransport"
	game.ledger.add_child(transport)
	tree.root.add_child(game)
	var world := WorldFixture.new()
	tree.root.add_child(world)
	var cave := VEILFALL.new()
	world.add_child(cave)
	cave.build(world)
	assert_true(cave.ready_for_intents)
	assert_eq(cave.entrance.y, 12.0)
	assert_eq(cave._gates.size(), 2)
	assert_eq(cave._controls.size(), 3)
	var boxes: Array[AABB] = []
	for body in cave.interior.get_children():
		if not body is StaticBody3D or body in cave._gates.values(): continue
		for child in body.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D:
				var size: Vector3 = child.shape.size
				boxes.append(AABB(child.global_position - cave.interior.global_position - size * 0.5, size))
	# Centreline must have a continuous supported floor and player-height clearance
	# through every room joint, apart from the separately tested mechanical gates.
	for z in range(2, 123):
		assert_true(_solid(boxes, Vector3(0, -0.1, z)), "Missing centre floor at z=%s" % z)
		assert_false(_solid(boxes, Vector3(0, 0.9, z)), "Blocked centre passage at z=%s" % z)
	# Both channels have actual trough collision below their decorative water;
	# four authored steps rise continuously back to the gallery floor.
	for side in [-1, 1]:
		for z in range(64, 79):
			assert_true(_solid(boxes, Vector3(side * 8, -1.1, z)))
			assert_false(_solid(boxes, Vector3(side * 8, -0.1, z)))
		for step in range(4):
			assert_true(_solid(boxes, Vector3(side * 5, -0.8 + step * 0.25, 59 + step)))
		for pair in [[9, 15], [15, 45], [15, 70], [21, 102], [12, 30], [18, 80]]:
			assert_true(_solid(boxes, Vector3(side * pair[0], 1, pair[1])), "Cave side/shoulder must be enclosed")
	assert_true(_solid(boxes, Vector3(0, 1, 0)))
	assert_true(_solid(boxes, Vector3(0, 1, 124)))
	for flag in cave._gates:
		var gate: StaticBody3D = cave._gates[flag]
		assert_eq(gate.collision_layer, 1)
		assert_true(gate.visible)
		assert_true(gate.get_child(0) is CollisionShape3D)
		assert_true(gate.get_child(0).shape is BoxShape3D)
	var intake: Vector3 = cave._controls.intake_pump.global_position
	var sluice: Vector3 = cave._controls.sluice_wheel.global_position
	var release: Vector3 = cave._controls.guardian_tether.global_position
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "unknown"}, 2, {"realm": "water", "position": intake}).ok)
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "intake_pump"}, 2, {"realm": "meadows", "position": intake}).ok)
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "intake_pump"}, 2, {"realm": "water", "position": intake + Vector3.RIGHT * 5}).ok)
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "sluice_wheel"}, 2, {"realm": "water", "position": sluice}).ok)
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "guardian_tether"}, 2, {"realm": "water", "position": release}).ok)
	game.authority = false
	assert_false(cave.host_commit({"kind": "veilfall_control", "control_id": "intake_pump"}, 2, {"realm": "water", "position": intake}).ok)
	game.authority = true
	assert_eq(game.ledger.submitted.size(), 0, "Refused controls must not mutate the ledger")
	assert_true(cave.host_commit({"kind": "veilfall_control", "control_id": "intake_pump"}, 2, {"realm": "water", "position": intake}).ok)
	cave._refresh()
	assert_eq(cave._gates.water_veilfall_intake_stopped.collision_layer, 0)
	assert_false(cave._gates.water_veilfall_intake_stopped.visible)
	assert_eq(cave._gates.water_veilfall_return_opened.collision_layer, 1)
	assert_true(cave.host_commit({"kind": "veilfall_control", "control_id": "sluice_wheel"}, 2, {"realm": "water", "position": sluice}).ok)
	cave._refresh()
	assert_eq(cave._gates.water_veilfall_return_opened.collision_layer, 0)
	assert_false(cave._gates.water_veilfall_return_opened.visible)
	flags.set_flag("water_captain_nerissa_defeated")
	assert_true(cave.host_commit({"kind": "veilfall_control", "control_id": "guardian_tether"}, 2, {"realm": "water", "position": release}).ok)
	assert_true(flags.has("water_guardian_freed"))
	assert_eq(game.ledger.submitted.size(), 3)
	world.free()
	game.free()
	if original != null: original.name = "Game"

func _solid(boxes: Array[AABB], point: Vector3) -> bool:
	for box in boxes:
		if box.has_point(point): return true
	return false

func test_generated_cave_geometry_and_authority_in_initialized_tree() -> void:
	var path := "user://veilfall-geometry-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_water_veilfall_geometry.gd").new()\n\ttest._case_generated_geometry_and_controls()\n\tprint("VEILFALL_GEOMETRY_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count > 300 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", ProjectSettings.globalize_path("user://veilfall-geometry-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("VEILFALL_GEOMETRY_RESULT="):
			result = JSON.parse_string(line.trim_prefix("VEILFALL_GEOMETRY_RESULT="))
	assert_true(int(result.get("assertions", 0)) > 300, "Generated geometry and all guarded control paths must run")
	assert_eq(result.get("failures", ["missing result"]), [])
