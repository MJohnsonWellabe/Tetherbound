extends Node3D

## Authored prop clusters, placed from data/config/props.json.
##
## Same shape as village.gd's structures: data describes, code places, and
## nothing is saved into a scene. Unlike the farm buildings (raw .obj meshes),
## the Fantasy Props MegaKit imports as glTF scenes, so each entry is
## instantiated as a scene rather than loaded as a bare Mesh -- this also
## means a multi-part model keeps its parts, instead of vegetation.gd's
## flatten-to-first-mesh shortcut (fine for scattered grass, wrong for an
## authored prop someone is meant to look at). A collider is still built from
## the combined mesh AABB, the same reasoning village.gd gives: a crate you
## can walk through is a hologram.

const PROPS_DIR := "res://assets/props/quaternius_fantasy"
const CONFIG_PATH := "res://data/config/props.json"

var _placed := 0


func build() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("props.json missing; the settlement has no prop clusters")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("props.json is not valid JSON")
		return

	for cluster: Variant in (parsed as Dictionary).get("clusters", []):
		if not cluster is Dictionary:
			continue
		var cluster_name := str((cluster as Dictionary).get("name", "cluster"))
		var group := Node3D.new()
		group.name = cluster_name
		add_child(group)
		for entry: Variant in (cluster as Dictionary).get("props", []):
			if entry is Dictionary:
				_place(group, entry as Dictionary)
	print("[props] placed %d props in %d clusters" % [_placed, (parsed as Dictionary).get("clusters", []).size()])


func placed() -> int:
	return _placed


func _place(into: Node3D, spec: Dictionary) -> void:
	var model := str(spec.get("model", ""))
	var path := "%s/%s.gltf" % [PROPS_DIR, model]
	if not ResourceLoader.exists(path):
		push_error("prop missing: %s" % path)
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("prop failed to load as a scene: %s" % path)
		return

	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under prop '%s' at %.0f, %.0f" % [model, x, z])
		return

	var scale_factor := float(spec.get("scale", 1.0))
	var root: Node3D = packed.instantiate()
	root.name = model
	root.position = Vector3(x, ground, z)
	root.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	root.scale = Vector3.ONE * scale_factor
	into.add_child(root)

	var meshes: Array[MeshInstance3D] = []
	_collect(root, meshes)
	if meshes.is_empty():
		push_warning("prop '%s' has no mesh; placed with no collider" % model)
		_placed += 1
		return

	# Meshes may sit under intermediate transform nodes the glTF importer adds,
	# so this reads each one's GLOBAL transform (valid immediately -- `root`
	# is already parented into the tree above) and un-does root's own
	# transform, leaving the combined bounds in root's local, unscaled,
	# unrotated space -- the same space village.gd's OBJ meshes get for free.
	var to_root_local: Transform3D = root.global_transform.affine_inverse()
	var aabb: AABB = to_root_local * (meshes[0].global_transform * meshes[0].get_aabb())
	for i in range(1, meshes.size()):
		aabb = aabb.merge(to_root_local * (meshes[i].global_transform * meshes[i].get_aabb()))

	var body := StaticBody3D.new()
	body.name = "%s_Collision" % model
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_factor
	shape.shape = box
	body.add_child(shape)
	body.position = root.global_transform * (aabb.position + aabb.size * 0.5)
	body.rotation.y = root.rotation.y
	into.add_child(body)
	_placed += 1


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN
