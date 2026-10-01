extends "res://tests/test_case.gd"

## Host-owned Stormwood fights have two seams that must stay independent of
## rendering: changing which participant is nearest must not restart the
## opponent's current attack, and the local party must receive one victory
## award when the hosted award hook and host's done record arrive in either
## order. Two-process smoke covers the killing-verdict delivery path itself.

const HOST_FIGHT := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const STORMWOOD_MANAGER := preload("res://scripts/combat/stormwood_combat_manager.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


class HostedTransport extends Node:
	func hosted_transport() -> bool:
		return true


class FightBody extends Node3D:
	var engaged := true

	func set_engaged(value: bool, _opponent: Node3D = null) -> void:
		engaged = value


class ThrowStub extends Node:
	func disarm() -> void:
		pass


func _creature(level: int, nickname: String) -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.level = level
	creature.nickname = nickname
	return creature


func _hosted_manager(encounter_id: String, party: Array[RefCounted], enemy: RefCounted) -> Node:
	var manager := STORMWOOD_MANAGER.new()
	manager.set("_party", party)
	manager.set("_active_index", 0)
	manager.set("_enemy", enemy)
	# A done record normally begins resolution. These tests exercise the
	# already-authoritative award seam without requiring a rendered arena.
	manager.set("state", STORMWOOD_MANAGER.State.RESOLVING)
	var transport := HostedTransport.new()
	manager.add_child(transport)
	manager.bind_encounter(transport, encounter_id, "trainer")
	return manager


func _active_manager(enemy_owned: bool) -> Node:
	var manager := STORMWOOD_MANAGER.new()
	manager.set("state", STORMWOOD_MANAGER.State.ACTIVE)
	manager.set("_enemy_owned", enemy_owned)
	var body := FightBody.new()
	manager.set("_wild", body)
	manager.add_child(body)
	var throw := ThrowStub.new()
	manager.set("_throw", throw)
	manager.add_child(throw)
	return manager


func _killing_done_record(encounter_id: String, seq: int) -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"seq": seq,
		"phase": "done",
		"opponent": {"hp": 0.0, "hp_max": 100.0},
	}


func test_host_retarget_changes_the_body_without_restarting_an_active_windup() -> void:
	var engine := HOST_FIGHT.new()
	var opponent := WILD.new()
	var first_target := Node3D.new()
	var nearer_target := Node3D.new()
	engine.set("_wild", opponent)
	engine.set("_ally_body", first_target)
	# These are the live AI's attack clocks. A call to set_engaged() would reset
	# them, which lets players indefinitely suppress a swing by swapping nearest.
	opponent.set("_opponent", first_target)
	opponent.set("_intent", 2)
	opponent.set("_beat_left", 0.42)
	opponent.set("_cooldown", 0.87)

	engine.set_target_body(nearer_target)

	assert_eq(engine.get("_ally_body"), nearer_target,
		"the host engine should point its hit selection at the newly nearest body")
	assert_eq(opponent.get("_opponent"), nearer_target,
		"the wild body should face the newly selected participant")
	assert_eq(int(opponent.get("_intent")), 2,
		"retargeting must leave the wind-up intent in progress")
	assert_almost_eq(float(opponent.get("_beat_left")), 0.42, 0.0001,
		"retargeting must not restart the current wind-up clock")
	assert_almost_eq(float(opponent.get("_cooldown")), 0.87, 0.0001,
		"retargeting must not reset the next-attack cooldown")

	opponent.free()
	first_target.free()
	nearer_target.free()
	engine.free()


func test_hosted_admission_yields_only_a_fleeable_wild_fight() -> void:
	var wild_manager := _active_manager(false)
	var wild_body: FightBody = wild_manager.get("_wild")
	assert_true(wild_manager.yield_wild_fight_for_hosted_trainer(),
		"host admission should win a race with an aggressive local wild")
	assert_false(wild_manager.is_fighting(),
		"the yielded wild must release CombatManager for the hosted round")
	assert_false(wild_body.engaged,
		"yielding must disengage the local wild through normal combat cleanup")
	wild_manager.free()

	var trainer_manager := _active_manager(true)
	var trainer_body: FightBody = trainer_manager.get("_wild")
	assert_false(trainer_manager.yield_wild_fight_for_hosted_trainer(),
		"host admission must never tear down an existing trainer fight")
	assert_true(trainer_manager.is_fighting(),
		"a protected trainer fight must remain active")
	assert_true(trainer_body.engaged,
		"a protected trainer opponent must remain engaged")
	trainer_manager.free()


func test_hosted_award_hook_awards_once_when_called_before_done_record() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy"))

	# The hosted award hook can run before the record, and that record can be
	# delivered twice by the session transport.
	manager.call("_award_victory")
	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	manager.apply_encounter_record(_killing_done_record("round-a", 1))

	assert_eq(winner.battles_fought, 1,
		"award hook then duplicate done snapshots must credit one completed fight")
	manager.free()


func test_hosted_award_hook_awards_once_when_done_record_arrives_first() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy"))

	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	manager.call("_award_victory")
	manager.apply_encounter_record(_killing_done_record("round-a", 2))

	assert_eq(winner.battles_fought, 1,
		"done record then hosted award hook must still credit one completed fight")
	manager.free()


func test_a_new_hosted_round_resets_the_one_award_guard() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy A"))

	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	var transport := HostedTransport.new()
	manager.add_child(transport)
	manager.bind_encounter(transport, "round-b", "trainer")
	manager.set("_enemy", _creature(4, "Enemy B"))
	manager.apply_encounter_record(_killing_done_record("round-b", 1))
	manager.apply_encounter_record(_killing_done_record("round-b", 1))

	assert_eq(winner.battles_fought, 2,
		"a fresh bound round must award once after the previous round's guard fired")
	manager.free()


class SharedRoundTransport extends Node:
	var intents: Array[Dictionary] = []

	func local_encounter_peer_id() -> int:
		return 2

	func submit_encounter_intent(intent: Dictionary) -> Dictionary:
		intents.append(intent.duplicate(true))
		return {"ok": true}


const SHARED_MANAGER := preload("res://scripts/combat/combat_manager.gd")


func _shared_round_manager(kind: String = "boss") -> Node:
	var manager := SHARED_MANAGER.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	manager.set_physics_process(false)
	manager.set("_party", [_creature(3, "Guest")] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("_enemy", _creature(4, "First"))
	manager.set("_party_wind", [37.0] as Array[float])
	manager.set("_realm_owned_opponent", true)
	manager.set("state", SHARED_MANAGER.State.ACTIVE)
	var body := FightBody.new()
	manager.add_child(body)
	manager.set("_wild", body)
	var throw := ThrowStub.new()
	manager.add_child(throw)
	manager.set("_throw", throw)
	var transport := SharedRoundTransport.new()
	manager.add_child(transport)
	manager.bind_encounter(transport, "shared-boss", kind)
	return manager


func _shared_round_record(manager: Node, seq: int, round_number: int,
		continues: Variant, done: bool = false) -> Dictionary:
	return {
		"encounter_id": "shared-boss", "seq": seq,
		"phase": "done" if done else "active",
		"opponent": {
			"round": round_number, "round_continues": continues,
			"card": {"uid": manager.get("_enemy").get("uid")},
			"hp": 0.0 if done else 100.0, "hp_max": 100.0,
		},
	}


func _case_shared_boss_guest_survives_next_round_before_and_after_faint_pause() -> void:
	# Exercise both transport schedules with the real manager's record, award,
	# resolve and finish methods. The two-process smoke owns real RPC timing.
	for gap: float in [0.01, 10.0]:
		for kind: String in ["boss", "trainer"]:
			var manager := _shared_round_manager(kind)
			var body: Node3D = manager.get("_wild")
			var transport: SharedRoundTransport = manager.get("_encounter_link")
			var winner: RefCounted = manager.active_creature()
			manager.apply_encounter_record(_shared_round_record(manager, 1, 1, true))
			var first_done := _shared_round_record(manager, 2, 1, true, true)
			manager.apply_encounter_record(first_done)
			manager.call("_physics_process", gap)
			assert_true(manager.is_networked(), "the inter-round gap retains admission")
			assert_true(manager.is_fighting(), "the inter-round gap retains presentation")
			assert_eq(transport.intents.size(), 0, "a queued opponent is not a disengage")
			assert_eq(winner.battles_fought, 1, "the first kill credits one round")

			# This is the director's existing mirror-card installation seam.
			manager.set("_enemy", _creature(4, "Second"))
			manager.apply_encounter_record(_shared_round_record(manager, 3, 2, false))
			assert_eq(int(manager.get("state")), SHARED_MANAGER.State.ACTIVE, "the installed next card resumes input")
			assert_eq(manager.get("_wild"), body, "the admitted mirror body survives")
			assert_eq(manager.get("_encounter_id"), "shared-boss", "one encounter spans rounds")
			assert_eq(manager.get("_party_wind"), [37.0], "a round swap does not refill Wind")
			manager.apply_encounter_record(first_done)
			assert_eq(int(manager.get("state")), SHARED_MANAGER.State.ACTIVE, "an older killing record cannot end round two")
			assert_eq(float(manager.enemy().hp), 100.0, "an older record cannot rewrite new HP")
			var final_done := _shared_round_record(manager, 4, 2, false, true)
			manager.apply_encounter_record(final_done)
			manager.apply_encounter_record(final_done)
			manager.call("_physics_process", 10.0)
			assert_false(manager.is_fighting(), "the final opponent uses normal finish")
			assert_false(manager.is_networked(), "the final opponent releases admission")
			assert_eq(transport.intents.size(), 1, "final cleanup submits one disengage")
			assert_eq(winner.battles_fought, 2, "each opponent awards once, including duplicates")
			manager.free()


func _case_shared_round_wait_requires_host_boolean_and_matching_card() -> void:
	for marker: Variant in [false, "true", null]:
		var manager := _shared_round_manager()
		manager.apply_encounter_record(_shared_round_record(manager, 1, 1, marker, true))
		manager.call("_physics_process", 10.0)
		assert_false(manager.is_fighting(), "unpromised continuation finishes normally")
		manager.free()
	var manager := _shared_round_manager()
	var mismatched := _shared_round_record(manager, 1, 1, true, true)
	mismatched["opponent"]["card"]["uid"] = "other-body"
	manager.apply_encounter_record(mismatched)
	manager.call("_physics_process", 10.0)
	assert_false(manager.is_fighting(), "an uninstalled card cannot retain this body")
	manager.free()


func _case_shared_round_terminal_close_and_disconnect_release_the_wait() -> void:
	for disconnect: bool in [false, true]:
		var manager := _shared_round_manager()
		manager.apply_encounter_record(_shared_round_record(manager, 1, 1, true, true))
		manager.call("_physics_process", 10.0)
		assert_true(manager.is_fighting(), "the guest waits for the promised opponent")
		if disconnect:
			var other_body := FightBody.new()
			assert_false(manager.end_shared_opponent_presentation(other_body),
				"another body's withdrawal cannot release the admitted fight")
			other_body.free()
			assert_true(manager.end_shared_opponent_presentation(manager.get("_wild")),
				"disconnect releases the actual presentation body")
		else:
			manager.apply_encounter_record(_shared_round_record(manager, 2, 1, false, true))
		manager.call("_physics_process", 10.0)
		assert_false(manager.is_fighting(), "withdrawal cannot leave an indefinite wait")
		manager.free()


func _case_shared_round_loss_flee_and_wild_keep_normal_finish() -> void:
	for outcome: String in ["lost", "fled"]:
		var manager := _shared_round_manager()
		manager.apply_encounter_record(_shared_round_record(manager, 1, 1, true))
		manager.call("_begin_resolve", outcome)
		manager.call("_physics_process", 10.0)
		assert_false(manager.is_fighting(), "a non-winning guest still leaves normally")
		manager.free()
	var manager := _shared_round_manager("wild")
	manager.apply_encounter_record(_shared_round_record(manager, 1, 1, true, true))
	manager.call("_physics_process", 10.0)
	assert_false(manager.is_fighting(), "wild presentation never waits for trainer rounds")
	manager.free()
	var host_manager := _shared_round_manager()
	host_manager.set("_realm_owned_opponent", false)
	host_manager.apply_encounter_record(_shared_round_record(host_manager, 1, 1, true, true))
	host_manager.call("_physics_process", 10.0)
	assert_false(host_manager.is_fighting(), "the host's simulated round keeps its normal exit")
	host_manager.free()


func test_host_round_continuation_survives_normalisation_and_terminal_close() -> void:
	var host := preload("res://scripts/net/encounter_host.gd").new()
	var rec: Dictionary = host.open(1, "meadows", "boss", {
		"species_id": "terrapup", "hp": 100.0, "hp_max": 100.0,
		"round": 1, "round_continues": true,
	})
	assert_eq(rec["opponent"].get("round_continues"), true,
		"the host's queue promise survives the opponent metadata whitelist")
	host.close(str(rec["encounter_id"]))
	assert_eq(host.record(str(rec["encounter_id"]))["opponent"].get("round_continues"), false,
		"terminal closure withdraws the promise even when the queue was nonempty")


func _drain_shared_lifetime_pipes(process: Dictionary, buffers: Dictionary) -> void:
	for key: String in ["stdio", "stderr"]:
		var pipe: FileAccess = process.get(key)
		if pipe == null:
			continue
		# Nonblocking pipes; bound each drain so output cannot starve the deadline.
		for _chunk in 16:
			var bytes := pipe.get_buffer(65536)
			if bytes.is_empty():
				break
			var retained: PackedByteArray = buffers[key]
			retained.append_array(bytes)
			buffers[key] = retained


func test_native_shared_boss_guest_round_lifetime_and_cleanup() -> void:
	# run_tests executes during SceneTree._init, before a main loop exists.
	# Use the same deferred native-child seam as the director transport cases.
	var runner_path := "user://shared_boss_round_lifetime_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar script = load("res://tests/test_stormwood_hosted_combat.gd")\n\tif script == null or not script.can_instantiate():\n\t\tquit(1)\n\t\treturn\n\tvar test = script.new()\n\ttest._case_shared_boss_guest_survives_next_round_before_and_after_faint_pause()\n\ttest._case_shared_round_wait_requires_host_boolean_and_matching_card()\n\ttest._case_shared_round_terminal_close_and_disconnect_release_the_wait()\n\ttest._case_shared_round_loss_flee_and_wild_keep_normal_finish()\n\tprint("SHARED_BOSS_LIFETIME_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 70 else 1)\n')
	runner.close()
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://shared-boss-round-lifetime-child.log")
	# Clear a former child's log so a failed launch cannot consume stale proof.
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(log_path)
	var process := OS.execute_with_pipe(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], false)
	var pid := int(process.get("pid", -1))
	assert_true(pid > 0, "the deferred native child must start")
	if pid <= 0:
		DirAccess.remove_absolute(absolute)
		return
	var buffers := {"stdio": PackedByteArray(), "stderr": PackedByteArray()}
	# This new focused regression has its own finite cap; original smoke caps stay unchanged.
	var deadline := Time.get_ticks_msec() + 60000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
		_drain_shared_lifetime_pipes(process, buffers)
		OS.delay_msec(10)
	var timed_out := OS.is_process_running(pid)
	if timed_out:
		OS.kill(pid)
		var kill_deadline := Time.get_ticks_msec() + 2000
		while OS.is_process_running(pid) and Time.get_ticks_msec() < kill_deadline:
			_drain_shared_lifetime_pipes(process, buffers)
			OS.delay_msec(10)
	var running := OS.is_process_running(pid)
	var code := OS.get_process_exit_code(pid)
	_drain_shared_lifetime_pipes(process, buffers)
	for key: String in ["stdio", "stderr"]:
		var pipe: FileAccess = process.get(key)
		if pipe != null:
			pipe.close()
	DirAccess.remove_absolute(absolute)
	var stdout_bytes: PackedByteArray = buffers["stdio"]
	var stderr_bytes: PackedByteArray = buffers["stderr"]
	var combined := stdout_bytes.get_string_from_utf8() + "\n" + stderr_bytes.get_string_from_utf8()
	assert_false(timed_out, "the deferred child exceeded its 60-second cap\n" + combined)
	assert_false(running, "the deferred child must be gone after cleanup")
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("SHARED_BOSS_LIFETIME_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("SHARED_BOSS_LIFETIME_RESULT="))
			if parsed is Dictionary:
				result = parsed
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(int(result.get("assertions", 0)), 70, "all original lifecycle assertions must finish")
	var native_log := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	assert_true(not native_log.is_empty(), "the child must retain its native log")
	combined += "\n" + native_log
	assert_false(combined.contains("ERROR:"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)
