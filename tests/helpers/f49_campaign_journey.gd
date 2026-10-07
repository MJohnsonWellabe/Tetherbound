extends RefCounted

## F49 ordinary-input composition. No fixtures, grants, pose writes or direct
## transaction calls. Existing helpers retain their disclosed simulation clocks;
## their elapsed time never supplies owner play or hardware performance proof.
const ORDER := preload("res://scripts/data/biome_order.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
# Reuse F20's ordinary dual-clock input, personal lesson reader and authored
# Hall approach. It extends the F49 travel checks; no fixture setup is used.
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const WARDEN := preload("res://tests/helpers/f49_warden_finale.gd")
const CLOUD := preload("res://tests/helpers/f49_cloudreach_chapter.gd")
const STORM_SETTLEMENT := preload("res://tests/helpers/f49_stormheart_settlement.gd")
const REQUIRED_FLAGS := ["redesign_portal_runtime_enabled", "redesign_boss_handoff_runtime_enabled", "redesign_ending_runtime_enabled"]
var driver: SceneTree
var game: Node
var travel: RefCounted
var disk: RefCounted
var visited: Array[String] = []
var resume_source := ""
var stop_boundary := ""
var resumed_boundary := ""
var segmented := false

func run(owner: SceneTree) -> void:
	driver = owner
	driver.started_ms = Time.get_ticks_msec()
	game = driver.root.get_node("Game")
	# Legacy checkpoint labels embed the old order. Never accept them silently.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--resume-from=") or arg.begins_with("--stop-at=") \
				or arg.begins_with("--checkpoint-dir=") or arg == "--dry-run-water-fixture" or arg == "--m4-finale":
			_fail("F49 refuses legacy resume/setup options; use --legacy-order-diagnostic for isolated debugging")
			return
		if arg.begins_with("--handoff-from="):
			if not resume_source.is_empty() or arg == "--handoff-from=":
				_fail("F49 accepts one nonempty segment source")
				return
			resume_source = arg.trim_prefix("--handoff-from=")
			segmented = true
		if arg.begins_with("--through-boundary="):
			if not stop_boundary.is_empty() or arg == "--through-boundary=":
				_fail("F49 accepts one nonempty segment stop")
				return
			stop_boundary = arg.trim_prefix("--through-boundary=")
			segmented = true
		if arg.begins_with("--world-seed="):
			var seed := arg.trim_prefix("--world-seed=")
			if not seed.is_valid_int():
				_fail("--world-seed must be an integer")
				return
			OS.set_environment("TB_WORLD_SEED", seed)
	if not stop_boundary.is_empty() and not HANDOFF.BOUNDARIES.has(stop_boundary):
		_fail("F49 segment stop must name a new-order chapter boundary")
		return
	if segmented:
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--through-") and not arg.begins_with("--through-boundary="):
				_fail("F49 chapter segments cannot be combined with opening prefix stops")
				return
		if OS.has_environment("TB_WORLD_SEED"):
			_fail("F49 chapter segments preserve the actual fresh population without seed overrides")
			return
	var session: Node = game.get("session")
	var config: Dictionary = session.call("config") if session != null and session.has_method("config") else {}
	for field: String in REQUIRED_FLAGS:
		if config.get(field) != true:
			_fail("F49 missing producer gate: multiplayer.json::session." + field + " remains OFF; ROOT must prove and enable the actual shared runtime")
			return
	if ORDER.runtime_ids() != ["meadows", "water", "cloudreach", "stormwood"]:
		_fail("F49 requires the authored Meadows/Tidewake/Cloudreach/Stormwood order")
		return
	driver.scratch = "user://f49_campaign_%d_%d" % [OS.get_process_id(), driver.started_ms]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(driver.scratch)):
		_fail("F49 scratch already exists; refusing overwrite")
		return
	game.set("save_system", SAVE.new(driver.scratch))
	driver.checkpoint_args = {"no_checkpoints": true}
	driver.coverage = driver.COVERAGE.new()
	if not driver.coverage.start(driver, driver.scratch + "_coverage.jsonl"):
		_fail("F49 road coverage observer could not start")
		return
	driver.route_ledger = driver.ROUTE_LEDGER.new()
	if not driver.route_ledger.start(driver, func() -> String: return driver.reached, driver.scratch + "_ledger.jsonl"):
		_fail("F49 M2 resource/route observer could not start")
		return
	if OS.get_cmdline_user_args().has("--fight-log") or OS.get_cmdline_user_args().has("--aftermath-capture"):
		driver.fight_log = (load("res://tests/helpers/meadows_earned_fight_log_segment.gd") as GDScript).new(
			OS.get_cmdline_user_args().has("--aftermath-capture"))
		driver.root.add_child(driver.fight_log)
	driver.local_chains = driver.LOCAL_CHAINS.new()
	driver.local_chains.earned = true
	travel = TRAVEL.new(driver, game)
	disk = HANDOFF.new(driver, game, driver.scratch + "_handoffs")
	var from := -1
	if not resume_source.is_empty():
		resumed_boundary = disk.import_prefix(resume_source)
		if resumed_boundary.is_empty():
			_failures(disk.failures)
			return
		from = HANDOFF.BOUNDARIES.find(resumed_boundary)
		if not stop_boundary.is_empty() and HANDOFF.BOUNDARIES.find(stop_boundary) <= from:
			_fail("F49 segment must advance beyond its imported boundary")
			return
		if not await disk.reload_boundary(resumed_boundary, travel):
			_failures(disk.failures)
			return
		driver.live = {"world": driver.current_scene, "game": game,
			"player": driver.current_scene.get_node_or_null("Player"),
			"rig": driver.current_scene.get_node_or_null("CameraRig")}
		driver.reached = resumed_boundary
		driver.resume_boundary = resumed_boundary
		driver.resume_info = {"source": resume_source, "boundary": resumed_boundary,
			"source_kind": "f49_hash_linked_production_prefix", "journey_id": disk.journey_id}
		for index in from + 1: visited.append(["meadows", "tidewake", "cloudreach", "stormwood"][index])
	if from < 0:
		if not await driver._stage_fresh_through_hall(game): return
		visited.append("meadows")
		if not driver._accepted(await WARDEN.new().run_finale(driver, driver.current_scene, game), "passed"): return
		if not await _boundary("meadows_settled"): return
	if from < 1:
		if not await travel.home_key() or not await travel.hang_relic("meadows") or not await travel.enter("tidewake", "water"):
			_failures(travel.failures)
			return
		visited.append("tidewake")
		driver.live["world"] = driver.current_scene
		await driver._stage_water_to_ending(game, true)
		if driver.finished or not driver.failures.is_empty(): return
		if driver.reached != "tidewake_ending_earned":
			_fail("F49 Tidewake did not settle its real chapter")
			return
		if not await _dock_conclusion_available(): return
		if not await _boundary("tidewake_settled"): return
		if not _dock_saved():
			_fail("F49 Tidewake departure lost its actual world conclusion or owner receipt on disk reload")
			return
	if from < 2:
		if not await travel.home_key() or not await travel.hang_relic("tidewake") or not await travel.enter("cloudreach", "cloudreach"):
			_failures(travel.failures)
			return
		visited.append("cloudreach")
		if not driver._accepted(await CLOUD.new().run(driver, driver.current_scene, game), "ok"): return
		if not await _boundary("cloudreach_settled"): return
	if from < 3:
		if not await travel.home_key() or not await travel.hang_relic("cloudreach") or not await travel.enter("stormwood", "stormwood"):
			_failures(travel.failures)
			return
		visited.append("stormwood")
		for helper: GDScript in [driver.STORMWOOD, driver.CROWN, driver.ROOTGATE, driver.DYNAMO, driver.MARROW]:
			var segment: RefCounted = driver.STORMWOOD.Segment.new() if helper == driver.STORMWOOD else helper.new()
			if not driver._accepted(await segment.run(driver, driver.current_scene, game), "passed"): return
		if not driver._accepted(await STORM_SETTLEMENT.new().run(driver, driver.current_scene, game), "passed"): return
		if HOME.journey_context(game).is_empty():
			_fail("F49 missing producer: accepted Stormheart outcome has no Game.regional_ending_context")
			return
		if not await _boundary("stormwood_settled"): return
	if from < 4:
		if not await travel.home_key() or not await travel.hang_relic("stormwood"):
			_failures(travel.failures)
			return
		var grandpa: Node3D
		for node: Node in driver.current_scene.find_children("*", "", true, false):
			if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa":
				grandpa = node as Node3D
		var dialogue: Node = driver.current_scene.get_node_or_null("DialoguePanel")
		if grandpa == null or dialogue == null or dialogue.call("is_open"):
			_fail("F49 homecoming approach requires the actual Grandpa prompt and closed dialogue")
			return
		# The existing approach walks the authored farmhouse doorway without X;
		# inherited homecoming then proves the exact provider's ordinary input.
		if not await travel.approach_grandpa(grandpa):
			_failures(travel.failures)
			return
		if dialogue.call("is_open"):
			_fail("F49 Grandpa dialogue opened before ordinary homecoming input")
			return
		if not await travel.grandpa_and_credits():
			_failures(travel.failures)
			return
		visited.append("homecoming_credits")
		if not await _boundary("completed_world", false): return
	if not await disk.reload_completed(travel):
		_failures(disk.failures)
		return
	driver.reached = "completed_world_continuation"
	driver.campaign_complete = not segmented
	if segmented: _segment_result("completed_world", true)
	print("F49 JOURNEY " + JSON.stringify({"order": visited, "shortcuts": ["agent emits ordinary actions", "declines pending legendaries to retain the earned five", "production saves copied to immutable handoffs", "credits skipped by controller after their actual opening", "inherited helpers retain their original simulation clocks; wall time is not owner/device timing"], "legacy_cards": {"M2": "same-route ledger/reloads; two-loss/four-character proof queued separately", "M3": "fight/optional activity/visual proof remains separate", "T2": "same-route six chains; island/fight/art/four-character proof remains separate", "S2": "storm/fight/activity/visual proof remains separate"}, "owner_play": "pending", "ally_hardware": "pending", "published_download": "pending"}))
	driver._finish(true)

func _boundary(label: String, reload_disk: bool = true) -> bool:
	driver.reached = label
	if not disk.export_boundary(label):
		_failures(disk.failures)
		return false
	if reload_disk and not await disk.reload_boundary(label, travel):
		_failures(disk.failures)
		return false
	if label == "tidewake_settled" and not _dock_saved():
		_fail("F49 Tidewake segment lost its saved conclusion on production reload")
		return false
	if segmented and label == stop_boundary and label != "completed_world":
		_segment_result(label, false)
		driver._finish(true)
		return false
	return true

func _segment_result(label: String, completed: bool) -> void:
	print("F49 SEGMENT RESULT " + JSON.stringify({"kind": "f49_earned_segment",
		"journey_id": disk.journey_id, "commit": disk.source_commit,
		"from_boundary": resumed_boundary, "through_boundary": label,
		"predecessors": disk.history, "visited": visited,
		"completed_world_reloaded": completed, "counts_as_uninterrupted_proof": false}))

func _fail(message: String) -> void:
	driver.failures.append(message)
	driver._finish(false)

func _failures(lines: Array) -> void:
	for line: Variant in lines: driver.failures.append(str(line))
	if lines.is_empty(): driver.failures.append("F49 continuation failed without a producer receipt")
	driver._finish(false)

func _dock_conclusion_available() -> bool:
	var chains: RefCounted = driver.local_chains
	var world := driver.current_scene as Node3D
	var cave := world.get_node_or_null("WaterVeilfall")
	if chains == null or chains.mount == null or cave == null or not chains.continuous \
		or not chains.earned or not cave.call("contains_interior", chains.player.global_position):
		_fail("F49 dock continuation requires the same earned swimmer and actual Veilfall chamber")
		return false
	var party_before := _dock_party_uids()
	var origin: Vector3 = cave.get("interior").global_position
	var interior: Array = driver.VEILFALL_INTERIOR_PATH.duplicate()
	interior.reverse()
	for point: Vector3 in interior:
		if not await chains.navigator.walk_to(origin + point, 2400, 1.5):
			_fail("F49 ordinary Veilfall exit walk stalled")
			return false
	var exit_prompt: Node3D = cave.get("_exit_prompt")
	if not await chains._approach_prompt(exit_prompt, exit_prompt.global_position):
		_fail("F49 actual Veilfall exit provider did not own Interact")
		return false
	await chains._press_interact()
	await chains._frames(30)
	if cave.call("contains_interior", chains.player.global_position):
		_fail("F49 ordinary exit input did not leave Veilfall")
		return false
	chains.last_island = "veilfall"
	# _talk uses the existing continuous island path, paid swimmer, ground
	# navigator, exact NPC provider and Interact-driven natural completion.
	var heard: Array = await chains._talk("water_mara")
	if heard.is_empty() or heard[0] != "water_mara_post" or not chains.failures.is_empty():
		_failures(chains.failures)
		return false
	var chapter := world.get_node_or_null("WaterChapter")
	var prompt: Node3D = chapter.get("_dock_prompt") if chapter != null else null
	if prompt == null or not await chains._approach_prompt(prompt, prompt.global_position):
		_fail("F49 civilian departure provider did not own ordinary Interact after Mara's afterword")
		return false
	await chains._press_interact()
	for frame in 600:
		if _dock_saved():
			if _dock_party_uids() != party_before:
				_fail("F49 dock continuation replaced the earned party")
				return false
			return true
		await driver.physics_frame
	_fail("F49 actual dock handoff did not settle its saved world and owner receipt")
	return false

func _dock_party_uids() -> Array[String]:
	var uids: Array[String] = []
	for member: RefCounted in game.party.members(): uids.append(str(member.get("uid")))
	return uids

func _dock_saved() -> bool:
	var receipt: String = "craft:water_dock_departure:" + str(game.local.character_id)
	var row: Dictionary = game.session.call("_owner_training_row")
	var decision: Dictionary = game.session.call("_training_decision", game.session.call("local_peer_id"), row)
	return decision.get("ok") == true and decision.get("saved") == true \
		and row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).has(receipt) \
		and game.world.flags.has("water_civilian_departure_complete") \
		and game.local.redesign_character.transaction_receipts.has(receipt)
