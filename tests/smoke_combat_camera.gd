extends SceneTree

## RG8. The production orbit rig across exploration -> real encounter ->
## active-creature movement/switch -> throw aim/cancel -> combat exit, driven
## with physical joypad events for every camera/control assertion.
##
##   godot --headless --path . --script tests/smoke_combat_camera.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

const SETTLE_FRAMES := 300
const RIGHT_X := JOY_AXIS_RIGHT_X
const RIGHT_Y := JOY_AXIS_RIGHT_Y
const LEFT_Y := JOY_AXIS_LEFT_Y

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: SpringArm3D = null
var _camera: Camera3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	# Raw B/LB events also reach the autoload menu. A manually-instanced world
	# is not current_scene unless the harness says so; without this, the menu's
	# production combat guard cannot find CombatManager and the test—not the
	# game—turns B into Pause instead of flee/cancel.
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	if not await _collect_and_stage():
		_report()
		return

	await _prove_exploration_baseline()
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_fail("the physical interact button never entered the production encounter")
		_report()
		return
	await _prove_combat_entry_follow_and_orbit()
	await _prove_camera_widens_with_separation()
	await _prove_creature_switch_keeps_the_camera()
	await _prove_aim_cancel_returns_combat_orbit()
	await _prove_combat_exit_restores_exploration()
	await _prove_a_second_entry_exit_cycle()
	_report()


func _collect_and_stage() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _rig.get_node_or_null(^"Camera3D") as Camera3D if _rig != null else null
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _game == null or _player == null or _rig == null or _camera == null \
			or _manager == null or _director == null:
		_fail("the real world is missing Game, Player, CameraRig/Camera3D, CombatManager, or EncounterDirector")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup", "Orbit")
	_wild = _director.call("wild_creature") as Node3D
	if _director.call("ally_instance") == null or _wild == null:
		_fail("the production encounter could not stage an ally and wild creature")
		return false

	# A real second party member makes the existing combat-switch input reachable.
	var second := CREATURE.from_species("ripplet", SPECIES.definition("ripplet"))
	(_game.get("party") as RefCounted).call("add", second)
	(_game.get("inventory") as RefCounted).call("add", "orb_basic", 3)

	# Move beside the authored wild spawn, but enter through the production
	# arbiter and physical X button. Walking there is smoke_combat.gd's concern.
	var offset := Vector3(3.0, 0.0, 0.0)
	var near := _wild.global_position + offset
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	return true


func _prove_exploration_baseline() -> void:
	if _rig.get("_target") != _player:
		_fail("exploration camera target is not the trainer before combat")
	if not _camera.current:
		_fail("CameraRig/Camera3D is not the active exploration camera")
	if not _rig.is_processing():
		_fail("the exploration orbit rig is not processing")
	await _assert_raw_orbit_changes("exploration baseline")


func _enter_real_encounter() -> void:
	# The wild keeps wandering while the baseline camera is exercised. Stage the
	# trainer beside its CURRENT authored body immediately before pressing X so
	# this remains a camera test rather than a race against wandering distance.
	# A scatter harvest prompt can legitimately be closer at any one side of the
	# wild (camera03-smoke-first caught exactly that intermittent fixture clash).
	# Try a fixed ring of nearby, grounded approach points and require the real
	# arbiter to publish EncounterDirector before physical X. This is equivalent
	# to the player taking a few steps around the creature; it neither bypasses
	# the arbiter nor changes production prompt priority.
	if not await _stage_at_published_engage():
		_print_entry_diagnostics("no clear production engage approach")
		return
	_print_entry_diagnostics("before physical engage")
	await _press_button(JOY_BUTTON_X)
	for i in 120:
		if bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_ally = _director.call("ally_body") as Node3D


func _stage_at_published_engage() -> bool:
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null or not arbiter.has_method("winning_provider"):
		return false
	# Cardinal points first keep the common case quick and make failures
	# reproducible. The second radius covers a prompt whose 2.6m reach overlaps
	# one side of the wild while remaining inside the encounter's 4m reach.
	var radii: Array[float] = [1.5, 2.2]
	var bearings: Array[float] = [0.0, PI, PI * 0.5, -PI * 0.5,
		PI * 0.25, -PI * 0.25, PI * 0.75, -PI * 0.75]
	for radius: float in radii:
		for bearing: float in bearings:
			if _wild == null or not is_instance_valid(_wild):
				return false
			var anchor := _wild.global_position
			var near := anchor + Vector3(cos(bearing), 0.0, sin(bearing)) * radius
			near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
			_player.global_position = near
			_player.velocity = Vector3.ZERO
			for i in 3:
				await physics_frame
			for i in 2:
				await process_frame
			var candidate := _director.call("_engageable") as Node3D
			var winner := arbiter.call("winning_provider") as Node
			if candidate == _wild and winner == _director:
				return true
	return false


func _prove_combat_entry_follow_and_orbit() -> void:
	print("camera target on entry: %s" % _node_label(_rig.get("_target")))
	print("active camera: %s current=%s processing=%s" % [
		_camera.get_path(), _camera.current, _rig.is_processing()])
	if _ally == null or _rig.get("_target") != _ally:
		_fail("combat camera target is not the deployed active creature body")
	if not _camera.current:
		_fail("another camera became active when combat began")
	if not _rig.is_processing():
		_fail("the camera rig stopped processing when combat began")

	var ally_before := _ally.global_position
	var rig_before := _rig.global_position
	_send_axis(LEFT_Y, -0.85)
	for i in 50:
		await physics_frame
	_send_axis(LEFT_Y, 0.0)
	for i in 20:
		await physics_frame
	var ally_travel := _ally.global_position.distance_to(ally_before)
	var rig_travel := _rig.global_position.distance_to(rig_before)
	print("combat follow: ally moved %.2fm, rig moved %.2fm" % [ally_travel, rig_travel])
	if ally_travel < 0.5:
		_fail("physical left-stick input did not move the active creature")
	if rig_travel < 0.3:
		_fail("the rig did not follow the moving active creature")
	await _assert_raw_orbit_changes("combat")


## OP-0905-17 (owner playtest 2026-09-05): "the fighting camera sucks. I think
## it is too zoomed in." `combat_manager.gd::_update_combat_camera_framing()`
## is meant to widen the shot as the two fighters separate, on top of the
## already-raised base distance. The real wild AI does not hold still at an
## arbitrary gap, so this drives the real framing function directly against
## the real ally/wild bodies -- the same private-method access the production
## smokes already use on this world (`_director.call("_engageable")` above) --
## rather than fighting the AI for a stable measurement.
func _prove_camera_widens_with_separation() -> void:
	var cfg: Dictionary = MATH.config().get("camera", {}) as Dictionary
	var base_distance := float(cfg.get("distance", 6.0))
	var max_extra := float((cfg.get("framing", {}) as Dictionary).get("max_extra_distance", 4.0))
	var ceiling := base_distance + max_extra

	var near_distance := _measure_framing_distance(3.0)
	var far_distance := _measure_framing_distance(9.0)
	print("camera framing: near(3m)=%.2f far(9m)=%.2f base=%.2f ceiling=%.2f" % [
		near_distance, far_distance, base_distance, ceiling])
	if near_distance < base_distance - 0.05:
		_fail("the near frame narrowed below the authored base distance")
	if far_distance <= near_distance + 0.25:
		_fail("the FOV-derived frame did not widen when the opponent moved from 3m to 9m")
	if near_distance > ceiling + 0.05:
		_fail("camera distance at a 3m gap exceeded base distance + max_extra_distance (near=%.2f ceiling=%.2f)" % [
			near_distance, ceiling])
	if far_distance > ceiling + 0.05:
		_fail("camera distance at a 9m gap exceeded base distance + max_extra_distance (far=%.2f ceiling=%.2f)" % [
			far_distance, ceiling])

	# Leave the fighters at a normal gap, and give the real per-tick framing a
	# few physics frames to settle back before the remaining proofs run —
	# otherwise the switch/aim/exit checks below inherit this test's synthetic
	# 9m separation.
	var centre := _player.global_position + Vector3(3.5, 0.0, 0.0)
	_ally.global_position = centre
	_wild.global_position = centre + Vector3(2.0, 0.0, 0.0)
	for i in 30:
		await physics_frame


## Places the wild `gap` metres from the ally along X and drives the real
## `_update_combat_camera_framing()` in a tight synchronous loop -- no
## `await physics_frame` between calls, so nothing else (the wild's own AI
## included) gets a tick to move either body between one call and the next --
## enough times for `camera.framing.lag`'s exponential smoothing to settle,
## then returns the rig's own `_distance`: the value
## `camera_rig.gd::_follow()` chases every real frame with
## `move_toward(spring_length, _distance, _recover_speed * delta)`.
func _measure_framing_distance(gap: float) -> float:
	var centre := _ally.global_position
	for i in 180:
		_ally.global_position = centre
		_wild.global_position = centre + Vector3(gap, 0.0, 0.0)
		_manager.call("_update_combat_camera_framing", 1.0 / 60.0)
	return float(_rig.get("_distance"))


func _prove_creature_switch_keeps_the_camera() -> void:
	await _press_button(JOY_BUTTON_DPAD_RIGHT)
	for i in 20:
		await physics_frame
	var active: RefCounted = _manager.call("active_creature")
	if active == null or str(active.get("species_id")) != "ripplet":
		_fail("physical D-pad switch did not make the second creature active")
	if _rig.get("_target") != _ally:
		_fail("switching left the camera on a stale/non-deployed target")
	if not _rig.is_processing():
		_fail("switching disabled the camera rig")
	await _assert_raw_orbit_changes("after creature switch")


func _prove_aim_cancel_returns_combat_orbit() -> void:
	# CONTROLLER-MAP: the orb is a hotbar item thrown with X, so `interact`
	# (raw button 2) is what opens throw aim on a pad now -- `combat_throw`
	# kept only its keyboard F. RB, which used to carry it, is
	# `creature_recall`, which combat_manager.gd::_flee_pressed() reads as
	# DISENGAGE: pressing it here ended the fight instead of opening the aim.
	await _press_button(JOY_BUTTON_X)
	for i in 30:
		if bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		_fail("physical X did not enter throw aim despite available orbs")
		return
	print("camera target in aim: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("throw aim did not temporarily target the trainer")
	# throw_aim deliberately guards the same press that opened the mode for
	# 0.15s. Wait beyond that production debounce before testing B/cancel.
	for i in 15:
		await physics_frame
	await _press_button(JOY_BUTTON_B)
	for i in 30:
		if not bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if bool(_manager.call("is_aiming")):
		_fail("physical B did not cancel throw aim")
	if _rig.get("_target") != _ally:
		_fail("cancelled aim did not return camera follow to the active creature")
	if bool(_player.call("locomotion_enabled")):
		_fail("cancelled aim left trainer locomotion active during creature combat")
	await _assert_raw_orbit_changes("after aim cancel")


## CONTROLLER-MAP: "Fleeing is RB. Putting the creature away IS disengaging."
## `combat_run` kept its keyboard Escape and lost its pad button;
## `combat_manager.gd::_flee_pressed()` reads `creature_recall` (RB) instead. B
## is `hotbar_1`/`build_cancel` now and does not end a fight.
func _prove_combat_exit_restores_exploration() -> void:
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")):
		_fail("physical RB did not disengage from combat")
		return
	print("camera target on exit: %s" % _node_label(_rig.get("_target")))
	if _rig.get("_target") != _player:
		_fail("combat exit did not return camera target to the trainer")
	if not _rig.is_processing() or not _camera.current:
		_fail("combat exit left the exploration camera inactive")
	if absf(_camera.fov - 70.0) > 0.01 or absf(float(_rig.get("_shoulder"))) > 0.001 \
			or absf(float(_rig.get("_sensitivity_scale")) - 1.0) > 0.001:
		_fail("combat exit did not restore the exploration camera profile")
	if not bool(_player.call("locomotion_enabled")):
		_fail("combat exit did not restore trainer locomotion")
	var deployed: RefCounted = _director.call("ally_instance") as RefCounted
	var party_active: RefCounted = (_game.get("party") as RefCounted).call("active") as RefCounted
	if deployed == null or str(deployed.get("species_id")) != "ripplet" or party_active != deployed:
		_fail("combat exit did not preserve the creature selected by the player")
	if not _ally.visible or str(_ally.get("species_id")) != "ripplet":
		_fail("combat exit did not restore the selected creature as the visible follower")
	await _assert_raw_orbit_changes("exploration after combat")


func _prove_a_second_entry_exit_cycle() -> void:
	# Flee leaves the same wild encounter available. Re-enter through X and exit
	# through B once more to catch state that degrades only after the first cycle.
	var near := _wild.global_position + Vector3(3.0, 0.0, 0.0)
	near.y = float(_world.call("ground_height_at", near.x, near.z)) + 1.0
	_player.global_position = near
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	await _enter_real_encounter()
	if not bool(_manager.call("is_fighting")):
		_print_entry_diagnostics("second entry refused")
		_fail("the second production encounter would not start")
		return
	_ally = _director.call("ally_body") as Node3D
	if _rig.get("_target") != _ally or not _rig.is_processing():
		_fail("second combat cycle did not retarget a live, processing camera")
	# Let the same production input guard that separates the engage X press from
	# the first charged attack elapse before moving another physical control.
	for i in 20:
		await physics_frame
	await _assert_raw_orbit_changes("second combat cycle")
	await _press_button(JOY_BUTTON_RIGHT_SHOULDER)
	for i in 180:
		if not bool(_manager.call("is_fighting")):
			break
		await physics_frame
	if bool(_manager.call("is_fighting")) or _rig.get("_target") != _player:
		_fail("second combat exit did not restore trainer camera follow")


## A failed second entry previously reported only the final inactive state. Keep
## the production physical-button path unchanged, but retain enough state to
## distinguish a stale/wrong interaction winner from CombatManager::begin()
## refusing the selected creature after the first cycle.
func _print_entry_diagnostics(context: String) -> void:
	var engageable := _director.call("_engageable") as Node3D
	var arbiter := get_first_node_in_group("interaction_arbiter")
	var winner: Node = null
	if arbiter != null and arbiter.has_method("winning_provider"):
		winner = arbiter.call("winning_provider") as Node
	var active: RefCounted = (_game.get("party") as RefCounted).call("active") as RefCounted
	var hp := -1.0
	var fainted := true
	var resting := true
	var species := "<null>"
	if active != null:
		hp = float(active.get("hp"))
		fainted = bool(active.get("fainted"))
		resting = bool(active.get("resting"))
		species = str(active.get("species_id"))
	var distance := -1.0
	if engageable != null:
		distance = _player.global_position.distance_to(engageable.global_position)
	var winner_detail := "<none>"
	if winner != null and is_instance_valid(winner):
		var winner_script := winner.get_script() as Script
		var owner := winner.get_parent()
		var owner_script: Script = null
		if owner != null:
			owner_script = owner.get_script() as Script
		var offer: Dictionary = {}
		if winner.has_method("interaction_offer"):
			offer = winner.call("interaction_offer", _player.global_position) as Dictionary
		var winner_position := Vector3.ZERO
		if winner is Node3D:
			winner_position = (winner as Node3D).global_position
		winner_detail = "label=%s offer=%s position=%s distance=%.3f script=%s parent=%s parent_script=%s parent_groups=%s parent_meta=%s" % [
			str(winner.get("label")), str(offer), winner_position,
			_player.global_position.distance_to(winner_position) if winner is Node3D else -1.0,
			winner_script.resource_path if winner_script != null else "<none>",
			_node_label(owner), owner_script.resource_path if owner_script != null else "<none>",
			str(owner.get_groups()) if owner != null else "[]",
			str(_metadata(owner))]
	print("%s: manager=%s active=%s hp=%.2f fainted=%s resting=%s wild=%s visible=%s engageable=%s distance=%.3f arbiter=%s winner=%s" % [
		context, bool(_manager.call("is_fighting")), species, hp, fainted, resting,
		_node_label(_wild), _wild.visible if _wild != null and is_instance_valid(_wild) else false,
		_node_label(engageable), distance, _node_label(arbiter), _node_label(winner)])
	print("%s winner detail: %s" % [context, winner_detail])


func _metadata(node: Node) -> Dictionary:
	var out := {}
	if node == null:
		return out
	for key: StringName in node.get_meta_list():
		var value: Variant = node.get_meta(key)
		# Runtime objects such as Tweens are noisy and cannot identify the owner;
		# retain only scalar/vector metadata useful in a preserved smoke log.
		if value is String or value is StringName or value is bool or value is int \
				or value is float or value is Vector2 or value is Vector3:
			out[str(key)] = value
	return out


func _assert_raw_orbit_changes(context: String) -> void:
	# Keep away from either pitch clamp so both axes have room to move.
	_rig.set("yaw", 0.15)
	_rig.set("pitch", -0.15)
	_rig.rotation = Vector3(-0.15, 0.15, 0.0)
	var yaw_before := float(_rig.get("yaw"))
	var pitch_before := float(_rig.get("pitch"))
	_send_axis(RIGHT_X, 0.72)
	_send_axis(RIGHT_Y, -0.58)
	await physics_frame
	var live := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	print("%s look vector: %s (paused=%s, processing=%s, target=%s)" % [
		context, live, paused, _rig.is_processing(), _node_label(_rig.get("_target"))])
	for i in 18:
		await physics_frame
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	for i in 10:
		await physics_frame
	var yaw_after := float(_rig.get("yaw"))
	var pitch_after := float(_rig.get("pitch"))
	# Synthetic joy-motion state may be cleared by the engine after the camera's
	# physics read and before this coroutine resumes. The resulting yaw/pitch
	# deltas below are the durable proof that these raw events reached the rig.
	if absf(angle_difference(yaw_after, yaw_before)) < 0.08:
		_fail("%s: right-stick horizontal input did not orbit the camera" % context)
	if absf(pitch_after - pitch_before) < 0.05:
		_fail("%s: right-stick vertical input did not pitch the camera" % context)
	var held_yaw := yaw_after
	for i in 15:
		await physics_frame
	if absf(angle_difference(float(_rig.get("yaw")), held_yaw)) > 0.01:
		_fail("%s: camera yaw was continuously recentered after the stick returned to neutral" % context)


func _press_button(index: JoyButton) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	# Match the project's controller smokes: hold across two rendered frames so
	# both idle UI readers and physics-world readers see the physical press.
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await process_frame


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


func _node_label(value: Variant) -> String:
	var node := value as Node
	return str(node.get_path()) if node != null and is_instance_valid(node) else "<null/stale>"


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	_send_axis(RIGHT_X, 0.0)
	_send_axis(RIGHT_Y, 0.0)
	_send_axis(LEFT_Y, 0.0)
	print("")
	if _failures.is_empty():
		print("PASS: combat camera follows the active creature, keeps free controller orbit, survives switch/aim, and restores exploration repeatedly")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)
