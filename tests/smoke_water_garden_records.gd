extends SceneTree

## F13 `side_water_garden_records` in the production Water scene: Edda points
## to the visible above-water Drowned Garden vault -> copy the vault wall's
## account at its prompt -> bring it back to Edda at Salt Crown, who explains
## the pre-Tether dock history; the vault's Candy II pays on its own receipt.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech,
## Edda's greet prompt routed through the Guardian participant gate
## (water_guardian_reward.gd), WaterChapter routing, WaterLocalChains' vault
## wall prop and Interact prompt, the `water_dock_action` intent through the
## host LedgerRPC and water_local_chain_rules, WaterPickups' production Candy II
## claim and the quest log.
## Disclosed fixtures: player poses are teleports (the Salt Crown -> Drowned
## Garden crossing is not traversed); the report is heard after pre-set
## `water_guardian_freed` and this character's own offer marker (it already
## answered), to prove the chain outranks Edda's post-freeing neutral line.
## Solo host.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const CANDY := "water:drowned_garden:pickup:002"
const LEAD := "water_claim:local:garden_records:lead"
const ACCOUNT := "water_claim:local:garden_records:account"
const DONE := "water_claim:local:garden_records:complete"

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
	player.global_position = body.global_position + Vector3(1.0, 0.1, 0.0)
	player.velocity = Vector3.ZERO
	await frames()
	game.take_pending_world_message()
	# Greet through the speaker's real prompt: Edda's is routed by the Guardian
	# participant gate, which then starts the chosen conversation.
	body.call("prompt_node").emit_signal("activated")
	if not bool(panel.call("is_open")):
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

func garden_entry(reader: RefCounted) -> Dictionary:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains("Drowned Garden"):
			return entry
	return {}

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
	game.local.character_id = "water-garden-records"
	for upstream: String in ["water_dock_brine_steps_trial_won", "water_aquaryn_resolved"]:
		game.world.flags.set_flag(upstream)
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
	var wall: Node3D = chains.call("site_root", "garden_records_wall")
	if not check(wall != null, "Vault wall built on Drowned Garden terrain"):
		finish()
		return
	var prompt: Node = wall.get_node("Prompt")
	check(wall.visible and not bool(prompt.get("enabled")), "Vault wall visible as the lure, unoffered before Edda's lead")
	check(garden_entry(reader).is_empty(), "Garden request not pre-labelled")

	# Step 1: Edda points to the vault (greeted through her real prompt).
	var heard: Array = await hear("water_edda")
	check(heard[0] == "water_edda_garden_lead", "Edda gives the vault lead (%s)" % heard[0])
	check(str(heard[1]).contains("Drowned Garden") and str(heard[1]).contains("Tideglass Compass"), "Lead names the vault and keeps her relic guidance")
	check(game.world.flags.has(LEAD), "Lead recorded through the host step")
	var entry := garden_entry(reader)
	check(not entry.is_empty() and not bool(entry.done), "Lead reveals the open request")
	await frames(2)
	check(bool(prompt.get("enabled")), "Wall account offered after the lead")
	heard = await hear("water_edda")
	check(heard[0] == "water_edda_garden_reminder", "Open lead: reminder (%s)" % heard[0])

	# Step 2: copy the wall's account at the vault through its real prompt.
	pose(wall.global_position + Vector3(0.0, 0.0, 1.8))
	await frames()
	var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
	check(not offer.is_empty(), "Wall prompt offers itself beside the vault: " + str(offer))
	game.take_pending_world_message()
	prompt.call("interaction_activate")
	var copied: String = game.take_pending_world_message()
	await frames()
	check(game.world.flags.has(ACCOUNT), "Wall account recorded")
	check(copied.contains("Edda"), "Account message points home: " + copied)
	check(wall.visible and not bool(prompt.get("enabled")), "The vault wall stays; its prompt is done")

	# The vault's existing Candy II pays through its own receipt.
	var row := candy_row()
	pose(Vector3(float(row.position[0]), 0.0, float(row.position[2])) + Vector3(-1.0, 0.0, 0.0))
	await frames(2)
	await create_timer(0.7).timeout
	pickups.call("refresh")
	var candy: Node = pickups.call("node_for", CANDY)
	check(candy != null, "Candy II streams in at garden_exposed_vault")
	var before := int(game.inventory.count("skill_candy_ii"))
	if candy != null:
		candy.call("_on_picked_up")
		await frames()
	check(int(game.inventory.count("skill_candy_ii")) == before + 1, "Production claim pays one Candy II")

	# Step 3 after the Guardian's freeing, for a character who has already
	# answered its offer: the chain report outranks Edda's neutral line.
	game.world.flags.set_flag("water_guardian_freed")
	game.world.flags.set_flag(REWARD.offered_flag(game.local.character_id))
	heard = await hear("water_edda")
	check(heard[0] == "water_edda_garden_return", "Edda hears the account (%s)" % heard[0])
	check(str(heard[1]).contains("dock") and str(heard[1]).contains("Tether"), "Edda explains pre-Tether dock history")
	check(game.world.flags.has(DONE), "Report records the chain completion")
	check(int(game.inventory.count("skill_candy_ii")) == before + 1, "Report grants no extra item")
	entry = garden_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Report completes the request")
	heard = await hear("water_edda")
	check(heard[0] == "water_edda_guardian_neutral", "Afterwards the Guardian gate speaks again (%s)" % heard[0])
	finish()

func finish() -> void:
	finished = true
	print("Water Garden records smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
