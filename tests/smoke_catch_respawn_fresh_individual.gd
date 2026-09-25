extends SceneTree

## Catch-respawn regression (Meadows core, F02). A caught wild's spawn POINT
## refills after the ordinary cooldown -- but the refill must be a NEW wild
## individual. Before the fix the respawning body kept the very
## CreatureInstance the player had just caught, so `revive_at_home()` healed
## the party member to full HP for free (a heal nobody paid for) and the body
## walked back into the meadow as the SAME individual (same uid, IVs, traits),
## a second copy of an owned creature that could be caught again.
##
## Production world, production engage: boots the Meadows, adopts the ordinary
## starter, stages the exact published engage offer and presses interact like
## the respawn-cooldown smoke. Only the fight's RESULT is chosen through the
## manager's `_begin_resolve("caught")` seam (the same seam other smokes use for
## "won"); the catch hand-off (`caught_instance` -> `_resolve_catch` ->
## Party.add), the respawn timer and `_tick_respawn` -> `revive_at_home()` are
## all the real code. The real throw minigame is covered by
## `smoke_party_count_after_catches.gd`, which catches a respawning Bramblebun
## three times. The host-authoritative shared-fight branch
## (`_finalize_shared_host_fight`) calls the same refill and is not driven here.
##
##   godot --headless --path . --script tests/smoke_catch_respawn_fresh_individual.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

const TARGET_NAME := &"Wild_bramblebun_1018_1"
const SPAWN_WAIT_FRAMES := 900
const EXIT_WAIT_FRAMES := 900
const APPROACH_SEAT_RADII := [2.4, 3.2, 4.0, 4.8, 5.5]
const APPROACH_SEATS_PER_RING := 16
const APPROACH_SETTLE_FRAMES := 3
## A player waits for a wandering creature to step away from a tree before
## walking up to it: while the creature stands against the trunk, the tree's
## own Chop prompt is genuinely nearer from every seat (batch-7 CI: Chop point
## 0.99 m from the player, the creature 3.23 m). Approach only once at least
## one approach seat would put the creature's body nearer than every other
## interaction prompt by SEAT_MARGIN_M, bounded by CLEAR_WAIT_FRAMES; the
## engage assertion itself is unchanged.
const SEAT_MARGIN_M := 0.5
const CLEAR_WAIT_FRAMES := 3600
## Clearance is re-checked every this many physics frames.
const CLEAR_CHECK_EVERY := 10
## Only prompts this close to the creature's home can compete at any seat
## (wander radius + the outer seat ring + margin); gathered once, not per frame.
const COMPETITOR_REACH_M := 18.0
const APPROACH_ATTEMPTS := 3
const DIRECTOR_SCRIPT := preload("res://scripts/combat/encounter_director.gd")
## A caught creature's HP when the respawn fires. Anything below max shows a
## free heal; 1.0 makes the failure message unambiguous.
const WOUNDED_HP := 1.0

var _world: Node3D = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _arbiter: Node = null
var _wild: Node3D = null
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
	if not _require(str((_director.get("_once_only") as Dictionary).get(_wild, "")).is_empty(),
			"%s must be an ordinary respawning wild, not a once-only named individual" % TARGET_NAME):
		_report()
		return

	if _director.call("ally_instance") == null:
		if not await _director.call("adopt_starter", "terrapup"):
			_fail("production EncounterDirector could not adopt the ordinary Meadows starter")
			_report()
			return
	for _frame in 30:
		await physics_frame
	var game := root.get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") as RefCounted if game != null else null
	if not _require(party != null, "no production Party to receive the catch"):
		_report()
		return
	var party_before := (party.call("members") as Array).size()

	# The creature keeps wandering while seats are tried, so a clear moment can
	# pass before staging finds it: wait-and-stage up to APPROACH_ATTEMPTS times.
	var staged := false
	for attempt in APPROACH_ATTEMPTS:
		var clear := await _wait_until_target_clear()
		if not _require(bool(clear.get("clear", false)),
				"%s never offered an approach seat where it beats every other prompt by %.1f m within %d frames (%s)" % [
					TARGET_NAME, SEAT_MARGIN_M, CLEAR_WAIT_FRAMES, str(clear)]):
			_report()
			return
		_clear_wait["attempt"] = attempt + 1
		if await _stage_published_engage():
			staged = true
			break
	if not staged:
		_fail("bounded production approaches never published the exact target's " \
			+ "actionable engage offer (observed_winners=%s, first_loss=%s)" % [
				JSON.stringify(_approach_winners), str(_approach_geometry)])
		_report()
		return
	var wild_instance_before: RefCounted = _wild.get("instance") as RefCounted
	await _press_interact()
	if not _require(bool(_manager.call("is_fighting")) and _director.get("_engaged_with") == _wild,
			"physical interact did not enter production combat with %s" % TARGET_NAME):
		_report()
		return

	_manager.call("_begin_resolve", "caught")
	for _frame in EXIT_WAIT_FRAMES:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if not _require(not bool(_manager.call("is_fighting")),
			"combat never exited after the caught result"):
		_report()
		return

	var caught: RefCounted = wild_instance_before
	var members: Array = party.call("members") as Array
	var copies := 0
	for member: Variant in members:
		if member == caught:
			copies += 1
	if not _require(copies == 1 and members.size() == party_before + 1,
			"the catch did not reach the party exactly once (copies=%d, party %d -> %d)" % [
				copies, party_before, members.size()]):
		_report()
		return
	var caught_uid := str(caught.get("uid"))
	var caught_species := str(caught.get("species_id"))
	var caught_level := int(caught.get("level"))

	# Before its respawn fires, the hidden body must already stop referencing
	# the party's creature: anything that touches the body's instance (a
	# revive, a streaming reset, a heal) would otherwise touch the party.
	if not _require(_wild.get("instance") != caught,
			"the caught creature is still the wild body's instance after the catch " \
			+ "(party member and respawning wild share one CreatureInstance, uid %s)" % caught_uid):
		_report()
		return

	# Wound the party member, then let the ordinary respawn run to completion.
	caught.set("hp", WOUNDED_HP)
	_director.set_process(false)
	var respawns: Dictionary = _director.get("_respawn_timers") as Dictionary
	if not _require(respawns.has(_wild), "catching an ordinary wild did not arm its respawn"):
		_report()
		return
	var delay := float(respawns[_wild])
	_director.call("_tick_respawn", delay + 0.01)

	if not _require(is_equal_approx(float(caught.get("hp")), WOUNDED_HP),
			"the wild's respawn healed the party's caught creature (hp %.1f -> %.1f)" % [
				WOUNDED_HP, float(caught.get("hp"))]):
		_report()
		return
	var fresh: RefCounted = _wild.get("instance") as RefCounted
	if not _require(fresh != null and fresh != caught and str(fresh.get("uid")) != caught_uid,
			"the spawn point refilled with the caught individual itself (uid %s)" % caught_uid):
		_report()
		return
	if not _require(_wild.visible and bool(_wild.call("is_alive"))
			and is_equal_approx(float(fresh.get("hp")), float(fresh.get("max_hp"))),
			"the refilled wild did not return visible, alive and at full health"):
		_report()
		return
	if not _require(str(fresh.get("species_id")) == caught_species
			and int(fresh.get("level")) == caught_level,
			"the refilled wild changed species or level (%s L%d -> %s L%d)" % [
				caught_species, caught_level, str(fresh.get("species_id")), int(fresh.get("level"))]):
		_report()
		return
	members = party.call("members") as Array
	for member: Variant in members:
		if member == fresh:
			_fail("the refilled wild is also a party member")
			_report()
			return

	_receipt = {
		"actor": str(_wild.name),
		"caught_uid": caught_uid,
		"refilled_uid": str(fresh.get("uid")),
		"species": caught_species,
		"level": caught_level,
		"caught_hp_after_respawn": float(caught.get("hp")),
		"party_size": members.size(),
		"respawn_delay_s": delay,
		"approach_seat": _approach_seat,
		"clear_wait": _clear_wait,
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


func _place_player_near(point: Vector3, distance: float) -> void:
	var at := point + Vector3(distance, 0.0, 0.0)
	at.y = float(_world.call("ground_height_at", at.x, at.z)) + 1.0
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Wait, as a player would, until some approach seat would put the wandering
## target's engage offer ahead of every other prompt the arbiter could rank
## there. Modelled the way the arbiter ranks offers: the engage offer's own
## distance (`EncounterDirector.engage_offer_distance`, from the seat at
## ground + 1 m, as staging stands the player); every other provider only if
## it is enabled, has a label and has the seat within its `radius`, measured
## in 3D; a positive-priority provider in range wins that seat outright, and
## negative-priority ones (companion recall/ride) never outrank engage.
## Competitors are gathered once around the creature's home; the check runs
## every CLEAR_CHECK_EVERY frames. Returns {clear, frames, margin_m, seat}.
func _wait_until_target_clear() -> Dictionary:
	var home: Vector3 = _wild.get("home") if _wild.get("home") is Vector3 else _wild.global_position
	var competitors: Array[Node3D] = []
	for provider: Variant in (_arbiter.get("_provider_set") as Dictionary).keys():
		var node := provider as Node3D
		if node == null or not is_instance_valid(node) or node == _director or not node.is_inside_tree():
			continue
		var flat := node.global_position - home
		flat.y = 0.0
		if flat.length() <= COMPETITOR_REACH_M:
			competitors.append(node)
	var radius := float(_wild.call("body_radius")) if _wild.has_method("body_radius") else 0.0
	var best_margin := -INF
	var best_seat: Dictionary = {}
	for frame in range(0, CLEAR_WAIT_FRAMES, CLEAR_CHECK_EVERY):
		best_margin = -INF
		best_seat = {}
		for raw_radius: Variant in APPROACH_SEAT_RADII:
			for seat_index in APPROACH_SEATS_PER_RING:
				var angle := TAU * float(seat_index) / float(APPROACH_SEATS_PER_RING)
				var seat := _wild.global_position + Vector3(cos(angle), 0.0, sin(angle)) * float(raw_radius)
				seat.y = float(_world.call("ground_height_at", seat.x, seat.z)) + 1.0
				var engage := float(DIRECTOR_SCRIPT.engage_offer_distance(seat, _wild.global_position, radius))
				var margin := _seat_margin(seat, engage, competitors)
				if margin > best_margin:
					best_margin = margin
					best_seat = {"radius_m": raw_radius, "index": seat_index}
		if best_margin >= SEAT_MARGIN_M:
			_clear_wait = {"clear": true, "frames": frame, "margin_m": snappedf(best_margin, 0.01), "seat": best_seat}
			return _clear_wait
		for _i in CLEAR_CHECK_EVERY:
			await physics_frame
	_clear_wait = {"clear": false, "frames": CLEAR_WAIT_FRAMES, "margin_m": snappedf(best_margin, 0.01), "seat": best_seat}
	return _clear_wait


## How far ahead the engage offer is at `seat`: nearest competing offer's
## distance minus the engage distance, or -INF if a positive-priority
## provider in range would win outright.
func _seat_margin(seat: Vector3, engage: float, competitors: Array[Node3D]) -> float:
	var nearest := INF
	for node: Node3D in competitors:
		if not is_instance_valid(node):
			continue
		if node.get("enabled") == false or str(node.get("label")) == "":
			continue
		var priority := int(node.get("priority")) if node.get("priority") != null else 0
		if priority < 0:
			continue
		var d := seat.distance_to(node.global_position)
		var reach: Variant = node.get("radius")
		if reach != null and d > float(reach):
			continue
		if priority > 0:
			return -INF
		nearest = minf(nearest, d)
	return nearest - engage


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


var _approach_geometry: Dictionary = {}
var _clear_wait: Dictionary = {}


func _record_approach_winner() -> void:
	var winner := _arbiter.call("winning_provider") as Node
	var winner_name := str(winner.name) if winner != null else "<none>"
	if winner is Node3D and winner != _director and _approach_geometry.is_empty():
		var offer := _arbiter.call("winner") as Dictionary
		_approach_geometry = {
			"player": _player.global_position, "wild": _wild.global_position,
			"wild_home": _wild.get("home"), "winner_at": (winner as Node3D).global_position,
			"winner_distance": offer.get("distance"),
			"wild_distance": _player.global_position.distance_to(_wild.global_position),
			"engageable": str(_director.call("_engageable")),
		}
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
		print("catch respawn receipt: " + JSON.stringify(_receipt))
		print("catch respawn: OK -- the caught creature stayed the party's alone, kept its wounds, and the spawn refilled with a new individual.")
		quit(0)
		return
	for failure in _failures:
		print("catch respawn FAIL: " + failure)
	quit(1)
