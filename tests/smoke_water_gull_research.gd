extends SceneTree

## F13 `side_water_gull_research` in the production Water scene: Adair names
## Gull Rest -> recover the survey satchel at its site -> return the
## observations to Adair at Brine Steps; the Candy II pocket pays on its own.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech
## (Adair's lead, reminder, return and thanks), WaterChapter's guarded-event
## routing, WaterLocalChains' satchel prop and Interact prompt, the
## `water_dock_action` intent through the host LedgerRPC and
## water_local_chain_rules, WaterPickups' production Candy II claim and the
## quest log.
## Disclosed fixtures: player poses are teleports (the Reedhaven -> Gull Rest
## crossing is not traversed here); upstream Reedhaven/Brine Steps dock facts
## are pre-set. Solo host only; the co-op split is covered by the rule tests.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CANDY := "water:gull_rest:pickup:002"
const LEAD := "water_claim:local:gull_research:lead"
const SATCHEL := "water_claim:local:gull_research:satchel"
const DONE := "water_claim:local:gull_research:complete"

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

func gull_entry(reader: RefCounted) -> Dictionary:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains("Gull Rest"):
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

func candy_row() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.pickups:
		if str(row.id) == CANDY:
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
	game.local.character_id = "water-gull-research"
	for upstream: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired"]:
		game.world.flags.set_flag(upstream)
	game.local.flags.set_flag("water_swim_lesson_briefed")
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
	var chains: Node = world.get_node("WaterLocalChains")
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var site: Node3D = chains.call("site_root", "gull_research_satchel")
	if not check(site != null, "Satchel site built on Gull Rest terrain"):
		finish()
		return
	var prompt: Node = site.get_node("Prompt")
	check(not site.visible and not bool(prompt.get("enabled")), "Satchel hidden and unoffered before Adair's lead")
	check(gull_entry(reader).is_empty(), "Gull Rest request not pre-labelled")

	# Step 1: Adair names Gull Rest.
	var heard: Array = await hear("water_adair")
	check(heard[0] == "water_adair_gull_lead", "Adair gives the Gull Rest lead (%s)" % heard[0])
	check(str(heard[1]).contains("Gull Rest") and str(heard[1]).contains("satchel"), "Lead names the island and the satchel")
	check(landmark_stands("gull_rest_signal_spire"), "Gull Rest's signal spire is an authored landmark standing above the water")
	check(game.world.flags.has(LEAD), "Lead recorded through the host step")
	check(str(heard[2]).contains("Gull Rest"), "Lead message shown: " + str(heard[2]))
	var entry := gull_entry(reader)
	check(not entry.is_empty() and not bool(entry.done), "Lead reveals the open request")
	await frames(2)
	check(site.visible and bool(prompt.get("enabled")), "Satchel appears and is offered after the lead")
	heard = await hear("water_adair")
	check(heard[0] == "water_adair_gull_reminder", "Open lead: Adair reminds (%s)" % heard[0])
	var early: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "gull_research_report", "inventory": {}})
	check(str(early.get("code", "")) == "prerequisite", "Report refused before the satchel (%s)" % str(early.get("code", "")))
	var remote: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "gull_research_satchel", "inventory": {}})
	check(str(remote.get("code", "")) == "too_far", "Satchel cannot be recorded from Brine Steps (%s)" % str(remote.get("code", "")))

	# Step 2: the satchel at Gull Rest, through its real prompt.
	pose(site.global_position + Vector3(1.5, 0.0, 0.0))
	await frames()
	var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
	check(not offer.is_empty(), "Satchel prompt offers itself beside the prop: " + str(offer))
	game.take_pending_world_message()
	prompt.call("interaction_activate")
	var satchel_message: String = game.take_pending_world_message()
	await frames()
	check(game.world.flags.has(SATCHEL), "Satchel recorded as a world quest record")
	check(satchel_message.contains("Brine Steps"), "Satchel message points home: " + satchel_message)
	check(not site.visible and not bool(prompt.get("enabled")), "Recovered satchel leaves the slope")
	check(game.inventory.count("research_satchel") == 0, "No satchel inventory object")
	check(not bool(gull_entry(reader).done), "Satchel alone does not finish the request")

	# The pocket's existing Candy II pays through its own receipt.
	var row := candy_row()
	pose(Vector3(float(row.position[0]), 0.0, float(row.position[2])) + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	var candy: Node = pickups.call("node_for", CANDY)
	check(candy != null, "Candy II streams in at gull_research_satchel")
	var before := int(game.inventory.count("skill_candy_ii"))
	if candy != null:
		candy.call("_on_picked_up")
		await frames()
	check(int(game.inventory.count("skill_candy_ii")) == before + 1, "Production claim pays one Candy II")

	# Step 3: return the observations on the next Brine Steps passage.
	heard = await hear("water_adair")
	check(heard[0] == "water_adair_gull_return", "Adair takes the observations (%s)" % heard[0])
	check(game.world.flags.has(DONE), "Report records the chain completion")
	check(str(heard[2]).contains("safe"), "Charted-route message shown: " + str(heard[2]))
	check(int(game.inventory.count("skill_candy_ii")) == before + 1, "Report grants no extra item")
	entry = gull_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Report completes the request")
	heard = await hear("water_adair")
	check(heard[0] == "water_adair_gull_thanks", "Adair acknowledges the charted route (%s)" % heard[0])
	check(str(heard[1]).contains("Gull Rest route is charted"), "Delivered thanks names the charted Gull Rest route")
	finish()

func finish() -> void:
	finished = true
	print("Water Gull research smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
