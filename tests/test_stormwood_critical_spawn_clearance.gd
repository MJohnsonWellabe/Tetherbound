extends "res://tests/test_case.gd"

const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const ROAD_VISIBILITY := preload("res://tools/gate_f/road_creature_visibility_model.gd")
const TARGET_ID := "stormwood_wild_dynamo_cluster_24"
const OLD_CENTRE := Vector2(-116.0, 5460.0)
const STORMHEART := Vector2(-100.0, 5470.0)
const ROAD_A := Vector2(-100.0, 5350.0)
const ROAD_B := Vector2(-100.0, 5470.0)
const CAMERA_ARM_M := 5.2


func test_stormheart_ordinary_cluster_clears_terminal_road_envelope() -> void:
	var calm := _spawn("calm")
	var surge := _spawn("surge")
	assert_false(calm.is_empty())
	assert_false(surge.is_empty())
	if calm.is_empty() or surge.is_empty():
		return
	assert_eq(str(calm.species), "tanglevolt")
	assert_eq(str(surge.species), "sparkit")
	var centre := Vector2(float(calm.centre[0]), float(calm.centre[2]))
	assert_eq(centre, Vector2(float(surge.centre[0]), float(surge.centre[2])))
	var largest_footprint := maxf(_fitted_footprint_radius(str(calm.species)),
		_fitted_footprint_radius(str(surge.species)))
	var envelope := float(calm.radius) + largest_footprint + _wander_radius() + CAMERA_ARM_M
	var road_distance := Geometry2D.get_closest_point_to_segment(centre, ROAD_A, ROAD_B).distance_to(centre)
	assert_true(road_distance > envelope,
		"ordinary spawn disc, fitted body, wander and production camera arm must clear the terminal road")
	assert_true(centre.distance_to(STORMHEART) < 100.0,
		"the cluster must remain nearby wildlife at the Stormheart destination")
	assert_false(Geometry2D.get_closest_point_to_segment(OLD_CENTRE, ROAD_A, ROAD_B).distance_to(OLD_CENTRE) > envelope,
		"the former authored centre must fail the same boundary")


func test_resite_keeps_both_derived_encounter_identities() -> void:
	var calm := _spawn("calm")
	var surge := _spawn("surge")
	for spawn: Dictionary in [calm, surge]:
		assert_eq(str(spawn.id), TARGET_ID)
		assert_eq(int(spawn.order), 284525011)
		assert_eq(int(spawn.count), 2)
		assert_almost_eq(float(spawn.radius), 40.0)
	assert_eq(str(calm.species), "tanglevolt")
	# `wild_config()` seeds the phase-qualified cluster id. For the calm table
	# that derives the absolute base level 40; the director pins every spawned
	# member to this value after consuming its ordinary per-instance rolls.
	assert_eq(int(calm.level), 40)
	assert_eq(str(surge.species), "sparkit")
	assert_eq(int(surge.level), 42)


func test_resite_preserves_two_forward_visible_bodies_on_terminal_road() -> void:
	var deepwood := {}
	for route: Dictionary in ROAD_VISIBILITY.evaluate_all().stormwood:
		if str(route.id) == "deepwood_road":
			deepwood = route
			break
	assert_false(deepwood.is_empty(), "the critical Deepwood road remains sampled")
	if deepwood.is_empty():
		return
	assert_eq(int(deepwood.failing_samples), 0,
		"the cleared cluster remains forward-visible through the final 10m samples")
	assert_eq(int(deepwood.minimum_visible), 2,
		"the route retains the required pair without adding creatures")


func _spawn(phase: String) -> Dictionary:
	for spawn: Dictionary in CATALOGUE.wild_config(phase).spawns:
		if str(spawn.get("id", "")) == TARGET_ID:
			return spawn
	return {}


func _fitted_footprint_radius(species_id: String) -> float:
	var species: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/creatures/species.json"))
	var look: Dictionary = species.species[species_id].placeholder
	var model := (load(str(look.model)) as PackedScene).instantiate() as Node3D
	var box := BOUNDS.measure(model)
	model.free()
	var fit := minf(float(look.height) / box.size.y,
		float(look.radius) * 2.0 * float(look.footprint_allowance) / maxf(box.size.x, box.size.z))
	var half_x := maxf(absf(box.position.x), absf(box.end.x)) * fit
	var half_z := maxf(absf(box.position.z), absf(box.end.z)) * fit
	return Vector2(half_x, half_z).length()


func _wander_radius() -> float:
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/combat.json"))
	return float(combat.wild.wander_radius)
