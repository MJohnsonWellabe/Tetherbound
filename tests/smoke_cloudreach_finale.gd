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
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

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
		var transport: Node = game.get("ledger")
		var world_ledger: RefCounted = transport.get("ledger")
		transport.call("apply_remote_delta",
			{"seq": int(world_ledger.get("seq")) + 1, "realm": "cloudreach", "ops": ops})

	func submits_of(flag: String) -> int:
		var count := 0
		for intent: Dictionary in submitted:
			if str(intent.get("id", "")) == flag:
				count += 1
		return count


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
	print("CLOUDREACH FINALE FIXTURE %s: body/input/collision, three relays, saved phase, aftermath, recovery, pending client" % ("PASS" if failures.is_empty() else "FAIL"))
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
