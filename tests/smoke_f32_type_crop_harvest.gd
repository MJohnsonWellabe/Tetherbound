extends SceneTree

## F32 criterion #3 engine smoke: one native type crop on the real Meadows
## authored plot, tilled/sown/picked by hand through the actual interact
## prompt and seed picker, ripened on the production host day clock, and
## proven from the decoded owner/world saves on disk.
##
## Disclosed fixtures: fresh isolated save directory; one owned Terrapup;
## opening free-play flag; starting satchel of one hoe and two seed_ground
## (seed source is not under test); trainer/camera start 6m west of
## authored:0 with a collision-streaming wait; explicit mount retry of the
## production FoundationResources adapter (same as smoke_f32_material_sites);
## host days advanced with Game.advance_day() (the host clock that
## world_look's day roll and night_rest call) rather than by resting; a
## transient in-memory {id: greenhouse, paid: true} record used only to read
## the live adapter's Greenhouse derivation, removed before any save.
## Real: baked Meadows scene, f32_world_mount.mount_authored_farm placement,
## controller walk, interact/ui_accept joypad taps, seed picker, host context,
## Foundation resource transaction, owner disk write and ACK.
## Not claimed: ENet/two-peer, off-biome Greenhouse sowing in engine, visuals.
const DRIVER := preload("res://tests/helpers/gate_a_material_route.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const ADAPTER := preload("res://scripts/net/foundation_resources.gd")
const FARM := preload("res://scripts/world/farm_logic.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const PLOT_ID := "authored:0"
const CROP := "ground"
## A whole-realm F32 mount from scratch; it held ~5 s per call before PERF.
const MAX_MOUNT_MS := 2000
var _report := {"checks": [], "fixture": "see header", "two_peer": false}
var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _resources: Node
var _driver: RefCounted
var _saver: RefCounted
var _settled: Array[Dictionary] = []
var _failed := false
var _finished := false
var _output := ""


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, label: String) -> bool:
	_report.checks.append({"ok": value, "label": label})
	_failed = _failed or not value
	print("F32 CROP %s: %s" % ["PASS" if value else "FAIL", label])
	return value


func _frames(count: int) -> void:
	for frame in count: await physics_frame


func _run() -> void:
	_output = "user://f32_type_crop_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): _output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_output)
	create_timer(540.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "native watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	if not _check(_game != null, "production Game exists"):
		_finish(); return
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", "meadows")
	_game.get("local").set("character_id", "f32-crop-owner")
	_game.get("world").set("world_id", "f32-crop-world")
	_game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_game.get("inventory").call("add", "hoe", 1)
	_game.get("inventory").call("add", "seed_" + CROP, 2)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/farm.json"))
	var crop := FARM.crop_definition(config, CROP)
	if not _check(not crop.is_empty() and config.get("native_types", []).has(CROP), "ground is a native type crop"):
		_finish(); return
	if not _check(change_scene_to_file(SCENE) == OK, "request actual Meadows scene"):
		_finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("world_realm") \
			and current_scene.call("world_realm") == "meadows" and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "Meadows procedural build completed"):
		_finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	_resources = _game.get("session").get_node_or_null(^"FoundationComposition/Resources")
	if not _check(_player != null and _resources != null, "production player and resource adapter mounted"):
		_finish(); return
	_resources.get_node(^"SourceService").connect("settled", _on_settled)
	_driver = DRIVER.new()
	_driver.set("_tree", self)
	_driver.set("_world", _world)
	_driver.set("_game", _game)
	_driver.set("_player", _player)
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	_driver.set("_rig", rig)
	_driver.set("_arbiter", get_first_node_in_group(&"interaction_arbiter"))
	if not _check(rig != null and _driver.get("_arbiter") != null and _driver.call("_resolve_move_bindings") == true,
		"controller driver resolves production camera and arbiter"):
		_finish(); return
	_driver.set("_nav", NAV.new(self, _player, rig, Callable(_driver, "_send_stick")))
	await _frames(30)
	await _crop_cycle(config, crop)
	if not _failed: _check_fresh_mount_time()
	if not _failed: _check_sequence_directors_are_grouped()
	_finish()


## PERF (2026-10-05): foundation_travel_lifecycle.gd finds the Meadows
## SequenceDirector through the `progression_restore` group instead of walking
## the whole world every sample. That is exact only while every director in a
## real world joins the group.
func _check_sequence_directors_grouped_list() -> Array:
	var out: Array = []
	for node: Node in _world.find_children("*", "Node", true, false):
		if node.get_script() == preload("res://scripts/story/sequence_director.gd"): out.append(node)
	return out


func _check_sequence_directors_are_grouped() -> void:
	var directors := _check_sequence_directors_grouped_list()
	_check(not directors.is_empty(), "the Meadows world has a SequenceDirector")
	for director: Node in directors:
		_check(director.is_in_group("progression_restore"),
			"SequenceDirector %s is in progression_restore" % str(director.get_path()))


## PERF (2026-10-05): a realm mount with every site still to place (as at world
## entry, on host and guest) scanned all ~180k world nodes again for each site,
## ~5 s per call. A throwaway mount re-runs that whole path after the crop
## cycle, so it cannot disturb the checks above. Its ~150 duplicate nodes live
## until quit(): keep it (and the read-only grouping check) last.
func _check_fresh_mount_time() -> void:
	var probe: Node3D = preload("res://scripts/world/f32_world_mount.gd").new()
	_world.add_child(probe)
	var started := Time.get_ticks_msec()
	var census: Dictionary = probe.call("mount", _world, _player, _resources.get("_service"))
	var took := Time.get_ticks_msec() - started
	print("F32 fresh realm mount: %d ms for %d sites" % [took, (census.get("mounted_ids", []) as Array).size()])
	_check((census.get("mounted_ids", []) as Array).size() > 0, "the fresh mount placed sites (the slow path ran)")
	_check(took <= MAX_MOUNT_MS, "a fresh realm mount stays within %d ms (took %d ms)" % [MAX_MOUNT_MS, took])
	probe.queue_free()


func _crop_cycle(config: Dictionary, crop: Dictionary) -> void:
	var at := Vector2(float(config.plots[0].at[0]), float(config.plots[0].at[1]))
	var start := at + Vector2(-6, 0)
	var ground := float(_world.call("ground_height_at", start.x, start.y))
	if not _check(is_finite(ground), "fixture start resolves baked ground"): return
	_player.set_physics_process(false)
	_player.global_position = Vector3(start.x, ground + 0.2, start.y)
	_player.velocity = Vector3.ZERO
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		rig.global_position = _player.global_position
		rig.reset_physics_interpolation()
	for frame in 8:
		await process_frame
		await physics_frame
	_player.set_physics_process(true)
	_player.reset_physics_interpolation()
	await _frames(6)
	for frame in 180:
		await physics_frame
		if _player.is_on_floor(): break
	_resources.get("_mount_retry").erase("meadows")
	_resources.call("_mount_realm", "meadows", _player)
	var plot_node: Node3D = _resources.call("_source", "meadows", PLOT_ID)
	if not _check(plot_node != null and plot_node.get_script() == preload("res://scripts/world/type_crop_plot.gd"),
		"mount_authored_farm placed the typed plot for " + PLOT_ID): return
	var prompt := plot_node.get_node_or_null(^"Interactable") as Node3D
	if not _check(prompt != null, "plot interact prompt exists"): return
	_driver.set("_active_walk_purpose", "F32 type crop " + PLOT_ID)
	var before_walk := _player.global_position
	var arrived: bool = await _driver.call("_walk_to", plot_node.global_position, 1.0, 600)
	var walked := Vector2(before_walk.x, before_walk.z).distance_to(Vector2(_player.global_position.x, _player.global_position.z))
	_report.walked_metres = walked
	if not _check(arrived and walked >= 3.0 and _player.global_position.distance_to(plot_node.global_position) <= 2.2,
		"controller walked %.1fm to the plot" % walked): return
	var peer := int(_game.get("session").call("local_peer_id"))
	var farm_intent := {"operation": "farm", "request": {"plot_id": PLOT_ID}}
	var context: Dictionary = _resources.call("host_context", peer, "resource:meadows:" + PLOT_ID, farm_intent)
	_check(context.get("greenhouse_built") == false, "live host context: no Greenhouse built -> outdoors only")
	var buildings: Array = _game.get("world").placed_buildings
	buildings.append({"id": "greenhouse", "realm": "meadows", "paid": true, "uid": "b999999"})
	context = _resources.call("host_context", peer, "resource:meadows:" + PLOT_ID, farm_intent)
	_check(context.get("greenhouse_built") == true, "live host context derives Greenhouse from paid world record")
	buildings.pop_back()
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		"pre-farming owner and world saved to isolated disk"): return
	var disk_before := _disk("before")
	# Till by hand (hoe owned).
	if not await _interact(prompt, "till"): return
	var disk_tilled := _disk("tilled")
	_check(_plot(disk_tilled.world).get("state") == FARM.TILLED, "disk: plot tilled")
	# Sow by hand: interact opens the seed picker; A confirms the focused crop.
	if not _check(await _driver.call("_prompt_holds_the_line", prompt.get_instance_id()), "plot prompt wins interaction (sow)"): return
	await _driver.call("_tap_action", &"interact")
	await _frames(10)
	if not _check(plot_node.call("is_open") == true, "seed picker opened from interact"): return
	var settled_before := _settled.size()
	await _driver.call("_tap_action", &"ui_accept")
	if not await _wait_settled(settled_before, "sow"): return
	var disk_sown := _disk("sown")
	var sown := _plot(disk_sown.world)
	var sow_day := int(disk_sown.world.get("day", 0))
	_check(sown.get("state") == FARM.SOWN and sown.get("crop_id") == CROP
		and int(sown.get("planted_on_day", -1)) == sow_day
		and int(sown.get("ripe_on_day", -1)) == sow_day + int(crop.grow_days),
		"disk: %s sown on host day %d, ripe on %d (%s)" % [CROP, sow_day, sow_day + int(crop.grow_days), sown])
	_check(_count(disk_sown.character, "seed_" + CROP) == _count(disk_before.character, "seed_" + CROP) - 1,
		"disk: exactly one seed_%s debited" % CROP)
	for item: String in crop.outputs:
		_check(_count(disk_sown.character, item) == _count(disk_before.character, item), "disk: sowing paid no " + item)
	_check(_receipt_row(disk_sown, "sow").get("status") == "accepted", "disk: sow journal row accepted")
	# Host clock: advance day by day until the crop is ripe; nothing harvests.
	for step: int in int(crop.grow_days):
		_check(plot_node.call("_plot").get("state") == FARM.SOWN and FARM.state_of(plot_node.call("_plot"), int(_game.get("day"))) == FARM.SOWN,
			"day %d: crop still growing" % int(_game.get("day")))
		_game.call("advance_day")
		await _frames(5)
	_saver.call("finish_fallback")
	_check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		"ripe-day owner and world saved")
	var disk_ripe := _disk("ripe")
	var ripe_plot := _plot(disk_ripe.world)
	_check(int(disk_ripe.world.get("day", 0)) == sow_day + int(crop.grow_days), "disk: host day advanced to ripe day")
	_check(ripe_plot.get("crop_id") == CROP and FARM.state_of(ripe_plot, int(disk_ripe.world.day)) == FARM.RIPE,
		"disk: ripe crop stays on the plot")
	for item: String in crop.outputs:
		_check(_count(disk_ripe.character, item) == _count(disk_sown.character, item), "disk: day advance paid no " + item)
	# Pick by hand.
	if not await _interact(prompt, "harvest"): return
	var disk_after := _disk("harvested")
	var row := _receipt_row(disk_after, "harvest")
	_check(row.get("status") == "accepted", "disk: harvest journal row accepted")
	for item: String in crop.outputs:
		_check(_count(disk_after.character, item) - _count(disk_ripe.character, item) == int(crop.outputs[item]),
			"disk: harvest paid exactly %d %s" % [int(crop.outputs[item]), item])
	_check(_count(disk_after.character, "seed_" + CROP) == _count(disk_before.character, "seed_" + CROP) - 1,
		"disk: net seed debit is exactly one")
	_check(disk_after.character.get("redesign_character", {}).get("transaction_receipts", []).has(row.get("receipt", "")),
		"disk: owner record holds the harvest receipt")
	_check(_plot(disk_after.world).get("state") == FARM.TILLED, "disk: picked bed returns to tilled")
	_report.receipt = row.get("receipt", "")


func _interact(prompt: Node3D, action: String) -> bool:
	if not _check(await _driver.call("_prompt_holds_the_line", prompt.get_instance_id()), "plot prompt wins interaction (%s)" % action):
		return false
	var settled_before := _settled.size()
	await _driver.call("_tap_action", &"interact")
	return await _wait_settled(settled_before, action)


func _wait_settled(count: int, action: String) -> bool:
	for frame in 900:
		if _settled.size() > count: break
		await physics_frame
	var verdict: Dictionary = _settled.back().verdict if _settled.size() > count else {}
	_report[action + "_verdict"] = verdict
	return _check(ADAPTER.saved_decision(verdict), "%s reaches owner save and ACK (%s)" % [action, verdict.get("code", "ok")])


func _on_settled(op: String, id: String, action: String, verdict: Dictionary) -> void:
	if op != "farm" or id != PLOT_ID: return
	_settled.append({"action_id": action, "verdict": verdict.duplicate(true)})
	if verdict.get("terminal_refusal") != true: return
	# Read only AFTER this actual attempt was refused. Admission/view/context
	# getters and save-store getters can settle writes; none belong here.
	var session: Node = _game.get("session")
	var authority: RefCounted = session.get("_character_authority")
	var original: Array[Dictionary] = []
	for envelope: Dictionary in (session.get("_foundation_requests") as Dictionary).values():
		if envelope.get("op") == "resource" and envelope.get("intent", {}).get("request", {}).get("action_id") == action:
			original.append(envelope.duplicate(true))
	var source: Node3D = _resources.call("_source", "meadows", PLOT_ID)
	var input: Node = preload("res://scripts/ui/input_owner.gd").current(self)
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var character: String = _game.get("local").character_id
	var diagnostic := {"original_envelopes": original, "character_id": character,
		"authority_revision": authority.call("revision", character),
		"authority_state": authority.call("state", character),
		"training_pending": (authority.get("_training_pending") as Dictionary).get(character, {}).duplicate(true),
		"research_preparation": (authority.get("_research_preparations") as Dictionary).get(character, {}).duplicate(true),
		"world_day": _game.get("world").day, "realm": _game.get("current_realm"),
		"player_position": [_player.global_position.x, _player.global_position.y, _player.global_position.z],
		"source_position": [source.global_position.x, source.global_position.y, source.global_position.z] if source != null else [],
		"distance_m": _player.global_position.distance_to(source.global_position) if source != null else -1.0,
		"world_owns_player": _world.is_ancestor_of(_player),
		"world_owns_source": source != null and _world.is_ancestor_of(source),
		"input_owner": str(input.get_path()) if input != null else "",
		"lifecycle": lifecycle.call("local_sample") if lifecycle != null else {}}
	_report.terminal_failure = diagnostic
	print("F32 CROP refused original source: ", JSON.stringify(diagnostic))


func _plot(world: Dictionary) -> Dictionary:
	var plots: Array = world.get("farm_plots", [])
	return plots[0] if not plots.is_empty() and plots[0] is Dictionary else {}


func _receipt_row(disk: Dictionary, action: String) -> Dictionary:
	for value: Variant in disk.world.get("reward_deliveries", {}).values():
		if value is Dictionary and value.get("action") == "resource" \
			and value.get("intent", {}).get("request", {}).get("plot_id") == PLOT_ID \
			and value.get("intent", {}).get("request", {}).get("action") == action:
			return value
	return {}


func _disk(label: String) -> Dictionary:
	_saver.call("finish_fallback")
	var paths := {"world": _saver.call("worlds").call("path_for", str(_game.get("world").world_id)),
		"character": _saver.call("characters").call("path_for", str(_game.get("local").character_id))}
	var result := {}
	for kind: String in paths:
		var path: String = paths[kind]
		var decoded: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		_check(decoded is Dictionary, label + " decodes " + kind + " save document")
		result[kind] = decoded if decoded is Dictionary else {}
	return result


func _count(character: Dictionary, item: String) -> int:
	var count := 0
	for slot: Variant in character.get("inventory", []):
		if slot is Dictionary and slot.get("id") == item: count += int(slot.get("n", 0))
	return count


func _finish() -> void:
	if _finished: return
	_finished = true
	if _driver != null: _driver.call("_release_move")
	_report.ok = not _failed
	var path := _output.path_join("report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "\t"))
		file.close()
	print("F32 CROP REPORT ", ProjectSettings.globalize_path(path))
	quit(1 if _failed else 0)
