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


## T1-GROUND-3's per-layer band weight, pinned the same way and for the same
## reason as `_band_scale_at` above. The backward-compatibility half is the one
## that matters most: every layer in vegetation.json except `drygrass` carries
## no `band_scale`, and if the absent key did anything but return 1.0 the whole
## chapter's scatter would move on the next bake.
func test_layer_band_scale_is_absent_by_default() -> void:
	var bands: Array = [{"id": "b1", "z_min": 0.0, "z_max": 100.0, "density_scale": 0.2}]
	assert_almost_eq(RULES._layer_band_scale_at(50.0, bands, {}), 1.0, 0.0001,
		"a layer with no band_scale must place exactly what it placed before this existed")
	assert_almost_eq(RULES._layer_band_scale_at(50.0, [], {"b1": 0.5}), 1.0, 0.0001,
		"an empty band table has no band to weight, so the weight cannot apply")
	assert_almost_eq(RULES._layer_band_scale_at(500.0, bands, {"b1": 0.5}), 1.0, 0.0001,
		"a z outside every band must not pick up some band's weight")


func test_layer_band_scale_is_keyed_by_band_id_and_may_exceed_one() -> void:
	var bands: Array = [
		{"id": "lower", "z_min": -500.0, "z_max": 0.0, "density_scale": 0.1},
		{"id": "upper", "z_min": 0.0, "z_max": 500.0, "density_scale": 0.1},
	]
	var weights := {"lower": 0.45, "upper": 1.6}
	assert_almost_eq(RULES._layer_band_scale_at(-250.0, bands, weights), 0.45, 0.0001)
	# Over 1.0 survives on purpose: this table says where a species BELONGS,
	# not what the chapter can afford, so it is not clamped the way
	# `density_scale` is. Clamping here would flatten a dry band into a normal
	# one and delete the gradient the key exists for.
	assert_almost_eq(RULES._layer_band_scale_at(250.0, bands, weights), 1.6, 0.0001,
		"a weight above 1.0 must survive; clamping it deletes the species gradient")
	# A band the layer says nothing about keeps its full share rather than
	# vanishing -- the same "unconfigured means unchanged" rule as above.
	assert_almost_eq(RULES._layer_band_scale_at(-250.0, bands, {"upper": 1.6}), 1.0, 0.0001,
		"a band absent from the weight table must keep full density, not zero")


## The gradient the second grass species actually ships with, asserted against
## the real config rather than a fixture -- a typo'd or dropped band id would
## silently return 1.0 for that band and flatten the regional read back out,
## which no other test here would notice.
func test_drygrass_carries_a_band_gradient_over_the_real_band_table() -> void:
	var config: Dictionary = RULES.config()
	var bands: Array = config.get("corridor_bands", [])
	var layers: Dictionary = config.get("layers", {})
	var drygrass: Dictionary = layers.get("drygrass", {})
	var weights: Dictionary = drygrass.get("band_scale", {})
	assert_false(weights.is_empty(),
		"drygrass is the chapter's second grass species and its band gradient is gone")
	assert_false(bands.is_empty(), "corridor_bands is empty; the gradient has nothing to key on")
	var seen := {}
	for entry: Variant in bands:
		var band: Dictionary = entry
		var id := str(band.get("id", ""))
		assert_true(weights.has(id),
			"corridor_bands has band '%s' with no drygrass band_scale entry -- " % id +
			"that band silently falls back to 1.0 and breaks the gradient")
		var mid: float = (float(band.get("z_min", 0.0)) + float(band.get("z_max", 0.0))) * 0.5
		var got := RULES._layer_band_scale_at(mid, bands, weights)
		assert_almost_eq(got, float(weights[id]), 0.0001,
			"band '%s' did not resolve to its own configured weight" % id)
		seen[id] = got
	# The gradient must actually be a gradient, and it must be one in the
	# quantity the bake applies -- which is `density_scale * band_scale`, NOT
	# `band_scale` alone. Asserting the weights alone would pass on a table
	# that reads like a clean ramp and lands as anything at all, which is
	# exactly the mistake the first cut of this made: 0.45 -> 1.6 across bands
	# whose own affordability runs 0.18/0.13/0.12/0.13/0.07 put band 4 drier
	# than band 5. The dry species has to thicken all the way to the
	# stronghold, so the PRODUCT has to rise monotonically along z.
	var previous := -1.0
	var previous_id := ""
	for entry2: Variant in bands:
		var band2: Dictionary = entry2
		var id2 := str(band2.get("id", ""))
		var product: float = float(band2.get("density_scale", 1.0)) * float(weights.get(id2, 1.0))
		assert_true(product > previous,
			"effective dry-species density must climb toward the stronghold: " +
			"'%s' is %.4f against '%s' at %.4f" % [id2, product, previous_id, previous])
		previous = product
		previous_id = id2
