extends SceneTree

## F13 `side_water_cradle_care` in the production Water scene: Otto points to
## `cradle_shell_nest` -> mine the nest's 4 Reef Stone -> return to Otto with
## an owned swimmer (or after Aquaryn's trial is settled) for 3 berries, once,
## and the alternate-swimmer habitat lead.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech
## (Otto's lead, reminder, wait, return and thanks), WaterChapter routing,
## WaterLocalChains submitting the `water_dock_action` intent with this peer's
## real party species as proof, the host LedgerRPC + water_local_chain_rules
## arbitration and grant, WaterPickups' production Reef Stone seam, quest log.
## Disclosed fixtures: player poses are teleports; the seam is gathered by
## calling its production `gather("pickaxe")` with a pickaxe added to the
## satchel (the held-tool hotbar walk is
## tests/smoke_water_pocket_walk_claim.gd's Cradle leg); the owned Mosshell is
## added to the real party with CreatureSpecies.spawn (not caught here).
## Solo host only; the co-op split is covered by the rule unit tests.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SEAM_ROW := "water:tidal_cradle:harvest:007"
const SEAM := "harvest_node:order:water:tidal_cradle:harvest:007"
const LEAD := "water_claim:local:cradle_care:lead"
const DONE := "water_claim:local:cradle_care:complete"

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
	# Beside the speaker at its own height: Otto stands on a steep slope, where
	# a ground-snapped pose 2 m away can sit several metres below him.
	player.global_position = body.global_position + Vector3(1.0, 0.1, 0.0)
	player.velocity = Vector3.ZERO
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

func nest_entry(reader: RefCounted) -> Dictionary:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains("shell nest"):
			return entry
	return {}

func seam_row() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.harvest:
		if str(row.id) == SEAM_ROW:
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
	game.local.character_id = "water-cradle-care"
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
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	check(nest_entry(reader).is_empty(), "Nest request not pre-labelled")
	check(not game.world.flags.has("water_aquaryn_resolved"), "Aquaryn's trial is unsettled for this run")

	# Step 1: Otto points to the nest.
	var heard: Array = await hear("water_otto")
	check(heard[0] == "water_otto_nest_lead", "Otto gives the nest lead (%s)" % heard[0])
	check(str(heard[1]).contains("nest") and str(heard[1]).contains("Reef Stone"), "Lead names the nest and its stone")
	check(game.world.flags.has(LEAD), "Lead recorded through the host step")
	var entry := nest_entry(reader)
	check(not entry.is_empty() and not bool(entry.done), "Lead reveals the open request")
	heard = await hear("water_otto")
	check(heard[0] == "water_otto_nest_reminder", "Open lead: reminder (%s)" % heard[0])

	# Step 2: the nest's own world-once Reef Stone seam.
	var row := seam_row()
	pose(Vector3(float(row.position[0]), 0.0, float(row.position[2])) + Vector3(1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	var seam: Node = pickups.call("node_for", SEAM_ROW)
	check(seam != null, "Reef Stone seam streams in at the shell nest")
	var stone_before := int(game.inventory.count("reef_stone"))
	check(game.inventory.add("pickaxe", 1) == 0, "Disclosed carried pickaxe fixture")
	if seam != null:
		seam.call("gather", "pickaxe")
		await frames(4)
	check(int(game.inventory.count("reef_stone")) == stone_before + 4, "The nest pays 4 Reef Stone to the gatherer")
	check(game.world.flags.has(SEAM), "Seam recorded world-once")

	# No swimmer and the trial unsettled: Otto waits and the host refuses.
	var berries_before := int(game.inventory.count("berries"))
	heard = await hear("water_otto")
	check(heard[0] == "water_otto_nest_wait", "No swimmer yet: Otto waits (%s)" % heard[0])
	check(not str(heard[1]).contains("catch Aquaryn"), "Otto never asks for Aquaryn")
	var refused: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "cradle_care_report", "inventory": {}, "party_species": []})
	check(str(refused.get("code", "")) == "swimmer", "Host refuses without a swimmer (%s)" % str(refused.get("code", "")))
	check(int(game.inventory.count("berries")) == berries_before, "No berries while refused")

	# Step 3: return with an owned swimmer (party proof from the real party).
	check(game.local.party.size() < 5, "Fixture party has room: no sixth-slot staging")
	check(game.local.party.add(SPECIES.spawn("water_mosshell")), "Owned Mosshell fixture joins the real party")
	heard = await hear("water_otto")
	check(heard[0] == "water_otto_nest_return", "Otto takes the report (%s)" % heard[0])
	for swimmer: String in ["Mosshell", "Riverdrake", "Sirenseal"]:
		check(str(heard[1]).contains(swimmer), "Habitat lead names " + swimmer)
	check(game.world.flags.has(DONE), "Return records the chain completion")
	check(int(game.inventory.count("berries")) == berries_before + 3, "Return pays exactly 3 berries")
	check(int(game.inventory.count("reef_stone")) == stone_before + 4, "Reef Stone stays with the player, not paid again")
	check(str(heard[2]).contains("berries"), "Payout message shown: " + str(heard[2]))
	entry = nest_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Return completes the request")
	var again: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
		"action_id": "cradle_care_report", "inventory": {}, "party_species": ["water_mosshell"]})
	check(str(again.get("code", "")) == "already_done", "Berries are paid once")
	check(int(game.inventory.count("berries")) == berries_before + 3, "Still exactly 3 berries")
	heard = await hear("water_otto")
	check(heard[0] == "water_otto_nest_thanks", "Otto acknowledges afterwards (%s)" % heard[0])
	check(str(heard[1]).contains("Mosshell on Tidal Cradle") and str(heard[1]).contains("saddle"), "Delivered thanks repeats the habitat lead and the stone's use")
	finish()

func finish() -> void:
	finished = true
	print("Water Cradle care smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
