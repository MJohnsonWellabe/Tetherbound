extends SceneTree

## GRASS-FIELD spike, step 0. Dump Terrain3D's OWN generated shader and the
## uniforms it binds, from a live terrain rather than from a bare resource.
##
##   godot --headless --path . --script tools/_probe_terrain3d_shader.gd
##
## `--headless` is correct: this reads shader source text and material
## parameters. It renders nothing.
##
## Why this has to exist before a line of grass shader is written: a
## camera-relative grass carpet has to put each blade on the terrain surface,
## which means sampling the same height data Terrain3D's own vertex shader
## samples, with the same region-lookup arithmetic. Getting that arithmetic
## subtly wrong does not error -- it puts the grass a few metres under the
## ground, or on a plane, and looks like "the shader does not work".
##
## The addon ships here as a GDExtension BINARY (`addons/terrain_3d/bin/*.so`)
## with no C++ sources vendored, so the generated shader IS the authoritative
## description of the data layout available offline. Copy its height lookup;
## do not reinvent it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/terrain3d_generated.gdshader"

## Boot frames before the terrain has built its material. Small: this does not
## need the scatter, the village or the encounter director, only Terrain3D's
## own `_ready`.
const BOOT_FRAMES := 30


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in BOOT_FRAMES:
		await physics_frame

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("FAIL: no Terrain node in %s" % SCENE)
		quit(1)
		return

	print("terrain class: %s" % terrain.get_class())
	for prop in ["region_size", "vertex_spacing", "mesh_size", "mesh_lods"]:
		if prop in terrain:
			print("  %-16s = %s" % [prop, str(terrain.get(prop))])

	var data: Object = terrain.get("data")
	if data != null:
		print("data class: %s" % data.get_class())
		for call_name in ["get_height_maps_rid", "get_control_maps_rid", "get_color_maps_rid"]:
			if data.has_method(call_name):
				print("  %-24s -> %s" % [call_name, str(data.call(call_name))])
		if data.has_method("get_region_map"):
			var region_map: Variant = data.call("get_region_map")
			print("  region_map size: %d" % (region_map as Array).size())

	var material: Object = terrain.get("material")
	if material == null:
		print("FAIL: terrain has no material")
		quit(1)
		return
	print("material class: %s" % material.get_class())

	# The generated source. This is the thing worth having on disk.
	var code := ""
	for getter in ["get_shader_code", "get_shader", "_get_shader_code"]:
		if material.has_method(getter):
			var got: Variant = material.call(getter)
			if got is String:
				code = got
			elif got is Shader:
				code = (got as Shader).code
			if code != "":
				print("shader source via %s(): %d chars" % [getter, code.length()])
				break
	if code == "" and material.has_method("get_shader_rid"):
		# 1.0.2 has no source getter on the resource, but it does expose the
		# RenderingServer RID of the shader it generated, and the server will
		# hand back the source for it. This is the authoritative copy: it is
		# the exact text the running terrain compiled.
		var shader_rid: RID = material.call("get_shader_rid")
		print("shader rid = %s" % str(shader_rid))
		if shader_rid.is_valid():
			code = RenderingServer.shader_get_code(shader_rid)
			print("shader source via RenderingServer.shader_get_code(): %d chars" % code.length())
	if code == "":
		print("FAIL: could not obtain the generated shader source")
	else:
		var f := FileAccess.open(OUT, FileAccess.WRITE)
		if f != null:
			f.store_string(code)
			f.close()
			print("wrote %s" % OUT)

	# What the material actually has bound. `_region_map`, `_vertex_spacing`
	# and friends are what a grass shader has to replicate.
	print("")
	print("--- shader parameters currently bound on the terrain material ---")
	for entry: Dictionary in material.get_property_list():
		var pname := str(entry.get("name", ""))
		if pname.begins_with("shader_parameter/") or pname.begins_with("_"):
			print("  %s" % pname)

	# The uniform block, pulled out of the source, is the useful part.
	if code != "":
		print("")
		print("--- uniforms declared by the generated shader ---")
		for line in code.split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("uniform") or stripped.begins_with("group_uniforms"):
				print("  %s" % stripped)
	quit(0)
