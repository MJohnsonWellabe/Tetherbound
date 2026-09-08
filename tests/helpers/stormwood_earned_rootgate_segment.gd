extends "res://tests/helpers/stormwood_crown_build_segment.gd"

## Earned continuation only: paid constructed arch -> Crown guardian -> Wen ->
## heartstone. No entry fixture, scene replacement, grants or pose writes.
const CROWN_REACHED := "stormwood:crown_reached"
const GUARDIAN_CLEAR := "stormwood:named:crown_guardian:cleared"
const TRUTH := "stormwood:engine_truth_learned"
const ROOTGATE := "stormwood:rootgate_released"
const ACT_II := "stormwood:act_ii_complete"
const COMBAT_REACH := preload("res://scripts/combat/combat_manager.gd")
var _complete := false
var _party_before: Array[int] = []

static func paid_crown_record(records: Array) -> Dictionary:
	for record: Dictionary in records:
		if str(record.get("id", "")) == "stormglass_arch" \
				and str(record.get("realm", "")) == "stormwood" \
				and bool(record.get("paid", false)) and not bool(record.get("removed", false)) \
				and str(record.get("arch_twin", "")) == "e_crown" \
				and str(record.get("arch_footing", "")) == "still_grove" \
				and not str(record.get("uid", "")).is_empty():
			return record
	return {}

func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "stormwood":
		_fail("Rootgate continuation requires the retained live Stormwood scene")
		return result()
	_player = world.get_node_or_null("Player")
	_camera = world.get_node_or_null("CameraRig")
	_manager = world.get_node_or_null("CombatManager")
	_director = world.get_node_or_null("EncounterDirector")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	var flags: RefCounted = game.get("progression")
	var record := paid_crown_record(game.get("placed_buildings"))
	if _player == null or _camera == null or _manager == null or _director == null \
			or _arbiter == null or record.is_empty() or not flags.call("has", BUILT_FLAG) \
			or not flags.call("has", RECIPE_FLAG) or flags.call("has", CROWN_REACHED) \
			or flags.call("has", ROOTGATE):
		_fail("Rootgate entry needs the earned recipe and paid Crown twin, before Crown arrival")
		return result()
	_party_before = _roster_ids()
	if _party_before.size() != 5:
		_fail("Rootgate continuation requires the retained five-member party")
		return result()
	var arches := world.get_node_or_null("StormglassArches")
	var rows: Dictionary = arches.get("_arches") if arches != null else {}
	var row: Dictionary = rows.get(str(record.uid), {})
	var arch: Node3D = row.get("node")
	if not is_instance_valid(arch) or _player.global_position.distance_to(arch.global_position) > 16.0:
		_fail("paid Crown runtime twin must be live beside the player after construction")
		return result()
	_navigator = NAVIGATOR.new(tree, _player, _camera, _drive_stick)
	_manager.exited.connect(_on_combat_exited)
	await _continue_from_arch(arch)
	_manager.exited.disconnect(_on_combat_exited)
	return result()

func _continue_from_arch(arch: Node3D) -> void:
	if not str(_game.get("pending_build")).is_empty():
		await _tap(&"build_cancel")
		if not str(_game.get("pending_build")).is_empty():
			_fail("ordinary Build Cancel did not return input after paid construction")
			return
	var outside := arch.to_global(Vector3(0, 0, -5))
	if not await _walk_xz(Vector2(outside.x, outside.z), "outside paid Crown passage"):
		return
	var beyond := arch.to_global(Vector3(0, 0, 3.5))
	_navigator.reset()
	for _frame in 1800:
		if _has(CROWN_REACHED):
			break
		if _manager.is_fighting():
			if not await _fight_current("paid Crown passage"):
				return
		elif _navigator.can_walk():
			await _navigator.step(beyond)
		else:
			await _tree.physics_frame
	_drive_stick(0, 0)
	if not _has(CROWN_REACHED):
		_fail("walking through paid Crown passage did not earn Crown arrival")
		return
	_note("TRAVELLED the actual paid Crown arch; Crown arrival earned")
	for point in [Vector2(590, 2540), Vector2(805, 2545), Vector2(700, 2700)]:
		if not await _walk_xz(point, "Crown ring to guardian"):
			return
	if not await _clear_guardian():
		return
	var wen := _world.get_node_or_null("StormwoodPeople/Archivist Wen") as Node3D
	var prompt := wen.get_node_or_null("Interactable") as Node3D if wen != null else null
	if not await _activate_exact(wen, prompt, Vector2(700, 2697.5), "Wen's Crown truth"):
		return
	var panel := _world.get_node("DialoguePanel")
	for _frame in 180:
		if panel.call("is_open"):
			break
		await _tree.physics_frame
	if not panel.call("is_open"):
		_fail("Wen's exact interaction did not open dialogue")
		return
	for _line in 64:
		if not panel.call("is_open"):
			break
		await _tap(&"interact")
	if panel.call("is_open") or not await _wait_flag(TRUTH, 180):
		_fail("ordinary Wen dialogue did not earn the engine truth")
		return
	var heart := _world.get_node("CrownHeartstone") as Node3D
	if not await _activate_exact(heart, heart.get_node("HeartstoneInteractable"),
			Vector2(700, 2708), "Crown heartstone"):
		return
	if not await _wait_flag(ROOTGATE, 180) or not _has(ACT_II):
		_fail("heartstone did not earn Rootgate release and Act II completion")
		return
	await _tree.physics_frame
	var rootgate := _world.get_node("Rootgate") as Node3D
	var collision := rootgate.get_node("CollisionShape3D") as CollisionShape3D
	if rootgate.visible or not collision.disabled or _roster_ids() != _party_before \
			or _tree.current_scene != _world:
		_fail("Rootgate receipt did not open its real barrier with the retained party/world")
		return
	_complete = true
	_note("EARNED guardian clearance, Wen truth and physically open Rootgate / Act II")

func _clear_guardian() -> bool:
	for _attempt in 4:
		if _manager.is_fighting() and not await _fight_current("Crown guardian arrival"):
			return false
		if _has(GUARDIAN_CLEAR):
			return true
		if not await _ensure_usable_ally("Crown guardian"):
			return false
		var body := _named_wild("crown_guardian")
		if body == null:
			return _fail("Crown guardian absent without its earned clear receipt")
		var collision := _player.get_node_or_null("Collision") as CollisionShape3D
		if collision == null or not collision.shape is CapsuleShape3D:
			return _fail("guardian approach requires the actual player capsule radius")
		var at := guardian_stance(body.global_position, _player.global_position,
			float(body.call("body_radius")), (collision.shape as CapsuleShape3D).radius)
		if not await _walk_xz(at, "actual Crown guardian", 1.2):
			return false
		for _frame in 180:
			if _has(GUARDIAN_CLEAR):
				return true
			if _manager.is_fighting():
				break
			if _named_engage_ready(body) and await _tap_named_engage(body):
				if _manager.is_fighting() and _manager.enemy_body() != body:
					return _fail("Crown guardian input admitted a different wild body")
				break
			await _tree.physics_frame
		if _manager.is_fighting() and not await _fight_current("Crown guardian"):
			return false
		if await _wait_flag(GUARDIAN_CLEAR, 180):
			return true
	return _fail("ordinary Crown guardian approaches did not earn its clear receipt")

static func guardian_stance(guardian: Vector3, player: Vector3,
		guardian_radius: float, player_radius: float) -> Vector2:
	var outward := Vector2(player.x - guardian.x, player.z - guardian.z)
	if outward.is_zero_approx():
		outward = Vector2.DOWN
	var reach := COMBAT_REACH.floor_reach_for_bodies({"range": 0.0}, guardian_radius, player_radius)
	return Vector2(guardian.x, guardian.z) + outward.normalized() * float(reach.range)

func _tap(action: StringName) -> void:
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	await super._tap(action)
	await _tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before

func _has(flag: String) -> bool:
	return bool(_game.get("progression").call("has", flag))

func _roster_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in _game.get("party").call("members"):
		ids.append(member.get_instance_id())
	return ids

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "endpoint": "earned Rootgate / Act II"}
