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

const COL_FLOOR := Color("#6b4f30")
const COL_COUNTER := Color("#8a6a3f")
const COL_CEILING := Color("#4a3626")
const COL_RUG := Color("#7a4a35")


## `_room` unused, same reason shop_interior.gd's own `build()` ignores it —
## this interior is Bram's and keeps its own hardcoded footprint. Signature
## matches the other two templates so village.gd can dispatch any of the
## three through the same `interior.call("build", room)`.
func build(_room: Dictionary = {}) -> void:
	_build_floor()
	_build_ceiling()
	_build_counter()
	_build_counter_dressing()
	_build_guest_area(-1.5, 1.5)
	_build_guest_area(1.5, 1.5)
	_build_bed_nook(1.7, -1.7)
	_build_rug()
	_build_lights()


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


## Spans the back wall, centred — 3.2m wide inside a 5.38m-wide room, so both
## ends stay clear of the side walls with margin to spare. Bram stands in the
## 0.7m gap behind it (`bar_position()`), guests approach from the front.
func _build_counter() -> void:
	_box(Vector3(3.2, 1.0, 0.6), Vector3(0.0, 0.5, COUNTER_Z), COL_COUNTER)


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
	bar_light.light_color = Color(1.0, 0.88, 0.7)
	bar_light.light_energy = 3.2
	bar_light.omni_range = 8.0
	bar_light.shadow_enabled = true
	add_child(bar_light)

	var room_light := OmniLight3D.new()
	room_light.name = "RoomLight"
	room_light.position = Vector3(0.0, 2.3, 1.5)
	room_light.light_color = Color(1.0, 0.88, 0.7)
	room_light.light_energy = 3.0
	room_light.omni_range = 8.0
	room_light.shadow_enabled = true
	add_child(room_light)

	var door_light := OmniLight3D.new()
	door_light.name = "DoorLight"
	door_light.position = Vector3(0.0, 2.3, 3.8)
	door_light.light_color = Color(1.0, 0.9, 0.75)
	door_light.light_energy = 2.4
	door_light.omni_range = 6.0
	door_light.shadow_enabled = false
	add_child(door_light)


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


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material
