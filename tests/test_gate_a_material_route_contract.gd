extends "res://tests/test_case.gd"

## Source-only guard for Gate A's natural paid-build itinerary.  The actual
## candidate run is still controller evidence; this protects the route's
## non-negotiable economics and keeps it out of fixture/state shortcuts.

const ROUTE_PATH := "res://tests/helpers/gate_a_material_route.gd"


func test_route_declares_the_full_prebuild_material_invariant() -> void:
	var source := FileAccess.get_file_as_string(ROUTE_PATH)
	assert_eq(preload("res://tests/helpers/gate_a_material_route.gd").required_stock(),
		{"wood": 30, "fiber": 34, "stone": 8})
	assert_true(source.contains('"wood": 30'))
	assert_true(source.contains('"stone": 8'))
	assert_true(source.contains('"fiber": 34'))
	assert_true(source.contains('Vector2(-5.0, 141.0)'),
		"the one open-spine fiber reserve must remain in the public Band-1 route")
	assert_false(source.contains('Vector2(-168.0, 312.0)'),
		"the current campsite does not require a pond detour")
	for position: String in ["Vector2(40.5, -28.0)", "Vector2(7.0, -24.0)",
			"Vector2(47.0, -34.5)", "Vector2(31.0, -32.0)"]:
		assert_true(source.contains(position), "route retained stale authored coordinates instead of %s" % position)


func test_route_selects_live_resources_through_public_identity() -> void:
	var source := FileAccess.get_file_as_string(ROUTE_PATH)
	assert_true(source.contains('resource_item'))
	assert_true(source.contains('resource_amount'))
	assert_true(source.contains('VEGETATION_POINT_PATH'))
	assert_true(source.contains('HARVEST_NODE_PATH'))
	assert_true(source.contains('Input.parse_input_event'),
		"travel and every material verb must start from parsed controller input")
	assert_true(source.contains('natural material invariant met'))


func test_route_forbids_state_staging_and_private_resource_introspection() -> void:
	var source := FileAccess.get_file_as_string(ROUTE_PATH)
	for forbidden in [
		'get("_item_id")', 'get("_amount")', 'global_position =', 'global_rotation =',
		'inventory.call("add"', 'pending_build', 'free_build', 'call("gather")',
	]:
		assert_false(source.contains(forbidden),
			"natural material route may not use fixture/state shortcut '%s'" % forbidden)
