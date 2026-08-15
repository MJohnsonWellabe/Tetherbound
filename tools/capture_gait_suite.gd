extends SceneTree

## MQ1A's full locomotion capture: every angle and transition the quality plan
## names, in one run.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" ~/.cache/tetherbound-art/godot \
##     --path . --rendering-driver opengl3 --resolution 960x540 \
##     --script tools/capture_gait_suite.gd
##
## Extends tools/capture_player_gait.gd (OF5), which proved the two capture
## rules this file lives by:
##   - cycle strips are stepped DETERMINISTICALLY (speed_scale = 0 + seek),
##     because advance() under speed_scale = 0 advances nothing and a frozen
##     cross-fade renders the wrong clip;
##   - the body must TRANSLATE at the real movement.json speed over striped
##     ground, because gait defects live between frames, not in one pose.
##
## What this adds over the OF5 tool, per MEADOWS_QUALITY_REBUILD_PLAN.md §2:
## rear / front three-quarter / rear three-quarter strips for both gaits, and
## start / stop / turn sequences driven through the REAL runtime path —
## play()'s cross-fade and match_gait_rate()'s cadence scaling — using
## AnimationMixer's MANUAL callback mode so the blend still progresses under
## a deterministic clock. The transition frames are what "acceleration reads
## as a gear shift" would show up in; a cycle strip cannot contain it.
##
## Writes shots/gait/*.png. Compose with tools/sheet.py for the blind pass.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const OUT_DIR := "res://shots/gait"

## Frames per full cycle in the side strips: enough to see contact, loading,
## mid-stance, toe-off and mid-swing for BOTH legs (the plan's checklist).
const CYCLE_STEPS := 12
## Frames in the shorter view strips (rear, three-quarters).
const VIEW_STEPS := 6
## Frames in each transition sequence, and the deterministic clock they step by.
const TRANSITION_STEPS := 10
const TRANSITION_DT := 1.0 / 16.0

var _walk_speed := 5.0
var _sprint_speed := 8.6
var _accel := 42.0
var _friction := 38.0
var _turn_speed := 11.0

var _world: Node3D
var _model: Node3D
var _anim: AnimationPlayer
var _camera: Camera3D


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame

	var move := _movement_config()
	var loco: Dictionary = move.get("locomotion", {})
	_walk_speed = float(loco.get("walk_speed", 5.0))
	_sprint_speed = float(loco.get("sprint_speed", 8.6))
	_accel = float(loco.get("ground_acceleration", 42.0))
	_friction = float(loco.get("ground_friction", 38.0))
	_turn_speed = float(loco.get("turn_speed", 11.0))

	_world = Node3D.new()
	root.add_child(_world)
	_light(_world)
	_striped_ground(_world)

	# GAIT_CHARACTER selects any art.json humanoid block (default trainer):
	# the same rigs share the same baked clips, and the shared-rig scope of
	# MQ1A means an NPC's gait needs the same evidence the trainer's gets.
	var who := OS.get_environment("GAIT_CHARACTER")
	if who == "":
		who = "trainer"
	_model = Node3D.new()
	_model.set_script(CHARACTER_MODEL)
	_world.add_child(_model)
	if not bool(_model.call("build", who)):
		printerr("%s failed to build" % who)
		quit(1)
		return
	# Clips animate in place; the tool owns translation. Face +X (travel).
	_model.rotation.y = deg_to_rad(90.0)
	_anim = _model.call("animation_player")

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_world.add_child(_camera)
	_camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for gait: Array in [["walk", _walk_speed], ["sprint", _sprint_speed]]:
		await _cycle_strips(str(gait[0]), float(gait[1]))

	await _start_sequence()
	await _stop_sequence()
	await _turn_sequence()

	print("done: shots/gait")
	quit(0)


## ---------- deterministic cycle strips (side, rear, both three-quarters) ----


func _cycle_strips(clip: String, speed: float) -> void:
	var cycle: float = _anim.get_animation(clip).length
	_model.call("play", clip)
	# Re-play unblended: under speed_scale = 0 the 0.18s cross-fade never
	# finishes and the strip renders a frozen blend (measured by OF5).
	_anim.play(clip)
	_anim.speed_scale = 0.0

	var views := {
		"side": VIEW_SIDE, "rear": VIEW_REAR, "f34": VIEW_F34, "r34": VIEW_R34,
	}
	for view_name: String in views:
		var steps: int = CYCLE_STEPS if view_name == "side" else VIEW_STEPS
		for i in steps:
			var t := cycle * i / steps
			_anim.seek(t, true)
			var x := -4.0 + speed * t
			_model.position.x = x
			_place_camera(int(views[view_name]), x)
			await _settle()
			_save("%s-%s-%02d" % [clip, view_name, i])
	_anim.speed_scale = 1.0


enum { VIEW_SIDE, VIEW_REAR, VIEW_F34, VIEW_R34 }


func _place_camera(view: int, x: float) -> void:
	# Close enough that knees and elbows are judgeable in a 620px sheet tile.
	match view:
		VIEW_SIDE:
			_camera.position = Vector3(x, 1.0, 3.4)
			_camera.look_at(Vector3(x, 0.92, 0.0), Vector3.UP)
		VIEW_REAR:
			_camera.position = Vector3(x - 3.2, 1.5, 0.0)
			_camera.look_at(Vector3(x, 0.95, 0.0), Vector3.UP)
		VIEW_F34:
			_camera.position = Vector3(x + 2.6, 1.5, 2.2)
			_camera.look_at(Vector3(x, 0.92, 0.0), Vector3.UP)
		VIEW_R34:
			_camera.position = Vector3(x - 2.6, 1.5, 2.2)
			_camera.look_at(Vector3(x, 0.92, 0.0), Vector3.UP)


## ---------- transitions through the real runtime path ----------------------


## Mimics trainer_model.gd's per-tick decisions (role from speed, play(),
## match_gait_rate()) while a deterministic clock advances the mixer manually,
## so the cross-fade and cadence scaling are the shipped ones but the software
## renderer's frame rate cannot skew what a frame shows.
func _drive(role: String, velocity: Vector3, dt: float) -> void:
	var speed := velocity.length()
	_model.call("play", role if role != "" else "idle")
	_model.call("match_gait_rate", role, speed)
	# The shipped momentum tilt (trainer_model.gd drives it in game): starts,
	# stops and turns are exactly where it shows, so the capture must run it.
	_model.call("apply_momentum_tilt", velocity, dt, _gait_feel())
	# advance() runs the blend and the animation under MANUAL callback mode.
	# speed_scale is applied by advance() itself in Godot 4 (verified below by
	# printing the animation position per step when this tool runs).
	_anim.advance(dt)


func _gait_feel() -> Dictionary:
	var feel: Variant = _movement_config().get("gait_feel", {})
	return feel if feel is Dictionary else {}


func _start_sequence() -> void:
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_anim.speed_scale = 1.0
	_model.call("play", "idle")
	_anim.play("idle")
	_anim.advance(0.0)

	var x := -2.0
	var v := 0.0
	for i in TRANSITION_STEPS:
		# First two frames hold idle so the sheet shows the pose being left.
		if i >= 2:
			v = minf(_walk_speed, v + _accel * TRANSITION_DT)
		x += v * TRANSITION_DT
		_model.position.x = x
		var role := "idle" if v < 0.4 else "walk"
		_drive(role, Vector3(v, 0.0, 0.0), TRANSITION_DT)
		print("start %d: v=%.2f pos=%.3f" % [i, v, _anim.current_animation_position])
		_camera.position = Vector3(x + 2.8, 1.5, 3.4)
		_camera.look_at(Vector3(x, 0.95, 0.0), Vector3.UP)
		await _settle()
		_save("start-%02d" % i)
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE


func _stop_sequence() -> void:
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_anim.speed_scale = 1.0
	_model.call("play", "sprint")
	_anim.play("sprint")
	_anim.advance(0.0)

	var x := -2.0
	var v := _sprint_speed
	for i in TRANSITION_STEPS:
		# Two frames of full sprint first, then friction takes the speed.
		if i >= 2:
			v = maxf(0.0, v - _friction * TRANSITION_DT)
		x += v * TRANSITION_DT
		_model.position.x = x
		var role := "idle" if v < 0.4 else "sprint"
		_drive(role, Vector3(v, 0.0, 0.0), TRANSITION_DT)
		print("stop %d: v=%.2f pos=%.3f" % [i, v, _anim.current_animation_position])
		_camera.position = Vector3(x + 2.8, 1.5, 3.4)
		_camera.look_at(Vector3(x, 0.95, 0.0), Vector3.UP)
		await _settle()
		_save("stop-%02d" % i)
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE


func _turn_sequence() -> void:
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_anim.speed_scale = 1.0
	_model.call("play", "walk")
	_anim.play("walk")
	_anim.advance(0.0)

	var pos := Vector3(-1.0, 0.0, 0.0)
	var heading := 0.0  # radians; 0 = +X
	var target := PI    # 180-degree reversal, the harshest turn the stick makes
	var turning_from := 3  # frames of straight walking first
	for i in TRANSITION_STEPS:
		if i >= turning_from and heading < target:
			heading = minf(target, heading + _turn_speed * TRANSITION_DT)
		var dir := Vector3(cos(heading), 0.0, -sin(heading))
		pos += dir * _walk_speed * TRANSITION_DT
		_model.position = pos
		_model.rotation.y = deg_to_rad(90.0) - heading
		_drive("walk", dir * _walk_speed, TRANSITION_DT)
		# Fixed camera: the path curls through the frame.
		_camera.position = Vector3(0.6, 2.4, 4.8)
		_camera.look_at(Vector3(0.6, 0.8, 0.0), Vector3.UP)
		await _settle()
		_save("turn-%02d" % i)
	_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE


## ---------- shared scaffolding (matches capture_player_gait.gd) ------------


func _settle() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		printerr("no image for %s" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])


func _movement_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 1.4
	env.environment = e
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-30.0), 0.0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	world.add_child(key)


## Half-metre stripes along the travel axis: the ruler that makes foot-skate a
## measurement rather than an opinion.
func _striped_ground(world: Node3D) -> void:
	var a := StandardMaterial3D.new()
	a.albedo_color = Color(0.42, 0.45, 0.42)
	var b := StandardMaterial3D.new()
	b.albedo_color = Color(0.72, 0.74, 0.70)
	for i in 120:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.05, 12.0)
		strip.mesh = box
		strip.material_override = a if i % 2 == 0 else b
		strip.position = Vector3(-10.0 + 0.5 * i + 0.25, -0.025, 0.0)
		world.add_child(strip)
