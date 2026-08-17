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

const COL_FLOOR := Color("#6b4f30")
const COL_COUNTER := Color("#8a6a3f")
const COL_TABLE := Color("#5a4030")
const COL_BENCH := Color("#4a3626")
const COL_BED := Color("#5a4030")
const COL_RUG := Color("#7a4a35")


## `_room` unused, same reason shop_interior.gd's own `build()` ignores it —
## this interior is Bram's and keeps its own hardcoded footprint. Signature
## matches the other two templates so village.gd can dispatch any of the
## three through the same `interior.call("build", room)`.
func build(_room: Dictionary = {}) -> void:
	_build_floor()
	_build_counter()
	_build_guest_table(-1.5, 1.5)
	_build_guest_table(1.5, 1.5)
	_build_bed_nook(1.6, -1.5)
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


## Spans the back wall, centred — 3.2m wide inside a 5.38m-wide room, so both
## ends stay clear of the side walls with margin to spare. Bram stands in the
## 0.7m gap behind it (`bar_position()`), guests approach from the front.
func _build_counter() -> void:
	_box(Vector3(3.2, 1.0, 0.6), Vector3(0.0, 0.5, COUNTER_Z), COL_COUNTER)


## One table with two benches (fore and aft, not flanking — the room is far
## deeper than it is wide, so clearance comes from z, not x). `x` must clear
## the door lane (`DOOR_X` +/- half `DOOR_W`) by at least the table's own
## half-width; both calls below sit at |x|=1.5, half a metre outside the
## 0.8m lane edge.
func _build_guest_table(x: float, z: float) -> void:
	_box(Vector3(1.0, 0.75, 0.7), Vector3(x, 0.375, z), COL_TABLE)
	_box(Vector3(1.0, 0.45, 0.3), Vector3(x, 0.225, z - 0.55), COL_BENCH)
	_box(Vector3(1.0, 0.45, 0.3), Vector3(x, 0.225, z + 0.55), COL_BENCH)


## The one guest bed, east side, well clear (3m in z) of the guest table on
## the same side so a generous bed footprint can never reach into the
## table's own space — the same overlap `cottage_interior.gd`'s own header
## warns a `clampf` bug produced once already. Also 2m+ clear of the counter
## in z, so nothing here reaches into Bram's own space either.
func _build_bed_nook(x: float, z: float) -> void:
	_box(Vector3(1.3, 0.5, 0.9), Vector3(x, 0.25, z), COL_BED)
	_box(Vector3(0.6, 0.45, 0.5), Vector3(x, 0.225, z - 0.8), COL_BED, false)


func _build_rug() -> void:
	_box(Vector3(1.6, 0.02, 1.4), Vector3(0.0, 0.13, COUNTER_Z + 1.6), COL_RUG, false)


## Two lamps — the counter and the guest area — the same reasoning
## shop_interior.gd/cottage_interior.gd already give theirs: the kit shell
## blocks the sun completely, and an unlit common room is a black doorway
## the player never walks into.
func _build_lights() -> void:
	var bar_light := OmniLight3D.new()
	bar_light.name = "BarLight"
	bar_light.position = Vector3(0.0, 2.3, COUNTER_Z + 1.0)
	bar_light.light_color = Color(1.0, 0.88, 0.7)
	bar_light.light_energy = 2.6
	bar_light.omni_range = 7.0
	bar_light.shadow_enabled = true
	add_child(bar_light)

	var room_light := OmniLight3D.new()
	room_light.name = "RoomLight"
	room_light.position = Vector3(0.0, 2.3, 1.5)
	room_light.light_color = Color(1.0, 0.88, 0.7)
	room_light.light_energy = 2.4
	room_light.omni_range = 7.0
	room_light.shadow_enabled = true
	add_child(room_light)


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
