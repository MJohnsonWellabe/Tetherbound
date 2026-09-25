extends "res://tests/test_case.gd"

## F02.4 (pacing). WORLD §3.1 route beat spacing / ACCEPTANCE A7, measured on
## the earned Upper Meadows -> Hall road for the authored world and 200 rolled
## world seeds. The model and its envelope are documented in
## tests/helpers/meadows_route_ambush_spacing.gd; this file holds the rule.
##
## Target, derived from WORLD §3.1 ("a meaningful sight, encounter or decision
## should occur every 150-250 m"): a forced ambush is one encounter beat, so two
## consecutive road-reaching aggressive envelopes must begin >= 150 m apart,
## i.e. at most two in any 300 m stretch. The receipt that opened F02.4 had four
## in ~320 m.
##
## Danger floor, so the fix cannot be "delete the aggressors": the authored
## world keeps a road-reaching ambush at least every 600 m (A7's 120 s at the
## 5 m/s walk) and at least one per earned band, and the Hall alpha pack (5001)
## stays where it was witnessed optional.

const MODEL := preload("res://tests/helpers/meadows_route_ambush_spacing.gd")

const ROLLED_SEEDS_FROM := 1
const ROLLED_SEEDS_TO := 200
const A7_WALK_WINDOW_M := 600.0
const BAND5_ENTRY_M := 3400.0  # chainage of (0,7000) on the band4+band5 route
const HALL_ALPHA_CENTRE := Vector2(-58.0, 7255.0)


func _rolled_seeds() -> Array:
	var out: Array = []
	for s in range(ROLLED_SEEDS_FROM, ROLLED_SEEDS_TO + 1):
		out.append(s)
	return out


func test_route_is_the_earned_band4_band5_spine() -> void:
	var road := MODEL.route()
	assert_eq(road[0], Vector2(0, 4760), "route starts at the band-4 entry")
	assert_eq(road[-1], Vector2(0, 7560), "route ends at the Hall gate")
	assert_true(absf(MODEL.route_length(road) - 4088.0) < 5.0,
		"route length changed (%.1fm); re-derive BAND5_ENTRY_M" % MODEL.route_length(road))


func test_authored_world_respects_route_ambush_spacing() -> void:
	var r := MODEL.measure(0)
	print(MODEL.line("[route-ambush] seed=0", r))
	for a: Dictionary in r.ambushes:
		print("[route-ambush]   seed=0 order=%d %s at %.0fm" % [int(a.order), str(a.species), float(a.at_m)])
	assert_eq(int(r.short_gaps), 0,
		"seed 0 has %d consecutive ambushes closer than %.0fm (min %.0fm)" % [
			int(r.short_gaps), MODEL.MIN_AMBUSH_GAP_M, float(r.min_gap_m)])
	assert_true(int(r.max_per_window) <= MODEL.MAX_PER_WINDOW,
		"seed 0 fits %d ambushes in one 300m stretch at %.0fm" % [int(r.max_per_window), float(r.worst_window_at_m)])


func test_rolled_worlds_respect_route_ambush_spacing() -> void:
	var results := MODEL.sweep(_rolled_seeds())
	var summary := MODEL.summarize(results)
	print(MODEL.summary_line("[route-ambush] seeds=%d..%d" % [ROLLED_SEEDS_FROM, ROLLED_SEEDS_TO], summary))
	var shown := 0
	for r: Dictionary in results:
		if (int(r.short_gaps) > 0 or int(r.max_per_window) > MODEL.MAX_PER_WINDOW) and shown < 5:
			shown += 1
			print(MODEL.line("[route-ambush]   violating seed=%d" % int(r.seed), r))
	assert_eq(int(summary.violating_seeds), 0,
		"%d of %d rolled worlds break the 150m ambush spacing (worst %d per 300m, seed %d)" % [
			int(summary.violating_seeds), int(summary.seeds), int(summary.worst_per_300m), int(summary.worst_seed)])


func test_authored_danger_is_kept() -> void:
	var r := MODEL.measure(0)
	assert_true(int(r.count) >= 8, "seed 0 keeps only %d road ambushes; the danger was removed, not spaced" % int(r.count))
	var ambushes: Array = r.ambushes
	var road_m := float(r.route_m)
	var previous := 0.0
	var band4 := 0
	var band5 := 0
	var hall_alpha := false
	for a: Dictionary in ambushes:
		assert_true(float(a.at_m) - previous <= A7_WALK_WINDOW_M,
			"%.0fm of road before order %d has no aggressive ambush" % [float(a.at_m) - previous, int(a.order)])
		previous = float(a.at_m)
		if float(a.at_m) < BAND5_ENTRY_M:
			band4 += 1
		else:
			band5 += 1
		if int(a.order) == 5001:
			hall_alpha = true
	assert_true(road_m - previous <= A7_WALK_WINDOW_M, "the last %.0fm before the Hall gate is ambush-free" % (road_m - previous))
	assert_true(band4 >= 1 and band5 >= 2,
		"each earned band keeps its danger (band4=%d band5=%d); the Hall approach stays harder than the crossing" % [band4, band5])
	assert_true(hall_alpha, "the Hall alpha pack (5001) still reaches the road it was witnessed optional from")
	var pack: Dictionary = {}
	for raw: Variant in MODEL.merged_spawns():
		if int((raw as Dictionary).get("order", -1)) == 5001:
			pack = raw
	var centre: Array = pack.get("centre", [0, 0, 0])
	assert_eq(Vector2(float(centre[0]), float(centre[2])), HALL_ALPHA_CENTRE, "order 5001 is not moved")
	assert_eq(int(pack.get("count", 0)), 3, "order 5001 keeps its three-body pack")


func test_envelope_matches_the_director_inputs() -> void:
	# A cluster centred on the road always reaches it; one a full envelope
	# plus a metre away never does.
	var road: Array[Vector2] = [Vector2(0, 0), Vector2(0, 100)]
	var reach := MODEL.envelope_m({"radius": 10.0}, 7.0, 14.0, 1.8)
	assert_almost_eq(reach, 32.8, 0.001)
	assert_almost_eq(MODEL.entry_chainage(road, Vector2(0, 50), reach), 17.2, 0.001)
	assert_eq(MODEL.entry_chainage(road, Vector2(reach + 1.0, 50), reach), -1.0)
	assert_almost_eq(MODEL.envelope_m({"radius": 10.0, "wander_radius": 2.0}, 7.0, 14.0, 1.8), 27.8, 0.001)


## The clusters the two real S08 walks actually fought on this stretch (4102,
## 4916, 4005, 4917) and the pinned position (-130.8,6669.3)/(-132.0,6675.9).
## Printed so the evidence note can quote each centre's road distance.
func test_s08_walk_clusters_are_spaced_or_stepped_back() -> void:
	var road := MODEL.route()
	var half := MODEL.path_half_width()
	var notice := float(MODEL.CATCH.config().get("aggression", {}).get("notice_range", 14.0))
	var by_order := {}
	for raw: Variant in MODEL.merged_spawns():
		by_order[int((raw as Dictionary).get("order", -1))] = raw
	for order: int in [4102, 4916, 4005, 4917]:
		var spawn: Dictionary = by_order.get(order, {})
		assert_false(spawn.is_empty(), "order %d is still authored" % order)
		if spawn.is_empty():
			continue
		var c := Vector2(float(spawn.centre[0]), float(spawn.centre[2]))
		var reach := MODEL.envelope_m(spawn, 7.0, notice, half)
		print("[route-ambush] S08 cluster %d %s centre=(%.1f,%.1f) road_distance=%.1fm envelope=%.1fm reaches_road=%s table=%s" % [
			order, str(spawn.species), c.x, c.y, MODEL.distance_to_route(road, c), reach,
			str(MODEL.entry_chainage(road, c, reach) >= 0.0), str(spawn.get("table", "-"))])
	# 4102 can no longer roll an aggressor; 4005's envelope clears the road.
	for r: Dictionary in MODEL.sweep(range(0, 201)):
		for a: Dictionary in r.ambushes:
			assert_false(int(a.order) in [4102, 4005],
				"seed %d: order %d still forces a road ambush" % [int(r.seed), int(a.order)])
	# 4916/4917 stay authored ambushes, but idle clear of the painted path.
	for order: int in [4916, 4917]:
		var spawn: Dictionary = by_order.get(order, {})
		var c := Vector2(float(spawn.centre[0]), float(spawn.centre[2]))
		assert_true(spawn.has("wander_radius"), "order %d opts into the director's road veto" % order)
		assert_true(MODEL.distance_to_route(road, c) - float(spawn.radius) - half >= 4.0,
			"order %d can scatter a home onto the trail" % order)
