extends "res://tests/test_case.gd"

const RELAY := preload("res://scripts/world/tether_relay.gd")
const CONFIG_PATH := "res://data/config/tether_relay.json"


func _gate_config() -> Dictionary:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(CONFIG_PATH)), OK,
		"relay config remains valid JSON")
	return (json.data as Dictionary).get("gate", {}) as Dictionary


func test_installed_gate_arch_is_fitted_around_the_unchanged_traversable_opening() -> void:
	var gate := _gate_config()
	var presentation := gate.get("presentation", {}) as Dictionary
	var mesh := load(str(presentation.get("model", ""))) as Mesh
	assert_true(mesh != null, "configured relay gate presentation is an installed Mesh")
	if mesh == null:
		return
	assert_eq(mesh.get_surface_count(), 2,
		"installed arch preserves broad masonry and raised detail surfaces")
	assert_eq(mesh.surface_get_name(0), "LightRock")
	assert_eq(mesh.surface_get_name(1), "DarkRock")

	var metrics := RELAY.gate_presentation_metrics(mesh)
	assert_false(metrics.is_empty(), "aperture is measurable from installed geometry")
	assert_almost_eq(float(metrics.get("opening_width", 0.0)), 0.890756, 0.0001)
	assert_almost_eq(float(metrics.get("opening_height", 0.0)), 0.989434, 0.0001)

	var collision_opening := float(gate.get("opening", 0.0))
	var pier_width := float(gate.get("pier_width", 0.0))
	var outer_height := float(gate.get("pier_height", 0.0)) \
		+ float(gate.get("lintel_height", 0.0))
	var outer_depth := float(gate.get("pier_depth", 0.0))
	var clearance := float(presentation.get("clearance_each_side_m", 0.0))
	var fit := RELAY.gate_presentation_fit(mesh, collision_opening,
		outer_height, outer_depth, clearance)
	assert_false(fit.is_empty(), "configured presentation produces a valid fit")
	var visible_opening := float(fit.get("visible_opening", 0.0))
	assert_almost_eq(visible_opening, collision_opening + clearance * 2.0, 0.0001)
	assert_true(visible_opening >= collision_opening,
		"visible stone never intrudes into the traversable collision opening")
	assert_between((visible_opening - collision_opening) * 0.5, 0.0, 0.021,
		"invisible collision margin stays at the authored two centimetres per side")
	var outer_size: Vector3 = fit.get("outer_size", Vector3.ZERO)
	assert_almost_eq(outer_size.y, outer_height, 0.0001)
	assert_almost_eq(outer_size.z, outer_depth, 0.0001)
	assert_true(outer_size.x >= collision_opening + pier_width * 2.0,
		"arch shoulders overlap the retained outer gate envelope instead of leaving wall gaps")
