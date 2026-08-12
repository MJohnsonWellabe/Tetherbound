extends Node3D

## The settlement, placed from data/config/village.json.
##
## EV6: every structure is now a PREFAB — a building composed once from
## Medieval Village MegaKit modules by scripts/world/building_prefabs.gd
## (D24: the one civilian architectural family) — rather than a single farm
## pack mesh. Same shape as before at this level: data describes, code
## places, nothing is saved into a scene. Each placement is stood on the
## ground by asking the world (docs/decisions/D09 — never a raycast) and
## given real collision; a building you can walk through is a hologram, and
## the camera's spring arm needs the walls as much as the player does.
##
## Collision comes from the prefab's own recipe when it authors collider
## boxes (the workshop does, so its open arch bay is enterable), and from
## one combined-AABB box otherwise — the same behaviour the farm pack got.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const CONFIG_PATH := "res://data/config/village.json"

var _prefabs: RefCounted = null
var _placed := 0


func build() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("village.json missing; the settlement is a field")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("village.json is not valid JSON")
		return

	_prefabs = PREFABS.new()
	if not _prefabs.call("load_recipes"):
		return

	# Cached prefab templates need a real SceneTree parent or they leak
	# RenderingServer resources at engine shutdown (see building_prefabs.gd's
	# own header on `_holder`) -- a hidden child of this node, never a raycast
	# target, never rendered.
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	_prefabs.call("set_template_holder", template_holder)

	for entry: Variant in (parsed as Dictionary).get("structures", []):
		if not entry is Dictionary:
			continue
		_place(entry as Dictionary)
	print("[village] placed %d structures" % _placed)


func placed() -> int:
	return _placed


func _place(spec: Dictionary) -> void:
	var prefab_name := str(spec.get("prefab", ""))
	var building: Node3D = _prefabs.call("instantiate", prefab_name)
	if building == null:
		return
	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))

	# Ground at the LOWEST of the footprint's centre and four corners, not the
	# centre alone: a multi-metre footprint on the flat's smoothstep skirt
	# otherwise stands on its uphill edge and hangs its downhill corner in the
	# air — the first EV6 render caught cottage_b doing exactly that, border
	# skirt floating over its own shadow. Sinking to the lowest corner buries
	# the high side a little instead, which is what an embedded building does
	# (bible §E).
	var aabb: AABB = _prefabs.call("combined_aabb", building)
	var ground := _ground_height(x, z)
	for corner: Vector2 in [
		Vector2(aabb.position.x, aabb.position.z),
		Vector2(aabb.position.x, aabb.end.z),
		Vector2(aabb.end.x, aabb.position.z),
		Vector2(aabb.end.x, aabb.end.z),
	]:
		var world := Vector2(x, z) + corner.rotated(-yaw)
		var h := _ground_height(world.x, world.y)
		if not is_nan(h):
			ground = h if is_nan(ground) else minf(ground, h)
	if is_nan(ground):
		push_error("no ground under village structure '%s' at %.0f, %.0f" % [prefab_name, x, z])
		building.free()
		return

	building.name = "%s_%d" % [prefab_name, _placed]
	# Sunk slightly further so a structure never hovers on a residual slope.
	# The prefabs' own stone border skirts (0.13m tall) stay proud of this.
	building.position = Vector3(x, ground - 0.05, z)
	building.rotation.y = yaw
	# Modest per-placement scale, for the authored trees (a 25% spread is the
	# difference between two oaks and a stamp). Colliders are children of the
	# building, so they inherit it.
	building.scale = Vector3.ONE * float(spec.get("scale", 1.0))
	var retint: Variant = spec.get("retint", {})
	if retint is Dictionary and not (retint as Dictionary).is_empty():
		_prefabs.call("apply_retint", building, retint)
	add_child(building)

	_collide(building, prefab_name)
	_placed += 1


func _collide(building: Node3D, prefab_name: String) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	var boxes: Array = _prefabs.call("colliders", prefab_name)
	if boxes.is_empty():
		var aabb: AABB = _prefabs.call("combined_aabb", building)
		boxes = [{
			"at": [aabb.get_center().x, aabb.get_center().y, aabb.get_center().z],
			"size": [aabb.size.x, aabb.size.y, aabb.size.z],
		}]
	for entry: Variant in boxes:
		if not entry is Dictionary:
			continue
		var spec := entry as Dictionary
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		var size: Array = spec.get("size", [1.0, 1.0, 1.0])
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		shape.shape = box
		shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		body.add_child(shape)
	# A child of the building, so every box inherits its position and yaw.
	building.add_child(body)


func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN
