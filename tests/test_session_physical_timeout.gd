extends "res://tests/test_case.gd"

const SESSION := preload("res://scripts/net/session.gd")

func test_client_timeout_targets_server_and_skips_relayed_client_ids() -> void:
	assert_true(SESSION.timeout_peer_is_physical(false, 1))
	assert_false(SESSION.timeout_peer_is_physical(false, 384642141))
	assert_false(SESSION.timeout_peer_is_physical(false, 117839934))
	assert_false(SESSION.timeout_peer_is_physical(false, 0))

func test_host_still_configures_both_direct_clients_and_skips_itself() -> void:
	assert_true(SESSION.timeout_peer_is_physical(true, 384642141))
	assert_true(SESSION.timeout_peer_is_physical(true, 117839934))
	assert_false(SESSION.timeout_peer_is_physical(true, 1))
	assert_false(SESSION.timeout_peer_is_physical(true, -1))
