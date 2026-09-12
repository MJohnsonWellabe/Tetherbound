extends SceneTree

## OWNER-0912 Tier 0 #8: a cleared Meadows wild cluster stays cleared for the
## configured five-minute cooldown, including after the player leaves its
## streaming radius and comes back. The same production body becomes available
## when that cooldown expires; streaming must not manufacture a replacement.
##
## This is deliberately a production smoke rather than a timer-shaped unit:
## it boots the Meadows, adopts the ordinary starter through EncounterDirector,
## physically engages an authored one-member cluster, and wins through the real
## CombatManager/input pilot. Only then does it use EncounterDirector's existing
## `_tick_respawn(delta)` seam to cross 300 seconds deterministically. No rule is
## shortened or bypassed: the smoke first pins the live configured duration and
## checks both sides of its exact remaining-time boundary.
##
##   godot --headless --path . --script tests/smoke_meadows_wild_respawn_cooldown_0912.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PILOT := preload("res://tools/combat_pilot.gd")

const TARGET_NAME := &"Wild_bramblebun_1018_1"
const CONFIGURED_COOLDOWN_SECONDS := 300.0
const BEFORE_BOUNDARY_SECONDS := 0.25
const SPAWN_WAIT_FRAMES := 900
const APPROACH_SEAT_RADII := [2.4, 3.2, 4.0, 4.8, 5.5]
const APPROACH_SEATS_PER_RING := 16
const APPROACH_SETTLE_FRAMES := 3

var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _arbiter: Node = null
var _wild: Node3D = null
var _cluster: Dictionary = {}
var _failures: Array[String] = []
var _receipt: Dictionary = {}
var _approach_winners: Dictionary = {}
var _approach_seat: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	if not _require(_player != null and _rig != null and _manager != null \
			and _director != null and _arbiter != null,
			"production Meadows is missing Player, CameraRig, CombatManager, " \
			+ "EncounterDirector, or InteractionArbiter"):
		_report()
		return

	for _frame in SPAWN_WAIT_FRAMES:
		_wild = _find_target()
		if _wild != null:
			break
		await physics_frame
	if not _require(_wild != null,
			"authored Meadows cluster %s did not spawn within %d physics frames" % [
				TARGET_NAME, SPAWN_WAIT_FRAMES]):
		_report()
		return

	_cluster = _director.get("_wild_cluster").get(_wild, {}) as Dictionary
	if not _require(not _cluster.is_empty(), "%s has no production streaming cluster" % TARGET_NAME):
		_report()
		return
	var members: Array = _cluster.get("members", []) as Array
	if not _require(members.size() == 1 and members[0] == _wild,
			"target must remain a real one-member cluster so clearing it clears the whole cluster"):
		_report()
		return
	if not _require(not (_director.get("_once_only") as Dictionary).has(_wild),
			"target unexpectedly became once-only; this smoke needs the ordinary respawn lifecycle"):
		_report()
		return
	if not _require(_matching_actor_count() == 1,
			"production boot did not create exactly one actor named %s" % TARGET_NAME):
		_report()
		return

	var configured := float(_director.call("_respawn_delay_for", _wild))
	if not _require(is_equal_approx(configured, CONFIGURED_COOLDOWN_SECONDS),
			"ordinary Meadows cooldown is %.3fs, expected the owner-approved 300s" % configured):
		_report()
		return

	if _director.call("ally_instance") == null:
		if not await _director.call("adopt_starter", "terrapup"):
			_fail("production EncounterDirector could not adopt the ordinary Meadows starter")
			_report()
			return
	for _frame in 30:
		await physics_frame

	# Sample bounded, ground-seated approaches around the live actor. Nearby
	# harvest prompts remain fully registered and enabled; a seat is accepted
	# only when the ordinary arbiter publishes EncounterDirector's exact engage
	# offer. Entry itself remains the normal physical interact action.
	if not await _stage_published_engage():
		var winner := _arbiter.call("winning_provider") as Node
		var winner_name := str(winner.name) if winner != null else "<none>"
		_fail("bounded production approaches never published the exact target's " \
			+ "actionable engage offer (engageable=%s, arbiter=%s, prompt='%s', " \
			+ "observed_winners=%s)" % [str(_director.call("_engageable")),
				winner_name, str(_arbiter.call("prompt")), JSON.stringify(_approach_winners)])
		_report()
		return
	if not _require(_director.call("_engageable") == _wild \
			and _arbiter.call("winning_provider") == _director \
			and bool((_arbiter.call("winner") as Dictionary).get("actionable", false)),
			"published engage offer changed before the physical interact press"):
		_report()
		return
	var physical_engage_distance := _player.global_position.distance_to(_wild.global_position)
	await _press_interact()
	if not _require(bool(_manager.call("is_fighting")),
			"physical interact did not enter production combat with %s" % TARGET_NAME):
		_report()
		return
	if not _require(_director.get("_engaged_with") == _wild,
			"production combat engaged a different wild actor"):
		_report()
		return

	var pilot := PILOT.new(self, _manager, _director, _rig)
	pilot.pilot = PILOT.Pilot.SPACER
	var fight: Dictionary = await pilot.fight_to_the_end()
	if not _require(not bool(fight.get("timed_out", true))
			and str(fight.get("outcome", "")) == "won",
			"real input-piloted cluster clear did not win: %s" % str(fight)):
		_report()
		return

	# `_process()` is the production caller of `_tick_respawn`. Stop that caller
	# after the real `exited` signal has armed the timer, then advance the same
	# production seam explicitly so this smoke does not consume five wall-clock
	# minutes. The timer value itself is never rewritten.
	_director.set_process(false)
	var respawns: Dictionary = _director.get("_respawn_timers") as Dictionary
	var faints: Dictionary = _director.get("_faint_timers") as Dictionary
	if not _require(respawns.has(_wild) and faints.has(_wild),
			"winning the real fight did not arm both faint linger and respawn timers"):
		_report()
		return
	var remaining := float(respawns[_wild])
	if not _require(remaining <= configured and remaining >= configured - 0.25,
			"respawn timer was not armed at the configured boundary (remaining %.3fs)" % remaining):
		_report()
		return
	if not _require(not bool(_wild.call("is_alive")) and not _wild.is_physics_processing(),
			"cleared wild remained available immediately after the won outcome"):
		_report()
		return

	# Leave beyond the cluster's full activation envelope. Streaming marks the
	# cluster inactive while the respawn timer continues to own its cleared body.
	var centre: Vector3 = _cluster.get("centre", Vector3.ZERO)
	var radius := float(_cluster.get("radius", 0.0))
	var margin := float(_director.call("_activation_radius_margin"))
	_place_player_near(centre, radius + margin + 80.0)
	_director.call("_tick_streaming")
	if not _require(not bool(_cluster.get("active", true)),
			"leaving beyond the production activation envelope did not unload/disable the cluster"):
		_report()
		return
	if not _require(((_director.get("_respawn_timers") as Dictionary).has(_wild)),
			"streaming departure discarded the live respawn lifecycle"):
		_report()
		return
	if not _require(_matching_actor_count() == 1,
			"streaming departure duplicated or removed the authored actor"):
		_report()
		return

	# Advance to a quarter-second before the exact live timer expires, return to
	# the actor's home, and prove proximity cannot make it reappear early.
	_director.call("_tick_respawn", remaining - BEFORE_BOUNDARY_SECONDS)
	var home: Vector3 = _wild.get("home") as Vector3
	_place_player_near(home, 2.5)
	_director.call("_tick_streaming")
	respawns = _director.get("_respawn_timers") as Dictionary
	if not _require(bool(_cluster.get("active", false)),
			"returning to the cluster did not restore its production proximity state"):
		_report()
		return
	if not _require(respawns.has(_wild)
			and is_equal_approx(float(respawns[_wild]), BEFORE_BOUNDARY_SECONDS),
			"return before five minutes did not preserve the remaining cooldown"):
		_report()
		return
	if not _require(not _wild.visible and not bool(_wild.call("is_alive"))
			and _director.call("_engageable") != _wild,
			"returning before five minutes made the cleared wild available again"):
		_report()
		return
	if not _require(_matching_actor_count() == 1,
			"early return created a duplicate actor instead of preserving the cleared one"):
		_report()
		return

	# Cross only the last quarter-second. Availability must return on the same
	# node, healed and engageable, with no second member added to the cluster.
	_director.call("_tick_respawn", BEFORE_BOUNDARY_SECONDS + 0.01)
	respawns = _director.get("_respawn_timers") as Dictionary
	members = _cluster.get("members", []) as Array
	var instance: RefCounted = _wild.get("instance") as RefCounted
	if not _require(not respawns.has(_wild), "cooldown remained armed after its full duration"):
		_report()
		return
	if not _require(_wild.visible and bool(_wild.call("is_alive"))
			and _wild.is_physics_processing(),
			"the original wild did not revive when the configured cooldown expired"):
		_report()
		return
	if not _require(instance != null and is_equal_approx(float(instance.get("hp")),
			float(instance.get("max_hp"))), "revived wild did not return at full health"):
		_report()
		return
	if not _require(_director.call("_engageable") == _wild,
			"revived wild is not available to the nearby player"):
		_report()
		return
	if not _require(_matching_actor_count() == 1 and members.size() == 1 and members[0] == _wild,
			"cooldown completion duplicated the wild actor or cluster membership"):
		_report()
		return

	_receipt = {
		"actor": str(_wild.name),
		"actor_instance_id": _wild.get_instance_id(),
		"cluster_members": members.size(),
		"configured_cooldown_seconds": configured,
		"early_return_seconds_before_expiry": BEFORE_BOUNDARY_SECONDS,
		"physical_engage_distance_m": physical_engage_distance,
		"approach_seat": _approach_seat,
		"fight_frames": int(fight.get("frames", -1)),
		"final_available": _director.call("_engageable") == _wild,
	}
	_report()


func _find_target() -> Node3D:
	if _director == null:
		return null
	for candidate: Variant in _director.get("_wild_creatures"):
		var body := candidate as Node3D
		if body != null and body.name == TARGET_NAME:
			return body
	return null


func _matching_actor_count() -> int:
	var count := 0
	for candidate: Variant in _director.get("_wild_creatures"):
		var body := candidate as Node3D
		if body != null and is_instance_valid(body) and body.name == TARGET_NAME:
			count += 1
	return count


func _place_player_near(point: Vector3, distance: float) -> void:
	var at := point + Vector3(distance, 0.0, 0.0)
	at.y = float(_world.call("ground_height_at", at.x, at.z)) + 1.0
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


func _stage_published_engage() -> bool:
	# One staging ray can happen to land beside a closer Gather provider. Probe a
	# compact set of ordinary player seats instead of mutating either provider.
	# Inner rings come first to leave a durable distance margin for the peaceful
	# wild while staying outside its body; the outer rings cover uneven ground.
	Input.action_release("move_forward")
	_approach_winners.clear()
	_approach_seat.clear()
	for raw_radius: Variant in APPROACH_SEAT_RADII:
		var radius := float(raw_radius)
		for seat_index in APPROACH_SEATS_PER_RING:
			if not is_instance_valid(_wild) or not bool(_wild.call("is_alive")):
				return false
			var angle := TAU * float(seat_index) / float(APPROACH_SEATS_PER_RING)
			var subject := _wild.global_position
			var at := subject + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
			at.y = float(_world.call("ground_height_at", at.x, at.z)) + 1.0
			_player.global_position = at
			_player.velocity = Vector3.ZERO
			_player.reset_physics_interpolation()
			_director.call("_tick_streaming")
			var to_subject := _wild.global_position - _player.global_position
			to_subject.y = 0.0
			_rig.set("yaw", atan2(-to_subject.x, -to_subject.z))
			for _frame in APPROACH_SETTLE_FRAMES:
				await process_frame
				_record_approach_winner()
				if _is_exact_published_offer():
					_approach_seat = {
						"radius_m": radius,
						"index": seat_index,
						"angle_degrees": rad_to_deg(angle),
					}
					return true
	return false


func _is_exact_published_offer() -> bool:
	var offer := _arbiter.call("winner") as Dictionary
	var expected := "Engage %s" % str(_wild.get("display_name"))
	return _director.call("_engageable") == _wild \
		and _arbiter.call("winning_provider") == _director \
		and str(offer.get("label", "")) == expected \
		and bool(offer.get("actionable", false))


func _record_approach_winner() -> void:
	var winner := _arbiter.call("winning_provider") as Node
	var winner_name := str(winner.name) if winner != null else "<none>"
	var key := "%s | %s" % [winner_name, str(_arbiter.call("prompt"))]
	_approach_winners[key] = int(_approach_winners.get(key, 0)) + 1


func _press_interact() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for _frame in 40:
		if bool(_manager.call("is_fighting")):
			return
		await physics_frame


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_back")
	Input.action_release("interact")
	print("")
	if _failures.is_empty():
		print("meadows wild respawn cooldown receipt: " + JSON.stringify(_receipt))
		print("meadows wild respawn cooldown: OK -- a real cleared cluster stayed absent across streaming and the first 299.75s, then the same single actor returned at 300s.")
		quit(0)
		return
	for failure in _failures:
		print("meadows wild respawn cooldown FAIL: " + failure)
	quit(1)
