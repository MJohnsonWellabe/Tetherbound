extends Node3D

## D39 (OF31). The inside of Mira's cottage: the village's second real interior.
##
## Owner: "Make one of the villagers the merchant. He has a store in his house."
## A store in a house means the house has an inside, and until now every
## villager cottage was a solid AABB brick (village.gd's own fallback) with a
## painted-on door.
##
## Follows `grandpa_house.gd`'s split exactly, which is the worked example this
## copies rather than invents: the KIT owns the exterior (the `cottage_a`
## recipe in data/config/building_prefabs.json, which now authors wall colliders
## with a hole where the doorway is), and the SCRIPT owns everything the kit
## cannot know about — floor, counter, shelf, light. Nothing here is saved into
## a scene; it is attached by `village.gd` when a structure in
## data/config/village.json names an `interior`.
##
## Kept to one room on purpose. The brief asked for small, and the honest reason
## to keep it small is that a shop the player walks into for twenty seconds does
## not need a second storey; the interior that DOES (Grandpa's) already exists
## and cost an entire task.
##
## No camera profile swap. `grandpa_house.gd` shortens the spring arm indoors
## because its room is 5.4m across and the arm clipped every turn; this room is
## smaller still, but the player is only ever a step inside the door and the
## rig's own wall collision keeps the arm honest. If it reads badly in a real
## playthrough the fix is the same `set_target(target, profile)` seam that
## house already uses — noted here rather than pre-built, because a camera
## profile is a visual-affecting change and this task shipped no rendered pass.

## Room, in the cottage prefab's own local metres. The kit puts the wall lines
## on x=±2 / z=±3 and the modules bring their inner faces ~0.31 inside that, so
## these are read from the building, not chosen.
const INNER_HALF_W := 1.69
const INNER_HALF_D := 2.69
const WALL_H := 3.12
const FLOOR_RISE := 0.02
var _floor_shape: CollisionShape3D = null

## The doorway the recipe leaves open: 1.6m clear, centred on x=1 in the front
## (+z) wall. Nothing may be built into this lane or the shop has a door you
## cannot walk through.
const DOOR_X := 1.0
const DOOR_W := 1.6

const COL_FLOOR := Color("#6b4f30")
const COL_COUNTER := Color("#8a6a3f")
const COL_SHELF := Color("#5a4030")
const COL_COIN := Color("#d7ad52")
const SHOP_CREST_SCENE := preload("res://assets/props/quaternius_fantasy/Shield_Wooden.gltf")

## OWNER-0912: the old 1.3m BoxMesh carrying tiny billboarded Label3D text was
## the reported terrible sign and also violated visual-acceptance §4.12's rule
## against label/box stand-ins. Mira now gets a physical trade crest: the
## installed fantasy-prop family's wooden shield, mounted above the real door,
## with a raised gold coin medallion. It reads by silhouette before text and
## stays in the village's one prop family. Visual only; no collision or prompt.
const CREST_SCALE := 1.8
const CREST_AT := Vector3(DOOR_X, 2.68, 3.39)
const CREST_LIGHT_COLOUR := Color("#ffd17a")


## This interior keeps its measured footprint; the prefab room supplies only
## counter and lamp presentation tunables. Signature matches `cottage_interior.gd`'s so village.gd can
## dispatch either template through the same `interior.call("build", room)`.
func build(room: Dictionary = {}) -> void:
	_build_floor()
	_build_counter(room.get("shop_counter", {}))
	_build_shelf()
	_build_light(room.get("shop_light", {}))
	_build_trade_crest()
	_build_crest_light()


## A real plank floor above the terrain. Coincident support surfaces produced
## repeated floor contacts while turning by the counter. The 2cm rise separates
## them within the ordinary step height; NPC placement reads this actual floor.
func _build_floor() -> void:
	_floor_shape = _box(
		Vector3(INNER_HALF_W * 2.0 + 0.6, 0.3, INNER_HALF_D * 2.0 + 0.6),
		Vector3(0.0, -0.10 + FLOOR_RISE, 0.0),
		COL_FLOOR
	)


## Placement support from the built enabled box, including its current yaw,
## scale and top plane. This is no terrain/collision clearance certificate.
func floor_top_world_at(x: float, z: float) -> float:
	if not is_finite(x) or not is_finite(z) or not is_instance_valid(_floor_shape) \
			or not _floor_shape.is_inside_tree() or _floor_shape.disabled \
			or not _floor_shape.shape is BoxShape3D:
		return NAN
	var body := _floor_shape.get_parent() as StaticBody3D
	if body == null or (body.collision_layer & 1) == 0:
		return NAN
	var pose := _floor_shape.global_transform
	if not pose.origin.is_finite() or not pose.basis.x.is_finite() \
			or not pose.basis.y.is_finite() or not pose.basis.z.is_finite() \
			or absf(pose.basis.determinant()) < 0.000001:
		return NAN
	var half: Vector3 = (_floor_shape.shape as BoxShape3D).size * 0.5
	if not half.is_finite() or half.x <= 0.0 or half.y <= 0.0 or half.z <= 0.0:
		return NAN
	var top: Vector3 = pose * Vector3(0.0, half.y, 0.0)
	var normal: Vector3 = (pose.basis.inverse().transposed() * Vector3.UP).normalized()
	if normal.y <= 0.000001:
		return NAN
	var y := top.y - (normal.x * (x - top.x) + normal.z * (z - top.z)) / normal.y
	var local: Vector3 = pose.affine_inverse() * Vector3(x, y, z)
	return y if is_finite(y) and absf(local.x) <= half.x and absf(local.z) <= half.z else NAN


## The counter Mira stands behind. Left of the door lane, so walking in never
## walks into it, and low enough (1.0m) to read as a shop counter rather than a
## wall across the room.
func _build_counter(presentation: Dictionary = {}) -> void:
	var wood := _counter_material(presentation, "tint")
	_box(Vector3(2.5, 1.0, 0.5), Vector3(-0.35, 0.5, -0.35), COL_COUNTER, true, wood)
	# Installed village timber and physical joinery replace the featureless
	# slab. These attached details have no collider or interaction of their own.
	var trim := _counter_material(presentation, "trim_tint")
	for raw: Variant in presentation.get("joinery", []):
		if not raw is Dictionary:
			continue
		var size: Array = raw.get("size", [])
		var at: Array = raw.get("at", [])
		if size.size() != 3 or at.size() != 3:
			continue
		_box(Vector3(float(size[0]), float(size[1]), float(size[2])),
			Vector3(float(at[0]), float(at[1]), float(at[2])), COL_COUNTER, false, trim)
	# Two crates of stock on the customer side, against the west wall, clear of
	# the door lane. Flat colour, same as the counter: this is joinery, not a
	# prop pass.
	_box(Vector3(0.5, 0.5, 0.5), Vector3(-1.3, 0.25, 1.5), COL_SHELF)
	_box(Vector3(0.45, 0.45, 0.45), Vector3(-1.3, 0.72, 1.5), COL_SHELF)


func _counter_material(presentation: Dictionary, tint_key: String) -> StandardMaterial3D:
	var material := _material(Color(str(presentation.get(tint_key, COL_COUNTER.to_html()))))
	if presentation.has("albedo"):
		material.albedo_texture = load(str(presentation.albedo)) as Texture2D
	if presentation.has("normal"):
		material.normal_enabled = true
		material.normal_texture = load(str(presentation.normal)) as Texture2D
		material.normal_scale = float(presentation.get("normal_scale", 1.0))
	for key: String in ["uv_scale", "uv_offset"]:
		var values: Array = presentation.get(key, [])
		if values.size() == 3:
			material.set("uv1_" + key.trim_prefix("uv_"), Vector3(float(values[0]), float(values[1]), float(values[2])))
	material.roughness = float(presentation.get("roughness", 0.9))
	return material


## A shelf board on the back wall behind her, so the room has a back to it from
## the doorway. Not solid — a player never gets behind the counter, and a
## collider up at chest height there is only ever something to snag on.
func _build_shelf() -> void:
	_box(
		Vector3(2.8, 0.1, 0.4),
		Vector3(0.0, 1.5, -INNER_HALF_D + 0.25),
		COL_SHELF,
		false
	)


## One warm lamp. The kit shell blocks the sun completely, and an unlit shop is
## a black doorway the player never walks into.
func _build_light(presentation: Dictionary = {}) -> void:
	var light := OmniLight3D.new()
	light.name = "ShopLight"
	light.position = Vector3(0.0, 2.4, 0.3)
	light.light_color = Color(str(presentation.get("colour", "#ffe0b3")))
	light.light_energy = float(presentation.get("energy", 2.6))
	light.omni_range = float(presentation.get("range_m", 7.0))
	light.shadow_enabled = true
	add_child(light)


func _build_trade_crest() -> void:
	var crest := Node3D.new()
	crest.name = "ShopTradeCrest"
	crest.position = CREST_AT
	crest.set_meta("shop_sign_role", "installed_trade_crest")
	add_child(crest)

	var shield := SHOP_CREST_SCENE.instantiate() as Node3D
	shield.name = "InstalledWoodenShield"
	shield.scale = Vector3.ONE * CREST_SCALE
	crest.add_child(shield)

	# The old 13cm dot disappeared at ordinary street distance. A dark mounting
	# rim and a three-coin relief now make an unmistakable merchant mark without
	# returning to text, a billboard, or an oversized blank board. CylinderMesh
	# remains raised joinery on the installed shield silhouette, never the sign
	# by itself.
	var rim := MeshInstance3D.new()
	rim.name = "TradeCoinMountingRim"
	var rim_disc := CylinderMesh.new()
	rim_disc.top_radius = 0.34
	rim_disc.bottom_radius = 0.34
	rim_disc.height = 0.055
	rim_disc.radial_segments = 24
	rim.mesh = rim_disc
	rim.rotation.x = PI * 0.5
	rim.position = Vector3(0.0, -0.01, 0.246)
	rim.material_override = _material(COL_SHELF)
	crest.add_child(rim)

	var coin := MeshInstance3D.new()
	coin.name = "TradeCoinMedallion"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.27
	disc.bottom_radius = 0.27
	disc.height = 0.065
	disc.radial_segments = 24
	coin.mesh = disc
	coin.rotation.x = PI * 0.5
	coin.position = Vector3(0.0, -0.01, 0.29)
	coin.material_override = _material(COL_COIN)
	crest.add_child(coin)

	# Two smaller overlapping coins break the blank circular read that survived
	# the first production capture. Their unequal height and overlap read as a
	# physical stack from the street, including when the central face is foreshortened.
	_add_trade_coin(crest, "TradeCoinStackLeft", Vector3(-0.29, 0.12, 0.265), 0.20)
	_add_trade_coin(crest, "TradeCoinStackRight", Vector3(0.29, 0.12, 0.265), 0.20)


func _add_trade_coin(parent: Node3D, node_name: String, at: Vector3, radius: float) -> void:
	var coin := MeshInstance3D.new()
	coin.name = node_name
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	disc.radial_segments = 20
	coin.mesh = disc
	coin.rotation.x = PI * 0.5
	coin.position = at
	coin.material_override = _material(COL_COIN.darkened(0.08))
	parent.add_child(coin)


func _build_crest_light() -> void:
	# The room light is correctly trapped by the cottage shell and did not light
	# the exterior crest at night. This tiny facade-only pool gives the shield and
	# threshold their own readable hierarchy without washing the street or acting
	# as a second civic beacon.
	var light := OmniLight3D.new()
	light.name = "TradeCrestWarmPool"
	light.position = CREST_AT + Vector3(0.0, -0.25, 0.45)
	light.light_color = CREST_LIGHT_COLOUR
	light.light_energy = 1.05
	light.omni_range = 4.2
	light.shadow_enabled = false
	add_child(light)


func _box(size: Vector3, at: Vector3, colour: Color, solid := true, material: Material = null) -> CollisionShape3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material if material != null else _material(colour)
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
		return shape
	return null


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material
