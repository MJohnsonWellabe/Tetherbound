extends SceneTree

## OP21-24: photograph the trainer chopping, so the swing and the grip can be
## judged by eye instead of asserted by a test.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     ~/.cache/tetherbound-art/godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_chop_swing.gd
##
## Frames land in shots/chop_swing/<TAG>/ (TAG defaults to `current`).
##
## RE-BAKE THE CLIP AND THIS TOOL WILL STILL PHOTOGRAPH THE OLD ONE until the
## project is re-imported. A `--script` run loads the IMPORTED form out of
## `.godot/`, and replacing `trainer_lod0.glb` on disk does not invalidate it,
## so a re-keyed clip renders frame-for-frame identical to the version it
## replaced and reads as "the change had no effect". Run
## `godot --headless --path . --import` between the bake and the capture.
##
## ## Why this is a bare scene and not the playground
##
## `capture_torch_night.gd` boots `meadows_playground.tscn` because the thing
## it photographs IS the world's light. Nothing here is: this is one body, one
## clip and one prop in the trainer's hand. The corridor's boot — terrain,
## ~130k scatter instances, village, stronghold, relay — is pure cost, and
## `docs/CURRENT_STATE.md`'s `PERF-LOD` entry records four capture attempts that
## died to exactly that cost on exactly this container, one of them at 43
## minutes without emitting a frame. So this builds the sun/sky rig, a flat
## pad, the real `scenes/player/player.tscn` and one real harvest node, the
## same way `capture_interior.gd` builds one room.
##
## ## What is real here and what is staged
##
## Real: the player scene, `trainer_model.gd` picking the clip from the
## trainer's own state, `tool_hold.gd` bone-attaching the prop from
## `items.json`, the authored `chop` clip inside `trainer_lod0.glb`, and the
## camera rig at its ordinary exploration distance.
##
## Staged: the swing is held open (`play_tool_swing` with a long duration) and
## the clip is then SEEKED to each pose. That is deliberate. A capture that
## waits on wall-clock to catch a 15-frame clip at frame 9 photographs a
## different pose every run on a contended box, which is unjudgeable — and the
## thing a blind critic has to answer ("does the impact frame read as an axe
## buried in wood?") is a question about a specific pose. The clip being
## seeked is still the clip gameplay chose: `_role_for_state()` selects it
## because a swing is genuinely running.
##
## The last vantage is a close-up on the hands at the impact pose, because
## half of OP21-24 is the grip — "the trainer does not hold the axe in a
## believable expected grip/pose" — and a full-body frame at exploration
## distance cannot resolve a hand on a haft.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")

const OUT_ROOT := "res://shots/chop_swing"
const SETTLE_FRAMES := 45
const SHOT_FRAMES := 6

## The tool in hand, and the clip to photograph it with.
const TOOL_ID := "axe"
const CLIP := "chop"
## Long enough that the swing state never lapses back to idle mid-capture.
const HELD_SWING_SECONDS := 600.0

## Where the tree stands relative to the player: straight ahead, at the reach
## `tool_hold.gd::SWING_REACH` connects well inside (3.2m), but the frame has
## to answer "does the hit look like it LANDS" -- at the cone's outer edge the
## axe is visibly a metre short of the trunk, which is a staging artefact, not
## the swing.
const TARGET_AHEAD := 1.35

## Clip position (seconds) -> frame name. `animate_humanoid.py::author_chop()`
## runs 15 frames at 24 fps and keys ready/raise/impact/follow at frames
## 0/4/9/11, so these are those poses in seconds. Re-derive if the clip is
## re-timed; `art.json`'s `trainer.tool_swing.impact_fraction` is the same
## number the game uses for the gather.
## The exported clip does NOT start at zero: Blender stashes the action as an
## NLA strip beginning at frame 1, so the glTF sampler times run 0.0417 ..
## 0.6667 and the authored frames 0/4/9/11/15 land at those times plus 0.0417.
## Verified by reading the sampler inputs out of the GLB, not assumed -- a
## `seek(0.02)` reads as "before the first key" and clamps, which is a silent
## way to photograph the wrong pose.
const CLIP_START := 0.0417
const POSES := [
	[CLIP_START, "01-ready"],
	[CLIP_START + 4.0 / 24.0, "02-raise"],
	[CLIP_START + 9.0 / 24.0, "03-impact"],
	[CLIP_START + 11.0 / 24.0, "04-follow-through"],
]

## Full-body vantage: the ordinary over-the-shoulder-ish three-quarter view a
## player actually chops from, not a flattering orthographic profile.
## Two body vantages, because one is not enough to judge a swing: a
## three-quarter view from the player's own side of the tree (what they see in
## play) and a profile from the trainer's left, which is the only angle where
## BOTH arms and the full arc of the axe are unoccluded. The first run of this
## tool shot only the first and could not answer whether the off hand joins the
## swing at all.
const BODY_YAW_DEG := 200.0
const BODY_PITCH_DEG := -8.0
const PROFILE_YAW_DEG := 110.0
const PROFILE_PITCH_DEG := -4.0

## Hands close-up, framed manually rather than through the rig: the rig's own
## minimum distance is an exploration distance and cannot get near a wrist.
## Shot from off the trainer's right shoulder rather than straight down his
## sightline: he faces +Z (the trunk), so a camera further along +Z gets bark
## in the way and one at -Z photographs his backpack. Both were tried.
const HAND_CAM_OFFSET := Vector3(1.05, 0.28, 0.30)
const HAND_CAM_FOV := 38.0


func _init() -> void:
	_run()


func _run() -> void:
	var tag := OS.get_environment("TAG")
	if tag == "":
		tag = "current"
	var out := "%s/%s" % [OUT_ROOT, tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	var world := Node3D.new()
	world.name = "ChopStage"
	root.add_child(world)
	# Same reason capture_interior.gd awaits here: nothing added in _init() is
	# inside the tree yet, and to_global() on a node that is not silently
	# answers with an identity transform instead of erroring.
	await process_frame

	_build_lighting(world)
	_build_ground(world)

	# The rig FIRST: player.tscn's `camera_rig_path` is the sibling NodePath
	# `../CameraRig`, resolved in the player's own _ready(), so a rig added
	# afterwards is a rig the controller never finds.
	var rig: SpringArm3D = _build_camera_rig(world)
	# Checked rather than assumed: `set_script` on a node of the wrong base
	# class fails with an error and leaves the node scriptless, and a SceneTree
	# tool that then walks off a script error keeps iterating forever with no
	# frames and no message -- twelve minutes of it, the first time.
	if not rig.has_method("set_target"):
		push_error("camera_rig.gd did not attach to the rig; nothing can be framed")
		quit(1)
		return

	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3.ZERO
	rig.call("set_target", player)

	_build_target(world)
	# Face the tree the way `player_controller.gd::_face()` does during a real
	# walk-up: Model only, never the body.
	var model_node := player.get_node_or_null(^"Model") as Node3D
	if model_node != null:
		model_node.rotation.y = atan2(0.0, TARGET_AHEAD)

	# The tool reaches the hand the way it does in play: the Game autoload's
	# equipped_tool, watched by tool_hold.gd. Set BEFORE settling so the prop
	# is built and bone-attached by the time anything is photographed.
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no /root/Game autoload; the tool would never reach the hand")
		quit(1)
		return
	game.set("equipped_tool", TOOL_ID)

	for i in SETTLE_FRAMES:
		await process_frame

	var model := player.get_node_or_null(^"Model")
	var hold := player.get_node_or_null(^"ToolHold")
	if model == null or hold == null:
		push_error("player scene has no Model/ToolHold; nothing to photograph")
		quit(1)
		return

	# Prove the two things the frames would otherwise only imply, in the log:
	# that the prop is genuinely in the hand, and that the clip being
	# photographed is the authored chop rather than the throw it used to
	# borrow. A capture that silently falls back is worse than one that fails.
	var prop: Variant = hold.call("prop_node")
	print("prop in hand: %s" % ("<none>" if prop == null else str((prop as Node).name)))
	# The other half of OP21-24 is the GRIP, and "the axe looks like a toy" is a
	# measurement, not an impression: print the prop's real world-space length
	# next to the trainer's own height so the two can be compared directly.
	if prop != null:
		_report_prop_size(prop as Node3D, player)
	var anim := model.call("animation_player") as AnimationPlayer
	if anim == null:
		push_error("trainer has no AnimationPlayer")
		quit(1)
		return
	print("clip present: chop=%s throw=%s" % [anim.has_animation(CLIP), anim.has_animation("throw")])
	if not anim.has_animation(CLIP):
		push_error("no '%s' clip on the trainer rig -- re-bake with animate_humanoid.py" % CLIP)
		quit(1)
		return

	# A real swing, started the way the player starts one, so the ROLE is
	# chosen by trainer_model.gd rather than asserted here -- then held open so
	# the poses below can be seeked without the state lapsing.
	hold.call("swing")
	model.call("play_tool_swing", HELD_SWING_SECONDS)
	await process_frame
	await process_frame
	print("playing: %s (expected %s)" % [anim.current_animation, CLIP])

	for spec: Array in POSES:
		var at := float(spec[0])
		var name := String(spec[1])
		await _shoot_body(rig, anim, at, "%s/%s.png" % [out, name],
			BODY_YAW_DEG, BODY_PITCH_DEG)
	for spec: Array in POSES:
		var at := float(spec[0])
		var name := String(spec[1])
		await _shoot_body(rig, anim, at, "%s/profile-%s.png" % [out, name],
			PROFILE_YAW_DEG, PROFILE_PITCH_DEG)

	await _shoot_hands(world, player, anim, "%s/05-grip-closeup.png" % out)

	print("done: %d frames in %s" % [POSES.size() * 2 + 1, out])
	quit(0)


## Hold the clip at one pose for a few frames, then save. The seek is re-issued
## every frame because trainer_model.gd's own _physics_process keeps driving
## the AnimationPlayer, and a single seek would be advanced past by the next
## tick.
func _shoot_body(rig: SpringArm3D, anim: AnimationPlayer, at: float, path: String,
		yaw_deg: float, pitch_deg: float) -> void:
	for i in SHOT_FRAMES:
		rig.set("yaw", deg_to_rad(yaw_deg))
		rig.set("pitch", deg_to_rad(pitch_deg))
		anim.seek(at, true)
		await process_frame
	root.get_texture().get_image().save_png(path)
	# The pose, as a number. Eyeballing a 1280x720 frame is how the ready pose
	# got mistaken for the raise once already; the axe head's height above the
	# trainer's feet says which pose this actually is.
	print("shot -> %s  (t=%.3f of %.3f, axe head %.2fm up)" % [
		path, at, anim.get_animation(anim.current_animation).length, _prop_top_height()])


## The grip, at the impact pose, from close enough to see a hand. Its own
## Camera3D made current for the shot and dropped afterwards, so nothing about
## the rig's own framing has to be disturbed.
func _shoot_hands(world: Node3D, player: Node3D, anim: AnimationPlayer, path: String) -> void:
	var cam := Camera3D.new()
	cam.name = "GripCamera"
	cam.fov = HAND_CAM_FOV
	world.add_child(cam)
	cam.make_current()
	# Aimed at the PROP, not at a guessed height on the body. The impact pose
	# puts the hands near the waist and the first version of this shot framed
	# the trainer's chin, which is the one part of him this half of OP21-24 is
	# not about.
	for i in SHOT_FRAMES:
		anim.seek(0.375, true)
		await process_frame
		var hold: Node = player.get("tool_hold")
		var prop := (hold.call("prop_node") if hold != null else null) as Node3D
		var look_at := player.global_position + Vector3(0.0, 1.1, 0.0)
		if prop != null:
			look_at = prop.global_position
		cam.global_position = look_at + HAND_CAM_OFFSET
		cam.look_at(look_at, Vector3.UP)
	root.get_texture().get_image().save_png(path)
	print("shot -> %s" % path)
	cam.queue_free()


## Height of the top of the held prop above the trainer's feet, or NAN with
## nothing in hand. Cheap pose telemetry for the log.
func _prop_top_height() -> float:
	var player := root.get_node_or_null(^"ChopStage/Player") as Node3D
	if player == null:
		return NAN
	var hold: Node = player.get("tool_hold")
	var prop := (hold.call("prop_node") if hold != null else null) as Node3D
	if prop == null:
		return NAN
	var top := -INF
	for node in _all_descendants(prop):
		var mesh := node as VisualInstance3D
		if mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		top = maxf(top, box.position.y + box.size.y)
	return top - player.global_position.y


## World-space size of whatever is in the hand, measured off the visual AABBs
## of its own MeshInstance3Ds rather than the local mesh bounds -- the prop
## hangs off a BoneAttachment3D inside a skeleton that `character_model._fit()`
## has scaled, so local size and the size a player sees are not the same
## number, and only the second one is the complaint.
func _report_prop_size(prop: Node3D, player: Node3D) -> void:
	var bounds := AABB()
	var seen := false
	for node in _all_descendants(prop):
		var mesh := node as VisualInstance3D
		if mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = box if not seen else bounds.merge(box)
		seen = true
	if not seen:
		print("prop size: no VisualInstance3D under %s" % prop.name)
		return
	var body_bounds := AABB()
	var body_seen := false
	for node in _all_descendants(player):
		var mesh := node as VisualInstance3D
		if mesh == null or not mesh.visible:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		body_bounds = box if not body_seen else body_bounds.merge(box)
		body_seen = true
	var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	print("prop size: %.2f x %.2f x %.2f m (longest %.2f m); trainer %.2f m tall; axe is %.0f%% of the body" % [
		bounds.size.x, bounds.size.y, bounds.size.z, longest,
		body_bounds.size.y, 100.0 * longest / maxf(body_bounds.size.y, 0.01)])


func _all_descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_descendants(child))
	out.append(node)
	return out


## Sun, sky and fog, in the shape capture_interior.gd uses. Plain daylight on
## purpose: this frame is about a body and a prop, and a graded time-of-day
## would put the thing being judged in shadow.
func _build_lighting(world: Node3D) -> void:
	var env_holder := WorldEnvironment.new()
	env_holder.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)


## A flat pad with collision, so the CharacterBody3D has something to stand on
## and the shadow has something to fall across.
func _build_ground(world: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.4, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)


## The tree being chopped: the real harvest node, not a stand-in cylinder, so
## the frame shows the axe meeting the thing the swing actually resolves
## against and at the size the player sees. Spec copied from the first `wood`
## entry in data/config/bands/*/harvest.json rather than invented, so the trunk
## in frame is the trunk in the game.
func _build_target(world: Node3D) -> void:
	var tree := HARVEST_NODE.new()
	tree.name = "ChopTarget"
	tree.call("setup", {
		"item": "wood",
		"amount": 4,
		"label": "Gather deadwood",
		"model": "res://assets/environment/stylized_nature/DeadTree_2.gltf",
		"model_scale": 0.22,
	})
	world.add_child(tree)
	# `Model`'s forward on this rig is +basis.z, NOT the engine's usual -Z --
	# tool_hold.gd::_facing_direction() documents that it was verified by
	# render, and the swing cone is measured against it. A target placed at -Z
	# is a target the trainer has his back to, which is what the first run of
	# this tool photographed.
	tree.position = Vector3(0.0, 0.0, TARGET_AHEAD)


## The exploration camera rig, built the way capture_interior.gd builds it --
## a SpringArm3D, because that is what `camera_rig.gd` extends. Setting its
## script on a plain Node3D silently fails to attach ("so it can't be assigned
## to an object of type 'Node3D'"), and everything downstream then calls into a
## bare Node3D, which is how the first run of this tool spun for twelve minutes
## without emitting a frame.
func _build_camera_rig(world: Node3D) -> SpringArm3D:
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.spring_length = 5.2
	rig.margin = 0.6
	rig.set_script(CAMERA_RIG_SCRIPT)
	world.add_child(rig)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 70.0
	camera.far = 2000.0
	rig.add_child(camera)
	return rig
