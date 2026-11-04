extends "res://scripts/world/interactable.gd"

## The trainer turns to face the player. Its two side interaction zones must
## follow its position without orbiting with that presentation rotation.
var _world_offset: Vector3

func _init(world_offset: Vector3 = Vector3.ZERO) -> void:
	_world_offset = world_offset

## A side zone's offset beside `trainer`, level with the trainer's own prompt
## `source`. The arbiter picks the nearest provider in 3D, so a zone at foot
## height beside a raised challenge prompt won for a player standing in front
## of the trainer (earned F49 line, 3 Nov: Mira's challenge lost unless the
## player stood within 0.37 m of her axis). Level zones split the ground at
## the midpoint: nearer the trainer offers her own challenge, nearer a side
## offers that rematch.
static func side_offset(source: Node, trainer: Node3D, side_x: float) -> Vector3:
	var lift := 0.0
	if source is Node3D and is_instance_valid(trainer) and trainer.is_inside_tree() and (source as Node3D).is_inside_tree():
		lift = (source as Node3D).global_position.y - trainer.global_position.y
	return Vector3(side_x, lift, 0.0)

func _ready() -> void:
	top_level = true
	_follow_trainer()
	super._ready()

func _process(_delta: float) -> void:
	_follow_trainer()

func _follow_trainer() -> void:
	var trainer := get_parent() as Node3D
	if trainer == null: return
	var at := trainer.global_position + _world_offset
	if not global_position.is_equal_approx(at): global_position = at
