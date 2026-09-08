extends RefCounted

## Controller-driven continuation from Tovin's durable victory through the
## liberated Shellwatch departure. The caller owns the live production Water
## world and unchanged carried party. No actor pose/orientation, HP, inventory
## or progression value is written by this helper.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TOVIN_ID := "water_trainer_tovin"
const TOVIN_FLAG := "defeated_water_trainer_tovin"
const TRIAL_FLAG := "water_dock_brine_steps_trial_won"
const ROUTE_ID := "brine_steps_to_shellwatch_sheltered"
const SOLM_ID := "water_trainer_solm"
const SOLM_FLAG := "defeated_water_trainer_solm"
const IRVA_ID := "water_trainer_irva"
const IRVA_FLAG := "defeated_water_trainer_irva"
const RELEASE_FLAG := "water_shellwatch_residents_freed"
const PUMP_FLAG := "water_shellwatch_pump_disabled"
const COMBINED_FLAG := "water_dock_shellwatch_residents_freed_and_pump_disabled"
const CAMP_ID := "water_camp_shellwatch"
const DEPARTURE_BARRIER := "shellwatch_to_tidal_cradle_dockBarrier"

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
var _docks: Node
var _camps: Node
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
	_docks = world.get_node_or_null("WaterDocks") if world != null else null
	_camps = world.get_node_or_null("WaterCamps") if world != null else null
	_navigator = NAV.new(tree, player, camera, _stick) \
		if tree != null and player != null and camera != null else null
	if _arbiter != null and not _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.connect(_on_activated)


func run() -> bool:
	if not _preconditions_hold():
		return false
	var tovin: Node3D = _director.trainer_nodes.get(TOVIN_ID) as Node3D
	if not is_instance_valid(tovin) or _player.global_position.distance_to(tovin.global_position) > 12.0 \
			or not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("segment must begin dry beside defeated Tovin; player=%s tovin=%s" % [
			str(_player.global_position), str(tovin.global_position) if is_instance_valid(tovin) else "missing"])

	var brine := _land_route("brine_steps_exploration_spine")
	if brine.size() < 7:
		return _fail("Brine Steps exploration spine is missing its seven authored points")
	# Tovin now stands beside p5. Continue forward to the departure rather
	# than walking the previous summit-era p4 detour backwards.
	for index in [5, 6]:
		if not await _walk_to(brine[index], "Brine departure spine point %d" % index):
			return false
	if not await _cross_human_route():
		return false
	if not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("Shellwatch crossing did not finish dry and grounded")
	_note("ordinary 93.320m human crossing reached Shellwatch")

	var shellwatch := _land_route("shellwatch_exploration_spine")
	if shellwatch.size() < 7:
		return _fail("Shellwatch exploration spine is missing its seven authored points")
	if not await _walk_to(shellwatch[1], "Shellwatch camp approach"):
		return false
	if not await _recover_at_camp("before Solm"):
		return false
	if not await _walk_to(shellwatch[2], "Shellwatch trainer approach"):
		return false
	if not await _fight_trainer(SOLM_ID, SOLM_FLAG, 2):
		return false
	if not await _walk_to(shellwatch[2], "return from Solm") \
			or not await _walk_to(shellwatch[1], "resident-release return"):
		return false
	if not await _activate_dock_action("shellwatch_release", RELEASE_FLAG):
		return false
	if not await _recover_at_camp("between Solm and Irva"):
		return false
	if not await _walk_to(shellwatch[2], "Irva route approach"):
		return false
	if not await _fight_trainer(IRVA_ID, IRVA_FLAG, 2):
		return false
	if not await _walk_to(shellwatch[3], "Shellwatch spine point 3"):
		return false
	var midpoint := (shellwatch[3] + shellwatch[4]) * 0.5
	midpoint.y = _world.ground_height_at(midpoint.x, midpoint.z) + 0.1
	if not await _walk_to(midpoint, "Shellwatch long-segment midpoint"):
		return false
	for index in [4, 5, 6]:
		if not await _walk_to(shellwatch[index], "Shellwatch departure spine point %d" % index):
			return false
	if not await _activate_dock_action("shellwatch_pump", PUMP_FLAG):
		return false
	if not await _wait_world_flag(COMBINED_FLAG, 240):
		return _fail("Shellwatch actions did not publish combined gate " + COMBINED_FLAG)
	for frame in 120:
		if _docks.get_node_or_null(DEPARTURE_BARRIER) == null:
			break
		await _tree.physics_frame
	if _docks.get_node_or_null(DEPARTURE_BARRIER) != null:
		return _fail("combined Shellwatch gate left the departure barrier in the world")
	_note("Solm, resident release, Irva, pump and departure barrier all resolved")
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
		and str(route.get("required_departure_flag", "")) == TRIAL_FLAG \
		and str(route.get("to_anchor", "")) == "brine_steps_to_shellwatch_arrival" \
		and absf(float(route.get("measured_surface_polyline_m", 0.0)) - 93.32) < 0.001 \
		and (route.get("polyline", []) as Array).size() == 3


static func trainer_contract(trainer: Dictionary, id: String, level: int,
		species: Array[String]) -> bool:
	if str(trainer.get("id", "")) != id or str(trainer.get("npc_entity_id", "")) != id \
			or not bool(trainer.get("critical", false)) or int(trainer.get("ace_level", 0)) != level:
		return false
	var team: Array = trainer.get("team", [])
	if team.size() != species.size():
		return false
	for index in species.size():
		if str((team[index] as Dictionary).get("species", "")) != species[index] \
				or int((team[index] as Dictionary).get("level", 0)) != level:
			return false
	return true


static func dock_contract(data: Dictionary) -> bool:
	var actions: Dictionary = {}
	for row: Dictionary in data.get("actions", []):
		actions[str(row.get("id", ""))] = row
	if not actions.has("shellwatch_release") or not actions.has("shellwatch_pump"):
		return false
	var release: Dictionary = actions.shellwatch_release
	var pump: Dictionary = actions.shellwatch_pump
	if release.get("requires_flags", []) != [SOLM_FLAG] or str(release.get("flag", "")) != RELEASE_FLAG \
			or pump.get("requires_flags", []) != [IRVA_FLAG] or str(pump.get("flag", "")) != PUMP_FLAG:
		return false
	for row: Dictionary in data.get("completions", []):
		if str(row.get("flag", "")) == COMBINED_FLAG:
			return row.get("requires_flags", []) == [RELEASE_FLAG, PUMP_FLAG]
	return false


static func world_dock_contract(world: Dictionary) -> bool:
	for row: Dictionary in world.get("docks", []):
		if str(row.get("id", "")) == "shellwatch_to_tidal_cradle_dock":
			return str(row.get("island_id", "")) == "shellwatch" \
				and str(row.get("departure_anchor", "")) == "shellwatch_to_tidal_cradle_departure" \
				and str(row.get("unlock_flag", "")) == COMBINED_FLAG
	return false


func _preconditions_hold() -> bool:
	if _tree == null or _world == null or _player == null or _camera == null \
			or _game == null or _arbiter == null or _director == null \
			or _manager == null or _docks == null or _camps == null or _navigator == null:
		return _fail("Shellwatch segment is missing a production tree/world/player/camera service")
	if str(_game.current_realm) != "water" or not _world.shell_build_complete():
		return _fail("Shellwatch segment requires the ready production Water realm")
	for required: String in [TOVIN_FLAG, TRIAL_FLAG]:
		if not _game.world.flags.has(required):
			return _fail("Shellwatch segment requires Tovin outcome " + required)
	for absent: String in [SOLM_FLAG, IRVA_FLAG, RELEASE_FLAG, PUMP_FLAG, COMBINED_FLAG]:
		if _game.world.flags.has(absent):
			return _fail("Shellwatch segment requires an uncompleted production state: " + absent)
	if _docks.get_node_or_null(DEPARTURE_BARRIER) == null:
		return _fail("Shellwatch segment requires its initially closed departure barrier")
	if _game.local.party.size() < 1:
		return _fail("Shellwatch segment requires the unchanged carried campaign party")
	for id: String in [SOLM_ID, IRVA_ID]:
		if not _director.trainer_nodes.has(id) or not _director.trainer_prompts.has(id):
			return _fail("mandatory production trainer/prompt is absent: " + id)
	if not trainer_contract(_director.trainer_specs.get(SOLM_ID, {}), SOLM_ID, 47,
			["water_mirejaw", "water_mangrove_monitor"]):
		return _fail("production Solm team contract is absent")
	if not trainer_contract(_director.trainer_specs.get(IRVA_ID, {}), IRVA_ID, 48,
			["water_riptusk", "water_cannonback"]):
		return _fail("production Irva team contract is absent")
	return true


func _cross_human_route() -> bool:
	var route := _water_route(ROUTE_ID)
	if not route_contract(route):
		return _fail("authored Brine-to-Shellwatch human crossing contract is missing")
	for raw: Array in route.polyline:
		if not await _swim_to(_vector(raw), ROUTE_ID):
			return false
	return await _swim_to(_anchor(str(route.to_anchor)), ROUTE_ID + " arrival")


func _swim_to(target: Vector3, label: String) -> bool:
	for frame in 3600:
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


func _fight_trainer(id: String, flag: String, expected_opponents: int) -> bool:
	if not await _ensure_ally_deployed(id):
		return false
	var prompt: Node3D = _director.trainer_prompts.get(id) as Node3D
	if not await _activate(prompt, id + " challenge"):
		return false
	var deadline := Time.get_ticks_msec() + 15000
	while not _director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		await _tree.physics_frame
	if not _director.trainer_battle_active() or _director.trainer_battle_id() != id:
		return _fail(id + " challenge never entered production trainer combat")
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
		return _fail("%s combat exceeded 180 seconds; opponents=%s" % [id, str(opponents.values())])
	if opponents.size() != expected_opponents:
		return _fail("%s did not field every authored opponent: %s" % [id, str(opponents.values())])
	if not await _wait_world_flag(flag, 240):
		return _fail("%s combat ended without durable victory %s" % [id, flag])
	var survivor: RefCounted = _director.ally_instance()
	if survivor == null or bool(survivor.fainted):
		return _fail(id + " victory ended without a surviving active creature")
	_note("%s victory opponents=%s ally_hp=%.1f/%.1f" % [id, str(opponents.values()),
		float(survivor.hp), float(survivor.max_hp)])
	return true


func _ensure_ally_deployed(label: String) -> bool:
	var existing: RefCounted = _director.ally_instance()
	if _director.ally_body() != null and existing != null and not bool(existing.fainted):
		return true
	# Cycle only when production says the current active member is unusable.
	for attempt in _game.local.party.size():
		if not _director.no_usable_ally():
			break
		await _tap(&"party_cycle")
	if _director.ally_body() == null:
		await _tap(&"creature_recall")
	for frame in 180:
		var ally: RefCounted = _director.ally_instance()
		if _director.ally_body() != null and ally != null and not bool(ally.fainted):
			return true
		await _tree.physics_frame
	return _fail("%s has no controller-deployed usable campaign creature; blocker=%s" % [
		label, str(_director.usable_ally_blocker())])


func _recover_at_camp(label: String, camp_id: String = CAMP_ID) -> bool:
	var rest: Node3D = _camps.camps.get(camp_id) as Node3D
	var bed: Node3D = _camps.get_node_or_null(camp_id + "_creature_bed") as Node3D
	var bed_prompt := bed.get_node_or_null("Interactable") as Node3D if bed != null else null
	var rest_prompt := rest.get_node_or_null("Interactable") as Node3D if rest != null else null
	if rest == null or bed == null or bed_prompt == null or rest_prompt == null:
		return _fail("Shellwatch recovery services are absent " + label)
	if not await _walk_to(rest.global_position, "Shellwatch camp " + label, 3.0):
		return false
	if not await _ensure_ally_deployed("Shellwatch camp " + label):
		return false
	var member: RefCounted = _director.ally_instance()
	await _tap(&"creature_recall")
	for frame in 90:
		if _director.ally_body() == null:
			break
		await _tree.physics_frame
	if _director.ally_body() != null:
		return _fail("Shellwatch camp could not recall active creature " + label)
	if not await _activate(bed_prompt, "Shellwatch creature bed " + label):
		return false
	var panel: Node = INPUT_OWNER.current(_tree)
	var focus := _tree.root.get_viewport().gui_get_focus_owner() as Button
	if panel == null or not panel.has_method("is_open") or not bool(panel.is_open()) \
			or focus == null or focus.disabled:
		return _fail("Shellwatch creature bed did not open a focused enabled party row " + label)
	var target_index := -1
	for index in _game.local.party.size():
		if _game.local.party.at(index) == member:
			target_index = index
			break
	var rows: Array = panel.get("_rows")
	if target_index < 0 or target_index >= rows.size() \
			or _game.local.party.at(target_index) != member:
		return _fail("Shellwatch creature bed lost the retained party member " + label)
	# The production panel initially focuses its first enabled row. Move the
	# controller focus to the retained active member; accepting whichever row
	# happened to own focus could heal a different creature after party cycling.
	for step in rows.size():
		focus = _tree.root.get_viewport().gui_get_focus_owner() as Button
		if focus == rows[target_index]:
			break
		await _tap(&"ui_down")
		rows = panel.get("_rows")
	focus = _tree.root.get_viewport().gui_get_focus_owner() as Button
	if target_index >= rows.size() or focus != rows[target_index] \
			or _game.local.party.at(target_index) != member:
		return _fail("Shellwatch controller focus did not select the retained creature row " + label)
	await _tap(&"ui_accept")
	await _frames(8)
	if not bool(member.resting) or int(member.rest_bed_index) != int(bed.build_index()):
		return _fail("Shellwatch controller input did not assign the active creature to bed " + label)
	await _tap(&"menu_cancel")
	await _frames(8)
	var day_before := int(_game.day)
	if not await _activate(rest_prompt, "Shellwatch overnight rest " + label):
		return false
	var deadline := Time.get_ticks_msec() + 15000
	while int(_game.day) == day_before and Time.get_ticks_msec() < deadline:
		await _tree.physics_frame
	if int(_game.day) != day_before + 1 or bool(member.fainted) \
			or float(member.hp) < float(member.max_hp) - 0.01:
		return _fail("Shellwatch ordinary rest did not advance one day and heal the bedded creature " + label)
	# Bedding the active member advances Party's selection. Rest heals it but
	# leaves that selection alone; restore it through the ordinary cycle input.
	var cycle_count := recovery_cycle_count(_game.local.party, member)
	if cycle_count < 0:
		return _fail("Shellwatch recovered creature cannot be selected " + label)
	for step in cycle_count:
		await _tap(&"party_cycle")
	if _game.local.party.active() != member:
		return _fail("Shellwatch controller did not select the recovered creature " + label)
	await _tap(&"creature_recall")
	for frame in 180:
		if _director.ally_body() != null and _director.ally_instance() == member:
			_note("Shellwatch camp recovered active creature " + label)
			return true
		await _tree.physics_frame
	return _fail("Shellwatch camp did not redeploy the recovered creature " + label)


static func recovery_cycle_count(party: RefCounted, member: RefCounted) -> int:
	if party == null or member == null or member.fainted or member.resting:
		return -1
	var members: Array = party.members()
	var start := members.find(party.active())
	if start < 0 or not members.has(member):
		return -1
	if party.active() == member:
		return 0
	var presses := 0
	for offset in range(1, members.size()):
		var candidate: RefCounted = members[(start + offset) % members.size()]
		if candidate.fainted or candidate.resting:
			continue
		presses += 1
		if candidate == member:
			return presses
	return -1


func _activate_dock_action(id: String, flag: String) -> bool:
	var equipment := _docks.get_node_or_null(id) as Node3D
	var prompt := _provider_child(equipment)
	if equipment == null or prompt == null:
		return _fail("production Shellwatch dock equipment/provider is absent: " + id)
	if not await _walk_to(equipment.global_position, id + " equipment", 3.0):
		return false
	if not await _activate(prompt, id):
		return false
	if not await _wait_world_flag(flag, 240):
		return _fail("Shellwatch dock action %s did not publish %s" % [id, flag])
	_note("Shellwatch dock action earned " + flag)
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
		if _arbiter.winning_provider() != prompt:
			continue
		_activated = null
		await _tap(&"interact")
		if _activated == prompt:
			return true
	return _fail("%s never won and received the production interact press; winner=%s" % [
		label, str(_arbiter.winning_provider())])


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


func _provider_child(parent: Node3D) -> Node3D:
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child.has_method("interaction_offer"):
			return child as Node3D
	return null


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
	print("WATER SHELLWATCH: " + message)
