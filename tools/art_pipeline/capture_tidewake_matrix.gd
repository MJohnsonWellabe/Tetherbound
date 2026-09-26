extends SceneTree

## X04 evidence for F13#5 / T2: "currents, inhabited docks and Veilfall distance
## read" at the NORMAL camera. Production Water scene, production Player,
## CameraRig/Camera3D and HUD -- unlike survey_water.gd, which swaps in its own
## free camera. Each view stands the player at a point (ground, or swimming at
## the surface where the ground is under water), turns the rig's yaw toward
## the target and lets the rig settle on its own. Day and night per view.
## Teleported stands are visual fixtures, not traversal evidence.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/art_pipeline/capture_tidewake_matrix.gd \
##     -- --out=res://shots/x04/f13 [--only=name,name]
##
## Coordinates: data/config/water_world.json and water_veilfall.json.

const SCENE := "res://scenes/world/water_archipelago.tscn"
const READY_TIMEOUT_MS := 600000
const SETTLE_FRAMES := 90
## The third-person trainer stands at frame centre; turning the rig this far
## off the target puts the subject beside the trainer instead of behind them.
const YAW_OFFSET_DEG := 14.0

## stand xz, target xyz (y < -999 means ground height at target + 4 m).
const VIEWS := [
	{"name": "dock-first-shore-settlement", "stand": Vector2(12.0, 150.0), "target": Vector3(35.7, -1000.0, 98.1),
		"what": "First Shore settlement and Welcome Beacon from the Reedhaven dock"},
	{"name": "dock-reedhaven-arrival", "stand": Vector2(0.0, 278.0), "target": Vector3(-54.0, -1000.0, 440.0),
		"what": "Reedhaven Woven Hall from the dock arrival point"},
	{"name": "dock-shellwatch-jetty", "stand": Vector2(250.0, 975.0), "target": Vector3(267.0, -1000.0, 1006.3),
		"what": "Shellwatch Rescue Jetty (occupied dock) from 35 m"},
	{"name": "current-first-shore-reedhaven", "stand": Vector2(0.0, 162.0), "target": Vector3(0.0, 1.0, 262.0),
		"what": "First Shore to Reedhaven current, from the dock looking along it"},
	{"name": "current-cradle-salt-crown", "stand": Vector2(560.0, 1728.0), "target": Vector3(299.8, 2.0, 2097.5),
		"what": "Tidal Cradle to Salt Crown current along its line"},
	{"name": "current-sluice-veilfall", "stand": Vector2(722.0, 3192.0), "target": Vector3(393.0, 2.0, 3789.6),
		"what": "Sluice Isle to Veilfall current (strongest) along its line"},
	{"name": "veilfall-far-first-shore", "stand": Vector2(0.0, 162.0), "target": Vector3(200.0, 620.0, 4140.0),
		"what": "Veilfall from First Shore, ~4 km (design sightline)", "pitch": -3.0, "yaw_offset": 24.0},
	{"name": "veilfall-mid-salt-crown", "stand": Vector2(419.6, 2640.0), "target": Vector3(200.0, 620.0, 4140.0),
		"what": "Veilfall from the Salt Crown rest, ~1.5 km", "pitch": -3.0, "yaw_offset": 24.0},
	{"name": "veilfall-near-arrival", "stand": Vector2(384.3, 3805.4), "target": Vector3(335.2, 139.4, 3885.7),
		"what": "Veilfall Cascade from the arrival point, ~95 m"},
]

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _look: Node
var _out := ""
var _only: PackedStringArray = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	if _out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --out= and a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var game := root.get_node_or_null(^"Game")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	if game != null:
		game.set("current_realm", "water")
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline and not bool(_world.call("shell_build_complete")):
		await physics_frame
	if not bool(_world.call("shell_build_complete")):
		push_error("production Water did not finish building")
		quit(1)
		return
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_look = _world.get_node_or_null(^"WorldLook")
	if _player == null or _rig == null or _look == null:
		push_error("Player, CameraRig or WorldLook missing")
		quit(1)
		return
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var records: Array = []
	for view: Dictionary in VIEWS:
		if not _only.is_empty() and not _only.has(str(view.name)):
			continue
		for time_name: String in ["day", "night"]:
			records.append(await _capture(view, time_name))
	var f := FileAccess.open("%s/frames.json" % _out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"scene": SCENE, "camera": "production CameraRig/Camera3D, HUD on",
		"staged": "teleported stands, frozen clock", "frames": records}, "\t"))
	f.close()
	quit(0)


func _capture(view: Dictionary, time_name: String) -> Dictionary:
	var stand: Vector2 = view.stand
	var target: Vector3 = view.target
	if target.y < -999.0:
		target.y = float(_world.call("ground_height_at", target.x, target.z)) + 4.0
	var ground := float(_world.call("ground_height_at", stand.x, stand.y))
	var swimming := ground < 0.0
	var at := Vector3(stand.x, (0.15 if swimming else ground + 0.15), stand.y)
	var to := target - at
	_look.call("apply_time", time_name)
	for i in SETTLE_FRAMES:
		_player.global_position = at
		_player.velocity = Vector3.ZERO
		_rig.set("yaw", atan2(-to.x, -to.z) + deg_to_rad(float(view.get("yaw_offset", YAW_OFFSET_DEG))))
		# The rig's positive pitch tilts the view UP: a distant high target
		# is framed with a small explicit down-tilt so the horizon stays in.
		_rig.set("pitch", float(view.get("pitch",
			clampf(rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length())) * 0.5, -10.0, 12.0))))
		await physics_frame
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var name := "%s-%s" % [str(view.name), time_name]
	var path := "%s/%s.png" % [_out, name]
	root.get_texture().get_image().save_png(path)
	print("frame %s player=%s swimming=%s" % [path, str(_player.global_position), str(swimming)])
	return {"frame": name, "what": view.what, "player": [at.x, at.y, at.z], "target": [target.x, target.y, target.z],
		"ground_y": ground, "swimming_stand": swimming, "distance_m": at.distance_to(target)}
