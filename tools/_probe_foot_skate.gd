extends SceneTree

## MQ1A scratch probe: measures flat-ground foot skate from the baked clips.
##
## For each gait, samples the foot bones' world position across one cycle
## while the body notionally translates at the movement.json speed. While a
## foot is PLANTED (lowest band of its own height range), its ground-relative
## speed should be ~0: the clip must sweep it backward at exactly body speed.
## Reports the planted-window mean and worst ground-relative speed per foot —
## the number OF5's whole redo was about, now measured from bone transforms
## instead of eyeballed stripes, so no render bias can flatter it.
##
##   ~/.cache/tetherbound-art/godot --headless --path . \
##       --script tools/_probe_foot_skate.gd

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const SAMPLES := 60


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var move := _movement_config()
	var loco: Dictionary = move.get("locomotion", {})

	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	root.add_child(model)
	if not bool(model.call("build", "trainer")):
		printerr("trainer failed to build")
		quit(1)
		return

	var anim: AnimationPlayer = model.call("animation_player")
	var skeleton := _find_skeleton(model)
	if skeleton == null:
		printerr("no skeleton")
		quit(1)
		return

	for gait: Array in [["walk", float(loco.get("walk_speed", 5.0))],
			["sprint", float(loco.get("sprint_speed", 8.6))]]:
		var clip: String = gait[0]
		var body_speed: float = gait[1]
		var cycle: float = anim.get_animation(clip).length
		model.call("play", clip)
		anim.play(clip)
		anim.speed_scale = 0.0

		# Pre-roll: the first few seeks after play() land in the renderer a
		# few frames late and read as a frozen foot (measured: 3-4 identical
		# leading samples). Throw a seek away before sampling.
		anim.seek(0.0, true)
		for w in 6:
			await process_frame

		for foot_name in ["LeftFoot", "RightFoot"]:
			var idx := skeleton.find_bone(foot_name)
			var xs: Array[float] = []
			var ys: Array[float] = []
			for i in SAMPLES:
				anim.seek(cycle * i / SAMPLES, true)
				# One frame is not enough for the seek to land in the bone
				# poses under speed_scale = 0 — the first run of this probe
				# read near-constant foot positions and reported the body
				# speed itself as "skate" on a clip whose renders visibly
				# sweep. Wait for the update, then force the skeleton.
				for w in 3:
					await process_frame
				skeleton.force_update_all_bone_transforms()
				var pose := skeleton.global_transform * skeleton.get_bone_global_pose(idx)
				# Model faces +Z unrotated; the clip's travel axis is +Z.
				xs.append(pose.origin.z)
				ys.append(pose.origin.y)
			if foot_name == "LeftFoot":
				for i in SAMPLES:
					print("  %s t=%.3f z=%.3f y=%.3f" % [clip, cycle * i / SAMPLES, xs[i], ys[i]])
			var y_min: float = ys.min()
			var y_max: float = ys.max()
			var planted_below: float = y_min + (y_max - y_min) * 0.25
			var dt := cycle / SAMPLES
			var worst := 0.0
			var total := 0.0
			var count := 0
			for i in SAMPLES:
				if ys[i] > planted_below:
					continue
				var j := (i + 1) % SAMPLES
				if ys[j] > planted_below:
					continue
				# Ground-relative: clip sweep speed plus body translation.
				var ground_v: float = (xs[j] - xs[i]) / dt + body_speed
				worst = maxf(worst, absf(ground_v))
				total += absf(ground_v)
				count += 1
			if count > 0:
				print("%s %s: planted mean skate %.2f m/s, worst %.2f m/s (body %.1f, %d planted samples)"
					% [clip, foot_name, total / count, worst, body_speed, count])
			else:
				print("%s %s: no planted window found" % [clip, foot_name])

	quit(0)


func _movement_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
