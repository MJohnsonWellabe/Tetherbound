extends SceneTree

## A disclosed post-Nerissa/current-restoration fixture. The dock exchange
## itself uses the shipping NPC, prompt, dialogue, authority and save writer.
## No Stormwood outcome is supplied, so this chapter cannot offer credits.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
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
	var dock_position_before: Vector3 = chapter.get("_dock_prompt").global_position
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
	if not proof.check(chapter.get("_dock_prompt").global_position.distance_to(dock_position_before) < 0.001,
		"dock action stays anchored while Mara turns to the approaching player"): finish(); return
	# Mara and the departure prompt are adjacent. A generic 2.5m approach
	# can leave Mara nearer; walk to this provider before checking the arbiter.
	var dock: Node3D = chapter.get("_dock_prompt")
	var player := game.call("find_player") as CharacterBody3D
	var recoveries_before := int(player.get("_unstick_count"))
	var navigator := preload("res://tests/helpers/stick_navigator.gd").new(self, player,
		current_scene.get_node("CameraRig"), Callable(travel, "_stick"))
	var near_dock: bool = await navigator.walk_to(dock.global_position, 1200, 0.6)
	travel.call("_stick", 0, 0)
	if not proof.check(near_dock and int(player.get("_unstick_count")) == recoveries_before,
		"ordinary capsule walk selects the adjacent dock provider"): finish(); return
	if not await travel.activate(chapter.get("_dock_prompt")):
		proof.failures.append_array(travel.failures); finish(); return
	var receipt := "craft:water_dock_departure:" + str(game.local.character_id)
	# A journaled world conclusion precedes the deferred personal bool write.
	# Wait for BOTH real sides; the shared flag alone is not an owner ACK.
	deadline = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.world.flags.call("has", "water_civilian_departure_complete") \
			and game.local.redesign_character.transaction_receipts.has(receipt): break
	if not game.local.redesign_character.transaction_receipts.has(receipt):
		var record := preload("res://scripts/net/character_record_rules.gd")
		var current: Dictionary = record.portable_projection(game.local.call("save_data"))
		for row: Dictionary in game.world.reward_deliveries.values():
			if row.get("receipt") != receipt: continue
			var plan: Dictionary = preload("res://scripts/net/character_action_delivery.gd").owner_plan(current, row, record.errors)
			var changed: Array[String] = []
			for key: String in current:
				if not preload("res://scripts/creatures/essence.gd")._equivalent(current[key], row.before.get(key)): changed.append(key)
			print("F20 DOCK OWNER TRACE status=", row.status, " pure_plan_code=", plan.get("code", "ok"), " changed_baseline_fields=", changed)
			for index: int in mini(current.party.size(), row.before.party.size()):
				for field: String in current.party[index]:
					var live: Variant = current.party[index][field]
					var frozen: Variant = row.before.party[index].get(field)
					if not preload("res://scripts/creatures/essence.gd")._equivalent(live, frozen):
						print("F20 DOCK OWNER EXACT party/", index, "/", field, " live=", live, " frozen=", frozen,
							" live_variant_hex=", var_to_bytes(live).hex_encode(), " frozen_variant_hex=", var_to_bytes(frozen).hex_encode())
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
