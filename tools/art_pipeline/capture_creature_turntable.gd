extends "res://tools/_capture_creature_roster.gd"

## X04 creature-art lane. The roster tool's own stage, lighting, trainer and
## camera, turned into a turntable for ONE species: the creature rotates in
## fixed steps, the camera and the 1.80 m trainer never move, so every frame is
## the same comparison from a different side.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/art_pipeline/capture_creature_turntable.gd \
##     -- --species=galecrest [--shiny] [--steps=8] [--out=res://shots/creature_art_lane/turntable]

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	var species := ""
	var shiny := false
	var steps := 8
	var out := "res://shots/creature_art_lane/turntable"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			species = arg.trim_prefix("--species=")
		elif arg == "--shiny":
			shiny = true
		elif arg.begins_with("--steps="):
			steps = maxi(1, int(arg.trim_prefix("--steps=")))
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if species.is_empty() or not SPECIES.has(species):
		push_error("turntable requires --species=<id present in species.json>")
		quit(1)
		return
	await process_frame
	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for i in BOOT_FRAMES:
		await physics_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in steps:
		var yaw := 360.0 * i / steps
		var body := _spawn_creature(species, shiny, PAIR_CREATURE_POS, yaw)
		for f in SETTLE_FRAMES:
			await physics_frame
		var name := "%s%s-yaw%03d" % [species, "-shiny" if shiny else "", int(yaw)]
		if await _capture("%s/%s.png" % [out, name]):
			_report(name, body, "")
		body.queue_free()
		await process_frame
	quit(0)
