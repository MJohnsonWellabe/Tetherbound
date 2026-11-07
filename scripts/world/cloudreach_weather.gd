extends "res://scripts/world/world_weather.gd"

## The production weather controller, with Cloudreach's base atmosphere delta
## retained underneath the named shared presets. No capture-only weather state.
var _realm_atmosphere_delta: Dictionary = {}


func _ready() -> void:
	# A server's simulation-only Cloudreach shell has no local weather visuals.
	if bool(get_parent().get("simulation_only")):
		set_process(false)
		return
	super._ready()


func configure_realm_atmosphere(delta: Dictionary) -> void:
	_realm_atmosphere_delta = delta.duplicate(true)
	_apply_realm_weather()


func set_weather(name: String) -> void:
	# Retain production named state, normal timer bookkeeping and rain emitter.
	super.set_weather(name)
	_apply_realm_weather()


func _apply_realm_weather() -> void:
	var look: Node = get_node_or_null(look_path)
	if look != null and look.has_method("set_weather"):
		look.call("set_weather", combined_delta(_realm_atmosphere_delta,
			realm_preset(weather(), _presets.get(weather(), {}))))


## F40#19 (NEAR6-CR): `cloudreach_visual.json` `weather_arms.<name>` (each OFF
## until judged) merge Cloudreach-only keys over a shared weather preset, so the
## realm's rain can carry its own mood without touching the Meadows presets.
static func realm_preset(name: String, preset: Dictionary) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	if not raw is Dictionary:
		return preset
	var result := preset.duplicate(true)
	var arms: Dictionary = (raw as Dictionary).get("weather_arms", {})
	for arm_name: String in arms:
		var arm: Variant = arms[arm_name]
		if not (arm is Dictionary) or (arm as Dictionary).get("enabled") != true:
			continue
		var over: Variant = ((arm as Dictionary).get("presets", {}) as Dictionary).get(name)
		if not (over is Dictionary):
			continue
		for block: String in over:
			if block.begins_with("_"):
				continue
			var value: Variant = (over as Dictionary)[block]
			if value is Dictionary and result.get(block) is Dictionary:
				var merged: Dictionary = (result[block] as Dictionary).duplicate(true)
				for key: String in value:
					if not key.begins_with("_"):
						merged[key] = (value as Dictionary)[key]
				result[block] = merged
			else:
				result[block] = value
	return result


static func combined_delta(realm_delta: Dictionary, preset: Dictionary) -> Dictionary:
	var result := preset.duplicate(true)
	var base_environment: Dictionary = realm_delta.get("environment", {})
	var environment: Dictionary = result.get("environment", {}).duplicate(true)
	# fold_atmosphere_into_base retains only these two delta operators; all
	# realm colours already live in WorldLook's time-aware base configuration.
	if base_environment.has("fog_density_add"):
		environment["fog_density_add"] = float(base_environment["fog_density_add"]) \
			+ float(environment.get("fog_density_add", 0.0))
	if base_environment.has("ambient_energy_mult"):
		environment["ambient_energy_mult"] = float(base_environment["ambient_energy_mult"]) \
			* float(environment.get("ambient_energy_mult", 1.0))
	if not environment.is_empty():
		result["environment"] = environment
	return result
