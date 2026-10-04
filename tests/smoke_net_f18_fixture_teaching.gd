extends "res://tests/smoke_net_f18_travel.gd"

# peers: 2
# requires-flag: multiplayer.json session.redesign_portal_runtime_enabled
## Focused pre-admission fixture proof only. No travel/co-op/earned F18 credit.
## Reuse the actual F18 peer process, sequential world boot and save inspection.
func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call", "ERROR:"],
		"F18 fixture teaching peer logs have no engine/script errors")
	if not await launch(2, "title", [], {1: ["--joiner"]}):
		quit(await finish())
		return
	for peer in 2:
		if not await _f18_pass(peer, "f18_boot_world", {}, 12000): return
		var fixture: Dictionary = await _f18_action(peer, "f18_fixture", {"guest": peer == 1}, 3000)
		if fixture.is_empty(): return
		var teaching: Dictionary = fixture.get("fixture_teaching", {})
		var presses: Array = teaching.get("menu_confirm_presses", [])
		check(not presses.is_empty(), "peer %d continued the actual Home Key teaching lines" % peer)
		check(teaching.get("earned_opening_credit") == false and teaching.get("budget_frames") == 180,
			"peer %d discloses bounded pre-admission teaching fixture" % peer)
		check(teaching.get("character_id") == fixture.get("character_id"),
			"peer %d teaching stays bound to its saved character" % peer)
		var observed: Dictionary = await _f18_observe(peer)
		check(observed.get("character_disk", {}).get("flags", {}).get("flags", []).has("opening:lesson:home_key"),
			"peer %d ordinary lesson acknowledgement is on portable disk" % peer)
		check(observed.get("home_key_count") == 1, "peer %d retains its own fixture Home Key" % peer)
	var file := FileAccess.open(_run_dir.path_join("F18_WITNESSES.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(_f18_witnesses, "\t"))
	print("F18_FIXTURE_TEACHING_ONLY: actual Continue input before admission; no earned opening or travel acceptance.")
	quit(await finish())
