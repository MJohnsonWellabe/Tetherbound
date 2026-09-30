extends "res://tests/smoke_title_new_game.gd"

## F16#0/#4. Uses the existing physical-pad title witness, including body
## selection and the disclosed trainer-name _confirm harness call. Adds the
## old-save refusal, protected namespace, actual opening and schema assertions.
const SAVE := preload("res://scripts/save/save_game.gd")
const SCRATCH := "user://foundations_title/"
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
var _old_bytes: PackedByteArray
var _old_path: String
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
	if not bool(game.call("autosave_here")):
		_fail("fresh game production autosave refused")
	if FileAccess.get_file_as_bytes(_old_path) != _old_bytes:
		_fail("New Game/autosave overwrote the old canonical save")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_system.slot_path(0)))
	if int(disk.get("version", 0)) != 28: _fail("new namespace autosave is not v28")
	print("F16 title evidence: old canonical preserved; refusal UI displayed; physical New Game reached Grandpa opening; empty satchel; production autosave v28")
	FIXTURE.wipe(SCRATCH)
	quit(0 if _failures.is_empty() else 1)
