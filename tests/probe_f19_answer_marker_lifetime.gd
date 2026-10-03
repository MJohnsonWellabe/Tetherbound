extends SceneTree

## Material lifetime diagnostic only: real authored captions and a Camera3D
## make the marker renderable, unlike the earlier blank-caption bare probe.
const CLIMAX := preload("res://scripts/world/stronghold_climax.gd")
var _world: Node3D

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var camera := Camera3D.new()
	_world.add_child(camera)
	camera.position = Vector3(0, 3, 7)
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold_climax.json"))
	var climax := CLIMAX.new()
	climax.set("_config", {"choice": config.choice})
	var anchor := Node3D.new()
	_world.add_child(anchor)
	climax.call("_mark_the_answer", anchor, str(climax.get("_prompt_prefix")) + "Accept")
	var caption := anchor.get_node("AnswerCaption") as Label3D
	print("F19 MARKER PROBE " + JSON.stringify({"caption": caption.text,
		"rendering_method": RenderingServer.get_current_rendering_method(), "visual_acceptance": false}))
	for frame in 3: await process_frame
	print("F19 MARKER BEFORE FREE")
	anchor.queue_free()
	for frame in 3: await process_frame
	print("F19 MARKER AFTER FREE")
	climax.free()
	_world.queue_free()
	for frame in 2: await process_frame
	quit(0)
