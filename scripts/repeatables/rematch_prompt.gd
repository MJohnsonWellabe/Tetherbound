extends "res://scripts/world/interactable.gd"

## The trainer turns to face the player. Its two side interaction zones must
## follow its position without orbiting with that presentation rotation.
var _world_offset: Vector3

func _init(world_offset: Vector3 = Vector3.ZERO) -> void:
	_world_offset = world_offset

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
