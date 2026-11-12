extends "res://tests/test_case.gd"

## F39#17 (LANE-BELOW6, 12 Nov 2026): `restored_sea_1112` gives the sea a restored
## look and clears lane debris only while `water_currents_restored` is set.

const RESTORED_SEA := preload("res://scripts/world/water_restored_sea.gd")
const CONFIG := "res://data/config/water_current_flow_visual.json"


class Flags extends RefCounted:
	var set_flags := {}
	func has(flag: String) -> bool:
		return set_flags.has(flag)


## Stands in for water_current_drift_markers.gd, which keeps the same list.
class Markers extends Node:
	var _drifters: Array[Dictionary] = []


func _cfg() -> Dictionary:
	return (JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary).get("restored_sea_1112", {})


func test_flag_is_declared_and_attach_follows_it() -> void:
	var cfg := _cfg()
	assert_false(cfg.is_empty(), "restored_sea_1112 is declared")
	assert_true(str(cfg.get("scope", "")).begins_with("client_presentation"))
	if not bool(cfg.get("enabled", false)):
		assert_true(RESTORED_SEA.settings().is_empty(), "off: no settings, so nothing attaches")


func test_sea_and_debris_follow_the_world_fact() -> void:
	var sea := ShaderMaterial.new()
	sea.shader = load("res://shaders/water.gdshader")
	sea.set_shader_parameter("wave_strength", 0.25)
	var markers := Markers.new()
	var log := Node3D.new()
	var buoy := Node3D.new()
	markers.add_child(log)
	markers.add_child(buoy)
	markers._drifters = [{"node": log}, {"node": buoy, "anchored": true}]
	var flags := Flags.new()
	var node: Node = RESTORED_SEA.new()
	node.call("setup", {"water": {"wave_strength": 0.1, "shallow_colour": "#9ee0cf"}, "clear_debris": true}, sea, markers, flags)
	assert_false(bool(node.call("is_restored_look")), "live: the sea is untouched")
	assert_eq(float(sea.get_shader_parameter("wave_strength")), 0.25)
	assert_true(log.visible, "live: debris drifts in the lane")
	flags.set_flags["water_currents_restored"] = true
	node.call("_process", 2.0)
	assert_true(bool(node.call("is_restored_look")), "restored: the look follows the fact")
	assert_eq(float(sea.get_shader_parameter("wave_strength")), 0.1, "restored: calmer surface")
	assert_false(log.visible, "restored: the debris is cleared")
	assert_true(buoy.visible, "restored: the buoys stay")
	flags.set_flags.clear()
	node.call("_process", 2.0)
	assert_eq(float(sea.get_shader_parameter("wave_strength")), 0.25, "cleared fact: the live values return")
	assert_true(log.visible)
	node.free()
	markers.free()
