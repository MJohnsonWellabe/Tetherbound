extends SceneTree

## What size does the trainer actually render at, and why?
##
##     godot --headless --path . --script tools/diag_trainer_scale.gd
##
## `smoke_art.gd` checks that every SPECIES model loads at its collider's size,
## and checks that the trainer has its clips — but it never checks the
## trainer's SIZE. That gap is why a trainer reported by its owner as
## "ridiculously large, all you can see are his shoes" passed every test.
##
## This prints the same numbers `trainer_model._fit()` works from: every mesh
## it can see, that mesh's own AABB, the merged box, and the scale factor that
## falls out. If a stray mesh is widening the box, it shows up here by name.

const ART_CONFIG := "res://data/config/art.json"


func _init() -> void:
	_report("trainer", "res://assets/characters/trainer/trainer_lod0.glb")
	_report("grandpa", "res://assets/characters/grandpa/grandpa_lod0.glb")
	_report("terrapup", "res://assets/pals/tetherbound/terrapup/models/pal_terrapup_lod0.glb")
	quit()


func _meshes(node: Node, found: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node)
	for child in node.get_children():
		_meshes(child, found)


func _report(label: String, path: String) -> void:
	print("\n=== %s   %s" % [label, path])
	if not ResourceLoader.exists(path):
		print("  MISSING")
		return
	var scene := load(path) as PackedScene
	var art: Node3D = scene.instantiate() as Node3D
	# Parent it so global_transform is meaningful, exactly as the game does.
	root.add_child(art)

	var found: Array = []
	_meshes(art, found)
	print("  %d mesh instance(s) visible to _fit()" % found.size())

	var box := AABB()
	var started := false
	var to_local := art.global_transform.affine_inverse()
	for mesh: MeshInstance3D in found:
		var local: AABB = (to_local * mesh.global_transform) * mesh.get_aabb()
		print("    %-24s aabb pos=(%.2f, %.2f, %.2f) size=(%.2f, %.2f, %.2f)" % [
			mesh.name,
			local.position.x, local.position.y, local.position.z,
			local.size.x, local.size.y, local.size.z])
		if started:
			box = box.merge(local)
		else:
			box = local
			started = true

	if not started:
		print("  NO MESHES — _fit() returns early and the model stays unscaled")
		art.queue_free()
		return

	print("  merged box: pos=(%.2f, %.2f, %.2f) size=(%.2f, %.2f, %.2f)" % [
		box.position.x, box.position.y, box.position.z,
		box.size.x, box.size.y, box.size.z])

	var target := 1.8
	var fit := target / box.size.y
	print("  target height %.2fm -> fit x%.3f, lifted y=%+.3f" % [
		target, fit, -box.position.y * fit])
	print("  the mesh alone would then render %.2fm tall" % (box.size.y * fit))
	art.queue_free()
