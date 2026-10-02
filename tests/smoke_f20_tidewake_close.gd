extends SceneTree

## A disclosed post-Nerissa/current-restoration fixture. The dock exchange
## itself uses the shipping NPC, prompt, dialogue, authority and save writer.
## No Stormwood outcome is supplied, so this chapter cannot offer credits.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
var proof := PROOF.new()

func _init() -> void: _run.call_deferred()

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	if not proof.fixture(game, "Tidewake"): finish(); return
	for flag: String in ["stormwood:legendary_ceremony_settled", "stormwood:regional_outcome:f20_fixture:refused",
		"stormwood:legendary_answer:f20_fixture:refused"]: game.local.flags.call("set_flag", flag, false)
	game.world.flags.call("set_flag", HOME.WORLD_FLAG, false)
	game.set("current_realm", "water")
	game.local.set("realm", "water")
	if change_scene_to_file("res://scenes/world/water_archipelago.tscn") != OK:
		proof.check(false, "production Tidewake loads"); finish(); return
	var deadline := Time.get_ticks_msec() + 180000
	var chapter: Node
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") and current_scene.call("shell_build_complete"):
			chapter = current_scene.get_node_or_null("WaterChapter")
			if chapter != null and chapter.get("npc_bodies").has("water_mara"): break
	if not proof.check(chapter != null, "Tidewake chapter and actual Mara are ready"): finish(); return
	var mara: Node3D = chapter.get("npc_bodies").get("water_mara")
	var travel := TRAVEL.new(self, game)
	if not await travel.activate(mara.call("prompt_node")):
		proof.failures.append_array(travel.failures); finish(); return
	var panel: Node = current_scene.get_node("DialoguePanel")
	var heard := ""
	deadline = Time.get_ticks_msec() + 30000
	while panel.call("is_open") and Time.get_ticks_msec() < deadline:
		if not proof.check(panel.call("runner").call("conversation_id") == "water_mara_post", "actual restored-current dock afterword is selected"): finish(); return
		heard += "\n" + str(panel.get("_body").text)
		await travel.tap("interact")
	for frame in 12: await process_frame
	if not proof.check(not heard.is_empty() and chapter.call("dock_departure_ready"), "natural dock afterword makes civilian departure ready"): finish(); return
	if not await travel.activate(chapter.get("_dock_prompt")):
		proof.failures.append_array(travel.failures); finish(); return
	for frame in 600:
		await process_frame
		if game.world.flags.call("has", "water_civilian_departure_complete"): break
	var receipt := "craft:water_dock_departure:" + str(game.local.character_id)
	proof.check(game.world.flags.call("has", "water_civilian_departure_complete") \
		and game.local.redesign_character.transaction_receipts.has(receipt), "dock closes Tidewake with its own saved character and world conclusion")
	proof.check(HOME.journey_context(game).is_empty() and not HOME.credits_pending(game), "Tidewake conclusion offers no homecoming or credits")
	for node: Node in get_nodes_in_group("story_modal"):
		proof.check(node.get_script() != load("res://scripts/ui/regional_credits.gd") or not node.call("is_open"), "no credits screen opened at the dock")
	proof.check(game.call("save_game", 0), "Tidewake chapter conclusion persists through production save")
	finish()

func finish() -> void:
	for failure: String in proof.failures: print("F20 FAIL ", failure)
	print("F20 TIDEWAKE: %d checks, %d failures; disclosed restored-current fixture then actual dock exchange" % [proof.checks, proof.failures.size()])
	quit(0 if proof.failures.is_empty() else 1)
