extends SceneTree

## Ground truth for the walk clip's arm/leg rotation tracks: prints the
## actual baked keyframe values so gait analysis doesn't have to guess a
## rig's bone-axis convention from Python source or from eyeballing renders.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	root.add_child(model)
	if not bool(model.call("build", "trainer")):
		printerr("trainer failed to build")
		quit(1)
		return

	var anim: AnimationPlayer = model.call("animation_player")
	var clip: Animation = anim.get_animation("walk")
	if clip == null:
		printerr("no walk clip")
		quit(1)
		return

	print("walk clip length: %.3f" % clip.length)
	for track_idx in clip.get_track_count():
		var path := str(clip.track_get_path(track_idx))
		if not (path.contains("Arm") or path.contains("Leg") or path.contains("Hand") or path.contains("Shoulder")):
			continue
		var key_count := clip.track_get_key_count(track_idx)
		print("\ntrack %s (%d keys, type %d):" % [path, key_count, clip.track_get_type(track_idx)])
		for k in key_count:
			var t := clip.track_get_key_time(track_idx, k)
			var v: Variant = clip.track_get_key_value(track_idx, k)
			if v is Quaternion:
				var q: Quaternion = v
				var euler := q.get_euler() * (180.0 / PI)
				print("  t=%.3f euler_deg=(%.1f, %.1f, %.1f)" % [t, euler.x, euler.y, euler.z])
			else:
				print("  t=%.3f value=%s" % [t, str(v)])
	quit(0)
