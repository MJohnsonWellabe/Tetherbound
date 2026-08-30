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
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/hall0830"
const SETTLE_FRAMES := 90
const POSE_FRAMES := 10
const FOV := 70.0

func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


var _out_dir := DEFAULT_OUT_DIR
## Stand-name substrings to restrict this run to; empty means every stand.
var _only: Array[String] = []


## Does this stand run? Empty `--only` means yes, as it always did.
func _wanted(name_value: String) -> bool:
	if _only.is_empty():
		return true
	for want: String in _only:
		if name_value.contains(want):
			return true
	return false


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
		elif a.begins_with("--only="):
			# Re-shoot named stands without re-running the whole set. A full pass
			# is ~45 minutes of software GL, and a single stand that came back
			# degraded should not cost that -- which is exactly the situation
			# that motivated this: `H-03-ramp-foot` needed one re-shoot after the
			# streaming fix and the other ten frames were already good. Substring
			# match, so `--only=H-03` catches the stand and its golden/night
			# variants together.
			for name in a.substr("--only=".length()).split(",", false):
				_only.append(name.strip_edges())
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

	# T1-HALL-REBUILD: the player is HIDDEN and frozen, but it is NOT parked
	# 4km away any more. `grass_field.gd` builds its tuft ring around the
	# player (72m radius, its own build log says so) and Terrain3D's streaming
	# bubble follows it too, so parking the player in Band 2 while shooting the
	# Hall at z 7560 renders every stand on bare far-cover ground with no grass
	# geometry in it at all -- which is exactly the "no grass plus a milky
	# haze" capture defect this harness is known for. `perf_render_stats.gd`
	# already solved it the same way and says so in its own comment: the player
	# goes where the camera goes. `_shoot` moves it per stand.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
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
		# T1-HALL-3: 7395 stood 5m off the gate, which was fine while the gate
		# was a fence and stopped being fine the moment D4 gave it 6.2m piers --
		# the first frame with them in it has the piers cut off by the top edge
		# and eating both sides, with the Hall (what this stand is FOR: "full
		# massing, three tiers, cable landing", design sec10) reduced to a slot
		# between them. Backed off to 22m, where the gate frames the Hall
		# instead of replacing it. Same bearing, same eye height, same subject.
		{"name": "H-02-sigil-gate", "at": Vector2(63.6, 7378.0), "eye_h": 1.7,
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
		await _shoot(camera, look, torch, false, eye, target, str(s["name"]), written, failures, "day", player)
		# Design §10: the gate face is the SHADED face at the day keyframe, so
		# its self-lit dusk/night read is part of the design and has to be
		# judged too. Only H-03 gets the variants -- it is the stand the gate
		# fills, and three frames of one stand is a comparison a judge can use
		# where eighteen frames of everything is a pile.
		if str(s["name"]) == "H-03-ramp-foot":
			for hour: String in ["golden", "night"]:
				await _shoot(camera, look, torch, false, eye, target,
					"H-03-ramp-foot-%s" % hour, written, failures, hour, player)

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
		# T1-HALL-3 / JUDGE-5 D1. This stand walks 34m UP the causeway, and the
		# causeway climbs ~9m over its 40m run -- but the eye height was taken
		# from `entrance`, which is the ramp FOOT. Every H-04 ever captured was
		# therefore shot from ~7m inside the slab, which is exactly what the
		# frame shows: cobble underside below, grass seen edge-on from beneath
		# the ground above, and the gate nowhere in it. The deck height is
		# sampled from the real ground at build time, so it cannot be re-derived
		# here -- ask the stronghold where its own walking surface is.
		# 34m up a 40m causeway put the eye 6m off the sill, and the first
		# correctly-exposed frame of this stand showed why that is too close:
		# the gate fills the frame edge to edge and the "four-plane stack" the
		# design asks this stand to prove (yard floor -> camp -> far wall ->
		# keep above) is cropped down to two. 24m leaves 16m of run in front of
		# the camera, so the gatehouse reads as a threshold being approached
		# rather than as a passage already entered.
		var eye4 := entrance + toward * 24.0
		eye4.y = float(stronghold.call("causeway_surface_y", eye4.x, eye4.z)) + 1.7
		# Look level and slightly UP the remaining climb rather than at a point
		# 20m dead ahead on the old (buried) eye plane: the gate sill is above
		# the stand, and a level aim put the arch's head out of frame.
		var target4 := eye4 + toward * 20.0
		target4.y = float(stronghold.call("causeway_surface_y", target4.x, target4.z)) + 4.0
		await _shoot(camera, look, torch, false, eye4, target4, "H-04-gate-mouth", written, failures, "day", player)

	# H-07 courtyard: inside, at the courtyard trainer, looking S.
	if stronghold.has_method("has_marker") and bool(stronghold.call("has_marker", "trainer_stronghold_courtyard")):
		var trainer_at: Vector3 = stronghold.call("marker", "trainer_stronghold_courtyard")
		var eye7 := trainer_at + Vector3(0.0, 1.7, -2.0)
		var target7 := trainer_at + Vector3(0.0, 1.4, 10.0)
		await _shoot(camera, look, torch, true, eye7, target7, "H-07-courtyard", written, failures, "day", player)

	print("")
	print("%d frames -> %s" % [written.size(), _out_dir])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
	quit(0 if failures.is_empty() else 1)


func _shoot(camera: Camera3D, look: Node, torch: OmniLight3D, interior: bool,
		eye: Vector3, target: Vector3, name_value: String,
		written: Array[String], failures: Array[String], hour: String = "day",
		player: Node3D = null) -> void:
	if not _wanted(name_value):
		return
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	# Carry the grass ring and the terrain bubble to the stand, then give them
	# real time to rebuild -- 8 frames was tuned for a camera that never moved
	# far from a parked player and is not enough for a 4km jump.
	if player != null:
		player.global_position = Vector3(eye.x, eye.y, eye.z)
	torch.visible = interior
	torch.global_position = eye + Vector3(0.0, 0.35, 0.0)
	# T1-HALL-3: 40 was still not enough, and the failure is quiet enough to be
	# worth naming. Two frames of THE SAME STAND in one run --
	# `H-03-ramp-foot` and `H-03-ramp-foot-golden`, identical camera, seconds
	# apart -- came back with 5.5% and 54.6% green cover on the same bank. The
	# first is not a content change and not a scatter edit: it is the grass ring
	# still rebuilding when the shutter opened. `capture_check` passes it,
	# because `_grass_problems` asks whether the field EXISTS, follows this
	# camera and holds instances -- all true of a field that is half-built. A
	# partially-streamed field is exactly the "silently degraded frame" that
	# file was written about, and it currently has no test for it; flagged in
	# the handover as the next thing that checker wants.
	#
	# The cheap half of the answer is here: give the ring real time. The
	# expensive half -- a stability poll on the field's own coverage -- belongs
	# in `capture_check` where every tool gets it, not in this one tool.
	# TWO settle passes with a real drawn frame between them, not one long one.
	# Frame count was never the lever: `H-03-ramp-foot` came back at 5.3% green
	# cover on a bank where `H-03-ramp-foot-golden` -- the very next shot, same
	# camera, same everything -- reads 53.6%. The variant succeeds because it is
	# the SECOND visit to that position, and what it is really waiting on is
	# Terrain3D streaming the region in: `grass_field`'s tufts are placed in a
	# shader off the live height and region maps, so until the region is
	# resident the field has nothing to stand on and quietly draws almost
	# nothing. Raising 40 -> 110 frames did not fix it; giving the stand a
	# second pass after a completed draw does.
	for pass_index in 2:
		for i in 60:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", hour)
	for i in POSE_FRAMES:
		await process_frame
	# T1-HALL-3. This tool shipped two rounds of evidence without ever calling
	# the checker that exists to catch exactly what was wrong with it.
	# `capture_check._embedded_problems` was WRITTEN by T1-STORMWALL in response
	# to the JUDGE-4 H-04-gate-mouth defect -- a camera buried in the ramp -- and
	# `_ground_problems` names that frame in its own failure text. Neither ever
	# ran here, so JUDGE-5 was handed the same broken frame a second time and
	# spent its top-ranked finding on it.
	#
	# `warn_only` rather than `require`: `require` quits the whole run on the
	# first problem, and this tool legitimately shoots one INTERIOR stand
	# (H-07, inside the courtyard) where the grass field is correctly absent.
	# Exterior stands promote any problem to a run failure, so the exit code
	# still refuses to call a degraded set "evidence"; the interior stand only
	# reports.
	# The player is EXPECTED to be inside the camera here: `_shoot` parks it at
	# the eye on purpose, so the grass ring and the terrain bubble stream to the
	# stand rather than staying wherever the gameplay rig was left. Declaring it
	# is what lets the embed check stay strict about everything else -- it now
	# walks several hits instead of reporting only the first, so "buried in the
	# ramp AND standing in the player" reports the ramp, which is the whole
	# point of running it here.
	var checked := CAPTURE_CHECK.warn_only(self, camera, "clear", null,
		[player] if player != null else [])
	for line: String in checked:
		if interior:
			print("[capture_check] (interior stand %s -- reported, not fatal)" % name_value)
		else:
			failures.append("%s: %s" % [name_value, line])

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
