extends TestCase

## The trainer's clips are BUILT AT RUN TIME, and one property of them decides
## whether he keeps moving.
##
## `test_animation_retarget.gd` covers the maths that puts a KayKit clip on the
## knight's skeleton. This covers what happens to the clip afterwards: the 25
## that get merged in all import with `loop_mode` 0, because glTF has no loop
## flag and Godot only infers one from a `-loop` name suffix that KayKit does not
## use. A clip with no loop plays once. `Running_A` is 0.80 seconds long, so the
## trainer ran for eight tenths of a second and then held the last frame of the
## cycle while still travelling at 7.6 m/s.
##
## D02 says these tests are for pure logic and not for scenes, and this is close
## to the line. It stays on the right side of it by never entering the tree: the
## model is built, its AnimationPlayer is read, and the node is freed. Nothing
## here renders, moves or takes input — it is asking a question about a resource
## the game builds, which is exactly the kind of thing that can be wrong while
## every frame still draws.

const TRAINER := preload("res://scripts/player/trainer_model.gd")
const CONFIG_PATH := "res://data/config/art.json"

## Roles the state machine can select in `trainer_model._clip_for_state`. A role
## whose clip is missing is a trainer stuck in whatever he was doing before.
const DRIVEN_ROLES := ["idle", "walk", "sprint", "jump", "throw"]


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).get("trainer", {}) if parsed is Dictionary else {}


## Build the trainer's body the way `_ready()` does, without a scene tree.
func _built() -> Node3D:
	var model := Node3D.new()
	model.set_script(TRAINER)
	var cfg := _config()
	if not bool(model.call("_build", str(cfg.get("model", "")))):
		model.free()
		return null
	return model


func _player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _player(child)
		if found != null:
			return found
	return null


## Every clip the state machine can ask for has to exist, or the trainer holds
## the pose he was last given for as long as that state lasts.
func test_every_driven_clip_exists() -> void:
	var model := _built()
	assert_ne(model, null, "the trainer model failed to build at all")
	if model == null:
		return
	var anim := _player(model)
	assert_ne(anim, null, "the built trainer has no AnimationPlayer")
	if anim != null:
		var clips: Dictionary = _config().get("clips", {})
		for role: String in DRIVEN_ROLES:
			var clip := str(clips.get(role, ""))
			assert_true(
				clip != "" and anim.has_animation(clip),
				"clips.%s is '%s', which the merged libraries do not provide" % [role, clip]
			)
	model.free()


## THE BUG. A held state needs a cycling clip; one that ends leaves the trainer
## frozen mid-stride while he is still travelling.
func test_held_clips_loop_and_the_throw_does_not() -> void:
	var model := _built()
	assert_ne(model, null, "the trainer model failed to build at all")
	if model == null:
		return
	var anim := _player(model)
	assert_ne(anim, null, "the built trainer has no AnimationPlayer")
	if anim != null:
		var cfg := _config()
		var looping := TRAINER.looping_clips(cfg)
		assert_true(looping.size() >= 3, "no locomotion clip is marked as looping at all")
		for clip: String in looping:
			assert_true(anim.has_animation(clip), "looping clip '%s' is missing" % clip)
			if anim.has_animation(clip):
				assert_eq(
					anim.get_animation(clip).loop_mode,
					Animation.LOOP_LINEAR,
					"'%s' is held for as long as its state lasts and must cycle" % clip
				)

		# The other half of the rule. A throw that looped would be a trainer
		# winding up forever, so the fix must not be "loop everything".
		var throw := str((cfg.get("clips", {}) as Dictionary).get("throw", ""))
		if throw != "" and anim.has_animation(throw):
			assert_eq(
				anim.get_animation(throw).loop_mode,
				Animation.LOOP_NONE,
				"the throw is fired once and must end"
			)
	model.free()


## The roles named in `looping_clips` must be roles that exist. A typo here is a
## clip that silently keeps its imported loop_mode of 0, which is the whole bug
## back again with no error anywhere.
func test_looping_roles_resolve_to_real_clips() -> void:
	var cfg := _config()
	var roles: Array = cfg.get("looping_clips", [])
	assert_false(roles.is_empty(), "art.json names no looping clips for the trainer")
	var clips: Dictionary = cfg.get("clips", {})
	for role: Variant in roles:
		assert_true(
			clips.has(str(role)),
			"looping_clips names the role '%s', which clips does not define" % role
		)
	assert_eq(
		TRAINER.looping_clips(cfg).size(),
		roles.size(),
		"a looping role resolved to no clip name"
	)
