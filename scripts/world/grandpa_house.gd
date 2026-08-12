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

## EV6. The settlement around this house was rebuilt on the Medieval Village
## MegaKit (D24), and the first render showed what that does to a flat-colour
## primitive shell: beside textured plaster, stone and terracotta it reads as
## a grey cardboard model — a FOURTH vernacular, in the settlement whose whole
## rebuild exists to get down to one. The item's own instruction was to judge
## the house against the family rather than preserve it out of sentiment.
##
## Judgement: the geometry survives (its dimensions are the opening's whole
## choreography — markers, stairs, camera profile, door gate), the flat
## materials do not. Each COL_* below now names a kit texture as well as a
## colour: the same T_Plaster/T_WoodTrim/T_RoundTiles/T_RockTrim sheets every
## other building in the square wears, applied triplanar so the box shell
## needs no UV work. The colour becomes a mild multiplier over the texture
## instead of the whole material. A full modular rebuild of the shell is
## EV6-remainder work; this closes the family gap without touching a marker.
const KIT_TEX_DIR := "res://assets/buildings/quaternius_medieval"
## World-space texture repeat: kit walls tile their sheets roughly every two
## metres, and matching that density is what makes the shell read as the same
## hand rather than a photo of it.
const KIT_TEX_SCALE := 0.5

const COL_TIMBER := Color("#5a4030")
## R9.4. Was #e6ddc8, a near-white cream. Under a 1.35-energy sun that rendered
## at ~154,165,169 flat, and the blind critic's word for the result was "an
## untextured grey box". Warmed and dropped a step toward the key art board's
## own plaster, which sits in the mid-value warm band rather than at the top of
## the range.
const COL_PLASTER := Color("#d8c8a6")
const COL_FLOOR := Color("#7a5a35")
## R9.4. Was #4a3f3a, which measured 11-16% luminance in direct midday sun —
## the critic's second-ranked finding was that every roof in the build is
## crushed to near-black while the reference board keeps its roofs in the warm
## 35-65% band and spends its darks on tree canopy instead. This is a farmhouse
## thatch/shingle, not a shadow.
const COL_ROOF := Color("#8a6a44")
const COL_RIDGE := Color("#6f5236")
const COL_STONE := Color("#9c968a")
## Warm interior light seen through a window from outside. The critic: a warm
## interior glow behind an existing casing is "most of what makes a building
## look inhabited".
const COL_GLASS := Color("#f0c684")

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
	_build_door_gate()

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


## Which kit sheet each of the house's roles wears. Keys are the COL_*
## constants; a colour not listed here (rugs, glass) stays a flat material.
## The multiplier lightens the old tuned colour so texture and tint do not
## stack into the crushed-dark roofs R9.4-remainder-3 measured.
## `lift` is how far the old tuned colour is pushed toward white before it
## multiplies the sheet: 1.0 would be the raw texture, 0.0 the old flat tint
## stacked on top of it (the crushed-dark failure R9.4-remainder-3 measured).
## The roof keeps more of its own warm brown than the rest — at 0.75 the
## first EV6 render read a half-step brighter and stripier than the kit
## roofs beside it (frame 06).
const KIT_TEXTURES := {
	COL_PLASTER: { "tex": "T_Plaster_BaseColor", "lift": 0.75 },
	COL_TIMBER: { "tex": "T_WoodTrim_BaseColor", "lift": 0.75 },
	COL_ROOF: { "tex": "T_RoundTiles_BaseColor", "lift": 0.45 },
	COL_RIDGE: { "tex": "T_RoundTiles_BaseColor", "lift": 0.45 },
	COL_STONE: { "tex": "T_RockTrim_BaseColor", "lift": 0.75 },
}
## COL_FLOOR deliberately absent: T_WoodTrim is a trim ATLAS — boards beside
## pale plaster patches — which reads as wood on a thin exterior bar but as
## broad circus stripes across a 9x7m floor slab; the round-2 interior frame
## showed exactly that. Floors and stairs stay flat colour.

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
			# Triplanar: object-space projection, so forty boxes of thirty
			# sizes all tile at the same density with no UV authoring. The
			# sheets carry the tone; the old colour becomes a cast over them.
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

	# Flat ceiling slab. It is no longer the roof — it is what the loft sees
	# when it looks up, and what the gable sits on. Kept solid so the player
	# cannot walk off the top of the world. COL_FLOOR, not COL_ROOF: since the
	# EV6 reskin the roof colour carries the round-tile sheet, and a bedroom
	# ceiling wearing terracotta tiles was the first thing the round-1
	# interior frame showed.
	_box(Vector3(INNER_W + WALL_T * 2, 0.3, INNER_D + WALL_T * 2),
		Vector3(0, FLOOR_H + LOFT_H + 0.15, 0), COL_FLOOR)

	_build_gable_roof()
	_build_facade()


## R9.4. The house used to end at a flat slab, with this comment above it: "a
## gable is a texture problem for another day; from outside the farm-pack barns
## carry the silhouette for the whole village." A blind critic looking only at
## the frames disagreed on both counts. It called the house "an untextured grey
## box" with "no window anywhere on it", a door that "does not read as a
## doorway, it reads as a missing texture", and named it the single
## highest-value piece of missing art in the set — noting it appears in three of
## five frames, because it is the player's home and it is right beside the
## square. The barns cannot carry a silhouette the house is standing next to.
##
## So: a real pitched roof with eaves and a ridge, gable ends that close it,
## and — in _build_facade below — windows, a doorframe, a plinth and corner
## posts. All still primitives, which is fine: CLAUDE.md allows placeholder
## geometry to prove a mechanic. What it does not allow is a building with no
## openings standing where the player will look at it more than anything else.
func _build_gable_roof() -> void:
	var half_w := INNER_W * 0.5 + WALL_T
	var half_d := INNER_D * 0.5 + WALL_T
	var eaves_y := FLOOR_H + LOFT_H + 0.3
	var rise := 2.1
	var overhang := 0.55

	# Two pitched slabs meeting at a ridge running north-south (along z), so
	# the gable ends face the yard and the square — the two directions the
	# house is actually seen from.
	var slope_run := half_w + overhang
	var slope_len := sqrt(slope_run * slope_run + rise * rise)
	var pitch := atan2(rise, slope_run)

	for side in [-1.0, 1.0]:
		var pane := MeshInstance3D.new()
		var pane_mesh := BoxMesh.new()
		pane_mesh.size = Vector3(slope_len, 0.22, (half_d + overhang) * 2.0)
		pane.mesh = pane_mesh
		pane.material_override = _material(COL_ROOF)
		pane.position = Vector3(side * slope_run * 0.5, eaves_y + rise * 0.5, 0.0)
		pane.rotation.z = -side * pitch
		add_child(pane)

	# Ridge cap, so the two panes meet in a line rather than in a crack.
	_box(Vector3(0.30, 0.22, (half_d + overhang) * 2.0),
		Vector3(0.0, eaves_y + rise + 0.02, 0.0), COL_RIDGE, false)

	# Gable infill: the triangle of wall between the eaves and the ridge at
	# each end. Stepped boxes rather than a real triangle — three steps is
	# enough to read as a gable at any distance the house is seen from, and it
	# keeps the whole building inside one primitive vocabulary.
	var steps := 4
	for end_side in [-1.0, 1.0]:
		for i in steps:
			var t := float(i) / float(steps)
			var t_next := float(i + 1) / float(steps)
			var band_w := (half_w * 2.0) * (1.0 - t)
			var band_h := rise / float(steps)
			_box(Vector3(band_w, band_h, WALL_T),
				Vector3(0.0, eaves_y + rise * (t + t_next) * 0.5, end_side * half_d),
				COL_PLASTER, false)

	# Fascia along both eaves — the shadow line that tells you a roof has an
	# edge. Without it the pitched slabs read as a folded sheet.
	for side in [-1.0, 1.0]:
		_box(Vector3(0.14, 0.34, (half_d + overhang) * 2.0),
			Vector3(side * (slope_run - 0.07), eaves_y - 0.05, 0.0), COL_TIMBER, false)

	# Chimney, off the ridge on the west side, above the hearth end.
	_box(Vector3(0.85, 2.4, 0.85), Vector3(-half_w * 0.55, eaves_y + 1.5, -half_d * 0.45),
		COL_STONE, false)
	_box(Vector3(1.05, 0.22, 1.05), Vector3(-half_w * 0.55, eaves_y + 2.75, -half_d * 0.45),
		COL_RIDGE, false)


## Windows, a framed doorway, a stone plinth and corner posts.
##
## The critic's exact words about the openings: "every window in the set is a
## black hole... in the key art every cottage window has a warm interior glow
## and a leaded pane. That single change is most of what makes a building look
## inhabited." So each window here is three parts — a recessed warm emissive
## pane, a mullion cross, and a frame around it — and the pane is emissive
## rather than lit, because under the Compatibility renderer a small interior
## light does not reliably reach an exterior surface (D01/D06).
func _build_facade() -> void:
	var half_w := INNER_W * 0.5 + WALL_T
	var half_d := INNER_D * 0.5 + WALL_T
	var wall_h := FLOOR_H + LOFT_H

	# Stone plinth. Buildings in the references sit IN the ground; this one met
	# the grass at a hard line, which the critic listed among the reasons
	# everything "looks like it's hovering".
	#
	# A RING, not a slab. The first cut of this was one box across the whole
	# footprint, which put a grey stone lid over the interior floor standing
	# half a metre proud of it — the room rendered pale and the furniture sat
	# in a bathtub. Only the perimeter is ever seen, so only the perimeter is
	# built.
	var plinth_h := 0.55
	var out_w := INNER_W + WALL_T * 2 + 0.34
	var out_d := INNER_D + WALL_T * 2 + 0.34
	for sz in [-1.0, 1.0]:
		_box(Vector3(out_w, plinth_h, 0.34),
			Vector3(0.0, plinth_h * 0.5 - 0.2, sz * (out_d * 0.5 - 0.17)), COL_STONE, false)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.34, plinth_h, out_d - 0.68),
			Vector3(sx * (out_w * 0.5 - 0.17), plinth_h * 0.5 - 0.2, 0.0), COL_STONE, false)

	# Corner posts, breaking the flat plaster into bays the way a timber-framed
	# farmhouse is actually built.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(0.30, wall_h, 0.30),
				Vector3(sx * half_w, wall_h * 0.5, sz * half_d), COL_TIMBER, false)

	# A mid rail at loft-floor height, which also tells the eye the building
	# has two storeys.
	for sz in [-1.0, 1.0]:
		_box(Vector3(INNER_W + WALL_T * 2, 0.18, 0.14),
			Vector3(0.0, FLOOR_H + 0.1, sz * (half_d + 0.02)), COL_TIMBER, false)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.14, 0.18, INNER_D + WALL_T * 2),
			Vector3(sx * (half_w + 0.02), FLOOR_H + 0.1, 0.0), COL_TIMBER, false)

	# Ground-floor windows: two on the south wall, one on the north, one on
	# the west. The east wall carries the door.
	_window(Vector3(0.0, 1.75, half_d + 0.02), 0.0, 1.30, 1.20)
	_window(Vector3(-2.9, 1.75, half_d + 0.02), 0.0, 1.30, 1.20)
	_window(Vector3(2.4, 1.75, -half_d - 0.02), PI, 1.30, 1.20)
	_window(Vector3(-half_w - 0.02, 1.75, 1.6), -PI * 0.5, 1.30, 1.20)
	# Loft windows, smaller, set into the gable-end walls.
	_window(Vector3(-2.2, FLOOR_H + 1.5, half_d + 0.02), 0.0, 0.85, 0.85)
	_window(Vector3(2.2, FLOOR_H + 1.5, -half_d - 0.02), PI, 0.85, 0.85)

	# Doorframe and threshold step, so the opening reads as a door rather than
	# as the dark rectangle the critic saw.
	var door_z := 0.6
	for sz in [-1.0, 1.0]:
		_box(Vector3(0.34, DOOR_H + 0.2, 0.20),
			Vector3(half_w, (DOOR_H + 0.2) * 0.5, door_z + sz * (DOOR_W * 0.5 + 0.1)),
			COL_TIMBER, false)
	_box(Vector3(0.34, 0.22, DOOR_W + 0.4),
		Vector3(half_w, DOOR_H + 0.11, door_z), COL_TIMBER, false)
	_box(Vector3(0.9, 0.18, DOOR_W + 0.5),
		Vector3(half_w + 0.4, 0.12, door_z), COL_STONE, false)


## One window: warm pane, mullion cross, frame. `yaw` faces it outward.
func _window(at: Vector3, yaw: float, w: float, h: float) -> void:
	var node := Node3D.new()
	node.position = at
	node.rotation.y = yaw
	add_child(node)

	var pane := MeshInstance3D.new()
	var pane_mesh := BoxMesh.new()
	pane_mesh.size = Vector3(w, h, 0.06)
	pane.mesh = pane_mesh
	var glow := StandardMaterial3D.new()
	glow.albedo_color = COL_GLASS
	glow.emission_enabled = true
	glow.emission = COL_GLASS
	# Low, because this is a lit room seen from outside in daylight, not a
	# lamp. High enough to stop the opening reading as a hole.
	glow.emission_energy_multiplier = 0.85
	pane.material_override = glow
	node.add_child(pane)

	var frame_t := 0.11
	for sx in [-1.0, 1.0]:
		_frame_bar(node, Vector3(w * 0.5 * sx, 0.0, 0.03), Vector3(frame_t, h + frame_t * 2.0, 0.13))
	for sy in [-1.0, 1.0]:
		_frame_bar(node, Vector3(0.0, h * 0.5 * sy, 0.03), Vector3(w + frame_t * 2.0, frame_t, 0.13))
	# Mullion cross — the detail that separates a window from a lit rectangle.
	_frame_bar(node, Vector3(0.0, 0.0, 0.04), Vector3(0.055, h, 0.10))
	_frame_bar(node, Vector3(0.0, 0.0, 0.04), Vector3(w, 0.055, 0.10))


func _frame_bar(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var bar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	bar.mesh = mesh
	bar.material_override = _material(COL_TIMBER)
	bar.position = at
	parent.add_child(bar)


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
	# The spare door that used to lean in this corner is gone (EV6): its
	# panel material renders as a flat BLUE rectangle — the same
	# vertex-colour defect class EV7 caught on FarmCrate_Carrot — and both
	# EV6 interior frames showed it as the loudest wrong thing in the room.
	# A model that cannot render its own wood is not clutter, it is a bug
	# on display.


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


## SA2 (spec sec1D): "the player cannot leave Grandpa's house until the
## required Grandpa opening interaction is complete." A collision box across
## the doorway, not a visible closed door — this file's own header already
## explains why: the door leaf is left open against the wall because a
## closing animation is out of scope for the slice, so a second, shut door
## standing in the same opening would look like a modelling error rather
## than a story beat. The gate's own feedback is Grandpa's conversation
## starting (sequence_director.gd's job), not a visible barrier.
var _door_gate_shape: CollisionShape3D = null

func _build_door_gate() -> void:
	var half_w := INNER_W * 0.5 + WALL_T
	var door_z := 0.6
	var body := StaticBody3D.new()
	body.name = "DoorGate"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WALL_T, DOOR_H, DOOR_W)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(half_w + WALL_T * 0.5, DOOR_H * 0.5, door_z)
	add_child(body)
	_door_gate_shape = shape


## Polled every frame by sequence_director.gd, the same "recomputed, never
## pushed" rule it already keeps for the interact lockout and the prompts —
## a gate set once and never revisited is a gate that is wrong the first
## time the beat changes under it.
func set_door_open(open: bool) -> void:
	if _door_gate_shape != null:
		_door_gate_shape.disabled = open
