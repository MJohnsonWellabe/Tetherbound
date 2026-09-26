extends "res://tools/_capture_creature_roster.gd"

## X04 creature-art lane. One species on the roster stage (trainer, lighting and
## camera unchanged), turned to a fixed yaw, with each gameplay clip paused at
## 25/50/75% of its length -- the deformation check a rigged candidate needs
## before integration (joint tearing, floor clipping, limbs through the body).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/art_pipeline/capture_creature_clips.gd \
##     -- --species=bramblebun [--yaw=90] [--out=res://shots/creature_art_lane/clips]

const CLIPS := ["idle", "walk", "run", "attack", "hit", "faint"]
const PHASES := [0.25, 0.5, 0.75]

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	var species := ""
	var yaw := 90.0
	var out := "res://shots/creature_art_lane/clips"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			species = arg.trim_prefix("--species=")
		elif arg.begins_with("--yaw="):
			yaw = float(arg.trim_prefix("--yaw="))
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if species.is_empty() or not SPECIES.has(species):
		push_error("clips capture requires --species=<id present in species.json>")
		quit(1)
		return
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for i in BOOT_FRAMES:
		await physics_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var body := _spawn_creature(species, false, PAIR_CREATURE_POS, yaw)
	for f in SETTLE_FRAMES:
		await physics_frame
	body.set_physics_process(false)
	body.set_process(false)
	var found := body.find_children("*", "AnimationPlayer", true, false)
	if found.is_empty():
		push_error("no AnimationPlayer on %s" % species)
		quit(1)
		return
	var anim := found[0] as AnimationPlayer
	anim.process_mode = Node.PROCESS_MODE_DISABLED
	for clip: String in CLIPS:
		var name := clip if anim.has_animation(clip) else ""
		if name.is_empty():
			print("MISSING clip %s" % clip)
			continue
		var length := anim.get_animation(name).length
		for phase: float in PHASES:
			anim.play(name)
			anim.seek(length * phase, true)
			anim.pause()
			for f in 3:
				await process_frame
			var path := "%s/%s-%s-%02d.png" % [out, species, clip, int(phase * 100)]
			if await _capture(path):
				print("clip %s %.2f -> %s" % [clip, phase, path])
	quit(0)
