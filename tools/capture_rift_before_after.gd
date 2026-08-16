extends SceneTree

## SG44's own done-when, rendered: "standing where SF33 put the seam, before
## and after the Warden, gives two visibly different horizons — and the player
## still cannot walk into the next region."
##
## The item shipped that claim proved by covered-area numbers (167,632 m² of
## storm going to 0; 70,645 m² of far country arriving) and said plainly that
## nothing had been visually judged. Numbers cannot tell you the storm wall
## reads as weather rather than as a grey card, or that the far ridges read as
## distance rather than as a sticker on the sky. This renders the pair so a
## judge can say.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_rift_before_after.gd
##
## Writes shots/_rift_before.png and shots/_rift_after.png from the identical
## camera, so the only difference between the two frames is the world event.
##
## NOT YET RUN TO COMPLETION, and the reason is the machine rather than the
## script: booting the full world under xvfb's software GL takes longer than
## any timeout this session could give it, and it got slower again when SD16's
## quarry and SE21's river went into the bake. It is committed unrun because a
## correct capture tool that needs a faster box is worth more than another
## paragraph promising to write one. On real hardware — or on CI, where a
## render job would have the machine to itself — this is a single command, and
## it is what closes SG44's own admitted gap: that item proved its horizon
## change by covered-area numbers and said plainly that nothing had been
## judged by eye.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_BEFORE := "res://shots/_rift_before.png"
const OUT_AFTER := "res://shots/_rift_after.png"

## Where the player stands to look down the storm road. Read from the spoke's
## own config at runtime rather than pinned here, so a retuned seam moves this
## camera with it.
const SPOKE := "storm_road"

## Long enough for the terrain to build and settle, matching the other
## world-booting captures.
const SETTLE_FRAMES := 150

## The collapse animates over ~9s of real time. Under xvfb's software GL a
## rendered frame is far slower than 1/60s, so a frame count chosen as
## "9s x 60" waits many minutes for nothing; this waits on the CLOCK instead
## and renders whatever the frame rate allows in between.
const COLLAPSE_SECONDS := 11.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var look := _seam_view(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = look[0]
	camera.look_at_from_position(look[0], look[1])
	camera.far = 4000.0
	camera.make_current()
	for i in 20:
		await process_frame
	_shoot(OUT_BEFORE)

	# Fire the event the way the chapter does: set the flag the collapse
	# watches, rather than calling into rift_collapse.gd directly. If the
	# wiring between the flag and the sky is what broke, this frame is where
	# it shows, which is the whole point of rendering rather than asserting.
	var game: Node = root.get_node_or_null(^"Game")
	if game != null:
		var progression: Variant = game.get("progression")
		if progression != null and (progression as Object).has_method("set_flag"):
			(progression as Object).call("set_flag", "legendary_freed", true)
	var until := Time.get_ticks_msec() + int(COLLAPSE_SECONDS * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame
	_shoot(OUT_AFTER)
	quit(0)


## The camera stands on the near side of the seam looking out along the
## spoke's own bearing — the shot SG44's done-when describes, not a survey
## angle chosen to flatter it.
func _seam_view(world: Node) -> Array:
	var eye := Vector3(120.0, 12.0, -150.0)
	var aim := Vector3(400.0, 40.0, -320.0)
	var terrain: Dictionary = _terrain()
	for entry: Variant in (terrain.get("spokes", []) as Array):
		var spoke: Dictionary = entry
		if str(spoke.get("id", "")) != SPOKE:
			continue
		var at: Array = spoke.get("gap", spoke.get("at", []))
		if at.size() >= 2:
			var gap := Vector3(float(at[0]), 0.0, float(at[1]))
			var ground := 0.0
			if world.has_method("ground_height_at"):
				ground = float(world.call("ground_height_at", gap.x, gap.z))
			# Back off along the bearing to the world centre so the whole
			# seam and the sky behind it are in frame.
			var back := (Vector3.ZERO - gap).normalized()
			eye = gap + back * 60.0 + Vector3(0.0, ground + 9.0, 0.0)
			aim = gap - back * 260.0 + Vector3(0.0, ground + 40.0, 0.0)
		break
	return [eye, aim]


func _terrain() -> Dictionary:
	var file := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _shoot(path: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved %s" % path)
