extends RefCounted

## Earned live First Shore arrival only. No chapter fixture or optional suffix.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LESSON_MS := 600000
var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var navigator: RefCounted
var activated: Object
var swim_metres := 0.0
var failures: Array[String] = []
var initial_party_ids: Array[int] = []
var _tree: SceneTree
var _arbiter: Node
var _deadline_ms := 0
var _completed := false

func run(tree: SceneTree, actual_world: Node3D, actual_game: Node) -> Dictionary:
	_tree = tree
	world = actual_world
	game = actual_game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "water" or not str(game.get("pending_realm_entry")).is_empty() \
			or not world.has_method("shell_build_complete") or not world.shell_build_complete():
		_fail("Earned Water opening requires the retained ready natural Water arrival")
		return result()
	if not game.world.flags.has("realm_gate_water_unlocked") or game.world.flags.has("realm_key_water") \
			or not game.world.flags.has("stormwood:waterward_revealed") or game.get("pending_catch") != null:
		_fail("Earned Water opening requires the consumed-key physical Waterward handoff")
		return result()
	player = world.get_node_or_null("Player")
	camera = world.get_node_or_null("CameraRig")
	_arbiter = world.get_node_or_null("InteractionArbiter")
	initial_party_ids = _party_ids()
	if player == null or camera == null or _arbiter == null or not retained_five(initial_party_ids, initial_party_ids) \
			or INPUT_OWNER.current(tree) != null:
		_fail("Earned Water opening requires live controls and five distinct retained creatures")
		return result()
	navigator = NAV.new(tree, player, camera, _stick)
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	await tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await tree.process_frame
	_deadline_ms = Time.get_ticks_msec() + LESSON_MS
	await _run_live()
	_stick(0, 0)
	if is_instance_valid(_arbiter) and _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.disconnect(_on_activated)
	await tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	return result()

func _run_live() -> void:
	await _frames(30)
	var arrival: Vector3 = world.entry_anchor("from_stormwood")
	if not arrival.is_finite() or not player.is_on_floor() or player.global_position.distance_to(arrival) > 3.0:
		_fail("Production arrival did not settle at First Shore: player=%s expected=%s" % [player.global_position, arrival])
		return
	print("WATER EARNED OPENING ARRIVED: actual First Shore pose=%s" % [
		player.global_position])
	if game.world.flags.has("water_swim_lesson_complete") or game.local.flags.has("water_swim_lesson_briefed"):
		_fail("Earned opening entry already contains lesson progress")
		return
	var pell := world.find_child("water_pell", true, false) as Node3D
	if pell == null:
		_fail("Pell's production body is absent")
		return
	var prompt := pell.call("prompt_node") as Node3D
	var arbiter: Node = world.get_node("InteractionArbiter")
	arbiter.activated.connect(_on_activated)
	var greeted := false
	for stance in 8:
		var angle := TAU * float(stance) / 8.0
		var point := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.3
		point.y = world.ground_height_at(point.x, point.z) + 0.1
		if not await _walk(point, "Pell grounded interaction stance"):
			return
		await _frames(8)
		if arbiter.call("winning_provider") != prompt:
			continue
		activated = null
		await _tap("interact")
		if activated == prompt:
			greeted = true
			break
	if not greeted:
		_fail("Pell never received the actual arbiter interaction: %s" % str(arbiter.call("winner")))
		return
	var panel: Node = world.get_node("DialoguePanel")
	if not panel.is_open():
		_fail("Pell interaction did not open dialogue")
		return
	for line in 30:
		if not panel.is_open():
			break
		await _tap("interact")
	if panel.is_open() or not game.local.flags.has("water_swim_lesson_briefed"):
		_fail("Controller dialogue did not earn Pell's briefing")
		return
	print("WATER OPENING BRIEFED through Pell's production dialogue")
	var spec: Dictionary = world.config.swim_lesson
	if not await _walk(_anchor(str(spec.start_anchor)), "west lesson landing"):
		return
	var first := _v(spec.surface_polyline[0])
	var last := _v(spec.surface_polyline[-1])
	if not await _swim_to(first):
		return
	swim_metres = 0.0
	if not await _swim_to(last):
		return
	if not await _swim_to(_anchor(str(spec.end_anchor))):
		return
	await _frames(20)
	if not game.world.flags.has("water_swim_lesson_complete") or swim_metres < 50.0:
		_fail("Ordinary crossing did not earn the lesson flag; observed swimming=%.3fm" % swim_metres)
		return
	if not player.is_on_floor() or player.swim_controller.is_swimming():
		_fail("Lesson completion did not end at dry grounded landing")
		return
	print("WATER EARNED OPENING: Pell and physical lesson complete; swimming=%.3fm" % swim_metres)
	if Time.get_ticks_msec() >= _deadline_ms or not retained_five(initial_party_ids, _party_ids()) or _tree.current_scene != world:
		_fail("Earned lesson exceeded its original ten-minute bound or changed the five/world")
		return
	_completed = true

func _walk(point: Vector3, label: String) -> bool:
	if not point.is_finite():
		return _fail(label + " target is not finite")
	var distance := player.global_position.distance_to(point)
	var remaining_frames := floori(float(_deadline_ms - Time.get_ticks_msec()) * 0.06)
	if remaining_frames <= 0:
		return _fail("Original ten-minute lesson ceiling expired")
	var budget := mini(maxi(1200, int(distance * 65)), remaining_frames)
	# Same navigator policy and zero-confined-reset acceptance as the wrapper,
	# stepped here so its independent ten-minute watchdog remains enforceable
	# while input is held or movement is blocked inside a leg.
	navigator.reset()
	var walked := 0
	var held := 0
	var anchor := player.global_position
	var anchor_age := 0
	var arrived := false
	while walked < budget and Time.get_ticks_msec() < _deadline_ms:
		var offset := point - player.global_position
		offset.y = 0
		if offset.length() <= 1.0:
			arrived = true
			break
		if not navigator.can_walk():
			held += 1
			if held > NAV.HELD_FRAMES:
				break
			_stick(0, 0)
			navigator.reset()
			anchor = player.global_position
			anchor_age = 0
			await _tree.physics_frame
			continue
		walked += 1
		if player.global_position.distance_to(anchor) > NAV.CONFINED_RADIUS_M:
			anchor = player.global_position
			anchor_age = 0
		else:
			anchor_age += 1
			if anchor_age >= NAV.CONFINED_FRAMES:
				return _fail(label + " requires a confined reset; original opening accepts zero")
		await navigator.step(point)
	_stick(0, 0)
	if not arrived or Time.get_ticks_msec() >= _deadline_ms:
		return _fail("%s failed: player=%s target=%s" % [label, player.global_position, point])
	return true

func _swim_to(point: Vector3) -> bool:
	var previous := player.global_position
	for frame in 2400:
		if Time.get_ticks_msec() >= _deadline_ms:
			return _fail("Original ten-minute lesson ceiling expired")
		var offset := point - player.global_position
		offset.y = 0
		if offset.length() < 0.5:
			_stick(0, 0)
			return true
		# Preserve the original world-space swim direction using actual input;
		# the wrapper's camera-yaw assignment is not part of this earned helper.
		var local := swim_axis(camera.call("planar_basis"), offset)
		_stick(local.x, local.y)
		await _tree.physics_frame
		if player.swim_controller.is_swimming():
			swim_metres += Vector2(player.global_position.x - previous.x, player.global_position.z - previous.z).length()
		previous = player.global_position
		if player.vitals.health <= 0:
			return _fail("Player died during ordinary lesson approach/crossing")
	return _fail("Lesson movement stalled: player=%s target=%s" % [player.global_position, point])

static func swim_axis(basis: Basis, offset: Vector3) -> Vector2:
	var horizontal := Vector3(offset.x, 0, offset.z).normalized()
	var local := basis.inverse() * horizontal
	return Vector2(local.x, local.z)

func _anchor(id: String) -> Vector3:
	for row: Dictionary in world.config.anchors:
		if str(row.id) == id:
			var point := _v(row.safe_position)
			point.y = world.ground_height_at(point.x, point.z) + 0.15
			return point
	return Vector3.INF

func _v(row: Array) -> Vector3:
	return Vector3(float(row[0]), float(row[1]), float(row[2]))

func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)

func _tap(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(8)

func _frames(count: int) -> void:
	for frame in count:
		await _tree.physics_frame

func _on_activated(provider: Object) -> void:
	activated = provider

func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in game.party.members():
		ids.append(member.get_instance_id())
	return ids

static func retained_five(before: Array[int], after: Array[int]) -> bool:
	if before.size() != 5 or before != after:
		return false
	var seen: Dictionary = {}
	for id in before:
		if id == 0 or seen.has(id):
			return false
		seen[id] = true
	return true

func _fail(reason: String) -> bool:
	_stick(0, 0)
	failures.append(reason)
	return false

func result() -> Dictionary:
	return {"ok": _completed and failures.is_empty(), "passed": _completed and failures.is_empty(),
		"completed_lesson": _completed, "failures": failures.duplicate(), "tree": _tree,
		"world": world, "game": game, "player": player, "camera": camera,
		"swim_metres": swim_metres, "initial_party_ids": initial_party_ids.duplicate(),
		"endpoint": "earned Pell and physical swim lesson, before Reedhaven"}
