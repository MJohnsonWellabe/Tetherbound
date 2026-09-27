extends SceneTree

## Run independently after import:
## godot --path . --rendering-method gl_compatibility --script tests/smoke_stat_draught_presentation.gd
## Live-tree assertions cannot run inside run_tests.gd's SceneTree._init.
## A real graphics backend is required for MultiMesh transform readback;
## headless's dummy RenderingServer returns defaults for those transforms.
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const GLOW := preload("res://scripts/world/pickup_glow.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const TEST_CASE := preload("res://tests/test_case.gd")
const ITEMS := ["elixir_might", "elixir_guard", "elixir_vigour",
	"swift_tonic", "attack_tonic", "stoneguard_brew"]

var checks := TEST_CASE.new()
var _completed_cases := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Stat draught presentation requires a graphics backend for MultiMesh readback; run with Compatibility (under xvfb on CI).")
		quit(2)
		return
	# If a runtime error aborts this function, the watchdog still exits nonzero.
	create_timer(15.0).timeout.connect(_timed_out)
	checks.assert_eq(Engine.get_main_loop(), self, "deferred smoke owns the live tree")
	for item: String in ITEMS:
		_check_visual_offset(item)
	_check_direct_teardown()
	checks.assert_eq(_completed_cases, ITEMS.size() + 1, "every case reached its final assertion")
	checks.assert_true(checks.assertion_count >= 150, "no empty or partly aborted smoke may pass")
	for failure: String in checks.failures:
		printerr("FAIL stat draught presentation: " + failure)
	print("Stat draught presentation: %d completed cases, %d assertions, %d failures" % [
		_completed_cases, checks.assertion_count, checks.failures.size()])
	quit(0 if checks.failures.is_empty() else 1)


func _timed_out() -> void:
	printerr("FAIL stat draught presentation: smoke did not finish (possible script error)")
	quit(1)


func _offset_fixture(item: String) -> Dictionary:
	var tree: SceneTree = self
	var previous := tree.current_scene
	var world := Node3D.new()
	tree.root.add_child(world)
	tree.current_scene = world
	var field := GLOW.new()
	field.name = GLOW.FIELD_NAME
	world.add_child(field)
	var pickup := ITEM_CACHE_PICKUP.new()
	world.add_child(pickup)
	pickup.position = Vector3(10.0, 0.35, 20.0)
	var model_path := "res://assets/props/stat_draughts/%s.tscn" % item
	checks.assert_true(ResourceLoader.exists(model_path), "production model exists: " + item)
	pickup.setup(item, "Take it", model_path, 0.8, "smoke_draught_presentation", "stormwood", 3)
	var visual := pickup.get("_visual") as Node3D
	return {"tree": tree, "previous": previous, "world": world,
		"pickup": pickup, "visual": visual, "field": field}


func _free_offset_fixture(fixture: Dictionary) -> void:
	(fixture.world as Node).free()
	(fixture.tree as SceneTree).current_scene = fixture.previous


func _check_visual_offset(item: String) -> void:
	var fixture := _offset_fixture(item)
	var pickup: Node3D = fixture.pickup
	var visual: Node3D = fixture.visual
	var field: Node3D = fixture.field
	var prompt := pickup.get_node("Interactable") as Node3D
	var root_transform := pickup.global_transform
	var prompt_transform := prompt.global_transform
	var key := str(pickup.call("_key"))
	checks.assert_eq(field.call("highlight_count"), 1)
	pickup.call("set_visual_offset", Vector3(0.0, -0.35, 0.0))
	var anchor := visual.get_parent() as Node3D
	checks.assert_eq(pickup.get("_visual"), visual, "bounds callers retain the same visual")
	checks.assert_eq(anchor.scale, Vector3.ONE, "glow measures the model's scale exactly once")
	checks.assert_eq(visual.scale, Vector3.ONE * 0.8)
	checks.assert_eq(pickup.global_transform, root_transform)
	checks.assert_eq(prompt.global_transform, prompt_transform)
	checks.assert_eq(float(prompt.get("radius")), 2.4)
	checks.assert_eq(str(pickup.call("_key")), key)
	checks.assert_eq(int(pickup.get("_count")), 3)
	var bounds := BOUNDS.measure(anchor)
	checks.assert_true(absf(bounds.size.y - 0.64) < 0.00001)
	checks.assert_true(absf((anchor.global_transform * bounds.position).y) < 0.00001,
		"rendered bottle base must reach ground while claim root stays at 0.35m")
	# Reward beams stay siblings of presentation, never part of item bounds.
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(1.0, 34.0, 1.0)
	beam.mesh = beam_mesh
	beam.position.y = 17.0
	pickup.add_child(beam)
	var glow_height := GLOW.prop_glow_height(anchor, 0.28)
	checks.assert_true(absf(glow_height - 0.352) < 0.00001,
		"glow belongs to scaled bottle, not elevated root or 34m reward beam")
	var positions: Array = field.call("highlight_positions")
	checks.assert_eq(positions.size(), 1)
	if positions.size() == 1:
		checks.assert_true((positions[0] as Vector3).is_equal_approx(Vector3(10.0, 0.0, 20.0)))
	field.call("_rebuild")
	var motes := field.get("_motes") as MultiMeshInstance3D
	checks.assert_true(motes != null, "real glow rendering layer initialized")
	if motes != null:
		checks.assert_eq(motes.multimesh.instance_count, 1)
		if motes.multimesh.instance_count == 1:
			checks.assert_true(motes.multimesh.get_instance_transform(0).origin.is_equal_approx(
				Vector3(10.0, 0.352, 20.0)), "actual halo transform follows grounded item")
	# Repeated corrections must reuse the anchor/registration, not accumulate.
	pickup.call("set_visual_offset", Vector3(0.0, -0.25, 0.0))
	checks.assert_eq(visual.get_parent(), anchor)
	checks.assert_eq(field.call("highlight_count"), 1)
	positions = field.call("highlight_positions")
	checks.assert_eq(positions.size(), 1)
	if positions.size() == 1:
		checks.assert_true(absf((positions[0] as Vector3).y - 0.1) < 0.00001)
	checks.assert_eq(pickup.global_transform, root_transform)
	pickup.call("_deactivate")
	checks.assert_eq(field.call("highlight_count"), 0, "claim removal immediately unregisters anchored glow")
	checks.assert_false(bool(prompt.get("enabled")))
	_free_offset_fixture(fixture)
	_completed_cases += 1


func _check_direct_teardown() -> void:
	var fixture := _offset_fixture("elixir_might")
	var pickup: Node3D = fixture.pickup
	var field: Node3D = fixture.field
	pickup.call("set_visual_offset", Vector3(0.0, -0.35, 0.0))
	checks.assert_eq(field.call("highlight_count"), 1)
	pickup.free()
	checks.assert_eq(field.call("highlight_count"), 0, "residency removal must not leave a registered emitter")
	_free_offset_fixture(fixture)
	_completed_cases += 1
