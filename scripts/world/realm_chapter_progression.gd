extends RefCounted

## Interprets a realm's authored chapter against the existing ProgressionState.
## Owns no saved state. World interactions emit events only after their physical
## action succeeds; this adapter checks story prerequisites, not physical access.
## Counts are named durable flags, never an incrementing counter.

static func flags_hold(progression: RefCounted, flags: Array) -> bool:
	for flag: String in flags:
		if not bool(progression.call("has", flag)):
			return false
	return true


static func _result() -> Dictionary:
	return {"accepted": false, "changed": false, "completed_ids": [], "granted_flags": []}


## event is an authored completion_event, count:<authored count flag>, or
## side:<authored chain id>:<authored step id>. Unknown events cannot set flags.
static func dispatch(progression: RefCounted, chapter: Dictionary, event: String) -> Dictionary:
	var result := _result()
	if progression == null or event.is_empty():
		return result
	for act: Dictionary in chapter.get("acts", []):
		if not flags_hold(progression, act.get("entry_flags", [])):
			continue
		for objective: Dictionary in act.get("objectives", []):
			if not flags_hold(progression, objective.get("requires_flags", [])):
				continue
			var counts: Array = objective.get("count_flags", [])
			if event.begins_with("count:") and counts.has(event.trim_prefix("count:")):
				result["accepted"] = true
				_set_flag(progression, event.trim_prefix("count:"), result)
			if str(objective.get("completion_event", "")) != event:
				continue
			# A counter objective cannot be completed by sending its aggregate event.
			if not counts.is_empty() and not flags_hold(progression, counts):
				continue
			result["accepted"] = true
			_complete(progression, objective, result)
	for chain: Dictionary in chapter.get("side_chains", []):
		if not _revealed(progression, chain):
			continue
		for step: Dictionary in chain.get("steps", []):
			var step_event := str(step.get("completion_event", "side:%s:%s" % [chain["id"], step["id"]]))
			if step_event == event and flags_hold(progression, step.get("requires_flags", [])):
				result["accepted"] = true
				_complete(progression, step, result)
	_merge(result, reconcile(progression, chapter))
	return result


## Called after load or an external progression revision. Recovers aggregate
## counts and missing entitlement flags, but never invents a story event, boss
## win, restoration witness, or reward conversation from an earlier milestone.
static func reconcile(progression: RefCounted, chapter: Dictionary) -> Dictionary:
	var result := _result()
	for act: Dictionary in chapter.get("acts", []):
		if not flags_hold(progression, act.get("entry_flags", [])):
			continue
		for objective: Dictionary in act.get("objectives", []):
			if not flags_hold(progression, objective.get("requires_flags", [])):
				continue
			var counts: Array = objective.get("count_flags", [])
			var already_complete := bool(progression.call("has", str(objective["flag_id"])))
			if already_complete or (not counts.is_empty() and flags_hold(progression, counts)):
				_complete(progression, objective, result)
	return result


static func _complete(progression: RefCounted, objective: Dictionary, result: Dictionary) -> void:
	# Entitlements are flags, not inventory consumables. Apply them before the
	# completion marker and repair missing ones safely when replaying an old save.
	for reward: String in objective.get("grants_flags", []):
		if _set_flag(progression, reward, result):
			result["granted_flags"].append(reward)
	if _set_flag(progression, str(objective["flag_id"]), result):
		result["completed_ids"].append(str(objective["id"]))


static func _set_flag(progression: RefCounted, flag: String, result: Dictionary) -> bool:
	if flag.is_empty() or bool(progression.call("has", flag)):
		return false
	progression.call("set_flag", flag)
	result["changed"] = true
	return true


static func _merge(into: Dictionary, other: Dictionary) -> void:
	into["changed"] = bool(into["changed"]) or bool(other["changed"])
	into["completed_ids"].append_array(other["completed_ids"])
	into["granted_flags"].append_array(other["granted_flags"])


static func _revealed(progression: RefCounted, chain: Dictionary) -> bool:
	var flag := str(chain.get("revealed_by", ""))
	return flag.is_empty() or bool(progression.call("has", flag))


## Read-only projection for the existing task feed. Side chains show actionable
## steps so a multi-step request does not remain just a title in the menu.
static func side_entries(progression: RefCounted, chapter: Dictionary) -> Array:
	var entries: Array = []
	for chain: Dictionary in chapter.get("side_chains", []):
		if not _revealed(progression, chain):
			continue
		var done := bool(progression.call("has", str(chain["completion_flag"])))
		var next_labels: Array[String] = []
		for step: Dictionary in chain.get("steps", []):
			if not bool(progression.call("has", str(step["flag_id"]))) \
					and flags_hold(progression, step.get("requires_flags", [])):
				next_labels.append(str(step["label"]))
		entries.append({"id": str(chain["id"]), "label": str(chain["title"]),
			"done": done, "how": "" if done else " ".join(next_labels)})
	return entries


static func count_progress(progression: RefCounted, chapter: Dictionary, objective_id: String) -> Vector2i:
	for act: Dictionary in chapter.get("acts", []):
		for objective: Dictionary in act.get("objectives", []):
			if str(objective["id"]) != objective_id:
				continue
			var counts: Array = objective.get("count_flags", [])
			var completed := 0
			for flag: String in counts:
				if bool(progression.call("has", flag)):
					completed += 1
			return Vector2i(completed, counts.size())
	return Vector2i.ZERO
