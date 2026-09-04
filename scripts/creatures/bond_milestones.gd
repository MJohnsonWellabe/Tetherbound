extends RefCounted

## OWNER-0901-BOND-MILESTONES: bond as a ladder of concrete tasks, replacing
## the old continuous 0-100 meter/threshold table. Owner playtest 2026-09-01:
## "I don't understand bond. It just goes up. It needs to be a task."
##
## A creature's bond TIER (0-5 for the shipped ladder) is how many milestones
## it has completed -- the exact same "how many nodes crossed" shape
## `progression.gd`'s `bond_stat_scale`/`trait_unlocked` already read, so
## neither of those changed: this file only decides how a node is EARNED,
## not what it buys (that stays in progression.json's own `bond` block).
##
## D74 (PROGRESSION-VISIBLE, 2026-09-04): the ladder is UNORDERED. D70 shipped
## it ordered -- tier N only once the first N tasks were done in sequence --
## and under that rule a creature fed ten meals before its fiftieth battle
## showed no bond progress at all from those meals. The owner's directive of
## the same day asks the player to see WHICH actions strengthen the bond, so a
## node is now earned when ANY task completes, and the "next" task the UI
## points at is whichever incomplete one is closest to done. Same five tasks,
## same targets, same 0-5 tier count; only `tier()` and `current()` changed.
##
## PROGRESSION-VISIBLE also makes this file the single source of the three
## bond event kinds on the progression feed (`bond_credit`, `bond_near`,
## `bond_milestone`): every crediting helper routes through `credit()`, which
## pushes them, so no call site can advance a counter silently.
##
## Deliberately its own small config (data/config/bond_milestones.json)
## rather than folded into progression.json, so the earn-ladder and the
## stat effects can be tuned independently, same split `creature_condition.gd`
## draws from `progression.gd`.

const CONFIG_PATH := "res://data/config/bond_milestones.json"
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

static var _config: Dictionary = {}


## The shipped bond_milestones.json, cached after the first read.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("bond_milestones.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


static func milestones(cfg: Dictionary) -> Array:
	var list: Variant = cfg.get("milestones", [])
	return list as Array if typeof(list) == TYPE_ARRAY else []


static func _valid(entry: Variant) -> bool:
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	var m := entry as Dictionary
	return not str(m.get("task", "")).is_empty() and float(m.get("target", 0)) > 0.0


static func _counter(creature: RefCounted, task: String) -> float:
	if creature == null or task.is_empty():
		return 0.0
	var value: Variant = creature.get(task)
	return float(value) if typeof(value) != TYPE_NIL else 0.0


static func _done(creature: RefCounted, m: Dictionary) -> bool:
	return _counter(creature, str(m.get("task", ""))) >= float(m.get("target", 0))


## How many milestones `creature` has completed, in ANY order (D74).
static func tier(creature: RefCounted, cfg: Dictionary) -> int:
	if creature == null:
		return 0
	var reached := 0
	for entry: Variant in milestones(cfg):
		if _valid(entry) and _done(creature, entry as Dictionary):
			reached += 1
	return reached


## The milestone `creature` is closest to finishing -- the incomplete task
## with the highest completion fraction, list order breaking ties -- or {}
## once every milestone is complete. This is the "next" the Team screen
## marks and the sentence the bond meter prints.
static func current(creature: RefCounted, cfg: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_fraction := -1.0
	for entry: Variant in milestones(cfg):
		if not _valid(entry):
			continue
		var m := entry as Dictionary
		if _done(creature, m):
			continue
		var fraction := _counter(creature, str(m.get("task", ""))) / float(m.get("target", 1))
		if fraction > best_fraction:
			best_fraction = fraction
			best = m
	return best.duplicate()


## "38/50 wild creatures defeated together", or a completion line once every
## milestone is done. The one place this sentence is built, so the Team
## screen, the bond widget and the release ceremony can never disagree about
## its wording.
static func progress_text(creature: RefCounted, cfg: Dictionary) -> String:
	var m := current(creature, cfg)
	if m.is_empty():
		return "Fully bonded"
	var task := str(m.get("task", ""))
	var target := int(m.get("target", 0))
	var have := mini(int(round(_counter(creature, task))), target) if not task.is_empty() else 0
	return "%d/%d %s" % [have, target, str(m.get("name", "bond"))]


## Every task against its target, for the Team screen (prompt 73 §2.3):
## `{task, name, have, target, done, next, remaining, fraction}` in ladder
## order. Exactly one incomplete row carries `next = true` (the one
## `current()` names); every complete row carries `done = true`.
static func task_rows(creature: RefCounted, cfg: Dictionary) -> Array:
	var next_task := str(current(creature, cfg).get("task", ""))
	var rows: Array = []
	for entry: Variant in milestones(cfg):
		if not _valid(entry):
			continue
		var m := entry as Dictionary
		var task := str(m.get("task", ""))
		var target := float(m.get("target", 0))
		var have := _counter(creature, task)
		var done := have >= target
		rows.append({
			"task": task,
			"name": str(m.get("name", "")),
			"have": mini(int(round(have)), int(target)),
			"target": int(target),
			"done": done,
			"next": task == next_task,
			"remaining": 0 if done else int(ceil(target - have)),
			"fraction": clampf(have / target, 0.0, 1.0) if target > 0.0 else 0.0,
		})
	return rows


## "2 more nights", "7 more meals", "140 m more" -- what is left on one task
## row, in the unit the row's own name implies. "" for a done row.
static func remaining_text(row: Dictionary) -> String:
	if bool(row.get("done", false)):
		return ""
	var remaining := int(row.get("remaining", 0))
	match str(row.get("task", "")):
		"battles_fought":
			return "%d more win%s" % [remaining, "" if remaining == 1 else "s"]
		"landmarks_visited_together":
			return "%d more landmark%s" % [remaining, "" if remaining == 1 else "s"]
		"distance_m_together":
			return "%d m more" % remaining
		"rest_nights_together":
			return "%d more night%s" % [remaining, "" if remaining == 1 else "s"]
		"feeds_together":
			return "%d more meal%s" % [remaining, "" if remaining == 1 else "s"]
		_:
			return "%d more" % remaining


## Whether the creature is within `near` of finishing ANY incomplete task
## (progression_feedback.json's per-task thresholds) -- the party strip's
## slow pulse and the Team screen's "N more" emphasis read this.
static func is_near(creature: RefCounted, cfg: Dictionary, feedback_cfg: Dictionary = {}) -> bool:
	for row: Variant in task_rows(creature, cfg):
		var r := row as Dictionary
		if bool(r.get("done", false)):
			continue
		var threshold := FEED.near_threshold(str(r.get("task", "")), feedback_cfg)
		if threshold > 0.0 and float(r.get("remaining", 0)) <= threshold:
			return true
	return false


## What node number `node` (1-based) buys, as one line: the per-node stat
## line always, plus "reveals second trait" at the trait unlock and "unlocks
## evolution" at the creature's own evolution tier. `progression_cfg` is
## progression.json's shape (bond.effects_per_node, traits, evolution).
static func benefit_text(node: int, creature: RefCounted, progression_cfg: Dictionary) -> String:
	var per_node: float = float(progression_cfg.get("bond", {}).get("effects_per_node", {}).get("attack_scale", 0.0))
	var parts: Array[String] = []
	parts.append("+%d%% attack and defence (now +%d%%)" % [
		int(round(per_node * 100.0)), int(round(per_node * 100.0 * float(node)))
	])
	if node == int(progression_cfg.get("traits", {}).get("unlock_bond_nodes", 5)):
		parts.append("reveals second trait")
	if creature != null:
		var req: Dictionary = progression_cfg.get("evolution", {}).get(str(creature.get("species_id")), {})
		if not req.is_empty() and int(req.get("bond_tier", 0)) == node:
			parts.append("unlocks evolution")
	return "  ·  ".join(parts)


## The benefit line for the NEXT node the creature would earn, or "" once
## every node is held.
static func next_benefit_text(creature: RefCounted, cfg: Dictionary, progression_cfg: Dictionary) -> String:
	var total := milestones(cfg).size()
	var nodes := tier(creature, cfg)
	if nodes >= total:
		return ""
	return benefit_text(nodes + 1, creature, progression_cfg)


# --- crediting: every task, one path -----------------------------------------
##
## `credit()` is the only thing that writes a bond counter in gameplay. It
## records the counter, then pushes to the progression feed: `bond_credit`
## for the tick (distance only once per `distance_tick_m`), `bond_near` when
## the task is within its near threshold, and `bond_milestone` when the tier
## rose. Returns what happened -- `{task, before, after, target, remaining,
## tier_before, tier_after, ticked, near, milestone}` -- so a test or a
## caller can read the outcome without re-deriving it from the feed.

static func credit(creature: RefCounted, task: String, amount: float, cfg: Dictionary = {}) -> Dictionary:
	if creature == null or task.is_empty() or amount <= 0.0:
		return {}
	var ladder := cfg if cfg.has("milestones") else config()
	var entry := _entry_for(task, ladder)
	var target := float(entry.get("target", 0))
	var task_name := str(entry.get("name", task))
	var before := _counter(creature, task)
	var tier_before := tier(creature, ladder)
	var after := before + amount
	var stored: Variant = creature.get(task)
	creature.set(task, int(round(after)) if typeof(stored) == TYPE_INT else after)
	var tier_after := tier(creature, ladder)

	var feedback := FEED.config()
	var ticked := true
	if task == "distance_m_together":
		var step := maxf(float(feedback.get("distance_tick_m", 250)), 1.0)
		ticked = floori(before / step) != floori(after / step)
	var remaining := maxf(0.0, target - after)
	var remaining_before := maxf(0.0, target - before)
	var threshold := FEED.near_threshold(task, feedback)
	var near := target > 0.0 and remaining > 0.0 and threshold > 0.0 and remaining <= threshold
	if task == "distance_m_together" and near:
		# Distance is fractional and continuous: say "near" on the frame the
		# band is entered and then once per tick inside it, not every poll.
		near = remaining_before > threshold or ticked
	var milestone := tier_after > tier_before

	if ticked:
		FEED.push("bond_credit", creature, {
			"task": task, "task_name": task_name,
			"before": before, "after": after, "target": target,
			"remaining": remaining, "tier": tier_after,
		})
	if near:
		FEED.push("bond_near", creature, {
			"task": task, "task_name": task_name,
			"remaining": remaining, "target": target,
		})
	if milestone:
		FEED.push("bond_milestone", creature, {
			"node": tier_after, "task": task, "task_name": task_name,
			"benefit": benefit_text(tier_after, creature, PROGRESSION.config()),
			"tier": tier_after, "total": milestones(ladder).size(),
		})
	return {
		"task": task, "before": before, "after": after, "target": target,
		"remaining": remaining, "tier_before": tier_before, "tier_after": tier_after,
		"ticked": ticked, "near": near, "milestone": milestone,
	}


static func _entry_for(task: String, cfg: Dictionary) -> Dictionary:
	for entry: Variant in milestones(cfg):
		if _valid(entry) and str((entry as Dictionary).get("task", "")) == task:
			return entry as Dictionary
	return {}


## Milestone 1's task. Credited by `combat_manager.gd`'s victory loop (via
## `creature_instance.credit_battle_fought()`) for every non-fainted member
## that fought -- the manager's own "it did not fight" rule decides who.
static func credit_battle(creature: RefCounted) -> void:
	credit(creature, "battles_fought", 1.0)


static func credit_landmark_visit(creature: RefCounted) -> void:
	credit(creature, "landmarks_visited_together", 1.0)


static func credit_distance(creature: RefCounted, meters: float) -> void:
	if meters <= 0.0:
		return
	credit(creature, "distance_m_together", meters)


static func credit_rest_night(creature: RefCounted) -> void:
	credit(creature, "rest_nights_together", 1.0)


static func credit_feed(creature: RefCounted) -> void:
	credit(creature, "feeds_together", 1.0)
