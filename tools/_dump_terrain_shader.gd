extends SceneTree

## Throwaway diagnostic (T1-GROUND-2): dump Terrain3D's generated shader code
## so the aerial-perspective fix (Job 2, distance-based colour/desaturation
## gradient in the terrain material) can be written against the REAL uniform
## names and insertion points, not guessed from strings in the .so.
##
##   godot --headless --path . --script tools/_dump_terrain_shader.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
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

	if material.has_method("enable_shader_override"):
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
