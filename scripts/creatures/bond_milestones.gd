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
	creature.set("landmarks_visited_together", int(creature.get("landmarks_visited_together")) + 1)


static func credit_distance(creature: RefCounted, meters: float) -> void:
	if creature == null or meters <= 0.0:
		return
	creature.set("distance_m_together", float(creature.get("distance_m_together")) + meters)


static func credit_rest_night(creature: RefCounted) -> void:
	if creature == null:
		return
	creature.set("rest_nights_together", int(creature.get("rest_nights_together")) + 1)


static func credit_feed(creature: RefCounted) -> void:
	if creature == null:
		return
	creature.set("feeds_together", int(creature.get("feeds_together")) + 1)
