extends "res://tests/test_case.gd"

## The Meadows procedural build moves collision after its root enters the tree.
## These are the exact player-state contracts that keep platform-velocity
## inheritance from launching the local body during that interval, without
## booting Terrain3D in the unit suite.

const WORLD := preload("res://scripts/world/playground_world.gd")


func test_real_build_disables_player_and_restores_exact_prior_mode() -> void:
	var player := CharacterBody3D.new()
	player.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	player.velocity = Vector3(12.0, -3.0, 8.0)

	var prior := WORLD.hold_player_for_real_build(player, false)
	assert_eq(prior, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_eq(player.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_eq(player.velocity, Vector3.ZERO)

	player.velocity = Vector3(90.0, 40.0, -20.0)
	WORLD.restore_player_after_real_build(player, prior)
	assert_eq(player.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)
	assert_eq(player.velocity, Vector3.ZERO,
		"restoring the build must discard velocity inherited during construction")
	player.free()


func test_simulation_shell_does_not_take_or_restore_the_local_player_hold() -> void:
	var player := CharacterBody3D.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.velocity = Vector3(3.0, 2.0, 1.0)

	var token := WORLD.hold_player_for_real_build(player, true)
	assert_eq(token, -1)
	assert_eq(player.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_eq(player.velocity, Vector3(3.0, 2.0, 1.0))
	WORLD.restore_player_after_real_build(player, token)
	assert_eq(player.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_eq(player.velocity, Vector3(3.0, 2.0, 1.0))
	player.free()


func test_build_restore_does_not_release_pending_arrival_physics_hold() -> void:
	var player := CharacterBody3D.new()
	player.set_physics_process(true)
	var prior := WORLD.hold_player_for_real_build(player, false)
	# `_place_player()` owns this separate flag while a pending realm arrival
	# waits for destination collision to stream.
	player.set_physics_process(false)

	WORLD.restore_player_after_real_build(player, prior)
	assert_false(player.is_physics_processing(),
		"build release must not pre-empt _settle_meadows_realm_arrival")
	assert_eq(player.process_mode, Node.PROCESS_MODE_INHERIT)
	player.free()
