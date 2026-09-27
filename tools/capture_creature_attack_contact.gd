extends "res://tools/capture_combat_depth.gd"

## Production combat witness, with disclosed species/start-position fixtures.
## DRY RUN — does not count toward earned-play or full feature acceptance.
## --species=tuskroot|fulgocobra|solmane --out=<absolute dir> [--view=side]
## Shared RENDER_LOCK.json must be held_by combat. One quick-attack input;
## no stat, animation, terrain, combat timing or body transform overrides.
var _subject := "tuskroot"
var _view := "production"
var _samples: Array[Dictionary] = []


func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("attack witness requires native 1920x1080; got %s" % root.size)
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="): _subject = arg.trim_prefix("--species=")
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg.begins_with("--view="): _view = arg.trim_prefix("--view=")
	if _out.is_empty() or not _owns_lock():
		push_error("attack contact capture requires --out and held_by combat render lock")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("save_system", load("res://scripts/save/save_game.gd").new("user://attack_contact_%s/" % _subject))
	RenderingServer.render_loop_enabled = false
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES: await physics_frame
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or not await director.call("adopt_starter", _subject):
		_fail("failed to adopt requested witness creature")
		_complete_contact()
		return
	_leave_the_farmhouse()
	if not _collect_capture_nodes():
		_complete_contact()
		return
	await _walk_to_the_wild_creature()
	if not _failures.is_empty():
		_complete_contact()
		return
	RenderingServer.render_loop_enabled = true
	await _engage()
	if not _manager.is_fighting():
		_fail("real interact input did not enter combat")
		_complete_contact()
		return
	_ally = _director.call("ally_body")
	var enemy: Node3D = _manager.enemy_body()
	var toward := enemy.global_position - _ally.global_position
	_aim_camera_along(toward)
	if _view == "side":
		_rig.set("yaw", float(_rig.get("yaw")) + PI * 0.5)
	for i in 18: await physics_frame
	await _contact_frame(0, false)
	var press := InputEventAction.new()
	press.action = "combat_quick"
	press.pressed = true
	Input.parse_input_event(press)
	_pressed_attack = "combat_quick"
	await physics_frame
	_release_inputs()
	var saw_attack := false
	for i in range(1, 121):
		await physics_frame
		if i % 2 == 0:
			var sample := await _contact_frame(i, true)
			if str(sample.get("animation", "")).to_lower().contains("attack"):
				saw_attack = true
		if not _manager.is_fighting():
			break
	if not saw_attack:
		_fail("no attack animation was observed after the input")
	_complete_contact()


func _contact_frame(frame: int, after_press: bool) -> Dictionary:
	await RenderingServer.frame_post_draw
	if not _owns_lock():
		_fail("render lock lost")
		return {}
	var animator: RefCounted = _ally.get("_animator")
	var player: AnimationPlayer = animator.get("_player") if animator != null else null
	var model: Node3D = _ally.get("_model")
	var at := _ally.global_position
	var sample := {"frame":frame,"physics_frame":Engine.get_physics_frames(),
		"viewport_size":[root.size.x,root.size.y],
		"after_press":after_press,"species":_subject,"view":_view,
		"animation":str(player.current_animation) if player != null else "",
		"animation_time":player.current_animation_position if player != null and player.is_playing() else -1.0,
		"body_position":[at.x,at.y,at.z],
		"model_position":[model.position.x,model.position.y,model.position.z],
		"ground_y":float(_world.call("ground_height_at",at.x,at.z)),
		"action":int(_manager.get("_action")),"hitstop_left":float(_manager.get("_hitstop_left")),
		"player_staggered":bool(_manager.player_is_staggered()),
		"fighting":bool(_manager.is_fighting())}
	var file := "%s_%s_%03d.png" % [_subject,_view,frame]
	sample["file"] = file
	var error := root.get_texture().get_image().save_png(_out.path_join(file))
	if error != OK: _fail("failed writing " + file)
	_samples.append(sample)
	return sample


func _complete_contact() -> void:
	_release_inputs()
	var file := FileAccess.open(_out.path_join("trace.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"samples":_samples,"failures":_failures},"\t"))
	print("ATTACK CONTACT %s %s: %d frames, %d failures" % [_subject,_view,_samples.size(),_failures.size()])
	quit(0 if _failures.is_empty() else 1)
