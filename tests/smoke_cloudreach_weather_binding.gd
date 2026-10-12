extends SceneTree

## Focused integration contract: inspect the shipping scene without building
## the full realm. Native F40 remains the clock/rain/visibility acceptance gate.
const WEATHER := preload("res://scripts/world/cloudreach_weather.gd")
const SHARED_WEATHER := preload("res://scripts/world/world_weather.gd")
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/world/cloudreach_cliffs.tscn") as PackedScene
	_check(scene != null, "shipping Cloudreach scene loads")
	if scene != null:
		var state := scene.get_state()
		var weather_nodes := 0
		var bindings := {}
		var root_nodes: Array[String] = []
		for i in state.get_node_count():
			var path := str(state.get_node_path(i)).trim_prefix("./")
			root_nodes.append(path)
			if path == "WorldWeather":
				weather_nodes += 1
				for property_index in state.get_node_property_count(i):
					bindings[str(state.get_node_property_name(i, property_index))] = state.get_node_property_value(i, property_index)
		_check(weather_nodes == 1, "exactly one root WorldWeather binding exists")
		_check(bindings.get("script") == WEATHER, "shipping node uses Cloudreach production adapter")
		_check(bindings.get("look_path") == NodePath("../WorldLook") and "WorldLook" in root_nodes,
			"weather binds the shipping production clock/look node")
		_check(bindings.get("player_path") == NodePath("../Player") and "Player" in root_nodes,
			"weather binds the shipping local player for rain following")
	var weather_script: Script = WEATHER
	_check(weather_script.get_base_script() == SHARED_WEATHER,
		"adapter inherits real named-weather and rain implementation")
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json"))
	var shared: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/weather.json"))
	var realm := {"environment": {"fog_density_add": visual.atmosphere.environment.fog_density_add}}
	var realm_before := realm.duplicate(true)
	_check(is_equal_approx(float(realm.environment.fog_density_add), -0.00015),
		"preserve the existing authored Cloudreach fog delta")
	for name: String in ["clear", "rain"]:
		var preset: Dictionary = shared.presets[name]
		var preset_before := preset.duplicate(true)
		var result := WEATHER.combined_delta(realm, preset)
		var expected := -0.00015 + float(preset.get("environment", {}).get("fog_density_add", 0.0))
		_check(is_equal_approx(float(result.environment.fog_density_add), expected),
			name + " composes realm fog with the production preset")
		_check(bool(result.get("rain", false)) == (name == "rain"),
			name + " preserves the actual precipitation request")
		_check(preset == preset_before and realm == realm_before,
			name + " leaves both authored inputs unchanged")
	for failure in failures:
		push_error(failure)
	print("CLOUD WEATHER BINDING: checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
