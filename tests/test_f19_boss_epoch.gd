extends "res://tests/test_case.gd"

const HARNESS := preload("res://tests/test_foundation_resource_save.gd")
const WORLD := preload("res://autoload/world_state.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")

func test_derived_settlement_flags_preserve_the_original_retained_boss_epoch() -> void:
	var game := HARNESS.FixtureGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world-a"
	game.world.reward_delivery_namespace = "namespace-a"
	var session := HARNESS.FixtureSession.new()
	session.fixture = game
	game.session = session
	var intent := {"trainer_id": "warden_aldis", "biome": "meadows", "encounter_id": "fight-a"}
	var captured := {"source_key": "boss:warden_aldis", "realm": "meadows", "validated_host_outcome": "win",
		"encounter_id": "fight-a", "participants": ["character-a"]}
	var event := EVENT.make(game.world, "original-fight-epoch", "boss:warden_aldis:fight-a", [{
		"character_id": "character-a", "action": "boss_relic", "intent": intent, "context": captured}])
	assert_false(event.is_empty())
	game.world.reward_deliveries[event.delivery_id] = event
	var context := captured.duplicate(true)
	context.merge({"character_id": "character-a", "expected_revision": 0, "in_range": true,
		"retained_event": event.delivery_id, "in_combat": false, "foundation_runtime_authorized": true,
		"boss_settlement_world_flags": []})
	var accepted := {"action": "boss_relic", "character_id": "character-a", "intent": intent, "host_context": context}
	assert_eq(session.foundation_event_stage_epoch(accepted), "original-fight-epoch")
	context.boss_settlement_world_flags = ["world_changed_after_victory"]
	assert_eq(session.foundation_event_stage_epoch(accepted), "original-fight-epoch", "current world flags are derived, never an immutable victory field")
	context.validated_host_outcome = "loss"
	assert_eq(session.foundation_event_stage_epoch(accepted), "", "a changed original verdict cannot match")
	session.free()
	game.free()
