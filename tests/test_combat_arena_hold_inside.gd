extends "res://tests/test_case.gd"

## `combat_arena.gd::hold_inside()` returns a fighter to the ring by a SWEEP,
## never a raw position write.
##
## Tidewake evidence: FLOOR LOST ally=(564.08,0.64,1308.79) vel=(0,-27.2,0)
## ground=1.28, arena centre (568.74,14.11,1318.75) radius 11. The ally stood
## below the ring on a steep bank rising toward the centre; the old write put
## it at the radius at its own height -- inside the bank -- and it fell through
## the terrain forever. `move_and_collide` stops it at the bank's surface.
##
## Needs a physics world, which the unit runner (SceneTree._init) does not
## have, so the cases run in an isolated child process
## (test_combat_realm_owned_begin.gd's convention).

const ARENA_SCRIPT := preload("res://scripts/combat/combat_arena.gd")
const RADIUS := 11.0
const SLOPE_DEGREES := 57.0
## Where the bank meets the ground plane (y = 0): 1m outside the ring.
const SLOPE_FOOT_X := 12.0
const CAPSULE_RADIUS := 0.4
const CAPSULE_HEIGHT := 1.8
const EXPECTED_ASSERTIONS := 7

var _root: Node3D = null


func _setup_fixture() -> void:
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)


func _free_fixture() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func _arena() -> Node3D:
	var arena := Node3D.new()
	arena.set_script(ARENA_SCRIPT)
	_root.add_child(arena)
	arena.global_position = Vector3.ZERO
	arena.set("radius", RADIUS)
	return arena


func _static_box(size: Vector3, xform: Transform3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_root.add_child(body)
	body.global_transform = xform
	return body


func _fighter(at: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	shape.shape = capsule
	body.add_child(shape)
	_root.add_child(body)
	body.global_position = at
	return body


## Anything solid overlapping the fighter's capsule (shrunk by 2cm so a resting
## contact at the sweep's safe margin is not counted as embedding).
func _overlaps(body: CharacterBody3D) -> Array:
	var query := PhysicsShapeQueryParameters3D.new()
	var probe := CapsuleShape3D.new()
	probe.radius = CAPSULE_RADIUS - 0.02
	probe.height = CAPSULE_HEIGHT - 0.04
	query.shape = probe
	query.transform = body.global_transform
	query.exclude = [body.get_rid()]
	return body.get_world_3d().direct_space_state.intersect_shape(query)


func _flat_distance(body: Node3D) -> float:
	return Vector2(body.global_position.x, body.global_position.z).length()


func _case_steep_bank_outside_the_ring_is_not_entered() -> void:
	var arena := _arena()
	# A 57-degree bank rising toward the centre, surface y = (12 - x) tan 57.
	var theta := deg_to_rad(SLOPE_DEGREES)
	var normal := Vector3(sin(theta), cos(theta), 0.0)
	var basis := Basis(Vector3.BACK, -theta)
	var on_surface := Vector3(SLOPE_FOOT_X, 0.0, 0.0)
	_static_box(Vector3(40.0, 2.0, 20.0), Transform3D(basis, on_surface - normal * 1.0))
	# The fighter stands 1m outside the bank's foot, clear of it.
	var body := _fighter(Vector3(RADIUS + 2.0, CAPSULE_HEIGHT * 0.5 + 0.05, 0.0))
	body.velocity = Vector3(4.0, 0.0, 0.0)
	await (Engine.get_main_loop() as SceneTree).physics_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame
	assert_eq(_overlaps(body).size(), 0, "fixture: the fighter starts clear of the bank")
	var pushed: Vector3 = arena.call("hold_inside", body)
	var hits := _overlaps(body)
	assert_eq(hits.size(), 0,
		"hold_inside must not embed the fighter in the bank (at %s, %d overlaps)" % [body.global_position, hits.size()])
	var clearance := normal.dot(body.global_position - on_surface)
	assert_true(clearance >= CAPSULE_RADIUS - 0.02,
		"the fighter stays on the open side of the bank's surface (centre %.2fm off it, at %s)" % [clearance, body.global_position])
	assert_eq(pushed, Vector3(-1.0, 0.0, 0.0), "the outward velocity is still reported and removed")


func _case_flat_ground_still_returns_the_fighter_to_the_radius() -> void:
	var arena := _arena()
	_static_box(Vector3(60.0, 1.0, 60.0), Transform3D(Basis.IDENTITY, Vector3(0.0, -0.5, 0.0)))
	var body := _fighter(Vector3(RADIUS + 3.0, CAPSULE_HEIGHT * 0.5 + 0.05, 0.0))
	body.velocity = Vector3(5.0, 0.0, 2.0)
	await (Engine.get_main_loop() as SceneTree).physics_frame
	await (Engine.get_main_loop() as SceneTree).physics_frame
	arena.call("hold_inside", body)
	assert_almost_eq(_flat_distance(body), RADIUS, 0.01, "flat ground: the fighter is back on the ring")
	assert_almost_eq(body.velocity.x, 0.0, 0.0001, "the outward velocity component is killed")
	assert_almost_eq(body.velocity.z, 2.0, 0.0001, "movement along the wall survives")


func test_hold_inside_sweeps_in_an_initialized_tree() -> void:
	var runner_path := "user://arena-hold-inside-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_arena_hold_inside.gd").new()\n\tfor method in ["_case_steep_bank_outside_the_ring_is_not_entered", "_case_flat_ground_still_returns_the_fighter_to_the_radius"]:\n\t\ttest._setup_fixture()\n\t\tawait test.call(method)\n\t\ttest._free_fixture()\n\tprint("ARENA_HOLD_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://arena-hold-inside-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("ARENA_HOLD_RESULT="):
			result = JSON.parse_string(line.trim_prefix("ARENA_HOLD_RESULT="))
	assert_eq(int(result.get("assertions", 0)), EXPECTED_ASSERTIONS, "the child must run both cases")
	assert_eq(result.get("failures", ["missing result"]), [])
