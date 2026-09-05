extends "res://tests/test_case.gd"

## N13-NIGHT-RESUME (CL-O2, OP-0904-2). The owner, flat, on the shipped ROG
## build: **"There is no night time."**
##
## Every day/night probe in this repo passed while that was true, and they
## passed honestly -- they were all asking the wrong question. They read
## `day_cycle.gd::is_dark()` (pure hour arithmetic, which was never broken) and
## `Sun.light_energy` (0.55 at night against 1.4 by day, which looks like a
## night). Not one of them read `tonemap_exposure`, which
## `world_look.gd::_apply_environment()` installs and which multiplies the whole
## linear scene before the ACES curve -- so a preset that dims its light and
## raises its exposure by the same factor has changed nothing at all about how
## bright the frame is. `art.json`'s night did exactly that, one blind-judge
## round at a time: exposure 0.85 -> 1.2 while day sits at 0.6.
##
## So this suite asserts the thing a player can see and nothing else could:
## across the window the game itself calls dark, how much light does the clock
## ASK the renderer for, compared with midday?
##
## Pure logic, no scene tree (docs/decisions/D02). It reads the real
## `data/config/art.json` through the real `day_cycle.gd::interpolate_at()` and
## the real `world_look.gd::light_budget_at()` -- the same functions the running
## game calls on every clock tick -- rather than a copy of their arithmetic,
## because a test that exercises a different mechanism from the thing it is
## checking is testing the mechanism.

const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")

## Half-hour resolution. The blend is piecewise linear between keyframes, so
## every extreme sits on or beside a keyframe and nothing hides between samples.
const STEP := 0.5

## Midnight may ask for at most this share of midday's light.
##
## Chosen before any frame was rendered, and bounded from BELOW by measurement
## as much as from above: `art.json`'s own `_comment_night_light` records that
## ambient 0.35 / sun 0.12 / exposure 0.85 -- an asked-for total near 0.22 on
## this scale -- rendered a literal flat black frame (near_luma 0.000) three
## blind-critic rounds running, because ACES's toe crushes everything below it.
## Midday asks for ~1.87, so 0.60 of it is ~1.12, five times clear of that
## floor. Night has to be unmistakably darker than day AND stay off the toe;
## this is the band where both are true.
const NIGHT_LIGHT_BUDGET_SHARE := 0.6

var _config: Dictionary = {}
var _cycle: RefCounted


func before_each() -> void:
	_config = DAY_CYCLE.load_config()
	_cycle = DAY_CYCLE.new(_config)


func _total_at(hour: float) -> float:
	return float(WORLD_LOOK.light_budget_at(_config, _cycle, hour).total)


## Every half-hour the shipped clock calls dark.
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


## The dark window wraps past midnight, so "the middle of the night" is the
## midpoint of the wrapped span, not the average of the two endpoints.
func _middle_of_the_dark_window() -> float:
	var from: float = float(_cycle.dark_from_hour)
	var to: float = float(_cycle.dark_to_hour)
	var span: float = fposmod(to - from, 24.0)
	return fposmod(from + span * 0.5, 24.0)


func test_the_real_config_has_a_dark_window_and_keyframes_to_blend_across_it() -> void:
	# Guards the three tests below from passing vacuously if art.json ever loses
	# its cycle: an empty dark window makes every loop below a no-op.
	assert_false(_config.is_empty(), "art.json should parse")
	assert_true(_dark_hours().size() > 0, "art.json should define a dark window")
	assert_true(_cycle.keyframe_names().size() >= 2,
		"the clock needs at least two keyframes to blend between")


## The defect, stated as plainly as the owner stated it.
func test_no_hour_of_the_night_asks_for_more_light_than_midday() -> void:
	var brightest := _brightest_lit_total()
	for hour: float in _dark_hours():
		var total := _total_at(hour)
		assert_true(total < brightest,
			("hour %.1f is inside is_dark()'s window but asks the renderer for %.3f, "
			+ "against the brightest daylit hour's %.3f -- the game is telling the player "
			+ "it is night while lighting the scene at least as brightly as noon")
			% [hour, total, brightest])


## Not merely "not brighter than day" -- actually, visibly night.
func test_the_middle_of_the_night_is_much_darker_than_midday() -> void:
	var middle := _middle_of_the_dark_window()
	var total := _total_at(middle)
	var brightest := _brightest_lit_total()
	assert_true(total <= brightest * NIGHT_LIGHT_BUDGET_SHARE,
		("the middle of the night (hour %.1f) asks for %.3f, which is %.0f%% of midday's %.3f; "
		+ "at most %.0f%% is night rather than a blue-tinted afternoon")
		% [middle, total, total / brightest * 100.0, brightest, NIGHT_LIGHT_BUDGET_SHARE * 100.0])


## The shape of the curve, not just its extremes.
##
## `world_look.gd` blends continuously between the two keyframes bracketing the
## current hour, so where the darkest point of the night LANDS says whether the
## night is a night or just the long ramp down into dawn. It belongs near the
## middle of the dark window. Finding it pressed against the window's far edge
## means the clock spends the whole night getting darker and then it is morning
## -- which is what a player would describe as never having had one.
func test_the_darkest_moment_lands_in_the_middle_of_the_night_not_on_its_edge() -> void:
	var darkest_hour := -1.0
	var darkest := INF
	for hour: float in _dark_hours():
		var total := _total_at(hour)
		if total < darkest:
			darkest = total
			darkest_hour = hour
	var from: float = float(_cycle.dark_from_hour)
	var span: float = fposmod(float(_cycle.dark_to_hour) - from, 24.0)
	# How far through the dark window the darkest moment sits, 0..1.
	var position: float = fposmod(darkest_hour - from, 24.0) / span
	assert_between(position, 0.25, 0.75,
		("the darkest moment of the night is hour %.1f, %.0f%% of the way through a dark "
		+ "window that runs %.1f -> %.1f; a night whose darkest point sits on the window's "
		+ "edge is a ramp, not a night") % [darkest_hour, position * 100.0, from, from + span])
