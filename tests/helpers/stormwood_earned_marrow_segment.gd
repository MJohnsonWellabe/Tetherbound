extends "res://tests/helpers/stormwood_earned_dynamo_segment.gd"

## One earned physical attempt: actual captain roster and conduit window.
## No legendary offer or ceremony is started by this helper.
const DYNAMO := preload("res://scripts/world/stormwood_dynamo.gd")
const CAPTAIN := "captain_marrow_dynamo_core"
## One attempt's wall-clock cap at the 1x clock. Five was too short: the
## focused smoke (tests/smoke_stormwood_marrow_press.gd) was still in round 5's
## overload phase at 300 s (round 1 alone ~65 s), before any conduit window.
const ATTEMPT_MS := 900000
## Break windows one attempt may use. BOSSES §3: a timed-out Break clears the
## partial conduits and restarts with a fresh 30 s window; a player retries.
const MAX_BREAK_WINDOWS := 3
var _attempt_started_ms := 0
const END_FLAGS := ["stormwood:marrow_defeated", "stormwood:legendary_freed",
	"realm_heart_stormwood_earned", "stormwood:long_storm_ended"]
var _rounds: Dictionary = {}
var _conduit_refusal := ""
var _waiting_bank := -1
var _fired_banks: Array[int] = []

## The nearest unstruck conduit, skipping `avoid` (the bank charging or firing
## now, whose discharge lane throws a creature back) unless it is the last.
static func next_bank(rules: RefCounted, local: Vector2, avoid := -1) -> int:
	var closest := -1
	var distance := INF
	var remaining := 0
	for index in int(rules.config.bank_count):
		if not (rules.conduits as Array).has(index):
			remaining += 1
	for index in int(rules.config.bank_count):
		if (rules.conduits as Array).has(index) or (index == avoid and remaining > 1):
			continue
		var candidate := local.distance_squared_to(rules.bank_position(index))
		if candidate < distance:
			distance = candidate
			closest = index
	return closest

## Whether a straight deck leg from `a` to `b` (Dynamo-local x/z) stays on
## solid deck: out of the 9 m core hole and out of the ascent's own band in
## the ring gap (`stormwood_dynamo.gd` DeckInfill leaves that band open).
## The sealed Waterward gate's barrier (`stormwood_world.json`
## stormwood_departure_to_water at (-100, 5501): Dynamo-local (0, 31), 3.15 m
## wide) stands 4 m in front of conduit 1; its reach is walked around.
const WATER_GATE_LOCAL := Vector2(0.0, 31.0)
const WATER_GATE_CLEAR_M := 2.6
## The Crown stair (`stormheart_tree.gd` CrownStair, 6 m wide, from (34, deck)
## rising west to (-16, deck + 24)) is too low to walk under near its foot,
## beside conduit 0; that strip is walked around.
const CROWN_STAIR_FOOT := Rect2(Vector2(26.0, -4.0), Vector2(8.3, 8.0))

static func deck_leg_clear(a: Vector2, b: Vector2) -> bool:
	var gap_from := float(DYNAMO.DECK_GAP_SEGMENTS.x) * 360.0 / 64.0
	var gap_to := float(DYNAMO.DECK_GAP_SEGMENTS.y) * 360.0 / 64.0
	# The band is fenced (stormwood_dynamo.gd GapGuard rails); keep the body's
	# steering lag well clear of the fences.
	var band_in := 26.0 - 4.0 - DYNAMO.DECK_GAP_CLEARANCE_M - 1.5
	var band_out := 26.0 + 4.0 + DYNAMO.DECK_GAP_CLEARANCE_M + 1.5
	for i in 41:
		var p := a.lerp(b, float(i) / 40.0)
		var r := p.length()
		var deg := fposmod(rad_to_deg(p.angle()), 360.0)
		if r < DYNAMO.DECK_INNER_RADIUS_M + 1.0 or p.distance_to(WATER_GATE_LOCAL) < WATER_GATE_CLEAR_M \
				or CROWN_STAIR_FOOT.has_point(p):
			return false
		if deg >= gap_from - 4.0 and deg <= gap_to + 4.0 and r > band_in and r < band_out:
			return false
	return true


## `to` when the straight leg is clear, else the shortest one-waypoint detour
## on radius 38 whose two legs are both clear (`to` if none is).
static func deck_waypoint(from: Vector2, to: Vector2) -> Vector2:
	if deck_leg_clear(from, to):
		return to
	var best := to
	var best_length := INF
	for step in 72:
		var w := Vector2.RIGHT.rotated(deg_to_rad(step * 5.0)) * 38.0
		if deck_leg_clear(from, w) and deck_leg_clear(w, to):
			var length := from.distance_to(w) + w.distance_to(to)
			if length < best_length:
				best_length = length
				best = w
	return best


## Where the piloted creature stands to strike conduit `index`: beside it,
## off its axis (the deck ring's trimesh seams lie on the bank axes).
static func strike_stand(rules: RefCounted, index: int) -> Vector2:
	var centre: Vector2 = rules.bank_position(index)
	return centre + centre.normalized().orthogonal() * 1.2


## Deck route length from `from` to `to`, through `deck_waypoint`'s detour.
static func deck_route_length(from: Vector2, to: Vector2) -> float:
	var w := deck_waypoint(from, to)
	return from.distance_to(w) + w.distance_to(to)


## One lap of the unstruck conduits: the nearest first, then round the rim in
## whichever direction makes the shorter deck route.
static func conduit_lap(rules: RefCounted, local: Vector2) -> Array[int]:
	var count := int(rules.config.bank_count)
	var first := next_bank(rules, local)
	var best: Array[int] = []
	if first < 0:
		return best
	var best_length := INF
	for direction in [1, -1]:
		var order: Array[int] = []
		var at := local
		var length := 0.0
		for step in count:
			var index := posmod(first + direction * step, count)
			if (rules.conduits as Array).has(index):
				continue
			length += deck_route_length(at, strike_stand(rules, index))
			at = strike_stand(rules, index)
			order.append(index)
		if length < best_length:
			best_length = length
			best = order
	return best


static func travel_lower_bound_seconds(rules: RefCounted, local: Vector2, speed: float) -> float:
	if speed <= 0.0:
		return INF
	var points: Array[Vector2] = []
	for index in int(rules.config.bank_count):
		if not (rules.conduits as Array).has(index):
			points.append(rules.bank_position(index))
	if points.is_empty():
		return 0.0
	var nearest := INF
	var minimum_edge := INF
	var reach := float(rules.config.conduit_reach_m)
	for first in points.size():
		nearest = minf(nearest, local.distance_to(points[first]))
		for second in range(first + 1, points.size()):
			minimum_edge = minf(minimum_edge, points[first].distance_to(points[second]))
	# Every visit path has at least n-1 edges; each is at least the closest
	# centre separation minus both acceptance radii. This intentionally ignores
	# acceleration, facing and input time, and is telemetry rather than a verdict.
	var distance := maxf(0.0, nearest - reach)
	if points.size() > 1:
		distance += float(points.size() - 1) * maxf(0.0, minimum_edge - 2.0 * reach)
	return distance / speed

func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "stormwood":
		_fail("Marrow requires the retained live earned Stormwood core scene")
		return result()
	if not _has(CORE) or not _has("stormwood:kestrel_defeated") or _has(END_FLAGS[0]):
		_fail("Marrow requires earned core/Kestrel before captain victory")
		return result()
	_player = world.get_node_or_null("Player")
	_camera = world.get_node_or_null("CameraRig")
	_manager = world.get_node_or_null("CombatManager")
	_director = world.get_node_or_null("EncounterDirector")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	var dynamo := world.get_node_or_null("StormwoodDynamo")
	var session := game.get_node_or_null("Session")
	_party_before = _roster_ids()
	if _player == null or _camera == null or _manager == null or _director == null \
			or _arbiter == null or dynamo == null or session == null or _party_before.size() != 5:
		_fail("Marrow requires actual controllers and the retained five")
		return result()
	if _manager.is_fighting() or _director.trainer_battle_active() or str(dynamo.phase) != "bank_cycle":
		_fail("Marrow entry already has combat or a persisted partial attempt")
		return result()
	_navigator = NAVIGATOR.new(tree, _player, _camera, _drive_stick)
	_manager.exited.connect(_on_combat_exited)
	session.stormwood_encounter_message.connect(_observe_marrow)
	var scale_before := Engine.time_scale
	var hz_before := Engine.physics_ticks_per_second
	await tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await tree.process_frame
	await _attempt_marrow(dynamo)
	_set_action(&"combat_quick", false)
	_drive_stick(0, 0)
	await tree.process_frame
	Engine.time_scale = scale_before
	Engine.physics_ticks_per_second = hz_before
	session.stormwood_encounter_message.disconnect(_observe_marrow)
	_manager.exited.disconnect(_on_combat_exited)
	return result()

func _attempt_marrow(dynamo: Node) -> void:
	var cast := _world.get_node("StormwoodTrainers")
	var spec: Dictionary = cast.get("authored_specs").get(CAPTAIN, {})
	var body := cast.call("body_for", CAPTAIN) as Node3D
	var prompt := body.call("prompt_node") as Node3D if body != null else null
	# The live cast's spec carries the roster as "team" (stormwood_encounter_
	# catalogue.gd); "party" is the data file's key. Run 29b reached the core
	# for the first time and failed here with the whole roster present.
	if spec.is_empty() or (spec.get("team", []) as Array).size() != 5 or body == null or prompt == null:
		_fail("actual Marrow five-creature roster/prompt absent (spec=%s team=%d body=%s prompt=%s)" % [
			str(not spec.is_empty()), (spec.get("team", []) as Array).size(), str(body != null), str(prompt != null)])
		return
	if not await _ensure_usable_ally(CAPTAIN):
		return
	if not _director.can_challenge(spec):
		_fail("earned Marrow challenge is unavailable")
		return
	if not await _activate_exact(body, prompt, Vector2(body.global_position.x,
			body.global_position.z - 2), "Captain Marrow") or not await _dialogue(CAPTAIN):
		return
	var started := Time.get_ticks_msec()
	_attempt_started_ms = started
	var next_quick := 0
	var tick := 0
	var release_tick := -1
	var conduit_cycle := -1
	var break_windows := 0
	var accepted_before := 0
	var window_left_before := INF
	var break_target := -1
	var break_active := -1
	var break_leg := Vector2.ZERO
	var lap: Array[int] = []
	var rules: RefCounted = dynamo.rules
	var control := dynamo.get_node_or_null("FieldControl")
	if control == null:
		_fail("actual Dynamo FieldControl absent")
		return
	while Time.get_ticks_msec() - started < ATTEMPT_MS:
		_drive_stick(0, 0)
		if release_tick >= 0 and tick >= release_tick:
			_set_action(&"combat_quick", false)
			release_tick = -1
		if not _conduit_refusal.is_empty():
			_fail("ordinary conduit strike refused: " + _conduit_refusal)
			return
		if _outcomes.has(CAPTAIN) and not bool(_outcomes[CAPTAIN]):
			_fail("actual Marrow roster lost; no second attempt")
			return
		var phase := str(dynamo.phase)
		if phase == "released":
			if not bool(_outcomes.get(CAPTAIN, false)) or _rounds.size() != 5 \
					or _fired_banks.size() != int(rules.config.bank_count):
				_fail("release lacks observed five-round victory and four physical conduit inputs")
				return
			var ready := true
			for flag: String in END_FLAGS:
				ready = ready and _has(flag)
			if ready:
				if _party_before != _roster_ids() or _tree.current_scene != _world:
					_fail("Marrow release changed the retained five or world")
					return
				_complete = true
				_note("EARNED actual Marrow five-round victory, four conduits and automatic Stormheart release; STOP before offer")
				return
		elif phase == "break_core":
			if not bool(_outcomes.get(CAPTAIN, false)) or _rounds.size() != 5:
				_fail("conduit phase lacks actual hosted five-round victory")
				return
			var state: Dictionary = rules.bank_state()
			if conduit_cycle < 0:
				conduit_cycle = int(state.cycle)
				_note("ENTERED first actual conduit cycle %d" % conduit_cycle)
				var phase_raw: Variant = _director.call("ally_body")
				var phase_ally := phase_raw as Node3D if is_instance_valid(phase_raw) else null
				if phase_ally != null:
					var at: Vector3 = dynamo.to_local(phase_ally.global_position)
					var speed := float(phase_ally.call("base_speed"))
					var timing: Dictionary = rules.config.phases.break_core
					var cycle_seconds := float(rules.config.bank_count) * (float(timing.charge_seconds)
						+ float(timing.fire_seconds) + float(timing.recovery_seconds))
					var remaining := cycle_seconds - fposmod(float(rules.elapsed), cycle_seconds)
					_note("CONDUIT feasibility start_world=%s local=%s base_speed=%.3f remaining_cycle_s=%.3f conservative_travel_s=%.3f ally=%s" % [
						phase_ally.global_position, at, speed, remaining,
						travel_lower_bound_seconds(rules, Vector2(at.x, at.z), speed),
						_fighter_snapshot(_director.call("ally_instance"))])
			if break_windows == 0:
				break_windows = 1
			# The rules cleared a partial set: that 30 s window timed out and a
			# fresh one began (the Break retries; the captain win stands).
			var window_now := float(rules.window_left())
			if window_now > window_left_before + 1.0:
				break_windows += 1
				_note("BREAK window %d timed out with %d/4; retrying in window %d" % [
					break_windows - 1, accepted_before, break_windows])
				_fired_banks.clear()
				_waiting_bank = -1
				lap.clear()
				if break_windows > MAX_BREAK_WINDOWS:
					_fail("four conduits not struck within %d Break windows" % MAX_BREAK_WINDOWS)
					return
			accepted_before = (rules.conduits as Array).size()
			window_left_before = window_now
			# The follower body carries no creature; the director owns it.
			var body_raw: Variant = _director.call("ally_body")
			var ally := body_raw as Node3D if is_instance_valid(body_raw) else null
			var ally_creature: RefCounted = _director.call("ally_instance")
			if not is_instance_valid(ally) or ally_creature == null or bool(ally_creature.get("fainted")):
				_fail("no surviving deployed ally for the real conduit window")
				return
			if absf(dynamo.to_local(ally.global_position).y) > 4.0:
				_fail("the piloted ally left the Dynamo deck at %s" % str(dynamo.to_local(ally.global_position)))
				return
			if tick % 120 == 0:
				var at_local: Vector3 = dynamo.to_local(ally.global_position) if ally != null else Vector3.ZERO
				_note("BREAK t=%.1fs ally_local=%s piloted=%s waiting=%d fired=%s struck=%s window_left=%.1f fighting=%s target=%d active=%d bank_state=%s leg=%s next_quick_in=%d release_tick=%d" % [
					(Time.get_ticks_msec() - started) / 1000.0, at_local, str(control.get("_body") == ally),
					_waiting_bank, str(_fired_banks), str(rules.conduits), float(rules.window_left()),
					str(_manager.is_fighting()), break_target, break_active, str(state.get("state", "")), break_leg,
					next_quick - Time.get_ticks_msec(), release_tick])
			if control.get("_body") == ally:
				var local: Vector3 = dynamo.to_local(ally.global_position)
				var active := int(state.bank) if str(state.state) != "recovery" else -1
				# One planned lap per window: a discharge costs health, a detour
				# the window (BOSSES §3's route budget).
				if lap.is_empty() or (rules.conduits as Array).has(lap[0]):
					lap = conduit_lap(rules, Vector2(local.x, local.z))
					if not lap.is_empty():
						_note("BREAK lap %s from %s" % [str(lap), Vector2(local.x, local.z)])
				var index: int = lap[0] if not lap.is_empty() else -1
				break_target = index
				break_active = active
				if _waiting_bank >= 0 and (rules.conduits as Array).has(_waiting_bank):
					_note("ACCEPTED ordinary conduit %d" % _waiting_bank)
					_waiting_bank = -1
				if index >= 0 and _waiting_bank < 0:
					# Stand beside the conduit, off its axis: the deck ring's trimesh
					# seams lie on the bank axes and snag a body walking along one.
					var bank_centre: Vector2 = rules.bank_position(index)
					var bank: Vector2 = strike_stand(rules, index)
					var toward := Vector3(bank_centre.x - local.x, 0, bank_centre.y - local.z)
					var approach := Vector3(bank.x - local.x, 0, bank.y - local.z)
					# Walk the deck around the core hole and the ascent's band.
					var leg := deck_waypoint(Vector2(local.x, local.z), bank)
					var toward_leg := Vector3(leg.x - local.x, 0, leg.y - local.z)
					break_leg = leg
					var reach := float(rules.config.conduit_reach_m)
					if leg != bank:
						_drive_toward(toward_leg)
					elif approach.length() > 0.6 and toward.length() > reach * 0.8:
						_drive_toward(approach)
					elif not DYNAMO.facing_conduit(ally.call("facing"), toward):
						_drive_toward(toward)
					elif Time.get_ticks_msec() >= next_quick and release_tick < 0:
						if _fired_banks.has(index):
							_fail("conduit progress reset inside one Break window")
							return
						_fired_banks.append(index)
						_waiting_bank = index
						_set_action(&"combat_quick", true)
						release_tick = tick + 2
						# Use the exact equipped quick move's production cooldown.
						var creature: RefCounted = ally_creature
						var moves := preload("res://scripts/creatures/move_db.gd").new()
						var profile: Dictionary = COMBAT_REACH.host_move_profile(moves, "player_quick",
							str(creature.get("move_quick")), float(ally.call("body_radius")), 1.25)
						next_quick = Time.get_ticks_msec() + ceili(1000.0 * maxf(float(profile.get("cooldown", 0)),
							float(profile.get("windup", 0.1)) + float(profile.get("recovery", 0.1))))
		else:
			if conduit_cycle >= 0:
				_fail("Dynamo reset after entering the first conduit window")
				return
			# Between rounds the fainted creature's body is freed; never cast a
			# freed instance (the Nysa loop's same guard).
			var ally_raw: Variant = _director.call("ally_body")
			var enemy_raw: Variant = _manager.call("enemy_body")
			var ally := ally_raw as Node3D if is_instance_valid(ally_raw) else null
			var enemy := enemy_raw as Node3D if is_instance_valid(enemy_raw) else null
			if _manager.is_fighting() and ally != null and enemy != null:
				var toward := enemy.global_position - ally.global_position
				toward.y = 0
				if toward.length() > float(_manager.combat_move_reach("quick")) * 0.8:
					_drive_toward(toward)
				if Time.get_ticks_msec() >= next_quick and _manager.quick_ready() and release_tick < 0:
					_set_action(&"combat_quick", true)
					release_tick = tick + 2
					next_quick = Time.get_ticks_msec() + 900
		tick += 1
		await _tree.physics_frame
	var ally_card: RefCounted = _director.call("ally_instance")
	_fail("one actual Marrow roster/conduit attempt exceeded %d s (phase=%s outcome=%s fighting=%s battle=%s rounds=%d conduits=%s ally=%s)" % [
		ATTEMPT_MS / 1000, str(dynamo.phase), str(_outcomes.get(CAPTAIN, "none")), str(_manager.is_fighting()),
		str(_director.trainer_battle_active()), _rounds.size(), str(_fired_banks),
		str(_fighter_snapshot(ally_card)) if ally_card != null else "none"])

func _drive_toward(toward: Vector3) -> void:
	var local := (_camera.call("planar_basis") as Basis).inverse() * toward.normalized()
	_drive_stick(local.x, local.z)

func _observe_marrow(event: Dictionary) -> void:
	if str(event.get("kind", "")) == "dynamo_verdict" and _waiting_bank >= 0:
		var verdict: Dictionary = event.get("verdict", {})
		if not bool(verdict.get("ok", false)):
			_conduit_refusal = str(verdict.get("reason", "unknown refusal"))
	if str(event.get("trainer_id", "")) != CAPTAIN:
		return
	if str(event.get("kind", "")) == "state" and int(event.get("total", 0)) == 5:
		var index := int(event.get("round", -1))
		if index >= 0 and index < 5 and not _rounds.has(index):
			_rounds[index] = (event.get("team_entry", {}) as Dictionary).duplicate(true)
			_note("OBSERVED Marrow round %d at %.1f s: %s" % [index + 1,
				(Time.get_ticks_msec() - _attempt_started_ms) / 1000.0, _rounds[index]])
	elif str(event.get("kind", "")) == "finished":
		_outcomes[CAPTAIN] = bool(event.get("won", false))

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "endpoint": "earned Stormheart release, before legendary offer"}
