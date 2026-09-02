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

## The doorway the recipe leaves open: 1.6m clear, centred on x=1 in the front
## (+z) wall. Nothing may be built into this lane or the shop has a door you
## cannot walk through.
const DOOR_X := 1.0
const DOOR_W := 1.6

const COL_FLOOR := Color("#6b4f30")
const COL_COUNTER := Color("#8a6a3f")
const COL_SHELF := Color("#5a4030")

## OWNER-0902 (owner playtest finding 9): "Mira shouldn't be hidden in a
## house." OF31 put the merchant behind a real counter in a real room, which
## is the right call for a shop — the fix is not to pull her back outside.
## What was actually missing is on the OUTSIDE: cottage_a's doorway looks
## exactly like cottage_b's or Grandpa's, so nothing tells a player a
## merchant is behind this specific door before they walk in. `_build_sign()`
## below hangs a placeholder board over the doorway, painted with her name —
## the same primitive-box-plus-Label3D mechanism `signpost.gd` already proves
## at the square (CLAUDE.md: a placeholder is fine to prove a mechanic; this
## spends no new asset and no Meshy generation).
const COL_SIGN := Color("#6b4a2f")
const SIGN_TEXT := "Mira's Store"
const SIGN_WIDTH := 1.3     # x
const SIGN_BOARD_H := 0.4   # y, vertical
const SIGN_THICKNESS := 0.06  # z, front-to-back
## Just above the 2.3m kit doorway, clear of a walking head.
const SIGN_Y := 2.55
## The recipe's own front wall line sits at local z=3 (this file's own
## `INNER_HALF_W`/`_D` comment); a hair further out clears the wall face.
const SIGN_Z := 3.45


## `_room` unused: this interior is Mira-specific and keeps its own hardcoded
## footprint. Signature matches `cottage_interior.gd`'s so village.gd can
## dispatch either template through the same `interior.call("build", room)`.
func build(_room: Dictionary = {}) -> void:
	_build_floor()
	_build_counter()
	_build_shelf()
	_build_light()
	_build_sign()


## A plank floor whose TOP sits level with the ground outside.
##
## village.gd sinks a building to `ground - 0.05`, so a slab centred at -0.10
## with a 0.30 body puts its surface exactly on the terrain height — no step at
## the threshold, and the villager standing inside (placed on the TERRAIN by
## village_npcs.gd, which knows nothing about floors) has her feet on the boards
## rather than through them.
func _build_floor() -> void:
	_box(
		Vector3(INNER_HALF_W * 2.0 + 0.6, 0.3, INNER_HALF_D * 2.0 + 0.6),
		Vector3(0.0, -0.10, 0.0),
		COL_FLOOR
	)


## The counter Mira stands behind. Left of the door lane, so walking in never
## walks into it, and low enough (1.0m) to read as a shop counter rather than a
## wall across the room.
func _build_counter() -> void:
	_box(Vector3(2.5, 1.0, 0.5), Vector3(-0.35, 0.5, -0.35), COL_COUNTER)
	# Two crates of stock on the customer side, against the west wall, clear of
	# the door lane. Flat colour, same as the counter: this is joinery, not a
	# prop pass.
	_box(Vector3(0.5, 0.5, 0.5), Vector3(-1.3, 0.25, 1.5), COL_SHELF)
	_box(Vector3(0.45, 0.45, 0.45), Vector3(-1.3, 0.72, 1.5), COL_SHELF)


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
func _build_light() -> void:
	var light := OmniLight3D.new()
	light.name = "ShopLight"
	light.position = Vector3(0.0, 2.4, 0.3)
	light.light_color = Color(1.0, 0.88, 0.7)
	light.light_energy = 2.6
	light.omni_range = 7.0
	light.shadow_enabled = true
	add_child(light)


## Billboarded rather than painted on a fixed face the way `signpost.gd`'s
## arms are: those need a face that points along a specific bearing so the
## plank itself reads as pointing somewhere, which is why that file goes to
## the trouble of painting both sides. This is one static board read from
## whichever direction a player approaches the doorway from, so a billboard
## is the simpler, equally correct choice — there is no bearing for it to get
## backwards.
func _build_sign() -> void:
	var board := MeshInstance3D.new()
	board.name = "ShopSignBoard"
	var box := BoxMesh.new()
	box.size = Vector3(SIGN_WIDTH, SIGN_BOARD_H, SIGN_THICKNESS)
	board.mesh = box
	board.position = Vector3(DOOR_X, SIGN_Y, SIGN_Z)
	board.material_override = _material(COL_SIGN)
	add_child(board)

	var text := Label3D.new()
	text.name = "ShopSignLabel"
	text.text = SIGN_TEXT
	text.font_size = 40
	# Fits the board's own width the same way signpost.gd's `_label_scale`
	# fits a plank — 0.55 em per glyph, a margin left at each end.
	text.pixel_size = (SIGN_WIDTH * 0.86) / maxf(1.0, float(SIGN_TEXT.length()) * 0.55 * 40.0)
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = false
	text.modulate = Color("#f4ecd8")
	text.outline_size = 4
	text.outline_modulate = Color("#241a10")
	text.position = Vector3(DOOR_X, SIGN_Y, SIGN_Z + SIGN_THICKNESS * 0.5 + 0.02)
	add_child(text)


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
