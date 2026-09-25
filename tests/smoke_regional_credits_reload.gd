extends SceneTree

## F15 / T3: "Credits occur once and reload resumes a safe completed world with
## local requests, without a fifth key or invented sequel prompt."
##
##   godot --headless --path . --script tests/smoke_regional_credits_reload.gd
##
## `test_homecoming_ending_invariants.gd` proves the transaction over in-memory
## stores with a stub saver. What only a real boot can show is the DISK round
## trip: the real `Game` autoload, the real `save_game.gd` split writer (into a
## scratch directory, never the player's saves), the real credits CanvasLayer,
## then a New Game reset that empties memory and a `load_game` that must bring
## the completed ending back from the files alone.
##
## Driven the way `sequence_director.gd` drives it: the initial homecoming
## conversation runs to `completed` with the live substitutions, then
## `regional_homecoming.gd::complete`, then the production credits roll opens
## and its Continue emits `acknowledged`, which calls `complete_credits`. No
## world scene is booted: Grandpa's prompt and the director's choice of
## conversation are the same `conversation_id()` read this file makes, and the
## scene-level interaction witness is REGIONAL-HOMECOMING's report, not this.

const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const CREDITS := preload("res://scripts/ui/regional_credits.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://smoke_regional_credits_reload/"
const SLOT := 2
const GUARD_TIMEOUT_MSEC := 5000

var _failures: Array[String] = []
var _checks := 0
var _game: Node = null


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, why: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(why)
		print("FAIL: ", why)


func _run() -> void:
	await process_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_check(false, "Game autoload is missing")
		_finish()
		return
	SPLIT_FIXTURE.wipe(TEST_DIR)
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))
	_game.set("current_realm", "meadows")
	# Mint the portable character id through the real save path, exactly as
	# smoke_local_requests.gd does for its title-screen bypass.
	_check(bool(_game.call("save_game", SLOT)), "fresh character identity saves")
	var character_id := HOMECOMING.character_id(_game)
	_check(not character_id.is_empty(), "portable character id was minted")

	# Explicit completed-Tidewake fixture: the world's currents are restored and
	# it still holds the Water key Stormwood granted. One Local Request is
	# revealed so "local requests remain" is a visible row, not an empty list.
	var world_flags: RefCounted = _game.get("world").flags
	for flag: String in ["water_captain_nerissa_defeated", "water_currents_restored",
			"realm_key_water", "realm_gate_water_unlocked"]:
		world_flags.set_flag(flag)
	_game.get("progression").set_flag("old_champion_met")
	var local: RefCounted = _game.get("local")
	var party: RefCounted = local.party
	for row: Array in [["terrapup", "Pip"], ["brooktail", "Rill"], ["mosshell", "Shelby"]]:
		var creature: RefCounted = local.make_creature(str(row[0]), str(row[1]))
		creature.level = 40
		creature.xp = 123
		_check(bool(party.add(creature)), "fixture creature joins: " + str(row[1]))
	# Rill is released before the homecoming; nothing may bring it back.
	party.remove_at(1)

	var keys_before := _realm_keys()
	var party_before := _party_fingerprint()
	var local_rows_before: Array = _log().local_entries(_game.get("progression"))
	_check(not local_rows_before.is_empty(), "fixture reveals at least one Local Request")

	# ---- the first, real ending --------------------------------------------
	var initial := HOMECOMING.conversation_id(_game)
	_check(initial == "regional_homecoming_2", "initial homecoming counts the current two")
	var spoken := _talk(initial, HOMECOMING.substitutions(_game))
	_check(not "\n".join(spoken).contains("Rill"), "released Rill is not acknowledged")
	_check(HOMECOMING.complete(_game, character_id), "homecoming saves for this character")
	_check(HOMECOMING.credits_pending(_game), "credits are pending after the saved homecoming")

	var credits: CanvasLayer = CREDITS.new()
	root.add_child(credits)
	await process_frame
	var acknowledgements: Array[String] = []
	credits.acknowledged.connect(func(id: String) -> void:
		acknowledgements.append(id)
		HOMECOMING.complete_credits(_game, id))
	_check(bool(credits.open_for(character_id, _game.get("world"))), "production credits roll opens")
	await _past_input_guard(credits)
	credits.call("_on_continue_pressed")
	await process_frame
	_check(acknowledgements == [character_id], "Continue acknowledges the roll exactly once")
	_check(not bool(credits.call("is_open")), "credits close on Continue")
	_check(local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG), "credits receipt is on the character")
	_check(not HOMECOMING.credits_pending(_game), "credits no longer pending")

	_check(bool(_game.call("save_game", SLOT)), "completed ending saves to the slot")

	# ---- empty memory, then reload from the files alone ---------------------
	_game.call("reset_for_new_game")
	_check(not _game.get("local").flags.has(HOMECOMING.SEEN_FLAG), "reset really emptied memory")
	_check(bool(_game.call("load_game", SLOT)), "load_game reads the completed ending back")
	await process_frame
	local = _game.get("local")

	_check(HOMECOMING.character_id(_game) == character_id, "same portable character reloaded")
	_check(local.flags.has(HOMECOMING.SEEN_FLAG), "homecoming receipt survived reload")
	_check(local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG), "credits receipt survived reload")
	_check(_game.get("world").flags.has(HOMECOMING.WORLD_FLAG), "restored currents survived reload")
	_check(not HOMECOMING.credits_pending(_game), "credits do not replay after reload")
	_check(HOMECOMING.conversation_id(_game) == HOMECOMING.REPEAT_ID,
		"Grandpa offers only the repeat greeting after reload")
	_check(_realm_keys() == keys_before, "no realm key added or removed across the ending and reload")
	_check(_party_fingerprint() == party_before, "party ids/species/names/levels/XP unchanged, released Rill absent")

	# The director opens credits after the repeat greeting only while pending.
	var repeat_completed := _talk_completed(HOMECOMING.REPEAT_ID, {})
	_check(repeat_completed == [HOMECOMING.REPEAT_ID], "repeat greeting completes normally")
	_check(not HOMECOMING.credits_pending(_game), "repeat greeting does not re-arm credits")
	# Defence in depth: even a stray open cannot acknowledge a finished ending;
	# the roll's own context check closes it on its next frame.
	var acks_before := acknowledgements.size()
	credits.open_for(character_id, _game.get("world"))
	await process_frame
	await process_frame
	_check(not bool(credits.call("is_open")), "a stray credits open self-closes when nothing is pending")
	_check(acknowledgements.size() == acks_before, "a stray credits open acknowledges nothing")

	var reader := _log()
	var progression: RefCounted = _game.get("progression")
	_check(reader.tracked_id(progression) == "", "completed ending leaves no active ending objective")
	_check(reader.local_entries(progression) == local_rows_before, "Local Requests feed is intact after reload")
	# With no tracked ending objective the tracked text is empty, so also scan
	# the resumed Local Requests rows the player actually sees.
	var shown: Array[String] = [reader.tracked_text(progression), reader.tracked_hint(progression)]
	for row: Variant in reader.local_entries(progression):
		shown.append(JSON.stringify(row))
	_check(reader.local_entries(progression).size() > 0, "Local Requests are offered after the ending")
	for text: String in shown:
		_check(not text.to_lower().contains("chapter") and not text.to_lower().contains("sequel"),
			"no chapter or sequel prompt in the resumed objectives: " + text)

	credits.queue_free()
	_finish()


func _finish() -> void:
	SPLIT_FIXTURE.wipe(TEST_DIR)
	print("Regional credits reload smoke: ", _checks, " checks, ", _failures.size(), " failures")
	quit(0 if _failures.is_empty() and _checks > 0 else 1)


## Waits out the credits' authored input guard (regional_credits.json
## motion.input_guard_seconds), read from config rather than restated here.
func _past_input_guard(credits: CanvasLayer) -> void:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/regional_credits.json"))
	var guard := float((config as Dictionary).get("motion", {}).get("input_guard_seconds", 0.0)) if config is Dictionary else 0.0
	_check(guard > 0.0, "credits declare an input guard")
	var deadline := Time.get_ticks_msec() + GUARD_TIMEOUT_MSEC
	while float(credits.get("_elapsed")) < guard and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(float(credits.get("_elapsed")) >= guard, "credits input guard elapsed")


func _talk(id: String, values: Dictionary) -> Array[String]:
	var spoken: Array[String] = []
	var runner := RUNNER.new()
	runner.set_values(values)
	_check(runner.start(id), "conversation starts: " + id)
	var guard := 0
	while runner.is_active() and guard < 64:
		spoken.append(str(runner.line().get("text", "")))
		runner.advance()
		guard += 1
	return spoken


func _talk_completed(id: String, values: Dictionary) -> Array[String]:
	var completed: Array[String] = []
	var runner := RUNNER.new()
	runner.completed.connect(func(done: String) -> void: completed.append(done))
	runner.set_values(values)
	_check(runner.start(id), "conversation starts: " + id)
	var guard := 0
	while runner.is_active() and guard < 64:
		runner.advance()
		guard += 1
	return completed


func _log() -> RefCounted:
	var reader: RefCounted = QUEST_LOG.new()
	reader.set_realm("meadows")
	return reader


func _realm_keys() -> Array[String]:
	var out: Array[String] = []
	for store: RefCounted in [_game.get("world").flags, _game.get("local").flags]:
		for id: Variant in store.save_data().get("flags", []):
			if str(id).begins_with("realm_key_"):
				out.append(str(id))
	out.sort()
	return out


func _party_fingerprint() -> String:
	var rows: Array = []
	for creature: RefCounted in _game.get("local").party.members():
		rows.append([str(creature.get("uid")), str(creature.get("species_id")),
			str(creature.get("nickname")), int(creature.get("level")), int(creature.get("xp"))])
	return JSON.stringify(rows)
