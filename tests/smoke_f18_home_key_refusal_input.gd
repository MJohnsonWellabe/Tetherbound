extends SceneTree

## Component input/presentation fixture, NOT ordinary gameplay refusal proof.
## Actual parsed binding and actual HomeKey observer/toast, with fake refusal
## context. Real lesson/system-screen presenters use disclosed fixture content;
## no actual fight, dialogue, swim, flight, cutscene or earned gameplay proof.
const KEY := preload("res://scripts/world/home_key.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
const LESSON := preload("res://scripts/onboarding/lesson_panel.gd")
const SCREEN := preload("res://scripts/ui/system_screen.gd")

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
	var presenting := true
	func presenting_fight() -> bool: return presenting
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

func _capture(path: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	_check(pixels != null and not pixels.is_empty() and pixels.save_png(path) == OK,
		"native component presenter/message screenshot saved: " + path)

func _preserved(game: FixtureGame, key: Node, owner: Node, before: Vector3, message: String) -> void:
	_check(OWNER.current(self) == owner and key.call("owns_input") == false and game.requests == 0
		and key.get("_phase") == "idle" and game.inventory.count("home_key") == 1
		and game.actor.global_position == before, message)

func _toast_observation(key: Node, expected_owner: Node) -> Dictionary:
	var layer: CanvasLayer = key.get("_refusal_layer")
	var panel: Control = key.get("_refusal_panel")
	var owner := OWNER.current(self)
	return {"layer": layer.layer if is_instance_valid(layer) else -1,
		"visible": is_instance_valid(panel) and panel.visible,
		"owner_is_expected": owner == expected_owner,
		"owner": str(owner.get_path()) if is_instance_valid(owner) else "",
		"time_left_msec": int(key.get("_refusal_until_msec")) - Time.get_ticks_msec(),
		"process_frame": Engine.get_process_frames()}

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
	key._refusal_at = -INF
	game.reason = ""
	notices = game.messages.size()
	await _press("combat_item_1")
	_check(game.messages.size() == notices and game.requests == 0, "eligible key use remains owned by ordinary HUD route")
	modal.free()
	fight.presenting = false
	game.reason = "Finish talking first."
	var lesson := LESSON.new()
	world.add_child(lesson)
	_check(lesson.open({"id": "home_key", "speaker": "Grandpa · Component fixture",
		"lines": ["Home Key lesson presentation fixture."],
		"goal": "UI fixture only; no earned gameplay acceptance."}), "actual lesson presenter opens with disclosed fixture content")
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(lesson.layer == 30 and key._refusal_layer.layer == 31
		and key._refusal_label.text == game.reason and key._refusal_label.is_visible_in_tree(),
		"assigned key refusal is structurally above actual layer-30 lesson")
	_preserved(game, key, lesson, before, "lesson refusal preserves owner, travel, inventory and actor pose")
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(key._refusal_layer.layer == 31, "repeated lesson refusal does not escalate its draw layer")
	await _capture("user://F18_HOME_KEY_REFUSAL_COMPONENT.png")
	# Keep an existing visible toast while the actual input owner changes.
	var transition_deadline: int = key._refusal_until_msec
	var transition_notices := game.messages.size()
	lesson.free()
	var screen := SCREEN.new()
	world.add_child(screen)
	_check(screen.begin("Home Key refusal · Component fixture", "UI fixture only; no earned gameplay acceptance."),
		"actual system-screen presenter opens with disclosed fixture content")
	var transition_observations: Array[Dictionary] = [_toast_observation(key, screen)]
	# process_frame emits before node _process callbacks. Two emissions allow
	# one real HomeKey process pass, without renewing the original toast timer.
	await process_frame
	transition_observations.append(_toast_observation(key, screen))
	await process_frame
	transition_observations.append(_toast_observation(key, screen))
	print("F18_HOME_KEY_REFUSAL_TRANSITION " + JSON.stringify(transition_observations))
	_check(screen.layer == 80 and key._refusal_layer.layer == 81 and key._refusal_panel.visible
		and OWNER.current(self) == screen and game.messages.size() == transition_notices
		and key._refusal_until_msec == transition_deadline and Time.get_ticks_msec() < transition_deadline,
		"visible toast follows actual input-owner change without a new refusal")
	game.reason = "Close the current screen first."
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(key._refusal_layer.layer == 81 and key._refusal_label.text == game.reason,
		"assigned key refusal is structurally above actual layer-80 system screen")
	_preserved(game, key, screen, before, "system-screen refusal preserves owner, travel, inventory and actor pose")
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(key._refusal_layer.layer == 81, "repeated system-screen refusal does not escalate its draw layer")
	await _capture("user://F18_HOME_KEY_REFUSAL_SYSTEM_COMPONENT.png")
	screen.free()
	var ancestor := CanvasLayer.new()
	ancestor.layer = 40
	world.add_child(ancestor)
	var nested_owner := Modal.new()
	nested_owner.add_to_group(OWNER.GROUP)
	ancestor.add_child(nested_owner)
	_check(key._refusal_draw_layer(nested_owner) == 41, "Node owner inherits its actual ancestor CanvasLayer draw order")
	var child_layer := CanvasLayer.new()
	child_layer.layer = 60
	nested_owner.add_child(child_layer)
	_check(key._refusal_draw_layer(nested_owner) == 61, "Node owner's child CanvasLayer contributes its draw order")
	var unrelated := CanvasLayer.new()
	unrelated.layer = 250
	root.add_child(unrelated)
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(key._refusal_layer.layer == 61, "unrelated root layer never influences the current owner's refusal")
	_preserved(game, key, nested_owner, before, "nested-owner refusal preserves owner, travel, inventory and actor pose")
	key._refusal_at = -INF
	await _press("hotbar_1")
	_check(key._refusal_layer.layer == 61, "repeated nested-owner refusal does not escalate its draw layer")
	var queued_layer := CanvasLayer.new()
	queued_layer.layer = 400
	nested_owner.add_child(queued_layer)
	queued_layer.queue_free()
	_check(key._refusal_draw_layer(nested_owner) == 61, "queued child layer contributes no draw order")
	nested_owner.queue_free()
	_check(key._refusal_draw_layer(nested_owner) == 21, "queued owner contributes no draw order")
	_check(key._refusal_draw_layer(null) == 21 and key._refusal_draw_layer(key) == 21,
		"absent owner and Home Key itself cannot feed back the toast's previous draw layer")
	await process_frame
	await process_frame
	_check(key._refusal_layer.layer == 21, "visible toast returns to baseline after its owner leaves")
	unrelated.free()
	ancestor.free()
	key.free()
	game.free()
	world.queue_free()
	await process_frame
	print("F18_HOME_KEY_REFUSAL_COMPONENT " + JSON.stringify({"checks": checks, "failures": failures,
		"fixtures": "real inventory/parsed input/HomeKey toast and lesson/system-screen presenters; fixture content/modal branches/fight/refusal state; structural checks and component captures only, no live gameplay acceptance"}))
	quit(0 if failures.is_empty() else 1)
