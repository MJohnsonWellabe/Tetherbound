extends SceneTree

## F10#2 footage: one Stormwood named fight rendered from an ordinary save the
## EARNED route wrote just before it (`capture_stormwood_b_named_route_earned.gd`
## `--named-saves=`). The save is copied to scratch and loaded through the
## production title's Load list, exactly as a player continues; the loaded
## party and flags must match the save's receipt or the run refuses. Then the
## player plays on: rest at a camp, walk the road, one Engage press, a reader's
## controller fight (`stormwood_b_named_detour_segment.gd`), with the passive
## recorder saving production-camera frames. No flag, item, party, position or
## weather write.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_stormwood_b_named_from_save.gd \
##     -- --save=<dir with save/ and receipts/> --label=named_pre_capacitor \
##        --ids=capacitor_alpha --named-out=res://shots/sw_b_named_from_save
##
## `named_pre_crown` plays the earned Crown continuation (walk through the paid
## arch, the guardian, Wen) with the same reader pilot. `--dry-run` marks a
## save that did not come from an earned run; its rows say so.

const GAME := preload("res://autoload/game_state.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")
const DETOURS := preload("res://tests/helpers/stormwood_b_named_detour_segment.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const SETTLE_FRAMES := 300

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _arg(name: String, fallback: String = "") -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--%s=" % name):
			return arg.trim_prefix("--%s=" % name)
	return fallback


func _run() -> void:
	var source := _arg("save")
	var label := _arg("label")
	var ids: Array = Array(_arg("ids").split(",", false))
	var out := _arg("named-out", "res://shots/sw_b_named_from_save")
	var dry := OS.get_cmdline_user_args().has("--dry-run")
	print("NAMED_FROM_SAVE source=%s label=%s ids=%s%s" % [source, label, str(ids),
		" DRY RUN — does not count" if dry else ""])
	var receipt := CHECKPOINTS.read_receipt(CHECKPOINTS.receipt_path(source, label))
	if source.is_empty() or label.is_empty() or receipt.is_empty():
		_done("no save/receipt at %s for %s" % [source, label])
		return
	print("NAMED_FROM_SAVE receipt commit=%s resumed_from=%s statement=%s" % [receipt.get("commit", ""),
		JSON.stringify(receipt.get("resumed_from", {})), str(receipt.get("no_fixture_statement", ""))])
	var scratch := "user://sw_b_named_from_save_%d_%d" % [OS.get_process_id(), Time.get_ticks_msec()]
	if not CHECKPOINTS.copy_tree(source.path_join("save"), scratch):
		_done("could not stage %s/save" % source)
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	game.set("save_system", SAVE.new(scratch))
	var recorder: Node = RECORDER.new(out, float(_arg("named-interval", "1.0")), false)
	root.add_child(recorder)
	var world := await _load_through_title(game)
	if world == null:
		_done("")
		return
	var uids: Array = []
	for i in int(game.get("party").call("size")):
		uids.append(str((game.get("party").call("at", i) as RefCounted).get("uid")))
	var problems := CHECKPOINTS.validate(receipt, label, uids,
		(game.get("progression").call("all_set") as Array).duplicate())
	if not problems.is_empty():
		for line: Variant in problems:
			_failures.append("REFUSED: " + str(line))
		_done("")
		return
	print("NAMED_FROM_SAVE loaded realm=%s player=%s party=%s" % [game.get("current_realm"),
		(world.get_node("Player") as Node3D).global_position, str(uids)])
	var detours := DETOURS.new()
	var result: Dictionary
	if ids.has("crown_guardian"):
		result = await detours.run(self, world, game)
	else:
		result = await detours.run_named(self, world, game, ids)
	for line: Variant in result.get("transcript", []):
		print("NAMED_FROM_SAVE — %s" % str(line))
	for line: Variant in result.get("failures", []):
		print("NAMED_FROM_SAVE note: %s" % str(line))
	print("NAMED_FROM_SAVE outcomes %s" % JSON.stringify(result.get("outcomes", {})))
	for row: Dictionary in recorder.get("rows"):
		print("NAMED_ROUTE SUMMARY %s attempt=%d outcome=%s seconds=%s tells=%s hits=%s frames=%d party=%s%s" % [
			str(row.id), int(row.attempt), str(row.outcome), str(row.get("seconds", "?")),
			JSON.stringify(row.tells), JSON.stringify(row.hits), (row.frames as Array).size(), str(row.party),
			" DRY RUN" if dry else ""])
	if (recorder.get("rows") as Array).is_empty():
		_failures.append("no named fight was recorded")
	_done("")


func _load_through_title(game: Node) -> Node3D:
	if not bool(game.call("has_save", CHECKPOINTS.CHECKPOINT_SLOT)):
		_failures.append("staged save has no slot %d" % CHECKPOINTS.CHECKPOINT_SLOT)
		return null
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 10:
		await process_frame
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		_failures.append("the production title has no Load button")
		return null
	load_button.pressed.emit()
	await process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % CHECKPOINTS.CHECKPOINT_SLOT) \
				and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		_failures.append("the title's Load list does not offer Save %d" % CHECKPOINTS.CHECKPOINT_SLOT)
		return null
	chosen.pressed.emit()
	for _frame in 7200:
		await process_frame
		var scene := current_scene
		if scene != null and scene != title and is_instance_valid(scene) \
				and scene.get_node_or_null("Player") != null \
				and str(game.get("pending_realm_entry")).is_empty() \
				and bool(game.call("_realm_scene_ready", scene, str(game.get("current_realm")))):
			for _i in SETTLE_FRAMES:
				await physics_frame
			for _i in 600:
				if INPUT_OWNER.current(self) == null:
					break
				await process_frame
			return scene as Node3D
	_failures.append("the loaded save never reached a ready world scene")
	return null


func _done(problem: String) -> void:
	if not problem.is_empty():
		_failures.append(problem)
	for line: String in _failures:
		print("NAMED_FROM_SAVE FAIL: %s" % line)
	print("NAMED_FROM_SAVE %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
