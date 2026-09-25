extends "res://tests/test_case.gd"

const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")
const ENCOUNTER := "captain_veyra_storm_anchor"


## A CLIENT's view of the host. Every chapter flag and relay flag this peer
## submits answers `pending` and is queued; `land()` is the host committing the
## queue and the delta arriving here. Chapter events run the real chapter logic
## with a writer, exactly as `realm_chapter_events.gd::emit_event` does.
class PendingHost extends Node:
	signal intent_refused(kind: String, code: String, reason: String, detail: Dictionary)
	const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
	var flags: RefCounted
	var chapter: Dictionary = {}
	var events: Array[String] = []
	var written: Array[String] = []
	var submitted: Array[Dictionary] = []
	var queued: Array[String] = []

	func emit_event(event: String) -> Dictionary:
		events.append(event)
		return LOGIC.dispatch(flags, chapter, event, Callable(self, "_write"))

	func _write(flag: String) -> Dictionary:
		written.append(flag)
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
		var landing := queued.duplicate()
		queued.clear()
		for flag: String in landing:
			flags.call("set_flag", flag)

	func submits_of(flag: String) -> int:
		var count := 0
		for intent: Dictionary in submitted:
			if str(intent.get("id", "")) == flag:
				count += 1
		return count


class FakeGame extends Node:
	var progression: RefCounted


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))


func _controller(flags: RefCounted) -> Node3D:
	var controller := FINALE.new()
	controller.setup(flags, func(event: String) -> Dictionary:
		return CHAPTER.dispatch(flags, _chapter(), event), Callable(), Callable())
	return controller


func _unlock(flags: RefCounted) -> void:
	for flag: String in FINALE.read_config()["requires_flags"]:
		flags.call("set_flag", flag)


func test_production_win_is_required_and_idempotent() -> void:
	var flags := FLAGS.new()
	var finale := _controller(flags)
	assert_false(finale.encounter_started("captain_veyra_storm_anchor"))
	_unlock(flags)
	assert_false(finale.encounter_won("captain_veyra_storm_anchor"), "Unstarted callback cannot grant victory")
	assert_false(finale.encounter_started("ordinary_trainer"))
	assert_true(finale.encounter_started("captain_veyra_storm_anchor"))
	assert_false(finale.encounter_started("captain_veyra_storm_anchor"))
	assert_eq(finale.phase, "crosswind_command")
	finale.opposition_remaining("captain_veyra_storm_anchor", 2, 3)
	assert_eq(finale.phase, "crosswind_command")
	finale.opposition_remaining("captain_veyra_storm_anchor", 1, 3)
	assert_eq(finale.phase, "anchor_overload")
	finale.opposition_remaining("captain_veyra_storm_anchor", 0, 3)
	assert_false(flags.has("captain_veyra_defeated"), "Zero count is not a production win callback")
	var emitted: Array = []
	finale.captain_defeated.connect(func() -> void: emitted.append("win"))
	assert_true(finale.encounter_won("captain_veyra_storm_anchor"))
	assert_eq(finale.phase, "break_the_eye")
	assert_false(finale.encounter_won("captain_veyra_storm_anchor"))
	assert_eq(emitted, ["win"])
	assert_false(flags.has("storm_anchor_network_disabled"))
	assert_false(flags.has("realm_key_stormwood"))
	finale.free()


func test_save_restores_partial_relays_and_repairs_only_completed_network() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	flags.set_flag("captain_veyra_defeated")
	var relays: Array = FINALE.read_config()["relays"]
	flags.set_flag(str(relays[0]["flag_id"]))
	var loaded := FLAGS.new()
	loaded.load_data(JSON.parse_string(JSON.stringify(flags.save_data())))
	var finale := _controller(loaded)
	assert_eq(finale.phase, "break_the_eye")
	assert_true(finale.presentation_state()["relays_disabled"]["west"])
	assert_false(finale.presentation_state()["relays_disabled"]["east"])
	assert_false(loaded.has("storm_anchor_network_disabled"))
	for relay: Dictionary in relays:
		loaded.set_flag(str(relay["flag_id"]))
	finale.sync_progression()
	assert_true(loaded.has("storm_anchor_network_disabled"))
	assert_eq(finale.phase, "awaiting_restoration")
	assert_false(finale.presentation_state()["hazards_active"])
	assert_false(loaded.has("cloudreach_winds_restored"), "Relays cannot invent witnessed aftermath")
	assert_false(loaded.has("realm_key_stormwood"))
	loaded.set_flag("cloudreach_winds_restored")
	finale.sync_progression()
	assert_true(finale.presentation_state()["natural_wind_trails"])
	assert_false(finale.presentation_state()["waterward_visible"], "Reward conversation is separate")
	loaded.set_flag("stormward_route_revealed")
	finale.sync_progression()
	assert_true(finale.presentation_state()["waterward_visible"])
	var revision: int = loaded.revision
	finale.sync_progression()
	assert_eq(loaded.revision, revision)
	finale.free()


func test_hazards_rotate_telegraph_and_preserve_three_lee_pockets() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	var finale := _controller(flags)
	finale.encounter_started("captain_veyra_storm_anchor")
	var centre: Vector3 = finale.position
	assert_eq(finale.hazard_at(centre, 0.5)["wind"], Vector3.ZERO)
	assert_eq(finale.hazard_at(centre, 0.5)["wind_stage"], "telegraph")
	assert_true((finale.hazard_at(centre, 2.0)["wind"] as Vector3).length() > 0.0)
	assert_ne(finale.hazard_at(centre, 2.0)["wind"], finale.hazard_at(centre, 3.0)["wind"])
	assert_eq(finale.hazard_at(centre, 5.0)["wind_stage"], "recovery")
	assert_eq(finale.hazard_at(centre - Vector3.UP * 30, 2.0)["wind"], Vector3.ZERO)
	assert_eq(finale.hazard_at(centre + Vector3.RIGHT * 70, 2.0)["wind"], Vector3.ZERO)
	finale.opposition_remaining("captain_veyra_storm_anchor", 1, 3)
	for lee: Dictionary in finale.config["lee_pockets"]:
		for time: float in [0.0, 2.0, 7.2, 30.0]:
			var sample: Dictionary = finale.hazard_at(centre + FINALE.vec(lee["offset"]), time)
			assert_true(sample["sheltered"])
			assert_eq(sample["wind"], Vector3.ZERO)
			assert_eq(sample["arc"], Vector3.ZERO)
	var angle := deg_to_rad(2.0 * float(finale.config["relay_arc"]["rotation_degrees_per_second"]))
	var arc_position := centre + Vector3(cos(angle), 0, sin(angle)) * 16.0
	assert_true((finale.hazard_at(arc_position, 2.0)["arc"] as Vector3).length() > 0.0)
	assert_eq(finale.hazard_at(arc_position, 0.0)["arc"], Vector3.ZERO)
	finale.free()


func test_older_unearned_save_cannot_infer_a_captain_win_from_relay_flags() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	for relay: Dictionary in FINALE.read_config()["relays"]:
		flags.set_flag(str(relay["flag_id"]))
	var finale := _controller(flags)
	assert_eq(finale.phase, "dormant")
	assert_false(flags.has("captain_veyra_defeated"))
	assert_false(flags.has("storm_anchor_network_disabled"))
	finale.free()


func test_client_pending_win_submits_once_and_settles_once_when_delta_lands() -> void:
	var config := FINALE.read_config()
	var victory := str(config["captain_victory_flag"])
	var victory_event := str(config["captain_victory_event"])
	var flags := FLAGS.new()
	_unlock(flags)
	var host := PendingHost.new()
	host.flags = flags
	host.chapter = _chapter()
	var finale := FINALE.new()
	finale.setup(flags, Callable(host, "emit_event"), Callable(), Callable())
	finale.ledger_transport = host
	var wins: Array = []
	finale.captain_defeated.connect(func() -> void: wins.append("win"))
	assert_true(finale.encounter_started(ENCOUNTER))
	assert_false(finale.encounter_won(ENCOUNTER), "A pending win grants nothing yet")
	assert_false(finale.encounter_won(ENCOUNTER), "An in-flight win is not submitted again")
	assert_eq(host.events.count(victory_event), 1, "One victory event submitted")
	assert_eq(host.written.count(victory), 1, "One victory flag intent")
	assert_false(flags.has(victory))
	assert_eq(wins, [])
	assert_eq(finale.phase, "crosswind_command")
	host.land()
	# The client's `progression_restore` sweep (`ledger_rpc.gd::apply_remote_delta`).
	var game := FakeGame.new()
	game.progression = flags
	finale.restore_progression_from_game(game)
	assert_eq(wins, ["win"], "captain_defeated emitted when the committed delta lands")
	assert_eq(finale.phase, "break_the_eye")
	finale._process(0.016)
	finale.sync_progression()
	finale.restore_progression_from_game(game)
	assert_eq(wins, ["win"], "captain_defeated emitted exactly once")
	assert_false(finale.encounter_won(ENCOUNTER), "Landed win cannot be won again")
	assert_eq(host.events.count(victory_event), 1)
	assert_false(flags.has("storm_anchor_network_disabled"))
	finale.free()
	game.free()
	host.free()


func test_client_pending_win_settles_from_revision_poll_alone() -> void:
	var config := FINALE.read_config()
	var flags := FLAGS.new()
	_unlock(flags)
	var host := PendingHost.new()
	host.flags = flags
	host.chapter = _chapter()
	var finale := FINALE.new()
	finale.setup(flags, Callable(host, "emit_event"), Callable(), Callable())
	finale.ledger_transport = host
	var wins: Array = []
	finale.captain_defeated.connect(func() -> void: wins.append("win"))
	finale.encounter_started(ENCOUNTER)
	finale.opposition_remaining(ENCOUNTER, 1, 3)
	assert_eq(finale.phase, "anchor_overload")
	assert_false(finale.encounter_won(ENCOUNTER))
	finale._process(1.0)
	assert_eq(wins, [], "No delta, no win")
	host.land()
	finale._process(0.25)
	assert_eq(wins, ["win"])
	assert_eq(finale.phase, "break_the_eye")
	assert_true(is_equal_approx(finale.elapsed, 0.25), "Landing resets the hazard clock like the host path")
	finale._process(0.25)
	assert_eq(wins, ["win"])
	assert_eq(host.written.count(str(config["captain_victory_flag"])), 1)
	finale.free()
	host.free()


func test_refused_pending_intent_releases_its_guard() -> void:
	var config := FINALE.read_config()
	var victory_event := str(config["captain_victory_event"])
	var flags := FLAGS.new()
	_unlock(flags)
	var host := PendingHost.new()
	host.flags = flags
	host.chapter = _chapter()
	var finale := FINALE.new()
	finale.setup(flags, Callable(host, "emit_event"), Callable(), Callable())
	finale.ledger_transport = host
	finale.encounter_started(ENCOUNTER)
	assert_false(finale.encounter_won(ENCOUNTER))
	host.intent_refused.emit("claim_pickup", "already_taken", "", {})
	assert_false(finale.encounter_won(ENCOUNTER), "Another consumer's refusal does not release it")
	assert_eq(host.events.count(victory_event), 1)
	host.intent_refused.emit("set_world_flag", "malformed", "", {})
	assert_false(finale.encounter_won(ENCOUNTER))
	assert_eq(host.events.count(victory_event), 2, "A refused win may be submitted again")
	finale.free()
	host.free()


func test_client_pending_relays_network_and_witness_submit_once_each() -> void:
	var flags := FLAGS.new()
	_unlock(flags)
	var config := FINALE.read_config()
	flags.set_flag(str(config["captain_victory_flag"]))
	var host := PendingHost.new()
	host.flags = flags
	host.chapter = _chapter()
	var data := config.duplicate(true)
	data["arena_origin"] = [0.0, 0.0, 0.0]
	data["aftermath_witness"]["position"] = [0.0, 0.0, -10.0]
	var holder := Node3D.new()
	var body := CharacterBody3D.new()
	var finale := FINALE.new()
	finale.setup(flags, Callable(host, "emit_event"), func() -> CharacterBody3D: return body,
		func() -> bool: return true, Callable(), data)
	finale.ledger_transport = host
	holder.add_child(finale)
	holder.add_child(body)
	(Engine.get_main_loop() as SceneTree).root.add_child(holder)
	assert_eq(finale.phase, "break_the_eye")
	var relays: Array = []
	var networks: Array = []
	var witnessed: Array = []
	finale.relay_disabled.connect(func(id: String) -> void: relays.append(id))
	finale.network_disabled.connect(func() -> void: networks.append("network"))
	finale.aftermath_restored.connect(func() -> void: witnessed.append("witness"))
	for relay: Dictionary in data["relays"]:
		var id := str(relay["id"])
		var flag := str(relay["flag_id"])
		body.position = FINALE.vec(relay["offset"]) + Vector3(0, 0.1, -1.0)
		var prompt: Node3D = finale.get_node("Relay_" + id)
		assert_false(prompt.interaction_offer(body.global_position).is_empty(), "Relay offers before a strike: " + id)
		assert_false(finale.strike_relay(id, body), "A client strike is pending, not done: " + id)
		assert_false(finale.strike_relay(id, body), "An in-flight strike is not submitted again: " + id)
		finale._activate_relay(id)
		assert_true(prompt.interaction_offer(body.global_position).is_empty(), "An in-flight relay stops offering: " + id)
		assert_eq(host.submits_of(flag), 1, "One relay intent: " + id)
		assert_false(flags.has(flag))
		assert_eq(relays.count(id), 0)
		host.land()
		finale._process(0.016)
		assert_eq(relays.count(id), 1, "relay_disabled emitted once the delta lands: " + id)
		assert_false(finale.strike_relay(id, body))
		finale._process(0.016)
		assert_eq(host.submits_of(flag), 1)
		assert_eq(relays.count(id), 1)
	var network_event := str(config["network_event"])
	assert_eq(host.events.count(network_event), 1, "Third landed relay submits the network repair")
	finale.sync_progression()
	finale._process(0.016)
	assert_eq(host.events.count(network_event), 1, "A pending network repair is not submitted again")
	assert_eq(networks, [])
	host.land()
	finale._process(0.016)
	assert_eq(networks, ["network"])
	assert_eq(finale.phase, "awaiting_restoration")
	var aftermath_event := str(config["aftermath_event"])
	body.position = Vector3(0, 0.1, -10)
	for frame in range(5):
		assert_false(finale.witness_restoration(body), "A pending witness is not done yet")
	assert_eq(host.events.count(aftermath_event), 1, "A per-frame witness poll submits once")
	assert_eq(witnessed, [])
	host.land()
	finale._process(0.016)
	assert_eq(witnessed, ["witness"])
	assert_eq(finale.phase, "restored")
	assert_false(finale.witness_restoration(body))
	finale.sync_progression()
	assert_eq(witnessed, ["witness"], "aftermath_restored emitted exactly once")
	assert_eq(host.events.count(aftermath_event), 1)
	assert_eq(networks, ["network"])
	assert_eq(relays.size(), 3)
	assert_false(flags.has("realm_key_stormwood"), "Witness still grants no reward")
	holder.free()
	host.free()
