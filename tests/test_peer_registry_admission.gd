extends "res://tests/test_case.gd"

const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")


func _seed() -> RefCounted:
	var registry := PEER_REGISTRY.new()
	registry.add(PEER_REGISTRY.HOST_PEER_ID, "host-character", "Host", "meadows", "trainer")
	registry.add(20, "character-a", "A", "water", "sera")
	return registry


func test_invalid_identity_is_refused_without_registry_mutation() -> void:
	var registry := _seed()
	var before: Dictionary = registry.save_data()
	for malformed: Variant in [null, 42, [], {}, "", "   ", " character-b", "character-b "]:
		var verdict: Dictionary = registry.admission_verdict(30, malformed, 4)
		assert_false(bool(verdict.get("ok", true)), "malformed identity is refused: %s" % str(malformed))
		assert_eq(str(verdict.get("code", "")), "invalid_character")
		assert_eq(registry.save_data(), before, "refusal leaves the real registry byte-for-byte unchanged")


func test_live_character_conflict_preserves_host_and_every_other_peer() -> void:
	var registry := _seed()
	registry.add(21, "character-b", "B", "stormwood", "kael")
	var before: Dictionary = registry.save_data()
	var verdict: Dictionary = registry.admission_verdict(30, "host-character", 4)
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "character_in_use")
	assert_eq(registry.add(30, "host-character", "Impostor"), {},
		"the mutation guard cannot evict peer 1 even if a caller skips admission")
	assert_eq(registry.save_data(), before)
	assert_eq(registry.peer_for_character("host-character"), PEER_REGISTRY.HOST_PEER_ID)
	assert_eq(registry.peer_for_character("character-a"), 20)
	assert_eq(registry.peer_for_character("character-b"), 21)


func test_full_session_refuses_before_mutation() -> void:
	var registry := _seed()
	registry.add(21, "character-b")
	registry.add(22, "character-c")
	var before: Dictionary = registry.save_data()
	var verdict: Dictionary = registry.admission_verdict(30, "character-d", 4)
	assert_false(bool(verdict.get("ok", true)))
	assert_eq(str(verdict.get("code", "")), "session_full")
	assert_eq(str(verdict.get("reason", "")), "This session is full (4/4).")
	assert_eq(registry.save_data(), before)


func test_character_can_reconnect_only_after_old_peer_is_gone() -> void:
	var registry := _seed()
	var live_verdict: Dictionary = registry.admission_verdict(30, "character-a", 4)
	assert_false(bool(live_verdict.get("ok", true)))
	assert_eq(str(live_verdict.get("code", "")), "character_in_use")
	assert_true(registry.remove(20))
	var reconnect_verdict: Dictionary = registry.admission_verdict(30, "character-a", 4)
	assert_true(bool(reconnect_verdict.get("ok", false)))
	assert_false(registry.add(30, "character-a", "A", "water", "sera").is_empty())
	assert_eq(registry.peer_for_character("character-a"), 30)
	assert_eq(registry.peer_for_character("host-character"), PEER_REGISTRY.HOST_PEER_ID)
	assert_eq(registry.size(), 2)
