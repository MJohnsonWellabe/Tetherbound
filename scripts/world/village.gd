extends Node3D

## The settlement, placed from data/config/village.json.
##
## Same shape as the vegetation: data describes, code places, and nothing is
## saved into a scene. Each structure is a Mesh resource (the Quaternius farm
## OBJs import as meshes, not scenes), stood on the ground by asking the world
## (docs/decisions/D09 — never a raycast), and given one box collider; a barn
## you can walk through is a hologram, and the camera's spring arm needs the
## walls as much as the player does.

const BUILDINGS_DIR := "res://assets/buildings/quaternius_farm"
const CONFIG_PATH := "res://data/config/village.json"

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

	for entry: Variant in (parsed as Dictionary).get("structures", []):
		if not entry is Dictionary:
			continue
		_place(entry as Dictionary)
	print("[village] placed %d structures" % _placed)


func placed() -> int:
	return _placed


func _place(spec: Dictionary) -> void:
	var model := str(spec.get("model", ""))
	var path := "%s/%s.obj" % [BUILDINGS_DIR, model]
	if not ResourceLoader.exists(path):
		push_error("village structure missing: %s" % path)
		return
	var at: Array = spec.get("at", [0.0, 0.0])
	var x := float(at[0])
	var z := float(at[1])
	var ground := _ground_height(x, z)
	if is_nan(ground):
		push_error("no ground under village structure '%s' at %.0f, %.0f" % [model, x, z])
		return

	var scale_factor := float(spec.get("scale", 1.0))
	var mesh := MeshInstance3D.new()
	mesh.name = model
	mesh.mesh = load(path)
	# Sunk slightly so a structure on the flat's smoothstep skirt does not
	# hover on the high side of a residual slope.
	mesh.position = Vector3(x, ground - 0.05, z)
	mesh.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	mesh.scale = Vector3.ONE * scale_factor
	add_child(mesh)

	var aabb: AABB = (mesh.mesh as Mesh).get_aabb()
	var body := StaticBody3D.new()
	body.name = "%s_Collision" % model
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# The fences are long and thin; a full-AABB box on a rotated fence is fine
	# because the box rotates with the body.
	box.size = aabb.size * scale_factor
	shape.shape = box
	body.add_child(shape)
	body.position = mesh.position + Vector3(0.0, aabb.size.y * 0.5 * scale_factor, 0.0)
	body.rotation.y = mesh.rotation.y
	add_child(body)
	_placed += 1


func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN
