extends RefCounted

## Controller-only Water prefix segment. The caller owns the already-running
## production world and must have earned the swim lesson and carried an axe in
## from the preceding campaign. This helper never resets the game, moves an
## actor directly, or writes inventory/progression state.
const NAV := preload("res://tests/helpers/stick_navigator.gd")
const PICKUP_DATA := "res://data/config/water_pickups.json"
const REPAIR_FLAG := "water_dock_reedhaven_repaired"
const LESSON_FLAG := "water_swim_lesson_complete"
const STOPS: Array[String] = [
	"water:reedhaven:harvest:019", # +3 reed beside the arrival-side spine
	"water:reedhaven:harvest:017", # +3 driftwood west of the central spine
	"water:reedhaven:harvest:003", # +3 driftwood beside the departure leg
	"water:reedhaven:harvest:001", # +3 reed beside the departure landing
]

var failures: Array[String] = []
var transcript: Array[String] = []
var _tree: SceneTree
var _world: Node3D
var _player: CharacterBody3D
var _camera: Node3D
var _game: Node
var _arbiter: Node
var _pickups: Node
var _navigator: RefCounted
var _activated: Object
var _completed := false


func setup(tree: SceneTree, world: Node3D, player: CharacterBody3D,
		camera: Node3D) -> void:
	_tree = tree
	_world = world
	_player = player
	_camera = camera
	_game = tree.root.get_node_or_null("Game")
	_arbiter = world.get_node_or_null("InteractionArbiter") if world != null else null
	_pickups = world.get_node_or_null("WaterPickups") if world != null else null
	_navigator = NAV.new(tree, player, camera, _stick) \
		if tree != null and player != null and camera != null else null
	if _arbiter != null and not _arbiter.activated.is_connected(_on_activated):
		_arbiter.activated.connect(_on_activated)


func run() -> bool:
	if not _preconditions_hold():
		return false
	var reed_before := _count("reed_fiber")
	var drift_before := _count("driftwood")
	var lesson_east := _anchor("water_first_shore_lesson_east")
	if _player.global_position.distance_to(lesson_east) > 8.0 \
			or not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("segment must begin dry at the earned lesson-east landing; player=%s expected=%s" % [
			str(_player.global_position), str(lesson_east)])
	if not await _walk_to(_anchor("first_shore_to_reedhaven_departure"),
			"First Shore departure", 1.3):
		return false
	if not await _cross_human_route("first_shore_to_reedhaven_sheltered"):
		return false
	if not _player.is_on_floor() or _player.swim_controller.is_swimming():
		return _fail("Reedhaven crossing did not finish dry and grounded")
	transcript.append("ordinary human crossing reached Reedhaven")

	# These ordered points keep each named disposable node resident before its
	# interaction. They are authored trail points, not actor-position writes.
	var spine := _land_route("reedhaven_exploration_spine")
	if spine.size() < 7:
		return _fail("Reedhaven exploration spine is missing its seven authored points")
	if not await _walk_to(spine[1], "Reedhaven arrival approach") \
			or not await _walk_to(spine[2], "Reedhaven resource approach"):
		return false
	if not await _gather(STOPS[0], "reed_fiber", false):
		return false
	if not await _walk_to(spine[3], "Reedhaven central spine"):
		return false
	if not await _gather(STOPS[1], "driftwood", true):
		return false
	if not await _gather(STOPS[2], "driftwood", true):
		return false
	if not await _walk_to(spine[4], "Reedhaven departure approach") \
			or not await _walk_to(spine[5], "Reedhaven departure landing"):
		return false
	if not await _gather(STOPS[3], "reed_fiber", false):
		return false

	var reed_gained := _count("reed_fiber") - reed_before
	var drift_gained := _count("driftwood") - drift_before
	if reed_gained != 6 or drift_gained != 6:
		return _fail("named production nodes paid unexpected supplies: reed=%d drift=%d" % [
			reed_gained, drift_gained])
	var before_repair := {"reed": _count("reed_fiber"), "drift": _count("driftwood")}
	var equipment := _world.get_node_or_null("WaterDocks/reedhaven_repair") as Node3D
	var repair_prompt := _provider_child(equipment)
	if repair_prompt == null:
		return _fail("production Reedhaven dock repair has no interaction provider")
	if not await _activate(repair_prompt, "Reedhaven dock repair"):
		return false
	if not await _wait_world_flag(REPAIR_FLAG, 180):
		return _fail("paid production repair did not publish " + REPAIR_FLAG)
	if _count("reed_fiber") != int(before_repair.reed) - 6 \
			or _count("driftwood") != int(before_repair.drift) - 4:
		return _fail("repair charged the wrong material delta: before=%s after={reed:%d,drift:%d}" % [
			str(before_repair), _count("reed_fiber"), _count("driftwood")])
	transcript.append("four named nodes yielded6 reed/6 drift; repair spent6 reed/4 drift")
	_completed = true
	return true


func result() -> Dictionary:
	return {"ok": verdict(_completed, failures), "failures": failures.duplicate(),
		"transcript": transcript.duplicate()}


static func verdict(completed: bool, errors: Array) -> bool:
	return completed and errors.is_empty()


func _preconditions_hold() -> bool:
	if _tree == null or _world == null or _player == null or _camera == null \
			or _game == null or _arbiter == null or _pickups == null or _navigator == null:
		return _fail("Reedhaven segment is missing a production tree/world/player/camera service")
	if str(_game.current_realm) != "water" or not _world.shell_build_complete():
		return _fail("Reedhaven segment requires the ready production Water realm")
	if not _game.world.flags.has(LESSON_FLAG):
		return _fail("Reedhaven segment requires the physically earned swim lesson")
	if _game.world.flags.has(REPAIR_FLAG):
		return _fail("Reedhaven segment requires an unrepaired departure dock")
	if int(_game.inventory.find_slot("axe")) < 0:
		return _fail("Reedhaven segment requires the campaign-earned axe")
	if _hotbar_action("axe") == &"":
		return _fail("campaign axe is not assigned to a controller hotbar action")
	for id: String in STOPS:
		if _harvest_row(id).is_empty():
			return _fail("named Reedhaven harvest row is absent: " + id)
	return true


func _cross_human_route(id: String) -> bool:
	var route := _water_route(id)
	if route.is_empty() or str(route.get("intended_traversal", "")) != "human_level_0" \
			or str(route.get("required_departure_flag", "")) != LESSON_FLAG:
		return _fail("authored sheltered human crossing contract is missing: " + id)
	for raw: Array in route.polyline:
		if not await _swim_to(_vector(raw), id):
			return false
	return await _swim_to(_anchor(str(route.to_anchor)), id + " arrival")


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


func _gather(id: String, item: String, needs_axe: bool) -> bool:
	var row := _harvest_row(id)
	var raw: Array = row.position
	var authored := Vector3(float(raw[0]), 0.0, float(raw[2]))
	authored.y = _world.ground_height_at(authored.x, authored.z) + 0.1
	# Enter residency; the physical node may block its own exact centre, so the
	# provider stance below—not a centre-distance assertion—owns reachability.
	if not await _walk_to(authored, id + " residency", 4.0):
		return false
	for frame in 45:
		if _pickups.node_for(id) != null:
			break
		await _tree.physics_frame
	var node := _pickups.node_for(id) as Node3D
	if node == null or str(node.call("resource_item")) != item \
			or int(node.call("resource_amount")) != int(row.get("yield", 0)):
		return _fail("named production harvest node did not instantiate exactly: " + id)
	if needs_axe:
		if not await _equip_axe():
			return false
	elif not await _stow_tool():
		return false
	var before := _count(item)
	var prompt := node.get_node_or_null("Interactable") as Node3D
	if prompt == null:
		return _fail("named production harvest node has no Interactable: " + id)
	if not await _activate(prompt, id):
		return false
	for frame in 180:
		if _count(item) > before and _game.progression.has("harvest_node:order:" + id):
			break
		await _tree.physics_frame
	var gained := _count(item) - before
	if gained != int(row.get("yield", 0)) \
			or not _game.progression.has("harvest_node:order:" + id):
		return _fail("%s did not pay its exact production yield/receipt: gained=%d" % [id, gained])
	transcript.append("%s +%d %s through controller interaction" % [id, gained, item])
	return true


func _activate(prompt: Node3D, label: String) -> bool:
	if prompt == null or not is_instance_valid(prompt):
		return _fail(label + " has no live production provider")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var stance := prompt.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.2
		stance.y = _world.ground_height_at(stance.x, stance.z) + 0.1
		if not await _walk_to(stance, label + " interaction stance", 1.0):
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


func _equip_axe() -> bool:
	var hold: Node = _player.get("tool_hold")
	for frame in 120:
		if hold == null or not hold.call("is_swinging"):
			break
		await _tree.physics_frame
	if str(_game.equipped_tool) != "axe":
		await _tap(_hotbar_action("axe"))
	for frame in 45:
		if str(_game.equipped_tool) == "axe" and hold != null \
				and hold.call("prop_node") != null:
			return true
		await _tree.physics_frame
	return _fail("controller hotbar did not visibly equip the campaign axe")


func _stow_tool() -> bool:
	if str(_game.equipped_tool).is_empty():
		return true
	var action := _hotbar_action(str(_game.equipped_tool))
	if action == &"":
		return _fail("held tool has no controller hotbar action: " + str(_game.equipped_tool))
	await _tap(action)
	for frame in 45:
		if str(_game.equipped_tool).is_empty():
			return true
		await _tree.physics_frame
	return _fail("controller hotbar did not stow the held tool")


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


func _hotbar_action(item: String) -> StringName:
	var hotbar: Array = _game.hotbar
	var index := hotbar.find(item)
	return StringName("hotbar_%d" % (index + 1)) if index >= 0 and index < 5 else &""


func _harvest_row(id: String) -> Dictionary:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(PICKUP_DATA))
	if not source is Dictionary:
		return {}
	for row: Dictionary in source.get("harvest", []):
		if str(row.get("id", "")) == id:
			return row
	return {}


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


func _count(item: String) -> int:
	return int(_game.inventory.count(item))


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
	_stop_stick()
	failures.append(message)
	transcript.append("FAIL: " + message)
	return false
