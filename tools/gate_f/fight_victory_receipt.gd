extends RefCounted

const PROGRESSION := preload("res://scripts/creatures/progression.gd")

## Observe the real manager.exited signal; never infer victory from idle time,
## an injected attack, a label-keyed award dictionary or a stale outcome field.
var outcomes: Array[String] = []
var members: Array = []
var before: Array = []
var _manager: Node


func begin(manager: Node) -> bool:
	if not is_instance_valid(manager) or not manager.has_signal("exited"):
		return false
	_manager = manager
	members = (manager.get("_party") as Array).duplicate()
	for member: RefCounted in members:
		before.append({"level": int(member.get("level")), "xp": int(member.get("xp"))})
	manager.connect("exited", _exited)
	return true


func _exited(outcome: String) -> void:
	outcomes.append(outcome)


func finish(still_running: bool) -> Dictionary:
	if is_instance_valid(_manager) and _manager.is_connected("exited", _exited):
		_manager.disconnect("exited", _exited)
	var result := {"ok": false, "outcomes": outcomes.duplicate(), "xp_progress": [], "why": ""}
	if still_running:
		result.why = "fight/battle still running at the step boundary"
		return result
	if outcomes.is_empty():
		result.why = "no production combat exit was observed"
		return result
	for outcome in outcomes:
		if outcome != "won":
			result.why = "production combat ended as '%s', not won" % outcome
			return result
	if not is_instance_valid(_manager) or members.is_empty():
		result.why = "victory party readback unavailable"
		return result
	var current: Array = _manager.get("_party")
	if current != members:
		result.why = "combat party identity/order changed"
		return result
	var cap := int(PROGRESSION.config().get("level", {}).get("cap", 100))
	var all_capped := true
	for index in members.size():
		var member: RefCounted = members[index]
		var level := int(member.get("level"))
		var xp := int(member.get("xp"))
		all_capped = all_capped and int(before[index].level) >= cap
		if level > int(before[index].level) or (level == int(before[index].level) and xp > int(before[index].xp)):
			result.xp_progress.append({"index": index, "before": before[index], "level": level, "xp": xp})
	if result.xp_progress.is_empty() and not all_capped:
		result.why = "won exit without any live uncapped-party XP/level progress"
		return result
	result.ok = true
	result.why = "production won exit and live XP progress verified" if not result.xp_progress.is_empty() \
		else "production won exit verified; every party member was already level-capped"
	return result
