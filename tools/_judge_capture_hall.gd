extends SceneTree

## T1-HALL (2026-08-30). The evidence stands HALL_DESIGN_2026-08-30.md §10
## specifies for the merged Meadows Hall, now that stronghold.gd builds real
## massing there. Same rig as tools/_judge_capture_arch_0829.gd (Terrain3D
## handed the capture camera, canvas layers hidden, day keyframe, weather
## cleared) so these frames are directly comparable in method, even though
## they point at a different, merged site with no castle/stronghold split
## any more.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_judge_capture_hall.gd
##
## NEVER --headless with a rendering driver: hangs forever.

## T1-HALL-REBUILD (2026-08-30) extends this tool rather than forking it: the
## same stands, plus the design §10 requirement its author flagged as unmet --
## "H-03 repeated at `golden` and `night` (the gate face is the SHADED face --
## §2 -- so its dusk/night self-lit read is part of the design and must be
## judged, not just the noon state)". `--out=` lets a lane write its own frames
## without overwriting a previous lane's evidence.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/hall0830"
const SETTLE_FRAMES := 90
const POSE_FRAMES := 3
const FOV := 70.0

func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


var _out_dir := DEFAULT_OUT_DIR


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_hide_canvas_layers(root)
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0 + 900.0, 2610.0 + 900.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var stronghold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	if stronghold == null:
		push_error("no Stronghold node; the Hall did not build")
		quit(1)
		return

	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	torch.visible = false
	world.add_child(torch)

	var written: Array[String] = []
	var failures: Array[String] = []

	# design §10's H-01..H-08, world coordinates, eye +1.7m above ground
	# unless the stand itself says otherwise.
	# T1-HALL-REBUILD: the two LONG stands aim at the Hall itself rather than
	# at a fixed compass bearing. H-02 stood at the Sigil Gate (63.6, 7395)
	# looking south-west on a hard-coded (-1,1); the Hall is at (8, 7560),
	# which from that point bears about 18 degrees west of south, not 45 -- so
	# the frame came back full of fence and treeline with the building off the
	# right edge entirely. Three acceptance items (2, 7 and 10) are judged at
	# H-02, and none of them can be judged in a frame the building is not in.
	# `aim_hall` points the stand at the complex's own courtyard marker, so the
	# stands follow the site instead of needing re-derivation every time it
	# moves.
	var hall_at: Vector3 = stronghold.call("marker", "courtyard") \
		if bool(stronghold.call("has_marker", "courtyard")) else stronghold.global_position
	var stands := [
		{"name": "H-01-approach-400", "at": Vector2(0.0, 7160.0), "eye_h": 8.0,
			"dir": Vector2(0.0, 1.0), "aim_hall": true},
		{"name": "H-02-sigil-gate", "at": Vector2(63.6, 7395.0), "eye_h": 1.7,
			"dir": Vector2(-1.0, 1.0), "aim_hall": true},
		# H-02b, added T1-HALL-REBUILD. At the authored 1.7m eye height the
		# Sigil Gate stand sees NOTHING of the Hall -- Band 5's treeline fills
		# the frame end to end, and it did in the previous lane's capture of
		# this same stand too, so acceptance items 2, 7 and 10 (three-tier read,
		# coursing at range, occupation reads) have never actually been judged
		# at the range they are written for. This is the same stand with its eye
		# above the canopy: not a nicer angle, the only one from which the item
		# is answerable. The 1.7m frame is KEPT alongside it, because what it
		# shows -- the chapter's climax reveal, fully occluded from the gate the
		# player opens to earn it -- is a real finding about the approach, and
		# deleting the frame would delete the finding.
		{"name": "H-02b-sigil-gate-raised", "at": Vector2(63.6, 7395.0), "eye_h": 26.0,
			"dir": Vector2(-1.0, 1.0), "aim_hall": true},
		{"name": "H-03-ramp-foot", "at": Vector2(8.0, 7505.0), "eye_h": 1.7, "dir": Vector2(0.0, 1.0)},
		{"name": "H-05-east-flank", "at": Vector2(48.0, 7590.0), "eye_h": 6.0, "dir": Vector2(-1.0, 0.0)},
		{"name": "H-06-west-keep", "at": Vector2(-60.0, 7630.0), "eye_h": 10.0, "dir": Vector2(1.0, 0.0)},
		{"name": "H-08-wall-close", "at": Vector2(14.0, 7542.0), "eye_h": 6.0, "dir": Vector2(0.0, 1.0)},
	]
	for entry: Variant in stands:
		var s: Dictionary = entry
		var at: Vector2 = s["at"]
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			failures.append("%s: no ground at %s" % [str(s["name"]), str(at)])
			continue
		var eye := Vector3(at.x, ground + float(s["eye_h"]), at.y)
		var dir: Vector2 = s["dir"]
		var target := eye + Vector3(dir.x, 0.0, dir.y).normalized() * 40.0
		if bool(s.get("aim_hall", false)):
			# Raise the aim point off the floor so the tiers fill the frame
			# rather than the ground in front of them.
			target = hall_at + Vector3(0.0, 10.0, 0.0)
		await _shoot(camera, look, torch, false, eye, target, str(s["name"]), written, failures)
		# Design §10: the gate face is the SHADED face at the day keyframe, so
		# its self-lit dusk/night read is part of the design and has to be
		# judged too. Only H-03 gets the variants -- it is the stand the gate
		# fills, and three frames of one stand is a comparison a judge can use
		# where eighteen frames of everything is a pile.
		if str(s["name"]) == "H-03-ramp-foot":
			for hour: String in ["golden", "night"]:
				await _shoot(camera, look, torch, false, eye, target,
					"H-03-ramp-foot-%s" % hour, written, failures, hour)

	# H-04 gate-mouth: on the ramp, looking S through the gate. Use the
	# stronghold's own ramp_foot/entrance marker plus a step up the slope
	# rather than a bare world guess, since the ramp's own rise is
	# self-derived from the ground (site.ramp_run is the only authored
	# number) and this stand needs to sit ON it, not beside it.
	if stronghold.has_method("has_marker") and bool(stronghold.call("has_marker", "entrance")):
		var entrance: Vector3 = stronghold.call("marker", "entrance")
		var outer_works: Vector3 = stronghold.call("marker", "outer_works")
		var toward := (outer_works - entrance)
		toward.y = 0.0
		toward = toward.normalized()
		var eye4 := entrance + toward * 34.0 + Vector3(0.0, 1.7, 0.0)
		var target4 := eye4 + toward * 20.0
		await _shoot(camera, look, torch, false, eye4, target4, "H-04-gate-mouth", written, failures)

	# H-07 courtyard: inside, at the courtyard trainer, looking S.
	if stronghold.has_method("has_marker") and bool(stronghold.call("has_marker", "trainer_stronghold_courtyard")):
		var trainer_at: Vector3 = stronghold.call("marker", "trainer_stronghold_courtyard")
		var eye7 := trainer_at + Vector3(0.0, 1.7, -2.0)
		var target7 := trainer_at + Vector3(0.0, 1.4, 10.0)
		await _shoot(camera, look, torch, true, eye7, target7, "H-07-courtyard", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), _out_dir])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
	quit(0 if failures.is_empty() else 1)


func _shoot(camera: Camera3D, look: Node, torch: OmniLight3D, interior: bool,
		eye: Vector3, target: Vector3, name_value: String,
		written: Array[String], failures: Array[String], hour: String = "day") -> void:
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	torch.visible = interior
	torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
	for i in 8:
		await physics_frame
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", hour)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name_value)
		return
	var path := "%s/%s.png" % [_out_dir, name_value]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name_value)
		return
	written.append(path)
	print("  %-28s -> %s" % [name_value, path])
