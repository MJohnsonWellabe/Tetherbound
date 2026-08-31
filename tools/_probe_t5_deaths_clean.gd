extends SceneTree

## AUDIT-H: two lethal falls, WITHOUT the dismantle step that precedes them in
## `tools/_play_t5_deaths.gd`. That script's dismantle portion pauses the tree
## permanently (see `ralph/reports/audit/H-2026-08-31.md` -- holding
## build_dismantle with nothing armed collides with the "inventory" action on
## the same joypad button and opens GameMenu, which the synthetic-input
## harness never presses B to close), which is why both "deaths" downstream
## reported landing on frame 11 at ~0 m/s: the world was already frozen.
## This isolates the fall/satchel question from that unrelated bug.
##
##   godot --headless --path . --script tools/_probe_t5_deaths_clean.gd

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
		print("T5CLEAN> BLOCKED: no player")
		quit(1)
		return
	await _stand(PATCH)
	await _deaths()

	print("")
	print("T5CLEAN> === deaths observations ===")
	for line in _notes:
		print("T5CLEAN> " + line)
	quit(0)


func _stand(xz: Vector2) -> void:
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	_player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	_player.velocity = Vector3.ZERO
	for i in 90:
		await physics_frame


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
		_notes.append("death %d — dropped from 120m carrying %d wood; landed on frame %d "
			% [i + 1, carried, landed_at] + "at %.0f m/s, health after = %.0f" % [top_speed, hp])
		var satchels: Array = _game.get("death_satchels") as Array
		_notes.append("  death satchels now: %d" % satchels.size())
		for f in 120:
			await physics_frame

	var final: Array = _game.get("death_satchels") as Array
	for i in final.size():
		var entry: Dictionary = final[i]
		var pos: Array = entry.get("position", [])
		if pos.size() == 3:
			_notes.append("  satchel %d at (%.1f, %.1f, %.1f)" % [
				i + 1, float(pos[0]), float(pos[1]), float(pos[2])])
	if final.size() >= 2:
		_notes.append("VERDICT: PASS — two deaths left two satchels; neither replaced the other.")
	elif final.size() == 1:
		_notes.append("VERDICT: one satchel after two deaths.")
	else:
		_notes.append("VERDICT: no satchels — check whether the falls were lethal at all.")
