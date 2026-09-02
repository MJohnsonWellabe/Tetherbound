extends SceneTree

## Does entering catch/aim mode actually slow the target down?
##
##   godot --headless --path . --script tests/smoke_catch_aim_slowdown.gd
##
## OWNER PLAYTEST 2026-09-02 finding #6: "Catching is hard because aiming at
## the creature is too hard. They should move a little less or in slow motion
## once you go into catch mode." An earlier investigation
## (`ralph/reports/T5-FEEL-COMBAT-ENGAGES-2026-08-30.md`) measured raw throw
## mechanics and found real throws land at a normal rate — it never tested
## whether the TARGET keeps moving at full speed while the player is trying to
## line up the reticle on it, which is this complaint's actual claim.
##
## This proves the fix at the one level that matters: not that a config number
## exists, but that the wild creature covers measurably less ground during a
## fixed-length window while `throw_aim.gd` reports `is_aiming() == true` than
## it does across an identical window with the aim closed.
##
## `wild_creature.gd::set_engaged(true, opponent)` is called directly (not
## just once via `combat_manager.gd::begin()`) to re-arm a fresh CLOSE beat —
## `combat_ai.gd::decide()` cannot leave CLOSE while `_cooldown` (reset to
## `first_attack_delay`, ~1.5s) is still positive, so this guarantees the
## creature is walking towards its target for the whole measurement window
## regardless of where either fighter happens to stand. That is an existing,
## already-landed pattern (`combat_manager.gd`'s own GATE-F-LEG-S04 auto-switch
## re-arms the same call mid-fight), not a new backdoor invented for this test.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CATCH := preload("res://scripts/combat/catch_math.gd")

const SETTLE_FRAMES := 300
## Physics frames measured per window. At 60Hz this is 1.0s, comfortably
## inside the ~1.5s `first_attack_delay` re-armed immediately before each
## window, so the beat cannot flip away from CLOSE mid-measurement.
const WINDOW_FRAMES := 60
## Metres the target is placed from the trainer's creature before each
## window, so both windows start from the same gap regardless of how far the
## previous window closed it.
const START_GAP := 5.0

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	_seed_orbs()
	if not _collect_nodes():
		_report()
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat; nothing below this point was tested")
		_report()
		return
	_ally = _director.call("ally_body") as Node3D

	await _measure_and_compare()
	_report()


## --- setup, mirrored from tests/smoke_catching.gd --------------------------

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


func _seed_orbs(count: int = 15) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload; nowhere to put the orbs")
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
		_fail("scene is missing the player, camera rig, combat manager or director")
		return false

	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_fail("no wild creature to aim at")
		return false
	if int(_manager.call("orbs_left")) <= 0:
		_fail("the trainer starts with no orbs; nothing here can run")
		return false
	return true


func _walk_to_the_wild_creature() -> void:
	var engage_range := 6.0
	for i in 1500:
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
	for i in 40:
		await physics_frame


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


## --- the actual measurement -------------------------------------------------

## Re-arms a fresh CLOSE beat at a known starting gap, then measures the total
## PATH LENGTH (sum of per-frame position deltas, not net displacement — a
## creature side-stepping cancels out on net displacement but not on ground
## actually covered) the wild creature covers over `WINDOW_FRAMES`.
func _measure_chase_distance(aim_active: bool) -> float:
	var spot := _wild.global_position + Vector3(START_GAP, 0.0, 0.0)
	if not bool(_ally.call("place_on_ground", spot)):
		_ally.global_position = spot
	_ally.set("velocity", Vector3.ZERO)

	# Fresh CLOSE beat with a fresh `first_attack_delay` cooldown -- see the
	# file header for why this guarantees CLOSE for the whole window ahead,
	# an already-landed pattern borrowed from combat_manager.gd's own
	# mid-fight re-arm rather than a new backdoor.
	_wild.call("set_engaged", true, _ally)
	for i in 3:
		await physics_frame

	if aim_active:
		await _press("combat_throw")
		if not bool(_manager.call("is_aiming")):
			_fail("could not open the aim to measure the slowed window")
			return -1.0

	var path := 0.0
	var previous: Vector3 = _wild.global_position
	for i in WINDOW_FRAMES:
		await physics_frame
		var current: Vector3 = _wild.global_position
		path += previous.distance_to(current)
		previous = current

	if aim_active:
		await _press("combat_run")
		if bool(_manager.call("is_aiming")):
			_fail("could not cancel the aim after the measurement window")

	return path


func _measure_and_compare() -> void:
	var baseline := await _measure_chase_distance(false)
	var aimed := await _measure_chase_distance(true)

	if baseline < 0.0 or aimed < 0.0:
		return

	var configured_scale: float = float(CATCH.config().get("aim", {}).get("target_slowdown_scale", 1.0))
	var ratio := aimed / baseline if baseline > 0.0 else 1.0
	print("catch aim slowdown: baseline=%.2fm aimed=%.2fm ratio=%.2f configured_scale=%.2f" % [
		baseline, aimed, ratio, configured_scale,
	])

	if baseline < 1.0:
		_fail("baseline chase covered only %.2fm in %d frames -- too little movement for this measurement to mean anything" % [baseline, WINDOW_FRAMES])
		return

	if aimed >= baseline * 0.7:
		_fail("the target moved almost as far while being aimed at (%.2fm) as it did outside the aim window (%.2fm) -- the owner's ask ('creatures should move a little less or in slow motion once you go into catch mode') is not landing" % [aimed, baseline])
	else:
		print("catch aim slowdown: OK -- the target covered %.0f%% as much ground while aimed at" % (ratio * 100.0))


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("catch_aim_slowdown: OK -- the target moves noticeably less while the player is aiming a catch.")
		quit(0)
		return
	for line in _failures:
		print("catch_aim_slowdown FAIL: %s" % line)
	quit(1)
