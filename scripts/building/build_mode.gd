extends Node

## Build Mode: a STATE, not a scene.
##
## Same shape as `combat_manager.gd`, and its header says why better than a new
## comment would: the world keeps rendering, the trainer stays standing where
## they opened it, nothing is unloaded and nothing is instanced from a separate
## scene. Entering build mode suspends locomotion and shows a ghost. That is all
## it is.
##
## This is the single place that knows building is happening. The HUD is told and
## does not ask; `structures.gd` is told what to place and does not decide.
##
## ONE WAY IN AND ONE WAY OUT, for the reason `encounter_director` gives about
## fights: "One place, so a new way of entering a fight cannot forget half of
## it." A second route that forgot to suspend locomotion would leave the player
## walking around with a ghost stuck to their face.

const GRID := preload("res://scripts/building/build_grid.gd")
const CONFIG_PATH := "res://data/config/building.json"

signal opened()
signal closed()
signal selection_changed(piece_id: String)
signal placed(piece_id: String)
signal refused(reason: String)

@export var player_path: NodePath
@export var world_path: NodePath
@export var structures_path: NodePath
@export var combat_path: NodePath

var _player: CharacterBody3D = null
var _world: Node = null
var _structures: Node3D = null
var _combat: Node = null

var _open: bool = false
var _ghost: Node3D = null
var _ghost_material: StandardMaterial3D = null
var _selected: int = 0
var _ids: Array[String] = []
var _yaw: float = 0.0
var _valid: bool = false
var _refusal: String = ""

var _reach: float = 9.0
var _reach_min: float = 1.6
var _max_slope_deg: float = 18.0
var _max_step: float = 0.55
var _remove_radius: float = 3.0
var _ghost_alpha: float = 0.55
var _valid_colour: Color = Color("#8fd694")
var _invalid_colour: Color = Color("#e0a05a")

## Swallows the frame the mode opened on.
##
## `combat_manager` documents the same guard for the same reason: "Engage and
## charged attack are the same physical button... Without this, the press that
## starts the fight is also read as the first attack of it." Here it is the
## press that opens build mode also being read as the first placement, which
## drops a wall on the player's feet the instant they enter.
var _input_guard: bool = false


func _ready() -> void:
	_load_config()
	_player = get_node_or_null(player_path) as CharacterBody3D
	_world = get_node_or_null(world_path)
	_structures = get_node_or_null(structures_path) as Node3D
	_combat = get_node_or_null(combat_path)
	if _structures != null:
		_ids.assign(_structures.call("catalogue").keys())
		_ids.sort()


func is_open() -> bool:
	return _open


func selected_id() -> String:
	return _ids[_selected] if _selected < _ids.size() else ""


func selected_name() -> String:
	if _structures == null:
		return ""
	return str((_structures.call("definition", selected_id()) as Dictionary).get("display_name", ""))


func ghost_valid() -> bool:
	return _valid


func refusal() -> String:
	return _refusal


func piece_ids() -> Array[String]:
	return _ids


## Input is read in `_physics_process`, never `_process`.
##
## `encounter_director` records the cost of getting this wrong:
## `Input.is_action_just_pressed()` is scoped to the frame the press was recorded
## in, so a system reading it from `_process` while another reads from
## `_physics_process` will sometimes each see a different half of one press.
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("build_toggle"):
		_set_open(not _open)
		return

	if not _open:
		return
	if _input_guard:
		_input_guard = false
		return

	if Input.is_action_just_pressed("combat_switch_right"):
		_cycle(1)
	elif Input.is_action_just_pressed("combat_switch_left"):
		_cycle(-1)
	if Input.is_action_just_pressed("tool_cycle"):
		_yaw = GRID.snap_yaw(_yaw + GRID.YAW_STEP)

	_update_ghost()

	if Input.is_action_just_pressed("combat_quick"):
		_try_place()
	elif Input.is_action_just_pressed("combat_charged"):
		_try_remove()


## The single door in and out.
func _set_open(value: bool) -> void:
	if value == _open:
		return

	# Refused rather than queued. Redecorating mid-fight is not a thing anyone
	# needs, and a build ghost over a combat HUD is two modes drawing at once.
	if value and _combat != null and bool(_combat.call("is_fighting")):
		refused.emit("not while you are in a fight")
		return

	_open = value
	if _player != null:
		_player.call("set_locomotion_enabled", not _open)

	if _open:
		_input_guard = true
		_yaw = 0.0
		_build_ghost()
		opened.emit()
	else:
		_clear_ghost()
		closed.emit()


func _cycle(step: int) -> void:
	if _ids.is_empty():
		return
	_selected = posmod(_selected + step, _ids.size())
	_build_ghost()
	selection_changed.emit(selected_id())


## Where the piece would go if you placed it now.
##
## The aim point is a fixed distance in front of the trainer rather than under a
## cursor: this is a controller-first game and there is no mouse look action in
## the input map at all.
func _aim_point() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var forward := -_player.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	return _player.global_position + forward.normalized() * (_reach * 0.55)


func _update_ghost() -> void:
	if _ghost == null or _structures == null:
		return
	var piece: Dictionary = _structures.call("definition", selected_id())
	if piece.is_empty():
		return

	var snapped: Dictionary = GRID.snap(_aim_point(), str(piece.get("anchor", GRID.ANCHOR_CELL)))
	var where: Vector3 = snapped["position"]
	# An edge anchor decides its own facing — a wall lies ALONG the edge it is
	# on, so taking yaw from the player here would float walls diagonally across
	# cell corners. The manual yaw still turns cell-anchored pieces.
	var yaw: float = _yaw if is_nan(float(snapped.get("yaw", NAN))) else float(snapped["yaw"]) + _yaw

	var ground := _ground_under(where, piece, yaw)
	if not is_nan(ground):
		where.y = ground

	_ghost.global_position = where
	_ghost.rotation.y = yaw
	_valid = _check(where, yaw, piece)
	if _ghost_material != null:
		var colour := _valid_colour if _valid else _invalid_colour
		colour.a = _ghost_alpha
		_ghost_material.albedo_color = colour


## Lowest ground height under the piece's footprint, or NAN off the terrain.
##
## `ground_height_at` and never a raycast: D09 measured roughly a quarter of
## downward rays missing terrain that is unquestionably there, and its closing
## section names this exact case — "ask the terrain first, and fall back to a ray
## only for what the terrain has never heard of."
func _ground_under(centre: Vector3, piece: Dictionary, yaw: float) -> float:
	if _world == null:
		return NAN
	var cells: Array = piece.get("size_cells", [1, 1])
	var corners := GRID.footprint_corners(
		centre, Vector2i(int(cells[0]), int(cells[1])), yaw
	)
	var lowest := INF
	for corner: Vector3 in corners:
		var height: float = float(_world.call("ground_height_at", corner.x, corner.z))
		if is_nan(height):
			return NAN
		lowest = minf(lowest, height)
	return lowest


func _check(where: Vector3, yaw: float, piece: Dictionary) -> bool:
	_refusal = ""
	if _player == null or _world == null:
		return false

	var flat := Vector2(where.x - _player.global_position.x, where.z - _player.global_position.z)
	if flat.length() > _reach:
		_refusal = "too far away"
		return false
	if flat.length() < _reach_min:
		_refusal = "too close to stand"
		return false

	var cells: Array = piece.get("size_cells", [1, 1])
	var corners := GRID.footprint_corners(where, Vector2i(int(cells[0]), int(cells[1])), yaw)
	var lowest := INF
	var highest := -INF
	for corner: Vector3 in corners:
		var height: float = float(_world.call("ground_height_at", corner.x, corner.z))
		if is_nan(height):
			_refusal = "no ground there"
			return false
		lowest = minf(lowest, height)
		highest = maxf(highest, height)
	if highest - lowest > _max_step:
		_refusal = "ground is too uneven"
		return false

	# The pond. `vegetation._drown()` already refuses to plant a meadow in open
	# water and this is the same question asked by the same method.
	if _world.has_method("water_level_at"):
		var water: float = float(_world.call("water_level_at", where.x, where.z))
		if not is_nan(water) and where.y < water:
			_refusal = "that is under water"
			return false

	if bool(_structures.call("occupied", where, yaw)):
		_refusal = "something is already there"
		return false
	return true


func _try_place() -> void:
	if not _valid:
		refused.emit(_refusal if _refusal != "" else "cannot build there")
		return
	var id := selected_id()
	if _structures.call("place", id, _ghost.global_position, _ghost.rotation.y) != null:
		placed.emit(id)


func _try_remove() -> void:
	if _structures == null:
		return
	if not bool(_structures.call("remove_nearest", _aim_point(), _remove_radius)):
		refused.emit("nothing here to remove")


## A translucent copy of the selected piece, with no collider.
##
## Its material is unshaded and transparent, and it deliberately keeps drawing
## when a placement is refused — it goes amber instead of vanishing. `combat_hud`
## learned that with cooldown verbs: a widget that disappears reads as broken,
## one that changes colour reads as an answer.
func _build_ghost() -> void:
	_clear_ghost()
	if _structures == null:
		return
	var piece: Dictionary = _structures.call("definition", selected_id())
	var model_path := str(piece.get("model", ""))
	if not ResourceLoader.exists(model_path):
		return

	_ghost = (load(model_path) as PackedScene).instantiate() as Node3D
	if _ghost == null:
		return
	add_child(_ghost)

	_ghost_material = StandardMaterial3D.new()
	_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.albedo_color = Color(_valid_colour, _ghost_alpha)
	# Visible through the wall it is about to join, so you can see where a piece
	# lands when the thing you are building is between you and it.
	_ghost_material.no_depth_test = true
	for node in _ghost.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.material_override = _ghost_material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _clear_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_material = null


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("building config missing: %s; using defaults" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var config: Dictionary = parsed
	_reach = float(config.get("reach", _reach))
	_reach_min = float(config.get("reach_min", _reach_min))
	_max_slope_deg = float(config.get("max_slope_deg", _max_slope_deg))
	_max_step = float(config.get("max_step", _max_step))
	_remove_radius = float(config.get("remove_radius", _remove_radius))
	_ghost_alpha = float(config.get("ghost_alpha", _ghost_alpha))
	_valid_colour = Color(str(config.get("ghost_valid_colour", "#8fd694")))
	_invalid_colour = Color(str(config.get("ghost_invalid_colour", "#e0a05a")))
