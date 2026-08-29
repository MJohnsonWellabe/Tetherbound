extends SceneTree

## Throwaway diagnostic (T1-GROUND-2): dump Terrain3D's generated shader code
## so the aerial-perspective fix (Job 2, distance-based colour/desaturation
## gradient in the terrain material) can be written against the REAL uniform
## names and insertion points, not guessed from strings in the .so.
##
##   godot --headless --path . --script tools/_dump_terrain_shader.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
# playground_world.gd's own _ready() is a coroutine (awaits process_frame
# itself before data_directory assignment, collision setup, THEN ground
# materials/shader). Two frames -- this tool's original wait -- reads the
# terrain material long before _apply_ground_shader has even run, so a
# "fresh" read looks identical to no override at all. Matches
# _capture_ground_and_sky.gd's own BOOT_FRAMES, the value proven to outlast
# world boot for a real capture.
const BOOT_FRAMES := 90

func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in BOOT_FRAMES:
		await process_frame

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("FAIL no Terrain node")
		quit(1)
		return

	var material: Object = terrain.get("material")
	if material == null:
		print("FAIL terrain has no material")
		quit(1)
		return

	print("material class: ", material.get_class())
	print("has enable_shader_override: ", material.has_method("enable_shader_override"))
	print("has get_shader: ", material.has_method("get_shader"))
	print("has get_shader_override: ", material.has_method("get_shader_override"))
	print("has set_shader_override: ", material.has_method("set_shader_override"))
	print("has is_shader_override_enabled: ", material.has_method("is_shader_override_enabled"))

	# T1-GROUND-2: a SECOND enable_shader_override(true) call regenerates the
	# shader from current auto-shader state and discards whatever was already
	# in shader_override, even when override was already enabled -- confirmed
	# by a real repro (playground_world.gd installs a custom override during
	# world boot; this tool used to call enable_shader_override(true) again
	# afterward and got back a fresh 23321-char stock dump instead of the
	# already-installed 27348-char custom one). Only call it when override
	# isn't already on.
	if material.has_method("enable_shader_override") and not bool(material.call("is_shader_override_enabled")):
		material.call("enable_shader_override", true)
	if material.has_method("get_shader_override"):
		var shd: Shader = material.call("get_shader_override")
		if shd != null:
			var f := FileAccess.open("res://shots/terrain_shader_dump.gdshader", FileAccess.WRITE)
			f.store_string(shd.code)
			f.close()
			print("dumped ", shd.code.length(), " chars to res://shots/terrain_shader_dump.gdshader")
		else:
			print("get_shader_override() returned null")

	quit(0)
