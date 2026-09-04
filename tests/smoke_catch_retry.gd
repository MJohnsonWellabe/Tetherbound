extends SceneTree

## G3-OPENING-FIX-0904 (GAME-11/RIG-26). tools/gate_f/segments/S02.json's own
## retry blocks (arm the aim -> track the reticle onto the body -> throw)
## measured "three retries, three re-aims, zero throws" across two Gate F
## runs -- the tutorial catch's own promise, "the practice catch cannot fail
## twice" (data/config/opening.json's `max_catch_failures`, quoting
## docs/specs/OPENING_SEQUENCE.md), only bites on the SECOND landed throw, so
## a retry that silently does nothing strands a fresh save with a party of one.
##
## Root cause traced to two places:
##
##   1. `encounter_director.gd::_spawn_creatures()` crashed on the FIRST spawn
##      cluster processed on this tree ("Invalid access to property or key
##      'combat' on a base object of type 'Dictionary'", from G-2's own
##      inline `for block: Dictionary in [elder, (X) if (Y) else Z]` merge
##      loop) -- `tests/smoke_catching.gd` caught this directly: "no wild
##      creature to throw at", because the crash landed on the practice
##      cluster (order 0, the one this test also drives), before any combat
##      could start at all. Rewritten as explicit locals rather than an
##      inline array-literal ternary; `smoke_catching.gd` is the regression
##      test for that half.
##
##   2. `throw_aim.gd::_release()`'s `_spend_orb()` failure path emitted no
##      signal at all -- the one refusal in the file that broke its own house
##      rule (every other refusal explains itself: out-of-range, no orbs,
##      fainted, owned). A silent failure there is indistinguishable from a
##      dropped input, which is exactly the shape "zero throws" describes.
##
## This drives the SAME shape S02.json's retry blocks do -- arm via the real
## `interact` action, steer the camera onto the body every physics frame like
## `track_aim`, release -- across four consecutive throw cycles against the
## real practice cluster, and asserts every single cycle either spends an orb
## (a throw actually left the hand) or explains itself with a signal. Neither
## happening on any cycle is the defect this file exists to catch.
##
##   godot --headless --path . --script tests/smoke_catch_retry.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")

const SETTLE_FRAMES := 300
const RETRY_CYCLES := 4

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _throw: Node = null
var _wild: Node3D = null

var _failures: Array[String] = []
var _refusals: Array[String] = []
var _struck: Array[float] = []
var _missed: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		_fail("no EncounterDirector in the world")
		_report()
		return
	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")
	for i in 30:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		_fail("scene is missing the player, camera rig, combat manager or director")
		_report()
		return
	_throw = _manager.call("throw_aim")
	if _throw == null:
		_fail("CombatManager has no throw_aim node")
		_report()
		return

	_manager.connect("catch_refused", func(reason: String) -> void: _refusals.append(reason))
	_throw.connect("throw_refused", func(reason: String) -> void: _refusals.append(reason))
	_throw.connect("orb_struck", func(_target, offset: float) -> void: _struck.append(offset))
	_throw.connect("orb_missed", func(message: String) -> void: _missed.append(message))

	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload; nowhere to put the orbs")
		_report()
		return
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "orb_basic", 15)

	for i in 60:
		await physics_frame
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_fail("no wild creature spawned near the practice cluster -- "
			+ "encounter_director.gd::_spawn_creatures() likely errored before it got here")
		_report()
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; nothing below this point was tested")
		_report()
		return

	for cycle in RETRY_CYCLES:
		if not bool(_manager.call("is_fighting")):
			print("fight ended after %d throw cycle(s); the creature was likely caught" % cycle)
			break
		var stock_before := int(_throw.call("stock"))
		var struck_before := _struck.size()
		var missed_before := _missed.size()
		var refused_before := _refusals.size()

		var armed := await _press_until_aiming(3)
		if not armed:
			_fail("throw %d: could not re-arm the aim within 3 presses" % (cycle + 1))
			break
		await _track_until_eligible(240)
		await _release_throw()

		var stock_after := int(_throw.call("stock"))
		var spent := stock_before != stock_after
		await _wait_seconds(6.0)
		var explained := _struck.size() > struck_before or _missed.size() > missed_before \
			or _refusals.size() > refused_before
		if not spent and not explained:
			_fail(("throw %d: the press did nothing at all -- no orb spent, no strike, no miss, "
				+ "no refusal signal. This is GAME-11/RIG-26: the second orb never left the hand.")
				% (cycle + 1))
		elif not spent and explained:
			print("throw %d: refused without spending an orb (%s) -- explained, not silent" % [
				cycle + 1, _refusals[-1] if not _refusals.is_empty() else "?"])
		else:
			print("throw %d: spent an orb (%d -> %d), %s" % [
				cycle + 1, stock_before, stock_after,
				"struck" if _struck.size() > struck_before else "missed"])

	_report()


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


## Same shape as `tools/gate_f/operator_harness.gd::_step_press_until` with
## control="interact": press, settle, check, repeat -- `interact` toggles the
## aim on (arm) exactly like S02-39/S02-43d/f/h do.
func _press_until_aiming(max_presses: int) -> bool:
	if bool(_throw.call("is_aiming")):
		return true
	for attempt in max_presses:
		Input.action_press("interact")
		await physics_frame
		await physics_frame
		Input.action_release("interact")
		for i in 20:
			await physics_frame
		if bool(_throw.call("is_aiming")):
			return true
	return false


## Same shape as `_step_track_aim`: steer the camera at the target's live
## centre every physics frame until the reticle reports eligible, rather than
## a one-shot snap that misses a creature that has moved since aim entry.
func _track_until_eligible(budget: int) -> void:
	if not bool(_throw.call("is_aiming")):
		return
	for i in budget:
		var report: Dictionary = _throw.call("aim_report")
		if bool(report.get("eligible", false)):
			return
		var body: Node3D = _manager.call("enemy_body") as Node3D
		if body == null or not is_instance_valid(body):
			return
		var centre: Vector3 = body.call("centre")
		var camera := (_rig.get_node_or_null(^"Camera3D") as Camera3D)
		if camera == null:
			return
		var to_target := centre - camera.global_position
		var have_yaw := float(_rig.get("yaw"))
		var want_yaw := atan2(-to_target.x, -to_target.z)
		_rig.set("yaw", have_yaw + angle_difference(have_yaw, want_yaw) * 0.3)
		var flat := Vector2(to_target.x, to_target.z).length()
		if flat > 0.01:
			var have_pitch := float(_rig.get("pitch"))
			var want_pitch := atan2(to_target.y, flat)
			_rig.set("pitch", have_pitch + angle_difference(have_pitch, want_pitch) * 0.3)
		await physics_frame


func _release_throw() -> void:
	if not bool(_throw.call("is_aiming")):
		return
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame
		if int(_throw.get("state")) != 1: # left AIMING (0 idle / 2 thrown)
			break


func _wait_seconds(seconds: float) -> void:
	var frames := int(ceil(seconds * float(Engine.physics_ticks_per_second)))
	for i in frames:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("catch retry: OK -- every throw cycle either spent an orb or explained why not.")
		quit(0)
		return
	for line in _failures:
		print("catch retry FAIL: %s" % line)
	quit(1)
