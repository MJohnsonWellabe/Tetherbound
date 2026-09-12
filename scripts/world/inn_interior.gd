extends Node3D

## R7.9's THIRD interior template — the inn's common room. Deliberately not a
## bigger `cottage_interior.gd`: that script's own scoping line ("not a
## bespoke interior per building") was written for ordinary houses, and
## stretching it to also carry a counter and multiple guest seats would bend
## that scoping rather than honour it. Follows `shop_interior.gd`'s pattern
## instead — a bespoke, single-purpose room with its own hardcoded footprint
## — because like Mira's shop this building has exactly one occupant role
## (an innkeeper) and one layout, not a family of houses sharing a script.
##
## Room dimensions match the `inn` prefab's own `room` key in
## data/config/building_prefabs.json (kept there for documentation even
## though this script does not read it, the same way shop_interior.gd
## ignores cottage_a's `room` key): wall lines at x=+-3/z=+-5, modules bring
## their inner face ~0.31 inside that.
const INNER_HALF_W := 2.69
const INNER_HALF_D := 4.69
const DOOR_X := 0.0
const DOOR_W := 1.6

## Back wall, centred — the counter Bram stands behind.
const COUNTER_Z := -INNER_HALF_D + 1.0

## R7.9 round 2 (blind visual-judge). Real furniture, the same two vendored
## packs grandpa_house.gd already draws its own dressing from — never a new
## Meshy generation, and the same "OBJ furniture pack needs a 0.5 correction,
## glTF Fantasy Props pack is already real-metre" split that file's own
## `_furnish()` documents.
const FURNITURE_DIR := "res://assets/props/quaternius_furniture"
const FANTASY_DIR := "res://assets/props/quaternius_fantasy"
const FURNITURE_SCALE := 0.5
const TABLE_APPLES := preload("res://assets/props/quaternius_fantasy/FarmCrate_Apple.gltf")
const SERVING_POT := preload("res://assets/props/quaternius_fantasy/Pot_1.gltf")
const WOOD_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png")
const WOOD_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_Normal.png")
const WOOD_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_Roughness.png")

## N05-WORLD-DRESSING-0905 dressing tones: shelf and sign timber a shade
## darker than the counter, lantern iron, pewter, and two bottle glasses.
const COL_SHELF := Color("#5a3d22")
const COL_IRON := Color("#2a2724")
const COL_PEWTER := Color("#8e8a84")
const COL_GLASS_GREEN := Color("#3a5a2e")
const COL_GLASS_AMBER := Color("#8a5a1e")
const COL_JUG := Color("#7a4a35")
const COL_LAMP_GLOW := Color(1.0, 0.82, 0.55)
const COL_FLOOR := Color("#6b4f30")
const COL_COUNTER := Color("#8a6a3f")
const COL_CEILING := Color("#4a3626")
const COL_RUG := Color("#315849")
const COL_RUNNER_GREEN := Color("#315849")
const COL_RUNNER_RED := Color("#753e34")
const COL_CROCKERY := Color("#d7c6a2")
const COL_RUG_BORDER := Color("#b18a52")
const COL_SCREEN_CLOTH := Color("#3f5745")
const COL_FLOOR_SEAM := Color("#493722")
const COL_FLOOR_WEAR := Color("#806747")

var _last_interior_time := ""


## `_room` unused, same reason shop_interior.gd's own `build()` ignores it —
## this interior is Bram's and keeps its own hardcoded footprint. Signature
## matches the other two templates so village.gd can dispatch any of the
## three through the same `interior.call("build", room)`.
func build(_room: Dictionary = {}) -> void:
	_build_floor()
	_build_ceiling()
	_build_architecture_dressing()
	_build_counter()
	_build_counter_dressing()
	_build_guest_area(-1.5, 1.5)
	_build_guest_area(1.5, 1.5)
	_build_bed_nook(1.7, -1.7)
	_build_rug()
	_build_public_room_aisle_textile()
	_build_floor_use_wear()
	_build_lodging_alcove_screen()
	_build_lights()
	_build_bar_dressing()
	_build_common_room_occupation()
	set_process(true)


## The point Bram stands, local to this node — a stride behind the counter,
## near the back wall, facing the door. Read by whoever places him (a
## one-time authoring probe, not a runtime lookup — village_npcs.json still
## stores a static world position, the same as every other villager) rather
## than hand-computed by rotation trig against the building's own yaw_deg,
## which ralph/NOTES.md's own R7.9 record calls out as the error-prone way
## Mira's own position was first derived.
func bar_position() -> Vector3:
	return to_global(Vector3(0.0, 0.0, COUNTER_Z - 0.7))


## village.gd sinks the building to `ground - 0.05`; a slab centred at -0.10
## (cottage_interior.gd/shop_interior.gd's own formula) puts its surface
## EXACTLY on that ground height, which only reads right on a site with some
## residual slope under the footprint. The inn's own site (village.json's
## `_why`) sits on the village square's dead-flat pad -- ground height is the
## SAME 0.900 at every sampled point across the whole 6x10 footprint, so the
## floor and the terrain underneath it were perfectly coplanar and lost every
## depth tie to the terrain's own draw order, rendering as grass filling the
## room in tools/capture_inn.gd's own first two passes (a first attempt at
## this fix sank the slab BELOW ground instead of above it, by the same
## margin in the wrong direction -- that buried the floor under the terrain
## outright, no tie to lose). Centred at -0.08, the floor's own top surface
## sits 2cm PROUD of true ground -- imperceptible as a lip at the doorsill,
## the same direction an actual wooden floor would sit over an earthen
## threshold, and clear of the terrain's own draw depth so it always wins.
func _build_floor() -> void:
	_box(
		Vector3(INNER_HALF_W * 2.0 + 0.6, 0.3, INNER_HALF_D * 2.0 + 0.6),
		Vector3(0.0, -0.08, 0.0),
		COL_FLOOR
	)
## R7.9 round 2 (blind visual-judge): this room has no second storey — that
## is the documented scope decision (building_prefabs.json's `inn` `_why`) —
## but that also means nothing capped the ROOM visually. The kit's upper
## floor/roof shell is real geometry, not a sealed box, so a camera inside
## the ground floor looking up saw straight through the exposed timber-frame
## lattice to open sky, which the blind critic read (reasonably) as a broken
## window texture. `building_prefabs.json`'s own "ceiling and everything
## above it" collider already blocks the PLAYER from reaching up there; this
## adds the visual mesh that collider never had, sealing the room the same
## way a real ceiling would. Bottom sits just under the kit's own wall-top
## (3.12) so there is no gap to see through; thickness is irrelevant since
## the roof shell hides it from outside.
func _build_ceiling() -> void:
	_box(
		Vector3(INNER_HALF_W * 2.0 + 0.6, 0.3, INNER_HALF_D * 2.0 + 0.6),
		Vector3(0.0, 3.15, 0.0),
		COL_CEILING,
		false
	)


func _build_architecture_dressing() -> void:
	# Break the common room's large pale plaster planes into the same timber-and-
	# limewash rhythm as the exterior. The previous interior was fully furnished
	# but still photographed as a beige box because every useful object sat
	# against an uninterrupted wall. These pieces are thin visual trim only and
	# do not change the room's collision or its clear central walking lane.
	var dressing := Node3D.new()
	dressing.name = "CommonRoomTimberDressing"
	add_child(dressing)
	_wood_trim_box(dressing, "WainscotWest", Vector3(0.10, 1.02, 8.65),
		Vector3(-INNER_HALF_W + 0.04, 0.55, 0.0), COL_SHELF)
	_wood_trim_box(dressing, "WainscotEast", Vector3(0.10, 1.02, 8.65),
		Vector3(INNER_HALF_W - 0.04, 0.55, 0.0), COL_SHELF)
	_wood_trim_box(dressing, "WainscotBar", Vector3(5.18, 1.02, 0.10),
		Vector3(0.0, 0.55, -INNER_HALF_D + 0.04), COL_SHELF)
	# The door wall stays open in the middle; short returns frame it without
	# creating hidden geometry across the actual threshold.
	for side: float in [-1.0, 1.0]:
		_wood_trim_box(dressing, "DoorWainscot%s" % ("L" if side < 0.0 else "R"),
			Vector3(1.65, 1.02, 0.10), Vector3(side * 1.82, 0.55, INNER_HALF_D - 0.04), COL_SHELF)
	# Unequal wall bays and four overhead ties make the long room feel built,
	# while keeping the window openings and bar shelves readable.
	for z: float in [-3.15, -0.85, 1.65, 3.45]:
		_wood_trim_box(dressing, "WestStud_%s" % str(z), Vector3(0.14, 2.02, 0.18),
			Vector3(-INNER_HALF_W + 0.02, 2.02, z), COL_CEILING)
		_wood_trim_box(dressing, "EastStud_%s" % str(z), Vector3(0.14, 2.02, 0.18),
			Vector3(INNER_HALF_W - 0.02, 2.02, z), COL_CEILING)
	for z: float in [-3.35, -1.05, 1.25, 3.35]:
		_wood_trim_box(dressing, "CeilingTie_%s" % str(z), Vector3(5.25, 0.16, 0.22),
			Vector3(0.0, 2.93, z), COL_CEILING)


func _trim_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(colour)
	instance.position = at
	parent.add_child(instance)


func _wood_trim_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _wood_material(colour)
	instance.position = at
	parent.add_child(instance)


## Spans the back wall, centred — 3.2m wide inside a 5.38m-wide room, so both
## ends stay clear of the side walls with margin to spare. Bram stands in the
## 0.7m gap behind it (`bar_position()`), guests approach from the front.
func _build_counter() -> void:
	_wood_box(Vector3(3.2, 1.0, 0.6), Vector3(0.0, 0.5, COUNTER_Z), COL_COUNTER)
	# Shallow front joinery breaks the service counter's former single flat
	# rectangle without changing its authoritative collision box or the customer
	# lane. All pieces sit on the guest face and are presentation-only.
	var joinery := Node3D.new()
	joinery.name = "CounterJoinery"
	add_child(joinery)
	_wood_trim_box(joinery, "CounterTopRail", Vector3(3.34, 0.10, 0.10),
		Vector3(0.0, 1.01, COUNTER_Z + 0.33), COL_SHELF)
	for x: float in [-1.08, 0.0, 1.08]:
		_wood_trim_box(joinery, "CounterPanel_%s" % str(x), Vector3(0.86, 0.66, 0.06),
			Vector3(x, 0.49, COUNTER_Z + 0.33), COL_SHELF)


## R7.9 round 2. A shelf behind the stock, against the west wall, clear of
## both the counter (z ends -3.39) and the guest area (z starts 0.8) — and
## two barrels flanking the inside of the doorway, the first thing a guest
## sees on the way to the bar. Real meshes (Cabinet/Barrel, the same Fantasy
## Props kit grandpa_house.gd's own EV6-remainder-polish swapped its
## featureless closet box for), replacing round 1's flat colour boxes, which
## the blind critic's own "unmodeled primitive" verdict named as the room's
## single biggest gap.
func _build_counter_dressing() -> void:
	_furnish("Cabinet", Vector3(-INNER_HALF_W + 0.25, 0.08, -2.5), 90.0, 1.0, FANTASY_DIR)
	_furnish("Barrel", Vector3(-1.6, 0.08, 3.5), 15.0, 1.0, FANTASY_DIR)
	_furnish("Barrel_Apples", Vector3(1.6, 0.08, 3.5), -20.0, 1.0, FANTASY_DIR)


## Table + chair + stool, real furniture from the same OBJ pack grandpa's own
## dining nook uses (`FURNITURE_SCALE` 0.5 is that pack's own correction, see
## `_furnish()`). Chair and stool sit fore/aft of the table (offset in z),
## not flanking it in x — the room is far deeper than it is wide, and this is
## round 1's own door-lane lesson carried over: `x` must clear the door lane
## (`DOOR_X` +/- half `DOOR_W`) by the table's own half-width, and adding
## furniture on the table's inner (door-lane) side would have reopened
## exactly the clearance problem round 1's flat boxes were built to avoid.
func _build_guest_area(x: float, z: float) -> void:
	_furnish("Table", Vector3(x, 0.08, z), 0.0, FURNITURE_SCALE, FURNITURE_DIR)
	_furnish("Chair", Vector3(x, 0.08, z - 0.9), 0.0, FURNITURE_SCALE, FURNITURE_DIR)
	_furnish("Stool", Vector3(x, 0.08, z + 0.9), 180.0, FURNITURE_SCALE, FURNITURE_DIR)


## The one guest bed, east side, well clear (0.6m+ in z) of the guest table on
## the same side so a generous bed footprint can never reach into the
## table's own space — the same overlap `cottage_interior.gd`'s own header
## warns a `clampf` bug produced once already. Also clear of the counter and
## the west-wall cabinet. Real `BedTwin`/`NightStand` meshes, the same pair
## grandpa_house.gd's own loft uses — round 1's flat-box bed was the second
## piece the blind critic named as unmodeled.
func _build_bed_nook(x: float, z: float) -> void:
	_furnish("BedTwin", Vector3(x, 0.08, z), 0.0, FURNITURE_SCALE, FURNITURE_DIR)
	_furnish("NightStand", Vector3(x, 0.08, z + 1.35), 0.0, FURNITURE_SCALE, FURNITURE_DIR)


func _build_rug() -> void:
	_box(Vector3(1.6, 0.02, 1.4), Vector3(0.0, 0.13, COUNTER_Z + 1.6), COL_RUG, false)


## A fitted wool runner turns the otherwise broad, uninterrupted tan route
## between the two dining tables into an intentional public-room aisle. It
## stops more than a metre short of the threshold and well before the bar rug,
## so both destinations retain a clear material break. This is a textile, not
## a second attempt at the rejected room-wide floorboard overlay: it occupies
## only the central metre, has a warm woven border, and is visual-only.
func _build_public_room_aisle_textile() -> void:
	var textile := Node3D.new()
	textile.name = "PublicRoomAisleTextile"
	add_child(textile)
	_trim_box(textile, "WoolField", Vector3(0.96, 0.018, 2.82),
		Vector3(0.0, 0.132, 1.55), COL_RUNNER_RED)
	for side: float in [-1.0, 1.0]:
		_trim_box(textile, "LongBorder%s" % ("L" if side < 0.0 else "R"),
			Vector3(0.055, 0.008, 2.68), Vector3(side * 0.415, 0.145, 1.55),
			COL_RUG_BORDER)
	for end: float in [-1.0, 1.0]:
		_trim_box(textile, "EndBorder%s" % ("Bar" if end < 0.0 else "Door"),
			Vector3(0.88, 0.008, 0.055), Vector3(0.0, 0.145, 1.55 + end * 1.31),
			COL_RUG_BORDER)
	# Three muted traffic patches break the untouched showroom read without
	# turning the runner into a patterned decal.
	for i in 3:
		_trim_box(textile, "TrafficWear%d" % (i + 1),
			Vector3(0.055, 0.006, 0.28 + i * 0.04),
			Vector3((-0.36 if i % 2 == 0 else 0.36), 0.149, 0.72 + i * 0.77),
			COL_RUG_BORDER.darkened(0.18))


## Thin visual seams and irregular scuffs give the exposed walking strips a
## used timber-floor rhythm. They remain below the rug surfaces and carry no
## collision, so the doorway-to-bar route is identical.
func _build_floor_use_wear() -> void:
	var wear := Node3D.new()
	wear.name = "CommonRoomFloorUseWear"
	add_child(wear)
	for x: float in [-2.25, -1.86, -1.10, 1.10, 1.78, 2.28]:
		_trim_box(wear, "FloorSeam_%s" % str(x), Vector3(0.018, 0.006, 8.62),
			Vector3(x, 0.074, 0.0), COL_FLOOR_SEAM)
	var scuffs: Array[Vector3] = [Vector3(-0.72, 0.078, 3.55), Vector3(0.64, 0.078, 3.18),
		Vector3(-0.82, 0.078, -0.35), Vector3(0.78, 0.078, -2.65)]
	for i in scuffs.size():
		_trim_box(wear, "TrafficScuff%d" % (i + 1),
			Vector3(0.34 + 0.05 * (i % 2), 0.007, 0.10 + 0.03 * (i % 3)),
			scuffs[i], COL_FLOOR_WEAR)


## The installed bed remains usable in exactly the same place, but no longer
## reads as a purple mattress dropped into the taproom. An open timber rail and
## three separate wool panels establish a modest lodging alcove along its west
## edge. The panels stop above the floor and carry no collision, so the player's
## authored route, the nightstand, and the furniture colliders are untouched.
## Separate drops and visible hems keep the screen from reading as another flat
## primitive wall when viewed down the central aisle.
func _build_lodging_alcove_screen() -> void:
	var screen := Node3D.new()
	screen.name = "LodgingAlcoveScreen"
	add_child(screen)
	var screen_x := 1.02
	var post_z: Array[float] = [-2.78, -2.05, -1.32, -0.59]
	for i in post_z.size():
		_wood_trim_box(screen, "ScreenPost%d" % (i + 1), Vector3(0.10, 1.72, 0.10),
			Vector3(screen_x, 0.94, post_z[i]), COL_CEILING)
	for rail_y: float in [0.28, 1.10, 1.80]:
		_wood_trim_box(screen, "ScreenRail_%s" % str(rail_y), Vector3(0.12, 0.10, 2.30),
			Vector3(screen_x, rail_y, -1.685), COL_CEILING)
	var panel_z: Array[float] = [-2.415, -1.685, -0.955]
	for i in panel_z.size():
		# Cloth occupies only the framed middle band; timber remains the dominant
		# read and open air above/below keeps this from becoming another slab wall.
		_trim_box(screen, "WoolDrop%d" % (i + 1), Vector3(0.028, 0.66, 0.54),
			Vector3(screen_x, 0.69, panel_z[i]), COL_SCREEN_CLOTH)
		_trim_box(screen, "WoolHem%d" % (i + 1), Vector3(0.038, 0.045, 0.56),
			Vector3(screen_x - 0.006, 1.02, panel_z[i]), COL_RUG_BORDER)


## Installed-family food and serving pieces plus fitted runners/place settings
## make the two guest tables read as used hospitality furniture. The earlier
## empty shipping crate on the east table looked like storage temporarily set
## down, not a meal; a real installed serving pot now gives that table a public-
## room verb. Everything here is visual-only, sits on the existing tables and
## never enters the clear x=0 route from doorway to counter.
func _build_common_room_occupation() -> void:
	var occupation := Node3D.new()
	occupation.name = "CommonRoomOccupation"
	add_child(occupation)
	_trim_box(occupation, "WestTableRunner", Vector3(0.54, 0.018, 3.15),
		Vector3(-1.5, 0.492, 1.5), COL_RUNNER_GREEN)
	_trim_box(occupation, "EastTableRunner", Vector3(0.54, 0.018, 3.15),
		Vector3(1.5, 0.492, 1.5), COL_RUNNER_RED)
	_visual_prop("GuestTableApples", TABLE_APPLES,
		Vector3(-1.5, 0.50, 1.28), 8.0, 0.58, occupation)
	_visual_prop("GuestTableServingPot", SERVING_POT,
		Vector3(1.5, 0.51, 1.52), -11.0, 0.58, occupation)
	_table_setting(occupation, "WestNear", Vector3(-1.5, 0.0, 2.48), -12.0)
	_table_setting(occupation, "WestFar", Vector3(-1.5, 0.0, 0.42), 8.0)
	_table_setting(occupation, "EastNear", Vector3(1.5, 0.0, 2.62), 10.0)
	_table_setting(occupation, "EastFar", Vector3(1.5, 0.0, 0.34), -7.0)


func _table_setting(parent: Node3D, node_name: String, at: Vector3,
		yaw_degrees: float) -> void:
	var setting := Node3D.new()
	setting.name = node_name
	setting.position = at
	setting.rotation.y = deg_to_rad(yaw_degrees)
	parent.add_child(setting)
	var variant := absi(node_name.hash()) % 3
	# Only the two occupied near seats carry a complete plate-and-tankard set.
	# The far positions become different shared-service beats, avoiding the four
	# identical white discs/cylinders that read like a staging checklist.
	if node_name == "WestNear" or node_name == "EastNear":
		var plate := MeshInstance3D.new()
		plate.name = "Plate"
		var plate_mesh := CylinderMesh.new()
		plate_mesh.top_radius = 0.105 + 0.008 * variant
		plate_mesh.bottom_radius = 0.115 + 0.008 * variant
		plate_mesh.height = 0.022
		plate_mesh.radial_segments = 18
		plate.mesh = plate_mesh
		plate.material_override = _material(COL_CROCKERY)
		plate.position = Vector3(0.0, 0.512, 0.0)
		setting.add_child(plate)
		var cup := MeshInstance3D.new()
		cup.name = "Tankard"
		var cup_mesh := CylinderMesh.new()
		cup_mesh.top_radius = 0.040 + 0.004 * (variant % 2)
		cup_mesh.bottom_radius = 0.044 + 0.004 * (variant % 2)
		cup_mesh.height = 0.12 + 0.012 * variant
		cup_mesh.radial_segments = 12
		cup.mesh = cup_mesh
		cup.material_override = _material(COL_PEWTER)
		cup.position = Vector3(0.17 + 0.025 * variant, 0.56, 0.03 - 0.025 * variant)
		setting.add_child(cup)
	if node_name == "WestNear":
		var snack := MeshInstance3D.new()
		snack.name = "BreadPortion"
		var snack_mesh := BoxMesh.new()
		snack_mesh.size = Vector3(0.12, 0.045, 0.075)
		snack.mesh = snack_mesh
		snack.material_override = _material(Color("#b8874f"))
		snack.position = Vector3(-0.02, 0.55, -0.01)
		snack.rotation.y = deg_to_rad(17.0)
		setting.add_child(snack)
	elif node_name == "WestFar":
		var bowl := MeshInstance3D.new()
		bowl.name = "SharedBowl"
		var bowl_mesh := CylinderMesh.new()
		bowl_mesh.top_radius = 0.115
		bowl_mesh.bottom_radius = 0.075
		bowl_mesh.height = 0.075
		bowl_mesh.radial_segments = 16
		bowl.mesh = bowl_mesh
		bowl.material_override = _material(Color("#6f4930"))
		bowl.position = Vector3(-0.06, 0.548, 0.02)
		setting.add_child(bowl)
	elif node_name == "EastFar":
		var board := MeshInstance3D.new()
		board.name = "BreadBoard"
		var board_mesh := BoxMesh.new()
		board_mesh.size = Vector3(0.34, 0.035, 0.18)
		board.mesh = board_mesh
		board.material_override = _wood_material(COL_COUNTER)
		board.position = Vector3(0.0, 0.53, 0.0)
		setting.add_child(board)
		for offset: float in [-0.09, 0.04, 0.12]:
			var loaf := MeshInstance3D.new()
			loaf.name = "Bread_%s" % str(offset)
			var loaf_mesh := BoxMesh.new()
			loaf_mesh.size = Vector3(0.095, 0.05, 0.065)
			loaf.mesh = loaf_mesh
			loaf.material_override = _material(Color("#b8874f"))
			loaf.position = Vector3(offset, 0.575, 0.0)
			loaf.rotation.y = offset * 1.7
			setting.add_child(loaf)


func _visual_prop(node_name: String, scene: PackedScene, at: Vector3,
		yaw_degrees: float, scale_factor: float, parent: Node3D) -> void:
	var prop := scene.instantiate() as Node3D
	prop.name = node_name
	prop.position = at
	prop.rotation.y = deg_to_rad(yaw_degrees)
	prop.scale = Vector3.ONE * scale_factor
	parent.add_child(prop)


## Three lamps — the counter, the guest area and the door end — the same
## reasoning shop_interior.gd/cottage_interior.gd already give theirs: the
## kit shell blocks the sun completely, and an unlit common room is a black
## doorway the player never walks into. R7.9 round 2 (blind visual-judge):
## the room read as flat ambient fill with nothing hinting the windows were
## the light source, so energy and range are both up from round 1 and a
## third fixture covers the long room's own door end, which two lights
## centred on the bar and the guest tables left dim by the doorway.
func _build_lights() -> void:
	var bar_light := OmniLight3D.new()
	bar_light.name = "BarLight"
	bar_light.position = Vector3(0.0, 2.3, COUNTER_Z + 1.0)
	# One restrained warm pool belongs at the bar. Keeping it short-range lets
	# the two cooler window/door fills below recover plaster, cloth and skin
	# colour instead of stacking three amber omnis into a red room-wide wash.
	bar_light.light_color = Color(1.0, 0.82, 0.62)
	bar_light.light_energy = 0.85
	bar_light.omni_range = 4.8
	bar_light.shadow_enabled = true
	add_child(bar_light)

	var room_light := OmniLight3D.new()
	room_light.name = "RoomLight"
	room_light.position = Vector3(0.0, 2.3, 1.5)
	room_light.light_color = Color(0.66, 0.84, 1.0)
	room_light.light_energy = 1.8
	room_light.omni_range = 7.5
	room_light.shadow_enabled = true
	add_child(room_light)

	var door_light := OmniLight3D.new()
	door_light.name = "DoorLight"
	door_light.position = Vector3(0.0, 2.3, 3.8)
	door_light.light_color = Color(0.74, 0.90, 1.0)
	door_light.light_energy = 1.25
	door_light.omni_range = 5.8
	door_light.shadow_enabled = false
	add_child(door_light)
	apply_interior_time("day")


func _process(_delta: float) -> void:
	# Capture tools instantiate the production world directly below SceneTree.root
	# without assigning current_scene. Climb to that world as a fallback so the
	# same authored day/night response is proven in both capture and gameplay.
	var scene: Node = get_tree().current_scene
	if scene == null:
		scene = self
		while scene.get_parent() != null and scene.get_parent() != get_tree().root:
			scene = scene.get_parent()
	var look := scene.get_node_or_null(^"WorldLook")
	if look == null or not look.has_method("time_of_day"):
		return
	var time_name := str(look.call("time_of_day"))
	if time_name != _last_interior_time:
		apply_interior_time(time_name)


## Interior practicals provide the night contrast that a sealed common room
## cannot receive from the world sun. Day keeps the existing cool window fill;
## night concentrates warm light at Bram and lets the doorway/table ends fall
## one step cooler and dimmer.
func apply_interior_time(time_name: String) -> void:
	_last_interior_time = time_name
	var is_night := time_name == "night"
	var bar := get_node_or_null(^"BarLight") as OmniLight3D
	var room := get_node_or_null(^"RoomLight") as OmniLight3D
	var door := get_node_or_null(^"DoorLight") as OmniLight3D
	if bar != null:
		bar.light_color = Color(1.0, 0.72, 0.43) if is_night else Color(1.0, 0.82, 0.62)
		bar.light_energy = 1.55 if is_night else 0.85
		bar.omni_range = 5.2 if is_night else 4.8
	if room != null:
		room.light_color = Color(0.92, 0.74, 0.54) if is_night else Color(0.66, 0.84, 1.0)
		room.light_energy = 0.72 if is_night else 1.8
	if door != null:
		door.light_color = Color(0.58, 0.68, 0.82) if is_night else Color(0.74, 0.90, 1.0)
		door.light_energy = 0.30 if is_night else 1.25
	for raw_glass: Node in find_children("LanternGlass*", "MeshInstance3D", true, false):
		var glass := raw_glass as MeshInstance3D
		var material := glass.material_override as StandardMaterial3D
		if material != null:
			material.emission = Color(1.0, 0.58, 0.25) if is_night else COL_LAMP_GLOW
			material.emission_energy_multiplier = 2.2 if is_night else 1.3


## Same loader `grandpa_house.gd::_furnish()` uses: an OBJ piece (the
## Furniture pack) loads as a bare Mesh at that pack's own native scale
## (hence `FURNITURE_SCALE`'s 0.5 correction); a glTF piece (the Fantasy
## Props MegaKit) loads as a real-metre scene and needs no correction. One
## simple full-AABB collider per piece, same as grandpa's own default —
## nothing here has a "lie down" story beat the way his bed does, so there is
## no reason for a shorter mattress-only collider.
func _furnish(model: String, at: Vector3, yaw_degrees: float,
		scale_factor := FURNITURE_SCALE, dir := FURNITURE_DIR) -> void:
	var obj_path := "%s/%s.obj" % [dir, model]
	var gltf_path := "%s/%s.gltf" % [dir, model]
	var node: Node3D
	var aabb: AABB
	if ResourceLoader.exists(obj_path):
		var mesh := MeshInstance3D.new()
		mesh.mesh = load(obj_path)
		aabb = (mesh.mesh as Mesh).get_aabb()
		node = mesh
	elif ResourceLoader.exists(gltf_path):
		node = (load(gltf_path) as PackedScene).instantiate() as Node3D
		var combined := AABB()
		var has := false
		for mi: MeshInstance3D in _mesh_instances(node):
			var xform := Transform3D.IDENTITY
			var walk: Node = mi
			while walk != null and walk != node:
				if walk is Node3D:
					xform = (walk as Node3D).transform * xform
				walk = walk.get_parent()
			var box := xform * mi.mesh.get_aabb()
			combined = combined.merge(box) if has else box
			has = true
		aabb = combined
	else:
		push_warning("inn furniture missing: %s" % obj_path)
		return
	node.position = at
	node.rotation.y = deg_to_rad(yaw_degrees)
	node.scale = Vector3.ONE * scale_factor
	add_child(node)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = aabb.size * scale_factor
	shape.shape = box_shape
	body.add_child(shape)
	body.position = at + Vector3(0, aabb.size.y * 0.5 * scale_factor, 0)
	body.rotation.y = deg_to_rad(yaw_degrees)
	add_child(body)


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


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


func _wood_box(size: Vector3, at: Vector3, colour: Color, solid := true) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _wood_material(colour)
	instance.position = at
	add_child(instance)
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


func _wood_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	# The medieval kit texture is an atlas; its upper 30% is the continuous
	# timber grain. Restrict primitive-box UVs to that band so counter/wainscot
	# depth gains the installed wood finish without leaking the atlas's stone row.
	material.albedo_color = colour.lightened(0.4)
	material.albedo_texture = WOOD_ALBEDO
	material.normal_enabled = true
	material.normal_texture = WOOD_NORMAL
	material.normal_scale = 0.55
	material.roughness_texture = WOOD_ROUGHNESS
	material.roughness = 0.82
	material.uv1_scale = Vector3(1.0, 0.30, 1.0)
	return material


## --- N05-WORLD-DRESSING-0905: the wall Bram stands in front of -----------------
##
## W08-DIALOGUE-CAMERA-0904's two blind-judge rounds, independently, on the
## real across-the-bar frame: "There is not one bottle, shelf, stool, tankard,
## barrel, sign or lamp in either frame", in a room whose own line says "beds
## are through the back, and I keep stock too." The conversation push-in that
## lane built parks the player's eye on the BACK wall for the length of every
## conversation with Bram, and until now that wall was bare plaster from the
## counter to the ceiling.
##
## Everything here is the installed prop family or a primitive the room already
## uses (`_box` is what the counter, rug and ceiling are made of) -- no new
## mesh, nothing generated. The furniture pack's Stool and Bookcase and the
## Fantasy kit's Barrel and Bucket are the same two packs `_furnish()` already
## loads; a tankard, a bottle and a lantern cage have no mesh in either pack and
## are a few cylinders and boxes each, which is what they are in the world too.
##
## Placement rules kept from the rest of this file: nothing enters the door
## lane (`DOOR_X` +/- half `DOOR_W`); nothing solid stands where Bram does
## (`bar_position()`, x 0 behind the counter) or in front of the counter's
## middle where the player talks to him; the shelves flank his stand rather
## than sit behind his head; and the lantern cages hang ABOVE the three lights
## `_build_lights()` already places, never around them -- two of those omnis
## cast shadows, and a shadow-casting light inside an opaque box lights nothing.
func _build_bar_dressing() -> void:
	var back := -INNER_HALF_D   # the back wall's inner face
	# Two pairs of wall shelves, one each side of Bram, bottles on every one.
	# JUDGE_DRESSING (blind, 2026-09-05): the west shelves ran into the stock
	# shelf's stile, so the west pair is shorter and stops 4 cm clear of it;
	# the east pair keeps its length. Uneven on purpose -- see `_bottle_row`.
	for side: float in [-1.0, 1.0]:
		var width := 1.1 if side < 0.0 else 1.5
		var x := -1.1 if side < 0.0 else 1.55
		for shelf_y: float in [1.5, 2.0]:
			_box(Vector3(width, 0.04, 0.28), Vector3(x, shelf_y, back + 0.14), COL_SHELF, false)
			_bottle_row(x, width, shelf_y + 0.02, back + 0.15, int(side) + (1 if shelf_y > 1.7 else 0))
	# The sign, centred over the bar and over Bram, on the wall behind him.
	_box(Vector3(1.4, 0.44, 0.05), Vector3(0.0, 2.42, back + 0.03), COL_SHELF, false)
	var label := Label3D.new()
	label.name = "InnSign"
	label.text = "ROOMS  -  ALE  -  STOCK"
	# JUDGE_DRESSING: at pixel_size 0.004 the text ran 1.8x the board's width
	# and the overhang sat at 1.2:1 against the plaster. Sized to the board
	# (1.4 m for ~23 glyphs), and painted dark so it reads ON the wood.
	label.font_size = 56
	label.pixel_size = 0.0021
	label.modulate = Color("#2e1f12")
	label.outline_size = 0
	label.position = Vector3(0.0, 2.42, back + 0.06)
	add_child(label)
	# Stock: a keg and a bucket at the east end of the counter, a tall empty
	# shelf unit at the west end, all behind the bar where Bram keeps it.
	_furnish("Barrel", Vector3(2.1, 0.08, -4.15), 0.0, 1.0, FANTASY_DIR)
	_furnish("Bucket_Wooden_1", Vector3(2.25, 0.08, -3.25), 35.0, 1.0, FANTASY_DIR)
	_furnish("Bookcase_Books", Vector3(-2.15, 0.08, -4.4), 0.0, FURNITURE_SCALE, FURNITURE_DIR)
	# On the counter: three tankards and a jug, on the top (y 1.0), toward the
	# guest side, clear of the middle where the player stands to talk.
	_tankard(Vector3(-1.15, 1.0, COUNTER_Z + 0.12))
	_tankard(Vector3(-0.92, 1.0, COUNTER_Z + 0.18))
	_tankard(Vector3(0.95, 1.0, COUNTER_Z + 0.14))
	_cylinder(0.09, 0.24, Vector3(1.22, 1.0, COUNTER_Z - 0.05), COL_JUG)
	# JUDGE_DRESSING: the three lantern cages hang above the conversation
	# camera's 40-degree frame, so the room read as having no light source at
	# all. A candle on the counter end puts one in the shot: a stub of wax and
	# a small glowing flame, no new light (the counter omni already lights it).
	_cylinder(0.035, 0.11, Vector3(-1.38, 1.0, COUNTER_Z - 0.1), Color("#e9dcc0"))
	var flame := MeshInstance3D.new()
	flame.name = "CandleFlame"
	var flame_box := BoxMesh.new()
	flame_box.size = Vector3(0.03, 0.06, 0.03)
	flame.mesh = flame_box
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.75, 0.35)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.7, 0.3)
	flame_mat.emission_energy_multiplier = 2.0
	flame.material_override = flame_mat
	flame.position = Vector3(-1.38, 1.14, COUNTER_Z - 0.1)
	add_child(flame)
	# Two bar stools on the guest side of the counter, either side of the
	# door lane. Native scale for a stool a person could sit at -- the pack's
	# 0.5 correction makes a 0.29 m footstool of it.
	_furnish("Stool", Vector3(-1.15, 0.08, COUNTER_Z + 0.78), 12.0, 1.0, FURNITURE_DIR)
	_furnish("Stool", Vector3(1.15, 0.08, COUNTER_Z + 0.78), -8.0, 1.0, FURNITURE_DIR)
	# A lantern cage over each of the room's three lights.
	_lantern(Vector3(0.0, 2.3, COUNTER_Z + 1.0))
	_lantern(Vector3(0.0, 2.3, 1.5))
	_lantern(Vector3(0.0, 2.3, 3.8))


## Bottles along a shelf as stock rather than as an array: the blind judge
## measured the first version's spacings at 77/42/75/41 px, "a strictly
## periodic pair repeated at fixed pitch, mirrored on the left shelf, repeated
## again on all four shelves". Each shelf now gets its own count, an uneven
## pitch from a small deterministic sequence (no RNG, so the room is the same
## on every load), three body heights, an empty stretch, and one bottle lying
## on its side.
func _bottle_row(shelf_x: float, width: float, base_y: float, z: float, seed_value: int) -> void:
	var offsets: Array[float] = [0.0, 0.17, 0.41, 0.52, 0.83, 1.0, 1.3]
	var heights: Array[float] = [0.24, 0.19, 0.27, 0.21, 0.24, 0.18]
	var count := 4 + (absi(seed_value) % 3)   # 4..6 on a shelf
	var start := shelf_x - width * 0.5 + 0.1
	var usable := width - 0.2
	for i in count:
		var t: float = offsets[(i + seed_value) % offsets.size()] / 1.3
		var x := start + usable * (float(i) / float(count) * 0.55 + t * 0.45)
		x = clampf(x, start, start + usable)
		var body_h: float = heights[(i * 2 + seed_value) % heights.size()]
		var colour := COL_GLASS_GREEN if (i + seed_value) % 3 != 1 else COL_GLASS_AMBER
		if i == count - 1 and seed_value % 2 == 0:
			# One on its side, along the shelf.
			var lying := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.045
			cyl.bottom_radius = 0.045
			cyl.height = body_h
			cyl.radial_segments = 12
			lying.mesh = cyl
			lying.material_override = _material(colour)
			lying.position = Vector3(x, base_y + 0.045, z)
			lying.rotation.z = PI * 0.5
			add_child(lying)
			continue
		_cylinder(0.045, body_h, Vector3(x, base_y, z), colour)
		_cylinder(0.018, 0.08, Vector3(x, base_y + body_h, z), colour)


## A pewter tankard: a cup and a handle.
func _tankard(at: Vector3) -> void:
	_cylinder(0.055, 0.15, at, COL_PEWTER)
	_box(Vector3(0.025, 0.09, 0.03), at + Vector3(0.07, 0.08, 0.0), COL_PEWTER, false)


## A lantern cage hung from the ceiling over one of the room's lights: chain,
## cap, base ring, four corner posts and the glowing glass between them. The
## cage's bottom sits 0.2 m ABOVE the light it belongs to, so the omni itself
## stays outside anything opaque (see `_build_bar_dressing`'s header).
func _lantern(light_at: Vector3) -> void:
	var glass_y := light_at.y + 0.36
	var cap_y := glass_y + 0.15
	var base_y := glass_y - 0.14
	var ceiling := 3.0   # the ceiling slab's underside (see `_build_ceiling`)
	_box(Vector3(0.03, ceiling - cap_y, 0.03), Vector3(light_at.x, (ceiling + cap_y) * 0.5, light_at.z), COL_IRON, false)
	_box(Vector3(0.26, 0.04, 0.26), Vector3(light_at.x, cap_y, light_at.z), COL_IRON, false)
	_box(Vector3(0.26, 0.03, 0.26), Vector3(light_at.x, base_y, light_at.z), COL_IRON, false)
	for cx: float in [-0.115, 0.115]:
		for cz: float in [-0.115, 0.115]:
			_box(Vector3(0.025, cap_y - base_y, 0.025),
				Vector3(light_at.x + cx, glass_y, light_at.z + cz), COL_IRON, false)
	var glass := MeshInstance3D.new()
	glass.name = "LanternGlass"
	var box := BoxMesh.new()
	box.size = Vector3(0.17, 0.24, 0.17)
	glass.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = COL_LAMP_GLOW
	material.emission_enabled = true
	material.emission = COL_LAMP_GLOW
	material.emission_energy_multiplier = 1.3
	glass.material_override = material
	glass.position = Vector3(light_at.x, glass_y, light_at.z)
	add_child(glass)


## A vertical cylinder standing on `base` (its own bottom at `base.y`).
## Decoration only: nothing here is solid.
func _cylinder(radius: float, height: float, base: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 12
	mesh.mesh = cylinder
	mesh.material_override = _material(colour)
	mesh.position = base + Vector3(0.0, height * 0.5, 0.0)
	add_child(mesh)
