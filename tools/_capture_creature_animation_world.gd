extends SceneTree

## THE FIVE, ANIMATING, IN THE ACTUAL MEADOWS — as frames, not as a claim.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_creature_animation_world.gd
##
## T1-RIG-3's second instrument. `tools/_probe_creature_animation_in_world.gd`
## answers "does a bone move" numerically and headlessly; this answers the part
## a number cannot — what it actually looks like, in the real world, with the
## real grass and the real terrain and the real light around it.
##
## Shot as A/B PAIRS a fixed interval apart, never as single frames. A single
## still of a creature standing in a field is exactly the evidence that cannot
## distinguish the thing this lane is checking: a rigged creature mid-idle and
## a frozen statue photograph identically. Two frames of the same creature from
## the same camera, half a second apart, do not — and the tool prints the
## measured pixel difference between them so the pair is checkable without
## eyeballing it.
##
## `CAPTURE_CHECK.require` runs at every shutter. A lot of this project's older
## visual evidence was invalidated by frames that had silently lost the grass
## field (`tools/capture_check.gd`'s own header, JUDGE-3 section 0); animation
## evidence shot the same way would be worth no more than that was.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://ralph/reports/T1-RIG-3/shots"

## The five this lane owns, plus one long-shipping control. If `terrapup` shows
## the same frozen pose across a pair, the fault is the capture, not the five.
const SUBJECTS := ["terrapup", "sparkit", "cindercub", "shadelet", "frostclaw", "bramblebun"]

const SETTLE_FRAMES := 12
const PER_SHOT_SETTLE := 3
## Seconds of clip between the A and B of a pair.
##
## SEEKED, not waited out. The first version of this tool let real time pass
## between the two shutters, and that made the pair cost 30 rendered frames of
## nothing — fatal here, because a frame of this world under llvmpipe software
## rendering costs about twenty seconds, so six species came to roughly two
## hours and the run was killed with zero frames written. Posing the
## AnimationPlayer directly with `seek()` buys the same evidence for two
## renders instead of thirty-eight, and buys it *better*: the gap is now an
## exact, repeatable distance into the clip rather than however far the frame
## rate happened to carry it, and nothing else in the world gets a chance to
## drift between the two exposures.
const PAIR_SECONDS := 0.45
const EYE_HEIGHT := 1.5

## Open, flat, grassy ground in Lower Meadows, clear of the village clutter and
## of Creek Hollow's rock/tree dressing — a plain field so nothing in the frame
## competes with the creature for attention.
const STAGE := Vector2(-430.0, 470.0)


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await process_frame

	# HUD off — this is a look at the world, not at the interface.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	# Pin the light and the weather, the same discipline every other probe in
	# this directory uses: a pair shot across a moving sun would differ frame to
	# frame for reasons that have nothing to do with animation, which is the one
	# measurement this tool exists to make.
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)

	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director == null:
		print("FATAL: no EncounterDirector")
		quit(1)
		return

	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var camera := Camera3D.new()
	camera.fov = 50.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	var terrain: Variant = world.get("_terrain")
	if terrain != null and (terrain as Node).has_method("set_camera"):
		(terrain as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var wanted: Array = OS.get_cmdline_user_args()
	for species: String in SUBJECTS:
		if not wanted.is_empty() and not wanted.has(species):
			continue
		await _shoot_pair(world, director, field, camera, look, species)

	quit(0)


## One species, alone on open ground, photographed twice.
func _shoot_pair(world: Node, director: Node, field: RefCounted, camera: Camera3D,
		look: Node, species: String) -> void:
	var ground: float = field.height_at(STAGE.x, STAGE.y)
	var spot := Vector3(STAGE.x, ground, STAGE.y)
	var wild: Node3D = director.call("spawn_wild", species, spot, {
		"name": "Shot_%s" % species,
		# Parked on the spot. A wandering creature would translate between A and
		# B, and a translation is not the thing being measured — the question is
		# whether the SKIN moves, not whether the node does.
		"wander_radius": 0.0,
	}) as Node3D
	if wild == null:
		print("%s: spawn_wild returned null" % species)
		return

	for _i in 6:
		await process_frame

	# Frame the creature from its own front-left, at roughly a player's eye
	# height, standing back by a distance scaled to how big it actually is, so a
	# 0.85m Sparkit and a 2.0m Frostclaw both fill a similar share of the frame.
	var height := _visual_height(wild)
	var standoff := maxf(3.2, height * 3.0)
	var eye := wild.global_position + Vector3(-standoff * 0.8, EYE_HEIGHT, standoff * 0.8)
	eye.y = field.height_at(eye.x, eye.z) + EYE_HEIGHT
	camera.global_position = eye
	camera.look_at(wild.global_position + Vector3(0.0, height * 0.5, 0.0), Vector3.UP)

	# Pin the clip and pose it by hand. Freeing the player from its own playback
	# is what makes the pair a controlled comparison: both frames are the same
	# creature, same camera, same light, same clip — differing only by how far
	# into that clip the skeleton has been wound.
	var anim := _find_animation_player(wild)
	var clip := ""
	if anim != null:
		clip = anim.current_animation
		if clip == "":
			clip = "idle" if anim.has_animation("idle") else ""

	var a := await _shutter(camera, look, anim, clip, 0.0, "%s/%s-a.png" % [OUT, species])
	var b := await _shutter(camera, look, anim, clip, PAIR_SECONDS, "%s/%s-b.png" % [OUT, species])

	var moved := _difference(a, b)
	print("%-12s clip '%s'  pair difference: %.4f%% of pixels changed  %s" % [
		species, clip, moved * 100.0,
		"MOVED" if moved > 0.001 else "*** IDENTICAL FRAMES — FROZEN ***",
	])

	wild.queue_free()
	await process_frame


func _shutter(camera: Camera3D, look: Node, anim: AnimationPlayer, clip: String,
		at: float, path: String) -> Image:
	if look != null:
		look.call("apply_time", "day")
	for _i in PER_SHOT_SETTLE:
		await process_frame
	# Wind the skeleton to an exact point in the clip, last thing before the
	# shutter, so the settle frames above cannot carry it somewhere else.
	# `update = true` applies the pose immediately rather than at the next tick.
	if anim != null and clip != "" and anim.has_animation(clip):
		anim.play(clip)
		anim.seek(at, true)
	await RenderingServer.frame_post_draw
	CAPTURE_CHECK.require(self, camera)
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png(path)
		print("wrote %s" % path)
	return image


func _find_animation_player(node: Node) -> AnimationPlayer:
	var found: Array[Node] = node.find_children("*", "AnimationPlayer", true, false)
	return null if found.is_empty() else found[0] as AnimationPlayer


## The model's real drawn height, from its own visual bounds rather than from
## the species' declared gameplay height — a creature whose model is scaled or
## offset would otherwise be framed against a number that does not match what
## the camera can see.
func _visual_height(node: Node3D) -> float:
	var tallest := 0.0
	for child: Node in node.find_children("*", "VisualInstance3D", true, false):
		var vis := child as VisualInstance3D
		if not vis.visible:
			continue
		tallest = maxf(tallest, vis.get_aabb().size.y * vis.global_transform.basis.get_scale().y)
	return maxf(0.6, tallest)


## Fraction of pixels that differ meaningfully between two frames.
##
## Sampled on a grid rather than per-pixel: this runs under software rendering
## on a container already short of throughput, and a 1-in-4 grid answers
## "did anything move" to the same confidence for a sixteenth of the work.
## The threshold is above encoder/dither noise and well below a real limb.
func _difference(a: Image, b: Image) -> float:
	if a == null or b == null or a.get_size() != b.get_size():
		return 0.0
	var changed := 0
	var total := 0
	var size := a.get_size()
	for y in range(0, size.y, 4):
		for x in range(0, size.x, 4):
			total += 1
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.02:
				changed += 1
	return 0.0 if total == 0 else float(changed) / float(total)
