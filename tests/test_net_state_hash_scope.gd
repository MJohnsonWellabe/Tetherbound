extends "res://tests/test_case.gd"

## Finding F5 (lane MP-ROWS-8-21), closed: the desync detector must be able to
## agree when two peers hold IDENTICAL WORLDS AND DIFFERENT PERSONAL PROGRESS,
## because that is not an edge case in co-op -- it is the normal state of two
## people playing together. One has done the tutorial, the other has not; one
## slept at home last night, the other did not.
##
## What shipped instead: `HASHED_KEYS` began with `progression`, and
## `save_game.gd` writes that key as the world's flags MERGED WITH the local
## player's own. Two peers with byte-identical worlds therefore hashed
## differently the moment either earned a personal flag. 7.A's reconnect smoke
## could ask for hash equality only because its joiner held nothing personal;
## the first smoke to give a client a player flag on purpose measured "state
## hashes never agreed across peers within 600 frames" while both peers'
## `world_snapshot()` were identical key for key.
##
## Why the proof lives here and not only in a net smoke: the selection was
## unreachable. It existed inside a heartbeat, inside a subprocess, behind a
## save file -- so nothing could assert on it and it went four waves unnoticed.
## `peer_runner.gd::hashed_subset()` is now a pure static over a world
## snapshot, and these tests are the negative control the mechanism never had.
## The net smokes still prove the detector FIRES; this file proves what it
## looks at.

const PEER_RUNNER := preload("res://tools/net/peer_runner.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")


## A world snapshot in `WorldState.save_data()`'s exact shape, so a rename there
## breaks this file rather than quietly making it assert about nothing.
func _snapshot(flags: Dictionary, day: int = 3) -> Dictionary:
	var world := WORLD_STATE.new()
	world.day = day
	world.world_seed = 12345
	for id: String in flags:
		(world.flags as RefCounted).set_flag(id)
	return world.save_data()


func test_the_hashed_set_is_world_state_keys_and_progression_is_gone() -> void:
	var snap := _snapshot({"boss_warden_defeated": true})
	var subset: Dictionary = PEER_RUNNER.hashed_subset(snap)
	assert_false(subset.has("progression"),
		"`progression` is the MERGED world+player store; hashing it is finding F5")
	assert_true(subset.has("flags"), "the world-only flag store is what gets hashed")
	for key: String in subset:
		assert_true(snap.has(key),
			"hashed key '%s' is not a WorldState.save_data() key" % key)


func test_no_player_scoped_key_survives_the_selection() -> void:
	# Every key contract §7 names as excluded, plus the character half D100
	# splits out. If any of these ever reaches the hash, two peers who are
	# simply different people stop being able to agree.
	var personal := ["party", "inventory", "hotbar", "satiety", "map", "realm_maps",
		"alpha_pins", "player_pose", "current_realm", "pending_realm_entry",
		"realm_hearts", "progression"]
	var snap := _snapshot({"boss_warden_defeated": true})
	for key: String in personal:
		snap[key] = "a value no two players would share"
	var subset: Dictionary = PEER_RUNNER.hashed_subset(snap)
	for key: String in personal:
		assert_false(subset.has(key),
			"player-scoped key '%s' reached the desync hash" % key)


func test_two_peers_with_one_world_and_different_personal_progress_agree() -> void:
	# THE ROW. Same world, two different people. The hash must be equal.
	var host := _snapshot({"boss_warden_defeated": true})
	var client := _snapshot({"boss_warden_defeated": true})
	host["party"] = ["terrapup", "galecrest"]
	host["progression"] = {"boss_warden_defeated": true, "opening:beat:three": true}
	client["party"] = []
	client["progression"] = {"boss_warden_defeated": true, "tutorial_gather": true}
	assert_eq(
		JSON.stringify(PEER_RUNNER.hashed_subset(host), "", true),
		JSON.stringify(PEER_RUNNER.hashed_subset(client), "", true),
		"identical worlds must hash equal however differently the two people have played")


func test_a_real_world_difference_still_diverges() -> void:
	# The other half, and the reason this is a scope fix rather than a mute:
	# a detector that agrees about everything has stopped being a detector.
	var host := _snapshot({"boss_warden_defeated": true})
	var client := _snapshot({})
	assert_ne(
		JSON.stringify(PEER_RUNNER.hashed_subset(host), "", true),
		JSON.stringify(PEER_RUNNER.hashed_subset(client), "", true),
		"a world flag one peer holds and the other does not MUST still diverge")


func test_a_world_record_difference_still_diverges() -> void:
	var host := _snapshot({})
	var client := _snapshot({})
	host["placed_buildings"] = [{"uid": "b1", "id": "wall", "realm": "meadows"}]
	assert_ne(
		JSON.stringify(PEER_RUNNER.hashed_subset(host), "", true),
		JSON.stringify(PEER_RUNNER.hashed_subset(client), "", true),
		"a building one peer has and the other does not MUST still diverge")


func test_the_day_still_counts_and_the_seed_still_does_not() -> void:
	# Contract §7 as amended: `world_seed` is ERASED from the hashed dictionary
	# and asserted separately against the pin, because a per-process roll would
	# make every fresh session look desynced.
	var host := _snapshot({}, 3)
	var client := _snapshot({}, 4)
	assert_ne(
		JSON.stringify(PEER_RUNNER.hashed_subset(host), "", true),
		JSON.stringify(PEER_RUNNER.hashed_subset(client), "", true),
		"a different day is a real divergence")
	var a := _snapshot({}, 3)
	var b := _snapshot({}, 3)
	b["world_seed"] = 999
	assert_eq(
		JSON.stringify(PEER_RUNNER.hashed_subset(a), "", true),
		JSON.stringify(PEER_RUNNER.hashed_subset(b), "", true),
		"`world_seed` is asserted against the pin separately, never hashed")
