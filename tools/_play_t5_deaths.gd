extends SceneTree

## T5-CARE: two deaths and a dismantle, instrumented.
##
##   godot --headless --path . --script tools/_play_t5_deaths.gd
##
## Two questions `tools/_play_t5_freeplay.gd` left ambiguous, split into their
## own short run so each gets a clean world:
##
##   * CLAUDE.md: "multiple death satchels persist". One death leaving one
##     satchel is already shown; the question is whether a SECOND death leaves a
##     second one or replaces the first.
##   * Dismantle with refund (H1). The freeplay run pressed the button standing
##     6m away facing elsewhere and removed nothing, which says nothing about
##     whether dismantle works.
##
## The fall is instrumented because the freeplay run reported health 100 after a
## 90m drop -- i.e. the player did not die at all -- and a death test that does
## not verify the death is not a death test.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PATCH := Vector2(30.0, -40.0)

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _notes: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _player == null:
		print("T5> BLOCKED: no player")
		quit(1)
		return
	await _stand(PATCH)

	await _dismantle()
	await _deaths()

	print("")
	print("T5> === deaths / dismantle observations ===")
	for line in _notes:
		print("T5> " + line)
	quit(0)


func _stand(xz: Vector2) -> void:
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	_player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	_player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame


## Place one piece, stand in front of it facing it, and press dismantle.
func _dismantle() -> void:
	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("add", id, 200)
	var placer := _find_placer()
	if placer == null:
		_notes.append("H1 dismantle: no BuildPlacer")
		return
	_game.set("pending_build", "creature_bed")
	for i in 30:
		await physics_frame
	var ghost: Node3D = placer.get("_ghost") as Node3D
	if ghost == null:
		_notes.append("H1 dismantle: arming produced no ghost")
		return
	await _pad(_pad_button_for("build_place"))
	for i in 25:
		await physics_frame
	_game.set("pending_build", "")
	for i in 15:
		await physics_frame

	var records: Array = _game.get("placed_buildings") as Array
	if records.is_empty():
		_notes.append("H1 dismantle: nothing was placed to dismantle")
		return
	var last: Dictionary = records.back()
	var lp: Array = last.get("position", [])
	var piece_at := Vector3(float(lp[0]), float(lp[1]), float(lp[2]))
	_notes.append("H1: placed a %s at (%.1f, %.1f, %.1f)" % [
		str(last.get("id", "?")), piece_at.x, piece_at.y, piece_at.z])

	# `build_placer.gd` picks its dismantle target from what the player is
	# looking at within DISMANTLE_RANGE (8m). Stand 3m back and face it: the
	# placer projects down the player's own -Z, so -Z must point at the piece.
	var back := Vector3(0.0, 0.0, 1.0) * 3.0
	_player.global_position = Vector3(piece_at.x, 0.0, piece_at.z) + back
	_player.global_position.y = float(_world.call("ground_height_at",
		_player.global_position.x, _player.global_position.z)) + 1.0
	_player.global_rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	for i in 45:
		await physics_frame
	var wood_pre := int(inventory.call("count", "wood"))
	var n_pre := (_game.get("placed_buildings") as Array).size()
	var target: Variant = placer.get("_dismantle_target")
	_notes.append("H1 dismantle: standing 3m south facing -Z; placer's highlighted target is %s" % [
		"<none>" if target == null else str((target as Node).name)])
	# Held, not tapped: `build_placer.gd` reads `is_action_pressed` for
	# dismantle and needs the button down across frames.
	await _hold(_pad_button_for("build_dismantle"), 60)
	for i in 30:
		await physics_frame
	var n_post := (_game.get("placed_buildings") as Array).size()
	var refunded := int(inventory.call("count", "wood")) - wood_pre
	if n_post < n_pre:
		_notes.append("H1 dismantle VERDICT: PASS — removed a piece (%d -> %d records), refunded %d wood."
			% [n_pre, n_post, refunded])
	else:
		_notes.append("H1 dismantle VERDICT: FAIL — aimed at the piece from 3m with the button "
			+ "held for a second, %d record(s) still standing." % n_post)


## Two lethal falls in two places.
func _deaths() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var vitals: RefCounted = _player.get("vitals") as RefCounted
	var spots: Array[Vector2] = [PATCH, PATCH + Vector2(18.0, 12.0)]
	for i in spots.size():
		await _stand(spots[i])
		inventory.call("add", "wood", 10 + i)
		vitals.set("health", 100.0)
		var carried := int(inventory.call("count", "wood"))
		var from := _player.global_position
		_player.global_position = from + Vector3.UP * 120.0
		_player.velocity = Vector3.ZERO
		var top_speed := 0.0
		var landed_at := -1
		for f in 600:
			await physics_frame
			top_speed = maxf(top_speed, -_player.velocity.y)
			if _player.is_on_floor() and f > 10:
				landed_at = f
				break
		for f in 120:
			await physics_frame
		var hp := float(vitals.get("health"))
		_notes.append("H/inventory: death %d — dropped from 120m carrying %d wood; landed on frame %d "
			% [i + 1, carried, landed_at] + "at %.0f m/s, health after = %.0f" % [top_speed, hp])
		var satchels: Array = _game.get("death_satchels") as Array
		_notes.append("H/inventory:   death satchels now: %d" % satchels.size())
		for f in 120:
			await physics_frame

	var final: Array = _game.get("death_satchels") as Array
	for i in final.size():
		var entry: Dictionary = final[i]
		var pos: Array = entry.get("position", [])
		if pos.size() == 3:
			_notes.append("H/inventory:   satchel %d at (%.1f, %.1f, %.1f)" % [
				i + 1, float(pos[0]), float(pos[1]), float(pos[2])])
	if final.size() >= 2:
		_notes.append("H/inventory VERDICT: PASS — two deaths left two satchels; neither replaced "
			+ "the other, which is the hard rule.")
	elif final.size() == 1:
		_notes.append("H/inventory VERDICT: one satchel after two deaths.")
	else:
		_notes.append("H/inventory VERDICT: no satchels — check whether the falls were lethal at all.")


func _find_placer() -> Node:
	for node in _world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("build_placer.gd"):
			return node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _pad(button_index: int) -> void:
	await _hold(button_index, 2)


func _hold(button_index: int, frames: int) -> void:
	if button_index < 0:
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in frames:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 6:
		await physics_frame
