extends RefCounted

## OWNER-0901-BOND-MILESTONES: bond as an ordered ladder of concrete tasks,
## replacing the old continuous 0-100 meter/threshold table. Owner playtest
## 2026-09-01: "I don't understand bond. It just goes up. It needs to be a
## task."
##
## A creature's bond TIER (0-5 for the shipped ladder) is how many milestones
## it has completed, IN ORDER -- the exact same "how many nodes crossed"
## shape `progression.gd`'s `bond_stat_scale`/`trait_unlocked` already read,
## so neither of those changed: this file only decides how a node is EARNED,
## not what it buys (that stays in progression.json's own `bond` block).
##
## Deliberately its own small config (data/config/bond_milestones.json)
## rather than folded into progression.json, so the earn-ladder and the
## stat effects can be tuned independently, same split `creature_condition.gd`
## draws from `progression.gd`.

const CONFIG_PATH := "res://data/config/bond_milestones.json"
const FEEDBACK := preload("res://scripts/creatures/progression_feed.gd")
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


## How many milestones `creature` has completed, in order. Sequential rather
## than five independent counters: a creature is always working toward
## exactly ONE named task, the same "0 to 1, then to 2" shape the owner
## described -- so this stops counting at the first task whose target has not
## been met, even if a later task's counter happens to already qualify.
static func tier(creature: RefCounted, cfg: Dictionary) -> int:
	if creature == null:
		return 0
	var reached := 0
	for entry: Variant in milestones(cfg):
		if typeof(entry) != TYPE_DICTIONARY:
			break
		var m := entry as Dictionary
		var target := float(m.get("target", 0))
		var task := str(m.get("task", ""))
		if task.is_empty() or target <= 0.0:
			break
		if float(creature.get(task)) < target:
			break
		reached += 1
	return reached


## The milestone `creature` is currently working toward, or {} once every
## milestone is complete.
static func current(creature: RefCounted, cfg: Dictionary) -> Dictionary:
	var list := milestones(cfg)
	var index := tier(creature, cfg)
	if index < 0 or index >= list.size() or typeof(list[index]) != TYPE_DICTIONARY:
		return {}
	return (list[index] as Dictionary).duplicate()


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
	var have := mini(int(round(float(creature.get(task)))), target) if not task.is_empty() else 0
	return "%d/%d %s" % [have, target, str(m.get("name", "bond"))]


# --- crediting: the four tasks with no pre-existing counter to reuse --------
##
## `battles_fought` (milestone 1) already exists and is credited by
## combat_manager.gd's own victory loop -- see bond_milestones.json's own
## comment for why. These four are new; kept here rather than scattered
## across every call site so the field names live in exactly one place.

static func credit_landmark_visit(creature: RefCounted) -> void:
	if creature == null:
		return
	credit(creature, "landmarks_visited_together", 1)


static func credit_distance(creature: RefCounted, meters: float, source: String = "") -> void:
	if creature == null or meters <= 0.0:
		return
	credit(creature, "distance_m_together", meters, source)


static func credit_rest_night(creature: RefCounted) -> void:
	if creature == null:
		return
	credit(creature, "rest_nights_together", 1)


static func credit_feed(creature: RefCounted) -> void:
	if creature == null:
		return
	credit(creature, "feeds_together", 1)


static func credit_battle(creature: RefCounted) -> void:
	credit(creature, "battles_fought", 1)


static func credit(creature: RefCounted, task: String, amount: float, source: String = "") -> void:
	if creature == null or amount <= 0:
		return
	var before := float(creature.get(task))
	var previous_tier := tier(creature, config())
	var after := before + amount
	creature.set(task, after if task == "distance_m_together" else int(after))
	for milestone: Dictionary in milestones(config()):
		if str(milestone.task) != task:
			continue
		var target := float(milestone.target)
		FEEDBACK.publish(creature, {"kind": "bond_credit", "task_id": task, "before": before,
			"after": after, "target": target, "source": source})
		var threshold := float(FEEDBACK.config().near_thresholds.get(task, 0))
		if before < target - threshold and after >= target - threshold and after < target:
			FEEDBACK.publish(creature, {"kind": "bond_near", "task_id": task, "remaining": target - after})
	var next_tier := tier(creature, config())
	for node_index in range(previous_tier + 1, next_tier + 1):
		var task_id := str(milestones(config())[node_index - 1].task)
		FEEDBACK.publish(creature, {"kind": "bond_milestone", "node_index": node_index,
			"task_id": task_id, "benefit": benefit_for(node_index, creature),
			"trait_unlocked": node_index == int(PROGRESSION.config().get("traits", {}).get("unlock_bond_nodes", 5)),
			"evolution_ready": FEEDBACK.evolution_ready(creature)})


static func benefit_for(node_index: int, creature: RefCounted = null) -> String:
	var cfg := PROGRESSION.config()
	var benefit := "+%d%% attack and defence" % int(round(float(cfg.get("bond", {}).get("effects_per_node", {}).get("attack_scale", 0.01)) * 100))
	if node_index == int(cfg.get("traits", {}).get("unlock_bond_nodes", 5)):
		benefit += " · second trait revealed"
	var evolution: Dictionary = cfg.get("evolution", {}).get(str(creature.get("species_id")), {}) if creature != null else {}
	if not evolution.is_empty() and node_index == int(evolution.get("bond_tier", -1)):
		benefit += " · evolution bond requirement met"
	return benefit


static func all_progress_text(creature: RefCounted) -> String:
	var lines: PackedStringArray = []
	var reached := tier(creature, config())
	var index := 0
	for milestone: Dictionary in milestones(config()):
		var have := minf(float(creature.get(str(milestone.task))), float(milestone.target))
		var state := "done" if index < reached else ("next" if index == reached else ("ready; earlier task first" if have >= float(milestone.target) else "counts now; later node"))
		lines.append("%d/%d %s · %s" % [int(have), int(milestone.target), milestone.name, state])
		index += 1
	if reached < milestones(config()).size():
		lines.append("Next action: " + next_action_text(creature))
		lines.append("Next benefit: " + benefit_for(reached + 1, creature))
	return "\n".join(lines)


static func next_action_text(creature: RefCounted) -> String:
	var milestone := current(creature, config())
	if milestone.is_empty():
		return "All five bond tasks complete"
	var remaining := maxi(0, ceili(float(milestone.target) - float(creature.get(str(milestone.task)))))
	var actions := {"battles_fought": "Win %d more battles together", "landmarks_visited_together": "Discover %d more landmarks together",
		"distance_m_together": "Travel %d more metres together", "rest_nights_together": "Complete %d more nights in a creature bed", "feeds_together": "Share %d more meals"}
	return str(actions.get(milestone.task, "%d more shared actions")) % remaining
