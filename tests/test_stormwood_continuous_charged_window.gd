extends "res://tests/test_case.gd"

const SMOKE := preload("res://tests/smoke_stormwood_continuous.gd")
const SOURCE_PATH := "res://tests/smoke_stormwood_continuous.gd"


func test_contiguous_open_time_counts_break_then_runtime_fading() -> void:
	assert_almost_eq(SMOKE.Segment.open_window_seconds(
		{"phase": "break", "remaining": 4.5},
		{"phase": "fading", "remaining": 59.999}), 64.499, 0.001)
	assert_almost_eq(SMOKE.Segment.open_window_seconds(
		{"phase": "fading", "remaining": 54.9}), 54.9)
	assert_almost_eq(SMOKE.Segment.open_window_seconds(
		{"phase": "calm", "remaining": 200.0}), 0.0)
	assert_almost_eq(SMOKE.Segment.open_window_seconds(
		{"phase": "break", "remaining": 12.0},
		{"phase": "calm", "remaining": 300.0}), 12.0)


func test_route_wait_reads_runtime_phase_and_each_node_settles_before_departure() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("MIN_CHARGED_ROUTE_SECONDS := 55.0"),
		"measured route margin must remain explicit")
	assert_true(source.contains("rules.call(\"phase_at\""),
		"window duration must come from production phase policy")
	assert_true(source.contains("next = rules.call(\"phase_at\""),
		"Break must include the runtime's actual following Fading duration")
	assert_true(source.contains("_harvest_charged_node"),
		"each Pools source must settle independently")
	assert_true(source.contains("harvest_node:order:"),
		"the durable source receipt must be awaited")
	assert_true(source.contains("gained != 3"),
		"each source must pay its authored amount")
	assert_true(source.contains("wear_after != wear_before - 1"),
		"a refused or uncommitted swing must not pass as a harvest")
