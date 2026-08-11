extends Node3D

## Grandpa's farmhouse: the building the opening now wakes up inside.
##
## Built in code at runtime, the same reasoning as the terrain and the
## vegetation: a hand-authored .tscn of forty wall segments is unreadable and
## unmergeable, and this is ONE authored building whose dimensions are its
## design. The flat material look deliberately matches the Quaternius packs
## (docs/ASSET_LEDGER.md) so the hand-built shell and the sourced furniture
## read as one hand.
##
## The room sizes are camera-driven, not fiction-driven: the interior camera
## profile keeps the spring arm at ~2.4m, and rooms under ~6m across put the
## arm inside a wall on every turn. Ground floor 9x7m inside, 3.2m ceiling;
## bedroom loft above, 3.0m to the ridge; a straight stair against the north
## wall; a 2.0m doorway on the east wall facing the village square, left as an
## opening (the door leaf stands open against the wall — a closed door needs
## an opening animation the slice does not).
##
## What the sequence director needs from the house it reads from MARKERS
## (`marker("bed")`, `marker("grandpa")`, `marker("door")`) rather than from
## coordinates in opening.json — the building is the authority on where its
## own bed is. opening.json keeps fallback positions for a world without a
## house.
##
## The camera swap is the house's own job: an Area3D spanning the interior
## applies the `interior` camera profile on entry and hands back the default
## on exit, through the same `set_target(target, profile)` seam the aim
## camera uses.

const FURNITURE_DIR := "res://assets/props/quaternius_furniture"
## Quaternius furniture is authored at roughly 2x real scale (a 4.26m bed).
const FURNITURE_SCALE := 0.5
## Surface clutter (R7.2): the survival pack's gear, borrowed for a backpack,
## an axe and a knife rather than a second furniture generation pass.
const SURVIVAL_DIR := "res://assets/props/quaternius_survival"

## Interior camera, tunable in spirit but authored here with the building it
## belongs to: the room is the constraint, not the player's taste.
const INTERIOR_PROFILE := {
	"distance": 2.4,
	"height": 1.5,
	"fov": 65.0,
	"pitch_min_deg": -40.0,
	"pitch_max_deg": 25.0,
	"retarget_lag": 10.0,
}

# Interior dimensions, metres. Origin is the house CENTRE at floor level.
const INNER_W := 9.0     # x
const INNER_D := 7.0     # z
const WALL_T := 0.3
const FLOOR_H := 3.2     # ground-floor ceiling height
const LOFT_H := 2.9      # loft floor to ridge
const DOOR_W := 2.0
const DOOR_H := 2.6
## The loft covers the west half; the east half is open to the ridge so the
## stair has headroom and the ground floor gets height over the door.
const LOFT_W := 4.6

const COL_TIMBER := Color("#402e2b")
const COL_PLASTER := Color("#e6ddc8")
const COL_FLOOR := Color("#7a5a35")
const COL_ROOF := Color("#4a3f3a")

var _markers: Dictionary = {}
var _camera_rig: Node = null
var _player: Node3D = null


func marker(name_key: String) -> Vector3:
	return _markers.get(name_key, global_position)


## The world root calls this once terrain is solid; everything is positioned
## relative to this node, so standing the node on the pad stands the house.
func build(camera_rig: Node, player: Node3D) -> void:
	_camera_rig = camera_rig
	_player = player
	_build_shell()
	_build_stairs()
	_build_furniture()
	_build_lights()
	_build_interior_area()

	_markers["bed"] = to_global(Vector3(-INNER_W * 0.5 + 1.3, FLOOR_H + 0.55, -INNER_D * 0.5 + 1.6))
	_markers["grandpa"] = to_global(Vector3(-2.4, 0.0, 1.2))
	_markers["door"] = to_global(Vector3(INNER_W * 0.5 + WALL_T + 1.2, 0.0, 0.6))
	# Far enough out that the starter row (which stands `forward` metres from
	# this point TOWARD the door) clears the east wall with room to walk around.
	_markers["outside"] = to_global(Vector3(INNER_W * 0.5 + WALL_T + 7.5, 0.0, 1.0))
	# The stair line, for anything that has to NAVIGATE the house rather than
	# teleport through it — the smoke test walks these as waypoints.
	_markers["stairs_top"] = to_global(Vector3(0.5, FLOOR_H, -INNER_D * 0.5 + 0.6))
	_markers["stairs_bottom"] = to_global(Vector3(4.0, 0.12, -INNER_D * 0.5 + 0.6))


func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.9
	return m


## A textured box with matching collision, positioned by its centre.
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


func _build_shell() -> void:
	var half_w := INNER_W * 0.5
	var half_d := INNER_D * 0.5

	# Ground slab, proud of the terrain so the doorway has a step.
	_box(Vector3(INNER_W + WALL_T * 2, 0.3, INNER_D + WALL_T * 2),
		Vector3(0, -0.15 + 0.12, 0), COL_FLOOR)

	# West wall (solid), and the north/south walls.
	_box(Vector3(WALL_T, FLOOR_H + LOFT_H, INNER_D + WALL_T * 2),
		Vector3(-half_w - WALL_T * 0.5, (FLOOR_H + LOFT_H) * 0.5, 0), COL_PLASTER)
	_box(Vector3(INNER_W + WALL_T * 2, FLOOR_H + LOFT_H, WALL_T),
		Vector3(0, (FLOOR_H + LOFT_H) * 0.5, -half_d - WALL_T * 0.5), COL_PLASTER)
	_box(Vector3(INNER_W + WALL_T * 2, FLOOR_H + LOFT_H, WALL_T),
		Vector3(0, (FLOOR_H + LOFT_H) * 0.5, half_d + WALL_T * 0.5), COL_PLASTER)

	# East wall, in three pieces around the doorway (door sits toward +z end).
	var door_centre_z := 0.6
	var south_len := (half_d - (door_centre_z + DOOR_W * 0.5))
	var north_len := (door_centre_z - DOOR_W * 0.5) + half_d
	_box(Vector3(WALL_T, FLOOR_H + LOFT_H, north_len),
		Vector3(half_w + WALL_T * 0.5, (FLOOR_H + LOFT_H) * 0.5, -half_d + north_len * 0.5), COL_PLASTER)
	_box(Vector3(WALL_T, FLOOR_H + LOFT_H, south_len),
		Vector3(half_w + WALL_T * 0.5, (FLOOR_H + LOFT_H) * 0.5, half_d - south_len * 0.5), COL_PLASTER)
	# Lintel over the door.
	_box(Vector3(WALL_T, FLOOR_H + LOFT_H - DOOR_H, DOOR_W),
		Vector3(half_w + WALL_T * 0.5, DOOR_H + (FLOOR_H + LOFT_H - DOOR_H) * 0.5, door_centre_z), COL_TIMBER)

	# Loft floor over the west half; timber edge beam where it ends — south of
	# the stair opening only. The beam's top sits proud of the loft floor, and
	# a CharacterBody3D cannot step UP a ledge: run it across the stair head
	# and the loft is a cell. (Found by the smoke test, frozen at the top step.)
	_box(Vector3(LOFT_W, 0.25, INNER_D),
		Vector3(-half_w + LOFT_W * 0.5, FLOOR_H + 0.125, 0), COL_FLOOR)
	_box(Vector3(0.25, 0.4, 4.2),
		Vector3(-half_w + LOFT_W, FLOOR_H + 0.2, 1.4), COL_TIMBER)
	# Loft rail so the drop reads intentional — over the SOUTH stretch only.
	# The first cut of this rail ran the whole loft edge and fenced the stairs
	# off; the smoke test found the player pacing the loft forever.
	_box(Vector3(0.12, 0.9, 4.2),
		Vector3(-half_w + LOFT_W - 0.06, FLOOR_H + 0.25 + 0.45, 1.4), COL_TIMBER)

	# Flat timber roof, above the ridge height. A gable is a texture problem
	# for another day; from inside it reads as a ceiling, from outside the
	# farm-pack barns carry the silhouette for the whole village.
	_box(Vector3(INNER_W + WALL_T * 2 + 1.2, 0.3, INNER_D + WALL_T * 2 + 1.2),
		Vector3(0, FLOOR_H + LOFT_H + 0.15, 0), COL_ROOF)


func _build_stairs() -> void:
	# Straight run against the north wall, climbing westward to the loft edge.
	var steps := 10
	var run_length := 3.4
	var step_rise := FLOOR_H / float(steps)
	var step_depth := run_length / float(steps)
	var start_x := -INNER_W * 0.5 + LOFT_W + run_length
	for i in steps:
		var x := start_x - (float(i) + 0.5) * step_depth
		_box(Vector3(step_depth + 0.02, step_rise * (i + 1), 1.2),
			Vector3(x, step_rise * (i + 1) * 0.5, -INNER_D * 0.5 + 0.6), COL_FLOOR)


func _furnish(model: String, at: Vector3, yaw_degrees: float, scale_factor := FURNITURE_SCALE,
		dir := FURNITURE_DIR, solid := true) -> void:
	var path := "%s/%s.obj" % [dir, model]
	if not ResourceLoader.exists(path):
		push_warning("house furniture missing: %s" % path)
		return
	var mesh := MeshInstance3D.new()
	mesh.mesh = load(path)
	mesh.position = at
	mesh.rotation.y = deg_to_rad(yaw_degrees)
	mesh.scale = Vector3.ONE * scale_factor
	add_child(mesh)
	if not solid:
		return
	# One simple blocker per piece: walking through a table breaks the room
	# harder than an approximate box breaks pathing.
	var aabb := (mesh.mesh as Mesh).get_aabb()
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_factor
	shape.shape = box
	body.add_child(shape)
	body.position = at + Vector3(0, aabb.size.y * 0.5 * scale_factor, 0)
	body.rotation.y = deg_to_rad(yaw_degrees)
	add_child(body)


## Clutter, through the same loader with a friendlier name at the call site:
## `solid` defaults false here rather than true, because the point of surface
## dressing — a knife, a backpack — is that nobody should ever be stopped by it.
func _clutter(model: String, at: Vector3, yaw_degrees: float, solid := false,
		dir := SURVIVAL_DIR, scale_factor := FURNITURE_SCALE) -> void:
	_furnish(model, at, yaw_degrees, scale_factor, dir, solid)


func _build_furniture() -> void:
	var half_w := INNER_W * 0.5
	var half_d := INNER_D * 0.5
	# Downstairs: his life, arranged for one person and a visitor — and OFF the
	# two lanes the opening actually walks: stairs-foot to Grandpa, and Grandpa
	# to the door. The smoke test walks those lanes blind; a stool in one reads
	# as "the opening is stuck".
	_furnish("Table", Vector3(0.4, 0.12, -0.9), 90.0)
	_furnish("Chair", Vector3(-0.6, 0.12, -0.9), 90.0)
	_furnish("Stool", Vector3(1.3, 0.12, -1.3), 0.0)
	_furnish("Bookcase_Books", Vector3(-half_w + 0.45, 0.12, half_d - 0.6), 180.0)
	_furnish("Desk", Vector3(1.8, 0.12, half_d - 0.55), 180.0)
	_furnish("ShortCloset", Vector3(half_w - 0.6, 0.12, -half_d + 0.7), -90.0)
	# The loft: the player's bed under the west eave, the nightstand at its
	# foot, both clear of the lane from the bed to the stair head.
	_furnish("BedTwin", Vector3(-half_w + 1.3, FLOOR_H + 0.25, -half_d + 1.9), 0.0)
	_furnish("NightStand", Vector3(-half_w + 0.55, FLOOR_H + 0.25, 0.6), 0.0)

	# Past-minimum dressing (R7.2): both reviews called this room an undressed
	# grey box. Everything below is either non-solid (a rug or a knife on a
	# shelf never blocks a CharacterBody3D) or checked with a headless probe
	# against every walked lane in this house — stairs-foot to Grandpa,
	# Grandpa to the door, and bed to stairs-head, the three lines
	# tests/smoke_opening.gd and a real player both actually cross.
	_build_rugs()
	# Grandpa's own bed, in the empty south-west corner ground floor never
	# used — well clear of both lanes (x < -2.4 puts it entirely off the
	# stairs-to-Grandpa segment) and of the loft bed directly above it.
	# Nothing in this room previously gave a man who has lived here for
	# decades anywhere to sleep.
	_furnish("BedDouble", Vector3(-half_w + 1.2, 0.12, -1.3), 0.0)
	# The alternate bookcase, doubled up rather than swapped in: one shelf
	# reads as furniture, two read as a life spent collecting books.
	_furnish("Bookcase", Vector3(-half_w + 0.45, 0.12, half_d - 2.2), 180.0)
	# A second table by the door, carrying the pack his own dialogue describes
	# ("that pack by the door carried me thirty years" — data/dialogue/
	# opening.json's grandpa_house line), given somewhere to actually sit.
	_furnish("Table2", Vector3(half_w - 1.0, 0.12, 2.6), 180.0)
	_clutter("Backpack", Vector3(half_w - 1.3, 0.12, 2.3), 30.0)
	_clutter("Axe", Vector3(half_w - 0.55, 0.12, 2.9), -20.0)
	_clutter("Knife", Vector3(half_w - 0.9, 0.12, 2.75), 10.0)
	# A spare door leaning in the corner. Deliberately clutter, not a second
	# functional doorway: the shell's own east opening stays open (this file's
	# header explains why — a closed door needs an opening animation the slice
	# does not have), so this reads as a door somebody took off its hinges once
	# and never got round to rehanging.
	_furnish("Door1", Vector3(-half_w + 0.4, 0.12, -0.3), 90.0, FURNITURE_SCALE, FURNITURE_DIR, false)


## `_box()`'s own comment gives the house its rug shorthand: a flat coloured
## box at floor height. Never solid — see `_clutter`'s reasoning, which
## applies here too.
func _build_rugs() -> void:
	var half_w := INNER_W * 0.5
	var half_d := INNER_D * 0.5
	# Under the table/chair/stool cluster, short of both the stair footprint
	# and the two named lanes' actual walked width.
	_box(Vector3(3.0, 0.02, 2.0), Vector3(0.5, 0.13, -0.8), Color("#8a4a35"), false)
	# An entry mat by the new gear table, east side near the door.
	_box(Vector3(1.8, 0.02, 2.0), Vector3(half_w - 1.1, 0.13, 2.2), Color("#5c4a34"), false)


func _build_lights() -> void:
	# Warm interior light; the shell blocks the sun entirely.
	for at: Vector3 in [Vector3(0, 2.6, 0), Vector3(-2.5, FLOOR_H + 2.0, -1.0)]:
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color(1.0, 0.88, 0.7)
		light.light_energy = 2.4
		light.omni_range = 9.0
		light.shadow_enabled = true
		add_child(light)


func _build_interior_area() -> void:
	var area := Area3D.new()
	area.name = "Interior"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(INNER_W, FLOOR_H + LOFT_H, INNER_D)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0, (FLOOR_H + LOFT_H) * 0.5, 0)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)


func _on_body_entered(body: Node3D) -> void:
	if body != _player or _camera_rig == null:
		return
	# Only take the camera if it is on the PLAYER — a fight or an aim owns it
	# otherwise, and neither can happen indoors today; the guard is for the day
	# one can.
	_camera_rig.call("set_target", _player, INTERIOR_PROFILE)


func _on_body_exited(body: Node3D) -> void:
	if body != _player or _camera_rig == null:
		return
	_camera_rig.call("set_target", _player, {})
