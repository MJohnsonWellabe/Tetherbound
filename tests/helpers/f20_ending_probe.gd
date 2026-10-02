extends RefCounted

## Disclosed post-finale setup only. Everything after setup uses production
## Game/Session, the real world, input, durable writers and UI. This cannot
## establish an earned campaign win or replace F19/F49's journey evidence.
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var checks := 0
var _heard := ""

func check(value: bool, message: String) -> bool:
	checks += 1
	print("F20 ", "PASS " if value else "FAIL ", message)
	if not value: failures.append(message)
	return value

func fixture(game: Node, label: String) -> bool:
	game.call("reset_for_new_game")
	game.set("save_system", SAVE.new("user://f20_actual_%s_%d" % [label, OS.get_process_id()]))
	if not check(game.call("save_game", 0), "fixture has a real saved stable character"): return false
	for flag: String in ["opening:starter_granted", "opening:beat:free_play", "legendary_refused",
		"water:legendary_refused", "cloudreach:legendary_refused", "stormwood:legendary_ceremony_settled",
		"stormwood:regional_outcome:f20_fixture:refused", "stormwood:legendary_answer:f20_fixture:refused"]:
		game.local.flags.call("set_flag", flag)
	for flag: String in [HOME.WORLD_FLAG, "stormwood:long_storm_ended", "water_currents_restored", "old_champion_met"]:
		game.progression.call("set_flag", flag)
	for index in 5:
		var species: String = ["terrapup", "brooktail", "mosshell", "bramblebun", "trailpup"][index]
		var companion: RefCounted = game.local.call("make_creature", species, label + str(index + 1))
		if not check(companion != null and game.party.call("add", companion), "fixture current companion " + species): return false
		companion.set("battles_fought", 4 + index)
	var personal: Dictionary = game.local.redesign_character
	personal.transaction_receipts.append("starter_choice:%s:%s" % [game.local.character_id, game.party.call("at", 0).uid])
	personal.portal_unlocks = ["tidewake", "cloudreach", "stormwood"]
	game.local.inventory.call("add", "home_key", 1)
	game.local.inventory.call("add", "fifth_portal_key", 1)
	game.local.inventory.call("add", "potion_small", 3)
	# Negative control: this perfectly valid older return must not satisfy F20.
	personal.transaction_receipts.append("craft:home_return_%s_before_finale:%s" % [game.world.reward_delivery_namespace, game.local.character_id])
	return check(game.call("save_game", 0), "post-finale fixture saves through production schema")

func ready(tree: SceneTree, game: Node) -> bool:
	var deadline := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline:
		await tree.physics_frame
		var scene := tree.current_scene
		var player := game.call("find_player") as CharacterBody3D
		if scene != null and scene.has_method("shell_build_complete") and scene.call("shell_build_complete") \
			and player != null and player.is_on_floor() and not HOME.journey_context(game).is_empty():
			return true
	return check(false, "production world and personal ending context become ready")

func ending(tree: SceneTree, game: Node, stir: bool = true) -> bool:
	if not await ready(tree, game): return false
	if not check(HOME.context(game).is_empty(), "older return cannot acknowledge homecoming"): return false
	var travel := TRAVEL.new(tree, game)
	if not await travel.home_key():
		failures.append_array(travel.failures); return false
	if not check(HOME.journey_context(game).get("durable_home_return") == true, "actual Home Key arrival saved an outcome-bound return"): return false
	if stir and not await fifth(tree, game, travel): return false
	if not await open_credits(tree, game) or not await finish_credits(tree, game): return false
	return check(HOME.context(game).get("regional_credits_seen") == true, "actual five, starter, memory and four choices lead to durable credits once")

func return_home(tree: SceneTree, game: Node) -> bool:
	if not await ready(tree, game): return false
	if not check(HOME.context(game).is_empty(), "earlier Home Key visits cannot acknowledge the finale"): return false
	var travel := TRAVEL.new(tree, game)
	if not await travel.home_key(): failures.append_array(travel.failures); return false
	return check(HOME.journey_context(game).get("durable_home_return") == true, "actual Home Key saved the personal finale return")

func open_credits(tree: SceneTree, game: Node) -> bool:
	if not await ready(tree, game): return false
	var travel := TRAVEL.new(tree, game)
	var prompt: Node3D
	for node: Node in tree.current_scene.find_children("*", "", true, false):
		if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa": prompt = node as Node3D
	var panel: Node = tree.current_scene.get_node_or_null("DialoguePanel")
	if not check(prompt != null and panel != null, "real Grandpa prompt and dialogue panel exist"): return false
	if not await travel.activate(prompt): failures.append_array(travel.failures); return false
	var expected := HOME.context(game)
	var first: bool = expected.get("homecoming_seen") != true
	var prose := HOME.substitutions(game)
	_heard = ""
	var opened := false
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if panel.call("is_open"):
			opened = true
			_heard += "\n" + str(panel.get("_body").text)
			await travel.tap("interact")
		elif HOME.context(game).get("homecoming_seen") == true: break
	if not check(opened and HOME.context(game).get("homecoming_seen") == true, "natural Grandpa completion receives durable personal acknowledgement"): return false
	if first:
		for companion: String in HOME.party_names(game.party):
			if not check(_heard.contains(companion), "Grandpa actually rendered " + companion): return false
		for field: String in ["starter_status", "bond_memory", "chapter_choices"]:
			if not check(not str(prose.get(field, "")).is_empty() and _heard.contains(str(prose[field])), "Grandpa rendered truthful " + field): return false
	var credits: Node
	for frame in 600:
		await tree.process_frame
		var owner := INPUT_OWNER.current(tree)
		if owner != null and owner.get_script() == load("res://scripts/ui/regional_credits.gd"):
			credits = owner; break
	return check(credits != null and credits.call("is_open"), "production credits own this player's input after acknowledgement")

func finish_credits(tree: SceneTree, game: Node) -> bool:
	var credits := INPUT_OWNER.current(tree)
	if not check(credits != null and credits.get_script() == load("res://scripts/ui/regional_credits.gd"), "Skip starts from actual open credits"): return false
	var acknowledgements: Array = []
	credits.connect("acknowledged", func(id: String) -> void: acknowledgements.append(id))
	var travel := TRAVEL.new(tree, game)
	var deadline := Time.get_ticks_msec() + 30000
	while float(credits.get("_elapsed")) < 0.3: await tree.process_frame
	await travel.tap("menu_cancel")
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if not credits.call("is_open") and HOME.context(game).get("regional_credits_seen") == true: break
	return check(not credits.call("is_open") and acknowledgements == [game.local.character_id] \
		and HOME.context(game).get("regional_credits_seen") == true, "Skip emitted exactly one durable acknowledgement for this character")

func fifth(tree: SceneTree, game: Node, travel: RefCounted = null) -> bool:
	if travel == null: travel = TRAVEL.new(tree, game)
	var arch: Node3D
	for hall: Node in tree.get_nodes_in_group("crossing_halls"):
		if tree.current_scene.is_ancestor_of(hall): arch = hall.call("arch", "biome5")
	if not check(arch != null, "fifth arch exists in the actual Hall"): return false
	var messages: Array[String] = []
	var observer := func() -> void:
		var hud: Node = tree.current_scene.get_node_or_null("PlaygroundHUD")
		if hud != null:
			var label: Label = hud.get("_hotbar_message")
			if label != null and not messages.has(label.text): messages.append(label.text)
		var queued: String = game.get("_pending_world_message")
		if not queued.is_empty() and not messages.has(queued): messages.append(queued)
	tree.process_frame.connect(observer)
	var activated: bool = await travel.activate(arch.get_node("Interactable"))
	if not activated:
		tree.process_frame.disconnect(observer)
		failures.append_array(travel.failures); return false
	for frame in 600:
		await tree.process_frame
		if game.call("portal_view", "biome5").get("character_stirred") == true: break
	for frame in 8: await tree.process_frame
	tree.process_frame.disconnect(observer)
	var view: Dictionary = game.call("portal_view", "biome5")
	if not check(view.get("character_stirred") == true and view.get("open") == false \
		and game.local.inventory.call("count", "fifth_portal_key") == 0, "one real key consumed; fifth arch stays sealed"): return false
	if not check(arch.get("_stir_seen") == true and is_instance_valid(arch.get("_stir_light")) \
		and is_instance_valid(arch.get("_stir_audio")), "durable result creates glow and diegetic SFX source"): return false
	if not check(messages.has("It stirred, but it is not ready yet."), "actual key use emits the single not-ready line"): return false
	return check(not arch.call("use_key"), "second fifth-key use refuses after personal stir")

func retained(game: Node) -> Dictionary:
	var names := HOME.party_names(game.party)
	return {"character": game.local.character_id, "names": names,
		"receipts": game.local.redesign_character.transaction_receipts.duplicate(),
		"inventory": game.local.inventory.call("save_data"), "world": game.world.reward_delivery_namespace}

func resumed(tree: SceneTree, game: Node, before: Dictionary) -> bool:
	if not await ready(tree, game): return false
	var now := retained(game)
	if not check(now.character == before.character and now.names == before.names and now.world == before.world, "disk reload retains character, current five and host world"): return false
	for receipt: String in before.receipts:
		if not check(now.receipts.has(receipt), "disk retains " + receipt): return false
	if not check(now.inventory == before.inventory, "disk reload preserves inventory without duplicate rewards"): return false
	if not check(not HOME.credits_pending(game), "completed character cannot replay credits after reload"): return false
	var travel := TRAVEL.new(tree, game)
	var player := game.call("find_player") as CharacterBody3D
	var position_before := player.global_position
	travel.call("_stick", 0.0, -0.5)
	for frame in 30: await tree.physics_frame
	travel.call("_stick", 0.0, 0.0)
	if not check(player.is_on_floor() and player.global_position.distance_to(position_before) > 0.1 \
		and HOME.journey_context(game).get("regional_credits_seen") == true, "safe completed world returns ordinary movement"): return false
	return await continuation_content(tree, game)

func continuation_content(tree: SceneTree, game: Node) -> bool:
	var journal := preload("res://scripts/world/quest_log.gd").new(game)
	if not check(not journal.call("local_entries", game.progression).is_empty(), "actual journal keeps unfinished local activities after credits"): return false
	var rematches: Node = game.session.get_node_or_null("FoundationComposition/Rematches")
	if not check(rematches != null, "production rematch service remains mounted"): return false
	var available := 0
	for reference: WeakRef in rematches.get("_prompts").values():
		var prompt: Node = reference.get_ref()
		if prompt != null and prompt.get("label") == "Endgame rematch" and prompt.get("enabled") == true: available += 1
	if not check(available > 0, "saved credits enable actual endgame rematch prompts"): return false
	var adapter: Node = game.session.get_node_or_null("FoundationComposition/BountyInteraction")
	var prompt: Node3D = adapter.get("_prompt") if adapter != null else null
	if not check(prompt != null and prompt.is_inside_tree(), "actual morning bounty board remains mounted"): return false
	var travel := TRAVEL.new(tree, game)
	if not await travel.activate(prompt): failures.append_array(travel.failures); return false
	var panel := INPUT_OWNER.current(tree)
	if not check(panel != null and panel.get_script() == load("res://scripts/ui/bounty_board_panel.gd"), "ordinary board input opens the production bounty screen"): return false
	var view: Dictionary = adapter.call("view")
	if not check(view.get("ready") == true and view.get("rows", []).size() == 3,
		"reloaded character has three active bounties in the live board"): return false
	await travel.tap("menu_cancel")
	return check(INPUT_OWNER.current(tree) == null, "bounty screen returns ordinary world input")
