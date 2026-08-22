extends SceneTree

## SKY-PLANES (prompt 22) diagnosis, step 1: "identify the actual Node3D / mesh
## / resource responsible", explicitly NOT "delete arbitrary MeshInstance3Ds
## until the responsible system is known."
##
## Reproduced first, on this branch: `shots/band5_approach/01-band-mouth.png`,
## `04-before-the-gate.png` and `06-the-waystop.png` all show several large
## translucent rectangles hanging above and behind the stronghold. So the defect
## is live, it is not stale bug prose, and it is worst on exactly the sightline
## Band 5 is built around -- the player looking at the works.
##
## What this walks: every MeshInstance3D in the built world, keeping the ones
## that are BIG (a sky-filling rectangle cannot be small), reporting each one's
## node path, mesh class, size, world position, and whether its material is
## actually transparent. Sorted by height above the ground, because the thing
## that distinguishes these from ordinary world geometry is that they are up in
## the sky.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const NEAR := Vector3(0.0, 0.0, 7400.0)
const WITHIN := 900.0
const BIG := 18.0

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame
	var field: RefCounted = HEIGHTFIELD.new()

	var found: Array = []
	for node: Node in _all(world):
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null or not mesh.visible:
			continue
		var aabb: AABB = mesh.get_aabb()
		var scale: Vector3 = mesh.global_transform.basis.get_scale()
		var size := Vector3(aabb.size.x * scale.x, aabb.size.y * scale.y, aabb.size.z * scale.z)
		if maxf(size.x, maxf(size.y, size.z)) < BIG:
			continue
		var at: Vector3 = mesh.global_position
		if at.distance_to(NEAR) > WITHIN:
			continue
		var ground: float = field.height_at(at.x, at.z)
		var above: float = at.y - (0.0 if is_nan(ground) else ground)
		var transparent := false
		var mat_name := "(none)"
		var material: Material = mesh.material_override
		if material == null and mesh.mesh.get_surface_count() > 0:
			material = mesh.mesh.surface_get_material(0)
		if material != null:
			mat_name = material.resource_path if material.resource_path != "" else material.get_class()
			var std := material as BaseMaterial3D
			if std != null:
				transparent = std.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
		found.append([above, str(world.get_path_to(node)), mesh.mesh.get_class(), size, at, transparent, mat_name])

	found.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	print("=== big visible meshes within %.0fm of the approach, highest above ground first ===" % WITHIN)
	print("%8s %8s %-46s %-16s %-22s %-5s" % ["ABOVE", "Y", "NODE", "MESH/SIZE", "AT", "TRANS"])
	for entry: Variant in found:
		var e: Array = entry
		var size: Vector3 = e[3]
		var at: Vector3 = e[4]
		print("%8.1f %8.1f %-46s %-16s (%6.0f,%6.0f,%6.0f) %-5s %s" % [
			float(e[0]), at.y, e[1].left(46),
			"%s %.0fx%.0fx%.0f" % [str(e[2]).replace("Mesh", ""), size.x, size.y, size.z],
			at.x, at.y, at.z, str(bool(e[5])), e[6]])
	print("(%d candidates)" % found.size())
	quit(0)


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
