extends SceneTree

## OF1's blind-judge frames: the whole catch sequence, both outcomes.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       --script tools/capture_catch_sequence.gd
##
## NOT --headless: that swaps in a no-op renderer and the run silently hangs
## (survey_combat.sh's own header). Same honest limits as every combat capture:
## software rendering, so composition/colour/readability are trustworthy and
## lighting quality is not.
##
## survey_combat.gd stops at "08-orb-in-flight" — it has never photographed the
## resolution, which is exactly the half of catching OF1 exists to redo. This
## walks: aim -> flight -> strike/absorb -> the orb at rest under the resolve
## camera -> a shake mid-rock -> the verdict, and it does it twice, because the
## feel of failure matters as much as success:
##   sequence A, full-health target  -> expect a breakout
##   sequence B, target at a sliver  -> expect a catch
## Each sequence retries until the dice actually produce its outcome, since a
## frame named "breakout" showing a seal would make the whole critique a lie.
##
## Beat frames use the pause-after-the-effect-draws trick from
## survey_combat._capture_the_impact: a node added mid-frame has drawn nothing
## until its next physics tick, and without pausing, physics outruns the
## software renderer and the moment is gone before the shutter opens.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const OUT_DIR := "res://shots/catch"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 2
## Physics frames between a beat's signal and its shutter, so the effect it
## names has actually drawn something.
const BEAT_FRAMES := 5
## Attempts allowed per sequence before giving up on the dice.
const MAX_ATTEMPTS := 6

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _written: Array[String] = []
var _failures: Array[String] = []
var _start_ms: int = 0

var _struck_flag := [false]
var _shook_flag := [false]
var _resolved := []  # appended [success] per resolution


func _init() -> void:
	_run()


func _run() -> void:
	_start_ms = Time.get_ticks_msec()
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
	_log("settled")

	await _ensure_ally()
	_leave_the_farmhouse()
	_seed_orbs()
	if not _collect_nodes():
		_finish()
		return

	var debug_hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false

	await _walk_to_the_wild_pal()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat; nothing captured")
		_finish()
		return
	_ally = _director.call("ally_body") as Node3D
	_log("fighting")

	# The dice are stacked per sequence THROUGH THE CLAMPS the formula already
	# has (`chance.min`/`chance.max`), because a frame named "breakout" showing
	# a seal would make the whole critique a lie: a full-health throw can still
	# roll its ~5-10%, and a catch in sequence A ends the fight the entire run
	# depends on. The resolution path being photographed is untouched — only
	# the roll's odds are pinned, and only inside this process.
	var chance_cfg: Dictionary = CATCH.config().get("chance", {})
	var real_min: float = float(chance_cfg.get("min", 0.02))
	var real_max: float = float(chance_cfg.get("max", 0.95))

	# --- sequence A: full health, expect a breakout -------------------------
	chance_cfg["max"] = 0.001
	chance_cfg["min"] = 0.0
	var got_failure := false
	for attempt in MAX_ATTEMPTS:
		if not bool(_manager.call("is_fighting")):
			break
		_top_up()
		var foe: RefCounted = _manager.call("enemy")
		foe.hp = foe.max_hp
		var first := attempt == 0
		var outcome := await _one_throw("01-aiming-full-health" if first else "",
			"02-orb-in-flight" if first else "", "03-strike-absorb" if first else "",
			"04-orb-resting" if first else "", "05-orb-shakes" if first else "",
			"06-breakout")
		if outcome == "failure":
			got_failure = true
			break
	if not got_failure:
		_failures.append("sequence A never produced a breakout to photograph")

	# --- sequence B: a sliver of health, expect a catch ---------------------
	chance_cfg["max"] = real_max
	chance_cfg["min"] = 0.999
	if bool(_manager.call("is_fighting")):
		var got_catch := false
		for attempt in MAX_ATTEMPTS:
			if not bool(_manager.call("is_fighting")):
				break
			_top_up()
			var foe: RefCounted = _manager.call("enemy")
			foe.hp = foe.max_hp * 0.06
			var outcome := await _one_throw("07-aiming-weakened" if attempt == 0 else "",
				"", "", "", "", "08-caught-verdict")
			if outcome == "success":
				got_catch = true
				for i in 30:
					await physics_frame
				await _capture("09-caught-banner")
				break
		if not got_catch:
			_failures.append("sequence B never produced a catch to photograph")
	else:
		_failures.append("the fight ended before sequence B could run")
	chance_cfg["min"] = real_min

	_finish()


## One aimed throw, capturing whichever beat frames were asked for ("" skips).
## Returns "success", "failure", or "" when the throw never resolved.
func _one_throw(aim_frame: String, flight_frame: String,
		strike_frame: String, rest_frame: String, shake_frame: String,
		verdict_frame: String) -> String:
	if not await _open_aim():
		return ""
	# Let the aim camera glide in before reading its eye or its frame.
	for i in 15:
		await physics_frame
	_aim_at_the_target()
	for i in 4:
		await physics_frame
	if aim_frame != "":
		await _capture(aim_frame)
		_aim_at_the_target()
		for i in 4:
			await physics_frame

	_struck_flag[0] = false
	_shook_flag[0] = false
	var resolutions_before := _resolved.size()
	await _press("combat_throw")

	if flight_frame != "":
		# Past the release windup (0.18s ~ 11 ticks) with the trail drawn.
		for i in 16:
			await physics_frame
		await _capture(flight_frame)

	# The strike: flash + the creature shrinking toward the hanging orb.
	var waited := 0
	while not _struck_flag[0] and waited < 300 and bool(_manager.call("is_fighting")):
		await physics_frame
		waited += 1
	if not _struck_flag[0]:
		# The orb went wide; no resolution follows.
		for i in 60:
			await physics_frame
		return ""
	if strike_frame != "":
		for i in BEAT_FRAMES + 6:
			await physics_frame
		await _capture_paused(strike_frame)

	# The orb at rest under the resolve camera, before the first shake.
	if rest_frame != "":
		var orb := _resting_orb()
		waited = 0
		while waited < 300:
			orb = _resting_orb()
			if orb != null and bool(orb.call("is_resting")):
				break
			await physics_frame
			waited += 1
		for i in 6:
			await physics_frame
		await _capture(rest_frame)

	# A shake, mid-rock. The rock is ~0.45s; shoot a third of the way in.
	if shake_frame != "":
		waited = 0
		while not _shook_flag[0] and waited < 300:
			await physics_frame
			waited += 1
		if _shook_flag[0]:
			for i in 8:
				await physics_frame
			await _capture_paused(shake_frame)
		else:
			_failures.append("%s: the orb never shook" % shake_frame)

	# The verdict.
	waited = 0
	while _resolved.size() == resolutions_before and waited < 900:
		await physics_frame
		waited += 1
	if _resolved.size() == resolutions_before:
		_failures.append("a struck orb never resolved")
		return ""
	if verdict_frame != "":
		for i in BEAT_FRAMES:
			await physics_frame
		await _capture_paused(verdict_frame)
	# Let the aftermath (breakout pop, camera handback, cooldown) play out.
	for i in 70:
		await physics_frame
	return "success" if bool(_resolved[-1]) else "failure"


## --- plumbing, same shapes as capture_combat_actions.gd ---------------------

func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _seed_orbs(count: int = 20) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


## Keep the ally standing and the satchel stocked between attempts, the same
## reasoning smoke_catching.gd already carries: aiming genuinely abandons the
## pal, and a capture run that throws repeatedly would otherwise end "lost".
func _top_up() -> void:
	_seed_orbs()
	var pal: RefCounted = _manager.call("active_pal")
	if pal != null:
		pal.hp = pal.max_hp


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

	var throw: Node = _manager.call("throw_aim")
	throw.connect("orb_struck", func(_t: Node3D, _o: float) -> void: _struck_flag[0] = true)
	_manager.connect("orb_shook", func(_i: int) -> void: _shook_flag[0] = true)
	_manager.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _resolved.append(success))
	return true


func _resting_orb() -> Node3D:
	var throw: Node = _manager.call("throw_aim")
	return throw.call("resting_orb") as Node3D


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


func _open_aim() -> bool:
	for i in 240:
		if not bool(_manager.call("is_fighting")):
			return false
		if not bool(_manager.call("player_is_committed")):
			break
		await physics_frame
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var budget := int(ceil(cooldown * float(Engine.physics_ticks_per_second))) + 120
	while budget > 0:
		await _press("combat_throw")
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(_manager.call("is_aiming")):
			return true
	return false


## smoke_catching.gd's proven aim: straight at the leaded centre from the
## camera's eye, letting `_aim_direction`'s snap window and ballistic solve do
## the rest.
func _aim_at_the_target() -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if _wild is CharacterBody3D:
		velocity = (_wild as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (_wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _log(label: String) -> void:
	print("  [phase] %-28s +%.1fs" % [label, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _capture(name: String) -> void:
	for i in POSE_FRAMES:
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
	print("  %-26s -> %s  (+%.1fs)" % [name, path, (Time.get_ticks_msec() - _start_ms) / 1000.0])


## Freeze physics for the shutter so a sub-second beat is not gone before the
## software renderer produces a frame.
func _capture_paused(name: String) -> void:
	paused = true
	await _capture(name)
	paused = false


func _finish() -> void:
	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering: composition, readability and colour only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
