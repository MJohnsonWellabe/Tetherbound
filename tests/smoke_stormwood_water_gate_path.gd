extends SceneTree

## Production Stormwood -> Water seam proof.
##
## The fixture supplies only the already-earned finale prerequisite through the
## host ledger. The production Waterward view grants the Water entitlement;
## then the local player uses the real RealmGate Interactable twice through the
## live InteractionArbiter: once to atomically consume/open, once to travel.
## No debug teleport and no direct Game.enter_realm() call performs the crossing.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const STORMWOOD_DIALOGUE_PATH := "res://data/dialogue/stormwood.json"

const TEST_SAVE_DIR := "user://stormwood_water_gate_path_smoke"
const WORLD_ID := "stormwood-water-gate-path-world"
const CHARACTER_ID := "stormwood-water-gate-path-character"
const BUILD_DEADLINE_MS := 180000
const TRANSITION_DEADLINE_MS := 180000
const PROVIDER_WAIT_FRAMES := 180
const ARRIVAL_TOLERANCE_M := 2.0

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not _finished:
			_expect(false, "240 second watchdog expired")
			_finish())
	_cleanup_test_saves()
	_expect(_waterward_reveal_names_tidewake(),
		"the first Waterward reveal conversation does not introduce Tidewake by name")
	if not _failures.is_empty():
		_finish()
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	game.get("local").set("character_id", CHARACTER_ID)
	game.get("world").set("world_id", WORLD_ID)
	game.set("current_realm", "stormwood")
	game.call("bind_realm_map")
	# This focused fixture starts directly in Stormwood instead of reaching it
	# through Game.enter_realm(). Mirror that router's required Session update so
	# host-owned Stormwood intents are not correctly rejected as Meadows traffic.
	game.call("announce_realm", "meadows", "stormwood")

	var stormwood := STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(stormwood)
	current_scene = stormwood
	if not await _wait_for_shell(stormwood, BUILD_DEADLINE_MS):
		_expect(false, "production Stormwood did not finish building")
		_finish()
		return

	var ending := stormwood.get_node_or_null(^"StormwoodEnding") as Node3D
	var player := stormwood.get_node_or_null(^"Player") as CharacterBody3D
	var arbiter := stormwood.get_node_or_null(^"InteractionArbiter")
	var view_prompt := ending.get_node_or_null(^"WaterwardView") as Node3D if ending != null else null
	var gate := stormwood.get_node_or_null(^"WaterwardRealmGate") as Node3D
	var gate_prompt := gate.get_node_or_null(^"Interactable") as Node3D if gate != null else null
	_expect(ending != null and player != null and arbiter != null,
		"production Stormwood is missing its ending, local player, or InteractionArbiter")
	_expect(view_prompt != null and gate != null and gate_prompt != null,
		"production ending did not mount the Waterward view and RealmGate Interactable")
	if ending == null or player == null or arbiter == null \
			or view_prompt == null or gate == null or gate_prompt == null:
		_finish()
		return
	var gate_callbacks: Array[String] = []
	for connection: Dictionary in gate_prompt.activated.get_connections():
		var callback: Callable = connection.get("callable", Callable()) as Callable
		gate_callbacks.append(str(callback.get_method()))
	_expect(gate_callbacks.has("_on_water_activated") and not gate_callbacks.has("_on_activated"),
		"Waterward prompt did not replace the generic handler (callbacks=%s)" % str(gate_callbacks))

	_expect(not bool(game.call("world_flags").call("has", "stormwood:waterward_revealed")),
		"fresh fixture unexpectedly begins with the Waterward revealed")
	_expect(not bool(game.call("world_flags").call("has", "realm_key_water")),
		"fresh fixture unexpectedly begins with the Water key")
	_expect(not bool(game.call("world_flags").call("has", "realm_gate_water_unlocked")),
		"fresh fixture unexpectedly begins with the Water gate open")
	var ending_messages: Array[Dictionary] = []
	var session := game.get("session") as Node
	if session != null:
		session.stormwood_encounter_message.connect(func(event: Dictionary) -> void:
			if str(event.get("kind", "")).begins_with("ending_"):
				ending_messages.append(event.duplicate(true)))
	var local_peer := int(session.call("local_peer_id")) if session != null else 0
	_expect(session != null and str(session.call("realm_of", local_peer)) == "stormwood",
		"Session does not route the focused local fixture as Stormwood (peer=%d realm=%s)"
			% [local_peer, str(session.call("realm_of", local_peer)) if session != null else "missing"])
	_expect(get_first_node_in_group("stormwood_encounter_hub") == ending.get("hub"),
		"Session's Stormwood dispatch group does not resolve the production ending hub")
	if not _failures.is_empty():
		_finish()
		return

	# The smoke starts after the player's real Stormheart roster decision. Relic
	# placement is now an optional power action at the Meadows home circle; it
	# no longer gates the continuous Waterward route.
	_expect(_commit_world_flag(game, "stormwood:act_ii_complete"),
		"fixture could not commit the completed Act II prerequisite through the host ledger")
	_expect(_commit_world_flag(game, "stormwood:legendary_offer_made"),
		"fixture could not commit the resolved Stormheart offer through the host ledger")
	player.set_physics_process(false)
	player.global_position = view_prompt.global_position + Vector3(0.0, 0.0, -2.0)
	player.velocity = Vector3.ZERO
	await _frames(3)
	var authority_actor := ending.get("hub").call("actor_for", local_peer) as Node3D
	_expect(is_instance_valid(authority_actor), "Stormwood authority cannot resolve the local actor")
	_expect(is_instance_valid(authority_actor) and authority_actor.global_position.distance_to(
		view_prompt.global_position) <= ending.VIEW_RADIUS_M,
		"host-observed actor is outside the Waterward view radius")
	_expect(bool(view_prompt.get("enabled")) and bool(view_prompt.get("actionable")),
		"Waterward view prompt did not become an actionable ordinary interaction")
	view_prompt.call("interaction_activate")
	await _frames(3)
	_expect(bool(game.call("world_flags").call("has", "stormwood:waterward_revealed")),
		"production Waterward view did not reveal the route; authority messages=%s" % str(ending_messages))
	_expect(bool(game.call("world_flags").call("has", "realm_key_water")),
		"production Waterward view did not grant the Water key")
	_expect(bool(game.call("world_flags").call("has", "stormwood:chapter_complete")),
		"production Waterward view did not complete Stormwood")
	_expect(str(gate.call("current_state")) == REALM_GATE.STATE_UNLOCKABLE,
		"Waterward gate did not become unlockable after the production reveal")
	if not bool(game.call("world_flags").call("has", "stormwood:waterward_revealed")) \
			or not bool(game.call("world_flags").call("has", "realm_key_water")):
		_finish()
		return
	# The successful view opens the authored aftermath conversation, which owns
	# input until the player reads it. Advance that ordinary UI before walking to
	# the gate; skipping it would correctly leave InteractionArbiter blocked.
	var dialogue := stormwood.get_node_or_null(^"DialoguePanel")
	for _line in 48:
		if dialogue == null or not bool(dialogue.call("is_open")):
			break
		await _press_interact()
	_expect(dialogue == null or not bool(dialogue.call("is_open")),
		"Waterward aftermath dialogue did not finish through ordinary interact presses")
	if dialogue != null and bool(dialogue.call("is_open")):
		_finish()
		return

	# Approach from the existing Waterward view side. The prompt must be the
	# arbiter's actual winner; calling the gate's try_* methods would not prove
	# the ordinary controller-facing path.
	var approach := (view_prompt.global_position - gate.global_position).normalized()
	player.global_position = gate.global_position + approach * 2.0
	player.velocity = Vector3.ZERO
	await _frames(3)
	_expect(await _wait_for_provider(arbiter, gate_prompt),
		"Waterward RealmGate prompt never won the live interaction arbiter")
	if arbiter.call("winning_provider") != gate_prompt:
		_finish()
		return

	var transport := game.get("ledger") as Node
	var published: Array[Dictionary] = []
	transport.delta_applied.connect(func(delta: Dictionary) -> void:
		published.append(delta.duplicate(true)))
	var sequence_before := int(transport.get("ledger").get("seq"))
	await _press_interact()
	await _frames(3)

	_expect(current_scene == stormwood and str(game.get("current_realm")) == "stormwood",
		"the first gate interaction travelled instead of only unlocking")
	_expect(not bool(game.call("world_flags").call("has", "realm_key_water")),
		"first gate interaction did not consume the one-time Water key")
	_expect(bool(game.call("world_flags").call("has", "realm_gate_water_unlocked")),
		"first gate interaction did not open the reusable Water gate")
	_expect(str(gate.call("current_state")) == REALM_GATE.STATE_UNLOCKED,
		"first gate interaction did not refresh the production gate to unlocked")
	_expect(int(transport.get("ledger").get("seq")) == sequence_before + 2,
		"gate unlock did not commit exactly the key-clear and gate-open operations")
	_expect(published.size() == 1,
		"gate unlock did not publish one externally visible combined delta")
	if published.size() == 1:
		_expect(_is_atomic_gate_delta(published[0]),
			"published gate delta was not the canonical key-clear plus gate-open pair")

	var saved_world: Dictionary = game.get("save_system").call("worlds").call("read", WORLD_ID)
	var saved_flags: Array = (saved_world.get("flags", {}) as Dictionary).get("flags", []) as Array
	_expect(not saved_flags.has("realm_key_water") and saved_flags.has("realm_gate_water_unlocked"),
		"world journal did not durably replace the Water key with the reusable gate unlock")
	_expect(not bool(game.call("can_enter_realm", "water")),
		"generic key entry unexpectedly remains authorised after key consumption")

	_expect(await _wait_for_provider(arbiter, gate_prompt),
		"unlocked Waterward RealmGate prompt was not actionable for the second interaction")
	if arbiter.call("winning_provider") != gate_prompt:
		_finish()
		return
	await _press_interact()

	var water := await _wait_for_current_scene("WaterArchipelago", TRANSITION_DEADLINE_MS)
	_expect(water != null, "second ordinary gate interaction did not enter production Water")
	if water == null:
		_finish()
		return
	await _wait_for_entry_settle(game, TRANSITION_DEADLINE_MS)
	_expect(str(game.get("current_realm")) == "water",
		"realm router did not finish in Water")
	_expect(str(game.get("pending_realm_entry")) == "",
		"Water did not settle water_arrival_from_stormwood")
	_expect(bool(water.call("shell_build_complete")),
		"Water scene became current before its production shell completed")
	var water_player := water.get_node_or_null(^"Player") as CharacterBody3D
	var expected: Vector3 = water.call("entry_anchor", "water_arrival_from_stormwood")
	_expect(water_player != null and water_player.global_position.distance_to(expected) <= ARRIVAL_TOLERANCE_M,
		"Water player did not settle at authored water_arrival_from_stormwood")
	_finish()


func _waterward_reveal_names_tidewake() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORMWOOD_DIALOGUE_PATH))
	if parsed is not Dictionary:
		return false
	var conversations: Variant = (parsed as Dictionary).get("conversations", {})
	if conversations is not Dictionary:
		return false
	var conversation: Variant = (conversations as Dictionary).get(
		"stormwood_waterward_aftermath", {})
	if conversation is not Dictionary:
		return false
	for line: Variant in (conversation as Dictionary).get("lines", []):
		if str(line).contains("Tidewake"):
			return true
	return false


func _commit_world_flag(game: Node, flag: String) -> bool:
	var verdict: Dictionary = game.get("ledger").call("submit", {
		"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true,
	})
	return bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false))


func _is_atomic_gate_delta(delta: Dictionary) -> bool:
	var ops: Array = delta.get("ops", []) as Array
	return ops.size() == 2 \
		and str((ops[0] as Dictionary).get("id", "")) == "realm_key_water" \
		and not bool((ops[0] as Dictionary).get("value", true)) \
		and str((ops[1] as Dictionary).get("id", "")) == "realm_gate_water_unlocked" \
		and bool((ops[1] as Dictionary).get("value", false))


func _wait_for_shell(world: Node, budget_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + budget_ms
	while is_instance_valid(world) and Time.get_ticks_msec() < deadline:
		if bool(world.call("shell_build_complete")):
			return true
		await process_frame
	return false


func _wait_for_provider(arbiter: Node, provider: Node) -> bool:
	for _frame in PROVIDER_WAIT_FRAMES:
		if is_instance_valid(arbiter) and arbiter.call("winning_provider") == provider:
			return true
		await physics_frame
	return false


func _press_interact() -> void:
	# Feed the same event path as a keyboard/controller press. `action_press()`
	# mutates polling state but does not reliably create a just-pressed event in
	# a headless SceneTree; the established realm-handoff smoke uses this exact
	# InputEventAction route for the InteractionArbiter's physics-tick edge.
	await process_frame
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await physics_frame
	event = InputEventAction.new()
	event.action = &"interact"
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _wait_for_current_scene(expected_name: String, budget_ms: int) -> Node:
	var deadline := Time.get_ticks_msec() + budget_ms
	while Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.name == expected_name:
			return current_scene
		await process_frame
	return null


func _wait_for_entry_settle(game: Node, budget_ms: int) -> void:
	var deadline := Time.get_ticks_msec() + budget_ms
	while str(game.get("pending_realm_entry")) != "" and Time.get_ticks_msec() < deadline:
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	Input.action_release(&"interact")
	_cleanup_test_saves()
	if _failures.is_empty():
		print("STORMWOOD WATER GATE PATH OK: reveal -> atomic unlock -> ordinary Water arrival")
		quit(0)
		return
	for failure: String in _failures:
		push_error("STORMWOOD WATER GATE PATH: %s" % failure)
	quit(1)


func _cleanup_test_saves() -> void:
	_remove_tree(ProjectSettings.globalize_path(TEST_SAVE_DIR))


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := path.path_join(name)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
