extends Node3D

## R7.8's second reusable interior template — a plain lived-in room for any
## house that is not Mira's shop. `shop_interior.gd` is the first template
## and stays Mira-specific (counter, stock crates); this one is the generic
## "someone lives here" room, reused as-is by every cottage/station that
## does not need a bespoke fit-out, sized from the `room` dict its own
## prefab recipe carries in data/config/building_prefabs.json (so cottage_b's
## 4x4 footprint and ranger_station's 4x6 one share one script).
##
## Same split as `grandpa_house.gd`/`shop_interior.gd`: the kit prefab owns
## the exterior and the authored doorway hole, this owns the floor and
## everything loose inside it.

const COL_FLOOR := Color("#6b4f30")
const COL_WOOD := Color("#5a4030")
const COL_RUG := Color("#7a4a35")

var _half_w := 1.69
var _half_d := 1.69
var _door_x := 1.0
var _door_w := 1.6


## `room`: the recipe's own `room` dict (building_prefabs.gd::room_spec) —
## `inner_half_w`, `inner_half_d`, `door_x`, `door_w`. Falls back to the
## shop's own footprint if a caller attaches this with no spec, so a missing
## key fails safe into a small room rather than a zero-size one.
func build(room: Dictionary = {}) -> void:
	_half_w = float(room.get("inner_half_w", _half_w))
	_half_d = float(room.get("inner_half_d", _half_d))
	_door_x = float(room.get("door_x", _door_x))
	_door_w = float(room.get("door_w", _door_w))
	_build_floor()
	_build_furniture()
	_build_rug()
	_build_light()


## Top level with the terrain outside, same reasoning as shop_interior.gd:
## village.gd sinks the building to `ground - 0.05`, so a slab centred at
## -0.10 with a 0.30-tall body puts its surface exactly on the doorsill.
func _build_floor() -> void:
	_box(
		Vector3(_half_w * 2.0 + 0.6, 0.3, _half_d * 2.0 + 0.6),
		Vector3(0.0, -0.10, 0.0),
		COL_FLOOR
	)


## A bed and a chest, both on the west wall, clear of the door lane
## (`_door_x` +/- half `_door_w`, which runs the room's full depth).
##
## Both pieces stay on ONE side rather than splitting bed/table across the
## lane: cottage_b and ranger_station's own door opening (1.6m, centred at
## x=1.0) reaches to x=1.8, almost the full inner half-width (1.69) on that
## side, so there is no room east of the door for anything at all in the
## smaller room -- a `clampf(value, min, max)` with min > max there silently
## returned `min` and placed a table outside the wall line. Two pieces on the
## clear side reads as furnished; a piece standing in the yard does not.
func _build_furniture() -> void:
	var bed_x := -_half_w + 0.85
	var bed_z := -_half_d + 0.75
	_box(Vector3(1.5, 0.5, 0.9), Vector3(bed_x, 0.25, bed_z), COL_WOOD)
	var chest_z := clampf(bed_z + 1.2, bed_z + 0.8, _half_d - 0.6)
	_box(Vector3(0.6, 0.45, 0.5), Vector3(bed_x, 0.225, chest_z), COL_WOOD)


func _build_rug() -> void:
	_box(Vector3(1.4, 0.02, 1.2), Vector3(0.0, 0.13, 0.2), COL_RUG, false)


func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.position = Vector3(0.0, 2.3, 0.0)
	light.light_color = Color(1.0, 0.88, 0.7)
	light.light_energy = 2.4
	light.omni_range = 6.5
	light.shadow_enabled = true
	add_child(light)


func _box(size: Vector3, at: Vector3, colour: Color, solid := true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = at
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		body.position = at
		add_child(body)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material
