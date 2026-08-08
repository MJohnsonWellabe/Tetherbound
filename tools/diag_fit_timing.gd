extends SceneTree

## Does `_fit()` measure the same box before and after the tree updates?
##
##   godot --headless --path . --script tools/diag_fit_timing.gd
##
## `trainer_model._build()` calls `_fit()` on the line after `add_child(_art)`,
## and `_fit()` measures with `mesh.global_transform`. A global transform is
## only meaningful once the node is in the tree AND the transform has
## propagated. If it has not, the measured box is the mesh's own local AABB
## with the glTF's internal scale chain missing — and the fit factor comes out
## wrong by exactly that chain.
##
## This measures the identical box three ways so the difference is visible
## rather than argued about.

const MODELS := {
	"trainer": "res://assets/characters/trainer/trainer_lod0.glb",
	"grandpa": "res://assets/characters/grandpa/grandpa_lod0.glb",
	"terrapup": "res://assets/pals/tetherbound/terrapup/models/pal_terrapup_lod0.glb",
}


func _meshes(node: Node, found: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node)
	for child in node.get_children():
		_meshes(child, found)


## Exactly what pal_body._bounds() / trainer_model._fit() do.
func _measure(art: Node3D) -> AABB:
	var box := AABB()
	var started := false
	var found: Array = []
	_meshes(art, found)
	for mesh in found:
		var m: MeshInstance3D = mesh
		var chain := Transform3D()
		var walk: Node3D = m
		while walk != null and walk != art:
			chain = walk.transform * chain
			walk = walk.get_parent() as Node3D
		var local: AABB = chain * m.get_aabb()
		if started:
			box = box.merge(local)
		else:
			box = local
			started = true
	return box


func _init() -> void:
	_run()


func _run() -> void:
	for label: String in MODELS:
		var holder := Node3D.new()
		root.add_child(holder)
		var art: Node3D = (load(MODELS[label]) as PackedScene).instantiate() as Node3D

		holder.add_child(art)
		var immediate := _measure(art)          # what the game does today
		await process_frame
		var settled := _measure(art)            # after the tree updates

		print("\n=== %s" % label)
		print("  immediately after add_child : size.y = %.4f  -> fit x%.3f"
			% [immediate.size.y, 1.8 / maxf(immediate.size.y, 0.0001)])
		print("  after one frame             : size.y = %.4f  -> fit x%.3f"
			% [settled.size.y, 1.8 / maxf(settled.size.y, 0.0001)])
		if absf(immediate.size.y - settled.size.y) > 0.001:
			print("  *** DIFFERENT — the measurement depends on tree timing ***")
		else:
			print("  same both ways")
		holder.queue_free()
		await process_frame
	quit()
