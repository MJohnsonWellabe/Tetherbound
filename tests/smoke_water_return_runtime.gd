extends SceneTree

## Focused fixture-only Water return proof. This mounts the production Water
## scene, walks its real player to the mounted return gate through ordinary
## stick input, activates the exact InteractionArbiter winner through a parsed
## Interact event, and waits for Game's asynchronous Stormwood transition to
## complete. The two world flags below are prerequisites supplied through the
## host ledger; this is not earned campaign evidence.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WATER_SCENE := preload("res://scenes/world/water_archipelago.tscn")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TEST_SAVE_DIR := "user://water_return_runtime_fixture"
const WORLD_ID := "water-return-runtime-world"
const CHARACTER_ID := "water-return-runtime-character"
const BUILD_DEADLINE_MS := GAME.REALM_SCENE_READY_TIMEOUT_MSEC
const PROVIDER_WAIT_FRAMES := 180
const ARRIVAL_SETTLE_FRAMES := 90
const CAPTURE_DEFAULT := "res://.artifacts/water-return-runtime/gate-normal-view.png"

var _failures: Array[String] = []
var _finished := false
var _gate_activations := 0
var _gate_prompt_id := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(360.0).timeout.connect(func() -> void:
		if not _finished:
			_fail("360 second watchdog expired")
			_finish())
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
	game.set("current_realm", "water")
	game.call("bind_realm_map")
	game.call("announce_realm", "meadows", "water")

	# Fixture prerequisites only. An earned save carrying the durable Water
	# unlock was not available. Both writes use the shipping host-ledger path;
	# no inventory, HP, party, chapter-completion, or Water-key state is added.
	_expect(_commit_world_flag(game, "realm_key_stormwood"),
		"fixture could not authorize the ordinary Stormwood router destination")
	_expect(_commit_world_flag(game, "realm_gate_water_unlocked"),
		"fixture could not provide the already-earned shared Water unlock")
	_expect(not bool(game.call("world_flags").call("has", "realm_key_water")),
		"fixture unexpectedly contains a second Water key")
	_expect(not bool(game.call("player_flags").call("has", "realm_gate_water_unlocked")),
		"fixture put the shared unlock in player authority")
	if not _failures.is_empty():
		_finish()
		return

	var water := WATER_SCENE.instantiate() as Node3D
	root.add_child(water)
	current_scene = water
	if not await _wait_for_shell(water, BUILD_DEADLINE_MS):
		_fail("production Water did not finish building")
		_finish()
		return

	var player := water.get_node_or_null(^"Player") as CharacterBody3D
	var camera := water.get_node_or_null(^"CameraRig") as Node3D
	var arbiter := water.get_node_or_null(^"InteractionArbiter")
	var gate := water.get_node_or_null(^"StormwoodReturnRealmGate") as Node3D
	var prompt := gate.get_node_or_null(^"Interactable") as Node3D if gate != null else null
	_expect(player != null and camera != null and arbiter != null,
		"production Water lacks its player, camera, or InteractionArbiter")
	_expect(gate != null and prompt != null,
		"production Water lacks the mounted Stormwood return gate or prompt")
	if player == null or camera == null or arbiter == null or gate == null or prompt == null:
		_finish()
		return
	_expect(str(gate.get("destination_realm")) == "stormwood"
		and str(gate.get("destination_entry_id")) == "stormwood_departure_to_water",
		"mounted return gate does not name the existing Stormwood destination")
	_expect(str(gate.call("current_state")) == "unlocked",
		"durable world unlock did not open the production Water gate")
	_expect(str(gate.get("key_flag")).is_empty(),
		"return gate exposes a second key path")

	for _frame in 30:
		await physics_frame
	var start := player.global_position
	var water_entry: Vector3 = water.call("entry_anchor", "from_stormwood")
	_expect(player.is_on_floor() and player.global_position.distance_to(water_entry) <= 3.0,
		"fixture did not begin at the real grounded First Shore entry")
	_expect(INPUT_OWNER.current(self) == null, "another UI owner holds ordinary world input")

	var toward_start := start - gate.global_position
	toward_start.y = 0.0
	if toward_start.length() < 0.001:
		toward_start = Vector3.LEFT
	var stance := prompt.global_position + toward_start.normalized() * 2.2
	var floor_y := float(water.call("ground_height_at", stance.x, stance.z))
	if is_finite(floor_y):
		stance.y = floor_y + 0.1
	var navigator := NAVIGATOR.new(self, player, camera, Callable(self, "_drive_stick"))
	var walked := await navigator.walk_to(stance, 1200, 0.9)
	_drive_stick(0.0, 0.0)
	_expect(walked, "ordinary stick input did not reach the Water return gate")
	_expect(Vector2(start.x, start.z).distance_to(Vector2(player.global_position.x,
		player.global_position.z)) >= 8.0,
		"return-gate approach did not traverse the real First Shore gap")
	if not walked:
		_finish()
		return
	for _frame in 8:
		await physics_frame
	_expect(await _wait_for_provider(arbiter, prompt),
		"return gate never won the live InteractionArbiter after the physical approach")
	if arbiter.call("winning_provider") != prompt:
		_finish()
		return

	# Frame the already-reached gate through the live gameplay camera. This
	# changes only the viewing yaw used for the evidence still, not the player,
	# gate, progression, or crossing result.
	var view := gate.global_position - player.global_position
	camera.set("yaw", atan2(-view.x, -view.z))
	camera.rotation = Vector3(float(camera.get("pitch")), float(camera.get("yaw")), 0.0)
	for _frame in 12:
		await process_frame
	_expect(root.get_viewport().get_camera_3d() == camera.get_node_or_null(^"Camera3D"),
		"gate still is not using Water's normal gameplay camera")
	await RenderingServer.frame_post_draw
	_capture_view(_capture_path())
	if not _failures.is_empty():
		_finish()
		return
	if not await _capture_time_views(water):
		_finish()
		return

	var world_flags_before: Dictionary = game.call("world_flags").call("save_data")
	var player_flags_before: Dictionary = game.call("player_flags").call("save_data")
	var route_flags_before := _route_flag_state(game)
	var source_id := water.get_instance_id()
	_gate_prompt_id = prompt.get_instance_id()
	arbiter.activated.connect(_watch_gate_activation)
	var request_observed := await _press_interact_and_observe_request(game)
	_expect(_gate_activations == 1,
		"ordinary Interact did not activate the exact Water return prompt once")
	_expect(request_observed,
		"gate activation did not issue the Stormwood router request with its authored entry id")

	var stormwood := await _wait_for_current_scene("Stormwood", source_id, BUILD_DEADLINE_MS)
	_expect(stormwood != null,
		"issued Water return request did not complete in the production Stormwood scene")
	if stormwood == null:
		_finish()
		return
	await _wait_for_entry_settle(game, BUILD_DEADLINE_MS)
	_expect(str(game.get("current_realm")) == "stormwood",
		"completed router transition did not finish in Stormwood")
	_expect(str(game.get("pending_realm_entry")) == "",
		"completed router transition left its Stormwood entry pending")
	_expect(bool(stormwood.call("shell_build_complete")),
		"Stormwood became current before its production build completed")
	for _frame in ARRIVAL_SETTLE_FRAMES:
		await physics_frame

	var arrived := stormwood.get_node_or_null(^"Player") as CharacterBody3D
	var anchor: Dictionary = stormwood.call("entry_anchor", "stormwood_departure_to_water")
	var expected: Vector3 = stormwood.call("resolve_entry_position", anchor)
	_expect(arrived != null, "Stormwood arrival has no live local Player")
	if arrived != null:
		_expect(Vector2(arrived.global_position.x, arrived.global_position.z).distance_to(
			Vector2(expected.x, expected.z)) <= 0.75,
			"Stormwood player did not retain the authored return-anchor X/Z")
		_expect(absf(arrived.global_position.y - expected.y) <= 0.5,
			"Stormwood player did not settle at the authored elevated anchor height")
		_expect(arrived.is_on_floor(),
			"Stormwood player is not standing on collision after arrival physics")
		_expect(_standing_on_stormheart_core(arrived),
			"arrival is not supported by the actual Stormheart DynamoCore collision")
	_expect(_route_flag_state(game) == route_flags_before,
		"return travel changed a route key/unlock fact")
	_expect(not bool(game.call("world_flags").call("has", "realm_key_water")),
		"return travel minted a second Water key")
	_expect(not bool(game.call("player_flags").call("has", "realm_gate_water_unlocked")),
		"return travel copied the world unlock into player authority")
	var world_flags_after: Dictionary = game.call("world_flags").call("save_data")
	var player_flags_after: Dictionary = game.call("player_flags").call("save_data")
	print("WATER RETURN FINGERPRINTS: world_before=%d world_after=%d player_before=%d player_after=%d world_id=%s character_id=%s" % [
		hash(JSON.stringify(world_flags_before)), hash(JSON.stringify(world_flags_after)),
		hash(JSON.stringify(player_flags_before)), hash(JSON.stringify(player_flags_after)),
		str(game.get("world").get("world_id")), str(game.get("local").get("character_id"))])
	_finish()


func _commit_world_flag(game: Node, flag: String) -> bool:
	var verdict: Dictionary = game.get("ledger").call("submit", {
		"kind": "set_world_flag", "realm": "water", "id": flag, "value": true,
	})
	return bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false))


func _route_flag_state(game: Node) -> Dictionary:
	var flags: RefCounted = game.call("world_flags")
	return {
		"realm_key_stormwood": flags.call("has", "realm_key_stormwood"),
		"realm_key_water": flags.call("has", "realm_key_water"),
		"realm_gate_water_unlocked": flags.call("has", "realm_gate_water_unlocked"),
	}


func _wait_for_shell(world: Node, budget_ms: int) -> bool:
	var deadline := Time.get_ticks_msec() + budget_ms
	while is_instance_valid(world) and Time.get_ticks_msec() < deadline:
		if world.has_method("shell_build_complete") and bool(world.call("shell_build_complete")):
			return true
		await process_frame
	return false


func _wait_for_provider(arbiter: Node, prompt: Node) -> bool:
	for _frame in PROVIDER_WAIT_FRAMES:
		if is_instance_valid(arbiter) and arbiter.call("winning_provider") == prompt:
			return true
		await physics_frame
	return false


func _press_interact_and_observe_request(game: Node) -> bool:
	var observed := false
	var down := InputEventAction.new()
	down.action = &"interact"
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	for _frame in 12:
		await physics_frame
		if str(game.get("current_realm")) == "stormwood" \
				and str(game.get("pending_realm_entry")) == "stormwood_departure_to_water":
			observed = true
			break
	var up := InputEventAction.new()
	up.action = &"interact"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	return observed


func _wait_for_current_scene(expected_name: String, source_id: int, budget_ms: int) -> Node3D:
	var deadline := Time.get_ticks_msec() + budget_ms
	while Time.get_ticks_msec() < deadline:
		var scene := current_scene as Node3D
		if is_instance_valid(scene) and scene.get_instance_id() != source_id \
				and scene.name == expected_name and scene.has_method("shell_build_complete") \
				and bool(scene.call("shell_build_complete")):
			return scene
		await process_frame
	return null


func _wait_for_entry_settle(game: Node, budget_ms: int) -> void:
	var deadline := Time.get_ticks_msec() + budget_ms
	while str(game.get("pending_realm_entry")) != "" and Time.get_ticks_msec() < deadline:
		await process_frame


func _standing_on_stormheart_core(player: CharacterBody3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 0.6,
		player.global_position + Vector3.DOWN * 1.0)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	var collider := hit.get("collider") as Node
	return collider != null and str(collider.get_path()).contains("StormheartTree/DynamoCore")


func _capture_path() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			return argument.trim_prefix("--capture=")
	return CAPTURE_DEFAULT


func _capture_time_views(water: Node) -> bool:
	var look := water.get_node_or_null(^"WorldLook")
	if look == null or not look.has_method("apply_time") or not look.has_method("time_of_day"):
		_fail("production Water lacks the WorldLook time authority needed for day/night gate views")
		return false
	var prior_preset := str(look.call("time_of_day"))
	var normal_path := _capture_path()
	for preset: String in ["day", "night"]:
		look.call("apply_time", preset)
		await process_frame
		await RenderingServer.frame_post_draw
		var path := normal_path.get_base_dir().path_join("gate-%s-view.png" % preset)
		_capture_view(path)
		if not _failures.is_empty():
			look.call("apply_time", prior_preset)
			return false
	look.call("apply_time", prior_preset)
	await process_frame
	return true


func _capture_view(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("live Water gate viewport capture returned no image")
		return
	var error := image.save_png(absolute)
	if error != OK:
		_fail("live Water gate viewport capture failed (%d)" % error)
		return
	print("WATER RETURN CAPTURE: %s (%dx%d)" % [absolute, image.get_width(), image.get_height()])


func _watch_gate_activation(provider: Object) -> void:
	if is_instance_valid(provider) and provider.get_instance_id() == _gate_prompt_id:
		_gate_activations += 1


func _drive_stick(x: float, y: float) -> void:
	_drive_axis(JOY_AXIS_LEFT_X, x)
	_drive_axis(JOY_AXIS_LEFT_Y, y)


func _drive_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("WATER RETURN RUNTIME FAIL: ", message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_drive_stick(0.0, 0.0)
	Input.action_release(&"interact")
	if _failures.is_empty():
		print("WATER RETURN RUNTIME OK: ordinary gate input -> completed Stormwood deck arrival; fixture prerequisites only")
		quit(0)
		return
	quit(1)
