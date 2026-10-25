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
	# close-1024 GPU asks (OFF until the GPU lane judges it): `_forward_plus`
	# keys that only Forward+/Mobile read, for the night shadow and noon seam.
	loaded = TIDEWAKE_PROFILE.overlay(loaded, "forward_plus_candidate")
	# Night creature emission floor (white-ghost creatures, F39#0 GPU pass):
	# its own section so it can stay OFF until a night round judges it.
	var floor_cfg: Dictionary = TIDEWAKE_PROFILE.overlay({}, "night_creature_floor")
	if floor_cfg.has("creature_emission_floor") and loaded.get("times", {}).has("night"):
		var night: Dictionary = loaded.times.night
		var env: Dictionary = night.get("environment", {})
		env["creature_emission_floor"] = float(floor_cfg.creature_emission_floor)
		night["environment"] = env
	return loaded


## close-1024 `rain_fog_candidate` (OFF in play): Tidewake's sightlines run to
## kilometres, so the shared rain mist (fog_density_add) washes the Veilfall and
## far islands to one grey. Scales only Tidewake's rain mist; the shared preset
## and every other realm are untouched.
func set_weather(delta: Dictionary) -> void:
	var candidate: Dictionary = TIDEWAKE_PROFILE.settings().get("rain_fog_candidate", {})
	# close-1024 `rain_grade_candidate` (OFF in play): sun/sky/environment keys
	# merged over the rain preset so Tidewake rain reads as overcast weather.
	var grade: Dictionary = TIDEWAKE_PROFILE.settings().get("rain_grade_candidate", {})
	if (candidate.is_empty() and grade.is_empty()) or not bool(delta.get("rain", false)):
		super.set_weather(delta)
		return
	var tuned := delta.duplicate(true)
	var env: Dictionary = tuned.get("environment", {})
	if env.has("fog_density_add") and not candidate.is_empty():
		env["fog_density_add"] = float(env.fog_density_add) * float(candidate.get("fog_density_add_scale", 1.0))
	tuned["environment"] = env
	for section: String in ["sun", "sky", "environment"]:
		if grade.has(section):
			tuned[section] = TIDEWAKE_PROFILE.merge(tuned.get(section, {}), grade[section])
	super.set_weather(tuned)
