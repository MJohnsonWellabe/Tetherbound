extends SceneTree

## Component input/presentation fixture, NOT ordinary gameplay refusal proof.
## Actual parsed binding and actual HomeKey observer/toast, with fake refusal
## context and modal. No actual fight, dialogue, swim, flight or cutscene.
const KEY := preload("res://scripts/world/home_key.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")

class FixtureGame extends Node:
	var inventory: RefCounted = preload("res://autoload/inventory.gd").new(preload("res://autoload/item_db.gd").new())
	var hotbar: Array[String] = ["home_key", "", "", "", ""]
	var actor: CharacterBody3D
	var reason := "Not during a fight."
	var requests := 0
	var messages: Array[String] = []
	func find_player() -> Node3D: return actor
	func home_key_refusal() -> String: return reason
	func request_portal_action(_payload: Dictionary) -> Dictionary:
		requests += 1
		return {"ok": false}
	func push_world_message(message: String) -> void: messages.append(message)

class Modal extends Node:
	func owns_input() -> bool: return true

class Fight extends Node:
	var aiming := false
	func presenting_fight() -> bool: return true
	func is_aiming() -> bool: return aiming

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	await process_frame
	await process_frame
	var actual_game := root.get_node(^"Game")
	var composition := actual_game.get_node(^"Session/FoundationComposition")
	var mounted := actual_game.get_node_or_null(^"HomeKey")
	_check(mounted != null and mounted.get_script() == KEY and mounted.get("_phase") == "idle",
		"actual composition installs the persistent key observer before any successful use")
	composition.call("_mount_home_key")
	_check(actual_game.get_node_or_null(^"HomeKey") == mounted, "composition retry retains the same presentation owner")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var game := FixtureGame.new()
	# Disclosed inventory fixture using the real inventory implementation.
	game.inventory.add("home_key", 1)
	game.actor = CharacterBody3D.new()
	world.add_child(game.actor)
	var fight := Fight.new()
	fight.name = "CombatManager"
	world.add_child(fight)
	var modal := Modal.new()
	modal.add_to_group(OWNER.GROUP)
	world.add_child(modal)
	var key := KEY.new()
	root.add_child(key)
	key._game = game
	var before := game.actor.global_position
	_check(OWNER.current(self) == modal, "fixture modal initially owns input")
	await _press("combat_item_1")
	_check(is_instance_valid(key._refusal_label) and key._refusal_label.text == game.reason
		and key._refusal_label.is_visible_in_tree(), "blocked hotbar press presents its readable reason outside hidden HUD")
	_check(key._refusal_layer.layer > preload("res://scripts/ui/ui_tokens.gd").LAYER_MENU, "message renders above ordinary modal layers")
	_check(OWNER.current(self) == modal and key.owns_input() == false, "refusal preserves existing input owner")
	_check(game.requests == 0 and key._phase == "idle" and game.inventory.count("home_key") == 1
		and game.actor.global_position == before, "observer cannot begin travel, move owner or consume key")
	fight.aiming = true
	key._refusal_at = -INF
	var notices := game.messages.size()
	await _press("combat_item_1")
	_check(game.messages.size() == notices, "aim cancel/throw input remains untouched")
	fight.aiming = false
	key._refusal_at = -INF
	game.reason = "Finish talking first."
	paused = true
	await _press("combat_item_1")
	_check(key._refusal_label.text == game.reason and key._refusal_label.is_visible_in_tree()
		and OWNER.current(self) == modal, "paused modal still receives a reason without losing ownership")
	paused = false
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var pixels := root.get_texture().get_image()
		_check(pixels != null and not pixels.is_empty() and pixels.save_png("user://F18_HOME_KEY_REFUSAL_COMPONENT.png") == OK, "native component message screenshot saved")
	key._refusal_at = -INF
	game.reason = ""
	notices = game.messages.size()
	await _press("combat_item_1")
	_check(game.messages.size() == notices and game.requests == 0, "eligible key use remains owned by ordinary HUD route")
	key.free()
	game.free()
	world.queue_free()
	await process_frame
	print("F18_HOME_KEY_REFUSAL_COMPONENT " + JSON.stringify({"checks": checks, "failures": failures,
		"fixtures": "real inventory/parsed input/HomeKey toast; fake modal/fight/refusal state; no live gameplay acceptance"}))
	quit(0 if failures.is_empty() else 1)
