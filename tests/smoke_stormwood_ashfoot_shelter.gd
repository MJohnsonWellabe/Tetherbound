extends SceneTree

## Ashfoot shelter in the live production Stormwood (GPU F41 matrix refusal,
## 24 Oct: "Ashfoot 11 m exterior incorrectly received roof/lightning shelter").
##
##   godot --headless --path . --script tests/smoke_stormwood_ashfoot_shelter.gd
##
## The two stands are the F41 catalogue's own (capture_f41_stormwood_catalog.gd
## `_ashfoot_shelter_stands`): inside, 0.6 m along the shelter axis from the
## Ashfoot centre; outside, 11 m across it. A control stand 60 m out lies past
## the Ashfoot camp safe zone (stormwood_surge.json safe_zones.ashfoot, r 42).
##
## What each stand must show, from the owning specs:
##   * the near-rain roof (`StormwoodSurge._roofed`, physics ray overhead) is ON
##     only under the actual roof: inside yes, 11 m out no, 60 m out no;
##   * lightning shelter (`StormwoodLightning.sheltered`, cached as
##     `StormwoodSurge.sheltered`) follows WORLD §5.2 "camps with rods ... are
##     safe": inside and 11 m out (inside the camp safe zone) yes, 60 m out no;
##     the live guard and the cached state always agree.
##
## Disclosed fixtures: debug placement at each stand (the production player
## body, settled on the ground); the camera rig follows as in play; no input.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const ASHFOOT_CENTER := Vector2(-365.0, 460.0)
const TEST_SAVE_DIR := "user://stormwood_ashfoot_shelter"

var _failures: Array[String] = []
var _passes := 0
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _surge: Node
var _lightning: Node
var _stands_done := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(900.0).timeout.connect(func() -> void:
		_expect(false, "900 second watchdog expired")
		_finish())
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_game = GAME.new()
		_game.name = "Game"
		root.add_child(_game)
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.get("local").set("character_id", "stormwood-ashfoot-shelter")
	_game.get("world").set("world_id", "stormwood-ashfoot-shelter-world")
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	_game.call("announce_realm", "meadows", "stormwood")
	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 240000
	while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(bool(_world.call("shell_build_complete")), "production Stormwood built")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _world.get_node_or_null(^"StormwoodLightning")
	_expect(_player != null and _surge != null and _lightning != null, "production player, surge and strike runtime mounted")
	if not _failures.is_empty():
		_finish()
		return
	var yaw := deg_to_rad(135.0)
	var along := Vector2(sin(yaw), cos(yaw))
	var across := Vector2(along.y, -along.x)
	await _stand("inside", ASHFOOT_CENTER + along * 0.6, true, true)
	await _stand("outside 11 m", ASHFOOT_CENTER + across * 11.0, false, true)
	await _stand("outside 60 m (past the camp safe zone)", ASHFOOT_CENTER + across * 60.0, false, false)
	_expect(_stands_done == 3, "all three stands were measured (%d)" % _stands_done)
	_finish()


func _stand(label: String, at: Vector2, want_roof: bool, want_shelter: bool) -> void:
	var ground := float(_world.call("ground_height_at", at.x, at.y))
	_player.global_position = Vector3(at.x, ground + 0.2, at.y)
	_player.velocity = Vector3.ZERO
	# The surge refreshes shelter and roof every 0.25 s; give it well over that.
	for _frame in 90:
		await physics_frame
	var pos := _player.global_position
	var roofed := bool(_surge.get("_roofed"))
	var exclude: Array[RID] = [_player.get_rid()]
	var subject_roof := bool(_surge.call("roof_over", pos, exclude, 2.2))
	var live := bool(_lightning.call("sheltered", pos, _player))
	var cached := bool(_surge.get("sheltered"))
	print("ASHFOOT %s at (%.1f, %.1f, %.1f): roofed=%s subject_roof=%s lightning_sheltered=%s cached=%s region=%s" % [
		label, pos.x, pos.y, pos.z, roofed, subject_roof, live, cached, str(_surge.call("region_at", pos))])
	_expect(subject_roof == want_roof, "%s: roof over the trainer is %s (want %s)" % [label, subject_roof, want_roof])
	_expect(roofed == want_roof, "%s: near-rain roof state is %s (want %s)" % [label, roofed, want_roof])
	_expect(live == want_shelter, "%s: lightning shelter is %s (want %s)" % [label, live, want_shelter])
	_expect(cached == live, "%s: cached surge shelter agrees with the live guard" % label)
	_stands_done += 1


func _expect(ok: bool, message: String) -> void:
	if ok:
		_passes += 1
	else:
		_failures.append(message)
		push_error(message)


func _finish() -> void:
	print("smoke_stormwood_ashfoot_shelter: %d checks, %d failed" % [_passes + _failures.size(), _failures.size()])
	for failure: String in _failures:
		print("  FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
