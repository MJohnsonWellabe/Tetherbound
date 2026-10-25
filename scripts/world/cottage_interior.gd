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
const FINISH_CONFIG := "res://data/config/cottage_interior_finish.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")

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
	_build_lining()
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
## GPU F41#0 / r16 judges (Ashfoot inside: "a bare plaster box", "blown-out
## window"): a ranger's timber lining over the plaster, full height on every
## wall, with the door opening left clear; the windows sit behind it as
## closed shutters. Presentation only (no collider), and only for the
## buildings `cottage_interior_finish.json` names by their village role.
func _build_lining() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FINISH_CONFIG)) if FileAccess.file_exists(FINISH_CONFIG) else null
	if not parsed is Dictionary:
		return
	var cfg: Dictionary = parsed
	if not bool(cfg.get("enabled", false)):
		return
	var holder := get_parent() as Node3D
	var role := str(holder.get_meta("village_role", "")) if holder != null else ""
	if role.is_empty() or not (cfg.get("lined_roles", []) as Array).has(role):
		return
	_build_hearth(cfg.get("hearth", {}))
	var height := float(cfg.get("lining_height_m", 2.45))
	var inset := float(cfg.get("lining_inset_m", 0.03))
	var thick := 0.04
	var wood := ShaderMaterial.new()
	wood.shader = CUT_WOOD_SHADER
	wood.set_shader_parameter("wood_atlas", WOOD_ATLAS)
	wood.set_shader_parameter("wood_tint", Color(str(cfg.get("lining_tint", "#b39a7c"))))
	wood.set_shader_parameter("weathering", float(cfg.get("lining_weathering", 0.3)))
	var y := FLOOR_TOP + height * 0.5
	var w := _half_w - inset
	var d := _half_d - inset
	# Back and side walls, full length.
	_lining_panel("LiningBack", Vector3(0.0, y, -d), Vector2(w * 2.0, height), 0.0, wood, thick)
	_lining_panel("LiningWest", Vector3(-w, y, 0.0), Vector2(d * 2.0, height), PI * 0.5, wood, thick)
	_lining_panel("LiningEast", Vector3(w, y, 0.0), Vector2(d * 2.0, height), -PI * 0.5, wood, thick)
	# Front wall either side of the door, which stays open.
	var door_left := _door_x - _door_w * 0.5
	var door_right := _door_x + _door_w * 0.5
	if door_left > -w + 0.05:
		var span := door_left + w
		_lining_panel("LiningFrontWest", Vector3(-w + span * 0.5, y, d), Vector2(span, height), PI, wood, thick)
	if door_right < w - 0.05:
		var span_r := w - door_right
		_lining_panel("LiningFrontEast", Vector3(door_right + span_r * 0.5, y, d), Vector2(span_r, height), PI, wood, thick)
	# A dark rail at chair height breaks the boards like a ranger's hut.
	var rail := StandardMaterial3D.new()
	rail.albedo_color = Color(str(cfg.get("rail_colour", "#4a3a2c")))
	rail.roughness = 0.85
	for side: Array in [[Vector3(0.0, 0.0, -d + 0.03), Vector2(w * 2.0, 0.0), 0.0], [Vector3(-w + 0.03, 0.0, 0.0), Vector2(d * 2.0, 0.0), PI * 0.5], [Vector3(w - 0.03, 0.0, 0.0), Vector2(d * 2.0, 0.0), -PI * 0.5]]:
		var at: Vector3 = side[0]
		var length: Vector2 = side[1]
		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(length.x, 0.09, 0.05)
		bar.mesh = bar_mesh
		bar.material_override = rail
		bar.position = Vector3(at.x, FLOOR_TOP + float(cfg.get("rail_height_m", 0.95)), at.z)
		bar.rotation.y = float(side[2])
		add_child(bar)


## The ranger hearth (Meshy, tb/meshy-1024 ae67083ec) on the back wall at the
## door lane's end, clear of the bed on the west side; a warm fire light in
## its firebox replaces the plaster-washing ceiling key.
func _build_hearth(cfg: Dictionary) -> void:
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		return
	var bounds := HERO_PROP.fit_height(model, float(cfg.get("height_m", 2.0)), 0.0)
	var factor := model.scale.x
	var depth := bounds.size.z * factor
	var at := Vector3(_door_x + float(cfg.get("x_offset_m", -0.28)), FLOOR_TOP, -_half_d + depth * 0.5 + 0.04)
	var holder := Node3D.new()
	holder.name = "Hearth"
	holder.position = at
	add_child(holder)
	holder.add_child(model)
	_solid(Vector3(bounds.size.x * factor, float(cfg.get("height_m", 2.0)), depth), at + Vector3(0.0, float(cfg.get("height_m", 2.0)) * 0.5, 0.0))
	var fire := OmniLight3D.new()
	fire.name = "HearthFire"
	fire.position = at + Vector3(0.0, 0.45, depth * 0.35)
	fire.light_color = Color(str(cfg.get("fire_colour", "#ffb066")))
	fire.light_energy = float(cfg.get("fire_energy", 1.8))
	fire.omni_range = float(cfg.get("fire_range_m", 5.5))
	fire.shadow_enabled = true
	add_child(fire)


func _lining_panel(id: String, at: Vector3, size: Vector2, yaw: float, material: Material, thick: float) -> void:
	var panel := MeshInstance3D.new()
	panel.name = id
	var quad := QuadMesh.new()
	quad.size = size
	panel.mesh = quad
	var lined := material.duplicate() as ShaderMaterial
	# Boards run vertically: the shader's board width runs along UV.x.
	lined.set_shader_parameter("uv_metres", Vector2(size.x, size.y))
	panel.material_override = lined
	panel.position = at
	panel.rotation.y = yaw
	add_child(panel)


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
	if get_node_or_null(^"Hearth") == null:
		_kit("PegRack", "Peg_Rack", Vector3(_door_x, FLOOR_TOP + 1.6, -_half_d + 0.06), 0.0, 0.8)


func _build_rug() -> void:
	_box(Vector3(1.0, 0.02, 1.4), Vector3(_door_x - _door_w * 0.5 + 0.55, FLOOR_TOP + 0.01, 0.2), COL_RUG, false)


func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "RoomLight"
	light.position = Vector3(0.0, 2.3, 0.0)
	# Lower and warmer than the old 2.4: the white plaster blew out to a
	# shadowless box (GPU F41#0, 25 Oct).
	light.light_color = Color(1.0, 0.82, 0.62)
	light.light_energy = 1.35
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
