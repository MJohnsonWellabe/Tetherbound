extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BAND1_SPAWNS := "res://data/config/bands/band1_lower_meadows/spawns.json"


func test_corrective_retry_does_not_spend_stat_rng() -> void:
	var stat_rng := RandomNumberGenerator.new()
	var control_rng := RandomNumberGenerator.new()
	stat_rng.seed = 99117
	control_rng.seed = 99117
	var preferred := Vector3(stat_rng.randf(), 0.0, stat_rng.randf())
	var control_preferred := Vector3(control_rng.randf(), 0.0, control_rng.randf())
	var occupied: Array[Dictionary] = [{"at": preferred, "radius": 1.1}]
	var result: Dictionary = DIRECTOR.resolve_cluster_spot(preferred, Vector3.ZERO, 8.0,
		1.1, occupied, 1.25, 77)
	assert_ne(result["spot"], control_preferred,
		"the fixture must force a corrective spacing retry")
	assert_almost_eq(stat_rng.randf(), control_rng.randf(), 0.0000001,
		"spacing retries must not consume the cluster RNG that rolls stats")


func test_legal_original_point_is_bit_identical() -> void:
	var preferred := Vector3(4.0, 0.0, -3.0)
	var result: Dictionary = DIRECTOR.resolve_cluster_spot(preferred, Vector3.ZERO, 8.0,
		1.1, [], 1.25, 77)
	assert_eq(result["spot"], preferred)
	assert_true(bool(result["feasible"]))


func test_overlap_resolves_deterministically_with_body_radius_clearance() -> void:
	var occupied: Array[Dictionary] = [{"at": Vector3.ZERO, "radius": 1.1}]
	var first: Dictionary = DIRECTOR.resolve_cluster_spot(Vector3(0.2, 0.0, 0.0),
		Vector3.ZERO, 10.0, 1.1, occupied, 1.25, 4401)
	var second: Dictionary = DIRECTOR.resolve_cluster_spot(Vector3(0.2, 0.0, 0.0),
		Vector3.ZERO, 10.0, 1.1, occupied, 1.25, 4401)
	assert_true(bool(first["feasible"]))
	assert_eq(first["spot"], second["spot"], "same authored order/member must resolve identically")
	var at: Vector3 = first["spot"]
	assert_true(Vector2(at.x, at.z).length() >= 1.1 + 1.1 + 1.25,
		"resolved bodies still overlap or visually merge")
	assert_true(Vector2(at.x, at.z).length() <= 10.0,
		"resolver moved a centre outside the authored cluster radius")


func test_infeasible_disc_keeps_a_bounded_best_candidate_instead_of_deleting() -> void:
	var occupied: Array[Dictionary] = [{"at": Vector3.ZERO, "radius": 2.0}]
	var result: Dictionary = DIRECTOR.resolve_cluster_spot(Vector3.ZERO, Vector3.ZERO,
		0.4, 2.0, occupied, 1.25, 12)
	assert_false(bool(result["feasible"]))
	var at: Vector3 = result["spot"]
	assert_true(at.is_finite())
	assert_true(Vector2(at.x, at.z).length() <= 0.40001,
		"even an infeasible fallback must preserve the authored disc")


func test_declared_radius_includes_elder_and_first_member_alpha_multipliers() -> void:
	var spawn := {
		"elder": {"body_scale": 1.2},
		"alpha": {"scale": 1.35},
	}
	var base := float(SPECIES.placeholder("burrowback").get("radius", 0.4))
	assert_almost_eq(DIRECTOR._declared_spawn_body_radius("burrowback", spawn, 0),
		base * 1.2 * 1.35)
	assert_almost_eq(DIRECTOR._declared_spawn_body_radius("burrowback", spawn, 1),
		base * 1.2, 0.0001, "only the named first member receives the alpha multiplier")


func test_wander_destination_rejects_a_same_cluster_body_but_not_open_ground() -> void:
	var occupied: Array[Dictionary] = [{"at": Vector3(4.0, 0.0, 0.0), "radius": 1.3}]
	assert_false(DIRECTOR.cluster_destination_clear(Vector3(2.0, 0.0, 0.0),
		1.1, occupied, 1.25),
		"candidate overlaps the other radius plus configured presentation gap")
	assert_true(DIRECTOR.cluster_destination_clear(Vector3(-4.0, 0.0, 0.0),
		1.1, occupied, 1.25),
		"open ground in the same authored cluster must remain available")


func test_authored_shallow_water_exception_disables_body_spacing_only_for_order_6() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BAND1_SPAWNS))
	assert_true(parsed is Dictionary)
	var order_6: Dictionary = {}
	for entry: Dictionary in (parsed as Dictionary).get("spawns", []):
		if int(entry.get("order", -1)) == 6:
			order_6 = entry
			break
	assert_false(order_6.is_empty(), "tracked Band 1 paddlenewt fixture must exist")
	assert_false(DIRECTOR.cluster_body_spacing_enabled(order_6),
		"the 0.4m depth-safe shelf must bypass resolver/warnings explicitly")
	assert_true(DIRECTOR.cluster_body_spacing_enabled({}),
		"all unannotated clusters keep body-aware spacing by default")
