extends "res://tests/test_case.gd"

## The conversation push-in (D73 §6, closure plan CL-G10).
##
## The owner's playtest said villagers read too small in dialogue. The decision
## was that this is a camera-depth problem — the camera blends to a two-shot at
## about 3.5m while the box is up and blends back when it closes — and
## explicitly NOT a change to villager scale, which has already been cut and
## re-cut. So what has to hold is:
##
##   1. opening a conversation actually moves the rig, to a shot that has the
##      speaker in front of the lens and the trainer's shoulder beside it;
##   2. closing it puts the rig back exactly where it was, because the
##      exploration yaw is a value the player authored;
##   3. indoors, where there is no 3.5m of floor behind the trainer, the shot
##      gives way to a closer over-shoulder instead of being clamped into a wall.
##
## WHY THE RIG IS DRIVEN BY HAND HERE. `tests/run_tests.gd` has no live
## SceneTree (see `tests/test_party_seam.gd`'s note on `Engine.get_main_loop()`),
## so there is no physics space to build a room in. The rig is therefore built
## detached and stepped by hand, and the ONE thing that genuinely needs a world —
## "how much space is behind the camera" — is injected through
## `set_occlusion_probe_for_tests`. Everything else is the rig's own code: the
## same `enter_conversation`, the same blend, the same restore the game runs.
## `tools/_capture_dialogue_camera.gd` runs the same cycle against real physics
## in the booted playground, indoors and out, by pressing the interaction button
## for real and photographing whatever the rig ends up looking at. That one needs
## a renderer and half an hour, so it is evidence a lane gathers rather than
## something every push runs; this file is the half that can never be skipped.

const RIG := preload("res://scripts/player/camera_rig.gd")
const CONVERSATION := preload("res://scripts/player/conversation_camera.gd")

## Steps of a fixed 1/60s. Long enough for any `blend_time` in camera.json to
## finish; the loops below stop early on their own condition.
const STEP := 1.0 / 60.0
const MAX_STEPS := 240

## Where the fixture stands. The speaker is 2.6m in front of the trainer along
## -Z, which is a normal greeting distance (`npc_body.gd`'s prompt radius is
## 3.8m).
const TRAINER_AT := Vector3(10.0, 0.0, 10.0)
const SPEAKER_AT := Vector3(10.0, 0.0, 7.4)
const SPEAKER_HEIGHT := 1.9


## A person to talk to. `conversation_camera.gd` accepts a speaker by duck type —
## `height()` and `has_model()` are what every `character_model.gd` descendant
## answers and what a berry bush or a gate does not — so this is that shape and
## nothing more.
class Villager extends Node3D:
	func height() -> float:
		return 1.9

	func has_model() -> bool:
		return true


var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _player: Node3D = null
var _speaker: Node3D = null


func before_each() -> void:
	_player = Node3D.new()
	_player.position = TRAINER_AT
	_speaker = Villager.new()
	_speaker.position = SPEAKER_AT

	_rig = SpringArm3D.new()
	_rig.set_script(RIG)
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 70.0
	_rig.add_child(_camera)
	# Runs the @onready assignments and then `_ready()`, which is what the engine
	# itself does on NOTIFICATION_READY. Calling `_ready()` directly would leave
	# `_camera` unbound inside the rig and every lens assertion below would pass
	# by doing nothing.
	_rig.notification(Node.NOTIFICATION_READY)
	_rig.set_target(_player)


func after_each() -> void:
	for node: Node in [_rig, _player, _speaker]:
		if node != null and is_instance_valid(node):
			node.free()
	_rig = null
	_camera = null
	_player = null
	_speaker = null


## --- the framing, as pure geometry ------------------------------------------

func test_the_frame_is_centred_on_the_person_talking() -> void:
	var cfg := CONVERSATION.config()
	var shot := CONVERSATION.solve(
		TRAINER_AT + Vector3.UP * 1.45,
		SPEAKER_AT + Vector3.UP * SPEAKER_HEIGHT * 0.78,
		Vector3.FORWARD, cfg)
	var pivot: Vector3 = shot["pivot"]
	var to_speaker := Vector2(SPEAKER_AT.x - TRAINER_AT.x, SPEAKER_AT.z - TRAINER_AT.z)
	var to_pivot := Vector2(pivot.x - TRAINER_AT.x, pivot.z - TRAINER_AT.z)
	var along := to_pivot.length() / to_speaker.length()
	assert_between(along, 0.6, 0.95,
		"the frame must be centred mostly on the speaker, not halfway between")


func test_the_rig_euler_actually_points_at_the_pivot() -> void:
	# The whole shot is delivered to the rig as `yaw`/`pitch`, and a SpringArm3D
	# hangs its camera along its own +Z. If the conversion is wrong the camera
	# ends up looking at the sky with a perfectly correct-looking dictionary.
	var shot := CONVERSATION.solve(
		Vector3(3.0, 1.45, -2.0), Vector3(-1.0, 1.6, 1.5),
		Vector3.FORWARD, CONVERSATION.config())
	var basis := Basis.from_euler(Vector3(float(shot["pitch"]), float(shot["yaw"]), 0.0))
	var dir: Vector3 = shot["dir"]
	assert_almost_eq(basis.z.distance_to(dir), 0.0, 0.001,
		"the arm's +Z must be the direction the camera was solved to stand along")


func test_the_camera_stands_behind_the_trainer_not_beside_the_speaker() -> void:
	var trainer_anchor := TRAINER_AT + Vector3.UP * 1.45
	var speaker_anchor := SPEAKER_AT + Vector3.UP * SPEAKER_HEIGHT * 0.78
	var shot := CONVERSATION.solve(
		trainer_anchor, speaker_anchor, Vector3.FORWARD, CONVERSATION.config())
	var camera_at: Vector3 = shot["pivot"] + Vector3(shot["dir"]) * float(shot["distance"])
	var axis := (speaker_anchor - trainer_anchor)
	axis.y = 0.0
	axis = axis.normalized()
	assert_true((camera_at - trainer_anchor).dot(axis) < 0.0,
		"the lens must be behind the trainer, looking past them at the speaker")
	assert_between(camera_at.distance_to(speaker_anchor), 3.0, 5.2,
		"the speaker must end up at roughly the decided 3.5m two-shot depth")


func test_the_camera_is_swung_off_the_axis_so_a_shoulder_is_in_frame() -> void:
	var trainer_anchor := TRAINER_AT + Vector3.UP * 1.45
	var speaker_anchor := SPEAKER_AT + Vector3.UP * SPEAKER_HEIGHT * 0.78
	var shot := CONVERSATION.solve(
		trainer_anchor, speaker_anchor, Vector3.FORWARD, CONVERSATION.config())
	var camera_at: Vector3 = shot["pivot"] + Vector3(shot["dir"]) * float(shot["distance"])
	var axis := (speaker_anchor - trainer_anchor)
	axis.y = 0.0
	axis = axis.normalized()
	var sideways := Vector3(axis.z, 0.0, -axis.x)
	var offset := absf((camera_at - trainer_anchor).dot(sideways))
	assert_between(offset, 0.35, 1.6,
		"a dead-on camera frames the back of the trainer's head; too far round frames neither")


func test_the_camera_is_never_put_inside_the_person_talking() -> void:
	# The player walking right into a villager to greet them. Left alone, a shot
	# solved from two anchors 20cm apart is a lens inside somebody's chest.
	var cfg := CONVERSATION.config()
	var shot := CONVERSATION.solve(
		Vector3(0.0, 1.45, 0.0), Vector3(0.15, 1.5, -0.2), Vector3.FORWARD, cfg)
	var camera_at: Vector3 = shot["pivot"] + Vector3(shot["dir"]) * float(shot["distance"])
	assert_true(camera_at.distance_to(Vector3(0.15, 1.5, -0.2))
			>= float(cfg["min_speaker_clearance"]) - 0.001,
		"the solved camera must stay outside the speaker's own body")


func test_a_speaker_is_a_character_and_a_fence_post_is_not() -> void:
	var villager := Villager.new()
	var post := Node3D.new()
	var prompt := Node3D.new()
	villager.add_child(prompt)
	assert_eq(CONVERSATION.resolve_speaker(villager), villager)
	assert_eq(CONVERSATION.resolve_speaker(prompt), villager,
		"the arbiter hands over the prompt node; the person is its parent")
	assert_eq(CONVERSATION.resolve_speaker(post), null,
		"a cart or a gate opens dialogue with nobody to frame, and must not move the camera")
	assert_eq(CONVERSATION.resolve_speaker(null), null)
	villager.free()
	post.free()


## --- a real open/close cycle on the rig -------------------------------------

func test_opening_a_conversation_moves_the_rig_to_the_two_shot() -> void:
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_clear_room)
	var before_yaw: float = _rig.yaw
	var before_pos := CONVERSATION.world_position(_rig)

	assert_true(_rig.enter_conversation(_speaker, cfg), "the push-in must engage")
	_settle_until_blended(1.0)

	var shot: Dictionary = _rig.conversation_shot()
	assert_almost_eq(_rig.spring_length, float(cfg["distance"]), 0.02,
		"the arm must be at the decided two-shot length with the room to do it")
	assert_almost_eq(CONVERSATION.world_position(_rig).distance_to(shot["pivot"]), 0.0, 0.02,
		"the arm's origin must be the framing pivot once the blend has finished")
	assert_true(absf(CONVERSATION.world_position(_rig).distance_to(before_pos)) > 0.5,
		"a push-in that does not move the camera is not a push-in")
	assert_ne(_rig.yaw, before_yaw)
	assert_almost_eq(_camera.fov, float(cfg["fov"]), 0.02,
		"the lens must narrow, or the speaker is the same size on screen as before")
	assert_true(_rig.is_in_conversation())
	assert_false(_rig.conversation_used_fallback(),
		"outdoors with clear space behind, the full two-shot must be used")


func test_closing_a_conversation_restores_the_rig_it_borrowed() -> void:
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_clear_room)
	_rig.yaw = 0.9
	_rig.pitch = -0.2
	var before_yaw: float = _rig.yaw
	var before_pitch: float = _rig.pitch
	var before_length: float = _rig.spring_length
	var before_fov: float = _camera.fov

	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)
	_rig.exit_conversation()
	_settle_until_blended(0.0)

	assert_almost_eq(_rig.yaw, before_yaw, 0.001,
		"the exploration yaw is player-authored; it must come back exactly")
	assert_almost_eq(_rig.pitch, before_pitch, 0.001)
	assert_almost_eq(_rig.spring_length, before_length, 0.02)
	assert_almost_eq(_camera.fov, before_fov, 0.02)
	assert_almost_eq(
		CONVERSATION.world_position(_rig).distance_to(CONVERSATION.world_position(_player) + Vector3.UP * 1.75),
		0.0, 0.05, "the rig must be back on the trainer's own orbit")
	assert_false(_rig.is_in_conversation())


func test_the_shot_owns_the_camera_while_the_box_is_up() -> void:
	# Controller and mouse look are ignored for the duration (the brief's
	# requirement, and the reason the shot is allowed to be a composition at
	# all). Proven by shoving the rig off the shot mid-conversation: the next
	# step must put it straight back, because nothing but the blend writes here.
	_rig.set_occlusion_probe_for_tests(_clear_room)
	assert_true(_rig.enter_conversation(_speaker, CONVERSATION.config()))
	_settle_until_blended(1.0)
	var framed: float = _rig.yaw
	_rig.yaw = framed + 1.2
	_rig.rotation = Vector3(_rig.pitch, _rig.yaw, 0.0)
	_rig._physics_process(STEP)
	assert_almost_eq(_rig.yaw, framed, 0.001,
		"look input must not be able to drag the camera off the conversation")


func test_a_conversation_with_nobody_to_frame_leaves_the_camera_alone() -> void:
	var before := CONVERSATION.world_position(_rig)
	# 20m away: the road gate's lock message is spoken from wherever the player
	# happens to be standing.
	_speaker.position = TRAINER_AT + Vector3(0.0, 0.0, -20.0)
	assert_false(_rig.enter_conversation(_speaker, CONVERSATION.config()),
		"a speaker outside the two-shot's range must not take the camera")
	assert_false(_rig.is_in_conversation())
	assert_almost_eq(CONVERSATION.world_position(_rig).distance_to(before), 0.0, 0.001)


func test_a_fight_taking_the_camera_beats_a_conversation_still_blending() -> void:
	_rig.set_occlusion_probe_for_tests(_clear_room)
	_rig.yaw = 0.4
	assert_true(_rig.enter_conversation(_speaker, CONVERSATION.config()))
	_settle_until_blended(1.0)
	var ally := Node3D.new()
	ally.position = TRAINER_AT + Vector3(1.0, 0.0, -1.0)
	_rig.set_target(ally)
	assert_false(_rig.is_in_conversation())
	assert_almost_eq(_rig.yaw, 0.4, 0.001,
		"the borrowed pose must be handed back before the new target takes over")
	assert_almost_eq(_camera.fov, 70.0, 0.02)
	ally.free()


func test_the_push_in_survives_the_idle_tick_being_switched_off() -> void:
	# The defect this locks out, and it is the one that made a shipped push-in
	# do nothing at all: `scripts/story/sequence_director.gd` gates the rig with
	# `_camera_rig.set_process(not panel)`, so for the whole length of every
	# conversation the rig's idle tick is OFF by design — that is how the stick
	# look and the follow are suspended while you read. A blend living on
	# `_process` therefore advanced one frame and froze five per cent in.
	_rig.set_occlusion_probe_for_tests(_clear_room)
	assert_true(_rig.enter_conversation(_speaker, CONVERSATION.config()))
	_rig.set_process(false)

	for _i in MAX_STEPS:
		# Only the tick a suspended rig still gets. `_process` is not called at
		# all here, exactly as the running game does not call it.
		_rig._physics_process(STEP)
		if is_equal_approx(float(_rig.conversation_blend()), 1.0):
			break
	assert_almost_eq(float(_rig.conversation_blend()), 1.0, 0.001,
		"the push-in must finish with the rig's idle tick switched off")
	assert_almost_eq(_rig.spring_length, float(CONVERSATION.config()["distance"]), 0.02)


## --- who the push-in decides it is talking to -------------------------------

## A stand-in for `interaction_arbiter.gd` with the ONE behaviour that matters
## here: `activate()` calls the provider's own `interaction_activate` first and
## emits `activated` only afterwards, exactly as the real arbiter does.
class Arbiter extends Node:
	signal activated(provider: Object)

	var current: Object = null
	var on_activate: Callable = Callable()

	func _ready() -> void:
		add_to_group("interaction_arbiter")

	func winning_provider() -> Object:
		return current

	func activate() -> bool:
		if current == null:
			return false
		# The villager's `interaction_activate` opens the dialogue panel, which
		# is what pushes the camera in. It happens BEFORE the signal.
		if on_activate.is_valid():
			on_activate.call()
		activated.emit(current)
		return true


func test_the_push_in_frames_the_person_being_activated_not_the_one_before() -> void:
	# The defect this locks out: reading the speaker from the `activated` signal
	# meant the first conversation of a session had no speaker at all (nothing
	# had been activated yet) and every later one framed the PREVIOUS villager.
	# `tools/_capture_dialogue_camera.gd` reported it as "the conversation opened
	# but the camera never pushed in".
	var tree := Node.new()
	var arbiter := Arbiter.new()
	tree.add_child(arbiter)
	arbiter.notification(Node.NOTIFICATION_READY)

	var watcher: Node = _rig.get_node_or_null(^"ConversationCamera")
	assert_ne(watcher, null, "the rig must build its own push-in watcher")
	# The watcher finds the arbiter through the group, which needs a live tree;
	# this suite has none, so it is handed over the same way `_bind_arbiter`
	# would have found it.
	watcher.set("_arbiter", arbiter)

	arbiter.current = _speaker
	assert_eq(watcher.call("current_speaker"), _speaker,
		"the speaker must be read from the arbiter's LIVE winner, mid-activate")

	# And the stale remembered provider must never win over the live one.
	var stale := Villager.new()
	watcher.call("note_activation_for_tests", stale)
	assert_eq(watcher.call("current_speaker"), _speaker,
		"a provider remembered from the last conversation must not be framed")

	stale.free()
	arbiter.free()
	tree.free()


func test_with_no_arbiter_the_remembered_provider_is_still_used() -> void:
	# A conversation opened by a story beat rather than a button press has no
	# live winner to read, and must still frame whoever was last walked up to.
	var watcher: Node = _rig.get_node_or_null(^"ConversationCamera")
	watcher.call("note_activation_for_tests", _speaker)
	assert_eq(watcher.call("current_speaker"), _speaker)


## --- the walled fixture -----------------------------------------------------

func test_a_cramped_room_falls_back_to_a_closer_over_the_shoulder() -> void:
	# Bram's inn and Mira's cottage: under two metres of floor behind the
	# trainer. The full two-shot cannot be stood up there, and an arm the engine
	# then clamps to whatever is left is a camera looking at plasterwork.
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_wall_at_1_8m)
	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)

	assert_true(_rig.conversation_used_fallback(),
		"1.8m of room must not be filled with a 3.5m two-shot")
	assert_almost_eq(_rig.spring_length, 1.8, 0.02,
		"the fallback must then be held to the room actually measured")
	var shot: Dictionary = _rig.conversation_shot()
	assert_true(float(shot["distance"]) < float(cfg["distance"]),
		"the fallback shot must be shorter than the shot it replaced")
	assert_true(float(shot["fov"]) > float(cfg["fov"]),
		"a closer camera needs a wider lens or the speaker overflows the frame")


func test_a_cramped_room_still_keeps_the_lens_out_of_the_trainers_head() -> void:
	# The defect a blind judge found in a real captured frame of Bram's inn:
	# the shot fell back, the arm was cut to the room and then cut AGAIN by the
	# spring arm's own 0.6m margin, and the lens finished 0.36m from the
	# trainer's centre line with their hair filling the left third of the
	# picture as unlit backfaces. The room cannot grow, so the speaker bias is
	# what has to give.
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_wall_at_1_8m)
	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)

	var shot: Dictionary = _rig.conversation_shot()
	var trainer_anchor := TRAINER_AT + Vector3.UP * float(cfg["trainer_anchor_height"])
	assert_true(
		CONVERSATION.trainer_clearance_of(shot, trainer_anchor)
			>= float(cfg["min_trainer_clearance"]) - 0.01,
		"the lens must stay behind the trainer's head even with no room to do it in")
	assert_true(float(shot["distance"]) > 0.0)


func test_the_measured_room_is_the_room_the_camera_can_actually_use() -> void:
	# `SpringArm3D` holds `margin` back from whatever it hits, so an arm set to
	# the raw hit distance is placed that much shorter — forward of everything
	# the shot was solved for. The probe must report the usable length, not the
	# raw one, or every guard downstream is computed for a camera that is not
	# where it says.
	var raw := 2.4
	var usable: float = _rig.call("_free_distance_behind", TRAINER_AT, Vector3.FORWARD, 4.0)
	# With no world and no injected probe the query cannot run and the full
	# limit is the honest answer; the interesting case is an actual hit.
	assert_almost_eq(usable, 4.0, 0.001, "no world to sweep means no reported obstruction")
	_rig.set_occlusion_probe_for_tests(func(_p: Vector3, _d: Vector3, limit: float) -> float:
		return minf(raw, limit))
	assert_almost_eq(
		float(_rig.call("_free_distance_behind", TRAINER_AT, Vector3.FORWARD, 4.0)), raw, 0.001,
		"an injected probe answers the usable length itself and is not trimmed twice")


func test_the_same_fixture_with_room_behind_it_keeps_the_two_shot() -> void:
	# The control that stops the case above passing vacuously: identical
	# geometry, identical call, and the only difference is how much space the
	# probe reports. If this ever starts falling back, the fallback is being
	# driven by something other than the room.
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_clear_room)
	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)
	assert_false(_rig.conversation_used_fallback())
	assert_almost_eq(_rig.spring_length, float(cfg["distance"]), 0.02)


func test_a_corner_swings_the_camera_to_the_side_the_room_is_on() -> void:
	# Backed into a corner: a wall a metre behind the trainer's shoulders, open
	# floor off to one side. A shot that insists on standing behind them gets
	# either the wall or the back of their head — captured once in Bram's inn,
	# the trainer's hair filling the middle of frame with the speaker entirely
	# hidden behind it. The camera has to go where the room is.
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(_wall_behind_open_to_the_side)
	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)

	assert_true(_rig.conversation_used_fallback())
	var shot: Dictionary = _rig.conversation_shot()
	var axis := (SPEAKER_AT - TRAINER_AT).normalized()
	var dir: Vector3 = shot["dir"]
	var planar := Vector3(dir.x, 0.0, dir.z).normalized()
	# Straight back down the axis is what the room does not allow. Anything
	# meaningfully off it is the search having done its job.
	assert_true(absf(planar.dot(-axis)) < 0.9,
		"the shot must swing off the blocked axis, not stand in the wall")
	assert_true(float(shot["distance"]) > 1.5,
		"having swung to the open side, the shot gets a usable arm back")
	var trainer_anchor := TRAINER_AT + Vector3.UP * float(cfg["trainer_anchor_height"])
	assert_true(
		CONVERSATION.trainer_clearance_of(shot, trainer_anchor)
			>= float(cfg["min_trainer_clearance"]) - 0.01,
		"and is still outside the trainer")


func test_a_wall_pressed_against_the_lens_never_collapses_the_arm() -> void:
	var cfg := CONVERSATION.config()
	_rig.set_occlusion_probe_for_tests(func(_p: Vector3, _d: Vector3, _l: float) -> float:
		return 0.05)
	assert_true(_rig.enter_conversation(_speaker, cfg))
	_settle_until_blended(1.0)
	assert_almost_eq(_rig.spring_length, float(cfg["min_distance"]), 0.02,
		"the arm must floor at min_distance, not collapse into the trainer's head")


func test_the_fallback_config_replaces_the_shot_and_drops_its_own_key() -> void:
	var cfg := CONVERSATION.config()
	var tighter := CONVERSATION.fallback_config(cfg)
	assert_false(tighter.has("fallback"),
		"a fallback that still carries a fallback can recurse")
	assert_true(float(tighter["distance"]) < float(cfg["distance"]))
	assert_almost_eq(float(tighter["min_distance"]), float(cfg["min_distance"]), 0.001,
		"guards the fallback does not override must survive the merge")
	assert_almost_eq(
		float(tighter["min_trainer_clearance"]), float(cfg["min_trainer_clearance"]), 0.001,
		"the closer shot is the one that needs the trainer guard most; it must survive too")


func test_a_room_ceiling_never_pushes_the_lens_through_the_trainer() -> void:
	# The solver's own half of the same guard, as pure geometry across a sweep
	# of rooms from generous to hopeless. No rig, no blend: if this can be made
	# to fail, no amount of care in the rig can save the frame.
	var cfg := CONVERSATION.fallback_config(CONVERSATION.config())
	var trainer_anchor := Vector3(0.0, 1.45, 0.0)
	var speaker_anchor_point := Vector3(0.0, 1.48, -1.83)
	for tenths in range(3, 36):
		var room := float(tenths) * 0.1
		var shot := CONVERSATION.solve(
			trainer_anchor, speaker_anchor_point, Vector3.FORWARD, cfg, room)
		var clear := CONVERSATION.trainer_clearance_of(shot, trainer_anchor)
		# Below the guard's own value there is simply not that much arm; the
		# shot must then spend ALL of it standing clear of the trainer, which is
		# bias zero and a clearance equal to the whole arm.
		var want := minf(float(cfg["min_trainer_clearance"]), float(shot["distance"]))
		assert_true(clear >= want - 0.01,
			"a %.1fm room left the lens %.2fm from the trainer, wanted %.2fm"
				% [room, clear, want])


## --- helpers ----------------------------------------------------------------

## Step the rig until the push-in blend reaches `weight` (1 = the two-shot,
## 0 = back on the exploration orbit), and fail loudly if it never gets there.
##
## Early-exit rather than a fixed frame count on purpose: past the end of the
## exit blend the rig hands itself back to `_follow()`, which reads and writes
## `global_position` directly and is meaningless on a node with no tree to be
## global in. Stopping the moment the blend is done is also what the assertion
## is actually about — "the pose came back", not "the pose came back and then
## survived four more seconds of a follow that cannot run here".
func _settle_until_blended(weight: float) -> void:
	for _i in MAX_STEPS:
		# The push-in is driven on the physics tick — see `camera_rig.gd`'s
		# `_physics_process` for why it cannot live on the idle one.
		_rig._physics_process(STEP)
		if is_equal_approx(float(_rig.conversation_blend()), weight):
			return
	assert_true(false, "the conversation blend never reached %.1f" % weight)


func _clear_room(_pivot: Vector3, _dir: Vector3, limit: float) -> float:
	return limit


func _wall_at_1_8m(_pivot: Vector3, _dir: Vector3, limit: float) -> float:
	return minf(1.8, limit)


## A corner. The fixture pair stands along -Z, so "behind the trainer" is +Z:
## that direction has a wall a metre out, and everything off it is open floor.
func _wall_behind_open_to_the_side(_pivot: Vector3, dir: Vector3, limit: float) -> float:
	var planar := Vector3(dir.x, 0.0, dir.z).normalized()
	if planar.dot(Vector3.BACK) > 0.9:
		return minf(1.0, limit)
	return limit
