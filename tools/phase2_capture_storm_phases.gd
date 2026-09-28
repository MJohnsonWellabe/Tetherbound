extends "res://tools/phase2_capture_locations.gd"

## Stormwood's real Surge presentation at three representative normal-camera
## stands. The ephemeral realm clock is moved to each phase midpoint; the
## production Surge applies its settled presentation without changing saves.

const PHASES := ["calm", "building", "break", "fading"]
var _requested_phase := ""


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "stormwood":
		push_error("Storm phase capture requires Stormwood")
		return false
	var base_rows: Array[Dictionary] = []
	var seen := {}
	for row: Dictionary in _planned:
		if str(row.time) != "day" or str(row.view) != "close":
			continue
		if "__landmark__" in str(row.identity) or seen.has(row.identity):
			continue
		seen[row.identity] = true
		base_rows.append(row)
	if base_rows.size() < 3:
		return false
	var selected: Array[Dictionary] = [base_rows[0], base_rows[int(base_rows.size() / 2)], base_rows.back()]
	_planned.clear()
	for base: Dictionary in selected:
		for phase: String in PHASES:
			var row := base.duplicate(true)
			row["phase"] = phase
			row["frame_id"] = "%s__%s" % [str(base.frame_id), phase]
			_planned.append(row)
	return true


func _capture_row(row: Dictionary) -> void:
	_requested_phase = str(row.phase)
	await super._capture_row(row)


func _pin_time(time_name: String) -> Dictionary:
	var clock := await super._pin_time(time_name)
	if clock.is_empty():
		return clock
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	var game := root.get_node_or_null(^"Game")
	if surge == null or game == null:
		_failures.append("Stormwood Surge or Game is missing")
		return {}
	var selected := false
	for second in range(0, 2000, 5):
		var environment: Dictionary = game.get("realm_environment")
		var storm: Dictionary = environment.get("stormwood", {}).duplicate(true)
		storm["elapsed"] = float(second)
		environment["stormwood"] = storm
		game.set("realm_environment", environment)
		var info: Dictionary = surge.call("phase_info_at", _player.global_position)
		if str(info.get("phase", "")) != _requested_phase:
			continue
		storm["elapsed"] = float(second) + float(info.get("duration", 0.0)) * 0.5 - float(info.get("elapsed", 0.0))
		environment["stormwood"] = storm
		game.set("realm_environment", environment)
		selected = true
		break
	if not selected:
		_failures.append("Could not locate Surge phase %s" % _requested_phase)
		return {}
	for _frame in 3:
		await physics_frame
	surge.call("settle_presentation")
	for _frame in 5:
		await process_frame
	clock["stormwood_phase"] = str(surge.get("phase"))
	clock["stormwood_phase_info"] = surge.call("phase_info_at", _player.global_position)
	if str(clock.stormwood_phase) != _requested_phase:
		_failures.append("Surge phase mismatch: wanted %s got %s" % [_requested_phase, str(clock.stormwood_phase)])
		return {}
	return clock
