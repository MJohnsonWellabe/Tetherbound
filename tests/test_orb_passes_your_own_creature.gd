extends "res://tests/test_case.gd"

## BP2: "your own creature and trainer intercept your orbs, and the orb is spent."
##
## From the 2026-08-22 blind cold playtest. `orb.gd::_hit_ground()` raycasts
## along the step the orb just travelled and excluded exactly one body -- the
## target. So an ally standing between the trainer and the wild creature read as
## ground: the orb stopped dead, the throw resolved as a miss, and the orb was
## gone.
##
## That compounds CATCH-FEEL/OP9, where the measured strike rate is ~22% over 27
## launches. A throw the player aimed correctly should not be eaten by the
## creature fighting on their behalf, and the trainer should not be able to hit
## themselves with an orb that left their own hand.
##
## Pure logic, per test_case.gd/D02: this pins the CONTRACT of the exclusion
## list. The live path is `smoke_catching.gd` and the Gate A opening segment.

const ORB_PATH := "res://scripts/combat/orb.gd"
const THROW_PATH := "res://scripts/combat/throw_aim.gd"
const MANAGER_PATH := "res://scripts/combat/combat_manager.gd"


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	return file.get_as_text() if file != null else ""


func _function_body(source: String, name: String) -> String:
	var start := source.find("func %s(" % name)
	if start < 0:
		return ""
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start, (end - start) if end > start else -1)


func test_the_orb_accepts_bodies_to_pass_through() -> void:
	var source := _source(ORB_PATH)
	var body := _function_body(source, "launch")
	assert_ne(body, "", "orb.gd has no launch()")
	assert_true(body.contains("pass_through"),
		"orb.gd::launch() takes no pass-through list, so the only body it can "
		+ "ignore is its target and your own creature still stops the throw")


func test_both_raycasts_share_one_exclusion_list() -> void:
	var source := _source(ORB_PATH)
	# The bug's shape: TWO raycasts each carried their own copy of the
	# target-exclusion line, so a fix applied to one would have left the other
	# stopping on the ally. One builder, used by both.
	assert_true(source.contains("_excluded_rids()"),
		"orb.gd does not build its exclusions in one place")
	for fn: String in ["_hit_ground", "_ground_below"]:
		var body := _function_body(source, fn)
		assert_ne(body, "", "orb.gd has no %s()" % fn)
		assert_true(body.contains("_excluded_rids()"),
			"%s() does not use the shared exclusion list, so it can still stop "
			% fn + "the orb on a body the other raycast passes through")


func test_the_thrower_is_never_hit_by_their_own_orb() -> void:
	var body := _function_body(_source(THROW_PATH), "_release")
	if body == "":
		body = _source(THROW_PATH)
	assert_true(body.contains("_player"),
		"throw_aim.gd does not put the trainer in the pass-through list; the orb "
		+ "leaves their own hand, so it could register against them")


func test_the_fight_tells_the_aim_who_is_fighting_for_the_trainer() -> void:
	var source := _source(MANAGER_PATH)
	assert_true(source.contains("set_pass_through"),
		"combat_manager.gd never hands the ally to throw_aim.gd. The aim node "
		+ "knows the trainer and the target but has no reason to know who is "
		+ "fighting for them, so the fight has to say")


func test_the_aim_exposes_the_setter_the_fight_calls() -> void:
	var body := _function_body(_source(THROW_PATH), "set_pass_through")
	assert_ne(body, "",
		"throw_aim.gd has no set_pass_through(); combat_manager.gd calls it")
	assert_true(body.contains("is_instance_valid"),
		"set_pass_through does not guard against a freed body; an ally that "
		+ "fainted and was freed mid-fight would poison every later throw")
