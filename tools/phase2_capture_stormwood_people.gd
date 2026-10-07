extends "res://tools/phase2_capture_dialogue.gd"

## P2-082 portrait and P2-084 opening comparison at the existing world posts.
## 24 rows produce 48 images: eleven arrivals, eight state panels and five
## synthetic side panels. Direct panel starts do not prove earned progression.
const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")
const PEOPLE_IDS := ["rodkeeper_hesk","stormreader_tamsin","warden_elect_bryn",
	"trader_oswin","keeper_ondra","archivist_wen","elder_maud","trader_fenn",
	"caretaker_lio","ace_trainer_rook","crown_caretaker_neri"]
const OPENING_IDS := ["warden_elect_bryn","trader_oswin","elder_maud","trader_fenn"]
var _f41_people_graphics: Dictionary = {}


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_f41_people_graphics = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self)
			if _f41_people_graphics.is_empty():
				quit(2)
				return
			break
	await super._run()


func _load_plan() -> bool:
	if _biome_id != "stormwood" or not _subsets.is_empty():
		_failures.append("Stormwood people matrix requires --biome=stormwood and no --subset")
		return false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--start=") or arg.begins_with("--count="):
			_failures.append("Stormwood people matrix requires all 24 rows")
			return false
	if not super._load_plan():
		return false
	var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))
	var names := {}
	for actor: Dictionary in registry.characters:
		names[str(actor.id)] = str(actor.name)
	var selected: Array[Dictionary] = []
	var found := {}
	for row: Dictionary in _planned:
		var id := str(row.authored_id)
		if str(row.family_type) != "character" or id not in PEOPLE_IDS:
			continue
		found[id] = true
		row["expected_speaker"] = names[id]
		selected.append(_panel_row(row,"","stormwood_%s_arrival"%id))
		if id in OPENING_IDS:
			for state: String in ["in_progress","post_storm"]:
				selected.append(_panel_row(row,state,"stormwood_%s_%s"%[id,state]))
		if id == "archivist_wen":
			selected.append(_panel_row(row,"guardian_refusal",CHAPTER.WEN_REFUSAL_CONVERSATION))
		if id == "warden_elect_bryn":
			for conversation: String in CHAPTER.GLASS_FOR_BRYN.conversations():
				selected.append(_panel_row(row,conversation,conversation))
	if found.size() != PEOPLE_IDS.size() or selected.size() != 24:
		_failures.append("Stormwood people matrix expected eleven actors and 24 rows")
		return false
	_planned.assign(selected)
	return true


func _panel_row(source: Dictionary,suffix: String,conversation: String) -> Dictionary:
	var row := source.duplicate(true)
	if not suffix.is_empty():
		row.frame_id = str(row.frame_id)+"__"+suffix
		row.identity = row.frame_id
	row["dialogue_fixture_id"] = conversation
	return row


func _dialogue_for(row: Dictionary) -> String:
	var id := str(row.dialogue_fixture_id)
	return id if RUNNER.table().has(id) else ""


func _begin_manifest() -> void:
	super._begin_manifest()
	if not _f41_people_graphics.is_empty():
		_manifest["graphics_capture"] = _f41_people_graphics
	_manifest["dialogue_presentation_config"] = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_dialogue_presentation.json"))
	_manifest["fixture_disclosure"] = "Debug placement at authored NPC posts. Post images hide HUD; dialogue images show only the production dialogue panel. Direct starts include unearned side/state text. The fixture disables chapter arrival processing and disconnects its dialogue-finished progression callback; panel/camera callbacks remain active. Per-row progression snapshots verify no flag changes. Not ordinary interaction or progression proof."
	_manifest["expected_rows"] = 24
	_manifest["expected_frames"] = 48


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var path := _output_dir + "/manifest.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("Stormwood people manifest could not be opened")
		return
	var text := JSON.stringify(_manifest, "\t") + "\n"
	file.store_string(text)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written or FileAccess.get_file_as_string(path) != text:
		_failures.append("Stormwood people manifest flush/readback failed")


func _finish(_complete: bool) -> void:
	# Retain the original whole 24-row matrix and two views per actor/state.
	# A partial capture or unwritten final receipt cannot turn the run green.
	var complete := _failures.is_empty() and _planned.size() == 24 and _records.size() == 48
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["complete"] = complete
	_manifest["captured_frame_count"] = _records.size()
	_manifest["planned_frame_count"] = _planned.size()
	_write_manifest()
	complete = complete and _failures.is_empty()
	for failure: String in _failures:
		push_error("Stormwood people: " + failure)
	print("STORMWOOD PEOPLE %s: %d/48 frames, %d/24 rows" % ["OK" if complete else "FAILED", _records.size(), _planned.size()])
	quit(0 if complete else 1)


func _prepare_capture_shell() -> bool:
	if not super._prepare_capture_shell():
		return false
	var chapter := _world.get_node_or_null("StormwoodChapter")
	var panel := get_first_node_in_group("dialogue_panel")
	if chapter == null or panel == null:
		_failures.append("missing chapter or panel for presentation isolation")
		return false
	var callback := Callable(chapter,"_dialogue_finished")
	if not panel.is_connected("finished",callback):
		_failures.append("expected chapter dialogue-finished callback is absent")
		return false
	panel.disconnect("finished",callback)
	chapter.set_process(false)
	_manifest["chapter_presentation_isolation"] = {
		"arrival_process_disabled":not chapter.is_processing(),
		"dialogue_finished_progression_disconnected":not panel.is_connected("finished",callback),
		"flags_before_capture":_progress_flags()}
	return true


func _progress_flags() -> Array:
	var flags: Array = root.get_node("Game").get("progression").call("all_set")
	flags.sort()
	return flags


func _settle_dialogue_capture() -> bool:
	for frame in 7:
		await physics_frame
	for frame in 120:
		if not bool(_rig.call("is_in_conversation")) or float(_rig.call("conversation_blend"))>=0.9999:
			return true
		await physics_frame
	_failures.append("production dialogue camera did not finish its blend")
	return false


func _capture_row(row: Dictionary) -> void:
	var before := _records.size()
	var flags_before := _progress_flags()
	await super._capture_row(row)
	var flags_after := _progress_flags()
	if flags_before != flags_after:
		_failures.append("%s: progression flags changed during visual fixture"%row.frame_id)
	for index in range(before,_records.size()):
		_records[index]["progression_flags_before"] = flags_before
		_records[index]["progression_flags_after_close"] = flags_after
	if _records.size() != before+2:
		_write_manifest()
		return
	var record: Dictionary = _records[-1]
	if str(record.get("dialogue_speaker","")) != str(row.expected_speaker):
		_failures.append("%s: displayed speaker differs from registry"%row.frame_id)
	_write_manifest()
