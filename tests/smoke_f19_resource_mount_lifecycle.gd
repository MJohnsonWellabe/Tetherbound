extends SceneTree

## Actual Node lifecycle, with a declared cache entry. No world/stock/reward
## fixture is claimed as earned placement or resource delivery.
const MOUNT := preload("res://scripts/world/f32_world_mount.gd")
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
		print("FAIL: " + message)

func _run() -> void:
	var mount := MOUNT.new()
	root.add_child(mount)
	_check(mount.node_for("missing") == null, "missing cached site is absent")
	var old := Node3D.new()
	mount.add_child(old)
	mount.get("_mounted")["declared-site"] = old
	_check(mount.node_for("declared-site") == old, "actual live cached node is readable")
	old.queue_free()
	_check(mount.node_for("declared-site") == null, "queued deletion is unavailable before destruction")
	for frame in 2: await process_frame
	_check(not is_instance_valid(old), "old adopted placement is actually destroyed")
	_check(mount.node_for("declared-site") == null, "freed Variant returns absence without a script error")
	var replacement := Node3D.new()
	mount.add_child(replacement)
	mount.get("_mounted")["declared-site"] = replacement
	_check(mount.node_for("declared-site") == replacement, "a replacement of the same site is readable")
	mount.remove_child(replacement)
	_check(mount.node_for("declared-site") == null, "detached cached node is unavailable")
	replacement.free()
	_check(mount.node_for("declared-site") == null, "immediate destruction is also safe")
	mount.queue_free()
	for frame in 2: await process_frame
	print("F19 RESOURCE MOUNT LIFECYCLE " + JSON.stringify({"checks": _checks,
		"failures": _failures, "scope": "Actual lightweight Node lifecycle; no stock, placement or earned-play claim"}))
	quit(0 if _failures.is_empty() else 1)
