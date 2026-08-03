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
