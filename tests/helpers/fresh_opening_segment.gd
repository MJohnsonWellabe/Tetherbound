extends "res://tests/helpers/gate_a_opening_drive.gd"

## Reuse the production title, dialogue, starter and walking inputs, but never
## the older catch fixture's inventory drain, HP pinning or direct revival.
## A failed live fight is evidence; this segment cannot repair its state.
const EARNED_NAV := preload("res://tests/helpers/stick_navigator.gd")


func _walk_to_earned_prompt(target: Node3D, budget: int) -> bool:
	var nav := EARNED_NAV.new(_tree, _player, _rig, _earned_walk_stick)
	var closest := INF
	print("earned prompt approach: target=%s target_position=%s player=%s budget=%d" % [
		target.get_path(), target.global_position, _player.global_position, budget])
	for _frame in budget:
		if not is_instance_valid(target):
			_stop_left_stick()
			return false
		var offset := target.global_position - _player.global_position
		offset.y = 0.0
		closest = minf(closest, offset.length())
		# Keep the inherited 2 m approach criterion, but never press a shared
		# unrelated offer simply because the player is near the intended target.
		if offset.length() <= 2.0 and _earned_prompt_ready(target):
			_stop_left_stick()
			await _tap_action("interact")
			return true
		nav.step(target.global_position)
		await _tree.physics_frame
	_stop_left_stick()
	var colliders: Array[String] = []
	for index in _player.get_slide_collision_count():
		var collider: Object = _player.get_slide_collision(index).get_collider()
		colliders.append(str(collider.name) if collider is Node else str(collider))
	print("earned prompt approach failed: target=%s target_position=%s player=%s closest=%.3f winner=%s offer=%s can_walk=%s colliders=%s" % [
		target.get_path(), target.global_position, _player.global_position, closest,
		_arbiter.call("winning_provider"), _arbiter.call("winner"), nav.can_walk(), colliders])
	return false


func _earned_prompt_ready(target: Node3D) -> bool:
	return is_instance_valid(target) and bool(_arbiter.call("enabled")) \
		and _arbiter.call("winning_provider") == target \
		and bool(_arbiter.call("winner").get("actionable", false))


func _earned_walk_stick(x: float, y: float) -> void:
	_send_axis(JOY_AXIS_LEFT_X, x)
	_send_axis(JOY_AXIS_LEFT_Y, y)

func _walk_to_and_engage_wild(target: Node3D, budget: int) -> bool:
	for _frame in budget:
		if not is_instance_valid(target) or not bool(target.call("is_alive")):
			_stop_left_stick()
			return false
		if bool(_combat.call("is_fighting")):
			_stop_left_stick()
			return _engaged_expected_body(target)
		var offer: Dictionary = _arbiter.call("winner")
		if (_arbiter.call("winning_provider") == _encounter
				and bool(offer.get("actionable", false))
				and _encounter.call("_engageable") == target):
			_stop_left_stick()
			# Do not yield between observing the offered body and pressing.
			# The provider is shared by every nearby wild creature.
			print("live wild approach: exact offered target ", target.name)
			await _tap_action("interact")
			for _settle in 180:
				if bool(_combat.call("is_fighting")):
					return _engaged_expected_body(target)
				await _tree.physics_frame
			_fail("exact wild offer did not enter combat after Interact")
			return false
		await _drive_body_toward(_player, target.global_position, 1)
	_stop_left_stick()
	return false


func _engaged_expected_body(target: Node3D) -> bool:
	var actual: Node3D = _combat.call("enemy_body")
	if actual == target:
		_checkpoint("engaged exact live target %s (%s)" % [target.name, target.get("species_id")])
		return true
	_fail("wild engagement selected %s instead of the offered target %s" % [
		actual.name if actual != null else "<none>", target.name])
	return false


func catch_existing(tree: SceneTree, world: Node, game: Node,
		player: CharacterBody3D, rig: Node3D, wild: Node3D) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	_started_ms = Time.get_ticks_msec()
	if not _collect_world_nodes():
		return _result()
	_wild = wild
	if not is_instance_valid(_wild) or not bool(_combat.call("is_fighting")):
		_fail("live capture segment requires an already engaged wild creature")
		return _result()
	if not _engaged_expected_body(_wild):
		return _result()
	var before := int(_game.party.size())
	if before >= 5:
		_fail("live capture preparation cannot bypass the five-slot roster ceremony")
		return _result()
	if not await _fight_until_catchable() or not await _catch_with_real_throws():
		return _result()
	for _frame in 900:
		if not bool(_combat.call("is_fighting")) and int(_game.party.size()) == before + 1:
			break
		await _tree.physics_frame
	if (bool(_combat.call("is_fighting")) or str(_combat.call("outcome")) != CAUGHT_OUTCOME
			or int(_game.party.size()) != before + 1):
		_fail("live capture did not finish with exactly one earned party addition")
	return _result()

func open_road_gate() -> Dictionary:
	var key := _find_interactable(["take the old key"])
	if key == null or not await _walk_to_earned_prompt(key, 2600):
		_fail("could not walk to and take the real village key")
		return _result()
	if int(_game.inventory.count("castle_gate_key")) != 1:
		_fail("physical key pickup did not produce its inventory receipt")
		return _result()
	var gate: Node3D = null
	for node in _descendants(_world):
		var script := node.get_script() as Script
		if script != null and script.resource_path == "res://scripts/world/road_gate.gd":
			if str(node.get("flag_id")) == "road_gate_open":
				gate = node.get_node_or_null("Interactable") as Node3D
				if gate != null:
					break
	if gate == null or not await _walk_to_earned_prompt(gate, 2600):
		_fail("could not walk to and unlock the real village gate")
		return _result()
	if not await _close_dialogue(20):
		_fail("village gate dialogue did not return input")
		return _result()
	if not bool(_game.progression.call("has", "road_gate_open")):
		_fail("ordinary key/gate interaction did not earn road_gate_open")
	elif int(_game.inventory.count("castle_gate_key")) != 0:
		_fail("village gate did not consume its key")
	else:
		_checkpoint("village key earned and consumed by the real gate")
	return _result()

func _catch_with_real_throws() -> bool:
	_stop_left_stick()
	var starting_orbs := _orbs_held()
	if starting_orbs <= 0:
		_fail("fresh opening has no earned orbs")
		return false
	_checkpoint("live catch begins with %d earned orbs; no HP or inventory fixture" % starting_orbs)
	var launches := 0
	var refused := 0
	var blocked := 0
	while launches < 40:
		if _live_catch_finished():
			return true
		if not bool(_combat.call("is_fighting")):
			_fail("live tutorial fight ended without capture: %s" % str(_combat.call("outcome")))
			return false
		var own: RefCounted = _combat.call("active_creature")
		var foe: RefCounted = _combat.call("enemy")
		if own == null or foe == null or bool(own.get("fainted")) or bool(foe.get("fainted")):
			_fail("live tutorial catch lost an eligible creature; no fixture revival is permitted")
			return false
		if not await _open_throw_aim():
			if _live_catch_finished():
				return true
			_fail("live catch aim failed: %s" % _why_the_aim_would_not_open())
			return false
		if not await _aim_at_wild():
			_fail("live catch right-stick aim did not converge")
			return false
		if not await _step_until_the_shot_is_clear():
			blocked += 1
			if blocked > BLOCKED_LINES_ALLOWED:
				_fail("live catch cannot find a clear physical throw line")
				return false
			await _wander_for_a_new_angle()
			continue
		blocked = 0
		if not await _aim_at_wild():
			_fail("live catch aim did not converge after moving")
			return false
		# `_aim_at_wild()` has already released look and survived a camera-process
		# plus physics refresh. Re-read synchronously at the actual pad dispatch
		# boundary so no stale convergence success can spend an earned orb.
		if not _final_throw_verdict_ready():
			return false
		var results_before := _catch_results.size()
		var strikes_before := _throw_strikes
		var misses_before := _throw_misses
		var orbs_before := _orbs_held()
		await _tap_action(THROW_ACTION)
		launches += 1
		for _frame in 360:
			if (_throw_strikes > strikes_before or _throw_misses > misses_before
					or not bool(_combat.call("is_fighting"))):
				break
			await _tree.physics_frame
		if _live_catch_finished():
			return true
		if _throw_misses > misses_before:
			_checkpoint("live physical throw %d missed" % launches)
			# A clear camera ray can still launch from behind another body's
			# shoulder. Respond to the observed physical miss by walking to a
			# different angle; repeating that same shot wastes the live fight.
			await _wander_for_a_new_angle()
			continue
		if _throw_strikes <= strikes_before:
			if _orbs_held() == orbs_before:
				refused += 1
				launches -= 1
				if refused > 8:
					_fail("live throw repeatedly refused: %s" % _why_the_aim_would_not_open())
					return false
				await _close_to_wild(AIM_THROWABLE_METRES, 900)
				continue
			_fail("live orb was spent without a physical strike or miss")
			return false
		for _frame in 900:
			if _catch_results.size() > results_before or not bool(_combat.call("is_fighting")):
				break
			await _tree.physics_frame
		if _live_catch_finished():
			return true
	_fail("live catch exhausted its 40-launch observation budget")
	return false


func _step_until_the_shot_is_clear() -> bool:
	if not await super._step_until_the_shot_is_clear():
		return false
	var throw: Node = _combat.call("throw_aim")
	if throw == null:
		return false
	var report: Dictionary = throw.call("aim_report")
	# Camera eligibility is not hand-to-target trajectory clearance. Use the
	# displayed physical obstruction before spending an earned orb; the caller
	# already has a bounded ordinary walk to find another angle.
	if bool(report.get("trajectory_blocked", false)):
		_checkpoint("live catch preview is obstructed; changing the physical angle")
		return false
	return true


func _live_catch_finished() -> bool:
	return (_catch_results.size() > 0 and _catch_results[-1]) or (
		not bool(_combat.call("is_fighting")) and str(_combat.call("outcome")) == CAUGHT_OUTCOME)


## Fail closed if a future inherited path accidentally reaches a fixture seam.
func _hold_the_fight_where_it_was() -> void:
	_fail("forbidden HP fixture reached from fresh opening")


func _drain_satchel_to_last_orb() -> int:
	_fail("forbidden inventory fixture reached from fresh opening")
	return -1


func _final_throw_verdict_ready() -> bool:
	var throw: Node = _combat.call("throw_aim")
	if throw == null or not bool(_combat.call("is_aiming")):
		_fail("live catch final aim is no longer active; no orb spent")
		return false
	var current: Dictionary = throw.call("launch_assist_diagnostics")
	var preview: Dictionary = throw.call("aim_report")
	if (not bool(current.get("eligible", false)) or preview.is_empty()
			or bool(preview.get("trajectory_blocked", false))):
		_fail("live catch final throw refused before spending an orb: current=%s preview=%s" % [
			str(current), str(preview)])
		return false
	return true


## Transient failures stay inside the inherited convergence timer. The final
## dispatch check above remains the strict, failure-reporting refusal.
func _aim_readiness_ready() -> bool:
	var throw: Node = _combat.call("throw_aim") if _combat != null else null
	if throw == null or not bool(_combat.call("is_aiming")):
		return false
	var current: Dictionary = throw.call("launch_assist_diagnostics")
	var preview: Dictionary = throw.call("aim_report")
	return bool(current.get("eligible", false)) and not preview.is_empty() \
		and not bool(preview.get("trajectory_blocked", false))
