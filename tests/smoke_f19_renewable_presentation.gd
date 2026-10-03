extends SceneTree

const HARVEST := preload("res://scripts/world/harvest_node.gd")

class Source extends Node:
	signal settled
	var current := {}
	func stock(_realm: String, _site: String) -> Dictionary: return current.duplicate(true)

var assertions := 0
var failures: Array[String] = []

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var game: Node = root.get_node("Game")
	var source := Source.new()
	source.current = {"revision": 0, "next_ready_day": int(game.day) + 1}
	var node := HARVEST.new()
	node._renewable_site_id = "declared-fixture-source"
	node._source_service = source
	node.set_renewable_stock(source.current)
	_check(node._renewable_stock == source.current, "actual supplied stock retained")
	_check(not node._taken, "detached stock updates do not perform world presentation")
	_check(node.visible, "detached visibility unchanged")
	root.add_child(node)
	_check(node._taken, "real ready reconciles supplied not-yet-ready stock immediately")
	_check(not node.visible, "unready live shell is hidden")
	source.current.next_ready_day = int(game.day)
	node.set_renewable_stock(source.current)
	_check(not node._taken, "ready stock restores the mounted shell")
	_check(node.visible, "ready live shell visible")
	root.remove_child(node)
	source.current.next_ready_day = int(game.day) + 1
	node.set_renewable_stock(source.current)
	_check(not node._taken, "a detached snapshot stays stored without an absolute root lookup")
	_check(node._renewable_stock == source.current, "detached snapshot recorded")
	node.free()
	source.free()
	print("F19 RENEWABLE PRESENTATION " + JSON.stringify({"assertions": assertions, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _check(value: bool, message: String) -> void:
	assertions += 1
	if not value: failures.append(message)
