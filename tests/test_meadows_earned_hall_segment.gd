extends "res://tests/test_case.gd"
const SEGMENT := preload("res://tests/helpers/meadows_earned_hall_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const COMBAT := preload("res://scripts/combat/combat_manager.gd")

class FacingBody extends Node3D:
	var at := Vector3.ZERO
	var forward := Vector3.FORWARD
	var impulses: Array[Vector3] = []
	var attacks := 0
	func centre() -> Vector3: return at
	func face_towards(target: Vector3) -> void: forward = (target - at).normalized()
	func facing() -> Vector3: return forward
	func add_impulse(direction: Vector3, _strength: float) -> void: impulses.append(direction)
	func play_attack() -> void: attacks += 1


func test_production_quick_start_faces_backward_body_without_a_preparatory_turn() -> void:
	var manager := COMBAT.new()
	var ally := FacingBody.new()
	var foe := FacingBody.new()
	foe.at = Vector3(0, 0, 2)
	manager._ally_body = ally
	manager._wild = foe
	assert_true(ally.forward.dot(foe.at.normalized()) < 0.0, "control begins facing away")
	assert_true(manager.quick_ready())
	manager._begin_move_presentation({"slot": "quick", "windup": 0.18, "recovery": 0.22, "cooldown": 0.4, "lunge": 3.6})
	assert_eq(ally.forward, Vector3.BACK, "ordinary accepted start faces the target immediately")
	assert_eq(ally.impulses, [Vector3.BACK], "production lunge follows its accepted facing")
	assert_eq(ally.attacks, 1)
	assert_false(manager.quick_ready(), "accepted windup remains committed")
	foe.at = Vector3(2, 0, 0)
	manager._tick_action(0.0)
	assert_eq(ally.forward, Vector3.RIGHT, "production keeps tracking during windup")
	assert_eq(ally.attacks, 1, "tracking does not start a second attack")
	manager.free()
	ally.free()
	foe.free()


func test_host_accepted_charged_start_uses_the_same_production_turn_and_commitment() -> void:
	var manager := COMBAT.new()
	var ally := FacingBody.new()
	var foe := FacingBody.new()
	foe.at = Vector3(0, 0, 2)
	manager._ally_body = ally
	manager._wild = foe
	var before := Time.get_ticks_msec()
	manager._begin_move_presentation({"slot": "charged", "accepted_action": 1, "windup": 0.55, "recovery": 0.5, "cooldown": 1.2, "lunge": 6.0})
	assert_eq(ally.forward, Vector3.BACK, "host acceptance faces the target through the same production path")
	assert_eq(ally.impulses, [Vector3.BACK])
	assert_true(manager.player_is_committed(), "the pilot still cannot cancel an accepted windup")
	assert_false(manager.quick_ready())
	assert_true(manager._accepted_strike_not_before_ms >= before + 550, "production keeps the host's original real-time strike fence")
	manager.free()
	ally.free()
	foe.free()


class Director extends Node:
	var trainer := "captain_riverwatch"
	func trainer_battle_id() -> String:
		return trainer

class Combat extends Node:
	var creature: RefCounted
	func enemy() -> RefCounted:
		return creature


func test_captain_xp_requires_exact_awards_below_cap_and_discards_only_cap_overflow() -> void:
	var before := {1: 100, 2: 950, 3: 1000, 4: 300, 5: 700}
	var awarded := {1: 120, 2: 120, 3: 120, 4: 0, 5: 42}
	var caps := {1: 1000, 2: 1000, 3: 1000, 4: 1000, 5: 1000}
	var after := {1: 220, 2: 1000, 3: 1000, 4: 300, 5: 742}
	assert_true(SEGMENT.exact_capped_captain_xp(before, after, awarded, caps))
	for id: int in before:
		var wrong := after.duplicate()
		wrong[id] += 1
		assert_false(SEGMENT.exact_capped_captain_xp(before, wrong, awarded, caps), "even one extra banked XP fails")
		wrong[id] = int(after[id]) - 1
		assert_false(SEGMENT.exact_capped_captain_xp(before, wrong, awarded, caps), "even one lost banked XP fails")
	var missing := caps.duplicate()
	missing.erase(5)
	assert_false(SEGMENT.exact_capped_captain_xp(before, after, awarded, missing))
	var negative := awarded.duplicate()
	negative[4] = -1
	assert_false(SEGMENT.exact_capped_captain_xp(before, after, negative, caps))
	var behind_cap := caps.duplicate()
	behind_cap[3] = 999
	assert_false(SEGMENT.exact_capped_captain_xp(before, after, awarded, behind_cap))


func test_cap_oracle_matches_production_gain_xp_for_capped_and_crossing_creatures() -> void:
	var cfg: Dictionary = SEGMENT.PROGRESSION.config().duplicate(true)
	cfg.level.cap = 20
	var before := {}
	var after := {}
	var awards := {}
	var caps := {}
	var cap_total := SEGMENT.total_xp(20, 0, cfg)
	for id in range(1, 6):
		var member: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
		# Detached unit creatures use their supplied cap, exactly as the
		# production method documents; they never join the real owned party.
		member.level = 20 if id <= 2 else 19
		member.xp = 0 if id <= 2 else SEGMENT.PROGRESSION.xp_to_next(19, cfg) - 10
		before[id] = SEGMENT.total_xp(member.level, member.xp, cfg)
		awards[id] = 120 if id != 5 else 0
		caps[id] = cap_total
		member.gain_xp(awards[id], cfg)
		after[id] = SEGMENT.total_xp(member.level, member.xp, cfg)
	assert_true(SEGMENT.exact_capped_captain_xp(before, after, awards, caps), "actual gain_xp must satisfy the exact admitted-cap bank model")
	assert_eq(after[1], before[1], "already capped creatures gain no banked XP")
	assert_eq(after[3] - before[3], 10, "crossing the cap discards only overflow")
	assert_eq(after[5], before[5], "zero awards do not manufacture XP")


func test_missing_context_cannot_claim_hall_progress() -> void:
	var observed: Dictionary = await SEGMENT.new().run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_false(observed.failures.is_empty())


func test_authored_foot_spine_visits_captains_in_order_then_the_sigil_gate() -> void:
	var terrain := SEGMENT._read(SEGMENT.TERRAIN)
	var road := SEGMENT.departure_spine(terrain)
	assert_eq(road[0], Vector2(-152, 4235), "begin beyond the paid Mill crossing")
	assert_eq(road[-1], Vector2(0, 7560))
	var previous := -1
	for id: String in SEGMENT.CAPTAIN_IDS:
		var spec: Dictionary = SEGMENT.TRAINERS.trainer(id)
		var position := Vector2(spec.position[0], spec.position[1])
		var at := SEGMENT.nearest_index(road, position)
		assert_true(at > previous)
		assert_eq(road[at], position, "actual captain lies on the authored spine")
		previous = at
	assert_true(SEGMENT.nearest_index(road, Vector2(63.6, 7400)) > previous)
	assert_eq(SEGMENT.departure_spine({}), [])
	var broken := terrain.duplicate(true)
	for row: Dictionary in broken.trail.bands:
		if row.id == "band4_upper_meadows_ironwood":
			row.points[0] = [99, 99]
	assert_eq(SEGMENT.departure_spine(broken), [], "do not silently bridge disconnected road bands")


func test_gauntlet_resolves_current_trainers_and_requires_each_owned_shutter() -> void:
	var config := SEGMENT._read(SEGMENT.HALL_CONFIG)
	var stages := SEGMENT.gauntlet_path(config)
	assert_eq(stages.size(), 3)
	assert_eq([stages[0].trainer, stages[1].trainer, stages[2].trainer],
		["stronghold_patrol", "stronghold_courtyard", "stronghold_elite"])
	assert_eq([stages[0].from, stages[1].from, stages[2].from], ["outer_works", "courtyard", "tether_approach"])
	assert_eq(stages[-1].to, "warden_arena", "the Warden and legendary chamber remain subsequent work")
	for index in 3:
		var missing := config.duplicate(true)
		missing.passages[index].erase("gated_by_flag")
		assert_eq(SEGMENT.gauntlet_path(missing), [], "missing passage lock must fail: " + str(index))
		var wrong_guard := config.duplicate(true)
		wrong_guard.gauntlet[index].trainer = "warden_aldis"
		assert_eq(SEGMENT.gauntlet_path(wrong_guard), [], "a different guard cannot unlock this chamber")
	assert_eq(SEGMENT.gauntlet_path({}), [])


func test_three_sigil_spend_is_exact_and_needs_actual_disabled_leaf() -> void:
	var before := {"field_sigil": 1, "ridge_sigil": 1, "river_sigil": 1}
	var after := {"field_sigil": 0, "ridge_sigil": 0, "river_sigil": 0}
	assert_true(SEGMENT.sigil_paid_receipt(before, after, true, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, before, true, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, false, true, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, true, false, true))
	assert_false(SEGMENT.sigil_paid_receipt(before, after, true, true, false))
	for id: String in SEGMENT.SIGILS:
		var unspent := after.duplicate()
		unspent[id] = 1
		assert_false(SEGMENT.sigil_paid_receipt(before, unspent, true, true, true))
		var preowned := before.duplicate()
		preowned[id] = 2
		assert_false(SEGMENT.sigil_paid_receipt(preowned, after, true, true, true))
	assert_true(SEGMENT.keys_match(["river_sigil", "ridge_sigil", "field_sigil"]))
	assert_false(SEGMENT.keys_match(["river_sigil", "river_sigil", "field_sigil"]))
	assert_false(SEGMENT.keys_match(["field_sigil"]))
	var rewarded := {}
	for id: String in SEGMENT.CAPTAIN_IDS:
		var items := SEGMENT.reward_items(SEGMENT.TRAINERS.trainer(id).reward)
		for key: String in SEGMENT.SIGILS:
			if items.has(key):
				rewarded[key] = int(rewarded.get(key, 0)) + int(items[key])
	assert_eq(rewarded, before, "the three current captains really pay exactly these gate keys")


func test_gate_waypoints_follow_live_rotation_and_require_opposite_road_sides() -> void:
	var at := Transform3D(Basis(Vector3.UP, deg_to_rad(-28.6)), Vector3(63.6, 8, 7400))
	var points := SEGMENT.gate_crossing_points(at, Vector2(80, 7370), Vector2(20, 7480))
	assert_eq(points.size(), 2)
	var centre := Vector2(at.origin.x, at.origin.z)
	# Vector2 uses float32: one ULP at world z=7400 is 0.000488m.
	assert_almost_eq(points[0].distance_to(centre), 6.0, 0.0005)
	assert_almost_eq(points[1].distance_to(centre), 6.0, 0.0005)
	assert_true((points[1] - points[0]).normalized().dot(Vector2(at.basis.z.x, at.basis.z.z)) > 0.999)
	var reverse := SEGMENT.gate_crossing_points(at, Vector2(20, 7480), Vector2(80, 7370))
	assert_true(reverse[0].is_equal_approx(points[1]))
	assert_true(reverse[1].is_equal_approx(points[0]))
	assert_eq(SEGMENT.gate_crossing_points(at, Vector2(80, 7370), Vector2(85, 7360)), [])


func test_shutter_receipt_checks_fixture_mesh_and_real_collision_fields_fail_closed() -> void:
	var hold := Node3D.new()
	var flag := "defeated_stronghold_patrol"
	assert_false(SEGMENT.shutter_receipt(hold, flag, true), "missing physical shutter must never look open")
	var body := StaticBody3D.new()
	body.name = "BlastShutterBody_" + flag
	hold.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "BlastShutter_" + flag
	hold.add_child(mesh)
	assert_true(SEGMENT.shutter_receipt(hold, flag, false))
	assert_false(SEGMENT.shutter_receipt(hold, flag, true))
	shape.disabled = true
	assert_false(SEGMENT.shutter_receipt(hold, flag, true), "collision alone cannot claim the visible door opened")
	mesh.visible = false
	assert_true(SEGMENT.shutter_receipt(hold, flag, true))
	assert_false(SEGMENT.shutter_receipt(hold, flag, false))
	shape.shape = null
	assert_false(SEGMENT.shutter_receipt(hold, flag, true))
	hold.free()


func test_room_axis_and_door_waypoints_share_one_existing_budget() -> void:
	assert_eq(SEGMENT.room_frames_remaining(0), 600)
	assert_eq(SEGMENT.room_frames_remaining(170), 430)
	assert_eq(SEGMENT.room_frames_remaining(599), 1)
	assert_eq(SEGMENT.room_frames_remaining(600), 0)
	assert_eq(SEGMENT.room_frames_remaining(601), 0)
	assert_eq(SEGMENT.room_frames_remaining(-1), 0)
	assert_eq(SEGMENT.ENTRANCE_FRAMES, 950)
	assert_true(SEGMENT.captain_within_deadline(8999))
	assert_false(SEGMENT.captain_within_deadline(9000))


func test_named_trainer_deadline_is_the_round_deadline_per_admitted_opponent() -> void:
	assert_true(SEGMENT.round_within_deadline(0))
	assert_true(SEGMENT.round_within_deadline(8999), "each admitted round has the bridge/tournament round budget")
	assert_false(SEGMENT.round_within_deadline(9000))
	assert_false(SEGMENT.round_within_deadline(-1))


func test_hall_reader_presses_and_steers_only_through_physical_controller_bindings() -> void:
	for action: String in ["combat_quick", "combat_charged", "jump", "move_right", "move_back"]:
		var event := SEGMENT.HallReader._joypad(action)
		assert_true(event is InputEventJoypadButton or event is InputEventJoypadMotion, "controller binding: " + action)
		assert_eq(event.device, 0)
	assert_true(SEGMENT.HallReader._joypad("combat_quick") is InputEventJoypadButton)
	assert_true(SEGMENT.HallReader._joypad("move_right") is InputEventJoypadMotion)
	var reader = SEGMENT.HallReader.new(null)
	assert_true(reader.presses.is_empty(), "a new reader has pressed nothing")
	assert_eq(int(reader._tally.get("burst_uses", -1)), 0)


func test_named_admission_rejects_another_trainer_and_out_of_order_opponents() -> void:
	var segment := SEGMENT.new()
	var director := Director.new()
	var combat := Combat.new()
	var creature := CREATURE.new()
	creature.species_id = "mosshell"
	creature.level = 15
	combat.creature = creature
	segment._director = director
	segment._combat = combat
	segment._captain_active = true
	segment._named_trainer = "captain_riverwatch"
	segment._captain_spec = SEGMENT.TRAINERS.trainer(segment._named_trainer)
	director.trainer = "relay_captain"
	segment._on_entered()
	assert_eq(segment._captain_rounds, 0)
	assert_false(segment.result().failures.is_empty())
	segment._failures.clear()
	director.trainer = "captain_riverwatch"
	segment._on_entered()
	assert_eq(segment._captain_rounds, 1)
	assert_eq(segment.result().failures, [])
	segment._on_entered()
	assert_eq(segment._captain_rounds, 1, "a duplicate first opponent cannot count as the next round")
	assert_false(segment.result().failures.is_empty())
	segment._failures.clear()
	creature.species_id = "trailpup"
	creature.level = 15
	segment._on_entered()
	assert_eq(segment._captain_rounds, 2)
	assert_eq(segment.result().failures, [])
	director.free()
	combat.free()
