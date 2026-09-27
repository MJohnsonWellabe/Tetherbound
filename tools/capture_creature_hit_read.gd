extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count. Isolated production body overlay at fixed times.
const GLOW := preload("res://scripts/vfx/body_glow.gd")
const VFX := preload("res://scripts/vfx/combat_vfx.gd")
const SUBJECTS := ["voltarach", "sparkit", "bramblebun", "fulgocobra"]

func _run_roster() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		_skip("viewport", "native 1920x1080 required")
		return
	await _build_stage()
	for id: String in SUBJECTS:
		if not _only.is_empty() and not _only.has(id): continue
		var body := _spawn_creature(id, Vector3.ZERO, -30.0)
		for i in 8: await physics_frame
		body.set_physics_process(false)
		var animator: RefCounted = body.get("_animator")
		if animator != null:
			var player := animator.get("_player") as AnimationPlayer
			if player != null: player.pause()
		var size := _measured(body.get_node_or_null(^"Model") as Node3D)
		var half_len := maxf(size.x, size.z) * 0.5
		_trainer.position = Vector3(-(half_len + 1.1), 0, 0)
		_frame(_trainer.position.x - 0.4, half_len, maxf(size.y, TRAINER_HEIGHT), 10.0, half_len * 0.9)
		await _shoot(id + "_unhit", {"subject":id,"effect":"none","proof":"DRY RUN — does not count"})
		for charged: bool in [false, true]:
			var spec: Dictionary = VFX.config().get("hit_flash", {})
			var strength := float(spec.get("charged_strength" if charged else "strength", 0.9))
			var glow: Node = GLOW.attach(body, GLOW.Mode.FLASH, spec, strength)
			if glow == null:
				_skip(id, "no overlay attached")
				continue
			glow.set_physics_process(false)
			var previous := 0.0
			for time: float in [0.0, 0.04, 0.1]:
				glow.call("advance", time - previous)
				previous = time
				await _shoot(id + ("_charged_" if charged else "_quick_") + str(int(time * 1000)),
					{"subject":id,"effect":"charged hit" if charged else "quick hit","time_s":time,"proof":"DRY RUN — does not count"})
			glow.call("advance", 1.0)
			await process_frame
		await _shoot(id + "_restored", {"subject":id,"effect":"restored","proof":"DRY RUN — does not count"})
		body.queue_free()
		await process_frame

func _finish(ok: bool) -> void:
	super._finish(ok and _skips.is_empty())
