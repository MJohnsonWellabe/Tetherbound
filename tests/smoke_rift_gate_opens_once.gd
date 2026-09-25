extends SceneTree

## F05 (ROADMAP §3) / ACCEPTANCE §6.1 F05 and card M4: "the gate opens exactly
## once" -- the Meadows -> Cloudreach crossing `scripts/world/rift_crossing.gd`
## rebuilds over the storm road's carve.
##
##   godot --headless --path . --script tests/smoke_rift_gate_opens_once.gd
##
## What "exactly once" is taken to mean here, each proven deterministically:
##   (a) before `legendary_freed` there is no span: no deck, no trigger;
##   (b) when the flag lands LIVE, the crossing waits out the collapse
##       (`collapse.hold_seconds + dissipate_seconds` from rift_collapse.json),
##       then builds the span ONCE and animates it in (`appear_seconds`);
##       afterwards `span_ready()` and exactly one deck and one trigger;
##   (c) any later flag/revision change never re-opens or rebuilds it;
##   (d) entering the far trigger repeatedly (twice in the same frame, then
##       again on later frames) calls `Game.enter_realm("cloudreach", ...)`
##       once, the realm changes once, and `realm_gate_cloudreach_unlocked` is
##       written once;
##   (e) a later load of a world where the flag is already set stands the span
##       instantly -- one deck, one trigger, no collapse wait, no appear
##       animation replayed.
##
## The clock is driven by hand: after `build()` the crossing's own processing
## is switched off and its `_process` is stepped with a fixed delta, so every
## timing assertion is frame-rate independent. The span/trigger counts are
## read both from the scene tree and from the crossing's read-only
## `openings()` / `crossings_fired()` counters.
##
## DISCLOSED FIXTURES (as `smoke_rift_crossing_same_five.gd`): the Warden's
## durable facts are set directly and the Meadows side is a flat stand-in
## world carrying the REAL `rift_crossing.gd`. The Cloudreach side is the
## production scene through the production realm router.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const RIFT_CROSSING := preload("res://scripts/world/rift_crossing.gd")
const CONFIG_PATH := "res://data/config/rift_collapse.json"
const TEST_SAVE_DIR := "user://rift_gate_opens_once_smoke"
const SLOT := 3
const STEP := 1.0 / 60.0

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


var failures: Array[String] = []
var passes: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var started_ms := Time.get_ticks_msec()
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	var progression: RefCounted = game.get("progression")
	for flag in ["legendary_freed", "realm_key_cloudreach", "realm_gate_cloudreach_unlocked"]:
		_check(not bool(progression.call("has", flag)), "setup: '%s' starts unset" % flag)

	var config := _load_json(CONFIG_PATH)
	var collapse: Dictionary = config.get("collapse", {})
	var wait_s := float(collapse.get("hold_seconds", 1.2)) + maxf(float(collapse.get("dissipate_seconds", 9.0)), 0.01)
	var appear_s := maxf(float((config.get("crossing", {}) as Dictionary).get("appear_seconds", 3.0)), 0.05)

	# ---------------------------------------------------------------- (a) ---
	var world_a := _stand_in("GateOnceLive")
	var crossing: Node3D = RIFT_CROSSING.new()
	crossing.name = "RiftCrossing"
	world_a.add_child(crossing)
	crossing.call("build", world_a)
	# The hand-driven clock below is only honest if build() itself turned the
	# crossing's own clock on: otherwise disabling it here would hide a crossing
	# that never processes in the game.
	_check(crossing.is_processing(), "(a) build() enables the crossing's own processing")
	crossing.set_process(false)
	await process_frame
	_check(_decks(crossing) == 0 and _triggers(crossing) == 0 and int(crossing.call("openings")) == 0,
		"(a) before legendary_freed: no deck, no trigger (decks=%d triggers=%d openings=%d)"
			% [_decks(crossing), _triggers(crossing), int(crossing.call("openings"))])
	_step(crossing, wait_s + appear_s + 5.0)
	progression.call("set_flag", "defeated_warden")
	progression.call("set_flag", "realm_key_cloudreach")
	_step(crossing, wait_s + appear_s + 5.0)
	_check(_decks(crossing) == 0 and _triggers(crossing) == 0 and not bool(crossing.call("span_ready"))
			and not bool(crossing.get("_waiting_for_collapse")),
		"(a) %.1fs of other flag changes without legendary_freed: still no span, no collapse wait" % (2.0 * (wait_s + appear_s + 5.0)))

	# ---------------------------------------------------------------- (b) ---
	progression.call("set_flag", "legendary_freed")
	_step(crossing, STEP)
	_check(bool(crossing.get("_waiting_for_collapse")) and _decks(crossing) == 0 and _triggers(crossing) == 0,
		"(b) flag lands live: crossing enters the collapse wait with nothing built yet")
	_step(crossing, wait_s - 3.0 * STEP)
	_check(_decks(crossing) == 0 and _triggers(crossing) == 0 and int(crossing.call("openings")) == 0,
		"(b) just short of hold+dissipate (%.2fs): still no deck/trigger" % wait_s)
	_step(crossing, 4.0 * STEP)
	_check(int(crossing.call("openings")) == 1 and _decks(crossing) == 1 and _triggers(crossing) == 1
			and bool(crossing.get("_appearing")) and not bool(crossing.call("span_ready")),
		"(b) collapse finished: span built once and animating in (openings=%d decks=%d triggers=%d)"
			% [int(crossing.call("openings")), _decks(crossing), _triggers(crossing)])
	var anchor := crossing.find_child("DeckAnchor", false, false) as Node3D
	_check(anchor != null and anchor.scale.x < 0.5, "(b) deck grows from the near abutment (scale.x=%.3f)" % (anchor.scale.x if anchor != null else -1.0))
	_step(crossing, appear_s + STEP)
	_check(bool(crossing.call("span_ready")) and anchor != null and is_equal_approx(anchor.scale.x, 1.0)
			and _decks(crossing) == 1 and _triggers(crossing) == 1 and int(crossing.call("openings")) == 1
			and _deck_collision_live(crossing),
		"(b) after appear_seconds: span_ready(), exactly one deck (collider live) and one trigger")

	# ---------------------------------------------------------------- (c) ---
	var deck_id := anchor.get_instance_id() if anchor != null else 0
	var trigger_a := crossing.find_child("RiftCrossingTrigger", false, false) as Area3D
	var trigger_id := trigger_a.get_instance_id() if trigger_a != null else 0
	var revision_before := int(progression.get("revision"))
	for i in 5:
		# Shipped, scoped flags only: toggle one on/off and re-assert the
		# gate's own flag, so the revision moves every round.
		progression.call("set_flag", "legendary_joined", i % 2 == 0)
		progression.call("set_flag", "legendary_freed")
		_step(crossing, wait_s + appear_s + 1.0)
	_check(int(progression.get("revision")) > revision_before, "(c) setup: the revision really moved (%d -> %d)"
		% [revision_before, int(progression.get("revision"))])
	var anchor_after := crossing.find_child("DeckAnchor", false, false)
	var trigger_after := crossing.find_child("RiftCrossingTrigger", false, false)
	_check(int(crossing.call("openings")) == 1 and _decks(crossing) == 1 and _triggers(crossing) == 1
			and anchor_after != null and anchor_after.get_instance_id() == deck_id
			and trigger_after != null and trigger_after.get_instance_id() == trigger_id
			and not bool(crossing.get("_waiting_for_collapse")) and bool(crossing.call("span_ready")),
		"(c) five further flag/revision changes: no reopen, no rebuild, same deck and trigger instances (openings=%d)"
			% int(crossing.call("openings")))
	_check(not bool(progression.call("has", "realm_gate_cloudreach_unlocked")),
		"(c) opening the span does not itself mark the realm gate crossed")
	world_a.queue_free()
	await process_frame

	print("  [t] live phase (a-c) done at %d ms" % (Time.get_ticks_msec() - started_ms))
	# ---------------------------------------------------------------- (e) ---
	# A real save with the flag set, the flags blanked, and a real load: the
	# world built after it reads legendary_freed from disk.
	_check(bool(game.call("save_game", SLOT)), "(e) setup: Game.save_game() with legendary_freed set")
	progression.call("load_data", {})
	_check(not bool(progression.call("has", "legendary_freed")), "(e) setup: flags blanked before the load")
	_check(bool(game.call("load_game", SLOT)), "(e) setup: Game.load_game()")
	progression = game.get("progression")
	_check(bool(progression.call("has", "legendary_freed")) and bool(progression.call("has", "realm_key_cloudreach")),
		"(e) setup: legendary_freed and realm_key_cloudreach came back from disk")
	var world_b := _stand_in("GateOnceLoaded")
	var loaded: Node3D = RIFT_CROSSING.new()
	loaded.name = "RiftCrossing"
	world_b.add_child(loaded)
	loaded.call("build", world_b)
	# Synchronously inside build(): no frame, no wait, no animation.
	var loaded_anchor := loaded.find_child("DeckAnchor", false, false) as Node3D
	_check(bool(loaded.call("span_ready")) and int(loaded.call("openings")) == 1
			and _decks(loaded) == 1 and _triggers(loaded) == 1
			and not bool(loaded.get("_waiting_for_collapse")) and not bool(loaded.get("_appearing"))
			and loaded_anchor != null and loaded_anchor.scale == Vector3.ONE and _deck_collision_live(loaded)
			and not loaded.is_processing(),
		"(e) later load with legendary_freed: open at build, one deck, one trigger, full scale, no collapse wait/appear")
	_step(loaded, wait_s + appear_s + 1.0)
	progression.call("set_flag", "legendary_settled")
	_step(loaded, wait_s + appear_s + 1.0)
	_check(int(loaded.call("openings")) == 1 and _decks(loaded) == 1 and _triggers(loaded) == 1
			and loaded_anchor != null and loaded_anchor.scale == Vector3.ONE and not bool(loaded.get("_appearing")),
		"(e) stepping the loaded crossing past collapse+appear: nothing replayed or rebuilt")

	print("  [t] loaded phase (e) done at %d ms" % (Time.get_ticks_msec() - started_ms))
	# ---------------------------------------------------------------- (d) ---
	_check(not bool(progression.call("has", "realm_gate_cloudreach_unlocked")), "(d) setup: realm gate not yet crossed")
	var trigger := loaded.find_child("RiftCrossingTrigger", false, false) as Area3D
	var walker := CharacterBody3D.new()
	walker.name = "Player"
	var body_collision := CollisionShape3D.new()
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.4
	body_shape.height = 1.8
	body_collision.shape = body_shape
	walker.add_child(body_collision)
	world_b.add_child(walker)
	if trigger != null:
		walker.global_position = trigger.global_position
	var realm_start := str(game.get("current_realm"))
	_check(realm_start == "meadows", "(d) setup: starting realm is meadows (%s)" % realm_start)
	var realm_changes := 0
	var last_realm := realm_start
	var fired_seen := 0
	var late_emits := 0
	if trigger != null:
		trigger.body_entered.emit(walker)
		var revision_after_first := int(progression.get("revision"))
		_check(bool(progression.call("has", "realm_gate_cloudreach_unlocked")),
			"(d) first entry writes realm_gate_cloudreach_unlocked")
		trigger.body_entered.emit(walker)
		fired_seen = int(loaded.call("crossings_fired"))
		_check(fired_seen == 1, "(d) two entries in the same frame: enter_realm called once (crossings_fired=%d)" % fired_seen)
		_check(int(progression.get("revision")) == revision_after_first,
			"(d) the same-frame duplicate entry writes nothing (revision %d -> %d)"
				% [revision_after_first, int(progression.get("revision"))])
		# Keep entering on every later frame for as long as the source world
		# (and the crossing with it) survives the scene swap.
		for _frame in 600:
			await process_frame
			var now := str(game.get("current_realm"))
			if now != last_realm:
				realm_changes += 1
				last_realm = now
				print("  [t] frame %d realm -> %s at %d ms" % [_frame, now, Time.get_ticks_msec() - started_ms])
			if is_instance_valid(loaded) and is_instance_valid(trigger) and is_instance_valid(walker):
				trigger.body_entered.emit(walker)
				late_emits += 1
				fired_seen = int(loaded.call("crossings_fired"))
			if current_scene != null and current_scene.name == "CloudreachCliffs" and not is_instance_valid(loaded):
				break
	_check(late_emits >= 1, "(d) at least one further entry on a later frame before the swap (%d)" % late_emits)
	_check(fired_seen == 1, "(d) after %d later-frame entries: enter_realm still called once (crossings_fired=%d)" % [late_emits, fired_seen])
	print("  [t] trigger entries done at %d ms (the Cloudreach scene load blocks here)" % (Time.get_ticks_msec() - started_ms))
	var cloudreach := await _wait_for_scene("CloudreachCliffs", 600)
	_check(cloudreach != null, "(d) the one crossing reached the Cloudreach scene")
	for _frame in 60:
		await process_frame
		var now := str(game.get("current_realm"))
		if now != last_realm:
			realm_changes += 1
			last_realm = now
	_check(realm_changes == 1 and str(game.get("current_realm")) == "cloudreach",
		"(d) realm changed exactly once, meadows -> cloudreach, and stayed (changes=%d now=%s)"
			% [realm_changes, str(game.get("current_realm"))])
	_check(bool(game.get("progression").call("has", "realm_gate_cloudreach_unlocked")),
		"(d) realm_gate_cloudreach_unlocked still set in Cloudreach")

	_cleanup_test_saves()
	for line: String in passes:
		print("  PASS: %s" % line)
	for line: String in failures:
		print("  FAIL: %s" % line)
	print("rift gate opens once: %d pass, %d fail, %d ms" % [passes.size(), failures.size(), Time.get_ticks_msec() - started_ms])
	if failures.is_empty():
		print("RIFT GATE OPENS ONCE OK")
		quit(0)
		return
	print("RIFT GATE OPENS ONCE FAILED")
	quit(1)


func _stand_in(scene_name: String) -> FlatWorld:
	var world := FlatWorld.new()
	world.name = scene_name
	root.add_child(world)
	current_scene = world
	return world


## Drive the crossing's own `_process` with a fixed delta for `seconds`.
func _step(crossing: Node, seconds: float) -> void:
	var ticks := int(ceil(seconds / STEP))
	for _i in ticks:
		crossing.call("_process", STEP)


func _decks(crossing: Node) -> int:
	return crossing.find_children("*CrossingDeckBody*", "StaticBody3D", true, false).size()


func _triggers(crossing: Node) -> int:
	return crossing.find_children("*", "Area3D", true, false).size()


func _deck_collision_live(crossing: Node) -> bool:
	var bodies := crossing.find_children("*CrossingDeckBody*", "StaticBody3D", true, false)
	if bodies.size() != 1:
		return false
	for child in (bodies[0] as Node).get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).disabled:
			return false
	return true


func _wait_for_scene(expected_name: String, frames: int) -> Node:
	for _frame in frames:
		var scene := current_scene
		if scene != null and scene.name == expected_name:
			return scene
		await process_frame
	return null


func _check(condition: bool, message: String) -> void:
	if condition:
		passes.append(message)
	else:
		failures.append(message)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _cleanup_test_saves() -> void:
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute)
