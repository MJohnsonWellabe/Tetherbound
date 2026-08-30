extends SceneTree

## T1-CAST-FIX: look at the unused generated flame/firewood sculpts
## (assets/props/generated_camp/camp_flame.glb, camp_firewood.glb) in
## isolation BEFORE deciding how to wire them into the player-built camp --
## the props.json `_why` history says both failed two Fable reviews ("opaque
## carved spire with no emissive light cast", "flat slabs / rock cairn") and
## the point of this rig is to find out whether that was the SHAPE or the
## LIGHTING. Renders each asset raw, then under `campfire_glow.gd`'s
## `ignite_mesh()` at a few energies, under an OUTDOOR sun (the same
## sun/sky/ACES recipe as tools/_capture_t1_camp.gd, since campfire_glow.gd's
## own notes record that a flat-lit grey-backdrop rig hid exactly the clipping
## this asset was rejected for). Also prints each surface's material facts.
##
##   xvfb-run -a -s "-screen 0 900x700x24" godot --path . \
##     --rendering-driver opengl3 --resolution 900x700 \
##     --script tools/_capture_flame_isolation.gd -- <out_dir>

const CAMPFIRE_GLOW := preload("res://scripts/world/campfire_glow.gd")

const FLAME := "res://assets/props/generated_camp/camp_flame.glb"
const FIREWOOD := "res://assets/props/generated_camp/camp_firewood.glb"


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/flame_isolation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var world := Node3D.new()
	root.add_child(world)

	# Outdoor conditions, matching _capture_t1_camp.gd's stage: sky ambient,
	# ACES, a real sun. The flat grey candidate rig already fooled one round.
	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20.0, 20.0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.31, 0.38, 0.22)
	gmat.roughness = 1.0
	ground.mesh = plane
	ground.material_override = gmat
	world.add_child(ground)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.make_current()

	for i in 30:
		await process_frame

	var shots := [
		# name, path, mode ("raw" / energy value), translucent, emission tint
		# override ("" keeps ignite_mesh's own FIRE_EMISSION)
		["flame-mult-2.0", FLAME, 2.0, true, ""],
		["flame-mult-3.5", FLAME, 3.5, true, ""],
		["flame-mult-5.0", FLAME, 5.0, true, ""],
		["flame-mult-3.5-warm", FLAME, 3.5, true, "warm"],
		["flame-mult-5.0-warm", FLAME, 5.0, true, "warm"],
	]

	var printed_materials := {}
	for shot: Array in shots:
		var scene := load(str(shot[1])) as PackedScene
		if scene == null:
			push_warning("no scene: %s" % str(shot[1]))
			continue
		var node := scene.instantiate() as Node3D
		world.add_child(node)

		if not printed_materials.has(shot[1]):
			printed_materials[shot[1]] = true
			_print_materials(str(shot[1]), node)

		if shot[2] is float:
			CAMPFIRE_GLOW.ignite_mesh(node, float(shot[2]), bool(shot[3]))
			if str(shot[4]) == "warm":
				# Variant: a warm near-white emission modulate instead of
				# FIRE_EMISSION's deep orange, letting the baked gradient's
				# own hue range (dark red base to yellow tip) carry more of
				# the colour story.
				for mi in _meshes(node):
					for si in mi.get_surface_override_material_count():
						var m := mi.get_surface_override_material(si) as StandardMaterial3D
						if m != null:
							m.emission = Color(1.0, 0.82, 0.55)

		var aabb := _combined_aabb(node)
		# Rest the sculpt's base on the ground so the render shows what a
		# placed prop would.
		node.position.y = -aabb.position.y
		aabb.position.y = 0.0
		var centre: Vector3 = aabb.position + aabb.size * 0.5
		var radius: float = aabb.size.length() * 0.5
		camera.global_position = centre + Vector3(1.0, 0.55, 1.0).normalized() * (radius * 2.4 + 0.5)
		camera.look_at(centre, Vector3.UP)

		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var out_path := "%s/%s.png" % [out_dir, str(shot[0])]
		image.save_png(out_path)
		print("wrote %s  (aabb pos=%.2f,%.2f,%.2f size=%.2f,%.2f,%.2f)" % [
			out_path, aabb.position.x, aabb.position.y, aabb.position.z,
			aabb.size.x, aabb.size.y, aabb.size.z])

		world.remove_child(node)
		node.queue_free()

	quit(0)


func _print_materials(label: String, node: Node3D) -> void:
	print("=== %s ===" % label)
	for mi in _meshes(node):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		print("  mesh instance '%s', %d surfaces" % [mi.name, mesh.get_surface_count()])
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			var std := mat as StandardMaterial3D
			if std == null:
				print("    surface %d '%s': material class %s (not StandardMaterial3D)" % [
					i, mesh.surface_get_name(i), mat.get_class() if mat != null else "<null>"])
				continue
			var arrays := mesh.surface_get_arrays(i)
			var has_uv: bool = arrays[Mesh.ARRAY_TEX_UV] != null
			print("    surface %d '%s': albedo_tex=%s albedo=%s emission_enabled=%s emission_tex=%s transparency=%d metallic=%.2f roughness=%.2f uv1=%s verts=%d" % [
				i, mesh.surface_get_name(i),
				"yes" if std.albedo_texture != null else "NO",
				std.albedo_color,
				std.emission_enabled,
				"yes" if std.emission_texture != null else "NO",
				std.transparency, std.metallic, std.roughness,
				"yes" if has_uv else "NO",
				(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()])


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var into: Array[MeshInstance3D] = []
	_collect(node, into)
	return into


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)


func _combined_aabb(node: Node3D) -> AABB:
	var meshes := _meshes(node)
	if meshes.is_empty():
		return AABB()
	var aabb: AABB = meshes[0].global_transform * meshes[0].get_aabb()
	for i in range(1, meshes.size()):
		aabb = aabb.merge(meshes[i].global_transform * meshes[i].get_aabb())
	return aabb
