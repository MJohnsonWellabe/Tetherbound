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
var _capture_index := 0
var continuation_content_entered := false

## Optional observations on the existing proof; no camera or gameplay writes.
## Hosted screenshots stay in the run artifact for independent visual review.
func capture(tree: SceneTree, label: String, frame_ready: Callable = Callable()) -> bool:
	if not OS.get_cmdline_user_args().has("--capture-ending") and not OS.get_cmdline_user_args().has("--capture-order-ui") \
		and not (OS.get_cmdline_user_args().has("--capture-lessons") and label.begins_with("lesson-")) \
		and not (OS.get_cmdline_user_args().has("--capture-next-goal") and label.begins_with("next-goal-")) \
		and not (OS.get_cmdline_user_args().has("--capture-relay") and label in ["relay-captain-fight", "relay-sela-exchange", "relay-sela-rescued", "relay-console-before", "relay-console-aftermath", "relay-mill-far-bank"]) \
		and not (OS.get_cmdline_user_args().has("--capture-surface") and label.begins_with("ripplet-surface-")) \
		and not (OS.get_cmdline_user_args().has("--capture-dive") and label.begins_with("ripplet-dive-")): return true
	# Explicit functional offload may draw this guarded lesson frame only. The
	# original capture still observes a real completed native draw; ordinary
	# physics, input and lesson state continue, and continuous drawing is restored.
	if (label.begins_with("lesson-") or label.begins_with("next-goal-")) and OS.get_cmdline_user_args().has("--functional-offload") \
		and not RenderingServer.render_loop_enabled:
		if not check(DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() == "gl_compatibility",
			"offloaded lesson capture requires the real Compatibility display"): return false
		RenderingServer.render_loop_enabled = true
		var captured: bool = await capture(tree, label, frame_ready)
		RenderingServer.render_loop_enabled = false
		return captured
	if not check(DisplayServer.get_name() != "headless" and RenderingServer.render_loop_enabled,
		"ending capture requires an actual drawing display"): return false
	var drawn: Array[bool] = [false]
	var frame_image: Array[Image] = []
	var deadline := Time.get_ticks_msec() + 30000
	var observer := func() -> void:
		if drawn[0] or Time.get_ticks_msec() >= deadline: return
		if frame_ready.is_valid() and frame_ready.call() != true: return
		drawn[0] = true
		# Retain this completed draw, including transient effects that could
		# finish before the awaiting reader resumes on the next idle edge.
		frame_image.append(tree.root.get_texture().get_image())
	RenderingServer.frame_post_draw.connect(observer)
	while not drawn[0] and Time.get_ticks_msec() < deadline: await tree.process_frame
	RenderingServer.frame_post_draw.disconnect(observer)
	if not check(drawn[0], "ending capture observes a completed frame within 30 seconds"): return false
	var image: Image = frame_image[0]
	var directory := "res://shots/f20-ending-%d" % OS.get_process_id()
	var path := directory.path_join("%03d-%s.png" % [_capture_index, label])
	_capture_index += 1
	if not check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK \
		and image != null and not image.is_empty() and image.save_png(path) == OK,
		"actual ending framebuffer saved: " + label): return false
	print("F20 ENDING CAPTURE " + JSON.stringify({"path": path, "label": label,
		"width": image.get_width(), "height": image.get_height()}))
	return true

func check(value: bool, message: String) -> bool:
	checks += 1
	print("F20 ", "PASS " if value else "FAIL ", message)
	if not value: failures.append(message)
	return value

## F19 presentation observations reuse this area's disclosed fixture and real
## Home Key return. No realm/pose/unlock changes are made after fixture setup.
func order_ui(tree: SceneTree, game: Node) -> bool:
	if not check(OS.get_cmdline_user_args().has("--capture-order-ui"), "order UI proof requires its actual frame captures"): return false
	if not await return_home(tree, game): return false
	var travel := TRAVEL.new(tree, game)
	var expected: Array[String] = ["meadows", "water", "cloudreach", "stormwood"]
	var names: Array[String] = ["The Meadows", "Tidewake", "Cloudreach Cliffs", "The Stormwood"]
	var map_names: Array[String] = ["Meadows", "Tidewake", "Cloudreach Cliffs", "The Stormwood"]
	await travel.tap("inventory")
	var menu: Node = game.call("menu")
	if not check(menu != null and menu.call("is_open") and INPUT_OWNER.current(tree) == menu,
		"ordinary inventory input opens the production owned menu"): return false
	for tab_id: String in ["map", "quest_log"]:
		for step in 12:
			if menu.call("current_tab_id") == tab_id: break
			await travel.tap("menu_tab_right")
		if not check(menu.call("current_tab_id") == tab_id, "ordinary menu navigation reaches " + tab_id): return false
		var body: Node = menu.get("_bodies")[int(menu.get("_index"))]
		if tab_id == "map":
			var available: Array = body.call("_available_realms")
			var row := body.get("_realm_row") as Control
			var labels: Array[String] = []
			if row != null:
				for button: Node in row.get_children():
					if button is Button: labels.append((button as Button).text)
			if not check(available == expected and row != null and row.is_visible_in_tree() and labels == map_names,
				"actual available map destinations and visible selector labels follow all four chapters"): return false
			print("F19 ORDER MAP " + JSON.stringify({"realms":available,"visible_labels":labels,"fixture_unlocks":true}))
		else:
			var heading := "Chapter 1 · The Meadows"
			var visible_heading := false
			for label: Node in body.find_children("*", "Label", true, false):
				if (label as Label).is_visible_in_tree() and (label as Label).text == heading: visible_heading = true
			if not check(body.get("_log").call("chapter_order") == expected and visible_heading,
				"production journal retains the chapter order and displays the current Meadows chapter heading"): return false
			print("F19 ORDER JOURNAL " + JSON.stringify({"order":expected,"visible_heading":heading,"other_chapter_headings_captured":false}))
		if not await capture(tree, "order-" + tab_id): return false
	await travel.tap("menu_cancel")
	if not check(not menu.call("is_open") and INPUT_OWNER.current(tree) == null, "menu cancel returns input before signed arch approaches"): return false
	var ids: Array[String] = ["home", "tidewake", "cloudreach", "stormwood"]
	var levels: Array[int] = [3, 20, 31, 42]
	for index in ids.size():
		var arch: Node3D
		for candidate: Node in tree.get_nodes_in_group("portal_arches"):
			if candidate.get("arch_id") == ids[index]: arch = candidate as Node3D
		if not check(arch != null, "production Hall mounts signed live arch " + ids[index]): return false
		var prompt := arch.get_node("Interactable") as Node3D
		var player := tree.current_scene.get_node("Player") as CharacterBody3D
		var rig := tree.current_scene.get_node("CameraRig") as Node3D
		var recoveries_before := int(player.get("_unstick_count"))
		var nav := preload("res://tests/helpers/stick_navigator.gd").new(tree, player, rig, Callable(travel, "_stick"))
		var approach := arch.get_parent().get_node_or_null("Approach") as Node3D
		var headings: Array[Vector3] = []
		if approach != null: headings.append(approach.global_position)
		var arrived: bool = await nav.walk_to_guided(prompt.global_position, 2400, 1.3, headings)
		travel.call("_stick", 0.0, 0.0)
		for frame in 8: await tree.physics_frame
		var arbiter: Node = tree.current_scene.get_node("InteractionArbiter")
		var offer: Dictionary = arbiter.call("winner")
		var text := str(prompt.get("label"))
		if not check(arrived and player.is_on_floor() and int(player.get("_unstick_count")) == recoveries_before \
			and INPUT_OWNER.current(tree) == null and arbiter.call("winning_provider") == prompt \
			and str(offer.get("label", "")) == text and text.contains(names[index]) and text.contains("Recommended Lv %d" % levels[index]),
			"actual grounded winner shows its chapter name and recommended level: " + ids[index]): return false
		print("F19 ORDER SIGN " + JSON.stringify({"id":ids[index],"label":text,"recommended_level":levels[index],
			"grounded":player.is_on_floor(),"unstick_unchanged":true,"entered_or_unlocked":false}))
		if not await capture(tree, "order-sign-" + ids[index]): return false
	return check(travel.failures.is_empty(), "order UI observations retain the real navigation and Home Key guards")

## The existing fixture already opened these personal arches. Enter them by
## their real provider; do not weaken the earned helper's still-locked key check.
func order_journals(tree: SceneTree, game: Node) -> bool:
	if not check(OS.get_cmdline_user_args().has("--capture-order-ui"), "journal extension requires actual frame captures"): return false
	if not await return_home(tree, game): return false
	var travel := TRAVEL.new(tree, game)
	var character_id := str(game.local.character_id)
	var original_uids: Array[String] = travel._uids()
	if not check(not character_id.is_empty() and original_uids.size() == 5 and not original_uids.has(""),
		"journal extension retains the fixture's actual stable character and five companions"): return false
	var expected: Array[String] = ["meadows", "water", "cloudreach", "stormwood"]
	var destinations := [["tidewake", "water", "Chapter 2 · Tidewake"],
		["cloudreach", "cloudreach", "Chapter 3 · Cloudreach Cliffs"],
		["stormwood", "stormwood", "Chapter 4 · The Stormwood"]]
	for index in destinations.size():
		var arch_id := str(destinations[index][0])
		var realm := str(destinations[index][1])
		var heading := str(destinations[index][2])
		var view: Dictionary = game.call("portal_view", arch_id)
		var arch: Node3D
		for candidate: Node in tree.get_nodes_in_group("portal_arches"):
			if candidate.get("arch_id") == arch_id: arch = candidate as Node3D
		if not check(str(game.current_realm) == "meadows" and arch != null \
			and view.get("ready") == true and view.get("character_open") == true \
			and str(game.local.character_id) == character_id and travel._uids() == original_uids,
			"journal route retains its character and actual already-open arch " + arch_id): return false
		var prompt := arch.get_node_or_null("Interactable") as Node3D
		if not check(prompt != null, "already-open journal destination has its actual provider"): return false
		if not await travel.enter_unlocked(arch_id, realm): failures.append_array(travel.failures); return false
		var arrived: bool = travel._ready_world(realm)
		if not check(arrived and str(game.local.character_id) == character_id and travel._uids() == original_uids,
			"ordinary portal Enter reaches the ready journal realm with the same five: " + realm): return false
		await travel.tap("inventory")
		var menu: Node = game.call("menu")
		if not check(menu != null and menu.call("is_open") and INPUT_OWNER.current(tree) == menu,
			"ordinary inventory input opens the actual destination menu"): return false
		for step in 12:
			if menu.call("current_tab_id") == "quest_log": break
			await travel.tap("menu_tab_right")
		if not check(menu.call("current_tab_id") == "quest_log", "ordinary tabs reach the destination quest log"): return false
		var body: Node = menu.get("_bodies")[int(menu.get("_index"))]
		var heading_label: Label
		for label: Node in body.find_children("*", "Label", true, false):
			if (label as Label).is_visible_in_tree() and (label as Label).text == heading: heading_label = label as Label
		var journal_visible := func() -> bool:
			return is_instance_valid(menu) and menu.call("is_open") and INPUT_OWNER.current(tree) == menu \
				and menu.call("current_tab_id") == "quest_log" and is_instance_valid(body) \
				and body.get("_log").call("chapter_order") == expected and body.get("_log").call("chapter_heading") == heading \
				and is_instance_valid(heading_label) and heading_label.is_visible_in_tree() and heading_label.text == heading \
				and str(game.current_realm) == realm and str(game.local.character_id) == character_id and travel._uids() == original_uids
		if not check(journal_visible.call() == true, "actual destination journal displays " + heading): return false
		if not await capture(tree, "order-journal-" + realm, journal_visible): return false
		if not check(journal_visible.call() == true, "destination journal identity and heading survive the completed capture"): return false
		print("F19 ORDER JOURNAL " + JSON.stringify({"realm": realm, "order": expected, "visible_heading": heading,
			"character_id": character_id, "party_uids": original_uids, "fixture_unlocks": true, "earned_campaign": false}))
		await travel.tap("menu_cancel")
		if not check(not menu.call("is_open") and INPUT_OWNER.current(tree) == null, "journal cancel returns ordinary world input"): return false
		if index < destinations.size() - 1:
			if not await travel.home_key(): failures.append_array(travel.failures); return false
	return check(travel.failures.is_empty(), "three destination journals retain ordinary portal and Home Key guards")

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

func ready(tree: SceneTree, game: Node, timeout_ms: int = 180000) -> bool:
	var began := Time.get_ticks_msec()
	var deadline := began + timeout_ms
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
			print("F20 READY elapsed_ms=", now - began, " physics_samples=", samples, " max_wait_ms=", max_wait_ms,
				" budget_ms=", timeout_ms)
			return true
	var scene := tree.current_scene
	var player := game.call("find_player") as CharacterBody3D
	var owner := INPUT_OWNER.current(tree)
	print("F20 READY TIMEOUT elapsed_ms=", Time.get_ticks_msec() - began,
		" budget_ms=", timeout_ms,
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
		var memory_fact := "%d %s" % [landmarks, "landmark" if landmarks == 1 else "landmarks"] if landmarks > 0 \
			else "%d %s" % [battles, "battle" if battles == 1 else "battles"]
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
		if not await capture(tree, "grandpa-%02d" % presses):
			panel.disconnect("completed", completion_observer)
			return false
		print("F20 TALK tap start index=", presses, " ticks_ms=", Time.get_ticks_msec())
		await travel.tap("interact")
		print("F20 TALK tap returned index=", presses, " ticks_ms=", Time.get_ticks_msec())
		presses += 1
	travel.trace_input = false
	print("F20 DIALOGUE input authored_lines=", line_count, " actual_presses=", presses)
	var deadline := Time.get_ticks_msec() + 30000
	var ack_intent := HOME.acknowledgement_intent(expected, HOME.SEEN_FLAG)
	var ack_decision: Dictionary = {}
	var acknowledged: bool = not first and HOME.context(game).get("homecoming_seen") == true
	while not panel.call("is_open") and not acknowledged and Time.get_ticks_msec() < deadline:
		# Owner apply installs the receipt before its host settlement. Observe
		# the original intent's accepted saved decision, not that early flag.
		var ack_row: Dictionary = game.session.call("_owner_training_row")
		if ack_row.get("action") == "regional_ack" and ack_row.get("intent") == ack_intent:
			ack_decision = game.session.call("_training_decision", game.session.call("local_peer_id"), ack_row)
			acknowledged = ack_decision.get("ok") == true and ack_decision.get("resolved") == true \
				and ack_decision.get("durable") == true and ack_decision.get("saved") == true \
				and HOME.context(game).get("homecoming_seen") == true
		if not acknowledged: await tree.process_frame
	panel.disconnect("completed", completion_observer)
	var dialogue_owner := INPUT_OWNER.current(tree)
	var row: Dictionary = game.session.call("_owner_training_row")
	print("F20 DIALOGUE finish opened=", opened, " completed=", completed,
		" panel_open=", panel.call("is_open"), " id=", panel.call("runner").call("conversation_id"),
		" owner=", dialogue_owner.get_path() if dialogue_owner != null else "none",
		" owner_script=", dialogue_owner.get_script().resource_path if dialogue_owner != null and dialogue_owner.get_script() != null else "none",
		" context=", game.call("regional_ending_context"),
		" ack_intents=", game.get("_regional_ack_intents"),
		" observed_ack_decision=", ack_decision,
		" training_action=", row.get("action", ""), " training_intent=", row.get("intent", {}),
		" notice=", game.get("_pending_world_message"))
	print("F20 DIALOGUE rendered ", _heard)
	if not check(opened and acknowledged, "natural Grandpa completion receives durable personal acknowledgement"): return false
	if first:
		for companion: String in HOME.party_names(game.party):
			if not check(_heard.contains(companion), "Grandpa actually rendered " + companion): return false
		for field: String in ["starter_status", "bond_memory", "chapter_choices"]:
			if not check(not str(prose.get(field, "")).is_empty() and _heard.contains(str(prose[field])), "Grandpa rendered truthful " + field): return false
	var credits: Node
	# Wall-clock bound: a slow runner can take over a second per frame.
	var credits_deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < credits_deadline:
		await tree.process_frame
		var owner := INPUT_OWNER.current(tree)
		if owner != null and owner.get_script() == load("res://scripts/ui/regional_credits.gd"):
			credits = owner; break
	if not check(credits != null and credits.call("is_open"), "production credits own this player's input after acknowledgement"): return false
	return await capture(tree, "credits")

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
	var completed: Array[String] = []
	var completion_observer := func(id: String) -> void: completed.append(id)
	panel.connect("completed", completion_observer)
	# Match the first homecoming reader: a released controller edge can take
	# more than 30 seconds to draw here. Bound input by the actual authored
	# lines plus the panel's opening guard, then check the unchanged outcome.
	var line_count := int(panel.call("runner").call("_line_count"))
	var presses := 0
	while panel.call("is_open") and presses < line_count + 2:
		if panel.call("runner").call("conversation_id") != HOME.REPEAT_ID \
				or INPUT_OWNER.current(tree) != panel: break
		await travel.tap("interact")
		presses += 1
	panel.disconnect("completed", completion_observer)
	for frame in 8: await tree.process_frame
	var credits_open := false
	for node: Node in tree.get_nodes_in_group("story_modal"):
		if node.get_script() == load("res://scripts/ui/regional_credits.gd") and node.call("is_open"): credits_open = true
	print("F20 REPEAT " + JSON.stringify({"authored_lines": line_count, "actual_presses": presses,
		"completed": completed, "panel_open": panel.call("is_open"), "credits_open": credits_open,
		"input_released": not Input.is_action_pressed("interact"),
		"world_input": INPUT_OWNER.current(tree) == null,
		"receipts_unchanged": game.local.redesign_character.transaction_receipts == receipts}))
	return check(completed == [HOME.REPEAT_ID] and not Input.is_action_pressed("interact") \
		and not panel.call("is_open") and not credits_open and INPUT_OWNER.current(tree) == null \
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
	var moment := {"results": 0, "presented": false, "capture_started": false, "capture_done": false, "captured": false}
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
		if moment.results == 1 and moment.presented and OS.get_cmdline_user_args().has("--capture-ending"):
			moment.capture_started = true
			var visible_stir := func() -> bool:
				if not is_instance_valid(arch) or not is_instance_valid(light) or tree.current_scene == null: return false
				var hud: Node = tree.current_scene.get_node_or_null("PlaygroundHUD")
				var label: Label = hud.get("_hotbar_message") if hud != null else null
				return light.is_visible_in_tree() and light.light_energy > float(arch.get("_stir_settings").resting_energy) \
					and label != null and label.is_visible_in_tree() and label.text == "It stirred, but it is not ready yet."
			# Arm at the durable result, while activation is still releasing X.
			# The observed HUD line and bright light must coexist in the draw.
			moment.captured = await capture(tree, "fifth-arch-stir", visible_stir)
			moment.capture_done = true
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
		while moment.capture_started and not moment.capture_done: await tree.process_frame
		failures.append_array(travel.failures); return false
	var stir_deadline := Time.get_ticks_msec() + 30000 # wall-clock: slow runners exceed 1 s/frame
	while Time.get_ticks_msec() < stir_deadline:
		await tree.process_frame
		if game.call("portal_view", "biome5").get("character_stirred") == true: break
	for frame in 8: await tree.process_frame
	tree.process_frame.disconnect(observer)
	game.disconnect("portal_action_result", result_observer)
	while moment.capture_started and not moment.capture_done: await tree.process_frame
	var view: Dictionary = game.call("portal_view", "biome5")
	if not check(view.get("character_stirred") == true and view.get("open") == false \
		and game.local.inventory.call("count", "fifth_portal_key") == 0, "one real key consumed; fifth arch stays sealed"): return false
	if not check(moment.results == 1 and moment.presented, "one actual durable result creates bright glow and a playing diegetic SFX source"): return false
	if not check(messages.has("It stirred, but it is not ready yet."), "actual key use emits the single not-ready line"): return false
	if OS.get_cmdline_user_args().has("--capture-ending") and not check(moment.capture_done and moment.captured,
		"fifth stir frame captured while the actual light is bright and the not-ready line is visible"): return false
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

func resumed(tree: SceneTree, game: Node, before: Dictionary, continuation: bool = true) -> bool:
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
	if not await capture(tree, "completed-world"): return false
	# A named F20#1 endpoint retains disk/revisit/once-only credits checks.
	# Full/default callers still require all F20#3 continuation assertions.
	if not continuation: return true
	return await continuation_content(tree, game)

func continuation_content(tree: SceneTree, game: Node) -> bool:
	continuation_content_entered = true
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
	var board_frame := func() -> bool:
		return is_instance_valid(panel) and panel.call("is_open") == true \
			and INPUT_OWNER.current(tree) == panel and adapter.call("view") == view
	if not await capture(tree, "completed-bounties", board_frame): return false
	await travel.tap("menu_cancel")
	if not check(INPUT_OWNER.current(tree) == null, "bounty screen returns ordinary world input"): return false
	return await admit_endgame_rematch(tree, game, rematches)

## F20 checks continuation availability, not F44 victory or repeat rewards.
## The isolated proof finishes in this genuinely admitted trainer fight;
## trainers cannot flee, so no forced outcome or fake recovery is used.
func admit_endgame_rematch(tree: SceneTree, game: Node, rematches: Node) -> bool:
	var rules := preload("res://scripts/repeatables/rematch_rules.gd")
	var player := game.call("find_player") as CharacterBody3D
	var prompt: Node3D
	var nearest := INF
	for reference: WeakRef in rematches.get("_prompts").values():
		var candidate := reference.get_ref() as Node3D
		if candidate == null or not candidate.is_inside_tree() or candidate.get("label") != "Endgame rematch" \
			or candidate.get("enabled") != true: continue
		var spec: Dictionary = candidate.get_parent().get_meta("foundation_trainer_spec", {})
		if rules.profile(str(spec.get("id", ""))).get("kind") != "trainer": continue
		var distance := player.global_position.distance_to(candidate.global_position)
		if distance < nearest:
			nearest = distance
			prompt = candidate
	if not check(prompt != null, "reloaded world has a mounted nonmaster endgame rematch"): return false
	var source := prompt.get_parent() as Node3D
	var original: Dictionary = source.get_meta("foundation_trainer_spec", {}).duplicate(true)
	var expected: Dictionary = rules.encounter_spec(original, "endgame")
	var director := tree.current_scene.get_node_or_null("EncounterDirector")
	var manager: Node = director.get("_manager") if director != null else null
	if not check(not expected.is_empty() and manager != null and director.call("trainer_battle_active") == false \
		and manager.call("is_fighting") == false, "rematch admission starts from ordinary completed-world exploration"): return false
	print("F20 REMATCH ordinary source=", source.get_path(), " trainer=", original.id, " tier=endgame")
	var travel := TRAVEL.new(tree, game)
	# A fresh load keeps the owned party but deliberately does not send anyone
	# out. Use the normal call-out button before asking for a trainer fight.
	var blocker := str(director.call("usable_ally_blocker"))
	print("F20 REMATCH callout initial_blocker=", blocker)
	if blocker == "undeployed":
		await travel.tap("creature_recall")
		var callout_deadline := Time.get_ticks_msec() + 30000
		while Time.get_ticks_msec() < callout_deadline:
			if director.call("usable_ally_blocker") != "undeployed":
				var preparing_body := director.call("ally_body") as Node3D
				if not is_instance_valid(preparing_body) or preparing_body.visible: break
			await tree.process_frame
	var ally: RefCounted = director.get("_ally")
	var ally_body := director.call("ally_body") as Node3D
	if not check(director.call("usable_ally_blocker") == "" and ally != null \
		and game.party.call("members").has(ally) and is_instance_valid(ally_body) and ally_body.visible \
		and ally_body.get("owner_peer_id") == game.session.call("local_peer_id"),
		"ordinary call-out has a conscious actually owned companion before the rematch"): return false
	if not await travel.activate_endgame_rematch(prompt): failures.append_array(travel.failures); return false
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline and manager.call("is_fighting") != true: await tree.process_frame
	var body := director.get("_trainer_body") as Node3D
	var enemy: RefCounted = body.get("instance") if is_instance_valid(body) else null
	var admitted: bool = director.call("trainer_battle_active") == true and manager.call("is_fighting") == true \
		and director.get("_trainer_node") == source and director.get("_trainer_spec") == expected \
		and enemy != null and enemy.get("species_id") == expected.team[0].species \
		and int(enemy.get("level")) == int(expected.team[0].level) and manager.get("_enemy") == enemy \
		and manager.get("_enemy_owned") == true
	if not admitted:
		var actual_source := director.get("_trainer_node") as Node
		print("F20 REMATCH admission fighting=", manager.call("is_fighting"), " trainer_active=", director.call("trainer_battle_active"),
			" expected_source=", source.get_path(), " actual_source=", actual_source.get_path() if is_instance_valid(actual_source) else "none",
			" expected_spec=", expected, " actual_spec=", director.get("_trainer_spec"),
			" enemy=", enemy, " species=", enemy.get("species_id") if enemy != null else "none",
			" level=", enemy.get("level") if enemy != null else 0, " manager_enemy_matches=", manager.get("_enemy") == enemy,
			" enemy_owned=", manager.get("_enemy_owned"), " ally_blocker=", director.call("usable_ally_blocker"),
			" can_challenge=", director.call("can_challenge", expected), " source_busy=", director.call("rematch_source_busy", source),
			" pending_world_message=", game.get("_pending_world_message"))
	if not check(admitted,
		"ordinary input admits the actual canonical endgame rematch at its configured tier; isolated proof quits during fight"): return false
	var rematch_frame := func() -> bool:
		return is_instance_valid(body) and body.is_visible_in_tree() and director.call("trainer_battle_active") == true \
			and manager.call("is_fighting") == true and director.get("_trainer_node") == source \
			and director.get("_trainer_spec") == expected and manager.get("_enemy") == enemy and manager.get("_enemy_owned") == true
	return await capture(tree, "completed-endgame-rematch", rematch_frame)
