extends "res://tests/test_case.gd"
## F04: a tree's only collider was its trunk cylinder, so the fight camera's
## arm swept straight through canopies (Captain Oreth's grove). Each resident
## trunk of a canopy layer now carries a CameraCanopy box on the camera rig's
## occlusion-only layer. This sweeps the arm's own probe (a 0.25 m sphere on
## the arm's mask) through a canopy and checks that the player's mask still
## passes it, in a live physics world (isolated child process, as
## test_combat_flee_buffer.gd does).

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const CAMERA_RIG := preload("res://scripts/player/camera_rig.gd")

var fixture: Node3D
var veg: Node3D


func _setup_fixture() -> void:
	fixture = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(fixture)
	veg = VEGETATION.new()
	var body := StaticBody3D.new()
	fixture.add_child(body)
	var canopy := {"size": Vector3(4.0, 4.0, 4.0), "centre": Vector3(0.0, 6.0, 0.0)}
	var trunk: CollisionShape3D = veg.call("_make_collision_shape",
		{"position": Vector3.ZERO, "scale": 1.0}, 0.435, canopy)
	body.add_child(trunk)


func _free_fixture() -> void:
	fixture.free()
	veg.free()


func _sweep(from: Vector3, to: Vector3, mask: int) -> float:
	var space := fixture.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.25
	q.shape = ball
	q.transform = Transform3D(Basis(), from)
	q.motion = to - from
	q.collision_mask = mask
	return space.cast_motion(q)[0]


func _case_the_arm_stops_at_the_canopy() -> void:
	var arm_mask := 1 | CAMERA_RIG.OCCLUSION_ONLY_LAYER
	var safe := _sweep(Vector3(-8.0, 6.0, 0.0), Vector3(8.0, 6.0, 0.0), arm_mask)
	assert_true(safe < 0.5, "the arm's probe stops at the canopy (safe fraction %.2f)" % safe)
	assert_almost_eq(16.0 * safe, 8.0 - 2.0 - 0.25, 0.1, "it stops at the canopy's face")


func _case_the_player_walks_under_and_through_nothing_new() -> void:
	var at_canopy := _sweep(Vector3(-8.0, 6.0, 0.0), Vector3(8.0, 6.0, 0.0), 1)
	assert_almost_eq(at_canopy, 1.0, 0.001, "the player's mask (layer 1) does not meet the canopy")
	var at_trunk := _sweep(Vector3(-8.0, 1.0, 0.0), Vector3(8.0, 1.0, 0.0), 1)
	assert_true(at_trunk < 1.0, "the trunk still blocks the player")


func _case_the_canopy_leaves_with_its_trunk() -> void:
	var trunk := (fixture.get_child(0) as StaticBody3D).get_child(0) as CollisionShape3D
	var canopy := trunk.get_node_or_null(^"CameraCanopy") as StaticBody3D
	assert_true(canopy != null, "the trunk shape owns its CameraCanopy body")
	if canopy != null:
		assert_eq(canopy.collision_layer, CAMERA_RIG.OCCLUSION_ONLY_LAYER)
		assert_eq(canopy.collision_mask, 0)


func _case_real_tree_models_get_a_canopy_and_rocks_do_not() -> void:
	var layers: Dictionary = veg.call("_vegetation_config").get("layers", {})
	var tree_model := str(((layers.get("trees", {}) as Dictionary).get("models", []) as Array)[0])
	var rock_model := str(((layers.get("rocks", {}) as Dictionary).get("models", []) as Array)[0])
	var tree: Dictionary = veg.call("_canopy_for", tree_model, layers["trees"])
	assert_false(tree.is_empty(), "%s gets a canopy box" % tree_model.get_file())
	if not tree.is_empty():
		assert_true((tree["size"] as Vector3).y > 0.5, "the box has real height")
		assert_true((tree["centre"] as Vector3).y > 4.0, "the box sits above the 4-unit trunk collider")
	assert_true((veg.call("_canopy_for", rock_model, layers["rocks"]) as Dictionary).is_empty(),
		"rocks get no canopy")


const CASES := ["_case_the_arm_stops_at_the_canopy", "_case_the_player_walks_under_and_through_nothing_new",
	"_case_the_canopy_leaves_with_its_trunk", "_case_real_tree_models_get_a_canopy_and_rocks_do_not"]


func test_camera_canopy_in_an_initialized_tree() -> void:
	var runner_path := "user://vegetation-camera-canopy-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_vegetation_camera_canopy.gd").new()\n\tfor method in test.CASES:\n\t\ttest._setup_fixture()\n\t\tawait physics_frame\n\t\tawait physics_frame\n\t\ttest.call(method)\n\t\ttest._free_fixture()\n\tprint("CANOPY_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://vegetation-camera-canopy-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file", log_path], output, true)
	var text := "\n".join(output)
	var marker := text.find("CANOPY_RESULT=")
	assert_true(marker >= 0, "the child run reported a result: %s" % text.right(600))
	if marker < 0:
		return
	var parsed: Variant = JSON.parse_string(text.substr(marker + "CANOPY_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [], "every canopy case passes")
	assert_true(int(result.get("assertions", 0)) >= 9, "the cases asserted (%s)" % str(result.get("assertions")))
	assert_eq(code, 0, "the child exited cleanly")
