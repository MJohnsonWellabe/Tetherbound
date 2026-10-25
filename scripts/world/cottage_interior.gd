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
## The room floor's walking surface in building-local metres; every prop
## stands on it (see `_build_floor`).
const FLOOR_TOP := 0.10
const COL_WOOD := Color("#5a4030")
const COL_RUG := Color("#5e5a44")
const CUT_WOOD_SHADER := preload("res://scripts/world/stormheart_cut_wood.gdshader")
const WOOD_ATLAS := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png")
const KIT := "res://assets/props/quaternius_fantasy/%s.gltf"

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


## village.gd sinks the building to `ground - 0.05`, so a slab centred at
## -0.05 with a 0.30-tall body puts its surface 5 cm proud of the terrain
## outside. Level with it (the old -0.10 centre) the two surfaces were
## coplanar on a flat settlement pad and the terrain z-fought up through the
## room (Stormwood Ashfoot shelter, GPU F41 matrix, 25 Oct); a 5 cm sill is
## well inside the character's step height.
func _build_floor() -> void:
	_box(
		Vector3(_half_w * 2.0 + 0.6, 0.3, _half_d * 2.0 + 0.6),
		Vector3(0.0, FLOOR_TOP - 0.15, 0.0),
		COL_FLOOR
	)
	# GPU F41#0 (Ashfoot inside, 25 Oct: "a bare plaster box"): planked
	# boards from the village kit's own wood atlas, the Stormheart decks'
	# cut-wood shader, laid over the slab's top face.
	var boards := MeshInstance3D.new()
	boards.name = "FloorBoards"
	var plane := PlaneMesh.new()
	plane.size = Vector2(_half_w * 2.0 + 0.6, _half_d * 2.0 + 0.6)
	boards.mesh = plane
	var wood := ShaderMaterial.new()
	wood.shader = CUT_WOOD_SHADER
	wood.set_shader_parameter("wood_atlas", WOOD_ATLAS)
	wood.set_shader_parameter("wood_tint", Color("#c9b49a"))
	wood.set_shader_parameter("weathering", 0.35)
	wood.set_shader_parameter("uv_metres", plane.size)
	boards.material_override = wood
	boards.position = Vector3(0.0, FLOOR_TOP + 0.003, 0.0)
	boards.rotation.y = PI * 0.5
	add_child(boards)


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
	# Installed village-kit furniture (quaternius_fantasy, the inn's family)
	# over the same solid footprints the boxes had; each piece keeps a box
	# collider so the room's walkable space is unchanged in kind.
	var west := -_half_w
	var bed_scale := 0.72
	var bed_size := Vector3(1.35, 0.58, 1.74)
	var bed_at := Vector3(west + bed_size.x * 0.5 + 0.03, FLOOR_TOP, -_half_d + bed_size.z * 0.5 + 0.03)
	_kit("Bed", "Bed_Twin1", bed_at, 0.0, bed_scale)
	_solid(bed_size, bed_at + Vector3(0.0, bed_size.y * 0.5, 0.0))
	var chest_size := Vector3(0.47, 0.44, 0.79)
	var chest_at := Vector3(west + chest_size.x * 0.5 + 0.04, FLOOR_TOP, bed_at.z + bed_size.z * 0.5 + chest_size.z * 0.5 + 0.12)
	if chest_at.z + chest_size.z * 0.5 > _half_d - 0.05:
		chest_at.z = _half_d - 0.05 - chest_size.z * 0.5
	_kit("Chest", "Chest_Wood", chest_at, 90.0, 0.62)
	_solid(chest_size, chest_at + Vector3(0.0, chest_size.y * 0.5, 0.0))
	var barrel_at := Vector3(west + 0.3, FLOOR_TOP, chest_at.z + chest_size.z * 0.5 + 0.32)
	if barrel_at.z + 0.25 < _half_d - 0.05:
		_kit("Barrel", "Barrel", barrel_at, 20.0, 0.7)
		_solid(Vector3(0.49, 0.63, 0.49), barrel_at + Vector3(0.0, 0.315, 0.0))
	# Wall pieces hang above head height, clear of the floor lane.
	_kit("Shelf", "Shelf_Simple", Vector3(west + 0.16, FLOOR_TOP + 1.55, chest_at.z), 90.0, 0.8)
	_kit("PegRack", "Peg_Rack", Vector3(_door_x, FLOOR_TOP + 1.6, -_half_d + 0.06), 0.0, 0.8)
	# A standing candle at the bed head is the room's warm key light (r16
	# judges: overexposed flat plaster); the ceiling fill drops to match.
	var candle_at := Vector3(bed_at.x + bed_size.x * 0.5 + 0.2, FLOOR_TOP, -_half_d + 0.3)
	_kit("Candles", "CandleStick_Stand", candle_at, 0.0, 0.6)
	_solid(Vector3(0.3, 0.8, 0.3), candle_at + Vector3(0.0, 0.4, 0.0))
	var candle := OmniLight3D.new()
	candle.name = "CandleLight"
	candle.position = candle_at + Vector3(0.0, 0.85, 0.0)
	candle.light_color = Color(1.0, 0.72, 0.45)
	candle.light_energy = 1.6
	candle.omni_range = 4.5
	candle.shadow_enabled = true
	add_child(candle)


func _build_rug() -> void:
	_box(Vector3(1.0, 0.02, 1.4), Vector3(_door_x - _door_w * 0.5 + 0.55, FLOOR_TOP + 0.01, 0.2), COL_RUG, false)


func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.position = Vector3(0.0, 2.3, 0.0)
	# Lower and warmer than the old 2.4: the white plaster blew out to a
	# shadowless box (GPU F41#0, 25 Oct).
	light.light_color = Color(1.0, 0.82, 0.62)
	light.light_energy = 0.8
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


func _kit(id: String, model: String, at: Vector3, yaw_deg: float, scale_factor: float) -> void:
	var scene := load(KIT % model) as PackedScene
	if scene == null:
		return
	var prop := scene.instantiate() as Node3D
	prop.name = id
	prop.position = at
	prop.rotation.y = deg_to_rad(yaw_deg)
	prop.scale = Vector3.ONE * scale_factor
	add_child(prop)


func _solid(size: Vector3, at: Vector3) -> void:
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
