extends "res://tests/test_case.gd"

## Owner playtest report, second round, watching a rendered walk cycle: "his
## arms bend backwards and look unnatural." Root-caused to the forearm/
## upper-arm swing amplitude in the baked walk/sprint clips being large
## enough that the hand travels up past the ribcage toward the shoulder
## strap (measured directly off the baked keyframes, tools/_probe_gait_keys.gd,
## and confirmed visually in a real render). `character_model.gd::
## _tame_gait_arm_swing()` corrects this at load time -- no Blender exists in
## this environment to re-bake `trainer_lod0.glb` with retuned authoring
## numbers, so the already-baked clips are pulled proportionally back toward
## their own rest pose instead. This pins that correction down so a future
## edit cannot silently widen the swing back to the reported-bad amount
## without a test going red, without needing a render to notice.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

## The untamed walk clip measured a forearm swing (rest-to-peak) of ~17
## degrees and an upper-arm swing of ~33 degrees (tools/_probe_gait_keys.gd,
## against trainer_lod0.glb as shipped before this fix). Bounds set at
## roughly double the TAMED expectation (~45% of that), so a real regression
## back toward the untamed amplitude fails loudly while leaving room for
## legitimate future re-tuning.
const MAX_FOREARM_SWING_DEG := 12.0
const MAX_UPPER_ARM_SWING_DEG := 24.0


func _build_trainer() -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	assert_true(bool(model.call("build", "trainer")), "trainer failed to build")
	return model


## Largest angular distance (degrees) any keyframe on the named bone's
## rotation track sits from that track's own first keyframe (its rest pose,
## which a cyclic clip already shares with its last frame).
func _max_swing_deg(animation: Animation, bone_suffix: String) -> float:
	var worst := 0.0
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		if not str(animation.track_get_path(track_idx)).ends_with(bone_suffix):
			continue
		var key_count := animation.track_get_key_count(track_idx)
		if key_count == 0:
			continue
		var rest: Quaternion = animation.track_get_key_value(track_idx, 0)
		for k in key_count:
			var value: Quaternion = animation.track_get_key_value(track_idx, k)
			worst = maxf(worst, rad_to_deg(rest.angle_to(value)))
	return worst


func test_walk_forearm_swing_is_tamed() -> void:
	var model := _build_trainer()
	var anim: AnimationPlayer = model.call("animation_player")
	var clip: Animation = anim.get_animation("walk")
	assert_true(clip != null, "trainer has no walk clip")
	if clip == null:
		return
	var swing := maxf(
		_max_swing_deg(clip, "LeftForeArm"), _max_swing_deg(clip, "RightForeArm")
	)
	assert_true(swing <= MAX_FOREARM_SWING_DEG,
		"walk forearm swing is %.1f deg, expected <= %.1f (the owner-reported unnatural gait)"
		% [swing, MAX_FOREARM_SWING_DEG])


func test_walk_upper_arm_swing_is_tamed() -> void:
	var model := _build_trainer()
	var anim: AnimationPlayer = model.call("animation_player")
	var clip: Animation = anim.get_animation("walk")
	assert_true(clip != null, "trainer has no walk clip")
	if clip == null:
		return
	var swing := maxf(_max_swing_deg(clip, "LeftArm"), _max_swing_deg(clip, "RightArm"))
	assert_true(swing <= MAX_UPPER_ARM_SWING_DEG,
		"walk upper-arm swing is %.1f deg, expected <= %.1f (the owner-reported unnatural gait)"
		% [swing, MAX_UPPER_ARM_SWING_DEG])


func test_sprint_forearm_swing_is_tamed() -> void:
	var model := _build_trainer()
	var anim: AnimationPlayer = model.call("animation_player")
	var clip: Animation = anim.get_animation("sprint")
	assert_true(clip != null, "trainer has no sprint clip")
	if clip == null:
		return
	var swing := maxf(
		_max_swing_deg(clip, "LeftForeArm"), _max_swing_deg(clip, "RightForeArm")
	)
	# Sprint is authored with a bigger raw swing than walk (a run really
	# does pump the arms more), so its own bound is looser -- this still
	# catches the taming being skipped or removed entirely, which is the
	# regression this test exists to catch.
	assert_true(swing <= MAX_FOREARM_SWING_DEG * 2.0,
		"sprint forearm swing is %.1f deg, expected <= %.1f"
		% [swing, MAX_FOREARM_SWING_DEG * 2.0])


## The idle/jump/throw clips were not part of the owner's report and this
## fix deliberately only touches walk/sprint (character_model.gd's own
## comment: OF5 already spent real effort on the legs, and widening scope
## risks the throw's own aimed-lob readability). Pins that scope down.
func test_throw_clip_is_not_touched() -> void:
	var model := _build_trainer()
	var anim: AnimationPlayer = model.call("animation_player")
	var clip: Animation = anim.get_animation("throw")
	assert_true(clip != null, "trainer has no throw clip")
	if clip == null:
		return
	var swing := _max_swing_deg(clip, "RightArm")
	assert_true(swing > MAX_UPPER_ARM_SWING_DEG,
		"throw's RightArm swing (%.1f deg) looks tamed too -- _tame_gait_arm_swing should only touch walk/sprint"
		% swing)
