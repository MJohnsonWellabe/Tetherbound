extends SceneTree

## OWNER-0912, runtime half for the South Bridge route prompt and Nessa's
## overlook payoff.
##
##   godot --headless --path . --script tests/smoke_meadows_route_prompt_nessa_0912.gd
##
## This boots the production Meadows once and drives both people through their
## actual placed `Interactable`: prompt signal -> `VillageNPCs._on_greeted()` ->
## live `greeting_when` selection -> shared DialoguePanel/DialogueRunner ->
## SequenceDirector's real `flag:`/`give:` effect drain. It then saves through
## `Game.save_game()` and reloads through `Game.load_game()` with the production
## SaveGame implementation pointed at a smoke-only directory.
##
## Deliberate evidence boundary: the player body is repositioned into greeting
## range. This proves placement, grounding, prompt proximity, branch retirement,
## effect delivery and one local character's persistence; it does not claim the
## 1.3 km route was walked, that either detour reads visually, or that two-peer
## isolation works. `test_meadows_route_prompt_0912.gd` separately pins both
## payoff flags to player scope; this smoke also verifies the effects landed in
## the live local store and not the live world store.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const SETTLE_FRAMES := 300
const SAVE_DIR := "user://smoke_meadows_route_prompt_nessa_0912/"
const SAVE_SLOT := 0

const TOBIN := "Tobin"
const NESSA := "Nessa"
const ROAD_GATE_FLAG := "road_gate_open"
const BRIDGE_OPEN_FLAG := "south_bridge_open"
const ROUTE_HEARD_FLAG := "south_bridge_team_prompt_heard"
const NESSA_GIFT_FLAG := "nessa_overlook_gift_taken"
const ROUTE_CONVERSATION := "village_south_bridge_team_prompt"
const NESSA_GIFT_CONVERSATION := "village_nessa_overlook_gift"
const BERRIES := "berries"

## A harmless already-completed world beat stands the opening down before the
## scene boots. Without it, a fresh SceneTree correctly starts Grandpa's modal
## opening over the two conversations this bounded smoke is trying to drive.
const OPENING_BYPASS_FLAG := "trainer_defeated_practice"

const POSITION_TOLERANCE_M := 0.15
const GROUND_TOLERANCE_M := 0.08
const APPROACH_OFFSET := Vector3(0.0, 0.0, 1.35)

var _failures: Array[String] = []
var _game: Node = null
var _world: Node3D = null
var _player: CharacterBody3D = null
var _villagers: Node3D = null
var _panel: CanvasLayer = null
var _tobin_spec: Dictionary = {}
var _nessa_spec: Dictionary = {}
var _last_finished := ""


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	if not _prepare_game():
		_report()
		return
	if not await _boot_meadows():
		_report()
		return

	_tobin_spec = _villager_spec(TOBIN)
	_nessa_spec = _villager_spec(NESSA)
	if _tobin_spec.is_empty() or _nessa_spec.is_empty():
		if _tobin_spec.is_empty():
			_fail("village_npcs.json has no Tobin entry")
		if _nessa_spec.is_empty():
			_fail("village_npcs.json has no Nessa entry")
		_report()
		return

	_panel.connect("finished", _on_dialogue_finished)
	_reset_feature_state()
	_assert_personal_scope_contract()
	_assert_nessa_is_grounded_and_reachable()
	await _exercise_route_prompt()
	await _exercise_nessa_gift()
	await _exercise_save_load_retirement()
	_report()


func _prepare_game() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("no /root/Game autoload; there is no production state to drive")
		return false
	_game.call("reset_for_new_game")
	_remove_tree(ProjectSettings.globalize_path(SAVE_DIR))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_game.set("save_system", SAVE_GAME.new(SAVE_DIR))
	_progression().call("set_flag", OPENING_BYPASS_FLAG)
	return true


func _boot_meadows() -> bool:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load %s" % SCENE)
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_villagers = _world.get_node_or_null(^"VillageNPCs") as Node3D
	_panel = _world.get_node_or_null(^"DialoguePanel") as CanvasLayer
	if _player == null or _villagers == null or _panel == null:
		_fail("Meadows did not build Player, VillageNPCs and DialoguePanel within %d physics frames" % SETTLE_FRAMES)
		return false
	return true


func _reset_feature_state() -> void:
	var progression := _progression()
	for flag: String in [ROAD_GATE_FLAG, BRIDGE_OPEN_FLAG, ROUTE_HEARD_FLAG, NESSA_GIFT_FLAG]:
		progression.call("set_flag", flag, false)


func _assert_personal_scope_contract() -> void:
	for flag: String in [ROUTE_HEARD_FLAG, NESSA_GIFT_FLAG]:
		var scope := PROGRESSION_STATE.scope_of(flag)
		if scope != PROGRESSION_STATE.SCOPE_PLAYER:
			_fail("'%s' is scope '%s', not personal/player scope" % [flag, scope])


## Nessa's body is checked against the production height query and her real
## prompt is asked from the real player body's nearby position. The later gift
## exercise activates this same prompt, so this is not merely config arithmetic.
func _assert_nessa_is_grounded_and_reachable() -> void:
	var nessa := _body_for(NESSA)
	if nessa == null:
		_fail("Nessa was not placed under the production VillageNPCs node")
		return
	var expected := _xz(_nessa_spec)
	var actual := Vector2(nessa.global_position.x, nessa.global_position.z)
	if actual.distance_to(expected) > POSITION_TOLERANCE_M:
		_fail("Nessa stands at %s, %.2f m from her configured overlook position %s" % [
			actual, actual.distance_to(expected), expected])

	var ground := float(_world.call("ground_height_at", expected.x, expected.y))
	if is_nan(ground):
		_fail("Nessa's configured overlook has no production ground height")
	elif absf(nessa.global_position.y - ground) > GROUND_TOLERANCE_M:
		_fail("Nessa is %.3f m off the production ground" % absf(nessa.global_position.y - ground))

	var prompt := nessa.call("prompt_node") as Node3D
	if prompt == null:
		_fail("Nessa has no configured greeting prompt")
		return
	_place_player_near(nessa)
	var offer := prompt.call("interaction_offer", _player.global_position) as Dictionary
	if offer.is_empty():
		_fail("Nessa's real prompt makes no offer from %.2f m away" % _player.global_position.distance_to(prompt.global_position))
	elif str(offer.get("label", "")) != "Greet Nessa":
		_fail("Nessa's nearby prompt says '%s', not 'Greet Nessa'" % str(offer.get("label", "")))


func _exercise_route_prompt() -> void:
	var progression := _progression()
	var fallback := str(_tobin_spec.get("greeting", ""))
	if VILLAGE_NPCS.greeting_for(_tobin_spec, progression) != fallback:
		_fail("Tobin offers route advice before the road gate opens")

	progression.call("set_flag", ROAD_GATE_FLAG)
	if VILLAGE_NPCS.greeting_for(_tobin_spec, progression) != ROUTE_CONVERSATION:
		_fail("Tobin did not select the route prompt after road_gate_open")
		return
	await _greet_through_real_prompt(TOBIN, ROUTE_CONVERSATION)
	_assert_personal_flag_landed(ROUTE_HEARD_FLAG)

	var retired := VILLAGE_NPCS.greeting_for(_tobin_spec, progression)
	if retired != fallback:
		_fail("Tobin's one-shot route prompt did not retire to '%s'; got '%s'" % [fallback, retired])
	else:
		await _greet_through_real_prompt(TOBIN, fallback)
	if not bool(progression.call("has", ROUTE_HEARD_FLAG)):
		_fail("Tobin's fallback greeting cleared the heard flag")


func _exercise_nessa_gift() -> void:
	var progression := _progression()
	var inventory := _inventory()
	var fallback := str(_nessa_spec.get("greeting", ""))
	if VILLAGE_NPCS.greeting_for(_nessa_spec, progression) != NESSA_GIFT_CONVERSATION:
		_fail("Nessa did not select her untaken overlook gift")
		return

	var before := int(inventory.call("count", BERRIES))
	await _greet_through_real_prompt(NESSA, NESSA_GIFT_CONVERSATION)
	var after := int(inventory.call("count", BERRIES))
	if after != before + 3:
		_fail("Nessa's real dialogue/effect path should add 3 berries; %d -> %d" % [before, after])
	_assert_personal_flag_landed(NESSA_GIFT_FLAG)

	var retired := VILLAGE_NPCS.greeting_for(_nessa_spec, progression)
	if retired != fallback:
		_fail("Nessa's gift did not retire to '%s'; got '%s'" % [fallback, retired])
		return
	await _greet_through_real_prompt(NESSA, fallback)
	if int(inventory.call("count", BERRIES)) != after:
		_fail("Nessa's fallback greeting paid the three-berry gift again")


func _exercise_save_load_retirement() -> void:
	var progression := _progression()
	var inventory := _inventory()
	var saved_berries := int(inventory.call("count", BERRIES))
	if not bool(_game.call("save_game", SAVE_SLOT)):
		_fail("Game.save_game refused the isolated smoke slot")
		return

	# Abandon the earned state in memory, then require load to reconstruct it.
	progression.call("set_flag", ROUTE_HEARD_FLAG, false)
	progression.call("set_flag", NESSA_GIFT_FLAG, false)
	if not bool(inventory.call("remove", BERRIES, 3)):
		_fail("could not remove Nessa's three berries for the load precondition")
		return
	if VILLAGE_NPCS.greeting_for(_nessa_spec, progression) != NESSA_GIFT_CONVERSATION:
		_fail("the pre-load mutation did not make Nessa's gift available again")

	if not bool(_game.call("load_game", SAVE_SLOT)):
		_fail("Game.load_game refused the isolated smoke slot")
		return
	await process_frame
	progression = _progression()
	inventory = _inventory()
	if not bool(progression.call("has", ROUTE_HEARD_FLAG)):
		_fail("save/load lost Tobin's personal heard flag")
	if not bool(progression.call("has", NESSA_GIFT_FLAG)):
		_fail("save/load lost Nessa's personal gift flag")
	if int(inventory.call("count", BERRIES)) != saved_berries:
		_fail("save/load restored %d berries, expected %d" % [
			int(inventory.call("count", BERRIES)), saved_berries])
	_assert_personal_flag_landed(ROUTE_HEARD_FLAG)
	_assert_personal_flag_landed(NESSA_GIFT_FLAG)

	# Drive both real prompts once more after load. Their fallback branches must
	# stay effect-free; otherwise a persisted one-shot can still repay on resume.
	var before_revisit := int(inventory.call("count", BERRIES))
	await _greet_through_real_prompt(TOBIN, str(_tobin_spec.get("greeting", "")))
	await _greet_through_real_prompt(NESSA, str(_nessa_spec.get("greeting", "")))
	if int(inventory.call("count", BERRIES)) != before_revisit:
		_fail("post-load fallback greetings replayed Nessa's gift")


## Repositioning is intentional and bounded: this smoke proves a nearby real
## player can see and activate the actual prompt, not traversal to the POI.
func _greet_through_real_prompt(who: String, expected_conversation: String) -> void:
	var body := _body_for(who)
	if body == null:
		_fail("%s has no placed production body" % who)
		return
	var prompt := body.call("prompt_node") as Node3D
	if prompt == null:
		_fail("%s has no placed production greeting prompt" % who)
		return
	if bool(_panel.call("is_open")):
		_panel.call("close")
		await process_frame

	_place_player_near(body)
	await physics_frame
	var offer := prompt.call("interaction_offer", _player.global_position) as Dictionary
	if offer.is_empty():
		_fail("%s's prompt is not available from the nearby production player" % who)
		return

	_last_finished = ""
	prompt.call("interaction_activate")
	await process_frame
	if not bool(_panel.call("is_open")):
		_fail("activating %s's real prompt opened no dialogue" % who)
		return
	var opened := str((_panel.call("runner") as RefCounted).call("conversation_id"))
	if opened != expected_conversation:
		_fail("%s's real prompt opened '%s', expected '%s'" % [who, opened, expected_conversation])

	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("%s's '%s' dialogue never closed" % [who, expected_conversation])
	elif _last_finished != expected_conversation:
		_fail("%s's dialogue finished as '%s', expected '%s'" % [who, _last_finished, expected_conversation])


func _assert_personal_flag_landed(flag: String) -> void:
	var player_flags := (_game.get("local") as RefCounted).get("flags") as RefCounted
	var world_flags := (_game.get("world") as RefCounted).get("flags") as RefCounted
	if player_flags == null or not bool(player_flags.call("has", flag)):
		_fail("'%s' did not land in the live local player's flag store" % flag)
	if world_flags != null and bool(world_flags.call("has", flag)):
		_fail("personal flag '%s' leaked into the live world flag store" % flag)


func _place_player_near(body: Node3D) -> void:
	_player.global_position = body.global_position + APPROACH_OFFSET
	_player.velocity = Vector3.ZERO


func _body_for(who: String) -> Node3D:
	return _villagers.get_node_or_null(NodePath(who)) as Node3D


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted


func _inventory() -> RefCounted:
	return _game.get("inventory") as RefCounted


func _villager_spec(who: String) -> Dictionary:
	var file := FileAccess.open(VILLAGERS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for raw: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("name", "")) == who:
			return (raw as Dictionary).duplicate(true)
	return {}


func _xz(spec: Dictionary) -> Vector2:
	var raw: Array = spec.get("position", []) as Array
	if raw.size() >= 3:
		return Vector2(float(raw[0]), float(raw[2]))
	if raw.size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO


func _on_dialogue_finished(conversation_id: String) -> void:
	_last_finished = conversation_id


func _fail(message: String) -> void:
	_failures.append(message)


func _remove_tree(absolute_path: String) -> void:
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := absolute_path.path_join(name)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _report() -> void:
	_remove_tree(ProjectSettings.globalize_path(SAVE_DIR))
	print("")
	if _failures.is_empty():
		print("Meadows route/Nessa: OK — both placed prompts drove their production dialogue/effect paths once, retired to fallback, and their personal flags plus Nessa's berries survived Game save/load without replay.")
		quit(0)
		return
	for line: String in _failures:
		print("Meadows route/Nessa FAIL: %s" % line)
	quit(1)
