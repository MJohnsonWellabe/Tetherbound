extends RefCounted

## F38 P2-033 / P2-034 (OFF): Meadows ground pickups and harvest rewards read
## as generic glows, crates or plants. Per item id, a Meshy model (provenance in
## its assets/props/meshy-1020 folder) replaces only the visual, fitted to a
## height and seated on the ground. Interaction, claims, glow and saves are the
## caller's and unchanged. Config: data/config/meshy_item_visuals.json.
const CONFIG := "res://data/config/meshy_item_visuals.json"
const META := &"meshy_item_visual"

static var _cfg: Dictionary = {}
static var _loaded := false


static func spec_for(item_id: String, realm: String = "meadows") -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		_cfg = parsed if parsed is Dictionary else {}
	if not bool(_cfg.get("enabled", false)) or realm not in (_cfg.get("realms", ["meadows"]) as Array):
		return {}
	var items: Dictionary = _cfg.get("items", {})
	return items.get(item_id, {})


## A wrapper node holding the fitted model, or null when not configured.
static func visual_for(item_id: String, realm: String = "meadows") -> Node3D:
	var spec := spec_for(item_id, realm)
	if spec.is_empty():
		return null
	var packed := load(str(spec.get("model", ""))) as PackedScene
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	var box := AABB()
	var first := true
	for raw: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		var t := Transform3D()
		var walk: Node = mesh
		while walk != null and walk != model:
			t = (walk as Node3D).transform * t
			walk = walk.get_parent()
		var b := t * mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y <= 0.0:
		model.free()
		return null
	var wrapper := Node3D.new()
	wrapper.name = "MeshyItemVisual"
	wrapper.set_meta(META, true)
	wrapper.set_meta(&"glow_scale", float(spec.get("glow_scale", 1.0)))
	wrapper.add_child(model)
	var s := float(spec.get("height_m", 0.4)) / box.size.y
	model.scale = Vector3.ONE * s
	model.position = -Vector3(box.get_center().x * s, box.position.y * s - float(spec.get("lift_m", 0.0)), box.get_center().z * s)
	model.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	return wrapper
