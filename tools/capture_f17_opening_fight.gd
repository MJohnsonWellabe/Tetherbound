extends "res://tests/smoke_four_biome_continuous.gd"

## Native presentation witness of the genuine fresh title/starter/tutorial
## catch. The inherited ordinary-input driver owns gameplay; this observer
## only saves actual frames/state. No staged party, pose, HP, fight outcome,
## direct purchase, collision removal or artificial keep-alive.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
var _fight_output := ""
var _fight_source := ""
var _fight_preset := ""
var _observer: FightObserver
var _ending_fight_capture := false

class FightObserver extends Node:
	var output := ""
	var preset := ""
	var rows: Array[Dictionary] = []
	var began_ms := -1
	var next_ms := 0
	var saving := false
	var failure := ""
	var live_frames := 0

	func _process(_delta: float) -> void:
		if saving or not failure.is_empty(): return
		var world := get_tree().current_scene
		var manager: Node = world.get_node_or_null("CombatManager") if world != null else null
		var live := manager != null and int(manager.get("state")) == COMBAT.State.ACTIVE
		if began_ms < 0 and not live: return
		if began_ms >= 0 and Time.get_ticks_msec() - began_ms >= 30000: return
		if Time.get_ticks_msec() >= next_ms:
			saving = true
			await _save()
			saving = false

	func _save() -> void:
		await RenderingServer.frame_post_draw
		var at := Time.get_ticks_msec()
		var world := get_tree().current_scene
		var manager: Node = world.get_node_or_null("CombatManager") if world != null else null
		var director: Node = world.get_node_or_null("EncounterDirector") if world != null else null
		var state := int(manager.get("state")) if manager != null else COMBAT.State.INACTIVE
		var live := state == COMBAT.State.ACTIVE
		if began_ms < 0 and not live:
			# State may have changed between idle and draw; never relabel it.
			next_ms = at + 100
			return
		var actual_preset := GRAPHICS.selected()
		var renderer := RenderingServer.get_current_rendering_method()
		if actual_preset != preset or renderer != ("gl_compatibility" if preset == "Low" else "forward_plus"):
			failure = "actual graphics preset/renderer drifted during earned fight capture"
			return
		var active: RefCounted = manager.call("active_creature") if live else null
		var enemy: RefCounted = manager.call("enemy") if live else null
		if live and (active == null or enemy == null or float(active.get("hp")) <= 0.0 \
				or float(enemy.get("hp")) <= 0.0 or bool(active.get("fainted")) or bool(enemy.get("fainted"))):
			# An ACTIVE transition with a fainted actor is aftermath, not a live sample.
			next_ms = at + 100
			return
		var pixels := get_viewport().get_texture().get_image()
		if pixels == null or pixels.is_empty() or pixels.get_size() != Vector2i(1920, 1080):
			failure = "native fight image missing or wrong resolution"
			return
		var camera := get_viewport().get_camera_3d()
		var ally := director.call("ally_body") as Node3D if director != null else null
		var foe := manager.call("enemy_body") as Node3D if live else null
		if camera == null or (live and (not is_instance_valid(ally) or not is_instance_valid(foe))):
			failure = "actual live fight camera/creature bodies missing"
			return
		var image_name := "%04d-earned-opening-%s.jpg" % [rows.size(), preset.to_lower()]
		if pixels.save_jpg(output.path_join(image_name), .95) != OK:
			failure = "could not save native fight frame"
			return
		var still_name := ""
		if live and live_frames == 0:
			still_name = "first-actual-live-fight-" + preset.to_lower() + ".png"
			if pixels.save_png(output.path_join(still_name)) != OK:
				failure = "could not retain first actual live fight PNG"
				return
		if began_ms < 0: began_ms = at
		if live: live_frames += 1
		rows.append({"image": image_name, "still_png": still_name, "elapsed_ms": at, "motion_sample": true,
			"label": "earned opening fight and ordinary aftermath", "preset": actual_preset,
			"renderer": renderer, "graphics_values": GRAPHICS.values(), "combat_state": state,
			"time_of_day": _world_value(world, "WorldLook", "time_of_day"),
			"weather": _world_value(world, "WorldWeather", "weather"),
			"live_fight": live, "physics_frame": Engine.get_physics_frames(),
			"camera": _xyz(camera.global_position),
			"camera_basis": [_xyz(camera.global_basis.x), _xyz(camera.global_basis.y), _xyz(camera.global_basis.z)],
			"ally_body": _body(ally), "enemy_body": _body(foe),
			"ally": _creature(active), "enemy": _creature(enemy)})
		next_ms = at + 100

	func finish() -> bool:
		if began_ms < 0:
			failure = "no actual native live fight was captured"
			return false
		# Finish this disclosed motion observation after the real prefix, without
		# any further gameplay input or game-clock manipulation.
		while failure.is_empty() and Time.get_ticks_msec() - began_ms < 30000:
			await get_tree().process_frame
		while saving:
			await get_tree().process_frame
		if not failure.is_empty(): return false
		await _save() # actual terminal sample establishes >=30s timestamp span
		return failure.is_empty() and live_frames > 0 and rows.size() >= 2 \
			and int(rows[-1].elapsed_ms) - int(rows[0].elapsed_ms) >= 30000

	func _xyz(value: Vector3) -> Array[float]: return [value.x, value.y, value.z]
	func _world_value(world: Node, child: String, method: String) -> String:
		var node := world.get_node_or_null(child) if world != null else null
		return str(node.call(method)) if node != null else "unavailable"
	func _body(body: Node3D) -> Dictionary:
		return {"path": str(body.get_path()), "position": _xyz(body.global_position), "visible": body.is_visible_in_tree()} if is_instance_valid(body) else {}
	func _creature(creature: RefCounted) -> Dictionary:
		return {"uid": str(creature.get("uid")), "species": str(creature.get("species_id")), "level": int(creature.get("level")), "hp": float(creature.get("hp")), "fainted": bool(creature.get("fainted"))} if creature != null else {}

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	for argument: String in arguments:
		if argument == "--legacy-order-diagnostic" or argument.begins_with("--resume") \
				or argument.begins_with("--dry") or argument.begins_with("--stop-at"):
			failures.append("earned fight capture refuses legacy, resumed, fixture and boundary-stop paths")
			super._finish(false)
			return
		if argument.begins_with("--output="): _fight_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--source-commit="): _fight_source = argument.trim_prefix("--source-commit=")
		elif argument.begins_with("--preset="): _fight_preset = argument.trim_prefix("--preset=")
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-f]{40}$")
	var renderer := "gl_compatibility" if _fight_preset == "Low" else "forward_plus"
	if DisplayServer.get_name() == "headless" or DisplayServer.window_get_size() != Vector2i(1920, 1080) \
			or not GRAPHICS.PRESETS.has(_fight_preset) or RenderingServer.get_current_rendering_method() != renderer \
			or pattern.search(_fight_source) == null or not _fight_output.is_absolute_path() \
			or DirAccess.dir_exists_absolute(_fight_output) or not arguments.has("--through-opening") \
			or not arguments.has("--no-checkpoints"):
		failures.append("earned fight capture requires native1920, matching preset/renderer, exact source, fresh output and through-opening/no-checkpoints")
		super._finish(false)
		return
	if DirAccess.make_dir_recursive_absolute(_fight_output) != OK or GRAPHICS.choose(_fight_preset) != OK:
		failures.append("could not create earned fight evidence or select preset")
		super._finish(false)
		return
	_observer = FightObserver.new()
	_observer.name = "F17EarnedOpeningFightObserver"
	_observer.output = _fight_output
	_observer.preset = _fight_preset
	_observer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_observer)
	await super._run()

func _finish(prefix_passed: bool) -> void:
	if _ending_fight_capture: return
	_ending_fight_capture = true
	var captured := _observer != null and prefix_passed and failures.is_empty()
	if captured: captured = await _observer.finish()
	if not captured:
		failures.append(_observer.failure if _observer != null and not _observer.failure.is_empty() else "earned opening or native fight observation did not complete")
	if _observer != null:
		var file := FileAccess.open(_fight_output.path_join("manifest.json"), FileAccess.WRITE)
		if file == null:
			failures.append("could not retain earned fight manifest")
		else:
			file.store_string(JSON.stringify({"complete": captured and failures.is_empty(), "source": _fight_source,
				"presets": [_fight_preset], "renderer": RenderingServer.get_current_rendering_method(), "resolution": [1920, 1080],
				"views": _observer.rows, "live_fight_frames": _observer.live_frames, "requested_prefix_passed": prefix_passed,
				"failures": failures, "scope": "actual fresh title/starter/catch presentation and >=30s native motion; no full M1, visual bar, multiplayer or device claim",
				"shortcuts": ["inherited ordinary-input fresh opening driver", "observational JPEG95 frames at actual timestamps", "motion may include ordinary post-catch aftermath", "no added gameplay inputs or state mutations by observer"]}, "\t") + "\n")
			file.close()
	super._finish(captured and failures.is_empty())
