extends "res://tests/smoke_title_new_game.gd"

## F16#0/#4. Uses the existing physical-pad title witness, including body
## selection and the disclosed trainer-name _confirm harness call. Adds the
## old-save refusal, protected namespace, actual opening and schema assertions.
const SAVE := preload("res://scripts/save/save_game.gd")
const SCRATCH := "user://foundations_title/"
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const DIALOGUE_RUNNER := preload("res://scripts/story/dialogue_runner.gd")
var _old_bytes: PackedByteArray
var _old_path: String
var _old_character_path: String
var _old_character_bytes: PackedByteArray
var _check_refusal := true

func _run() -> void:
	FIXTURE.wipe(SCRATCH)
	var game := root.get_node(^"Game")
	game.save_system = SAVE.new(SCRATCH + "redesign-v28/", SCRATCH + "old/")
	_old_path = SCRATCH + "old/slot_0.json"
	DirAccess.make_dir_recursive_absolute(_old_path.get_base_dir())
	_old_bytes = FileAccess.get_file_as_bytes("res://data/schema/fixtures/v27_save.json")
	var file := FileAccess.open(_old_path, FileAccess.WRITE)
	file.store_buffer(_old_bytes)
	file.close()
	_old_character_path = SCRATCH + "old/characters/legacy-portable/character.json"
	DirAccess.make_dir_recursive_absolute(_old_character_path.get_base_dir())
	_old_character_bytes = JSON.stringify({"version": 6, "character_id": "legacy-portable", "party": []}).to_utf8_buffer()
	file = FileAccess.open(_old_character_path, FileAccess.WRITE)
	file.store_buffer(_old_character_bytes)
	file.close()
	await super._run()

func _pad(button_index: int) -> void:
	if _check_refusal:
		_check_refusal = false
		var game := root.get_node(^"Game")
		var before: Dictionary = game.save_system.snapshot(game)
		current_scene.call("_show_load_slots")
		current_scene.call("_load_slot", 0)
		var status := current_scene.get("_status") as Label
		if status == null or not status.text.contains("older version") or not status.text.contains("new game"):
			_fail("old-save refusal did not show the clear New Game message on the real title")
		if game.save_system.snapshot(game) != before:
			_fail("title refusal mutated live game")
		if FileAccess.get_file_as_bytes(_old_path) != _old_bytes:
			_fail("title refusal overwrote the old save")
		if not current_scene.call("_saved_portable_character_ids", game).has("legacy-portable"):
			_fail("read-only legacy portable character discovery omitted the old character")
		status.text = ""
		current_scene.call("_show_portable_character_select")
		if not status.text.contains("older version"):
			_fail("portable picker silently omitted an old character without the refusal message")
		var before_steam: Dictionary = game.save_system.snapshot(game)
		var ready: bool = current_scene.call("prepare_steam_character", game, {"kind": "existing", "character_id": "legacy-portable"})
		if ready or game.save_system.snapshot(game) != before_steam:
			_fail("Steam old-character refusal reset or mutated live state")
		current_scene.call("_show_main")
	await super._pad(button_index)

func _finish() -> void:
	_verify_opening.call_deferred()

func _verify_opening() -> void:
	var game := root.get_node(^"Game")
	for i in 30: await process_frame
	var sequence := current_scene.find_child("SequenceDirector", true, false) if current_scene != null else null
	if sequence == null or sequence.get("_grandpa_prompt") == null or sequence.get("_bed_prompt") == null:
		_fail("title New Game did not reach the actual Grandpa opening director and prompts")
	if game.inventory.used_slots() != 0:
		_fail("new satchel contains unauthored items before Grandpa gifts")
	if SAVE.VERSION <= 27 or game.save_system.snapshot(game).version <= 27:
		_fail("new game uses an old save schema")
	if sequence != null:
		await _exercise_grandpa_opening(sequence, game)
	if not bool(game.call("autosave_here")):
		_fail("fresh game production autosave refused")
	if FileAccess.get_file_as_bytes(_old_path) != _old_bytes:
		_fail("New Game/autosave overwrote the old canonical save")
	if FileAccess.get_file_as_bytes(_old_character_path) != _old_character_bytes:
		_fail("New Game/autosave overwrote the old portable character")
	var disk: Dictionary = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(game.save_system.slot_path(0)))
	if int(disk.get("version", 0)) != 28: _fail("new namespace autosave is not v28")
	if _failures.is_empty():
		print("F16#0/#4 title evidence: old merged and portable files preserved; refusal UI displayed; physical New Game, bed wake and complete Grandpa opening dialogue; authored-gifts-only satchel; production autosave v28. Shortcuts: isolated saves, authored v27 fixture, direct refusal/picker/Steam and trainer-name callbacks, teleport from loft to Grandpa, injected physical joypad taps.")
	FIXTURE.wipe(SCRATCH)
	quit(0 if _failures.is_empty() else 1)


func _exercise_grandpa_opening(sequence: Node, game: Node) -> void:
	var player := sequence.get("_player") as CharacterBody3D
	var arbiter := sequence.get("_arbiter") as Node
	var dialogue := sequence.get("_dialogue") as CanvasLayer
	var bed := sequence.get("_bed_prompt") as Node3D
	var grandpa := sequence.get("_grandpa_prompt") as Node3D
	if player == null or arbiter == null or dialogue == null or bed == null or grandpa == null:
		_fail("opening lacks the production player, prompts, arbiter or dialogue panel")
		return
	# Wait for the real initial fade and bed offer. No beat or flag writes.
	for i in 180:
		if sequence.call("beat") == "wake" and arbiter.call("winning_provider") == bed:
			break
		await physics_frame
	if sequence.call("beat") != "wake" or arbiter.call("winning_provider") != bed:
		_fail("fresh opening did not offer the actual bed wake interaction")
		return
	await _opening_pad(&"interact")
	if sequence.call("beat") != "house":
		_fail("physical bed interaction did not advance to Grandpa's house beat")
		return
	# Disclosed travel shortcut; interaction and dialogue still use real input.
	player.global_position = grandpa.global_position + Vector3(0.7, 0.0, 0.7)
	player.velocity = Vector3.ZERO
	for i in 60:
		if bool(dialogue.call("is_open")) or arbiter.call("winning_provider") == grandpa:
			break
		await physics_frame
	if not bool(dialogue.call("is_open")):
		if arbiter.call("winning_provider") != grandpa:
			_fail("Grandpa's actual prompt was not reachable at the disclosed position")
			return
		await _opening_pad(&"interact")
	var runner: RefCounted = dialogue.call("runner")
	if not bool(dialogue.call("is_open")) or runner.call("conversation_id") != "grandpa_house":
		_fail("actual Grandpa interaction did not open the authored house conversation")
		return
	var authored: Dictionary = DIALOGUE_RUNNER.table()["grandpa_house"]
	var expected_lines: Array[String] = []
	var gifts: Dictionary = {}
	for raw: Variant in authored.get("lines", []):
		var row: Dictionary = raw if raw is Dictionary else {"text": str(raw)}
		expected_lines.append(str(row.get("text", "")))
		var effects: Array = row.get("effects", []).duplicate()
		effects.append(str(row.get("effect", "")))
		for effect: Variant in effects:
			var parts := str(effect).split(":")
			if parts.size() == 3 and parts[0] == "give":
				gifts[parts[1]] = int(gifts.get(parts[1], 0)) + int(parts[2])
	var seen: Array[String] = []
	for i in 40:
		if not bool(dialogue.call("is_open")):
			break
		var text := str((runner.call("line") as Dictionary).get("text", ""))
		if seen.is_empty() or seen.back() != text:
			seen.append(text)
		_check_authored_satchel(game, gifts, false)
		await _opening_pad(&"interact")
	if bool(dialogue.call("is_open")) or seen != expected_lines:
		_fail("physical dialogue taps did not expose and complete every authored Grandpa line: %s" % str(seen))
	for i in 20: await process_frame
	var picker := sequence.get("_starter_picker") as CanvasLayer
	if sequence.call("beat") != "choose" or picker == null or not bool(picker.call("is_open")):
		_fail("completing Grandpa's actual dialogue did not reach the production starter choice")
	_check_authored_satchel(game, gifts, true)
	print("Grandpa opening observations: saw %d authored lines; allowed gifts %s; observed beat %s. Loft-to-Grandpa position write disclosed." % [seen.size(), str(gifts), str(sequence.call("beat"))])


func _check_authored_satchel(game: Node, gifts: Dictionary, complete: bool) -> void:
	for index in game.inventory.slot_count():
		var stack: Dictionary = game.inventory.stack_at(index)
		if stack.is_empty(): continue
		var id := str(stack.get("id", ""))
		if not gifts.has(id) or game.inventory.count(id) > int(gifts.get(id, 0)):
			_fail("Grandpa opening satchel contains an unauthored item or excess gift: %s" % id)
	if complete:
		for id: String in gifts:
			if game.inventory.count(id) != int(gifts[id]):
				_fail("Grandpa opening did not grant exactly its authored gift: %s" % id)


func _opening_pad(action: StringName) -> void:
	var button := _pad_button_for(action)
	if button < 0:
		_fail("opening action has no physical joypad binding: %s" % action)
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	for i in 3: await physics_frame
	event = event.duplicate() as InputEventJoypadButton
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	for i in 4: await physics_frame
