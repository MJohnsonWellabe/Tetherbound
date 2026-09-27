extends SceneTree

## Headless check of the passive F10#2 named-fight recorder: it notices a
## production-shaped CombatManager fighting a body with the catalogue's
## `stormwood_named_encounter` meta, records tells (authored and measured),
## hits and misses, closes the row when the fight ends, ignores an ordinary
## wild, and never touches the fight. Rows only (no display, no frames).

const RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")

var _failures: Array[String] = []


class FakeManager extends Node:
	signal hit_landed(on_enemy: bool, amount: float)
	signal attack_missed(by_player: bool)
	var fighting := false
	var enemy: Node3D = null
	func is_fighting() -> bool: return fighting
	func enemy_body() -> Node3D: return enemy


class FakeBody extends Node3D:
	signal telegraph_started(seconds: float)
	signal lunge_started(heading: Vector3, distance: float)
	signal strike_ready()
	var instance: RefCounted = null


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	print("RECORDER CHECK %s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures.append(label)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var out := "user://stormwood_b_recorder_smoke_%d" % OS.get_process_id()
	var scene := Node3D.new()
	scene.name = "World"
	root.add_child(scene)
	current_scene = scene
	var manager := FakeManager.new()
	manager.name = "CombatManager"
	scene.add_child(manager)
	var recorder: Node = RECORDER.new(out, 1.0)
	root.add_child(recorder)
	await _frames(3)

	var plain := FakeBody.new()
	scene.add_child(plain)
	manager.enemy = plain
	manager.fighting = true
	await _frames(10)
	_check((recorder.get("rows") as Array).is_empty(), "an ordinary wild fight is not recorded")
	manager.fighting = false
	await _frames(3)

	var named := FakeBody.new()
	named.set_meta("stormwood_named_encounter", "capacitor_alpha")
	scene.add_child(named)
	manager.enemy = named
	manager.fighting = true
	await _frames(3)
	var ticks := Engine.physics_ticks_per_second
	named.telegraph_started.emit(0.8)
	await _frames(int(0.8 * ticks))
	named.lunge_started.emit(Vector3.FORWARD, 5.5)
	manager.hit_landed.emit(false, 17.3)
	await _frames(5)
	manager.attack_missed.emit(false)
	manager.hit_landed.emit(true, 9.0)
	await _frames(5)
	manager.fighting = false
	await _frames(3)

	var rows: Array = recorder.get("rows")
	_check(rows.size() == 1, "exactly one named fight row")
	if rows.size() == 1:
		var row: Dictionary = rows[0]
		_check(str(row.id) == "capacitor_alpha" and int(row.attempt) == 1, "row names the fight and attempt")
		_check((row.tells as Array).size() == 1, "one tell recorded")
		if (row.tells as Array).size() == 1:
			var tell: Dictionary = row.tells[0]
			_check(is_equal_approx(float(tell.authored_s), 0.8), "authored tell kept")
			_check(absf(float(tell.measured_s) - 0.8) <= 2.0 / float(ticks), "measured tell ≈ 0.8 s (%.3f)" % float(tell.measured_s))
			_check(str(tell.kind) == "lunge_started", "strike kind recorded")
		_check((row.hits as Array).size() == 3, "hit, miss and ally hit recorded (%d)" % (row.hits as Array).size())
		_check(str(row.end_reason) == "resolved" and row.has("seconds"), "row closes when the fight ends")
		var expected := "not_cleared" if root.get_node_or_null(^"Game") != null else "unknown"
		_check(str(row.outcome) == expected, "outcome read from progression, never guessed (%s)" % str(row.outcome))
	var file := FileAccess.open(out.path_join("named_route.json"), FileAccess.READ)
	_check(file != null and (JSON.parse_string(file.get_as_text()) as Array).size() == 1,
		"rows flushed to named_route.json")
	# A second fight with the same body is a new attempt, not a merged row.
	manager.fighting = true
	await _frames(3)
	manager.fighting = false
	await _frames(3)
	_check((recorder.get("rows") as Array).size() == 2 and int(rows[1].attempt) == 2,
		"a re-engagement is recorded as attempt 2")
	print("RECORDER SMOKE %s" % ("PASS" if _failures.is_empty() else "FAIL %s" % str(_failures)))
	quit(0 if _failures.is_empty() else 1)
