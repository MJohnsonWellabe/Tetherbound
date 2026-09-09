extends "res://tests/test_case.gd"

const ORIGINS := preload("res://scripts/net/realm_spawn_origins.gd")

func _peers() -> Array:
	return [{"peer_id": 1, "realm": "meadows"},
		{"peer_id": 20, "realm": "water"}, {"peer_id": 30, "realm": "meadows"}]

func test_origin_denies_absent_staying_receiver_and_preserves_authority_and_initialjoin() -> void:
	var origins := ORIGINS.new()
	origins.create("1:20:1@water", "water", 20, _peers())
	assert_false(origins.allowed("1:20:1@water", 30))
	assert_true(origins.allowed("1:20:1@water", 1))
	assert_true(origins.allowed("1:20:1@water", 20))
	assert_true(origins.allowed("1:20:1@water", 40), "unrelated new identity keeps baseline join policy")
	assert_true(origins.allowed("", 30), "existing bodies without origin keep baseline policy")

func test_failed_later_entry_keeps_deny_and_success_clears_only_captured_generation() -> void:
	var origins := ORIGINS.new()
	origins.create("1:20:1@water", "water", 20, _peers())
	var capture := origins.capture(30, "water")
	assert_false(origins.allowed("1:20:1@water", 30), "request/capture alone does not admit")
	origins.create("1:20:2@water", "water", 20, _peers())
	origins.admit_ready(30, "water", capture)
	assert_true(origins.allowed("1:20:1@water", 30))
	assert_false(origins.allowed("1:20:2@water", 30), "stale readiness cannot open a later origin")

func test_origin_is_immutable_and_rollback_requires_its_own_realm_readiness() -> void:
	var origins := ORIGINS.new()
	origins.create("1:20:1@water", "water", 20, _peers())
	origins.create("1:20:1@water", "meadows", 30, [])
	assert_eq(origins.rows["1:20:1@water"].realm, "water")
	assert_eq(origins.rows["1:20:1@water"].owner, 20)
	var capture := origins.capture(30, "water")
	origins.admit_ready(30, "meadows", capture)
	assert_false(origins.allowed("1:20:1@water", 30))
	origins.admit_ready(30, "water", capture)
	assert_true(origins.allowed("1:20:1@water", 30))

func test_last_body_cleanup_disconnect_and_session_reset_bound_policy_lifetime() -> void:
	var origins := ORIGINS.new()
	origins.create("1:20:1@water", "water", 20, _peers())
	var trainer := Node.new()
	var creature := Node.new()
	origins.track("1:20:1@water", trainer)
	origins.track("1:20:1@water", creature)
	trainer.free()
	assert_true(origins.collect_dead().is_empty())
	assert_false(origins.allowed("1:20:1@water", 30))
	origins.disconnect_peer(30)
	assert_true(origins.allowed("1:20:1@water", 30), "reused peer identity cannot inherit previous deny")
	creature.free()
	assert_eq(origins.collect_dead().size(), 1)
	assert_true(origins.rows.is_empty())
	origins.create("2:20:1@water", "water", 20, _peers())
	origins.reset()
	assert_true(origins.rows.is_empty())
	assert_true(origins.live_bodies.is_empty())
