extends SceneTree

const SAVE := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

class TraceMaterials:
	extends "res://tests/helpers/meadows_earned_material_segment.gd"
	var active_purpose := "material_walk"
	var leg := 0

	func _walk_target(target: Vector3, budget: int) -> bool:
		active_purpose = "material_return"
		var result := await super._walk_target(target, budget)
		active_purpose = "material_walk"
		return result

	func _walk_to(target: Vector3, close_enough: float, budget: int) -> bool:
		leg += 1
		var this_leg := leg
		print("RETAINED TRACE WALK START phase=materials leg=", this_leg,
			" purpose=", active_purpose, " target=", target,
			" tolerance=", close_enough, " budget=", budget,
			" frame=", Engine.get_physics_frames(), " player=", _player.global_position)
		_observe.call_deferred(this_leg, target, close_enough)
		var result := await super._walk_to(target, close_enough, budget)
		leg += 1
		print("RETAINED TRACE WALK END phase=materials leg=", this_leg,
			" arrived=", result, " frame=", Engine.get_physics_frames(),
			" player=", _player.global_position, " distance=", _flat(target))
		return result

	func _observe(this_leg: int, target: Vector3, tolerance: float) -> void:
		var records := 0
		while leg == this_leg and records < 500:
			for _frame in 10:
				await _tree.physics_frame
				if leg != this_leg:
					return
			var distance := _flat(target)
			if distance > 10.0:
				continue
			records += 1
			_print_observation("materials", this_leg, active_purpose, target, tolerance, distance, records)

	func _flat(target: Vector3) -> float:
		return Vector2(target.x - _player.global_position.x, target.z - _player.global_position.z).length()

	func _print_observation(phase: String, this_leg: int, purpose: String, target: Vector3,
			tolerance: float, distance: float, record: int) -> void:
		var owner := INPUT_OWNER.current(_tree)
		var contacts: Array[String] = []
		for index in _player.get_slide_collision_count():
			var collider := _player.get_slide_collision(index).get_collider()
			contacts.append(str(collider.get_path()) if collider is Node else str(collider))
		print("RETAINED TRACE NEAR phase=", phase, " leg=", this_leg,
			" purpose=", purpose, " record=", record, " frame=", Engine.get_physics_frames(),
			" target=", target, " tolerance=", tolerance, " player=", _player.global_position,
			" distance=", distance, " input_owner=", str(owner.get_path()) if owner != null else "none",
			" detour=", str(_nav.get("_detour")) if _nav != null else "none",
			" detour_left=", int(_nav.get("_detour_left")) if _nav != null else -1,
			" detour_age=", int(_nav.get("_detour_age")) if _nav != null else -1,
			" contacts=", JSON.stringify(contacts))

class TraceCamp:
	extends "res://tests/helpers/meadows_earned_camp_segment.gd"
	var leg := 0

	func _walk_to(target: Vector3, purpose: String, close_enough: float = MOVE_EPSILON,
			direct: bool = false) -> bool:
		leg += 1
		var this_leg := leg
		print("RETAINED TRACE WALK START phase=camp leg=", this_leg, " purpose=", purpose,
			" target=", target, " tolerance=", close_enough,
			" frame=", Engine.get_physics_frames(), " player=", _player.global_position)
		_observe.call_deferred(this_leg, target, purpose, close_enough)
		var result := await super._walk_to(target, purpose, close_enough, direct)
		leg += 1
		print("RETAINED TRACE WALK END phase=camp leg=", this_leg, " purpose=", purpose,
			" arrived=", result, " frame=", Engine.get_physics_frames(),
			" player=", _player.global_position, " distance=", _flat(target))
		return result

	func _observe(this_leg: int, target: Vector3, purpose: String, tolerance: float) -> void:
		var records := 0
		while leg == this_leg and records < 500:
			for _frame in 10:
				await _tree.physics_frame
				if leg != this_leg:
					return
			var distance := _flat(target)
			if distance > 10.0:
				continue
			records += 1
			var owner := INPUT_OWNER.current(_tree)
			var contacts: Array[String] = []
			for index in _player.get_slide_collision_count():
				var collider := _player.get_slide_collision(index).get_collider()
				contacts.append(str(collider.get_path()) if collider is Node else str(collider))
			print("RETAINED TRACE NEAR phase=camp leg=", this_leg, " purpose=", purpose,
				" record=", records, " frame=", Engine.get_physics_frames(), " target=", target,
				" tolerance=", tolerance, " player=", _player.global_position, " distance=", distance,
				" input_owner=", str(owner.get_path()) if owner != null else "none",
				" detour=", str(_nav.get("_detour")) if _nav != null else "none",
				" detour_left=", int(_nav.get("_detour_left")) if _nav != null else -1,
				" detour_age=", int(_nav.get("_detour_age")) if _nav != null else -1,
				" contacts=", JSON.stringify(contacts))

	func _flat(target: Vector3) -> float:
		return Vector2(target.x - _player.global_position.x, target.z - _player.global_position.z).length()

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new("user://diagnostic_material_camp_copy"))
	if not game.load_game(0):
		print("RETAINED TRACE TERMINAL load_failed")
		quit(2)
		return
	print("RETAINED TRACE DIAGNOSTIC ONLY copied autosave; no earned continuity claim")
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	await scene_changed
	for _frame in 120:
		await physics_frame
	var world := current_scene as Node3D
	var player := world.get_node("Player") as CharacterBody3D
	var rig := world.get_node("CameraRig") as Node3D
	var materials := TraceMaterials.new()
	print("RETAINED TRACE MATERIALS ENTRY frame=", Engine.get_physics_frames(), " player=", player.global_position)
	var material_result: Dictionary = await materials.run(self, world, game, player, rig, true)
	print("RETAINED TRACE MATERIALS RETURN frame=", Engine.get_physics_frames(), " player=", player.global_position,
		" result=", JSON.stringify(material_result))
	if not bool(material_result.get("passed", false)):
		quit(1)
		return
	var camp := TraceCamp.new()
	print("RETAINED TRACE CAMP ENTRY frame=", Engine.get_physics_frames(), " player=", player.global_position)
	var camp_result: Dictionary = await camp.run(self, world, game, player, rig, false, false, true)
	print("RETAINED TRACE CAMP RETURN frame=", Engine.get_physics_frames(), " player=", player.global_position,
		" result=", JSON.stringify(camp_result))
	quit(0 if bool(camp_result.get("passed", false)) else 1)
