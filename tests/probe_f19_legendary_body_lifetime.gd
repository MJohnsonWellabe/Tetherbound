extends SceneTree

## Material diagnostic only. It uses the same body scene, script, setup and
## model-pivot scale as the chamber, with a camera and actual draw frames.
const BODY_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY_SCRIPT := preload("res://scripts/creatures/creature_body.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 5, 15)
	camera.look_at(Vector3(0, 3, 0))
	camera.current = true
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold_climax.json"))
	var body := BODY_SCENE.instantiate() as Node3D
	body.set_script(BODY_SCRIPT)
	world.add_child(body)
	body.call("setup", str(config.legendary.species), false)
	body.set_physics_process(false)
	var pivot: Node3D = body.call("model_pivot")
	pivot.scale = Vector3.ONE * float(config.legendary.get("scale", 1.0))
	for frame in 3: await process_frame
	print("F19 BODY BEFORE FREE " + JSON.stringify({"species": config.legendary.species,
		"has_model": body.call("has_model"), "rendering_method": RenderingServer.get_current_rendering_method(),
		"scope": "Drawn actual legendary body teardown only; no fight, reward or visual acceptance"}))
	body.queue_free()
	for frame in 3: await process_frame
	print("F19 BODY AFTER FREE")
	world.queue_free()
	for frame in 2: await process_frame
	quit(0)
