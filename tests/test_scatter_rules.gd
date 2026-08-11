extends "res://tests/test_case.gd"

## Where things grow.
##
## These pin the properties that separate an authored-looking meadow from
## generator output, and the ones whose failure is a visible artefact: trees
## growing out of cliffs, a bush inside the player's spawn, a world that
## reshuffles itself every launch so no two survey frames can be compared.
##
## They do not pin densities. "Too sparse" is the owner's call on the Ally and
## a test that fixed the tree count would break every time the meadow was made
## to look better.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var field: RefCounted = null
var world_size: float = 512.0


func before_each() -> void:
	field = HEIGHTFIELD.new()
	world_size = float(HEIGHTFIELD.load_config().get("world_size", 512))


func _layer(name: String) -> Dictionary:
	return RULES.config().get("layers", {}).get(name, {})


# --- the rules ------------------------------------------------------------

func test_a_steep_face_refuses_everything_that_should_not_grow_there() -> void:
	# The cheapest way to destroy the sense that a place was authored.
	for name in ["trees", "bushes", "flowers", "deadfall"]:
		var layer := _layer(name)
		var limit := float(layer.get("max_slope_deg", 26.0))
		assert_false(RULES.allowed(layer, 0.0, limit + 15.0, 500.0),
			"%s were allowed on a %.0f degree face" % [name, limit + 15.0])


func test_rocks_prefer_slopes_and_flat_ground_refuses_them() -> void:
	# Boulders sitting on flat grass read as dropped props rather than geology.
	var rocks := _layer("rocks")
	assert_false(RULES.allowed(rocks, 0.0, 0.5, 500.0), "a boulder was allowed on flat ground")
	assert_true(RULES.allowed(rocks, 0.0, 20.0, 500.0), "a boulder was refused on a shoulder")


func test_the_spawn_pad_stays_clear() -> void:
	# The player's first sight of the game should not be the inside of a bush.
	for name: String in RULES.config().get("layers", {}).keys():
		if name.begins_with("_"):
			continue
		var layer := _layer(name)
		var clear := float(layer.get("clear_radius", 0.0))
		if clear <= 0.0:
			continue
		assert_false(RULES.allowed(layer, 0.0, 0.0, clear * 0.5),
			"%s was allowed %.1fm from spawn, inside its %.1fm clearing" % [name, clear * 0.5, clear])


func test_every_layer_keeps_the_spawn_clear_at_all() -> void:
	# A layer that forgets its clearing puts grass through the player's feet on
	# the title frame of every survey.
	for name: String in RULES.config().get("layers", {}).keys():
		if name.begins_with("_"):
			continue
		assert_true(float(_layer(name).get("clear_radius", 0.0)) > 0.0,
			"layer '%s' has no spawn clearing" % name)


# --- determinism ----------------------------------------------------------

func test_the_meadow_is_the_same_every_run() -> void:
	# Without this, no survey frame can be compared with the one before it and
	# no placement can ever be authored on top.
	var first: Array[Dictionary] = RULES.placements_for(_layer("trees"), field, world_size, 12345)
	var second: Array[Dictionary] = RULES.placements_for(_layer("trees"), field, world_size, 12345)
	assert_eq(first.size(), second.size(), "the same seed produced a different number of trees")
	for i in mini(first.size(), second.size()):
		assert_true(first[i]["position"].is_equal_approx(second[i]["position"]),
			"tree %d moved between two runs of the same seed" % i)


func test_a_different_seed_produces_a_different_meadow() -> void:
	var a: Array[Dictionary] = RULES.placements_for(_layer("trees"), field, world_size, 1)
	var b: Array[Dictionary] = RULES.placements_for(_layer("trees"), field, world_size, 2)
	if a.is_empty() or b.is_empty():
		assert_true(false, "one of the seeds placed nothing at all")
		return
	assert_false(a[0]["position"].is_equal_approx(b[0]["position"]),
		"two seeds produced the same first placement; the seed is not being used")


# --- what actually gets placed --------------------------------------------

func test_every_layer_places_something() -> void:
	# A layer whose slope limits are impossible silently vanishes, and an empty
	# layer looks exactly like a layer nobody added.
	for name: String in RULES.config().get("layers", {}).keys():
		if name.begins_with("_"):
			continue
		var placed: Array[Dictionary] = RULES.placements_for(_layer(name), field, world_size, 99)
		assert_true(placed.size() > 0, "layer '%s' placed nothing anywhere in the world" % name)


func test_nothing_is_placed_outside_the_world() -> void:
	var half := world_size * 0.5
	for name in ["trees", "grass", "rocks"]:
		for placement in RULES.placements_for(_layer(name), field, world_size, 7):
			var spot: Vector3 = placement["position"]
			assert_between(spot.x, -half, half, "%s x out of bounds" % name)
			assert_between(spot.z, -half, half, "%s z out of bounds" % name)


func test_placements_actually_sit_on_the_terrain() -> void:
	# A prop placed at the wrong height either floats or is buried, and both
	# read as a bug rather than as scenery.
	for placement in RULES.placements_for(_layer("trees"), field, world_size, 7):
		var spot: Vector3 = placement["position"]
		var ground: float = field.height_at(spot.x, spot.z)
		assert_almost_eq(spot.y, ground, 0.01, "a tree was placed off the ground")


func test_scale_varies_within_a_layer() -> void:
	# Uniform prop scale is the readable signature of generator output, and the
	# visual rubric calls it out by name.
	var scales: Array[float] = []
	for placement in RULES.placements_for(_layer("trees"), field, world_size, 7):
		scales.append(float(placement["scale"]))
	assert_true(scales.size() > 4, "not enough trees to judge scale variety")
	var low: float = scales.min()
	var high: float = scales.max()
	assert_true(high > low * 1.3,
		"every tree is nearly the same size (%.2f to %.2f); the meadow will read as procedural" % [low, high])


func test_more_than_one_model_is_used() -> void:
	# Five tree models in the config and one in the world is a bug nobody sees
	# until the forest looks like wallpaper.
	var models := {}
	for placement in RULES.placements_for(_layer("trees"), field, world_size, 7):
		models[placement["model"]] = true
	assert_true(models.size() > 1, "the whole tree layer used a single model")


func test_the_layers_do_not_all_share_one_pattern() -> void:
	# The seed is offset per layer. Without that, grass grows in exactly the
	# same clumps as the trees and the meadow reads as a single stamped tile.
	var built: Dictionary = RULES.all_placements(field, world_size, 4242)
	var trees: Array = built.get("trees", [])
	var bushes: Array = built.get("bushes", [])
	if trees.is_empty() or bushes.is_empty():
		assert_true(false, "cannot compare layers; one of them is empty")
		return
	assert_false((trees[0]["position"] as Vector3).is_equal_approx(bushes[0]["position"]),
		"trees and bushes start at the same point; the layers share a seed")


# --- the shipped models ---------------------------------------------------

func test_every_model_named_in_the_config_exists() -> void:
	# A renamed or missing asset drops a whole layer out of the world, and the
	# only symptom is that the meadow looks a bit empty.
	for name: String in RULES.config().get("layers", {}).keys():
		if name.begins_with("_"):
			continue
		for entry: Variant in _layer(name).get("models", []):
			var path := str(entry)
			assert_true(ResourceLoader.exists(path), "layer '%s' names a missing model: %s" % [name, path])


# --- ridge bias (R7.1-remainder: sparse clumping on the true horizon) -----

func test_ridge_bias_of_zero_changes_nothing() -> void:
	# The default for every layer that does not opt in. Same seed, same
	# heightfield, ridge_bias 0.0 must reproduce the unbiased placements
	# exactly -- this is the backward-compatibility guarantee every other
	# layer's tuning depends on.
	var trees := _layer("trees").duplicate(true)
	trees["ridge_bias"] = 0.0
	var with_zero := RULES.placements_for(trees, field, world_size, 55)
	var without_the_key := _layer("trees").duplicate(true)
	without_the_key.erase("ridge_bias")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_zero.size(), without.size())
	for i in with_zero.size():
		assert_true((with_zero[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"ridge_bias 0.0 moved a placement; it must be a no-op")


func test_ridge_bias_of_one_prefers_higher_ground() -> void:
	# Not a claim about any specific ridgeline -- just that biased clumps land
	# somewhere higher, on average, than unbiased ones drawn from the same
	# heightfield and seed range. Averaged over many seeds so one unlucky draw
	# cannot flake the test.
	var layer := _layer("trees").duplicate(true)
	layer["clumps"] = 1
	layer["per_clump"] = 1
	layer["strays"] = 0
	layer["clump_radius"] = 0.1

	var biased_sum := 0.0
	var unbiased_sum := 0.0
	var samples := 40
	for seed_value in samples:
		layer["ridge_bias"] = 1.0
		var biased := RULES.placements_for(layer, field, world_size, seed_value * 101)
		layer["ridge_bias"] = 0.0
		var unbiased := RULES.placements_for(layer, field, world_size, seed_value * 101)
		if biased.is_empty() or unbiased.is_empty():
			continue
		biased_sum += (biased[0]["position"] as Vector3).y
		unbiased_sum += (unbiased[0]["position"] as Vector3).y

	assert_true(biased_sum > unbiased_sum,
		"ridge_bias 1.0 averaged %.1f height across %d seeds, no higher than unbiased's %.1f" % [
			biased_sum / samples, samples, unbiased_sum / samples
		])


# --- path bias (EV3: path_stones clumps anchored to the actual road) ------

func test_path_bias_of_zero_changes_nothing() -> void:
	# Same backward-compatibility guarantee as ridge_bias 0.0: a layer that
	# does not opt in must place identically whether the key is present at
	# 0.0 or absent entirely.
	var stones := _layer("path_stones").duplicate(true)
	stones["path_bias"] = 0.0
	var with_zero := RULES.placements_for(stones, field, world_size, 55)
	var without_the_key := _layer("path_stones").duplicate(true)
	without_the_key.erase("path_bias")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_zero.size(), without.size())
	for i in with_zero.size():
		assert_true((with_zero[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"path_bias 0.0 moved a placement; it must be a no-op")


func test_path_bias_of_one_lands_clumps_on_the_road() -> void:
	# The defect this fixes: path_stones clumps scattering independently of
	# path_factor, landing several metres of untouched lawn away from the
	# nearest route. Uses the real layer's own clumps/per_clump/clump_radius
	# (unlike ridge_bias's isolated-single-instance test above) because a
	# clump straddling the road is the actual shape of the fix -- some
	# instances on the centreline, some in the verge grass beside it -- and
	# collapsing to one instance at zero radius would only prove the snap
	# point itself is on the road, not that the fix changes what ships.
	var layer := _layer("path_stones").duplicate(true)

	layer["path_bias"] = 0.0
	var unbiased_total := 0.0
	var unbiased_count := 0
	layer["path_bias"] = 1.0
	var biased_total := 0.0
	var biased_count := 0

	var samples := 5
	for seed_value in samples:
		layer["path_bias"] = 0.0
		for p in RULES.placements_for(layer, field, world_size, seed_value * 97):
			var spot: Vector3 = p["position"]
			unbiased_total += field.path_factor(spot.x, spot.z)
			unbiased_count += 1
		layer["path_bias"] = 1.0
		for p in RULES.placements_for(layer, field, world_size, seed_value * 97):
			var spot: Vector3 = p["position"]
			biased_total += field.path_factor(spot.x, spot.z)
			biased_count += 1

	assert_true(unbiased_count > 0 and biased_count > 0, "one of the two runs placed nothing at all")
	var unbiased_avg := unbiased_total / unbiased_count
	var biased_avg := biased_total / biased_count
	assert_true(biased_avg > unbiased_avg * 10.0,
		"path_bias 1.0 averaged path_factor %.3f across %d instances, not meaningfully above unbiased's %.3f" % [
			biased_avg, biased_count, unbiased_avg
		])


# --- path bias jitter (EV3-remainder round 2: break up the collinear "hedge") ---

func test_path_bias_jitter_of_zero_changes_nothing() -> void:
	# path_stones wants the exact snap and must be completely unaffected by
	# this key's mere presence at 0.0, the same backward-compatibility
	# guarantee every other bias parameter carries.
	var stones := _layer("path_stones").duplicate(true)
	stones["path_bias"] = 1.0
	stones["path_bias_jitter"] = 0.0
	var with_zero := RULES.placements_for(stones, field, world_size, 55)
	var without_the_key := _layer("path_stones").duplicate(true)
	without_the_key["path_bias"] = 1.0
	without_the_key.erase("path_bias_jitter")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_zero.size(), without.size())
	for i in with_zero.size():
		assert_true((with_zero[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"path_bias_jitter 0.0 moved a placement; it must be a no-op")


func test_path_bias_jitter_spreads_clumps_off_the_exact_centreline() -> void:
	# The defect this fixes: every path-biased clump snapping to the EXACT
	# nearest point puts several clumps strung along one straight route on
	# the same line, which a blind critic read as a hedge planted with a
	# ruler. A jittered clump should land close to the road but not ON it as
	# reliably as an unjittered one.
	# A minimal, permissive layer rather than a real one duplicated -- this is
	# testing the geometry of the jitter itself, not any layer's own slope/
	# clearing rules, and flowers' own max_slope_deg was filtering out enough
	# jittered draws (onto locally steep ground beside the path) to starve
	# the sample.
	# grows_on_paths: true, so the "nothing grows on the road" rule (a
	# separate, unrelated mechanism) does not confound this test -- it would
	# reject exactly the draws this test wants to see (a jittered point that
	# still lands close to the centreline), which is testing the wrong thing.
	var layer := {
		"models": _layer("flowers").get("models", []),
		"clumps": 1, "per_clump": 1, "strays": 0, "clump_radius": 0.01,
		"path_bias": 1.0, "path_bias_jitter": 4.0, "grows_on_paths": true,
		"max_slope_deg": 60.0, "clear_radius": 0.5, "cleared_by_clearings": false,
	}

	var exactly_on_road := 0
	var attempted := 0
	var samples := 30
	for seed_value in samples:
		var placed := RULES.placements_for(layer, field, world_size, seed_value * 151)
		if placed.is_empty():
			continue
		attempted += 1
		var spot: Vector3 = placed[0]["position"]
		if field.path_factor(spot.x, spot.z) > 0.99:
			exactly_on_road += 1

	assert_true(attempted >= samples / 2, "too few of %d draws placed anything to judge (%d)" % [samples, attempted])
	assert_true(exactly_on_road < attempted,
		"path_bias_jitter 4.0 still landed every one of %d placed clumps exactly on the centreline" % attempted)
