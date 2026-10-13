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
	# The durable source receipt (411c6ee06): the settle loop awaits the
	# chapter's own exact-site predicate, which still reads the exact
	# "harvest_node:order:<id>" receipt (or that site's renewable stock record).
	assert_true(source.contains("""		for _frame in 600:
			if _site_gathered(id) \\
					and int(inventory.call("count", "stormglass")) > count_before:"""),
		"the durable source receipt must be awaited")
	assert_true(source.contains("preload(\"res://scripts/world/stormwood_harvest_runtime.gd\").site_gathered("),
		"the awaited receipt must be the chapter's own site_gathered predicate")
	var runtime := FileAccess.get_file_as_string("res://scripts/world/stormwood_harvest_runtime.gd")
	assert_true(runtime.contains("\"harvest_node:order:\" + id"),
		"site_gathered must still read the exact durable source receipt")
	assert_true(source.contains("gained != 3"),
		"each source must pay its authored amount")
	assert_true(source.contains("wear_after != wear_before - 1"),
		"a refused or uncommitted swing must not pass as a harvest")
