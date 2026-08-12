extends Node3D

## A generic placeable build piece: one glTF module, one box collider, no
## interaction. `camp.gd` stays its own hand-authored script because it
## carries the rest/craft prompts; every other `data/items/buildables.json`
## entry is plain geometry, so this one script places any of them rather
## than each piece needing its own copy of camp.gd's mesh/collision code.
##
## The Medieval Village MegaKit ships each module as a glTF scene (a node
## tree, not a bare `Mesh`), the same shape `building_prefabs.gd` already
## unpacks for `EV6`'s settlement pieces — `load()` on a `.gltf` returns a
## `PackedScene`, so it has to be instantiated rather than dropped straight
## onto a `MeshInstance3D.mesh`.

var _model: Node3D = null


## The see-through preview the placer drags around. No collision.
func build_ghost(mesh_path: String) -> void:
	_spawn(mesh_path, false)


## The real thing: solid and collidable.
func build_real(mesh_path: String) -> void:
	_spawn(mesh_path, true)


func _spawn(mesh_path: String, solid: bool) -> void:
	if not ResourceLoader.exists(mesh_path):
		push_warning("build piece missing: %s" % mesh_path)
		return
	var scene: PackedScene = load(mesh_path)
	_model = scene.instantiate() as Node3D
	add_child(_model)
	if not solid:
		return

	var combined := AABB()
	var first := true
	for mesh_instance in _mesh_instances(_model):
		var local_aabb := mesh_instance.mesh.get_aabb()
		var world_aabb := mesh_instance.transform * local_aabb
		combined = world_aabb if first else combined.merge(world_aabb)
		first = false
	if first:
		return

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = combined.size
	shape.shape = box
	body.add_child(shape)
	body.position = combined.get_center()
	add_child(body)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## Legal (green) or not (red), at ghost alpha either way — applied to every
## mesh in the module, since some are more than one part (a door and its
## handle, a fence rail and its posts).
func tint_ghost(ok: bool) -> void:
	if _model == null or not is_instance_valid(_model):
		return
	var colour := Color(0.5, 1.0, 0.5, 0.45) if ok else Color(1.0, 0.4, 0.4, 0.45)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mesh_instance in _mesh_instances(_model):
		mesh_instance.material_override = material
