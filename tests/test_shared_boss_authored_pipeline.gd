extends "res://tests/test_case.gd"

## The original smoke owns transport timing and rendered bodies. These cases
## cover the previously missing authored-NPC -> strict codec -> host record ->
## director callback -> manager lifetime path. Only visual body setup is a double.
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const HOST := preload("res://scripts/net/encounter_host.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const FIXTURE := preload("res://tests/test_stormwood_hosted_combat.gd")


class DirectorShell extends DIRECTOR:
	var submitted: Array[Dictionary] = []

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func _local_peer_id() -> int:
		return 2

	func submit_encounter_intent(intent: Dictionary) -> Dictionary:
		submitted.append(intent.duplicate(true))
		return {"ok": true}


class MirrorBody extends Node3D:
	var instance: RefCounted
	var body_generation := 1
	var last_pose_seq := 0

	func configure_presentation(card: RefCounted, generation: int, feet: Vector3,
			_facing: Vector3, _half_life: float) -> bool:
		instance = card
		body_generation = generation
		global_position = feet
		return true

	func apply_pose(generation: int, sequence: int, _feet: Vector3, _facing: Vector3) -> bool:
		if generation != body_generation or sequence <= last_pose_seq:
			return false
		last_pose_seq = sequence
		return true


func _warden_team() -> Array:
	return TRAINER.team_of(TRAINER.trainer("warden_aldis"))


func test_all_authored_warden_cards_preserve_identity_moves_and_stats() -> void:
	var team := _warden_team()
	assert_eq(team.size(), 5, "use the actual authored full roster")
	for entry: Dictionary in team:
		var original := TRAINER.creature_for(entry)
		var wire := CODEC.encode(original)
		assert_false(wire.is_empty(), "authored equipped moves must pass strict preflight")
		assert_eq(wire.get("uid"), original.uid)
		assert_eq(wire.get("move_quick"), original.move_quick)
		assert_eq(wire.get("move_charged"), original.move_charged)
		var decoded := CODEC.decode(wire)
		assert_true(decoded != null, "the actual owned codec reconstructs the whole card")
		if decoded == null:
			continue
		assert_eq(decoded.uid, original.uid)
		assert_eq(decoded.move_quick, original.move_quick)
		assert_eq(decoded.move_charged, original.move_charged)
		assert_eq(decoded.known_moves, original.known_moves)
		assert_eq(decoded.max_hp, original.max_hp)
		assert_eq(decoded.attack, original.attack)
		assert_eq(decoded.defence, original.defence)
	# Registering authored knowledge does not relax the codec's owned preflight.
	var invalid := TRAINER.creature_for(team[0])
	invalid.known_moves.erase(invalid.move_quick)
	assert_true(CODEC.encode(invalid).is_empty(), "unknown equipped moves still refuse")
	var wrong_slot := TRAINER.creature_for(team[0])
	wrong_slot.move_charged = wrong_slot.move_quick
	assert_true(CODEC.encode(wrong_slot).is_empty(), "known moves in the wrong slot still refuse")


func test_authored_charged_override_is_known_without_duplicate_defaults() -> void:
	var original := TRAINER.creature_for({"species": "burrowback", "level": 18,
		"moves": {"quick": "burrow_strike", "charged": "stone_rush"}})
	assert_eq(original.known_moves.count("burrow_strike"), 1, "an existing authored move stays unique")
	assert_eq(original.known_moves.count("stone_rush"), 1, "a charged override is also knowledge")
	assert_eq(original.move_mastery_uses, {}, "construction grants no mastery uses")
	assert_false(CODEC.encode(original).is_empty(), "strict preflight supports either authored slot")


func _opponent(creature: RefCounted, round_number: int) -> Dictionary:
	return {"species_id": creature.species_id, "level": creature.level,
		"hp": creature.hp, "hp_max": creature.max_hp, "owner_npc": "warden_aldis",
		"card": CODEC.encode(creature), "round": round_number, "round_continues": true,
		"position": [4.0, 0.0, 5.0], "foot_position": [4.0, 0.0, 5.0],
		"facing": [0.0, 0.0, 1.0]}


func _case_authored_warden_record_pipeline() -> void:
	for gap: float in [0.01, 10.0]:
		var team := _warden_team()
		var first := TRAINER.creature_for(team[0])
		var second := TRAINER.creature_for(team[1])
		var first_row := _opponent(first, 1)
		var second_row := _opponent(second, 2)
		assert_false(first_row.card.is_empty(), "the real first authored card is transmitted")
		assert_false(second_row.card.is_empty(), "the real next authored card is transmitted")
		assert_false(first.uid == second.uid, "distinct actual NPC creatures")
		var host := HOST.new()
		var rec: Dictionary = host.open(1, "meadows", "boss", first_row)
		var id := str(rec.encounter_id)
		assert_true(bool(host.join(id, 2).get("ok", false)))
		var fixture := FIXTURE.new()
		var manager: Node = fixture._shared_round_manager()
		var director := DirectorShell.new()
		manager.add_child(director)
		director.set("_manager", manager)
		var old_body: Node = manager.get("_wild")
		old_body.free()
		var body := MirrorBody.new()
		manager.add_child(body)
		var mirror: RefCounted = director._legacy_opponent_instance(rec.opponent)
		assert_true(mirror != null)
		if mirror == null:
			manager.free()
			continue
		body.instance = mirror
		manager.set("_wild", body)
		manager.set("_enemy", mirror)
		manager.bind_encounter(director, id, "boss")
		director.set("_legacy_mirror", body)
		director.set("_engaged_with", body)
		director.set("_legacy_mirror_key", DIRECTOR._legacy_opponent_key(rec.opponent))
		assert_eq(mirror.uid, first.uid, "actual codec prevents a fallback UID")
		director._rpc_encounter_record(rec.duplicate(true))
		assert_eq(manager.get("_shared_trainer_round"), 1, "the real wire card arms continuation")
		host.set_opponent_hp(id, 0.0, first.max_hp)
		host.set_phase(id, "done")
		var done: Dictionary = host.record(id).duplicate(true)
		director._rpc_encounter_record(done)
		manager.call("_physics_process", gap)
		assert_true(manager.is_networked(), "both arrival gaps preserve admission")
		assert_true(manager.is_fighting(), "the actual authored card preserves the mirror")
		assert_eq(director.submitted, [], "no premature disengage")
		assert_eq(manager.active_creature().battles_fought, 1)
		host.set_phase(id, "active")
		assert_true(host.set_opponent(id, second_row))
		var next: Dictionary = host.record(id).duplicate(true)
		director._rpc_encounter_record(next)
		assert_eq(manager.enemy().uid, second.uid, "director installed the next host UID")
		assert_eq(body.instance.uid, second.uid, "manager and body refer to the same host card")
		assert_eq(manager.enemy().move_quick, "wind_blade", "actual authored move survived")
		assert_eq(int(manager.get("state")), FIXTURE.SHARED_MANAGER.State.ACTIVE)
		assert_eq(body.body_generation, 2, "the real refresh callback reconfigured the body")
		assert_eq(body.last_pose_seq, 0, "next generation does not retain old pose sequence")
		assert_eq(manager.get("_wild"), body)
		assert_eq(manager.get("_encounter_id"), id)
		assert_eq(manager.get("_party_wind"), [37.0], "no round refill")
		director._rpc_encounter_record(done)
		assert_eq(manager.enemy().uid, second.uid, "late first-round record cannot reinstall it")
		assert_eq(manager.enemy().hp, second.hp, "late first-round HP cannot overwrite next card")
		director._rpc_encounter_record(next)
		assert_eq(body.body_generation, 2, "duplicate current record cannot reconfigure")
		host.set_opponent_hp(id, 0.0, second.max_hp)
		host.close(id)
		director._rpc_encounter_record(host.record(id).duplicate(true))
		manager.call("_physics_process", 10.0)
		assert_false(manager.is_networked(), "actual host close releases the wait")
		assert_false(manager.is_fighting(), "normal final cleanup still completes")
		assert_eq(director.submitted.size(), 1, "one final disengage")
		assert_eq(manager.active_creature().battles_fought, 2, "one award per actual card")
		manager.free()


func test_native_authored_warden_record_pipeline() -> void:
	# Deferred child is required because run_tests executes inside SceneTree._init.
	var runner_path := "user://shared_boss_authored_pipeline_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar script = load("res://tests/test_shared_boss_authored_pipeline.gd")\n\tif script == null or not script.can_instantiate():\n\t\tquit(1)\n\t\treturn\n\tvar test = script.new()\n\ttest._case_authored_warden_record_pipeline()\n\tprint("SHARED_BOSS_AUTHORED_PIPELINE_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == 56 else 1)\n')
	runner.close()
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://shared-boss-authored-pipeline-child.log")
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(log_path)
	var process := OS.execute_with_pipe(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], false)
	var pid := int(process.get("pid", -1))
	assert_true(pid > 0, "the deferred native child must start")
	if pid <= 0:
		DirAccess.remove_absolute(absolute)
		return
	var fixture := FIXTURE.new()
	var buffers := {"stdio": PackedByteArray(), "stderr": PackedByteArray()}
	var deadline := Time.get_ticks_msec() + 60000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
		fixture._drain_shared_lifetime_pipes(process, buffers)
		OS.delay_msec(10)
	var timed_out := OS.is_process_running(pid)
	if timed_out:
		OS.kill(pid)
		var kill_deadline := Time.get_ticks_msec() + 2000
		while OS.is_process_running(pid) and Time.get_ticks_msec() < kill_deadline:
			fixture._drain_shared_lifetime_pipes(process, buffers)
			OS.delay_msec(10)
	var running := OS.is_process_running(pid)
	var code := OS.get_process_exit_code(pid)
	fixture._drain_shared_lifetime_pipes(process, buffers)
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
		if line.begins_with("SHARED_BOSS_AUTHORED_PIPELINE_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("SHARED_BOSS_AUTHORED_PIPELINE_RESULT="))
			if parsed is Dictionary:
				result = parsed
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(int(result.get("assertions", 0)), 56, "both complete authored pipeline schedules")
	var native_log := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	assert_true(not native_log.is_empty(), "the child must retain its native log")
	combined += "\n" + native_log
	assert_false(combined.contains("ERROR:"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)
