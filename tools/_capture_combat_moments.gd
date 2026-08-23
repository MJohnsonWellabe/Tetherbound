extends SceneTree

## COMBAT-AS-EVENT. Photographs real-time creature combat for a blind visual
## critic, through the REAL combat camera (`CameraRig`/`Camera3D`, the same
## SpringArm3D `scripts/player/camera_rig.gd` drives in exploration and
## `combat_manager.gd::_take_camera()` re-points at the fight) rather than a
## survey camera built for this tool.
##
## Why: `.claude/skills/visual-judge/SKILL.md` names "whether a fight looks
## like an event" as an axis the Palworld references
## (`docs/reference/palworld-01-boss-fight-forest.jpg`,
## `palworld-03-field-boss-meadow.jpg`) may be judged on, and no survey has
## ever put a Tetherbound fight in front of a critic. Combat here is
## real-time and directly piloted (CLAUDE.md: no shields, human never
## fights, catching happens during wild combat, trainer-owned creatures
## cannot be caught) — none of that is checkable from data or from a
## world-survey frame; it has to be photographed while it is happening.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_combat_moments.gd
##
## NEVER `--headless` together with a real rendering driver. Verified
## 2026-08-22 (ralph/conventions.md, "Art pipeline traps"): that combination
## hangs FOREVER with no error, no crash, no partial output — and leaves a
## zombie Godot process burning CPU after the lane that started it gives up.
## `--headless` alone is correct and fast for tests, which render nothing;
## it is specifically headless + opengl3 that hangs. This tool renders, so
## it never uses `--headless`.
##
## FRAME BUDGET, measured against the corridor survey's own number
## (`tools/_probe_corridor_survey.gd`: ~2.4s per awaited frame under llvmpipe
## at 1280x800 — every `await physics_frame`/`await process_frame` in this
## script is a full software render, not a cheap tick). The plan below stays
## inside ONE world instance and drives THREE encounters in it rather than
## reloading the scene per shot, because the boot alone (terrain, vegetation,
## the whole spawn table) is the single most expensive fixed cost here:
##
##   boot (BOOT_FRAMES)                                    ~90 frames
##   leave the farmhouse + adopt the starter                ~5 frames
##   encounter A (wild fight): engage, teleport-settle,
##     engage-settle, a quick attack's windup/resolve/
##     travel, a shot pair after each of 3 moments, then
##     open+shoot the catch reticle and flee                ~170 frames
##   encounter B (trainer battle): teleport-settle,
##     begin_trainer_battle() directly (no dialogue —
##     see "trainer battle" below), engage-settle, one
##     shot pair, flee                                       ~70 frames
##   encounter C (elite/boss): teleport-settle (this one
##     is a 1km jump, so extra margin for Terrain3D to
##     stream collision there), engage-settle, one shot
##     pair, flee                                             ~90 frames
##   ------------------------------------------------------------------
##   total                                                  ~425 frames
##                                                           ~17 minutes
##
## That leaves real headroom under the 25-minute / ~600-frame ceiling for the
## bounded retries this script actually takes (a missed quick attack, a strike
## that does not resolve, an aim that does not open) — every one of those
## waits is capped and FAILs loudly rather than hanging (requirement 5/6): the
## single worst thing a capture tool can do here is the 45-minute wait on a
## moment that never came that an earlier harness already paid for once.
##
## SHOT LIST (12 PNGs — six moments, each shot twice):
##   01-engagement          — player creature and wild creature squared up,
##                             the instant a wild fight opens
##   02-move-firing          — a quick attack's projectile VFX in flight
##                             (Terrapup's pebble_toss, `data/moves/moves.json`)
##   03-hit-landing           — the impact flash + the wild creature's hit
##                             reaction, the same attack a few frames later
##   04-catching               — the capture reticle up, mid-aim, over the
##                             SAME wild creature (thrown never released —
##                             the aim is cancelled afterwards so nothing is
##                             actually caught)
##   05-trainer-battle         — engaged against `practice_trainer` (Bryn),
##                             a trainer-owned creature, which cannot be caught
##   06-elite-encounter         — engaged against Band 1's one elder (Elder
##                             Mosshell, `data/config/bands/band1_lower_meadows/
##                             spawns.json` order 1900) — the closest thing to
##                             a boss reachable without playing the whole
##                             chapter first; CLAUDE.md forbids Biome 2 work,
##                             so nothing past Band 1 is in scope here anyway
## Each is written twice: `<name>-hud.png` (the world exactly as the game
## draws it — CombatHUD, and whatever else happens to be showing) and
## `<name>-clean.png` (every CanvasLayer this scene owns forced invisible for
## one render, then restored). The HUD frames answer visual-judge's interface
## criterion; the clean frames answer whether the FIGHT reads on its own —
## one set of shots cannot honestly answer both questions.
##
## THE CAMERA, AND WHY THE 1.80 m TRAINER IS NOT IN EVERY FRAME. This is not
## a survey — it is the SAME `CameraRig` the player looks through, doing
## exactly what it does in play: `combat_manager.gd::_take_camera()`
## re-targets it onto the piloted creature (`_ally_body`) for the fight
## itself, and `throw_aim.gd::_apply_aim_camera()` re-targets it onto the
## PLAYER for the over-the-shoulder throw. Nothing here builds a second
## camera or moves the rig by hand beyond setting `yaw` toward whichever
## body the rig is currently centred on — the same substitute for a
## controller stick every existing combat probe already uses
## (`tools/_probe_combat_hit_rate.gd::_aim_camera_along`), because there is
## no human hand on a stick in a `--script` run.
##
## `combat_manager.gd::_stand_the_trainer_aside()` moves the human trainer to
## the SIDE of the arena the moment a fight opens, specifically so their
## 1.8m body does not block the camera's view of the creature fight — its
## own comment says the old behaviour "filled the frame". That is a real,
## deliberate design decision (human never fights; the creature IS the
## fight), not an oversight this tool should route around, so the
## engagement/move-firing/hit-landing/trainer-battle/elite frames do NOT
## reliably contain the trainer as a scale ruler — by design, the camera is
## not looking at them. The one shot where the trainer genuinely is the
## camera's own anchor is 04-catching: the throw camera sits behind and
## above THEM, over their shoulder, so that frame is where relative scale
## against the 1.80 m trainer is actually checkable.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/combat"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const BOOT_FRAMES := 90
## After a teleport close to where the world already booted (band 1's near
## field). Generous over `_probe_corridor_survey.gd`'s own ARRIVE_FRAMES (20)
## because that tool disables the rig and drives Terrain3D's camera by hand;
## this one lets the real rig (and therefore Terrain3D, which
## `playground_world.gd` hands the PLAYER's own camera) catch up on its own.
const NEAR_TELEPORT_SETTLE_FRAMES := 25
## The elder mosshell is roughly 1km from where the world boots. Terrain3D
## streams collision around the camera dynamically
## (`encounter_director.gd`'s own GATE-D comment measures this exact cost for
## a wild creature reactivating far from boot); a jump this size gets more
## room than a near teleport to avoid photographing a frame the ground has
## not finished streaming into.
const FAR_TELEPORT_SETTLE_FRAMES := 45
## After any `begin()`/`begin_trainer_battle()`/engage: long enough for
## `camera_rig.gd::_follow()`'s exponential-smoothing retarget
## (`combat.json` camera.retarget_lag = 6.0) to have visibly arrived rather
## than photographing the glide mid-flight, and for `flow.input_guard`
## (0.25s) to have cleared.
const ENGAGE_SETTLE_FRAMES := 40
## Bounded wait for `hit_landed`/`attack_missed` after a quick-attack press.
## `player_quick.windup` is 0.18-0.22s (~11-13 physics frames at 60fps); this
## is generous the same way `_probe_combat_hit_rate.gd::RESOLVE_WAIT_FRAMES`
## (90) is, so a genuinely stuck attack FAILs instead of hanging.
const STRIKE_RESOLVE_BOUND := 60
## After the strike resolves, before the "move firing" shot: enough physics
## time for the projectile to be visibly clear of the creature that just
## threw it (pebble_toss travels at 26 m/s; 6 frames is ~2.6m of travel).
const PROJECTILE_INFLIGHT_FRAMES := 6
## From the "move firing" shot to the "hit landing" shot: the remaining
## flight time to a ~5m separation (`combat.json` arena.separation) at 26
## m/s is ~12 frames; this adds margin for the impact flash to actually be
## on screen rather than photographed one frame early.
const IMPACT_SETTLE_FRAMES := 20
## Let `player_quick.recovery` (0.22-0.24s, ~13-15 frames) finish so
## `_action == Action.READY` before the aim button is pressed — pressing
## Throw during recovery is silently ignored by `_read_player_input()`.
const RECOVERY_SETTLE_FRAMES := 20
## `catching.json` aim.guard plus enough for the reticle to have a real
## position/chance drawn into it (`combat_hud.gd` reads the manager every
## frame; there is no signal for "the reticle has a value").
const AIM_SETTLE_FRAMES := 15
## How many times a missed quick attack (or a fight that never opened) is
## retried before this tool gives up on that shot and prints FAIL rather
## than looping forever.
const MAX_ATTEMPTS := 3
## process_frame waits before a shutter, matching
## `_probe_corridor_survey.gd::POSE_FRAMES` — enough for a just-toggled
## CanvasLayer visibility change to actually reach the next drawn frame.
const RENDER_SETTLE_FRAMES := 2
## Bounded wait for a fight/trainer-battle to actually end after fleeing, so
## a director stuck mid-teardown FAILs loudly instead of corrupting the next
## encounter's state silently.
const FLEE_BOUND := 90

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null

## Set by the `hit_landed`/`attack_missed` signal handlers for whichever
## quick-attack attempt is currently in flight; cleared before each attempt.
## Same shape as `_probe_combat_hit_rate.gd::_last_result`.
var _last_strike: Dictionary = {}

var _frame_count := 0
var _shots_written := 0
var _shots_failed := 0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run, see the header comment")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	await _await_physics(BOOT_FRAMES, "boot")

	if not _collect_nodes():
		quit(1)
		return

	_manager.connect("hit_landed", _on_hit)
	_manager.connect("attack_missed", _on_missed)

	_leave_the_farmhouse()
	await _ensure_ally()
	if _director.call("ally_instance") == null:
		print("FAIL: the player has no creature to fight with; nothing below this point can run")
		_report()
		quit(1)
		return

	await _run_wild_encounter()
	await _run_trainer_encounter()
	await _run_elite_encounter()

	_report()
	quit(0)


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		print("FAIL: scene is missing the player, camera rig, combat manager or director")
		return false
	return true


## Same reasoning as `_probe_combat_hit_rate.gd::_leave_the_farmhouse` — a
## known-clear spot before anything else is asked of the player.
func _leave_the_farmhouse() -> void:
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO


## `sequence_director.gd` suspends the sandbox's automatic starter for the
## real opening flow; this scene carries that node, so the starter has to be
## granted directly. Same call every combat probe/smoke test in this repo
## already makes for the same reason (`_probe_combat_hit_rate.gd`,
## `smoke_trainer_battle.gd`, both `_ensure_ally()`).
func _ensure_ally() -> void:
	if _director.call("ally_instance") != null:
		return
	await _director.call("adopt_starter", "terrapup")


## --- encounter A: the wild fight (engagement, move firing, hit landing, catching) ---

func _run_wild_encounter() -> void:
	print("")
	print("=== encounter A: wild fight (bramblebun cluster, band 1) ===")
	# spawns.json role "practice" is bramblebun; the cluster centre is
	# data/config/bands/band1_lower_meadows/spawns.json order 0, [30, 0, -40].
	var cluster_centre := Vector3(30.0, 0.0, -40.0)
	var wild := _find_nearest_wild(cluster_centre)
	if wild == null:
		print("FAIL: no wild creature found near the bramblebun cluster; encounter A skipped")
		return

	await _teleport_player_near(wild.global_position, NEAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage the practice wild creature; encounter A stops here")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	_aim_camera(ally.global_position, wild.global_position)
	await _shoot_pair("01-engagement")

	var attempt := 0
	var landed := false
	while attempt < MAX_ATTEMPTS and not landed:
		attempt += 1
		print("quick-attack attempt %d/%d" % [attempt, MAX_ATTEMPTS])
		ally = _director.call("ally_body") as Node3D
		if ally == null or wild == null or not is_instance_valid(wild):
			print("FAIL: the ally body or the wild creature disappeared mid-attempt")
			break
		_aim_camera(ally.global_position, wild.global_position)
		var result := await _throw_a_quick_attack()
		if result.is_empty():
			print("FAIL: quick attack %d/%d did not resolve within %d frames (no signal)" % [
				attempt, MAX_ATTEMPTS, STRIKE_RESOLVE_BOUND])
			continue
		if str(result.get("outcome", "")) != "hit":
			print("quick attack %d/%d missed; retrying" % [attempt, MAX_ATTEMPTS])
			continue
		landed = true

		await _await_physics(PROJECTILE_INFLIGHT_FRAMES, "projectile in flight")
		if not bool(_manager.call("is_fighting")):
			print("FAIL: the fight ended before the projectile could be photographed")
			break
		ally = _director.call("ally_body") as Node3D
		if ally != null and is_instance_valid(wild):
			_aim_camera(ally.global_position, wild.global_position)
		await _shoot_pair("02-move-firing")

		await _await_physics(IMPACT_SETTLE_FRAMES, "impact settle")
		if bool(_manager.call("is_fighting")) and is_instance_valid(wild):
			ally = _director.call("ally_body") as Node3D
			if ally != null:
				_aim_camera(ally.global_position, wild.global_position)
			await _shoot_pair("03-hit-landing")
		else:
			print("FAIL: the fight ended before the hit-reaction frame could be photographed")

	if not landed:
		print("FAIL: no quick attack landed in %d attempts; 02-move-firing/03-hit-landing were not both captured" % MAX_ATTEMPTS)

	if bool(_manager.call("is_fighting")):
		await _await_physics(RECOVERY_SETTLE_FRAMES, "recovery settle before opening the aim")
		if await _open_aim():
			ally = _director.call("ally_body") as Node3D
			if ally == null:
				ally = _player
			if is_instance_valid(wild):
				_aim_camera(_player.global_position, wild.global_position)
			await _shoot_pair("04-catching")
			await _cancel_aim()
		else:
			print("FAIL: the capture reticle never opened; 04-catching was not captured")

	await _flee_if_fighting()


## One quick-attack press, and the resolved outcome, or {} if nothing
## resolved within `STRIKE_RESOLVE_BOUND`. Mirrors
## `_probe_combat_hit_rate.gd::_attempt_quick`.
func _throw_a_quick_attack() -> Dictionary:
	_last_strike = {}
	await _press("combat_quick")
	var waited := 0
	while _last_strike.is_empty() and waited < STRIKE_RESOLVE_BOUND:
		waited += 1
		_frame_count += 1
		print("[frame %4d] waiting for the quick attack to resolve (%d/%d)" % [
			_frame_count, waited, STRIKE_RESOLVE_BOUND])
		await physics_frame
	return _last_strike


func _on_hit(on_enemy: bool, amount: float) -> void:
	if not on_enemy or not _last_strike.is_empty():
		return
	_last_strike = {"outcome": "hit", "damage": amount}


func _on_missed(by_player: bool) -> void:
	if not by_player or not _last_strike.is_empty():
		return
	_last_strike = {"outcome": "miss"}


## Opens the capture reticle and waits for `is_aiming()`, bounded. Never
## releases the throw — the reticle is the shot, not the catch.
func _open_aim() -> bool:
	await _press("combat_throw")
	var waited := 0
	while not bool(_manager.call("is_aiming")) and waited < AIM_SETTLE_FRAMES * 2:
		waited += 1
		_frame_count += 1
		print("[frame %4d] waiting for the aim to open (%d/%d)" % [
			_frame_count, waited, AIM_SETTLE_FRAMES * 2])
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		return false
	await _await_physics(AIM_SETTLE_FRAMES, "aim settle (reticle materialising)")
	return bool(_manager.call("is_aiming"))


## `throw_aim.gd::_tick_aiming` reads `combat_run`/`menu_cancel` to back out
## for free — no orb spent, the fight keeps running.
func _cancel_aim() -> void:
	if not bool(_manager.call("is_aiming")):
		return
	await _press("combat_run")
	await _await_physics(5, "leaving the aim")


## --- encounter B: a trainer battle -----------------------------------------

## `TRAINER_ID` is `practice_trainer` ("Bryn") —
## `data/config/bands/band1_lower_meadows/trainers.json`'s own comment names
## this row as the one standalone trainer kept specifically so a tool can
## drive a real trainer fight through `trainer_npc.gd`'s own placement
## without depending on the village-greeting trainers' dialogue routing.
##
## `begin_trainer_battle()` is called DIRECTLY rather than through the
## challenge conversation `smoke_trainer_battle.gd` drives — that dialogue
## exchange costs many real-rendered frames for words a blind image critic
## never reads, and this tool's whole budget is frames. Everything the
## camera actually needs to see (the trainer, their creature, the arena) is
## identical either way: `encounter_director.gd::_start_fight()` is the one
## door both routes walk through.
const TRAINER_ID := "practice_trainer"


func _run_trainer_encounter() -> void:
	print("")
	print("=== encounter B: trainer battle (%s) ===" % TRAINER_ID)
	var spec: Dictionary = TRAINERS.trainer(TRAINER_ID)
	if spec.is_empty():
		print("FAIL: trainers.json has no trainer '%s'; encounter B skipped" % TRAINER_ID)
		return
	var trainers_node: Node = _world.get_node_or_null(^"Trainers")
	if trainers_node == null:
		print("FAIL: the world built no Trainers node; encounter B skipped")
		return
	var trainer_body: Node3D = trainers_node.call("body_for", TRAINER_ID) as Node3D
	if trainer_body == null:
		print("FAIL: trainer '%s' was never stood up in the world; encounter B skipped" % TRAINER_ID)
		return

	var facing := deg_to_rad(float(spec.get("facing_deg", 0.0)))
	var spot := trainer_body.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.6
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	_aim_camera(_player.global_position, trainer_body.global_position)
	await _await_physics(NEAR_TELEPORT_SETTLE_FRAMES, "trainer teleport settle")

	if not bool(_director.call("can_challenge", spec)):
		print("FAIL: the director refuses this challenge (already beaten, or no ally); encounter B skipped")
		return
	if not bool(_director.call("begin_trainer_battle", spec, trainer_body)):
		print("FAIL: begin_trainer_battle() returned false; encounter B skipped")
		return

	await _await_physics(ENGAGE_SETTLE_FRAMES, "trainer-battle camera settle")
	if not bool(_manager.call("is_fighting")):
		print("FAIL: the trainer battle never actually opened a fight; 05-trainer-battle was not captured")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	var opponent: Node3D = _world.find_child("TrainerCreature_*", true, false) as Node3D
	if ally != null and opponent != null:
		_aim_camera(ally.global_position, opponent.global_position)
	await _shoot_pair("05-trainer-battle")

	await _flee_if_fighting()


## --- encounter C: the elite/boss-tier encounter ----------------------------

## Band 1's own elder — `data/config/bands/band1_lower_meadows/spawns.json`
## order 1900, a solitary level-boosted, scaled-up mosshell (`elder.title`
## "Elder", `body_scale` 1.35, `level_bonus` +4). CLAUDE.md forbids Biome 2
## work until the Meadows exits, so nothing past Band 1 is reachable content
## right now; this is the strongest single wild encounter that already
## exists in the shipped game. `radius: 0.0, count: 1` in that entry means
## this is the one wild creature standing exactly at its authored centre —
## no scatter to search.
const ELDER_CENTRE := Vector3(-490.0, 0.0, 555.0)


func _run_elite_encounter() -> void:
	print("")
	print("=== encounter C: elite encounter (elder mosshell, band 1) ===")
	var wild := _find_nearest_wild(ELDER_CENTRE)
	if wild == null:
		print("FAIL: no wild creature found at the elder mosshell's spawn point; encounter C skipped")
		return
	if wild.global_position.distance_to(ELDER_CENTRE) > 5.0:
		print("FAIL: nearest wild creature to the elder's spawn is %.0fm away; likely the wrong creature; encounter C skipped" % wild.global_position.distance_to(ELDER_CENTRE))
		return

	var display_name := "?"
	var instance: Variant = wild.get("instance")
	if instance != null:
		display_name = str(instance.get("display_name"))
	print("found '%s' at %s" % [display_name, wild.global_position])

	await _teleport_player_near(wild.global_position, FAR_TELEPORT_SETTLE_FRAMES)
	if not await _engage(wild):
		print("FAIL: could not engage the elder mosshell; 06-elite-encounter was not captured")
		return

	var ally: Node3D = _director.call("ally_body") as Node3D
	if ally != null:
		_aim_camera(ally.global_position, wild.global_position)
	await _shoot_pair("06-elite-encounter")

	await _flee_if_fighting()


## --- shared plumbing --------------------------------------------------------

func _find_nearest_wild(from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for entry: Variant in _director.call("wild_creatures"):
		var body := entry as Node3D
		if body == null or not is_instance_valid(body):
			continue
		var d := body.global_position.distance_to(from)
		if d < best_distance:
			best = body
			best_distance = d
	return best


## Stands the player a few metres from `spot`, facing it — close enough to be
## well inside `flow.engage_range` (6.0m) without walking, the same shortcut
## every combat probe in this repo already takes (a capture tool is not the
## traversal smoke test).
func _teleport_player_near(spot: Vector3, settle_frames: int) -> void:
	var stand := spot + Vector3(0.0, 0.0, 4.0)
	stand.y = float(_world.call("ground_height_at", stand.x, stand.z)) + 1.0
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	_aim_camera(_player.global_position, spot)
	await _await_physics(settle_frames, "teleport settle")


func _aim_camera(from: Vector3, to: Vector3) -> void:
	var dir := to - from
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_rig.set("yaw", atan2(-dir.x, -dir.z))


## Press the interact button until a fight opens, bounded. The wild bodies
## this tool engages are peaceful (GAME_DESIGN.md 14: proximity never starts
## a fight with one), so this is the only door in — same as a player's own
## first press.
func _engage(wild: Node3D) -> bool:
	var attempt := 0
	while attempt < MAX_ATTEMPTS and not bool(_manager.call("is_fighting")):
		attempt += 1
		await _press("interact")
		var waited := 0
		while not bool(_manager.call("is_fighting")) and waited < 30:
			waited += 1
			_frame_count += 1
			print("[frame %4d] waiting to engage (attempt %d/%d, %d/30)" % [
				_frame_count, attempt, MAX_ATTEMPTS, waited])
			await physics_frame
	if not bool(_manager.call("is_fighting")):
		return false
	await _await_physics(ENGAGE_SETTLE_FRAMES, "engage camera settle")
	return bool(_manager.call("is_fighting"))


## Flee cleanly so the next encounter starts from a known INACTIVE state.
## Cancels an open aim first — `_flee_pressed()` is not read while the throw
## is busy (`combat_manager.gd::_read_player_input`'s own guard).
func _flee_if_fighting() -> void:
	if not bool(_manager.call("is_fighting")):
		return
	if bool(_manager.call("is_aiming")):
		await _cancel_aim()
	await _press("combat_run")
	var waited := 0
	while bool(_manager.call("is_fighting")) and waited < FLEE_BOUND:
		waited += 1
		_frame_count += 1
		print("[frame %4d] waiting for the fight to end (%d/%d)" % [_frame_count, waited, FLEE_BOUND])
		await physics_frame
	if bool(_manager.call("is_fighting")):
		print("FAIL: the fight did not end after fleeing; the next encounter may start from a bad state")


## Real hardware-shaped presses: hold for two physics frames before
## releasing, same as `smoke_trainer_battle.gd::_press` — `is_action_just_pressed`
## is scoped to the frame the press lands in, and pressing between frames can
## put it in a frame that has already run.
func _press(action: String) -> void:
	Input.action_press(action)
	await _await_physics(2, "press %s" % action)
	Input.action_release(action)
	await _await_physics(1, "release %s" % action)


## --- the shutter ------------------------------------------------------------

## One conceptual moment, two frames: the world exactly as the game draws
## it, then every CanvasLayer this scene owns forced invisible for one more
## render. Both renders happen on `process_frame` waits, never
## `physics_frame` — the fight's own action state machine
## (`combat_manager.gd::_tick_action`) only advances on the physics tick, so
## toggling HUD visibility between the two shots does not let the moment
## drift out from under them.
func _shoot_pair(name: String) -> void:
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (hud) for %s" % name)
	await _screenshot("%s/%s-hud.png" % [OUT_DIR, name])

	var saved: Dictionary = {}
	for child in _world.get_children():
		if child is CanvasLayer:
			saved[child] = (child as CanvasLayer).visible
			(child as CanvasLayer).visible = false
	await _await_process(RENDER_SETTLE_FRAMES, "render settle (clean) for %s" % name)
	await _screenshot("%s/%s-clean.png" % [OUT_DIR, name])

	for child: Variant in saved.keys():
		if is_instance_valid(child):
			(child as CanvasLayer).visible = bool(saved[child])


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % path)
		_shots_failed += 1
		return
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % path)
		_shots_failed += 1
		return
	print("shot: %s" % path)
	_shots_written += 1


func _await_physics(n: int, label: String) -> void:
	for i in n:
		_frame_count += 1
		print("[frame %4d] %s (%d/%d)" % [_frame_count, label, i + 1, n])
		await physics_frame


func _await_process(n: int, label: String) -> void:
	for i in n:
		_frame_count += 1
		print("[frame %4d] %s (%d/%d)" % [_frame_count, label, i + 1, n])
		await process_frame


func _report() -> void:
	print("")
	print("=== combat moments capture: %d frames, %d shots written, %d shots failed ===" % [
		_frame_count, _shots_written, _shots_failed])
	print("written to %s" % OUT_DIR)
