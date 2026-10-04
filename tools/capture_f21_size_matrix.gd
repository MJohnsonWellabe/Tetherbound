extends SceneTree

## F21#4 size-matrix stills for a code-blind judge, sized for an in-container
## software renderer (llvmpipe draws a 1080p Meadows frame in about two
## seconds, so `tests/smoke_combat_camera.gd --matrix-live` cannot meet its
## 30 s per-pair wall budget here).
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --resolution 1920x1080 --fixed-fps 60 --script tools/capture_f21_size_matrix.gd -- --out=/abs/dir
##
## Same staging as the live matrix: a real encounter entered by walking to the
## authored wild and pressing interact, then each of the nine authored
## small/normal/giant species pairs (mudsnout, terrapup, veridian) swapped in at
## the encounter's own start poses, a 0.6 m visible gap, never rescaled. The
## manager, AI, collision, HUD, herd and the production fight camera stay live.
## Per pair: `--frames` process frames (default 72); the ally walks forward
## between frames 24 and 48, as the live matrix's movement window does.
## Stills at frames 12, 36, 60 and the last. `matrix.json` records each
## camera solution (framed, overlap, faded foreground count, distance).
## `--no-fade` reproduces the pre-fix rule for a matched before set.
##
## Disclosed shortcuts (ACCEPTANCE §6.1): the farmhouse-exit teleport of
## `tools/capture_combat_actions.gd`; species/roster swapped by fixture.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const FIGHT := preload("res://scripts/combat/fight_camera.gd")
const SETTLE_FRAMES := 240
const KINDS := {"small": "mudsnout", "normal": "terrapup", "giant": "veridian"}

var _out := ""
var _frames := 72
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null
var _failures: Array[String] = []
var _cases: Array[Dictionary] = []


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg.begins_with("--frames="): _frames = maxi(60, int(arg.trim_prefix("--frames=")))
		elif arg == "--no-fade":
			# Nearest to the pre-fix rule: cover fails a view, nothing is
			# dithered and failed fits rank by raw overlap. The nearest-first
			# occluder order is not reverted (it changes no verdict).
			(FIGHT.config().get("readability", {}) as Dictionary)["fade_foreground"] = false
			FIGHT.config()["fallback_overlap_tolerance"] = 0.0
	if _out.is_empty(): _out = ProjectSettings.globalize_path("res://shots/_diag/f21-matrix")
	# Run with `--fixed-fps 60`: each frame is 1/60 s of game time however long
	# the software draw takes. Frames between stills are simulated undrawn.
	RenderingServer.render_loop_enabled = false
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	var chosen := GRAPHICS.choose("Low")
	if chosen != OK or root.get_visible_rect().size != Vector2(1920, 1080):
		_failures.append("needs the Low preset at 1920x1080 (choose=%d, size=%s)" % [chosen, root.get_visible_rect().size])
		_finish()
		return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES: await physics_frame
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _director != null and _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	_leave_the_farmhouse()
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	if _player == null or _rig == null or _manager == null or _director == null:
		_failures.append("scene is missing the player, rig, manager or director")
		_finish()
		return
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_failures.append("no wild creature spawned")
		_finish()
		return
	var debug_hud := _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null: debug_hud.visible = false
	await _walk_to_the_wild()
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 45: await physics_frame
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat")
		_finish()
		return
	_wild = _manager.get("_wild") as Node3D
	_ally = _director.call("ally_body") as Node3D
	var camera := (_rig.get_node_or_null(^"Camera3D") as Camera3D)
	if camera != null: GRAPHICS.apply_camera(camera)
	GRAPHICS.apply_viewport(root)
	var start_ally := _ally.global_transform
	var start_foe := _wild.global_transform
	var index := 0
	for ally_class: String in KINDS:
		for foe_class: String in KINDS:
			if int(_manager.get("state")) != 1:
				_failures.append("encounter ended before %s/%s" % [ally_class, foe_class])
				break
			await _capture_pair(index, ally_class, foe_class, start_ally, start_foe)
			index += 1
	_finish()


func _capture_pair(index: int, ally_class: String, foe_class: String,
		start_ally: Transform3D, start_foe: Transform3D) -> void:
	var ally_instance: RefCounted = SPECIES.spawn(str(KINDS[ally_class]))
	var foe_instance: RefCounted = SPECIES.spawn(str(KINDS[foe_class]))
	var party: Array = (_manager.get("_party") as Array).duplicate()
	party[int(_manager.get("_active_index"))] = ally_instance
	_manager.set("_party", party)
	_manager.set("_enemy", foe_instance)
	_director.set("_ally", ally_instance)
	_wild.set("instance", foe_instance)
	_ally.call("setup", str(KINDS[ally_class]))
	_wild.call("setup", str(KINDS[foe_class]))
	_ally.global_transform = start_ally
	_wild.global_transform = start_foe
	var a: AABB = _manager.call("_body_world_bounds", _ally)
	var b: AABB = _manager.call("_body_world_bounds", _wild)
	var foe_at := _ally.global_position + Vector3((a.size.x + b.size.x) * 0.5 + 0.6, 0.0, 0.0)
	foe_at.y = float(_world.call("ground_height_at", foe_at.x, foe_at.z))
	_wild.global_position = foe_at
	_ally.set("velocity", Vector3.ZERO)
	_wild.set("velocity", Vector3.ZERO)
	_ally.call("face_towards", _wild.global_position)
	_wild.call("face_towards", _ally.global_position)
	_manager.call("_end_hitstop")
	_wild.call("set_engaged", true, _ally)
	_manager.call("_take_camera")
	_manager.emit_signal("state_changed")
	var pair := "%s/%s" % [ally_class, foe_class]
	var shots: Array[Dictionary] = []
	var milestones := [12, 36, 60, _frames - 1]
	for frame: int in _frames:
		if frame == 24: Input.action_press("move_forward")
		elif frame == 48: Input.action_release("move_forward")
		if frame in milestones:
			RenderingServer.render_loop_enabled = true
			await RenderingServer.frame_post_draw
			var solution: Dictionary = _manager.get("_fight_camera_solution")
			var visibility: Dictionary = solution.get("actual_visibility", {})
			var name := "%02d-%03d.png" % [index, frame]
			var image := root.get_texture().get_image()
			if image == null or image.save_png(_out.path_join(name)) != OK:
				_failures.append("%s: could not save %s" % [pair, name])
			RenderingServer.render_loop_enabled = false
			shots.append({"frame": frame, "png": name,
				"framed": solution.get("actual_framed"), "overlap": solution.get("actual_overlap"),
				"hud_clear": visibility.get("hud_clear"), "cover_faded": visibility.get("cover_faded"),
				"faded_foreground": solution.get("faded_foreground"),
				"distance": solution.get("selected_distance"), "solver_pass": solution.get("pass"),
				"yaw_offset_deg": solution.get("yaw_offset_deg")})
		else:
			await process_frame
	Input.action_release("move_forward")
	_cases.append({"pair": pair, "ally": KINDS[ally_class], "foe": KINDS[foe_class],
		"ally_height_m": a.size.y, "foe_height_m": b.size.y, "shots": shots})
	print("[f21-matrix] %s %s" % [pair, JSON.stringify(shots)])


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null: return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _walk_to_the_wild() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6: break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10: await physics_frame


func _finish() -> void:
	var file := FileAccess.open(_out.path_join("matrix.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
			"video_adapter": RenderingServer.get_video_adapter_name(), "preset": "Low",
			"resolution": [1920, 1080], "cases": _cases, "failures": _failures}, "  "))
	for failure in _failures: printerr("[f21-matrix] FAIL ", failure)
	quit(1 if not _failures.is_empty() else 0)
