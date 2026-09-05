extends "res://tests/test_case.gd"

## N13-NIGHT-RESUME (CL-O2, OP-0904-2). The owner, flat, on the shipped ROG
## build: **"There is no night time."**
##
## What this suite pins is the half of that the data can be held to: the window
## `day_cycle.gd::is_dark()` calls night has to BE night. It is not a cosmetic
## flag -- torches, camp fill lights and `creature_body.gd`'s night emission
## floor all switch on the moment it turns true -- and it had drifted to nine
## in-game hours, 225 real seconds of a 600-second day, opening at an hour that
## renders at 67% of midday and closing after dawn has already begun.
##
## `docs/prompts/07-RG21-continuous-day-night-short-night.md` is the owner-facing
## contract and says otherwise in as many words: about 120 real seconds of true
## dark, "about 4.8 in-game hours"; "Dawn and dusk are transition periods, not
## part of the 2-minute fully dark window"; and `is_dark()` "should not simply
## return true for the entire dusk/dawn blend."
##
## The numbers the thresholds here are set against are rendered, not reasoned --
## `tools/gate_f/probe_daynight_contrast.gd`, one camera, one world, seven hours
## of the same day through `world_look.gd::_apply_blended()`:
##
##     hour   8.0  mean luma 114.5   1.000 of midday
##     hour  12.0             104.5   0.913
##     hour  18.0              90.5   0.790
##     hour  20.0              77.0   0.672
##     hour  22.0              54.7   0.478
##     hour   0.0              29.5   0.258
##     hour   3.0              43.2   0.377
##
## Pure logic, no scene tree (docs/decisions/D02). It reads the real
## `data/config/art.json` through the real `day_cycle.gd::interpolate_at()` and
## the real `world_look.gd::light_budget_at()` -- the functions the running game
## calls on every clock tick -- rather than a copy of their arithmetic.

const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")

const STEP := 0.5

## RG21's acceptance criterion, in its own units: "Approximately 2 real minutes
## are genuinely dark night." Held to a real band rather than a point, because
## the criterion says "approximately" and the exact clock boundaries are called
## tunable in the same document.
const TRUE_DARK_SECONDS_MIN := 90.0
const TRUE_DARK_SECONDS_MAX := 160.0

## Every hour inside the dark window must ask for at most this share of what
## midday asks for. Set from the render table above: hour 22 and hour 3, the
## endpoints this window is drawn at, come in at 0.48 and 0.38 of midday's mean
## luma, while hour 20 -- the old opening hour, and plainly dusk in the frame --
## sits at 0.67. Asked-for light and rendered luma are different scales, so this
## is deliberately loose; it is a guard against the window creeping back out
## over the transitions, not a second opinion about the tuning.
const DARK_LIGHT_BUDGET_SHARE := 0.75

var _config: Dictionary = {}
var _cycle: RefCounted


func before_each() -> void:
	_config = DAY_CYCLE.load_config()
	_cycle = DAY_CYCLE.new(_config)


func _total_at(hour: float) -> float:
	return float(WORLD_LOOK.light_budget_at(_config, _cycle, hour).total)


func _dark_hours() -> Array[float]:
	var found: Array[float] = []
	for step in int(24.0 / STEP):
		var hour := step * STEP
		if _cycle.is_dark(hour):
			found.append(hour)
	return found


func _brightest_lit_total() -> float:
	var best := -INF
	for step in int(24.0 / STEP):
		var hour := step * STEP
		if not _cycle.is_dark(hour):
			best = maxf(best, _total_at(hour))
	return best


func _dark_span_hours() -> float:
	return fposmod(float(_cycle.dark_to_hour) - float(_cycle.dark_from_hour), 24.0)


func test_the_real_config_has_a_dark_window_and_keyframes_to_blend_across_it() -> void:
	# Guards every test below from passing vacuously on a config that lost its
	# cycle: an empty dark window makes each of these loops a no-op.
	assert_false(_config.is_empty(), "art.json should parse")
	assert_true(_dark_hours().size() > 0, "art.json should define a dark window")
	assert_true(_cycle.keyframe_names().size() >= 2,
		"the clock needs at least two keyframes to blend between")


## RG21's own acceptance criterion, as arithmetic.
func test_true_dark_is_about_two_real_minutes_of_the_ten_minute_day() -> void:
	var seconds := _dark_span_hours() / 24.0 * float(_cycle.day_length_seconds)
	assert_between(seconds, TRUE_DARK_SECONDS_MIN, TRUE_DARK_SECONDS_MAX,
		("is_dark() covers %.1f in-game hours = %.0f real seconds of a %.0f-second day; "
		+ "docs/prompts/07-RG21-continuous-day-night-short-night.md asks for about 120, "
		+ "'about 4.8 in-game hours of true night', with dusk and dawn NOT counted in it")
		% [_dark_span_hours(), seconds, float(_cycle.day_length_seconds)])


## The half of RG21 that the span alone cannot catch: a two-minute window is
## still wrong if it is the wrong two minutes.
func test_the_dark_window_does_not_open_before_the_light_has_actually_gone() -> void:
	var brightest := _brightest_lit_total()
	for hour: float in _dark_hours():
		var share := _total_at(hour) / brightest
		assert_true(share <= DARK_LIGHT_BUDGET_SHARE,
			("hour %.1f is inside is_dark()'s window -- every torch, camp fill light and "
			+ "creature emission floor is on -- while the clock still asks for %.0f%% of "
			+ "midday's light. RG21: is_dark() 'should not simply return true for the "
			+ "entire dusk/dawn blend'") % [hour, share * 100.0])


## The shape of the curve, not just its extremes. `world_look.gd` blends
## continuously between the two keyframes bracketing the current hour, so where
## the darkest point LANDS says whether the night is a night or just the long
## ramp down into dawn -- it belongs inside the window, not pressed against an
## edge of it.
func test_the_darkest_moment_lands_inside_the_dark_window_not_on_its_edge() -> void:
	var darkest_hour := -1.0
	var darkest := INF
	for hour: float in _dark_hours():
		var total := _total_at(hour)
		if total < darkest:
			darkest = total
			darkest_hour = hour
	var from: float = float(_cycle.dark_from_hour)
	var span := _dark_span_hours()
	var position: float = fposmod(darkest_hour - from, 24.0) / span
	assert_between(position, 0.1, 0.9,
		("the darkest moment of the night is hour %.1f, %.0f%% of the way through a dark "
		+ "window that runs %.1f -> %.1f; a night whose darkest point sits on the window's "
		+ "edge is a transition, not a night") % [darkest_hour, position * 100.0, from, from + span])
