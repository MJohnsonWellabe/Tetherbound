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


## This is imported CPU geometry plus initialized physics, not a renderer
## readback or a Stormwood visual verdict. Keep the ordinary Meadows cases.
func _case_stormwood_lower_bark_is_exact_shared_geometry() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_vegetation.json"))
	veg.set("_realm_config", config)
	var layers: Dictionary = config.layers
	for model: String in layers.storm_canopy.models:
		var resolved: Dictionary = veg.call("_layer_for", model)
		assert_eq(resolved, layers.storm_canopy, "shared model resolves to the first Stormwood layer")
		var rule: Dictionary = veg.call("_canopy_for", model, resolved)
		assert_false(rule.has("size"), "Stormwood gets no whole-model canopy box")
		var shape := rule.get("lower_bark") as ConcavePolygonShape3D
		assert_true(shape != null, "actual imported bark has a camera surface")
		if shape == null: continue
		var giant_rule: Dictionary = veg.call("_canopy_for", model, layers.giant_canopy)
		assert_eq(giant_rule.get("lower_bark"), shape, "ordinary/giant placements share the same model-local shape")
		assert_eq((veg.call("_canopy_for", model, resolved) as Dictionary).get("lower_bark"), shape,
			"repeat queries reuse the cached shape")
		assert_true(shape.backface_collision, "camera can meet either side of bark")
		var faces := shape.get_faces()
		assert_true(not faces.is_empty() and faces.size() % 3 == 0, "shape is real triangles")
		var below_boundary := true
		for point: Vector3 in faces: below_boundary = below_boundary and point.y <= 4.00001
		assert_true(below_boundary, "upper branches/leaves are outside the lower-bark surface")
		var mesh: Mesh = veg.call("_mesh_for", model)
		assert_true(faces.size() < mesh.get_faces().size(), "whole model was not copied into this collider")
	assert_eq((veg.get("_camera_lower_bark_shapes") as Dictionary).size(), 2, "only two model-local shapes are cached")


func _case_bark_triangle_clip_keeps_plane_winding_and_no_cap() -> void:
	var faces: PackedVector3Array = veg.call("_clip_camera_bark_triangle",
		Vector3(-1, 3, 0), Vector3(1, 3, 0), Vector3(0, 5, 0), 4.0)
	assert_eq(faces.size(), 6, "crossing triangle clips to a quad with two triangles")
	assert_true(faces.has(Vector3(-.5, 4, 0)) and faces.has(Vector3(.5, 4, 0)), "cut follows the original triangle edges")
	for offset in range(0, faces.size(), 3):
		var a := faces[offset]; var b := faces[offset + 1]; var c := faces[offset + 2]
		assert_true(a.z == 0.0 and b.z == 0.0 and c.z == 0.0, "clipped points stay on the source plane")
		assert_true((b - a).cross(c - a).z > 0.0, "source winding is retained, with no new horizontal cap")
	var empty: PackedVector3Array = veg.call("_clip_camera_bark_triangle",
		Vector3(-1, 5, 0), Vector3(1, 5, 0), Vector3(0, 6, 0), 4.0)
	assert_true(empty.is_empty(), "fully upper triangle contributes no surface")


## Pick a large real lower-bark face outside the walking radius, with its
## outward normal oriented radially. This gives an actual imported witness
## for both directions of the same camera sphere sweep at each giant scale.
func _lower_bark_witness(faces: PackedVector3Array) -> Dictionary:
	var best := {}
	var largest := 0.0
	for offset in range(0, faces.size(), 3):
		var a := faces[offset]; var b := faces[offset + 1]; var c := faces[offset + 2]
		var point := (a + b + c) / 3.0
		var cross := (b - a).cross(c - a)
		var area := cross.length_squared()
		if point.y < .2 or point.y > 1.0 or Vector2(point.x, point.z).length() < .9 or area <= largest: continue
		var normal := cross.normalized()
		if absf(normal.y) > .35: continue
		if normal.dot(Vector3(point.x, 0, point.z)) < 0: normal = -normal
		best = {"point": point, "normal": normal}
		largest = area
	return best


func _case_actual_giant_bark_stops_camera_not_player_and_leaves_gaps() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_vegetation.json"))
	veg.set("_realm_config", config)
	for model: String in config.layers.storm_canopy.models:
		var rule: Dictionary = veg.call("_canopy_for", model, veg.call("_layer_for", model))
		var shape := rule.get("lower_bark") as ConcavePolygonShape3D
		assert_true(shape != null, "actual Stormwood model needs its bark shape")
		if shape == null: continue
		var witness := _lower_bark_witness(shape.get_faces())
		assert_false(witness.is_empty(), "actual bark has a low face outside the walking cylinder")
		if witness.is_empty(): continue
		for scale: float in [6.0, 7.5]:
			for yaw: float in [0.0, 1.17]:
				var body := StaticBody3D.new()
				fixture.add_child(body)
				var placement := {"position": Vector3(40, 0, 0), "scale": scale, "yaw": yaw}
				var trunk: CollisionShape3D = veg.call("_make_collision_shape", placement, .62, rule)
				body.add_child(trunk)
				await (Engine.get_main_loop() as SceneTree).physics_frame
				await (Engine.get_main_loop() as SceneTree).physics_frame
				assert_almost_eq((trunk.shape as CylinderShape3D).radius, .62 * scale, .00001, "walking radius unchanged")
				assert_almost_eq((trunk.shape as CylinderShape3D).height, 4.0 * scale, .00001, "walking height unchanged")
				var camera := trunk.get_node_or_null(^"CameraLowerBark") as StaticBody3D
				assert_true(camera != null, "resident trunk owns its lower-bark camera body")
				if camera == null: body.free(); continue
				assert_eq(camera.collision_layer, CAMERA_RIG.OCCLUSION_ONLY_LAYER)
				assert_eq(camera.collision_mask, 0)
				var bark := camera.get_child(0) as CollisionShape3D
				assert_eq(bark.shape, shape, "instance keeps the shared shape resource")
				var expected := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale),
					placement.position - Vector3.UP * VEGETATION.SINK)
				assert_true(bark.global_transform.is_equal_approx(expected), "physics placement matches actual render yaw/scale/sink")
				var point: Vector3 = bark.global_transform * (witness.point as Vector3)
				var normal: Vector3 = (bark.global_transform.basis * (witness.normal as Vector3)).normalized()
				var start := point + normal * 2.0
				var end := point - normal * .5
				assert_true(_sweep(start, end, 1 | CAMERA_RIG.OCCLUSION_ONLY_LAYER) < 1.0, "real low bark stops the camera sphere")
				assert_almost_eq(_sweep(start, end, 1), 1.0, .001, "player mask sees no new bark collision")
				assert_true(_sweep(point - normal, point + normal, CAMERA_RIG.OCCLUSION_ONLY_LAYER) < 1.0, "backside camera approach also meets actual bark")
				var gap_start := bark.global_transform * Vector3(2, 1, 1)
				var gap_end := bark.global_transform * Vector3(2, 1, 2)
				assert_almost_eq(_sweep(gap_start, gap_end, 1 | CAMERA_RIG.OCCLUSION_ONLY_LAYER), 1.0, .001,
					"empty under-branch space inside whole-model bounds remains open")
				var camera_ref: WeakRef = weakref(camera)
				trunk.free()
				await (Engine.get_main_loop() as SceneTree).physics_frame
				assert_true(camera_ref.get_ref() == null, "camera geometry is freed with its resident trunk")
				assert_almost_eq(_sweep(start, end, CAMERA_RIG.OCCLUSION_ONLY_LAYER), 1.0, .001, "no orphan camera geometry after eviction")
				body.free()


const CASES := ["_case_the_arm_stops_at_the_canopy", "_case_the_player_walks_under_and_through_nothing_new",
	"_case_the_canopy_leaves_with_its_trunk", "_case_real_tree_models_get_a_canopy_and_rocks_do_not",
	"_case_stormwood_lower_bark_is_exact_shared_geometry", "_case_bark_triangle_clip_keeps_plane_winding_and_no_cap",
	"_case_actual_giant_bark_stops_camera_not_player_and_leaves_gaps"]


func test_camera_canopy_in_an_initialized_tree() -> void:
	var runner_path := "user://vegetation-camera-canopy-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_vegetation_camera_canopy.gd").new()\n\tfor method in test.CASES:\n\t\ttest._setup_fixture()\n\t\tawait physics_frame\n\t\tawait physics_frame\n\t\tawait test.call(method)\n\t\ttest._free_fixture()\n\tprint("CANOPY_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
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


## Stormwood lower bark: a camera-only trimesh clipped at the canopy boundary.
func test_lower_bark_triangle_clip_keeps_only_bark_below_the_boundary() -> void:
	var veg := VEGETATION.new()
	var below: PackedVector3Array = veg._clip_camera_bark_triangle(Vector3(0,0,0), Vector3(1,0,0), Vector3(0,1,0), 4.0)
	assert_eq(below.size(), 3, "a triangle wholly below the boundary is kept as is")
	var above: PackedVector3Array = veg._clip_camera_bark_triangle(Vector3(0,5,0), Vector3(1,5,0), Vector3(0,6,0), 4.0)
	assert_eq(above.size(), 0, "canopy above the boundary adds no camera face")
	var split: PackedVector3Array = veg._clip_camera_bark_triangle(Vector3(0,0,0), Vector3(2,0,0), Vector3(0,8,0), 4.0)
	assert_true(split.size() > 0 and split.size() % 3 == 0, "a crossing triangle is fanned, not capped")
	for point: Vector3 in split:
		assert_true(point.y <= 4.0 + 0.00001, "no clipped point rises above the boundary")
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/vegetation_camera_canopy.json"))
	assert_true(cfg.lower_bark.layers.has("storm_canopy") and cfg.lower_bark.layers.has("giant_canopy"))
	veg.free()
