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
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")

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
	_build_deposits()
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
		m.albedo_color = ROCK_TINT
		m.normal_enabled = true
		m.normal_texture = ROCK_NORMAL
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

		_box(Vector3(outer.x, _skirt, outer.y),
			Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z), _floor_colour())
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

		var floor_size := Vector3(length, _skirt, width + _wall_t * 2.0)
		var ceiling_size := Vector3(length, 0.8, width + _wall_t * 2.0)
		if not along_x:
			floor_size = Vector3(width + _wall_t * 2.0, _skirt, length)
			ceiling_size = Vector3(width + _wall_t * 2.0, 0.8, length)
		_box(floor_size, Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z), _floor_colour())
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
func _build_vault_door(centre: Vector3, along_x: bool, width: float, height: float) -> void:
	var size := Vector3(0.6, height, width) if along_x else Vector3(width, height, 0.6)
	var colour := Color(str(_config.get("site", {}).get("vault_door_colour", "#6d5f4a")))
	_vault_door_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	_vault_door_mesh.mesh = box
	_vault_door_mesh.material_override = _material(colour)
	_vault_door_mesh.position = Vector3(centre.x, _floor_y + height * 0.5, centre.z)
	_vault_door_mesh.name = "VaultDoor"
	add_child(_vault_door_mesh)

	_vault_door = StaticBody3D.new()
	_vault_door.name = "VaultDoorBody"
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	_vault_door.add_child(shape)
	_vault_door.position = _vault_door_mesh.position
	add_child(_vault_door)


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
		_box(Vector3(width, _skirt, run / float(steps) + 0.15),
			Vector3(0.0, top - _skirt * 0.5, z), _floor_colour())


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


func _on_body_entered(body: Node3D) -> void:
	if body != _player or _camera_rig == null:
		return
	_camera_rig.call("set_target", _player, INTERIOR_PROFILE)


func _on_body_exited(body: Node3D) -> void:
	if body != _player or _camera_rig == null:
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
	# placeholder prop in this project, but emissive so it reads as the one
	# thing in a dark room that is worth walking to.
	_box(Vector3(1.0, 0.5, 1.0), Vector3(at.x, _floor_y + 0.25, at.z), _rock())
	var gem := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	gem.mesh = sphere
	gem.material_override = _material(Color("#c8564a"), 2.0)
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
		_markers["guardian"] = _guardian.global_position


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
	_sync_vault_door()

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
func _sync_vault_door() -> void:
	var open := is_cleared()
	if _vault_door != null:
		_vault_door.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
		for child in _vault_door.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = open
	if _vault_door_mesh != null:
		_vault_door_mesh.visible = not open


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
	var local := to_local(Vector3(x, 0.0, z))
	for rect: Array in _footprint:
		if local.x >= float(rect[0]) - _wall_t and local.x <= float(rect[2]) + _wall_t \
				and local.z >= float(rect[1]) - _wall_t and local.z <= float(rect[3]) + _wall_t:
			return global_position.y + _floor_y
	if _world != null and is_instance_valid(_world) and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", x, z))
	return NAN


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
