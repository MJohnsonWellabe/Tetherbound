extends RefCounted

## Ordinary parsed menu/interaction input and read-only observations. No key
## grants, state edits, private gameplay calls or actor/camera transforms.
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LESSON_PANEL := preload("res://scripts/onboarding/lesson_panel.gd")
const LESSON_SERVICE := preload("res://scripts/onboarding/lesson_service.gd")
const SWIM_CONTROLLER := preload("res://scripts/player/swim_controller.gd")
const SWIM_STATE := preload("res://scripts/player/swim_state.gd")
const FLY_CONTROLLER := preload("res://scripts/player/fly_controller.gd")
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
	if not is_instance_valid(source) or tree.current_scene != scene: return false
	if kind == "cutscene":
		var service: Node = game.get_node_or_null(^"OnboardingLessons")
		var session: Node = game.get("session")
		if service == null or service.get_script() != LESSON_SERVICE or service.get_parent() != game \
			or service.get("_panel") != source or source.get_parent() != service or source.get_script() != LESSON_PANEL \
			or service.get("_identity") != game.get("local").get("character_id") or service.get("_replaying") != true \
			or source.call("is_open") != true or INPUT_OWNER.current(tree) != source \
			or source.get("_row").get("id") != "home_key" or source.get("_row").get("conversation") != "lesson_home_key" \
			or not (source as CanvasLayer).visible or session == null: return false
		var context: Dictionary = session.call("_host_portal_context", session.call("local_peer_id"))
		var lifecycle: Node = session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
		var sample: Dictionary = lifecycle.call("local_sample") if lifecycle != null else {}
		return context.get("combat") == false and context.get("dialogue") == false and context.get("cutscene") == true \
			and sample.get("dialogue") == false and sample.get("cutscene") == true
	if not scene.is_ancestor_of(source): return false
	if kind in ["swimming", "flying"]:
		var actor := game.call("find_player") as CharacterBody3D
		if actor == null or not scene.is_ancestor_of(actor): return false
		if kind == "swimming":
			return game.get("current_realm") == "water" and source == actor.get("swim_controller") \
				and source.get_script() == SWIM_CONTROLLER and source.get_parent() == actor \
				and source.get("_world") == scene and source.get("state").get("mode") == SWIM_STATE.Mode.HUMAN \
				and source.call("is_swimming") == true and not actor.is_on_floor()
		return source == actor.get("fly_controller") and source.get_script() == FLY_CONTROLLER \
			and source.get_parent() == actor and source.call("is_flying") == true and not actor.is_on_floor()
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
	var expected: String = {"combat": "Not during a fight.", "cutscene": "Wait until the scene finishes.",
		"dialogue": "Finish the conversation first.", "swimming": "Reach solid ground first.",
		"flying": "Land first."}.get(kind, "")
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
	var lesson_line: int = int(source.get("_line")) if kind == "cutscene" else -1
	var lesson_row: Dictionary = (source.get("_row") as Dictionary).duplicate(true) if kind == "cutscene" else {}
	var safety: Dictionary = session.call("_host_portal_context", session.call("local_peer_id")) if kind == "cutscene" else {}
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
	elif kind == "combat":
		unchanged = unchanged and is_instance_valid(source) and source.call("enemy_body") == enemy
	elif kind == "cutscene":
		unchanged = unchanged and is_instance_valid(source) and source.get("_line") == lesson_line and source.get("_row") == lesson_row
	var readable: bool = label != null and panel != null and label.is_visible_in_tree() \
		and panel.is_visible_in_tree() and label.text == expected
	var refusal_layer: CanvasLayer = key.get("_refusal_layer") if is_instance_valid(key) else null
	if kind == "cutscene": readable = readable and refusal_layer != null and is_instance_valid(source) \
		and refusal_layer.layer > (source as CanvasLayer).layer
	receipts.append({"phase": kind + "_key_refusal", "input": action, "binding": binding,
		"reason": label.text if label != null else "", "expected_reason": expected,
		"readable": readable, "unchanged": unchanged, "home_keys": inventory.call("count", "home_key"),
		"owner": character, "epoch": epoch, "realm": realm, "source": source_path, "dialogue": dialogue_id,
		"portal_actions": results, "channel_created": policy.call("open_channels") != channels,
		"lesson_line": lesson_line, "refusal_layer": refusal_layer.layer if refusal_layer != null else -1,
		"lesson_layer": (source as CanvasLayer).layer if kind == "cutscene" and is_instance_valid(source) else -1,
		"actual_safety": {"combat": safety.get("combat"), "dialogue": safety.get("dialogue"), "cutscene": safety.get("cutscene")} if kind == "cutscene" else {},
		"visibility_evidence": "structural visibility/layer observation; no rendered acceptance claim",
		"passed": readable and unchanged})
	return (readable and unchanged) or _fail("actual bound " + kind + " key press did not visibly refuse without side effects")

func replay_cutscene(open_tab: Callable) -> bool:
	var scene: Node = tree.current_scene
	var actor: Node3D = game.call("find_player")
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var session: Node = game.get("session")
	var character: String = local.get("character_id")
	var epoch: String = session.call("_altar_current_epoch")
	var retained: Callable = func() -> bool:
		return tree.current_scene == scene and game.call("find_player") == actor and game.get("world") == world \
			and game.get("local") == local and local.get("character_id") == character and game.get("session") == session \
			and session.call("_altar_current_epoch") == epoch
	var before_flags: Array = local.get("flags").call("all_set")
	before_flags.sort()
	var before_receipts: Array = (local.get("redesign_character").get("transaction_receipts") as Array).duplicate(true)
	var before_inventory: Array = _inventory()
	var before_bar: Array = (game.get("hotbar") as Array).duplicate()
	if actor == null or scene == null or not scene.is_ancestor_of(actor) or INPUT_OWNER.current(tree) != null \
		or local.get("flags").call("has", "opening:lesson:home_key") != true:
		return _fail("earned Home Key Replay requires actual completed opening lesson and world input")
	var tab: Node = await open_tab.call("settings")
	if not retained.call() or tab == null or tab.get_script().resource_path != "res://scripts/ui/tab_settings.gd": return _fail("ordinary Settings route/retained owner missing")
	var buttons: Array = tab.get("_lesson_buttons")
	if buttons.is_empty() or not buttons[0] is Button or tree.root.gui_get_focus_owner() != buttons[0] \
		or buttons[0].text != "Home Key" or not buttons[0].is_visible_in_tree():
		return _fail("Settings did not focus the actual available Home Key lesson button")
	await travel.tap("ui_accept")
	var service: Node = game.get_node_or_null(^"OnboardingLessons")
	var lesson: Node = service.get("_panel") if service != null else null
	var opened: bool = false
	for frame in 180:
		if not retained.call(): return _fail("actual owner/scene changed while waiting for Replay")
		if _refusal_context("cutscene", lesson, scene): opened = true; break
		await tree.process_frame
	if not opened or game.call("menu").call("is_open") == true: return _fail("Settings Replay did not open the actual owned lesson cutscene")
	if not await bound_refusal("cutscene", lesson): return false
	var row: Dictionary = (lesson.get("_row") as Dictionary).duplicate(true)
	var lines: int = (row.get("lines") as Array).size()
	if lines < 1 or lines > 20 or lesson.get("_line") != 0: return _fail("Replay lesson cursor/content changed before ordinary continuation")
	for line in lines:
		if not retained.call() or not _refusal_context("cutscene", lesson, scene) or lesson.get("_row") != row or lesson.get("_line") != line:
			return _fail("actual Replay lesson changed identity/content during continuation")
		await travel.tap("menu_confirm")
	var released: bool = false
	for frame in 180:
		if not retained.call(): return _fail("actual owner/scene changed during Replay release")
		if is_instance_valid(lesson) and lesson.call("is_open") == false and lesson.call("owns_input") == false \
			and INPUT_OWNER.current(tree) == null and not tree.paused: released = true; break
		await tree.process_frame
	var after_flags: Array = local.get("flags").call("all_set")
	after_flags.sort()
	var unchanged: bool = tree.current_scene == scene and game.call("find_player") == actor and game.get("world") == world \
		and game.get("local") == local and local.get("character_id") == character and game.get("session") == session \
		and session.call("_altar_current_epoch") == epoch and _inventory() == before_inventory and game.get("hotbar") == before_bar \
		and after_flags == before_flags and local.get("redesign_character").get("transaction_receipts") == before_receipts
	receipts.append({"phase": "settings_home_key_replay", "input": ["inventory", "menu_tab_right", "ui_accept", "hotbar_5", "menu_confirm"],
		"lesson": row.get("id"), "conversation": row.get("conversation"), "confirmed_lines": lines,
		"owner": character, "epoch": epoch, "released": released, "flags_unchanged": after_flags == before_flags,
		"transaction_receipts_unchanged": local.get("redesign_character").get("transaction_receipts") == before_receipts,
		"unchanged": unchanged, "passed": released and unchanged})
	return (released and unchanged) or _fail("ordinary Replay failed to release input or changed owned progression/receipts/inventory")

func shop_key_offer_absent(panel: Node) -> bool:
	if panel == null or panel.get_script().resource_path != "res://scripts/ui/shop_panel.gd" \
		or panel.call("is_open") != true or INPUT_OWNER.current(tree) != panel:
		return _fail("actual open shop must own input for sell-offer observation")
	var vendor: String = panel.call("vendor_id")
	if vendor not in ["mira", "bram"]: return _fail("unexpected actual shop vendor: " + vendor)
	var before: Array = _inventory()
	var inventory: RefCounted = game.get("inventory")
	var db: RefCounted = game.get("items")
	var trade: RefCounted = panel.get("_trade")
	var column: Control = panel.get("_sell_column")
	if trade == null or column == null or not column.is_visible_in_tree() or inventory.call("count", "home_key") != 1:
		return _fail("actual sell rows/earned Home Key missing")
	var key_name: String = db.call("item_name", "home_key")
	var expected: Array[String] = []
	var traded: Array = trade.call("traded_ids", vendor)
	for raw: Variant in traded:
		var item: String = str(raw)
		var count: int = inventory.call("count", item)
		if trade.call("buys", vendor, item) == true and count > 0:
			expected.append("%s x%d" % [str(db.call("item_name", item)), count])
	var offered: Array[String] = []
	var labels: Array[String] = []
	for child: Node in column.get_children():
		var control: Control = child as Control
		if child.is_queued_for_deletion() or control == null or not control.is_visible_in_tree(): continue
		if child is Button:
			var row_labels: Array[Node] = child.find_children("*", "Label", true, false)
			if child.disabled or child.focus_mode != Control.FOCUS_ALL or row_labels.is_empty(): return _fail("actual sale offer lacks its controller row")
			offered.append(str(row_labels[0].get("text")))
			for candidate: Node in row_labels:
				var label: Label = candidate as Label
				if label != null and not label.is_queued_for_deletion() and label.is_visible_in_tree(): labels.append(label.text)
		elif child is Label: labels.append(child.text)
	var absent: bool = not key_name.is_empty()
	for label: String in labels:
		if label.contains(key_name): absent = false
	var unchanged: bool = _inventory() == before and inventory.call("count", "home_key") == 1
	var complete: bool = offered == expected and (not offered.is_empty() or labels.has("(nothing she wants)"))
	receipts.append({"phase": "shop_key_offer_absent", "vendor": vendor, "reachable_sell_offers": offered,
		"visible_sell_labels": labels, "home_key_name": key_name, "home_key_in_traded_ids": traded.has("home_key"),
		"vendor_buys_home_key": trade.call("buys", vendor, "home_key"), "home_keys": inventory.call("count", "home_key"),
		"inventory_unchanged": unchanged, "attempted_sale": false, "passed": absent and complete and unchanged})
	return (absent and complete and unchanged) or _fail("actual shop offered the retained Home Key or sell rows did not match actual vendor stock")

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
