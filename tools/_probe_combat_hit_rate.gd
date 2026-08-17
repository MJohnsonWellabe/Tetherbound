extends SceneTree

## COMBAT-REACH. Does a real controller's quick-attack press actually connect
## against a wild opponent, and how often?
##
##   godot --headless --path . --script tools/_probe_combat_hit_rate.gd
##
## Filed from OF18's own unchased observation (ralph/NOTES.md, 2026-08-17):
## "energy never reached charged_cost after 16 quick-attack attempts" against a
## real wild encounter, with the numbers (gain_per_quick=26, charged_cost=100)
## meaning four landed hits should have been plenty. That reads as attacks
## whiffing far more than expected -- this probe measures the real number
## instead of guessing at it.
##
## REAL HARDWARE INPUT, not InputEventAction. `combat_quick`'s gamepad binding
## in project.godot is `InputEventJoypadMotion(axis=5, axis_value=1.0)` -- the
## right trigger, not a button -- so an `InputEventAction` or an
## `InputEventJoypadButton` here would both miss the actual binding shape a
## controller sends. The axis/sign is read live off the InputMap, the same
## pattern `tests/smoke_backpack_pad_target.gd` uses for buttons.
##
## Every attempt is only issued once `quick_ready()` says the creature can act,
## so presses map 1:1 onto resolved outcomes (a hit or a miss), which is what
## makes "N presses, M hits" a real hit rate rather than a mix of buffered and
## dropped ones. The `attack_missed`/`hit_landed` handlers below sample the
## attacker's actual facing and the horizontal distance to the target AT THE
## MOMENT the manager makes its connect/miss decision (the signal fires
## synchronously from inside `_resolve_player_strike`, so the geometry read in
## the handler is exactly what the decision was made from -- not a frame
## later, not inferred).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")

const SETTLE_FRAMES := 240
## How many resolved quick-attack attempts to gather before stopping. OF18's
## own sample was 16; 50 is enough to see a real rate rather than noise from a
## handful of presses.
const TARGET_ATTEMPTS := 50
## Backstop so a director that never opens a fight, or a wild creature that
## faints too fast to reach TARGET_ATTEMPTS, still ends the run.
const FRAME_LIMIT := 14000
## Frames to wait for a press to resolve (windup + recovery) before giving up
## and logging it as "no signal" -- player_charged's own worst case is
## windup 0.55 + recovery 0.5 = ~63 frames at 60fps; quick is far shorter.
const RESOLVE_WAIT_FRAMES := 90

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _hits := 0
var _misses := 0
## Populated by the signal handlers for the attempt currently in flight; null
## between attempts.
var _last_result: Dictionary = {}

var _attempts: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_nodes():
		quit(1)
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		print("FAIL: could not enter combat; nothing measured")
		quit(1)
		return

	_ally = _director.call("ally_body") as Node3D
	_manager.connect("attack_missed", _on_missed)
	_manager.connect("hit_landed", _on_hit)

	await _drive_and_measure()
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


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		print("FAIL: scene is missing the player, camera rig, combat manager or director")
		return false

	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		print("FAIL: the encounter director never spawned a wild creature")
		return false
	if _director.call("ally_instance") == null:
		print("FAIL: the player has no creature to fight with")
		return false
	return true


func _walk_to_the_wild_creature() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame


## --- the measurement --------------------------------------------------------

## A real player does not stand still: this drives toward the wild creature
## whenever it has drifted out of comfortable range and otherwise fires the
## real trigger the instant the creature is ready, which is exactly the
## "mash quick whenever it comes up" behaviour OF18's own capture run
## describes. No special-casing for the enemy's telegraph/recover/reposition
## beats -- the point is what an ordinary player's presses actually meet, not
## a hand-tuned punish rhythm.
func _drive_and_measure() -> void:
	var quick_axis := _pad_axis_for("combat_quick")
	if quick_axis.is_empty():
		print("FAIL: combat_quick has no gamepad axis binding at all")
		return
	var move_axis := _pad_axis_for("move_forward")

	var frames := 0
	while _attempts.size() < TARGET_ATTEMPTS and frames < FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			print("fight ended early (outcome '%s') after %d attempts" % [
				str(_manager.call("outcome")), _attempts.size()])
			return

		# Kept alive for measurement only -- a practice-cluster wild creature
		# faints in well under TARGET_ATTEMPTS worth of quick attacks, which
		# would cut the sample short before the AI has cycled through
		# CLOSE/TELEGRAPH/RECOVER/REPOSITION more than once or twice. This never
		# touches damage math, reach or the connect decision -- only how long
		# the target survives to be swung at.
		var enemy: RefCounted = _manager.call("enemy")
		if enemy != null and float(enemy.hp) < float(enemy.max_hp) * 0.3:
			enemy.hp = enemy.max_hp

		var to: Vector3 = _wild.call("centre") - _ally.call("centre")
		to.y = 0.0
		var distance := to.length()

		if distance > 3.0 and not move_axis.is_empty():
			_aim_camera_along(to)
			await _hold_axis(move_axis, 1)
			continue

		if bool(_manager.call("quick_ready")):
			await _attempt_quick(quick_axis)
		else:
			await physics_frame


## One full attempt: press, wait for the manager's own decision, sample and
## record it. Movement is left alone during the wait -- windup roots the
## creature anyway (`combat_manager.gd::_drive_player_creature`), so holding
## the stick would do nothing but muddy what caused the outcome.
func _attempt_quick(quick_axis: Dictionary) -> void:
	var pre_distance: float = (_wild.call("centre") - _ally.call("centre")).length()
	var pre_facing_deg := _facing_error_deg()
	var pre_intent := _intent_name()

	_last_result = {}
	await _tap_axis(quick_axis)

	var waited := 0
	while _last_result.is_empty() and waited < RESOLVE_WAIT_FRAMES:
		await physics_frame
		waited += 1

	if _last_result.is_empty():
		_attempts.append({
			"outcome": "no-signal", "pre_distance": pre_distance,
			"pre_facing_deg": pre_facing_deg, "waited": waited, "intent": pre_intent,
		})
		return

	var entry: Dictionary = _last_result.duplicate()
	entry["pre_distance"] = pre_distance
	entry["pre_facing_deg"] = pre_facing_deg
	entry["waited"] = waited
	entry["intent"] = pre_intent
	_attempts.append(entry)


## The wild AI's own beat at the moment the press was issued -- CLOSE (still
## approaching), TELEGRAPH/RECOVER (rooted -- the AI's own enum groups these
## as `is_rooted()`), REPOSITION (actively retreating), or IDLE. Distinguishes
## "pressed while it was standing still" from "pressed while it was fleeing",
## which combat_ai.gd's own header names as the one beat spacing could plausibly
## defeat a swing during.
func _intent_name() -> String:
	if _wild == null or not _wild.has_method("intent"):
		return "?"
	var value := int(_wild.call("intent"))
	for key in AI.Intent.keys():
		if AI.Intent[key] == value:
			return key
	return "?"


## Degrees between the ally's current facing and the direction to the wild
## creature's centre -- the same quantity `combat_math.gd::in_hit_cone` tests
## against `cone_degrees * 0.5`, computed here independently so this probe does
## not trust the code under test to grade itself.
func _facing_error_deg() -> float:
	var facing: Vector3 = _ally.call("facing")
	var to: Vector3 = _wild.call("centre") - _ally.call("centre")
	to.y = 0.0
	if to.length() < 0.001:
		return 0.0
	var aim := Vector3(facing.x, 0.0, facing.z)
	if aim.length() < 0.001:
		return 180.0
	return rad_to_deg(aim.normalized().angle_to(to.normalized()))


## The reach a quick attack would actually be floored to right now, by the
## same formula `combat_manager.gd::_with_reach_for_the_bodies` applies --
## recomputed here from public data (`body_radius()`, `combat.json`'s own
## `enemy.body_clearance`) rather than read off the manager's private pending
## move, so this number is independent of the code it is cross-checking.
func _floored_range() -> float:
	var base := float(MATH.config().get("player_quick", {}).get("range", 2.6))
	var mine := 0.5
	var theirs := 0.5
	if _ally.has_method("body_radius"):
		mine = float(_ally.call("body_radius"))
	if _wild.has_method("body_radius"):
		theirs = float(_wild.call("body_radius"))
	var clearance := float(MATH.config().get("enemy", {}).get("body_clearance", 1.8))
	return maxf(base, (mine + theirs) * clearance + 0.5)


func _on_missed(by_player: bool) -> void:
	if not by_player or not _last_result.is_empty():
		return
	_misses += 1
	_last_result = {
		"outcome": "miss",
		"resolve_distance": (_wild.call("centre") - _ally.call("centre")).length(),
		"resolve_facing_deg": _facing_error_deg(),
		"floored_range": _floored_range(),
	}


func _on_hit(on_enemy: bool, amount: float) -> void:
	if not on_enemy or not _last_result.is_empty():
		return
	_hits += 1
	_last_result = {
		"outcome": "hit",
		"damage": amount,
		"resolve_distance": (_wild.call("centre") - _ally.call("centre")).length(),
		"resolve_facing_deg": _facing_error_deg(),
		"floored_range": _floored_range(),
	}


## --- real hardware input ----------------------------------------------------

## The axis and sign an action is actually bound to on a gamepad, or an empty
## dict. Read from the live InputMap -- see `smoke_backpack_pad_target.gd`'s
## `_pad_button_for`, the same idea for a button rather than an axis.
func _pad_axis_for(action: String) -> Dictionary:
	if not InputMap.has_action(action):
		return {}
	for event in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null:
			return {"axis": motion.axis, "sign": signf(motion.axis_value)}
	return {}


## A trigger pull long enough to register and release, real
## `InputEventJoypadMotion` throughout -- never an `InputEventAction`, which
## would skip the InputMap translation this probe exists to go through.
func _tap_axis(binding: Dictionary) -> void:
	var down := InputEventJoypadMotion.new()
	down.axis = int(binding["axis"])
	down.axis_value = float(binding["sign"])
	Input.parse_input_event(down)
	await physics_frame
	await physics_frame
	var up := InputEventJoypadMotion.new()
	up.axis = int(binding["axis"])
	up.axis_value = 0.0
	Input.parse_input_event(up)
	for i in 4:
		await physics_frame


## A held stick direction for one physics tick's worth of movement -- called
## in a loop by `_drive_and_measure` so the aim can be corrected every frame,
## the same pattern `smoke_combat.gd::_the_creature_moves_on_the_stick` uses
## with `Input.action_press`, translated to a real axis event.
func _hold_axis(binding: Dictionary, _unused: int) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = int(binding["axis"])
	motion.axis_value = float(binding["sign"])
	Input.parse_input_event(motion)
	await physics_frame
	var release := InputEventJoypadMotion.new()
	release.axis = int(binding["axis"])
	release.axis_value = 0.0
	Input.parse_input_event(release)


func _report() -> void:
	print("")
	print("=== COMBAT-REACH hit-rate probe ===")
	print("%d attempts, %d hits, %d misses, %d no-signal" % [
		_attempts.size(), _hits, _misses, _attempts.size() - _hits - _misses])
	if not _attempts.is_empty():
		var rate := float(_hits) / float(_attempts.size()) * 100.0
		print("hit rate: %.1f%%" % rate)

	var by_intent: Dictionary = {}
	for e: Dictionary in _attempts:
		var key := str(e.get("intent", "?"))
		var bucket: Dictionary = by_intent.get(key, {"hits": 0, "total": 0})
		bucket["total"] = int(bucket["total"]) + 1
		if str(e.get("outcome", "")) == "hit":
			bucket["hits"] = int(bucket["hits"]) + 1
		by_intent[key] = bucket
	print("by wild AI beat at press time:")
	for key in by_intent.keys():
		var bucket: Dictionary = by_intent[key]
		print("  %-11s %d/%d hit" % [key, int(bucket["hits"]), int(bucket["total"])])

	print("")
	print("%-4s %-6s %-11s %-9s %-9s %-9s %-9s %-8s" % [
		"#", "result", "intent", "pre_dist", "pre_ang", "res_dist", "res_ang", "floor"])
	for i in _attempts.size():
		var e: Dictionary = _attempts[i]
		print("%-4d %-6s %-11s %-9.2f %-9.1f %-9s %-9s %-8s" % [
			i + 1, str(e.get("outcome", "?")), str(e.get("intent", "?")),
			float(e.get("pre_distance", -1.0)), float(e.get("pre_facing_deg", -1.0)),
			("%.2f" % float(e["resolve_distance"])) if e.has("resolve_distance") else "-",
			("%.1f" % float(e["resolve_facing_deg"])) if e.has("resolve_facing_deg") else "-",
			("%.2f" % float(e["floored_range"])) if e.has("floored_range") else "-",
		])
