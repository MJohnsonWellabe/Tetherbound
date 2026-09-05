extends SceneTree

## Real viewport/ImmediateMesh lifecycle, not a screenshot acceptance fixture.
const FLOURISH := preload("res://scripts/vfx/level_up_flourish.gd")
const GLOW := preload("res://scripts/vfx/body_glow.gd")
var failures := 0
var checks := 0

func _init() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: ", label)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var body := Node3D.new()
	world.add_child(body)
	var mesh := MeshInstance3D.new()
	mesh.name = "Body"
	mesh.mesh = BoxMesh.new()
	body.add_child(mesh)
	var glow: Node = GLOW.attach(body, GLOW.Mode.FLASH, {"duration": 0.1}, 0.85)
	check(glow != null and mesh.material_overlay != null, "real glow attaches")
	mesh.free()
	glow.call("suspend", true)
	glow.call("suspend", false)
	glow.call("advance", 0.2)
	check(glow.call("finished") and glow.is_queued_for_deletion(), "freed model does not break finish")
	var flourish: Node3D = FLOURISH.attach(body, {"duration": 1.5}, 2.0, 0.7)
	flourish.set_physics_process(false)
	flourish.call("advance", 0.0)
	var beam: ImmediateMesh = flourish.get("_mesh")
	var solid: ImmediateMesh = flourish.get("_solid_mesh")
	check(beam.get_surface_count() == 0, "zero envelope has no empty beam surface")
	check(solid.get_surface_count() == 0, "zero envelope has no empty solid surface")
	flourish.call("advance", 0.000001)
	check(beam.get_surface_count() == 0, "tiny alpha skips beam without invalid surface_end")
	flourish.call("advance", 0.6)
	check(beam.get_surface_count() == 1, "visible beam still draws")
	check(solid.get_surface_count() == 1, "visible rings/motes still draw")
	flourish.call("advance", 2.0)
	check(beam.get_surface_count() == 0 and solid.get_surface_count() == 0, "expiry clears both layers")
	check(flourish.is_queued_for_deletion(), "expiry releases flourish")
	world.queue_free()
	await process_frame
	print("VFX lifecycle: %d/%d passed" % [checks - failures, checks])
	quit(1 if failures else 0)
