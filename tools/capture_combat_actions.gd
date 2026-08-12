extends SceneTree

## `HD1`'s own blind-judge frames: combat_hud.gd's Actions row with real
## device-aware icons instead of hardcoded Xbox letters.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_combat_actions.gd
##
## NOT `tools/survey_combat.gd`, on purpose. That tool still walks from the
## raw scene spawn, which `meadows_playground.tscn` has put inside Grandpa's
## farmhouse since D18's indoor opening -- confirmed by testing it directly
## this session, two frames in a row of the trainer's back against an indoor
## wall next to a piece of furniture, never reaching the outdoor world. That
## staleness is real and pre-existing (`R9.4-remainder-9` already tracks
## getting survey_combat.gd producing real frames again, with its own
## "budget" concerns), not something this item caused or is scoped to fix.
## `tests/smoke_combat.gd` already carries the fix for it
## (`_leave_the_farmhouse()`, teleporting to the practice cluster) and this
## reuses that exact approach rather than re-diagnosing it.
##
## Also deliberately does not wait for a hit to land or the charged meter to
## fill -- HD1 only needs the Actions row's icons to be on screen and
## legible, not a real impact, so this captures far fewer frames than a full
## fight and runs in a fraction of survey_combat.gd's time.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _written: Array[String] = []
var _failures: Array[String] = []


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

	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_nodes():
		_finish()
		return

	var debug_hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false

	await _walk_to_the_wild_pal()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat; no frames to show")
		_finish()
		return
	_ally = _director.call("ally_body") as Node3D

	# The ordinary state: Quick/Charged/Throw/Run, whatever their current
	# ready/dimmed mix happens to be the moment the fight opens.
	await _capture("combat-actions-open")

	# Aiming swaps the row to Throw/Cancel -- a genuinely different pair of
	# icons, not just a relabel, so it needs its own frame.
	if await _open_the_aim():
		await _capture("combat-actions-aiming")
	else:
		_failures.append("could not open the aim; no aiming-state frame captured")

	_finish()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


## Same teleport `tests/smoke_combat.gd::_leave_the_farmhouse()` uses.
func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		_failures.append("scene is missing the player, camera rig, combat manager or director")
		return false
	_wild = _director.call("wild_pal") as Node3D
	if _wild == null:
		_failures.append("the encounter director never spawned a wild pal")
		return false
	return true


func _walk_to_the_wild_pal() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame


func _open_the_aim() -> bool:
	for i in 240:
		if not bool(_manager.call("is_fighting")):
			return false
		if not bool(_manager.call("player_is_committed")):
			break
		await physics_frame
	Input.action_press("combat_throw")
	await physics_frame
	await physics_frame
	Input.action_release("combat_throw")
	for i in 240:
		if bool(_manager.call("is_aiming")):
			break
		await physics_frame
	return bool(_manager.call("is_aiming"))


func _capture(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	_written.append(path)
	print("  %-24s -> %s" % [name, path])


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering; placeholder capsules. HUD legibility only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
