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
			_presets.get(weather(), {})))


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
