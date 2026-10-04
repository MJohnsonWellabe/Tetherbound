extends SceneTree

## Component diagnostic only. Actual station geometry, tint, BuildPlacer
## overlay and ghost cancellation run with a camera. Startup/interaction
## fixtures avoid mounting a world, registering a station or paying a build.
const STATION := preload("res://scripts/build/station_piece.gd")
const PLACER := preload("res://scripts/build/build_placer.gd")

class DiagnosticPlacer extends PLACER:
	func _ready() -> void:
		set_physics_process(false)

class DiagnosticStation extends STATION:
	func mount_interaction() -> void:
		pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for drawing: bool in [true, false]:
		RenderingServer.render_loop_enabled = drawing
		for settled_frames: int in [0, 3]:
			var world := Node3D.new()
			root.add_child(world)
			var camera := Camera3D.new()
			world.add_child(camera)
			camera.position = Vector3(0, 5, 12)
			camera.look_at(Vector3(0, 1, 0))
			camera.current = true
			print("F19 BUILD MATERIAL BEGIN " + JSON.stringify({
				"continuous_drawing": drawing, "settled_frames": settled_frames,
				"scope": "Actual component lifecycle only; no paid placement or visual acceptance"}))
			var placer := DiagnosticPlacer.new()
			world.add_child(placer)
			placer.call("_ensure_overlay")
			placer.call("_set_overlay_visible", true)
			var ghost := STATION.new()
			ghost.call("build", "altar", true)
			world.add_child(ghost)
			placer.set("_ghost", ghost)
			for frame in settled_frames: await process_frame
			# Ordinary feedback can dirty the material immediately before cancel.
			ghost.call("tint_ghost", false)
			placer.call("_drop_ghost")
			for frame in 3: await process_frame
			print("F19 BUILD MATERIAL GHOST DROPPED")
			var placed := DiagnosticStation.new()
			placed.call("build", "altar", false)
			placed.set_process(false)
			placed.position.x = 3
			world.add_child(placed)
			for frame in settled_frames: await process_frame
			placed.queue_free()
			for frame in 3: await process_frame
			print("F19 BUILD MATERIAL PLACED GEOMETRY FREED")
			# The actual overlay is a root CanvasLayer; the grid belongs to world.
			var overlay: Node = placer.get("_overlay")
			world.queue_free()
			overlay.queue_free()
			for frame in 3: await process_frame
			print("F19 BUILD MATERIAL END")
	RenderingServer.render_loop_enabled = true
	for frame in 3: await process_frame
	quit(0)
