extends SceneTree

## RG1 (owner playtest, 2026-08-18): "The game seems to freeze a lot after
## coming out of an interaction or menu. Like interacting with the trader at
## the beginning then it freezes. Doing a build, then it freezes."
##
##   godot --headless --path . --script tests/smoke_post_modal_control.gd
##
## `smoke_modal_stacking.gd` already proves the pause shell REFUSES to open
## over a modal; it never checks what happens once that modal closes on its
## own. This is the other half: drive a real conversation-into-shop (the
## trader) and a real build (ghost -> plant) to completion in the full
## Meadows playground, through real input, and prove the world is still
## alive afterward -- movement moves the player, `interact` reaches a real
## provider again, and nothing is left owning input or holding the tree
## paused. A freeze that "looks exactly like" a panel that registered as
## input_owner and never deregistered (input_owner.gd's own worry) or a
## pause that never got handed back would show up here as the player simply
## not moving when told to.
##
## Two real repros named, so two checks: the trader (dialogue -> shop ->
## close) and a build (armed -> ghost -> planted). Both run in the SAME
## world, one after the other, so a freeze left behind by the first would
## also fail the second -- which is useful signal, not noise, if it happens.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null
var _world: Node = null
var _player: CharacterBody3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_menu = _game.call("menu") if _game != null else null
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _game == null or _menu == null or _player == null:
		print("FAIL: world did not stand up Game/menu/Player; nothing to test")
		quit(1)
		return

	await _check_control_survives_a_trader_conversation_and_shop()
	await _check_pause_menu_to_build_handoff()
	await _check_control_survives_placing_a_build()

	_cleanup()
	print("")
	if _failures.is_empty():
		print("post-modal control smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## Proves control comes back: nobody owns input, the tree is not paused, and
## holding a real movement key actually moves the player -- the same measure
## `smoke_input.gd` uses for "the game responds at all".
func _assert_control_returned(context: String) -> void:
	if paused:
		_fail("%s: the tree is still paused after everything closed" % context)
		return
	var owner_node: Node = INPUT_OWNER.current(self)
	if owner_node != null:
		_fail("%s: '%s' still owns input after everything closed" % [context, owner_node.name])
		return

	var start := _player.global_position
	_player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
	var drift := Vector2(_player.global_position.x - start.x, _player.global_position.z - start.z).length()
	if drift < 0.3:
		_fail("%s: holding move_forward moved the player %.2fm -- the world reads as frozen" % [context, drift])
	else:
		print("%s: control returned (moved %.2fm, nothing owns input, tree unpaused)" % [context, drift])


## The trader: start Mira's shop-opening conversation on the one shared
## dialogue panel every villager and the opening both drive
## (`village_npcs.gd`, `scripts/story/sequence_director.gd`), advance it for
## real with `interact`, let the shop queue and open the way
## `sequence_director._maybe_open_shop` does every frame, then close the
## shop for real and check the world is still alive.
func _check_control_survives_a_trader_conversation_and_shop() -> void:
	var panel: Node = get_first_node_in_group("dialogue_panel")
	if panel == null:
		_fail("trader: no dialogue_panel in the world; cannot reproduce the report")
		return
	if not bool(panel.call("start", "village_mira_shop_intro")):
		_fail("trader: 'village_mira_shop_intro' would not start; data/dialogue/village.json may have moved")
		return

	# Advance through every line with a real `interact` press, the same button
	# the owner used, until the box closes on its own.
	var guard := 0
	while bool(panel.call("is_open")) and guard < 20:
		Input.action_press("interact")
		await physics_frame
		await physics_frame
		Input.action_release("interact")
		for i in 6:
			await physics_frame
		guard += 1
	if bool(panel.call("is_open")):
		_fail("trader: the conversation never closed after %d real interact presses" % guard)
		return

	# The shop is queued by `sequence_director._drain_effects` and opened by
	# `_maybe_open_shop` on a later frame, same as production timing.
	var shop: Node = null
	for i in 20:
		await physics_frame
		for node: Node in root.get_children():
			if node.has_method("vendor_id") and node.has_method("is_open") and bool(node.call("is_open")):
				shop = node
				break
		if shop != null:
			break
	if shop == null:
		_fail("trader: Mira's shop-opening line never opened a shop panel")
		return
	print("trader: shop opened after a real conversation")

	shop.call("close")
	for i in 10:
		await physics_frame
	if bool(shop.call("is_open")):
		_fail("trader: the shop panel would not close")
		return

	await _assert_control_returned("trader")


## Owner's severe repro: Pause/Main menu -> Build -> Open Build Menu. This must
## hand pause ownership back before the live-world build surface opens.
func _check_pause_menu_to_build_handoff() -> void:
	if not bool(_menu.call("open", "build")):
		_fail("pause->build: pause menu refused to open on Build tab")
		return
	for i in 3:
		await process_frame
	if not paused:
		_fail("pause->build: pause menu did not pause the tree")
		return

	var launch: Button = _find_button_with_text(_menu, "Open Build Menu")
	if launch == null:
		_fail("pause->build: Build tab has no Open Build Menu button")
		_menu.call("close")
		return
	launch.emit_signal("pressed")
	for i in 5:
		await process_frame

	if paused:
		_fail("pause->build: tree stayed paused after handoff to live build menu")
		return
	if bool(_menu.call("is_open")):
		_fail("pause->build: pause shell remained open after handoff")
		return

	var build_menu: Node = null
	for node: Node in root.get_children():
		if node.name == "BuildMenu" and node.has_method("is_open") and bool(node.call("is_open")):
			build_menu = node
			break
	if build_menu == null:
		_fail("pause->build: live BuildMenu never opened")
		return
	build_menu.call("close")
	for i in 3:
		await process_frame
	await _assert_control_returned("pause->build")


func _find_button_with_text(node: Node, needle: String) -> Button:
	if node is Button and needle in (node as Button).text:
		return node as Button
	for child: Node in node.get_children():
		var found := _find_button_with_text(child, needle)
		if found != null:
			return found
	return null


## A build: arm a camp (free build, so cost is not the variable under test),
## let the ghost draw, plant it with a real `build_place` press -- the
## owner's other named repro -- and check the world is still alive after.
func _check_control_survives_placing_a_build() -> void:
	_game.set("free_build", true)
	_player.global_position += (-_player.global_transform.basis.z) * 20.0
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var placer := _world.get_node_or_null(^"BuildPlacer")
	if placer == null:
		_fail("build: no BuildPlacer in the world; cannot reproduce the report")
		_game.set("free_build", false)
		return

	_game.set("pending_build", "workbench")
	for i in 20:
		await physics_frame
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame

	var placed := false
	for node: Node in _world.get_tree().get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == "workbench":
			placed = true
	if not placed:
		_fail("build: pressing build_place with a legal free-build ghost planted nothing")
		_game.set("free_build", false)
		return
	print("build: a workbench was planted with a real build_place press")

	_game.set("free_build", false)
	await _assert_control_returned("build")


func _cleanup() -> void:
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
	if paused:
		paused = false
