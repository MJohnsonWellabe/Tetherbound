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
	await travel.tap("inventory")
	var menu: Node = game.call("menu")
	if menu == null or menu.call("is_open") != true or menu.call("current_tab_id") != "backpack":
		return _fail("actual Satchel did not open for protection check")
	var tab: Node = (menu.get("_bodies") as Array)[0]
	var care := CARE.new()
	care.set("_tree", tree)
	if not await care.call("_focus_slot", tab.get("_buttons"), slot): return _fail("controller focus did not reach earned key")
	await travel.tap("backpack_drop")
	var rows: Array = tab.get("_confirm_rows")
	if int(tab.get("_confirming")) != slot or rows.is_empty() or tree.root.gui_get_focus_owner() != rows[0]:
		return _fail("actual Drop confirmation was not offered for selected key")
	await travel.tap("ui_accept")
	var reason: Label = menu.get("_status")
	if inventory.call("count", "home_key") != 1 or _inventory() != before or int(tab.get("_confirming")) != -1 \
		or reason == null or reason.text != "Keys stay with their owner." or not reason.is_visible_in_tree():
		return _fail("actual protected-key Drop did not visibly refuse without changing inventory")
	receipts.append({"phase": "protected_drop", "input": ["inventory", "backpack_drop", "ui_accept"],
		"reason": reason.text, "home_keys": inventory.call("count", "home_key"), "inventory_unchanged": true})
	if not await care.call("_focus_slot", tab.get("_buttons"), slot): return _fail("key focus not restored after Drop refusal")
	# Cycle the real assignment verb; never write the quick bar directly.
	for attempt in 2:
		await travel.tap("backpack_assign")
		if int(game.call("hotbar_slot_of", "home_key")) >= 0: break
	var binding := int(game.call("hotbar_slot_of", "home_key"))
	if binding < 0 or binding >= 5 or inventory.call("count", "home_key") != 1:
		return _fail("actual Satchel assignment did not bind retained key")
	receipts.append({"phase": "key_binding", "slot": binding, "input": "backpack_assign", "home_keys": 1})
	await travel.tap("menu_cancel")
	for frame in 30:
		await tree.physics_frame
		if INPUT_OWNER.current(tree) == null: return true
	return _fail("key protection menu did not release input")

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
