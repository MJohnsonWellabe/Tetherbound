extends SceneTree

## Native finalized-death lifecycle, synthetic rigs/transport, no chapter scene.
const DEATH := preload("res://scripts/world/player_death.gd")
const HUB := preload("res://scripts/world/stormwood_encounter_hub.gd")
const HOSTED := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const ENGINE := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const MANAGER := preload("res://scripts/combat/stormwood_combat_manager.gd")
const DIRECTOR := preload("res://scripts/combat/stormwood_encounter_director.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var failures: Array[String] = []
var checks := 0
const TRAINER := "synthetic_varga_lifecycle"

class Vitals extends RefCounted:
	var health := 0.0
	var max_health := 100.0
	func rest() -> void:
		health = max_health
class Rig extends CharacterBody3D:
	signal died
	var vitals := Vitals.new()
	var locomotion := false
	func set_locomotion_enabled(value: bool) -> void:
		locomotion = value
class Body extends Node3D:
	var instance: RefCounted
	var arena: Node
	var following := false
	func set_following(value: bool) -> void:
		following = value
	func set_engaged(_value: bool, _other: Node3D = null) -> void:
		pass
	func centre() -> Vector3:
		return global_position
class Realm extends Node3D:
	var simulation_only := false
class QuietDirector extends DIRECTOR:
	var starts := 0
	var awards := 0
	var observations := 0
	var accept_start := false
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _physics_process(_delta: float) -> void:
		pass
	func begin_hosted_round(_link: Node, _state: Dictionary) -> bool:
		starts += 1
		return accept_start
	func observe_hosted_state(_state: Dictionary) -> void:
		observations += 1
	func observe_hosted_event(_id: String, _event: Dictionary) -> void:
		pass
	func award_hosted_trainer(_spec: Dictionary, _peers: Array) -> void:
		awards += 1
class SessionAdapter extends Node:
	var hub: Node
	var host := true
	var delayed := false
	var messages: Array[Dictionary] = []
	var requests: Array[Dictionary] = []
	func is_host() -> bool:
		return host
	func is_active() -> bool:
		return not host
	func local_peer_id() -> int:
		return 1
	func realm_of(_peer: int) -> String:
		return "stormwood"
	func peers_in_realm(_realm: String) -> Array[int]:
		return [1, 2]
	func request_stormwood_encounter(intent: Dictionary) -> void:
		requests.append(intent.duplicate(true))
		if not delayed:
			hub.dispatch(1, intent)
	func send_stormwood_encounter(peer: int, event: Dictionary) -> void:
		messages.append({"peer": peer, "event": event.duplicate(true)})
		if peer == 1:
			hub.call("_receive", event)
class DownedAdapter extends Node:
	var accept := false
	func request_down() -> bool:
		return accept

func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, label: String) -> void:
	checks += 1
	print("FINALIZED DEATH %s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)

func _setup(gap: bool = false, multiple: bool = false) -> Dictionary:
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var creature: RefCounted = SPECIES.spawn("sparkit")
	game.get("party").call("add", creature)
	var world := Realm.new()
	root.add_child(world)
	var player := Rig.new()
	player.name = "Player"
	world.add_child(player)
	player.position = Vector3(100, 20, 100)
	var ally := Body.new()
	ally.instance = creature
	world.add_child(ally)
	var enemy := Body.new()
	enemy.instance = SPECIES.spawn("stormraven")
	world.add_child(enemy)
	var manager := MANAGER.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	manager.set_physics_process(false)
	manager.set("_party", [creature] as Array[RefCounted])
	manager.set("_player", player)
	manager.set("_ally_body", ally)
	manager.set("_wild", enemy)
	manager.set("_enemy", enemy.instance)
	manager.set("state", MANAGER.State.RESOLVING if gap else MANAGER.State.ACTIVE)
	manager.set("_outcome", "won" if gap else "")
	var director := QuietDirector.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	director.set("_manager", manager)
	director.set("_player", player)
	director.set("_ally_body", ally)
	director.set("_ally", creature)
	director.set("_hosted_trainer", TRAINER)
	manager.exited.connect(director._on_combat_exited)
	var outcomes: Array[String] = []
	manager.exited.connect(func(outcome: String) -> void: outcomes.append(outcome))
	var hub := HUB.new()
	world.add_child(hub)
	hub.world = world
	hub.director = director
	var session := SessionAdapter.new()
	world.add_child(session)
	session.hub = hub
	hub.session = session
	var fight := HOSTED.new()
	world.add_child(fight)
	fight.set_process(false)
	fight.hub = hub
	fight.authority = hub.authority
	fight.spec = {"id": TRAINER}
	fight.team = [{"species": "stormraven", "level": 39}, {"species": "stormraven", "level": 39}]
	fight.round_index = 0
	fight.participants.append(1)
	fight.contributors.append(1)
	if multiple:
		fight.participants.append(2)
		fight.contributors.append(2)
	fight.engine = ENGINE.new()
	fight.add_child(fight.engine)
	# No opponent AI/body is required for departure. HP stays in real authority.
	fight.record = hub.authority.open(1, "stormwood", "trainer", {"species_id": "stormraven", "hp": 70.0, "hp_max": 100.0})
	if multiple:
		hub.authority.join(str(fight.record.encounter_id), 2)
	if gap:
		hub.authority.set_phase(str(fight.record.encounter_id), "done")
		fight.set("_between", 2.4)
	hub.fights[TRAINER] = fight
	hub.set("_local_trainer", TRAINER)
	hub.set("_local_record", str(fight.record.encounter_id))
	manager.bind_encounter(hub, str(fight.record.encounter_id), "trainer")
	var pending: Dictionary = fight.snapshot()
	pending.trainer_id = TRAINER
	hub.set("_pending_state", pending.duplicate(true))
	hub.set_process(false)
	var death := DEATH.new()
	world.add_child(death)
	death.configure_recovery([{"id": "synthetic_camp", "position": [10, 0, 10], "requires_flag": ""}])
	death.build(world, player, Vector3(10, 0, 10))
	var downed := DownedAdapter.new()
	world.add_child(downed)
	death.set("_downed", downed)
	if death.has_signal("finalized_death"):
		death.connect("finalized_death", Callable(hub, "on_finalized_death"))
	return {"world": world, "game": game, "player": player, "ally": ally,
		"manager": manager, "director": director, "hub": hub, "session": session,
		"fight": fight, "death": death, "downed": downed, "outcomes": outcomes, "pending": pending}

func _run() -> void:
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new("user://synthetic_finalized_death_%d" % OS.get_process_id()))
	await process_frame
	if OS.get_cmdline_user_args().has("--negative-control"):
		var baseline := _setup()
		baseline.death.call("_on_died")
		_check(baseline.manager.is_fighting() and baseline.fight.participants.has(1),
			"negative control: old actual finalized-death path leaves combat ACTIVE and participant present")
		await create_timer(1.8).timeout
		_check(baseline.player.position != Vector3(100, 20, 100) and baseline.manager.is_fighting(),
			"negative control: actual respawn relocates human while combat remains active")
		baseline.world.free()
	else:
		for gap: bool in [false, true]:
			var fixture := _setup(gap)
			fixture.game.get("inventory").call("add", "wood", 3)
			fixture.death.call("_on_died")
			_check(not fixture.manager.is_fighting() and not fixture.fight.participants.has(1), "final death retires local and host combat, gap=%s" % gap)
			_check(fixture.fight.finished and fixture.director.awards == 0, "sole departure finishes unwon without awards")
			_check(fixture.outcomes == ["lost"], "even resolving won becomes one local loss")
			_check(fixture.player.position == Vector3(100, 20, 100), "combat retired synchronously before respawn movement")
			_check(fixture.ally.following, "production director releases deployed control to following")
			fixture.hub.call("_receive", fixture.pending)
			fixture.hub.call("_process", 0.0)
			_check(fixture.director.starts == 0 and (fixture.hub.get("_pending_state") as Dictionary).is_empty(), "stale participant snapshot cannot restart withdrawn fight")
			fixture.hub.call("on_finalized_death")
			_check(fixture.outcomes.size() == 1, "duplicate final-death notification is idempotent")
			await create_timer(1.8).timeout
			_check(fixture.player.position == Vector3(12, 1, 12) and fixture.player.vitals.health == 100.0, "actual camp offset and vitals recovery preserved")
			_check(fixture.game.get("party").call("size") == 1 and fixture.director.awards == 0, "party ownership and no false rewards preserved")
			_check(fixture.game.get("inventory").call("count", "wood") == 0
				and (fixture.game.get("death_satchels") as Array).size() == 1,
				"actual final death preserves inventory drop into persistent satchel")
			fixture.session.delayed = true
			fixture.hub.request_start(TRAINER)
			var fresh: Dictionary = fixture.pending.duplicate(true)
			fresh.record = fixture.hub.authority.open(1, "stormwood", "trainer", {"species_id": "stormraven", "hp": 100.0, "hp_max": 100.0})
			fixture.hub.call("_receive", fresh)
			_check(fixture.director.starts == 1, "explicit fresh challenge clears withdrawal latch")
			fixture.world.free()
		var multi := _setup(false, true)
		multi.session.delayed = true
		multi.session.host = false
		multi.death.call("_on_died")
		_check(not multi.manager.is_fighting() and multi.fight.participants.has(1), "client clears local control before delayed host request arrives")
		multi.hub.call("_receive", multi.pending)
		_check(multi.director.starts == 0, "in-flight state ignored while withdrawal awaits host")
		var request: Dictionary = multi.session.requests[0]
		request["peer_id"] = 2 # malicious target is ignored: sender1 is authoritative.
		multi.session.host = true
		multi.hub.dispatch(1, request)
		_check(multi.fight.participants == [2] and not multi.fight.finished, "host removes sender only and leaves other participant fighting")
		_check(float(multi.hub.authority.record(str(multi.fight.record.encounter_id)).opponent.hp) == 70.0 and multi.fight.round_index == 0, "surviving fight keeps HP and roster round")
		_check(multi.fight.contributors == [1, 2] and multi.director.awards == 0, "contribution policy preserved without death-triggered reward")
		_check(multi.session.messages.any(func(message: Dictionary) -> bool: return message.peer == 1 and message.event.kind == "withdrawn"), "host acknowledgement targets departing client")
		var observed_before := int(multi.director.observations)
		multi.hub.call("_receive", multi.fight.snapshot())
		_check(multi.director.observations == observed_before + 1 and not multi.manager.is_fighting(),
			"withdrawn player observes surviving participant without resuming combat")
		await create_timer(1.8).timeout
		multi.world.free()
		var admission := _setup()
		# Start request is in flight; no accepted local round or queued state yet.
		admission.manager.unbind_encounter()
		admission.manager.set("state", MANAGER.State.INACTIVE)
		admission.director.set("_hosted_trainer", "")
		admission.hub.set("_local_trainer", "")
		admission.hub.set("_local_record", "")
		admission.hub.set("_pending_state", {})
		admission.session.delayed = true
		admission.hub.request_start(TRAINER)
		admission.death.call("_on_died")
		_check(admission.session.requests.size() == 2
			and admission.session.requests[0].kind == "start"
			and admission.session.requests[1].kind == "finalized_death_withdrawal",
			"final death during delayed admission sends withdrawal after start in reliable order")
		admission.hub.call("_receive", admission.pending)
		_check(admission.director.starts == 0 and not admission.manager.is_fighting(),
			"first accepted state arriving after final death cannot begin combat")
		admission.hub.dispatch(1, admission.session.requests[1])
		_check(admission.fight.participants.is_empty() and admission.fight.finished,
			"host retires late accepted membership with self-only withdrawal")
		_check(str(admission.hub.get("_pending_challenge")).is_empty(), "withdrawal clears pending challenge identity")
		admission.hub.request_start(TRAINER)
		admission.hub.call("_receive", {"kind": "start_refused", "trainer_id": "other_trainer", "reason": "already_fighting"})
		_check(str(admission.hub.get("_pending_challenge")) == TRAINER, "unrelated refusal preserves pending challenge")
		admission.hub.call("_receive", {"kind": "start_refused", "trainer_id": TRAINER, "reason": "already_fighting"})
		_check(str(admission.hub.get("_pending_challenge")).is_empty(), "matching refusal clears pending challenge")
		admission.hub.request_start(TRAINER)
		admission.director.accept_start = true
		admission.hub.call("_receive", admission.pending)
		_check(str(admission.hub.get("_pending_challenge")).is_empty()
			and str(admission.hub.get("_local_trainer")) == TRAINER,
			"successful fresh admission clears pending challenge")
		await create_timer(1.8).timeout
		admission.world.free()
		var transient := _setup()
		transient.downed.accept = true
		transient.death.call("_on_died")
		_check(transient.manager.is_fighting() and transient.fight.participants == [1] and transient.session.requests.is_empty(), "transient downed acceptance never withdraws or resolves combat")
		transient.world.free()
	print("FINALIZED DEATH: checks=%d failures=%s" % [checks, failures])
	quit(0 if failures.is_empty() else 1)
