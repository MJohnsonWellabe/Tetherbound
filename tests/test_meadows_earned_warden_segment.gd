extends "res://tests/test_case.gd"
const SEGMENT := preload("res://tests/helpers/meadows_earned_warden_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class Emitter extends Node:
	signal pulse


func test_each_entrypoint_refuses_missing_live_context_without_story_receipts() -> void:
	for method: String in ["run", "run_finale", "run_after_finale"]:
		var segment := SEGMENT.new()
		var out: Dictionary = await segment.call(method, null, null, null)
		assert_false(out.passed)
		assert_false(out.completed)
		assert_eq(out.receipts, [])
		assert_false(out.failures.is_empty())


func test_current_warden_and_machine_chain_are_the_authored_finale() -> void:
	var cfg := SEGMENT._read(SEGMENT.CLIMAX_CONFIG)
	var spec: Dictionary = SEGMENT.TRAINERS.trainer(cfg.warden.trainer)
	assert_eq(spec.id, "warden_aldis")
	assert_eq(spec.team.size(), 5)
	var levels: Array = []
	for member: Dictionary in spec.team:
		levels.append(int(member.level))
	assert_eq(levels, [18, 18, 19, 19, 20])
	assert_eq(SEGMENT.reward_items(spec.reward), {"coin": 150, "revive": 2, "potion_small": 4})
	assert_eq(SEGMENT.TRAINERS.reward_xp_bonus(spec), 400)
	assert_eq(SEGMENT.TRAINERS.reward_flags(spec), ["realm_key_cloudreach", "realm_heart_meadows_earned"])
	assert_eq(cfg.legendary.species, "veridian")
	assert_eq(int(cfg.legendary.level), 22)
	assert_eq(cfg.reveal.conversation, "stronghold_reveal")
	assert_eq(cfg.machine.chamber_conversation, "stronghold_chamber")
	assert_eq(cfg.machine.free_conversation, "stronghold_free_legendary")
	assert_eq(cfg.machine.join_conversation, "stronghold_legendary_joins")
	assert_eq(cfg.machine.failure_conversation, "stronghold_machinery_fails")
	assert_eq(SEGMENT.SEQUENCE_FRAMES, 900)
	assert_eq(SEGMENT.ARRIVAL_MSEC, 120000)


func test_automatic_dialogue_sequence_rejects_skips_duplicates_and_extra_beats() -> void:
	var expected := ["chamber", "free", "join"]
	assert_true(SEGMENT.dialogue_prefix([], expected))
	assert_true(SEGMENT.dialogue_prefix(["chamber"], expected))
	assert_true(SEGMENT.dialogue_prefix(expected, expected))
	assert_false(SEGMENT.dialogue_prefix(["free"], expected))
	assert_false(SEGMENT.dialogue_prefix(["chamber", "chamber"], expected))
	assert_false(SEGMENT.dialogue_prefix(["chamber", "join"], expected))
	assert_false(SEGMENT.dialogue_prefix(expected + ["failure"], expected))
	assert_false(SEGMENT.dialogue_prefix([], [""]))


func test_declining_pending_legendary_retains_every_owned_identity_and_clears_pending() -> void:
	var before: Array[int] = [11, 12, 13, 14, 15]
	assert_true(SEGMENT.declined_pending_receipt(before, before, 99, null))
	assert_false(SEGMENT.declined_pending_receipt(before, [11, 12, 13, 14, 99], 99, null))
	assert_false(SEGMENT.declined_pending_receipt(before, [11, 12, 13, 14, 15, 99], 99, null))
	assert_false(SEGMENT.declined_pending_receipt(before, [12, 11, 13, 14, 15], 99, null))
	assert_false(SEGMENT.declined_pending_receipt(before, before, 11, null))
	assert_false(SEGMENT.declined_pending_receipt(before, before, 0, null))
	assert_false(SEGMENT.declined_pending_receipt(before, before, 99, RefCounted.new()))
	assert_false(SEGMENT.declined_pending_receipt([11, 11, 13, 14, 15], [11, 11, 13, 14, 15], 99, null))
	var actual := CREATURE.new()
	assert_true(SEGMENT.declined_pending_receipt(before, before, actual.get_instance_id(), null),
		"Godot RefCounted instance IDs are signed and may be negative")
	assert_true(SEGMENT.declined_pending_receipt(before, before, -99, null))


func test_acknowledgement_reaches_real_kell_and_requires_his_actual_effect() -> void:
	var config := SEGMENT._read(SEGMENT.NPC_CONFIG)
	var dialogue := SEGMENT._read(SEGMENT.FREED_DIALOGUE)
	var spec := SEGMENT.acknowledgement_spec(config, dialogue)
	assert_eq(spec.name, "Kell")
	assert_eq(spec.position, [184.2, 52.6], "the actual actor has not been relocated beside Hall")
	assert_eq(spec.greeting, "spoke_traveller_storm_road")
	dialogue.conversations.spoke_traveller_storm_road.lines[0].erase("effect")
	assert_eq(SEGMENT.acknowledgement_spec(config, dialogue), {}, "missing real acknowledgement effect cannot be bypassed")


func _gate_rows(terrain: Dictionary) -> Array[Dictionary]:
	var gates: Array[Dictionary] = []
	for name: String in ["SouthBridge", "MillCrossing"]:
		var config: Dictionary = SEGMENT.INPUTS.crossing_config(terrain) if name == "SouthBridge" else SEGMENT.mill_config(terrain)
		var carve: Dictionary = config.get("carve", config.get("channel", {}))
		var centre := Vector2(carve.centre[0], carve.centre[1])
		var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.axis_deg)))
		var across := Vector2(-axis.y, axis.x)
		var start := Vector2(config.road[0][0], config.road[0][1])
		if start.distance_to(centre + across) < start.distance_to(centre - across):
			across = -across
		var bank := float(carve.half_width) + float(carve.rim) + 3.0
		gates.append({"gate": name, "near": centre - across * bank, "far": centre + across * bank})
	var transform := Transform3D(Basis(Vector3.UP, deg_to_rad(-28.6)), Vector3(63.6, 0, 7400))
	var sigil := SEGMENT.gate_crossing_points(transform, Vector2(80, 7370), Vector2(20, 7480))
	gates.append({"gate": "SigilGate", "near": sigil[0], "far": sigil[1]})
	return gates


func test_aftermath_road_uses_relay_loop_and_each_actual_safe_crossing_pair() -> void:
	var terrain := SEGMENT._read(SEGMENT.TERRAIN)
	var gates := _gate_rows(terrain)
	var road := SEGMENT.aftermath_road(terrain, gates)
	var points := SEGMENT.road_points(road)
	assert_false(points.is_empty())
	assert_eq(points[0], Vector2(8, 90), "outside the actual village boundary")
	assert_true(points.has(Vector2(340, 3810)), "use the authored Relay loop outside the compound")
	assert_false(points.has(Vector2(350, 3760)), "never draw a return chord into the compound centre")
	assert_false(points.has(Vector2(8, 1330)), "SouthBridge centre is gully ground, not a ground-projected walking target")
	for gate: Dictionary in gates:
		var entries: Array = []
		for entry: Dictionary in road:
			if str(entry.get("gate", "")) == gate.gate:
				entries.append(entry.at)
		assert_eq(entries, [gate.near, gate.far])
	var length := SEGMENT.road_length(points)
	print("EARNED AFTERMATH SOURCE ROAD metres_one_way=", length)
	assert_true(length > 11000 and length < 12000, "make the current product dead-travel cost visible")
	assert_eq(SEGMENT.aftermath_road({}, gates), [])
	assert_eq(SEGMENT.aftermath_road(terrain, []), [])
	var absent := gates.duplicate(true)
	absent[2].near += Vector2(0, 10000)
	absent[2].far += Vector2(0, 10000)
	assert_eq(SEGMENT.aftermath_road(terrain, absent), [], "do not silently miss a relocated required gate")
	var storm := SEGMENT.storm_road(terrain)
	assert_eq(storm[0], Vector2(0, 7000))
	assert_eq(storm[-1], Vector2(-33.99, 7513.46))
	assert_eq(SEGMENT.storm_road({}), [])


func test_rift_requires_live_enabled_collision_and_observes_exact_player_identity() -> void:
	var body := StaticBody3D.new()
	assert_false(SEGMENT.enabled_collision(body))
	var shape := CollisionShape3D.new()
	body.add_child(shape)
	assert_false(SEGMENT.enabled_collision(body))
	shape.shape = BoxShape3D.new()
	assert_true(SEGMENT.enabled_collision(body))
	shape.disabled = true
	assert_false(SEGMENT.enabled_collision(body))
	var segment := SEGMENT.new()
	var player := CharacterBody3D.new()
	var other := CharacterBody3D.new()
	segment._crossing_player_id = player.get_instance_id()
	segment._on_rift_entered(other)
	assert_eq(segment._rift_crossings, 0)
	segment._on_rift_entered(player)
	assert_eq(segment._rift_crossings, 1)
	body.free()
	player.free()
	other.free()


func test_scene_transition_cleanup_handles_destroyed_outgoing_signal_owners() -> void:
	var segment := SEGMENT.new()
	var dead := Emitter.new()
	var live := Emitter.new()
	var heard := [0]
	var callback := func() -> void: heard[0] += 1
	segment._watch(dead, "pulse", callback)
	segment._watch(live, "pulse", callback)
	live.pulse.emit()
	assert_eq(heard[0], 1)
	dead.free()
	segment._disconnect_watches()
	assert_eq(segment._connections, [])
	live.pulse.emit()
	assert_eq(heard[0], 1, "remaining live observers are disconnected too")
	live.free()
