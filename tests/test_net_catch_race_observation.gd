extends "res://tests/test_case.gd"

const SMOKE := preload("res://tests/smoke_net_catch_race.gd")


func test_client_first_breakout_is_one_granted_throw() -> void:
	# CI 34221457038: the client's successful admission arrived asynchronously.
	# The host was refused, and the client played one breakout, but its submit
	# return still said pending. Neither catch success nor host-first is required.
	var host := {"verdict": {"ok": false, "pending": false,
		"code": "already_resolving"}, "resolutions": []}
	var client := {"verdict": {"ok": false, "pending": true, "code": "pending"},
		"resolutions": [{"caught": false, "shakes": 1}]}
	assert_false(SMOKE._won(host))
	assert_true(SMOKE._won(client), "a completed client breakout proves host admission")
	assert_false(SMOKE._caught(client), "admission is distinct from capture success")


func test_pending_without_host_response_is_not_a_grant() -> void:
	assert_false(SMOKE._won({"verdict": {"ok": false, "pending": true},
		"resolutions": []}))
	assert_false(SMOKE._won({}))


func test_host_first_admission_remains_a_grant() -> void:
	assert_true(SMOKE._won({"verdict": {"ok": true, "pending": false,
		"caught": false}, "resolutions": [{"caught": false, "shakes": 1}]}))
	assert_false(SMOKE._won({"verdict": {"ok": false, "pending": true},
		"last_refusal": {"code": "already_resolving"}, "resolutions": []}))


func test_client_caught_outcome_comes_from_host_resolution() -> void:
	var client := {"verdict": {"ok": false, "pending": true, "caught": false},
		"resolutions": [{"caught": true, "shakes": 3}]}
	assert_true(SMOKE._won(client))
	assert_true(SMOKE._caught(client), "conservation counts the client's actual capture")


func test_two_completed_throws_are_two_grants_not_one() -> void:
	var row := {"verdict": {"ok": false, "pending": true},
		"resolutions": [{"caught": false, "shakes": 1}]}
	assert_eq(int(SMOKE._won(row)) + int(SMOKE._won(row.duplicate(true))), 2,
		"two admitted peers must still fail the smoke's exactly-one invariant")
