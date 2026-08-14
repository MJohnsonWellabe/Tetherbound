extends "res://scripts/characters/character_model.gd"

## A person who stands where they are put, turns to look at you, and talks.
##
## Grandpa, for the whole of the opening. He never walks, never fights and never
## follows — GAME_DESIGN.md §3 makes him a former trainer who is too old to
## travel, and the one thing the scene has to sell is that he is staying. A body
## that could walk would eventually be asked to.
##
## The model, height and clips come from a named block in data/config/art.json,
## which `grandpa` already has. So a second NPC is a data edit and one call.
##
## He owns a static collider. Walking through the man who is giving you your
## first creature reads as him not really being there, and a StaticBody3D cannot be
## shoved the way the invisible ally body once shoved the trainer.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

## Radians per second. Slow: he is old, and a head that snaps round to track the
## player reads as a turret.
const TURN_SPEED := 2.2

## What the player must be within before he bothers turning. Beyond it he keeps
## whatever facing he was placed with, so a distant Grandpa is a man looking at
## his meadow rather than a man staring at you across it.
const NOTICE_RANGE := 22.0

var _player: Node3D = null
var _collider: StaticBody3D = null
var _interactable: Node3D = null


func setup(config_key: String, player: Node3D) -> bool:
	_player = player
	var built := build(config_key)
	if not built:
		push_error("no model for NPC '%s'; there will be nothing standing there" % config_key)
	else:
		play(clip_for("idle"))
	_build_collider()
	return built


## The prompt he offers. Created here rather than by the caller so an NPC always
## has one and it is always in the same place — at chest height, not between his
## feet, which is where the player is actually looking.
func add_prompt(label: String, radius: float = 3.8) -> Node3D:
	if _interactable == null:
		_interactable = INTERACTABLE.new()
		_interactable.name = "Interactable"
		_interactable.position = Vector3(0.0, height() * 0.6, 0.0)
		add_child(_interactable)
	_interactable.call("configure", label, radius, true)
	return _interactable


func prompt_node() -> Node3D:
	return _interactable


func _build_collider() -> void:
	if _collider != null:
		return
	var radius := 0.36
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(height(), radius * 2.0 + 0.01)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0.0, height() * 0.5, 0.0)
	_collider = StaticBody3D.new()
	_collider.name = "Body"
	_collider.add_child(collision)
	add_child(_collider)


## Put him on the ground at an x/z.
##
## Asks the world, NEVER a raycast — docs/decisions/D09. A downward ray against
## Terrain3D's heightmap collision misses roughly a quarter of the time at
## points where the ground is unquestionably there, and the last thing placed by
## ray was a creature that then did not exist.
##
## Returns false when there is no ground yet, so the caller can retry: Terrain3D
## builds its data over several frames after the directory loads.
func stand_at(x: float, z: float) -> bool:
	var source := _ground_source()
	if source == null:
		return false
	var ground: float = float(source.call("ground_height_at", x, z))
	if is_nan(ground):
		return false
	global_position = Vector3(x, ground, z)
	return true


func _ground_source() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return node
		node = node.get_parent()
	return null


func set_player(player: Node3D) -> void:
	_player = player


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to := _player.global_position - global_position
	to.y = 0.0
	if to.length() < 0.2 or to.length() > NOTICE_RANGE:
		return
	# +Z forward, the same convention the trainer's model and every creature body
	# use. There is no convention across asset packs; this one is the project's,
	# and `model_yaw` in art.json is the per-character correction into it.
	rotation.y = rotate_toward(rotation.y, atan2(to.x, to.z), TURN_SPEED * delta)
