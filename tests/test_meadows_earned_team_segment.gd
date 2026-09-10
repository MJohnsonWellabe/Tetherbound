extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const ROAD_GATE := preload("res://scripts/world/road_gate.gd")


class Admission extends Node:
	var admitted: Node3D
	var fighting := true
	func enemy_body() -> Node3D:
		return admitted
	func is_fighting() -> bool:
		return fighting


func test_logged_campsite_return_walks_around_exterior_before_crossing_an_open_gate() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SEGMENT.BOUNDARY_CONFIG))
	var polygon := PackedVector2Array()
	for raw: Array in config.outline.points:
		polygon.append(Vector2(float(raw[0]), float(raw[1])))
	var start := Vector2(-33.8717, -51.71674)
	var target := Vector2(30, -40)
	var route := SEGMENT.boundary_approach(config, start, target, ["RoadGate", "PondGate", "TrailGate"])
	assert_true(route.required)
	assert_true(route.points.size() > 3, "recorded southwest return needs an exterior detour")
	if route.points.size() <= 3:
		return
	var previous := start
	for index in route.points.size() - 2:
		var point: Vector2 = route.points[index]
		assert_true(SEGMENT.exterior_edge_clear(previous, point, polygon), "exterior leg clears fence, guards and arrival tolerance")
		previous = point
	var centre: Vector2 = route.points[-2]
	var crossings := 0
	for index in polygon.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(route.points[-3], route.points[-1],
			polygon[index], polygon[(index + 1) % polygon.size()])
		if hit != null:
			crossings += 1
			assert_true((hit as Vector2).distance_to(centre) < 0.02)
	assert_eq(crossings, 1, "the sole fence crossing is the authored open leaf")
	assert_false(SEGMENT.crosses_boundary(route.points[-1], target, polygon))
	assert_eq(SEGMENT.boundary_approach(config, start, target, []).points, [])
	assert_false(SEGMENT.exterior_edge_clear(start, target, polygon), "direct fence shortcut remains forbidden")
	var reverse := SEGMENT.boundary_approach(config, target, start, [str(route.gate)])
	assert_true(reverse.points.size() > 3, "the same exterior detour is available after leaving the gate")


func test_logged_outside_wild_approach_crosses_solid_corner_and_routes_through_open_pond_gate() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SEGMENT.BOUNDARY_CONFIG))
	var polygon := PackedVector2Array()
	for raw: Array in config.outline.points:
		polygon.append(Vector2(float(raw[0]), float(raw[1])))
	var stopped := Vector2(-37.72714, 4.499945)
	var target := Vector2(-54.17064, 23.00343)
	assert_true(Geometry2D.is_point_in_polygon(stopped, polygon))
	assert_false(Geometry2D.is_point_in_polygon(target, polygon))
	assert_eq(polygon[11], Vector2(-38, 6))
	# Production corner half-width1.1 plus Player capsule radius0.4 explains
	# the observed z=4.5 stop. Terrain alone is a walkable ~13 degree slope.
	assert_almost_eq(stopped.y, polygon[11].y - 1.1 - 0.4, 0.0001)
	var corner_hit: Variant = Geometry2D.segment_intersects_segment(stopped, target,
		polygon[11] + Vector2(-1.1, -1.1), polygon[11] + Vector2(1.1, -1.1))
	assert_true(corner_hit != null, "direct bearing hits the authored corner guard")
	var route := SEGMENT.boundary_approach(config, stopped, target, ["RoadGate", "PondGate", "TrailGate"])
	assert_true(route.required)
	assert_eq(route.gate, "PondGate")
	assert_eq(route.points.size(), 3)
	assert_eq(route.points[1], Vector2(-21, 21))
	assert_false(SEGMENT.crosses_boundary(stopped, route.points[0], polygon))
	assert_false(SEGMENT.crosses_boundary(route.points[2], target, polygon))
	var crossings: Array[Vector2] = []
	for index in polygon.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(route.points[0], route.points[2],
			polygon[index], polygon[(index + 1) % polygon.size()])
		if hit != null:
			crossings.append(hit)
	assert_eq(crossings.size(), 1, "only the actual gate opening crosses the fence")
	assert_true(crossings[0].distance_to(Vector2(-21, 21)) < 0.01)
	var original_start := Vector2(19.65534, -42.48375)
	assert_eq(SEGMENT.boundary_approach(config, original_start, target, ["RoadGate", "PondGate", "TrailGate"]).gate, "PondGate")
	var reverse := SEGMENT.boundary_approach(config, target, original_start, ["PondGate"])
	assert_eq(reverse.gate, "PondGate")
	assert_true(Geometry2D.is_point_in_polygon(reverse.points[-1], polygon))


func test_boundary_route_does_not_assume_an_open_leaf_or_invent_a_direct_crossing() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SEGMENT.BOUNDARY_CONFIG))
	var stopped := Vector2(-37.72714, 4.499945)
	var target := Vector2(-54.17064, 23.00343)
	var refused := SEGMENT.boundary_approach(config, stopped, target, [])
	assert_true(refused.required)
	assert_eq(refused.points, [])
	assert_eq(SEGMENT.boundary_approach(config, stopped, target, ["MissingGate"]).points, [])
	var direct := SEGMENT.boundary_approach(config, Vector2(20, -40), Vector2(30, -40), [])
	assert_false(direct.required)
	assert_eq(direct.points, [])
	assert_true(SEGMENT.boundary_approach({}, stopped, target, []).required)
	assert_eq(SEGMENT.APPROACH_FRAMES, 3600, "gate travel shares the original approach budget")
	var missing := config.duplicate(true)
	missing.gates.entries = []
	assert_eq(SEGMENT.boundary_approach(missing, stopped, target, ["PondGate"]).points, [])


func test_only_an_actual_open_leaf_with_disabled_collision_authorizes_the_route() -> void:
	var world := Node3D.new()
	var boundary := Node3D.new()
	boundary.name = "VillageBoundary"
	world.add_child(boundary)
	var gate := ROAD_GATE.new()
	gate._shape = CollisionShape3D.new()
	gate.add_child(gate._shape)
	gate.name = "PondGate"
	boundary.add_child(gate)
	var segment := SEGMENT.new()
	segment._world = world
	assert_false(segment._open_boundary_gate("PondGate"))
	gate._open = true
	assert_false(segment._open_boundary_gate("PondGate"), "logical open cannot bypass a solid leaf")
	gate._shape.disabled = true
	assert_true(segment._open_boundary_gate("PondGate"))
	gate.flag_id = "another_gate"
	assert_false(segment._open_boundary_gate("PondGate"))
	assert_false(segment._open_boundary_gate("MissingGate"))
	world.free()


func test_training_selection_prefers_the_eligible_current_offer_before_latching_identity() -> void:
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 4.0, 8.0], 1), 1,
		"the offered nearby candidate must win over a distant lower-level candidate")
	assert_eq(SEGMENT.preferred_candidate_index([4.0, 4.0], 1), 1,
		"a contested equal-distance offer must retain production's exact chosen body")
	assert_eq(SEGMENT.preferred_candidate_index([4.0, 4.1], 1), 1,
		"a valid offer sampled in this frame wins over a second opinion of its tie")
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 8.0, 20.0], -1), 1,
		"without an eligible offer, approach the nearest eligible live candidate")
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 8.0, 20.0], 7), 1,
		"an offer outside the already-filtered list cannot bypass species/level/ownership limits")
	assert_eq(SEGMENT.preferred_candidate_index([], -1), -1)
	assert_eq(SEGMENT.preferred_candidate_index([INF, NAN, -2.0], -1), -1)
	assert_eq(SEGMENT.APPROACH_FRAMES, 3600, "selection repair does not extend the failed approach deadline")


func test_pilot_selection_uses_underlevel_bonus_only_with_supplied_stock() -> void:
	var party := PARTY.new()
	var underlevel := _pilot_creature(3, 0.9)
	var healthy := _pilot_creature(5, 1.0)
	party.add(underlevel)
	party.add(healthy)
	var supplied := SEGMENT.pilot_selection(party, 1, true, 5)
	assert_eq(int(supplied.index), 0, "supplied care keeps the under-level pilot bonus")
	var depleted := SEGMENT.pilot_selection(party, 0, true, 5)
	assert_eq(int(depleted.index), 1, "depleted care removes the under-level bonus and chooses the healthiest pilot")


func test_depleted_pilot_selection_compares_usable_health_fraction() -> void:
	var party := PARTY.new()
	var fuller := _pilot_creature(2, 0.95)
	var weaker := _pilot_creature(5, 0.8)
	party.add(fuller)
	party.add(weaker)
	var selected := SEGMENT.pilot_selection(party, 0, false, 5)
	assert_eq(int(selected.index), 0, "depleted selection uses the maximum eligible HP fraction")
	assert_almost_eq(float(selected.score), 9.5, 0.0001)


func test_pilot_selection_excludes_fainted_resting_and_dead_instances() -> void:
	var party := PARTY.new()
	var fainted := _pilot_creature(5, 1.0)
	fainted.set("fainted", true)
	var resting := _pilot_creature(5, 1.0)
	resting.set("resting", true)
	var dead := _pilot_creature(5, 0.0)
	var usable := _pilot_creature(1, 0.4)
	party.add(fainted)
	party.add(resting)
	party.add(dead)
	party.add(usable)
	var selected := SEGMENT.pilot_selection(party, 0, false, 5)
	assert_eq(int(selected.index), 3, "only a living, non-resting instance is eligible")


func _pilot_creature(level: int, hp_fraction: float) -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("bramblebun")
	creature.call("set_level", level, PROGRESSION.config())
	creature.set("hp", float(creature.get("max_hp")) * hp_fraction)
	creature.set("fainted", false)
	creature.set("resting", false)
	return creature


func test_engagement_checks_the_admitted_body_after_the_input_frame() -> void:
	var selected := Node3D.new()
	selected.name = "Bramblebun"
	var nearby := Node3D.new()
	nearby.name = "Mudsnout"
	var combat := Admission.new()
	var segment := SEGMENT.new()
	segment._combat = combat
	combat.admitted = selected
	assert_true(segment._verify_engagement(selected))
	# The input had a valid Bramblebun offer; a subsequent admission must still
	# be that body before any chip, aim or throw consumes the chosen reference.
	combat.admitted = nearby
	assert_false(segment._verify_engagement(selected))
	assert_true(str(segment.result().failures).contains("Mudsnout"))
	combat.admitted = selected
	combat.fighting = false
	assert_false(segment._verify_engagement(selected))
	selected.free()
	nearby.free()
	combat.free()


func test_missing_live_context_cannot_create_or_complete_preparation() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_eq(observed.world, null)
	assert_true(not observed.failures.is_empty())


func test_catch_receipt_rejects_replacement_reorder_duplicate_and_sixth_member() -> void:
	assert_true(SEGMENT.one_new_member([10, 20], [10, 20, 30]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 20]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 30, 40]))
	assert_false(SEGMENT.one_new_member([10, 20], [20, 10, 30]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 20, 10]))
	assert_false(SEGMENT.one_new_member([1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 6]))


func test_training_receipt_accepts_level_rollover_but_rejects_no_xp_and_replacement() -> void:
	var before: Array[Dictionary] = [{"id": 10, "level": 2, "xp": 80}]
	assert_true(SEGMENT.earned_training_progress(before, [{"id": 10, "level": 3, "xp": 2}]))
	assert_true(SEGMENT.earned_training_progress(before, [{"id": 10, "level": 2, "xp": 90}]))
	assert_false(SEGMENT.earned_training_progress(before, before))
	assert_false(SEGMENT.earned_training_progress(before, [{"id": 20, "level": 3, "xp": 2}]))
	assert_false(SEGMENT.earned_training_progress(before, []))
	assert_false(SEGMENT.earned_training_progress(
		[{"id": 10, "level": 2, "xp": 80}, {"id": 20, "level": 3, "xp": 50}],
		[{"id": 10, "level": 3, "xp": 2}, {"id": 20, "level": 3, "xp": 0}]),
		"one member's progress cannot hide another member's lost XP")


func test_shared_care_refuses_missing_context_without_spending_or_receipts() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.care_existing(null, null, null, "berries", 0)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])


func test_earned_requirement_uses_real_tournament_roster_and_training_rules() -> void:
	var party := PARTY.new()
	for index in TOURNAMENT.required_party_size():
		var creature: RefCounted = SPECIES.spawn("bramblebun")
		creature.call("set_level", TOURNAMENT.required_level(), PROGRESSION.config())
		party.add(creature)
	assert_true(TOURNAMENT.team_ready(party))
	assert_true(TOURNAMENT.training_ready(party))
	party.at(0).set_level(TOURNAMENT.required_level() - 1, PROGRESSION.config())
	assert_true(TOURNAMENT.team_ready(party))
	assert_false(TOURNAMENT.training_ready(party))


func test_live_preparation_has_no_state_injection_or_direct_interaction_callbacks() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_team_segment.gd")
	for forbidden: String in ["reset_for_new_game", "set_flag(", "inventory.add(",
		"party.add(", "set_level(", "take_damage(", "gain_xp(", "heal(", "revive(",
		"_begin_resolve(", "load_game(", "save_game(", "global_position =",
		"set_physics_process(", "set_process(", "rig.set(", "cycle_active(",
		"interaction_activate(", "_on_target_row(", "_hold_the_fight_where_it_was("]:
		assert_false(source.contains(forbidden), "earned route may not bypass input: " + forbidden)
