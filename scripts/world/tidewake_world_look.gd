extends "res://scripts/world/world_look.gd"

## The existing host-carried clock, weather and quality controls own the rig.
## Tidewake overrides their presentation inputs before the clock is built.
const TIDEWAKE_PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")


func _load() -> Dictionary:
	var loaded := TIDEWAKE_PROFILE.overlay(super._load(), "lighting")
	# The evening/dawn/night regrade rides its own section. It ships ON (judged
	# at mapped CPU 7.07, close-1024 lt2; score in `_why_lighting_candidate`)
	# and drops out of play only if it is listed in `sections_off` again.
	loaded = TIDEWAKE_PROFILE.overlay(loaded, "lighting_candidate")
	# Night creature emission floor (white-ghost creatures, F39#0 GPU pass):
	# its own section so it can stay OFF until a night round judges it.
	var floor_cfg: Dictionary = TIDEWAKE_PROFILE.overlay({}, "night_creature_floor")
	if floor_cfg.has("creature_emission_floor") and loaded.get("times", {}).has("night"):
		var night: Dictionary = loaded.times.night
		var env: Dictionary = night.get("environment", {})
		env["creature_emission_floor"] = float(floor_cfg.creature_emission_floor)
		night["environment"] = env
	return loaded
