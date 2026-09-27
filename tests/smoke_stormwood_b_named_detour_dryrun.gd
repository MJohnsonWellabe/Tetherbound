extends "res://tests/smoke_stormwood_continuous.gd"

## DRY RUN — does not count. A fast check of the F10#2 named-wild detours
## (`stormwood_b_named_detour_segment.gd`) without walking the whole chapter:
## the inherited chapter-entry seam (in-memory completed-Cloudreach party),
## then straight to the detours for `--ids=` (default hollows_alpha), with the
## passive named-fight recorder on the tree. Proves the detour mechanics
## (camp rest, road walk, one Engage press, ordinary fight) only; the counted
## evidence rides the earned route.
##
##   godot --headless --path . --script res://tests/smoke_stormwood_b_named_detour_dryrun.gd \
##     -- --ids=hollows_alpha --named-out=user://sw_b_detour_dryrun
##
## `--write-save=<dir>`: instead of playing the detours, write an ordinary save
## at the arrival (label `named_dry_arrival`, receipt marked as a DRY RUN seam)
## and stop, so `capture_stormwood_b_named_from_save.gd --dry-run` can be
## exercised before an earned save exists.

const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")

const NAMED_RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")
const NAMED_DETOURS := preload("res://tests/helpers/stormwood_b_named_detour_segment.gd")


func _run() -> void:
	var ids: Array = ["hollows_alpha"]
	var out := "user://sw_b_detour_dryrun"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ids="):
			ids = Array(arg.trim_prefix("--ids=").split(",", false))
		elif arg.begins_with("--named-out="):
			out = arg.trim_prefix("--named-out=")
	print("NAMED_DETOUR DRY RUN — does not count (chapter-entry seam, no route)")
	var recorder: Node = NAMED_RECORDER.new(out, 1.0, true)
	root.add_child(recorder)
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	var save_dir := "%s_%d" % [TEST_SAVE_DIR_PREFIX, OS.get_process_id()]
	game.set("save_system", SAVE_GAME.new(save_dir))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "stormwood-b-detour-dryrun")
	game.get("world").set("world_id", "stormwood-b-detour-dryrun-world")
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	for flag: String in COMPLETED_CLOUDREACH_FLAGS:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "cloudreach",
			"id": flag, "value": true})
	for species_id: String in ENTRY_PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		creature.call("set_level", 44, PROGRESSION.config())
		game.get("party").call("add", creature)
	var source := Node3D.new()
	root.add_child(source)
	current_scene = source
	await process_frame
	await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach")
	var world := await _wait_for_stormwood()
	for _frame in SCENE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			break
		await physics_frame
	if world == null or str(game.get("current_realm")) != "stormwood":
		print("NAMED_DETOUR FAIL: Stormwood never became current")
		quit(1)
		return
	var write_to := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--write-save="):
			write_to = arg.trim_prefix("--write-save=")
	if not write_to.is_empty():
		for _frame in 600:
			await physics_frame
		var saved := bool(game.call("save_game", CHECKPOINTS.CHECKPOINT_SLOT))
		var uids: Array = []
		var party := game.get("party") as RefCounted
		var rows: Array = []
		for i in int(party.call("size")):
			var member := party.call("at", i) as RefCounted
			rows.append({"uid": str(member.get("uid")), "species": str(member.get("species_id")),
				"level": int(member.get("level"))})
		var receipt := CHECKPOINTS.build_receipt("named_dry_arrival", {"commit": CHECKPOINTS.commit_sha(),
			"realm": str(game.get("current_realm")), "party": rows,
			"flags": (game.get("progression").call("all_set") as Array).duplicate()})
		receipt["passed"] = true
		receipt["fixtures_used_in_run_path"] = true
		receipt["no_fixture_statement"] = "DRY RUN seam: in-memory completed-Cloudreach party (smoke_stormwood_continuous chapter entry). Does not count."
		var out_dir := CHECKPOINTS.export_checkpoint(save_dir, write_to, "named_dry_arrival", "named_dry_arrival", receipt, {})
		print("NAMED_DETOUR wrote DRY RUN save %s saved=%s -> %s" % ["named_dry_arrival", str(saved),
			ProjectSettings.globalize_path(out_dir)])
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = 60
		quit(0 if saved and not out_dir.is_empty() else 1)
		return
	var detours := NAMED_DETOURS.new()
	var result: Dictionary = await detours.run_named(self, world, game, ids)
	for line: Variant in result.get("transcript", []):
		print("NAMED_DETOUR — %s" % str(line))
	for line: Variant in result.get("failures", []):
		print("NAMED_DETOUR note: %s" % str(line))
	print("NAMED_DETOUR outcomes %s" % JSON.stringify(result.get("outcomes", {})))
	for row: Dictionary in recorder.get("rows"):
		print("NAMED_ROUTE SUMMARY %s attempt=%d outcome=%s tells=%s" % [str(row.id),
			int(row.attempt), str(row.outcome), JSON.stringify(row.tells)])
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	quit(0)
