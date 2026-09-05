extends SceneTree

## Production realm entry, real prompts/dialogue/rest, then disk reload and
## scene reconstruction. Warps between authored sites keep this a bounded
## interaction/persistence smoke; it does not claim continuous route evidence.
const SAVE := preload("res://scripts/save/save_game.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const NIGHT := preload("res://scripts/world/night_rest.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const QUEST_TAB := preload("res://scripts/ui/tab_quest_log.gd")
const GAME_MENU := preload("res://scripts/ui/game_menu.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const TEST_SAVE_DIR := "user://cloudreach_act_one_smoke"
var _failures: Array[String] = []
var _game: Node
var _world: Node3D
var _player: CharacterBody3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new(TEST_SAVE_DIR))
	var flags: RefCounted = _game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	var source := Node3D.new()
	root.add_child(source)
	current_scene = source
	var gate := REALM_GATE.new()
	gate.call("setup", "cloudreach", "cloudreach_arrival_from_meadows", "Cloudreach Cliffs",
		"realm_key_cloudreach", "realm_gate_cloudreach_unlocked")
	source.add_child(gate)
	_expect(bool(gate.call("try_unlock", _game)), "realm gate unlock")
	_expect(bool(gate.call("try_enter", _game)), "realm gate entry")
	await _wait_world()
	var log: RefCounted = _game.get("quest_log")
	_expect(str(log.call("tracked_id", flags)) == "cloudreach_arrive", "entry selects Cloudreach feed")
	_expect(not bool(flags.call("has", "cloudreach_chapter_started")), "arrival requires reaching camp")
	var chapter := _world.get_node(^"CloudreachChapter")
	var physical := chapter.call("physical_runtime") as Node3D
	_expect(physical != null and physical.name == "PhysicalRuntime", "single full physical runtime is installed")
	_expect(chapter.call("events_adapter") == chapter.get_node(^"Events"), "public event adapter retains shared chapter store")
	var bodies: Dictionary = chapter.call("npc_bodies")
	_expect(bodies.size() == 11, "full canonical cast is instantiated")
	var aila := bodies.get("warden_aila") as Node3D
	_expect(_world.find_children("Warden Aila", "", true, false).size() == 1, "exactly one Aila body")
	_expect(_world.find_children("cr_pickup_lower_good_candy", "", true, false).size() == 1, "exactly one lower candy cache")
	_expect(_world.find_children("galefoot_waycamp", "", true, false).size() == 1, "exactly one Galefoot camp")
	_expect(chapter.get_node_or_null(^"People") == null and chapter.get_node_or_null(^"GalefootRest") == null, "opening-only cast/camp builders are removed")
	_expect(absf(aila.global_position.y - 180.0) < 0.5, "Aila uses intended camp elevation")
	await _approach(aila.get_node(^"Interactable") as Node3D, Vector3(0, 0, -2.2))
	_expect(bool(flags.call("has", "cloudreach_chapter_started")), "camp arrival event")
	_expect(str(log.call("tracked_id", flags)) == "cloudreach_learn_crisis", "camp arrival advances feed")
	await _press(aila.get_node(^"Interactable"))
	var panel := _world.get_node(^"DialoguePanel")
	_expect(bool(panel.call("is_open")), "Aila opens production dialogue panel")
	for _line in 3:
		await _tap_interact()
	_expect(not bool(panel.call("is_open")), "conversation closes through input")
	await process_frame
	_expect(bool(flags.call("has", "cloudreach_crisis_learned")), "dialogue effect advances chapter without Meadows director")
	_expect(str(log.call("tracked_text", flags)).ends_with("0/2"), "HUD feed starts 0/2")
	var tab := QUEST_TAB.new()
	var menu := GAME_MENU.new()
	menu.set("game", _game)
	tab.set("menu", menu)
	_world.add_child(tab)
	tab.call("build")
	_expect(str((tab.get("_log") as RefCounted).call("tracked_text", flags)).ends_with("0/2"), "menu quest feed agrees with HUD realm")
	tab.queue_free()
	menu.free()
	await _approach(chapter.get_node(^"lower_west/Interactable") as Node3D)
	await _press(chapter.get_node(^"lower_west/Interactable"))
	_expect(str(log.call("tracked_text", flags)).ends_with("1/2"), "first anchor feed 1/2")
	await _approach(chapter.get_node(^"lower_east/Interactable") as Node3D)
	await _press(chapter.get_node(^"lower_east/Interactable"))
	_expect(bool(flags.call("has", "cloudreach_lower_anchors_investigated")), "aggregate anchor completion is durable")
	_expect(str(log.call("main_entries", flags)[2]["label"]).ends_with("2/2"), "completed task retains 2/2")
	var cache := physical.get_node(^"cr_pickup_lower_good_candy")
	_expect(ResourceLoader.exists("res://assets/props/candy_pickup/candy_pickup.glb"), "production candy mesh imported")
	var inventory: RefCounted = _game.get("inventory")
	var candy_before := int(inventory.call("count", "good_candy"))
	await _approach(cache.get_node(^"Interactable") as Node3D)
	var full_inventory := INVENTORY.new(_game.get("items"))
	full_inventory.add("wood", 99999)
	_game.set("inventory", full_inventory)
	await _press(cache.get_node(^"Interactable"))
	_expect(cache.visible and not CACHE.was_taken(_game, "good_candy", "cr_pickup_lower_good_candy", "cloudreach"),
		"full satchel refuses without consuming the placement")
	_game.set("inventory", inventory)
	await _press(cache.get_node(^"Interactable"))
	_expect(int(inventory.call("count", "good_candy")) == candy_before + 1, "one Good Candy awarded")
	_expect(CACHE.was_taken(_game, "good_candy", "cr_pickup_lower_good_candy", "cloudreach"), "placement flag saved")
	_expect(not CACHE.was_taken(_game, "good_candy", "cr_pickup_bridge_good_candy", "cloudreach"), "second Good Candy remains independent")
	var rest := physical.get_node(^"galefoot_waycamp")
	await _approach(rest.get_node(^"Interactable") as Node3D)
	var day_before := int(_game.get("day"))
	await _press(rest.get_node(^"Interactable"))
	await create_timer(1.9).timeout
	_expect(int(_game.get("day")) == day_before + 1, "rest advances day once")
	var slot := int(_game.call("autosave_slot"))
	var saved_at := _player.global_position
	# Discard live state before loading disk, then rebuild the registered scene.
	_game.call("reset_for_new_game")
	_expect(bool(_game.call("load_game", slot)), "rest autosave reloads")
	_expect(str(_game.get("current_realm")) == "cloudreach", "save restores realm")
	_expect(change_scene_to_file(str(_game.call("current_realm_scene"))) == OK, "reload reconstructs Cloudreach")
	await _wait_world()
	flags = _game.get("progression")
	log = _game.get("quest_log")
	chapter = _world.get_node(^"CloudreachChapter")
	physical = chapter.call("physical_runtime") as Node3D
	_expect(bool(flags.call("has", "cloudreach_lower_anchors_investigated")), "reload preserves chapter completion")
	_expect(str(log.call("tracked_id", flags)) == "cloudreach_reconnect_survivors", "reload preserves next objective")
	_expect(physical.get_node_or_null(^"cr_pickup_lower_good_candy") == null, "collected placement absent on reload")
	_expect(physical.get_node_or_null(^"cr_pickup_bridge_good_candy") != null, "other same-item placement survives reload")
	_expect(_world.find_children("Warden Aila", "", true, false).size() == 1, "reload retains exactly one Aila")
	_expect(_world.find_children("galefoot_waycamp", "", true, false).size() == 1, "reload retains exactly one Galefoot camp")
	_expect(_player.global_position.distance_to(saved_at) < 2.0, "rest saved the Cloudreach pose")
	_expect(int((_game.get("inventory") as RefCounted).call("count", "good_candy")) == candy_before + 1, "reload preserves awarded candy")
	for failure: String in _failures:
		push_error("CLOUDREACH ACT ONE: " + failure)
	print("CLOUDREACH ACT ONE %s entry -> camp -> Aila -> anchors 0/2 1/2 2/2 -> candy -> rest -> disk reload" % ("OK" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)


func _wait_world() -> void:
	for _frame in 600:
		await process_frame
		if current_scene != null and current_scene.name == "CloudreachCliffs":
			_world = current_scene as Node3D
			_player = _world.get_node(^"Player") as CharacterBody3D
			for _settle in 12:
				await physics_frame
			return
	push_error("Cloudreach scene failed to load")
	quit(1)


func _approach(prompt: Node3D, offset := Vector3(0, 0, -1.6)) -> void:
	var at := prompt.global_position + offset
	at.y = float(_world.call("ground_height_near", Vector3(at.x, prompt.global_position.y, at.z))) + 0.08
	_expect(not is_nan(at.y), "interaction approach has physical ground: " + str(prompt.get_path()))
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	for _frame in 12:
		await physics_frame
	_expect(_player.is_on_floor(), "player settles on ground beside " + str(prompt.get_path()))


func _press(prompt: Node) -> void:
	var arbiter := _world.get_node(^"InteractionArbiter")
	arbiter.call("_recompute")
	_expect(arbiter.get("_winning_provider") == prompt, "arbiter selects " + str(prompt.get_path()))
	await _tap_interact()


func _tap_interact() -> void:
	for _frame in 3:
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	for _frame in 3:
		await physics_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
