extends "res://scripts/world/world_look.gd"

## The existing host-carried clock, weather and quality controls own the rig.
## Tidewake overrides their presentation inputs before the clock is built.
const TIDEWAKE_PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")


func _load() -> Dictionary:
	return TIDEWAKE_PROFILE.overlay(super._load(), "lighting")
