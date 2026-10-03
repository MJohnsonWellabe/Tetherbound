extends RefCounted

## Disclosed post-finale setup only. Everything after setup uses production
## Game/Session, the real world, input, durable writers and UI. This cannot
## establish an earned campaign win or replace F19/F49's journey evidence.
const HOME := preload("res://scripts/story/regional_homecoming.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var checks := 0
var _heard := ""
var _expected_choices: Array[String] = ["meadows:refused", "water:refused", "cloudreach:refused", "stormwood:refused"]

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
	if label == "Peer1":
		game.local.flags.call("set_flag", "water:legendary_refused", false)
		game.local.flags.call("set_flag", "water:legendary_joined")
		_expected_choices[1] = "water:accepted"
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
	if label == "Solo":
		# Disclosed post-finale clock setup: the actual host advances one morning.
		# The production board poll alone must issue and durably deliver its rows.
		if not check(game.call("advance_day") == 2 and int(game.world.redesign_world.bounty_day) == 1,
			"solo post-finale fixture has passed its first actual host morning"): return false
	return check(game.call("save_game", 0), "post-finale fixture saves through production schema")

func ready(tree: SceneTree, game: Node) -> bool:
	var began := Time.get_ticks_msec()
	var deadline := began + 180000
	var previous := began
	var samples := 0
	var max_wait_ms := 0
	while Time.get_ticks_msec() < deadline:
		await tree.physics_frame
		var now := Time.get_ticks_msec()
		max_wait_ms = maxi(max_wait_ms, now - previous)
		previous = now
		samples += 1
		var scene := tree.current_scene
		var player := game.call("find_player") as CharacterBody3D
		if scene != null and scene.has_method("shell_build_complete") and scene.call("shell_build_complete") \
			and player != null and player.is_on_floor() and not HOME.journey_context(game).is_empty():
			print("F20 READY elapsed_ms=", now - began, " physics_samples=", samples, " max_wait_ms=", max_wait_ms)
			return true
	var scene := tree.current_scene
	var player := game.call("find_player") as CharacterBody3D
	var owner := INPUT_OWNER.current(tree)
	print("F20 READY TIMEOUT elapsed_ms=", Time.get_ticks_msec() - began,
		" physics_samples=", samples, " max_wait_ms=", max_wait_ms,
		" scene=", scene.get_path() if scene != null else "none",
		" shell_complete=", scene.call("shell_build_complete") if scene != null and scene.has_method("shell_build_complete") else false,
		" player=", player.get_path() if player != null else "none",
		" floor=", player.is_on_floor() if player != null else false,
		" position=", player.global_position if player != null else Vector3.INF,
		" journey_empty=", HOME.journey_context(game).is_empty(),
		" paused=", tree.paused, " owner=", owner.get_path() if owner != null else "none")
	return check(false, "production world and personal ending context become ready")

func ending(tree: SceneTree, game: Node, stir: bool = true) -> bool:
	if not await ready(tree, game): return false
	# A resumed Stormwood may offer the shipping aftermath automatically.
	# Complete it through ordinary input before using the Home Key.
	var owner := INPUT_OWNER.current(tree)
	if owner != null:
		var deadline := Time.get_ticks_msec() + 30000
		var travel_after := TRAVEL.new(tree, game)
		while owner != null and Time.get_ticks_msec() < deadline:
			if not check(owner.get_script() == load("res://scripts/ui/dialogue_panel.gd") \
				and owner.call("runner").call("conversation_id") == "stormwood_homecoming_aftermath", "only the actual settled-finale aftermath owns input"): return false
			await travel_after.tap("interact")
			owner = INPUT_OWNER.current(tree)
		if not check(owner == null, "natural aftermath returns input for the Home Key"): return false
	if not check(HOME.context(game).is_empty(), "older return cannot acknowledge homecoming"): return false
	var travel := TRAVEL.new(tree, game)
	if not await traced_return(tree, game, travel):
		failures.append_array(travel.failures); return false
	if not check(HOME.journey_context(game).get("durable_home_return") == true, "actual Home Key arrival saved an outcome-bound return"): return false
	if stir and not await fifth(tree, game, travel): return false
	if not await open_credits(tree, game) or not await finish_credits(tree, game): return false
	return check(HOME.context(game).get("regional_credits_seen") == true, "actual five, starter, memory and four choices lead to durable credits once")

func return_home(tree: SceneTree, game: Node) -> bool:
	if not await ready(tree, game): return false
	if not check(HOME.context(game).is_empty(), "earlier Home Key visits cannot acknowledge the finale"): return false
	var travel := TRAVEL.new(tree, game)
	if not await traced_return(tree, game, travel): failures.append_array(travel.failures); return false
	return check(HOME.journey_context(game).get("durable_home_return") == true, "actual Home Key saved the personal finale return")

func traced_return(tree: SceneTree, game: Node, travel: RefCounted) -> bool:
	var timing := {"last": Time.get_ticks_msec(), "max_frame_ms": 0, "frames": 0}
	var frame_trace := func() -> void:
		var now := Time.get_ticks_msec()
		timing.max_frame_ms = maxi(timing.max_frame_ms, now - timing.last)
		timing.last = now
		timing.frames += 1
	var result_trace := func(result: Dictionary) -> void:
		if str(result.get("kind", "")).begins_with("home_key_"):
			print("F20 HOME TRACE ticks_ms=", Time.get_ticks_msec(), " frames=", timing.frames,
				" max_frame_ms=", timing.max_frame_ms, " result=", result)
			if result.get("reason") == "The arrival anchor is obstructed.": diagnose_home_anchor(tree, game)
	tree.process_frame.connect(frame_trace)
	game.connect("portal_action_result", result_trace)
	var passed: bool = await travel.home_key()
	game.disconnect("portal_action_result", result_trace)
	tree.process_frame.disconnect(frame_trace)
	return passed

## Read-only reproduction of the shipping arrival footprint for its owner.
## It reports real colliders; it never seats an actor or changes a permit.
func diagnose_home_anchor(tree: SceneTree, game: Node) -> void:
	var arrival: Node = game.session.get_node_or_null("FoundationComposition/PortalArrival")
	var player := game.call("find_player") as CharacterBody3D
	var world := tree.current_scene as Node3D
	if arrival == null or player == null or world == null or game.current_realm != "meadows": return
	var target: Vector3 = arrival.call("_arrival_target", world, {"realm": "meadows", "entry_id": "hall_home"})
	var terrain: float = arrival.call("_ground_height", world, target)
	var collision := player.get_node("Collision") as CollisionShape3D
	var height: float = arrival.call("_landing_height", world, player, target, (collision.shape as CapsuleShape3D).radius)
	if not is_finite(height):
		print("F20 HOME ANCHOR target=", target, " terrain_height=", terrain, " actual_floor=unsupported")
		return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.transform.origin += Vector3(target.x, height + player.safe_margin, target.z) - player.global_position
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var paths: Array[String] = []
	for hit: Dictionary in player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var body: Node = hit.collider
		paths.append(str(body.get_path()) + " class=" + body.get_class())
	print("F20 HOME ANCHOR target=", target, " terrain_height=", terrain, " actual_floor=", height, " capsule_transform=", query.transform,
		" capsule_shape=", query.shape, " safe_margin=", player.safe_margin, " collision_mask=", query.collision_mask,
		" actual_blockers=", paths)
	var ray := PhysicsRayQueryParameters3D.create(target + Vector3.UP * 2, target - Vector3.UP * 2,
		player.collision_mask, [player.get_rid()])
	var floor: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(ray)
	if not floor.is_empty():
		print("F20 HOME ANCHOR actual_surface=", floor.position, " normal=", floor.normal,
			" path=", floor.collider.get_path())

func approach_grandpa(tree: SceneTree, game: Node) -> bool:
	if not await ready(tree, game): return false
	var prompt: Node3D
	for node: Node in tree.current_scene.find_children("*", "", true, false):
		if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa": prompt = node as Node3D
	var panel: Node = tree.current_scene.get_node_or_null("DialoguePanel")
	if not check(prompt != null and panel != null and not panel.call("is_open"), "Grandpa approach starts with the actual closed panel"): return false
	var travel := TRAVEL.new(tree, game)
	if not await travel.approach_grandpa(prompt): failures.append_array(travel.failures); return false
	return check(not panel.call("is_open"), "ordinary Grandpa walk preserves the closed dialogue until normal X")

func open_credits(tree: SceneTree, game: Node) -> bool:
	if not await ready(tree, game): return false
	var travel := TRAVEL.new(tree, game)
	var prompt: Node3D
	for node: Node in tree.current_scene.find_children("*", "", true, false):
		if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa": prompt = node as Node3D
	var panel: Node = tree.current_scene.get_node_or_null("DialoguePanel")
	if not check(prompt != null and panel != null, "real Grandpa prompt and dialogue panel exist"): return false
	print("F20 TALK navigation start ticks_ms=", Time.get_ticks_msec(), " process=", Engine.get_process_frames(), " physics=", Engine.get_physics_frames())
	if not await travel.activate(prompt): failures.append_array(travel.failures); return false
	print("F20 TALK navigation complete ticks_ms=", Time.get_ticks_msec(), " process=", Engine.get_process_frames(), " physics=", Engine.get_physics_frames())
	var expected := HOME.context(game)
	var first: bool = expected.get("homecoming_seen") != true
	var prose := HOME.substitutions(game)
	if first:
		if not check(expected.get("chapter_choices") == _expected_choices \
			and expected.get("starter_uid") == game.party.call("at", 0).uid,
			"reader retains the fixture's own four decisions and actual first companion"): return false
		var first_companion: RefCounted = game.party.call("at", 0)
		# Ordinary travel may discover a landmark after the disclosed setup.
		# Check its actual retained count rather than requiring the old fixture
		# memory to override a newly earned one. No counter is set here.
		var landmarks := int(first_companion.get("landmarks_visited_together"))
		var battles := int(first_companion.get("battles_fought"))
		var memory_fact := "%d landmarks" % landmarks if landmarks > 0 else "%d battles" % battles
		if not check(battles >= 4 and str(prose.get("starter_status", "")).contains(HOME.party_names(game.party)[0]) \
			and str(prose.get("bond_memory", "")).contains(HOME.party_names(game.party)[0]) \
			and str(prose.get("bond_memory", "")).contains(memory_fact),
			"retained starter and actual landmark or battle count produce truthful prose"): return false
	_heard = ""
	var opened := false
	var completed: Array[String] = []
	var completion_observer := func(id: String) -> void:
		completed.append(id)
		print("F20 DIALOGUE completed id=", id)
	panel.connect("completed", completion_observer)
	print("F20 DIALOGUE start id=", panel.call("runner").call("conversation_id"), " expected=", expected)
	# A software-rendered/loaded world can spend the old total30s merely
	# drawing its authored lines. Bound actual input by that real line count
	# (plus the panel's initial guard), then observe the durable ACK separately.
	var line_count := int(panel.call("runner").call("_line_count"))
	var presses := 0
	travel.trace_input = true
	while panel.call("is_open") and presses < line_count + 2:
		opened = true
		_heard += "\n" + str(panel.get("_body").text)
		print("F20 TALK tap start index=", presses, " ticks_ms=", Time.get_ticks_msec())
		await travel.tap("interact")
		print("F20 TALK tap returned index=", presses, " ticks_ms=", Time.get_ticks_msec())
		presses += 1
	travel.trace_input = false
	print("F20 DIALOGUE input authored_lines=", line_count, " actual_presses=", presses)
	var deadline := Time.get_ticks_msec() + 30000
	while not panel.call("is_open") and HOME.context(game).get("homecoming_seen") != true \
			and Time.get_ticks_msec() < deadline: await tree.process_frame
	panel.disconnect("completed", completion_observer)
	var dialogue_owner := INPUT_OWNER.current(tree)
	var row: Dictionary = game.session.call("_owner_training_row")
	print("F20 DIALOGUE finish opened=", opened, " completed=", completed,
		" panel_open=", panel.call("is_open"), " id=", panel.call("runner").call("conversation_id"),
		" owner=", dialogue_owner.get_path() if dialogue_owner != null else "none",
		" owner_script=", dialogue_owner.get_script().resource_path if dialogue_owner != null and dialogue_owner.get_script() != null else "none",
		" context=", game.call("regional_ending_context"),
		" ack_intents=", game.get("_regional_ack_intents"),
		" training_action=", row.get("action", ""), " training_intent=", row.get("intent", {}),
		" notice=", game.get("_pending_world_message"))
	print("F20 DIALOGUE rendered ", _heard)
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
	while credits.call("is_open") and float(credits.get("_elapsed")) < 0.3 \
		and Time.get_ticks_msec() < deadline: await tree.process_frame
	if not check(credits.call("is_open") and float(credits.get("_elapsed")) >= 0.3,
		"actual credits remain open through their input guard"): return false
	await travel.tap("menu_cancel")
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		if not credits.call("is_open") and HOME.context(game).get("regional_credits_seen") == true: break
	return check(not credits.call("is_open") and acknowledgements == [game.local.character_id] \
		and HOME.context(game).get("regional_credits_seen") == true, "Skip emitted exactly one durable acknowledgement for this character")

func revisit_completed(tree: SceneTree, game: Node) -> bool:
	if not check(not HOME.credits_pending(game) and HOME.context(game).get("regional_credits_seen") == true,
		"completed character starts its revisit with saved credits acknowledged"): return false
	var receipts: Array = game.local.redesign_character.transaction_receipts.duplicate()
	var prompt: Node3D
	for node: Node in tree.current_scene.find_children("*", "", true, false):
		if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa": prompt = node as Node3D
	var panel: Node = tree.current_scene.get_node_or_null("DialoguePanel")
	if not check(prompt != null and panel != null, "completed revisit has the actual Grandpa prompt"): return false
	var travel := TRAVEL.new(tree, game)
	if not await travel.activate(prompt): failures.append_array(travel.failures); return false
	if not check(panel.call("is_open") and panel.call("runner").call("conversation_id") == HOME.REPEAT_ID,
		"ordinary Grandpa input selects the repeat conversation after credits"): return false
	var deadline := Time.get_ticks_msec() + 30000
	while panel.call("is_open") and Time.get_ticks_msec() < deadline: await travel.tap("interact")
	for frame in 8: await tree.process_frame
	var credits_open := false
	for node: Node in tree.get_nodes_in_group("story_modal"):
		if node.get_script() == load("res://scripts/ui/regional_credits.gd") and node.call("is_open"): credits_open = true
	return check(not panel.call("is_open") and not credits_open and INPUT_OWNER.current(tree) == null \
		and game.local.redesign_character.transaction_receipts == receipts,
		"natural repeat returns world input without credits or another personal receipt")

func fifth(tree: SceneTree, game: Node, travel: RefCounted = null) -> bool:
	if travel == null: travel = TRAVEL.new(tree, game)
	var arch: Node3D
	for candidate: Node in tree.get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == "biome5" and tree.current_scene.is_ancestor_of(candidate):
			arch = candidate as Node3D
	if not check(arch != null, "fifth arch exists in the actual Hall"): return false
	var journal := preload("res://scripts/world/quest_log.gd").new(game)
	journal.call("set_realm", "meadows")
	var quests_before: Array = journal.call("main_entries", game.progression).duplicate(true)
	var tracked_before: String = journal.call("tracked_text", game.progression)
	var moment := {"results": 0, "presented": false}
	# The actual arch subscribes in _ready, before this observer. Its durable
	# result creates the transient source; observe it on that real edge.
	var result_observer := func(result: Dictionary) -> void:
		if result.get("kind") != "portal_unlock" or result.get("arch_id") != "biome5" \
			or result.get("ok") != true or result.get("durable") != true: return
		moment.results += 1
		var light: OmniLight3D = arch.get("_stir_light")
		var sound: AudioStreamPlayer3D = arch.get("_stir_audio")
		moment.presented = arch.get("_stir_seen") == true and is_instance_valid(light) \
			and light.light_energy > float(arch.get("_stir_settings").resting_energy) \
			and is_instance_valid(sound) and sound.playing and sound.stream != null and sound.bus == "SFX"
	game.connect("portal_action_result", result_observer)
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
		game.disconnect("portal_action_result", result_observer)
		failures.append_array(travel.failures); return false
	for frame in 600:
		await tree.process_frame
		if game.call("portal_view", "biome5").get("character_stirred") == true: break
	for frame in 8: await tree.process_frame
	tree.process_frame.disconnect(observer)
	game.disconnect("portal_action_result", result_observer)
	var view: Dictionary = game.call("portal_view", "biome5")
	if not check(view.get("character_stirred") == true and view.get("open") == false \
		and game.local.inventory.call("count", "fifth_portal_key") == 0, "one real key consumed; fifth arch stays sealed"): return false
	if not check(moment.results == 1 and moment.presented, "one actual durable result creates bright glow and a playing diegetic SFX source"): return false
	if not check(messages.has("It stirred, but it is not ready yet."), "actual key use emits the single not-ready line"): return false
	if not check(journal.call("main_entries", game.progression) == quests_before \
		and journal.call("tracked_text", game.progression) == tracked_before,
		"fifth-key use adds no main quest or sequel objective"): return false
	return check(not arch.call("use_key"), "second fifth-key use refuses after personal stir")

func retained(game: Node) -> Dictionary:
	var names := HOME.party_names(game.party)
	var uids: Array[String] = []
	for companion: RefCounted in game.party.members(): uids.append(str(companion.get("uid")))
	# Inventory exposes slots, not save_data(). Read the same detached stack
	# array as the actual SaveGame writer, including empty slots and quantities.
	var inventory: Array = game.save_system.call("_inventory_to_array", game.local.inventory)
	return {"character": game.local.character_id, "names": names, "uids": uids,
		"receipts": game.local.redesign_character.transaction_receipts.duplicate(),
		"inventory": inventory.duplicate(true), "world": game.world.reward_delivery_namespace}

func retained_valid(value: Dictionary) -> bool:
	return value.get("character") is String and not str(value.character).is_empty() \
		and value.get("world") is String and not str(value.world).is_empty() \
		and value.get("names") is Array and value.names.size() > 0 and value.names.size() <= 5 \
		and value.get("uids") is Array and value.uids.size() == value.names.size() \
		and value.get("receipts") is Array and value.get("inventory") is Array and not value.inventory.is_empty()

func resumed(tree: SceneTree, game: Node, before: Dictionary) -> bool:
	if not check(retained_valid(before), "reload proof starts with a complete detached character snapshot"): return false
	if not await ready(tree, game): return false
	var now := retained(game)
	if not check(retained_valid(now), "reloaded character snapshot is complete"): return false
	if not check(now.character == before.character and now.names == before.names and now.uids == before.uids \
		and now.world == before.world, "disk reload retains character, current five identities and host world"): return false
	for receipt: String in before.receipts:
		if not check(now.receipts.has(receipt), "disk retains " + receipt): return false
	if not check(now.inventory == before.inventory, "disk reload preserves inventory without duplicate rewards"): return false
	if not check(not HOME.credits_pending(game), "completed character cannot replay credits after reload"): return false
	if not await revisit_completed(tree, game): return false
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
	var unfinished := false
	for entry: Dictionary in journal.call("local_entries", game.progression):
		if entry.get("done") == false: unfinished = true
	if not check(unfinished, "actual journal keeps unfinished local activities after credits"): return false
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
	if view.get("ready") != true or view.get("rows", []).size() != 3:
		print("F20 BOUNTY live view=", view, " local_board=", game.local.redesign_character.bounties,
			" world_day=", game.world.day, " bounty_day=", game.world.redesign_world.bounty_day)
	if not check(view.get("ready") == true and view.get("rows", []).size() == 3,
		"reloaded character has three active bounties in the live board"): return false
	await travel.tap("menu_cancel")
	return check(INPUT_OWNER.current(tree) == null, "bounty screen returns ordinary world input")
