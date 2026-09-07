extends SceneTree

## Actual Water world, one explicit exterior proximity fixture, then production
## movement and nearby interaction callbacks. No progression flag injection.
const SAVE := preload("res://scripts/save/save_game.gd")
var checks := 0
var failures := 0
var player: Node3D
var cave: Node3D

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "veilfall-runtime-smoke"
	game.world.world_id = "veilfall-runtime-world"
	game.save_system = SAVE.new("user://water_veilfall_runtime_%d/" % Time.get_ticks_usec())
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water world builds with Veilfall service"):
		_finish()
		return
	cave = world.get_node("WaterVeilfall")
	player = world.local_rig()
	var entry: Node3D = cave.get("_entry_prompt")
	player.global_position = cave.entrance + Vector3(0, 0.2, 1.8)
	player.velocity = Vector3.ZERO
	await _frames(4)
	if not check(not entry.interaction_offer(player.global_position).is_empty(), "Authored exterior waterfall entrance offers nearby interaction"):
		_finish()
		return
	entry.interaction_activate()
	await _frames(12)
	if not check(cave.contains_interior(player.global_position), "Actual entrance transfers local rig into the same-realm cave"):
		_finish()
		return
	check(game.current_realm == "water", "Cave entry retains Water realm identity")
	check(player.is_on_floor() and absf(player.position.y - cave.interior.position.y) < 0.15, "Real CharacterBody settles on cave collision floor")
	var transport: Node = game.ledger.get_node("WaterVeilfallTransport")
	var refused: Dictionary = transport.submit({"kind":"veilfall_control", "control_id":"intake_pump"})
	check(not refused.get("ok", false) and not game.world.flags.has("water_veilfall_intake_stopped"), "Real authority refuses pump activation from distant entry")
	# Deliberately supplied actor positions isolate prerequisite validation;
	# ordinary success below always uses transport's observed player position.
	var controls: Dictionary = cave.get("_controls")
	var order: Dictionary = cave.host_commit({"kind":"veilfall_control", "control_id":"sluice_wheel"}, game.session.local_peer_id(), {"realm":"water", "position":controls.sluice_wheel.global_position})
	check(not order.get("ok", false) and not game.world.flags.has("water_veilfall_return_opened"), "Host rejects return sluice before intake prerequisite")
	await _walk_to(Vector3(0, 0, 34), 420)
	check(player.position.z < cave.interior.position.z + 30 and player.position.z > cave.interior.position.z + 25, "Closed intake grille physically blocks normal movement")
	if not check(await _walk_to(Vector3(-5, 0, 18.9)), "Normal walking reaches intake pump from blocked gallery"):
		_finish()
		return
	if not _activate_nearby(controls.intake_pump, "Intake pump"):
		_finish()
		return
	await _frames(4)
	check(game.world.flags.has("water_veilfall_intake_stopped"), "Actual pump interaction publishes real world flag")
	check(cave.get("_gates").water_veilfall_intake_stopped.collision_layer == 0, "Published intake flag removes grille collision")
	if not check(await _walk_to(Vector3(0, 0, 18.9)), "Normal walking clears the pump housing before turning toward grille"):
		_finish()
		return
	if not check(await _walk_to(Vector3(0, 0, 34)), "Normal walking passes newly opened intake grille"):
		_finish()
		return
	if not check(await _walk_to(Vector3(9, 0, 45.9)), "Normal walking reaches return sluice in Pump Hall"):
		_finish()
		return
	if not _activate_nearby(controls.sluice_wheel, "Return sluice"):
		_finish()
		return
	await _frames(4)
	check(game.world.flags.has("water_veilfall_return_opened"), "Actual sluice interaction publishes real world flag")
	check(cave.get("_gates").water_veilfall_return_opened.collision_layer == 0, "Published return flag removes second grille collision")
	for point: Vector3 in [Vector3(0, 0, 56), Vector3(0, 0, 70), Vector3(0, 0, 87), Vector3(0, 0, 109.9)]:
		if not check(await _walk_to(point), "Production movement traverses cave waypoint %s" % point):
			_finish()
			return
	check(player.is_on_floor() and absf(player.position.y - cave.interior.position.y) < 0.15, "Bridge and Heart Chamber retain actual grounded movement")
	_activate_nearby(controls.guardian_tether, "Guardian tether")
	await _frames(4)
	check(not game.world.flags.has("water_guardian_freed"), "Nearby real tether interaction cannot release Guardian before captain victory")
	for point: Vector3 in [Vector3(0, 0, 70), Vector3(0, 0, 40), Vector3(0, 0, 4)]:
		if not check(await _walk_to(point), "Production movement returns through cave waypoint %s" % point):
			_finish()
			return
	var exit_prompt: Node3D = cave.get("_exit_prompt")
	_activate_nearby(exit_prompt, "Waterfall exit")
	await _frames(8)
	check(not cave.contains_interior(player.global_position) and player.global_position.distance_to(cave.entrance) < 5.0, "Actual exit returns local rig to authored waterfall outside")
	check(game.current_realm == "water", "Exit keeps Water realm and progression resident")
	_finish()

func _activate_nearby(prompt: Node3D, label: String) -> bool:
	if not check(not prompt.interaction_offer(player.global_position).is_empty(), label + " offers actual nearby interaction"):
		return false
	prompt.interaction_activate()
	return true

func _walk_to(local_point: Vector3, maximum_frames: int = 1800) -> bool:
	var target: Vector3 = cave.interior.position + local_point
	var camera: Node = player.get("_camera_rig")
	for frame in maximum_frames:
		var offset := target - player.global_position
		offset.y = 0
		if offset.length() < 0.45:
			_release()
			await _frames(8)
			return true
		var direction: Vector3 = camera.planar_basis().inverse() * offset.normalized()
		_release()
		if direction.x < 0: Input.action_press("move_left", -direction.x)
		else: Input.action_press("move_right", direction.x)
		if direction.z < 0: Input.action_press("move_forward", -direction.z)
		else: Input.action_press("move_back", direction.z)
		await physics_frame
	_release()
	print("Walk stopped at ", player.global_position - cave.interior.position, " targeting ", local_point)
	return false

func _release() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _finish() -> void:
	_release()
	print("Water Veilfall runtime smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
