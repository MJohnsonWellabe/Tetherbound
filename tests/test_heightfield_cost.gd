extends "res://tests/test_case.gd"

## PERF2 — what one `height_at` call is allowed to cost.
##
## The water composer bakes two 512x512 depth textures at boot, which is
## 524,288 `height_at` calls before anything else in the world is built.
## Measured on this project's own boot log, that was **137 seconds of a 3m08s
## startup**, and 71% of it was one line:
##
##     flat.get("height", _raw_height(centre.x, centre.y))
##
## `Dictionary.get(key, default)` evaluates its default argument EAGERLY, so
## that ran a full `_raw_height` — the entire hills/detail/valley/rise-relief
## stack — for all eleven building pads on every query, including the ten that
## carry an explicit `height` and threw the result away. Eleven redundant noise
## evaluations per sample, 262,144 samples per texture.
##
## These are cost assertions, and they are deliberately NOT wall-clock
## thresholds. A stopwatch limit measures the CI runner, flakes under load, and
## has to be retuned every time the hardware changes. Both tests below compare
## the work `height_at` does against the work it unavoidably has to do, so they
## mean the same thing on any machine.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const COUNTING := preload("res://tests/helpers/counting_heightfield.gd")

## One `_raw_height` per query is the honest allowance: the spawn pad genuinely
## needs the natural ground at its own centre, and a point inside the pad has
## to ask for it. Eleven means the flats are re-deriving constants.
const MAX_RAW_HEIGHT_PER_QUERY := 1

## `height_at` is `_raw_height` plus the carves, the pads and the shore step —
## dot products and smoothsteps against a handful of authored shapes, all of it
## cheap beside the noise stack `_raw_height` already paid for. Anything past a
## few times that means a query is re-parsing config or re-deriving a constant.
## Measured before this item: 16.6x. After: 1.9x.
const MAX_COST_RATIO := 6.0

const TIMED_SAMPLES := 400


func test_height_at_does_not_re_derive_the_pads_every_query() -> void:
	var field: RefCounted = COUNTING.new()
	# One warm-up call: any lazily-built cache is allowed to derive constants
	# once. What must not happen is deriving them again on the next query.
	field.call("height_at", 12.0, -34.0)
	field.set("raw_height_calls", 0)

	field.call("height_at", 40.0, 40.0)
	var calls: int = int(field.get("raw_height_calls"))
	assert_true(calls <= MAX_RAW_HEIGHT_PER_QUERY,
		"one height_at re-derived the natural ground %d times; at most %d is the pads' honest need, and this is called 524288 times at boot" % [
			calls, MAX_RAW_HEIGHT_PER_QUERY])


func test_the_pads_still_flatten_after_being_cached() -> void:
	# The counter above would also be satisfied by a `_apply_flats` that had
	# stopped working, so assert the pads are still pads: a building pad is
	# flat, which is the property the whole cache has to preserve.
	var config: Dictionary = HEIGHTFIELD.load_config()
	var flats: Array = config.get("flats", [])
	assert_true(flats.size() > 0, "the playground should author building pads")

	var field: RefCounted = HEIGHTFIELD.new(config)
	var flat: Dictionary = flats[0]
	var centre: Array = flat.get("centre", [0.0, 0.0])
	var cx := float(centre[0])
	var cz := float(centre[1])
	# Well inside the core, where `_apply_flats` returns the pad's target
	# outright, so every sample must agree to the millimetre.
	var radius := float(flat.get("radius", 10.0)) * 0.5
	var middle: float = field.call("height_at", cx, cz)
	for offset: Vector2 in [
		Vector2(radius, 0.0), Vector2(-radius, 0.0),
		Vector2(0.0, radius), Vector2(0.0, -radius),
	]:
		assert_almost_eq(field.call("height_at", cx + offset.x, cz + offset.y), middle, 0.001,
			"the pad at (%.1f, %.1f) should be flat %.1fm out along %s" % [cx, cz, radius, offset])


func test_height_at_costs_only_a_small_multiple_of_the_noise_it_needs() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	# Warm every lazy cache before timing, so this measures the steady state a
	# 262,144-sample bake actually pays rather than the first call's setup.
	field.call("height_at", 0.0, 0.0)
	field.call("_raw_height", 0.0, 0.0)

	var full := _time_of(field, "height_at")
	var raw := _time_of(field, "_raw_height")
	assert_true(raw > 0.0, "_raw_height should take measurable time")

	var ratio := full / raw
	assert_true(ratio < MAX_COST_RATIO,
		"height_at costs %.1fx _raw_height (%.1f us vs %.1f us); above %.1fx it is re-deriving constants, not computing terrain" % [
			ratio, full, raw, MAX_COST_RATIO])


## Average microseconds per call over a spread of the map, so no single cheap
## early-out (a rise's radius, the river's bounding box) dominates the sample.
func _time_of(field: RefCounted, method: String) -> float:
	var started := Time.get_ticks_usec()
	for i in TIMED_SAMPLES:
		field.call(method, -250.0 + float(i % 500), -250.0 + float(i / 500))
	return float(Time.get_ticks_usec() - started) / TIMED_SAMPLES
