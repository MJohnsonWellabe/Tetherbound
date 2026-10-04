extends "res://scripts/world/playground_world.gd"

## Component fixture: reuse production terrain construction/material methods,
## while suppressing the rest of the playground's actors and world startup.
func _ready() -> void:
	set_process(false)
	set_physics_process(false)

func _process(_delta: float) -> void:
	pass
