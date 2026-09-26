extends SceneTree

## F13 `side_water_lantern_return` in the production Water scene: Pell's lead
## -> claim `lantern_hidden_cache` -> return to Pell at the First Shore landing.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech
## (Pell's lesson briefing, lead, reminder, return and thanks conversations),
## WaterChapter's guarded-event routing, WaterLocalChains submitting the
## `water_dock_action` intent, the host LedgerRPC + water_local_chain_rules
## arbitration, WaterPickups' production Candy I claim, and the quest log.
## Disclosed fixtures: player poses are teleports (the Lantern Cove swim itself
## is not traversed here; tests/smoke_water_pocket_walk_claim.gd walks the
## pocket from its landing); the swim lesson's world completion is pre-set.
## Solo host only; the co-op split (world records, per-character receipts) is
## covered by the rule unit tests.
## Saved completion: the finished chain is written through Game.save_game,
## the world destroyed, Game reset and reloaded through Game.load_game into a
## rebuilt production Water world (tests/helpers/water_chain_reload.gd).
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const RELOAD := preload("res://tests/helpers/water_chain_reload.gd")
const CACHE := "water:lantern_cove:pickup:002"
const LEAD := "water_claim:local:lantern_return:lead"
const DONE := "water_claim:local:lantern_return:complete"

var game: Node
var world: Node3D
var player: CharacterBody3D
var checks := 0
var failures: Array[String] = []
var finished := false

func _init() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ", message)
	return ok

func frames(count: int = 4) -> void:
	for frame in count:
		await physics_frame

func pose(at: Vector3) -> void:
	player.global_position = Vector3(at.x, float(world.ground_height_at(at.x, at.z)) + 0.1, at.z)
	player.velocity = Vector3.ZERO

## Speak to an NPC through the production seam, delivering every line.
## Returns [conversation, text, world message shown when it ended].
func hear(npc_id: String) -> Array:
	var chapter: Node = world.get_node("WaterChapter")
	var npcs: Node = world.get_node("WaterNPCs")
	var panel: Node = world.get_node("DialoguePanel")
	var body: Node3D = chapter.npc_bodies.get(npc_id)
	if body == null:
		return ["", "", ""]
	pose(body.global_position + Vector3(2.0, 0.0, 0.0))
	await frames()
	game.take_pending_world_message()
	if not bool(npcs.call("start_conversation", npc_id)):
		return ["", "", ""]
	var conversation := str(npcs.get("_active_conversation"))
	var text := ""
	var message := ""
	for guard in 12:
		if not bool(panel.call("is_open")):
			break
		text += str(panel.call("runner").call("line").get("text", "")) + "\n"
		panel.call("advance")
		var shown: String = game.take_pending_world_message()
		if not shown.is_empty():
			message = shown
		await process_frame
	if bool(panel.call("is_open")):
		panel.call("close")
	return [conversation, text, message]

func lantern_entry(reader: RefCounted) -> Dictionary:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains("Lantern Cove"):
			return entry
	return {}

## The authored landmark the lead names: listed in the production world config,
## standing on dry terrain above the waterline (a data/terrain check only; the
## rendered read from the normal camera is T2's visual matrix).
func landmark_stands(landmark_id: String) -> bool:
	for raw: Dictionary in world.config.get("landmarks", []):
		if str(raw.get("id", "")) != landmark_id:
			continue
		var at := Vector3(float(raw.position[0]), 0.0, float(raw.position[2]))
		return float(world.ground_height_at(at.x, at.z)) > 1.0 and is_zero_approx(world.water_depth_at(at))
	return false

func cache_row() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.pickups:
		if str(row.id) == CACHE:
			return row
	return {}

func run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "240 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-lantern-return"
	RELOAD.isolate(game, "water_lantern_return")
	game.world.flags.set_flag("water_swim_lesson_complete")
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 900:
		await process_frame
		if world.shell_build_complete():
			break
	if not check(world.shell_build_complete(), "Production Water world built"):
		finish()
		return
	player = world.get_node("Player")
	player.set_physics_process(false)
	var pickups: Node = world.get_node("WaterPickups")
	check(world.get_node_or_null("WaterLocalChains") != null, "Local chain service is installed in the production scene")
	var reader := QUEST_LOG.new()
	reader.set_realm("water")

	# A never-briefed character hears the lesson briefing first.
	var heard: Array = await hear("water_pell")
	check(heard[0] == "water_pell_lesson_briefing", "Unbriefed character is briefed first (%s)" % heard[0])
	check(game.local.flags.has("water_swim_lesson_briefed"), "Briefing records the personal lesson beat")
	check(not game.world.flags.has(LEAD), "Briefing writes no chain record")
	check(lantern_entry(reader).is_empty(), "Lantern request not pre-labelled")

	# Step 1: Pell's lead, host-recorded.
	heard = await hear("water_pell")
	check(heard[0] == "water_pell_lantern_lead", "Pell gives the Lantern Cove lead (%s)" % heard[0])
	check(str(heard[1]).contains("arch") and str(heard[1]).contains("Lantern Cove"), "Lead names the cove's rock arch")
	check(landmark_stands("lantern_cove_drift_arch"), "The named arch is an authored landmark standing above the water")
	check(game.world.flags.has(LEAD), "Lead conversation records the world lead through the host step")
	check(str(heard[2]).contains("Lantern Cove"), "Lead message shown to the speaker: " + str(heard[2]))
	var entry := lantern_entry(reader)
	check(not entry.is_empty() and not bool(entry.done), "Lead reveals the open local request")
	heard = await hear("water_pell")
	check(heard[0] == "water_pell_lantern_reminder", "Without the cache Pell only reminds (%s)" % heard[0])
	check(not game.world.flags.has(DONE), "Reminder records nothing")
	var early: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "lantern_return_report", "inventory": {}})
	check(not bool(early.get("ok", false)) and str(early.get("code", "")) == "claim", "Host refuses a return before the claim (%s)" % str(early.get("code", "")))

	# Step 2: the existing Candy I claim beneath the arch.
	var row := cache_row()
	pose(Vector3(float(row.position[0]), 0.0, float(row.position[2])) + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	var cache: Node = pickups.call("node_for", CACHE)
	check(cache != null, "Lantern cache streams in at the arch pocket")
	var candy_before := int(game.inventory.count("skill_candy_i"))
	if cache != null:
		cache.call("_on_picked_up")
		await frames()
	check(int(game.inventory.count("skill_candy_i")) == candy_before + 1, "Production claim pays exactly one Candy I")
	check(game.world.flags.has("water_claim:water-lantern-return:" + CACHE), "Original per-character receipt recorded")

	# Step 3: back at Pell's First Shore landing.
	var far: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "lantern_return_report", "inventory": {}})
	check(str(far.get("code", "")) == "too_far", "Return must be reported at the First Shore landing (%s)" % str(far.get("code", "")))
	heard = await hear("water_pell")
	check(heard[0] == "water_pell_lantern_return", "Pell hears the return (%s)" % heard[0])
	check(game.world.flags.has(DONE), "Return records the chain completion")
	check(str(heard[2]).contains("return"), "Return message shown: " + str(heard[2]))
	check(int(game.inventory.count("skill_candy_i")) == candy_before + 1, "No extra candy for the return")
	entry = lantern_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Return completes the local request")
	heard = await hear("water_pell")
	check(heard[0] == "water_pell_lantern_thanks", "Pell acknowledges afterwards (%s)" % heard[0])
	check(str(heard[1]).contains("Lantern Cove line is on my board"), "Delivered thanks acknowledges the charted cove line")
	var again: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "lantern_return_report", "inventory": {}})
	check(str(again.get("code", "")) == "already_done", "A second report is refused")

	# Saved completion: production save -> fresh state -> production load ->
	# a rebuilt Water world. World half: lead/complete records and the
	# per-character cache receipt; character half: the Candy I.
	var reloaded: Dictionary = await RELOAD.save_and_reload(self, game, world, DONE, "skill_candy_i")
	for pair: Array in reloaded.checks:
		check(pair[0], pair[1])
	if reloaded.world == null:
		finish()
		return
	world = reloaded.world
	player = world.get_node("Player")
	player.set_physics_process(false)
	pickups = world.get_node("WaterPickups")
	check(game.world.flags.has(LEAD) and game.world.flags.has(DONE), "Reload keeps the lead and completion records")
	check(game.world.flags.has("water_claim:water-lantern-return:" + CACHE), "Reload keeps the per-character cache receipt")
	check(int(game.inventory.count("skill_candy_i")) == candy_before + 1, "Reload keeps exactly the one Candy I")
	entry = lantern_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Reloaded quest log shows the request done")
	var cache_at := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	pose(cache_at + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	check(RELOAD.neighbour_resident(pickups, cache_at, CACHE), "Lantern Cove finds stream in around the arch after reload")
	check(pickups.call("node_for", CACHE) == null, "Claimed cache does not respawn after reload")
	heard = await hear("water_pell")
	check(heard[0] == "water_pell_lantern_thanks", "Reloaded Pell acknowledges, no re-offer (%s)" % heard[0])
	check(str(heard[1]).contains("Lantern Cove line is on my board"), "Reloaded thanks still names the charted cove line")
	again = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "lantern_return_report", "inventory": {}})
	check(str(again.get("code", "")) == "already_done", "Reloaded host still refuses a second report")
	check(int(game.inventory.count("skill_candy_i")) == candy_before + 1, "No second Candy I after reload")
	finish()

func finish() -> void:
	finished = true
	print("Water Lantern return smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
