extends "res://tests/test_case.gd"

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const ART_CONFIG_PATH := "res://data/config/art.json"
const SURGE_CONFIG_PATH := "res://data/config/stormwood_surge.json"

var _fixture: Node
var _look: Node
var _sun: DirectionalLight3D


func before_each() -> void:
	_fixture = Node.new()
	_fixture.name = "NightShadowContractFixture"
	var environment_holder := WorldEnvironment.new()
	environment_holder.name = "WorldEnvironment"
	environment_holder.environment = Environment.new()
	_fixture.add_child(environment_holder)
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_fixture.add_child(_sun)
	_look = WORLD_LOOK.new()
	_look.name = "WorldLook"
	_look.sun_path = NodePath("../Sun")
	_look.environment_path = NodePath("../WorldEnvironment")
	_fixture.add_child(_look)
	# The pure TestCase runner executes during SceneTree._init, before absolute
	# /root lookups are legal. Load the same production data `_ready()` loads,
	# then exercise the real WorldLook apply path against real engine nodes.
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ART_CONFIG_PATH))
	_look.set("_config", parsed as Dictionary)


func after_each() -> void:
	if is_instance_valid(_fixture):
		_fixture.free()


func test_night_softens_shadow_without_changing_day_or_blocking_explicit_layers() -> void:
	_look.call("set_weather", {})
	_look.call("apply_time", "night")
	assert_almost_eq(_sun.shadow_opacity, 0.68, 0.0001, "clear night applies the restrained shadow floor")

	_look.call("apply_time", "day")
	assert_almost_eq(_sun.shadow_opacity, 1.0, 0.0001, "day retains its existing hard-shadow default")

	_look.call("set_weather", {"sun": {"shadow_opacity": 0.08}})
	_look.call("apply_time", "night")
	assert_almost_eq(_sun.shadow_opacity, 0.08, 0.0001, "an explicit weather shadow value wins")

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SURGE_CONFIG_PATH))
	assert_true(parsed is Dictionary, "Stormwood surge config parses")
	var break_opacity := float((parsed as Dictionary).get("presentation", {}).get("shadow_opacity", {}).get("break", -1.0))
	_look.call("set_weather", {"sun": {"shadow_opacity": break_opacity}})
	_look.call("apply_time", "night")
	assert_almost_eq(_sun.shadow_opacity, 1.0, 0.0001, "Stormwood Break keeps its explicit fully hard shadow")
