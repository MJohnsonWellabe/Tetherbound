extends "res://tests/helpers/meadows_earned_hall_segment.gd"

## Earned Sigils/Hall for the C1 chain: the read-only helper
## (`tests/helpers/meadows_earned_hall_segment.gd`) with the same disclosed
## prompt-press handling as `relay_route.gd` (BLOCKERS.md B4): a trainer's real
## Interact can open its dialogue without the arbiter's `activated` signal.
## `_talk()` still requires the exact expected conversation.
const PRESS_TRIES := 3
## B5: after the first Sigil captain the helper walks on with a drained active
## creature (bramblebun 0 HP) and loses the next ordinary wild fight's budget.
## Before each road leg, when the active creature is fainted or under this
## fraction, run the helper's own `_prepare()` (real Satchel revive/potion and
## party-cycle input) first. Disclosed as `between_fight_care`.
const CARE_BELOW_FRACTION := 0.4
const TAIL := preload("res://tests/helpers/gate_b_tail_segment.gd")
## Coordinator ruling on B5, step 1: an earned camp rest before the Sigil loop,
## the way a player would. The nearest authored rest before the loop is
## `riverwatch_rest` (band3 props.json, rest at (211,3700), one creature bed),
## back across the already-restored Mill. The same production bed-panel and
## "Rest until morning" input the camp_tournament rest used
## (`gate_b_tail_segment.gd` `_assign_to_bed`/`_sleep_at_camp`) puts the most
## drained members to bed, one per night. Then the party walks back over the
## Mill to where the helper's own departure spine starts.
const RIVERWATCH := Vector2(211.0, 3700.0)
const MAX_NIGHTS := 3
const WELL_RESTED_FRACTION := 0.8
## Ruling step 2 switch: when true, bench care no longer re-runs `_prepare()`.
const BENCH_CARE_PREPARES := true


class CampInput extends TAIL:
	pass

var _activated_path := ""


func _on_activated(provider: Object) -> void:
	super._on_activated(provider)
	_activated_path = str((provider as Node).get_path()) if provider is Node and is_instance_valid(provider) else str(provider)


func _press_prompt(prompt: Node3D) -> bool:
	for attempt in PRESS_TRIES:
		if not await _approach_prompt(prompt):
			return false
		var expected := prompt.get_instance_id()
		_activated_id = 0
		_activated_path = ""
		await _input._tap("interact")
		if _activated_id == expected:
			return true
		# Attempt 2 showed the press does reach the trainer: with nothing
		# reported through the arbiter's `activated` signal, a modal opened a
		# moment later during the re-approach. Give the real press time to
		# open its dialogue; `_talk()` still requires the exact expected
		# conversation to finish, so a wrong provider cannot pass.
		if _activated_id == 0:
			for _frame in 240:
				if _activated_id == expected:
					return true
				if bool(_panel.call("is_open")) and not _fighting():
					_receipt("prompt_press_delayed_dialogue", {"target": str(prompt.get_path()),
						"frames_waited": _frame, "activated_signal": "<none>", "player": _player.global_position})
					return true
				if _fighting() or _activated_id != 0:
					break
				await _tree.physics_frame
		if _activated_id == expected:
			return true
		var side_effect := INPUT_OWNER.current(_tree) != null or _fighting() or bool(_panel.call("is_open"))
		_receipt("prompt_press_retry", {"attempt": attempt + 1, "target": str(prompt.get_path()),
			"activated": _activated_path if _activated_id != 0 else "<nothing>", "side_effect": side_effect,
			"player": _player.global_position})
		if side_effect:
			return _fail("Physical Interact activated %s (not the offered target) and it opened a modal or fight" % _activated_path)
		for _frame in 20:
			await _tree.physics_frame
	return _fail("Physical Interact never activated the exact offered target in %d ordinary presses" % PRESS_TRIES)


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	if not _fighting() and INPUT_OWNER.current(_tree) == null:
		if not await _bench_care():
			return false
	return await super._walk_ground(at, radius)


## Attempt 2 of B5: the live pilot voluntarily cycles to benched members, and
## the 22 HP bramblebun it cycled to fainted and stalled the fight. So keep
## every member usable, not just the active one: revive the fainted and give
## a small potion to anyone under CARE_BELOW_FRACTION while stock lasts, each
## through the team helper's real Satchel seam (`care_existing`), then the
## helper's own `_prepare()` for pilot selection.
func _bench_care() -> bool:
	var party: RefCounted = _game.get("party")
	var acted := false
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		var item := ""
		if bool(member.get("fainted")) and _count("revive") > 0:
			item = "revive"
		elif not bool(member.get("fainted")) and _count("potion_small") > 0 \
				and float(member.get("hp")) < float(member.get("max_hp")) * CARE_BELOW_FRACTION:
			item = "potion_small"
		if item.is_empty():
			continue
		var before := {"index": index, "species": str(member.get("species_id")), "hp": float(member.get("hp")),
			"max_hp": float(member.get("max_hp")), "fainted": bool(member.get("fainted")), "item": item}
		var observed: Dictionary = await CARE.new().care_existing(_tree, _world, _game, item, index)
		if not bool(observed.get("passed", false)):
			return _fail("Real Satchel care failed: " + str(observed.get("failures", [])))
		before["hp_after"] = float(member.get("hp"))
		_receipt("between_fight_care", before)
		acted = true
	if acted and BENCH_CARE_PREPARES:
		return await _prepare()
	return true


func _travel() -> bool:
	if not await _pre_sigil_camp_rest():
		return false
	return await super._travel()


func _rest_point_near(at: Vector2) -> Node3D:
	for node: Node in _world.find_children("*", "Node3D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("rest_point.gd") \
				and Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z).distance_to(at) < 1.0:
			return node as Node3D
	return null


func _pre_sigil_camp_rest() -> bool:
	var terrain := _read(TERRAIN)
	var crossing := mill_config(terrain)
	var channel: Dictionary = crossing.get("channel", {})
	var bank := float(channel.get("half_width", 0.0)) + float(channel.get("rim", 0.0)) + 3.0
	var band := trail_points(terrain, "bands", "band3_the_river_lock")
	var road: Array = crossing.get("road", [])
	var camp := _rest_point_near(RIVERWATCH)
	if camp == null or band.is_empty() or road.is_empty() or not bool(_mill.call("is_open")):
		return _fail("The authored riverwatch rest, band3 road or open Mill is unavailable for the pre-Sigil rest")
	var bed := camp.get_node_or_null("CampCreatureBed") as Node3D
	if bed == null:
		return _fail("The riverwatch rest has no real creature bed")
	var start := Vector2(_player.global_position.x, _player.global_position.z)
	var back: Array[Vector2] = [_mill.call("far_point", bank), _mill.call("near_point", bank)]
	var from := nearest_index(band, _v2(road[0]))
	var to := nearest_index(band, RIVERWATCH)
	var step := -1 if to < from else 1
	for index in range(from, to + step, step):
		back.append(band[index])
	_receipt("pre_sigil_camp_route", {"from": start, "camp": RIVERWATCH, "waypoints": back.size(),
		"party": _hp_rows()})
	for point: Vector2 in back:
		if not await super._walk_ground(point, 1.5):
			return false
	var driver := CampInput.new()
	driver._tree = _tree
	driver._world = _world
	driver._game = _game
	driver._player = _player
	driver._rig = _rig
	driver._party = _game.get("party")
	driver._progression = _game.get("progression")
	if not driver._collect_nodes():
		return _fail("Camp input dependencies are missing: " + str(driver.failures))
	driver._resolve_move_bindings()
	driver._bed = bed
	driver._bedroll = camp
	for night in MAX_NIGHTS:
		var worst := -1
		var worst_fraction := WELL_RESTED_FRACTION
		for index in int(driver._party.call("size")):
			var member: RefCounted = driver._party.call("at", index)
			var fraction := 0.0 if bool(member.get("fainted")) else float(member.get("hp")) / float(member.get("max_hp"))
			if fraction < worst_fraction:
				worst = index
				worst_fraction = fraction
		if worst < 0:
			break
		var day_before := int(_game.get("day"))
		var member: RefCounted = driver._party.call("at", worst)
		var before := {"night": night + 1, "index": worst, "species": str(member.get("species_id")),
			"hp": float(member.get("hp")), "max_hp": float(member.get("max_hp")), "fainted": bool(member.get("fainted"))}
		if not await driver._assign_to_bed(worst) or not await driver._sleep_at_camp():
			return _fail("Real riverwatch bed/rest input failed: " + str(driver.failures))
		for _frame in 120:
			if INPUT_OWNER.current(_tree) == null and not _tree.paused:
				break
			await _tree.physics_frame
		before["hp_after"] = float(member.get("hp"))
		before["day"] = [day_before, int(_game.get("day"))]
		_receipt("pre_sigil_camp_night", before)
		if int(_game.get("day")) != day_before + 1:
			return _fail("A riverwatch night did not advance the day")
	back.reverse()
	for point: Vector2 in back:
		if not await super._walk_ground(point, 1.5):
			return false
	if not await super._walk_ground(start, 1.5):
		return false
	_receipt("pre_sigil_camp_done", {"party": _hp_rows(), "player": _player.global_position})
	return true


func _hp_rows() -> Array:
	var rows: Array = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		rows.append("%s L%d %d/%d" % [member.get("species_id"), int(member.get("level")),
			int(member.get("hp")), int(member.get("max_hp"))])
	return rows
