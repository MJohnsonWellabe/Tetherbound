extends SceneTree

## F13 `side_water_lastlight_shelter` in the production Water scene: Halen
## reveals the sheltered way beside Lastlight -> deliver 4 driftwood + 4 reed
## fiber at the Veilfall landing camp -> rest one companion in that camp's
## creature bed -> Halen's acknowledgement.
##
## Real: production water_archipelago world, WaterNPCs + DialoguePanel speech
## (Halen's lead, reminder, rest request and thanks), WaterChapter routing,
## WaterLocalChains' delivery prop/prompt (inventory proof, host debit) and its
## rest watcher over this peer's real party, the `water_dock_action` intent
## through the host LedgerRPC and water_local_chain_rules, WaterCamps' real
## Veilfall creature bed, and the quest log.
## Disclosed fixtures: player poses are teleports; the delivered driftwood and
## reed fiber are added to the satchel directly (not gathered here); the
## companion is put to rest by calling the production bed's
## `assign_creature()` (the bed panel UI is not driven); if the reset party is
## empty, one Brooktail is spawned into it. Solo host only.
## Saved completion: the finished chain is written through Game.save_game,
## the world destroyed, Game reset and reloaded through Game.load_game into a
## rebuilt production Water world (tests/helpers/water_chain_reload.gd).
## Lure: Lastlight is an authored water_world.json landmark on dry ground
## with WaterLocalChains' lamp post standing at it.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RELOAD := preload("res://tests/helpers/water_chain_reload.gd")
const LEAD := "water_claim:local:lastlight_shelter:lead"
const SUPPLIED := "water_claim:local:lastlight_shelter:supplied"
const RESTED := "water_claim:local:lastlight_shelter:rested"

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

func shelter_entry(reader: RefCounted) -> Dictionary:
	for entry: Dictionary in reader.local_entries(game.progression):
		if str(entry.label).contains("Lastlight"):
			return entry
	return {}

## The authored landmark the lead names: listed in the production world config,
## standing on dry terrain above the waterline (a data/terrain check only; the
## rendered read from the approach is ralph/reports/TIDEWAKE/f13_local_chains/lastlight.png).
func landmark_stands(landmark_id: String) -> bool:
	for raw: Dictionary in world.config.get("landmarks", []):
		if str(raw.get("id", "")) != landmark_id:
			continue
		var at := Vector3(float(raw.position[0]), 0.0, float(raw.position[2]))
		return float(world.ground_height_at(at.x, at.z)) > 1.0 and is_zero_approx(world.water_depth_at(at))
	return false

## Lastlight's lamp post stands in the scene at its landmark, grounded, lit,
## and clear of the delivery and bed prompts it frames.
func lamp_post_stands(chains: Node, site: Node3D) -> bool:
	var at: Vector2 = chains.call("landmark_xz", "lastlight")
	var lamp: Node3D = chains.call("landmark_root", "lastlight")
	if not at.is_finite() or lamp == null or not lamp.is_visible_in_tree():
		return false
	var post := lamp.get_node_or_null("LampPost") as MeshInstance3D
	var lantern := lamp.get_node_or_null("Lantern") as Node3D
	var ground := float(world.ground_height_at(at.x, at.y))
	var bed: Node3D = world.get_node("WaterCamps").get_node_or_null("water_camp_veilfall_creature_bed")
	var lamp_xz := Vector2(lamp.global_position.x, lamp.global_position.z)
	return post != null and lantern != null and lamp.get_node_or_null("WarmLight") != null \
		and lamp_xz.distance_to(at) < 0.05 and absf(lamp.global_position.y - ground) < 0.05 \
		and lantern.global_position.y > ground + 2.0 \
		and lamp_xz.distance_to(Vector2(site.global_position.x, site.global_position.z)) > 4.8 \
		and bed != null and lamp_xz.distance_to(Vector2(bed.global_position.x, bed.global_position.z)) > 4.8

func run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "240 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-lastlight-shelter"
	RELOAD.isolate(game, "water_lastlight_shelter")
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
	var chains: Node = world.get_node("WaterLocalChains")
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var site: Node3D = chains.call("site_root", "lastlight_shelter_supply")
	if not check(site != null, "Delivery site built at the Veilfall camp"):
		finish()
		return
	var prompt: Node = site.get_node("Prompt")
	var built: Node3D = site.get_node_or_null("Built")
	check(built != null, "Shelter piece prepared over the camp bed")
	check(not site.visible and not bool(prompt.get("enabled")), "Nothing offered before Halen's lead")
	check(shelter_entry(reader).is_empty(), "Shelter request not pre-labelled")
	var interior_before: Array = []
	for flag: String in ["water_veilfall_intake_stopped", "water_veilfall_return_opened", "water_captain_nerissa_defeated"]:
		interior_before.append(game.world.flags.has(flag))

	# Step 1: Halen reveals the sheltered way and the request.
	var heard: Array = await hear("water_halen")
	check(heard[0] == "water_halen_shelter_lead", "Halen gives the shelter lead (%s)" % heard[0])
	check(str(heard[1]).contains("Lastlight") and str(heard[1]).contains("4 driftwood"), "Lead names Lastlight and the delivery")
	check(landmark_stands("lastlight"), "Lastlight is an authored landmark standing on dry ground above the water")
	check(lamp_post_stands(chains, site), "Lastlight's lamp post stands in the scene at its landmark, clear of the camp prompts")
	check(game.world.flags.has(LEAD), "Lead recorded through the host step")
	var entry := shelter_entry(reader)
	check(not entry.is_empty() and not bool(entry.done), "Lead reveals the open request")
	await frames(2)
	check(site.visible and bool(prompt.get("enabled")) and not built.visible, "Delivery offered; shelter not yet built")
	heard = await hear("water_halen")
	check(heard[0] == "water_halen_shelter_reminder", "Open delivery: reminder (%s)" % heard[0])

	# Step 2: deliver at the camp through the real prompt.
	pose(site.global_position + Vector3(0.0, 0.0, -1.5))
	await frames()
	check(game.inventory.add("driftwood", 4) == 0 and game.inventory.add("reed_fiber", 3) == 0, "Disclosed material fixture")
	game.take_pending_world_message()
	prompt.call("interaction_activate")
	var short: String = game.take_pending_world_message()
	await frames()
	check(not game.world.flags.has(SUPPLIED), "Short delivery refused")
	check(short.contains("4 reed fiber"), "Refusal names the delivery: " + short)
	check(int(game.inventory.count("driftwood")) == 4 and int(game.inventory.count("reed_fiber")) == 3, "Refusal debits nothing")
	check(game.inventory.add("reed_fiber", 1) == 0, "One more reed fiber")
	prompt.call("interaction_activate")
	var supplied: String = game.take_pending_world_message()
	await frames()
	check(game.world.flags.has(SUPPLIED), "Delivery recorded")
	check(int(game.inventory.count("driftwood")) == 0 and int(game.inventory.count("reed_fiber")) == 0, "Host debited exactly 4 + 4")
	check(supplied.contains("sheltered"), "Delivery message shown: " + supplied)
	check(built.visible and not bool(prompt.get("enabled")), "The shelter stands; the delivery is closed")
	heard = await hear("water_halen")
	check(heard[0] == "water_halen_shelter_rest", "Halen asks for a companion to rest there (%s)" % heard[0])

	# Step 3: one companion rests in the camp's own creature bed.
	var bed: Node = world.get_node("WaterCamps").get_node_or_null("water_camp_veilfall_creature_bed")
	if not check(bed != null, "Veilfall camp creature bed exists"):
		finish()
		return
	if game.local.party.size() == 0:
		check(game.local.party.add(SPECIES.spawn("brooktail")), "Disclosed companion fixture")
	player.global_position = (bed as Node3D).global_position + Vector3(1.2, 0.1, 0.0)
	player.velocity = Vector3.ZERO
	await frames()
	game.take_pending_world_message()
	check(bool(bed.call("assign_creature", 0)), "Production bed takes the companion")
	var rest_message := ""
	for attempt in 90:
		await process_frame
		var shown: String = game.take_pending_world_message()
		if not shown.is_empty():
			rest_message = shown
		if game.world.flags.has(RESTED):
			break
	check(game.world.flags.has(RESTED), "Rest in the sheltered bed recorded")
	check(rest_message.contains("sheltered bed"), "Rest message shown: " + rest_message)
	entry = shelter_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Rest completes the request")
	heard = await hear("water_halen")
	check(heard[0] == "water_halen_shelter_thanks", "Halen acknowledges (%s)" % heard[0])
	check(str(heard[1]).contains("stays sheltered for everyone"), "Delivered thanks acknowledges the permanent shared shelter")
	check(built.visible, "The shelter still stands after the acknowledgement")
	var interior_after: Array = []
	for flag: String in ["water_veilfall_intake_stopped", "water_veilfall_return_opened", "water_captain_nerissa_defeated"]:
		interior_after.append(game.world.flags.has(flag))
	check(interior_after == interior_before, "The chain opened nothing inside the Veilfall")

	# Saved completion: production save -> fresh state -> production load ->
	# a rebuilt Water world. World half: lead/supplied/rested records (the
	# shelter is world-visible); character half: the debited satchel and the
	# resting companion.
	var reloaded: Dictionary = await RELOAD.save_and_reload(self, game, world, RESTED, "")
	for pair: Array in reloaded.checks:
		check(pair[0], pair[1])
	if reloaded.world == null:
		finish()
		return
	world = reloaded.world
	player = world.get_node("Player")
	player.set_physics_process(false)
	chains = world.get_node("WaterLocalChains")
	for flag: String in [LEAD, SUPPLIED, RESTED]:
		check(game.world.flags.has(flag), "Reload keeps " + flag)
	check(int(game.inventory.count("driftwood")) == 0 and int(game.inventory.count("reed_fiber")) == 0,
		"Reload keeps the delivery debited (no materials returned)")
	entry = shelter_entry(reader)
	check(not entry.is_empty() and bool(entry.done), "Reloaded quest log shows the request done")
	site = chains.call("site_root", "lastlight_shelter_supply")
	check(site != null, "Delivery site rebuilt at the Veilfall camp")
	if site != null:
		built = site.get_node_or_null("Built")
		await frames(2)
		check(site.visible and built != null and built.visible, "The shelter still stands over the bed after reload")
		check(not bool(site.get_node("Prompt").get("enabled")), "The delivery stays closed after reload")
		check(lamp_post_stands(chains, site), "Lastlight still stands after reload")
		pose(site.global_position + Vector3(0.0, 0.0, -1.5))
		await frames()
		var again: Dictionary = game.ledger.submit({"kind": "water_dock_action", "realm": "water",
			"action_id": "lastlight_shelter_supply", "inventory": {"driftwood": 4, "reed_fiber": 4}})
		check(str(again.get("code", "")) == "already_done", "Reloaded host refuses a second delivery at the camp (%s)" % str(again.get("code", "")))
	heard = await hear("water_halen")
	check(heard[0] == "water_halen_shelter_thanks", "Reloaded Halen acknowledges, no re-offer (%s)" % heard[0])
	finish()

func finish() -> void:
	finished = true
	print("Water Lastlight shelter smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
