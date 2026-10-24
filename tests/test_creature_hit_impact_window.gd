extends "res://tests/test_case.gd"

# P2-016 (GPU F38 fight scan): hurt poses kept the idle silhouette in a real
# fight. A remake playing its own held hit clip started from the neutral lead-in,
# hitstop froze that frame, and the next movement request cancelled the hold.
# A species may now name its own hit's impact window (`hit_impact`), and the
# animator then treats it like an installed recipe's: start at the wince and
# hold it until the release phase.

const ANIMATOR := preload("res://scripts/creatures/creature_animator.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HIT_LENGTH := 0.5

var _player: AnimationPlayer


func before_each() -> void:
	_player = AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for clip: String in ["idle", "walk", "run", "attack", "hit", "faint"]:
		var animation := Animation.new()
		animation.length = HIT_LENGTH
		library.add_animation(clip, animation)
	_player.add_animation_library("", library)


func after_each() -> void:
	_player.free()


func _animator(extra: Dictionary) -> RefCounted:
	var clips := {"idle": "idle", "walk": "walk", "run": "run", "attack": "attack",
		"hit": "hit", "faint": "faint"}
	clips.merge(extra)
	return ANIMATOR.new(_player, clips)


func test_named_impact_window_starts_at_the_wince_and_survives_movement() -> void:
	var animator := _animator({"hit_start_phase": 0.12, "hit_release_phase": 0.5})
	animator.call("play_once", "hit")
	assert_eq(_player.current_animation, "hit", "the hit clip plays")
	assert_almost_eq(float(animator.get("_hold")), HIT_LENGTH * (1.0 - 0.12), 0.0001,
		"the hold starts from the impact sample, not the neutral lead-in")
	animator.call("cancel_hold")
	assert_true(float(animator.get("_hold")) > 0.0,
		"a same-step movement request cannot cancel the wince inside its window")


func test_without_a_window_the_installed_hit_behaves_as_before() -> void:
	var animator := _animator({})
	animator.call("play_once", "hit")
	assert_almost_eq(float(animator.get("_hold")), HIT_LENGTH, 0.0001, "the whole clip holds")
	animator.call("cancel_hold")
	assert_almost_eq(float(animator.get("_hold")), 0.0, 0.0001, "movement still cancels it")


func test_species_impact_windows_are_ordered_phases_on_a_hit_clip() -> void:
	var named := 0
	for id: String in SPECIES.table().keys():
		var look := SPECIES.placeholder(id)
		var impact: Variant = look.get("hit_impact", null)
		if impact == null:
			continue
		named += 1
		assert_true(impact is Dictionary, "%s hit_impact is a block" % id)
		if not impact is Dictionary:
			continue
		var start := float((impact as Dictionary).get("start_phase", -1.0))
		var release := float((impact as Dictionary).get("release_phase", -1.0))
		assert_true(start > 0.0 and start < release and release < 1.0,
			"%s impact window %.2f..%.2f is ordered inside the clip" % [id, start, release])
		assert_true(str((look.get("animations", {}) as Dictionary).get("hit", "")) != "",
			"%s names a hit clip for its window" % id)
	assert_true(named >= 1, "the remakes name their impact windows")
