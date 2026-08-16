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
## The Fantasy Props MegaKit (glTF, real-metre scale, trim-textured — the
## same family the workshop yard and creature bed already draw from).
const FANTASY_DIR := "res://assets/props/quaternius_fantasy"

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

## The flight, as named numbers rather than as locals inside the loop that
## lays the treads. PT-03's handrail has to sit ON the pitch line those
## numbers describe, and a rail that re-derives the pitch by eye is a rail
## parallel to nothing in particular.
const STAIR_STEPS := 10
const STAIR_RUN := 3.4
const STAIR_WIDTH := 1.2
## Handrail height above the nosing line, metres. Picked so the raked rail
## arrives at the loft edge within ~0.1m of the existing loft rail's cap
## (FLOOR_H + 0.25 + 0.9 = 4.35): that near-match is what makes the two
## read as ONE rail turning a corner and going down, rather than as a rail
## and, separately, a diagonal.
const RAIL_ABOVE_NOSING := 0.85

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
	# building_prefabs.gd caches an un-parented Node3D template tree per
	# prefab name; without a real SceneTree parent it leaks RenderingServer
	# resources at engine shutdown (see building_prefabs.gd's own header on
	# `_holder` — reproduced as a real crash: hundreds of "leaked" GL buffers
	# followed by a heap-corrupting SIGABRT in the exported build, absent
	# once every `BuildingPrefabs` caller parks its templates).
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)
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
	var step_rise := FLOOR_H / float(STAIR_STEPS)
	var step_depth := STAIR_RUN / float(STAIR_STEPS)
	var start_x := -INNER_W * 0.5 + LOFT_W + STAIR_RUN
	var stair_z := -INNER_D * 0.5 + 0.6
	for i in STAIR_STEPS:
		var x := start_x - (float(i) + 0.5) * step_depth
		_box(Vector3(step_depth + 0.02, step_rise * (i + 1), STAIR_WIDTH),
			Vector3(x, step_rise * (i + 1) * 0.5, stair_z), COL_FLOOR)
	_build_stair_rail(start_x, stair_z, step_rise, step_depth)


## PT-03: the affordance that tells a stranger this is the way out.
##
## Two testers — one of them the owner, twice — could not find these stairs
## and jumped off the mezzanine instead
## (docs/reviews/2026-08-15-full-blind-playtest/PLAYER_LOG.md beats 16-20:
## "no stairs/exit visible in any frame yet from this room"). The cause is
## geometric and total: the loft floor's own east edge occludes everything
## below it, and every tread of this flight sits below that edge. Measured
## from the spot the opening leaves the player standing, the sightline that
## grazes the loft edge passes ABOVE the treads for the entire run — so no
## amount of light on the treads could ever have reached that eye. What the
## player sees instead is a floor edge with a shallow ledge under it, which
## is exactly what a parapet looks like.
##
## So the flight is given the one part of a staircase that can rise above the
## occluding edge: a handrail raked to its own pitch, ending in a newel at
## the head where the loft rail stops. The same arithmetic says the rail
## clears that sightline from x = the loft edge out to x ~ 1.9, which is over
## half the run — a long descending diagonal, and nothing else in this room
## is diagonal. A parapet cannot be mistaken for one.
##
## Nothing here is solid. The interior camera's spring arm collapsing against
## this room's geometry was the same playtest's dominant complaint, and a
## handrail is exactly the wrong place to put fresh collision at head height
## beside a player walking a 1.2m flight. It is also not needed: the rail
## sits 0.11m inside the flight's own south face, and the walked lane
## (`stairs_top` -> `stairs_bottom`) runs down the middle.
func _build_stair_rail(start_x: float, stair_z: float, step_rise: float, step_depth: float) -> void:
	# The pitch line, through the nosing of each tread: step 0's nose is its
	# east edge, at (start_x, step_rise), and every nose above it is one rise
	# up and one going west.
	var pitch := step_rise / step_depth
	var head_x := -INNER_W * 0.5 + LOFT_W - 0.06  # the loft rail's own x
	var foot_x := start_x
	# Inside the flight's south face, so that below tread height the balusters
	# are buried in the step solids rather than hanging in open air beside them.
	var rail_z := stair_z + STAIR_WIDTH * 0.5 - 0.11
	var head_y := step_rise + (foot_x - head_x) * pitch + RAIL_ABOVE_NOSING
	var foot_y := step_rise + RAIL_ABOVE_NOSING

	var span := Vector2(foot_x - head_x, foot_y - head_y)
	_raked_box(Vector3(span.length(), 0.10, 0.12),
		Vector3((head_x + foot_x) * 0.5, (head_y + foot_y) * 0.5, rail_z),
		atan2(span.y, span.x), COL_TIMBER)

	# The head newel, standing on the loft where the loft rail ends. The
	# vertical accent matters as much as the diagonal: it is what turns "the
	# rail simply stops" into "the rail arrives somewhere".
	var loft_top := FLOOR_H + 0.25
	var head_cap := head_y + 0.10
	# Deeper in z than the foot newel so it reaches back to the loft rail's own
	# north face: the rail line and the flight line are 0.11m apart, and a
	# hairline gap between the two at eye level reads as a modelling error.
	_raked_box(Vector3(0.16, head_cap - loft_top, 0.22),
		Vector3(head_x, (loft_top + head_cap) * 0.5, rail_z), 0.0, COL_TIMBER)
	# The foot newel, on the ground slab, for the same reason seen from below.
	var foot_cap := foot_y + 0.10
	_raked_box(Vector3(0.16, foot_cap - 0.12, 0.16),
		Vector3(foot_x, (0.12 + foot_cap) * 0.5, rail_z), 0.0, COL_TIMBER)

	# Balusters. Without them the rail is a plank floating at 43 degrees; with
	# them it is a staircase seen edge-on. Each one runs from just under the
	# rail down through the pitch line by one rise, so it always meets its own
	# tread whatever fraction of the going it lands on, and disappears into
	# the step solid below.
	for i in 5:
		var t := (float(i) + 0.5) / 5.0
		var x: float = lerpf(head_x, foot_x, t)
		var top: float = lerpf(head_y, foot_y, t) - 0.05
		var bottom := step_rise + (foot_x - x) * pitch - step_rise
		_raked_box(Vector3(0.07, top - bottom, 0.07),
			Vector3(x, (top + bottom) * 0.5, rail_z), 0.0, COL_TIMBER)


## A box that may be tilted in the x-y plane, positioned by its centre.
##
## `_box()` cannot express the one piece of this house that is not
## axis-aligned, and a staircase of small axis-aligned boxes approximating a
## diagonal is the silhouette the player already fails to read. Never solid:
## see `_build_stair_rail()`'s own note on the interior camera.
func _raked_box(size: Vector3, at: Vector3, roll: float, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = at
	mesh.rotation.z = roll
	add_child(mesh)


func _furnish(model: String, at: Vector3, yaw_degrees: float, scale_factor := FURNITURE_SCALE,
		dir := FURNITURE_DIR, solid := true) -> void:
	# OBJ pieces load as a bare Mesh (the Furniture/Survival packs); glTF
	# pieces load as a scene (the Fantasy Props MegaKit, real-metre scale and
	# trim-textured — EV6-remainder-polish swaps the featureless ShortCloset
	# box for the kit's panelled Cabinet through exactly this branch). Same
	# two-format fallback building_prefabs.gd::_build_template already uses.
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
		aabb = (PREFABS.new() as RefCounted).call("combined_aabb", node)
	else:
		push_warning("house furniture missing: %s" % obj_path)
		return
	node.position = at
	node.rotation.y = deg_to_rad(yaw_degrees)
	node.scale = Vector3.ONE * scale_factor
	add_child(node)
	if not solid:
		return
	# One simple blocker per piece: walking through a table breaks the room
	# harder than an approximate box breaks pathing.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_factor
	shape.shape = box
	body.add_child(shape)
	body.position = at + Vector3(0, aabb.size.y * 0.5 * scale_factor, 0)
	body.rotation.y = deg_to_rad(yaw_degrees)
	add_child(body)


## OF8. `_furnish`'s own "one simple blocker per piece" collider boxes the
## model's FULL AABB, headboard included — measured directly against
## `BedTwin.obj`'s vertices: local Y spans 0..1.56, so ~1.03m tall once
## `FURNITURE_SCALE` is applied. A CharacterBody3D placed to rest ON that box
## (the sequence director's own "into bed" staging did exactly this) therefore
## settles at HEADBOARD height, not mattress height — confirmed with a
## headless probe: the trainer's resting Y measured 0.465m above the "bed"
## marker, matching this box's own top-minus-marker math (1.03 - 0.55 =
## 0.48m) to within a few centimetres. That is the entire "the player starts
## standing on the bed" bug (OF8): they are standing on the tallest point of
## its bounding box, not lying in it.
##
## Capped here at 0.3m — the same gap the "bed" marker already sits above
## this piece's own base (FLOOR_H + 0.55 vs FLOOR_H + 0.25, both already
## written into `bed_at` above), so a body resting on THIS collider lands
## at the same height the marker, `BedPrompt`, and the lying pose
## (`sequence_director.gd`, `character_model.gd::set_lying`) already assume.
## Full X/Z footprint kept, so the bed still blocks a straight walk-through
## from the sides; only the height changed.
func _bed_mattress_collider(at: Vector3) -> void:
	var mesh: Mesh = load("%s/BedTwin.obj" % FURNITURE_DIR)
	if mesh == null:
		return
	var aabb := mesh.get_aabb()
	var mattress_h := 0.3
	var size := Vector3(aabb.size.x * FURNITURE_SCALE, mattress_h, aabb.size.z * FURNITURE_SCALE)
	_collider(size, at + Vector3(0, mattress_h * 0.5, 0))


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
	# lane (DOOR_W/2 = 0.8; the cabinet's near edge sits at z 0.82).
	# EV6-remainder-polish: was the furniture pack's `ShortCloset`, which the
	# furniture fix's own confirming blind pass named "a featureless flat
	# slab" — a geometry/detail limit of that mesh, not a colour bug. Swapped
	# for the Fantasy Props MegaKit's `Cabinet` (panelled doors, metal
	# handles, trim-textured), real-metre kit so scale 1.0, back against the
	# east wall (half-depth 0.18 + 0.06 gap).
	_furnish("Cabinet", Vector3(half_w - 0.24, 0.12, 1.5), -90.0, 1.0, FANTASY_DIR)
	# The loft: the player's bed under the west eave, the nightstand at its
	# foot, both clear of the lane from the bed to the stair head.
	#
	# BedTwin gets its own collider rather than `_furnish`'s default
	# full-AABB one (OF8 — see `_bed_mattress_collider`'s own comment for why).
	var bed_at := Vector3(-half_w + 1.3, FLOOR_H + 0.25, -half_d + 1.9)
	_furnish("BedTwin", bed_at, 0.0, FURNITURE_SCALE, FURNITURE_DIR, false)
	_bed_mattress_collider(bed_at)
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
	# EV6-remainder-polish: was the Survival pack's `Backpack`, which the
	# round-1 blind critic read as "a modern military/camping asset dropped
	# into a medieval timber-frame interior". The Fantasy Props MegaKit's
	# `Bag` (a buckled leather rucksack, already in use at the trainer_camp
	# cluster) is the same story beat in the period's own material language.
	# Real-metre kit, so scale 1.0.
	_clutter("Bag", Vector3(half_w - 1.3, 0.12, 1.85), 30.0, false, FANTASY_DIR, 1.0)
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
	#
	# The third one is PT-03's other half. The first two sit in the middle of
	# the ground floor and over the bed, which is why the stair head — the one
	# corner a first-time player has to find — was the darkest place in the
	# room. It hangs over the stairwell above the top treads, so it lights the
	# new handrail from the side the loft looks at it from, and puts a warm
	# pool on the loft floor at the corner the player has to walk to. Shadows
	# stay on, as on the other two: unshadowed it would spill straight through
	# the north wall onto the village square.
	for at: Vector3 in [Vector3(0, 2.6, 0), Vector3(-2.5, FLOOR_H + 2.0, -1.0)]:
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color(1.0, 0.88, 0.7)
		light.light_energy = 2.4
		light.omni_range = 9.0
		light.shadow_enabled = true
		add_child(light)

	# The stair-head light is deliberately NOT in the loop above, and its range
	# is the reason. It was written into that loop for tidiness and inherited
	# the room lights' 9.0 range — in a room 5.4m deep that is a third room
	# light, not a stair light. A blind critic comparing before/after frames
	# measured the result as a global lift (mean luma 137 -> 159, raised evenly
	# across ceiling, both side walls and the far wall) and pointed out that a
	# uniform lift cannot function as a wayfinding cue: it brightens the thing
	# you are looking for by exactly as much as everything else. It was also
	# actively counterproductive, washing the left wall toward white and
	# flattening the timber trim nearest the stair head.
	#
	# So: shorter range and lower energy, sized to fall off before it reaches
	# the opposite wall, so what it does is put a pool on the corner the player
	# has to walk to rather than raise the room. TUNABLE — these are chosen to
	# be directional, not balanced, and the frame is the judge.
	var stair_head := OmniLight3D.new()
	stair_head.position = Vector3(-INNER_W * 0.5 + LOFT_W + 0.6, FLOOR_H + 0.8,
		-INNER_D * 0.5 + 0.6)
	stair_head.light_color = Color(1.0, 0.88, 0.7)
	stair_head.light_energy = 2.0
	stair_head.omni_range = 4.5
	# Shadows stay on, as on the other two: unshadowed it would spill straight
	# through the north wall onto the village square.
	stair_head.shadow_enabled = true
	add_child(stair_head)


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
