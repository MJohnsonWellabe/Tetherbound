extends SceneTree

## THE GROUND ITSELF. Every other survey in this repo photographs something
## standing ON the ground -- a creature, a building, a signpost, a corridor
## viewpoint framed at a distant landmark. The standing blind critique's #1
## ranked gap is emptiness: "60-90% of most frames is one flat green terrain
## material with confetti scatter" -- and the ground is the single largest
## share of pixels in every frame the game ever shows a player. Nothing else
## in tools/ points a camera DOWN at the near field and holds it there, or
## cycles every weather and time-of-day state at a fixed ground viewpoint, or
## looks at the water itself rather than past it.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_ground_and_sky.gd
##
## NEVER `--headless` with a real rendering driver: verified 2026-08-22 (see
## ralph/conventions.md, "Art pipeline traps") that the combination hangs
## forever with no error, no crash, no partial output -- and leaves a zombie
## Godot process burning CPU after the lane that started it gives up. Always
## `xvfb-run` for the virtual display, `--rendering-driver opengl3` for a real
## renderer, and no `--headless` flag at all.
##
## FOUR CORRECTIONS REUSED FROM tools/_probe_corridor_survey.gd, because that
## tool is the union of several earlier tools' hard-won bugs and this one
## needs all of them too:
##
## 1. Pin the clock AND FREEZE both WorldLook/WorldWeather -- a pin that is
##    not frozen wears off across a multi-viewpoint pass and the later frames
##    come back in a dusk wash under whatever weather rolled underneath.
## 2. Hand the capture CAMERA to Terrain3D (`terrain.set_camera(camera)`), or
##    the frames are of whatever coarse LOD reached wherever the gameplay rig
##    last parked, not the streamed ground under the actual shot.
## 3. Reseat on the REAL collision surface (`_surface()`), never the analytic
##    heightfield alone -- the two disagree by up to 22m near the river
##    channel, and seating a camera on the analytic value can bury it inside
##    the terrain and photograph the underside of the ground.
## 4. VISUAL-CORRIDOR fix: step the seat aside with `_clear_of_bodies()`
##    before placing the player at an authored coordinate -- an authored
##    ground/bank point can land dead-centre on an NPC capsule or a
##    scattered rock prop's collider, and a player capsule spawned centred
##    on another body has no lateral escape vector, so Godot's depenetration
##    shoves it straight UP the shared axis instead of sideways. See
##    `_clear_of_bodies`'s own comment (ported from corridor's, which
##    diagnosed this first) for the full mechanism.
##
## What this tool does NOT need from that one: corridor's SETTLE_FRAMES exists
## so the encounter director can populate wild creatures around a player who
## just arrived -- this tool is not a creature census, so it settles only
## long enough for Terrain3D's own region stream and collision to resolve.
##
## FREEZE-ONCE, NOT FREEZE-PER-PRESET. _probe_corridor_survey.gd's own _pin()
## briefly UNFREEZES WorldLook/WorldWeather to call apply_time()/set_weather()
## and waits 30 frames before freezing again, once per time-of-day. That
## dance is not needed here: apply_time() and set_weather() are ordinary
## direct method calls that do not read `_process` state to take effect (read
## scripts/world/world_look.gd::apply_time and world_weather.gd::set_weather
## -- both write node properties immediately, not through a per-frame tween).
## So this tool freezes BOTH nodes exactly once, right after boot, and then
## calls apply_time()/set_weather() directly for every subsequent state --
## which is a STRICTER reading of "freeze before framing anything, and
## re-apply after" than corridor's own dance: nothing here ever risks drifting
## between calls, because nothing is ever unfrozen again. The one thing that
## genuinely depends on a live `_process` tick -- WorldWeather's rain box
## re-centring on the player (`_follow_player`) -- is called BY HAND after
## every `set_weather()`, the same fix tools/capture_weather.gd already
## shipped for the same reason.
##
## THE WATER-HAZARD TRAP THIS TOOL DELIBERATELY AVOIDS. tools/capture_water.gd
## parks the player 500m straight down when a viewpoint carries no `actor` key
## ("Parked straight down from the eye ... see tools/survey.gd's _place_actor
## for why never far outside the world"), on the theory that 500m below
## ground is safely outside the streamed world. It is not outside the WATER
## HAZARD check (data/config/water_hazard.json, scripts/world/water.gd):
## submersion is judged on the player's own head depth below the water
## surface with no floor on how far below counts, so a body parked 500m under
## a pond reads as fully submerged and the drowning vignette can paint the
## whole capture red. This tool's `_place()` NEVER parks the player away from
## the real ground -- every single shot, ground or water, stands the trainer
## on real surface at `ground + 0.4`, in frame, as the 1.80m ruler every shot
## needs anyway.
##
## MEASURED FRAME BUDGET, not guessed -- corridor's own header already proved
## the mistake of guessing here: every awaited frame is a full software render
## under llvmpipe, ~2.4s at 1280x800, independent of how light the requested
## frame is. So the arithmetic:
##
##   BOOT (once)                                    90 frames
##   8 viewpoints x (ARRIVE 15 + REFRAME 15)         240 frames
##     (5 ground bands + pond + river + stream)
##   24 shots total:
##     15 ground time-of-day shots (day/golden/night x 5 bands)
##       x (STATE_SETTLE 6 + POSE 3)                 135 frames
##     3 extra weather shots at one fixed ground
##     viewpoint (cloudy/fog/rain; day+clear already
##     covered by that viewpoint's own day shot)
##       x (STATE_SETTLE 6 + POSE 3)                  27 frames
##     1 reset to day/clear before the water section
##       x STATE_SETTLE 6                              6 frames
##     3 water-eye shots (pond/river/stream)
##       x POSE 3                                      9 frames
##     3 water-grazing shots (camera reposition only)
##       x (GRAZE_SETTLE 4 + POSE 3)                   21 frames
##   TOTAL                                          528 frames
##
## 528 * 2.4s ~= 1267s ~= 21.1 minutes. Under the 25-minute target with real
## margin for JSON parsing, world instantiation and script overhead outside
## the awaited-frame count (corridor's own header measured that overhead at
## well under a minute for a heavier 143,630-prop world stand-up).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/ground"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 15     # analytic seat -> let Terrain3D stream the region
const REFRAME_FRAMES := 15    # real-surface reseat -> let collision settle
const STATE_SETTLE_FRAMES := 6  # after apply_time()/set_weather(), before posing
const GRAZE_SETTLE_FRAMES := 4  # camera-only reposition for the grazing shot
const POSE_FRAMES := 3
const FOV := 70.0

## Ground framing: NOT a horizon shot. The camera stands close behind the
## player and aims at a NEAR point on the ground ahead (target height 0, not
## the "aim at the far subject's head" convention every other survey camera
## in this repo uses) -- exactly the half of frame a walking player actually
## looks at and a corridor/horizon viewpoint never shows.
const GROUND_BACK := 2.2   # camera metres behind the player
const GROUND_UP := 2.0     # camera metres above the ground
const GROUND_AHEAD := 4.5  # how far ahead of the player the ground target sits
const GROUND_TARGET_H := 0.0

## Water framing shares one shape for all three bodies: PLAYER stands on the
## dry bank throughout (never moved, so the ruler and the water-hazard safety
## both hold across both shots); the CAMERA repositions between the two.
const WATER_BACK := 2.0     # eye-height camera, back from the bank
const WATER_UP := 1.85
const GRAZE_TOWARD_WATER := 1.0   # camera steps this far toward the water, never past the bank
const GRAZE_TANGENT := 22.0       # grazing shot looks ALONG the shore, not across it

## Five bands, one ground-down eye per band, reusing the same corridor-band
## eye/aim pairs _probe_corridor_survey.gd already proved sit on real ground
## (its own per-shot collision-raycast log is the evidence) -- `aim` here
## only supplies the walking DIRECTION; the actual look target is much
## nearer than that corridor tool's own horizon-framed target.
##
## VISUAL-CORRIDOR fix (2026-08-23): band3's entry used to carry
## `Vector2(230.0, 3670.0) -> Vector2(350.0, 3760.0)` under the name
## "river-lock" -- but that exact coordinate pair is
## `_probe_corridor_survey.gd::VIEWPOINTS`' own `"05-band3-relay"` entry, a
## Team Tether checkpoint (a campfire, crates, a red flag, a "Relay Approach
## Loop" signpost -- confirmed directly in `shots/ground/ground-03-band3-
## river-lock-day.png`), nowhere near water. `band3_the_river_lock/`'s own
## directory name is the region's title, not a literal landmark, so this
## survey needs to reach the region's actual river feature -- that is
## corridor's OWN separate, correctly-named `"06-band3-crossing"` entry
## (`Vector2(-152.0, 4170.0) -> Vector2(-100.0, 4350.0)`, sitting right on
## `terrain_playground.json`'s river course at the Old Mill Crossing narrows,
## course index 8: `[-152, 4203]`). This was a copy-paste of the wrong one of
## corridor's two band3 viewpoints, not a bad coordinate invented from
## scratch -- swapped in here rather than picking a third point, and the
## label renamed to match corridor's own name for it so nothing calls a
## relay checkpoint a river again.
const GROUND_VIEWPOINTS := [
	["ground-01-band1-opening",   Vector2(8.0, 90.0),      Vector2(-40.0, 180.0)],
	["ground-02-band2-stone-root", Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	["ground-03-band3-crossing",  Vector2(-152.0, 4170.0), Vector2(-100.0, 4350.0)],
	["ground-04-band4-ironwood",   Vector2(170.0, 5590.0), Vector2(450.0, 5860.0)],
	["ground-05-band5-approach",   Vector2(0.0, 7000.0),   Vector2(0.0, 7560.0)],
]

## Index into GROUND_VIEWPOINTS that also carries the weather sweep -- band 2,
## `density_scale` 0.05 in vegetation.json's corridor_bands, ordinary
## mid-corridor ground rather than a set piece. Weather is shot at ONE
## viewpoint on purpose (the task's own instruction): every other axis held
## fixed so the four presets differ in exactly one variable.
const WEATHER_VIEWPOINT_INDEX := 1

## [suffix, time-of-day name, weather preset name]. "day"+"clear" is shot as
## part of GROUND_STATES for every band; WEATHER_STATES supplies the three
## non-clear presets so nothing is captured twice.
const GROUND_STATES := [
	["day", "day", "clear"],
	["golden", "golden", "clear"],
	["night", "night", "clear"],
]
const WEATHER_STATES := [
	["cloudy", "day", "cloudy"],
	["fog", "day", "fog"],
	["rain", "day", "rain"],
]

var _config: Dictionary = {}
var _field: RefCounted = null
var _world: Node = null
var _camera: Camera3D = null
var _player: Node3D = null
var _look: Node = null
var _weather: Node = null
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_config = HEIGHTFIELD.load_config()
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[ground] world up, boot settled; starting ground and water capture")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	# Once, deep: catch every CanvasLayer the world built during `_ready` --
	# corridor's own lesson (Band 5 round 1 burned the HUD into all twelve
	# frames because the shallow per-frame hide missed a layer built later).
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("FAIL no Player node; every shot would have no 1.80m ruler in it")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	else:
		print("FAIL no Terrain.set_camera(); frames would be of whatever LOD reaches the eye")

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	if _look == null:
		print("FAIL no WorldLook node; time-of-day cannot be pinned")
	if _weather == null:
		print("FAIL no WorldWeather node; weather cannot be pinned")

	# Pin to day/clear and freeze both immediately -- see header for why this
	# tool freezes ONCE rather than per-preset. No settle wait needed here:
	# the first shot at the first viewpoint carries its own STATE_SETTLE_FRAMES.
	if _weather != null:
		_weather.call("set_weather", "clear")
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.call("apply_time", "day")
		_look.set_process(false)
		_look.set_physics_process(false)

	for band_index in GROUND_VIEWPOINTS.size():
		var entry: Array = GROUND_VIEWPOINTS[band_index]
		var pos := await _arrive_ground(entry)
		for state: Variant in GROUND_STATES:
			await _shoot_ground_state(pos, state as Array)
		if band_index == WEATHER_VIEWPOINT_INDEX:
			for state: Variant in WEATHER_STATES:
				await _shoot_ground_state(pos, state as Array)

	# Reset to day/clear before the water section -- the last ground state
	# shot may have left the world at night, in rain, or both.
	_apply_state("day", "clear")
	for i in STATE_SETTLE_FRAMES:
		await physics_frame

	await _capture_pond()
	await _capture_river()
	await _capture_stream()

	print("")
	print("ground and water capture written to %s" % OUT_DIR)
	print("Software rendering under the Compatibility renderer: composition,")
	print("density and silhouette are trustworthy; frame times are not a")
	print("performance measurement.")

	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Reseat the clock/weather each call so a state does not silently inherit
## whatever the previous shot left running -- both nodes stay frozen the
## whole time (see header), so this is the ONLY thing that ever changes them.
func _apply_state(time_name: String, weather_name: String) -> void:
	if _look != null:
		_look.call("apply_time", time_name)
	if _weather != null:
		_weather.call("set_weather", weather_name)
		# WorldWeather is frozen, so its own _process (which normally
		# re-centres the rain ring on the player every tick) never runs.
		# Without this explicit call a "rain" shot renders drops wherever
		# the ring last followed the player to -- likely the spawn point,
		# hundreds of metres from wherever this shot actually stands.
		# tools/capture_weather.gd already paid for this exact bug.
		_weather.call("_follow_player")


## ---------------------------------------------------------------------
## GROUND
## ---------------------------------------------------------------------

func _arrive_ground(entry: Array) -> Dictionary:
	var name: String = str(entry[0])
	var eye_xz: Vector2 = entry[1]
	var aim_xz: Vector2 = entry[2]
	var forward := (aim_xz - eye_xz).normalized()
	# VISUAL-CORRIDOR fix: two of these authored eye coordinates land dead-
	# centre on a captain NPC's own capsule collider -- `captain_field` at
	# (170, 5590) is this file's own "ground-04-band4-ironwood" eye, and
	# `captain_ridge` at (-280, 6460) (`data/config/bands/
	# band4_upper_meadows_ironwood/trainers.json`) is close enough to
	# band4's own AHEAD-projected target/camera path to graze the same body.
	# `tools/_probe_corridor_survey.gd`'s own header already diagnosed the
	# exact failure this produces: a player capsule spawned centred on
	# another capsule has no lateral escape vector, so Godot's depenetration
	# shoves it straight UP the shared axis instead of sideways -- "the
	# trainer standing on the NPC's head" a blind critic saw in all three
	# band-4 ground frames. Stepping the seat aside before framing (same
	# `_clear_of_bodies` that tool already proved) fixes the HARNESS choosing
	# an occupied seat; it is not a game bug to route around any other way.
	eye_xz = _clear_of_bodies(eye_xz, forward, _surface(eye_xz))
	var cam_xz := eye_xz - forward * GROUND_BACK
	var target_xz := eye_xz + forward * GROUND_AHEAD

	# Pass one: the analytic seat, so Terrain3D has somewhere to stream to.
	# There is no collision to raycast against until the camera already
	# stands there.
	_place(eye_xz, _field.height_at(eye_xz.x, eye_xz.y))
	_frame_ground(cam_xz, _field.height_at(cam_xz.x, cam_xz.y),
		target_xz, _field.height_at(target_xz.x, target_xz.y))
	for i in ARRIVE_FRAMES:
		await physics_frame

	# Pass two: reseat on the surface that actually arrived.
	var eye_ground := _surface(eye_xz)
	_place(eye_xz, eye_ground)
	_frame_ground(cam_xz, _surface(cam_xz), target_xz, _surface(target_xz))
	for i in REFRAME_FRAMES:
		await physics_frame

	print("[ground] arrived %-28s eye(%.0f, %.1f, %.0f)" % [name, eye_xz.x, eye_ground, eye_xz.y])
	return {"name": name, "eye_xz": eye_xz, "cam_xz": cam_xz, "target_xz": target_xz}


func _shoot_ground_state(pos: Dictionary, state: Array) -> void:
	var suffix: String = str(state[0])
	var time_name: String = str(state[1])
	var weather_name: String = str(state[2])
	_apply_state(time_name, weather_name)
	for i in STATE_SETTLE_FRAMES:
		await physics_frame
	_hide_huds()

	var cam_xz: Vector2 = pos["cam_xz"]
	var target_xz: Vector2 = pos["target_xz"]
	_frame_ground(cam_xz, _surface(cam_xz), target_xz, _surface(target_xz))
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	_capture("%s-%s" % [pos["name"], suffix])


func _frame_ground(cam_xz: Vector2, cam_ground: float, target_xz: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(cam_xz.x, cam_ground + GROUND_UP, cam_xz.y)
	_camera.look_at(Vector3(target_xz.x, target_ground + GROUND_TARGET_H, target_xz.y), Vector3.UP)


## ---------------------------------------------------------------------
## WATER -- pond, river, stream. Player parked on the dry bank throughout;
## the camera alone moves between the eye and grazing shots.
## ---------------------------------------------------------------------

func _capture_pond() -> void:
	var water_cfg: Dictionary = _config.get("water", {})
	var centre_arr: Array = water_cfg.get("pond_centre", [-395.0, 545.0])
	if centre_arr.size() < 2:
		_failures.append("pond: no water.pond_centre in terrain_playground.json")
		print("FAIL pond: no water.pond_centre in terrain_playground.json")
		return
	var centre := Vector2(float(centre_arr[0]), float(centre_arr[1]))
	var level := float(water_cfg.get("level", -17.0))
	var bank := _shore_point(centre, Vector2(0.0, -1.0), level)

	var pos := await _arrive_water("water-01-pond", bank, centre)
	await _shoot_water_eye(pos)
	await _shoot_water_grazing(pos, level)


func _capture_river() -> void:
	var river_cfg: Dictionary = _config.get("river", {})
	var course: Array = river_cfg.get("course", [])
	if course.size() < 3:
		_failures.append("river: no usable river.course in terrain_playground.json")
		print("FAIL river: no usable river.course in terrain_playground.json")
		return

	# An interior point, well clear of both ends and of the Old Mill Crossing
	# narrows (SE22) -- an open reach of channel, not the one place the
	# river is deliberately pinched to a footbridge's width.
	#
	# VISUAL-CORRIDOR fix: `course.size() / 2` was the actual index picker,
	# and for this file's own 19-point course that integer-divides to 9 --
	# `[-152, 4203], half_width 3.6`, dead centre of the SAME Old Mill
	# Crossing narrows this comment already says to avoid (course indices
	# 6-10 all pinch to half_width 3.6-7.0, against 10-13 everywhere else).
	# A blind critic saw the result: "water-02-river-grazing contains NO
	# water at all -- it is a grass hillside and the top of a building" (the
	# Mill itself, whose barrels/crates are also what "water-02-river-eye"
	# ends up staring at instead of open water). The comment's own intent
	# was always "widest reach nearest the middle", never "the middle
	# index" -- so pick by width now: the interior point with the largest
	# `half_width`, ties broken toward whichever is closer to the course's
	# midpoint index, which keeps the "an open reach... not the narrows"
	# reasoning true regardless of how this JSON's own point spacing changes
	# later.
	var mid := course.size() / 2
	var idx := clampi(mid, 1, course.size() - 2)
	var best_width := -1.0
	for i in range(1, course.size() - 1):
		var w := float((course[i] as Dictionary).get("half_width", 10.0))
		if w > best_width or (is_equal_approx(w, best_width) and absi(i - mid) < absi(idx - mid)):
			best_width = w
			idx = i
	var at_pt: Dictionary = course[idx]
	var prev_pt: Dictionary = course[idx - 1]
	var next_pt: Dictionary = course[idx + 1]
	var at_arr: Array = at_pt.get("at", [])
	var prev_arr: Array = prev_pt.get("at", [])
	var next_arr: Array = next_pt.get("at", [])
	if at_arr.size() < 2 or prev_arr.size() < 2 or next_arr.size() < 2:
		_failures.append("river: malformed course entry at index %d" % idx)
		print("FAIL river: malformed course entry at index %d" % idx)
		return

	var centre := Vector2(float(at_arr[0]), float(at_arr[1]))
	var flow_dir := (Vector2(float(next_arr[0]), float(next_arr[1]))
		- Vector2(float(prev_arr[0]), float(prev_arr[1]))).normalized()
	var perp := Vector2(-flow_dir.y, flow_dir.x)
	var half_width := float(at_pt.get("half_width", 10.0))
	var rim := float(at_pt.get("rim", 5.0))
	# Well past the rim's own fade so the bank is undisturbed ground, not the
	# carve's own steep shoulder.
	var bank := centre + perp * (half_width + rim + 6.0)
	var level := float(river_cfg.get("water_level", -9.0))

	var pos := await _arrive_water("water-02-river", bank, centre)
	await _shoot_water_eye(pos)
	await _shoot_water_grazing(pos, level)


func _capture_stream() -> void:
	var stream_cfg: Dictionary = _config.get("water", {}).get("stream", {})
	var points: Array = stream_cfg.get("points", [])
	if points.size() < 3:
		_failures.append("stream: no usable water.stream.points in terrain_playground.json")
		print("FAIL stream: no usable water.stream.points in terrain_playground.json")
		return

	var idx := clampi(points.size() / 2, 1, points.size() - 2)
	var at_arr: Array = points[idx]
	var prev_arr: Array = points[idx - 1]
	var next_arr: Array = points[idx + 1]
	if at_arr.size() < 2 or prev_arr.size() < 2 or next_arr.size() < 2:
		_failures.append("stream: malformed point entry at index %d" % idx)
		print("FAIL stream: malformed point entry at index %d" % idx)
		return

	var centre := Vector2(float(at_arr[0]), float(at_arr[1]))
	var flow_dir := (Vector2(float(next_arr[0]), float(next_arr[1]))
		- Vector2(float(prev_arr[0]), float(prev_arr[1]))).normalized()
	var perp := Vector2(-flow_dir.y, flow_dir.x)
	var half_width := float(stream_cfg.get("width", 2.4)) * 0.5 + float(stream_cfg.get("shoulder", 1.2))
	# The stream carries no flat `water_level` the way the pond/river do (its
	# surface is a ribbon riding a fixed depth above the carved bed) -- the
	# analytic ground height at its own centreline is the honest stand-in for
	# "roughly where the water sits" when posing the grazing camera below.
	var level := float(_field.height_at(centre.x, centre.y))
	var bank := centre + perp * (half_width + 6.0)

	var pos := await _arrive_water("water-03-stream", bank, centre)
	await _shoot_water_eye(pos)
	await _shoot_water_grazing(pos, level)


func _arrive_water(name: String, bank: Vector2, look_at_xz: Vector2) -> Dictionary:
	var toward := (look_at_xz - bank).normalized()
	if toward == Vector2.ZERO:
		toward = Vector2(0.0, 1.0)
	# VISUAL-CORRIDOR fix: the same occupied-seat hazard `_arrive_ground`
	# steps around (see its own comment) -- but here the blocker is as
	# likely to be a scattered rock/harvest-point prop as an NPC capsule.
	# `_clear_of_bodies` already excludes only Terrain3D's own collision,
	# never a specific body TYPE, so it catches both for free. This is the
	# confirmed cause of "water-03-stream-eye has the camera at the
	# trainer's side while he reaches into a giant unlit near-black
	# box-rock": the authored stream `bank` point lands close enough to a
	# scattered boulder prop that the player's own capsule ends up touching
	# it, the same way a ground viewpoint could land on an NPC.
	bank = _clear_of_bodies(bank, toward, _surface(bank))
	var away := -toward
	var cam_xz := bank + away * WATER_BACK

	_place(bank, _field.height_at(bank.x, bank.y))
	_pose_water_eye(cam_xz, _field.height_at(cam_xz.x, cam_xz.y),
		look_at_xz, _field.height_at(look_at_xz.x, look_at_xz.y))
	for i in ARRIVE_FRAMES:
		await physics_frame

	var bank_ground := _surface(bank)
	_place(bank, bank_ground)
	_pose_water_eye(cam_xz, _surface(cam_xz), look_at_xz, _surface(look_at_xz))
	for i in REFRAME_FRAMES:
		await physics_frame

	print("[ground] arrived %-28s bank(%.0f, %.1f, %.0f)" % [name, bank.x, bank_ground, bank.y])
	return {"name": name, "bank": bank, "cam_xz": cam_xz, "look_at": look_at_xz, "away": away}


func _shoot_water_eye(pos: Dictionary) -> void:
	_hide_huds()
	var cam_xz: Vector2 = pos["cam_xz"]
	var look_at_xz: Vector2 = pos["look_at"]
	_pose_water_eye(cam_xz, _surface(cam_xz), look_at_xz, _surface(look_at_xz))
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	_capture("%s-eye" % pos["name"])


## Camera only, close to the surface, angled ALONG the shore instead of
## across it -- the framing an eye-height shot cannot give, and the one that
## actually shows the grass/water edge transition an earlier critique named
## ("hard grass-water edges", "resort-turquoise pond water against a dusk
## sky"). The player never moves from the bank the eye shot already reseated.
func _shoot_water_grazing(pos: Dictionary, level: float) -> void:
	var bank: Vector2 = pos["bank"]
	var away: Vector2 = pos["away"]
	var look_at_xz: Vector2 = pos["look_at"]
	var tangent := Vector2(-away.y, away.x)
	var graze_xz: Vector2 = bank - away * GRAZE_TOWARD_WATER
	var graze_ground := _surface(graze_xz)
	# Never below the real ground under the camera, never far above the
	# water plane either -- a grazing shot standing head-height above the
	# surface is just the eye shot again.
	var cam_h: float = maxf(level + 0.35, graze_ground + 0.15)

	# VISUAL-CORRIDOR fix: `tangent` used to pick ONE fixed 90-degree
	# rotation of `away` with no way to know whether THAT side of the shore
	# stays wet for the next `GRAZE_TANGENT` metres or curves inland -- a
	# blind critic caught the failure on the pond ("almost no water -- a
	# sliver in the far right corner") and the river (no water at all).
	# `_surface()` already answers "is this point wet": water itself carries
	# no collision, so a raycast over the water body hits the carved BED
	# below `level`, while dry ground reads at or above it. Try both
	# along-shore directions and keep whichever lands lower (wetter) at the
	# full distance, rather than trusting a single blind rotation.
	var far_pos := bank + tangent * GRAZE_TANGENT
	var far_neg := bank - tangent * GRAZE_TANGENT
	if _surface(far_neg) < _surface(far_pos):
		tangent = -tangent
	var target_far: Vector2 = bank + tangent * GRAZE_TANGENT
	# Even the wetter side can still curve away over that stretch (a bend,
	# an inlet) -- blending 35% of the way back toward the water's own
	# centre keeps the water body the actual subject of the shot without
	# giving up the shallow, along-the-shore angle that makes this framing
	# different from the eye shot (a full blend TO centre would just be the
	# eye shot again).
	var target_xz: Vector2 = target_far.lerp(look_at_xz, 0.35)
	var target_ground := _surface(target_xz)

	_hide_huds()
	_camera.global_position = Vector3(graze_xz.x, cam_h, graze_xz.y)
	_camera.look_at(Vector3(target_xz.x, maxf(level, target_ground), target_xz.y), Vector3.UP)
	for i in GRAZE_SETTLE_FRAMES:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	_capture("%s-grazing" % pos["name"])


func _pose_water_eye(cam_xz: Vector2, cam_ground: float, target_xz: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(cam_xz.x, cam_ground + WATER_UP, cam_xz.y)
	_camera.look_at(Vector3(target_xz.x, target_ground + 1.0, target_xz.y), Vector3.UP)


## Analytic search outward from `centre` along `dir` for the first point at
## or above `level` (plus a small margin so the result is solidly on dry
## ground, not right at the waterline's own edge). Mirrors
## tools/capture_water.gd's `_shore_point`, which this reuses because it is
## already the proven mechanism for finding a pond bank from config alone.
func _shore_point(centre: Vector2, dir: Vector2, level: float) -> Vector2:
	var d := dir.normalized()
	for distance in range(1, 251):
		var candidate := centre + d * float(distance)
		if float(_field.height_at(candidate.x, candidate.y)) >= level + 0.3:
			return candidate
	return centre + d * 80.0


## ---------------------------------------------------------------------
## SHARED
## ---------------------------------------------------------------------

func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


## The analytic heightfield and the streamed collision surface disagree -- by
## nearly 3m on ordinary ground and up to 22m near the river channel.
## Seating a camera or the player on the analytic value can bury them inside
## the terrain wherever the real ground is higher, and what comes back is the
## UNDERSIDE of the ground. Raycast, and say so out loud when the ray misses.
func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("  WARN no collision under (%.0f, %.0f); analytic %.2f may be under the surface" % [
			at.x, at.y, analytic])
		return analytic
	return float((hit["position"] as Vector3).y)


## Ported from `tools/_probe_corridor_survey.gd::_clear_of_bodies` (see that
## file's own header comment for the full diagnosis) rather than duplicated
## by rewriting: this harness places the player at an authored `eye_xz` the
## same way corridor's `_shoot` places it at an authored `eye`, so the same
## occupied-seat failure and the same fix apply unchanged. Steps the seat
## sideways, perpendicular to the walking direction, until the player's own
## capsule footprint is clear of any body that is not Terrain3D's own
## collision (a slope graze is not an occupied seat).
func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return eye
	var aside := Vector2(-toward.y, toward.x).normalized()
	for attempt in 4:
		var candidate := eye if attempt == 0 else eye + aside * 2.0 * float(attempt)
		var query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.6
		capsule.height = 2.6
		query.shape = capsule
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.3, candidate.y))
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if _player != null:
			query.exclude = [_player.get_rid()]
		var blocker := ""
		for hit: Dictionary in space.intersect_shape(query, 4):
			var body: Node = hit.get("collider") as Node
			if body == null or _under_terrain(body):
				continue
			blocker = body.name
			break
		if blocker == "":
			if attempt > 0:
				print("  NOTE (%.0f,%.0f) was occupied by an NPC body; landing moved %.1fm aside" % [
					eye.x, eye.y, (candidate - eye).length()])
			return candidate
	return eye


## Terrain3D's own collision is a StaticBody3D too, and the occupancy
## capsule's lower edge can graze a slope. Only a body OUTSIDE the Terrain
## node counts as something worth stepping around.
func _under_terrain(body: Node) -> bool:
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		return false
	var node: Node = body
	while node != null:
		if node == terrain:
			return true
		node = node.get_parent()
	return false


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _capture(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		print("FAIL %s: save_png failed" % name)
		return
	print("  %-28s -> %s" % [name, path])


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
