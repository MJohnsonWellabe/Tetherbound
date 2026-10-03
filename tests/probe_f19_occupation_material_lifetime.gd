extends SceneTree

## Actual Stronghold glow factory plus occupation withdrawal's unlight method.
## Direct construction/camera are component fixtures; no world or victory
## state is supplied. IDs/property snapshots do not retain Resources.
const STRONGHOLD := preload("res://scripts/world/stronghold.gd")
const OCCUPATION := preload("res://scripts/world/stronghold_occupation.gd")
var _held: Array[Material] = []
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "gl_compatibility":
		quit(2)
		return
	RenderingServer.render_loop_enabled = false
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 3, 8)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var factory := STRONGHOLD.new()
	var occupation := OCCUPATION.new()
	for treatment: String in ["baseline", "retain-masked-surface"]:
		print("F19 OCCUPATION MATERIAL BEGIN " + treatment)
		var glow: MeshInstance3D = factory.call("_glow_card", STRONGHOLD.WALL_TORCH_GLOW_M, STRONGHOLD.FIRE_COLOUR, 0.45)
		world.add_child(glow)
		for frame in 3: await process_frame
		var changed: int = occupation.call("_unlight", glow)
		if changed != 1: _failures.append("Actual glow withdrawal did not report one changed surface")
		_observe(glow, treatment == "retain-masked-surface")
		for frame in 3: await process_frame
		print("F19 OCCUPATION MATERIAL DELETE " + treatment)
		glow.queue_free()
		for frame in 4: await process_frame
		_held.clear()
		for frame in 3: await process_frame
		print("F19 OCCUPATION MATERIAL END " + treatment)
	factory.free()
	occupation.free()
	world.queue_free()
	for frame in 4: await process_frame
	print("F19 OCCUPATION MATERIAL DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures,
		"acceptance": false, "renderer": RenderingServer.get_current_rendering_method(), "drawing": false}))
	quit(0 if _failures.is_empty() else 1)

func _observe(instance: MeshInstance3D, retain: bool) -> void:
	var active := instance.get_active_material(0) as BaseMaterial3D
	var surface_override := instance.get_surface_override_material(0) as BaseMaterial3D
	if retain and surface_override != null and surface_override != active: _held.append(surface_override)
	print("F19 OCCUPATION MATERIAL OBSERVED " + JSON.stringify({
		"active_emission": active.emission_enabled if active != null else false,
		"surface_override_emission": surface_override.emission_enabled if surface_override != null else false,
		"override_masked": surface_override != null and surface_override != active,
		"held": _held.size()}))
