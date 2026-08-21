extends SceneTree

## Gate A's production-faithful opening preflight, as one uninterrupted run.
##
## This intentionally does not use the shortcuts in smoke_catching.gd: no
## direct starter adoption, inventory seeding, teleport, HP assignment, or
## camera-yaw assignment. Every player action starts as a physical joypad event
## and travels through the live InputMap. State is read only to know when the
## next visible action is ready and to print useful checkpoint timings.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"
const STARTER_PICKER_SCRIPT := "res://scripts/ui/starter_picker.gd"
const NAME_ENTRY := preload("res://scripts/ui/name_entry.gd")
const CHOSEN_NAME := "Bud"

var _failures: Array[String] = []
var _started_ms := 0
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _sequence: Node = null
var _encounter: Node = null
var _combat: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null
var _starter_picker: CanvasLayer = null
var _wild: Node3D = null
var _catch_results: Array[bool] = []
var _throw_strikes := 0
var _throw_misses := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_started_ms = Time.get_ticks_msec()
	if str(ProjectSettings.get_setting("application/run/main_scene", "")) != TITLE_SCENE:
		_fail("configured main scene is not the production title")
		_finish()
		return
	if not _required_pad_actions_exist():
		_finish()
		return

	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	_checkpoint("title interactive")
	var focused := root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start New Game":
		_fail("title focus is not on Start New Game")
		_finish()
		return
	await _tap_action("ui_accept")
	for _i in 2400:
		if current_scene != null and current_scene.scene_file_path == WORLD_SCENE:
			_world = current_scene
			break
		await process_frame
	if _world == null:
		_fail("Start New Game never reached the configured Meadows world")
		_finish()
		return
	_checkpoint("new game world entered")
	for _i in 300:
		await physics_frame
	if not _collect_world_nodes():
		_finish()
		return

	var get_up := _find_interactable(["get up"])
	if get_up == null or not await _walk_to_and_activate(get_up, 600):
		_fail("the real wake-up prompt could not be reached and activated")
		_finish()
		return
	if str(_sequence.call("beat")) == "wake":
		_fail("Get Up did not advance the opening")
		_finish()
		return
	_checkpoint("wake/Get Up complete")

	var house := _world.get_node_or_null(^"GrandpaHouse")
	if house == null:
		_fail("production world has no GrandpaHouse")
		_finish()
		return
	if not await _walk_toward(house.call("marker", "stairs_top"), 500):
		_fail("could not naturally reach the stair head")
	if _failures.is_empty() and not await _walk_toward(house.call("marker", "stairs_bottom"), 500):
		_fail("could not naturally descend Grandpa's stairs")
	if not _failures.is_empty():
		_finish()
		return
	var grandpa := _find_interactable(["grandpa", "talk"])
	if grandpa == null or not await _walk_to_and_activate(grandpa, 700):
		_fail("Grandpa's real interaction could not be completed")
		_finish()
		return
	if not await _close_dialogue(50):
		_fail("Grandpa's briefing did not close through physical Interact presses")
		_finish()
		return
	_checkpoint("Grandpa briefing and pack complete")

	for _i in 120:
		if bool(_starter_picker.call("is_open")):
			break
		await physics_frame
	if not bool(_starter_picker.call("is_open")):
		_fail("starter picker did not open after the real briefing")
		_finish()
		return
	await _tap_action("ui_right")
	await _tap_action("menu_confirm")
	for _i in 60:
		if bool(_name_prompt.call("is_open")):
			break
		await physics_frame
	if not bool(_name_prompt.call("is_open")):
		_fail("physical starter selection did not open naming")
		_finish()
		return
	await _type_name_with_pad(CHOSEN_NAME)
	if not _failures.is_empty():
		_finish()
		return
	for _i in 600:
		if _game.party.size() == 1:
			break
		await physics_frame
	if _game.party.size() != 1 or str(_game.party.at(0).nickname) != CHOSEN_NAME:
		_fail("named starter did not reach the real one-creature party")
		_finish()
		return
	_checkpoint("starter selected and named")

	if not await _close_dialogue(20):
		_fail("Grandpa's post-name reply did not return control")
		_finish()
		return
	if not await _walk_toward(house.call("marker", "grandpa"), 500):
		_fail("could not cross the ground floor after naming")
	if _failures.is_empty() and not await _walk_toward(house.call("marker", "door"), 700):
		_fail("could not leave the now-unlocked front doorway")
	if not _failures.is_empty():
		_finish()
		return
	_checkpoint("usable house/front doorway exited")

	_wild = _encounter.call("wild_creature") as Node3D
	if _wild == null:
		_fail("opening has no naturally spawned tutorial Bramblebun")
		_finish()
		return
	if str(_wild.get("species_id")) != "bramblebun":
		_fail("opening's natural tutorial creature is '%s', not Bramblebun" % str(_wild.get("species_id")))
		_finish()
		return
	if not await _walk_to_and_engage_wild(_wild, 2600):
		_fail("natural travel did not reach and engage the tutorial Bramblebun")
		_finish()
		return
	for _i in 180:
		if bool(_combat.call("is_fighting")):
			break
		await physics_frame
	if not bool(_combat.call("is_fighting")):
		_fail("Interact at the natural Bramblebun did not enter real combat")
		_finish()
		return
	_checkpoint("tutorial Bramblebun combat entered")

	if not await _fight_until_catchable():
		_finish()
		return
	if not await _catch_with_real_throws():
		_finish()
		return
	for _i in 900:
		if not bool(_combat.call("is_fighting")):
			break
		await physics_frame
	if bool(_combat.call("is_fighting")) or str(_combat.call("outcome")) != "caught":
		_fail("successful catch did not return to exploration")
	elif _game.party.size() != 2:
		_fail("catch returned to exploration with %d party members, expected two" % _game.party.size())
	elif not bool(_player.call("locomotion_enabled")):
		_fail("trainer locomotion was not restored after the catch")
	else:
		_checkpoint("catch complete; exploration resumed with two-creature party")
	_finish()


func _collect_world_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_encounter = _world.get_node_or_null(^"EncounterDirector")
	_combat = _world.get_node_or_null(^"CombatManager")
	_arbiter = get_first_node_in_group(&"interaction_arbiter")
	_sequence = _find_by_script(_world, DIRECTOR_SCRIPT)
	_dialogue = _find_by_method(_world, "drain_effects") as CanvasLayer
	_name_prompt = _find_by_method(_world, "current_text") as CanvasLayer
	_starter_picker = _find_by_script(_world, STARTER_PICKER_SCRIPT) as CanvasLayer
	if (_game == null or _player == null or _rig == null or _encounter == null
			or _arbiter == null
			or _combat == null or _sequence == null or _dialogue == null
			or _name_prompt == null or _starter_picker == null):
		_fail("production world is missing an opening/combat/UI dependency")
		return false
	_combat.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _catch_results.append(success))
	var throw: Node = _combat.call("throw_aim")
	throw.connect("orb_struck", func(_target: Node3D, _offset: float) -> void: _throw_strikes += 1)
	throw.connect("orb_missed", func() -> void: _throw_misses += 1)
	return true


func _type_name_with_pad(chosen: String) -> void:
	for _i in 20:
		if bool(_name_prompt.get("_using_gamepad")):
			break
		await physics_frame
	if not bool(_name_prompt.get("_using_gamepad")):
		_fail("naming prompt did not remain in gamepad mode after real pad input")
		return
	var entry: RefCounted = _name_prompt.call("entry")
	for character in chosen:
		if not await _select_name_cell(entry, character):
			return
		await _tap_action("menu_confirm")
	if str(_name_prompt.call("current_text")) != chosen:
		_fail("controller typed '%s', expected '%s'" % [str(_name_prompt.call("current_text")), chosen])
		return
	if not await _select_name_cell(entry, NAME_ENTRY.DONE):
		return
	await _tap_action("menu_confirm")
	for _i in 120:
		if not bool(_name_prompt.call("is_open")):
			return
		await physics_frame
	_fail("controller Done did not close naming")


func _select_name_cell(entry: RefCounted, cell: String) -> bool:
	var target := Vector2i(-1, -1)
	for row_index in NAME_ENTRY.ROWS.size():
		var row: Array = NAME_ENTRY.ROWS[row_index]
		for column_index in row.size():
			if str(row[column_index]) == cell:
				target = Vector2i(row_index, column_index)
	if target.x < 0:
		_fail("naming grid has no '%s' cell" % cell)
		return false
	for _i in 16:
		if int(entry.row) == target.x:
			break
		await _tap_action("ui_down")
	for _i in 20:
		if int(entry.column) == target.y:
			break
		await _tap_action("ui_right")
	if str(entry.selected()) != cell:
		_fail("controller stopped on '%s' instead of '%s'" % [str(entry.selected()), cell])
		return false
	return true


func _fight_until_catchable() -> bool:
	var ally := _encounter.call("ally_body") as Node3D
	var foe: RefCounted = _combat.call("enemy")
	var own: RefCounted = _combat.call("active_creature")
	if ally == null or foe == null or own == null:
		_fail("combat started without both real creature instances/bodies")
		return false
	for _i in 1800:
		if not bool(_combat.call("is_fighting")):
			_fail("fight ended before the Bramblebun became catchable")
			return false
		if own.fainted:
			_fail("starter fainted before naturally weakening the tutorial Bramblebun")
			return false
		if float(foe.hp) <= float(foe.max_hp) * 0.28:
			_checkpoint("Bramblebun naturally weakened to %.0f/%d HP" % [foe.hp, foe.max_hp])
			return true
		await _drive_body_toward(ally, _wild.global_position, 1)
		if ally.global_position.distance_to(_wild.global_position) < 4.0 and _i % 35 == 0:
			await _tap_action("combat_quick")
	_stop_left_stick()
	_fail("real piloted attacks did not weaken Bramblebun within the bounded fight")
	return false


func _catch_with_real_throws() -> bool:
	var launches := 0
	while launches < 8:
		if not bool(_combat.call("is_fighting")):
			break
		# A resolved throw has a production 0.9s cooldown. One press during that
		# window is deliberately ignored, so retry until a real aim opens instead
		# of counting the ignored press as one of this evidence run's launches.
		# The old loop therefore launched only on iterations 2/4/6/8 after a miss,
		# exactly matching the alternating outcomes in the continuous-run log.
		if not await _open_throw_aim():
			_fail("catch aim did not reopen after its bounded cooldown")
			return false
		if not await _aim_camera_at(_wild, 360):
			_fail("right-stick aim could not line up the real throw reticle")
			return false
		var results_before := _catch_results.size()
		var strikes_before := _throw_strikes
		var misses_before := _throw_misses
		await _tap_action("combat_throw")
		launches += 1
		# A launch is not a landed throw. Wait first for the projectile's physical
		# outcome, so a miss advances the retry immediately instead of spending the
		# full catch-resolution budget waiting for a signal that only a strike can
		# emit. This distinction exposed the old false inference: eight committed
		# orbs were reported as eight catch attempts even when none had landed.
		for _i in 360:
			if (_throw_strikes > strikes_before or _throw_misses > misses_before
					or not bool(_combat.call("is_fighting"))):
				break
			await physics_frame
		if _throw_misses > misses_before:
			print("physical launch %d went wide; retrying after a real miss" % launches)
			continue
		if _throw_strikes <= strikes_before:
			_fail("physical launch %d produced no strike or miss outcome" % launches)
			return false
		for _i in 900:
			if _catch_results.size() > results_before or not bool(_combat.call("is_fighting")):
				break
			await physics_frame
		if _catch_results.size() > results_before and _catch_results[-1]:
			_checkpoint("physical landed throw caught Bramblebun on launch %d (%d strike(s), %d miss(es))" % [
				launches, _throw_strikes, _throw_misses,
			])
			return true
	_fail("eight natural weakened-target launches produced %d strike(s), %d miss(es), and no catch" % [
		_throw_strikes, _throw_misses,
	])
	return false


## Open a fresh physical aim after any preceding throw's lockout.
##
## `try_begin_aim()` intentionally ignores input during its cooldown and emits
## no refusal. A single press cannot distinguish that expected lockout from a
## dropped controller input, so use the same bounded retry pattern as the
## focused controller-catching smoke.
func _open_throw_aim() -> bool:
	for _attempt in 18:
		await _tap_action("combat_throw")
		for _i in 6:
			if bool(_combat.call("is_aiming")):
				return true
			await physics_frame
	return false


func _aim_camera_at(target: Node3D, budget: int) -> bool:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return false
	var last_yaw_error := 0.0
	var last_pitch_error := 0.0
	for _i in budget:
		# The opponent keeps circling while the trainer aims. Lead the visible
		# body by one short throw flight, through the raw right-stick path, just as
		# a player leads the moving creature using the production trajectory arc.
		# Aiming at its current centre and then committing was the harness bug: the
		# reticle converged truthfully, but the creature had moved before impact.
		var velocity := Vector3.ZERO
		if target is CharacterBody3D:
			velocity = (target as CharacterBody3D).velocity
		var predicted := (target.call("centre") as Vector3) + velocity * 0.30
		var to := predicted - camera.global_position
		var desired_yaw := atan2(-to.x, -to.z)
		var desired_pitch := atan2(to.y, maxf(Vector2(to.x, to.z).length(), 0.01))
		var yaw_error := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_error := desired_pitch - float(_rig.get("pitch"))
		last_yaw_error = yaw_error
		last_pitch_error = pitch_error
		if absf(yaw_error) < deg_to_rad(2.0) and absf(pitch_error) < deg_to_rad(2.0):
			_stop_right_stick()
			return true
		# The target keeps circling while aim owns the trainer. Full deflection is
		# intentional here: proportional easing fell behind the live target even
		# though the stick was correctly mapped, creating a harness-only miss.
		var yaw_strength := 1.0 if absf(yaw_error) >= deg_to_rad(2.0) else 0.0
		var pitch_strength := 1.0 if absf(pitch_error) >= deg_to_rad(2.0) else 0.0
		_send_axis(JOY_AXIS_RIGHT_X, -signf(yaw_error) * yaw_strength)
		_send_axis(JOY_AXIS_RIGHT_Y, -signf(pitch_error) * pitch_strength)
		await physics_frame
	_stop_right_stick()
	print("aim convergence stopped at yaw %.2f°, pitch %.2f°" % [rad_to_deg(last_yaw_error), rad_to_deg(last_pitch_error)])
	return false


func _walk_to_and_activate(target: Node3D, budget: int) -> bool:
	if not await _walk_toward(target.global_position, budget, 2.0):
		return false
	await _tap_action("interact")
	return true


## Wild creatures wander while the trainer crosses the meadow. Following the
## position captured at the farmhouse door can therefore stop at empty grass,
## unlike a player who keeps the visible creature in view. Reach the live body
## and wait until the production arbiter actually publishes EncounterDirector's
## actionable offer before sending the same physical Interact press a player
## uses. This observes readiness; it does not activate the arbiter directly.
func _walk_to_and_engage_wild(target: Node3D, budget: int) -> bool:
	var closest := INF
	for _i in budget:
		if not is_instance_valid(target):
			print("wild approach: target despawned")
			_stop_left_stick()
			return false
		var distance := _player.global_position.distance_to(target.global_position)
		closest = minf(closest, distance)
		var winner: Object = _arbiter.call("winning_provider")
		var offer := _arbiter.call("winner") as Dictionary
		if winner == _encounter and bool(offer.get("actionable", false)):
			_stop_left_stick()
			for _j in 3:
				await physics_frame
			# Recheck after releasing movement: the target may have crossed the
			# edge of the interaction radius during those settling frames.
			winner = _arbiter.call("winning_provider")
			offer = _arbiter.call("winner") as Dictionary
			if winner == _encounter and bool(offer.get("actionable", false)):
				print("wild approach: ready at %.2fm with '%s'" % [
					_player.global_position.distance_to(target.global_position),
					str(_arbiter.call("prompt")),
				])
				await _tap_action("interact")
				return true
		await _drive_body_toward(_player, target.global_position, 1)
	_stop_left_stick()
	print("wild approach: exhausted after closest %.2fm; final %.2fm; visible=%s alive=%s prompt='%s' winner=%s" % [
		closest,
		_player.global_position.distance_to(target.global_position),
		target.visible,
		bool(target.call("is_alive")),
		str(_arbiter.call("prompt")),
		str(_arbiter.call("winning_provider")),
	])
	return false


func _walk_toward(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	for _i in budget:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			_stop_left_stick()
			for _j in 5:
				await physics_frame
			return true
		await _drive_body_toward(_player, point, 1)
	_stop_left_stick()
	return false


func _drive_body_toward(body: Node3D, point: Vector3, frames: int) -> void:
	var direction := point - body.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		_stop_left_stick()
		return
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction.normalized()
	_send_axis(JOY_AXIS_LEFT_X, local.x)
	_send_axis(JOY_AXIS_LEFT_Y, local.z)
	for _i in frames:
		await physics_frame


func _close_dialogue(max_presses: int) -> bool:
	for _i in max_presses:
		if not bool(_dialogue.call("is_open")):
			return true
		await _tap_action("interact")
	return not bool(_dialogue.call("is_open"))


func _tap_action(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	Input.parse_input_event(event)
	for _i in 3:
		await physics_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for configured in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _required_pad_actions_exist() -> bool:
	for action in [&"ui_accept", &"ui_right", &"ui_down", &"menu_confirm", &"interact", &"combat_quick", &"combat_throw"]:
		if _event_for(action, true) == null:
			_fail("required action '%s' has no physical joypad binding" % action)
	return _failures.is_empty()


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_left_stick() -> void:
	_send_axis(JOY_AXIS_LEFT_X, 0.0)
	_send_axis(JOY_AXIS_LEFT_Y, 0.0)


func _stop_right_stick() -> void:
	_send_axis(JOY_AXIS_RIGHT_X, 0.0)
	_send_axis(JOY_AXIS_RIGHT_Y, 0.0)


func _find_interactable(words: Array[String]) -> Node3D:
	for node in _descendants(_world):
		if not node is Node3D:
			continue
		var script := node.get_script() as Script
		if script == null or script.resource_path != INTERACTABLE_SCRIPT or not bool(node.get("enabled")):
			continue
		var lowered := str(node.get("label")).to_lower()
		for word in words:
			if lowered.contains(word.to_lower()):
				return node as Node3D
	return null


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _find_by_method(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child in node.get_children():
		var found := _find_by_method(child, method)
		if found != null:
			return found
	return null


func _find_by_script(node: Node, path: String) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _checkpoint(label: String) -> void:
	print("GATE A OPENING +%.2fs — %s" % [(Time.get_ticks_msec() - _started_ms) / 1000.0, label])


func _fail(message: String) -> void:
	if not _failures.has(message):
		_failures.append(message)
	push_error(message)


func _finish() -> void:
	_stop_left_stick()
	_stop_right_stick()
	print("")
	if _failures.is_empty():
		print("gate A opening segment: OK — title through natural catch passed continuously with parsed controller input")
	else:
		for message in _failures:
			print("gate A opening segment FAIL: %s" % message)
	quit(0 if _failures.is_empty() else 1)
