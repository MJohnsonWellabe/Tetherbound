extends "res://tests/capture_stormwood_b_named_fights.gd"
## DRY RUN — does not count. Production fight with the parent's disclosed fixtures.
## Extra frames follow real damage signals; no damage or VFX is injected.
## Tags are damage-relative: a ranged projectile can apply its overlay later.
## Parent saves only one simultaneously due request. Check saved PNGs, summary
## and nonempty HIT_FRAME strengths; exit zero alone does not establish coverage.
var _hit_serial := 0

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920, 1080)
	await process_frame
	if root.size != Vector2i(1920, 1080):
		push_error("native 1920x1080 required")
		quit(1)
		return
	await super._run()

func _on_hit(on_enemy: bool, amount: float) -> void:
	super._on_hit(on_enemy, amount)
	_hit_serial += 1
	var prefix := "hit%02d_%s" % [_hit_serial, "enemy" if on_enemy else "ally"]
	_pending.push_front({"tag": prefix + "_contact", "at": _phys})
	_pending.append({"tag": prefix + "_early", "at": _phys + 2})
	_pending.append({"tag": prefix + "_late", "at": _phys + 6})

func _save(tag: String) -> void:
	await super._save(tag)
	if tag.begins_with("hit"):
		var body := _named if "_enemy_" in tag else _director.call("ally_body") as Node3D
		var strengths: Array = []
		if is_instance_valid(body):
			for child in body.get_children():
				if child.get_script() == preload("res://scripts/vfx/body_glow.gd"):
					var mat := child.get("_material") as ShaderMaterial
					strengths.append(mat.get_shader_parameter("strength"))
		_note("HIT_FRAME %s overlay_strengths=%s" % [tag, str(strengths)])
