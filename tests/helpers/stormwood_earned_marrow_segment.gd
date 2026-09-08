extends "res://tests/helpers/stormwood_earned_dynamo_segment.gd"

## One earned physical attempt: actual captain roster and conduit window.
## No legendary offer or ceremony is started by this helper.
const DYNAMO := preload("res://scripts/world/stormwood_dynamo.gd")
const CAPTAIN := "captain_marrow_dynamo_core"
const ATTEMPT_MS := 300000
const END_FLAGS := ["stormwood:marrow_defeated", "stormwood:legendary_freed",
	"realm_heart_stormwood_earned", "stormwood:long_storm_ended"]
var _rounds: Dictionary = {}
var _conduit_refusal := ""
var _waiting_bank := -1
var _fired_banks: Array[int] = []

static func next_bank(rules: RefCounted, local: Vector2) -> int:
	var closest := -1
	var distance := INF
	for index in int(rules.config.bank_count):
		if (rules.conduits as Array).has(index):
			continue
		var candidate := local.distance_squared_to(rules.bank_position(index))
		if candidate < distance:
			distance = candidate
			closest = index
	return closest

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
	if spec.is_empty() or (spec.get("party", []) as Array).size() != 5 or body == null or prompt == null:
		_fail("actual Marrow five-creature roster/prompt absent")
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
	var next_quick := 0
	var tick := 0
	var release_tick := -1
	var conduit_cycle := -1
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
				var phase_ally := _director.call("ally_body") as Node3D
				if is_instance_valid(phase_ally):
					var at: Vector3 = dynamo.to_local(phase_ally.global_position)
					var speed := float(phase_ally.call("base_speed"))
					var timing: Dictionary = rules.config.phases.break_core
					var cycle_seconds := float(rules.config.bank_count) * (float(timing.charge_seconds)
						+ float(timing.fire_seconds) + float(timing.recovery_seconds))
					var remaining := cycle_seconds - fposmod(float(rules.elapsed), cycle_seconds)
					_note("CONDUIT feasibility start_world=%s local=%s base_speed=%.3f remaining_cycle_s=%.3f conservative_travel_s=%.3f ally=%s" % [
						phase_ally.global_position, at, speed, remaining,
						travel_lower_bound_seconds(rules, Vector2(at.x, at.z), speed),
						_fighter_snapshot(phase_ally.get("instance"))])
			if int(state.cycle) != conduit_cycle:
				_fail("first actual four-conduit window expired; no additional cycle")
				return
			var ally := _director.call("ally_body") as Node3D
			if not is_instance_valid(ally) or ally.get("instance") == null \
					or bool(ally.get("instance").get("fainted")):
				_fail("no surviving deployed ally for the real conduit window")
				return
			if control.get("_body") == ally:
				var local: Vector3 = dynamo.to_local(ally.global_position)
				var index := next_bank(rules, Vector2(local.x, local.z))
				if _waiting_bank >= 0 and (rules.conduits as Array).has(_waiting_bank):
					_note("ACCEPTED ordinary conduit %d" % _waiting_bank)
					_waiting_bank = -1
				if index >= 0 and _waiting_bank < 0:
					var bank: Vector2 = rules.bank_position(index)
					var toward := Vector3(bank.x - local.x, 0, bank.y - local.z)
					var reach := float(rules.config.conduit_reach_m)
					if toward.length() > reach * 0.8 \
							or not DYNAMO.facing_conduit(ally.call("facing"), toward):
						_drive_toward(toward)
					elif Time.get_ticks_msec() >= next_quick and release_tick < 0:
						if _fired_banks.has(index):
							_fail("conduit progress reset inside the first window")
							return
						_fired_banks.append(index)
						_waiting_bank = index
						_set_action(&"combat_quick", true)
						release_tick = tick + 2
						# Use the exact equipped quick move's production cooldown.
						var creature: RefCounted = ally.get("instance")
						var moves := preload("res://scripts/creatures/move_db.gd").new()
						var profile: Dictionary = COMBAT_REACH.host_move_profile(moves, "player_quick",
							str(creature.get("move_quick")), float(ally.call("body_radius")), 1.25)
						next_quick = Time.get_ticks_msec() + ceili(1000.0 * maxf(float(profile.get("cooldown", 0)),
							float(profile.get("windup", 0.1)) + float(profile.get("recovery", 0.1))))
		else:
			if conduit_cycle >= 0:
				_fail("Dynamo reset after entering the first conduit window")
				return
			var ally := _director.call("ally_body") as Node3D
			var enemy := _manager.call("enemy_body") as Node3D
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
	_fail("one actual Marrow roster/conduit attempt exceeded five minutes")

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
			_note("OBSERVED Marrow round %d: %s" % [index + 1, _rounds[index]])
	elif str(event.get("kind", "")) == "finished":
		_outcomes[CAPTAIN] = bool(event.get("won", false))

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "endpoint": "earned Stormheart release, before legendary offer"}
