extends SceneTree

## Round 2 raised two questions a picture cannot answer on its own.
##
## 1. WHAT ARE THE WHITE BOXES? The critic found "small untextured white boxes
##    standing on the path" and "a flat white plane hovering against the
##    hillside" near the waystop. A flat white plane is the exact symptom of
##    `23-BILLBOARD-WHITE`, which THIS LANE PREVIOUSLY REPORTED AS NOT
##    REPRODUCING on this route -- from frames captured with the player parked
##    7km away, where nothing player-driven (LOD, impostors, streaming) was
##    running. That negative result has to be re-tested with the player here.
##
## 2. WHERE ARE THE CREATURES? The critic found none in any of the twelve
##    frames, in a region carrying 22 authored clusters and 75 creatures, with
##    the player now standing on the route. Counting them beats squinting.
##
## Drives the player to each viewpoint exactly as the capture pass does, then
## reports what is actually near them.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const EYES := [
	["01-band-mouth", Vector2(0.0, 7000.0)],
	["03-mid-route", Vector2(-20.0, 7250.0)],
	["06-the-waystop", Vector2(-25.0, 7462.0)],
]
const RADIUS := 160.0

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame
	var field: RefCounted = HEIGHTFIELD.new()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D

	for entry: Variant in EYES:
		var shot: Array = entry as Array
		var at: Vector2 = shot[1]
		var ground: float = field.height_at(at.x, at.y)
		if player != null:
			player.global_position = Vector3(at.x, ground + 0.4, at.y)
		for i in 150:
			await physics_frame

		var creatures := 0
		var species := {}
		var pale: Array = []
		for node: Node in _all(world):
			var n3 := node as Node3D
			if n3 == null:
				continue
			var here := Vector2(n3.global_position.x, n3.global_position.z)
			if here.distance_to(at) > RADIUS:
				continue
			# Creatures: anything in the group the spawner uses, or a node whose
			# script path names a creature. Both, so a rename cannot hide them.
			# BY NAME, not by group. The first version of this probe asked
			# `is_in_group("creatures")` and reported a confident zero at every
			# viewpoint -- `encounter_director.gd::_spawn_creatures` adds each
			# body as `Wild_<species>_<n>` and puts it in NO group, so the check
			# could only ever return zero. A false negative that agrees with
			# what you expected to find is the most expensive kind.
			#
			# `contains`, not `begins_with`, for the second reason: colliding
			# names are auto-renamed to `@Wild_x_1@123`, so a prefix test
			# undercounts too. Both flaws pointed the same way -- fewer
			# creatures than there are.
			if n3.name.contains("Wild_"):
				creatures += 1
				var key := "%s@%.0fm" % [n3.name, here.distance_to(at)]
				species[key] = true
				continue
			var mesh := n3 as MeshInstance3D
			if mesh == null or mesh.mesh == null or not mesh.visible:
				continue
			var material: Material = mesh.material_override
			if material == null and mesh.mesh.get_surface_count() > 0:
				material = mesh.mesh.surface_get_material(0)
			var std := material as BaseMaterial3D
			var untextured: bool = std == null or std.albedo_texture == null
			if not untextured:
				continue
			var albedo: Color = std.albedo_color if std != null else Color.WHITE
			if albedo.get_luminance() < 0.55:
				continue
			var aabb: AABB = mesh.get_aabb()
			var sc: Vector3 = n3.global_transform.basis.get_scale()
			var size := Vector3(aabb.size.x * sc.x, aabb.size.y * sc.y, aabb.size.z * sc.z)
			pale.append([str(world.get_path_to(node)), mesh.mesh.get_class(), size,
				n3.global_position, albedo, std == null])

		print("=== %s (%.0f, %.0f) ===" % [shot[0], at.x, at.y])
		print("  creatures within %.0fm: %d %s" % [RADIUS, creatures, species.keys()])
		print("  pale untextured meshes within %.0fm: %d" % [RADIUS, pale.size()])
		for p: Variant in pale.slice(0, 12):
			var e: Array = p
			var size: Vector3 = e[2]
			var pos: Vector3 = e[3]
			print("    %-52s %-6s %5.1fx%5.1fx%5.1f at (%6.0f,%5.0f,%6.0f) %s%s" % [
				str(e[0]).right(52), str(e[1]).replace("Mesh", ""),
				size.x, size.y, size.z, pos.x, pos.y, pos.z,
				(e[4] as Color).to_html(false), "  NO-MATERIAL" if bool(e[5]) else ""])
	quit(0)

func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
