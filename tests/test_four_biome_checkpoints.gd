extends "res://tests/test_case.gd"

## Pure checks of the four-biome checkpoint boundaries used by
## tests/smoke_four_biome_continuous.gd (no world is loaded).
const CP := preload("res://tests/helpers/four_biome_checkpoints.gd")
const IDS := ["creature-a", "creature-b", "creature-c", "creature-d", "creature-e"]

var _tmp := ""


func before_each() -> void:
	_tmp = "user://test_four_biome_checkpoints_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]


func after_each() -> void:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_tmp)):
		CP.remove_tree(_tmp)


func _party() -> Array:
	var out: Array = []
	for id: String in IDS:
		out.append({"uid": id, "species": "bramblebun", "level": 20, "nickname": ""})
	return out


func _receipt(boundary: String) -> Dictionary:
	return CP.build_receipt(boundary, {"commit": "abc", "world_seed": 1393508821, "elapsed_seconds": 12.5,
		"cumulative_elapsed_seconds": 99.0, "realm": "cloudreach", "party": _party(),
		"flags": ["warden_defeated", "tournament_won", "south_bridge_open"]})


func _fake_save(dir: String) -> void:
	for path: String in ["slot_1.json", "slot_0.json", "worlds/slot-1/world.json",
			"characters/character-x/character.json"]:
		var full := ProjectSettings.globalize_path(dir.path_join(path))
		DirAccess.make_dir_recursive_absolute(full.get_base_dir())
		var f := FileAccess.open(full, FileAccess.WRITE)
		f.store_string("{\"path\": \"%s\"}" % path)
		f.close()


func test_parse_args_reads_all_three_flags() -> void:
	var a := CP.parse_args(PackedStringArray(["--resume-from=/tmp/cp/c1_arrival:c1_arrival",
		"--stop-at=water_arrived", "--checkpoint-dir=/tmp/out"]))
	assert_eq(a["errors"], [])
	assert_eq(a["resume_source"], "/tmp/cp/c1_arrival")
	assert_eq(a["resume_boundary"], "c1_arrival")
	assert_eq(a["stop_at"], "water_arrived")
	assert_eq(a["checkpoint_dir"], "/tmp/out")
	assert_true(bool(a["requested"]))


func test_parse_args_default_is_unrequested() -> void:
	var a := CP.parse_args(PackedStringArray(["--through-meadows", "--reload-at-transitions"]))
	assert_eq(a["errors"], [])
	assert_false(bool(a["requested"]), "no checkpoint arg means default behaviour")
	assert_eq(a["resume_source"], "")


func test_parse_args_name_without_boundary_and_uri_source() -> void:
	var a := CP.parse_args(PackedStringArray(["--resume-from=seed4_hall"]))
	assert_eq(a["resume_source"], "seed4_hall")
	assert_eq(a["resume_boundary"], "")
	var b := CP.parse_args(PackedStringArray(["--resume-from=user://cps/stormwood_arrived:stormwood_arrived"]))
	assert_eq(b["resume_source"], "user://cps/stormwood_arrived")
	assert_eq(b["resume_boundary"], "stormwood_arrived")
	var c := CP.parse_args(PackedStringArray(["--resume-from=user://cps/x"]))
	assert_eq(c["resume_source"], "user://cps/x")
	assert_eq(c["errors"], [])


func test_parse_args_refuses_bad_values() -> void:
	assert_false((CP.parse_args(PackedStringArray(["--stop-at=moon"]))["errors"] as Array).is_empty())
	assert_false((CP.parse_args(PackedStringArray(["--resume-from=x:moon"]))["errors"] as Array).is_empty())
	assert_false((CP.parse_args(PackedStringArray(["--resume-from=x:water_arrived",
		"--stop-at=c1_arrival"]))["errors"] as Array).is_empty(), "stop before resume refused")
	assert_false((CP.parse_args(PackedStringArray(["--checkpoint-dir="]))["errors"] as Array).is_empty())
	assert_false((CP.parse_args(PackedStringArray(["--no-checkpoints", "--stop-at=hall"]))["errors"] as Array).is_empty())


func test_boundary_order_and_next_segment() -> void:
	assert_eq(CP.boundary_names(), ["hall", "c1_arrival", "stormwood_arrived", "water_arrived"])
	assert_eq(CP.next_segment("hall"), "warden")
	assert_eq(CP.next_segment("c1_arrival"), "cloudreach")
	assert_eq(CP.next_segment("stormwood_arrived"), "stormwood")
	assert_eq(CP.next_segment("water_arrived"), "water_opening")
	assert_eq(CP.reached_label("c1_arrival"), "cloudreach_arrived")
	assert_eq(CP.reached_label("hall"), "warden_arena_entered")
	assert_eq(CP.next_segment("moon"), "")
	for i in range(1, CP.BOUNDARIES.size()):
		assert_true(CP.boundary_index(CP.BOUNDARIES[i]["name"]) > CP.boundary_index(CP.BOUNDARIES[i - 1]["name"]))


func test_receipt_round_trip_and_validation() -> void:
	var r := _receipt("c1_arrival")
	assert_eq(r["boundary"], "c1_arrival")
	assert_false(bool(r["fixtures_used_in_run_path"]))
	assert_true(str(r["no_fixture_statement"]).contains("no fixture"))
	var path := CP.receipt_path(_tmp, "c1_arrival")
	assert_true(CP.write_json(path, r))
	var back := CP.read_receipt(path)
	assert_eq(back["party"].size(), 5)
	assert_eq(CP.receipt_party_ids(back), IDS)
	assert_eq(int(back["world_seed"]), 1393508821)
	assert_eq(CP.validate(back, "c1_arrival", IDS.duplicate(), ["south_bridge_open", "tournament_won", "warden_defeated", "extra"]), [])
	var shuffled := IDS.duplicate()
	shuffled.reverse()
	assert_eq(CP.validate(back, "c1_arrival", shuffled, back["flags"]), [], "party order does not matter")


func test_validation_refuses_mismatches() -> void:
	var r := _receipt("c1_arrival")
	var wrong := IDS.duplicate()
	wrong[4] = "creature-z"
	assert_false(CP.validate(r, "c1_arrival", wrong, r["flags"]).is_empty(), "swapped member refused")
	assert_false(CP.validate(r, "c1_arrival", IDS.slice(0, 4), r["flags"]).is_empty(), "missing member refused")
	assert_false(CP.validate(r, "c1_arrival", IDS, ["tournament_won"]).is_empty(), "missing flags refused")
	assert_false(CP.validate(r, "water_arrived", IDS, r["flags"]).is_empty(), "wrong boundary refused")
	assert_false(CP.validate({}, "c1_arrival", IDS, []).is_empty(), "missing receipt refused")
	var failed := r.duplicate()
	failed["passed"] = false
	assert_false(CP.validate(failed, "c1_arrival", IDS, r["flags"]).is_empty(), "failed producing run refused")


func test_export_layout_matches_earned_saves() -> void:
	var save := _tmp.path_join("scratch")
	_fake_save(save)
	var carried := {"hall": _receipt("hall")}
	var out := CP.export_checkpoint(save, _tmp.path_join("cps"), "c1_arrival", "c1_arrival",
		_receipt("c1_arrival"), carried)
	assert_eq(out, _tmp.path_join("cps").path_join("c1_arrival"))
	assert_eq(CP.layout_problems(out, "c1_arrival"), [])
	assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(CP.receipt_path(out, "hall"))), "earlier receipts carried")
	assert_true(FileAccess.file_exists(ProjectSettings.globalize_path(out.path_join("save/worlds/slot-1/world.json"))))
	# Same top-level shape as the repo's earned checkpoint.
	var fixture := CP.FIXTURE_ROOT + "seed4_hall"
	var want := Array(DirAccess.get_directories_at(ProjectSettings.globalize_path(fixture)))
	var got := Array(DirAccess.get_directories_at(ProjectSettings.globalize_path(out)))
	want.sort()
	got.sort()
	assert_eq(got, want)
	for sub: String in ["characters", "worlds"]:
		assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(fixture.path_join("save").path_join(sub))))
	# The exported checkpoint resolves and picks its latest boundary.
	assert_eq(CP.resolve_source("c1_arrival", _tmp.path_join("cps")), out)
	assert_eq(CP.pick_boundary(out, ""), "c1_arrival")
	assert_eq(CP.pick_boundary(out, "hall"), "hall")
	assert_eq(CP.pick_boundary(out, "water_arrived"), "")
	assert_eq(CP.read_all_receipts(out).keys().size(), 2)


func test_existing_seed4_hall_checkpoint_is_resumable() -> void:
	var source := CP.resolve_source("seed4_hall", "")
	assert_eq(source, CP.FIXTURE_ROOT + "seed4_hall")
	assert_eq(CP.pick_boundary(source, ""), "hall", "chain-runner receipts map to the hall boundary")
	var receipt := CP.read_receipt(CP.receipt_path(source, "hall"))
	var ids := CP.receipt_party_ids(receipt)
	assert_eq(ids.size(), 5)
	assert_eq(CP.validate(receipt, "hall", ids, CP.receipt_flags(receipt)), [])
	assert_false(CP.validate(receipt, "hall", ids.slice(1), CP.receipt_flags(receipt)).is_empty())


func _write(path: String, text: String) -> void:
	var full := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	var f := FileAccess.open(full, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_resume_kind_is_detected_from_the_directory() -> void:
	# Meadows reload-transition checkpoint: checkpoint.json + save/.
	var reload := _tmp.path_join("four_biome_checkpoints/south_bridge_crossed_123")
	_fake_save(reload.path_join("save"))
	_write(reload.path_join(CP.RELOAD_CHECKPOINT_META), JSON.stringify({"label": "south_bridge_crossed",
		"scene": "res://scenes/world/meadows.tscn", "world_seed": "15"}))
	assert_eq(CP.classify_resume(reload, ""), {"kind": CP.RESUME_RELOAD_TRANSITION, "error": ""})
	assert_eq(CP.classify_resume(ProjectSettings.globalize_path(reload), ""),
		{"kind": CP.RESUME_RELOAD_TRANSITION, "error": ""}, "absolute path too")
	# Chapter-boundary checkpoint: receipts/ + save/, as a dir and as a name.
	var save := _tmp.path_join("scratch")
	_fake_save(save)
	var boundary := CP.export_checkpoint(save, _tmp.path_join("cps"), "hall", "hall", _receipt("hall"), {})
	assert_eq(CP.classify_resume(boundary, ""), {"kind": CP.RESUME_BOUNDARY, "error": ""})
	assert_eq(CP.classify_resume(boundary, "hall"), {"kind": CP.RESUME_BOUNDARY, "error": ""})
	assert_eq(CP.classify_resume("seed4_hall", "")["kind"], CP.RESUME_BOUNDARY, "bare fixture name")
	assert_eq(CP.classify_resume("no_such_checkpoint", "")["kind"], CP.RESUME_BOUNDARY,
		"unknown names fall to the boundary resolver, which refuses them")
	# parse_args + classify agree for the command-line forms.
	var args := CP.parse_args(PackedStringArray(["--resume-from=" + reload]))
	assert_eq(args["errors"], [])
	assert_eq(CP.classify_resume(args["resume_source"], args["resume_boundary"])["kind"], CP.RESUME_RELOAD_TRANSITION)
	args = CP.parse_args(PackedStringArray(["--resume-from=" + boundary + ":hall"]))
	assert_eq(CP.classify_resume(args["resume_source"], args["resume_boundary"])["kind"], CP.RESUME_BOUNDARY)
	# Both markers: only an explicit :<boundary> resolves it.
	_write(boundary.path_join(CP.RELOAD_CHECKPOINT_META), "{}")
	var both := CP.classify_resume(boundary, "")
	assert_eq(both["kind"], "")
	assert_false(str(both["error"]).is_empty(), "ambiguous dir refused")
	assert_eq(CP.classify_resume(boundary, "hall")["kind"], CP.RESUME_BOUNDARY)
	assert_false(str(CP.classify_resume("", "")["error"]).is_empty())


func test_commit_sha_prefers_env_then_git() -> void:
	var sha := CP.commit_sha()
	assert_false(sha.is_empty())
	assert_ne(sha, "unknown", "git or the .git HEAD file names the commit")
