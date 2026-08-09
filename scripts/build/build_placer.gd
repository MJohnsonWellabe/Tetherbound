extends Node

## Turns the Build tab's armed choice into a thing standing in the world.
##
## `GameState.pending_build` has been the honest end of the build screen since
## the menu shipped — the tab arms an id and nothing read it. This reads it:
## while a build is armed, a ghost of the camp hovers on the ground ahead of
## the player, green where it can stand and red where it cannot, and the
## interact button plants it. Costs go through `GameState.build_cost_for` /
## `can_afford`, which is the one gate the free-build toggle is allowed to
## bend (docs/decisions/D16).
##
## Only `camp` exists today, and this file knows that: the ghost and the
## planted result are both the campfire-and-bedroll pair. When M8 brings real
## pieces, the ghost becomes per-piece and this comment dies happily.

const CAMP := preload("res://scripts/build/camp.gd")

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


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_camera_rig = get_node_or_null(camera_rig_path)


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

	_show_ghost()
	if _ghost_ok and Input.is_action_just_pressed("interact"):
		_place(armed)


## The ghost: the camp's own silhouette at half alpha, coloured by legality.
func _show_ghost() -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		_ghost = CAMP.new()
		_ghost.name = "CampGhost"
		_ghost.call("build_ghost")
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
	_ghost_ok = rise <= MAX_SLOPE_RISE and _can_afford()
	_ghost.visible = true
	_ghost.global_position = Vector3(spot.x, ground, spot.z)
	_ghost.call("tint_ghost", _ghost_ok)


func _can_afford() -> bool:
	var game := _game()
	return game != null and bool(game.call("can_afford", "camp"))


func _place(armed: String) -> void:
	var game := _game()
	# Spend first, all-or-nothing; the inventory refuses partial removals.
	var inventory: RefCounted = game.get("inventory")
	for requirement: Variant in (game.call("build_cost_for", armed) as Array):
		var need: Dictionary = requirement
		if not bool(inventory.call("remove", str(need.get("id", "")), int(need.get("n", 0)))):
			push_error("could not spend the cost for '%s' after can_afford said yes" % armed)
			return

	var camp: Node3D = CAMP.new()
	camp.name = "Camp"
	get_parent().add_child(camp)
	camp.call("build_real")
	camp.global_position = _ghost.global_position
	game.set("pending_build", "")
	_drop_ghost()


func _drop_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_ok = false


func _ground_height(at: Vector3) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", at.x, at.z))
		node = node.get_parent()
	return NAN
