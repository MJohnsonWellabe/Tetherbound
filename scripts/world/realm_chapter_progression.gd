extends RefCounted

## Interprets a realm's authored chapter against the existing ProgressionState.
## Owns no saved state. World interactions emit events only after their physical
## action succeeds; this adapter checks story prerequisites, not physical access.
## Counts are named durable flags, never an incrementing counter.
##
## ## Stage B Wave 6 lane 6.E: the flags this file sets are WORLD facts
##
## D103. Every id this file writes -- an act completion, a boss defeat, a storm
## anchor going dark, a route unlocking, a side-chain step -- is `world` in
## `data/progression/flag_scopes.json`. Written straight onto
## `progression` they land in `WorldState.flags` on whichever peer happened to
## run the code, and nothing crosses the wire: two players standing in
## Cloudreach would disagree about whether the counterweight road is down.
##
## So `dispatch()` and `reconcile()` now take an optional `writer` -- a
## `Callable(flag: String) -> Dictionary` returning `world_ledger.gd`'s verdict
## shape. `realm_chapter_events.gd` supplies one that submits a `set_world_flag`
## intent stamped with the REALM'S OWN id (D97; never `Game.current_realm`,
## which from Wave 6 is whichever realm the local player is standing in). The
## host commits it; every peer applies the delta.
##
## The writer is OPTIONAL and its absence is not a fallback nobody takes: this
## file is pure and node-free (D02), `tests/test_realm_chapter_progression.gd`
## drives it against a bare `ProgressionState` with no scene tree and no `Game`,
## and that path must keep writing locally or every rule in this file becomes
## untestable without booting a world.
##
## ## `pending` is not `changed`
##
## A client's submit returns `pending`: the host has not answered yet, so the
## flag is NOT set and `changed` stays false -- a caller that spends a repair
## cost on `changed` must not spend it on a maybe. The result carries `pending`
## separately so a caller can tell "the host said no" from "the host has not
## said anything yet" and settle its own half when the delta lands
## (`cloudreach_physical_runtime.gd::_on_delta_applied`).

static func flags_hold(progression: RefCounted, flags: Array) -> bool:
	for flag: String in flags:
		if not bool(progression.call("has", flag)):
			return false
	return true


static func _result() -> Dictionary:
	return {"accepted": false, "changed": false, "pending": false,
		"completed_ids": [], "granted_flags": []}


## event is an authored completion_event, count:<authored count flag>, or
## side:<authored chain id>:<authored step id>. Unknown events cannot set flags.
static func dispatch(progression: RefCounted, chapter: Dictionary, event: String,
		writer: Callable = Callable()) -> Dictionary:
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
				_set_flag(progression, event.trim_prefix("count:"), result, writer)
			if str(objective.get("completion_event", "")) != event:
				continue
			# A counter objective cannot be completed by sending its aggregate event.
			if not counts.is_empty() and not flags_hold(progression, counts):
				continue
			result["accepted"] = true
			_complete(progression, objective, result, writer)
	for chain: Dictionary in chapter.get("side_chains", []):
		if not _revealed(progression, chain):
			continue
		for step: Dictionary in chain.get("steps", []):
			var step_event := str(step.get("completion_event", "side:%s:%s" % [chain["id"], step["id"]]))
			if step_event == event and flags_hold(progression, step.get("requires_flags", [])):
				result["accepted"] = true
				_complete(progression, step, result, writer)
	_merge(result, reconcile(progression, chapter, writer))
	return result


## Called after load or an external progression revision. Recovers aggregate
## counts and missing entitlement flags, but never invents a story event, boss
## win, restoration witness, or reward conversation from an earlier milestone.
static func reconcile(progression: RefCounted, chapter: Dictionary,
		writer: Callable = Callable()) -> Dictionary:
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
				_complete(progression, objective, result, writer)
	return result


static func _complete(progression: RefCounted, objective: Dictionary, result: Dictionary,
		writer: Callable = Callable()) -> void:
	# Entitlements are flags, not inventory consumables. Apply them before the
	# completion marker and repair missing ones safely when replaying an old save.
	for reward: String in objective.get("grants_flags", []):
		if _set_flag(progression, reward, result, writer):
			result["granted_flags"].append(reward)
	if _set_flag(progression, str(objective["flag_id"]), result, writer):
		result["completed_ids"].append(str(objective["id"]))


## Write one chapter flag, and answer whether the world NOW says it.
##
## With a `writer` this submits an intent and takes the ledger's word for it:
##   * `ok`      -- committed here and now (solo, or the host). The flag is set.
##   * `pending` -- a client, waiting on the host. NOTHING is set locally, and
##                  `result["pending"]` says so; the committed delta is what
##                  eventually sets it, and `reconcile()` (driven by the
##                  `progression_restore` sweep and by the revision poll in
##                  `realm_chapter_events.gd`) finishes the aggregates then.
##   * `offline` -- there is no transport at all (a bare fixture, a capture
##                  tool, an early boot frame). The old local write still
##                  happens, for the same reason lane 5.A kept it: a chapter
##                  that emits events and changes nothing is worse than one
##                  written locally in a process that has nobody to tell.
##   * anything else -- a real refusal. Nothing is written.
static func _set_flag(progression: RefCounted, flag: String, result: Dictionary,
		writer: Callable = Callable()) -> bool:
	if flag.is_empty() or bool(progression.call("has", flag)):
		return false
	if writer.is_valid():
		var verdict: Dictionary = writer.call(flag)
		if bool(verdict.get("ok", false)):
			result["changed"] = true
			return true
		if bool(verdict.get("pending", false)):
			result["pending"] = true
			return false
		if str(verdict.get("code", "")) != "offline":
			return false
	progression.call("set_flag", flag)
	result["changed"] = true
	return true


static func _merge(into: Dictionary, other: Dictionary) -> void:
	into["changed"] = bool(into["changed"]) or bool(other["changed"])
	into["pending"] = bool(into.get("pending", false)) or bool(other.get("pending", false))
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
