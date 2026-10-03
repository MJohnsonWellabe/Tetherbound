extends "res://tests/helpers/f49_portal_travel.gd"

## Preserve the existing real navigation/provider/authority checks. Hold a
## normal button edge through both clocks: world X is read on physics ticks,
## while inventory/credits also read idle frames.
const LESSON_PANEL := preload("res://scripts/onboarding/lesson_panel.gd")
var _lesson_busy := false
var before_interact: Callable
var trace_input := false

func activate(prompt: Node3D) -> bool:
	var failures_before := failures.size()
	# A lesson may be due on this character's first walk past its teacher.
	# Read/continue its real card; retain the original navigation budget and
	# exact grounded/provider checks after ordinary world input returns.
	await _continue_navigation_lesson()
	tree.process_frame.connect(_continue_navigation_lesson)
	var passed := await _activate_world(prompt)
	tree.process_frame.disconnect(_continue_navigation_lesson)
	while _lesson_busy: await tree.process_frame
	return passed and failures.size() == failures_before

func _continue_navigation_lesson() -> void:
	if _lesson_busy: return
	var owner := INPUT_OWNER.current(tree)
	if owner == null or owner.get_script() != LESSON_PANEL or not owner.call("is_open"): return
	_lesson_busy = true
	var row: Dictionary = owner.get("_row")
	var id := str(row.get("id", ""))
	var deadline := Time.get_ticks_msec() + 30000
	print("F20 LESSON actual ordinary Continue id=", id)
	while is_instance_valid(owner) and INPUT_OWNER.current(tree) == owner \
		and owner.call("is_open") and Time.get_ticks_msec() < deadline:
		print("F20 LESSON rendered ", owner.get("_text").text)
		await tap("menu_confirm")
	while Time.get_ticks_msec() < deadline and game.local.flags.call("has", "opening:lesson:" + id) != true:
		await tree.process_frame
	if id.is_empty() or not is_instance_valid(owner) or owner.call("is_open") \
		or game.local.flags.call("has", "opening:lesson:" + id) != true:
		_fail("F20 ordinary lesson Continue did not complete this character's actual " + id)
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
		await preparation.call()
	for pressed: bool in [true, false]:
		if trace_input: _trace_clock(action, pressed, "before input")
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

func _trace_clock(action: String, pressed: bool, phase: String) -> void:
	var input_owner := INPUT_OWNER.current(tree)
	var dialogue: Node = tree.current_scene.get_node_or_null("DialoguePanel") if tree.current_scene != null else null
	print("F20 INPUT CLOCK ticks_ms=", Time.get_ticks_msec(), " process=", Engine.get_process_frames(),
		" physics=", Engine.get_physics_frames(), " action=", action, " pressed=", pressed, " phase=", phase,
		" held=", Input.is_action_pressed(action), " paused=", tree.paused,
		" panel_open=", dialogue.call("is_open") if dialogue != null else false,
		" owner=", input_owner.get_path() if input_owner != null else "none",
		" owner_script=", input_owner.get_script().resource_path if input_owner != null and input_owner.get_script() != null else "none")
