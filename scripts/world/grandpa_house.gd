extends Node3D

## Grandpa's farmhouse: the building the opening wakes up inside.
##
## EV6 follow-up. The first EV6 pass kept this house as a primitive-box shell
## and reskinned it onto the kit's texture sheets; a genuinely blind critic
## still split the settlement in two over it — "smooth stucco walls...
## vertical pinstripe quoining... small flat punched windows, a
## shallow-pitched dull brick-red flat-tile roof, no exposed structural
## timber anywhere... reads as an asset from a different pack." A texture is
## not a construction language. So the EXTERIOR is now composed from the
## same Medieval Village MegaKit modules as every other building in the
## square (data/config/building_prefabs.json, prefab `farmhouse_shell`,
## assembled by scripts/world/building_prefabs.gd): uneven-brick ground
## course, plaster/timber-grid upper course, the kit's lattice windows and
## shutters, brick gable fronts, and the settlement's one round-tile roof at
## the kit's own pitch. Two storeys — the big sibling that bridges cottage_b
## (stone) and cottage_a (plaster and timber).
##
## What stays in code is everything the OPENING choreography owns: floor,
## loft, stairs, furniture, lights, markers, the interior camera area and
## the door gate — plus all collision, because the door opening and the
## enterable interior need collision the placer's AABB fallback would get
## wrong. The kit dictates the footprint now: its roof family spans 4m or 6m
## walls only, so the house is 10m x 6m outside (the old 9x7 interior
## becomes ~9.4 x ~5.4). Rooms narrower than ~6m squeeze the interior
## camera, so the spring arm shortens a step below (the room is the
## constraint, not the player's taste).
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

const PREFABS := preload("res://scripts/world/building_prefabs.gd")

const FURNITURE_DIR := "res://assets/props/quaternius_furniture"
## Quaternius furniture is authored at roughly 2x real scale (a 4.26m bed).
const FURNITURE_SCALE := 0.5
## Surface clutter (R7.2): the survival pack's gear, borrowed for a backpack,
## an axe and a knife rather than a second furniture generation pass.
const SURVIVAL_DIR := "res://assets/props/quaternius_survival"

## Interior camera, tunable in spirit but authored here with the building it
## belongs to: the room is the constraint, not the player's taste. Distance
## dropped 2.4 -> 2.1 with the kit rebuild: the kit roof family fixes the
## room at ~5.4m across, and the old arm clipped the walls on every turn.
const INTERIOR_PROFILE := {
	"distance": 2.1,
	"height": 1.5,
	"fov": 65.0,
	"pitch_min_deg": -40.0,
	"pitch_max_deg": 25.0,
	"retarget_lag": 10.0,
}

# Interior dimensions, metres. Origin is the house CENTRE at floor level.
# These are READ from the kit now, not chosen: exterior wall lines sit on the
# kit's 2m grid at x=+-5 / z=+-3 (10m x 6m, the span Roof_RoundTiles_6x10
# covers), wall modules put their inner faces ~0.31m inside the line, and the
# interior is what is left. FLOOR_H is the kit wall-course height, 3.12,
# rounded up a step the stairs already climbed before the rebuild.
const INNER_W := 9.4     # x
const INNER_D := 5.4     # z
const WALL_T := 0.4      # kit wall body thickness, for colliders and markers
const EXT_HALF_W := 5.0  # exterior wall line, x
const EXT_HALF_D := 3.0  # exterior wall line, z
const FLOOR_H := 3.2     # ground-floor ceiling height
const LOFT_H := 2.9      # loft floor to the flat interior ceiling
## Kit door: DoorFrame_Flat_WoodDark measures a 2.3m-tall, ~1.6m-clear
## opening, centred in its 2m module — which the kit grid puts at z=0.
const DOOR_W := 1.6
const DOOR_H := 2.3
## The loft covers the west half; the east half is open to the ceiling so the
## stair has headroom and the ground floor gets height over the door.
const LOFT_W := 4.6

const COL_TIMBER := Color("#5a4030")
const COL_FLOOR := Color("#7a5a35")

## The old reskin table is gone with the primitive shell it painted — walls,
## roof and windows are real kit modules now, and the few primitives left
## (floors, stairs, the loft beam and rail) stay FLAT colour. T_WoodTrim is
## a trim ATLAS: across the 4.2m loft beam it sampled its pale plaster
## patches and rendered the beam as a blue-grey band in the interior frame,
## the same defect class as the round-2 circus-stripe floor.
const KIT_TEX_DIR := "res://assets/buildings/quaternius_medieval"
const KIT_TEX_SCALE := 0.5
const KIT_TEXTURES := {}

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
	_build_kit_shell()
	_build_shell()
	_build_stairs()
	_build_furniture()
	_build_lights()
	_build_interior_area()
	_build_door_gate()

	_markers["bed"] = to_global(Vector3(-INNER_W * 0.5 + 1.3, FLOOR_H + 0.55, -INNER_D * 0.5 + 1.6))
	_markers["grandpa"] = to_global(Vector3(-2.4, 0.0, 1.2))
	# The kit grid centres the doorway on z=0 (it was 0.6 in the hand-built
	# shell); everything that walks to the door reads it from here.
	_markers["door"] = to_global(Vector3(INNER_W * 0.5 + WALL_T + 1.2, 0.0, 0.0))
	# Far enough out that the starter row (which stands `forward` metres from
	# this point TOWARD the door) clears the east wall with room to walk around.
	_markers["outside"] = to_global(Vector3(INNER_W * 0.5 + WALL_T + 7.5, 0.0, 1.0))
	# The stair line, for anything that has to NAVIGATE the house rather than
	# teleport through it — the smoke test walks these as waypoints.
	_markers["stairs_top"] = to_global(Vector3(0.5, FLOOR_H, -INNER_D * 0.5 + 0.6))
	_markers["stairs_bottom"] = to_global(Vector3(4.0, 0.12, -INNER_D * 0.5 + 0.6))


## The exterior: one kit prefab, same composer, same recipes file, same
## module family as the workshop, the cottages and the well. The recipe is
## authored front = +z per the file's convention; the yaw turns that front
## gable — door, shuttered window, window over the door — toward the village
## square east of the house.
func _build_kit_shell() -> void:
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the farmhouse has no shell")
		return
	var shell: Node3D = prefabs.call("instantiate", "farmhouse_shell")
	if shell == null:
		return
	shell.name = "KitShell"
	shell.rotation.y = deg_to_rad(90.0)
	add_child(shell)


var _materials: Dictionary = {}


func _material(colour: Color) -> StandardMaterial3D:
	if _materials.has(colour):
		return _materials[colour]
	var m := StandardMaterial3D.new()
	m.roughness = 0.9
	if KIT_TEXTURES.has(colour):
		var entry: Dictionary = KIT_TEXTURES[colour]
		var tex: Texture2D = load("%s/%s.png" % [KIT_TEX_DIR, str(entry["tex"])])
		if tex != null:
			m.albedo_texture = tex
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE * KIT_TEX_SCALE
			m.albedo_color = colour.lerp(Color.WHITE, float(entry["lift"]))
		else:
			m.albedo_color = colour
	else:
		m.albedo_color = colour
	_materials[colour] = m
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
		_collider(size, at)


## An invisible collision box — the kit shell carries the visuals, the house
## carries the physics, because the recipe deliberately authors no colliders
## (see farmhouse_shell's _why).
func _collider(size: Vector3, at: Vector3) -> void:
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
	var wall_h := 6.24  # two kit wall courses of 3.12
	# Wall collider boxes sit on the kit wall lines, mid-body: modules put
	# their mass from ~0.31 inside the line to ~0.09 outside it.
	var wall_mid_x := EXT_HALF_W - 0.11
	var wall_mid_z := EXT_HALF_D - 0.11

	# Ground slab, proud of the terrain so the doorway has a step. Runs under
	# the kit walls so no grass shows at the skirting from inside.
	_box(Vector3(INNER_W + 0.8, 0.3, INNER_D + 0.8),
		Vector3(0, -0.15 + 0.12, 0), COL_FLOOR)

	# Wall collision: west solid, north/south solid, east in three pieces
	# around the kit doorway (opening DOOR_W wide, centred z=0).
	_collider(Vector3(0.45, wall_h, INNER_D + 1.0),
		Vector3(-wall_mid_x, wall_h * 0.5, 0))
	_collider(Vector3(INNER_W + 1.0, wall_h, 0.45),
		Vector3(0, wall_h * 0.5, -wall_mid_z))
	_collider(Vector3(INNER_W + 1.0, wall_h, 0.45),
		Vector3(0, wall_h * 0.5, wall_mid_z))
	var flank := (EXT_HALF_D + 0.1) - DOOR_W * 0.5
	_collider(Vector3(0.45, wall_h, flank),
		Vector3(wall_mid_x, wall_h * 0.5, -(DOOR_W * 0.5 + flank * 0.5)))
	_collider(Vector3(0.45, wall_h, flank),
		Vector3(wall_mid_x, wall_h * 0.5, DOOR_W * 0.5 + flank * 0.5))
	_collider(Vector3(0.45, wall_h - DOOR_H, DOOR_W),
		Vector3(wall_mid_x, DOOR_H + (wall_h - DOOR_H) * 0.5, 0))

	# Loft floor over the west half; timber edge beam where it ends — south of
	# the stair opening only. The beam's top sits proud of the loft floor, and
	# a CharacterBody3D cannot step UP a ledge: run it across the stair head
	# and the loft is a cell. (Found by the smoke test, frozen at the top step.)
	_box(Vector3(LOFT_W, 0.25, INNER_D),
		Vector3(-half_w + LOFT_W * 0.5, FLOOR_H + 0.125, 0), COL_FLOOR)
	_box(Vector3(0.25, 0.4, 4.2),
		Vector3(-half_w + LOFT_W, FLOOR_H + 0.2, 0.6), COL_TIMBER)
	# Loft rail so the drop reads intentional — over the SOUTH stretch only.
	# The first cut of this rail ran the whole loft edge and fenced the stairs
	# off; the smoke test found the player pacing the loft forever.
	_box(Vector3(0.12, 0.9, 4.2),
		Vector3(-half_w + LOFT_W - 0.06, FLOOR_H + 0.25 + 0.45, 0.6), COL_TIMBER)

	# Flat interior ceiling under the kit roof. Solid so neither the player
	# nor the camera ends up inside the roof shell. COL_FLOOR, not tiles: a
	# bedroom ceiling wearing terracotta was the first thing the EV6 round-1
	# interior frame showed.
	_box(Vector3(INNER_W, 0.22, INNER_D),
		Vector3(0, FLOOR_H + LOFT_H + 0.1, 0), COL_FLOOR)

	# The kit roof volume, for the camera arm and any jump — bottom sits above
	# the interior ceiling, so it blocks nothing walkable.
	_collider(Vector3(11.9, 4.9, 8.3), Vector3(0, 8.7, 0))


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
	# as "the opening is stuck". The room is a step narrower since the kit
	# rebuild (INNER_D 7 -> ~5.4), so the south-wall pieces moved with it.
	_furnish("Table", Vector3(0.4, 0.12, -0.9), 90.0)
	_furnish("Chair", Vector3(-0.6, 0.12, -0.9), 90.0)
	_furnish("Stool", Vector3(1.3, 0.12, -1.3), 0.0)
	_furnish("Bookcase_Books", Vector3(-half_w + 0.45, 0.12, half_d - 0.6), 180.0)
	_furnish("Desk", Vector3(1.8, 0.12, half_d - 0.55), 180.0)
	# The wardrobe moved off the north-east corner: the narrower room put its
	# old spot inside the stair landing (stairs_bottom stands there now).
	# South of the door against the east wall, clear of the grandpa-to-door
	# lane by a measured 0.7m.
	_furnish("ShortCloset", Vector3(half_w - 0.6, 0.12, 1.2), -90.0)
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
	_furnish("BedDouble", Vector3(-half_w + 1.2, 0.12, -1.3), 0.0)
	# The alternate bookcase, doubled up rather than swapped in: one shelf
	# reads as furniture, two read as a life spent collecting books.
	_furnish("Bookcase", Vector3(-half_w + 0.45, 0.12, half_d - 2.2), 180.0)
	# A second table by the door, carrying the pack his own dialogue describes
	# ("that pack by the door carried me thirty years" — data/dialogue/
	# opening.json's grandpa_house line), given somewhere to actually sit.
	_furnish("Table2", Vector3(half_w - 1.0, 0.12, 2.15), 180.0)
	_clutter("Backpack", Vector3(half_w - 1.3, 0.12, 1.85), 30.0)
	_clutter("Axe", Vector3(half_w - 0.55, 0.12, 2.4), -20.0)
	_clutter("Knife", Vector3(half_w - 0.9, 0.12, 2.3), 10.0)


## `_box()`'s own comment gives the house its rug shorthand: a flat coloured
## box at floor height. Never solid — see `_clutter`'s reasoning, which
## applies here too.
func _build_rugs() -> void:
	var half_w := INNER_W * 0.5
	# Under the table/chair/stool cluster, short of both the stair footprint
	# and the two named lanes' actual walked width.
	_box(Vector3(3.0, 0.02, 2.0), Vector3(0.5, 0.13, -0.8), Color("#8a4a35"), false)
	# An entry mat by the gear table, east side near the door.
	_box(Vector3(1.8, 0.02, 1.4), Vector3(half_w - 1.1, 0.13, 1.6), Color("#5c4a34"), false)


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


## SA2 (spec sec1D): "the player cannot leave Grandpa's house until the
## required Grandpa opening interaction is complete." A collision box across
## the doorway, not a visible closed door — the kit doorframe stands open
## (no Door_1_Flat leaf in the recipe) because a closing animation is out of
## scope for the slice, so a second, shut door standing in the same opening
## would look like a modelling error rather than a story beat. The gate's
## own feedback is Grandpa's conversation starting (sequence_director.gd's
## job), not a visible barrier.
var _door_gate_shape: CollisionShape3D = null

func _build_door_gate() -> void:
	var body := StaticBody3D.new()
	body.name = "DoorGate"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WALL_T + 0.2, DOOR_H, DOOR_W)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(EXT_HALF_W - 0.11, DOOR_H * 0.5, 0.0)
	add_child(body)
	_door_gate_shape = shape


## Polled every frame by sequence_director.gd, the same "recomputed, never
## pushed" rule it already keeps for the interact lockout and the prompts —
## a gate set once and never revisited is a gate that is wrong the first
## time the beat changes under it.
func set_door_open(open: bool) -> void:
	if _door_gate_shape != null:
		_door_gate_shape.disabled = open
