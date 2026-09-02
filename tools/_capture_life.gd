extends SceneTree

## VP9 FIFTH SLICE -- COURSE CORRECTION. Rounds 3-4 staged wild creatures
## directly via `EncounterDirector.spawn_wild()` purely for the shutter. The
## owner's own VP9 brief already said not to do this: "do not fake life only
## for screenshots. The visible population and the real gameplay population
## must agree." Round 5 drops staging as the deliverable path entirely.
##
## What this file does now:
##  1. Every stand's eye is positioned (with `_clear_eye()`'s raycast/sphere
##     clearance sweep, round 5's own fix for "the eye is inside static
##     rock"), the world is given time to stream/activate nearby clusters,
##     and NOTHING is hidden or spawned for the shot. The frame shows
##     whatever the game's own `spawns.json` population actually puts there.
##  2. The tool REPORTS which wild bodies are within 30m of the eye, their
##     species, and their measured on-screen bbox (pass/fail against the
##     same contract round 4/5 built) -- evidence of what supplied the
##     frame, not a claim about it.
##  3. Legibility is now entirely a DATA problem: `data/config/bands/*/
##     spawns.json` gained new authored clusters this round so a 2-species,
##     3-5-individual group actually stands 8-14m from each stand's own eye
##     -- see each new cluster's own `_why_vp9_r5` comment for the id and
##     distance. The tool does not move or invent population.
##  4. The pairing frame uses the REAL summon path: `CreatureSpecies.spawn()`
##     + `Game.party.add()` + `EncounterDirector.summon_active_creature()`
##     -- the same three calls the party screen's own "send this one out"
##     flow makes -- not `spawn_wild()`.
##  5. One additional village-life frame reports the existing authored
##     villager NPCs from the standing point `_capture_locations.gd` already
##     uses for its own "01-village standing" shot.
##
## Round 4's staged-composition code is KEPT, gated behind `--staged`
## (default off) as a diagnostic only -- never the deliverable. It answers
## "can a body be framed legibly at all" for tuning field_emission/placement
## in the data; it is not evidence about what a player actually sees.
##
## ROUND 5 ADDENDUM (bbox measurement): round 4's own code-blind judge found
## 5 of 9 frames had a body pressed against the lens at 40-100% of frame
## height while this tool's measurement reported ~10% and PASS. Root cause:
## every creature (and the player) is a skinned, animated mesh, and
## `VisualInstance3D.get_aabb()` on a skinned mesh reports the imported
## BIND-POSE AABB, not the live posed extent. `_creature_global_aabb()` now
## measures from the species' own DECLARED size (`species.json` height/
## radius/footprint_allowance -- the same numbers `creature_body.gd::_fit()`
## builds the collider from) instead of walking mesh geometry; the trainer
## measures from its own COLLISION capsule (never skinned) rather than a
## mesh walk, preferring a direct, non-hitbox-named `CollisionShape3D`.
## `_save_diag()` draws the projected rect from the SAME `_screen_rect()`
## the pass/fail verdict uses onto one real frame, the visual proof asked
## for before any contract result was allowed to count.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_life.gd [-- --staged] [-- --only=stands|starter|village]
##
## VP_FAST=1 halves the settle budget. BUDGET: max two world boots.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/visual-parity/LIFE/round5"

const BOOT_FRAMES := 90
const SETTLE_FRAMES := 60
const ARRIVE_FRAMES := 24
const REPOSITION_SETTLE := 10
const POSE_FRAMES := 4
const FOV := 70.0

## Bbox contract.
const MARGIN_FRAC := 0.03
const GROUP_MIN_H := 0.08
const GROUP_MAX_H := 0.45
const GROUP_WIDTH_CENTRAL := 0.8
const PAIR_MIN_H := 0.25
const PAIR_MAX_H := 0.45
const MAX_REROLLS := 5
const REPORT_RADIUS := 30.0

## The camera can NOT sit at the same point as the player: `_capture_locations.
## gd`'s own established rig always pulls the camera back from the standing
## point (`back := eye - toward * back_m`, RIG["standing"] = 3.2) precisely
## because a camera co-located with the player looks straight into the
## trainer's own hood/hair at 0m. This file's first round-5 boot skipped that
## offset and every stand frame paid for it -- see REPORT.md's round 5
## section. STAND_BACK_M matches that same default; VILLAGE_BACK_M/_UP_M copy
## `_capture_locations.gd`'s own "01 standing" rig verbatim (back 15, up 2.6),
## since that is literally the same eye this file's village frame reuses.
const STAND_BACK_M := 3.5
const VILLAGE_BACK_M := 15.0
const VILLAGE_UP_M := 2.6

## Five evidence stands. `eye`/`facing_toward` are round 2-3's own
## confirmed-clear camera geometry. Round 5 adds `_why_vp9_r5`-tagged
## clusters in the band spawns.json files so the REAL population reads a
## 2-species group from these eyes -- see each stand's cluster reference.
const STANDS := [
	{"id": "01-village-edge", "night": true,
	 "eye": [21.0, -32.0], "facing_toward": [30.0, -40.0],
	 "cluster_note": "band1 order 0 (bramblebun, existing) + order 1070 (mudsnout, new)"},
	{"id": "02-mill-pond-banks", "night": true,
	 "eye": [-386.0, 520.0], "facing_toward": [-378.0, 528.0],
	 "cluster_note": "band1 order 6 (paddlenewt, existing) + order 1071 (mosshell, new)"},
	{"id": "03-band1-open-meadow", "night": false,
	 "eye": [-6.0, 700.0], "facing_toward": [-20.0, 700.0],
	 "cluster_note": "band1 order 1002 (pipwing, existing) + order 1072 (bramblebun, new)"},
	{"id": "04-relay-camp", "night": true,
	 "eye": [332.0, 932.0], "facing_toward": [321.0, 928.5],
	 "cluster_note": "band1 order 1073 (bramblebun, new) + order 1074 (trailpup, new)",
	 "night_eye": [330.0, 940.0], "night_facing_toward": [345.6, 935.4]},
	{"id": "05-ridge-camp", "night": false,
	 "eye": [-250.0, 6458.0], "facing_toward": [-260.9, 6451.7],
	 "cluster_note": "band4 order 4076 (burrowback, existing) + order 4102 (trailpup, new)"},
]

## Staged-diagnostic-only groups (see file header). Never the deliverable.
const STAGED_GROUPS := {
	"01-village-edge": {"day": [{"species": "bramblebun", "count": 2}, {"species": "mudsnout", "count": 2}],
		"night": [{"species": "bramblebun", "count": 2}, {"species": "mudsnout", "count": 2}]},
	"02-mill-pond-banks": {"day": [{"species": "mosshell", "count": 2}, {"species": "paddlenewt", "count": 1}],
		"night": [{"species": "mosshell", "count": 2}, {"species": "paddlenewt", "count": 1}]},
	"03-band1-open-meadow": {"day": [{"species": "pipwing", "count": 2}, {"species": "bramblebun", "count": 2}]},
	"04-relay-camp": {"day": [{"species": "bramblebun", "count": 2}, {"species": "trailpup", "count": 2}],
		"night": [{"species": "bramblebun", "count": 2}, {"species": "duskhush", "count": 2}]},
	"05-ridge-camp": {"day": [{"species": "burrowback", "count": 2}, {"species": "trailpup", "count": 2}]},
}

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _director: Node = null
var _written: int = 0
var _failures: int = 0
var _rng := RandomNumberGenerator.new()
var _staged_mode := false

static var _fast_mode: bool = false


static func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast_mode else n


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	_fast_mode = "--fast" in args or OS.get_environment("VP_FAST") == "1"
	_staged_mode = "--staged" in args
	if _fast_mode:
		print("[fast] iteration mode: settle halved, msaa off")
	if _staged_mode:
		print("[staged] DIAGNOSTIC mode -- staged bodies, never the deliverable")
	_rng.seed = 20260902

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in _frames(BOOT_FRAMES):
		await physics_frame
	print("[life] world up, boot settled")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("FAIL no Player node")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	if _fast_mode:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _director == null:
		print("FATAL: no EncounterDirector")
		quit(1)
		return

	var only := ""
	for arg: String in args:
		if arg.begins_with("--only="):
			only = arg.substr(7).strip_edges()

	if only == "" or only == "stands":
		await _pin("day")
		for entry: Variant in STANDS:
			await _shoot_stand(entry as Dictionary, "day")

		await _pin("night")
		for entry: Variant in STANDS:
			var stand: Dictionary = entry as Dictionary
			if bool(stand.get("night", false)):
				await _shoot_stand(stand, "night")

	if only == "" or only == "village":
		await _pin("day")
		await _shoot_village()

	if only == "" or only == "starter":
		await _pin("day")
		await _shoot_pairing()

	print("")
	print("life survey: %d frames written, %d failed, into %s" % [_written, _failures, OUT_DIR])
	quit(0 if _failures == 0 else 1)


func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in _frames(30):
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.set_process(false)
		_look.set_physics_process(false)
	print("[life] clock pinned to %s and frozen" % time)


## THE DELIVERABLE PATH: position the eye, let the world's own population
## stream in, hide/spawn nothing, report what is actually there. Falls back
## to the round-4 staged-diagnostic path only under `--staged`.
func _shoot_stand(stand: Dictionary, suffix: String) -> void:
	if _staged_mode:
		await _shoot_stand_staged_diagnostic(stand, suffix)
		return

	var id: String = str(stand["id"])
	var is_night := suffix == "night"
	var eyeArr: Array = (stand["night_eye"] as Array) if (is_night and stand.has("night_eye")) else (stand["eye"] as Array)
	var towardArr: Array = (stand["night_facing_toward"] as Array) if (is_night and stand.has("night_facing_toward")) else (stand["facing_toward"] as Array)
	var eye_raw := Vector2(float(eyeArr[0]), float(eyeArr[1]))
	var toward := Vector2(float(towardArr[0]), float(towardArr[1]))
	var eye := _clear_eye(eye_raw, toward, "%s-%s" % [id, suffix])
	var ground := _surface(eye)
	var facing := (toward - eye).normalized()
	var cam2 := eye - facing * STAND_BACK_M
	var cam_ground := _surface(cam2)
	_place(eye, ground)
	_frame(cam2, cam_ground, toward, ground)
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame
	# Let encounter streaming activate/settle whatever the world's own
	# population near this eye is doing -- no spawn, no hide.
	for i in _frames(SETTLE_FRAMES):
		await physics_frame

	_hide_huds()
	_frame(cam2, cam_ground, toward, ground)
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var eye3 := Vector3(eye.x, ground, eye.y)
	print("  [%s-%s] cluster reference: %s" % [id, suffix, str(stand.get("cluster_note", "(none noted)"))])
	print("  [%s-%s] real wild bodies within %.0fm of the eye:" % [id, suffix, REPORT_RADIUS])
	var pass_count := 0
	var total_count := 0
	var species_seen: Dictionary = {}
	if _director != null and _director.has_method("wild_creatures"):
		for w: Variant in _director.call("wild_creatures"):
			var body := w as Node3D
			if body == null or not is_instance_valid(body):
				continue
			var d := body.global_position.distance_to(eye3)
			if d > REPORT_RADIUS:
				continue
			total_count += 1
			var sid := str(body.get("species_id"))
			var chk := _bbox_check(_creature_global_aabb(body), GROUP_MIN_H, GROUP_MAX_H, GROUP_WIDTH_CENTRAL)
			print("    %-30s species=%-12s dist=%5.1fm height_frac=%.2f -> %s (%s)" % [
				body.name, sid, d, float(chk["height_frac"]), "PASS" if bool(chk["pass"]) else "FAIL", str(chk["reason"])])
			if bool(chk["pass"]):
				pass_count += 1
				species_seen[sid] = true

	if id == "01-village-edge" and suffix == "day" and total_count > 0:
		var diag_aabbs: Array = []
		for w: Variant in _director.call("wild_creatures"):
			var body := w as Node3D
			if body != null and is_instance_valid(body) and body.global_position.distance_to(eye3) <= REPORT_RADIUS:
				diag_aabbs.append(_creature_global_aabb(body))
		_save_diag("%s-%s" % [id, suffix], diag_aabbs)

	_save("%s-%s" % [id, suffix])
	print("  %-24s %-5s %d/%d real wild bodies pass the bbox contract, %d distinct species" % [
		id, suffix, pass_count, total_count, species_seen.size()])
	if total_count == 0:
		print("  WARN %s-%s: no wild body registered within %.0fm at all" % [id, suffix, REPORT_RADIUS])


## The one extra ask: an existing-population frame at the village's own
## standing point (`_capture_locations.gd`'s own '01-village standing' eye),
## reporting the authored villager NPCs actually there.
func _shoot_village() -> void:
	var eye_raw := Vector2(10.0, -15.5)
	var toward := Vector2(3.0, 1.0)
	var eye := _clear_eye(eye_raw, toward, "00-village-life")
	var ground := _surface(eye)
	var facing := (toward - eye).normalized()
	var cam2 := eye - facing * VILLAGE_BACK_M
	var cam_ground := _surface(cam2)
	_place(eye, ground)
	_frame(cam2, cam_ground, toward, ground, VILLAGE_UP_M, 1.6)
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame
	for i in _frames(SETTLE_FRAMES):
		await physics_frame
	_hide_huds()
	_frame(cam2, cam_ground, toward, ground, VILLAGE_UP_M, 1.6)
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var eye3 := Vector3(eye.x, ground, eye.y)
	var count := 0
	print("  [00-village-life] existing villager NPCs within 40m of the eye:")
	for container_name: String in ["VillageNPCs", "Trainers"]:
		var container: Node = _world.get_node_or_null(NodePath(container_name))
		if container == null:
			continue
		for child in container.get_children():
			var body := child as Node3D
			if body == null or not is_instance_valid(body):
				continue
			var d := body.global_position.distance_to(eye3)
			if d <= 40.0:
				count += 1
				print("    %-30s dist=%5.1fm" % [body.name, d])

	_save("00-village-life-day")
	print("  00-village-life         day   %d villager NPC(s) within 40m" % count)
	if count == 0:
		print("  WARN 00-village-life: no villager NPC registered within 40m")


## THE PAIRING FRAME, real party path: `CreatureSpecies.spawn()` + `Game.
## party.add()` + `EncounterDirector.summon_active_creature()` -- the same
## three calls the party screen's own "send this one out first" flow makes,
## not `spawn_wild()`. gap=2m per the brief, back swept monotonically 4-7m.
func _shoot_pairing() -> void:
	var candidates: Array[Vector2] = [
		Vector2(70.0, -70.0), Vector2(85.0, -55.0), Vector2(55.0, -85.0),
		Vector2(100.0, -80.0), Vector2(60.0, -100.0), Vector2(90.0, -95.0),
		Vector2(21.0, -32.0), Vector2(29.0, -34.0), Vector2(13.0, -30.0),
	]
	var facing_bearing := Vector2(1.0, -1.0).normalized()
	var gap := 2.0
	var base_back := 5.0
	var chosen := Vector2.ZERO
	var found := false
	for base: Vector2 in candidates:
		var facing := facing_bearing
		var side := Vector2(-facing.y, facing.x)
		var creature2 := base - facing * gap
		var mid := (base + creature2) * 0.5
		var camEye2 := mid - facing * base_back
		if _stand_is_clear(base) and _stand_is_clear(creature2) and _stand_is_clear(camEye2):
			chosen = base
			found = true
			print("  [pairing] candidate (%.0f,%.0f) passed the ground/clearance check" % [base.x, base.y])
			break
		else:
			print("  [pairing] candidate (%.0f,%.0f) REJECTED (prop underfoot or a static body within 4m)" % [base.x, base.y])
	if not found:
		print("  FAIL starter-beside-trainer: no candidate stand cleared the geometry check")
		_failures += 1
		return

	var base := chosen
	var facing := facing_bearing
	var side := Vector2(-facing.y, facing.x)

	var player_ground := _surface(base)
	_player.global_position = Vector3(base.x, player_ground + 0.4, base.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("  FAIL starter-beside-trainer: no /root/Game autoload")
		_failures += 1
		return
	var party: RefCounted = game.get("party")
	if party == null:
		print("  FAIL starter-beside-trainer: Game.party is null")
		_failures += 1
		return
	var starter: RefCounted = SPECIES.spawn("terrapup")
	if starter == null:
		print("  FAIL starter-beside-trainer: CreatureSpecies.spawn('terrapup') returned null")
		_failures += 1
		return
	if not bool(party.call("add", starter)):
		print("  FAIL starter-beside-trainer: Game.party.add(starter) returned false")
		_failures += 1
		return
	print("  [pairing] granted terrapup to Game.party via the real add() path")
	var summoned: bool = await _director.call("summon_active_creature")
	if not summoned:
		print("  FAIL starter-beside-trainer: summon_active_creature() returned false")
		_failures += 1
		return
	var wild: Node3D = _director.call("ally_body")
	if wild == null:
		print("  FAIL starter-beside-trainer: ally_body() returned null after a successful summon")
		_failures += 1
		return
	print("  [pairing] summoned via EncounterDirector.summon_active_creature() -- real party path")

	# The follower's own AI walks it toward the player; give it a moment,
	# then re-seat both bodies at the framed spot for a stable shot rather
	# than fighting its live pathing every attempt.
	for i in _frames(SETTLE_FRAMES):
		await physics_frame
	var spot2 := base - facing * gap
	wild.global_position = Vector3(spot2.x, _surface(spot2), spot2.y)
	wild.rotation.y = atan2(facing.x, facing.y)
	for i in _frames(REPOSITION_SETTLE):
		await physics_frame

	var attempt := 0
	var trainer_chk: Dictionary = {}
	var creature_chk: Dictionary = {}
	var ok := false
	while attempt <= MAX_REROLLS:
		var back := lerpf(4.0, 7.0, float(attempt) / float(MAX_REROLLS))
		var mid := (base + spot2) * 0.5
		var camEye2 := mid - facing * back
		var camGround := _surface(camEye2)
		var camPos := Vector3(camEye2.x, camGround + 1.6, camEye2.y)
		var lookAt := Vector3(mid.x, _surface(mid) + 1.1, mid.y)
		_camera.global_position = camPos
		_camera.look_at(lookAt, Vector3.UP)
		_hide_huds()
		for i in _frames(POSE_FRAMES):
			await process_frame
		await RenderingServer.frame_post_draw

		var trainer_aabb := _player_visible_aabb(_player)
		var creature_aabb := _creature_global_aabb(wild)
		trainer_chk = _bbox_check(trainer_aabb, PAIR_MIN_H, PAIR_MAX_H)
		creature_chk = _bbox_check(creature_aabb, PAIR_MIN_H, PAIR_MAX_H)
		ok = bool(trainer_chk["pass"]) and bool(creature_chk["pass"])
		print("  [pairing] attempt=%d back=%.1f trainer height_frac=%.2f(%s) creature height_frac=%.2f(%s)" % [
			attempt, back, float(trainer_chk["height_frac"]), str(trainer_chk["reason"]),
			float(creature_chk["height_frac"]), str(creature_chk["reason"])])
		if ok:
			break
		attempt += 1

	_save("06-starter-beside-trainer-day")
	print("  06-starter-beside-trainer  day  player(%.0f,%.0f) terrapup(%.0f,%.0f) ASSERTION=%s" % [
		base.x, base.y, spot2.x, spot2.y, "PASS" if ok else "FAIL"])
	if not ok:
		_failures += 1
	await process_frame


## ---- Round 4 staged-composition path, KEPT AS A DIAGNOSTIC ONLY (--staged).
## Never the deliverable -- see file header. ----

func _shoot_stand_staged_diagnostic(stand: Dictionary, suffix: String) -> void:
	var id: String = str(stand["id"])
	var is_night := suffix == "night"
	var eyeArr: Array = (stand["night_eye"] as Array) if (is_night and stand.has("night_eye")) else (stand["eye"] as Array)
	var towardArr: Array = (stand["night_facing_toward"] as Array) if (is_night and stand.has("night_facing_toward")) else (stand["facing_toward"] as Array)
	var eye_raw := Vector2(float(eyeArr[0]), float(eyeArr[1]))
	var toward := Vector2(float(towardArr[0]), float(towardArr[1]))
	var eye := _clear_eye(eye_raw, toward, "%s-%s [staged]" % [id, suffix])
	var facing := (toward - eye).normalized()
	var side := Vector2(-facing.y, facing.x)

	var ground := _surface(eye)
	_place(eye, ground)
	_frame(eye, ground, eye + facing, ground)
	for i in _frames(ARRIVE_FRAMES):
		await physics_frame

	var min_depth := 6.0 if is_night else 9.0
	var max_depth := 8.0 if is_night else 12.0
	var lateral_range := 2.0 if is_night else 3.0

	var groups: Dictionary = STAGED_GROUPS.get(id, {})
	var spec: Array = groups.get(suffix, []) as Array
	if spec.is_empty():
		print("  [staged] %s-%s: no staged group defined for this suffix, skipping" % [id, suffix])
		return

	var spawned: Array[Node3D] = []
	var lane := 0
	var total := 0
	for entry: Variant in spec:
		total += int((entry as Dictionary)["count"])
	for entry: Variant in spec:
		var g: Dictionary = entry as Dictionary
		var species: String = str(g["species"])
		for n in int(g["count"]):
			var t := (float(lane) + 1.0) / float(total + 1)
			var lateral := lerpf(-lateral_range, lateral_range, t)
			var wild := await _stage_creature(
				"%s_%s_%s_%d" % [id.replace("-", "_"), suffix, species, n],
				species, eye, facing, side, min_depth, max_depth, lateral)
			if wild != null:
				spawned.append(wild)
			lane += 1

	_desync(spawned)
	_hide_huds()
	_frame(eye, ground, eye + facing, ground)
	for i in _frames(POSE_FRAMES):
		await process_frame
	await RenderingServer.frame_post_draw

	var pass_count := 0
	for wild in spawned:
		if not is_instance_valid(wild):
			continue
		var chk := _bbox_check(_creature_global_aabb(wild), GROUP_MIN_H, GROUP_MAX_H, GROUP_WIDTH_CENTRAL)
		print("    %-40s height_frac=%.2f -> %s (%s)" % [
			wild.name, float(chk["height_frac"]), "PASS" if bool(chk["pass"]) else "FAIL", str(chk["reason"])])
		if bool(chk["pass"]):
			pass_count += 1

	_save("%s-%s-STAGED" % [id, suffix])
	print("  %-24s %-5s [staged] %d/%d pass the bbox contract" % [id, suffix, pass_count, spawned.size()])

	for wild in spawned:
		if is_instance_valid(wild):
			wild.queue_free()
	await process_frame


func _stage_creature(name: String, species: String, eye: Vector2, facing: Vector2, side: Vector2,
		min_depth: float, max_depth: float, lateral: float) -> Node3D:
	var temp2 := eye + facing * 80.0
	var temp3 := Vector3(temp2.x, _surface(temp2), temp2.y)
	var wild: Node3D = _director.call("spawn_wild", species, temp3, {
		"name": "Shot_%s" % name,
		"wander_radius": 0.0,
	}) as Node3D
	if wild == null:
		print("    FAIL %s: spawn_wild('%s') returned null" % [name, species])
		return null
	wild.rotation.y = atan2(facing.x, facing.y)
	for i in range(2):
		await process_frame

	var measured := _creature_global_aabb(wild)
	var longest := maxf(measured.size.x, maxf(measured.size.y, measured.size.z))
	var floor_dist := maxf(3.5, 4.0 * longest)
	var base_depth := clampf((min_depth + max_depth) * 0.5, floor_dist, maxf(floor_dist, max_depth))
	print("    %-40s AABB size=%s longest=%.2fm near-clip-floor=%.1fm base_depth=%.1fm" % [
		name, measured.size, longest, floor_dist, base_depth])

	var attempt := 0
	var chk: Dictionary = {}
	while attempt <= MAX_REROLLS:
		var depth := base_depth if attempt == 0 else lerpf(floor_dist, maxf(floor_dist, max_depth), _rng.randf())
		var lat := lateral if attempt == 0 else lateral + _rng.randf_range(-1.2, 1.2)
		var pos2 := eye + facing * depth + side * lat
		var pos3 := Vector3(pos2.x, _surface(pos2), pos2.y)
		wild.global_position = pos3
		wild.rotation.y = atan2(facing.x, facing.y)
		for i in _frames(REPOSITION_SETTLE):
			await physics_frame
		var aabb := _creature_global_aabb(wild)
		chk = _bbox_check(aabb, GROUP_MIN_H, GROUP_MAX_H, GROUP_WIDTH_CENTRAL)
		print("      attempt=%d depth=%.1f lat=%.1f height_frac=%.2f -> %s (%s)" % [
			attempt, depth, lat, float(chk["height_frac"]), "PASS" if bool(chk["pass"]) else "FAIL", str(chk["reason"])])
		if bool(chk["pass"]):
			break
		attempt += 1

	for i in _frames(SETTLE_FRAMES / (MAX_REROLLS + 1)):
		await physics_frame
	return wild


func _desync(bodies: Array[Node3D]) -> void:
	for body in bodies:
		if not is_instance_valid(body):
			continue
		body.rotation.y = _rng.randf_range(0.0, TAU)
		for player in body.find_children("*", "AnimationPlayer", true, false):
			var ap := player as AnimationPlayer
			var current := ap.current_animation
			if current == "":
				var list := ap.get_animation_list()
				if list.size() > 0:
					current = list[0]
					ap.play(current)
			if current != "":
				var anim := ap.get_animation(current)
				if anim != null and anim.length > 0.05:
					ap.seek(_rng.randf_range(0.0, anim.length), true)


## ---- Shared geometry/measurement helpers ----

func _clear_eye(intended: Vector2, look_toward: Vector2, label: String) -> Vector2:
	var dir2 := (look_toward - intended)
	if dir2.length() < 0.01:
		print("    [%s] eye == look target; cannot derive a sightline, using eye as-is" % label)
		return intended
	dir2 = dir2.normalized()
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	var candidate := intended
	for attempt in range(5):
		var ground := _surface(candidate)
		var eye3 := Vector3(candidate.x, ground + 1.6, candidate.y)
		var dir3 := Vector3(dir2.x, 0.0, dir2.y)
		var blocked := false
		var blocker_name := ""
		var blocked_at := 0.0
		if space != null:
			var t := 0.3
			while t <= 3.0:
				var p := eye3 + dir3 * t
				var shape := SphereShape3D.new()
				shape.radius = 0.5
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = shape
				query.transform = Transform3D(Basis(), p)
				query.collide_with_bodies = true
				query.collide_with_areas = false
				for hit: Dictionary in space.intersect_shape(query, 4):
					var body: Node = hit.get("collider") as Node
					if body != null and not _under_terrain(body):
						blocked = true
						blocker_name = body.name
						blocked_at = t
						break
				if blocked:
					break
				t += 0.5
		if not blocked:
			print("    [%s] eye (%.1f,%.1f) clear for the first 3m of its sightline (attempt %d)" % [
				label, candidate.x, candidate.y, attempt])
			return candidate
		print("    [%s] eye (%.1f,%.1f) blocked by %s at %.1fm along sightline; retreating" % [
			label, candidate.x, candidate.y, blocker_name, blocked_at])
		candidate -= dir2 * 2.0
	print("    [%s] WARN eye clearance unresolved after 5 attempts; using (%.1f,%.1f)" % [
		label, candidate.x, candidate.y])
	return candidate


func _player_visible_aabb(body: Node3D) -> AABB:
	var direct: Array = []
	for child in body.get_children():
		if child is CollisionShape3D:
			direct.append(child)
	var candidates: Array = direct if not direct.is_empty() else body.find_children("*", "CollisionShape3D", true, false)
	var best: CollisionShape3D = null
	var best_height := -1.0
	for c in candidates:
		var cs := c as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var lname := String(cs.name).to_lower()
		if lname.contains("hitbox") or lname.contains("trigger") or lname.contains("interaction"):
			continue
		var h := 1.8
		if cs.shape is CapsuleShape3D:
			h = (cs.shape as CapsuleShape3D).height
		elif cs.shape is BoxShape3D:
			h = (cs.shape as BoxShape3D).size.y
		if h > best_height:
			best_height = h
			best = cs
	if best == null:
		print("    WARN no usable CollisionShape3D found under the player; using a fixed human-scale box")
		return _player_aabb(body)
	print("    trainer collider chosen: %s (height=%.2f) of %d candidate(s)" % [best.name, best_height, candidates.size()])
	return _shape_global_aabb(best)


func _shape_global_aabb(cs: CollisionShape3D) -> AABB:
	var shape := cs.shape
	var height := 1.8
	var radius := 0.35
	if shape is CapsuleShape3D:
		height = (shape as CapsuleShape3D).height
		radius = (shape as CapsuleShape3D).radius
	elif shape is BoxShape3D:
		height = (shape as BoxShape3D).size.y
		radius = maxf((shape as BoxShape3D).size.x, (shape as BoxShape3D).size.z) * 0.5
	var centre := cs.global_position
	var half := Vector3(radius, height * 0.5, radius)
	return AABB(centre - half, half * 2.0)


func _player_aabb(body: Node3D) -> AABB:
	var shapes := body.find_children("*", "CollisionShape3D", true, false)
	if shapes.size() > 0:
		return _shape_global_aabb(shapes[0] as CollisionShape3D)
	var half2 := Vector3(0.35, 0.9, 0.35)
	return AABB(body.global_position - half2, half2 * 2.0)


func _stand_is_clear(at: Vector2) -> bool:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return true
	var ground := _surface(at)
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	query.shape = shape
	query.transform = Transform3D(Basis(), Vector3(at.x, ground + 1.0, at.y))
	query.collide_with_bodies = true
	query.collide_with_areas = false
	for hit: Dictionary in space.intersect_shape(query, 8):
		var body: Node = hit.get("collider") as Node
		if body == null or _under_terrain(body) or not (body is StaticBody3D):
			continue
		print("      blocked by: %s (%s)" % [body.name, body.get_class()])
		return false
	return true


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


func _image_size() -> Vector2:
	return Vector2(root.size)


func _unproject_scaled(world_pos: Vector3) -> Vector2:
	var vp_size: Vector2 = _camera.get_viewport().get_visible_rect().size
	var scale: Vector2 = _image_size() / vp_size
	return _camera.unproject_position(world_pos) * scale


func _aabb_corners(aabb: AABB) -> Array:
	var c := []
	for i in 8:
		c.append(aabb.position + Vector3(
			aabb.size.x if (i & 1) else 0.0,
			aabb.size.y if (i & 2) else 0.0,
			aabb.size.z if (i & 4) else 0.0))
	return c


## Creature bbox from its own DECLARED size (species.json height/radius/
## footprint_allowance -- the same numbers creature_body.gd::_fit() builds
## the collider from), not a mesh walk. See file header's ADDENDUM section.
func _creature_global_aabb(root_node: Node3D) -> AABB:
	var species_id := str(root_node.get("species_id"))
	if species_id != "" and SPECIES.has(species_id):
		var ph: Dictionary = SPECIES.placeholder(species_id)
		var height: float = float(ph.get("height", 1.8))
		var radius: float = float(ph.get("radius", 0.4))
		var footprint: float = float(ph.get("footprint_allowance", 1.5))
		var horiz := radius * maxf(1.0, footprint * 0.65)
		var half := Vector3(horiz, height * 0.5, horiz)
		var centre := root_node.global_position + Vector3(0.0, height * 0.5, 0.0)
		return AABB(centre - half, half * 2.0)
	print("    WARN no species_id/placeholder for %s; using a fixed fallback box" % root_node.name)
	return AABB(root_node.global_position - Vector3(0.3, 0.0, 0.3), Vector3(0.6, 1.0, 0.6))


func _bbox_check(aabb: AABB, min_h: float, max_h: float, width_central_frac: float = 1.0) -> Dictionary:
	var image := _image_size()
	var proj := _screen_rect(aabb)
	if bool(proj["any_behind"]):
		return {"pass": false, "reason": "part_behind_camera", "height_frac": 0.0}
	var rect: Rect2 = proj["rect"]
	var margin := image * MARGIN_FRAC
	var inside := rect.position.x >= margin.x and rect.position.y >= margin.y \
		and rect.end.x <= image.x - margin.x and rect.end.y <= image.y - margin.y
	var width_margin := image.x * (1.0 - width_central_frac) * 0.5
	var centred := rect.position.x >= width_margin and rect.end.x <= image.x - width_margin
	var h_frac := rect.size.y / image.y
	var size_ok := h_frac >= min_h and h_frac <= max_h
	var reason := "ok"
	if not inside:
		reason = "outside_margin"
	elif not centred:
		reason = "outside_central_width"
	elif not size_ok:
		reason = "height_frac_%s" % ("too_small" if h_frac < min_h else "too_large")
	return {"pass": inside and centred and size_ok, "reason": reason, "height_frac": h_frac}


func _screen_rect(aabb: AABB) -> Dictionary:
	var minv := Vector2(INF, INF)
	var maxv := Vector2(-INF, -INF)
	var any_behind := false
	var forward := -_camera.global_transform.basis.z
	for corner in _aabb_corners(aabb):
		var to_point: Vector3 = corner - _camera.global_position
		if to_point.dot(forward) <= 0.05:
			any_behind = true
			continue
		var vp := _unproject_scaled(corner)
		minv.x = minf(minv.x, vp.x)
		minv.y = minf(minv.y, vp.y)
		maxv.x = maxf(maxv.x, vp.x)
		maxv.y = maxf(maxv.y, vp.y)
	if any_behind or minv.x == INF:
		return {"rect": Rect2(), "any_behind": true}
	return {"rect": Rect2(minv, maxv - minv), "any_behind": false}


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		print("  FAIL %s: viewport returned no image" % name)
		_failures += 1
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("  FAIL %s: save_png" % name)
		_failures += 1
		return
	_written += 1
	print("wrote %s" % path)


func _save_diag(name: String, aabbs: Array) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		return
	for aabb in aabbs:
		var proj := _screen_rect(aabb as AABB)
		if bool(proj["any_behind"]):
			continue
		_draw_rect_border(image, Rect2i(proj["rect"]), Color(1, 0, 0, 1), 3)
	var path := "%s/%s-DIAG.png" % [OUT_DIR, name]
	image.save_png(path)
	print("wrote DIAG %s (%d rect(s) drawn)" % [path, aabbs.size()])


func _draw_rect_border(image: Image, r: Rect2i, color: Color, thickness: int) -> void:
	var w := image.get_width()
	var h := image.get_height()
	for x in range(maxi(0, r.position.x), mini(w, r.position.x + r.size.x)):
		for t in range(thickness):
			image.set_pixel(x, clampi(r.position.y + t, 0, h - 1), color)
			image.set_pixel(x, clampi(r.position.y + r.size.y - 1 - t, 0, h - 1), color)
	for y in range(maxi(0, r.position.y), mini(h, r.position.y + r.size.y)):
		for t in range(thickness):
			image.set_pixel(clampi(r.position.x + t, 0, w - 1), y, color)
			image.set_pixel(clampi(r.position.x + r.size.x - 1 - t, 0, w - 1), y, color)


func _hide_huds() -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


func _frame(eye: Vector2, eye_ground: float, target: Vector2, target_ground: float,
		eye_up: float = 1.70, look_up: float = 1.70) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + eye_up, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + look_up, target.y), Vector3.UP)


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
		return analytic
	return float((hit["position"] as Vector3).y)
