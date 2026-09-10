extends SceneTree

## Diagnostic-only replay of the quarry/Warrens segment from a copied earned
## post-bridge save. The source slot is read-only; all autosaves land beneath
## user://diagnostic_warrens_copy.

const SAVE := preload("res://scripts/save/save_game.gd")


class TraceWarrens:
	extends "res://tests/helpers/meadows_earned_warrens_segment.gd"
	var approach_only := false

	func _travel() -> bool:
		if not approach_only:
			return await super._travel()
		if not await _prepare():
			return false
		# Recreate the exact leg that failed after the fourth real quarry harvest.
		# The diagnostic may place its starting state; the leg itself still uses
		# only the production controller binding and real CharacterBody collision.
		_player.global_position = Vector3(401.0, -0.5, 1809.0)
		_player.velocity = Vector3.ZERO
		await _tree.physics_frame
		await _tree.physics_frame
		for at: Vector2 in [Vector2(394.1, 1809.0), Vector2(392.85, 1806.82), Vector2(393, 1802)]:
			if not await _walk_ground(at, 1.5):
				return false
		print("QUARRY APPROACH-ONLY reached the fifth quarry pose through ordinary movement")
		return true

	func _walk(target: Vector3, radius: float = 1.5, budget: int = -1) -> bool:
		if budget < 0:
			budget = maxi(1800, int(_player.global_position.distance_to(target) / 2.5 * 60.0) + 600)
		_nav.reset()
		for frame in budget:
			if not _failures.is_empty():
				return false
			if _fighting():
				_stick(0.0, 0.0)
				if not await _fight():
					return false
				_nav.reset()
			if INPUT_OWNER.current(_tree) != null:
				_stick(0.0, 0.0)
				return _fail("Unexpected modal interrupted the real quarry/Warrens walk")
			if _player.global_position.distance_to(target) <= radius:
				_stick(0.0, 0.0)
				return true
			_nav.step(target)
			await _tree.physics_frame
			if frame % 60 == 0 and Vector2(target.x, target.z).distance_to(Vector2(400, 1800)) < 50.0:
				print("QUARRY CONTACT ", JSON.stringify(_trace_row(frame, target)))
		_stick(0.0, 0.0)
		return _fail("Ordinary quarry/Warrens movement did not reach %s; player=%s" % [target, _player.global_position])

	func _trace_row(frame: int, target: Vector3) -> Dictionary:
		var collisions: Array[Dictionary] = []
		if _player is CharacterBody3D:
			for index in (_player as CharacterBody3D).get_slide_collision_count():
				var hit := (_player as CharacterBody3D).get_slide_collision(index)
				var collider := hit.get_collider() as Node
				collisions.append({"collider": str(collider.get_path()) if collider != null else "<none>",
					"normal": str(hit.get_normal()), "position": str(hit.get_position())})
		var foundation_local := {}
		var quarry := _world.get_node_or_null("OldQuarry")
		if quarry != null:
			for child in quarry.get_children():
				if child is Node3D and str(child.name).begins_with("Foundation_"):
					foundation_local[str(child.name)] = str((child as Node3D).to_local(_player.global_position))
		return {"frame": frame, "player": str(_player.global_position), "target": str(target),
			"distance": _player.global_position.distance_to(target), "velocity": str(_player.velocity),
			"nav_side": _nav.get("_side"), "nav_detour": str(_nav.get("_detour")),
			"nav_detour_left": _nav.get("_detour_left"), "collisions": collisions,
			"foundation_local": foundation_local}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var source_slot := ""
	var approach_only := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--source-slot="):
			source_slot = arg.trim_prefix("--source-slot=")
		elif arg == "--approach-only":
			approach_only = true
	if source_slot.is_empty() or not FileAccess.file_exists(source_slot):
		push_error("WARRENS TRACE requires --source-slot=<absolute slot_0.json>")
		quit(2)
		return
	var copied_dir := "user://diagnostic_warrens_copy"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(copied_dir))
	var destination := copied_dir + "/slot_0.json"
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		push_error("WARRENS TRACE could not create isolated slot copy")
		quit(2)
		return
	file.store_buffer(FileAccess.get_file_as_bytes(source_slot))
	file.close()
	var game := root.get_node_or_null(^"Game")
	game.set("save_system", SAVE.new(copied_dir))
	if not bool(game.call("load_game", 0)):
		push_error("WARRENS TRACE could not load copied slot")
		quit(2)
		return
	print("WARRENS TRACE DIAGNOSTIC ONLY copied save; no continuity claim")
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	await scene_changed
	for frame in 120:
		await physics_frame
	var trace := TraceWarrens.new()
	trace.approach_only = approach_only
	var result: Dictionary = await trace.run(self, current_scene as Node3D, game)
	print("WARRENS TRACE RESULT ", JSON.stringify(result))
	quit(0 if bool(result.get("passed", false)) else 1)
