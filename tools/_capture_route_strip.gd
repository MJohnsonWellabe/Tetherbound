extends SceneTree
## KICKOFF (docs/acceptance/KICKOFF_RUN.md). The route strip: one frame every
## `--step` metres along the authored trail spine, at a walking player's eye
## height, looking the way the road goes. Every band, start to finish.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_route_strip.gd -- --step=40 --bands=1,2,3,4,5
##
## NEVER with `--headless` and a real rendering driver (it hangs forever).
##
## Why this exists beside tools/survey.gd and the composition stands: every
## visual verdict to date was made from a handful of fixed stands, chosen by
## whoever was fixing something. The two bar questions ask about the game the
## player walks through, and the player walks the road. This is the road, at
## the player's own eye, at a fixed cadence nobody picked to flatter a fix.
## The blind judge answers the bars on these sheets (D73).
##
## W01-ROUTE-STRIP (2026-09-04, docs/FINISH_THE_MEADOWS.md Phase 0.1). Until
## this the strip walked the spine and shot empty scenery: Bar B ("is this the
## same kind of game?") cannot be answered by a frame with nobody in it, and
## four blind passes said so. Now, borrowed from the capture tools that already
## knew how (`_capture_life.gd`'s pairing frame, `_capture_combat_moments.gd`'s
## engage/flee):
##
##   * The trainer's REAL party companion is summoned through the production
##     path before the walk -- `CreatureSpecies.spawn()` + `Game.party.add()`
##     + `EncounterDirector.summon_active_creature()`, the same three calls the
##     party screen's "send this one out" makes -- and stands beside the
##     trainer in every road frame, both facing the way the road goes.
##   * Once per band, the strip walks up to the band's nearest wild, engages
##     it through the director (a real `CombatManager` fight, arena, camera
##     hand-off and all), and takes one frame with the camera solved so that
##     trainer, companion AND opponent all fit and read -- the two-creature
##     solve that left the trainer out is the first lesson recorded in
##     `docs/VISUAL_PARITY_PROGRESS.md`.
##   * Every frame is refused, not saved, if `capture_check.readable_problems`
##     says a subject is missing, behind the camera, under 12% of the frame's
##     height, cropped or occluded. A refused frame is listed in the manifest
##     under `rejected` and the run exits non-zero, so the next reader knows a
##     frame is absent and why rather than judging an empty meadow.
##   * Fight cleanup is unconditional and runs AFTER `combat.json`'s 0.25 s
##     input guard (the second recorded lesson: a flee pressed inside the
##     guard is silently dropped); the walk continues only once the world is
##     back in the `world` input context, checked through the same resolver
##     the Gate F harness uses (`gate_f_probe.gd::input_context`).
##
## Camera maths copied from tools/_capture_band1_composition.gd (itself from
## tools/survey.gd). The trainer stands ON the road at the stand's arc metre;
## the eye is `CAM_BACK_M` behind them, so the pair is the 1.80 m ruler the
## rubric asks for and the road ahead is still the subject of the frame.
##
## Flags: `--step=<m>` (default 40), `--bands=1,3` (default all five),
## `--time=day|golden|night` (default day), `--out=res://shots_route`,
## `--max=<n>` (stop after n ROAD frames, for a smoke; the per-band fight
## frame is extra), `--fast` (halve settles), `--no-fight` (road frames only),
## `--fight-search=<m>` (how far from a stand to look for a wild, default 150).
## A `manifest.json` in the output directory maps every frame to its band,
## arc metre, world XZ and measured subjects, and lists every refused frame.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const GATE_F_PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 30
const ACTOR_CLEARANCE := 0.4
## The eye stands this far behind the trainer along the road. At 70 degrees
## vertical a 1.80 m trainer 6.5 m out is ~20% of the frame's height -- well
## over the 12% readable floor, and still small enough that the road, not the
## back of a head, is the frame.
const CAM_BACK_M := 6.5
## The companion stands this far to the trainer's right, at the same depth:
## the side-by-side pairing `_capture_life.gd` round 6 settled on, not the
## follower's own behind-the-shoulder rest spot, which the eye would be
## standing in.
const COMPANION_SIDE_M := 1.8
const EYE_H := 2.2
const TARGET_H := 1.6
const LOOK_AHEAD_M := 60.0
const FOV := 70.0
const HORIZON := 0.30
## Fight frame: the eye stands this high above the fighters' ground and looks
## at a point this high above their centroid.
## Run 2 of this lane, at 1.9 m: the fighters had closed to touching and the
## front one hid the back one on any ground-level bearing. A higher eye
## looking down separates bodies that stand in a line. Run 3's code-blind
## judge then called the resulting frame a high, distant view in which the
## fight occupied a twelfth of the picture, so this is the compromise: high
## enough to separate two bodies in a line, low enough to be a fight camera.
const FIGHT_EYE_H := 2.4
const FIGHT_LOOK_UP := 0.8
const FIGHT_MARGIN := 0.08
## No fighter may fill more than this of the frame: run 2's first fit put the
## companion at 69% with the fight behind it.
const FIGHT_MAX_HEIGHT_FRAC := 0.5
## And none may be smaller than this. Run 3 framed a mudsnout at 14.5% -- it
## passed every other rule and the judge reported it as unreadable and
## ambiguous with a background prop. A bearing that cannot satisfy both
## bounds is skipped rather than shot.
const FIGHT_MIN_HEIGHT_FRAC := 0.18
const FIGHT_D_MIN := 4.0
const FIGHT_D_MAX := 26.0
## How many physics ticks the trainer stands beside the wild before engaging,
## then after `begin()` before the shutter. The second must clear both
## `combat.json` flow.input_guard (0.25 s = 15 ticks at 60 Hz) -- the flee
## below is read by `_read_player_input`, which the guard gates -- and the
## camera hand-off, so the fight is visibly under way rather than mid-deploy.
const FIGHT_APPROACH_SETTLE := 25
const FIGHT_ENGAGE_SETTLE := 40
const FIGHT_GUARD_TICKS := 20
const ENGAGE_ATTEMPTS := 2
const ENGAGE_WAIT := 30
const FLEE_BOUND := 90
const DEFAULT_FIGHT_SEARCH_M := 150.0

var _step := 40.0
var _bands: Array[int] = [1, 2, 3, 4, 5]
var _time := "day"
var _out_dir := "res://shots_route"
var _max := 0
var _fast := false
var _fight := true
var _fight_search := DEFAULT_FIGHT_SEARCH_M

var _world: Node = null
var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _field: RefCounted = null
var _director: Node = null
var _manager: Node = null
var _companion: Node3D = null
var _weather: Node = null
## Wilds already fought for a fight frame this run, so a refused frame retries
## against a different opponent at the next stand rather than the same one.
var _fought: Array[Node3D] = []
var _failures: Array[String] = []
var _manifest: Array = []
var _rejected: Array = []
var _projection_checked := false


func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast else n


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--step="):
			_step = maxf(5.0, float(a.substr("--step=".length())))
		elif a.begins_with("--bands="):
			_bands.clear()
			for b in a.substr("--bands=".length()).split(",", false):
				_bands.append(int(b.strip_edges()))
		elif a.begins_with("--time="):
			_time = a.substr("--time=".length())
		elif a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
			_out_dir = _out_dir.trim_suffix("/")
		elif a.begins_with("--max="):
			_max = int(a.substr("--max=".length()))
		elif a == "--fast":
			_fast = true
		elif a == "--no-fight":
			_fight = false
		elif a.begins_with("--fight-search="):
			_fight_search = maxf(10.0, float(a.substr("--fight-search=".length())))
	_fast = _fast or OS.get_environment("VP_FAST") == "1"


func _run() -> void:
	_parse_args()
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run or a real GPU")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var config: Dictionary = HEIGHTFIELD.load_config()
	var bands: Array = (config.get("trail", {}) as Dictionary).get("bands", []) as Array
	if bands.is_empty():
		push_error("terrain_playground.json has no trail.bands; nothing to walk")
		quit(1)
		return

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	_world = packed.instantiate()
	root.add_child(_world)
	# `gate_f_probe.gd::input_context` and `capture_check.gd` both look for the
	# world through `current_scene`; a script-booted tree has none unless told.
	current_scene = _world

	_weather = _world.find_child("WorldWeather", true, false)
	_freeze_weather("at boot")

	for i in _frames(SETTLE_FRAMES):
		await physics_frame
	_freeze_weather("after the boot settle")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_camera = Camera3D.new()
	_camera.name = "RouteStripCamera"
	_camera.fov = FOV
	_camera.far = 2000.0
	_world.add_child(_camera)
	_camera.make_current()
	if _fast:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var look: Node = _world.get_node_or_null(^"WorldLook")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	_field = HEIGHTFIELD.new()
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", _time)
	_freeze_weather("after the clock pin")
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	else:
		_failures.append("no Terrain node with set_camera")
	if _player == null:
		_failures.append("no Player node; the strip cannot stage the trainer")
	if _director == null or _manager == null:
		_failures.append("no EncounterDirector/CombatManager; the strip cannot stage a companion or a fight")
	if not _failures.is_empty():
		_finish(0)
		return

	var written := 0
	var attempted := 0
	var band_index := 0
	for entry: Variant in bands:
		band_index += 1
		if not _bands.has(band_index):
			continue
		var band: Dictionary = entry
		var band_id := str(band.get("id", ""))
		var points: Array = band.get("points", []) as Array
		var line: PackedVector2Array = []
		for p: Variant in points:
			if p is Array and (p as Array).size() >= 2:
				line.append(Vector2(float(p[0]), float(p[1])))
		if line.size() < 2:
			_failures.append("band %d (%s) has fewer than two trail points" % [band_index, band_id])
			continue
		var total := _arc_length(line)
		var arc := 0.0
		var fight_done := not _fight
		while arc <= total:
			# The cap counts stands ATTEMPTED, not frames saved: a bounded
			# smoke whose frames are all refused must still stop.
			if _max > 0 and attempted >= _max:
				break
			attempted += 1
			var stand_xz := _point_at(line, arc)
			var look_xz := _point_at(line, minf(total, arc + LOOK_AHEAD_M))
			if look_xz.distance_to(stand_xz) < 1.0:
				# The last stand looks back the way it came rather than at itself.
				look_xz = _point_at(line, maxf(0.0, arc - LOOK_AHEAD_M))
			var eye_xz := _point_at(line, maxf(0.0, arc - CAM_BACK_M))
			if eye_xz.distance_to(stand_xz) < CAM_BACK_M - 0.5:
				# The very first stand has no road behind it: back the eye off
				# along the road's own opening bearing instead.
				var ahead := (look_xz - stand_xz).normalized()
				eye_xz = stand_xz - ahead * CAM_BACK_M

			# The companion is summoned once the trainer stands on the first
			# road stand, so `_spawn_ally_body` puts it on real ground beside
			# them rather than at wherever the scene booted the player.
			_place_trainer(stand_xz, look_xz)
			if _companion == null:
				for i in _frames(SETTLE_AFTER_MOVE):
					await physics_frame
				if not await _summon_companion():
					_finish(written)
					return
			_place_companion(stand_xz, look_xz)
			_pose_road_eye(eye_xz, stand_xz, look_xz)
			for i in _frames(SETTLE_AFTER_MOVE):
				await physics_frame
			# The follower keeps its own idea of where to stand; re-seat it
			# beside the trainer after the settle so the shutter sees the pair.
			_place_companion(stand_xz, look_xz)
			for i in _frames(POSE_FRAMES):
				await process_frame

			var name := "band%d_%05dm" % [band_index, int(round(arc))]
			# Every canvas layer goes dark for a road frame: run 2 caught the
			# flee's "You backed off." toast (a layer beside PlaygroundHUD) in
			# the next road shot. The fight frame keeps its HUD -- nameplates
			# and level tags are part of what 2.15 asked the strip to show.
			var layers := _hide_canvas_layers()
			for i in 2:
				await process_frame
			var subjects := _road_subjects()
			var problems := _frame_problems(subjects, [_player, _companion])
			var record := {
				"frame": name, "band": band_index, "band_id": band_id,
				"arc_m": snappedf(arc, 0.1), "x": snappedf(stand_xz.x, 0.1), "z": snappedf(stand_xz.y, 0.1),
				"look_x": snappedf(look_xz.x, 0.1), "look_z": snappedf(look_xz.y, 0.1), "time": _time,
				"subjects": _describe_subjects(subjects),
			}
			if problems.is_empty():
				if await _save(name):
					written += 1
					_manifest.append(record)
					print("  %-16s (%.1f, %.1f) trainer+%s -> %s/%s.png" % [
						name, stand_xz.x, stand_xz.y, _companion_species(), _out_dir, name])
			else:
				_reject(name, record, problems)
			_restore_canvas_layers(layers)
			arc += _step

			if not fight_done:
				fight_done = await _shoot_fight(band_index, band_id, stand_xz, look_xz)
		if not fight_done and _fight:
			_failures.append("band %d (%s): no fight frame -- no wild within %.0f m of any stand walked" % [
				band_index, band_id, _fight_search])
		if _max > 0 and attempted >= _max:
			break

	_finish(written)


## Write the manifest, print the verdict, exit. Non-zero when a frame was
## refused or a stage failed, so the kickoff run and its reader both see it.
func _finish(written: int) -> void:
	var mf := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if mf != null:
		mf.store_string(JSON.stringify({
			"step_m": _step, "time": _time, "frames": _manifest, "rejected": _rejected,
			"failures": _failures,
		}, "  "))
		mf.close()

	print("")
	print("%d route frames -> %s (%d refused)" % [written, _out_dir, _rejected.size()])
	for entry: Dictionary in _rejected:
		print("REFUSED %s:" % str(entry.get("frame", "?")))
		for line: String in (entry.get("problems", []) as Array):
			print("    * %s" % line)
	if not _failures.is_empty():
		for fail_line in _failures:
			print("FAIL: %s" % fail_line)
	quit(1 if (not _failures.is_empty() or not _rejected.is_empty()) else 0)


## Pin the weather to clear and FREEZE it, and say whether it was found
## ticking. Run 1 of this lane refused all 62 frames on `capture_check`'s
## "WorldWeather is still processing" line even though the pin was made at
## boot exactly as the old strip made it -- so the pin is re-applied before
## every shutter and each application reports what it found, so the log says
## which step thawed it rather than leaving the next reader to guess.
func _freeze_weather(when: String) -> void:
	if _weather == null or not is_instance_valid(_weather):
		if when == "at boot":
			_failures.append("no WorldWeather node; the weather cannot be pinned")
		return
	var was_ticking := _weather.is_processing() or _weather.is_physics_processing()
	if _weather.has_method("set_weather") and str(_weather.call("weather")) != "clear":
		_weather.call("set_weather", "clear")
	_weather.set_process(false)
	_weather.set_physics_process(false)
	if was_ticking and when != "at boot":
		print("[weather] WorldWeather was ticking %s; frozen again" % when)


## --- the companion ---------------------------------------------------------

## `CreatureSpecies.spawn()` + `Game.party.add()` + `EncounterDirector.
## summon_active_creature()` -- the party screen's own "send this one out"
## path, copied from `_capture_life.gd::_shoot_pairing`. A party that already
## has members (a scene that granted a starter) is used as it is; only an
## empty belt is given a Terrapup, the way the real opening does.
func _summon_companion() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("no /root/Game autoload; the party cannot be reached")
		return false
	var party: RefCounted = game.get("party")
	if party == null:
		_failures.append("Game.party is null; nothing to summon")
		return false
	if (party.call("members") as Array).is_empty():
		var starter: RefCounted = SPECIES.spawn("terrapup")
		if starter == null:
			_failures.append("CreatureSpecies.spawn('terrapup') returned null")
			return false
		if not bool(party.call("add", starter)):
			_failures.append("Game.party.add(starter) returned false")
			return false
		print("[companion] granted terrapup to Game.party via the real add() path")
	var existing: Node3D = _director.call("ally_body") as Node3D
	if existing == null:
		var summoned: bool = await _director.call("summon_active_creature")
		if not summoned:
			_failures.append("EncounterDirector.summon_active_creature() returned false " +
				"(GAME-2 class: the game refused to deploy the party's active creature)")
			return false
	_companion = _director.call("ally_body") as Node3D
	if _companion == null:
		_failures.append("ally_body() is null after a successful summon")
		return false
	print("[companion] %s summoned via EncounterDirector.summon_active_creature() -- real party path" % _companion_species())
	return true


func _companion_species() -> String:
	if _companion == null or not is_instance_valid(_companion):
		return "<none>"
	return str(_companion.get("species_id"))


## --- staging the road stand --------------------------------------------------

func _place_trainer(xz: Vector2, look_xz: Vector2) -> void:
	_player.global_position = Vector3(xz.x, _field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	_player.velocity = Vector3.ZERO
	_player.rotation = Vector3.ZERO
	# The controller owns the model's yaw, not the body's --
	# `combat_manager.gd::_stand_the_trainer_aside` turns the trainer the same
	# way. Locomotion is idle here, so writing it holds.
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	var ahead := look_xz - xz
	if model != null and ahead.length() > 0.01:
		model.rotation.y = atan2(ahead.x, ahead.y)


func _place_companion(xz: Vector2, look_xz: Vector2) -> void:
	if _companion == null or not is_instance_valid(_companion):
		return
	var ahead := (look_xz - xz).normalized()
	var side := Vector2(-ahead.y, ahead.x)
	var spot := xz + side * COMPANION_SIDE_M
	if not bool(_companion.call("place_on_ground", Vector3(spot.x, 0.0, spot.y))):
		_companion.global_position = Vector3(spot.x, _field.height_at(spot.x, spot.y) + 0.1, spot.y)
	var far := spot + ahead * 20.0
	_companion.call("face_towards", Vector3(far.x, _companion.global_position.y, far.y))


func _pose_road_eye(eye_xz: Vector2, stand_xz: Vector2, target_xz: Vector2) -> void:
	var eye_ground: float = _field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = _field.height_at(target_xz.x, target_xz.y)
	# On a crest the road behind the trainer can be lower than where they stand;
	# the eye never sits under the trainer's own feet.
	var stand_ground: float = _field.height_at(stand_xz.x, stand_xz.y)
	var eye := Vector3(eye_xz.x, maxf(eye_ground, stand_ground) + EYE_H, eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + TARGET_H, target_xz.y)
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)
	_camera.rotation = Vector3(_pitch_for_horizon(HORIZON), _camera.rotation.y, 0.0)
	_camera.make_current()


## --- subjects and the shutter check ----------------------------------------

## The trainer's box from its own collision capsule -- never a skinned mesh's
## bind-pose AABB (`_capture_life.gd`'s round 5 addendum) -- and a creature's
## from `species.json`'s declared height/radius, the numbers
## `creature_body.gd::_fit()` builds the collider from.
func _trainer_subject() -> Dictionary:
	var height := 1.8
	var radius := 0.4
	for child in _player.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is CapsuleShape3D:
			var cs := child as CollisionShape3D
			var scale := cs.global_transform.basis.get_scale()
			height = (cs.shape as CapsuleShape3D).height * scale.y
			radius = (cs.shape as CapsuleShape3D).radius * maxf(scale.x, scale.z)
			break
	var half := Vector3(radius, height * 0.5, radius)
	var centre := _player.global_position + Vector3(0.0, height * 0.5, 0.0)
	return {"name": "trainer", "aabb": AABB(centre - half, half * 2.0), "body": _player}


func _creature_subject(body: Node3D, label: String) -> Dictionary:
	var species_id := str(body.get("species_id"))
	var height := 1.0
	var radius := 0.4
	var footprint := 1.5
	if species_id != "" and SPECIES.has(species_id):
		var ph: Dictionary = SPECIES.placeholder(species_id)
		height = float(ph.get("height", height))
		radius = float(ph.get("radius", radius))
		footprint = float(ph.get("footprint_allowance", footprint))
	var horiz := radius * maxf(1.0, footprint * 0.65)
	var half := Vector3(horiz, height * 0.5, horiz)
	var centre := body.global_position + Vector3(0.0, height * 0.5, 0.0)
	return {"name": "%s:%s" % [label, species_id], "aabb": AABB(centre - half, half * 2.0), "body": body}


func _road_subjects() -> Array:
	var out: Array = [_trainer_subject()]
	if _companion != null and is_instance_valid(_companion):
		out.append(_creature_subject(_companion, "companion"))
	return out


## Every reason not to save this frame: the world checks `capture_check`
## already runs for every tool (grass bound, terrain streaming here, camera
## above ground and outside geometry, weather pinned) plus the readable check.
func _frame_problems(subjects: Array, ignore_bodies: Array, readable_opts: Dictionary = {}) -> Array[String]:
	_check_projection_once()
	_freeze_weather("before the shutter")
	var out: Array[String] = CAPTURE_CHECK.problems(self, _camera, "clear", null, ignore_bodies)
	out.append_array(CAPTURE_CHECK.readable_problems_for_camera(_camera, subjects, readable_opts))
	return out


## `capture_check.readable_problems` projects with its own arithmetic so the
## unit suite can exercise it; this proves, once per run and on the live
## camera, that the arithmetic agrees with the engine's own `unproject_position`
## to the pixel. A disagreement is a failure of the run, not a note.
func _check_projection_once() -> void:
	if _projection_checked:
		return
	_projection_checked = true
	var size: Vector2 = _camera.get_viewport().get_visible_rect().size
	var probe := _camera.global_position + (-_camera.global_transform.basis.z) * 8.0 \
		+ _camera.global_transform.basis.x * 1.5 + Vector3(0.0, -0.7, 0.0)
	var engine := _camera.unproject_position(probe)
	var ours: Variant = CAPTURE_CHECK.project_point(_camera.global_transform, _camera.fov, size, probe)
	if ours == null:
		_failures.append("projection self-check: capture_check saw the probe point behind the camera")
		return
	var delta: float = engine.distance_to(ours as Vector2)
	print("[projection] engine %s vs capture_check %s: %.2f px apart" % [str(engine), str(ours), delta])
	if delta > 1.5:
		_failures.append("projection self-check: capture_check disagrees with unproject_position by %.2f px" % delta)


func _describe_subjects(subjects: Array) -> Array:
	var size: Vector2 = _camera.get_viewport().get_visible_rect().size
	var out: Array = []
	for subject: Dictionary in subjects:
		var projected: Dictionary = CAPTURE_CHECK.projected_rect(
			_camera.global_transform, _camera.fov, size, subject["aabb"])
		var rect: Rect2 = projected["rect"]
		out.append({
			"name": str(subject["name"]),
			"height_frac": 0.0 if bool(projected["behind"]) else snappedf(rect.size.y / size.y, 0.001),
			"behind": bool(projected["behind"]),
		})
	return out


func _hide_canvas_layers() -> Dictionary:
	var saved: Dictionary = {}
	for child in _world.get_children():
		if child is CanvasLayer:
			saved[child] = (child as CanvasLayer).visible
			(child as CanvasLayer).visible = false
	return saved


func _restore_canvas_layers(saved: Dictionary) -> void:
	for child: Variant in saved.keys():
		if is_instance_valid(child) and child != _world.get_node_or_null(^"PlaygroundHUD"):
			(child as CanvasLayer).visible = bool(saved[child])


func _reject(name: String, record: Dictionary, problems: Array[String]) -> void:
	record["problems"] = problems
	_rejected.append(record)
	print("  %-16s REFUSED, not saved:" % name)
	for line: String in problems:
		print("      * %s" % line)


func _save(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return false
	var path := "%s/%s.png" % [_out_dir, name]
	var err := image.save_png(path)
	if err != OK:
		_failures.append("%s: save_png failed (%d)" % [name, err])
		return false
	return true


## --- the fight frame --------------------------------------------------------

## One real fight per band, entered the way a player enters one and left the
## way a player leaves one. Returns true once a fight FRAME was saved, so the
## band is done; false when no untried wild was near enough or the frame was
## refused, which lets the next stand try again against a different opponent
## (a refused frame is still recorded and still fails the run).
##
## Structured so cleanup cannot be skipped: nothing between `begin` and
## `_end_fight` returns early. A frame that fails its check is refused and
## recorded, and the flee still runs.
func _shoot_fight(band_index: int, band_id: String, stand_xz: Vector2, look_xz: Vector2) -> bool:
	var stand := Vector3(stand_xz.x, _field.height_at(stand_xz.x, stand_xz.y), stand_xz.y)
	var wild := _nearest_wild(stand, _fight_search)
	if wild == null:
		return false
	_fought.append(wild)
	var species := str(wild.get("species_id"))
	print("[fight] band %d: nearest wild is %s at %.1f m from the stand" % [
		band_index, species, stand.distance_to(wild.global_position)])

	# Stand the trainer a few metres from the wild, facing it, inside
	# `flow.engage_range` (6 m) -- `_capture_combat_moments.gd::_teleport_player_near`.
	var toward := wild.global_position - stand
	toward.y = 0.0
	if toward.length() < 0.01:
		toward = Vector3(0.0, 0.0, 1.0)
	var approach_xz := Vector2(wild.global_position.x, wild.global_position.z) \
		- Vector2(toward.x, toward.z).normalized() * 4.0
	_place_trainer(approach_xz, Vector2(wild.global_position.x, wild.global_position.z))
	_place_companion(approach_xz, Vector2(wild.global_position.x, wild.global_position.z))
	_pose_road_eye(approach_xz - Vector2(toward.x, toward.z).normalized() * CAM_BACK_M,
		approach_xz, Vector2(wild.global_position.x, wild.global_position.z))
	for i in _frames(FIGHT_APPROACH_SETTLE):
		await physics_frame

	var entered_by := await _engage(wild)
	var name := "band%d_fight_%s" % [band_index, species]
	var record := {
		"frame": name, "band": band_index, "band_id": band_id, "fight": true,
		"opponent": species, "entered_by": entered_by, "time": _time,
		"x": snappedf(wild.global_position.x, 0.1), "z": snappedf(wild.global_position.z, 0.1),
	}
	if entered_by == "":
		_failures.append("band %d: could not enter a fight with %s (not fighting after %d interact presses, " % [
			band_index, species, ENGAGE_ATTEMPTS] + "interaction_activate() and _start_fight())")
		return false

	for i in _frames(FIGHT_ENGAGE_SETTLE):
		await physics_frame
	var context := _input_context()
	record["context_in_fight"] = context
	if context != "combat":
		_failures.append("band %d: input context is '%s' inside the fight, not 'combat'" % [band_index, context])

	# --- frame it: every bearing tried is measured with the tree PAUSED so the
	# box the check reads is the box the shutter sees. ---
	var saved_pose := _camera.global_transform
	var best_problems: Array[String] = []
	var best_bearing := ""
	var framed := false
	for candidate: Dictionary in _fight_bearings():
		var subjects := _fight_subjects(wild)
		if subjects.size() < 3:
			best_problems = ["a fighter vanished mid-frame (%d of 3 subjects)" % subjects.size()]
			break
		var focus := _ground_centroid(subjects)
		var d: float = CAPTURE_CHECK.fit_distance(focus, candidate["bearing"], FIGHT_EYE_H, FIGHT_LOOK_UP,
			FOV, _camera.get_viewport().get_visible_rect().size, subjects, FIGHT_MARGIN, FIGHT_D_MIN, FIGHT_D_MAX,
			0.25, FIGHT_MAX_HEIGHT_FRAC, FIGHT_MIN_HEIGHT_FRAC)
		if d < 0.0:
			print("[fight] %s: no distance between %.0f and %.0f m puts all three fighters inside the frame with none under %.0f%% or over %.0f%% of its height" % [
				str(candidate["label"]), FIGHT_D_MIN, FIGHT_D_MAX,
				FIGHT_MIN_HEIGHT_FRAC * 100.0, FIGHT_MAX_HEIGHT_FRAC * 100.0])
			if best_bearing == "":
				best_problems = ["no distance between %.0f and %.0f m frames all three fighters readably from any bearing tried" % [
					FIGHT_D_MIN, FIGHT_D_MAX]]
			continue
		_pose_fight_eye(focus, candidate["bearing"], d)
		# Let the grass ring and terrain bubble follow the moved eye before
		# freezing the world under it.
		for i in _frames(POSE_FRAMES):
			await process_frame
		paused = true
		subjects = _fight_subjects(wild)
		for i in 2:
			await process_frame
		var problems := _frame_problems(subjects, [_player, _companion, wild], {
			"max_height_frac": FIGHT_MAX_HEIGHT_FRAC, "min_height_frac": FIGHT_MIN_HEIGHT_FRAC})
		print("[fight] %s at %.1f m: %s" % [str(candidate["label"]), d,
			"fits and reads" if problems.is_empty() else str(problems)])
		if problems.is_empty():
			record["bearing"] = str(candidate["label"])
			record["distance_m"] = snappedf(d, 0.1)
			record["subjects"] = _describe_subjects(subjects)
			if await _save(name):
				_manifest.append(record)
				print("  %-16s fight vs %s from the %s at %.1f m -> %s/%s.png" % [
					name, species, str(candidate["label"]), d, _out_dir, name])
			framed = true
			paused = false
			break
		if best_bearing == "" or problems.size() < best_problems.size():
			best_bearing = str(candidate["label"])
			best_problems = problems
			record["subjects"] = _describe_subjects(subjects)
		paused = false
	if not framed:
		record["bearing"] = best_bearing
		_reject(name, record, best_problems)

	# --- cleanup, unconditional ---
	paused = false
	await _end_fight(band_index)
	_camera.global_transform = saved_pose
	_camera.make_current()
	return framed


func _nearest_wild(from: Vector3, within: float) -> Node3D:
	var best: Node3D = null
	var best_distance := within
	for entry: Variant in _director.call("wild_creatures"):
		var body := entry as Node3D
		if body == null or not is_instance_valid(body) or not body.visible or _fought.has(body):
			continue
		if body.has_method("is_alive") and not bool(body.call("is_alive")):
			continue
		var flat := body.global_position
		flat.y = from.y
		var d := flat.distance_to(from)
		if d < best_distance:
			best = body
			best_distance = d
	return best


## The player's own door in first (`interact`, read by the arbiter and handed
## to `EncounterDirector.interaction_activate`), then the director's provider
## entry point directly, then its one internal way in. Returns which one
## opened the fight, or "" if none did.
func _engage(wild: Node3D) -> String:
	var attempt := 0
	while attempt < ENGAGE_ATTEMPTS and not _fighting():
		attempt += 1
		await _press("interact")
		var waited := 0
		while not _fighting() and waited < ENGAGE_WAIT:
			waited += 1
			await physics_frame
	if _fighting():
		return "interact"
	if _director.has_method("interaction_activate"):
		_director.call("interaction_activate")
		await physics_frame
		if _fighting():
			return "interaction_activate"
	if _director.has_method("_start_fight"):
		_director.call("_start_fight", wild)
		await physics_frame
		if _fighting():
			return "_start_fight"
	return ""


func _fighting() -> bool:
	return _manager != null and bool(_manager.call("is_fighting"))


## Bearings to try, in order. The three subjects make a triangle: the ally
## and the wild along one axis, the trainer standing aside. Run 2 showed that
## a broadside (fighters in profile) puts the trainer either in front of the
## fight or behind it, so the FRONT quarters go first -- the eye past the
## wild, on the trainer's side, looking back along the axis: the small wild
## nearest, the taller companion behind it, the trainer off to the side.
## Broadsides and rear quarters follow.
func _fight_bearings() -> Array:
	var ally_pos := _companion.global_position if (_companion != null and is_instance_valid(_companion)) else _player.global_position
	var enemy: Node3D = _manager.call("enemy_body") as Node3D
	var axis := (enemy.global_position - ally_pos) if enemy != null else Vector3(0.0, 0.0, 1.0)
	axis.y = 0.0
	if axis.length() < 0.01:
		axis = Vector3(0.0, 0.0, 1.0)
	axis = axis.normalized()
	var side := axis.cross(Vector3.UP).normalized()
	var trainer_side := _player.global_position - ally_pos
	trainer_side.y = 0.0
	# Prefer the side the trainer stands on, so they read beside the fight
	# rather than behind it.
	if trainer_side.dot(side) < 0.0:
		side = -side
	return [
		{"label": "front-quarter-trainer-side", "bearing": (side + axis).normalized()},
		{"label": "front-quarter-far-side", "bearing": (-side + axis).normalized()},
		{"label": "broadside-trainer-side", "bearing": side},
		{"label": "broadside-far-side", "bearing": -side},
		{"label": "rear-quarter-trainer-side", "bearing": (side - axis).normalized()},
		{"label": "rear-quarter-far-side", "bearing": (-side - axis).normalized()},
		{"label": "behind-ally", "bearing": -axis},
	]


func _fight_subjects(wild: Node3D) -> Array:
	var out: Array = [_trainer_subject()]
	if _companion != null and is_instance_valid(_companion):
		out.append(_creature_subject(_companion, "companion"))
	if wild != null and is_instance_valid(wild):
		out.append(_creature_subject(wild, "opponent"))
	return out


func _ground_centroid(subjects: Array) -> Vector3:
	var sum := Vector3.ZERO
	for subject: Dictionary in subjects:
		var box: AABB = subject["aabb"]
		sum += Vector3(box.get_center().x, box.position.y, box.get_center().z)
	return sum / float(subjects.size())


func _pose_fight_eye(focus: Vector3, bearing: Vector3, distance: float) -> void:
	var xform: Transform3D = CAPTURE_CHECK.camera_transform_at(focus, bearing, distance, FIGHT_EYE_H, FIGHT_LOOK_UP)
	# The solver works in the fighters' plane; the ground under the eye can be
	# higher on a slope. Ask the world, never carry a Y across a horizontal
	# move (D09), and re-aim from wherever the eye actually ends up.
	var ground := _ground_at(xform.origin.x, xform.origin.z)
	var origin := xform.origin
	origin.y = maxf(origin.y, ground + 1.2)
	_camera.global_position = origin
	_camera.look_at(focus + Vector3(0.0, FIGHT_LOOK_UP, 0.0), Vector3.UP)
	_camera.make_current()


func _ground_at(x: float, z: float) -> float:
	if _world.has_method("ground_height_at"):
		var h := float(_world.call("ground_height_at", x, z))
		if not is_nan(h):
			return h
	return _field.height_at(x, z)


## Leave the fight the way a player does, and prove the world came back.
##
## The flee is read by `combat_manager.gd::_read_player_input`, which
## `flow.input_guard` gates for 0.25 s after `begin()`; a press inside the
## guard is silently dropped (docs/VISUAL_PARITY_PROGRESS.md, lesson two).
## `FIGHT_GUARD_TICKS` of physics are spent here regardless of how long the
## framing above took, so a bearing that fitted first try cannot flee early.
func _end_fight(band_index: int) -> void:
	if not _fighting():
		return
	for i in FIGHT_GUARD_TICKS:
		await physics_frame
	if _manager.has_method("is_aiming") and bool(_manager.call("is_aiming")):
		await _press("menu_cancel")
	var presses := 0
	while _fighting() and presses < 2:
		presses += 1
		await _press("combat_run")
		var waited := 0
		while _fighting() and waited < FLEE_BOUND:
			waited += 1
			await physics_frame
	if _fighting():
		_failures.append("band %d: the fight did not end after %d flee presses; the walk continues in combat state" % [
			band_index, presses])
	# The fight ends on a physics tick; `sequence_director.gd::_refresh_lockout`
	# hands the arbiter back from `_process`. Read the context only once a
	# render frame has run, or a world that IS back reads as 'locked' (run 1).
	for i in 2:
		await process_frame
	await physics_frame
	var context := _input_context()
	if context != "world":
		_failures.append("band %d: input context after the flee is '%s', not 'world'" % [band_index, context])
	else:
		print("[fight] band %d: fled after %d press(es); input context is back to 'world'" % [band_index, presses])
	if _companion != null and is_instance_valid(_companion) and not _companion.visible:
		_failures.append("band %d: the companion is hidden after the fight; the director did not restore the follower" % band_index)


func _input_context() -> String:
	var probe: RefCounted = GATE_F_PROBE.new(self)
	return str(probe.call("input_context"))


## Hardware-shaped press: held two physics ticks, released, one tick to settle
## (`_capture_combat_moments.gd::_press`).
func _press(action: String) -> void:
	Input.action_press(action)
	for i in 2:
		await physics_frame
	Input.action_release(action)
	await physics_frame


## --- trail geometry ---------------------------------------------------------

func _arc_length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, line.size()):
		total += line[i - 1].distance_to(line[i])
	return total


func _point_at(line: PackedVector2Array, arc: float) -> Vector2:
	var remaining := maxf(0.0, arc)
	for i in range(1, line.size()):
		var seg := line[i - 1].distance_to(line[i])
		if remaining <= seg or i == line.size() - 1:
			if seg <= 0.0001:
				return line[i]
			return line[i - 1].lerp(line[i], clampf(remaining / seg, 0.0, 1.0))
		remaining -= seg
	return line[line.size() - 1]


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
