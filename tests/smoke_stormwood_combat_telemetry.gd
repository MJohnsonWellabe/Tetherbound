extends SceneTree

## SYNTHETIC isolated host-strike seam with admitted owned actor/Session data.
## No mounted campaign world, network, controller
## simulation, live AI, or roster advancement is claimed by this proof.
const TELEMETRY := preload("res://tests/helpers/stormwood_combat_telemetry.gd")
const HOSTED := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const FIGHT := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const DATA_FIXTURE := preload("res://tests/test_foundation_resources.gd")
const SAVE_FIXTURE := preload("res://tests/test_foundation_resource_save.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const CARD := preload("res://scripts/save/water_capture_codec.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
var checks := 0
var failures: Array[String] = []

class GeometryBody extends Node3D:
	var instance: RefCounted
	var radius := 1.0
	var height := 2.0
	func centre() -> Vector3:
		return global_position + Vector3.UP * height * 0.5
	func facing() -> Vector3:
		return global_transform.basis.z.normalized()
	func body_radius() -> float:
		return radius

class FixtureHub extends Node:
	var ally: Node3D
	var card: Dictionary
	var director: Node
	var session: Node
	func body_for(_peer: int) -> Node3D:
		return ally
	func card_for(_peer: int) -> Dictionary:
		return card
	func body_radius(body: Node3D) -> float:
		return body.call("body_radius")
	func body_rows() -> Array:
		return []
	func publish(_fight: Node, _event: Dictionary) -> void:
		pass
	func host_card_cooldown_multiplier(_card: Dictionary) -> float:
		return 1.0

## Only physical discovery is detached. Binding, pending-settlement checks,
## owned admission, move starts and impact publication use production methods.
class FixtureDirector extends "res://scripts/combat/encounter_director.gd":
	var fixture_body: Node3D
	var fixture_card: Dictionary
	func deployed_body_for(peer: int) -> Node3D:
		return fixture_body if peer == 1 else null
	func _creature_card_for(peer: int) -> Dictionary:
		return fixture_card if peer == 1 else {}

func _start_fixture_move(fight: Node, director: Node, owned: Dictionary,
		admitted: Dictionary, intent: Dictionary, ally: Node3D, opponent: Node3D) -> bool:
	var id := str(intent.encounter_id)
	var publication: Dictionary = director.call("_ordinary_actor_binding", id, 1, ally)
	var binding: Dictionary = director.call("_strike_actor_binding", id, 1, ally)
	if publication.is_empty() or binding.is_empty(): return false
	var actor := {"character_id": binding.character_id, "creature_uid": binding.creature_uid,
		"encounter_id": id, "generation": binding.deployment_generation, "action": intent.action}
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "quick", actor,
		admitted.redesign_character.creatures[binding.creature_uid].breakthroughs, MOVES.load_default())
	if frozen.get("ok") != true: return false
	var move := FIGHT.host_move_profile(MOVES.load_default(), "player_quick", str(owned.move_quick),
		ally.call("body_radius"), opponent.call("body_radius"), 1.0, 0.0, frozen.move)
	var verdict: Dictionary = fight.authority.authorize_move_start(intent, 1, owned, binding,
		move, FIGHT.host_wind_profile(director.fixture_card), Time.get_ticks_msec())
	if verdict.get("ok") != true: return false
	var started: Dictionary = fight.authority.move_commit(id, 1, int(intent.action))
	# Observe the authored start's arrival deadline; never backdate its clock.
	while Time.get_ticks_msec() < int(started.strike_at_ms):
		await process_frame
	return true

func _initialize() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("STORMWOOD TELEMETRY: 15-second fixture watchdog expired")
		quit(1))
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("TELEMETRY CHECK %s: %s" % ["PASS" if ok else "FAIL", message])

func _body(creature: RefCounted, at: Vector3) -> GeometryBody:
	var body := GeometryBody.new()
	body.instance = creature
	var look: Dictionary = SPECIES.placeholder(str(creature.species_id))
	body.radius = float(look.get("radius", 1.0))
	body.height = float(look.get("height", 2.0))
	root.add_child(body)
	body.position = at
	return body

func _run() -> void:
	var started := Time.get_ticks_msec()
	var authored: Dictionary = {}
	for spec: Dictionary in CATALOGUE.trainer_specs():
		if str(spec.id) == "lieutenant_varga_rodline_bridge":
			authored = spec
	var team: Array = TRAINERS.team_of(authored)
	var enemy: RefCounted = TRAINERS.creature_for(team[2])
	_check(str(enemy.species_id) == "stormraven" and int(enemy.level) == 49,
		"opponent uses the F19 Varga third member, Stormraven level 49")
	var data := DATA_FIXTURE.new()
	var game := SAVE_FIXTURE.FixtureGame.new()
	game.local = data._player()
	game.world = data._world()
	var session := SAVE_FIXTURE.FixtureSession.new()
	session.fixture = game
	game.session = session
	var creature: RefCounted = game.local.party.at(0)
	creature.set_level(44, PROGRESSION.config())
	var admitted := RECORD.portable_projection(game.local.save_data())
	var owner_authority: RefCounted = session.get("_character_authority")
	_check(owner_authority.call("bind_world", game.world.reward_delivery_namespace)
		and owner_authority.call("seed_admitted_character", admitted, DATA_FIXTURE.CHARACTER).get("ok") == true,
		"synthetic party is admitted before binding the production strike actor")
	session.get("_registry").call("add", 1, DATA_FIXTURE.CHARACTER, "Synthetic", "stormwood")
	var ally := _body(creature, Vector3.ZERO)
	# Independent immutable geometry entities deliberately distinguish the
	# rendered replica from authority; no real actor is moved by the collector.
	var opponent := _body(enemy, Vector3(0, 0, 2))
	var replica := _body(enemy, Vector3(0, 0, 3))
	var hub := FixtureHub.new()
	hub.ally = ally
	var director := FixtureDirector.new()
	hub.director = director
	hub.session = session
	hub.card = {"creature_uid": creature.uid, "hp": creature.hp, "move_quick": creature.move_quick,
		"attack": creature.effective_attack(PROGRESSION.config())}
	director.fixture_body = ally
	director.fixture_card = hub.card
	director.set("_session", session)
	director.set("_deployment_identity", {1: {"character_id": DATA_FIXTURE.CHARACTER,
		"creature_uid": creature.uid, "generation": 1}})
	var fight := HOSTED.new()
	var engine := FIGHT.new()
	# Wire only the production strike seam, outside SceneTree processing. This
	# avoids fake campaign admissions, live AI, models, and timer side effects.
	engine.set("_enemy", enemy)
	engine.set("_party", [creature] as Array[RefCounted])
	engine.set("_moves", MOVES.new())
	engine.set("state", FIGHT.State.ACTIVE)
	fight.hub = hub
	fight.spec = authored.duplicate(true)
	fight.team = team.duplicate(true)
	fight.engine = engine
	fight.opponent = opponent
	fight.round_index = 2
	fight.participants.append(1)
	fight.record = fight.authority.open(1, "stormwood", "trainer", {
		"species_id": enemy.species_id, "level": enemy.level, "hp": enemy.hp, "hp_max": enemy.max_hp,
		"card": CARD.encode(enemy), "body_generation": 3}, creature.uid, DATA_FIXTURE.CHARACTER)
	director.set("_encounter_host", fight.authority)
	var telemetry := TELEMETRY.new()
	var counts := {"controller_presses": 0, "controller_releases": 0, "direct_fixture_intents": 0}
	telemetry.capture("entry", fight, engine, ally, replica, counts)
	var intent := {"encounter_id": fight.record.encounter_id,
		"slot": "quick", "move_id": creature.move_quick, "action": 1}
	# Facing away induces an accepted miss without changing range or HP.
	ally.rotation.y = PI
	_check(await _start_fixture_move(fight, director, admitted.party[0], admitted, intent, ally, opponent),
		"geometric miss has a real owned move start at its authored arrival time")
	counts.direct_fixture_intents += 1
	var miss: Dictionary = fight.strike(1, intent)
	telemetry.capture("accepted_miss", fight, engine, ally, replica, counts)
	_check(bool(miss.get("ok", false)) and not bool(miss.get("delta", {}).get("hit", true)),
		"production host accepts a geometric miss")
	var hp_before := float(enemy.hp)
	# Preserve the existing driver's 900 ms wall cadence. No cooldown mutation.
	var next_intent_ms := Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < next_intent_ms:
		await process_frame
	ally.rotation.y = 0.0
	intent.action = 2
	_check(await _start_fixture_move(fight, director, admitted.party[0], admitted, intent, ally, opponent),
		"geometric hit has a second real owned move start after unchanged cadence")
	counts.direct_fixture_intents += 1
	var hit: Dictionary = fight.strike(1, intent)
	telemetry.capture("accepted_hit", fight, engine, ally, replica, counts)
	_check(bool(hit.get("ok", false)) and bool(hit.get("delta", {}).get("hit", false)),
		"production host accepts a geometric hit after unchanged 900 ms cadence")
	_check(float(enemy.hp) < hp_before and float(enemy.hp) > 0.0,
		"production damage reduces authored HP without ending the fight")
	_check(telemetry.impacts.size() == 2 and not bool(telemetry.impacts[0].verdict.delta.hit)
		and bool(telemetry.impacts[1].verdict.delta.hit), "miss and hit remain separate immutable impact records")
	_check(int(telemetry.impacts[1].host_now_ms) - int(telemetry.impacts[0].host_now_ms) >= 900,
		"recorded host intent times verify at least 900 ms wall cadence")
	var before: Dictionary = fight.authority.record(str(fight.record.encounter_id)).duplicate(true)
	var terminal: Dictionary = telemetry.capture("terminal_active", fight, engine, ally, replica, counts)
	_check(bool(terminal.manager.fighting) and str(terminal.record.phase) == "active",
		"terminal record retained while manager and authority are active")
	_check(terminal.replica.position != terminal.authority_body.position,
		"replica and authoritative poses are captured independently")
	_check(before == fight.authority.record(str(fight.record.encounter_id)),
		"capture leaves authoritative state unchanged")
	_check(telemetry.impacts.size() == 2 and int(terminal.input_counts.controller_presses) == 0
		and int(terminal.input_counts.direct_fixture_intents) == 2,
		"terminal sample does not duplicate impact or mislabel intents as controller presses")
	_check(int(terminal.record.opponent.level) == 49, "authority record retains authored level metadata")
	ally.instance = null
	var without_body_instance := telemetry.capture("body_without_instance", fight, engine, ally, replica)
	_check(str(without_body_instance.manager.active_creature.species_id) == "terrapup"
		and float(without_body_instance.manager.active_creature.hp) > 0.0,
		"active creature identity and HP come from manager even when body has no instance")
	var stale: Variant = Node3D.new()
	stale.free()
	_check(TELEMETRY.live_body(stale) == null, "freed raw body reference validated before typed assignment")
	opponent.free()
	var freed_authority: Dictionary = telemetry.capture(
		"freed_authority_body", fight, engine, ally, replica)
	_check(not bool(freed_authority.authority_body.valid)
		and bool(freed_authority.replica.valid)
		and bool(freed_authority.manager.fighting)
		and str(freed_authority.record.phase) == "active",
		"freed authority opponent stays invalid while other live fight telemetry is retained")
	var missing: Dictionary = telemetry.capture("missing_after_teardown", null, null, null, null)
	_check(not bool(missing.ally.valid) and not bool(missing.authority_body.valid)
		and missing.record.is_empty(), "missing fight and bodies remain observable without errors")
	var output := OS.get_environment("TETHERBOUND_TELEMETRY_OUTPUT")
	var file := FileAccess.open(output, FileAccess.WRITE)
	_check(file != null, "artifact output opened")
	if file != null:
		file.store_string(JSON.stringify({"synthetic": true, "scope": "host strike seam only",
			"checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - started,
			"rows": telemetry.rows, "impacts": telemetry.impacts}, "\t"))
		file.close()
	engine.free()
	fight.free()
	hub.free()
	director.free()
	session.free()
	game.free()
	ally.free()
	replica.free()
	print("STORMWOOD TELEMETRY: %d checks; %d failures; elapsed_ms=%d" % [checks, failures.size(), Time.get_ticks_msec() - started])
	quit(0 if failures.is_empty() else 1)
