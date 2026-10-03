extends RefCounted

## Ordinary parsed menu/interaction input and read-only observations. No key
## grants, state edits, private gameplay calls or actor/camera transforms.
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var tree: SceneTree
var game: Node
var travel: RefCounted
var failures: Array[String] = []
var receipts: Array[Dictionary] = []

func _init(owner: SceneTree, actual_game: Node, actual_travel: RefCounted) -> void:
	tree = owner
	game = actual_game
	travel = actual_travel

func _fail(message: String) -> bool:
	failures.append(message)
	return false

func _inventory() -> Array:
	var inventory: RefCounted = game.get("inventory")
	var slots: Array = []
	for i in int(inventory.call("slot_count")): slots.append(inventory.call("stack_at", i))
	return slots

func protected_drop_and_assign() -> bool:
	var inventory: RefCounted = game.get("inventory")
	var slot: int = inventory.call("find_slot", "home_key")
	if slot < 0 or inventory.call("count", "home_key") != 1: return _fail("actual earned Home Key required")
	var before := _inventory()
	var starting_bar: Array = (game.get("hotbar") as Array).duplicate()
	receipts.append({"phase": "earned_key_starting_bindings", "hotbar": starting_bar,
		"home_keys": 1, "earned_basic_orbs": inventory.call("count", "orb_basic"),
		"owner": str(game.get("local").get("character_id"))})
	await travel.tap("inventory")
	var menu: Node = game.call("menu")
	if menu == null or menu.call("is_open") != true or menu.call("current_tab_id") != "backpack":
		return _fail("actual Satchel did not open for protection check")
	var tab: Node = (menu.get("_bodies") as Array)[0]
	var care := CARE.new()
	care.set("_tree", tree)
	if not await care.call("_focus_slot", tab.get("_buttons"), slot): return _fail("controller focus did not reach earned key")
	# Read the actual UI-time bar too: a just-released lesson can precede the
	# HUD's ordinary initial autofill. No pre-existing orb binding is required.
	var original_bar: Array = (game.get("hotbar") as Array).duplicate()
	await travel.tap("backpack_drop")
	var rows: Array = tab.get("_confirm_rows")
	if int(tab.get("_confirming")) != slot or rows.is_empty() or tree.root.gui_get_focus_owner() != rows[0]:
		return _fail("actual Drop confirmation was not offered for selected key")
	await travel.tap("ui_accept")
	var reason: Label = menu.get("_status")
	if inventory.call("count", "home_key") != 1 or _inventory() != before or int(tab.get("_confirming")) != -1 \
		or game.get("hotbar") != original_bar or reason == null or reason.text != "Keys stay with their owner." or not reason.is_visible_in_tree():
		return _fail("actual protected-key Drop did not visibly refuse without changing inventory")
	receipts.append({"phase": "protected_drop", "input": ["inventory", "backpack_drop", "ui_accept"],
		"reason": reason.text, "home_keys": inventory.call("count", "home_key"), "inventory_unchanged": true,
		"hotbar_before_drop": original_bar, "hotbar_unchanged": true})
	if not await care.call("_focus_slot", tab.get("_buttons"), slot): return _fail("key focus not restored after Drop refusal")
	# The real verb walks through occupied slots. Restore the actual prior
	# items in reverse order after assigning the key; slot 5 is its new home.
	if not await _assign_in_satchel(tab, care, "home_key", 4): return false
	var expected_bar: Array = original_bar.duplicate()
	if expected_bar.size() != 5: return _fail("actual quick bar does not have five slots")
	for destination in range(3, -1, -1):
		var item: String = str(original_bar[destination])
		if item == "home_key": expected_bar[destination] = ""
		elif not item.is_empty() and not await _assign_in_satchel(tab, care, item, destination): return false
	expected_bar[4] = "home_key"
	# Gate A presses combat_throw. ThrowAim selects/spends its strongest earned
	# orb from inventory, independently of the tool/food/consumable quick bar.
	var combat: Node = tree.current_scene.get_node_or_null(^"CombatManager")
	var throw: Node = combat.call("throw_aim") if combat != null else null
	var catch_orb: String = str(throw.call("current_orb_id")) if throw != null else ""
	if inventory.call("count", "home_key") != 1 or _inventory() != before:
		return _fail("ordinary quick-slot assignment changed earned inventory")
	if game.get("hotbar") != expected_bar or catch_orb != "orb_basic":
		return _fail("ordinary key binding changed prior quick slots or the production earned catch orb")
	receipts.append({"phase": "key_binding", "slot": 4, "input": "backpack_assign", "home_keys": 1,
		"starting_hotbar": starting_bar, "hotbar_before_binding": original_bar, "hotbar_after_binding": expected_bar,
		"catch_input": "combat_throw", "production_catch_orb": catch_orb, "catch_orb_source": "earned_inventory",
		"inventory_unchanged": true, "owner": str(game.get("local").get("character_id"))})
	await travel.tap("menu_cancel")
	for frame in 30:
		await tree.physics_frame
		if INPUT_OWNER.current(tree) == null: return true
	return _fail("key protection menu did not release input")

func _assign_in_satchel(tab: Node, care: RefCounted, item: String, destination: int) -> bool:
	var inventory: RefCounted = game.get("inventory")
	var slot: int = inventory.call("find_slot", item)
	if slot < 0 or not await care.call("_focus_slot", tab.get("_buttons"), slot):
		return _fail("ordinary Satchel focus did not reach " + item)
	for attempt in (game.get("hotbar") as Array).size() + 1:
		if int(game.call("hotbar_slot_of", item)) == destination: return true
		await travel.tap("backpack_assign")
	return int(game.call("hotbar_slot_of", item)) == destination \
		or _fail("ordinary Satchel assignment did not reach required slot for " + item)

func _refusal_context(kind: String, source: Node, scene: Node) -> bool:
	if not is_instance_valid(source) or tree.current_scene != scene or not scene.is_ancestor_of(source): return false
	if kind == "combat":
		var hud: Node = scene.get_node_or_null(^"PlaygroundHUD")
		return source == scene.get_node_or_null(^"CombatManager") and source.call("is_fighting") == true \
			and source.call("presenting_fight") == true and source.call("is_aiming") == false \
			and hud != null and hud.get("_aim_hotbar_latch") == false
	return kind == "dialogue" and source == scene.get_node_or_null(^"DialoguePanel") \
		and source.call("is_open") == true and INPUT_OWNER.current(tree) == source

func bound_refusal(kind: String, source: Node) -> bool:
	# Observe production state and press the actually assigned action. Never
	# call use/refuse, open a channel, or arrange a combat/dialogue context.
	var expected: String = "Not during a fight." if kind == "combat" else "Finish the conversation first."
	var scene: Node = tree.current_scene
	var actor: Node3D = game.call("find_player")
	var key: Node = game.get_node_or_null(^"HomeKey")
	var session: Node = game.get("session")
	var inventory: RefCounted = game.get("inventory")
	var binding: int = game.call("hotbar_slot_of", "home_key")
	if scene == null or actor == null or not scene.is_ancestor_of(actor) or key == null or session == null \
		or key.get("_phase") != "idle" or inventory.call("count", "home_key") != 1 or binding != 4 \
		or not _refusal_context(kind, source, scene) or str(game.call("home_key_refusal")) != expected:
		return _fail("actual " + kind + " refusal preconditions are missing")
	var before: Array = _inventory()
	var bar: Array = (game.get("hotbar") as Array).duplicate()
	var realm: String = game.get("current_realm")
	var world: RefCounted = game.get("world")
	var local: RefCounted = game.get("local")
	var character: String = local.get("character_id")
	var epoch: String = str(session.call("_altar_current_epoch"))
	var input_owner: Node = INPUT_OWNER.current(tree)
	var serial: int = session.get("_portal_request_serial")
	var requests: Dictionary = (session.get("_portal_requests") as Dictionary).duplicate(true)
	var policy: RefCounted = session.get("_portal_policy")
	var channels: Array = policy.call("open_channels")
	var source_path: String = str(source.get_path())
	var enemy: Node3D = source.call("enemy_body") if kind == "combat" else null
	var dialogue_id: String = str(source.get("_runner").call("conversation_id")) if kind == "dialogue" else ""
	var dialogue_line: int = int(source.get("_runner").get("_index")) if kind == "dialogue" else -1
	var results: Array[Dictionary] = []
	var observe := func(result: Dictionary) -> void: results.append(result.duplicate(true))
	game.connect("portal_action_result", observe)
	var action: String = "hotbar_%d" % (binding + 1)
	await travel.tap(action)
	game.disconnect("portal_action_result", observe)
	var label: Label = key.get("_refusal_label") if is_instance_valid(key) else null
	var panel: Control = key.get("_refusal_panel") if is_instance_valid(key) else null
	var unchanged: bool = is_instance_valid(key) and tree.current_scene == scene and game.get("session") == session \
		and game.call("find_player") == actor and game.get("world") == world and game.get("current_realm") == realm \
		and game.get("local") == local and local.get("character_id") == character \
		and str(session.call("_altar_current_epoch")) == epoch and INPUT_OWNER.current(tree) == input_owner \
		and _inventory() == before and game.get("hotbar") == bar and inventory.call("count", "home_key") == 1 \
		and key.get("_phase") == "idle" and key.get("_pending") == "" and key.get("_use_id") == "" \
		and session.get("_portal_request_serial") == serial and session.get("_portal_requests") == requests \
		and policy.call("open_channels") == channels and results.is_empty() and _refusal_context(kind, source, scene)
	if kind == "dialogue":
		unchanged = unchanged and is_instance_valid(source) and str(source.get("_runner").call("conversation_id")) == dialogue_id \
			and int(source.get("_runner").get("_index")) == dialogue_line
	else:
		unchanged = unchanged and is_instance_valid(source) and source.call("enemy_body") == enemy
	var readable: bool = label != null and panel != null and label.is_visible_in_tree() \
		and panel.is_visible_in_tree() and label.text == expected
	receipts.append({"phase": kind + "_key_refusal", "input": action, "binding": binding,
		"reason": label.text if label != null else "", "expected_reason": expected,
		"readable": readable, "unchanged": unchanged, "home_keys": inventory.call("count", "home_key"),
		"owner": character, "epoch": epoch, "realm": realm, "source": source_path, "dialogue": dialogue_id,
		"portal_actions": results, "channel_created": policy.call("open_channels") != channels,
		"passed": readable and unchanged})
	return (readable and unchanged) or _fail("actual bound " + kind + " key press did not visibly refuse without side effects")

func locked_arch() -> bool:
	var scene := tree.current_scene
	var player := scene.get_node_or_null(^"Player") as CharacterBody3D
	var rig := scene.get_node_or_null(^"CameraRig") as Node3D
	var arbiter: Node = scene.get_node_or_null(^"InteractionArbiter")
	var arch: Node3D
	for candidate: Node in tree.get_nodes_in_group("portal_arches"):
		if scene.is_ancestor_of(candidate) and candidate.get("arch_id") == "tidewake": arch = candidate as Node3D
	if arch == null or player == null or rig == null or arbiter == null: return _fail("actual locked Hall arch/player missing")
	var view: Dictionary = game.call("portal_view", "tidewake")
	if view.get("ready") != true or view.get("open") == true or view.get("has_key") == true:
		return _fail("locked-arch proof requires actual unearned Tidewake key")
	var prompt := arch.get_node(^"Interactable") as Node3D
	var nav := NAV.new(tree, player, rig, travel._stick)
	var recovery: int = player.get("_unstick_count")
	var reached: bool = await nav.walk_to(prompt.global_position, 2400, 2.5)
	travel._stick(0, 0)
	for frame in 8: await tree.physics_frame
	if not reached or not player.is_on_floor() or player.get("_unstick_count") != recovery \
		or arbiter.call("winning_provider") != prompt: return _fail("ordinary grounded walk did not reach exact locked arch")
	var offer: Dictionary = arbiter.call("winner")
	var label: Control = scene.get_node(^"PlaygroundHUD").get("_prompt_label")
	if offer.get("actionable") != false or not str(offer.get("label", "")).contains("Needs the Tidewake Portal Key") \
		or label == null or not label.is_visible_in_tree() or not str(label.get("text")).contains("Needs the Tidewake Portal Key"):
		return _fail("locked arch did not render its readable missing-key reason")
	var before := _inventory()
	var results: Array[Dictionary] = []
	var observe := func(result: Dictionary) -> void: results.append(result.duplicate(true))
	game.connect("portal_action_result", observe)
	await travel.tap("interact")
	for frame in 16: await tree.physics_frame
	game.disconnect("portal_action_result", observe)
	view = game.call("portal_view", "tidewake")
	if str(game.get("current_realm")) != "meadows" or view.get("open") == true or _inventory() != before or not results.is_empty():
		return _fail("locked arch press travelled, mutated ownership or dispatched an action")
	receipts.append({"phase": "locked_arch", "input": "interact", "reason": str(label.get("text")),
		"realm": game.get("current_realm"), "inventory_unchanged": true, "portal_actions": results})
	return true
