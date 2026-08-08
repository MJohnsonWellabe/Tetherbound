extends SceneTree

## PHOTOGRAPH THE WHOLE GAME, IN ONE RUN, INTO ONE SHEET.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/capture_all.gd
##
##   ... --script tools/capture_all.gd -- world weather      # just those chapters
##
## Fifteen `tools/preview_*.gd` harnesses each photograph their own corner of the
## game, and every one of them is better at its corner than this file is. What
## none of them can do is put the whole game in front of one reviewer in one
## consistently-framed set, so that a round of criticism is about the GAME rather
## than about whichever system happened to be photographed that week — and so
## that the next round can be held against this one frame for frame.
##
## This runs the game. It does not pose a diorama of it: every frame below comes
## out of `meadows_playground.tscn` with the real scatter, the real terrain, the
## real creatures and the real UI, except for the three studio frames, which say
## so in their own names and exist because a scale comparison needs a controlled
## background.
##
## WHAT IT DELIBERATELY DOES NOT DO
##
##   * It does not fake a shot. Two things on the owner's list — GRANDPA and THE
##     DIALOGUE — do not exist in this project at all: there is no NPC, no
##     dialogue system and no quest code anywhere in `scripts/`. Grandpa's HOUSE
##     is authored geography and is photographed inside and out. The man and the
##     conversation are recorded as MISSING in the manifest, and nothing is put
##     in front of the camera to stand in for them.
##   * It does not change the game to make a shot easier. Nothing here writes to
##     a game script, a scene or a data file. Where a state could not be reached
##     through the game's own API, that is recorded as a finding instead.
##
## THE THREE RULES THIS FILE INHERITED THE HARD WAY
##
##   1. D06 — `--headless` disables rendering, so this must run under Xvfb, and
##      it must run on the COMPATIBILITY renderer: Terrain3D segfaults under
##      lavapipe. No SSAO, no volumetrics, no screen or depth texture reads.
##      Composition, silhouette, colour and framing are trustworthy here.
##      Lighting quality and frame times are not.
##   2. `tools/play_session.gd` — a frame must provably belong to THIS run. Two
##      sessions once wrote the same filenames and produced a set of eleven
##      correctly-numbered frames from two different games, caught only because
##      frame 10 was written before frame 09. So: the output directory is cleared
##      first, every write is verified on disk, and the manifest carries each
##      frame's size, sha256 and modification time.
##   3. `tools/preview_ceremony.gd` — a frame that captured nothing looks exactly
##      like a frame that captured something. Every frame is hashed and compared
##      against every other frame in the run, and a repeat is shouted about,
##      because that is how a harness pressing a button that never registered was
##      found.
##
## AND ONE MORE, FROM `docs/reviews/MA-04`: settle before you shoot. A skinned
## mesh in bind pose is not a silhouette anybody will ever see.
##
## THE HUD, PER SHOT. `tools/survey.gd` hides `PlaygroundHUD` and — because it
## predates the minimap — leaves the minimap drawing into the top right of every
## frame it takes. The choice here is explicit and recorded in the manifest:
##
##   * WORLD, WEATHER and STUDIO frames: no HUD at all. They are photographs of
##     a place, and a debug readout over a landscape is a photograph of a debug
##     readout.
##   * GAMEPLAY frames (creatures, combat, doors, home, menus): the minimap and
##     the combat HUD stay, because whether the fight reads with its own UI on it
##     is exactly the question. `PlaygroundHUD` is hidden even there — it is the
##     M1 movement telemetry, not shipping UI — except in one frame that exists
##     to show it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/review"

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const BODY_SCRIPT := preload("res://scripts/pals/pal_body.gd")
const CEREMONY := preload("res://scripts/pals/release_ceremony.gd")
const MOUNT := preload("res://scripts/pals/mount.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const GRID := preload("res://scripts/building/build_grid.gd")
const STATION := preload("res://scripts/building/station.gd")
const STRUCTURES := preload("res://scripts/building/structures.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const TETHER_DATA := preload("res://scripts/trainers/tether_data.gd")
const TETHER_ROSTER := preload("res://scripts/trainers/tether_roster.gd")
const TETHER_MODEL := preload("res://scripts/trainers/tether_trainer_model.gd")
const PLAYER_MODEL := preload("res://scripts/player/trainer_model.gd")

## Vertical FOV of the gameplay camera. The horizon maths depends on it.
const FOV := 70.0
## Where the true horizon lands by default, as a fraction of frame height from
## the top. `tools/survey.gd` explains why this is stated as a composition rather
## than as a rotation.
const DEFAULT_HORIZON := 0.30

## Ceiling on the boot wait, not a fixed wait. Terrain3D streams its regions,
## builds collision after that, the scatter runs, the doors are hung and the
## encounter director places 34 creatures — and how many frames that takes
## depends on the machine. `_boot` waits for the CONDITIONS and this is only the
## point at which it gives up and says so.
const BOOT_LIMIT := 1200
## Physics frames for a moved body to settle onto the ground.
const SETTLE_AFTER_MOVE := 14
## Rendered frames between posing and the shutter.
const POSE_FRAMES := 3

## How far below the camera's aim line a posed trainer is parked, as a fraction
## of the distance to them. `tools/survey.gd`'s number, kept so its five
## viewpoints frame the figure where they framed it before.
const ACTOR_CLEARANCE := 0.4

## The five fixed viewpoints from `tools/survey.gd`, COPIED VERBATIM so this
## round is comparable with MA-05's frame for frame. They are named after panels
## on `docs/reference/tetherbound-meadows-keyart.png`; changing one invalidates
## the comparison with every earlier sheet, so they are not changed here.
const SURVEY_VIEWPOINTS := [
	{
		"file": "01-world-spawn-outward", "was": "survey 01-spawn-outward",
		"eye": Vector2(0.0, 0.0), "eye_h": 2.2,
		"target": Vector2(150.0, 120.0), "target_h": 6.0,
		"time": "day", "horizon": 0.28, "actor": Vector2(9.0, 7.0),
	},
	{
		"file": "02-world-valley-floor", "was": "survey 02-valley-floor",
		"eye": Vector2(-120.0, 130.0), "eye_h": 2.2,
		"target": Vector2(40.0, 40.0), "target_h": 20.0,
		"time": "day", "horizon": 0.32, "actor": Vector2(-108.0, 118.0),
	},
	{
		"file": "03-world-rise-overlook", "was": "survey 03-rise-overlook",
		"eye": Vector2(148.0, -102.0), "eye_h": 11.0,
		"target": Vector2(-60.0, 60.0), "target_h": 0.0,
		"time": "day", "horizon": 0.24,
	},
	{
		"file": "04-world-three-quarter", "was": "survey 04-three-quarter",
		"eye": Vector2(70.0, 40.0), "eye_h": 8.0,
		"target": Vector2(-90.0, -60.0), "target_h": 4.0,
		"time": "day", "horizon": 0.26,
	},
	{
		"file": "05-world-spawn-low-sun", "was": "survey 05-spawn-low-sun",
		"eye": Vector2(0.0, 0.0), "eye_h": 2.2,
		"target": Vector2(150.0, 120.0), "target_h": 6.0,
		"time": "golden", "horizon": 0.34, "actor": Vector2(9.0, 7.0),
	},
]

## The features the owner named that the five survey viewpoints do not look at.
## Coordinates are read off the data that authored them — `terrain_playground.json`
## for the rises, `water.json` and its channel for the pond and the brook,
## `trails.json` for the trail, `settlement.json` for the village, the stronghold
## and Grandpa's, `vegetation.json` for the tree clumps — so a frame here is
## aimed at the thing the file says is there rather than at a spot that looked
## right once.
##
## `aim: true` means "keep the pitch `look_at` produced" instead of overriding it
## to put the horizon at a fixed height. Used for anything the camera has to look
## up at, which the horizon rule cannot express.
const FEATURE_VIEWPOINTS := [
	{
		# `target_h` is metres ABOVE THE GROUND AT THE TARGET, and the ground at
		# this target is the 46m summit. The first pass asked for 26 on top of
		# that, pitched the camera 72m into the air, and photographed a bare slope
		# with two thirds of the frame empty sky.
		"file": "06-world-hills-north", "shows": "the big rise at (140,-90), 46m, as landmark mass",
		"eye": Vector2(26.0, 18.0), "eye_h": 16.0,
		"target": Vector2(140.0, -90.0), "target_h": 6.0, "time": "day", "aim": true,
	},
	{
		"file": "07-world-trees-grove", "shows": "the tree clumps at (-52,84) and the twisted grove at (-46,78)",
		"eye": Vector2(-26.0, 58.0), "eye_h": 5.0,
		"target": Vector2(-56.0, 88.0), "target_h": 7.0, "time": "day", "horizon": 0.30,
	},
	{
		"file": "08-world-pond", "shows": "ValleyPond, centre (-96,116) radius 16, and its shoreline",
		"eye": Vector2(-68.0, 134.0), "eye_h": 7.0,
		"target": Vector2(-96.0, 116.0), "target_h": 0.0, "time": "day", "horizon": 0.34,
	},
	{
		"file": "09-world-stream", "shows": "StrongholdBrook where its channel is cut, near (-66,160)",
		"eye": Vector2(-52.0, 148.0), "eye_h": 4.5,
		"target": Vector2(-78.0, 164.0), "target_h": 0.0, "time": "day", "horizon": 0.40,
	},
	{
		"file": "10-world-trail", "shows": "the meadow_spine trail between (28,4) and (70,50)",
		"eye": Vector2(24.0, 0.0), "eye_h": 2.6,
		"target": Vector2(70.0, 50.0), "target_h": 2.0, "time": "day", "horizon": 0.32,
		"actor": Vector2(33.0, 8.0),
	},
	{
		"file": "11-world-settlement", "shows": "the village: hall, cottages, barn and green around (82,76)",
		"eye": Vector2(56.0, 52.0), "eye_h": 9.0,
		"target": Vector2(84.0, 78.0), "target_h": 3.0, "time": "day", "horizon": 0.30,
	},
	{
		# Back far enough that the bluff is a shape rather than a slope. At 45m the
		# first pass had a single boulder on the near face filling the left third
		# of the frame, which is the same mistake `survey.gd` records fixing on
		# `03-rise-overlook`: the shot that is meant to show a landmark cannot be
		# taken from inside it.
		"file": "12-world-stronghold", "shows": "the stronghold ruin on its bluff at (60,178), 33m up",
		"eye": Vector2(24.0, 104.0), "eye_h": 10.0,
		"target": Vector2(60.0, 178.0), "target_h": 10.0, "time": "golden", "aim": true,
	},
	{
		"file": "13-world-grandpa-house", "shows": "Grandpa's cottage at (54,12) from the road, door side",
		"eye": Vector2(36.0, 2.0), "eye_h": 3.4,
		"target": Vector2(53.0, 11.0), "target_h": 2.6, "time": "day", "aim": true,
		"actor": Vector2(44.0, 6.0),
	},
]

## Sampled rather than duplicated: `tools/preview_weather.gd` renders eighteen
## and is the tool for judging the weather system. These nine are the ones a
## whole-game sheet needs — the ends of the day, and each weather state once.
const WEATHER_SHOTS := [
	{"file": "14-weather-night-0100", "hour": 1.0, "weather": "clear"},
	{"file": "15-weather-dawn-0620", "hour": 6.2, "weather": "clear"},
	{"file": "16-weather-day-1100", "hour": 11.0, "weather": "clear"},
	{"file": "17-weather-golden-1800", "hour": 18.0, "weather": "clear"},
	{"file": "18-weather-dusk-2000", "hour": 20.0, "weather": "clear"},
	{"file": "19-weather-cloudy", "hour": 11.0, "weather": "cloudy"},
	{"file": "20-weather-rain", "hour": 11.0, "weather": "rain"},
	{"file": "21-weather-storm-flash", "hour": 11.0, "weather": "storm", "flash": true},
	{"file": "22-weather-fog", "hour": 6.2, "weather": "fog"},
]

## Rain has a 1.1s lifetime; capturing before a full generation has fallen gives
## a frame with a band of drops at the top and clear air underneath.
const RAIN_FILL_FRAMES := 70

var _run_id: String = ""
var _started_at: int = 0
var _chapters: PackedStringArray = PackedStringArray()

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _lens: Camera3D = null
var _cam: Camera3D = null
var _field: RefCounted = null

var _hud: CanvasLayer = null
var _minimap: CanvasLayer = null

## One entry per frame ATTEMPTED, whether or not it landed. A manifest that only
## lists successes cannot be checked against the shot list.
var _manifest: Array[Dictionary] = []
## sha256 -> the first frame that had it. Two frames with one hash means an input
## did nothing, and that has to be shouted about rather than filed.
var _seen: Dictionary = {}
## Things a reviewer needs told that are not a frame: an unreachable state, an
## API that refused, a shot that could not be produced.
var _findings: Array[String] = []

## Rendering is switched off between shots. A software-rendered frame of a meadow
## with ~74,000 scattered props costs about two seconds of wall clock, and a boot
## settles for hundreds of physics frames — `tools/preview_run_cycle.gd` found
## this and it is the difference between a twenty-minute run and a four-hour one.
var _rendering: bool = true


func _init() -> void:
	_run()


func _run() -> void:
	_started_at = int(Time.get_unix_time_from_system())
	_run_id = "%d-%d" % [_started_at, OS.get_process_id()]

	_chapters = _requested_chapters()
	print("capture_all: run %s" % _run_id)
	print("  renderer: %s" % DisplayServer.get_name())
	print("  chapters: %s" % ", ".join(_chapters))
	if DisplayServer.get_name() == "headless":
		print("FATAL: headless disables rendering. Run under xvfb-run; see D06.")
		quit(2)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_clear_prior_output()

	# The save goes before the world is built, not after. `SaveDirector` restores
	# slot 0 at boot, so a previous run's buildings and party would otherwise walk
	# into this run's frames looking exactly like this run's game.
	await process_frame
	_wipe_save()

	_slow_rendering(false)

	if _has("studio"):
		await _chapter_studio()

	if _needs_world():
		if not await _boot():
			_finish()
			return

	if _has("world"):
		await _chapter_world()
	if _has("weather"):
		await _chapter_weather()
	if _has("characters"):
		await _chapter_characters()
	if _has("creatures"):
		await _chapter_creatures()
	if _has("home"):
		await _chapter_home()
	if _has("doors"):
		await _chapter_doors()
	# COMBAT BEFORE MENUS, and the order is load-bearing.
	#
	# The ceremony frames need a party of five, because that is the only state in
	# which the ceremony can open at all. But a full party is also the state in
	# which the game correctly refuses to let you throw an orb — there would be
	# nowhere to put what you caught — so a combat chapter run afterwards cannot
	# open the aim. The first run of this file did menus first and came back
	# with "could not open the throw aim; frames 45, 46 and 47 are missing",
	# which is the game working exactly as designed and the harness asking for
	# the two states at once.
	if _has("combat"):
		await _chapter_combat()
	if _has("menus"):
		await _chapter_menus()

	_finish()


func _requested_chapters() -> PackedStringArray:
	var all := PackedStringArray([
		"studio", "world", "weather", "characters", "creatures",
		"home", "doors", "menus", "combat",
	])
	var asked := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		var name := str(argument).strip_edges()
		if all.has(name):
			asked.append(name)
		else:
			print("  unknown chapter '%s' ignored (known: %s)" % [name, ", ".join(all)])
	return all if asked.is_empty() else asked


func _has(chapter: String) -> bool:
	return _chapters.has(chapter)


func _needs_world() -> bool:
	for chapter in ["world", "weather", "characters", "creatures", "home", "doors", "menus", "combat"]:
		if _has(chapter):
			return true
	return false


# --- the world ----------------------------------------------------------------

## Boot the meadow and WAIT FOR THE CONDITIONS, not for a frame count.
##
## Four things have to have happened before any of this is worth photographing,
## and each of them is asked about directly: the terrain can answer for its own
## height, the encounter director has placed its creatures, the settlement's
## doors are hung, and Team Tether is on the road. A fixed settle is either too
## short on a slow machine — which photographs an empty world and calls it the
## game — or several minutes too long on a fast one.
func _boot() -> bool:
	var began := Time.get_ticks_msec()
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_find("FATAL: could not load %s" % SCENE)
		return false
	_world = packed.instantiate()
	root.add_child(_world)

	var director: Node = null
	var doors: Node = null
	var route: Node = null
	var waited := 0
	while waited < BOOT_LIMIT:
		await physics_frame
		waited += 1
		director = _world.get_node_or_null(^"EncounterDirector")
		doors = _world.get_node_or_null(^"Doors")
		route = _world.get_node_or_null(^"StrongholdRoute")
		var creatures: int = 0
		if director != null:
			creatures = (director.call("wild_pals") as Array).size()
		var hung: int = 0 if doors == null else int(doors.call("hung"))
		var tethered: int = 0
		if route != null:
			tethered = (route.call("trainers") as Array).size()
		if creatures > 0 and hung > 0 and tethered > 0:
			break

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_lens = null if _rig == null else _rig.get_node_or_null(^"Camera3D") as Camera3D
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_minimap = _world.get_node_or_null(^"Minimap") as CanvasLayer
	_field = HEIGHTFIELD.new()

	# A CAMERA OF OUR OWN for the posed frames. `tools/preview_doors.gd` learned
	# why the scene's own camera will not do: it hangs off a SpringArm3D, and a
	# spring arm rewrites its child's transform from an INTERNAL physics
	# notification that `set_physics_process(false)` does not touch.
	_cam = Camera3D.new()
	_cam.name = "ReviewCamera"
	_cam.fov = FOV
	_cam.far = 2000.0
	_world.add_child(_cam)

	var creatures_now: int = 0 if director == null else (director.call("wild_pals") as Array).size()
	var hung_now: int = 0 if doors == null else int(doors.call("hung"))
	var tether_now: int = 0
	if route != null:
		tether_now = (route.call("trainers") as Array).size()
	print("  world up after %d physics frames (%.1fs): %d wild creatures, %d doors hung, %d Team Tether on the road" % [
		waited, (Time.get_ticks_msec() - began) / 1000.0, creatures_now, hung_now, tether_now
	])
	if _player == null or _rig == null or _lens == null:
		_find("FATAL: the world has no Player, CameraRig or lens; nothing can be framed")
		return false
	if creatures_now == 0:
		_find("the encounter director placed NO creatures; every creature frame below is of an empty meadow")
	if hung_now == 0:
		_find("no doors were hung in the settlement; the door frames below cannot be produced")
	if tether_now == 0:
		_find("Team Tether never appeared on the road within %d frames" % waited)
	return true


# --- chapters -----------------------------------------------------------------

## The three frames that need a controlled background rather than the meadow.
##
## Run BEFORE the world exists, and freed afterwards, because two
## WorldEnvironments in one tree is a coin toss about which one lights the scene.
func _chapter_studio() -> void:
	print("")
	print("-- studio --")
	TETHER_ROSTER.register()

	var stage := Node3D.new()
	root.add_child(stage)
	# ONE FRAME BEFORE ANYTHING IS BUILT ON IT: under `--script`, a node added in
	# `_init()` is not inside the tree yet, and every world-space assignment
	# against it silently resolves to the origin.
	await process_frame
	_studio_light(stage)
	_studio_floor(stage)

	var camera := Camera3D.new()
	camera.fov = 42.0
	stage.add_child(camera)
	camera.make_current()

	# Left to right: the player's own trainer at 1.80m, then the road in
	# ascending order — the wrangler at 1.53m, the picket at 1.80m, the Warden at
	# 1.96m. The picket standing beside the player's trainer is the point: the
	# same body wearing a different flag, with the Warden visibly not one of them.
	_studio_player_trainer(stage, Vector3(-2.6, 0.0, 0.0))
	_studio_tether(stage, TETHER_DATA.trainer("tether_wrangler"), Vector3(-0.9, 0.0, 0.0))
	_studio_tether(stage, TETHER_DATA.trainer("tether_picket"), Vector3(0.5, 0.0, 0.0))
	_studio_tether(stage, TETHER_DATA.trainer("warden_meadows"), Vector3(2.0, 0.0, 0.0))
	_studio_ruler(stage, Vector3(-3.5, 0.0, 0.0), 1.80)
	_studio_ruler(stage, Vector3(2.9, 0.0, 0.0), 1.96)

	# The models load, retarget twenty-five clips and start their idle. A frame
	# taken before that photographs a bind pose, which is indistinguishable from a
	# retarget that failed.
	for i in 150:
		await physics_frame

	camera.position = Vector3(-0.3, 1.30, 6.6)
	camera.look_at(Vector3(-0.3, 1.00, 0.0), Vector3.UP)
	await _shoot("29-character-team-tether", "studio",
		"the player's trainer, the wrangler, the picket and the Warden, with 1.80m and 1.96m rulers", false)

	camera.position = Vector3(2.0, 1.25, 3.4)
	camera.look_at(Vector3(2.0, 1.05, 0.0), Vector3.UP)
	await _shoot("30-character-warden-close", "studio",
		"the Warden of the Meadows close, for dress, colour and silhouette", false)

	stage.queue_free()
	await process_frame

	# The roster in one rank, at scale, with the 1.80m trainer standing in it.
	await _roster_line()


## The whole cast in one orthographic rank. Not a grid of tiles each framed on
## its own subject: making every creature the same size on the sheet is the one
## thing a scale review must not do.
func _roster_line() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	await process_frame
	_studio_light(stage)
	_studio_floor(stage)

	var camera := Camera3D.new()
	camera.name = "Cam"
	camera.fov = 42.0
	stage.add_child(camera)
	camera.make_current()

	var ids: Array[String] = []
	for id: String in SPECIES.table().keys():
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return SPECIES.body_height(a) < SPECIES.body_height(b))

	# Spaced by MEASURED length, not by collider radius: every quadruped here is
	# two to three times longer than it is wide, and radius-spacing stands the
	# 3.4m Thornback inside its neighbour.
	const GAP := 0.55
	var cursor := GAP
	for id in ids:
		var body: Node3D = PAL_SCENE.instantiate()
		body.set_script(BODY_SCRIPT)
		stage.add_child(body)
		await process_frame
		body.call("setup", id)
		body.rotation.y = deg_to_rad(90.0)
		var length: float = _measured_length(body, id)
		body.position = Vector3(cursor + length * 0.5, 0.0, 0.0)
		cursor += length + GAP
		print("  %-16s %-14s %.2fm tall, %.2fm long" % [
			id, SPECIES.display_name(id), SPECIES.body_height(id), length])

	var trainer := _studio_player_trainer(stage, Vector3(cursor + 0.6, 0.0, 0.0))
	if trainer != null:
		trainer.rotation.y = deg_to_rad(180.0)
	var span: float = cursor + 1.8

	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# KEEP_WIDTH, because `size` is the VERTICAL extent by default and a rank 17m
	# wide framed to 17m tall renders a row of ants.
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = span
	camera.look_at_from_position(
		Vector3(span * 0.5, 1.1, span * 0.9), Vector3(span * 0.5, 1.1, 0.0), Vector3.UP)

	for i in 120:
		await physics_frame
	await _shoot("31-creature-roster-line", "studio",
		"all %d species side-on at true scale, with the 1.80m trainer at the right-hand end" % ids.size(), false)

	stage.queue_free()
	await process_frame


func _chapter_world() -> void:
	print("")
	print("-- world --")
	_show_hud(false)
	_use_own_camera()
	var look: Node = _world.get_node_or_null(^"WorldLook")

	for entry: Variant in SURVEY_VIEWPOINTS:
		var view: Dictionary = entry
		await _posed_frame(view, look, "the fixed viewpoint MA-05 judged as %s" % str(view["was"]))
	for entry: Variant in FEATURE_VIEWPOINTS:
		var view: Dictionary = entry
		await _posed_frame(view, look, str(view["shows"]))


func _posed_frame(view: Dictionary, look: Node, intent: String) -> void:
	_pose(view)
	_park_actor(view)
	if look != null:
		look.call("apply_time", str(view.get("time", "day")))
	for i in SETTLE_AFTER_MOVE:
		await physics_frame
	await _shoot(str(view["file"]), "world", intent, false)


func _chapter_weather() -> void:
	print("")
	print("-- weather --")
	var cycle: Node = _world.get_node_or_null(^"SkyCycle")
	var look: Node = _world.get_node_or_null(^"WorldLook")
	if cycle == null or look == null:
		_find("the scene has no SkyCycle/WorldLook pair; no weather or time-of-day frames")
		return
	if not bool(look.call("blending_sky")):
		_find("the sky is on the FALLBACK path, not the cross-fading shader — none of the "
			+ "weather frames show the sky the game actually renders")

	_show_hud(false)
	_use_own_camera()
	# One viewpoint on purpose, and it is `01-world-spawn-outward`'s, so a weather
	# frame and a world frame differ only by the sky.
	_pose(SURVEY_VIEWPOINTS[0])
	_park_actor(SURVEY_VIEWPOINTS[0])
	cycle.call("set_paused", true)

	for entry: Variant in WEATHER_SHOTS:
		var shot: Dictionary = entry
		var weather := str(shot["weather"])
		if not bool(cycle.call("force_weather", weather)):
			_find("%s: there is no weather state called '%s'" % [shot["file"], weather])
			continue
		cycle.call("set_hour", float(shot["hour"]))
		var wet: bool = weather in ["rain", "storm"]
		for i in (RAIN_FILL_FRAMES if wet else 20):
			await process_frame
		if bool(shot.get("flash", false)):
			cycle.call("strike_lightning")
			# Two frames in: the rise is 0.04s, so waiting longer photographs the
			# decay rather than the strike.
			await process_frame
			await process_frame
		else:
			# A storm rolls its own strikes and one landing before the shutter
			# would brighten a frame meant to show the storm's ordinary light.
			var guard := 0
			while float(cycle.call("flash")) > 0.005 and guard < 240:
				guard += 1
				await process_frame
		await _shoot(str(shot["file"]), "weather",
			"%s at %04.1fh, from the spawn viewpoint: %s" % [weather, shot["hour"], cycle.call("describe")],
			false)

	# Put the world back to the middle of a clear day for everything after this.
	cycle.call("force_weather", "clear")
	cycle.call("set_hour", 11.0)
	cycle.call("set_paused", true)
	for i in 20:
		await process_frame


## The trainer, through the game's own camera, doing the three things he does.
##
## Driven with `Input.action_press`, not posed: a preview that arranges what it
## wants to see cannot report that the locomotion state machine is not running.
## `docs/reviews/MA-05` and the owner independently reported an un-blended rest
## pose, so these frames exist to be looked at rather than measured.
func _chapter_characters() -> void:
	print("")
	print("-- characters --")
	_show_hud(false)
	_use_own_camera()

	var spawn := _ground_at(Vector2(6.0, -14.0))
	await _stand_player(spawn, spawn + Vector3(0.0, 0.0, 12.0))

	# FRONT IS LOCAL +X, NOT LOCAL +Z, and that is measured rather than assumed:
	# the first pass took +Z for the front and came back with two side views
	# labelled front and side. The rig this model came out of does not face the
	# Godot -Z convention, and `tools/preview_run_cycle.gd` has the same offset
	# with the same 90 degrees baked into it — it just happened to want a side.
	await _actor_frame("23-character-idle-front", Vector3(3.4, 1.05, 0.0),
		"the trainer idle, seen from the front", 40)
	await _actor_frame("24-character-idle-side", Vector3(0.0, 1.05, 3.4),
		"the trainer idle, seen from the side", 10)

	# Walking. Held, and photographed with the clock stopped, because a software
	# frame costs an appreciable fraction of a second of real time and the trainer
	# covers four metres in one.
	Input.action_press("move_forward")
	for i in 50:
		await physics_frame
	await _actor_frame("25-character-walking-side", Vector3(0.0, 1.05, 3.6),
		"the trainer walking, side on, mid-clip", 0, true)

	Input.action_press("sprint")
	for i in 60:
		await physics_frame
	await _actor_frame("26-character-running-side", Vector3(0.0, 1.05, 3.6),
		"the trainer running, side on, mid-clip", 0, true)
	for i in 22:
		await physics_frame
	await _actor_frame("27-character-running-front", Vector3(3.8, 1.15, 0.0),
		"the trainer running, seen from the front", 0, true)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame

	await _mounted_frame()


## The trainer on a creature's back, through the mount system's own path.
func _mounted_frame() -> void:
	var party: Node = _world.get_node_or_null(^"Party")
	var bag: Node = _world.get_node_or_null(^"TrainerInventory")
	if party == null or bag == null:
		_find("no Party or TrainerInventory in the world; the mounted frame cannot be produced")
		return

	# A rideable species THAT HAS A MODEL.
	#
	# `SPECIES.ids()` sorts alphabetically and `meadows_legendary` sorts first, so
	# "the first rideable species" is the one creature in the table with
	# `model: ""` — an unmodelled capsule. The first pass mounted that, and the
	# frame came back as a white bean standing alone in a field. The legendary
	# genuinely is rideable (M14, §28); it just cannot be photographed yet.
	var rideable := ""
	for id in SPECIES.ids():
		if not MOUNT.is_rideable(id):
			continue
		if str(SPECIES.placeholder(id).get("model", "")).is_empty():
			_find("%s is rideable and has no model; it cannot be the mounted frame" % id)
			continue
		rideable = id
		break
	if rideable.is_empty():
		_find("no species in species.json is both rideable and modelled; no mounted frame")
		return

	bag.call("inventory").call("add", MOUNT.SADDLE_ITEM, 1)
	var pal: RefCounted = SPECIES.spawn(rideable)
	if not bool(party.call("add", pal)):
		_find("the party would not take a %s for the mounted frame: %s" % [
			rideable, party.call("last_refusal")])
		return
	# Deployed, so `mount.gd` has something to call out.
	var index: int = int(party.call("size")) - 1
	party.call("set_active", index)
	for i in 20:
		await physics_frame

	var mount: Node = _player.call("mount")
	if not bool(mount.call("mount")):
		_find("mounting refused: %s — no mounted frame" % mount.call("last_refusal"))
		return
	for i in 30:
		await physics_frame

	var creature: Node3D = mount.call("body")
	var at: Vector3 = _player.global_position if creature == null else creature.global_position
	# Aimed at the RIDER's chest, not at the animal's. The seat is a metre or more
	# above the creature's origin, and a camera pointed at the creature crops the
	# person off the top of the frame — which is the only thing this shot is for.
	var seat: float = MOUNT.seat_offset(rideable).y + 1.1
	_cam.global_position = at + Vector3(6.0, seat + 0.6, 0.8)
	_cam.look_at(at + Vector3(0.0, seat, 0.0), Vector3.UP)
	await _shoot("28-character-mounted", "characters",
		"the trainer mounted on a %s, side on" % SPECIES.display_name(rideable), false)

	mount.call("dismount")
	# AND PUT THE FIRST PAL BACK OUT. Deploying the mount leaves it as the party's
	# active member, which is the creature every later fight in this run would send
	# into the arena. The first pass did that with the unmodelled legendary and
	# every combat frame afterwards was a white capsule fighting a Thornback.
	party.call("set_active", 0)
	for i in 20:
		await physics_frame


## Creatures: the whole roster on the real ground, the ones actually alive in the
## meadow, and the behaviour difference between an aggressive one and a passive
## one — which is `aggressive` in species.json and `wild_pal._tick_aggression`.
func _chapter_creatures() -> void:
	print("")
	print("-- creatures --")
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_find("no EncounterDirector; no creature frames")
		return

	_show_hud(false)
	_use_own_camera()
	await _roster_field()

	# The creatures that are actually alive out there, through the gameplay
	# camera. MA-05: "Five frames of a creature-training game contained no
	# creatures... the camera positions do not look at them."
	_show_hud(true)
	var wilds: Array = director.call("wild_pals")
	var passive: Node3D = director.call("wild_pal") as Node3D
	var aggressive: Node3D = director.call("aggressive_pal") as Node3D

	if wilds.is_empty():
		_find("the meadow holds no wild creatures; nothing to photograph alive")
	else:
		var subject: Node3D = wilds[0] as Node3D
		await _stand_player(subject.global_position + Vector3(7.0, 0.0, 6.5), subject.global_position)
		_use_game_camera()
		for i in 30:
			await physics_frame
		await _shoot("33-creature-in-the-meadow", "creatures",
			"a wild creature where it lives, framed through the gameplay camera", true)

	if passive == null:
		_find("no peaceful wild_rabbit in the world; the passive-behaviour frame cannot be produced")
	else:
		await _stand_player(passive.global_position + Vector3(4.2, 0.0, 3.6), passive.global_position)
		_use_game_camera()
		# Long enough that the creature has decided what it is doing about you.
		for i in 120:
			await physics_frame
		var gap: float = passive.global_position.distance_to(_player.global_position)
		await _shoot("34-creature-passive", "creatures",
			("a PASSIVE creature (%s, aggressive=false) standing %.1fm from the trainer: it stops "
			+ "and looks and does nothing else — GAME_DESIGN 14 forbids proximity starting a fight") % [
				SPECIES.display_name(str(passive.get("species_id"))), gap], true)

	if aggressive == null:
		_find("no aggressive creature in the world; the aggression frames cannot be produced")
		return

	# The aggressive one. Stood 12m off — inside its 14m notice range — and then
	# left alone, so what the frames show is the creature's own decision rather
	# than a pose. It closes; the fight it starts is refused and fled below so the
	# rest of the run is not spent inside it.
	var home: Vector3 = aggressive.global_position
	await _stand_player(home + Vector3(10.0, 0.0, 7.0), home)
	_use_game_camera()
	var manager: Node = _world.get_node_or_null(^"CombatManager")
	var closed := 999.0
	for i in 240:
		await physics_frame
		closed = aggressive.global_position.distance_to(_player.global_position)
		if closed < 7.0 or bool(manager.call("is_fighting")):
			break
	await _shoot("35-creature-aggressive-closing", "creatures",
		("an AGGRESSIVE creature (%s, aggressive=true) that has closed to %.1fm on its own — nobody "
		+ "pressed anything; `_tick_aggression` is chasing") % [
			SPECIES.display_name(str(aggressive.get("species_id"))), closed], true)

	for i in 240:
		await physics_frame
		closed = aggressive.global_position.distance_to(_player.global_position)
		if closed < 3.6 or bool(manager.call("is_fighting")):
			break
	await _shoot("36-creature-aggressive-engaging", "creatures",
		"the same creature at %.1fm, the range at which it starts the fight itself%s" % [
			closed, " — a fight is now open" if bool(manager.call("is_fighting")) else ""], true)

	await _leave_any_fight()
	# Out of its notice range, or it follows the camera through the next chapter.
	await _stand_player(_ground_at(Vector2(0.0, 0.0)), _ground_at(Vector2(30.0, 0.0)))


## The whole cast standing on the REAL meadow, under the real sun.
##
## Five of the eight species never spawn near the player, so nothing else in the
## project can put them in front of this ground — and "does this creature read
## against THIS grass" is a question about this grass.
func _roster_field() -> void:
	var origin: Vector3 = _ground_at(Vector2(-16.0, -34.0))
	var ids: Array[String] = []
	for id: String in SPECIES.table().keys():
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return SPECIES.body_height(a) < SPECIES.body_height(b))

	var placed: Array[Node3D] = []
	var cursor := 0.0
	for id in ids:
		var body: Node3D = PAL_SCENE.instantiate()
		body.set_script(BODY_SCRIPT)
		_world.add_child(body)
		await process_frame
		body.call("setup", id)
		var length: float = _measured_length(body, id)
		cursor += length * 0.5 + 0.8
		body.call("place_on_ground", origin + Vector3(cursor, 0.0, 0.0))
		cursor += length * 0.5
		body.rotation.y = deg_to_rad(90.0)
		placed.append(body)

	# Long enough for every one of them to be standing in its idle rather than in
	# the bind pose the AABBs are padded for.
	for i in 90:
		await physics_frame

	var middle: Vector3 = origin + Vector3(cursor * 0.5, 0.0, 0.0)
	_cam.global_position = middle + Vector3(0.0, 3.4, 16.5)
	_cam.look_at(middle + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_cam.make_current()
	await _shoot("32-creature-roster-field", "creatures",
		"all %d species standing on the real meadow, at true scale, shortest to tallest" % ids.size(), false)

	for body in placed:
		body.queue_free()
	await process_frame


## Home: the trainer's bed, a pal bed, and a creature actually asleep in one.
##
## M6 built `recovery.gd`, and a resting pal gets a real body on the bed playing
## its `rest` clip — `sit` for every creature in the shipped pack, because there
## is no sleep or lie-down animation anywhere in it.
func _chapter_home() -> void:
	print("")
	print("-- home --")
	# Nothing below is worth photographing from inside a fight.
	await _leave_any_fight()
	var structures: Node3D = _world.get_node_or_null(^"Structures") as Node3D
	var recovery: Node = _world.get_node_or_null(^"Recovery")
	var home: Node = _world.get_node_or_null(^"Home")
	var party: Node = _world.get_node_or_null(^"Party")
	if structures == null or recovery == null or home == null or party == null:
		_find("the world is missing Structures, Home, Recovery or Party; no bed frames")
		return

	_show_hud(true)
	_use_own_camera()

	# A camp on the flat spawn pad, placed through `structures.place` — the same
	# call build mode makes when the player puts a piece down.
	var base := _ground_at(Vector2(-10.0, -6.0))
	var laid: Array[Node] = []
	var plan := [
		{"piece": "floor_wooddark", "at": Vector3(0, 0, 0)},
		{"piece": "floor_wooddark", "at": Vector3(GRID.CELL, 0, 0)},
		{"piece": "floor_wooddark", "at": Vector3(0, 0, GRID.CELL)},
		{"piece": "floor_wooddark", "at": Vector3(GRID.CELL, 0, GRID.CELL)},
		{"piece": "bed_simple", "at": Vector3(0, 0, 0)},
		{"piece": "pal_bed_straw", "at": Vector3(GRID.CELL, 0, 0)},
		{"piece": "pal_bed_straw", "at": Vector3(GRID.CELL, 0, GRID.CELL)},
		{"piece": "campfire_stone", "at": Vector3(0, 0, GRID.CELL)},
	]
	for entry: Variant in plan:
		var step: Dictionary = entry
		var cell: Vector3 = GRID.snap_to_cell(base + (step["at"] as Vector3))
		cell.y = _world.call("ground_height_at", cell.x, cell.z)
		var node: Node = structures.call("place", str(step["piece"]), cell, 0.0)
		if node == null:
			_find("could not place a %s for the home frames" % step["piece"])
		else:
			laid.append(node)
	for i in 20:
		await physics_frame

	var bed: Node = structures.call("nearest_station", base, 12.0, STATION.BEHAVIOUR_REST)
	if bed == null:
		_find("no rest station within 12m of the camp that was just built; no bed frames")
		return

	var trainer_bed: Node = null
	var pal_bed: Node = null
	for entry: Variant in structures.call("stations", STATION.BEHAVIOUR_REST):
		var station: Node = entry
		if bool(station.call("is_for_pals")):
			if pal_bed == null:
				pal_bed = station
		elif trainer_bed == null:
			trainer_bed = station

	if trainer_bed != null:
		var spot: Vector3 = trainer_bed.call("where")
		await _stand_player(spot + Vector3(1.4, 0.0, 1.4), spot)
		_cam.global_position = spot + Vector3(3.4, 2.4, 3.4)
		_cam.look_at(spot + Vector3(0.0, 0.3, 0.0), Vector3.UP)
		await _shoot("59-home-trainer-bed", "home",
			"the trainer's own bed, with him standing at it — SEE THE MANIFEST: nothing in the "
			+ "game puts the trainer IN it, there is no sleep state", true)
	else:
		_find("no trainer bed was placed; frame 59 is missing")

	if pal_bed == null:
		_find("no pal bed was placed; frames 60 and 61 are missing")
		return

	var pal_spot: Vector3 = pal_bed.call("where")
	_cam.global_position = pal_spot + Vector3(2.6, 1.7, 2.6)
	_cam.look_at(pal_spot + Vector3(0.0, 0.3, 0.0), Vector3.UP)
	await _shoot("60-home-pal-bed-empty", "home", "a pal bed, empty, for comparison with the next frame", true)

	# A pal that NEEDS the bed. `recovery.rest()` refuses a pal at full health, so
	# one is hurt first — through the instance's own HP, which is what a fight
	# would have done to it.
	var sleeper: RefCounted = party.call("at", 0) as RefCounted
	if sleeper == null:
		_find("the party is empty; no creature can be put in a bed")
		return
	sleeper.hp = sleeper.max_hp * 0.25
	if not bool(recovery.call("rest", sleeper, pal_bed)):
		_find("recovery refused to put %s in the bed: %s" % [
			sleeper.call("display"), recovery.call("last_refusal")])
		return
	# Long enough for the body to be built, grounded and playing its rest clip.
	for i in 60:
		await physics_frame
	await _shoot("61-home-pal-resting", "home",
		("%s asleep on a pal bed — a real body from pal.tscn on the bed's own rest point, "
		+ "playing the species' rest clip") % sleeper.call("display"), true)

	var overview: Vector3 = base
	_cam.global_position = overview + Vector3(7.0, 5.5, 7.0)
	_cam.look_at(overview, Vector3.UP)
	await _shoot("62-home-camp", "home",
		"the whole camp: floors, the trainer's bed, two pal beds, a campfire, one pal asleep", true)

	recovery.call("wake_all")
	for i in 10:
		await physics_frame


## Doors, open and shut, outside and in, on Grandpa's cottage and on one the
## player put up.
##
## `tools/preview_doors.gd` is the tool that PROVES a door works, and it also
## fires rays through the doorway because a door swinging open in front of an
## invisible wall looks perfect in a screenshot. This is the picture half only,
## on both kinds of door, with the trainer in frame for scale.
func _chapter_doors() -> void:
	print("")
	print("-- doors --")
	# Nothing below is worth photographing from inside a fight.
	await _leave_any_fight()
	var structures: Node3D = _world.get_node_or_null(^"Structures") as Node3D
	var doors: Node = _world.get_node_or_null(^"Doors")
	if structures == null or doors == null:
		_find("the world has no Structures or no Doors; no door frames")
		return
	_show_hud(true)

	await _door_pair("63", "grandpa", _site_origin("grandpa"), structures, doors, 14.0)
	await _build_a_doorway(structures)
	await _door_pair("67", "built", _ground_at(Vector2(12.0, -8.0)), structures, doors, 8.0)


## Four frames of one door: shut and open, from outside and from inside.
##
## WHICH SIDE IS OUTSIDE is decided by the building, not by the door — the far
## side from the room's own centre. A door's local +Z points into the house on
## one wall and out of it on the opposite one, and guessing costs a whole session
## of frames taken from inside a wall. That lesson is `preview_doors.gd`'s.
func _door_pair(
	first: String, label: String, origin: Vector3, structures: Node3D, doors: Node, radius: float
) -> void:
	var door: Node = structures.call("nearest_station", origin, radius, STATION.BEHAVIOUR_DOOR)
	if door == null:
		_find("no door within %.0fm of '%s'; frames %s.. are missing" % [radius, label, first])
		return
	var at: Vector3 = door.call("where")
	var facing: float = float(door.get("facing"))
	var through: Vector3 = Basis(Vector3.UP, facing) * Vector3(0.0, 0.0, 1.0)
	var outward: Vector3 = through if through.dot(at - origin) > 0.0 else -through
	var along: Vector3 = Basis(Vector3.UP, facing) * Vector3(1.0, 0.0, 0.0)
	var aim := at + Vector3.UP * 1.25
	var number := int(first)

	_use_own_camera()
	for state: String in ["closed", "open"]:
		if state == "open":
			# Opened from OUTSIDE, through the same call the `interact` press makes.
			doors.call("open_nearest", at + outward * 1.2)
			door.call("snap")
			await physics_frame

		await _stand_player(at + outward * 1.9 + along * 0.9, at)
		_cam.global_position = at + outward * 3.4 + along * 1.6 + Vector3.UP * 2.0
		_cam.look_at(aim, Vector3.UP)
		await _shoot("%02d-doors-%s-outside-%s" % [number, label, state], "doors",
			"%s's door %s, from outside, trainer at 1.80m beside it" % [label, state], true)
		number += 1

		await _stand_player(at - outward * 2.2 + along * 1.0, at)
		_cam.global_position = at - outward * 2.6 + along * 0.4 + Vector3.UP * 1.55
		_cam.look_at(aim, Vector3.UP)
		await _shoot("%02d-doors-%s-inside-%s" % [number, label, state], "doors",
			"%s's door %s, from INSIDE the building looking out" % [label, state], true)
		number += 1
		# So the four come out in this order: outside-closed, inside-closed,
		# outside-open, inside-open. Each pair is the same camera on the same
		# frame, so the only thing that changes between them is the leaf —
		# anything else that moves between two of these frames is a bug.


## A doorway the PLAYER could have built: a wall with a hole, a frame in it and a
## leaf hung in that, placed through `structures.place` on the real terrain.
##
## Three pieces, not one. The kit splits a doorway into the wall that has the
## hole, the frame that covers the reveal and the leaf that swings — and the leaf
## is hinged on its own edge, which is why `structures.place` applies the piece's
## measured `hangs` offset rather than dropping it on the wall's origin.
func _build_a_doorway(structures: Node3D) -> void:
	var base := _ground_at(Vector2(12.0, -8.0))
	var placed := 0
	# A two-by-two room, so there is an inside to stand in and a wall to look at.
	for cx in 2:
		for cz in 2:
			var cell: Vector3 = GRID.snap_to_cell(base + Vector3(cx * GRID.CELL, 0.0, cz * GRID.CELL))
			cell.y = _world.call("ground_height_at", cell.x, cell.z)
			if structures.call("place", "floor_wooddark", cell, 0.0) != null:
				placed += 1
			for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				var neighbour := Vector2i(cx + int(side.x), cz + int(side.z))
				if neighbour.x >= 0 and neighbour.x < 2 and neighbour.y >= 0 and neighbour.y < 2:
					continue
				var edge: Dictionary = GRID.snap_to_edge(cell + side * (GRID.CELL * 0.45))
				var piece := "wall_plaster_straight"
				var is_doorway: bool = side.z > 0 and cx == 0
				if is_doorway:
					piece = "wall_plaster_door_round"
				elif side.x != 0 and cz == 0:
					piece = "wall_plaster_window_wide_round"
				if structures.call("place", piece, edge["position"], float(edge["yaw"])) != null:
					placed += 1
				if is_doorway:
					for extra in ["doorframe_round_wooddark", "door_1_round"]:
						if structures.call("place", extra, edge["position"], float(edge["yaw"])) != null:
							placed += 1
	var roof: Vector3 = GRID.snap_to_cell(base + Vector3(GRID.CELL * 0.5, 0.0, GRID.CELL * 0.5))
	roof.y = _world.call("ground_height_at", roof.x, roof.z) + GRID.STOREY
	if structures.call("place", "roof_roundtiles_4x4", roof, 0.0) != null:
		placed += 1
	print("  built a %d-piece cottage with a door in it beside the spawn" % placed)
	for i in 20:
		await physics_frame


## The menus, opened the way a player opens them — through the real actions.
##
## A screen that only appears when a harness instances it is not a screen a
## player can reach, and `tools/play_session.gd` says so at length. The one
## exception is the release ceremony, which needs a sixth creature caught while
## the party is full; that is a thirty-five minute session on its own, so the
## ceremony object is opened directly and pushed onto the game's own stack. The
## SCREENS are the game's; only the trigger is not.
func _chapter_menus() -> void:
	print("")
	print("-- menus --")
	# Nothing below is worth photographing from inside a fight.
	await _leave_any_fight()
	var stack: Node = _world.get_node_or_null(^"ScreenStack")
	var bag: Node = _world.get_node_or_null(^"TrainerInventory")
	var party: Node = _world.get_node_or_null(^"Party")
	var build: Node = _world.get_node_or_null(^"BuildMode")
	if stack == null or bag == null or party == null:
		_find("the world has no ScreenStack, TrainerInventory or Party; menu frames are missing")
		return

	_show_hud(true)
	_use_game_camera()
	await _stand_player(_ground_at(Vector2(4.0, 4.0)), _ground_at(Vector2(4.0, 20.0)))

	# Something in the bag, so the inventory screen is photographed with stock in
	# it rather than empty. Every one of these is an item the game already grants
	# or drops; nothing new is invented.
	var inventory: RefCounted = bag.call("inventory")
	for line: Variant in [
		["wood", 60], ["stone", 40], ["fiber", 40], ["berries", 12],
		["axe", 1], ["pickaxe", 1], ["tether_orb", 8], ["revival_draught", 2],
	]:
		var pair: Array = line
		inventory.call("add", str(pair[0]), int(pair[1]))

	# The ordinary HUD, with nothing open over it, so the menus can be compared
	# against the screen the player is normally looking at.
	if _hud != null:
		_hud.visible = true
	for i in 20:
		await physics_frame
	await _shoot("58-menu-hud-in-world", "menus",
		"the game with nothing open: the M1 debug HUD, the minimap and the interact prompt", true)
	if _hud != null:
		_hud.visible = false

	# Build mode, with a ghost standing where a piece would go.
	if build == null:
		_find("no BuildMode node; the build palette frames are missing")
	else:
		await _press("build_toggle")
		for i in 30:
			await physics_frame
		if not bool(build.call("is_open")):
			_find("pressing build_toggle did not open build mode; no palette frames")
		else:
			await _shoot("49-menu-build-palette-ghost", "menus",
				("the build palette with the ghost of '%s' standing in the world, valid=%s" % [
					build.call("selected_name"), build.call("ghost_valid")]), true)
			# `combat_quick` is what places a piece — build mode reads its own
			# actions and `interact` is not one of them.
			await _press("combat_quick")
			for i in 30:
				await physics_frame
			await _shoot("50-menu-build-placed", "menus",
				"the palette after placing a piece, showing the placement message and the cost", true)
			await _press("build_toggle")
			for i in 20:
				await physics_frame

	# The party screen.
	await _press("party_menu")
	for i in 30:
		await physics_frame
	if not bool(stack.call("is_open")):
		_find("pressing party_menu opened no screen")
	await _shoot("51-menu-party-screen", "menus",
		"the party screen: %s" % _top_name(stack), true)
	await _press("menu_cancel")
	for i in 20:
		await physics_frame

	await _press("inventory")
	for i in 30:
		await physics_frame
	await _shoot("52-menu-inventory-screen", "menus",
		"the inventory screen: %s" % _top_name(stack), true)
	await _press("menu_cancel")
	for i in 20:
		await physics_frame

	await _press("map")
	for i in 30:
		await physics_frame
	await _shoot("53-menu-map-screen", "menus",
		"the map screen: %s" % _top_name(stack), true)
	await _press("menu_cancel")
	for i in 20:
		await physics_frame

	await _ceremony_frames(stack, party)


## All four screens of the release ceremony, on the game's own screen stack, over
## the running world rather than over a flat backdrop.
func _ceremony_frames(stack: Node, party: Node) -> void:
	var screen: Control = stack.get_node_or_null(^"ReleaseScreen") as Control
	if screen == null:
		_find("the screen stack has no ReleaseScreen; the ceremony frames are missing")
		return
	var roster: RefCounted = party.get("party") as RefCounted
	if roster == null:
		_find("the party manager holds no party object; the ceremony frames are missing")
		return

	# Fill to the cap, then a sixth. Five is the hard rule; the ceremony is what
	# the game does about the sixth, and it cannot open on a party with room.
	var ids := SPECIES.ids()
	var guard := 0
	while int(party.call("size")) < int(party.call("capacity")) and guard < 12:
		guard += 1
		var pal: RefCounted = SPECIES.spawn(str(ids[guard % ids.size()]))
		pal.set_level(6 + guard * 3)
		if not bool(party.call("add", pal)):
			break
	if not bool(party.call("is_full")):
		_find("could not fill the party to its cap (%d of %d); the ceremony may refuse" % [
			party.call("size"), party.call("capacity")])

	var newcomer: RefCounted = SPECIES.spawn("evolved_wolf")
	newcomer.set_level(31)
	newcomer.hp = newcomer.max_hp * 0.05
	var ceremony: RefCounted = CEREMONY.open(roster, newcomer)
	if ceremony == null:
		_find("the ceremony refused to open on a party of %d; its frames are missing" % party.call("size"))
		return

	screen.call("set_ceremony", ceremony)
	stack.call("push", screen)
	for i in 30:
		await process_frame
	await _shoot("54-menu-ceremony-six", "menus",
		"the release ceremony: five kept pals and the newcomer, all six on one screen", true)

	await _press("move_right")
	await _shoot("55-menu-ceremony-focused", "menus",
		"the ceremony with a different card focused, showing what one pal's detail looks like", true)

	await _press("menu_cancel")
	await _shoot("56-menu-ceremony-refused", "menus",
		"the ceremony refusing to be dismissed — it has to say why and stay", true)

	await _press("menu_confirm")
	await _shoot("57-menu-ceremony-farewell", "menus",
		"the farewell screen: the last thing the player sees before a pal leaves for good", true)

	# Off the stack, whichever screens are on it, so combat is not driven with a
	# menu up and the tree paused.
	for i in 6:
		if not bool(stack.call("is_open")):
			break
		await _press("menu_cancel")
	if bool(stack.call("is_open")):
		stack.call("clear")
	for i in 20:
		await physics_frame


## A fight, from the prompt to the wobble, through the arena camera.
##
## Every beat here is waited on by STATE and not by a frame count. Under software
## rendering one process frame can be a fifth of a second of game time — longer
## than the enemy's whole wind-up — so a fixed wait reliably photographs the beat
## AFTER the one it is named for. `tools/survey_combat.gd` records what that cost
## the last time: a frame called "quick attack lands" taken before the blow, and
## a blind critic concluding from it that a hit produces no visual event.
func _chapter_combat() -> void:
	print("")
	print("-- combat --")
	# This chapter opens its OWN fight and photographs it from the first beat. A
	# fight already running would make frame 39 — "walking up to a wild creature" —
	# a picture of the middle of somebody else's, which is what the first run
	# produced.
	await _leave_any_fight()
	var manager: Node = _world.get_node_or_null(^"CombatManager")
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	if manager == null or director == null:
		_find("no CombatManager or EncounterDirector; no combat frames")
		return

	_show_hud(true)
	_use_game_camera()

	var wild: Node3D = director.call("wild_pal") as Node3D
	if wild == null or not bool(wild.call("is_alive")):
		var alive: Array = director.call("wild_pals")
		wild = null
		for entry: Variant in alive:
			var candidate: Node3D = entry
			if bool(candidate.call("is_alive")) and candidate.visible:
				wild = candidate
				break
	if wild == null:
		_find("there is no living wild creature to fight; the combat chapter is empty")
		return

	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	await _stand_player(wild.global_position + Vector3(3.2, 0.0, 3.2), wild.global_position)
	for i in 40:
		await physics_frame
	await _shoot("39-combat-approach", "combat",
		"walking up to a wild creature: the engage prompt, at %.1fm inside a %.1fm range" % [
			wild.global_position.distance_to(_player.global_position), engage_range], true)

	await _press("interact")
	for i in 60:
		await physics_frame
	if not bool(manager.call("is_fighting")):
		_find("pressing interact beside a wild creature did not open a fight; no combat frames after 39")
		return
	var ally: Node3D = director.call("ally_body") as Node3D
	await _shoot("40-combat-arena-opens", "combat",
		"the arena: the player's pal deployed, the opponent opposite, the trainer still in shot", true)

	await _drive(ally, wild, manager, 90, 2.6)
	await _shoot("41-combat-closing-in", "combat",
		"piloting your own pal towards the opponent, at creature height", true)

	var waited := 0
	while not bool(manager.call("enemy_is_winding_up")) and bool(manager.call("is_fighting")) and waited < 900:
		await _drive(ally, wild, manager, 1, 2.4)
		waited += 1
	await _shoot("42-combat-enemy-winds-up", "combat",
		"the enemy's telegraph — the fight's only warning, and the thing a player acts on", true)

	await _drive(ally, wild, manager, 120, 2.8)
	await _press("combat_quick")
	await _impact("43-combat-quick-attack", manager, "a quick attack landing, caught on the frame the blow lands")

	while not bool(manager.call("charged_ready")) and bool(manager.call("is_fighting")):
		await _drive(ally, wild, manager, 30, 2.8)
		await _press("combat_quick")
		for i in 24:
			await physics_frame
	await _drive(ally, wild, manager, 60, 2.8)
	await _press("combat_charged")
	await _impact("44-combat-charged-attack", manager,
		"the charged attack landing: a full meter and half a second rooted, so it has to look heavier")

	# The aim. The camera leaves the pal and goes over the trainer's shoulder.
	if not await _open_the_aim(manager):
		_find("could not open the throw aim; frames 45, 46 and 47 are missing")
		return
	await _shoot("45-combat-aim-reticle", "combat",
		"aim mode: the reticle up, over the trainer's shoulder, with your own pal undefended in shot", true)

	# The orb in flight, and then the wobble. `catch_resolved` and `orb_shook` are
	# the manager's own events; the wobble is waited on rather than timed, because
	# a throw that misses never wobbles at all and a frame named for the wobble
	# would then be a frame of grass.
	var shook := [0]
	var resolved := [false, false, 0]
	var on_shake := func(index: int) -> void: shook[0] = index
	var on_resolved := func(success: bool, shakes: int) -> void:
		resolved[0] = true
		resolved[1] = success
		resolved[2] = shakes
	manager.connect("orb_shook", on_shake)
	manager.connect("catch_resolved", on_resolved)

	await _press("combat_throw")
	for i in 7:
		await physics_frame
	await _shoot("46-combat-orb-in-flight", "combat",
		"the orb in the air: a small fast object against sunlit grass, which is the background of every throw", true)

	var spun := 0
	while shook[0] < 1 and not resolved[0] and spun < 900:
		await physics_frame
		spun += 1
	if shook[0] < 1 and not resolved[0]:
		_find("the orb never resolved into a catch attempt; frame 47 shows whatever was on screen instead")
	await _shoot("47-combat-capture-wobble", "combat",
		"the capture: the creature is inside the orb and the orb is wobbling (shake %d of the roll)" % shook[0], true)

	var settled := 0
	while not resolved[0] and settled < 900:
		await physics_frame
		settled += 1
	if manager.is_connected("orb_shook", on_shake):
		manager.disconnect("orb_shook", on_shake)
	if manager.is_connected("catch_resolved", on_resolved):
		manager.disconnect("catch_resolved", on_resolved)
	for i in 40:
		await physics_frame
	await _shoot("48-combat-outcome", "combat",
		"the moment after the throw resolves: %s after %d wobbles" % [
			("CAUGHT" if resolved[1] else "it broke out") if resolved[0] else "unresolved",
			int(resolved[2])], true)
	print("  catch resolved=%s success=%s shakes=%d" % [resolved[0], resolved[1], resolved[2]])


# --- driving ------------------------------------------------------------------

## Pilot the player's pal towards the opponent, steered through the camera —
## which is the same path the player's stick takes.
func _drive(ally: Node3D, wild: Node3D, manager: Node, frames: int, stop_at: float) -> void:
	if ally == null or wild == null:
		for i in frames:
			await physics_frame
		return
	for i in frames:
		if not bool(manager.call("is_fighting")):
			Input.action_release("move_forward")
			return
		var to := wild.global_position - ally.global_position
		to.y = 0.0
		if _rig != null:
			_rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > stop_at:
			Input.action_press("move_forward")
		else:
			Input.action_release("move_forward")
		await physics_frame
	Input.action_release("move_forward")


## Wait for the pal to finish whatever it is committed to, then open the aim and
## wait until it is actually open — on state, not on a count. A fixed wait once
## captured the tail of the charged attack's recovery, during which the throw
## press is correctly ignored, and the survey came back with two frames of
## ordinary combat labelled as aiming.
func _open_the_aim(manager: Node) -> bool:
	for i in 240:
		if not bool(manager.call("is_fighting")):
			return false
		if not bool(manager.call("player_is_committed")):
			break
		await physics_frame
	await _press("combat_throw")
	for i in 240:
		if bool(manager.call("is_aiming")):
			break
		await physics_frame
	if not bool(manager.call("is_aiming")):
		return false
	# Lead the target: the orb flies a real arc, so pointing straight at the
	# creature aims under it.
	for i in 8:
		await process_frame
		_aim_at(manager)
	return true


func _aim_at(manager: Node) -> void:
	var wild: Node3D = manager.call("enemy_body") as Node3D if manager.has_method("enemy_body") else null
	if wild == null:
		var director: Node = _world.get_node_or_null(^"EncounterDirector")
		if director != null:
			wild = director.call("wild_pal") as Node3D
	if wild == null or _rig == null:
		return
	var cfg: Dictionary = CATCH.config().get("throw", {})
	var speed := float(cfg.get("speed", 17.0))
	var gravity := float(cfg.get("gravity", 14.0))
	var origin := _player.global_position + Vector3.UP * float(cfg.get("spawn_height", 1.5))
	var to: Vector3 = (wild.call("centre") as Vector3) - origin
	var flat := Vector2(to.x, to.z).length()
	var flight := flat / maxf(speed, 0.01)
	_rig.set("yaw", atan2(-to.x, -to.z))
	_rig.set("pitch", atan2(to.y + 0.5 * gravity * flight * flight, maxf(flat, 0.01)))


## Shoot the frame the blow actually lands on.
##
## Wait for `hit_landed`, let the burst open, THEN stop the clock. Both halves
## are needed and each was wrong on its own: a node added mid-frame does not run
## its first `_physics_process` until the next tick, so pausing immediately
## freezes an effect that has drawn nothing — and without pausing, one software
## frame costs a real fraction of a second while physics keeps ticking, so a
## 0.3-second effect is long dead by the time the shutter opens.
func _impact(name: String, manager: Node, intent: String) -> void:
	var landed := [false]
	var handler := func(_on_enemy: bool, _amount: float) -> void: landed[0] = true
	manager.connect("hit_landed", handler)
	var waited := 0
	while not landed[0] and waited < 240 and bool(manager.call("is_fighting")):
		await physics_frame
		waited += 1
	if manager.is_connected("hit_landed", handler):
		manager.disconnect("hit_landed", handler)
	if not landed[0]:
		_find("%s: no hit landed within 240 frames; the frame shows the lull, not the blow" % name)
	for i in 5:
		await physics_frame
	paused = true
	await _shoot(name, "combat", intent, true)
	paused = false


## Get out of a fight, and keep pressing until the fight is actually over.
##
## ONE PRESS IS NOT ENOUGH and the first run proved it. `combat_manager` reads
## Run inside `_read_player_input`, which returns early while the pal is
## committed to a move or while the throw is busy — so a single press landing in
## a wind-up is correctly ignored, and the harness walked on into the next
## chapter still inside the fight. Frames 59 to 62 of that run were photographed
## with the combat HUD up and an enemy health bar across the top of a picture of
## a bed.
func _leave_any_fight() -> void:
	var manager: Node = _world.get_node_or_null(^"CombatManager")
	if manager == null or not bool(manager.call("is_fighting")):
		return
	for attempt in 12:
		await _press("combat_run")
		for i in 40:
			await physics_frame
			if not bool(manager.call("is_fighting")):
				print("  left the fight after %d press(es) of Run" % (attempt + 1))
				return
	_find("pressing Run %d times did not end the fight; frames after this one have a combat HUD on them"
		% 12)


## Press an action and HOLD it across physics frames.
##
## Not pressed and released in one call. The two kinds of input in
## `screen_stack.gd` are read differently: buttons latch for the frame the press
## was recorded in, but DIRECTIONS come from `Input.get_axis()`, which reports
## what is held right now — so a press and release inside one call is never held
## during a physics frame and the cursor does not move. `preview_ceremony.gd`
## shipped with that bug and produced two byte-identical PNGs of the same screen,
## logged as two different screens.
func _press(action: StringName) -> void:
	Input.action_press(action)
	for i in 8:
		await physics_frame
	Input.action_release(action)
	for i in 6:
		await physics_frame


# --- posing -------------------------------------------------------------------

func _pose(view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_ground: float = _field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = _field.height_at(target_xz.x, target_xz.y)
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = FOV
	_cam.global_position = Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
	_cam.look_at(
		Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y), Vector3.UP)
	if bool(view.get("aim", false)):
		return
	# `look_at` fixes the heading; the pitch is then overridden so the horizon
	# lands where the composition wants it. Heading is a content choice, pitch is
	# a framing one — and stating the framing as "sky is 28% of this shot" means
	# the number a critic measures and the number in this file are the same one.
	_cam.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))), _cam.rotation.y, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


## Stand the trainer in shot for viewpoints that ask for one, and park him out of
## shot for the ones that do not.
##
## Parked rather than hidden: hiding disables the body, and a disabled body is a
## different scene from the one being photographed.
##
## ON THE GROUND, AND WITH HIS VELOCITY ZEROED — both of which `tools/survey.gd`
## does not do, because it predates fall damage and death. Parking him at
## (9000, 200, 9000) drops him off the edge of a 512m world, and the first run of
## this file did exactly that: he accumulated a fall, was teleported back into
## the next shot still falling at terminal speed, went through the terrain, and
## died. The log says so — `[death] fell at 9, -1, 7 — 3 stack(s) in satchel,
## woke at 0, 1, 0` — and frame `05-world-spawn-low-sun` came back with a brown
## crate standing exactly where the trainer should have been. That crate was his
## death satchel. The harness had killed the subject of the photograph.
const PARKING := Vector2(232.0, 232.0)


func _park_actor(view: Dictionary) -> void:
	if _player == null:
		return
	var xz: Vector2 = view["actor"] if view.has("actor") else PARKING
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(
		xz.x, _field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	if not view.has("actor"):
		return
	var away := _player.global_position - _cam.global_position
	_player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


## Put the trainer somewhere and point the gameplay camera at something.
##
## Moved rather than walked: the stronghold road is 130 metres of ground the
## smoke suite already proves is walkable, and walking it under software
## rendering costs minutes per frame for nothing any of these frames asks about.
func _stand_player(at: Vector3, look_at: Vector3) -> void:
	if _player == null:
		return
	var height := at.y
	if _world != null and _world.has_method("ground_height_at"):
		var ground: float = float(_world.call("ground_height_at", at.x, at.z))
		if not is_nan(ground):
			height = ground
	_player.global_position = Vector3(at.x, height + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	if _rig != null:
		var to := look_at - _player.global_position
		_rig.set("yaw", atan2(-to.x, -to.z))
		_rig.set("pitch", deg_to_rad(-6.0))
	for i in SETTLE_AFTER_MOVE:
		await physics_frame


## One frame of the trainer, framed relative to the way he is currently FACING,
## so the figure sits in the same place in every sample and the only thing that
## changes between them is the pose. Optionally with the clock stopped, which is
## what makes the printed pose and the rendered pose the same instant.
func _actor_frame(name: String, offset: Vector3, intent: String, settle: int, freeze: bool = false) -> void:
	for i in settle:
		await physics_frame
	if freeze:
		paused = true
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	var yaw: float = 0.0 if model == null else model.rotation.y
	var feet := _player.global_position
	_cam.global_position = feet + Basis(Vector3.UP, yaw) * offset
	_cam.look_at(feet + Vector3(0.0, 0.95, 0.0), Vector3.UP)
	_cam.make_current()
	var clip := ""
	var anim := _animation_player(model)
	if anim != null:
		clip = "%s @ %.2fs" % [anim.current_animation, anim.current_animation_position]
	await _shoot(name, "characters", "%s (%s)" % [intent, clip], false)
	if freeze:
		paused = false


func _use_own_camera() -> void:
	if _rig != null:
		_rig.set_process(false)
		_rig.set_physics_process(false)
	if _cam != null:
		_cam.make_current()


func _use_game_camera() -> void:
	if _rig != null:
		_rig.set_process(true)
		_rig.set_physics_process(true)
	if _lens != null:
		_lens.make_current()


## The HUD choice, made per chapter and recorded in the manifest.
##
## `PlaygroundHUD` stays off even for gameplay frames: it is the M1 movement
## telemetry, and frame 58 exists to show it once rather than have it over every
## picture. The minimap and the combat HUD are shipping UI and belong in a
## gameplay shot.
func _show_hud(gameplay: bool) -> void:
	if _hud != null:
		_hud.visible = false
	if _minimap != null:
		_minimap.visible = gameplay


func _ground_at(xz: Vector2) -> Vector3:
	var y: float = 0.0
	if _field != null:
		y = _field.height_at(xz.x, xz.y)
	return Vector3(xz.x, y, xz.y)


func _site_origin(site: String) -> Vector3:
	var sites: Dictionary = RULES.settlement().get("sites", {})
	var entry: Variant = sites.get(site, {})
	if not entry is Dictionary:
		return Vector3.ZERO
	var at: Array = (entry as Dictionary).get("origin", [0.0, 0.0])
	return _ground_at(Vector2(float(at[0]), float(at[1])))


func _top_name(stack: Node) -> String:
	var top: Variant = stack.call("top")
	return "nothing is open" if not (top is Node) else str((top as Node).name)


# --- capture ------------------------------------------------------------------

## Take the picture, prove it landed, and say so out loud when it did not.
##
## Everything a reviewer needs to trust the frame is measured here: that the file
## exists, that it has bytes in it, that it was written during THIS run, that it
## is not byte-identical to another frame in the same run, and that it is not one
## flat colour — which is what a rendering failure looks like when it is dressed
## up as a dark scene.
func _shoot(name: String, chapter: String, intent: String, gameplay_hud: bool) -> void:
	_slow_rendering(true)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_slow_rendering(false)

	var entry := {
		"file": "%s.png" % name,
		"chapter": chapter,
		"intent": intent,
		"hud": "minimap + combat HUD" if gameplay_hud else "none",
		"ok": false,
		"note": "",
		"bytes": 0,
		"sha": "",
	}

	if image == null:
		entry["note"] = "the viewport returned no image"
		_manifest.append(entry)
		print("  %-34s FAILED: no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		entry["note"] = "save_png failed (%d)" % error
		_manifest.append(entry)
		print("  %-34s FAILED: save_png %d" % [name, error])
		return
	if not FileAccess.file_exists(path):
		entry["note"] = "save_png reported success and wrote no file"
		_manifest.append(entry)
		print("  %-34s FAILED: nothing on disk" % name)
		return

	var handle := FileAccess.open(path, FileAccess.READ)
	entry["bytes"] = 0 if handle == null else handle.get_length()
	entry["sha"] = FileAccess.get_sha256(path)
	var written_at := FileAccess.get_modified_time(path)

	var notes: Array[String] = []
	if int(entry["bytes"]) <= 0:
		notes.append("THE FILE IS EMPTY")
	if written_at < _started_at:
		notes.append("WRITTEN BEFORE THIS RUN STARTED (%d < %d) — it is not this run's frame" % [
			written_at, _started_at])
	var flat := _flatness(image)
	if flat < 0.02:
		notes.append("almost a single flat colour (spread %.4f); nothing rendered" % flat)
	var sha := str(entry["sha"])
	if _seen.has(sha):
		notes.append("BYTE-IDENTICAL to %s — whatever was supposed to change did not" % _seen[sha])
	else:
		_seen[sha] = entry["file"]

	entry["ok"] = notes.is_empty()
	entry["note"] = " / ".join(notes)
	_manifest.append(entry)
	print("  %-34s %7d bytes  spread %.3f  %s" % [
		name, entry["bytes"], flat, "ok" if entry["ok"] else ("!! " + str(entry["note"]))])


## Rendering off between shots. A software-rendered frame of this scene costs
## about two seconds of wall clock, and a boot settles for hundreds of physics
## frames — with the render loop left on, this run takes hours and every one of
## them draws a frame nobody will ever see.
func _slow_rendering(on: bool) -> void:
	if _rendering == on:
		return
	_rendering = on
	RenderingServer.render_loop_enabled = on


## Rough measure of how much the frame varies, sampled on a grid. Plenty to tell
## "a rendered scene" from "a flat fill", which is the only thing it is for.
func _flatness(image: Image) -> float:
	var width := image.get_width()
	var height := image.get_height()
	var step := maxi(1, width / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, height, step):
		for x in range(0, width, step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()


# --- bookkeeping --------------------------------------------------------------

func _find(line: String) -> void:
	_findings.append(line)
	print("  FINDING: %s" % line)


## Clear the frames this run is about to write, BEFORE it writes any of them.
##
## `tools/play_session.gd` learned why: two runs once wrote the same filenames
## and produced a set of eleven correctly-numbered frames from two different
## games. A stale frame from an earlier run is indistinguishable from a fresh one
## unless it is impossible for it to still be there.
func _clear_prior_output() -> void:
	var dir := DirAccess.open(OUT_DIR)
	if dir == null:
		print("  no previous %s to clear" % OUT_DIR)
		return
	var removed := 0
	var kept := 0
	for file in dir.get_files():
		if not (file.ends_with(".png") or file.ends_with(".png.import") or file == "MANIFEST.txt"):
			continue
		var mine: bool = file == "MANIFEST.txt" or _chapters.has(_chapter_of(file))
		if not mine:
			kept += 1
			continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s" % [OUT_DIR, file]))
		removed += 1
	print("  cleared %d file(s) from %s, kept %d belonging to chapters not being run" % [
		removed, OUT_DIR, kept])


## Which chapter owns a frame, by its number.
##
## Read off the NUMBER rather than off the name. The three studio frames are
## named for what they show — two trainers and a creature rank — and clearing by
## the word in the filename would leave them behind when the studio is re-shot
## and delete them when the creatures are. A partial run that silently keeps one
## stale frame is exactly the failure this whole file is arranged against.
const NUMBER_RANGES := [
	{"from": 1, "to": 13, "chapter": "world"},
	{"from": 14, "to": 22, "chapter": "weather"},
	{"from": 23, "to": 28, "chapter": "characters"},
	{"from": 29, "to": 31, "chapter": "studio"},
	{"from": 32, "to": 38, "chapter": "creatures"},
	{"from": 39, "to": 48, "chapter": "combat"},
	{"from": 49, "to": 58, "chapter": "menus"},
	{"from": 59, "to": 62, "chapter": "home"},
	{"from": 63, "to": 70, "chapter": "doors"},
]


func _chapter_of(file: String) -> String:
	var head := file.split("-")[0]
	if not head.is_valid_int():
		return ""
	var number := int(head)
	for entry: Variant in NUMBER_RANGES:
		var band: Dictionary = entry
		if number >= int(band["from"]) and number <= int(band["to"]):
			return str(band["chapter"])
	return ""


## Delete slot 0 before the world exists.
##
## `SaveDirector` restores it at boot, so without this the world comes up holding
## a previous run's party and buildings — and every frame would be a photograph
## of somebody else's game, in a way that reads as perfectly ordinary.
func _wipe_save() -> void:
	var save: Node = root.get_node_or_null(^"/root/SaveManager")
	if save == null:
		print("  SaveManager not attached before boot; no save could be cleared")
		return
	var existed: bool = bool(save.call("has_slot", 0)) if save.has_method("has_slot") else false
	if existed and save.has_method("delete_slot"):
		save.call("delete_slot", 0)
	print("  a save existed before this run: %s; slot 0 exists going into the world: %s" % [
		existed, bool(save.call("has_slot", 0)) if save.has_method("has_slot") else "unknown"])


func _finish() -> void:
	_slow_rendering(true)
	var lines := PackedStringArray()
	lines.append("TETHERBOUND — WHOLE-GAME CAPTURE")
	lines.append("run %s   started %s UTC" % [_run_id, Time.get_datetime_string_from_unix_time(_started_at)])
	lines.append("renderer %s, Compatibility under Xvfb (D06): composition, silhouette, colour and"
		% DisplayServer.get_name())
	lines.append("framing are trustworthy here; lighting quality and frame times are NOT.")
	lines.append("chapters: %s" % ", ".join(_chapters))
	lines.append("")

	var ok := 0
	lines.append("%-38s %-11s %-22s %s" % ["FRAME", "CHAPTER", "HUD", "WHAT IT IS MEANT TO SHOW"])
	for entry: Dictionary in _manifest:
		if bool(entry["ok"]):
			ok += 1
		lines.append("%-38s %-11s %-22s %s" % [
			entry["file"], entry["chapter"], entry["hud"], entry["intent"]])
		lines.append("%-38s %-11s %s" % [
			"", "", "-> %s  %d bytes  sha %s" % [
				"OK" if bool(entry["ok"]) else "PROBLEM: " + str(entry["note"]),
				entry["bytes"], str(entry["sha"]).substr(0, 16)]])
	lines.append("")
	lines.append("%d of %d frames landed cleanly." % [ok, _manifest.size()])
	lines.append("")

	# EVERY PNG IN THE DIRECTORY, not only the ones this run wrote.
	#
	# A chapter can be re-shot on its own, which leaves frames from an earlier run
	# sitting beside this one's. A manifest that lists only what this process
	# wrote would describe a sheet that is not the sheet on disk — and "the
	# transcript and the pictures disagree about which game they are of" is the
	# exact failure `tools/play_session.gd` records. So the carried-over frames are
	# named, with the time they were written, and a reader can decide for
	# themselves whether that is old enough to matter.
	var mine := PackedStringArray()
	for entry: Dictionary in _manifest:
		mine.append(str(entry["file"]))
	var carried := PackedStringArray()
	var dir := DirAccess.open(OUT_DIR)
	if dir != null:
		for file in dir.get_files():
			if not file.ends_with(".png") or file.begins_with("_") or mine.has(file):
				continue
			var when := FileAccess.get_modified_time("%s/%s" % [OUT_DIR, file])
			carried.append("  %-38s written %s UTC, by an earlier run" % [
				file, Time.get_datetime_string_from_unix_time(when)])
	if carried.is_empty():
		lines.append("Every frame in %s was written by this run." % OUT_DIR)
	else:
		lines.append("FRAMES IN %s THAT THIS RUN DID NOT WRITE (%d):" % [OUT_DIR, carried.size()])
		for line in carried:
			lines.append(line)
	lines.append("")

	lines.append("SHOTS ON THE OWNER'S LIST THAT CANNOT BE PRODUCED, AND WHY")
	lines.append("  GRANDPA      — there is no Grandpa. There is no NPC of any kind in this project:")
	lines.append("                 no character node, no schedule, no interaction. GAME_DESIGN 3's")
	lines.append("                 story frame is entirely unimplemented. His HOUSE is authored")
	lines.append("                 geography and is photographed, inside and out, in frames 13 and")
	lines.append("                 63-66. The man is not substituted for.")
	lines.append("  THE DIALOGUE — there is no dialogue system, no dialogue data and no quest code.")
	lines.append("                 Nothing in the game ever says anything to the player except the")
	lines.append("                 interact prompt and the menus, both of which are photographed.")
	lines.append("")

	if _findings.is_empty():
		lines.append("Nothing else refused, and no state was found unreachable.")
	else:
		lines.append("EVERYTHING ELSE THAT REFUSED, WAS UNREACHABLE, OR LOOKED WRONG WHILE SHOOTING")
		for line in _findings:
			lines.append("  * %s" % line)

	var text := "\n".join(lines)
	print("")
	print(text)
	var out := FileAccess.open("%s/MANIFEST.txt" % OUT_DIR, FileAccess.WRITE)
	if out != null:
		out.store_string(text + "\n")
		out.close()
		print("")
		print("manifest -> %s/MANIFEST.txt" % OUT_DIR)
	quit(0)


# --- studio furniture ---------------------------------------------------------

func _studio_light(stage: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.17, 0.19, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.76, 0.79, 0.84)
	e.ambient_light_energy = 1.3
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	stage.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-32.0), 0.0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	stage.add_child(key)


## The floor is painted the meadow's own measured olive, and it has a COLLIDER
## under it. `pal_body` is a CharacterBody3D and runs gravity the moment it is
## visible; without a floor to land on, every creature falls out of the frame
## during the settle and the sheet renders as an empty field — which is exactly
## what MA-04 got and reported as "_creatures.png contains no creatures".
func _studio_floor(stage: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.33, 0.36, 0.21)
	mat.roughness = 0.95
	ground.material_override = mat
	stage.add_child(ground)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(shape)
	stage.add_child(body)


## The player's own trainer, posed mid-clip.
##
## `trainer_model` drives its clips off a `CharacterBody3D` it has not got on a
## studio stage, so it would hold a bind pose — and frame zero of most libraries
## is very close to the bind pose, which is also the pose a BROKEN retarget
## produces. Seeking into the idle is what tells those two apart.
func _studio_player_trainer(stage: Node3D, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.set_script(PLAYER_MODEL)
	stage.add_child(node)
	node.position = at
	var anim := _animation_player(node)
	if anim != null and anim.has_animation("Idle_A"):
		anim.play("Idle_A")
		anim.seek(0.5, true)
	else:
		_find("the reference trainer has no Idle_A clip; he is standing in his bind pose")
	return node


func _studio_tether(stage: Node3D, definition: Dictionary, at: Vector3) -> void:
	var node := Node3D.new()
	node.set_script(TETHER_MODEL)
	node.call("configure", definition)
	stage.add_child(node)
	node.position = at


func _studio_ruler(stage: Node3D, at: Vector3, height: float) -> void:
	var post := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.05, height, 0.05)
	post.mesh = bar
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.88, 0.89, 0.91)
	post.material_override = pale
	stage.add_child(post)
	post.position = at + Vector3(0.0, height * 0.5, 0.0)


# --- small helpers ------------------------------------------------------------

## How much room a creature needs in a rank, along its own long axis.
##
## Measured off the model where there is one, and off the species' declared
## collider where there is not. `meadows_legendary` has `model: ""` — it is drawn
## as a capsule built at runtime, outside the `Model` node — so the measured
## length is 0.00m, and a rank spaced on that stands the next creature and the
## trainer INSIDE it. The first pass did exactly that and the legendary's
## placeholder swallowed the Palehorn's head and half the trainer.
func _measured_length(body: Node3D, id: String) -> float:
	var model := body.get_node_or_null(^"Model") as Node3D
	var length: float = 0.0 if model == null else _model_bounds(model).size.z
	if length > 0.05:
		return length
	return maxf(1.0, float(SPECIES.placeholder(id).get("radius", 0.5)) * 2.0)


func _model_bounds(node: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect(node, meshes)
	var box := AABB()
	var started := false
	var to_local := node.global_transform.affine_inverse()
	for mesh in meshes:
		var local: AABB = (to_local * mesh.global_transform) * mesh.get_aabb()
		box = local if not started else box.merge(local)
		started = true
	return box


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


func _animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _animation_player(child)
		if found != null:
			return found
	return null
