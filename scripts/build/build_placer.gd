extends Node

## Turns the Build tab's armed choice into a thing standing in the world.
##
## `GameState.pending_build` has been the honest end of the build screen since
## the menu shipped — the tab arms an id and nothing read it. This reads it:
## while a build is armed, a ghost of the piece hovers ahead of the player,
## snapped onto the world's 2m module grid (`build_grid.gd`, matching
## `building_prefabs.json`'s own grid) or flush against a same-type neighbour
## when one is close enough, rotatable in 90-degree steps, green where it can
## stand and red where it cannot. The interact button plants it. Costs go
## through `GameState.build_cost_for` / `can_afford`, which is the one gate
## the free-build toggle is allowed to bend (docs/decisions/D16).
##
## `camp` and `storage` keep their own hand-authored geometry (`camp.gd`,
## `storage_container.gd`) because each carries state and an interaction, not
## just a mesh. Every other `buildables.json` entry (R2.6: floor, wall, door,
## roof, fence; R2.7: workbench) is plain geometry, placed generically through
## `build_piece.gd` from the catalogue's own `mesh` path.
##
## BG1: this is the ONE placement system, serving both the player's own base
## (M8's original purpose) and the OF4 castle rebuild (D28) — there is no
## second, landmark-only copy of any of this.

const CAMP := preload("res://scripts/build/camp.gd")
const STORAGE_CONTAINER := preload("res://scripts/build/storage_container.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const BUILD_GRID := preload("res://scripts/build/build_grid.gd")

## Ids placed by their own hand-authored script rather than build_piece.gd's
## generic path — kept as one list so the "is this a special id" question is
## answered in exactly one place instead of every branch below re-deriving it.
const STATEFUL_IDS := ["camp", "storage"]

## R3.1. Every node this script has planted for real, ghost excluded — how
## `restore_from_game` finds and clears the old set before rebuilding from a
## loaded save, and how `GameState.load_game` finds this node at all.
const PLACED_GROUP := "placed_building"
const BUILD_PLACER_GROUP := "build_placer"

## Which catalogue id a placed node came from, stashed as node metadata
## rather than a new exported var on `build_piece.gd`/`camp.gd`/
## `storage_container.gd` — those three scripts do not otherwise need to know
## their own catalogue id, and every reader of it (only `_neighbour_positions`
## below) lives in this file.
const BUILDING_ID_META := "building_id"

## New action (project.godot, data/config/menu.json's "Building" controls
## group): rotates the armed ghost one 90-degree step. Keyboard T and gamepad
## D-pad down were both unused by any existing action — see the input-map
## audit in this file's own commit message / ralph/DONE.md entry.
const ROTATE_ACTION := "build_rotate"

## Metres ahead of the player the ghost sits.
const PLACE_AHEAD := 3.0
## A camp needs ground this flat. Steeper reads as a tent on a cliff.
const MAX_SLOPE_RISE := 0.8
## Below this, two grid cells count as "the same cell" for the
## already-occupied check — comfortably smaller than the smallest float
## drift `snappedf` can introduce, comfortably larger than none.
const SAME_CELL_EPSILON := 0.01

@export var player_path: NodePath
@export var camera_rig_path: NodePath

var _player: Node3D = null
var _camera_rig: Node = null
var _ghost: Node3D = null
var _ghost_ok := false
var _ghost_id := ""
## 0-3, one per 90-degree step. Reset whenever a new ghost is created
## (`_drop_ghost`) so switching pieces in the Build tab does not carry a
## rotation the player chose for a different piece onto the next one.
var _ghost_rotation_steps := 0


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

	if Input.is_action_just_pressed(ROTATE_ACTION):
		_ghost_rotation_steps = BUILD_GRID.next_rotation_steps(_ghost_rotation_steps)

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
	var raw_spot := _player.global_position + forward * PLACE_AHEAD

	var ground := _ground_height(raw_spot)
	if is_nan(ground):
		_ghost.visible = false
		_ghost_ok = false
		return

	var resolved := BUILD_GRID.resolve_position(raw_spot, ground, _neighbour_positions(armed))
	var spot: Vector3 = resolved.position
	var snapped_to_neighbour: bool = resolved.snapped_to_neighbour

	# Slope check by sampling the corners the bedroll would cover. Skipped
	# when snapped to a neighbour: `spot.y` is already that neighbour's own
	# ground-clamped height, and re-checking raw terrain slope under it would
	# reject the very thing snapping exists for — continuing a wall run over
	# ground that dips slightly from where the first piece sat.
	var rise := 0.0
	if not snapped_to_neighbour:
		for corner: Vector3 in [Vector3(1.2, 0, 0), Vector3(-1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
			var h := _ground_height(spot + corner)
			if not is_nan(h):
				rise = maxf(rise, absf(h - ground))

	var occupied := _cell_occupied(armed, spot)
	_ghost_ok = rise <= MAX_SLOPE_RISE and not occupied and _can_afford(game, armed)
	_ghost.visible = true
	_ghost.global_position = spot
	_ghost.rotation.y = deg_to_rad(BUILD_GRID.yaw_for_steps(_ghost_rotation_steps))
	_ghost.call("tint_ghost", _ghost_ok)


## World X/Z positions of every already-placed piece sharing `armed`'s
## catalogue id — the candidate set `build_grid.gd`'s neighbour-snap searches,
## and (via `_cell_occupied`) the exact-overlap check below. Restricted to the
## same id, not every placed piece, so a wall run snaps against other walls
## without a nearby floor tile or fence post pulling it off-line — the literal
## "wall-to-wall, floor-to-floor" the task asks for.
func _neighbour_positions(armed: String) -> Array:
	var out: Array = []
	for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):
		if node == _ghost:
			continue
		if str(node.get_meta(BUILDING_ID_META, "")) == armed:
			out.append((node as Node3D).global_position)
	return out


## True if a piece of the SAME type already occupies `spot`'s grid cell —
## placing the ghost exactly on top of one it already snapped flush against,
## which `build_grid.gd::resolve_position` deliberately never returns on its
## own but which is still reachable (the raw grid-snap path, no neighbour in
## range, landing on an existing piece's own cell).
func _cell_occupied(armed: String, spot: Vector3) -> bool:
	for pos: Vector3 in _neighbour_positions(armed):
		if absf(pos.x - spot.x) < SAME_CELL_EPSILON and absf(pos.z - spot.z) < SAME_CELL_EPSILON:
			return true
	return false


func _can_afford(game: Node, armed: String) -> bool:
	return game != null and bool(game.call("can_afford", armed))


## The plain node-creation half of placement, shared with `restore_from_game`
## below — spends nothing and does not touch position, so a save restore can
## reuse it without re-charging the satchel for a piece it already paid for.
## `yaw_deg` is applied to the whole node: every stateful piece's own
## sub-parts (`camp.gd`'s fire/bedroll, `storage_container.gd`'s prompt) are
## positioned in ITS local space, so rotating the root carries them with it.
func _spawn_building(game: Node, id: String, yaw_deg: float = 0.0) -> Node3D:
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
	placed.rotation.y = deg_to_rad(yaw_deg)
	placed.set_meta(BUILDING_ID_META, id)
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

	var yaw_deg := BUILD_GRID.yaw_for_steps(_ghost_rotation_steps)
	var placed := _spawn_building(game, armed, yaw_deg)
	placed.global_position = _ghost.global_position
	# R3.1. The registry, not this node, is what a save actually persists —
	# see GameState.placed_buildings.
	game.call("register_building", armed, placed.global_position, yaw_deg)
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
		# Absent on a save written before BG1 shipped rotation — see
		# GameState.register_building's own comment on why that is not a
		# version bump.
		var yaw_deg := float(record.get("yaw_deg", 0.0))
		var placed := _spawn_building(game, id, yaw_deg)
		placed.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))


func _drop_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_ok = false
	_ghost_id = ""
	_ghost_rotation_steps = 0


func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN
