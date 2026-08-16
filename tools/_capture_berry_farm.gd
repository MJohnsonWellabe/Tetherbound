extends SceneTree

## R7.6 verification capture: the berry farm beside Grandpa's house.
##
## `tools/survey.gd`'s five fixed viewpoints all sit around the village square
## and none of them looks at the house's south yard, so a blind pass against
## the standard survey could not judge these beds at all — "no farm named" would
## be as consistent with "not in frame" as with "does not read as a farm". The
## same reason `tools/_capture_grove_closeup.gd` exists, and this follows it
## down to the trainer parked in shot as the 1.8m scale reference the
## visual-judge rubric asks for.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_berry_farm.gd
##
## Three frames, because a farm bed has four appearances and one frame of
## bare soil would be a critique of a third of the feature:
##
##   01-fallow    what the player meets first — unworked ground, no hoe yet.
##   02-worked    the mixed state: tilled, sown and ripe beds side by side,
##                which is what the farm actually looks like in play.
##   03-ripe      the payoff, closer in — every bed carrying fruit.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/farm"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const FOV := 60.0

## The farm's own centre (data/config/farm.json) and the house it belongs to
## (data/config/village.json).
const FARM_XZ := Vector2(-22.0, -7.8)
const HOUSE_XZ := Vector2(-22.0, -16.0)

## Where the trainer stands for scale: at the near edge of the beds, off the
## rows rather than in them.
const PLAYER_XZ := Vector2(-17.6, -7.8)

var _world: Node = null
var _field: RefCounted = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	# The rig would fight every camera move below; the HUD would sit over the
	# frame the critic is meant to read.
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var look: Node = _world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	_field = HEIGHTFIELD.new()

	var player: Node3D = _world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(
			PLAYER_XZ.x, _field.height_at(PLAYER_XZ.x, PLAYER_XZ.y), PLAYER_XZ.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 500.0
	_world.add_child(_camera)
	_camera.make_current()

	# 01: unworked. This is what stands there before the player owns a hoe, so
	# it has to read as "a plot somebody could farm" and not as six brown
	# rectangles nobody put there on purpose.
	_set_all(FARM_LOGIC.FALLOW)
	await _shoot("01-fallow", Vector2(-11.0, -1.5), 2.6, 0.8)

	# 02: the working farm. Two ripe, two sown, one tilled, one fallow — the
	# mix a player actually stands in front of, and the frame that shows
	# whether the four states are told apart at a glance.
	_set_mixed()
	await _shoot("02-worked", Vector2(-11.0, -1.5), 2.6, 0.8)

	# 03: the payoff, closer and lower.
	_set_all(FARM_LOGIC.RIPE)
	await _shoot("03-ripe", Vector2(-15.5, -3.6), 1.9, 0.5)

	print("Software rendering under the Compatibility renderer (D06, tools/survey.sh's")
	print("own caveat): trustworthy for composition, silhouette and colour")
	print("relationships; NOT for fine lighting or post-processing judgements.")
	quit(0)


## Farm beds poll `Game` every frame (`farm_plot.gd::_process`), so writing the
## state is all that is needed — the next few frames redraw them.
func _set_all(state: String) -> void:
	var game := _world.get_node_or_null(^"/root/Game")
	if game == null:
		return
	for i in 6:
		game.call("set_farm_plot", i, {"state": state, "ripe_on_day": 0})


func _set_mixed() -> void:
	var game := _world.get_node_or_null(^"/root/Game")
	if game == null:
		return
	var states := [
		FARM_LOGIC.RIPE, FARM_LOGIC.RIPE, FARM_LOGIC.SOWN,
		FARM_LOGIC.SOWN, FARM_LOGIC.TILLED, FARM_LOGIC.FALLOW,
	]
	for i in states.size():
		game.call("set_farm_plot", i, {"state": states[i], "ripe_on_day": 0})


## `eye_xz` looks at the farm's centre; `aim_h` is how far above the ground
## the camera aims, which is what decides whether the farmhouse behind the
## beds is in shot (it is the reason these beds are where they are).
func _shoot(name_key: String, eye_xz: Vector2, eye_h: float, aim_h: float) -> void:
	var eye := Vector3(eye_xz.x, _field.height_at(eye_xz.x, eye_xz.y) + eye_h, eye_xz.y)
	var target := Vector3(
		FARM_XZ.x, _field.height_at(FARM_XZ.x, FARM_XZ.y) + aim_h, FARM_XZ.y)
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)

	for i in 20:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image for %s" % name_key)
		return
	var path := "%s/%s.png" % [OUT_DIR, name_key]
	if image.save_png(path) != OK:
		push_error("save_png failed for %s" % path)
		return
	print("-> %s" % path)
