extends Node3D

## SD17 -- the Burrow Warrens: the Meadows' one required dungeon.
##
## MEADOWS_PROGRESSION_SPEC.md §3 Band 2 asks for a COMPACT cave: aggressive
## Ground creatures, Rootstone deposits, chamber navigation, a guardian fight
## and one rare side branch. Everything about it that is a number, a position
## or a species lives in `data/config/burrow_warrens.json`; this file is only
## the machine that stands it up.
##
## Built the way `grandpa_house.gd` builds an interior, for the same reasons:
## primitive boxes with REAL colliders (floor, walls, ceiling, an opening you
## walk through), named markers so anything that has to navigate the place
## asks the place rather than hard-coding metres, an Area3D that swaps the
## camera profile on entry, and one gate that can be disabled. Nothing here
## is final art -- the layout, chamber shapes and lighting are still
## blockout, and the thing that makes it legible today is that it is DARK
## (see `_build_lights`) and the player is carrying OF24's torch. The rock
## itself carries a real texture (MAT-BLOCKOUT, `_material`) rather than a
## flat colour, so it does not read as unfinished geometry up close.
##
## Three deliberate non-inventions:
##
##  * The creatures inside are ordinary wild creatures, spawned through
##    `encounter_director.gd::spawn_wild()`. Same engage prompt, same fight,
##    same catching, same respawn. There is no dungeon combat mode.
##  * The guardian is a strong NORMAL species (spec §20 and §3 Band 2 both
##    say outright not to invent a legendary, and D23 forbids the mesh), just
##    at a level well above the field.
##  * The side branch's door is the SB9 cleared flag, not `item_gate.gd`.
##    That class is for a carried key operating the world; nothing here hands
##    out a key, and "you have beaten the thing that lives here" is already a
##    fact the flag store remembers across saves.
##
## The floor is one level, sitting `floor_clearance` above the terrain at the
## mouth. The cave's depth axis points into the rocky rise, so the ground
## climbs ~27m over the 47m the warrens runs and everything past the first
## chamber is genuinely buried. `ground_height_at()` is overridden here so
## anything standing itself on "the ground" inside the footprint (creature
## bodies, harvest nodes) lands on the cave floor instead of on the hillside
## that is now several metres overhead -- `creature_body.gd::_find_ground_source`
## walks up the tree and takes the first ancestor offering that method, so
## parenting a creature under this node is the whole of the wiring.

const CONFIG_PATH := "res://data/config/burrow_warrens.json"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
## Read for its group and meta names only -- see `_build_approach_apron`.
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")

## How far past the approach ramp's own edge its ground clearance reaches. The
## same 0.7m `village.gd` gives a building over its wall line, for the same
## reason: the last hand's-breadth of grass at a paved edge is grass leaning
## ON the paving, not grass growing through it.
const APRON_CLEAR_MARGIN := 0.7

const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
## BAND2-63-WARRENS. The above-ground prop placer, reused underground for the
## cave's Team Tether dressing -- see `_build_dressing()`.
const PROPS := preload("res://scripts/world/props.gd")

## CONTENT-0828B. The shared constructed-interior method -- the bay rhythm,
## the course, the ceiling ribs, the door reveals and the corner posts that
## every space this project BUILDS was missing. See interior_structure.gd's
## header for why the owner named a class of space rather than a list of
## sites, and `interior_structure` in burrow_warrens.json for this cave's own
## vocabulary of it.
const INTERIOR_STRUCTURE := preload("res://scripts/world/interior_structure.gd")

## OP21-25. See `combat_arena_bounds_at()` below -- how far inside a chamber's
## wall FACE the fight boundary is required to sit. Clearance for a body's own
## radius, not a fudge factor.
const ARENA_WALL_MARGIN := 1.0

## MAT-BLOCKOUT. The wall/ceiling boxes below carried a flat StandardMaterial3D
## colour and nothing else, by design (see this file's header) -- a blind
## critic named the result correctly: "completely flat-shaded... no texture...
## unfinished blockout geometry." Textured with `terrain_playground.json`'s own
## `rock` material (data/config/terrain_playground.json, the `rock` entry under
## `materials`) rather than a new asset: it is the SAME stone the hillside this
## cave is dug into is textured with, already tuned against this project's own
## lighting across several OF11/EV4 rounds (uv_scale, normal_depth, tint below
## are its vetted values, not new numbers), so the cave reads as continuous
## with the cliff the player just walked past, not a second, unrelated rock.
## `uv1_triplanar` avoids authoring UVs for primitive boxes of varying size --
## the same technique `severed_spokes.gd::_stone_material` and
## `grandpa_house.gd::_material` already use for procedurally-sized geometry
## in this exact codebase.
const ROCK_ALBEDO := preload("res://assets/environment/terrain/Rock030_Color.jpg")
const ROCK_NORMAL := preload("res://assets/environment/terrain/Rock030_NormalGL.jpg")
const ROCK_UV_SCALE := 0.46
const ROCK_TINT := Color("#fff2e0")

## CONTENT-0828B. THE FLOOR HAD NO TEXTURE AT ALL, and it is the largest
## surface in every room in this dungeon.
##
## Found in a frame, not in the code: `W1-den-wide` came back with a fully
## textured wall and ceiling standing on a flat unbroken brown plane. The cause
## is one defaulted argument -- `_box()` takes `textured := false` and
## `_build_chambers()`/`_build_passages()` pass `_floor_colour()` and stop
## there, while every wall and ceiling beside them passes `true, true`. This is
## the same class of bug MAT-BLOCKOUT already fixed for the walls and
## STRONGHOLD-MAT for the fortress ("one model family, reached down a code path
## that never warmed its material"); the floor was simply the surface neither
## pass looked at. `stronghold.gd` textures its own floors, so this was a
## Warrens-only omission.
##
## A DIFFERENT texture from the walls, deliberately, and this is the half that
## is a design call rather than a bug fix. A cave floor is not the same
## material as a cave wall -- it is what has fallen off the walls and been
## walked on. Giving the floor the wall's own Rock030 would fix "untextured"
## and leave the room a single material from floor to ceiling, which is the
## other half of what makes these spaces read as blockout. `Ground030` is the
## dirt/pebble surface `build_playground_terrain.gd` already uses for the
## meadow's own paths (its comment calls it "a real dirt/pebble pathway
## photo"), so this is the same material family the player has been walking on
## all chapter, indoors.
const FLOOR_ALBEDO := preload("res://assets/environment/terrain/Ground030_Color.jpg")
const FLOOR_NORMAL := preload("res://assets/environment/terrain/Ground030_NormalGL.jpg")
const FLOOR_UV_SCALE := 0.30

## The cave is a narrow, low place; the village's default third-person arm
## puts the camera through the rock. Same seam grandpa_house.gd uses.
const INTERIOR_PROFILE := {
	"distance": 2.6,
	"height": 1.6,
	"fov": 70.0,
	"pitch_min_deg": -35.0,
	"pitch_max_deg": 30.0,
	"retarget_lag": 10.0,
}

var _config: Dictionary = {}
var _world: Node = null
var _camera_rig: Node = null
var _player: Node3D = null

var _floor_y: float = 0.0
var _wall_t: float = 1.2
var _skirt: float = 10.0
var _chambers: Dictionary = {}          # id -> chamber dict
var _markers: Dictionary = {}           # name -> global Vector3
var _materials: Dictionary = {}
var _footprint: Array = []              # local AABB rectangles [minx, minz, maxx, maxz]
## CONTENT-0828. `[centre, radius]` per passage, in local metres. Filled by
## `_build_passages()` and read by `_build_interior_rock()`.
var _doorways: Array = []
## CONTENT-0828B. One entry per END of every passage -- the hole this cave
## actually cut in a chamber wall, which is where a reveal has to stand. The
## passage MIDPOINT (which `_doorways` records) is inside the tunnel, and a
## frame there is a frame nobody standing in either room can see.
var _openings: Array = []

var _vault_door: StaticBody3D = null
var _vault_door_mesh: MeshInstance3D = null
var _guardian: Node3D = null
var _guardian_seen_alive: bool = false
var _poll_left: float = 0.0
var _population: Array[Node3D] = []


## --- build -----------------------------------------------------------------

## `world` is the playground root (it answers `ground_height_at`), `director`
## is the encounter director that owns every wild body in the scene. Both may
## be null in a bare test scene; the cave still stands up, just empty.
func build(world: Node, camera_rig: Node = null, player: Node3D = null, director: Node = null) -> bool:
	_world = world
	_camera_rig = camera_rig
	_player = player
	_config = _load_config()
	if _config.is_empty():
		push_error("burrow_warrens.json missing or malformed; the dungeon does not exist")
		return false

	var site: Dictionary = _config.get("site", {})
	var at: Array = site.get("at", [0.0, 0.0])
	var mouth_ground := 0.0
	if world != null and world.has_method("ground_height_at"):
		mouth_ground = float(world.call("ground_height_at", float(at[0]), float(at[1])))
		if is_nan(mouth_ground):
			push_error("no ground under the Burrow Warrens entrance; it has nowhere to stand")
			return false
	_wall_t = float(site.get("wall_thickness", 1.2))
	_skirt = float(site.get("skirt", 10.0))
	position = Vector3(float(at[0]), mouth_ground, float(at[1]))
	rotation.y = deg_to_rad(float(site.get("yaw_deg", 0.0)))
	# Local Y of the cave floor. The node itself sits on the terrain at the
	# mouth, so this is just the clearance step up over the doorway sill.
	_floor_y = float(site.get("floor_clearance", 0.35))

	for entry: Variant in _config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		_chambers[str(chamber.get("id", ""))] = chamber
		var centre := _local_of(chamber.get("at", [0.0, 0.0]))
		var size := _size_of(chamber.get("size", [4.0, 4.0]))
		_footprint.append([centre.x - size.x * 0.5, centre.z - size.y * 0.5,
			centre.x + size.x * 0.5, centre.z + size.y * 0.5])
		_markers[str(chamber.get("id", ""))] = to_global(Vector3(centre.x, _floor_y, centre.z))

	_build_chambers()
	_build_passages()
	_build_approach_apron()
	_build_lights()
	_build_interior_area()
	_clear_the_ground_the_cave_stands_on()
	_build_mound()
	_build_deposits()
	_build_dressing()
	_build_interior_rock()
	_build_structure()
	_build_prize()
	_sync_vault_door()

	_markers["entrance"] = to_global(Vector3(0.0, _floor_y, _mouth_outer_z() - 3.0))
	if director != null:
		_spawn_population(director)
	set_process(true)
	return true


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _local_of(raw: Variant) -> Vector3:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector3.ZERO
	return Vector3(float(list[0]), 0.0, float(list[1]))


func _size_of(raw: Variant) -> Vector2:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector2(4.0, 4.0)
	return Vector2(float(list[0]), float(list[1]))


## --- geometry --------------------------------------------------------------

func _material(colour: Color, emissive := 0.0, textured := false) -> StandardMaterial3D:
	var key := "%s_%.2f_%s" % [colour.to_html(), emissive, textured]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.95
	if textured:
		m.albedo_texture = ROCK_ALBEDO
		# MAT-BLOCKOUT round 2: the terrain's own near-white #fff2e0 tint (tuned
		# for a photo lit by strong exterior sun) read as too flat/washed once a
		# blind critic saw it at normal frame size inside the dimmer cave --
		# "completely flat... almost no texture variation" persisted even though
		# the texture and normal map were both genuinely present (confirmed by
		# a direct pixel crop). Pulled 25% toward this element's own configured
		# colour for more contrast, and normal_scale raised past the terrain's
		# default 1.0 to buy back relief the cave's flatter, less grazing light
		# doesn't supply on its own. TUNABLE.
		m.albedo_color = colour.lerp(ROCK_TINT, 0.75)
		m.normal_enabled = true
		m.normal_texture = ROCK_NORMAL
		m.normal_scale = 2.2
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * ROCK_UV_SCALE
	else:
		m.albedo_color = colour
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = emissive
	_materials[key] = m
	return m


## A box with matching collision, positioned by its centre in cave-local space.
func _box(size: Vector3, at: Vector3, colour: Color, solid := true, textured := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour, 0.0, textured)
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
	return mesh


func _rock() -> Color:
	return Color(str(_config.get("site", {}).get("rock", "#5b5147")))


func _floor_colour() -> Color:
	return Color(str(_config.get("site", {}).get("floor_colour", "#4a423a")))


## The cave floor's own material. Triplanar for the same reason every other
## surface in here is: these are procedurally-sized primitive boxes with no
## authored UVs, so the texture has to project itself from world space.
##
## `uv1_scale` is looser than the wall's (0.30 against ROCK_UV_SCALE's 0.46)
## because a floor is seen at a grazing angle across its whole length and a
## tight tile reads as noise at that angle -- the wall is seen face-on and
## wants the finer grain.
func _floor_material() -> StandardMaterial3D:
	var key := "floor"
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.98
	m.albedo_texture = FLOOR_ALBEDO
	# Round 2 lerped this 0.6 toward `ROCK_TINT` the way the walls do and the
	# frames came back with a bright sandy floor that was the LIGHTEST surface
	# in every room -- a beach, and brighter than the stone above it, which
	# inverts a cave's own value structure. A floor is the surface furthest
	# from every light in the room and it should read that way. 0.22 keeps
	# enough of the tint to sit in the same warm family as the walls while
	# leaving `site.floor_colour` doing the work it was authored to do.
	#
	# 0.22 was then measured and it had overshot the other way: against
	# `origin/main` the den went from 38.9% of pixels below luminance 40 to
	# 56.5% and the hall from 40.4% to 62.3%, because the floor is the largest
	# surface in the room and a dark floor takes the frame's whole midtone mass
	# with it. The blind critic's first finding on these rooms was the value
	# crush, so darkening the floor was making its headline defect worse while
	# fixing the sandiness. 0.42 reads as packed dirt DARKER than the wall
	# above it without emptying the histogram -- between round 2's beach and
	# round 3's hole.
	m.albedo_color = _floor_colour().lerp(ROCK_TINT, 0.42)
	m.normal_enabled = true
	m.normal_texture = FLOOR_NORMAL
	m.normal_scale = 1.8
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * FLOOR_UV_SCALE
	_materials[key] = m
	return m


## A box whose material is supplied rather than derived from a colour -- the
## floor is the one surface in this cave that is not made of the wall's stone.
func _floor_box(size: Vector3, at: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _floor_material()
	mesh.position = at
	add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = at
	add_child(body)


## Every chamber: a floor plinth (it reaches `skirt` metres down so the cave
## does not float where the hillside falls away below the mouth), a ceiling
## slab, and four walls split around whatever passages meet them.
func _build_chambers() -> void:
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 4.0))
		var outer := Vector2(size.x + _wall_t * 2.0, size.y + _wall_t * 2.0)

		_floor_box(Vector3(outer.x, _skirt, outer.y),
			Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z))
		_box(Vector3(outer.x, 0.8, outer.y),
			Vector3(centre.x, _floor_y + height + 0.4, centre.z), _rock(), true, true)

		for side: String in ["-x", "+x", "-z", "+z"]:
			_build_wall(id, centre, size, height, side, _opening_on(id, side))


## The opening (if any) in one side of one chamber: {width, height}, or {} for
## a solid wall. Derived from the passage table rather than authored twice.
func _opening_on(chamber_id: String, side: String) -> Dictionary:
	for entry: Variant in _config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		var from := str(passage.get("from", ""))
		var to := str(passage.get("to", ""))
		if from != chamber_id and to != chamber_id:
			continue
		var other := to if from == chamber_id else from
		if not _chambers.has(other):
			continue
		if _side_toward(chamber_id, other) == side:
			return {"width": float(passage.get("width", 2.5)),
				"height": float(passage.get("height", 2.6))}
	# The way in. The mouth chamber's outward wall carries the same opening
	# its inward passage does -- one cave mouth, sized like a tunnel.
	if chamber_id == "mouth" and side == "-z":
		var first: Dictionary = _first_passage()
		return {"width": float(first.get("width", 3.0)), "height": float(first.get("height", 3.0))}
	return {}


func _first_passage() -> Dictionary:
	var list: Array = _config.get("passages", [])
	return list[0] as Dictionary if not list.is_empty() else {}


## Which of `a`'s four sides faces `b`. Passages are axis-aligned by contract
## (see burrow_warrens.json's own note), so this is a comparison, not a ray.
func _side_toward(a_id: String, b_id: String) -> String:
	var a := _local_of((_chambers[a_id] as Dictionary).get("at", []))
	var b := _local_of((_chambers[b_id] as Dictionary).get("at", []))
	if absf(b.x - a.x) >= absf(b.z - a.z):
		return "+x" if b.x > a.x else "-x"
	return "+z" if b.z > a.z else "-z"


## One wall, in up to three pieces: two flanks either side of the opening and
## a lintel over it (grandpa_house.gd's doorway technique -- a
## CharacterBody3D cannot walk through a gap that was never cut).
func _build_wall(_id: String, centre: Vector3, size: Vector2, height: float,
		side: String, opening: Dictionary) -> void:
	var along_x := side == "-z" or side == "+z"
	var span := (size.x if along_x else size.y) + _wall_t * 2.0
	var offset := (size.y if along_x else size.x) * 0.5 + _wall_t * 0.5
	var sign_ := -1.0 if side.begins_with("-") else 1.0
	var wall_centre := centre
	if along_x:
		wall_centre.z += sign_ * offset
	else:
		wall_centre.x += sign_ * offset
	var wall_h := height + 1.2  # up past the ceiling slab, so no seam of daylight

	if opening.is_empty():
		_wall_piece(along_x, wall_centre, span, wall_h, 0.0)
		return

	var gap := float(opening.get("width", 2.5))
	var gap_h := minf(float(opening.get("height", 2.6)), height)
	var flank := (span - gap) * 0.5
	if flank > 0.05:
		_wall_piece(along_x, _shift(wall_centre, along_x, -(gap * 0.5 + flank * 0.5)), flank, wall_h, 0.0)
		_wall_piece(along_x, _shift(wall_centre, along_x, gap * 0.5 + flank * 0.5), flank, wall_h, 0.0)
	# The lintel: from the top of the opening to the top of the wall.
	_wall_piece(along_x, wall_centre, gap, wall_h - gap_h, gap_h)


func _shift(at: Vector3, along_x: bool, by: float) -> Vector3:
	if along_x:
		at.x += by
	else:
		at.z += by
	return at


func _wall_piece(along_x: bool, at: Vector3, span: float, height: float, base: float) -> void:
	if span <= 0.01 or height <= 0.01:
		return
	var size := Vector3(span, height, _wall_t) if along_x else Vector3(_wall_t, height, span)
	# Walls reach `skirt` below the floor too, so the outside of the mound
	# reads as rock meeting the hillside rather than as a floating box.
	var extra := 0.0 if base > 0.0 else _skirt
	size.y += extra
	_box(size, Vector3(at.x, _floor_y + base + (height + extra) * 0.5 - extra, at.z), _rock(), true, true)


## The tunnels between chambers: floor, ceiling and two side walls each. The
## gated one also gets a slab across it.
func _build_passages() -> void:
	for entry: Variant in _config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		var from := str(passage.get("from", ""))
		var to := str(passage.get("to", ""))
		if not _chambers.has(from) or not _chambers.has(to):
			push_warning("burrow_warrens.json passage names an unknown chamber (%s -> %s)" % [from, to])
			continue
		var side := _side_toward(from, to)
		var along_x := side == "+x" or side == "-x"
		var a := _local_of((_chambers[from] as Dictionary).get("at", []))
		var b := _local_of((_chambers[to] as Dictionary).get("at", []))
		var a_size := _size_of((_chambers[from] as Dictionary).get("size", []))
		var b_size := _size_of((_chambers[to] as Dictionary).get("size", []))
		var a_edge: float = (a.x + signf(b.x - a.x) * a_size.x * 0.5) if along_x else (a.z + signf(b.z - a.z) * a_size.y * 0.5)
		var b_edge: float = (b.x - signf(b.x - a.x) * b_size.x * 0.5) if along_x else (b.z - signf(b.z - a.z) * b_size.y * 0.5)
		var mid: float = (a_edge + b_edge) * 0.5
		var length := absf(b_edge - a_edge) + _wall_t * 2.0
		var width := float(passage.get("width", 2.5))
		var height := float(passage.get("height", 2.6))
		var lateral := a.z if along_x else a.x
		var centre := Vector3(mid, 0.0, lateral) if along_x else Vector3(lateral, 0.0, mid)
		# CONTENT-0828. Kept so the interior rock pass can stay out of the
		# doorways -- a boulder in a passage mouth is a wall the player has to
		# walk round in the one place a cave gives them no room to.
		_doorways.append([centre, maxf(width, length) * 0.5 + 1.6])
		# CONTENT-0828B. Both ends, because both rooms see their own opening.
		# `along_x` flips: a passage running along x cuts a hole whose WIDTH
		# runs along z, and the reveal pass is told about the hole, not the
		# tunnel.
		for edge: float in [a_edge, b_edge]:
			_openings.append({
				"centre": Vector3(edge, 0.0, lateral) if along_x else Vector3(lateral, 0.0, edge),
				"along_x": not along_x, "width": width, "height": height,
			})

		var floor_size := Vector3(length, _skirt, width + _wall_t * 2.0)
		var ceiling_size := Vector3(length, 0.8, width + _wall_t * 2.0)
		if not along_x:
			floor_size = Vector3(width + _wall_t * 2.0, _skirt, length)
			ceiling_size = Vector3(width + _wall_t * 2.0, 0.8, length)
		_floor_box(floor_size, Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z))
		_box(ceiling_size, Vector3(centre.x, _floor_y + height + 0.4, centre.z), _rock(), true, true)

		for s in [-1.0, 1.0]:
			var wall_at := centre
			var wall_size := Vector3(length, height + _skirt, _wall_t)
			if along_x:
				wall_at.z += s * (width * 0.5 + _wall_t * 0.5)
			else:
				wall_at.x += s * (width * 0.5 + _wall_t * 0.5)
				wall_size = Vector3(_wall_t, height + _skirt, length)
			_box(wall_size, Vector3(wall_at.x, _floor_y + height * 0.5 - _skirt * 0.5, wall_at.z), _rock(), true, true)

		if bool(passage.get("gated", false)):
			_build_vault_door(centre, along_x, width, height)


## The one door in the cave. A rock slab filling the passage, removed for good
## once the guardian is down (`_sync_vault_door`). No prompt, no UI, no key:
## it is a mechanism, the same way SC14's bridge is.
##
## CONTENT-0828: the slab also has to be SEEN, from the den floor, while the
## alpha is still alive. The owner's report is that there is no point going in,
## and a sealed grey box the same colour as the wall it sits in is a wall --
## the player fought the guardian in a room with no visible reason to be there
## and only discovered the branch afterwards, if at all. `seam` is that reason:
## a thin emissive line down the door's own face and a warm light on the vault
## side of it, so what the player can see across the den is a shut way on with
## something lit behind it. That is the whole difference between a fight at the
## end of a corridor and a fight for what is through the door, and it is the
## `encounter context` lever CLAUDE.md names -- no new mesh, no new system, and
## the light dies with the door it belongs to.
func _build_vault_door(centre: Vector3, along_x: bool, width: float, height: float) -> void:
	var size := Vector3(0.6, height, width) if along_x else Vector3(width, height, 0.6)
	var colour := Color(str(_config.get("site", {}).get("vault_door_colour", "#6d5f4a")))
	_vault_door_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	_vault_door_mesh.mesh = box
	# CONTENT-0828B: untextured until now, and a blind critic looking at the den
	# called it exactly what it was -- "a flat untextured pale-tan surface, a
	# different material from every other wall in the build. Proxy geometry left
	# in shot." It is the door the whole payoff is behind and it was the one
	# surface in the room still wearing a flat colour. Same defaulted `textured`
	# argument as the floors and the plinth; the slab is cut stone and now looks
	# like it. The seam and the two spills are what make it read as a DOOR
	# rather than as more wall, and they are unaffected.
	_vault_door_mesh.material_override = _material(colour, 0.0, true)
	_vault_door_mesh.position = Vector3(centre.x, _floor_y + height * 0.5, centre.z)
	_vault_door_mesh.name = "VaultDoor"
	add_child(_vault_door_mesh)
	_build_vault_door_seam(along_x, width, height, size)

	_vault_door = StaticBody3D.new()
	_vault_door.name = "VaultDoorBody"
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	_vault_door.add_child(shape)
	_vault_door.position = _vault_door_mesh.position
	add_child(_vault_door)


## The lit half of the door above. Parented to the door MESH, not to the cave,
## so `_sync_vault_door()` hiding the slab takes the seam and the glow with it
## in one move and there is no second thing to remember to switch off.
##
## All of it is tunable from `site.vault_door_seam`; setting `energy` to 0
## turns the whole treatment off without touching this file.
func _build_vault_door_seam(along_x: bool, width: float, height: float, size: Vector3) -> void:
	var cfg: Dictionary = _config.get("site", {}).get("vault_door_seam", {})
	var energy := float(cfg.get("energy", 1.1))
	if energy <= 0.0:
		return
	var glow := Color(str(cfg.get("colour", "#e0a761")))
	var seam_w := float(cfg.get("width_m", 0.14))

	# The seam runs floor-to-lintel down the middle of the face the den sees.
	# `size` is the slab; the strip is a hair proud of it on both sides so it
	# does not z-fight the face it is drawn on, and it reads from the vault
	# side too for a player walking back out.
	var strip := MeshInstance3D.new()
	strip.name = "VaultDoorSeam"
	var bar := BoxMesh.new()
	bar.size = Vector3(size.x + 0.04, height * 0.86, seam_w) if along_x \
		else Vector3(seam_w, height * 0.86, size.z + 0.04)
	strip.mesh = bar
	var lit := StandardMaterial3D.new()
	lit.albedo_color = glow
	lit.emission_enabled = true
	lit.emission = glow
	lit.emission_energy_multiplier = float(cfg.get("emission", 1.6))
	lit.roughness = 0.6
	strip.material_override = lit
	_vault_door_mesh.add_child(strip)

	# Warm spill on the VAULT side, at knee height: the light of the room the
	# door is shut on, leaking around it. Offset along the passage axis so it
	# sits behind the slab rather than inside it.
	var lamp := OmniLight3D.new()
	lamp.name = "VaultDoorGlow"
	lamp.light_color = glow
	lamp.light_energy = energy
	lamp.omni_range = float(cfg.get("range_m", 6.0))
	var push := float(cfg.get("spill_offset_m", 0.9))
	# `+x` is toward the vault when the passage runs along x (the vault sits at
	# local x=15 against the den's 0); otherwise `+z`. Read off the chamber
	# rather than hardcoded so a relocated cave keeps the light on the right
	# side of its own door.
	var vault_centre := _local_of((_chambers.get("vault", {}) as Dictionary).get("at", []))
	var den_centre := _local_of((_chambers.get("den", {}) as Dictionary).get("at", []))
	var toward: Vector3 = (vault_centre - den_centre).normalized()
	if toward.length() < 0.5:
		toward = Vector3.RIGHT if along_x else Vector3.BACK
	lamp.position = toward * push + Vector3.UP * (height * -0.5 + 0.8)
	_vault_door_mesh.add_child(lamp)

	# CONTENT-0828B. AND A SPILL ON THE DEN SIDE, UNDER THE SLAB.
	#
	# CONTENT-0828's claim for this door is that "what the player can see across
	# the den WHILE THE ALPHA IS STILL ALIVE is a sealed way on with something
	# lit behind it", and its own report flagged that its evidence did not show
	# that -- the frame meant to prove it had the door out of shot, and the
	# claim rested on a head-on stand instead.
	#
	# `tools/_probe_den_door_sightline.gd` measures it rather than photographing
	# it again, from the stands a player actually occupies: the den doorway they
	# enter by, and a ring at engage range around the guardian. The shut door is
	# within the 70-degree camera and unoccluded at ONE of eight. It reads on
	# the way in and then leaves the frame for the whole fight, because the
	# guardian stands in the middle of the room and the door is on a side wall.
	#
	# A seam on the door's own face cannot fix that: it is on the surface the
	# player has turned away from. Light on the FLOOR can, because the floor is
	# in frame from every facing -- it is what the player is standing on. This
	# is a low warm pool at the foot of the slab on the DEN side, which is also
	# the most ordinary thing a shut door with something lit behind it does.
	# Deliberately weak and short-ranged: it is a glow under a door, not a
	# second light source, and the den's authored key still owns the room.
	var under := OmniLight3D.new()
	under.name = "VaultDoorUnderGlow"
	under.light_color = glow
	under.light_energy = energy * float(cfg.get("under_energy_scale", 0.55))
	under.omni_range = float(cfg.get("under_range_m", 4.5))
	under.position = -toward * push + Vector3.UP * (height * -0.5 + 0.25)
	_vault_door_mesh.add_child(under)


## The way in, and the reason this is not just a doorway: the cave floor sits
## `floor_clearance` above the hillside, and a 0.35m sill is a WALL to a
## capsule of the player's radius — measured, not guessed. The first build of
## this cave stopped the smoke test 1.4m short of its own open mouth, dead
## against the floor plinth's edge, with nothing visibly in the way.
##
## So the mouth gets a ramp: ten shallow steps running out from the opening,
## lerping from the cave floor down to the terrain six metres out, each one a
## few centimetres tall. Sampled from the world rather than assumed, so the
## ramp meets the actual hillside wherever the site is retuned to.
func _build_approach_apron() -> void:
	if not _chambers.has("mouth"):
		return
	var width := float(_first_passage().get("width", 3.0)) + 1.6
	var outer_z := _mouth_outer_z()
	var run := 6.0
	var steps := 10
	var end_local := _floor_y - 0.6
	if _world != null and _world.has_method("ground_height_at"):
		var far := to_global(Vector3(0.0, 0.0, outer_z - run))
		var height := float(_world.call("ground_height_at", far.x, far.z))
		if not is_nan(height):
			end_local = height - global_position.y
	for i in steps:
		var t := (float(i) + 0.5) / float(steps)
		var z := outer_z - t * run
		var top: float = lerpf(_floor_y, end_local, t)
		# Same dirt as the chambers' own floors. This ramp is OUTDOORS, in
		# daylight, beside textured terrain and the mound's own boulders, and
		# a flat untextured colour reads worse out there than it does in the
		# dark -- it is the last thing a player sees before going in.
		_floor_box(Vector3(width, _skirt, run / float(steps) + 0.15),
			Vector3(0.0, top - _skirt * 0.5, z))

	# GRASS-INDOORS, owner 2026-08-28. The runtime ground cover
	# (`scripts/world/grass_field.gd`) is procedural and camera-relative, so it
	# cannot be authored around placed geometry the way the baked scatter is --
	# it grew straight up through these steps, on the one approach every player
	# who enters the Warrens walks down. It has to be told, and this function is
	# the only thing that knows where the ramp is and how long it runs, so it
	# tells it here rather than somebody transcribing the numbers into a config.
	# The marker is a bare Node3D at the ramp's own midpoint, because the ramp
	# itself is ten separate boxes and the field wants one circle.
	var apron := Node3D.new()
	apron.name = "ApronGround"
	apron.position = Vector3(0.0, 0.0, outer_z - run * 0.5)
	add_child(apron)
	apron.set_meta(GRASS_FIELD.CLEAR_RADIUS_META,
			Vector2(width, run).length() * 0.5 + APRON_CLEAR_MARGIN)
	apron.add_to_group(GRASS_FIELD.CLEAR_GROUP)


func _build_lights() -> void:
	for entry: Variant in _config.get("lights", []):
		var spec: Dictionary = entry as Dictionary
		var at := _local_of(spec.get("at", []))
		var light := OmniLight3D.new()
		light.position = Vector3(at.x, _floor_y + float(spec.get("y", 3.0)), at.z)
		light.light_color = Color(str(spec.get("colour", "#8a8a8a")))
		light.light_energy = float(spec.get("energy", 0.5))
		light.omni_range = float(spec.get("range", 10.0))
		light.shadow_enabled = false
		add_child(light)


## The camera swap, exactly as grandpa_house.gd does it: one Area3D over the
## whole footprint, handed back on exit.
func _build_interior_area() -> void:
	if _footprint.is_empty():
		return
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for rect: Array in _footprint:
		min_x = minf(min_x, float(rect[0]))
		min_z = minf(min_z, float(rect[1]))
		max_x = maxf(max_x, float(rect[2]))
		max_z = maxf(max_z, float(rect[3]))
	var area := Area3D.new()
	area.name = "Interior"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(max_x - min_x, 8.0, max_z - min_z)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3((min_x + max_x) * 0.5, _floor_y + 4.0, (min_z + max_z) * 0.5)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)


## OP23-02: same race `stronghold.gd::_combat_owns_the_camera()` guards
## against, for the same shared Area3D pattern -- a wild fight can open
## while the player is crossing this room's own threshold, and this handler
## used to reassign the rig to the player mid-fight when that happened.
func _combat_owns_the_camera() -> bool:
	var manager: Node = _world.get_node_or_null(^"CombatManager") if _world != null else null
	return manager != null and manager.has_method("is_fighting") and bool(manager.call("is_fighting"))


func _on_body_entered(body: Node3D) -> void:
	if body != _player or _camera_rig == null or _combat_owns_the_camera():
		return
	_camera_rig.call("set_target", _player, INTERIOR_PROFILE)


func _on_body_exited(body: Node3D) -> void:
	if body != _player or _camera_rig == null or _combat_owns_the_camera():
		return
	_camera_rig.call("set_target", _player, {})


## --- contents --------------------------------------------------------------

func _build_deposits() -> void:
	for entry: Variant in _config.get("deposits", []):
		var spec: Dictionary = entry as Dictionary
		var at := _local_of(spec.get("at", []))
		var node: Node3D = HARVEST_NODE.new()
		node.name = "Deposit_%s_%d" % [str(spec.get("item", "rootstone")), get_child_count()]
		node.position = Vector3(at.x, _floor_y, at.z)
		add_child(node)
		node.call("setup", spec)


## Nothing grows through a cave.
##
## `data/config/bands/band2_stone_and_root/vegetation.json` authors a clearing
## at this site, and that clearing does not take effect until the Gate D
## coordinator re-bakes the scatter -- a band clearing does not invalidate the
## bake (GATE_D_LANE_CONTRACT.md sec4, inherited by every lane, not this one's
## to fix). Until then the stale bake stands its trees exactly where the cave
## now is, and the driven run proved what that costs: `tools/_probe_warrens_run.gd`
## walked 70m from the road, reached the entrance, and stopped dead against a
## `CommonTree_3` growing in the doorway.
##
## So the cave clears its own ground at build time, through
## `vegetation.gd::clear_area()`. The radius is the authored clearing's own, so
## the two say the same thing and the re-bake changes nothing about what the
## player sees here -- it just does it properly, offline, for the grass too.
func _clear_the_ground_the_cave_stands_on() -> void:
	var radius := float(_config.get("site", {}).get("clear_radius_m", 0.0))
	if radius <= 0.0 or _world == null or not is_instance_valid(_world):
		return
	var vegetation: Node = _world.get_node_or_null(^"Vegetation")
	if vegetation == null or not vegetation.has_method("clear_area"):
		return
	var removed := int(vegetation.call("clear_area", global_position, radius))
	if removed > 0:
		print("[warrens] cleared %d scattered trees/rocks inside the %.0fm site radius" % [
			removed, radius])


## The outcrop the cave stands in.
##
## The chambers, walls and ceiling slabs are boxes, and at this site most of
## that mass is ABOVE ground (see `burrow_warrens.json`'s `_comment_resiting`:
## there is no hillside here to put it in). The first capture round showed the
## consequence plainly -- a grey rectangular slab standing in a meadow. This
## dresses that mass into stone: boulders from the same nature family the
## corridor is already scattered with, around the perimeter and over the roof,
## sunk so they read as rock in the ground rather than props resting on a box.
##
## Deterministic, from the config's own `seed` -- the same rock stands in the
## same place every boot, which is the promise `encounter_director.gd` makes
## about creatures and `scatter_rules.gd` makes about grass. Nothing here has a
## collider: the cave's own walls already stop the player, a second collision
## shell around them would catch them on nothing visible, and a boulder that
## is decoration should not be a place to get stuck.
##
## The `skip_front_m` metres in front of the mouth stay clear. An outcrop that
## swallows its own entrance is worse than a bare box, because the box at
## least has a visible hole in it.
func _build_mound() -> void:
	var mound: Dictionary = _config.get("mound", {})
	var models: Array = mound.get("models", [])
	if mound.is_empty() or models.is_empty() or _footprint.is_empty():
		return
	var loaded: Array[PackedScene] = []
	for path: Variant in models:
		var packed: PackedScene = load(str(path)) as PackedScene
		if packed != null:
			loaded.append(packed)
	if loaded.is_empty():
		push_warning("the warrens mound names no model that loads; the cave stands bare")
		return

	var holder := Node3D.new()
	holder.name = "Mound"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(mound.get("seed", 63220))
	var sink := float(mound.get("sink_m", 1.0))
	var tint := Color(str(mound.get("tint", "#ffffff")))
	var skip_front := float(mound.get("skip_front_m", 9.0))
	var mouth_z := _mouth_outer_z()

	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for rect: Array in _footprint:
		min_x = minf(min_x, float(rect[0]) - _wall_t)
		min_z = minf(min_z, float(rect[1]) - _wall_t)
		max_x = maxf(max_x, float(rect[2]) + _wall_t)
		max_z = maxf(max_z, float(rect[3]) + _wall_t)

	# The perimeter, walked as four edges at a fixed spacing.
	var spacing := maxf(float(mound.get("perimeter_spacing_m", 4.5)), 1.0)
	var perimeter_scale: Array = mound.get("perimeter_scale", [2.6, 4.4])
	# Two courses, because one is a hedge on the skyline with a bare grey wall
	# under it -- the first capture round's own picture. The lower course
	# stands on the ground the wall comes out of, the upper on the shoulder
	# just under the roof, and between them the slab is broken all the way up.
	var courses := maxi(int(mound.get("perimeter_courses", 1)), 1)
	var tallest := 0.0
	for id_value: String in _chambers:
		tallest = maxf(tallest, float((_chambers[id_value] as Dictionary).get("height", 4.0)))
	# The lowest course sits BELOW the floor, on the ground the plinth stands
	# on, or the base of the wall stays a grey band under the rock -- again,
	# the capture round's own picture.
	var base_drop := float(mound.get("perimeter_base_drop_m", 1.6))
	for course in courses:
		var lift: float = -base_drop if courses <= 1 else \
			lerpf(-base_drop, tallest - 1.0, float(course) / float(courses - 1))
		for edge in 4:
			var along_x := edge < 2
			var length: float = (max_x - min_x) if along_x else (max_z - min_z)
			var steps := maxi(int(length / spacing), 1)
			for step in steps + 1:
				var t := float(step) / float(steps)
				var at := Vector3.ZERO
				if along_x:
					at = Vector3(lerpf(min_x, max_x, t), _floor_y + lift,
						min_z if edge == 0 else max_z)
				else:
					at = Vector3(min_x if edge == 2 else max_x, _floor_y + lift,
						lerpf(min_z, max_z, t))
				if at.z < mouth_z + skip_front and absf(at.x) < skip_front:
					continue
				_place_rock(holder, loaded, rng, at, perimeter_scale, sink, tint)

	_build_site_skirt(holder, mound, rng)

	# And the roofs: one grid per chamber, at that chamber's own ceiling.
	var roof_spacing := maxf(float(mound.get("roof_spacing_m", 7.0)), 1.0)
	var roof_scale: Array = mound.get("roof_scale", [2.2, 3.8])
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var top: float = _floor_y + float(chamber.get("height", 4.0)) + 0.8
		var steps_x := maxi(int(size.x / roof_spacing), 1)
		var steps_z := maxi(int(size.y / roof_spacing), 1)
		for ix in steps_x + 1:
			for iz in steps_z + 1:
				var at := Vector3(
					centre.x + size.x * (float(ix) / float(steps_x) - 0.5),
					top,
					centre.z + size.y * (float(iz) / float(steps_z) - 0.5))
				if at.z < mouth_z + skip_front and absf(at.x) < skip_front:
					continue
				_place_rock(holder, loaded, rng, at, roof_scale, sink, tint)


## CONTENT-0828. What turns these rooms from boxes into a cave.
##
## The owner localised the "some locations look lame" complaint on 2026-08-28
## and it is a claim about METHOD, not about assets:
##
##   *"burrow warrens and the castle are the lame looking locations. basically
##   everywhere we had to build an under ground or build a building"*
##
## The terrain, the scatter and the grass drew no complaint. The two spaces
## this project ASSEMBLES did. And the before-frames of this cave say exactly
## why: `docs/evidence/content-0828/04-vault-prize-after.png` is a perfect
## rectangular box -- four flat walls meeting at hard 90-degree corners, a flat
## ceiling, a flat floor, one triplanar texture at one scale across all of it.
## The meadow next door has hundreds of pieces of variety per comparable area.
## The room does not read as unfinished because the rock texture is bad; it
## reads as unfinished because a cave does not have corners.
##
## So this breaks the three junctions that say "box", and nothing else:
##
##   * the wall/floor line, with boulders banked along the inside of each wall;
##   * the wall/ceiling line, with rock tucked into the ceiling corners;
##   * the flat floor plane, with scree thinning inward from the walls.
##
## Three rules keep it from becoming the problem it is fixing. **It hugs the
## walls** -- everything sits within `edge_band_m` of a wall face, so the
## middle of every room is untouched and a fight in the den still has the arena
## `combat_arena_bounds_at()` promises it. **It stays out of the doorways**
## (`_doorways`, recorded by `_build_passages()`), because a boulder in a
## passage mouth is a wall in the one place a cave gives no room to walk round.
## And **it has no colliders** -- the models are plain glTF instances, the same
## as `_build_site_skirt()`'s ground cover, whose own comment states the rule
## this follows: dressing, and a pebble that stops a player is a bug.
##
## Deliberately the SAME nature family the outcrop outside is built from and
## tinted with the same `mound.tint`, per D24's one-nature-family rule: the
## stone inside the hill and the stone showing above it are the same stone.
## No new mesh, nothing sourced, and nothing here needs owner art -- this is
## the composition-and-dressing half the playtest's own 4a says is available
## while modelling is blocked.
func _build_interior_rock() -> void:
	var cfg: Dictionary = _config.get("interior_rock", {})
	if cfg.is_empty() or not bool(cfg.get("enabled", true)):
		return
	var models: Array[PackedScene] = _load_models(cfg.get("models", []))
	var scree_models: Array[PackedScene] = _load_models(cfg.get("scree_models", []))
	if models.is_empty():
		return

	var holder := Node3D.new()
	holder.name = "InteriorRock"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.get("seed", 828828))
	# The interior's OWN tint, not the mound's. See this block's `_comment_tint`
	# in burrow_warrens.json: the mound value was tuned against rock standing in
	# direct sun, and under the cave's dim cool pools it let the nature pack's
	# mint-grey back through -- the exact green a blind critic called "a heap of
	# enormous cabbages" on the mound, now inside the room. Falls back to the
	# mound's value so the key stays optional.
	var tint := Color(str(cfg.get("tint",
		_config.get("mound", {}).get("tint", "#ffffff"))))
	var band := float(cfg.get("edge_band_m", 1.7))
	var placed := 0

	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 4.0))
		var half := Vector2(size.x * 0.5, size.y * 0.5)

		# --- the wall/floor line ------------------------------------------
		# Walked as four edges at a fixed spacing, the same way the mound walks
		# its perimeter, so the two read as one continuous rock mass either
		# side of the wall rather than two unrelated decisions.
		var step := maxf(float(cfg.get("wall_spacing_m", 3.2)), 1.0)
		var base_scale: Array = cfg.get("wall_scale", [0.8, 1.5])
		for edge in 4:
			var along_x := edge < 2
			var length: float = size.x if along_x else size.y
			var steps := maxi(int(length / step), 1)
			for i in steps + 1:
				var t := float(i) / float(steps)
				var inward := rng.randf_range(0.15, band)
				var at := Vector3.ZERO
				if along_x:
					var z_side: float = -1.0 if edge == 0 else 1.0
					at = Vector3(centre.x + lerpf(-half.x, half.x, t), _floor_y,
						centre.z + z_side * (half.y - inward))
				else:
					var x_side: float = -1.0 if edge == 2 else 1.0
					at = Vector3(centre.x + x_side * (half.x - inward), _floor_y,
						centre.z + lerpf(-half.y, half.y, t))
				at.x += rng.randf_range(-0.5, 0.5)
				at.z += rng.randf_range(-0.5, 0.5)
				if _blocks_a_doorway(at):
					continue
				# Sunk so the boulder grows out of the floor rather than
				# standing on it, which is the difference between rock and
				# furniture. Capped against the room's own height so a wall
				# boulder can never become a ceiling one.
				var drop := float(cfg.get("wall_sink_m", 0.45))
				_place_interior_rock(holder, models, rng, at + Vector3.DOWN * drop,
					base_scale, tint, height * float(cfg.get("wall_height_cap", 0.55)),
					float(cfg.get("wall_width_cap_m", 1.9)))
				placed += 1

		# --- the wall/ceiling line ----------------------------------------
		# Four corners only. The ceiling's MIDDLE stays clear on purpose: that
		# is where the mound's roof rocks used to hang through, and a frame
		# with rock over the guardian's head is the frame this pass exists to
		# stop producing.
		var corner_scale: Array = cfg.get("corner_scale", [1.1, 1.9])
		for cx in [-1.0, 1.0]:
			for cz in [-1.0, 1.0]:
				var at := Vector3(
					centre.x + cx * (half.x - rng.randf_range(0.2, 1.0)),
					_floor_y + height + float(cfg.get("corner_lift_m", 0.35)),
					centre.z + cz * (half.y - rng.randf_range(0.2, 1.0)))
				if _blocks_a_doorway(at):
					continue
				_place_interior_rock(holder, models, rng, at, corner_scale, tint,
					height * 0.4, float(cfg.get("corner_width_cap_m", 2.2)))
				placed += 1

		# --- the floor plane ----------------------------------------------
		# Weighted to the walls with the same `pow(randf(), n)` the site skirt
		# uses and for the same reason: what reads as scree is thick at the
		# foot of the rock and thin toward the middle of the room.
		if not scree_models.is_empty():
			var scree_count := int(cfg.get("scree_per_chamber", 18))
			var scree_scale: Array = cfg.get("scree_scale", [0.35, 0.95])
			for i in scree_count:
				var edge_bias: float = 1.0 - pow(rng.randf(), 2.2)
				var side := rng.randi() % 2
				var at := Vector3(
					centre.x + rng.randf_range(-half.x, half.x),
					_floor_y - 0.05,
					centre.z + rng.randf_range(-half.y, half.y))
				# Pull it toward whichever wall pair this piece belongs to.
				if side == 0:
					at.z = centre.z + signf(at.z - centre.z) * lerpf(0.3, half.y - 0.2, edge_bias)
				else:
					at.x = centre.x + signf(at.x - centre.x) * lerpf(0.3, half.x - 0.2, edge_bias)
				if _blocks_a_doorway(at):
					continue
				_place_interior_rock(holder, scree_models, rng, at, scree_scale, tint,
					float(cfg.get("scree_height_cap_m", 0.5)),
					float(cfg.get("scree_width_cap_m", 1.0)))
				placed += 1

	if placed > 0:
		print("[warrens] %d pieces of interior rock across %d chambers" % [
			placed, _chambers.size()])


## CONTENT-0828B. The shared constructed-interior method, in the cave's own
## vocabulary.
##
## `_build_interior_rock()` above already broke this cave's wall/floor and
## wall/ceiling LINES with banked stone, and its own report was honest about
## what that left: "the walls themselves are still flat planes and the ceiling
## is still a slab between its corners... it does not give the space vertical
## interest, level changes, or a silhouette." That remainder is what this call
## is for, and it is the same call `stronghold.gd` makes -- the owner named
## constructed space as a class, so the answer is one method with two
## vocabularies rather than two dressing passes.
##
## The cave's vocabulary is `jitter` above zero (rock ribbing leans and varies;
## masonry does not) and its own stone for every role: `_material(colour, 0,
## true)` is the triplanar Rock030 the chamber walls already wear, which is the
## finding the previous pass paid two rounds for -- a tint MULTIPLIED over the
## nature pack's mint-grey stays mint under a 0.3-1.5 energy pool, and only
## wearing the wall's actual material makes a member read as this cave's stone.
##
## The role tints are small deliberate value steps rather than one flat stone,
## because these rooms are lit by shadowless omnis (`_build_lights`) and no
## light in here is going to model the form for us: a member the same value as
## the wall behind it is invisible however well it is shaped.
## The structure members' own material.
##
## NOT `_material(colour, 0, true)`, and the frames are why. That function
## lerps its colour 75% toward `ROCK_TINT` -- a MAT-BLOCKOUT round-2 decision
## tuned for the WALLS, and correct for them -- which leaves a member only a
## quarter of its configured colour. The first round of this pass used it and
## every shaft came back the same value as the wall behind it: present in the
## geometry, invisible in the photograph.
##
## That matters more here than anywhere else in the cave, because every light
## in these chambers is a shadowless omni (`_build_lights`). Outdoors the sun
## models a proud form for free; in here a box standing 32cm off a wall is lit
## almost exactly like the wall, so if the VALUE does not separate them,
## nothing will. So the member keeps the cave's own stone texture -- that
## finding stands, and a tinted nature-pack rock still comes back mint -- and
## takes its colour at nearly full strength instead.
##
## The coarser `uv1_scale` is the second separator and costs nothing: the same
## stone at a different grain reads as a different piece of stone, which is
## what a rib standing against a wall actually is.
func _structure_material(colour: Color) -> StandardMaterial3D:
	var key := "structure_%s" % colour.to_html()
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.95
	m.albedo_texture = ROCK_ALBEDO
	m.albedo_color = colour.lerp(ROCK_TINT, 0.2)
	m.normal_enabled = true
	m.normal_texture = ROCK_NORMAL
	m.normal_scale = 2.4
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * (ROCK_UV_SCALE * 0.55)
	_materials[key] = m
	return m


func _build_structure() -> void:
	var cfg: Dictionary = _config.get("interior_structure", {})
	if cfg.is_empty():
		return
	var chambers: Array = []
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		chambers.append({
			"id": id, "centre": centre,
			"size": _size_of(chamber.get("size", [])),
			"height": float(chamber.get("height", 4.0)), "open": false,
		})
	var placed: int = INTERIOR_STRUCTURE.new().dress(self, {
		"chambers": chambers, "doorways": _doorways, "openings": _openings,
		"floor_y": _floor_y, "config": cfg,
		"material_for": func(role: String) -> StandardMaterial3D:
			return _structure_material(_structure_colour(role)),
	})
	if placed > 0:
		print("[warrens] %d structural members across %d chambers" % [placed, _chambers.size()])


## One value step per role, off this cave's own rock colour. Darker where a
## member should sit back, lighter where it should catch what little light
## there is. Tunable from `interior_structure.tints`; the defaults are the
## values the blind rounds settled on.
func _structure_colour(role: String) -> Color:
	var tints: Dictionary = _config.get("interior_structure", {}).get("tints", {})
	if tints.has(role):
		return Color(str(tints[role]))
	# Structure is a LIGHTER stone than the infill it stands against. That is
	# not decoration: it is what dressed stone against rubble actually looks
	# like, and under shadowless omnis (`_build_lights`) the value is the only
	# cue there is. Round 1 returned the wall's own `site.rock` for shafts and
	# corners -- the member was literally the same colour as the wall -- and
	# the frames showed exactly nothing.
	#
	# ROUND 2 THEN MADE THE COURSE NEARLY BLACK, on the theory that a recessed
	# line reads as a shadow. It does, when there are shadows. With none, a
	# dark band on a lit wall is not a recess, it is a painted stripe -- and in
	# the stronghold's daylit courtyard the same value read as an arrow slit,
	# which is an actively wrong thing for a wall to appear to have. Every
	# member is the light dressed stone now and the geometry's own edges do the
	# rest, which is the only version of this that survives both a torchlit
	# cave and a yard under the real sun.
	#
	# The ribs are the ONE exception and the reason is per-consumer rather than
	# general: a rib is read against the CEILING it hangs from, and this cave's
	# ceiling is the same pale rock as its walls. Darker is what separates them
	# here. `stronghold.gd::_structure_colour` makes the opposite call for the
	# same reason -- its ceilings are dark, so its ribs are light.
	var rock := _rock()
	# The corbel goes with the rib it carries -- they are one piece of structure
	# and a bracket in a different stone from its own beam reads as a mistake.
	if role == "rib" or role == "corbel":
		return rock.darkened(0.28)
	return rock.lightened(0.34)


## Is this local point in a passage mouth?
func _blocks_a_doorway(at: Vector3) -> bool:
	for entry: Array in _doorways:
		var centre: Vector3 = entry[0]
		if Vector2(at.x - centre.x, at.z - centre.z).length() < float(entry[1]):
			return true
	return false


## One piece of interior rock. `height_cap` above zero re-scales the piece down
## if it would stand taller than that -- measured, not assumed, because these
## models arrive at different sizes and a wall boulder that reaches the ceiling
## is the intrusion this pass replaced.
func _place_interior_rock(holder: Node3D, models: Array[PackedScene],
		rng: RandomNumberGenerator, at: Vector3, scale_range: Array,
		tint: Color, height_cap: float, width_cap: float) -> void:
	var art: Node3D = models[rng.randi() % models.size()].instantiate() as Node3D
	if art == null:
		return
	var low := float(scale_range[0]) if scale_range.size() > 0 else 0.8
	var high := float(scale_range[1]) if scale_range.size() > 1 else 1.4
	art.scale = Vector3.ONE * rng.randf_range(low, high)
	art.position = at
	art.rotation = Vector3(
		rng.randf_range(-0.25, 0.25),
		rng.randf_range(-PI, PI),
		rng.randf_range(-0.25, 0.25))
	holder.add_child(art)
	# Measured, then re-scaled to fit -- twice, because a boulder can be wrong
	# in two directions and round 2 of this pass only checked one. `height_cap`
	# kept a wall rock from becoming a ceiling rock and said nothing about
	# WIDTH, and the frames showed the cost: a five-metre-wide rock sitting
	# correctly against the den wall still reaches two and a half metres into
	# the room, and one of them ended up between the camera and the guardian --
	# the exact failure this pass replaced. Both caps are applied to the
	# measured bounds rather than to the scale factor, because these models
	# arrive at different sizes and a scale number means nothing across them.
	var fit := 1.0
	var box := _bounds_of(art)
	if height_cap > 0.0 and box.size.y > height_cap and box.size.y > 0.01:
		fit = minf(fit, height_cap / box.size.y)
	if width_cap > 0.0:
		var widest: float = maxf(box.size.x, box.size.z)
		if widest > width_cap and widest > 0.01:
			fit = minf(fit, width_cap / widest)
	if fit < 1.0:
		art.scale *= fit
	_wear_the_cave_stone(art, tint)


## Round 2 of this pass tinted these rocks and the frames said no twice: at
## `mound.tint` and again at a much warmer value, the nature pack's mint-grey
## came back through and the cave filled with green.
##
## `_tint_rock()` MULTIPLIES `albedo_color`, which is the right tool outside --
## it keeps each rock's own shading and texture variation under strong sun, and
## two blind rounds tuned the mound with it. Inside, under 0.3-1.5 energy
## pools, the multiply is doing almost none of the work: what survives is the
## model's own texture, and that texture is mint.
##
## So stop guessing at multipliers and give the interior rock the SAME material
## the wall behind it is made of -- `_material(colour, 0, textured)`, the
## triplanar `Rock030` stone every chamber wall and ceiling already wears
## (MAT-BLOCKOUT). Triplanar is what makes this legal on models whose UVs were
## authored for something else: it projects from world space and needs no UVs
## at all, which is the same reason the walls use it on primitive boxes of
## varying size. The result is not a rock that has been tinted to look like the
## cave. It is the cave's own stone, in a rock shape.
##
## `tint` is kept as the per-piece variation: each rock takes the site's rock
## colour nudged toward its own value, so the bank along a wall is not one flat
## sheet of identical stone.
func _wear_the_cave_stone(node: Node, tint: Color) -> void:
	var stone := _material(_rock().lerp(tint, 0.35), 0.0, true)
	for child in _mesh_boxes_nodes(node):
		var instance := child as MeshInstance3D
		var mesh := instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			instance.set_surface_override_material(surface, stone)


func _mesh_boxes_nodes(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_mesh_boxes_nodes(child))
	return found


func _load_models(paths: Variant) -> Array[PackedScene]:
	var loaded: Array[PackedScene] = []
	for path: Variant in (paths if paths is Array else []):
		var packed: PackedScene = load(str(path)) as PackedScene
		if packed != null:
			loaded.append(packed)
	return loaded


## Ground cover for the ground this site cleared.
##
## `_clear_the_ground_the_cave_stands_on()` takes every scattered tree, rock
## and grass tuft inside the site radius, because otherwise they stand in the
## cave. What it leaves is a bare ring, and the first blind pass named ground
## density as the single loudest gap between these frames and the references.
## So the site plants its own: broken rock and low cover banked against the
## outcrop, thinning with distance, densest where debris and shade would put
## it. Deterministic from the mound's own seed, and never collidable -- a
## pebble that stops a player is a bug, and the cave's walls already do the
## stopping that matters.
func _build_site_skirt(holder: Node3D, mound: Dictionary, rng: RandomNumberGenerator) -> void:
	var models: Array = mound.get("skirt_models", [])
	var count := int(mound.get("skirt_count", 0))
	if models.is_empty() or count <= 0:
		return
	var loaded: Array[PackedScene] = []
	for path: Variant in models:
		var packed: PackedScene = load(str(path)) as PackedScene
		if packed != null:
			loaded.append(packed)
	if loaded.is_empty():
		return
	var reach := float(mound.get("skirt_reach_m", 30.0))
	var scale_range: Array = mound.get("skirt_scale", [0.7, 2.0])
	var low := float(scale_range[0])
	var high := float(scale_range[1])
	var planted := 0
	for i in count:
		# Weighted toward the outcrop: sqrt would spread evenly over the disc,
		# so this deliberately does NOT use it -- what reads as a rock skirt is
		# thick at the foot of the rock and thin at the edge of the clearing.
		var distance: float = reach * pow(rng.randf(), 1.7)
		var angle := rng.randf() * TAU
		var local := Vector3(sin(angle) * distance, 0.0, cos(angle) * distance)
		# Nothing inside the cave's own footprint, and nothing in the doorway.
		if _inside_footprint(local) or (local.z < _mouth_outer_z() + 5.0 and absf(local.x) < 4.0):
			continue
		var ground := _site_ground(local)
		if is_nan(ground):
			continue
		var art: Node3D = loaded[rng.randi() % loaded.size()].instantiate() as Node3D
		if art == null:
			continue
		art.position = Vector3(local.x, ground - 0.08, local.z)
		art.rotation = Vector3(0.0, rng.randf_range(-PI, PI), 0.0)
		art.scale = Vector3.ONE * rng.randf_range(low, high)
		holder.add_child(art)
		planted += 1
	if planted > 0:
		print("[warrens] planted %d pieces of ground cover around the site" % planted)


## Is this local point over one of the cave's own rooms?
func _inside_footprint(local: Vector3) -> bool:
	for rect: Array in _footprint:
		if local.x >= float(rect[0]) - _wall_t and local.x <= float(rect[2]) + _wall_t \
				and local.z >= float(rect[1]) - _wall_t and local.z <= float(rect[3]) + _wall_t:
			return true
	return false


## Terrain height under a LOCAL point, in this node's own local Y -- the
## meadow outside the cave, not the cave floor.
func _site_ground(local: Vector3) -> float:
	if _world == null or not _world.has_method("ground_height_at"):
		return NAN
	var at := to_global(Vector3(local.x, 0.0, local.z))
	var ground := float(_world.call("ground_height_at", at.x, at.z))
	if is_nan(ground):
		return NAN
	return ground - global_position.y


## One boulder. `at.y` is the height its BASE should sit around; `sink` pulls
## it down into whatever it is standing on so there is no seam under it.
func _place_rock(holder: Node3D, models: Array[PackedScene], rng: RandomNumberGenerator,
		at: Vector3, scale_range: Array, sink: float, tint: Color) -> void:
	var art: Node3D = models[rng.randi() % models.size()].instantiate() as Node3D
	if art == null:
		return
	var low := float(scale_range[0]) if scale_range.size() > 0 else 2.0
	var high := float(scale_range[1]) if scale_range.size() > 1 else 3.0
	var scale_value := rng.randf_range(low, high)
	art.scale = Vector3.ONE * scale_value
	art.position = Vector3(
		at.x + rng.randf_range(-1.2, 1.2),
		at.y - sink,
		at.z + rng.randf_range(-1.2, 1.2))
	art.rotation = Vector3(
		rng.randf_range(-0.18, 0.18),
		rng.randf_range(-PI, PI),
		rng.randf_range(-0.18, 0.18))
	holder.add_child(art)
	_keep_rock_out_of_the_rooms(art)
	_tint_rock(art, tint)


## CONTENT-0828. The one thing `_place_rock()` never checked: whether the
## boulder it just dropped ends up INSIDE the cave.
##
## Found in frames, not in reasoning. The 2026-08-28 before-capture of the den
## and the vault came back with huge faceted olive slabs filling both rooms,
## one of them standing between the camera and the guardian in the single shot
## that exists to show the guardian. They are these rocks.
##
## The arithmetic that puts them there. Roof rocks are placed at `top =
## _floor_y + chamber height + 0.8` and then moved DOWN by `sink_m` (1.2), so
## the model's own origin lands 0.4 m BELOW the ceiling it is supposed to be
## sitting on -- and is then scaled by up to `roof_scale`'s 2.8. Nothing
## measured the result. Whatever hangs below that origin hangs into the room,
## multiplied by the scale factor. Perimeter rocks reach the same way from the
## side: their top course sits at `_floor_y + tallest - 1.0` on the footprint's
## bounding-box edge, which for the den's far wall, the vault's +x wall and the
## warren's -x wall IS a chamber wall, with 1.2 m of jitter and up to 3.6x
## scale to carry it through.
##
## BAND2-63-WARRENS is where this became visible: it lowered every ceiling by
## 0.6-1.2 m to stop the cave reading as a six-metre slab on the skyline, which
## was right, and neither `sink_m` nor the roof grid was re-checked against the
## new ceilings.
##
## The fix is the technique this codebase already uses for exactly this class
## of problem -- `creature_body.gd::_fit()` measures an imported model's bounds
## rather than trusting a hand-tuned offset per asset, because every model
## arrives differently. Same here: measure what was actually instantiated and
## scaled, and if its underside is below the ceiling of a chamber it stands
## over, lift it until it is not. A rock over open ground is untouched, so the
## outcrop's silhouette from the road is the silhouette that was tuned.
func _keep_rock_out_of_the_rooms(art: Node3D) -> void:
	var box := _bounds_of(art)
	if box.size == Vector3.ZERO:
		return
	# The rock's OWN extent, not the point it was placed at. The first version
	# of this tested only `art.position`, and the vault came back still full of
	# rock: perimeter boulders are placed ON the footprint's bounding-box edge
	# with up to 1.2 m of jitter, so their origin sits legitimately OUTSIDE the
	# room while up to 3.6x of scaled geometry reaches back through the wall.
	# Three walls do this and they are the three the bounding box touches --
	# the den's far wall, the vault's +x wall and the warren's -x wall.
	var ceiling := _ceiling_over_box(box)
	if is_inf(ceiling):
		return
	if box.position.y < ceiling:
		art.position.y += ceiling - box.position.y


## The highest ceiling of any chamber this box actually reaches INTO, or -INF
## when it clears every room.
##
## Tested against each chamber's INTERIOR rect, deliberately without the wall
## thickness the other footprint tests add. A boulder standing against the
## outside of a wall is the outcrop doing its job -- two blind rounds tuned
## those courses so the cave's mass is broken all the way up rather than
## reading as a grey slab with a hedge on top. Only geometry that comes past
## the wall's inner face is in a room, and only that is moved.
##
## Highest rather than nearest because chamber rects are allowed to touch: a
## rock over the seam between two rooms has to clear the taller of them.
func _ceiling_over_box(box: AABB) -> float:
	var best := -INF
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		if box.position.x + box.size.x < centre.x - size.x * 0.5:
			continue
		if box.position.x > centre.x + size.x * 0.5:
			continue
		if box.position.z + box.size.z < centre.z - size.y * 0.5:
			continue
		if box.position.z > centre.z + size.y * 0.5:
			continue
		best = maxf(best, _floor_y + float(chamber.get("height", 4.0)))
	return best


## The AABB of everything a placed model draws, in THIS node's own local frame
## -- the frame `_floor_y` and the chamber rects are in.
##
## Walked with an accumulated transform rather than read off
## `global_transform`, because `_build_mound()` runs during `build()` and must
## not depend on whether this node is in the tree yet. `art.transform` is the
## starting frame because `Mound` sits at identity under this node.
func _bounds_of(art: Node3D) -> AABB:
	var box := AABB()
	var seeded := false
	for pair: Array in _mesh_boxes(art, art.transform):
		var found: AABB = pair[0]
		box = found if not seeded else box.merge(found)
		seeded = true
	return box if seeded else AABB()


func _mesh_boxes(node: Node, xform: Transform3D) -> Array:
	var found: Array = []
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			found.append([xform * instance.get_aabb()])
	for child in node.get_children():
		var child_3d := child as Node3D
		found.append_array(_mesh_boxes(child, xform * child_3d.transform if child_3d != null else xform))
	return found


## The nature pack's rocks ship a cool mint-grey. Beside this cave's own warm
## dark stone that read, to a blind critic, as "a heap of enormous cabbages" --
## the outcrop and the cave it dresses have to be made of the same thing. The
## albedo is MULTIPLIED rather than replaced so the model keeps its own shading
## and texture variation, and each source material is duplicated once and
## cached, so a hundred boulders sharing one material still cost one.
func _tint_rock(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface in mesh.get_surface_count():
				var source: Material = mesh_instance.get_active_material(surface)
				if source == null:
					continue
				var key := "%s#%d" % [str(source.resource_path), source.get_instance_id()]
				if not _materials.has(key):
					var copy: StandardMaterial3D = source.duplicate() as StandardMaterial3D
					if copy == null:
						continue
					copy.albedo_color = copy.albedo_color * tint
					_materials[key] = copy
				mesh_instance.set_surface_override_material(surface, _materials[key])
	for child in node.get_children():
		_tint_rock(child, tint)


## The cave's authored props: crates, a barrel, a pickaxe, a bag, a tipped
## bucket. Prompt 63's required-dungeon list asks for `evidence of Team Tether
## activity` inside the warrens itself, and there was none down here -- the
## band's only Team Tether trace was a prop cluster out at the ranger camp
## spur, which a player who walks to the mouth and goes straight down never
## sees. See `burrow_warrens.json`'s own `_comment_dressing` for what the set
## says and why there is deliberately nothing to READ in it.
##
## Placed through `props.gd` rather than through this file's own `_box()`,
## because that script already owns the two things a second implementation
## would get wrong: the collider built from the combined mesh AABB, and the
## `sink_m` offset that keeps a shallow-origin model from reading as floating.
##
## `top_level` is the whole trick. The placer needs to sit UNDER this node so
## that `props.gd::_ground_height()`'s walk up the parent chain reaches this
## file's `ground_height_at()` and gets the cave floor -- but `props.gd` writes
## world metres straight into `root.position`, which a rotated parent would
## then re-interpret as its own local space and swing the whole set off into
## the hillside. `top_level` keeps the tree parent (so the ground lookup works)
## while ignoring its transform (so world coordinates stay world coordinates).
## The authored yaw is cave-local for the same reason every other position in
## this file is, so the site's own yaw is added back on here.
func _build_dressing() -> void:
	var entries: Array = _config.get("dressing", [])
	if entries.is_empty():
		return
	var placer: Node3D = PROPS.new()
	placer.name = "Dressing"
	placer.top_level = true
	add_child(placer)
	var site_yaw := float(_config.get("site", {}).get("yaw_deg", 0.0))
	var index := 0
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = (entry as Dictionary).duplicate()
		index += 1
		var chamber := str(spec.get("chamber", ""))
		if not _chambers.has(chamber):
			push_warning("warrens dressing names chamber '%s', which does not exist" % chamber)
			continue
		var centre := _local_of((_chambers[chamber] as Dictionary).get("at", []))
		var offset := _local_of(spec.get("offset", [0.0, 0.0]))
		var world := to_global(Vector3(centre.x + offset.x, _floor_y, centre.z + offset.z))
		spec["at"] = [world.x, world.z]
		# Unique, and readable in a remote tree: this set uses three models
		# twice each, and same-named siblings get auto-renamed to `@Node3D@`ids.
		spec["name"] = "%s_%s_%d" % [str(spec.get("model", "prop")), chamber, index]
		spec["yaw_deg"] = float(spec.get("yaw_deg", 0.0)) + site_yaw
		placer.call("place", placer, spec)


## The Heartstone (R4.6's evolution catalyst), in the branch chamber. One
## time, across saves: the flag is what stops a reload minting a second.
func _build_prize() -> void:
	var prize: Dictionary = _config.get("prize", {})
	if prize.is_empty():
		return
	var progression := _progression()
	if progression != null and bool(progression.call("has", str(prize.get("flag", "")))):
		return
	var chamber := str(prize.get("chamber", ""))
	if not _chambers.has(chamber):
		return
	var centre := _local_of((_chambers[chamber] as Dictionary).get("at", []))
	var offset := _local_of(prize.get("offset", [0.0, 0.0]))
	var at := Vector3(centre.x + offset.x, _floor_y + 0.45, centre.z + offset.z)

	var holder := Node3D.new()
	holder.name = "Heartstone"
	holder.position = at
	add_child(holder)

	# A cut stone on a plinth, lit from inside. Primitive, like every other
	# prop in this project, but emissive so it reads as the one thing in a dark
	# room that is worth walking to.
	#
	# CONTENT-0828B: the plinth was ONE UNTEXTURED BOX, and `W3-vault` is the
	# frame that says why that matters -- the object at the bottom of the
	# chapter's one required dungeon, the thing the whole descent is for, was a
	# flat grey cube with a pink dome on it, in the same idiom the owner
	# rejected for the TM ("cardboard cards"). `_box()` defaults `textured` to
	# false and this call never passed it, the same defaulted argument that
	# left every floor in the cave untextured.
	#
	# STEPPED, not one block, and that is the cheap half of the fix: two courses
	# with the lower one proud reads as something that was BUILT to hold an
	# object, where a single cube reads as a crate. It is the same base-course
	# cue `stronghold.gd::_wall_piece` already puts under every wall in the
	# fortress, at prop scale.
	# At PROP grain, not wall grain. Round 3 gave the plinth `_material()`, which
	# is the walls' own triplanar stone at `ROCK_UV_SCALE` -- tuned for a
	# four-metre wall -- and a blind critic caught the result immediately: "a
	# knee-high plinth has masonry grain sized for a fortress wall, which makes
	# the plinth read as a toy." Texel density has to agree with an object's
	# size, so a metre-wide plinth gets its own scale.
	var plinth := _material(_rock(), 0.0, true).duplicate() as StandardMaterial3D
	plinth.uv1_scale = Vector3.ONE * (ROCK_UV_SCALE * 3.4)
	for step: Array in [[Vector3(1.24, 0.18, 1.24), 0.09], [Vector3(0.96, 0.42, 0.96), 0.39]]:
		var course := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = step[0]
		course.mesh = slab
		course.material_override = plinth
		course.position = Vector3(at.x, _floor_y + float(step[1]), at.z)
		add_child(course)
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = step[0]
		shape.shape = box_shape
		body.add_child(shape)
		body.position = course.position
		add_child(body)
	var gem := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	# Was 0.22. A 44cm stone on a metre plinth across a dark eight-metre room
	# is a bright dot; the light around it was doing all the work of saying
	# something is there, and the object itself none.
	sphere.radius = 0.30
	sphere.height = 0.60
	# FACETED, not a dome. A blind critic called the old one "a flat salmon-pink
	# dome, zero texture, zero gradient across its whole surface" and ranked it
	# an unfinished asset -- correct about what it looked like, and the cause is
	# that a smooth emissive sphere under flat ambient light has no shading to
	# vary: every normal points somewhere the same light reaches equally. Cutting
	# the segment counts right down gives it flat faces at different angles,
	# which is the only way this renderer will put a gradient across it, and it
	# is also what a cut stone IS. No new asset: `SphereMesh` already takes both
	# counts. The item's own description calls it a stone that beats slowly, so
	# a rough crystal is what it should have been.
	sphere.radial_segments = 7
	sphere.rings = 4
	gem.mesh = sphere
	# FACETS ONLY WORK IF THE FACES SHADE DIFFERENTLY, and at emission 2.0 they
	# did not. An emissive surface ignores its own normals -- every face renders
	# at the same brightness whichever way it points -- so cutting the segment
	# counts changed the silhouette and left the shading exactly as flat as the
	# dome a blind critic had already called out. Emission drops to a value
	# FLOOR (the same trick `severed_spokes.gd` uses on the faction colours, and
	# for the same gl_compatibility reason: without one this reads black in a
	# room this dark), and the albedo and roughness are given something to do,
	# so the plinth's own OmniLight models the cut faces. It is still the
	# brightest object in the chamber -- that is what the light beside it is
	# for -- it is now an object rather than a decal.
	var stone := _material(Color("#c8564a"), 0.75).duplicate() as StandardMaterial3D
	stone.albedo_color = Color("#a8322c")
	stone.roughness = 0.35
	stone.metallic = 0.0
	gem.material_override = stone
	holder.add_child(gem)
	var glow := OmniLight3D.new()
	glow.light_color = Color("#e08a6a")
	glow.light_energy = 1.4
	glow.omni_range = 5.0
	holder.add_child(glow)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.call("configure", str(prize.get("label", "Take it")), 2.4, true)
	prompt.connect("activated", _on_prize_taken)
	holder.add_child(prompt)


func _on_prize_taken() -> void:
	var prize: Dictionary = _config.get("prize", {})
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var inventory: RefCounted = game.get("inventory")
	var item := str(prize.get("item", ""))
	if inventory == null or item == "":
		return
	if not bool(inventory.call("has_room_for", item, 1)):
		# Refused visibly, the same way key_pickup.gd refuses: the stone stays
		# on its plinth rather than vanishing into a full satchel.
		game.call("push_world_message", "No room in the satchel for it.")
		return
	inventory.call("add", item, 1)
	var progression := _progression()
	if progression != null:
		progression.call("set_flag", str(prize.get("flag", "")))
	var message := str(prize.get("message", ""))
	if message != "":
		game.call("push_world_message", message)
	var holder := get_node_or_null(^"Heartstone")
	if holder != null:
		holder.queue_free()


## The population and the guardian, through the encounter director's own
## spawner so these are ordinary wild creatures in every respect.
func _spawn_population(director: Node) -> void:
	if not director.has_method("spawn_wild"):
		push_error("the encounter director has no spawn_wild(); the warrens will be empty")
		return
	for entry: Variant in _config.get("spawns", []):
		var spec: Dictionary = entry as Dictionary
		var chamber := str(spec.get("chamber", ""))
		if not _chambers.has(chamber):
			continue
		var centre := _local_of((_chambers[chamber] as Dictionary).get("at", []))
		var offset := _local_of(spec.get("offset", [0.0, 0.0]))
		var spread := float(spec.get("spread", 0.0))
		var count := int(spec.get("count", 1))
		for n in count:
			# Deterministic fan rather than a random scatter: a dungeon is a
			# hand-placed room, and the whole world is deterministic by
			# contract (see encounter_director.gd's own seeding comment).
			var angle := TAU * float(n) / float(maxi(count, 1))
			var at := Vector3(
				centre.x + offset.x + sin(angle) * spread,
				_floor_y + 0.5,
				centre.z + offset.z + cos(angle) * spread)
			var body: Node3D = director.call("spawn_wild", str(spec.get("species", "")), to_global(at), {
				"level": int(spec.get("level", 0)),
				"aggressive": bool(spec.get("aggressive", false)),
				"parent": self,
				"name": "Warrens_%s_%d" % [str(spec.get("species", "")), n + 1],
			})
			if body != null:
				# CONTENT-0828. Optional, and used by exactly one entry today:
				# the vault's Terrapup is the ONLY wild Terrapup in the whole
				# game (`_comment_spawns_special`), and nothing told the player
				# that. It read as one more aggressive animal in a dark room,
				# so a player who fled it or beat it never learned they had
				# just passed the rarest catch in the chapter. A name is the
				# cheapest honest signal and it is the same two-object write
				# `_dress_the_guardian()` documents at length: the BODY's
				# `display_name` is what the engage prompt shows, the INSTANCE's
				# `nickname` is what the combat plate shows, and writing the
				# nickname rather than the instance's `display_name` keeps the
				# species underneath so catching it does not lose what it is.
				var label := str(spec.get("nickname", ""))
				if label != "":
					body.set("display_name", label)
					var body_instance: Object = body.get("instance")
					if body_instance != null:
						body_instance.set("nickname", label)
				_population.append(body)

	var guardian: Dictionary = _config.get("guardian", {})
	var g_chamber := str(guardian.get("chamber", ""))
	if guardian.is_empty() or not _chambers.has(g_chamber):
		return
	var g_centre := _local_of((_chambers[g_chamber] as Dictionary).get("at", []))
	var g_offset := _local_of(guardian.get("offset", [0.0, 0.0]))
	_guardian = director.call("spawn_wild", str(guardian.get("species", "")),
		to_global(Vector3(g_centre.x + g_offset.x, _floor_y + 0.5, g_centre.z + g_offset.z)), {
			"level": int(guardian.get("level", 15)),
			"aggressive": true,
			"parent": self,
			"name": "WarrenGuardian",
		})
	if _guardian != null:
		_guardian_seen_alive = true
		_dress_the_guardian(guardian)
		_markers["guardian"] = _guardian.global_position


## What makes the thing at the bottom read as the thing at the bottom.
##
## Prompt 63's acceptance asks for a guardian that is `memorable, not standard
## fight + HP`, and the owner's 2026-08-28 playtest reports the same thing from
## the other end -- "there needs to be a point to going in the burrows warren.
## like a prize at the bottom or an alpha animal or something." The cave HAS a
## guardian and a prize; what it did not have was a guardian that reads as an
## alpha, and this game already knows how to build one.
##
## CONTENT-0828: this now routes the guardian through the SAME alpha
## presentation every ordinary field cluster uses -- `encounter_director.gd`'s
## `_make_alpha()` is the reference and this is deliberately the same three
## calls in the same order, because the chapter's boss reading as less of an
## alpha than a roadside duskhush was the actual defect:
##
##   * `apply_size_multiplier()` replaces the old `art_scale`. The old key
##     multiplied the MODEL PIVOT only, on the stated reasoning that scaling
##     the body would retune the fight. That reasoning is backwards and
##     `creature_body.gd`'s own PW2 note says so at the declaration of
##     `body_scale`: the collider, the hit cone's reach and the catch accuracy
##     bonus all read `_height`/`_radius`, so scaling only the art gives a
##     three-metre silhouette with a field burrowback's capsule -- a throw or a
##     swing that visually connects resolves against a body that is not there.
##     That is the invisible discrepancy PW2 forbids, and it is why every band
##     alpha in `data/config/bands/*/spawns.json` uses the multiplier instead.
##     Scale drops 1.4 -> `scale` (1.35) because it is now a real reach change
##     and not just a picture.
##   * `set_alpha(true)` is the half that costs nothing and was simply never
##     called here. `creature_burrowback_lod0_base_color_alpha.png` and its
##     emissive sibling are ALREADY INSTALLED -- the heavier-stone-plates
##     repaint CREATURE-IDENTITY-2 authored for exactly this species -- plus
##     the silhouette rim and the ring of drifting motes. D23 forbids a new
##     mesh and spec Sec20 forbids inventing a legendary; material, texture,
##     modest scale, VFX and encounter context are what CLAUDE.md names as the
##     differentiation that IS allowed, and all of it was sitting unused.
##   * `signature_move` gives the fight a shape instead of a bigger number.
##     `creature_instance.gd` holds `move_quick`/`move_charged` as plain fields
##     resolved through `move_db.gd`, so this is a per-instance override and
##     not a species edit -- ordinary burrowbacks out in the meadow are
##     untouched. `earth_fist` (1.4x power against `tremor_roll`'s 1.0, 0.62s
##     windup, 72-degree cone) is deliberately DIRECTIONAL: `earthshatter` is
##     the harder move and is exactly wrong here, because a 360-degree 7.5m
##     move inside a den whose `combat_arena_bounds_at()` clearance is about
##     six metres cannot be stepped out of, and an unavoidable hit is not a
##     memorable fight. A longer windup the player can read and walk around
##     is. Level stays 14: SH47/D42 lowered it deliberately against measured
##     pacing and this pass does not reopen that.
##
## The name still goes on TWO different objects because two different screens
## read two different things: `encounter_director.gd`'s engage prompt reads the
## BODY's `display_name`, and `combat_hud.gd`'s enemy plate reads the INSTANCE
## through `creature_instance.label()`, which prefers `nickname` and falls back
## to the species name. Writing the nickname rather than overwriting the
## instance's own `display_name` is what keeps the species underneath -- a
## player who CATCHES the guardian (legal, and this cave says so out loud) gets
## a creature called Warren Guardian that still knows it is a Burrowback, and
## keeps its Earth Fist. That is the bug encounter_director.gd:463 already
## documents, not to be reintroduced here.
func _dress_the_guardian(spec: Dictionary) -> void:
	var nickname := str(spec.get("nickname", ""))
	var instance: Object = _guardian.get("instance")
	if nickname != "":
		_guardian.set("display_name", nickname)
		if instance != null:
			instance.set("nickname", nickname)

	# Per-instance, never a species edit: the meadow's own burrowbacks keep
	# `species.json`'s `tremor_roll`.
	if instance != null:
		var quick := str(spec.get("signature_quick", ""))
		if quick != "":
			instance.set("move_quick", quick)
		var charged := str(spec.get("signature_move", ""))
		if charged != "":
			instance.set("move_charged", charged)

	# Order matters and is the same order `_make_alpha()` uses: the multiplier
	# rebuilds the art from the species look, which would discard the dressing
	# if `set_alpha()` had already applied it.
	var scale := float(spec.get("scale", spec.get("art_scale", 1.0)))
	if not is_equal_approx(scale, 1.0) and _guardian.has_method("apply_size_multiplier"):
		_guardian.call("apply_size_multiplier", scale)
	if _guardian.has_method("set_alpha"):
		_guardian.call("set_alpha", true)
	# Same marker `_make_alpha()` sets, so anything asking "is this an alpha"
	# gets one answer for the field and the dungeon alike.
	_guardian.set_meta("alpha", true)


## --- clearing --------------------------------------------------------------

## Polled rather than signal-driven, because there are three legal ways for
## the guardian to leave the field and only one of them is a `fainted` signal:
## beaten (faints), caught (the director hides the body and refills the spawn
## point), or freed outright. All three mean the same thing to the warrens.
func _process(delta: float) -> void:
	if _guardian == null or is_cleared():
		return
	_poll_left -= delta
	if _poll_left > 0.0:
		return
	_poll_left = 0.25
	var down := not is_instance_valid(_guardian)
	if not down:
		down = not bool(_guardian.call("is_alive")) or not _guardian.visible
	if down and _guardian_seen_alive:
		grant_clear_reward()


## True once the guardian has gone down, ever. Read from SB9's flag store, so
## a warrens cleared before a save is still cleared after a reload.
func is_cleared() -> bool:
	var progression := _progression()
	if progression == null:
		return false
	return bool(progression.call("has", _clear_flag()))


func _clear_flag() -> String:
	return str(_config.get("clear", {}).get("flag", "warrens_cleared"))


## Sets the cleared flag and pays the story reward -- ONCE. Returns true only
## on the call that actually paid, which is what "cleared only once for its
## story reward" means in `SD17`'s done-when. Public so a test can call it
## twice without having to beat a level-18 Burrowback twice.
func grant_clear_reward() -> bool:
	var progression := _progression()
	if progression == null:
		return false
	if bool(progression.call("has", _clear_flag())):
		_sync_vault_door()
		return false
	progression.call("set_flag", _clear_flag())
	# The one call that animates: this is the moment the guardian fell.
	_sync_vault_door(true)

	var reward: Dictionary = _config.get("clear", {}).get("reward", {})
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return true
	var inventory: RefCounted = game.get("inventory")
	var catalogue: RefCounted = game.get("items")
	var won: Array[String] = []

	var coins := int(reward.get("coins", 0))
	if coins > 0 and inventory != null:
		var leftover := int(inventory.call("add", "coin", coins))
		if coins - leftover > 0:
			won.append("%d coin" % (coins - leftover))
	for entry: Variant in reward.get("items", []):
		var item: Dictionary = entry as Dictionary
		var id := str(item.get("id", ""))
		var count := int(item.get("count", 1))
		if id == "" or count <= 0 or inventory == null:
			continue
		if catalogue != null and not bool(catalogue.call("has", id)):
			push_error("the warrens rewards '%s', which data/items/items.json does not define" % id)
			continue
		var left := int(inventory.call("add", id, count))
		if count - left > 0:
			won.append("%d %s" % [count - left,
				str(catalogue.call("item_name", id)) if catalogue != null else id])

	var xp_bonus := int(reward.get("xp_bonus", 0))
	if xp_bonus > 0:
		var party: RefCounted = game.get("party")
		if party != null:
			var cfg: Dictionary = _progression_config()
			for i in int(party.call("size")):
				var member: RefCounted = party.call("at", i)
				if member != null and not bool(member.get("fainted")):
					member.call("gain_xp", xp_bonus, cfg)

	var message := str(reward.get("message", ""))
	if message != "":
		game.call("push_world_message",
			message if won.is_empty() else "%s (%s)" % [message, ", ".join(won)])
	return true


## The branch door follows the flag, both at build time (a returning player
## walks into an open branch) and the moment the guardian falls.
##
## CONTENT-0828: `animate` is what separates those two cases. At BUILD time the
## flag is already set and the door must simply not be there -- a returning
## player walking into an open branch must not watch a door they already opened
## grind down again. At the moment the guardian falls it is the payoff beat, so
## the slab SINKS into the floor rather than blinking out of existence. Same
## mechanism either way (`is_cleared()` is still the only authority and the
## collider is still what actually stops a player), just shown rather than
## skipped -- the door is the one moving part in the cave and the only thing
## the player's win visibly does to the world.
func _sync_vault_door(animate := false) -> void:
	var open := is_cleared()
	if _vault_door != null:
		_vault_door.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
		for child in _vault_door.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = open
	if _vault_door_mesh == null:
		return
	if not open:
		_vault_door_mesh.visible = true
		_vault_door_mesh.position.y = _door_shut_y()
		return
	if not animate or not is_inside_tree():
		_vault_door_mesh.visible = false
		return
	# Down by its own height plus the skirt the walls already extend below the
	# floor, so it is genuinely gone under the slab rather than parked with its
	# top edge showing. Hidden at the end because a mesh sunk into geometry is
	# still drawn.
	var mesh: MeshInstance3D = _vault_door_mesh
	var drop := _door_travel()
	var seconds := float(_config.get("site", {}).get("vault_door_seam", {}).get("open_seconds", 1.4))
	var tween := create_tween()
	tween.tween_property(mesh, "position:y", _door_shut_y() - drop, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(mesh):
			mesh.visible = false)


## Where the slab sits when it is shut. Recomputed rather than remembered so a
## re-sync after an animated open cannot leave the door parked underground.
func _door_shut_y() -> float:
	var height := 0.0
	var box: BoxMesh = _vault_door_mesh.mesh as BoxMesh if _vault_door_mesh != null else null
	if box != null:
		height = box.size.y
	return _floor_y + height * 0.5


func _door_travel() -> float:
	var box: BoxMesh = _vault_door_mesh.mesh as BoxMesh if _vault_door_mesh != null else null
	return ((box.size.y if box != null else 3.0) + _skirt * 0.5)


func branch_is_open() -> bool:
	if _vault_door == null:
		return true
	for child in _vault_door.get_children():
		if child is CollisionShape3D:
			return (child as CollisionShape3D).disabled
	return false


## --- queries other systems use --------------------------------------------

## The cave floor inside the warrens' footprint, the hillside outside it.
##
## `creature_body.gd::place_on_ground` and the harvest props ask whatever
## ancestor offers this method; everything parented under this node therefore
## stands on the cave floor rather than on the terrain now several metres
## overhead. Outside the footprint it defers to the world, so a creature that
## wanders out of the mouth is handed back to the meadow cleanly.
func ground_height_at(x: float, z: float) -> float:
	var built := built_floor_height_at(x, z)
	if not is_nan(built):
		return built
	if _world != null and is_instance_valid(_world) and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", x, z))
	return NAN


## GATE-E. This building's own floor over `(x, z)`, or NAN where it does not
## claim the spot -- the half of `ground_height_at()` with no fall-through.
##
## Split out and public for the reason `stronghold.gd`'s copy is: the bodies a
## FIGHT places are added to the world root rather than under this node
## (`encounter_director._send_out_next_creature`), so they discover the
## terrain's `ground_height_at` by walking up and never reach this one. The
## stronghold is where that was measured and it is the same code here, which is
## the other half of the owner's 2026-08-21 report -- "Stronghold and Burrow
## Warrens fights sometimes phasing participants outside reachable arena bounds
## and becoming effectively impossible". `scripts/world/built_floor.gd` reads it.
func built_floor_height_at(x: float, z: float) -> float:
	var local := to_local(Vector3(x, 0.0, z))
	for rect: Array in _footprint:
		if local.x >= float(rect[0]) - _wall_t and local.x <= float(rect[2]) + _wall_t \
				and local.z >= float(rect[1]) - _wall_t and local.z <= float(rect[3]) + _wall_t:
			return global_position.y + _floor_y
	return NAN


## OP21-25: the largest radius `combat_arena.gd` can draw around `(x, z)`
## without its boundary reaching a real cave wall -- the containment fix.
## `combat_arena.hold_inside()` corrects a fighter with a raw position write,
## not a physics move, so it has no collision to stop it: a boundary that
## reaches past a chamber's walls does not clip a knocked-back fighter against
## them, it teleports the fighter straight through to the far side. Every
## chamber here is smaller than `combat.json`'s flat 11m default radius in at
## least one dimension -- even "den", the biggest, is 16x14 -- so every fight
## in the warrens was asking for a boundary wider than the room. Sized off the
## same `_footprint` rects `ground_height_at()` above already tests against.
##
## Returns -1.0 -- "no opinion, keep the caller's own default" -- when `(x, z)`
## is not inside any chamber this building knows about (a passage, a bare test
## scene with no footprint yet). CombatManager falls back to `combat.json`'s
## flat radius in that case, same as it always did.
func combat_arena_bounds_at(x: float, z: float) -> float:
	var local := to_local(Vector3(x, 0.0, z))
	var best := -1.0
	for rect: Array in _footprint:
		if local.x < float(rect[0]) or local.x > float(rect[2]) \
				or local.z < float(rect[1]) or local.z > float(rect[3]):
			continue
		var clearance: float = minf(
			minf(local.x - float(rect[0]), float(rect[2]) - local.x),
			minf(local.z - float(rect[1]), float(rect[3]) - local.z))
		var usable := maxf(0.5, clearance - ARENA_WALL_MARGIN)
		best = usable if best < 0.0 else minf(best, usable)
	return best


## Global position of a named place: any chamber id, plus "entrance" and
## "guardian". The building is the authority on where its own rooms are --
## same rule grandpa_house.gd's markers keep.
func marker(name_key: String) -> Vector3:
	return _markers.get(name_key, global_position)


func chamber_ids() -> Array:
	return _chambers.keys()


func guardian() -> Node3D:
	return _guardian


func population() -> Array[Node3D]:
	return _population


func _mouth_outer_z() -> float:
	if not _chambers.has("mouth"):
		return 0.0
	var chamber: Dictionary = _chambers["mouth"]
	return _local_of(chamber.get("at", [])).z - _size_of(chamber.get("size", [])).y * 0.5


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null


func _progression_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
