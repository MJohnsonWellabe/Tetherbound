extends SceneTree

## Isolated real-physics fixture, NOT production captain/combat or route proof.
## Exercises the production Interactable/arbiter on a moving CharacterBody,
## collision under wind, save restoration and recovery handoff. No owner saves.
##
## State is the `Game` autoload's own, not a detached store: the controller is
## bound to `Game.progression` (the merged view `cloudreach_world_runtime.gd`
## passes in `mount()`), a relay strike commits through `Game.ledger` (solo is
## the host) into `Game.world.flags`, the relay prompts are the ones the runtime
## installs (`_install_creature_relay_prompts`, `cloudreach_relay_interactable.gd`)
## and save/reload round-trips `Game.progression`'s save payload (the one
## `save_game.gd` writes) after a New Game reset. Disclosed shortcuts: chapter
## events go through the pure `realm_chapter_progression.gd` against that same
## store rather than a `realm_chapter_events.gd` node, the captain win is the
## injected callback, and the "creature" is a driven capsule.
##
## A second, PENDING-CLIENT leg (`_pending_client_leg`) needs this real root
## (`run_tests.gd` has none): the same controller on `Game.progression`, but its
## ledger and chapter adapter answer `pending` as a joined client's do, and each
## commit arrives through `Game.ledger.apply_remote_delta` -- the production
## client entry behind `_rpc_delta`, which applies the world delta and runs the
## `progression_restore` sweep. It proves one submit and one signal per win,
## relay, network repair and witness. Disclosed: the "host" is a stand-in that
## commits whatever was asked, and the entry flags are set directly as setup.
##
## A third, LIVE-FIGHT SWEEP leg (`_live_fight_sweep_leg`): a controller mid-
## Veyra, handed a stand-in encounter director as `mount()` hands it the real one,
## receives unrelated committed deltas through the same
## `Game.ledger.apply_remote_delta` sweep and must stay in crosswind_command and
## then anchor_overload with its hazards and clock intact. A real
## `Game.load_game()` (isolated save directory) and `Game.apply_world_snapshot()`
## must still reset it whenever the fight is over or the reloaded flags no
## longer admit it. Disclosed: the director is a stub exposing only
## `trainer_battle_active()`/`trainer_battle_id()`.
##
## A fourth, BREAK-THE-EYE PILOT leg (`_break_the_eye_pilot_leg`): the real
## `cloudreach_world_runtime.gd` `_process` hands the ally to a client in
## break_the_eye, then an unrelated delta and another peer's relay arrive
## through the same sweep. Field control, the arbiter viewer and the camera
## target stay on the ally with no set_target call at all, sampled right after
## the sweep; the wind clock, drift and a recovery guard (while its body is
## still inside the current) are kept.
## The network landing (a phase change) releases the pilot by the next
## `_process`; a real `Game.load_game()` still restarts the clock; a sweep
## during a fight leaves the combat camera alone; and a recalled (freed) ally
## hands control back to the trainer, both from `_process` and from a load.
## The runtime is added to the world BEFORE the finale, as
## `cloudreach_world.gd` and `mount()` do, so it is swept first. Disclosed: the
## runtime is not `mount()`ed; its world, camera rig, director, manager,
## atmosphere and bodies are stubs wired onto its fields, it joins
## `progression_restore` by hand as `mount()` does, and the recall is
## `dismiss_active_creature()`'s own two steps: `queue_free()` and `ally_body()`
## answering null.
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const SAVE := preload("res://scripts/save/save_game.gd")

## A joined client's view of the host: every chapter flag and relay flag
## answers `pending` and is queued; `land()` is the host committing the queue.
class PendingClientHost extends Node:
	signal intent_refused(kind: String, code: String, reason: String, detail: Dictionary)
	const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
	const SCOPES := preload("res://autoload/progression_state.gd")
	var game: Node
	var chapter: Dictionary = {}
	var events: Array[String] = []
	var submitted: Array[Dictionary] = []
	var queued: Array[String] = []
	## The production `Game.ledger` while this stand-in is swapped into its
	## place (`_director_client_leg`); null when it is not.
	var real_ledger: Node = null
	## `ledger_rpc.gd`'s delta-sweep marker, answered by the real ledger whose
	## `apply_remote_delta` this stand-in's `land()` runs.
	var sweeping_for_delta: bool:
		get:
			return real_ledger != null and real_ledger.get("sweeping_for_delta") == true

	## The same call `realm_chapter_events.gd::emit_event` makes, with a writer.
	func emit_event(event: String) -> Dictionary:
		events.append(event)
		return LOGIC.dispatch(game.get("progression"), chapter, event, Callable(self, "_write"))

	func _write(flag: String) -> Dictionary:
		return _pending(flag)

	func submit(intent: Dictionary) -> Dictionary:
		submitted.append(intent.duplicate(true))
		return _pending(str(intent.get("id", "")))

	func _pending(flag: String) -> Dictionary:
		if not queued.has(flag):
			queued.append(flag)
		return {"ok": false, "kind": "set_world_flag", "peer": 2, "code": "pending",
			"reason": "", "pending": true, "delta": {"seq": 0, "realm": "", "ops": []}}

	func land() -> void:
		var ops: Array = []
		for flag: String in queued:
			if SCOPES.scope_of(flag) == SCOPES.SCOPE_PLAYER:
				ops.append({"op": "flag", "scope": "player", "realm": "cloudreach", "id": flag,
					"value": true, "peers": [1]})
			else:
				ops.append({"op": "flag", "scope": "world", "realm": "cloudreach", "id": flag,
					"value": true})
		queued.clear()
		var transport: Node = real_ledger if real_ledger != null else game.get("ledger")
		var world_ledger: RefCounted = transport.get("ledger")
		transport.call("apply_remote_delta",
			{"seq": int(world_ledger.get("seq")) + 1, "realm": "cloudreach", "ops": ops})

	## The host refusing the queued intents: a verdict, and no delta.
	func refuse() -> void:
		queued.clear()
		intent_refused.emit("set_world_flag", "refused", "", {})

	func submits_of(flag: String) -> int:
		var count := 0
		for intent: Dictionary in submitted:
			if str(intent.get("id", "")) == flag:
				count += 1
		return count


## The real Cloudreach director with only its scene bootstrap and per-frame
## ticking skipped: both want a player, a manager and a world to spawn into.
## `_record_trainer_defeat`, the base session path, `_submit_reward_intent`
## (to `Game.ledger`), `_progression()` and `_pay_trainer_reward` are the real
## ones.
class ClientDirector extends "res://scripts/combat/cloudreach_encounter_director.gd":
	func _ready() -> void:
		# No player, manager or world to tick against: the leg drives the
		# defeat itself.
		set_process(false)
		set_physics_process(false)


## A joined client's session, as the director asks it.
class ClientSession extends Node:
	func is_active() -> bool:
		return true

	func is_host() -> bool:
		return false

	func is_multi_peer() -> bool:
		return true

	func local_peer_id() -> int:
		return 424242


## A world root answers which realm its director fights in.
class CloudreachRoot extends Node3D:
	func world_realm() -> String:
		return "cloudreach"


## The encounter director's trainer-battle surface (`encounter_director.gd`).
class FightDirector extends Node:
	var active_id := ""

	func trainer_battle_active() -> bool:
		return not active_id.is_empty()

	func trainer_battle_id() -> String:
		return active_id


## The surface `cloudreach_world_runtime.gd` drives on the trainer and the ally.
class PilotBody extends CharacterBody3D:
	var following := true
	var locomotion: Array = []

	func register_environment_velocity_modifier(_id: StringName, _owner: Object, _fn: Callable, _priority: int) -> void:
		pass

	func clear_environment_velocity_modifier(_id: StringName) -> void:
		pass

	func set_following(value: bool) -> void:
		following = value

	func request_move(_direction: Vector3) -> void:
		pass

	func set_locomotion_enabled(value: bool) -> void:
		locomotion.append(value)


class PilotDirector extends FightDirector:
	var ally: CharacterBody3D

	func ally_body() -> CharacterBody3D:
		return ally


class CombatStub extends Node:
	var fighting := false

	func is_fighting() -> bool:
		return fighting


## Records every retarget, so a one-frame flip cannot hide.
class CameraStub extends Node3D:
	var target: Node
	var calls: Array = []

	func set_target(next: Node, _profile: Dictionary = {}) -> void:
		target = next
		calls.append(next)

	func planar_basis() -> Basis:
		return Basis()


class AtmosphereStub extends Node:
	var bindings: Dictionary = {}


class DrivenBody extends CharacterBody3D:
	var finale: Node3D
	var move_enabled := true
	func _physics_process(delta: float) -> void:
		if move_enabled:
			var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			velocity.x = stick.x * 6.0
			velocity.z = stick.y * 6.0
		velocity.y -= 25.0 * delta
		if finale != null:
			finale.apply_hazards(self, delta)
		move_and_slide()

var failures: Array[String] = []
var flags: RefCounted
var chapter: Dictionary
var creature_piloted := true
var recovered := 0
var _body: DrivenBody
var _finale: Node3D
## world flag id -> how many committed `Game.ledger` deltas set it.
var _flag_commits: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _press(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)


func _event(event: String) -> Dictionary:
	return CHAPTER.dispatch(flags, chapter, event)


func _count_commits(delta: Dictionary) -> void:
	for op: Variant in (delta.get("ops", []) as Array):
		if typeof(op) != TYPE_DICTIONARY:
			continue
		var id := str((op as Dictionary).get("id", ""))
		if LEDGER_CLAIM.sets_world_flag(delta, id):
			_flag_commits[id] = int(_flag_commits.get(id, 0)) + 1


func _recover(body: CharacterBody3D, camp_id: String, at: Vector3) -> void:
	recovered += 1
	_check(camp_id == "summit_bivouac", "Recovery uses authored camp identity")
	body.global_position = at
	body.velocity = Vector3.ZERO


func _box(parent: Node, at: Vector3, size: Vector3) -> void:
	var solid := StaticBody3D.new()
	solid.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	solid.add_child(collider)
	parent.add_child(solid)


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null("Game")
	if game == null or game.get("ledger") == null:
		push_error("Game autoload with a mounted ledger is required")
		quit(1)
		return
	game.set_process(false)
	game.call("reset_for_new_game")
	flags = game.get("progression")
	var ledger: Node = game.get("ledger")
	ledger.connect("delta_applied", _count_commits)
	chapter = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))
	var scene := Node3D.new()
	scene.name = "FinaleFixture"
	root.add_child(scene)
	current_scene = scene
	_box(scene, Vector3(0, -0.5, 0), Vector3(76, 1, 76))
	# Wall across the wind direction at x=0,z=7. Real collisions stop the body.
	_box(scene, Vector3(0, 2, 7), Vector3(20, 4, 1))
	_body = DrivenBody.new()
	_body.name = "ControlledCreatureFixture"
	_body.position = Vector3(0, 0.2, 0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	_body.add_child(shape)
	scene.add_child(_body)
	var arbiter := ARBITER.new()
	scene.add_child(arbiter)
	arbiter.set_player(_body)
	var data := FINALE.read_config()
	data["arena_origin"] = [0.0, 0.0, 0.0]
	data["aftermath_witness"]["position"] = [0.0, 0.0, -10.0]
	data["recovery"]["safe_position"] = [-10.0, 0.2, -10.0]
	_finale = FINALE.new()
	_finale.setup(flags, _event, func() -> CharacterBody3D: return _body,
		func() -> bool: return creature_piloted, _recover, data)
	scene.add_child(_finale)
	# The production relay prompts: the runtime's own installer, on a runtime
	# that is not mounted. Its `controlled_body()` answers `player` while there
	# is no field body or manager, which is this driven body.
	var runtime: Node = RUNTIME.new()
	runtime.set("finale", _finale)
	runtime.set("player", _body)
	runtime.call("_install_creature_relay_prompts")
	for relay: Dictionary in data["relays"]:
		var installed: Node = _finale.get_node_or_null("Relay_" + str(relay["id"]))
		_check(installed != null and installed.get_script() == preload("res://scripts/world/cloudreach_relay_interactable.gd"),
			"Runtime installs the creature relay prompt for " + str(relay["id"]))
	_body.finale = _finale
	await _frames(20)
	_check(_body.is_on_floor(), "CharacterBody rests on a real floor")
	_check(not _finale.strike_relay("west", _body), "Relay refuses pre-victory use")
	for flag: String in data["requires_flags"]:
		flags.set_flag(flag)
	_check(_finale.encounter_started("captain_veyra_storm_anchor"), "Real encounter-start seam accepts gated captain")
	_finale.set_process(false)
	_finale.elapsed = 2.0
	_press("move_back", true)
	await _frames(95)
	_press("move_back", false)
	_check(_body.position.z < 6.3, "Body did not pass through windward wall")
	_check(_body.position.z > 3.5, "Synthetic movement input actually moved body")
	_body.position = Vector3(0, 0.1, 0)
	for tick in range(180):
		_body.velocity = Vector3.ZERO
		_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.length() <= 7.01 and _body.velocity.length() > 6.5,
		"Wind accumulates against fresh locomotion but stays at configured speed cap")
	_body.position = Vector3(-20, 0.1, -12)
	for tick in range(20):
		_body.velocity = Vector3.ZERO
		_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.is_zero_approx(), "Lee pocket sheds accumulated drift")
	_check(_finale.encounter_won("captain_veyra_storm_anchor"), "Injected production-win seam advances once")
	_check(not _finale.encounter_won("captain_veyra_storm_anchor"), "Duplicate win refused")
	_body.position = Vector3(-29, 0.1, 3.0)
	creature_piloted = false
	_finale.sync_progression()
	_check(not _finale.strike_relay("west", _body), "Human cannot strike relay")
	creature_piloted = true
	_finale.sync_progression()
	_finale.elapsed = 0.0
	for relay: Dictionary in data["relays"]:
		_body.position = FINALE.vec(relay["offset"]) + Vector3(0, 0.1, -1.0)
		_body.velocity = Vector3.ZERO
		await _frames(5)
		var prompt: Node3D = _finale.get_node("Relay_" + str(relay["id"]))
		_check(not prompt.interaction_offer(_body.global_position).is_empty(), "Reachable relay offers interaction")
		_press("interact", true)
		await _frames(3)
		_press("interact", false)
		await _frames(3)
		_check(flags.has(str(relay["flag_id"])), "Shared input arbiter strikes " + str(relay["id"]))
	# A second press at the last relay once it is dark must not commit again.
	_press("interact", true)
	await _frames(3)
	_press("interact", false)
	await _frames(3)
	var world_flags: RefCounted = game.call("world_flags")
	for relay: Dictionary in data["relays"]:
		var flag := str(relay["flag_id"])
		_check(bool(world_flags.call("has", flag)), "Relay flag lands in Game world flags: " + flag)
		_check(int(_flag_commits.get(flag, 0)) == 1,
			"Relay flag committed exactly once through Game.ledger: %s (%d)" % [flag, int(_flag_commits.get(flag, 0))])
	_check(flags.has("storm_anchor_network_disabled"), "Three physical relay interactions disable network")
	_check(not flags.has("cloudreach_winds_restored"), "Network does not auto-witness restoration")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(flags.call("save_data")))
	game.call("reset_for_new_game")
	_check(not flags.has("storm_anchor_network_disabled"), "New-game reset empties the live store before reload")
	flags.call("load_data", saved)
	_check(flags == game.get("progression"), "Reload keeps the controller on Game.progression")
	_finale.setup(game.get("progression"), _event, func() -> CharacterBody3D: return _body,
		func() -> bool: return creature_piloted, _recover, data)
	_check(_finale.phase == "awaiting_restoration", "Saved network restores presentation without replay")
	_body.position = Vector3(0, 0.1, -10)
	_check(_finale.witness_restoration(_body), "Physical overlook visit witnesses restoration")
	_check(not _finale.witness_restoration(_body), "Duplicate witness is idempotent")
	_check(not flags.has("realm_key_stormwood"), "Heart/key still require reward dialogue")
	_body.move_enabled = false
	_body.position = Vector3(40, -8, 0)
	_body.velocity = Vector3(0, -20, 0)
	_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(_body.velocity.y > 0 and _body.velocity.x < 0, "Recovery current lifts and returns inward")
	_body.position = Vector3(30, -30, 0)
	_finale.apply_hazards(_body, 1.0 / 60.0)
	_check(recovered == 1, "Deep fall hands off once to safe bivouac")
	_check(_body.position.distance_to(Vector3(-10, 0.2, -10)) < 0.01, "Recovery callback physically places body safely")
	_check(flags.has("cloudreach_winds_restored"), "Recovery retains finale state")
	_body.finale = null
	ledger.disconnect("delta_applied", _count_commits)
	scene.queue_free()
	await process_frame
	runtime.free()
	await _pending_client_leg(game, data)
	await _live_fight_sweep_leg(game, data)
	await _break_the_eye_pilot_leg(game, data)
	await _director_client_leg(game, data)
	print("CLOUDREACH FINALE FIXTURE %s: body/input/collision, three relays, saved phase, aftermath, recovery, pending client, live-fight sweep, break-the-eye pilot, director client" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


## See the header. `set_process(false)` keeps the revision poll out of it, so
## every settlement below is the client delta sweep's alone.
func _pending_client_leg(game: Node, data: Dictionary) -> void:
	game.call("reset_for_new_game")
	var progression: RefCounted = game.get("progression")
	var world_flags: RefCounted = game.call("world_flags")
	for flag: String in data["requires_flags"]:
		progression.call("set_flag", flag)
	var encounter := str(data["encounter_id"])
	var victory_event := str(data["captain_victory_event"])
	var network_event := str(data["network_event"])
	var aftermath_event := str(data["aftermath_event"])
	var host := PendingClientHost.new()
	host.game = game
	host.chapter = chapter
	var scene := Node3D.new()
	scene.name = "PendingClientFixture"
	root.add_child(scene)
	var body := CharacterBody3D.new()
	body.name = "PendingClientCreature"
	scene.add_child(body)
	var finale: Node3D = FINALE.new()
	finale.setup(progression, Callable(host, "emit_event"), func() -> CharacterBody3D: return body,
		func() -> bool: return true, Callable(), data)
	finale.set("ledger_transport", host)
	scene.add_child(finale)
	finale.set_process(false)
	var seen: Array = []
	finale.connect("captain_defeated", func() -> void: seen.append("win"))
	finale.connect("relay_disabled", func(id: String) -> void: seen.append("relay:" + id))
	finale.connect("network_disabled", func() -> void: seen.append("network"))
	finale.connect("aftermath_restored", func() -> void: seen.append("witness"))
	var expected: Array = ["win"]

	_check(finale.encounter_started(encounter), "Pending client: encounter starts")
	_check(not finale.encounter_won(encounter), "Pending client: win waits for the host")
	_check(not finale.encounter_won(encounter), "Pending client: in-flight win is not re-submitted")
	_check(host.events.count(victory_event) == 1, "Pending client: one victory event submitted")
	_check(seen.is_empty(), "Pending client: nothing announced before the delta")
	host.land()
	_check(seen == expected, "Pending client: captain_defeated once when the delta lands %s" % [seen])
	_check(finale.phase == "break_the_eye", "Pending client: landed win opens the relays")
	_check(not finale.encounter_won(encounter) and host.events.count(victory_event) == 1,
		"Pending client: landed win is not submitted again")

	for relay: Dictionary in data["relays"]:
		var id := str(relay["id"])
		var flag := str(relay["flag_id"])
		body.position = FINALE.vec(relay["offset"]) + Vector3(0, 0.1, -1.0)
		var prompt: Node3D = finale.get_node("Relay_" + id)
		_check(not prompt.interaction_offer(body.global_position).is_empty(), "Pending client: relay offers " + id)
		_check(not finale.strike_relay(id, body), "Pending client: strike waits for the host " + id)
		_check(not finale.strike_relay(id, body), "Pending client: in-flight strike is not re-submitted " + id)
		finale.call("_activate_relay", id)
		_check(prompt.interaction_offer(body.global_position).is_empty(), "Pending client: in-flight relay stops offering " + id)
		_check(host.submits_of(flag) == 1, "Pending client: one relay intent " + id)
		_check(not progression.has(flag), "Pending client: nothing goes dark before the delta " + id)
		_check(seen.count("relay:" + id) == 0, "Pending client: no relay signal before the delta " + id)
		host.land()
		expected.append("relay:" + id)
		_check(bool(world_flags.call("has", flag)), "Pending client: relay lands in Game world flags " + id)
		_check(seen.count("relay:" + id) == 1, "Pending client: relay_disabled once when the delta lands " + id)
		_check(not finale.strike_relay(id, body) and host.submits_of(flag) == 1,
			"Pending client: landed relay is not struck again " + id)

	_check(host.events.count(network_event) == 1, "Pending client: third landed relay submits the network repair")
	finale.sync_progression()
	finale.sync_progression()
	_check(host.events.count(network_event) == 1, "Pending client: pending network repair is not re-submitted")
	_check(not seen.has("network"), "Pending client: no network signal before the delta")
	host.land()
	expected.append("network")
	_check(seen.count("network") == 1, "Pending client: network_disabled once when the delta lands")
	_check(finale.phase == "awaiting_restoration", "Pending client: landed network awaits restoration")

	body.position = Vector3(0, 0.1, -10)
	for frame in range(5):
		_check(not finale.witness_restoration(body), "Pending client: witness waits for the host")
		await process_frame
	_check(host.events.count(aftermath_event) == 1, "Pending client: per-frame witness poll submits once")
	_check(not seen.has("witness"), "Pending client: no witness signal before the delta")
	host.land()
	expected.append("witness")
	_check(finale.phase == "restored", "Pending client: landed witness restores the winds")
	_check(not finale.witness_restoration(body), "Pending client: landed witness is not submitted again")
	finale.sync_progression()
	_check(host.events.count(aftermath_event) == 1, "Pending client: one witness event in total")
	_check(seen == expected, "Pending client: each signal exactly once, in order %s" % [seen])
	_check(not progression.has("realm_key_stormwood"), "Pending client: witness still grants no reward")
	scene.queue_free()
	await process_frame
	host.free()


## One committed delta through the production client entry, which applies it
## and sweeps `progression_restore`.
func _land_delta(game: Node, op: Dictionary) -> void:
	_land_ops(game, [op])


func _land_ops(game: Node, ops: Array) -> void:
	var transport: Node = game.get("ledger")
	var world_ledger: RefCounted = transport.get("ledger")
	transport.call("apply_remote_delta",
		{"seq": int(world_ledger.get("seq")) + 1, "realm": "cloudreach", "ops": ops})


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for child in dir.get_directories():
		_remove_tree(path.path_join(child))
	for file in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


## Mid-Veyra, with drift built up by the hazards themselves and a clock set.
func _enter_fight(finale: Node3D, director: FightDirector, body: CharacterBody3D, encounter: String,
		overload: bool, at: float) -> void:
	_check(finale.encounter_started(encounter), "Live sweep: encounter starts")
	director.active_id = encounter
	if overload:
		finale.opposition_remaining(encounter, 1, 3)
	finale.elapsed = at
	body.global_position = Vector3(0, 0.1, 0)
	for tick in range(10):
		body.velocity = Vector3.ZERO
		finale.apply_hazards(body, 1.0 / 60.0)
	finale.elapsed = at


func _reset_state(finale: Node3D, body: CharacterBody3D) -> bool:
	return finale.phase == "dormant" and not bool(finale.get("_in_encounter")) \
		and not bool(finale.get("_overload")) and is_zero_approx(finale.elapsed) \
		and not (finale.get("_hazard_drift") as Dictionary).has(body.get_instance_id())


## See the header.
func _live_fight_sweep_leg(game: Node, data: Dictionary) -> void:
	game.call("reset_for_new_game")
	var progression: RefCounted = game.get("progression")
	var encounter := str(data["encounter_id"])
	var original_saver: RefCounted = game.get("save_system")
	var save_dir := "user://test_cloudreach_finale_sweep_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var saves: RefCounted = SAVE.new(save_dir)
	game.set("save_system", saves)
	# An earlier world/save that predates the encounter's entry flags, and one
	# taken just before the fight.
	var early_world: Dictionary = game.call("world_snapshot")
	_check(bool(saves.call("save", game, 0)), "Live sweep: early save written")
	for flag: String in data["requires_flags"]:
		progression.call("set_flag", flag)
	_check(bool(saves.call("save", game, 1)), "Live sweep: pre-fight save written")

	var scene := Node3D.new()
	scene.name = "LiveFightSweepFixture"
	root.add_child(scene)
	var body := CharacterBody3D.new()
	body.name = "LiveFightCreature"
	scene.add_child(body)
	var director := FightDirector.new()
	director.name = "EncounterDirector"
	var finale: Node3D = FINALE.new()
	finale.setup(progression, func(event: String) -> Dictionary: return CHAPTER.dispatch(progression, chapter, event),
		func() -> CharacterBody3D: return body, func() -> bool: return true, Callable(), data)
	scene.add_child(finale)
	# Added after the controller and handed to it, as
	# `cloudreach_world_runtime.gd::mount()` does.
	scene.add_child(director)
	finale.set("fight_director", director)
	finale.set_process(false)
	var phases: Array = []
	finale.connect("phase_changed", func(phase: String) -> void: phases.append(phase))

	# 1. crosswind_command survives an unrelated world delta (a pickup).
	await _enter_fight(finale, director, body, encounter, false, 3.25)
	var drift: Vector3 = (finale.get("_hazard_drift") as Dictionary).get(body.get_instance_id(), Vector3.ZERO)
	_check(finale.phase == "crosswind_command" and not drift.is_zero_approx(),
		"Live sweep: crosswind wind has built drift before the delta")
	phases.clear()
	_land_delta(game, {"op": "flag", "scope": "world", "realm": "cloudreach",
		"id": "pickup:cloudreach_sweep_crate", "value": true})
	_check(progression.has("pickup:cloudreach_sweep_crate"), "Live sweep: the unrelated pickup delta landed")
	_check(finale.phase == "crosswind_command", "Live sweep: unrelated delta keeps crosswind_command (%s)" % finale.phase)
	_check(bool(finale.get("_in_encounter")), "Live sweep: unrelated delta keeps the encounter running")
	_check(is_equal_approx(finale.elapsed, 3.25), "Live sweep: hazard clock not restarted (%.2f)" % finale.elapsed)
	_check((finale.get("_hazard_drift") as Dictionary).get(body.get_instance_id(), Vector3.ZERO) == drift,
		"Live sweep: accumulated wind drift kept")
	_check(bool(finale.presentation_state()["hazards_active"]), "Live sweep: hazards still active after the delta")
	_check(not (finale.hazard_at(body.global_position)["wind"] as Vector3).is_zero_approx(),
		"Live sweep: the wind lane still pushes after the delta")
	_check(phases.is_empty(), "Live sweep: no phase change from an unrelated delta %s" % [phases])

	# 2. anchor_overload survives another peer's flag.
	finale.opposition_remaining(encounter, 1, 3)
	_check(finale.phase == "anchor_overload", "Live sweep: half the opposition down enters anchor_overload")
	finale.elapsed = 1.75
	phases.clear()
	_land_delta(game, {"op": "flag", "scope": "player", "realm": "cloudreach",
		"id": "tam_tools_given", "value": true, "peers": [2]})
	_check(finale.phase == "anchor_overload", "Live sweep: another peer's flag keeps anchor_overload (%s)" % finale.phase)
	_check(bool(finale.get("_overload")), "Live sweep: overload kept")
	_check(is_equal_approx(finale.elapsed, 1.75), "Live sweep: overload clock not restarted (%.2f)" % finale.elapsed)
	_check(str(finale.hazard_at(body.global_position)["arc_stage"]) == "active",
		"Live sweep: relay arc still active on the kept clock")
	_check(phases.is_empty(), "Live sweep: no phase change from another peer's flag %s" % [phases])

	# 3. A world snapshot that predates the encounter resets it, fight or not.
	game.call("apply_world_snapshot", early_world)
	_check(_reset_state(finale, body), "Live sweep: a pre-encounter world snapshot resets the finale (%s)" % finale.phase)
	_check(game.get("progression") == progression, "Live sweep: the snapshot reloads the same store in place")
	director.active_id = ""

	# 4. A real save-load once the fight is over resets it. (The game menu
	# refuses to open while `is_fighting()`.)
	_check(bool(game.call("load_game", 1)), "Live sweep: pre-fight save loads")
	_check(game.get("progression") == progression, "Live sweep: Game.load_game reloads the same store in place")
	await _enter_fight(finale, director, body, encounter, true, 2.0)
	_check(finale.phase == "anchor_overload", "Live sweep: fight re-entered after the load")
	# Between Veyra's creatures the menu can open; the director's battle is still
	# running and nothing restores it, so the finale keeps mirroring it.
	_check(bool(game.call("load_game", 1)), "Live sweep: mid-battle load succeeds")
	_check(finale.phase == "anchor_overload" and bool(finale.get("_in_encounter")),
		"Live sweep: a load while the director still runs the battle keeps it (%s)" % finale.phase)
	director.active_id = ""
	_check(bool(game.call("load_game", 1)), "Live sweep: post-fight load succeeds")
	_check(_reset_state(finale, body), "Live sweep: a real save-load with the fight over resets the finale (%s)" % finale.phase)

	# 5. A real save-load of an earlier save resets it even mid-battle.
	await _enter_fight(finale, director, body, encounter, true, 2.0)
	_check(bool(game.call("load_game", 0)), "Live sweep: early save loads")
	_check(_reset_state(finale, body), "Live sweep: loading a save from before the encounter resets it (%s)" % finale.phase)

	game.set("save_system", original_saver)
	scene.queue_free()
	await process_frame
	_remove_tree(ProjectSettings.globalize_path(save_dir))


## Control is the trainer's again: locomotion on, camera and arbiter on them.
func _trainer_has_control(runtime: Node, trainer: PilotBody, camera: CameraStub,
		arbiter: Node) -> bool:
	return runtime.get("_field_body") == null and not trainer.locomotion.is_empty() \
		and bool(trainer.locomotion.back()) and camera.target == trainer and arbiter.viewer() == trainer


func _pilot_ally(scene: Node3D, director: PilotDirector, runtime: Node, name: String) -> PilotBody:
	var ally := PilotBody.new()
	ally.name = name
	scene.add_child(ally)
	ally.global_position = Vector3(0, 0.1, 0)
	director.ally = ally
	runtime.call("_process", 1.0 / 60.0)
	return ally


## What `encounter_director.gd::dismiss_active_creature()` does to the body.
func _recall(director: PilotDirector, body: PilotBody) -> void:
	body.queue_free()
	director.ally = null


## See the header.
func _break_the_eye_pilot_leg(game: Node, data: Dictionary) -> void:
	game.call("reset_for_new_game")
	var progression: RefCounted = game.get("progression")
	for flag: String in data["requires_flags"]:
		progression.call("set_flag", flag)
	progression.call("set_flag", str(data["captain_victory_flag"]))
	var original_saver: RefCounted = game.get("save_system")
	var save_dir := "user://test_cloudreach_finale_pilot_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var saves: RefCounted = SAVE.new(save_dir)
	game.set("save_system", saves)
	_check(bool(saves.call("save", game, 0)), "Pilot: break_the_eye save written")

	var scene := Node3D.new()
	scene.name = "PilotSweepFixture"
	root.add_child(scene)
	var camera := CameraStub.new()
	camera.name = "CameraRig"
	scene.add_child(camera)
	var arbiter := ARBITER.new()
	arbiter.name = "InteractionArbiter"
	scene.add_child(arbiter)
	var trainer := PilotBody.new()
	trainer.name = "Player"
	scene.add_child(trainer)
	trainer.global_position = Vector3(-6, 0.1, 0)
	var deep := PilotBody.new()
	deep.name = "FallingCompanion"
	scene.add_child(deep)
	var director := PilotDirector.new()
	director.name = "EncounterDirector"
	var manager := CombatStub.new()
	manager.name = "CombatManager"
	var atmosphere := AtmosphereStub.new()
	var handoffs: Array = []
	var finale: Node3D = FINALE.new()
	finale.setup(progression, func(event: String) -> Dictionary: return CHAPTER.dispatch(progression, chapter, event),
		func() -> CharacterBody3D: return director.ally, func() -> bool: return true,
		func(body: CharacterBody3D, _camp: String, _at: Vector3) -> void: handoffs.append(body), data)
	var runtime: Node = RUNTIME.new()
	runtime.name = "CloudreachRuntime"
	runtime.set("world", scene)
	runtime.set("player", trainer)
	runtime.set("finale", finale)
	runtime.set("director", director)
	runtime.set("manager", manager)
	runtime.set("atmosphere", atmosphere)
	runtime.set("_mounted", true)
	# Production order: the runtime is in the world before `mount()` adds the
	# finale, so the sweep reaches it first.
	scene.add_child(runtime)
	runtime.set_process(false)
	runtime.set_physics_process(false)
	scene.add_child(finale)
	scene.add_child(director)
	scene.add_child(manager)
	scene.add_child(atmosphere)
	finale.set("fight_director", director)
	finale.set_process(false)
	runtime.add_to_group("progression_restore")
	var swept: Array = get_nodes_in_group("progression_restore")
	_check(swept.find(runtime) >= 0 and swept.find(runtime) < swept.find(finale),
		"Pilot: the runtime is swept before the finale, as in production")
	_check(finale.phase == "break_the_eye", "Pilot: fixture opens in break_the_eye (%s)" % finale.phase)

	var ally := _pilot_ally(scene, director, runtime, "Ally")
	_check(runtime.call("controlled_body") == ally, "Pilot: the exam hands the ally to the trainer")
	_check(camera.target == ally and arbiter.viewer() == ally, "Pilot: camera and arbiter follow the ally")
	finale.elapsed = 2.5
	for tick in range(10):
		ally.velocity = Vector3.ZERO
		finale.apply_hazards(ally, 1.0 / 60.0)
	finale.elapsed = 2.5
	var drift: Vector3 = (finale.get("_hazard_drift") as Dictionary).get(ally.get_instance_id(), Vector3.ZERO)
	_check(not drift.is_zero_approx(), "Pilot: the break_the_eye wind has built drift on the ally")
	# A companion already below handoff depth has been handed off once.
	deep.global_position = Vector3(30, -30, 0)
	finale.apply_hazards(deep, 1.0 / 60.0)
	_check(handoffs.size() == 1, "Pilot: the deep fall is handed off once")

	for step: Array in [["unrelated pickup", {"op": "flag", "scope": "world", "realm": "cloudreach",
			"id": "pickup:cloudreach_pilot_crate", "value": true}],
			["another peer's relay", {"op": "flag", "scope": "world", "realm": "cloudreach",
			"id": str(data["relays"][0]["flag_id"]), "value": true}]]:
		var label := str(step[0])
		camera.calls.clear()
		trainer.locomotion.clear()
		_land_delta(game, step[1])
		# Sampled straight after the sweep, before any `_process` could repair it.
		_check(runtime.get("_field_body") == ally, "Pilot: %s keeps field control on the ally" % label)
		_check(camera.calls.is_empty() and camera.target == ally,
			"Pilot: %s never retargets the camera %s" % [label, camera.calls])
		_check(arbiter.viewer() == ally, "Pilot: %s keeps the arbiter on the ally" % label)
		_check(trainer.locomotion.is_empty() and not ally.following,
			"Pilot: %s does not hand locomotion back %s" % [label, trainer.locomotion])
		_check(finale.phase == "break_the_eye", "Pilot: %s keeps break_the_eye (%s)" % [label, finale.phase])
		_check(is_equal_approx(finale.elapsed, 2.5), "Pilot: %s keeps the wind clock (%.2f)" % [label, finale.elapsed])
		_check((finale.get("_hazard_drift") as Dictionary).get(ally.get_instance_id(), Vector3.ZERO) == drift,
			"Pilot: %s keeps the ally's drift" % label)
		finale.apply_hazards(deep, 1.0 / 60.0)
		_check(handoffs.size() == 1, "Pilot: %s does not hand the same fall off twice (%d)" % [label, handoffs.size()])
		runtime.call("_process", 1.0 / 60.0)
		_check(camera.calls.is_empty() and runtime.call("controlled_body") == ally,
			"Pilot: the next frame after %s changes nothing" % label)
		await process_frame
	_check(progression.has(str(data["relays"][0]["flag_id"])), "Pilot: the other peer's relay landed")

	# Lifted back up into the current (between its 3 m and the 27 m handoff
	# depth) the fall is still one fall: a sweep keeps its guard, as
	# `_apply_recovery_current` does, and sinking again is no second handoff.
	deep.global_position = Vector3(30, -10, 0)
	finale.apply_hazards(deep, 1.0 / 60.0)
	_land_delta(game, {"op": "flag", "scope": "world", "realm": "cloudreach",
		"id": "pickup:cloudreach_pilot_crate_lift", "value": true})
	_check((finale.get("_pending_recoveries") as Dictionary).has(deep.get_instance_id()),
		"Pilot: a sweep keeps the handoff guard while the body is still inside the current")
	deep.global_position = Vector3(30, -30, 0)
	finale.apply_hazards(deep, 1.0 / 60.0)
	_check(handoffs.size() == 1, "Pilot: sinking again inside the current is no second handoff (%d)" % handoffs.size())
	await process_frame

	# The network landing ends break_the_eye. The runtime is swept first and
	# still reads the old phase; the next `_process` releases the pilot.
	var network_ops: Array = []
	for relay: Dictionary in data["relays"]:
		network_ops.append({"op": "flag", "scope": "world", "realm": "cloudreach",
			"id": str(relay["flag_id"]), "value": true})
	network_ops.append({"op": "flag", "scope": "world", "realm": "cloudreach",
		"id": str(data["network_flag"]), "value": true})
	trainer.locomotion.clear()
	_land_ops(game, network_ops)
	_check(finale.phase == "awaiting_restoration", "Pilot: the network landing moves the phase on (%s)" % finale.phase)
	# Swept before the finale, the runtime still read break_the_eye: the pilot
	# stays until the next frame rather than flickering off inside the sweep.
	_check(runtime.get("_field_body") == ally, "Pilot: the network landing's sweep leaves the pilot in place")
	runtime.call("_process", 1.0 / 60.0)
	_check(_trainer_has_control(runtime, trainer, camera, arbiter),
		"Pilot: the next frame after the network landing releases the pilot")
	await process_frame

	# A real save-load back into break_the_eye restarts the wind clock and
	# drift; the exam applies again from the next frame.
	_check(bool(game.call("load_game", 0)), "Pilot: break_the_eye save loads")
	_check(finale.phase == "break_the_eye", "Pilot: the load restores break_the_eye from its flags")
	_check(is_zero_approx(finale.elapsed) and (finale.get("_hazard_drift") as Dictionary).is_empty(),
		"Pilot: a real load still restarts the wind clock and drift (%.2f)" % finale.elapsed)
	runtime.call("_process", 1.0 / 60.0)
	_check(runtime.get("_field_body") == ally, "Pilot: the exam hands the ally over again after the load")

	# A fight takes the camera; a sweep during it must leave the camera alone.
	manager.fighting = true
	runtime.call("_process", 1.0 / 60.0)
	_check(runtime.get("_field_body") == null, "Pilot: a fight releases the exam pilot")
	camera.set_target(ally, {})
	camera.calls.clear()
	_land_delta(game, {"op": "flag", "scope": "world", "realm": "cloudreach",
		"id": "pickup:cloudreach_pilot_crate_two", "value": true})
	_check(camera.calls.is_empty() and camera.target == ally,
		"Pilot: a sweep mid-fight leaves the combat camera alone %s" % [camera.calls])
	manager.fighting = false
	runtime.call("_process", 1.0 / 60.0)
	_check(runtime.get("_field_body") == ally, "Pilot: the exam resumes after the fight")

	# Recall mid-exam: the ally is freed at the end of the frame while still
	# piloted. The next `_process` must hand control back to the trainer.
	trainer.locomotion.clear()
	_recall(director, ally)
	await process_frame
	_check(not is_instance_valid(ally), "Pilot: the recalled ally is freed")
	runtime.call("_process", 1.0 / 60.0)
	_check(_trainer_has_control(runtime, trainer, camera, arbiter),
		"Pilot: a recalled ally hands control back to the trainer %s" % [trainer.locomotion])

	# The same, repaired by a load's sweep before any `_process` runs.
	var second := _pilot_ally(scene, director, runtime, "SecondAlly")
	_check(runtime.get("_field_body") == second, "Pilot: a re-summoned ally is piloted")
	trainer.locomotion.clear()
	_recall(director, second)
	await process_frame
	_check(bool(game.call("load_game", 0)), "Pilot: load with a freed piloted ally succeeds")
	_check(_trainer_has_control(runtime, trainer, camera, arbiter),
		"Pilot: a load hands control back from a freed ally %s" % [trainer.locomotion])

	game.set("save_system", original_saver)
	scene.queue_free()
	await process_frame
	_remove_tree(ProjectSettings.globalize_path(save_dir))


## The integrated client path: the REAL Cloudreach director's final-round
## victory reaches the finale through `trainer_victory` (as
## `cloudreach_world_runtime.gd::_trainer_won` wires it), with `Game.ledger`
## answering as a joined client's does. The host refuses once, then commits.
## Disclosed: the win is `_record_trainer_defeat` called directly (what the
## inherited final round calls), `_trainer_spec` is set as
## `begin_trainer_battle` would, and `Game.ledger` is the stand-in for the leg.
func _director_client_leg(game: Node, data: Dictionary) -> void:
	game.call("reset_for_new_game")
	var progression: RefCounted = game.get("progression")
	var world_flags: RefCounted = game.call("world_flags")
	for flag: String in data["requires_flags"]:
		progression.call("set_flag", flag)
	var encounter := str(data["encounter_id"])
	var victory := str(data["captain_victory_flag"])
	var victory_event := str(data["captain_victory_event"])
	var real_ledger: Node = game.get("ledger")
	var host := PendingClientHost.new()
	host.game = game
	host.chapter = chapter
	host.real_ledger = real_ledger
	game.set("ledger", host)
	var session := ClientSession.new()

	var scene := CloudreachRoot.new()
	scene.name = "DirectorClientFixture"
	root.add_child(scene)
	var body := CharacterBody3D.new()
	body.name = "DirectorClientCreature"
	scene.add_child(body)
	var director := ClientDirector.new()
	director.name = "EncounterDirector"
	director.setup(scene)
	director.set("_session", session)
	var finale: Node3D = FINALE.new()
	finale.setup(progression, Callable(host, "emit_event"), func() -> CharacterBody3D: return body,
		func() -> bool: return true, Callable(), data)
	scene.add_child(director)
	scene.add_child(finale)
	finale.set("fight_director", director)
	finale.set_process(false)
	director.connect("trainer_victory", func(id: String) -> void:
		if id == encounter:
			finale.encounter_won(id))
	var wins: Array = []
	finale.connect("captain_defeated", func() -> void: wins.append("win"))
	var spec: Dictionary = (director.get("trainer_specs") as Dictionary)[encounter]
	_check(str(spec["defeat_flag"]) == victory, "Director client: Veyra's defeat flag is the finale's victory flag")
	var inventory: RefCounted = game.get("inventory")

	_check(finale.encounter_started(encounter), "Director client: encounter starts")
	director.set("_trainer_spec", spec)
	var world_before: Dictionary = JSON.parse_string(JSON.stringify(world_flags.call("save_data")))
	director.call("_record_trainer_defeat", spec)
	director.set("_trainer_spec", {})
	_check(not progression.has(victory) and not bool(world_flags.call("has", victory)),
		"Director client: a client's win writes no captain_veyra_defeated before the host commits")
	_check(host.events.count(victory_event) == 1, "Director client: one victory event submitted")
	finale.sync_progression()
	finale.call("_process", 0.1)
	_check(finale.phase == "crosswind_command" and wins.is_empty(),
		"Director client: nothing settles before the host answers (%s)" % finale.phase)
	# Whatever the base pays a client for its own win (today a self-payout), it
	# pays it once: neither the retry nor the landing pays again.
	var coins_after_win := int(inventory.call("count", "coin"))

	host.refuse()
	finale.sync_progression()
	finale.call("_process", 0.1)
	_check(finale.phase != "break_the_eye" and wins.is_empty(),
		"Director client: a host refusal leaves the client out of break_the_eye (%s)" % finale.phase)
	_check(JSON.stringify(world_flags.call("save_data")) == JSON.stringify(world_before),
		"Director client: a host refusal leaves the client's world store unchanged")

	# The fight is won again and this time the host commits.
	if not bool(finale.get("_in_encounter")):
		finale.encounter_started(encounter)
	director.set("_trainer_spec", spec)
	director.call("_record_trainer_defeat", spec)
	director.set("_trainer_spec", {})
	_check(not progression.has(victory), "Director client: the retried win is still only an intent")
	host.land()
	_check(progression.has(victory), "Director client: the committed delta sets the flag")
	_check(wins == ["win"], "Director client: captain_defeated once when the delta lands %s" % [wins])
	_check(finale.phase == "break_the_eye", "Director client: the landed win opens the relays")
	finale.sync_progression()
	finale.call("_process", 0.1)
	director.call("_record_trainer_defeat", spec)
	_check(wins == ["win"], "Director client: settled exactly once %s" % [wins])
	_check(int(inventory.call("count", "coin")) == coins_after_win,
		"Director client: the client is paid once, not again on the retry or the landing")

	# A relay the host never answers comes back after the timeout, and its late
	# delta still settles once.
	var relay: Dictionary = data["relays"][0]
	var relay_id := str(relay["id"])
	var relays: Array = []
	finale.connect("relay_disabled", func(id: String) -> void: relays.append(id))
	body.global_position = FINALE.vec(relay["offset"]) + Vector3(0, 0.1, -1.0)
	var prompt: Node3D = finale.get_node("Relay_" + relay_id)
	_check(not finale.strike_relay(relay_id, body), "Director client: relay strike waits for the host")
	_check(prompt.interaction_offer(body.global_position).is_empty(), "Director client: the in-flight relay stops offering")
	var timeout := float(data.get("pending_intent_timeout_s", 8.0))
	finale.call("_process", timeout - 1.0)
	_check(prompt.interaction_offer(body.global_position).is_empty(), "Director client: held while the timeout runs")
	finale.call("_process", 1.5)
	_check(not prompt.interaction_offer(body.global_position).is_empty(),
		"Director client: an unanswered relay offers again after the timeout")
	host.land()
	finale.call("_process", 0.1)
	_check(relays == [relay_id], "Director client: the late relay delta settles once %s" % [relays])

	game.set("ledger", real_ledger)
	scene.queue_free()
	await process_frame
	host.free()
	session.free()
