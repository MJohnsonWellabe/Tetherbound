extends SceneTree

## HIST-164 — "three named landmarks are two kits used twice."
##
##   "$GODOT" --headless --path . --script tools/_probe_village_kit_modules.gd
##
## The register's finding, re-derived from `building_prefabs.json` before
## starting: the inn and `farmhouse_shell` have **identical module histograms**
## — 74 modules against 75, and the one extra is a door leaf, which is not
## visible from outside. From the square they are the same building.
##
## Before reaching for new art, this asks what the installed kit already has.
## `assets/buildings/quaternius_medieval/` holds 64 modules and the 18 prefabs
## in `building_prefabs.json` use a subset of them; this probe reports the AABB
## of every candidate a differentiating pass would want, so placements can be
## real numbers off the mesh rather than guesses off a filename.
##
## Origin matters as much as size. A module whose origin sits at its own base
## centre places differently from one whose origin is a corner, and the recipe
## format is a bare `at`/`yaw_deg` with no offset convention written down
## anywhere — so every number here is printed relative to the mesh's own
## origin, which is what `at` moves.

const KIT := "res://assets/buildings/quaternius_medieval"

## Candidates for differentiating one village building from another, plus the
## modules already in use as a control: a size read that disagrees with a
## placement already shipping means the read is wrong, not the placement.
const CANDIDATES := [
	"Roof_Dormer_RoundTile",
	"Overhang_Plaster_Long",
	"Overhang_Plaster_Short",
	"Overhang_Plaster_Corner",
	"Overhang_Plaster_Corner_Front",
	"Overhang_Roof_Plaster",
	"Overhang_RoofIncline_Plaster",
	"Roof_FrontSupports",
	"Roof_Support2",
	"Prop_Support",
	"Stairs_Exterior_Straight",
	"Stairs_Exterior_Platform",
	"Wall_Arch",
	"Prop_Chimney",
	"Prop_Chimney2",
	"Prop_Brick1",
	"Prop_Brick2",
	"Prop_Wagon",
	"Roof_RoundTiles_6x10",
	"Roof_Front_Brick6",
	"Wall_UnevenBrick_Straight",
	"Wall_Plaster_Straight",
]


func _init() -> void:
	_run()


func _run() -> void:
	for i in 4:
		await process_frame
	var holder := Node3D.new()
	root.add_child(holder)

	print("village kit module measurements (AABB relative to each mesh's own origin)")
	print("%-32s %-24s %-24s %s" % ["module", "size (x,y,z)", "min (x,y,z)", "max (x,y,z)"])
	for name: String in CANDIDATES:
		var path := "%s/%s.gltf" % [KIT, name]
		if not ResourceLoader.exists(path):
			print("%-32s MISSING" % name)
			continue
		var packed: PackedScene = load(path)
		if packed == null:
			print("%-32s could not load" % name)
			continue
		var instance: Node = packed.instantiate()
		holder.add_child(instance)
		await process_frame
		var aabb := _aabb(instance)
		holder.remove_child(instance)
		instance.queue_free()
		if aabb.size == Vector3.ZERO:
			print("%-32s no MeshInstance3D found" % name)
			continue
		print("%-32s %-24s %-24s %s" % [
			name, _v(aabb.size), _v(aabb.position), _v(aabb.end),
		])
	quit()


## The union of every `MeshInstance3D` AABB under `node`, in `node`'s own local
## space — i.e. the space the recipe's `at` is expressed in.
func _aabb(node: Node) -> AABB:
	var out := AABB()
	var started := false
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var mesh := current as MeshInstance3D
		if mesh != null and mesh.mesh != null:
			var local := mesh.get_aabb()
			var xform := (node as Node3D).global_transform.affine_inverse() * mesh.global_transform
			var world := xform * local
			out = world if not started else out.merge(world)
			started = true
		for child in current.get_children():
			stack.append(child)
	return out


func _v(v: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [v.x, v.y, v.z]
