extends "res://tests/test_case.gd"

const SWIM := preload("res://scripts/player/swim_state.gd")


func test_exhaustion_charges_only_remaining_frame_and_is_partition_invariant() -> void:
	var state := SWIM.new()
	state.enter_water(false, 0.0)
	var whole: Dictionary = state.advance(1, 2.0, 2.0, 100.0, 2.0, 4.0)
	assert_almost_eq(whole.stamina_spent, 2.0, 0.001)
	assert_almost_eq(whole.health_lost, 4.0, 0.001)
	var first: Dictionary = state.advance(1, 1.0, 2.0, 100.0, 2.0, 4.0)
	var second: Dictionary = state.advance(1, 1.0, 0.0, 100.0, 2.0, 4.0)
	assert_almost_eq(first.health_lost + second.health_lost, whole.health_lost, 0.001)
	assert_true(state.drowning)


func test_combat_freezes_resources_and_failed_mount_resumes_human() -> void:
	var state := SWIM.new()
	state.enter_water(true, 0.0)
	state.pause_for_combat()
	state.pause_for_combat()
	var change: Dictionary = state.advance(1, 90.0, 0.0, 200.0, 2.0, 3.0)
	assert_eq(change.stamina_spent, 0.0)
	assert_eq(change.health_lost, 0.0)
	assert_false(state.drowning)
	state.resume_after_combat(false)
	assert_eq(state.mode, SWIM.Mode.HUMAN)


func test_combat_returns_to_surviving_mount() -> void:
	var state := SWIM.new()
	state.enter_water(true, 0.0)
	state.pause_for_combat()
	state.resume_after_combat(true)
	assert_eq(state.mode, SWIM.Mode.MOUNTED)


func test_land_ends_pressure_without_refilling_stamina() -> void:
	var state := SWIM.new()
	state.enter_water(false, 0.0)
	state.advance(1, 1.0, 0.0, 100.0, 2.8, 4.0)
	state.reach_land(Vector3(5, 2, 9))
	assert_false(state.drowning)
	assert_eq(state.stamina_fraction, 0.0)
	assert_true(state.has_safe_landing)
	assert_eq(state.safe_landing, Vector3(5, 2, 9))
	assert_eq(state.advance(1, 5.0, 0.0, 100.0, 2.8, 4.0).health_lost, 0.0)


func test_remote_peer_cannot_advance_owned_resources() -> void:
	var state := SWIM.new()
	state.owner_peer_id = 7
	state.enter_water(false, 0.0)
	var change: Dictionary = state.advance(8, 5.0, 0.0, 100.0, 2.8, 4.0)
	assert_eq(change.health_lost, 0.0)
	assert_false(state.drowning)


func test_owned_snapshot_reconstructs_drowning_and_rejects_wrong_peer_or_replay() -> void:
	var owner := SWIM.new()
	owner.owner_peer_id = 7
	owner.reach_land(Vector3(1, 2, 3))
	owner.enter_water(true, 4.0)
	owner.advance(7, 1.0, 0.0, 200.0, 2.0, 3.0)
	var remote := SWIM.new()
	remote.owner_peer_id = 7
	assert_false(remote.apply_remote_snapshot(owner.snapshot(), 8))
	assert_true(remote.apply_remote_snapshot(owner.snapshot(), 7))
	assert_eq(remote.mode, SWIM.Mode.MOUNTED)
	assert_true(remote.drowning)
	assert_eq(remote.safe_landing, Vector3(1, 2, 3))
	assert_false(remote.apply_remote_snapshot(owner.snapshot(), 7))


func test_invalid_snapshot_is_atomic() -> void:
	var state := SWIM.new()
	state.enter_water(false, 0.0)
	var packet: Dictionary = state.snapshot()
	packet.stamina_fraction = NAN
	var remote := SWIM.new()
	assert_false(remote.apply_remote_snapshot(packet, 1))
	assert_eq(remote.mode, SWIM.Mode.LAND)
	for key in ["owner_peer_id", "version", "revision", "mode", "resume_mode", "surface_y", "stamina_fraction", "drowning", "has_safe_landing"]:
		for invalid in [{}, [], "1", null]:
			var malformed: Dictionary = state.snapshot()
			malformed[key] = invalid
			assert_false(remote.apply_remote_snapshot(malformed, 1))
	packet.stamina_fraction = 1.0
	packet.drowning = true
	assert_false(remote.apply_remote_snapshot(packet, 1))
	assert_eq(remote.mode, SWIM.Mode.LAND)


func test_efficiency_reduces_drain_without_granting_regeneration() -> void:
	var state := SWIM.new()
	state.enter_water(false, 0.0)
	var result: Dictionary = state.advance(1, 10.0, 100.0, 100.0, 2.8, 4.0, 0.65)
	assert_almost_eq(result.stamina_spent, 18.2, 0.001)
	assert_eq(result.health_lost, 0.0)
	assert_eq(state.advance(1, -1.0, 50.0, 100.0, 2.8, 4.0).stamina_spent, 0.0)
