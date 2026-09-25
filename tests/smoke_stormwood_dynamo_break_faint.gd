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
## there: the session (offline, fixed peers; a client-mode copy records the
## faint report instead of sending it), the hub transport (records events;
## `body_for` answers from the real director, cards are hand-built as the
## director's `_creature_card_for()` would), the combat manager (never
## fighting), the arena, camera, interaction arbiter and player rig.
## The director is attached without its `_ready()` (no spawner, no wild
## population, no process tick), so its first ally is assigned directly rather
## than summoned, and the recovery teleport is not applied. After the faint the
## LB prompt is read from `Game`'s world-message slot, and the send-out goes
## through the director's own code: `party_cycle` pressed through Input and read
## by `_read_creature_control_input()`, then `_sync_active_creature()` (both
## called directly, as its physics and idle ticks would) recalling the hidden
## body and summoning the next creature beside the trainer stub.
const CONTROLLER := preload("res://scripts/world/stormwood_dynamo.gd")
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const FIELD_CONTROL := preload("res://scripts/world/stormwood_dynamo_field_control.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

var failures: Array[String] = []
var assertions := 0


class RegistryStub extends RefCounted:
	func row(peer: int) -> Dictionary:
		return {"character_id": "character-%d" % peer}


class SessionStub extends Node:
	var present := {}
	var host := true
	var requests: Array = []
	var _registry := RegistryStub.new()

	func registry() -> RefCounted:
		return _registry

	func is_host() -> bool:
		return host

	func request_stormwood_encounter(intent: Dictionary) -> void:
		requests.append(intent.duplicate(true))

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
		sent.append({"peer": peer, "kind": str(event.get("kind", "")), "paused": bool(event.get("paused", false))})

	func body_for(peer: int) -> Node3D:
		if bodies.has(peer) or director == null:
			return bodies.get(peer, null)
		return director.call("deployed_body_for", peer)

	func card_for(peer: int) -> Dictionary:
		return cards.get(peer, {})

	func actor_for(peer: int) -> Node3D:
		return actors.get(peer, null)

	## Whether the last Dynamo state sent to `peer` said the Break is paused.
	func last_paused(peer: int) -> Variant:
		for i in range(sent.size() - 1, -1, -1):
			if int(sent[i].peer) == peer and str(sent[i].kind) == "dynamo_state":
				return bool(sent[i].paused)
		return null

	func recoveries() -> int:
		return sent.filter(func(row: Dictionary) -> bool: return row.kind == "dynamo_recovery").size()

	func recoveries_for(peer: int) -> int:
		return sent.filter(func(row: Dictionary) -> bool:
			return row.kind == "dynamo_recovery" and int(row.peer) == peer).size()


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


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
	await _prompt_exits(session)
	_finish()


## Review nit (batch 5): every way a faint prompt ends must end its hold on the
## Break pause. Two remote Break participants (4 and 5) with host-held cards;
## a faint is their own `dynamo_ally_fainted` report, a send-out is a new card
## (`_host_set_deployed`), a recall is the card removed (`_host_clear_deployed`)
## and a disconnect is leaving Stormwood.
func _prompt_exits(session: SessionStub) -> void:
	session.present.clear()
	session.present[4] = true
	session.present[5] = true
	var hub := HubStub.new()
	root.add_child(hub)
	var arena := ArenaStub.new()
	root.add_child(arena)
	var controller := CONTROLLER.new()
	controller.session = session
	controller.hub = hub
	controller.arena = arena
	controller.rules = RULES.new()
	controller.rules.update_team(0, 5)
	controller.phase = "break_core"
	controller.participants = [4, 5]
	controller.contributors = [4, 5]
	root.add_child(controller)
	for peer: int in [4, 5]:
		var body := Node3D.new()
		root.add_child(body)
		body.global_position = controller.global_position + Vector3(4.0 * peer, 0, 6)
		hub.bodies[peer] = body
	var send_out := func(peer: int, uid: String) -> void:
		hub.cards[peer] = {"hp": 40.0, "max_hp": 40.0, "creature_uid": uid, "move_quick": "spark"}
	var faint := func(peer: int) -> void:
		controller.dispatch(peer, {"kind": "dynamo_ally_fainted",
			"creature_uid": str((hub.cards[peer] as Dictionary).creature_uid), "party_down": false})
	send_out.call(5, "exit-5a")
	send_out.call(4, "exit-4a")
	await _ticks(3)
	_check(controller.get("_break_paused") == false, "exits: two live participants run the Break")

	# Choose a creature: the next one sent out ends the prompt and the pause.
	hub.cards.erase(5)
	faint.call(4)
	await _ticks(3)
	_check(controller.get("_break_paused") == true and hub.last_paused(4) == true,
		"exits: one fainted and one with nothing out pauses the Break")
	send_out.call(4, "exit-4b")
	_check(await _runs(controller) and hub.last_paused(4) == false,
		"exit 'choose a creature': sending one out clears the pause and the banks run")

	# Choose "none": recalling the fainted creature with nothing sent out.
	faint.call(4)
	await _ticks(3)
	_check(controller.get("_break_paused") == true, "exits: the faint pauses again")
	hub.cards.erase(4)
	_check(await _runs(controller) and hub.last_paused(4) == false,
		"exit 'none': recalling with nothing sent out clears the pause and the banks run")

	# Cancel by reload: restoring the Break state while paused ends the open
	# prompt; a participant still down after it is asked again.
	send_out.call(4, "exit-4d")
	await _ticks(2)
	faint.call(4)
	await _ticks(3)
	_check(controller.get("_break_paused") == true, "exits: paused before a reload")
	controller.restore_progression_from_game(root.get_node("Game"))
	_check(controller.get("_break_paused") == false and hub.last_paused(4) == false,
		"exit 'cancel' by reload: restoring the Break ends the open prompt's pause and publishes it")
	await _ticks(3)
	_check(controller.get("_break_paused") == true,
		"after the reload a participant still down is asked again from its restored state")

	# Timeout: COMBAT says "no timer in solo". The faint toast lapsing is not a
	# choice, so with nobody live the Break stays paused until an answer.
	var held := float(controller.rules.get("elapsed"))
	for _i in 30:
		await process_frame
		await create_timer(1.0 / 60.0).timeout
	_check(controller.get("_break_paused") == true and is_equal_approx(float(controller.rules.get("elapsed")), held),
		"exit 'timeout': half a second later nothing has expired the choice (no timer, per COMBAT)")

	# Disconnect: participant 5 faints and answers "none"; the only one still
	# choosing (4) leaves Stormwood. No stale hold may keep the Break paused.
	send_out.call(5, "exit-5b")
	await _ticks(2)
	faint.call(5)
	await _ticks(2)
	hub.cards.erase(5)
	await _ticks(2)
	_check(controller.get("_break_paused") == true and controller.participants == [4, 5],
		"exits: 4 still choosing after 5 answered none keeps the pause")
	session.present.erase(4)
	_check(await _runs(controller) and hub.last_paused(5) == false and controller.participants == [5],
		"exit 'disconnect': the last participant choosing leaves and the Break runs again")

	# Cancel by wipe: the only participant left faints and then its whole party
	# is down. The attempt is cancelled (BOSSES §4.7) and takes the pause with it.
	send_out.call(5, "exit-5c")
	await _ticks(2)
	faint.call(5)
	await _ticks(3)
	_check(controller.get("_break_paused") == true, "exits: the sole participant's faint pauses")
	var wiped := hub.recoveries_for(5)
	controller.dispatch(5, {"kind": "dynamo_ally_fainted", "creature_uid": "exit-5c", "party_down": true})
	await _ticks(3)
	_check(controller.get("_break_paused") == false and hub.last_paused(5) == false
		and hub.recoveries_for(5) == wiped + 1,
		"exit 'cancel' by wipe: a full-party faint under the prompt restarts the Break unpaused")
	controller.set_process(false)
	root.remove_child(controller)
	controller.free()
	hub.queue_free()
	arena.queue_free()


func _ticks(count: int) -> void:
	for _i in count:
		await process_frame


## True when the Break is unpaused and its clock advances over a few frames.
func _runs(controller: Node) -> bool:
	await _ticks(2)
	var before := float(controller.rules.get("elapsed"))
	for _i in 3:
		await process_frame
		await create_timer(1.0 / 60.0).timeout
	return controller.get("_break_paused") == false and float(controller.rules.get("elapsed")) > before


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

	# The host's own party, in player order: the piloted creature, one resting
	# in a camp bed (it cannot take the field) and one conscious reserve.
	var game := root.get_node("Game")
	var party: RefCounted = game.get("party")
	while int(party.call("size")) > 0:
		party.call("remove_at", 0)
	var benched: RefCounted = TRAINER_NPC.creature_for({"species": "fulgocobra", "level": 20})
	var reserve: RefCounted = TRAINER_NPC.creature_for({"species": "fulgocobra", "level": 20})
	creature.set("nickname", "Volt")
	benched.set("nickname", "Drowse")
	reserve.set("nickname", "Gale")
	party.call("add", creature)
	party.call("add", benched)
	party.call("add", reserve)
	benched.set("resting", true)
	_check(party.call("active") == creature, "the piloted creature is the party's active member")
	# The director reaches the trainer and the manager as its `_ready()` would.
	director.set("_player", player)
	director.set("_manager", manager)

	# The Break admits only a visible body whose creature has not fainted.
	_check(controller.call("_in_break_reach", 1), "a visible, conscious ally in the arena is in the Break")
	ally.visible = false
	_check(not controller.call("_in_break_reach", 1), "a hidden ally body is refused")
	ally.visible = true
	creature.set("fainted", true)
	_check(not controller.call("_in_break_reach", 1), "an ally whose creature has fainted is refused")
	creature.set("fainted", false)
	session.present[4] = true
	session.present[7] = true
	var remote := Node3D.new()
	world.add_child(remote)
	remote.global_position = controller.global_position + Vector3(0, 0, 8)
	hub.bodies[4] = remote
	hub.cards[4] = {"hp": 25.0, "max_hp": 40.0, "creature_uid": "creature-remote-4", "move_quick": "spark"}
	remote.visible = false
	controller.dispatch(4, {"kind": "dynamo_join"})
	_check(not controller.participants.has(4), "another peer's hidden body is refused")
	remote.visible = true
	controller.dispatch(4, {"kind": "dynamo_join"})
	_check(controller.participants == [4], "another peer's visible, conscious creature joins")

	# A remote creature's faint reaches the host only from its owner, through
	# the real Stormwood intent path; reporting it can only hurt the reporter.
	controller.phase = "overload"
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-remote-4", "party_down": true})
	controller.phase = "break_core"
	_check(controller.call("_in_break_reach", 4) and not controller.call("_party_out", 4),
		"a faint report outside Break is ignored")
	controller.dispatch(7, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-remote-4", "party_down": true})
	_check(controller.call("_in_break_reach", 4) and not controller.call("_party_out", 4),
		"a non-participant cannot report someone else's creature")
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-other", "party_down": false})
	_check(controller.call("_in_break_reach", 4), "a report naming a creature other than the deployed one is ignored")
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-other", "party_down": true})
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "", "party_down": true})
	_check(not controller.call("_party_out", 4),
		"a whole-party report with no matching faint of the deployed creature cannot restart the Break")
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-remote-4", "party_down": false})
	var refused: Dictionary = controller.call("_validate_conduit_strike", 4,
		{"slot": "quick", "move_id": "spark", "action": 1, "index": 0})
	_check(not controller.call("_in_break_reach", 4) and not bool(refused.get("ok", true)),
		"a reported fainted remote creature no longer joins or strikes")
	_check(not controller.call("_party_out", 4),
		"with conscious creatures left that peer stays in the Break and may send out the next")
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-remote-4", "party_down": true})
	_check(controller.call("_party_out", 4), "a reported full-party faint takes that peer out of the Break")
	controller.participants.clear()
	hub.bodies.erase(4)
	session.present.erase(4)
	session.present.erase(7)

	# Between two of Marrow's rounds (captain phase, not fighting, a trainer
	# battle running) a discharge never faints the active creature directly.
	var before_hp := float(creature.get("hp"))
	controller.phase = "overload"
	controller.receive({"kind": "dynamo_hazard_hit", "damage": 100000.0, "static_seconds": 1.0})
	_check(not bool(creature.get("fainted")) and is_equal_approx(float(creature.get("hp")), before_hp),
		"a discharge during the captain fight's send-out gap does not faint the lead")
	controller.phase = "break_core"
	director.set("_trainer_spec", {"id": CONTROLLER.TRAINER_ID})
	controller.receive({"kind": "dynamo_hazard_hit", "damage": 100000.0, "static_seconds": 1.0})
	_check(not bool(creature.get("fainted")), "no direct discharge damage while a trainer battle is active")
	director.set("_trainer_spec", {})

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

	# A discharge knocks the piloted creature out through the Dynamo's own
	# hazard handler. A conscious reserve is left: not a full-party faint.
	creature.set("rested", true)
	var happiness := float(creature.get("happiness"))
	game.call("take_pending_world_message")
	controller.receive({"kind": "dynamo_hazard_hit", "damage": 100000.0, "static_seconds": 1.0})
	_check(bool(creature.get("fainted")), "the discharge faints the real creature instance")
	var frozen_window: float = controller.rules.window_left()
	var frozen_serial := int(controller.rules.bank_state().serial)
	var frozen_elapsed := float(controller.rules.get("elapsed"))
	# COMBAT: "A faint leaves a clear LB prompt". It names the fainted creature,
	# the party_cycle button as the live bindings name it, and the creature LB
	# will send out: the next available one in player order, past the resting.
	var cycle_button := INPUT_GLYPH.action_name("party_cycle")
	var prompt := str(game.call("take_pending_world_message"))
	_check(prompt == "Volt fainted. Press %s to send out Gale." % cycle_button,
		"one clear prompt names the faint, the party_cycle button and the next available creature: " + prompt)
	_check(not bool(creature.get("rested")) and float(creature.get("happiness")) < happiness,
		"the faint is noted on the creature's condition, as a fight's faint is")
	for _i in 4:
		await process_frame
	_check(control.get("_body") == null and player.locomotion, "the field control releases a fainted ally")
	_check(controller.participants == [1] and hub.recoveries() == 0 and controller.rules.conduits == [0],
		"one fainted creature with a conscious reserve is not a full-party faint: the Break goes on")
	var waited := 0.0
	while ally.visible and waited < CONTROLLER.FAINT_HIDE_S + 1.0:
		await process_frame
		waited += 1.0 / 60.0
		await create_timer(1.0 / 60.0).timeout
	_check(not ally.visible, "the fainted follower leaves the field, as a fight hides a fainted ally")
	# COMBAT: the faint "pauses enemy attack issuance until a replacement is
	# selected ... no timer in solo". Over a second of frames the banks and the
	# conduit window have not moved, and every peer was told.
	_check(controller.get("_break_paused") == true and hub.last_paused(1) == true,
		"a solo faint pauses the Break and publishes the pause")
	_check(is_equal_approx(float(controller.rules.get("elapsed")), frozen_elapsed)
		and is_equal_approx(controller.rules.window_left(), frozen_window)
		and int(controller.rules.bank_state().serial) == frozen_serial,
		"while the solo player chooses, no bank advances or fires and the conduit window holds")

	# Co-op: another participant with a live creature keeps the Break running.
	session.present[4] = true
	var partner := Node3D.new()
	world.add_child(partner)
	partner.global_position = controller.global_position + Vector3(0, 0, 10)
	hub.bodies[4] = partner
	hub.cards[4] = {"hp": 40.0, "max_hp": 40.0, "creature_uid": "creature-partner-4", "move_quick": "spark"}
	for _i in 3:
		await process_frame
	_check(controller.participants == [1, 4], "a partner with a live creature in the arena joins the Break")
	var coop_elapsed := float(controller.rules.get("elapsed"))
	for _i in 3:
		await process_frame
		await create_timer(1.0 / 60.0).timeout
	_check(controller.get("_break_paused") == false and hub.last_paused(1) == false
		and float(controller.rules.get("elapsed")) > coop_elapsed,
		"in co-op, a participant with a live creature keeps the banks and the window running")
	# The partner's creature faints too, with its party still up: both choose.
	controller.dispatch(4, {"kind": "dynamo_ally_fainted", "creature_uid": "creature-partner-4", "party_down": false})
	await process_frame
	var both_elapsed := float(controller.rules.get("elapsed"))
	for _i in 3:
		await process_frame
	_check(controller.get("_break_paused") == true and is_equal_approx(float(controller.rules.get("elapsed")), both_elapsed),
		"with every participant choosing a replacement the Break pauses again")
	# The partner disconnects mid-pause: the existing logic drops them, and the
	# host still choosing keeps it paused. A live creature outside the Break
	# (not a participant, out of reach) cannot hold or release it.
	session.present.erase(4)
	await process_frame
	await process_frame
	_check(controller.participants == [1] and controller.get("_break_paused") == true,
		"a participant who leaves while paused is dropped; the pause stays with the one still choosing")
	session.present[4] = true
	partner.global_position = controller.global_position + Vector3(0, 0, CONTROLLER.BREAK_JOIN_RADIUS_M + 30.0)
	hub.cards[4] = {"hp": 40.0, "max_hp": 40.0, "creature_uid": "creature-partner-4b", "move_quick": "spark"}
	for _i in 3:
		await process_frame
	_check(controller.participants == [1] and controller.get("_break_paused") == true
		and is_equal_approx(float(controller.rules.get("elapsed")), both_elapsed),
		"a live creature outside the Break does not count: only participants do")
	session.present.erase(4)
	hub.bodies.erase(4)
	hub.cards.erase(4)
	partner.queue_free()

	# COMBAT: "No automatic switch on faint". With the director's own sync
	# running and no button pressed, nobody is sent out and the prompt is not
	# repeated. `summon_active_creature()` is still a no-op for the hidden body:
	# LB is the way out.
	for _i in 5:
		director.call("_sync_active_creature")
		await process_frame
	_check(director.call("ally_body") == ally and director.call("ally_instance") == creature
		and party.call("active") == creature and not ally.visible,
		"no automatic switch on faint: the fainted creature stays the active one, hidden")
	_check(str(game.call("take_pending_world_message")).is_empty(), "the faint prompt is shown once, not every frame")
	_check(not bool(await director.call("summon_active_creature")),
		"summon is a no-op while the fainted body is still the deployed one")
	# The prompt is a transient toast: still paused once its re-show time is up,
	# it is shown once more, and never a third time.
	controller.set("_faint_prompt_left", 0.0)
	await process_frame
	_check(str(game.call("take_pending_world_message")) == prompt, "a still-paused Break shows the prompt once more")
	controller.set("_faint_prompt_left", 0.0)
	for _i in 3:
		await process_frame
	_check(str(game.call("take_pending_world_message")).is_empty(), "the prompt is re-shown only once")
	var paused_elapsed := float(controller.rules.get("elapsed"))

	# The player presses LB: `party_cycle` through Input, read by the director's
	# own control handler, then its own party-revision sync.
	Input.action_press("party_cycle")
	director.call("_read_creature_control_input")
	Input.action_release("party_cycle")
	_check(party.call("active") == reserve, "LB makes the next available creature active, skipping the resting one")
	_check(str(game.call("take_pending_world_message")) == "Active creature: Gale",
		"the director confirms the switch in its own words")
	director.call("_sync_active_creature")
	var next_body: Node3D = director.call("ally_body")
	_check(is_instance_valid(next_body) and next_body != ally and director.call("ally_instance") == reserve,
		"the director recalls the hidden fainted body and deploys the next creature")
	_check(ally.is_queued_for_deletion(), "the fainted follower is put away, not left in the field")
	await process_frame
	await process_frame
	_check(is_instance_valid(next_body) and next_body.visible and not bool(reserve.get("fainted"))
		and director.call("deployed_body_for", 1) == next_body,
		"the next creature stands in the field as a visible, conscious follower")
	_check(control.get("_body") == next_body and not player.locomotion,
		"the field control pilots the newly sent-out creature")
	_check(controller.call("_in_break_reach", 1) and controller.participants == [1] and hub.recoveries() == 0,
		"the sent-out creature is in the Break")
	for _i in 2:
		await process_frame
		await create_timer(1.0 / 60.0).timeout
	_check(controller.get("_break_paused") == false and hub.last_paused(1) == false
		and float(controller.rules.get("elapsed")) > paused_elapsed,
		"sending a creature out resumes the banks and the conduit window")

	# A discharge now faints the last creature able to take the field (the
	# third rests in a camp bed): no LB prompt, the full-party wipe instead.
	controller.receive({"kind": "dynamo_hazard_hit", "damage": 100000.0, "static_seconds": 1.0})
	_check(bool(reserve.get("fainted")), "the discharge faints the sent-out creature")
	_check(str(game.call("take_pending_world_message")).is_empty(),
		"with no creature left to send out there is no LB prompt")
	for _i in 4:
		await process_frame
	_check(hub.recoveries_for(1) == 1, "the full-party faint sends the fighter back to Ember Bivouac once")
	_check(controller.get("_break_paused") == false and hub.last_paused(1) == false,
		"a full-party faint is the wipe, not a pause")
	_check(hub.recoveries_for(5) == 1, "an observer standing in the arena is restored too")
	_check(hub.recoveries_for(6) == 0, "a Stormwood peer far from the arena is not moved")
	_check(controller.rules.phase == "break_core" and controller.rules.conduits.is_empty(),
		"only the Break restarts: the captain win stands and the partial conduits clear")
	_check(controller.contributors == [1] and controller.fighter_characters == ["character-1"],
		"the fainted fighter keeps the captain win and their Stormheart offer")
	for _i in 3:
		await process_frame
	_check(hub.recoveries_for(1) == 1 and controller.participants.is_empty(),
		"the waiting Break does not throw anyone back twice")

	# The recovery restores: the trainer at Ember Bivouac, every creature up,
	# and no rest XP for a wipe.
	var xp_before := [int(creature.get("xp")), int(reserve.get("xp"))]
	var level_before := [int(creature.get("level")), int(reserve.get("level"))]
	controller.receive({"kind": "dynamo_recovery"})
	_check([int(creature.get("xp")), int(reserve.get("xp"))] == xp_before
		and [int(creature.get("level")), int(reserve.get("level"))] == level_before,
		"the wipe recovery grants no XP: a deliberate wipe is not an XP loop")
	_check(not bool(creature.get("fainted")) and not bool(reserve.get("fainted"))
		and is_equal_approx(float(creature.get("hp")), float(creature.get("max_hp")))
		and is_equal_approx(float(reserve.get("hp")), float(reserve.get("max_hp"))),
		"the recovery heals and revives the whole party")
	_check(Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(-120, 5270)) < 0.01,
		"the recovery returns the trainer to Ember Bivouac")
	controller.set_process(false)

	# The owning client's side: it reports its own piloted creature's faint
	# once, and its whole party once, through the Stormwood intent.
	var client_session := SessionStub.new()
	client_session.host = false
	client_session.present[1] = true
	root.add_child(client_session)
	var client := CONTROLLER.new()
	client.name = "ClientDynamo"
	client.world = world
	client.session = client_session
	client.hub = hub
	client.arena = arena
	client.rules = RULES.new()
	client.rules.update_team(0, 5)
	client.phase = "break_core"
	client.participants = [1]
	world.add_child(client)
	var lead: RefCounted = director.call("ally_instance")
	var spare: RefCounted = creature if lead == reserve else reserve
	lead.call("take_damage", 100000.0)
	for _i in 3:
		await process_frame
	var reports: Array = client_session.requests.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "dynamo_ally_fainted")
	_check(reports.size() == 1 and str(reports[0].creature_uid) == str(lead.get("uid"))
		and reports[0].party_down == false, "the client reports its own creature's faint once, reserve still up")
	spare.call("take_damage", 100000.0)
	for _i in 3:
		await process_frame
	reports = client_session.requests.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "dynamo_ally_fainted")
	_check(reports.size() == 2 and reports[1].party_down == true, "and its whole party's faint once")
	client.set_process(false)
	client_session.queue_free()
	while int(party.call("size")) > 0:
		party.call("remove_at", 0)
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
