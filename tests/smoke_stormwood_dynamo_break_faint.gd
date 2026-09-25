extends SceneTree

## BOSSES §4.7: "A full-party faint restores everyone at Ember Bivouac and
## resets only the Break attempt." The real Dynamo controller and rules run
## with stub session/hub/arena; the fight and the recovery teleport are not
## played here.
##
## The last section takes the faint through a more real path: the real
## `encounter_director.gd` script (its `ally_body()`, `ally_instance()` and
## `deployed_body_for()`), a real `follower_creature.gd` body in the
## `deployed_creature` group, a real creature instance knocked out through the
## Dynamo's own discharge handler, and the real field control. Still stubbed
## there: the session (offline, fixed peers), the hub transport (records
## events; `body_for` answers from the real director), the combat manager
## (never fighting), the arena, camera, interaction arbiter and player rig.
## The director is attached without its `_ready()` (no spawner, no wild
## population, no process tick), so its ally is assigned directly rather than
## summoned, and the recovery teleport is not applied.
const CONTROLLER := preload("res://scripts/world/stormwood_dynamo.gd")
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const FIELD_CONTROL := preload("res://scripts/world/stormwood_dynamo_field_control.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")

var failures: Array[String] = []
var assertions := 0


class RegistryStub extends RefCounted:
	func row(peer: int) -> Dictionary:
		return {"character_id": "character-%d" % peer}


class SessionStub extends Node:
	var present := {}
	var _registry := RegistryStub.new()

	func registry() -> RefCounted:
		return _registry

	func is_host() -> bool:
		return true

	func is_active() -> bool:
		return false

	func local_peer_id() -> int:
		return 1

	func realm_of(peer: int) -> String:
		return "stormwood" if present.has(peer) else ""

	func peers_in_realm(_realm: String) -> Array:
		return present.keys()


class HubStub extends Node:
	var sent: Array = []
	var bodies := {}
	## The host's card per peer, as `encounter_director._creature_card_for()`.
	var cards := {}
	## Trainer (human actor) bodies per peer, as `actor_for()`.
	var actors := {}
	## When set, `body_for` answers from the real director, as the real hub does.
	var director: Node = null

	func send_to(peer: int, event: Dictionary) -> void:
		sent.append({"peer": peer, "kind": str(event.get("kind", ""))})

	func body_for(peer: int) -> Node3D:
		if bodies.has(peer) or director == null:
			return bodies.get(peer, null)
		return director.call("deployed_body_for", peer)

	func card_for(peer: int) -> Dictionary:
		return cards.get(peer, {})

	func actor_for(peer: int) -> Node3D:
		return actors.get(peer, null)

	func recoveries() -> int:
		return sent.filter(func(row: Dictionary) -> bool: return row.kind == "dynamo_recovery").size()

	func recoveries_for(peer: int) -> int:
		return sent.filter(func(row: Dictionary) -> bool:
			return row.kind == "dynamo_recovery" and int(row.peer) == peer).size()


class FixtureWorld extends Node3D:
	var simulation_only := false


class ManagerStub extends Node:
	func is_fighting() -> bool:
		return false


class PlayerStub extends CharacterBody3D:
	var locomotion := true

	func set_locomotion_enabled(enabled: bool) -> void:
		locomotion = enabled


class CameraStub extends Node3D:
	func set_target(_target: Node3D, _options: Dictionary) -> void:
		pass

	func planar_basis() -> Basis:
		return Basis.IDENTITY


class ArbiterStub extends Node:
	func set_player(_body: Node3D) -> void:
		pass

	func enabled() -> bool:
		return true


class ArenaStub extends Node3D:
	func show_state(_state: Dictionary) -> void:
		pass


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var session := SessionStub.new()
	var hub := HubStub.new()
	var arena := ArenaStub.new()
	root.add_child(session)
	root.add_child(hub)
	root.add_child(arena)
	var controller := CONTROLLER.new()
	controller.session = session
	controller.hub = hub
	controller.arena = arena
	controller.rules = RULES.new()
	controller.rules.update_team(0, 5)
	controller.phase = "break_core"
	controller.participants = [2]
	controller.contributors = [2]
	controller.fighter_characters = ["character-2"]
	root.add_child(controller)
	_check(controller.rules.strike_conduit(0, controller.rules.bank_position(0), true), "one conduit struck before the wipe")

	# The only fighter faints out of the realm: a full-party loss during Break.
	for _i in 5:
		await process_frame
	_check(hub.recoveries() == 1, "the party is sent to Ember Bivouac exactly once, not every frame")
	_check(controller.rules.phase == "break_core", "the captain win stands: Break, not a fresh captain fight")
	_check(controller.rules.conduits.is_empty(), "the partial conduit set clears")
	_check(controller.contributors == [2], "the captain win's contributors are kept for the release")
	_check(controller.fighter_characters == ["character-2"], "the fainted fighter keeps their Stormheart offer")
	var frozen: float = controller.rules.window_left()
	for _i in 5:
		await process_frame
	_check(is_equal_approx(controller.rules.window_left(), frozen) and is_equal_approx(frozen, 30.0),
		"Break waits with a fresh 30 s window while nobody is there")

	# Reloading a waiting Break neither replays the wipe nor loses the wait.
	var saved: Dictionary = controller.save_payload()
	var reloaded := CONTROLLER.new()
	reloaded.rules = RULES.new()
	reloaded.load_payload(saved.duplicate(true))
	_check(reloaded.get("_awaiting_break_party") == true and reloaded.participants.is_empty()
		and reloaded.rules.phase == "break_core", "a reload keeps Break waiting with no stale fighters")
	reloaded.free()

	# A fighter climbs back: their creature reaches the arena edge, where the
	# field control takes it over short of Marrow's prompt, and joins Break.
	session.present[2] = true
	var body := Node3D.new()
	root.add_child(body)
	hub.bodies[2] = body
	hub.cards[2] = {"hp": 40.0, "max_hp": 40.0}
	body.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M + 20.0)
	for _i in 3:
		await process_frame
	_check(controller.participants.is_empty(), "a creature still outside the arena does not join")
	body.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M - 2.0)
	for _i in 3:
		await process_frame
	_check(controller.participants == [2], "the returning fighter's creature at the arena edge rejoins Break")
	_check(controller.rules.window_left() < 30.0, "the window runs again once someone is there")
	_check(hub.recoveries() == 1, "no further recovery after rejoining")

	# A bystander who never fought the captain team: a join from far away is
	# refused; once their creature is in the arena they strike conduits but do
	# not enter the captain win's reward ledger.
	session.present[3] = true
	var bystander := Node3D.new()
	root.add_child(bystander)
	hub.bodies[3] = bystander
	hub.cards[3] = {"hp": 40.0, "max_hp": 40.0}
	bystander.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M + 30.0)
	controller.dispatch(3, {"kind": "dynamo_join"})
	await process_frame
	_check(not controller.participants.has(3), "a dynamo_join from outside the arena is refused")
	bystander.global_position = controller.global_position + Vector3(10, 0, 0)
	controller.dispatch(3, {"kind": "dynamo_join"})
	for _i in 2:
		await process_frame
	_check(controller.participants.has(3) and not controller.contributors.has(3),
		"a Break arrival strikes conduits but earns no captain-win reward")
	_check(controller.fighter_characters == ["character-2"],
		"a Break arrival is an observer: no Stormheart offer from proximity alone")
	for bank in 4:
		controller.rules.strike_conduit(bank, controller.rules.bank_position(bank), true)
	_check(controller.rules.phase == "released", "the restarted Break can still release the Stormheart")
	controller.set_process(false)
	root.remove_child(controller)
	controller.free()

	# A save taken mid-Break reloads with fighter ids from the old session:
	# they are dropped quietly and Break waits; nobody is thrown back.
	var stale := CONTROLLER.new()
	stale.session = session
	stale.hub = hub
	stale.arena = arena
	stale.rules = RULES.new()
	var mid := RULES.new()
	mid.update_team(0, 5)
	mid.strike_conduit(1, mid.bank_position(1), true)
	stale.load_payload({"rules": mid.save_data(), "participants": [9], "contributors": [9]})
	stale.phase = "break_core"
	hub.bodies.erase(2)
	hub.bodies.erase(3)
	var before := hub.recoveries()
	root.add_child(stale)
	for _i in 5:
		await process_frame
	_check(hub.recoveries() == before and stale.rules.conduits == [1] and stale.participants.is_empty()
		and stale.get("_awaiting_break_party") == true,
		"a reloaded Break with stale fighter ids waits without a recovery or a reset")
	stale.set_process(false)
	root.remove_child(stale)
	stale.free()
	hub.queue_free()
	await _real_faint_path(session)
	_finish()


## A hidden body, a fainted creature and a live one, then a full-party faint
## through the real director, follower body, creature instance and field control.
func _real_faint_path(session: SessionStub) -> void:
	session.present.clear()
	session.present[1] = true
	var world := FixtureWorld.new()
	world.name = "DynamoFaintFixture"
	root.add_child(world)
	var manager := ManagerStub.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	var player := PlayerStub.new()
	player.name = "Player"
	world.add_child(player)
	var camera := CameraStub.new()
	camera.name = "CameraRig"
	world.add_child(camera)
	var arbiter := ArbiterStub.new()
	arbiter.name = "InteractionArbiter"
	world.add_child(arbiter)
	# The real director script, attached after entering the tree so its
	# `_ready()` (spawner, wild population) never runs.
	var director := Node.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	director.set_script(DIRECTOR)
	director.set_process(false)
	director.set_physics_process(false)
	var hub := HubStub.new()
	hub.name = "StormwoodEncounterHub"
	hub.director = director
	world.add_child(hub)
	var arena := ArenaStub.new()
	world.add_child(arena)
	# The ally exactly as `_spawn_ally_body()` builds it: the creature scene
	# wearing the follower script, owned by the local peer.
	var ally := CREATURE_SCENE.instantiate() as CharacterBody3D
	ally.set_script(FOLLOWER)
	ally.name = "AllyCreature"
	world.add_child(ally)
	ally.call("setup", "fulgocobra", false)
	ally.set("owner_peer_id", 1)
	var creature: RefCounted = TRAINER_NPC.creature_for({"species": "fulgocobra", "level": 20})
	director.set("_ally_body", ally)
	director.set("_ally", creature)
	_check(director.call("deployed_body_for", 1) == ally and director.call("ally_instance") == creature,
		"the real director resolves the local peer's deployed follower and its creature")
	_check(ally.get("instance") == null,
		"a follower body carries no creature instance of its own; the director's ally is it")

	var controller := CONTROLLER.new()
	controller.name = "StormwoodDynamo"
	controller.world = world
	controller.session = session
	controller.hub = hub
	controller.arena = arena
	controller.rules = RULES.new()
	controller.rules.update_team(0, 5)
	controller.phase = "break_core"
	world.add_child(controller)
	controller.set_process(false)
	ally.global_position = controller.global_position + Vector3(6, 0, 0)

	# Item: the Break admits only a visible body whose creature has not fainted.
	_check(controller.call("_in_break_reach", 1), "a visible, conscious ally in the arena is in the Break")
	ally.visible = false
	_check(not controller.call("_in_break_reach", 1), "a hidden ally body is refused")
	ally.visible = true
	creature.set("fainted", true)
	_check(not controller.call("_in_break_reach", 1), "an ally whose creature has fainted is refused")
	creature.set("fainted", false)
	session.present[4] = true
	var remote := Node3D.new()
	world.add_child(remote)
	remote.global_position = controller.global_position + Vector3(0, 0, 8)
	hub.bodies[4] = remote
	hub.cards[4] = {"hp": 0.0, "max_hp": 40.0}
	controller.dispatch(4, {"kind": "dynamo_join"})
	_check(not controller.participants.has(4), "another peer whose creature card has no hit points is refused")
	hub.cards[4] = {"hp": 25.0, "max_hp": 40.0}
	remote.visible = false
	controller.dispatch(4, {"kind": "dynamo_join"})
	_check(not controller.participants.has(4), "another peer's hidden body is refused")
	remote.visible = true
	controller.dispatch(4, {"kind": "dynamo_join"})
	_check(controller.participants == [4], "another peer's visible, conscious creature joins")
	controller.participants.clear()
	hub.bodies.erase(4)
	session.present.erase(4)

	# The real field control pilots only that same live ally.
	var control := FIELD_CONTROL.new()
	control.name = "FieldControl"
	controller.add_child(control)
	control.mount(world, controller)
	await process_frame
	await process_frame
	_check(control.get("_body") == ally and not player.locomotion,
		"the field control takes over the live ally inside the arena")

	# A fighter with the captain win behind them, one observer standing in the
	# arena and one Stormwood peer far away.
	controller.participants = [1]
	controller.contributors = [1]
	controller.fighter_characters = ["character-1"]
	for peer: int in [5, 6]:
		session.present[peer] = true
		var actor := Node3D.new()
		world.add_child(actor)
		hub.actors[peer] = actor
	(hub.actors[5] as Node3D).global_position = controller.global_position + Vector3(20, 0, 0)
	(hub.actors[6] as Node3D).global_position = controller.global_position + Vector3(400, 0, 0)
	controller.set_process(true)
	_check(controller.rules.strike_conduit(0, controller.rules.bank_position(0), true), "one conduit struck before the faint")
	await process_frame
	_check(controller.participants == [1] and hub.recoveries() == 0, "a live fighter keeps the Break running")

	# A discharge knocks the ally out through the Dynamo's own hazard handler.
	controller.receive({"kind": "dynamo_hazard_hit", "damage": 100000.0, "static_seconds": 1.0})
	_check(bool(creature.get("fainted")), "the discharge faints the real creature instance")
	for _i in 4:
		await process_frame
	_check(control.get("_body") == null and player.locomotion, "the field control releases a fainted ally")
	_check(hub.recoveries_for(1) == 1, "the full-party faint sends the fighter back to Ember Bivouac once")
	_check(hub.recoveries_for(5) == 1, "an observer standing in the arena is restored too")
	_check(hub.recoveries_for(6) == 0, "a Stormwood peer far from the arena is not moved")
	_check(controller.rules.phase == "break_core" and controller.rules.conduits.is_empty(),
		"only the Break restarts: the captain win stands and the partial conduits clear")
	_check(controller.contributors == [1] and controller.fighter_characters == ["character-1"],
		"the fainted fighter keeps the captain win and their Stormheart offer")
	var waited := 0.0
	while ally.visible and waited < CONTROLLER.FAINT_HIDE_S + 1.0:
		await process_frame
		waited += 1.0 / 60.0
		await create_timer(1.0 / 60.0).timeout
	_check(not ally.visible, "the fainted follower leaves the field, as a fight hides a fainted ally")
	for _i in 3:
		await process_frame
	_check(hub.recoveries_for(1) == 1 and controller.participants.is_empty(),
		"the waiting Break does not throw anyone back twice")
	controller.set_process(false)
	world.queue_free()
	await process_frame


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("FAIL: " + failure)
	print("STORMWOOD DYNAMO BREAK FAINT %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
