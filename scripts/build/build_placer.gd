extends Node

## Turns the Build tab's armed choice into a thing standing in the world.
##
## `GameState.pending_build` has been the honest end of the build screen since
## the menu shipped — the tab arms an id and nothing read it. This reads it:
## while a build is armed, a ghost of the piece hovers on the ground ahead of
## the player, green where it can stand and red where it cannot, and the
## interact button plants it. Costs go through `GameState.build_cost_for` /
## `can_afford`, which is the one gate the free-build toggle is allowed to
## bend (docs/decisions/D16).
##
## `camp` and `storage` keep their own hand-authored geometry (`camp.gd`,
## `storage_container.gd`) because each carries state and an interaction, not
## just a mesh. Every other `buildables.json` entry (R2.6: floor, wall, door,
## roof, fence; R2.7: workbench) is plain geometry, placed generically through
## `build_piece.gd` from the catalogue's own `mesh` path.

const CAMP := preload("res://scripts/build/camp.gd")
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")

## Ids placed by their own hand-authored script rather than build_piece.gd's
## generic path — kept as one list so the "is this a special id" question is
## answered in exactly one place instead of every branch below re-deriving it.
const STATEFUL_IDS := ["camp", "storage"]

## R3.1. Every node this script has planted for real, ghost excluded — how
## `restore_from_game` finds and clears the old set before rebuilding from a
## loaded save, and how `GameState.load_game` finds this node at all.
const PLACED_GROUP := "placed_building"
const BUILD_PLACER_GROUP := "build_placer"

## Metres ahead of the player the ghost sits.
const PLACE_AHEAD := 3.0
## A camp needs ground this flat. Steeper reads as a tent on a cliff.
const MAX_SLOPE_RISE := 0.8

@export var player_path: NodePath
@export var camera_rig_path: NodePath

var _player: Node3D = null
var _camera_rig: Node = null
var _ghost: Node3D = null
var _ghost_ok := false
var _ghost_id := ""


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_camera_rig = get_node_or_null(camera_rig_path)
	add_to_group(BUILD_PLACER_GROUP)
	restore_from_game(_game())


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _physics_process(_delta: float) -> void:
	var game := _game()
	if game == null or _player == null:
		return
	var armed := str(game.get("pending_build"))
	if armed == "":
		_drop_ghost()
		return

	_show_ghost(game, armed)
	if _ghost_ok and Input.is_action_just_pressed("interact"):
		_place(game, armed)


## The mesh path a plain catalogue entry places, or "" if it has none (an id
## the catalogue doesn't know, or one of the stateful ids above).
func _piece_mesh(game: Node, id: String) -> String:
	if STATEFUL_IDS.has(id):
		return ""
	var items: RefCounted = game.get("items")
	if items == null:
		return ""
	var entry: Dictionary = items.call("buildable", id)
	return str(entry.get("mesh", ""))


## The ghost: the armed piece's own silhouette at half alpha, coloured by
## legality. Rebuilt whenever the armed id changes, so switching pieces in
## the Build tab swaps the ghost rather than leaving the old one behind.
func _show_ghost(game: Node, armed: String) -> void:
	if _ghost != null and is_instance_valid(_ghost) and _ghost_id != armed:
		_drop_ghost()

	if _ghost == null or not is_instance_valid(_ghost):
		_ghost_id = armed
		if armed == "camp":
			_ghost = CAMP.new()
			_ghost.name = "CampGhost"
			_ghost.call("build_ghost")
		elif armed == "storage":
			_ghost = STORAGE_CONTAINER.new()
			_ghost.name = "StorageGhost"
			_ghost.call("build_ghost")
		else:
			var mesh_path := _piece_mesh(game, armed)
			_ghost = BUILD_PIECE.new()
			_ghost.name = "PieceGhost"
			_ghost.call("build_ghost", mesh_path)
		get_parent().add_child(_ghost)

	var forward := -_player.global_transform.basis.z
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		forward = -(_camera_rig.call("planar_basis") as Basis).z
	var spot := _player.global_position + forward * PLACE_AHEAD

	var ground := _ground_height(spot)
	if is_nan(ground):
		_ghost.visible = false
		_ghost_ok = false
		return
	# Slope check by sampling the corners the bedroll would cover.
	var rise := 0.0
	for corner: Vector3 in [Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
		var h := _ground_height(spot + corner)
		if not is_nan(h):
			rise = maxf(rise, absf(h - ground))
	_ghost_ok = rise <= MAX_SLOPE_RISE and _can_afford(game, armed)
	_ghost.visible = true
	_ghost.global_position = Vector3(spot.x, ground, spot.z)
	_ghost.call("tint_ghost", _ghost_ok)


func _can_afford(game: Node, armed: String) -> bool:
	return game != null and bool(game.call("can_afford", armed))


## The plain node-creation half of placement, shared with `restore_from_game`
## below — spends nothing and does not touch position, so a save restore can
## reuse it without re-charging the satchel for a piece it already paid for.
func _spawn_building(game: Node, id: String) -> Node3D:
	var placed: Node3D = null
	if id == "camp":
		placed = CAMP.new()
		placed.name = "Camp"
		get_parent().add_child(placed)
		placed.call("build_real")
	elif id == "storage":
		placed = STORAGE_CONTAINER.new()
		placed.name = "Storage"
		get_parent().add_child(placed)
		placed.call("build_real")
	else:
		var mesh_path := _piece_mesh(game, id)
		placed = BUILD_PIECE.new()
		placed.name = "Piece_%s" % id
		get_parent().add_child(placed)
		placed.call("build_real", mesh_path)
	placed.add_to_group(PLACED_GROUP)
	return placed


func _place(game: Node, armed: String) -> void:
	# Spend first, all-or-nothing; the inventory refuses partial removals.
	var inventory: RefCounted = game.get("inventory")
	for requirement: Variant in (game.call("build_cost_for", armed) as Array):
		var need: Dictionary = requirement
		if not bool(inventory.call("remove", str(need.get("id", "")), int(need.get("n", 0)))):
			push_error("could not spend the cost for '%s' after can_afford said yes" % armed)
			return

	var placed := _spawn_building(game, armed)
	placed.global_position = _ghost.global_position
	# R3.1. The registry, not this node, is what a save actually persists —
	# see GameState.placed_buildings.
	game.call("register_building", armed, placed.global_position)
	game.set("pending_build", "")
	_drop_ghost()


## R3.1. Rebuild everything `GameState.placed_buildings` remembers: called
## once at boot (a no-op the first time a save is ever written, since the
## list starts empty) and again by `GameState.load_game` whenever the player
## loads a slot mid-session. Existing placed pieces are cleared first so a
## mid-session load cannot leave two copies of the same building standing on
## top of each other.
func restore_from_game(game: Node) -> void:
	if game == null:
		return
	for node in get_tree().get_nodes_in_group(PLACED_GROUP):
		node.queue_free()
	for entry: Variant in (game.get("placed_buildings") as Array):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var record := entry as Dictionary
		var id := str(record.get("id", ""))
		var position: Array = record.get("position", [])
		if id.is_empty() or position.size() != 3:
			continue
		var placed := _spawn_building(game, id)
		placed.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))


func _drop_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_ok = false
	_ghost_id = ""


func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN
