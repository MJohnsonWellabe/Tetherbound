extends SceneTree

## X04 before/after evidence for the Meadows home circle (the realm-heart
## shrine and its three relic slots, realm_transitions.json
## `meadows_heart_shrine`). Production Meadows scene, Player, CameraRig and
## HUD: the player is stood at a point on a ring around the circle centre, the
## rig's yaw turned toward the centre, and the rig left to settle. Day only.
## Teleported stands are a visual fixture, not traversal evidence.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/art_pipeline/capture_meadows_home_circle.gd \
##     -- --out=res://shots/x04/home_circle [--label=before]

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRANSITIONS := "res://data/config/realm_transitions.json"
const WORLD_SETTLE := 300
const VIEW_SETTLE := 90
## Bearings (degrees, 0 = +Z) and distances of the stands around the centre.
const STANDS := [[0.0, 14.0], [90.0, 14.0], [180.0, 14.0], [270.0, 14.0], [45.0, 26.0]]

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _out := ""
var _label := "frame"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --out= and a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var spec: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(TRANSITIONS)) as Dictionary) \
		.get("meadows_heart_shrine", {})
	var centre := Vector2(float(spec.position[0]), float(spec.position[1]))
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in WORLD_SETTLE:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	var look := _world.get_node_or_null(^"WorldLook")
	if _player == null or _rig == null:
		push_error("Player or CameraRig missing")
		quit(1)
		return
	if look != null and look.has_method("apply_time"):
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		look.call("apply_time", "day")
	var centre_y := float(_world.call("ground_height_at", centre.x, centre.y))
	for stand: Array in STANDS:
		var bearing := deg_to_rad(float(stand[0]))
		var at2 := centre + Vector2(sin(bearing), cos(bearing)) * float(stand[1])
		var ground := float(_world.call("ground_height_at", at2.x, at2.y))
		var at := Vector3(at2.x, ground + 0.15, at2.y)
		var to := Vector3(centre.x, centre_y + 1.0, centre.y) - at
		for i in VIEW_SETTLE:
			_player.global_position = at
			_player.velocity = Vector3.ZERO
			_rig.set("yaw", atan2(-to.x, -to.z))
			_rig.set("pitch", -12.0 if float(stand[1]) < 20.0 else -30.0)
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/%s-b%03d-d%02d.png" % [_out, _label, int(stand[0]), int(stand[1])]
		root.get_texture().get_image().save_png(path)
		print("frame %s" % path)
	quit(0)
