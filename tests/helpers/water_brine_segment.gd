extends RefCounted

## Controller-only continuation from the paid Reedhaven dock to Tovin's
## durable Brine Steps victory. The caller owns the already-running production
## Water world and an earned, healthy campaign party. This helper never resets
## the game, moves an actor directly, grants a creature, repairs HP/stamina, or
## writes inventory/progression state.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const REPAIR_FLAG := "water_dock_reedhaven_repaired"
const TOVIN_ID := "water_trainer_tovin"
const TOVIN_FLAG := "defeated_water_trainer_tovin"
const TRIAL_FLAG := "water_dock_brine_steps_trial_won"
const ROUTE_ID := "reedhaven_to_brine_steps_sheltered"
const SPINE_ID := "brine_steps_exploration_spine"
const TOVIN_LOCAL_OFFSET := Vector3(-25.0, 0.0, 149.0)

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _world: Node3D
var _player: CharacterBody3D
var _camera: Node3D
var _game: Node
var _arbiter: Node
var _director: Node
var _manager: Node
var _navigator: RefCounted
var _activated: Object
var _completed := false


func setup(tree: SceneTree, world: Node3D, player: CharacterBody3D,
		camera: Node3D) -> void:
	_tree = tree
	_world = world
	_player = player
	_camera = camera
	_game = tree.root.get_node_or_null("Game") if tree != null else null
	_arbiter = world.get_node_or_null("InteractionArbiter") if world != null else null
	_director = world.get_node_or_null("EncounterDirector") if world != null else null
	_manager = world.get_node_or_null("CombatManager") if world != null else null
	_navigator = NAV.new(tree, player, camera, _stick) \
		if tree != null and player != null and camera != null else null
	if _arbiter != null and not _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.connect(_on_activated)


func run() -> bool:
	if not _preconditions_hold():
		return false
	var departure := _anchor("reedhaven_to_brine_steps_departure")
	if _player.global_position.distance_to(departure) > 9.0 \
			or not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("segment must begin dry at the repaired Reedhaven departure; player=%s expected=%s" % [
			str(_player.global_position), str(departure)])
	if not await _stow_tool():
		return false
	if not await _walk_to(departure, "repaired Reedhaven departure", 1.3):
		return false
	if not await _cross_human_route():
		return false
	if not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("Brine Steps crossing did not finish dry and grounded")
	_note("ordinary 107.088m human crossing reached Brine Steps")

	var spine := _land_route(SPINE_ID)
	if spine.size() < 7:
		return _fail("Brine Steps exploration spine is missing its seven authored points")
	# Stay on the authored graded arrival-to-pier route through the final inland
	# point. Tovin now stands beside p5 instead of across an ungraded summit chord.
	for index in [1, 2, 3, 4, 5]:
		if not await _walk_to(spine[index], "Brine Steps spine point %d" % index):
			return false
	if not await _ensure_ally_deployed():
		return false
	if not await _fight_tovin():
		return false
	if not await _wait_world_flag(TOVIN_FLAG, 240):
		return _fail("Tovin combat ended without durable defeat flag " + TOVIN_FLAG)
	if not await _wait_world_flag(TRIAL_FLAG, 240):
		return _fail("Tovin defeat did not publish dock completion " + TRIAL_FLAG)
	_note("Tovin durable victory and Brine Steps trial completion earned")
	_completed = true
	return true


func result() -> Dictionary:
	return {"ok": verdict(_completed, failures), "failures": failures.duplicate(),
		"transcript": transcript.duplicate()}


static func verdict(completed: bool, errors: Array) -> bool:
	return completed and errors.is_empty()


static func route_contract(route: Dictionary) -> bool:
	return str(route.get("id", "")) == ROUTE_ID \
		and str(route.get("intended_traversal", "")) == "human_level_0" \
		and str(route.get("required_departure_flag", "")) == REPAIR_FLAG \
		and str(route.get("to_anchor", "")) == "reedhaven_to_brine_steps_arrival" \
		and absf(float(route.get("measured_surface_polyline_m", 0.0)) - 107.088) < 0.001 \
		and (route.get("polyline", []) as Array).size() == 3


static func trainer_contract(trainer: Dictionary) -> bool:
	return str(trainer.get("id", "")) == TOVIN_ID \
		and str(trainer.get("npc_entity_id", "")) == "water_tovin" \
		and bool(trainer.get("critical", false)) \
		and int(trainer.get("ace_level", 0)) == 46 \
		and (trainer.get("team", []) as Array).size() == 2


static func placement_contract(npc: Dictionary) -> bool:
	var raw: Array = npc.get("island_local_offset", [])
	return str(npc.get("id", "")) == "water_tovin" \
		and str(npc.get("island_id", "")) == "brine_steps" \
		and str(npc.get("role", "")) == "trainer_dock_test" \
		and raw.size() == 3 \
		and Vector3(float(raw[0]), float(raw[1]), float(raw[2])).is_equal_approx(
			TOVIN_LOCAL_OFFSET)


func _preconditions_hold() -> bool:
	if _tree == null or _world == null or _player == null or _camera == null \
			or _game == null or _arbiter == null or _director == null \
			or _manager == null or _navigator == null:
		return _fail("Brine segment is missing a production tree/world/player/camera service")
	if str(_game.current_realm) != "water" or not _world.shell_build_complete():
		return _fail("Brine segment requires the ready production Water realm")
	if not _game.world.flags.has(REPAIR_FLAG):
		return _fail("Brine segment requires the paid Reedhaven repair")
	if _game.world.flags.has(TOVIN_FLAG) or _game.world.flags.has(TRIAL_FLAG):
		return _fail("Brine segment requires undefeated Tovin and an incomplete trial")
	if _game.local.party.size() < 1:
		return _fail("Brine segment requires an existing campaign party")
	var active: RefCounted = _game.local.party.active()
	if active == null or bool(active.fainted) or bool(active.resting):
		return _fail("Brine segment requires a healthy, available active campaign creature")
	if not _director.trainer_nodes.has(TOVIN_ID) \
			or not _director.trainer_prompts.has(TOVIN_ID) \
			or not trainer_contract(_director.trainer_specs.get(TOVIN_ID, {})):
		return _fail("production Tovin trainer/prompt/team contract is absent")
	return true


func _cross_human_route() -> bool:
	var route := _water_route(ROUTE_ID)
	if not route_contract(route):
		return _fail("authored Reedhaven-to-Brine human crossing contract is missing")
	for raw: Array in route.polyline:
		if not await _swim_to(_vector(raw), ROUTE_ID):
			return false
	return await _swim_to(_anchor(str(route.to_anchor)), ROUTE_ID + " arrival")


func _swim_to(target: Vector3, label: String) -> bool:
	for frame in 4200:
		var offset := target - _player.global_position
		offset.y = 0.0
		if offset.length() <= 0.8:
			_stop_stick()
			await _frames(4)
			return true
		_camera.set("yaw", atan2(-offset.x, -offset.z))
		_stick(0.0, -1.0)
		await _tree.physics_frame
		if float(_player.vitals.health) <= 0.0:
			return _fail("player died during %s toward %s" % [label, str(target)])
	_stop_stick()
	return _fail("human crossing stalled for %s: player=%s target=%s stamina=%.2f" % [
		label, str(_player.global_position), str(target), float(_player.vitals.stamina)])


func _ensure_ally_deployed() -> bool:
	var existing: RefCounted = _director.ally_instance()
	if _director.ally_body() != null and existing != null and not bool(existing.fainted):
		return true
	await _tap(&"creature_recall")
	for frame in 180:
		var ally: RefCounted = _director.ally_instance()
		if _director.ally_body() != null and ally != null and not bool(ally.fainted):
			return true
		await _tree.physics_frame
	return _fail("controller recall did not deploy the healthy active campaign creature; blocker=%s" %
		str(_director.usable_ally_blocker()))


func _fight_tovin() -> bool:
	var prompt: Node3D = _director.trainer_prompts.get(TOVIN_ID) as Node3D
	if not await _activate(prompt, "Tovin challenge"):
		return false
	var deadline := Time.get_ticks_msec() + 15000
	while not _director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		await _tree.physics_frame
	if not _director.trainer_battle_active() or _director.trainer_battle_id() != TOVIN_ID:
		return _fail("Tovin challenge never entered its production trainer battle")
	var opponents: Dictionary = {}
	deadline = Time.get_ticks_msec() + 180000
	var tick := 0
	while _director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		var enemy: Node3D = _manager.enemy_body()
		var ally: Node3D = _director.ally_body()
		if is_instance_valid(enemy) and is_instance_valid(ally) and _manager.is_fighting():
			opponents[enemy.get_instance_id()] = str(enemy.instance.species_id)
			var offset := enemy.global_position - ally.global_position
			offset.y = 0.0
			_stop_combat_input()
			if offset.length() > _manager.combat_move_reach("quick") * 0.8:
				var local: Vector3 = _camera.planar_basis().inverse() * offset.normalized()
				_stick(local.x, local.z)
			if tick % 20 == 0:
				Input.action_press("combat_quick")
			elif tick % 20 == 2:
				Input.action_release("combat_quick")
		else:
			_stop_combat_input()
		tick += 1
		await _tree.physics_frame
	_stop_combat_input()
	if _director.trainer_battle_active():
		return _fail("Tovin combat exceeded 180 seconds after opponents=%s" %
			str(opponents.values()))
	if opponents.size() != 2:
		return _fail("Tovin combat did not reach both authored opponents: " + str(opponents.values()))
	var survivor: RefCounted = _director.ally_instance()
	if survivor == null or bool(survivor.fainted):
		return _fail("Tovin combat ended without a surviving campaign creature: opponents=%s" %
			str(opponents.values()))
	_note("Tovin production combat reached two opponents; ally_hp=%.1f/%.1f" % [
		float(survivor.hp), float(survivor.max_hp)])
	return true


func _activate(prompt: Node3D, label: String) -> bool:
	if prompt == null or not is_instance_valid(prompt):
		return _fail(label + " has no live production provider")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var stance := prompt.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.5
		stance.y = _world.ground_height_at(stance.x, stance.z) + 0.1
		if not stance.is_finite():
			continue
		if not await _walk_to(stance, label + " stance %d" % index, 1.0):
			return false
		await _frames(8)
		if _arbiter.call("winning_provider") != prompt:
			continue
		_activated = null
		await _tap(&"interact")
		if _activated == prompt:
			return true
	return _fail("%s never won and received the production interact press; winner=%s" % [
		label, str(_arbiter.call("winning_provider"))])


func _stow_tool() -> bool:
	var held := str(_game.equipped_tool)
	if held.is_empty():
		return true
	var action := _hotbar_action(held)
	if action == &"":
		return _fail("held campaign tool has no controller hotbar action: " + held)
	await _tap(action)
	for frame in 45:
		if str(_game.equipped_tool).is_empty():
			return true
		await _tree.physics_frame
	return _fail("controller hotbar did not stow the held campaign tool: " + held)


func _walk_to(target: Vector3, label: String, tolerance: float = 1.3) -> bool:
	if not target.is_finite():
		return _fail(label + " target is not finite")
	var horizontal := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(target.x, target.z))
	var arrived: bool = await _navigator.walk_to(target,
		maxi(1200, int(horizontal * 65.0)), tolerance)
	_stop_stick()
	if not arrived:
		return _fail("%s walk failed: player=%s target=%s resets=%d" % [label,
			str(_player.global_position), str(target), int(_navigator.confined_resets())])
	await _frames(4)
	return true


func _hotbar_action(item: String) -> StringName:
	var hotbar: Array = _game.hotbar
	var index := hotbar.find(item)
	return StringName("hotbar_%d" % (index + 1)) if index >= 0 and index < 5 else &""


func _water_route(id: String) -> Dictionary:
	for route: Dictionary in _world.config.water_routes:
		if str(route.id) == id:
			return route
	return {}


func _land_route(id: String) -> Array[Vector3]:
	for route: Dictionary in _world.config.land_routes:
		if str(route.id) == id:
			var points: Array[Vector3] = []
			for raw: Array in route.polyline:
				points.append(_vector(raw))
			return points
	return []


func _anchor(id: String) -> Vector3:
	for row: Dictionary in _world.config.anchors:
		if str(row.id) == id:
			var point := _vector(row.safe_position)
			point.y = _world.ground_height_at(point.x, point.z) + 0.15
			return point
	return Vector3.INF


func _wait_world_flag(id: String, frames: int) -> bool:
	for frame in frames:
		if _game.world.flags.has(id):
			return true
		await _tree.physics_frame
	return _game.world.flags.has(id)


func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _on_activated(provider: Object) -> void:
	_activated = provider


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _stop_stick() -> void:
	_stick(0.0, 0.0)


func _stop_combat_input() -> void:
	_stop_stick()
	Input.action_release("combat_quick")


func _tap(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	await _tree.process_frame
	await _frames(4)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	up.strength = 0.0
	Input.parse_input_event(up)
	await _tree.process_frame
	await _frames(8)


func _frames(count: int) -> void:
	for frame in count:
		await _tree.physics_frame


func _fail(message: String) -> bool:
	_stop_combat_input()
	failures.append(message)
	_note("FAIL: " + message)
	return false


func _note(message: String) -> void:
	transcript.append(message)
	print("WATER BRINE: " + message)
