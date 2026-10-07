extends "res://tests/helpers/f49_portal_travel.gd"

## Preserve the existing real navigation/provider/authority checks. Hold a
## normal button edge through both clocks: world X is read on physics ticks,
## while inventory/credits also read idle frames.
const LESSON_PANEL := preload("res://scripts/onboarding/lesson_panel.gd")
var _lesson_busy := false
var _lesson_active := false
var _lesson_generation := 0
var before_interact: Callable
var trace_input := false
var _lesson_controller_input := false
var _lesson_capture_probe: RefCounted

static func lesson_witness_options() -> Dictionary:
	var options := {"controller": false, "capture": false, "skip_line": 0, "failures": []}
	var seen := {}
	for arg: String in OS.get_cmdline_user_args():
		var key := ""
		if arg.begins_with("--lesson-controller-witness"):
			key = "controller"
			if arg != "--lesson-controller-witness": options.failures.append("Use --lesson-controller-witness without a value")
			options.controller = true
		elif arg.begins_with("--capture-lessons"):
			key = "capture"
			if arg != "--capture-lessons": options.failures.append("Use --capture-lessons without a value")
			options.capture = true
		elif arg.begins_with("--lesson-skip-line"):
			key = "skip_line"
			var value := arg.trim_prefix("--lesson-skip-line=")
			if not arg.begins_with("--lesson-skip-line=") or not value.is_valid_int() \
				or int(value) < 0 or str(int(value)) != value:
				options.failures.append("--lesson-skip-line requires one nonnegative zero-based integer")
			else:
				options.skip_line = int(value)
		if not key.is_empty():
			if seen.has(key): options.failures.append("Duplicate lesson option: " + key)
			seen[key] = true
	if seen.has("skip_line") and not options.controller:
		options.failures.append("--lesson-skip-line requires --lesson-controller-witness")
	if options.capture and OS.get_cmdline_user_args().has("--functional-offload"):
		options.failures.append("--capture-lessons requires drawing and cannot use --functional-offload")
	return options

func _portal_result(result: Dictionary) -> void:
	super._portal_result(result)
	# A refused begin is terminal for this ordinary Use, never a successful
	# arrival. The shared walker otherwise waits only for finish replies.
	if result.get("kind") == "home_key_begin" and result.get("ok") == false \
		and result.get("character_id") == game.local.character_id \
		and result.get("world_instance_id") == game.world.reward_delivery_namespace:
		_home_result = result.duplicate(true)

func activate(prompt: Node3D) -> bool:
	# A lesson may be due on this character's first walk past its teacher.
	# Read/continue its real card; retain the original navigation budget and
	# exact grounded/provider checks after ordinary world input returns.
	return await _with_navigation_lessons(_activate_world.bind(prompt))

func _with_navigation_lessons(navigate: Callable) -> bool:
	if _lesson_active or _lesson_busy: return _fail("F20 navigation re-entered its active lesson reader")
	var options := lesson_witness_options()
	if not options.failures.is_empty():
		failures.append_array(options.failures)
		return false
	var failures_before := failures.size()
	_lesson_generation += 1
	_lesson_active = true
	var reader := _continue_navigation_lesson.bind(_lesson_generation)
	# The service can offer another due lesson on the same panel after the
	# first receipt. Finish each actual card before binding world input.
	while failures.size() == failures_before:
		var owner := INPUT_OWNER.current(tree)
		if owner == null or owner.get_script() != LESSON_PANEL or not owner.call("is_open"): break
		await reader.call()
	var passed := false
	if failures.size() == failures_before:
		tree.process_frame.connect(reader)
		passed = await navigate.call()
		# Signal emission copies its callable list. Invalidate this invocation
		# before disconnect so a copied callback cannot enter after it returns,
		# including when this helper is reused by the next navigation command.
		_lesson_active = false
		tree.process_frame.disconnect(reader)
	else:
		_lesson_active = false
	# An entered reader still owns its press/release and personal receipt.
	while _lesson_busy: await tree.process_frame
	return passed and failures.size() == failures_before

## Full two-peer proof separates the physical walk from the authored reader.
## This command never presses X; activate() still proves the original input.
func approach_grandpa(prompt: Node3D) -> bool:
	if prompt == null or prompt.get_parent().name != "Grandpa":
		return _fail("F20 approach requires the actual Grandpa prompt")
	return await _with_navigation_lessons(_walk_to_grandpa.bind(prompt))

func _walk_to_grandpa(prompt: Node3D) -> bool:
	if not _bind(): return false
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F20 Grandpa approach lacks the actual arbiter")
	var recoveries_before := int(_player.get("_unstick_count"))
	var nav := NAV.new(tree, _player, _rig, _stick)
	var distance := _player.global_position.distance_to(prompt.global_position)
	var budget := maxi(1200, int(distance * 65.0))
	# Grandpa stands inside the farmhouse. A straight line from the Hall meets
	# its wall beside the door, so walk the authored doorway first: a point
	# outside on the inside->door line, then the prompt. The same total frame
	# budget is shared in proportion to each leg; checks below are unchanged.
	var house: Node = tree.current_scene.find_child("GrandpaHouse", true, false)
	var legs: Array[Vector3] = [prompt.global_position]
	if house != null and house.has_method("marker"):
		var door: Variant = house.call("marker", "door")
		var inside: Variant = house.call("marker", "inside")
		if door is Vector3 and inside is Vector3 and (door as Vector3).distance_to(inside) > 0.1:
			var out_dir: Vector3 = ((door as Vector3) - (inside as Vector3)).normalized()
			legs.push_front((door as Vector3) + out_dir * 2.0)
	var total := 0.0
	var at := _player.global_position
	for leg: Vector3 in legs:
		total += at.distance_to(leg)
		at = leg
	at = _player.global_position
	var reached := true
	for index in legs.size():
		var leg: Vector3 = legs[index]
		var share := int(float(budget) * at.distance_to(leg) / maxf(total, 0.001))
		var close := 2.5 if index == legs.size() - 1 else 1.0
		reached = await nav.walk_to(leg, maxi(1, share), close)
		at = leg
		if not reached: break
	_stick(0, 0)
	if not reached: return _fail("F20 ordinary capsule walk failed to Grandpa")
	for frame in 8: await tree.physics_frame
	for frame in 2: await tree.process_frame
	if int(_player.get("_unstick_count")) != recoveries_before or not _player.is_on_floor() \
			or arbiter.call("winning_provider") != prompt:
		var winning: Variant = arbiter.call("winning_provider")
		print("F20 APPROACH unstick=%d->%d on_floor=%s winner=%s at=%s prompt=%s" % [recoveries_before,
			int(_player.get("_unstick_count")), str(_player.is_on_floor()),
			str(winning.get_path()) if winning is Node else "none", str(_player.global_position), str(prompt.global_position)])
		var ending: Variant = game.call("regional_ending_context") if game.has_method("regional_ending_context") else {}
		var lifecycle: Node = game.get("session").get_node_or_null(^"FoundationComposition/TravelLifecycle") if game.get("session") != null else null
		print("F20 APPROACH ending=%s sample=%s offer=%s" % [str(ending), str(lifecycle.call("local_sample")) if lifecycle != null else "none",
			str(arbiter.call("winner"))])
		return _fail("F20 Grandpa approach requires grounded exact provider without recovery")
	var offer: Dictionary = arbiter.call("winner")
	return offer.get("actionable") == true or _fail("F20 actual Grandpa approach refused its action")

## Rematch prompts sit beside a trainer's original conversation prompt.
## Approach this actual provider closely through the original capsule walker;
## preserve range/LOS/winner/input checks without editing either prompt.
func activate_endgame_rematch(prompt: Node3D) -> bool:
	return await _with_navigation_lessons(_activate_endgame_rematch.bind(prompt))

func _activate_endgame_rematch(prompt: Node3D) -> bool:
	if prompt == null or prompt.get("label") != "Endgame rematch" or not _bind():
		return _fail("F20 rematch requires its actual enabled world provider")
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F20 rematch lacks the actual arbiter")
	var recoveries_before := int(_player.get("_unstick_count"))
	var distance := _player.global_position.distance_to(prompt.global_position)
	var nav := NAV.new(tree, _player, _rig, _stick)
	var reached: bool = await nav.walk_to(prompt.global_position, maxi(1200, int(distance * 65.0)), 0.6)
	_stick(0, 0)
	if not reached: return _fail("F20 ordinary capsule walk failed to endgame rematch")
	for frame in 8: await tree.physics_frame
	for frame in 2: await tree.process_frame
	if int(_player.get("_unstick_count")) != recoveries_before or not _player.is_on_floor() \
			or arbiter.call("winning_provider") != prompt or arbiter.call("winner").get("actionable") != true:
		print("F20 REMATCH provider expected=", prompt.get_path(), " winner=", arbiter.call("winning_provider"),
			" offer=", arbiter.call("winner"), " player=", _player.global_position, " target=", prompt.global_position)
		return _fail("F20 rematch lacks grounded exact actionable provider without recovery")
	_activated = null
	var director := tree.current_scene.get_node_or_null("EncounterDirector")
	var writer: Callable = director.get("_rematch_outcome_writer") if director != null else Callable()
	print("F20 REMATCH activation authority host=", game.session.call("is_host"),
		" active=", game.session.call("is_active"), " director=", director,
		" writer_valid=", writer.is_valid(), " bindings=", prompt.get_signal_connection_list("activated"))
	arbiter.connect("activated", _activation)
	var previous_trace := trace_input
	trace_input = true
	await tap("interact")
	trace_input = previous_trace
	if is_instance_valid(arbiter) and arbiter.is_connected("activated", _activation): arbiter.disconnect("activated", _activation)
	if _activated != prompt:
		var activated_node := _activated as Node
		var owner := INPUT_OWNER.current(tree)
		var manager: Node = director.get("_manager") if director != null else null
		var actual_source := director.get("_trainer_node") as Node if director != null else null
		print("F20 REMATCH activation expected=", prompt.get_path(),
			" actual=", activated_node.get_path() if is_instance_valid(activated_node) else str(_activated),
			" winner=", arbiter.call("winning_provider"), " offer=", arbiter.call("winner"),
			" enabled=", arbiter.call("enabled"), " owner=", owner.get_path() if owner != null else "none",
			" player=", _player.global_position, " target=", prompt.global_position,
			" trainer_active=", director.call("trainer_battle_active") if director != null else false,
			" trainer_source=", actual_source.get_path() if is_instance_valid(actual_source) else "none",
			" trainer_spec=", director.get("_trainer_spec") if director != null else {},
			" fighting=", manager.call("is_fighting") if manager != null else false)
	return _activated == prompt or _fail("F20 rematch X did not record its expected provider activation")

func _continue_navigation_lesson(generation: int) -> void:
	if not _lesson_active or generation != _lesson_generation or _lesson_busy: return
	var owner := INPUT_OWNER.current(tree)
	if owner == null or owner.get_script() != LESSON_PANEL or not owner.call("is_open"): return
	var options := lesson_witness_options()
	if not options.failures.is_empty():
		failures.append_array(options.failures)
		return
	_lesson_busy = true
	var row: Dictionary = (owner.get("_row") as Dictionary).duplicate(true)
	var id := str(row.get("id", ""))
	var character_id := str(game.local.character_id)
	var began := Time.get_ticks_msec()
	var line_count := int(row.get("lines", []).size())
	var start_line := int(owner.get("_line"))
	var presses := 0
	var input_ok := not id.is_empty() and start_line >= 0 and start_line < line_count
	var controller_witness: bool = options.controller
	var capture_lessons: bool = options.capture
	var observing := controller_witness or capture_lessons
	var skip_line: int = options.skip_line
	if controller_witness and (skip_line < start_line or skip_line >= line_count):
		_fail("Requested lesson skip line %d is outside actual %s lines %d..%d" % [skip_line, id, start_line, line_count - 1])
		_lesson_busy = false
		return
	if capture_lessons and _lesson_capture_probe == null:
		# Runtime load only: the existing probe preloads this travel helper.
		var capture_script := load("res://tests/helpers/f20_ending_probe.gd") as GDScript
		if capture_script == null:
			_fail("Existing F20 completed-frame capture could not load")
			_lesson_busy = false
			return
		_lesson_capture_probe = capture_script.new()
	var action := "menu_confirm"
	var skip_presses := 0
	var observed_lines: Array[Dictionary] = []
	var witness := {}
	var service := game.get_node_or_null(^"OnboardingLessons")
	if observing:
		var label := owner.get("_text") as Label
		witness = {"lesson": id, "character_id": character_id, "party_uids": _uids(),
			"conversation": row.get("conversation", ""), "speaker": row.get("speaker", ""),
			"line": start_line, "authored_lines": line_count,
			"text": label.text if label != null else "", "goal": row.get("goal", ""),
			"visible": label != null and label.is_visible_in_tree(),
			"ack_before": game.local.flags.call("has", "opening:lesson:" + id)}
		input_ok = input_ok and witness.visible and not witness.ack_before \
			and service != null and service.get("_panel") == owner and service.get("_replaying") == false
		if input_ok:
			input_ok = label.text == str(row.lines[start_line]) + "\n\nNext: " + str(row.get("goal", ""))
	var dismissed: Array[String] = []
	var dismissal_observer := func(lesson_id: String) -> void: dismissed.append(lesson_id)
	owner.connect("dismissed", dismissal_observer)
	print("F20 LESSON actual ordinary ", "Skip" if controller_witness else "Continue", " id=", id, " reader=", get_instance_id(),
		" generation=", generation, " ticks_ms=", began, " start_line=", start_line)
	# Each normal edge spans both clocks. Slow drawing can exhaust 30 seconds
	# during one edge, so bound input by the actual remaining authored lines;
	# the unchanged receipt deadline starts after the last released edge.
	while input_ok and dismissed.is_empty() and presses < line_count - start_line:
		if not is_instance_valid(owner) or INPUT_OWNER.current(tree) != owner \
			or not owner.call("is_open") or str(owner.get("_row").get("id", "")) != id \
			or str(game.local.character_id) != character_id:
			input_ok = false
			break
		var before_line := int(owner.get("_line"))
		if observing:
			if before_line != start_line + presses or before_line < 0 or before_line >= line_count:
				input_ok = false
				break
			var expected_text := str(row.lines[before_line]) + "\n\nNext: " + str(row.get("goal", ""))
			var line_matches := func() -> bool:
				if not is_instance_valid(owner) or not is_instance_valid(service) or INPUT_OWNER.current(tree) != owner \
					or service.get("_panel") != owner or service.get("_replaying") != false \
					or not owner.call("is_open") or owner.get("_row") != row or owner.get("_line") != before_line \
					or str(game.local.character_id) != character_id or _uids() != witness.party_uids:
					return false
				var label := owner.get("_text") as Label
				return is_instance_valid(label) and label.is_visible_in_tree() and label.text == expected_text
			input_ok = line_matches.call() == true
			if not input_ok: break
			var capture_label := "lesson-%s-reader-%d-generation-%d-line-%02d" % [id, get_instance_id(), generation, before_line]
			if capture_lessons:
				if not await _lesson_capture_probe.capture(tree, capture_label, line_matches):
					failures.append_array(_lesson_capture_probe.failures)
					input_ok = false
					break
				input_ok = line_matches.call() == true
				if not input_ok: break
			observed_lines.append({"line": before_line, "text": owner.get("_text").text,
				"capture_label": capture_label if capture_lessons else "", "captured": capture_lessons})
		print("F20 LESSON rendered ", owner.get("_text").text)
		action = "menu_cancel" if controller_witness and before_line == skip_line else "menu_confirm"
		_lesson_controller_input = controller_witness
		await tap(action)
		_lesson_controller_input = false
		presses += 1
		if action == "menu_cancel": skip_presses += 1
		input_ok = (dismissed == [id] and (not controller_witness or action == "menu_cancel")) \
			or (action == "menu_confirm" and is_instance_valid(owner) and owner.call("is_open") \
			and str(owner.get("_row").get("id", "")) == id and int(owner.get("_line")) == before_line + 1)
		if observing:
			input_ok = input_ok and not Input.is_action_pressed(action) and _uids() == witness.party_uids \
				and str(game.local.character_id) == character_id
	var released := not Input.is_action_pressed(action)
	if is_instance_valid(owner): owner.disconnect("dismissed", dismissal_observer)
	var receipt_began := Time.get_ticks_msec()
	var deadline := receipt_began + 30000
	while str(game.local.character_id) == character_id and Time.get_ticks_msec() < deadline \
		and game.local.flags.call("has", "opening:lesson:" + id) != true:
		await tree.process_frame
	var acknowledged: bool = str(game.local.character_id) == character_id \
		and game.local.flags.call("has", "opening:lesson:" + id) == true
	var original_open: bool = is_instance_valid(owner) and owner.call("is_open") \
		and str(owner.get("_row").get("id", "")) == id
	var completed := input_ok and released and is_instance_valid(owner) and not original_open \
		and dismissed == [id] and acknowledged
	if observing:
		completed = completed and _uids() == witness.party_uids \
			and str(game.local.character_id) == character_id \
			and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("menu_confirm") and not Input.is_action_pressed("ui_accept")
		if controller_witness:
			completed = completed and skip_presses == 1 and presses == skip_line - start_line + 1
		witness.merge({"action": action, "presses": presses, "skip_presses": skip_presses,
			"requested_skip_line": skip_line if controller_witness else null, "observed_lines": observed_lines,
			"controller_input": controller_witness, "dismissed": dismissed,
			"ack_after": acknowledged, "released": released, "original_open": original_open,
			"party_uids_after": _uids(), "passed": completed,
			"render_loop_enabled": RenderingServer.render_loop_enabled,
			"scope": "Observed lesson lines only; replay, unvisited lines and full F46 remain unproven"})
		print(("F46 LESSON CONTROLLER WITNESS " if controller_witness else "F46 LESSON OBSERVATION ") + JSON.stringify(witness))
	print("F20 LESSON result id=", id, " reader=", get_instance_id(), " generation=", generation,
		" completed=", completed, " elapsed_ms=", Time.get_ticks_msec() - began,
		" receipt_ms=", Time.get_ticks_msec() - receipt_began, " authored_lines=", line_count,
		" start_line=", start_line, " presses=", presses, " input_ok=", input_ok,
		" released=", released, " dismissed=", dismissed, " original_open=", original_open,
		" personal_ack=", acknowledged)
	if not completed:
		_fail("F20 ordinary lesson " + ("Skip" if controller_witness else "Continue") + " did not complete this character's actual " + id)
	else:
		print("F20 LESSON actual personal acknowledgement id=", id)
	_lesson_busy = false

func _activate_world(prompt: Node3D) -> bool:
	var bounty: Node = game.session.get_node_or_null("FoundationComposition/BountyInteraction")
	if bounty != null and bounty.get("_prompt") == prompt:
		return await _activate_bounty_via_road(prompt)
	# Hall arches face an authored room approach. Reaching their coordinates
	# from the exterior side of the wall does not establish a visible offer.
	# Walk the installed marker through the original capsule navigator first.
	if prompt != null and prompt.get_parent().get_script() == load("res://scripts/world/portal_arch.gd") and _bind():
		var approach := prompt.get_parent().get_parent().get_node_or_null("Approach") as Node3D
		if approach != null:
			var recoveries_before := int(_player.get("_unstick_count"))
			var nav := NAV.new(tree, _player, _rig, _stick)
			var distance := _player.global_position.distance_to(approach.global_position)
			var arrived: bool = await nav.walk_to(approach.global_position, maxi(1200, int(distance * 65.0)), 0.6)
			_stick(0, 0)
			if not arrived or int(_player.get("_unstick_count")) != recoveries_before:
				return _fail("F20 ordinary capsule walk failed to the authored Hall arch approach")
	var passed := await super.activate(prompt)
	if not passed and tree.current_scene != null:
		var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
		var owner := INPUT_OWNER.current(tree)
		print("F20 INPUT TRACE expected=", prompt.get_path() if is_instance_valid(prompt) else "missing",
			" activated=", _activated.get_path() if _activated is Node else str(_activated),
			" winner=", arbiter.call("winning_provider") if arbiter != null else null,
			" enabled=", arbiter.call("enabled") if arbiter != null else false,
			" fight_owns=", arbiter.call("_fight_owns_the_world") if arbiter != null else false,
			" owner=", owner.get_path() if owner != null else "none",
			" player_position=", _player.global_position if is_instance_valid(_player) else Vector3.INF,
			" prompt_position=", prompt.global_position if is_instance_valid(prompt) else Vector3.INF,
			" floor=", _player.is_on_floor() if is_instance_valid(_player) else false,
			" offer=", prompt.call("interaction_offer", _player.global_position) if is_instance_valid(prompt) and is_instance_valid(_player) else {},
			" dock_complete=", game.world.flags.call("has", "water_civilian_departure_complete"))
	return passed

func _activate_bounty_via_road(prompt: Node3D) -> bool:
	if prompt == null or not _bind(): return _fail("F20 bounty travel requires ordinary world input")
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F20 bounty travel lacks the actual interaction arbiter")
	var terrain: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	if not terrain is Dictionary or not terrain.get("paths") is Dictionary \
			or not terrain.paths.get("approaches") is Array:
		return _fail("F20 bounty travel lacks the authored village road")
	var road: Array = []
	var matches := 0
	for route: Variant in terrain.paths.approaches:
		if route is Dictionary and route.get("id") == "village_main_street":
			matches += 1
			if route.get("points") is Array: road = route.points
	if matches != 1 or road.size() != 2: return _fail("F20 bounty travel requires the one straight authored village road")
	var ends: Array[Vector2] = []
	for raw: Variant in road:
		if not raw is Array or raw.size() != 2 or not (raw[0] is int or raw[0] is float) \
				or not (raw[1] is int or raw[1] is float): return _fail("F20 bounty road coordinates are invalid")
		var at := Vector2(float(raw[0]), float(raw[1]))
		if not at.is_finite(): return _fail("F20 bounty road coordinates are not finite")
		ends.append(at)
	var start := Geometry2D.get_closest_point_to_segment(Vector2(_player.global_position.x, _player.global_position.z), ends[0], ends[1])
	var headings: Array[Vector3] = [Vector3(start.x, _player.global_position.y, start.y),
		Vector3(ends[1].x, _player.global_position.y, ends[1].y)]
	var distance := _player.global_position.distance_to(prompt.global_position)
	var recoveries_before := int(_player.get("_unstick_count"))
	var nav := NAV.new(tree, _player, _rig, _stick)
	# The failed diagonal crosses the south-side house row. Follow the actual
	# eastward road before turning onto the tournament lawn. All headings
	# share the original direct-distance budget and confined watchdog.
	print("F20 BOUNTY authored road headings=", headings, " target=", prompt.global_position)
	var reached: bool = await nav.walk_to_guided(prompt.global_position, maxi(1200, int(distance * 65.0)), 2.5, headings)
	_stick(0, 0)
	if not reached: return _fail("F20 ordinary bounty capsule walk failed via the authored village road")
	for frame in 8: await tree.physics_frame
	# The arbiter publishes its prompt in _process, whereas navigation and
	# settling use physics. r13's current board offer was nearer than the
	# stored Halda winner. Let ordinary idle callbacks publish the stopped
	# position; two edges include one completed callback pass, without calling
	# _recompute or changing the original exact-provider/input checks.
	for frame in 2: await tree.process_frame
	if int(_player.get("_unstick_count")) != recoveries_before:
		return _fail("F20 unexpected entombment recovery interrupted bounty travel")
	if not _player.is_on_floor() or arbiter.call("winning_provider") != prompt:
		var bounty_owner := INPUT_OWNER.current(tree)
		var bounty_winner: Node = arbiter.call("winning_provider") as Node
		print("F20 BOUNTY provider trace player=", _player.global_position, " floor=", _player.is_on_floor(),
			" prompt=", prompt.global_position, " prompt_radius=", prompt.get("radius"),
			" expected=", prompt.get_path(), " target_offer=", prompt.call("interaction_offer", _player.global_position),
			" target_los=", prompt.call("_has_line_of_sight", _player.global_position),
			" winner=", arbiter.call("winning_provider"), " winning_offer=", arbiter.call("winner"),
			" winner_path=", bounty_winner.get_path() if bounty_winner != null else "none",
			" arbiter_enabled=", arbiter.call("enabled"), " fight_owns=", arbiter.call("_fight_owns_the_world"),
			" owner=", bounty_owner.get_path() if bounty_owner != null else "none")
		return _fail("F20 bounty travel did not reach its grounded exact provider")
	var offer: Dictionary = arbiter.call("winner")
	if offer.get("actionable") != true: return _fail("F20 actual bounty provider refused its action")
	_activated = null
	arbiter.connect("activated", _activation)
	await tap("interact")
	if is_instance_valid(arbiter) and arbiter.is_connected("activated", _activation): arbiter.disconnect("activated", _activation)
	return _activated == prompt or _fail("F20 bounty input activated another provider")

func tap(action: String) -> void:
	# Presentation proofs can use ordinary camera input after the original
	# capsule navigation has reached its exact provider, before pressing X.
	if action == "interact" and before_interact.is_valid():
		var preparation := before_interact
		before_interact = Callable()
		var prepared: Variant = await preparation.call()
		if prepared is bool and not prepared:
			_fail("F20 ordinary camera preparation failed before interaction")
			return
	var pad: InputEventJoypadButton = null
	if _lesson_controller_input and action in ["menu_cancel", "menu_confirm"]:
		for binding: InputEvent in InputMap.action_get_events(action):
			if binding is InputEventJoypadButton:
				pad = binding.duplicate() as InputEventJoypadButton
				break
		if pad == null:
			_fail("F46 lesson action has no actual joypad button binding: " + action)
			return
	for pressed: bool in [true, false]:
		if trace_input: _trace_clock(action, pressed, "before input")
		if pad != null:
			var event := pad.duplicate() as InputEventJoypadButton
			event.device = 0
			event.pressed = pressed
			Input.parse_input_event(event)
			print("F46 LESSON INPUT " + JSON.stringify({"action": action, "button_index": event.button_index,
				"device": event.device, "pressed": pressed}))
		else:
			var event := InputEventAction.new()
			event.action = action
			event.pressed = pressed
			event.strength = 1.0 if pressed else 0.0
			Input.parse_input_event(event)
		for frame in 2:
			if trace_input: _trace_clock(action, pressed, "before physics %d" % frame)
			await tree.physics_frame
			if trace_input: _trace_clock(action, pressed, "after physics %d" % frame)
			await tree.process_frame
			if trace_input: _trace_clock(action, pressed, "after process %d" % frame)

## Read-only snapshots, not a forced UI refresh or a full F46 acceptance result.
## Offload can expose Control state but cannot supply rendered readability proof.
func observe_next_goal(gate: String, phase: String) -> Dictionary:
	var scene := tree.current_scene
	var hud := scene.get_node_or_null(^"PlaygroundHUD") if scene != null else null
	var label := hud.get("_objective_text_label") as Label if hud != null else null
	var block := hud.get("_objective_block") as Control if hud != null else null
	var hint := hud.get("_objective_hint_label") as Label if hud != null else null
	var log: RefCounted = game.get("quest_log")
	var progression: RefCounted = game.get("progression")
	var tracked := str(log.call("tracked_text", progression)) if log != null and progression != null else ""
	var text := str(game.get("objective_text"))
	var owner := INPUT_OWNER.current(tree)
	var service := game.get_node_or_null(^"OnboardingLessons")
	var panel: Node = service.get("_panel") if service != null else null
	var lesson := {}
	if is_instance_valid(panel):
		var row: Dictionary = panel.get("_row")
		var id := str(row.get("id", ""))
		var lesson_text := panel.get("_text") as Label
		lesson = {"id": id, "open": panel.call("is_open"), "owns_input": panel.call("owns_input"),
			"line": panel.get("_line"), "text": lesson_text.text if is_instance_valid(lesson_text) else "",
			"visible": is_instance_valid(lesson_text) and lesson_text.is_visible_in_tree(),
			"personal_ack": not id.is_empty() and game.local.flags.call("has", "opening:lesson:" + id) == true}
	var visible := label != null and block != null and label.is_visible_in_tree() and block.is_visible_in_tree()
	var observation := {"kind": "next_goal_snapshot", "gate": gate, "phase": phase,
		"realm": str(game.get("current_realm")), "scene": str(scene.get_path()) if scene != null else "",
		"character_id": str(game.local.character_id), "party_uids": _uids(),
		"process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(),
		"input_owner": str(owner.get_path()) if owner != null else "", "paused": tree.paused,
		"tracked_id": str(log.call("tracked_id", progression)) if log != null and progression != null else "",
		"quest_text": tracked, "game_text": text, "hud_text": label.text if label != null else "",
		"hud_visible": visible, "objective_is_posed": game.get("_objective_is_posed"),
		"visible_text_matches": visible and not text.strip_edges().is_empty() and label.text == text and text == tracked,
		"game_hint": str(game.get("objective_hint")),
		"hint_text": hint.text if hint != null else "", "hint_visible": hint != null and hint.is_visible_in_tree(),
		"lesson": lesson, "render_loop_enabled": RenderingServer.render_loop_enabled,
		"scope": "Partial UI/state observation only; no readability, comprehension, replay or full F46 claim"}
	print("F46 NEXT GOAL OBSERVATION " + JSON.stringify(observation))
	return observation

func _trace_clock(action: String, pressed: bool, phase: String) -> void:
	var input_owner := INPUT_OWNER.current(tree)
	var dialogue: Node = tree.current_scene.get_node_or_null("DialoguePanel") if tree.current_scene != null else null
	print("F20 INPUT CLOCK ticks_ms=", Time.get_ticks_msec(), " process=", Engine.get_process_frames(),
		" physics=", Engine.get_physics_frames(), " action=", action, " pressed=", pressed, " phase=", phase,
		" held=", Input.is_action_pressed(action), " paused=", tree.paused,
		" panel_open=", dialogue.call("is_open") if dialogue != null else false,
		" owner=", input_owner.get_path() if input_owner != null else "none",
		" owner_script=", input_owner.get_script().resource_path if input_owner != null and input_owner.get_script() != null else "none")
