extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_tidal_segment.gd")


func test_next_crossing_requires_earned_shellwatch_gate() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var route: Dictionary = {}
	for row: Dictionary in world.water_routes:
		if str(row.id) == SEGMENT.TIDAL_ROUTE:
			route = row
	assert_true(SEGMENT.tidal_route_contract(route))
	var wrong_gate := route.duplicate(true)
	wrong_gate.required_departure_flag = "water_dock_brine_steps_trial_won"
	assert_false(SEGMENT.tidal_route_contract(wrong_gate))
	var wrong_mode := route.duplicate(true)
	wrong_mode.intended_traversal = "mounted_swimming"
	assert_false(SEGMENT.tidal_route_contract(wrong_mode))


func test_unrun_helper_cannot_claim_alpha_recipe_completion() -> void:
	var helper := SEGMENT.new()
	assert_false(helper.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["Iona did not open"]))
