extends SceneTree

## MEASURE the catch loop before touching a single number in `catching.json`.
##
##   godot --headless --path . --script tools/_probe_catch_rate.gd -- \
##       --throws=24 --hp=0.5 --jitter=0
##
## OP-0830-5 (owner playtest, 2026-08-30): *"catching is way too hard."* The
## order attached to that item is explicit that the fix must be diagnosed
## rather than tuned -- the failure could be the catch formula, the aim/throw
## feel, the HP precondition, the timing window, or the orb's flight and
## collision, and multiplying `species_rate` would hide four of those five
## rather than fix any of them.
##
## So this drives the REAL loop -- real input actions, real aim camera, real
## orb, real `catch_math.resolve()` -- at a representative early-game encounter
## and reports where each throw actually died:
##
##   REFUSED       the game would not take the press (and why)
##   MISS          the orb flew and never reached the body (with closest/needed)
##   STRIKE-FAIL   the orb landed, the roll lost
##   CAUGHT        the orb landed, the roll won
##
## plus, for every landed throw, the placement offset the resolution scored it
## at and whether the launch assist was eligible. That last pair is the whole
## diagnosis: `combat_manager.gd::catch_aim_offset()` returns 0 (the full
## `centre_bonus` 1.45) for an ELIGIBLE throw and the reticle/trajectory offset
## otherwise, so "how often is a throw the player believes is on target
## actually eligible" is the difference between a 1.45x and a 0.80x multiplier
## on every single attempt.
##
## ## The aim model, and why it is not the smoke test's
##
## `tests/smoke_catching.gd` aims by setting the camera RIG's yaw at the
## creature, and its own docstring records that this does not put the reticle on
## the body -- the aim profile carries a 1.45m `shoulder_offset`, so the rig
## pointing at the creature and the screen-centre ray reaching it are different
## claims. Measuring a success rate through that aim would measure the harness,
## not the game.
##
## This closes the loop instead: each frame it reads the camera's ACTUAL
## forward, computes the yaw/pitch error to the creature's centre, and feeds it
## back into the rig -- which is what a player does with a thumbstick, and
## converges regardless of the shoulder offset. `--jitter=<deg>` then adds a
## fixed angular error to model a handheld aim that is close but not perfect,
## so the report brackets "a player who lined it up" against "a player who
## nearly lined it up" rather than pretending either is the only case.
##
## Nothing here is a test. It prints numbers; `tests/smoke_catching.gd` is
## still what asserts the wiring.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CATCH := preload("res://scripts/combat/catch_math.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SETTLE_FRAMES := 300

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _throws: int = 16
var _hp_fraction: float = 0.5
var _jitter_deg: float = 0.0
var _seed: int = 20260830
## The representative early-game encounter. `bramblebun` is the practice
## cluster's own species (data/config/spawns.json) and carries `catch_rate` 0.60
## -- the most catchable creature in the Meadows, which is deliberate: if the
## EASIEST early catch is a chore then OP-0830-5 is not about rare species.
var _species_id: String = "bramblebun"

## One row per attempt: {outcome, offset, eligible, reason, chance}
var _rows: Array[Dictionary] = []
var _pending: Dictionary = {}
var _settled: bool = false


func _init() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	for raw: String in OS.get_cmdline_user_args():
		var arg := raw.strip_edges()
		if arg.begins_with("--throws="):
			_throws = maxi(1, int(arg.substr(9)))
		elif arg.begins_with("--hp="):
			_hp_fraction = clampf(float(arg.substr(5)), 0.01, 1.0)
		elif arg.begins_with("--jitter="):
			_jitter_deg = maxf(0.0, float(arg.substr(9)))
		elif arg.begins_with("--seed="):
			_seed = int(arg.substr(7))
		elif arg.begins_with("--species="):
			_species_id = arg.substr(10)


func _run() -> void:
	seed(_seed)
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	_seed_orbs(200)
	if not _collect_nodes():
		quit(1)
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		print("[probe] could not enter combat; nothing measured")
		quit(1)
		return
	_ally = _director.call("ally_body") as Node3D

	for attempt in _throws:
		if not bool(_manager.call("is_fighting")):
			# A catch or a faint ends the encounter, and one encounter is not a
			# sample. Trim the party back to the starter (the five-creature cap
			# is a hard rule and would start refusing throws by attempt six),
			# put a fresh representative creature in front of the player, and
			# keep measuring.
			if not await _reacquire():
				print("[probe] could not re-acquire an encounter after %d attempts" % attempt)
				break
		await _one_attempt()

	_report()
	quit(0)


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _seed_orbs(count: int) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		print("[probe] scene is missing player/rig/manager/director")
		return false
	_manager.connect("catch_refused", _on_refused)
	_manager.connect("catch_resolved", _on_resolved)
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		print("[probe] no wild creature to throw at")
		return false
	return true


func _on_refused(reason: String) -> void:
	_pending["outcome"] = "REFUSED"
	_pending["reason"] = reason
	_settled = true


func _on_resolved(success: bool, _shakes: int) -> void:
	_pending["outcome"] = "CAUGHT" if success else "STRIKE-FAIL"
	_settled = true


func _walk_to_the_wild_creature() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1500:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 40:
		await physics_frame


## A fresh encounter with the same representative species, so the sample is
## many throws rather than many throws at one lucky creature.
func _reacquire() -> bool:
	var game := root.get_node_or_null(^"/root/Game")
	if game != null:
		var party: RefCounted = game.get("party")
		if party != null:
			while int(party.call("size")) > 1:
				party.call("remove_at", int(party.call("size")) - 1)
	var creature: RefCounted = _manager.call("active_creature")
	if creature != null:
		creature.hp = creature.max_hp

	var forward := Vector3(sin(randf() * TAU), 0.0, cos(randf() * TAU))
	var spot := _player.global_position + forward * 7.0
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z))
	var wild: Node3D = _director.call("spawn_wild", _species_id, spot, {})
	if wild == null:
		return false
	_wild = wild
	for i in 30:
		await physics_frame
	await _walk_to_the_wild_creature()
	await _engage()
	return bool(_manager.call("is_fighting"))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


## Put the SCREEN-CENTRE RAY on the creature's centre, by feeding back the
## camera's own measured error -- see the header for why aiming the rig is not
## the same thing. `--jitter` then offsets the converged aim by a fixed angle,
## because a handheld player who has "got it on target" is a degree or two off,
## and a report that only measures a perfect aim is not measuring the game.
func _converge_aim(frames: int) -> void:
	var camera := root.get_camera_3d()
	for i in frames:
		if camera == null or _wild == null or not is_instance_valid(_wild):
			return
		var centre: Vector3 = _wild.call("centre") if _wild.has_method("centre") \
			else _wild.global_position
		var to := (centre - camera.global_position)
		if to.length_squared() < 0.0001:
			return
		to = to.normalized()
		var forward := -camera.global_transform.basis.z
		var yaw_error := wrapf(atan2(-to.x, -to.z) - atan2(-forward.x, -forward.z), -PI, PI)
		var pitch_error := asin(clampf(to.y, -1.0, 1.0)) - asin(clampf(forward.y, -1.0, 1.0))
		_rig.set("yaw", wrapf(float(_rig.get("yaw")) + yaw_error, -PI, PI))
		_rig.set("pitch", float(_rig.get("pitch")) + pitch_error)
		await physics_frame
	if _jitter_deg > 0.0:
		# A fixed magnitude at a rotating bearing, so the sample is not biased
		# to one side of the body.
		var bearing := randf() * TAU
		_rig.set("yaw", float(_rig.get("yaw")) + deg_to_rad(_jitter_deg) * cos(bearing))
		_rig.set("pitch", float(_rig.get("pitch")) + deg_to_rad(_jitter_deg) * sin(bearing))
		for i in 4:
			await physics_frame


func _one_attempt() -> void:
	# Hold the encounter at the tier being measured. The probe is about the
	# throw, so the fight is not allowed to drift the inputs under it.
	var foe: RefCounted = _manager.call("enemy")
	if foe == null:
		return
	# The fight, not the spawner, owns which body is the opponent -- see
	# `combat_manager.gd::enemy_body()`'s own header on why searching the tree
	# for it is a bug.
	var body: Node3D = _manager.call("enemy_body") as Node3D
	if body != null and is_instance_valid(body):
		_wild = body
	foe.hp = foe.max_hp * _hp_fraction
	var creature: RefCounted = _manager.call("active_creature")
	if creature != null:
		creature.hp = creature.max_hp
	if int(_manager.call("orbs_left")) <= 2:
		_seed_orbs(200)

	if not bool(_manager.call("is_aiming")):
		await _press("combat_throw")
		for i in 20:
			await physics_frame
	if not bool(_manager.call("is_aiming")):
		_rows.append({"outcome": "NO-AIM", "reason": "could not enter aim"})
		return

	await _converge_aim(40)

	# Snapshot what the game is telling the player right before the press.
	var report: Dictionary = {}
	var aim: Node = _manager.call("throw_aim")
	if aim != null:
		report = aim.call("aim_report")
	var radius := 0.5
	if _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))
	_pending = {
		"outcome": "LOST",
		"reason": "",
		"locked": bool(_manager.call("catch_aim_is_locked")),
		"advertised": float(_manager.call("catch_chance_now")),
		"aim_offset": float(_manager.call("catch_aim_offset", radius)),
		"hp": _hp_fraction,
		"range": _player.global_position.distance_to(_wild.global_position),
	}
	if not report.is_empty():
		_pending["eligible"] = bool(report.get("eligible", false))
		_pending["assist_reason"] = str(report.get("reason", ""))
		_pending["reticle_offset"] = float(report.get("reticle_offset", -1.0))
	_settled = false

	await _press("combat_throw")
	# Long enough for the whole staged resolution (catching.json `resolve` is
	# about 5.5s end to end on a success) plus the flight before it.
	for i in 900:
		await physics_frame
		if _settled:
			break
	if not _settled:
		_pending["outcome"] = "STUCK"
	_rows.append(_pending.duplicate())
	# Never let a successful catch or a faint end the measurement early.
	for i in 90:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break


func _report() -> void:
	var counts: Dictionary = {}
	var eligible := 0
	var landed := 0
	var caught := 0
	var advertised_sum := 0.0
	var offset_sum := 0.0
	print("")
	print("[probe] === catch loop, %d attempts, hp=%.2f jitter=%.1f deg ===" % [
		_rows.size(), _hp_fraction, _jitter_deg])
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var outcome := str(row.get("outcome", "?"))
		counts[outcome] = int(counts.get(outcome, 0)) + 1
		if bool(row.get("eligible", false)):
			eligible += 1
		if outcome == "CAUGHT" or outcome == "STRIKE-FAIL":
			landed += 1
		if outcome == "CAUGHT":
			caught += 1
		advertised_sum += float(row.get("advertised", 0.0))
		offset_sum += float(row.get("aim_offset", 0.0))
		print("[probe]  %2d  %-12s locked=%s eligible=%s assist=%-22s aim_offset=%.3f advertised=%.3f range=%.1f %s" % [
			i + 1, outcome,
			"y" if bool(row.get("locked", false)) else "n",
			"y" if bool(row.get("eligible", false)) else "n",
			str(row.get("assist_reason", "-")),
			float(row.get("aim_offset", -1.0)),
			float(row.get("advertised", 0.0)),
			float(row.get("range", 0.0)),
			str(row.get("reason", "")),
		])
	var n := maxi(_rows.size(), 1)
	print("[probe] ---")
	for key: String in counts.keys():
		print("[probe] %-12s %d  (%.1f%%)" % [key, int(counts[key]), 100.0 * float(counts[key]) / float(n)])
	print("[probe] assist eligible on   %d/%d  (%.1f%%)" % [eligible, _rows.size(), 100.0 * float(eligible) / float(n)])
	print("[probe] orb reached the body %d/%d  (%.1f%%)" % [landed, _rows.size(), 100.0 * float(landed) / float(n)])
	print("[probe] CATCHES PER THROW    %d/%d  (%.1f%%)" % [caught, _rows.size(), 100.0 * float(caught) / float(n)])
	print("[probe] mean advertised chance %.3f, mean scored offset %.3f" % [
		advertised_sum / float(n), offset_sum / float(n)])
	var foe: RefCounted = _manager.call("enemy")
	if foe != null:
		print("[probe] species=%s catch_rate=%.2f" % [foe.species_id, SPECIES.catch_rate(foe.species_id)])
	print("")
