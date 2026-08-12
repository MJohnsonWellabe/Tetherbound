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


# --- path standoff (OF12: the noise-varying verge that replaced every ------
# --- constant-distance path rule) ------------------------------------------
#
# The properties pinned here are exactly the ones the "flanking border" verdict
# was about: the exclusion distance must VARY along a route (a constant offset
# is a ruler-drawn border by definition), and the two sides of a path must
# vary INDEPENDENTLY (matched pairs across the path are what read as planted).
# Densities and the specific min/max metres stay unpinned -- those are the
# owner's call on a rendered frame, and a test that froze them would break
# every time the meadow was made to look better.

## Probe points strung along Grandpa's-house route's first leg -- the
## specific stretch five blind critics kept naming -- each offset a couple of
## metres onto the verge, where ground cover actually gets judged.
func _route_probes(side: float) -> Array[Vector2]:
	var from := Vector2(10.0, -10.0)
	var to := Vector2(-18.0, -15.0)
	var tangent := (to - from).normalized()
	var perpendicular := Vector2(-tangent.y, tangent.x)
	var probes: Array[Vector2] = []
	for i in 40:
		var along := from.lerp(to, (float(i) + 0.5) / 40.0)
		probes.append(along + perpendicular * side * 2.5)
	return probes


func test_path_standoff_absent_or_empty_changes_nothing() -> void:
	# Same backward-compatibility guarantee ridge_bias 0.0 and path_bias 0.0
	# carry: a layer that does not opt in must place identically whether the
	# key is an empty dictionary or absent entirely.
	var grass := _layer("grass").duplicate(true)
	grass["path_standoff"] = {}
	var with_empty := RULES.placements_for(grass, field, world_size, 55)
	var without_the_key := _layer("grass").duplicate(true)
	without_the_key.erase("path_standoff")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_empty.size(), without.size())
	for i in with_empty.size():
		assert_true((with_empty[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"an empty path_standoff moved a placement; it must be a no-op")


func test_path_standoff_never_places_inside_its_minimum() -> void:
	# `min` is the one constant the mechanism keeps: the standoff drifts
	# between min and max, so no instance -- clump-sourced or stray -- may
	# ever stand closer to a path than min. This is the floor that keeps
	# growth off the worn dirt's immediate shoulder even where the noise
	# swings low.
	var layer := {
		"models": _layer("grass").get("models", []),
		"clumps": 30, "per_clump": 10, "strays": 300, "clump_radius": 10.0,
		"max_slope_deg": 60.0, "clear_radius": 0.0, "cleared_by_clearings": false,
		"path_standoff": {"min": 2.0, "max": 8.0, "wavelength": 17.0, "salt": 1},
	}
	var placements := RULES.placements_for(layer, field, world_size, 909)
	assert_true(placements.size() > 0, "nothing survived at all; the test proves nothing")
	for p in placements:
		var spot: Vector3 = p["position"]
		var distance := Vector2(spot.x, spot.z).distance_to(field.nearest_point_on_paths(spot.x, spot.z))
		assert_true(distance >= 2.0,
			"an instance landed %.2fm from a path, inside the standoff's 2.0m minimum" % distance)


func test_path_standoff_varies_along_a_route() -> void:
	# The property whose absence WAS the flanking border: a constant
	# exclusion distance gives the meadow a ruler-straight inner edge at one
	# offset. Probed directly through path_standoff_at (a pure function of
	# position) along the exact route the critics kept naming: the standoff
	# must swing through a real fraction of its min..max range, and never
	# leave it.
	var config := {"min": 0.5, "max": 7.0, "wavelength": 15.0, "salt": 1}
	var lowest := 1000.0
	var highest := -1000.0
	for probe in _route_probes(1.0):
		var nearest: Vector2 = field.nearest_point_on_paths(probe.x, probe.y)
		var standoff: float = RULES.path_standoff_at(probe, nearest, config, field)
		assert_between(standoff, 0.5, 7.0, "standoff left its own configured range")
		lowest = minf(lowest, standoff)
		highest = maxf(highest, standoff)
	assert_true(highest - lowest > 1.5,
		"the standoff spanned only %.2fm-%.2fm along a 28m route; a near-constant offset is the flanking border again" % [
			lowest, highest
		])


func test_path_standoff_sides_are_independent() -> void:
	# Matched pairs across the path are what read as planted. The noise is
	# salted with the SIDE of the path, so the verge distance directly across
	# from any point is drawn from an independent field -- the two sides must
	# not track each other.
	var config := {"min": 0.5, "max": 7.0, "wavelength": 15.0, "salt": 1}
	var left := _route_probes(1.0)
	var right := _route_probes(-1.0)
	var pairs := 0
	var clearly_different := 0
	for i in left.size():
		var nearest_left: Vector2 = field.nearest_point_on_paths(left[i].x, left[i].y)
		var nearest_right: Vector2 = field.nearest_point_on_paths(right[i].x, right[i].y)
		var standoff_left: float = RULES.path_standoff_at(left[i], nearest_left, config, field)
		var standoff_right: float = RULES.path_standoff_at(right[i], nearest_right, config, field)
		pairs += 1
		if absf(standoff_left - standoff_right) > 0.5:
			clearly_different += 1
	assert_true(pairs > 0, "no probe pairs at all; the test proves nothing")
	assert_true(clearly_different * 2 >= pairs,
		"only %d of %d mirrored probe pairs differ by more than 0.5m; the two verges are tracking each other" % [
			clearly_different, pairs
		])


func test_verge_absent_or_empty_changes_nothing() -> void:
	# The fringe is opt-in, like every other path mechanism here.
	var grass := _layer("grass").duplicate(true)
	grass["verge"] = {}
	var with_empty := RULES.placements_for(grass, field, world_size, 55)
	var without_the_key := _layer("grass").duplicate(true)
	without_the_key.erase("verge")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_empty.size(), without.size())
	for i in with_empty.size():
		assert_true((with_empty[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"an empty verge moved a placement; it must be a no-op")


func test_verge_appends_near_path_instances_without_moving_the_rest() -> void:
	# Two properties in one draw: the fringe never perturbs the layer's own
	# clump/stray placements (it runs last, so the shared prefix must be
	# bit-identical), and every instance it adds sits within inner + band of
	# a route — the fringe is the path's own margin, not scatter leaking
	# across the map.
	var base := {
		"models": _layer("grass").get("models", []),
		"clumps": 10, "per_clump": 5, "strays": 50, "clump_radius": 8.0,
		"max_slope_deg": 60.0, "clear_radius": 0.0, "cleared_by_clearings": false,
	}
	var with_verge: Dictionary = base.duplicate(true)
	with_verge["verge"] = {"count": 300, "inner": 1.5, "band": 4.0}
	var plain := RULES.placements_for(base, field, world_size, 321)
	var fringed := RULES.placements_for(with_verge, field, world_size, 321)
	assert_true(fringed.size() > plain.size(), "a 300-draw verge placed nothing at all")
	for i in plain.size():
		assert_true((fringed[i]["position"] as Vector3).is_equal_approx(plain[i]["position"]),
			"adding a verge moved a clump/stray placement; the fringe must only append")
	for i in range(plain.size(), fringed.size()):
		var spot: Vector3 = fringed[i]["position"]
		var distance := Vector2(spot.x, spot.z).distance_to(field.nearest_point_on_paths(spot.x, spot.z))
		assert_true(distance <= 1.5 + 4.0 + 0.1,
			"a verge instance landed %.2fm from the nearest path, outside its own inner+band reach" % distance)


func test_path_standoff_is_a_stable_property_of_position() -> void:
	# No RNG state: the same spot must always get the same standoff, or the
	# meadow's edge would depend on placement order and no survey frame could
	# be compared with the one before it.
	var config := {"min": 0.5, "max": 7.0, "wavelength": 15.0, "salt": 3}
	var probe := Vector2(4.0, -11.5)
	var nearest: Vector2 = field.nearest_point_on_paths(probe.x, probe.y)
	var first: float = RULES.path_standoff_at(probe, nearest, config, field)
	var second: float = RULES.path_standoff_at(probe, nearest, config, field)
	assert_almost_eq(first, second, 0.000001, "the same spot drew two different standoffs")


