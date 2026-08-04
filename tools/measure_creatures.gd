extends SceneTree

## Measure candidate creature/character models: native size, clips, materials.
##
##   godot --headless --path . --script tools/measure_creatures.gd -- <dir> [dir...]
##
## `tools/measure_models.gd` reports size and materials but says nothing about
## ANIMATION, and for a creature the clip list is the thing that decides whether
## the model is usable at all: `scripts/pals/pal_animator.gd` plays a per-species
## clip map, so a model that cannot idle, walk, attack, flinch and faint is not a
## candidate no matter how it looks.
##
## Sizes are reported against the 1.80m trainer, which is the project's ruler
## (`docs/reviews/MA-04`).

const TRAINER := 1.80


func _init() -> void:
	var dirs: Array = []
	for arg in OS.get_cmdline_user_args():
		dirs.append(arg)
	if dirs.is_empty():
		dirs = ["res://assets/pals/quaternius"]
	for dir_path: String in dirs:
		print("\n== %s   (trainer = %.2fm)" % [dir_path, TRAINER])
		var dir := DirAccess.open(dir_path)
		if dir == null:
			print("  cannot open")
			continue
		var names: Array[String] = []
		for file in dir.get_files():
			if file.get_extension().to_lower() in ["gltf", "glb", "fbx"]:
				names.append(file)
		names.sort()
		for file in names:
			_report("%s/%s" % [dir_path, file])
	quit(0)


func _report(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("  %-16s FAILED TO LOAD" % path.get_file())
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)

	var meshes: Array[MeshInstance3D] = []
	_collect(scene, meshes)
	var box := AABB()
	var started := false
	var tris := 0
	var textured := 0
	var mats := 0
	for mesh in meshes:
		# NOT `mesh.get_aabb()`. On a skinned mesh Godot returns a custom AABB
		# padded to cover every pose in every clip, so a 1.4m alpaca measured
		# 5.4m tall — its rear-up animation, not its height. The rest-pose
		# vertices are what a scale check is actually about, so read them.
		var world: AABB = mesh.global_transform * _rest_aabb(mesh.mesh)
		box = world if not started else box.merge(world)
		started = true
		if mesh.mesh != null:
			tris += mesh.mesh.get_faces().size() / 3
			for surface in mesh.mesh.get_surface_count():
				mats += 1
				var m: Material = mesh.mesh.surface_get_material(surface)
				if m is StandardMaterial3D and (m as StandardMaterial3D).albedo_texture != null:
					textured += 1

	var clips: PackedStringArray = []
	var players: Array[AnimationPlayer] = []
	_collect_players(scene, players)
	for player in players:
		for lib in player.get_animation_library_list():
			for a in player.get_animation_library(lib).get_animation_list():
				clips.append(String(a))

	print("  %-14s %5.2f x %5.2f x %5.2f m   %.2fx trainer   %5d tris  %d surf (%d textured)" % [
		path.get_file().get_basename(), box.size.x, box.size.y, box.size.z,
		box.size.y / TRAINER, tris, mats, textured,
	])
	print("      clips(%d): %s" % [clips.size(), ", ".join(clips)])

	root.remove_child(scene)
	scene.queue_free()


func _rest_aabb(mesh: Mesh) -> AABB:
	var box := AABB()
	var started := false
	if mesh == null:
		return box
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			if not started:
				box = AABB(v, Vector3.ZERO)
				started = true
			else:
				box = box.expand(v)
	return box


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


func _collect_players(node: Node, into: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		into.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_players(child, into)
