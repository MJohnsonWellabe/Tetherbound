extends "res://tests/helpers/water_shellwatch_segment.gd"

## Fixture-free continuation of the actual paid swim mount. No wrapper loading,
## grants, poses, direct interaction callbacks or invitation in this segment.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const START_ANCHOR := "tidal_cradle_to_salt_crown_departure"
const LATE_ROUTES := ["tidal_cradle_to_salt_crown_sheltered",
	"salt_crown_to_sluice_isle_sheltered", "sluice_isle_to_veilfall_sheltered"]
const WATCHDOG_MS := 50 * 60 * 1000
const TRAINERS := {"water_trainer_bex": 2, "water_trainer_calder": 3,
	"water_trainer_venn": 3, "water_trainer_nerissa": 4}
var _riding: Node
var _swimmer: RefCounted
var _carried: Array = []
var _abort: Callable
var _deadline := 0
var _deadline_reported := false
var _running := false


func run_from_mount(swimmer: RefCounted, abort: Callable) -> bool:
	_swimmer = swimmer
	_abort = abort
	return await run()


func run() -> bool:
	if not _entry_valid():
		return false
	_carried = _game.local.party.members().duplicate()
	_deadline = Time.get_ticks_msec() + WATCHDOG_MS
	_deadline_reported = false
	_running = true
	_tree.physics_frame.connect(_observe_deadline)
	var passed := await _run_route()
	_running = false
	if _tree.physics_frame.is_connected(_observe_deadline):
		_tree.physics_frame.disconnect(_observe_deadline)
	_stop_combat_input()
	_completed = passed and not _expired() and _same_party() and failures.is_empty()
	return _completed


func _run_route() -> bool:
	# Preparation ends mounted on the arrival-side Tidal spine. Follow its
	# authored land legs rather than replacing the island with a straight chord.
	var tidal := _land_route("tidal_cradle_exploration_spine")
	if tidal.size() != 7:
		return _fail("Tidal departure requires the complete authored seven-point spine")
	for point: Vector3 in tidal.slice(1):
		if not await _move_mount_to(point,
				maxi(900, int(_riding.mount_body().global_position.distance_to(point) * 45.0)), 2.5):
			return false
	var departure := _anchor(START_ANCHOR)
	if not departure.is_finite() or not await _move_mount_to(departure,
			maxi(900, int(_riding.mount_body().global_position.distance_to(departure) * 45.0)), 1.8):
		return _fail("Could not physically reach Tidal mounted departure")
	if not await _cross_route(LATE_ROUTES[0]) or not await _dismount_on_land("Salt Crown"):
		return false
	if not await _walk_land_route("salt_crown_exploration_spine") \
			or not await _activate_dock_action("salt_crown_chart", "water_dock_salt_crown_landing_charted"):
		return false
	if not await _mount_existing("Salt Crown departure") or not await _cross_route(LATE_ROUTES[1]) \
			or not await _dismount_on_land("Sluice Isle"):
		return false
	var sluice := _land_route("sluice_isle_exploration_spine")
	if sluice.size() < 6:
		return _fail("Sluice exploration spine is incomplete")
	if not await _walk_to(sluice[1], "Sluice approach waypoint 1") \
			or not await _defeat_trainer("water_trainer_bex", "defeated_water_trainer_bex") \
			or not await _activate_dock_action("sluice_west_control", "water_sluice_west_disabled") \
			or not await _recover_at_camp("after Bex", "water_camp_sluice_isle"):
		return false
	for index in range(2, 6):
		if not await _walk_to(sluice[index], "Sluice ascent/departure waypoint %d" % index):
			return false
	if not await _defeat_trainer("water_trainer_calder", "defeated_water_trainer_calder") \
			or not await _activate_dock_action("sluice_east_control", "water_sluice_east_disabled") \
			or not await _wait_world_flag("water_dock_sluice_isle_both_controls_disabled", 240):
		return _fail("Both physical Sluice controls did not publish completion")
	if _docks.get("_barriers").has("water_dock_sluice_isle_both_controls_disabled"):
		return _fail("Combined Sluice completion did not remove its crossing barrier")
	_note("Bex/Calder defeated; both controls and final crossing barrier opened")
	if not await _mount_existing("Sluice departure") or not await _cross_route(LATE_ROUTES[2]) \
			or not await _dismount_on_land("Veilfall") \
			or not await _recover_at_camp("before Venn", "water_camp_veilfall"):
		return false
	var veilfall := _land_route("veilfall_exploration_spine")
	if veilfall.size() < 3:
		return _fail("Veilfall exploration spine is incomplete")
	for index in range(1, veilfall.size() - 1):
		if not await _walk_to(veilfall[index], "Veilfall exterior waypoint %d" % index):
			return false
	if not await _defeat_trainer("water_trainer_venn", "defeated_water_trainer_venn") \
			or not await _recall_active("post-Venn recovery return"):
		return false
	for index in range(veilfall.size() - 2, 0, -1):
		if not await _walk_to(veilfall[index], "Veilfall recovery waypoint %d" % index):
			return false
	if not await _recover_at_camp("after Venn", "water_camp_veilfall") \
			or not await _recall_active("return to waterfall"):
		return false
	for index in range(2, veilfall.size()):
		if not await _walk_to(veilfall[index], "Veilfall return waypoint %d" % index):
			return false
	var cave := _world.get_node_or_null("WaterVeilfall") as Node3D
	if cave == null or not await _activate(cave.get("_entry_prompt"), "Veilfall waterfall entrance"):
		return _fail("Physical Veilfall entrance did not activate")
	await _frames(12)
	if not cave.contains_interior(_player.global_position):
		return _fail("Same player did not enter actual Veilfall interior")
	if _director.ally_body() == null:
		await _tap(&"creature_recall")
		await _frames(24)
	if not _same_deployed_swimmer():
		return _fail("Controller did not redeploy retained swimmer inside Veilfall")
	var controls: Dictionary = cave.get("_controls")
	if not controls.has_all(["intake_pump", "sluice_wheel", "guardian_tether"]):
		return _fail("Veilfall production controls are incomplete")
	var origin: Vector3 = cave.interior.global_position
	if not await _walk_to(origin + Vector3(-5, 0, 18.9), "intake pump") \
			or not await _activate(controls.intake_pump, "Veilfall intake pump") \
			or not await _wait_world_flag("water_veilfall_intake_stopped", 180):
		return _fail("Physical intake control sequence failed")
	if not await _walk_to(origin + Vector3(0, 0, 34), "opened intake grille") \
			or not await _walk_to(origin + Vector3(9, 0, 45.9), "return sluice") \
			or not await _activate(controls.sluice_wheel, "Veilfall return sluice") \
			or not await _wait_world_flag("water_veilfall_return_opened", 180):
		return _fail("Physical return-sluice sequence failed")
	for point in [Vector3(0, 0, 56), Vector3(0, 0, 70), Vector3(0, 0, 87)]:
		if not await _walk_to(origin + point, "Veilfall interior waypoint"):
			return false
	if not await _defeat_trainer("water_trainer_nerissa", "water_captain_nerissa_defeated") \
			or not await _activate(controls.guardian_tether, "Abyssal Guardian tether") \
			or not await _wait_world_flag("water_guardian_freed", 240):
		return _fail("Nerissa victory did not permit physical Guardian release")
	if not _game.world.flags.has("water_tether_disabled") \
			or _game.pending_catch != null or _game.world.flags.has("water_guardian_claimed") \
			or _game.world.flags.has("water_guardian_settled") \
			or _game.world.flags.has("water_currents_restored"):
		return _fail("Late segment crossed its pre-invitation boundary")
	_note("Nerissa defeated, tether released; STOP before Guardian invitation, same five retained")
	return _same_party() and not _expired()


func _entry_valid() -> bool:
	if _tree == null or _world == null or _game == null or _player == null \
			or _camera == null or _arbiter == null or _director == null or _manager == null \
			or _camps == null or _docks == null or not _abort.is_valid():
		return _fail("Late Water requires live services and caller-owned terminal abort callback")
	_riding = _world.get_node_or_null("RidingController")
	if _riding == null or not _riding.is_mounted() or not is_instance_valid(_riding.mount_body()) \
			or _swimmer == null or _riding.mount_body().instance != _swimmer:
		return _fail("Late Water requires the actual already-mounted earned swimmer")
	if str(_game.current_realm) != "water" or _game.local.party.size() != 5 \
			or not _game.local.party.members().has(_swimmer) or _game.pending_catch != null \
			or not bool(SPECIES.definition(str(_swimmer.species_id)).get("swim_mount", {}).get("compatible", false)):
		return _fail("Late Water requires an unchanged full belt with actual compatible swimmer")
	for flag in ["water_swim_stone_earned", "water_swim_saddle_recipe_learned"]:
		if not _game.local.flags.has(flag):
			return _fail("Missing earned Water prerequisite " + flag)
	if _game.inventory.count("swim_saddle") < 1:
		return _fail("No carried paid Swim Saddle")
	for flag in ["water_dock_salt_crown_landing_charted", "water_sluice_west_disabled",
		"water_sluice_east_disabled", "defeated_water_trainer_bex", "defeated_water_trainer_calder",
		"defeated_water_trainer_venn", "water_captain_nerissa_defeated", "water_veilfall_intake_stopped",
		"water_veilfall_return_opened", "water_guardian_freed", "water_guardian_claimed",
		"water_tether_disabled", "water_guardian_settled", "water_currents_restored"]:
		if _game.world.flags.has(flag):
			return _fail("Cannot credit pre-completed late Water milestone " + flag)
	return true


static func same_five(current: Array, original: Array) -> bool:
	if current.size() != 5 or original.size() != 5 or current != original:
		return false
	var seen: Dictionary = {}
	for member in current:
		if not member is RefCounted or seen.has(member.get_instance_id()):
			return false
		seen[member.get_instance_id()] = true
	return true


func _same_party() -> bool:
	return same_five(_game.local.party.members(), _carried) and _game.pending_catch == null


func _same_deployed_swimmer() -> bool:
	return _director.ally_body() != null and _director.ally_instance() == _swimmer \
		and not bool(_swimmer.fainted) and _same_party()


func _expired() -> bool:
	return _deadline > 0 and Time.get_ticks_msec() >= _deadline


func _observe_deadline() -> void:
	if not _running or not _expired() or _deadline_reported:
		return
	_deadline_reported = true
	_fail("Late Water exceeded its unchanged 50-minute total watchdog")
	for action in ["interact", "creature_recall", "party_cycle", "ui_down", "ui_accept", "menu_cancel"]:
		Input.action_release(action)
	if _abort.is_valid():
		_abort.call(failures.back())


func _cross_route(id: String) -> bool:
	var route := _water_route(id)
	if route.is_empty() or not _riding.is_mounted():
		return _fail("Missing authored mounted crossing " + id)
	for raw: Array in route.polyline:
		var point := _vector(raw)
		var distance: float = _riding.mount_body().global_position.distance_to(point)
		if not await _move_mount_to(point, maxi(900, int(distance * 45.0)), 2.5):
			return false
	if not await _move_mount_to(_anchor(str(route.to_anchor)), 1600, 1.8):
		return false
	_note("Mounted authored crossing completed " + id)
	return true


func _move_mount_to(target: Vector3, budget: int, tolerance: float) -> bool:
	if not target.is_finite():
		return _fail("Mounted target is not finite")
	for frame in budget:
		if _expired() or not _same_party() or not _riding.is_mounted() \
				or not is_instance_valid(_riding.mount_body()) or _riding.mount_body().instance != _swimmer:
			return _fail("Retained mount/party/deadline lost during physical crossing")
		var offset: Vector3 = target - _riding.mount_body().global_position
		offset.y = 0
		if offset.length() <= tolerance:
			_stop_stick()
			await _frames(6)
			return not _expired()
		var local: Vector3 = _camera.planar_basis().inverse() * offset.normalized()
		_stick(local.x, local.z)
		await _tree.physics_frame
	return _fail("Mounted leg exhausted %d frames: at=%s target=%s" % [budget,
		str(_riding.mount_body().global_position), str(target)])


func _riding_press(label: String) -> bool:
	await _frames(8)
	if _expired() or _arbiter.winning_provider() != _riding \
			or not bool(_arbiter.winner().get("actionable", false)):
		return _fail(label + " actual Riding provider does not own Interact")
	_activated = null
	await _tap(&"interact")
	if _activated != _riding or _expired():
		return _fail(label + " physical Interact did not activate Riding before the deadline")
	return true


func _dismount_on_land(label: String) -> bool:
	if not _riding.is_mounted() or _world.water_depth_at(_riding.mount_body().global_position) >= 1.2:
		return _fail(label + " does not have a dry mounted arrival")
	if not await _riding_press(label + " dismount"):
		return false
	await _frames(12)
	if _riding.is_mounted() or not _player.is_on_floor():
		return _fail(label + " controller dismount did not finish grounded")
	return _same_deployed_swimmer()


func _mount_existing(label: String) -> bool:
	if not await _ensure_ally_deployed(label) or not _same_deployed_swimmer():
		return _fail(label + " lost the retained swimmer")
	var body: Node3D = _director.ally_body()
	if not await _walk_to(body.global_position, label, float(body.body_radius()) + 2.5) \
			or not await _riding_press(label + " mount"):
		return false
	await _frames(12)
	if not _riding.is_mounted() or _riding.mount_body().instance != _swimmer or _expired():
		return _fail(label + " did not mount the retained swimmer before the deadline")
	return true


func _recall_active(label: String) -> bool:
	if not _same_deployed_swimmer():
		return _fail(label + " requires the retained deployed swimmer")
	await _tap(&"creature_recall")
	await _frames(12)
	if _director.ally_body() != null or _expired():
		return _fail(label + " did not recall the retained swimmer before the deadline")
	return true


func _walk_land_route(id: String) -> bool:
	var points := _land_route(id)
	if points.is_empty():
		return _fail("Missing authored land route " + id)
	for point: Vector3 in points.slice(1):
		if not await _walk_to(point, id):
			return false
	return true


func _activate_dock_action(id: String, flag: String) -> bool:
	var equipment := _docks.get_node_or_null(id) as Node3D
	if not await _activate(_provider_child(equipment), id) or not await _wait_world_flag(flag, 180):
		return _fail("Physical dock action did not earn " + flag)
	_note("Earned " + flag)
	return true


func _drain_dialogue() -> bool:
	var panel := _world.get_node_or_null("DialoguePanel")
	if panel == null:
		return _fail("Production dialogue panel is missing")
	for line in 80:
		if _expired():
			return false
		if not panel.is_open():
			return true
		await _tap(&"interact")
		await _frames(2)
	return _fail("Production conversation exceeded its original 80-line bound")


func _defeat_trainer(id: String, flag: String) -> bool:
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var passed := await _fight_at_normal_clock(id, flag)
	_stop_combat_input()
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	return passed


func _fight_at_normal_clock(id: String, flag: String) -> bool:
	if not TRAINERS.has(id) or not _director.trainer_nodes.has(id) \
			or not await _ensure_ally_deployed(id) or not _same_deployed_swimmer():
		return _fail("Trainer or retained swimmer missing for " + id)
	if not await _activate(_director.trainer_prompts.get(id), id + " challenge") \
			or not await _drain_dialogue():
		return false
	var deadline := Time.get_ticks_msec() + 15000
	while not _director.trainer_battle_active() and Time.get_ticks_msec() < deadline and not _expired():
		await _tree.physics_frame
	if not _director.trainer_battle_active() or _director.trainer_battle_id() != id:
		return _fail(id + " did not enter its production hosted trainer battle")
	var opponents: Dictionary = {}
	deadline = Time.get_ticks_msec() + 180000
	var tick := 0
	while _director.trainer_battle_active() and Time.get_ticks_msec() < deadline and not _expired():
		var enemy: Node3D = _manager.enemy_body()
		var ally: Node3D = _director.ally_body()
		if is_instance_valid(enemy) and is_instance_valid(ally) and _manager.is_fighting():
			opponents[enemy.get_instance_id()] = str(enemy.instance.species_id)
			var offset := enemy.global_position - ally.global_position
			offset.y = 0
			_stop_stick()
			# Facing is earned by ordinary movement, never body.face_towards().
			if offset.length() > _manager.combat_move_reach("quick") * 0.8 \
					or ally.facing().dot(offset.normalized()) < 0.95:
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
	if _expired() or _director.trainer_battle_active():
		return _fail(id + " exceeded its original 180-second fight bound or total deadline")
	if opponents.size() != int(TRAINERS[id]) or not await _drain_dialogue() \
			or not await _wait_world_flag(flag, 180) or not _same_deployed_swimmer():
		return _fail(id + " lacked complete opponents/durable victory/retained surviving swimmer")
	_note("Hosted victory %s opponents=%s hp=%.1f/%.1f" % [id, str(opponents.values()),
		float(_swimmer.hp), float(_swimmer.max_hp)])
	return true


func _wait_world_flag(id: String, frames: int) -> bool:
	for frame in frames:
		if _expired():
			return false
		if _game.world.flags.has(id):
			return true
		await _tree.physics_frame
	return not _expired() and _game.world.flags.has(id)


func _tap(action: StringName) -> void:
	if _expired():
		return
	# Both GUI and gameplay edges must span real process/physics observation.
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	if not _expired():
		await super._tap(action)
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before


func _frames(count: int) -> void:
	for frame in count:
		if _expired():
			return
		await _tree.physics_frame


func _note(message: String) -> void:
	transcript.append(message)
	print("EARNED LATE WATER %.3f: %s" % [Time.get_ticks_msec() / 1000.0, message])


func result() -> Dictionary:
	return {"ok": _completed and failures.is_empty(), "passed": _completed and failures.is_empty(),
		"failures": failures.duplicate(), "transcript": transcript.duplicate(), "swimmer": _swimmer,
		"party": _carried.duplicate(), "endpoint": "guardian_freed_before_invitation"}


func _recover_at_camp(label: String, camp_id: String = CAMP_ID) -> bool:
	if _expired() or not _same_party():
		return _fail("Camp lost retained party or total deadline")
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
		await _frames(1)
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
	while int(_game.day) == day_before and Time.get_ticks_msec() < deadline and not _expired():
		await _frames(1)
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
			return not _expired() and _same_deployed_swimmer()
		await _frames(1)
	return _fail("Shellwatch camp did not redeploy the recovered creature " + label)




# Local deadline seam preserves the shared navigator's exact recovery/held
# accounting without changing any other campaign helper or its frame budgets.
class DeadlineNavigator extends "res://tests/helpers/stick_navigator.gd":
	var deadline := 0
	func walk_to(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
		if deadline <= Time.get_ticks_msec():
			return false
		reset()
		_confined_resets = 0
		var held := 0
		var walked := 0
		# The leg-level watchdog's rolling anchor -- see `CONFINED_FRAMES`.
		var anchor := _player.global_position
		var anchor_age := 0
		while walked < budget:
			if Time.get_ticks_msec() >= deadline:
				_drive.call(0.0, 0.0)
				return false
			var to := point - _player.global_position
			to.y = 0.0
			if to.length() <= close_enough:
				return true
			if not can_walk():
				held += 1
				if held > HELD_FRAMES:
					return false
				# Hands off the stick, and forget the stall this was building up:
				# nothing that happened while the body was frozen says anything
				# about what is in the way.
				_drive.call(0.0, 0.0)
				reset()
				# The anchor goes with it. A fight the body stood still through is
				# not evidence that the walk is confined, and counting those frames
				# would fire the watchdog on a walk that was never stuck.
				anchor = _player.global_position
				anchor_age = 0
				await _tree.physics_frame
				continue
			walked += 1
			if _player.global_position.distance_to(anchor) > CONFINED_RADIUS_M:
				anchor = _player.global_position
				anchor_age = 0
			else:
				anchor_age += 1
				if anchor_age >= CONFINED_FRAMES:
					# S06-50. The leg has gone nowhere for twenty seconds of real
					# walking. Do what the next `move_to` would have done -- forget
					# the committed side, the running detour and the stall count --
					# and back straight out, which is the one direction the body is
					# known to have come from. `_back_off` sets no side of its own,
					# so the next stall re-probes fresh from wherever this lands.
					_confined_resets += 1
					reset()
					_back_off(to)
					anchor = _player.global_position
					anchor_age = 0
			await step(point)
		return false


func _walk_to(target: Vector3, label: String, tolerance: float = 1.3) -> bool:
	if _expired() or not target.is_finite():
		return _fail(label + " target/deadline is invalid")
	var navigator := DeadlineNavigator.new(_tree, _player, _camera, _stick)
	navigator.deadline = _deadline
	var horizontal := Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(target.x, target.z))
	var arrived := await navigator.walk_to(target, maxi(1200, int(horizontal * 65.0)), tolerance)
	_stop_stick()
	if not arrived or _expired():
		return _fail("%s walk failed at %s toward %s resets=%d" % [label,
			str(_player.global_position), str(target), navigator.confined_resets()])
	await _frames(4)
	return not _expired()


func _ensure_ally_deployed(label: String) -> bool:
	if _expired() or not _same_party() or _game.local.party.active() != _swimmer or _swimmer.fainted:
		return _fail(label + " retained swimmer is not the usable active member")
	if _director.ally_body() == null:
		await _tap(&"creature_recall")
	for frame in 180:
		if _expired():
			return false
		if _same_deployed_swimmer():
			return true
		await _tree.physics_frame
	return _fail(label + " did not controller-deploy retained swimmer")
