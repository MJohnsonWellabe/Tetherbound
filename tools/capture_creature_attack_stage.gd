extends "res://tools/capture_visual_audit.gd"

## Flat-floor diagnostic supplement to the production combat witness.
## DRY RUN — does not count toward earned-play or full feature acceptance.
## Uses the audit's unchanged light/floor and production CreatureBody fit/animator.
## Captures uninterrupted playback and the authored return pose at fixed 60 Hz.
## --section=roster --only=tuskroot,riptusk,staticub,fulgocobra,solmane --out=<dir>
const CONTACT_SUBJECTS := ["tuskroot", "riptusk", "staticub", "fulgocobra", "solmane"]


func _run_roster() -> void:
	# Windows can clamp the startup size to its work area before the scene tree
	# exists. Set the capture window after initialization and fail on mismatch.
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		_skip("viewport", "required native 1920x1080, got %s" % root.size)
		return
	await _build_stage()
	for id: String in CONTACT_SUBJECTS:
		if not _only.is_empty() and not _only.has(id): continue
		var body := _spawn_creature(id, Vector3.ZERO, -90.0)
		for i in 8: await physics_frame
		var size := _measured(body.get_node_or_null(^"Model") as Node3D)
		var half_len := maxf(size.x, size.z) * 0.5
		_trainer.global_position = Vector3(-(half_len + 1.1), 0.0, 0.0)
		_trainer.rotation.y = 0.0
		_frame(_trainer.global_position.x - 0.4, half_len, maxf(size.y, TRAINER_HEIGHT), 0.0, maxf(size.x, size.z) * 0.4)
		var animator: RefCounted = body.get("_animator")
		var player: AnimationPlayer = animator.get("_player") if animator != null else null
		if player == null or not player.has_animation("attack"):
			_skip(id, "missing production attack player/clip")
			body.queue_free()
			continue
		body.call("play_attack")
		for frame in 78:
			await physics_frame
			if frame % 2 != 0: continue
			await RenderingServer.frame_post_draw
			var label := "%s_%03d" % [id, frame]
			var file := "%s/%s.png" % [_dir, label]
			var error := root.get_texture().get_image().save_png(file)
			_log_line({"kind":"frame", "subject":id, "view":"side_uninterrupted_attack", "frame":frame,
				"viewport_size":[root.size.x,root.size.y],
				"physics_frame":Engine.get_physics_frames(), "file":file,
				"animation":player.current_animation, "animation_time":player.current_animation_position,
				"save_error":error, "measured_bind_height":size.y})
			if error != OK: _skip(id, "PNG save failed")
			else: _frames.append({"name":file})
		body.queue_free()
		await process_frame


func _finish(ok: bool) -> void:
	super._finish(ok and _skips.is_empty())
