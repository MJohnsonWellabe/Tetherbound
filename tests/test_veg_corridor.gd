extends "res://tests/test_case.gd"

## VEG-CORRIDOR. The scatter's clumps and strays sampled only inside the old
## +-256m square for as long as the Meadows was a square (`world_size` in
## terrain_playground.json, still 512 for legacy reasons -- see that key's
## own `_comment_world`). `_place_corridor_fill` (scatter_rules.gd) is what
## extends coverage to the real corridor (`field.world_bounds()`, x +-1024,
## z -512..7680) without touching the density already tuned inside the
## square. This file pins the two properties that separate "the corridor is
## dressed" from "the corridor silently went back to a square": something
## really does land outside the old square on the shipped config, and adding
## that coverage never perturbs a placement the square already had.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var field: RefCounted = null
var world_size: float = 512.0


func before_each() -> void:
	field = HEIGHTFIELD.new()
	world_size = float(HEIGHTFIELD.load_config().get("world_size", 512))


func _layer(name: String) -> Dictionary:
	return RULES.config().get("layers", {}).get(name, {})


## THE placement-extent test: if the corridor fill is ever deleted, disabled,
## or the scatter otherwise reverts to sampling only the old square, this
## fails.
##
## A bare "is anything at all outside the square" check would NOT catch that
## regression, and not for the reason it looks like at first: it is `verge`
## (OF12), not `anchors`, that already places outside the old square with
## `corridor_fill` completely absent -- a verge fringe strings instances
## along `field.path_polylines()`, which has spanned the whole 8192x2048m
## corridor since OW5C, and `_consider`'s own bounds check
## (`_out_of_bounds`) already prefers `field.world_bounds()` over `half`
## whenever the field has one. Measured directly (stripping `corridor_fill`
## from every layer and counting): **3,090** placements already land outside
## the square from verge alone, entirely independent of this feature. With
## `corridor_fill` live on the shipped config that rises to **78,209**. The
## threshold below sits an order of magnitude above the verge-only floor and
## well below the corridor-fill total, so this fails on a real corridor_fill
## regression and does not false-positive on the pre-existing verge reach.
func test_the_real_meadow_places_something_outside_the_old_square() -> void:
	var half := world_size * 0.5
	const REGRESSION_THRESHOLD := 20000
	var built: Dictionary = RULES.all_placements(field, world_size, int(RULES.config().get("seed", 1)))
	var outside := 0
	var checked := 0
	for layer_name: String in built.keys():
		for placement: Variant in (built[layer_name] as Array):
			var spot: Vector3 = (placement as Dictionary)["position"]
			checked += 1
			if absf(spot.x) > half or absf(spot.z) > half:
				outside += 1
	assert_true(checked > 0, "the meadow placed nothing at all; this test proves nothing")
	assert_true(outside > REGRESSION_THRESHOLD,
		"only %d of %d placements sat outside the old +-%.0fm square (need > %d); " % [
			outside, checked, half, REGRESSION_THRESHOLD
		] + "the corridor fill is disabled, missing, or reverted to a square")


## Every instance the real config places outside the old square must still
## sit inside the real corridor bounds -- `_out_of_bounds` already enforces
## this for clumps/strays generally (test_scatter_rules.gd's own
## `test_nothing_is_placed_outside_the_world`), pinned again here scoped to
## exactly the NEW placements this feature adds, so a bug specific to
## `_place_corridor_fill` (e.g. sampling past `max_x`/`max_z`) cannot hide
## behind the broader test passing.
func test_corridor_fill_never_places_past_the_real_corridor_bounds() -> void:
	var bounds: Dictionary = field.world_bounds()
	assert_false(bounds.is_empty(), "the real config has no world_bounds; this test cannot check anything")
	var half := world_size * 0.5
	var min_x: float = bounds["min_x"]
	var max_x: float = bounds["max_x"]
	var min_z: float = bounds["min_z"]
	var max_z: float = bounds["max_z"]
	var built: Dictionary = RULES.all_placements(field, world_size, int(RULES.config().get("seed", 1)))
	var outside_square_checked := 0
	for layer_name: String in built.keys():
		for placement: Variant in (built[layer_name] as Array):
			var spot: Vector3 = (placement as Dictionary)["position"]
			if absf(spot.x) <= half and absf(spot.z) <= half:
				continue
			outside_square_checked += 1
			assert_between(spot.x, min_x, max_x, "%s corridor-fill x out of bounds" % layer_name)
			assert_between(spot.z, min_z, max_z, "%s corridor-fill z out of bounds" % layer_name)
	assert_true(outside_square_checked > 0, "nothing landed outside the square; this test proves nothing")


# --- the mechanism, isolated ------------------------------------------------

func test_corridor_fill_absent_or_empty_changes_nothing() -> void:
	# Same backward-compatibility contract verge/anchors/path_standoff already
	# carry: a layer that does not opt in must place identically whether the
	# key is an empty dictionary or absent entirely.
	var trees := _layer("trees").duplicate(true)
	trees["corridor_fill"] = {}
	var with_empty := RULES.placements_for(trees, field, world_size, 55)
	var without_the_key := _layer("trees").duplicate(true)
	without_the_key.erase("corridor_fill")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(with_empty.size(), without.size())
	for i in with_empty.size():
		assert_true((with_empty[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"an empty corridor_fill moved a placement; it must be a no-op")


func test_corridor_fill_density_scale_zero_changes_nothing() -> void:
	var trees := _layer("trees").duplicate(true)
	trees["corridor_fill"] = {"density_scale": 0.0}
	var scaled_to_zero := RULES.placements_for(trees, field, world_size, 55)
	var without_the_key := _layer("trees").duplicate(true)
	without_the_key.erase("corridor_fill")
	var without := RULES.placements_for(without_the_key, field, world_size, 55)
	assert_eq(scaled_to_zero.size(), without.size())
	for i in scaled_to_zero.size():
		assert_true((scaled_to_zero[i]["position"] as Vector3).is_equal_approx(without[i]["position"]),
			"density_scale 0.0 moved a placement; it must be a no-op")


## `_band_scale_at` is a pure function of position and the band table -- pinned
## directly, the same way `path_standoff_at` is pinned in test_scatter_rules.gd,
## because the corridor-fill tests above only exercise it indirectly through
## the real (currently populated) `corridor_bands` config.
func test_band_scale_defaults_to_full_density_with_no_matching_band() -> void:
	var bands: Array = [{"z_min": 0.0, "z_max": 100.0, "density_scale": 0.2}]
	assert_almost_eq(RULES._band_scale_at(500.0, bands), 1.0, 0.0001,
		"a z with no matching band must fill at full origin-square density, not zero")
	assert_almost_eq(RULES._band_scale_at(50.0, []), 1.0, 0.0001,
		"an empty band table must fill at full origin-square density everywhere")


func test_band_scale_picks_the_band_that_contains_z() -> void:
	var bands: Array = [
		{"z_min": -500.0, "z_max": 0.0, "density_scale": 0.1},
		{"z_min": 0.0, "z_max": 500.0, "density_scale": 0.5},
	]
	assert_almost_eq(RULES._band_scale_at(-250.0, bands), 0.1, 0.0001)
	assert_almost_eq(RULES._band_scale_at(250.0, bands), 0.5, 0.0001)
	# z_max is exclusive: the boundary itself belongs to the NEXT band.
	assert_almost_eq(RULES._band_scale_at(0.0, bands), 0.5, 0.0001,
		"z_max should be exclusive; the boundary landed in the wrong band")
