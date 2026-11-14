extends RefCounted

## F38#12 `cache_dressing_1113` (per harvest node, flag-off). A found reward
## (the orb basket, the dropped travel pack, the stashed tonic) sat alone on
## bare lawn. This stages it as a small traveller's cache from installed camp
## props: each node lists a few props at offsets round its own anchor.
## Visual only: children of the node, no collider, prompt, claim or save
## change; they leave with the node when the reward is taken. Positions come
## from config, so every peer builds the same dressing.
## Switch: data/config/harvest_stash_support.json `cache_dressing_enabled`
## (the node blocks sit in a JSON list a deep-merge overlay cannot address).
const SWITCH := "res://data/config/harvest_stash_support.json"
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const ROOT_NAME := "HarvestCacheDressing"


static func switch_on() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SWITCH))
	return parsed is Dictionary and bool((parsed as Dictionary).get("cache_dressing_enabled", false))


static func block_for(presentation: Dictionary) -> Dictionary:
	var block: Variant = presentation.get("cache_dressing_1113", {})
	if not block is Dictionary or not bool((block as Dictionary).get("enabled", false)):
		return {}
	return block as Dictionary


## Builds the props under `node`. Returns the dressing root, or null.
static func build(node: Node3D, presentation: Dictionary) -> Node3D:
	var block := block_for(presentation)
	if block.is_empty() or not switch_on():
		return null
	return build_props(node, block.get("props", []), ROOT_NAME)


## The shared builder: a named root under `node` holding one holder per prop
## row (`model`, `height_m`, `at` [x, z], `yaw_deg`, optional `lift_m`).
static func build_props(node: Node3D, props: Array, root_name: String, yaw_deg: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.rotation.y = deg_to_rad(yaw_deg)
	for entry: Variant in props:
		if not entry is Dictionary:
			continue
		var prop := _prop(entry as Dictionary)
		if prop != null:
			root.add_child(prop)
	if root.get_child_count() == 0:
		root.free()
		return null
	node.add_child(root)
	return root


## Once the node is in the world: rest each prop on the ground under its own
## offset, so a cache on a slope neither floats nor sinks.
static func settle(node: Node3D, root_name: String = ROOT_NAME) -> void:
	var root := node.get_node_or_null(root_name) as Node3D
	if root == null or not node.is_inside_tree():
		return
	for child: Node in root.get_children():
		var prop := child as Node3D
		var at := prop.global_position
		var ground := _ground_height(node, at.x, at.z)
		if is_finite(ground):
			prop.global_position.y = ground + float(prop.get_meta(&"lift_m", 0.0))


static func _ground_height(from: Node, x: float, z: float) -> float:
	var walk: Node = from.get_parent()
	while walk != null:
		if walk.has_method("ground_height_at"):
			return float(walk.call("ground_height_at", x, z))
		walk = walk.get_parent()
	return NAN


static func _prop(entry: Dictionary) -> Node3D:
	var path := str(entry.get("model", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed: Variant = load(path)
	if not packed is PackedScene:
		return null
	var holder := Node3D.new()
	holder.name = str(entry.get("name", path.get_file().get_basename()))
	var model := (packed as PackedScene).instantiate() as Node3D
	if model == null:
		holder.free()
		return null
	holder.add_child(model)
	IMPORTED_MATERIALS.make_dielectric(model)
	var bounds := _bounds(model)
	var height := float(entry.get("height_m", 0.0))
	if bounds.size.y > 0.0 and height > 0.0:
		model.scale *= height / bounds.size.y
		bounds = _bounds(model)
	# Stand the model on the holder's origin, centred.
	model.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var at: Array = entry.get("at", [0.0, 0.0])
	holder.position = Vector3(float(at[0]), 0.0, float(at[1])) if at.size() >= 2 else Vector3.ZERO
	holder.rotation = Vector3(
			deg_to_rad(float(entry.get("pitch_deg", 0.0))),
			deg_to_rad(float(entry.get("yaw_deg", 0.0))),
			deg_to_rad(float(entry.get("roll_deg", 0.0))))
	holder.set_meta(&"lift_m", float(entry.get("lift_m", 0.0)))
	holder.position.y = float(entry.get("lift_m", 0.0))
	return holder


static func _bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	for node: Node in root.find_children("*", "MeshInstance3D", true, false) + ([root] if root is MeshInstance3D else []):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var local := Transform3D.IDENTITY
		var walk: Node3D = mesh
		while walk != null and walk != root.get_parent():
			local = walk.transform * local
			walk = walk.get_parent() as Node3D
		var box: AABB = local * mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	return bounds
