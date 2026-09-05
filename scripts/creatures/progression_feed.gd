extends RefCounted

## PROGRESSION-VISIBLE (docs/prompts/73, D76): the one progression feed.
##
## Every progression change -- XP, a level, a bond credit, a bond milestone --
## is pushed here by its single source of truth, and every presenter (the
## party strip, the world HUD's moment banner, the combat HUD's XP line, the
## Team screen) reads it back. Not a signal: `project.godot` declares one
## autoload and zero signals, and cross-system change in this repo is
## revision-counter polling. This is that shape: a bounded, sequence-numbered
## log with a revision counter, exactly what `Game.push_world_message()` /
## `take_pending_world_message()` already do for a one-line toast.
##
## Static rather than a node on purpose. The producers are `RefCounted`
## instances (`creature_instance.gd::gain_xp`) with no scene tree to reach
## `Game` through, and the unit suite runs without the autoload at all;
## `autoload/game_state.gd` exposes the same queue beside `push_world_message`
## for anything that already talks to `Game`.
##
## Presenters keep their own cursor (the `seq` of the last event they acted
## on) and call `peek_since()`; nothing in production drains, so four readers
## can watch one log. `drain()` exists for the new-game reset and for tests.
##
## Event kinds and payloads (prompt 73 §2.1):
##   xp_gained      amount, xp, xp_to_next, level
##   level_up       old_level, new_level, levels_gained, hp_delta, attack_delta,
##                  defence_delta, trait_unlocked, evolution_ready,
##                  evolution_level_reached, source
##   bond_credit    task, task_name, before, after, target, remaining, tier
##   bond_near      task, task_name, remaining, target
##   bond_milestone node, task, task_name, benefit, tier, total
## Every event also carries `kind`, `seq`, `creature_id` (the instance id),
## `name` (the creature's label) and `species_id`.

const CONFIG_PATH := "res://data/config/progression_feedback.json"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

static var _config: Dictionary = {}
static var _events: Array = []
static var _seq: int = 0
static var _revision: int = 0


## data/config/progression_feedback.json, cached after the first read.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("progression_feedback.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


static func near_threshold(task: String, cfg: Dictionary = {}) -> float:
	var near: Dictionary = (cfg if not cfg.is_empty() else config()).get("near", {})
	return float(near.get(task, 0))


static func seconds(key: String, fallback: float, cfg: Dictionary = {}) -> float:
	return float((cfg if not cfg.is_empty() else config()).get(key, fallback))


# --- the log -----------------------------------------------------------------

## Append one event. Returns the stored event (with its `seq`), so a caller
## that wants to react to its own push -- a test, mostly -- has the record.
static func push(kind: String, creature: RefCounted, payload: Dictionary = {}) -> Dictionary:
	_seq += 1
	var event := payload.duplicate()
	event["kind"] = kind
	event["seq"] = _seq
	event["creature_id"] = creature.get_instance_id() if creature != null else 0
	event["name"] = str(creature.call("label")) if creature != null and creature.has_method("label") else ""
	event["species_id"] = str(creature.get("species_id")) if creature != null else ""
	_events.append(event)
	var cap := int(config().get("max_events", 64))
	while _events.size() > maxi(cap, 1):
		_events.pop_front()
	_revision += 1
	return event


## Bumps on every push and every drain -- the cheap integer a presenter
## compares each frame before doing any work.
static func revision() -> int:
	return _revision


## The `seq` of the newest event, 0 when nothing has ever been pushed. A
## presenter that mounts late seeds its cursor from this so it does not replay
## history it never saw happen.
static func latest_seq() -> int:
	return _seq


## Every event with `seq` strictly greater than `after`, oldest first.
static func peek_since(after: int) -> Array:
	var out: Array = []
	for event: Variant in _events:
		if int((event as Dictionary).get("seq", 0)) > after:
			out.append(event)
	return out


## A copy of everything currently held, oldest first.
static func events() -> Array:
	return _events.duplicate()


## Take everything and empty the log. Bumps the revision so a presenter
## comparing revisions sees the drain as a change too.
static func drain() -> Array:
	var out := _events.duplicate()
	_events.clear()
	_revision += 1
	return out


## The new-game reset: nothing held, sequence and revision back to zero.
static func clear() -> void:
	_events.clear()
	_seq = 0
	_revision = 0


# --- derived state presenters ask about ---------------------------------------

## XP the creature still needs for its next level.
static func xp_remaining(creature: RefCounted, progression_cfg: Dictionary) -> int:
	if creature == null:
		return 0
	return maxi(0, int(creature.call("xp_to_next", progression_cfg)) - int(creature.get("xp")))


## "Within one ordinary fight of a level" (prompt 73 §2.2's Near level for
## XP): the XP still needed is at most `near.xp_fights` level-matched wild
## wins' worth. A creature at the level cap is never near.
static func xp_near(creature: RefCounted, progression_cfg: Dictionary, cfg: Dictionary = {}) -> bool:
	if creature == null:
		return false
	var cap := int(progression_cfg.get("level", {}).get("cap", 50))
	if int(creature.get("level")) >= cap:
		return false
	var fights := float((cfg if not cfg.is_empty() else config()).get("near", {}).get("xp_fights", 1.0))
	var one_fight := float(PROGRESSION.xp_award_for(int(creature.get("level")), progression_cfg))
	return float(xp_remaining(creature, progression_cfg)) <= one_fight * fights


## 0..1 fill of the creature's XP bar toward its next level.
static func xp_fraction(creature: RefCounted, progression_cfg: Dictionary) -> float:
	if creature == null:
		return 0.0
	var needed := int(creature.call("xp_to_next", progression_cfg))
	if needed <= 0:
		return 1.0
	return clampf(float(creature.get("xp")) / float(needed), 0.0, 1.0)


# --- the sentences, built once -------------------------------------------------
##
## Every surface that says something about an event says it through one of
## these, so the strip, the banner and the combat HUD can never disagree
## about wording (the same rule `bond_milestones.gd::progress_text` set).

## The one-word verb a bond tick shows ("+bond · fed"), from
## progression_feedback.json's `tick_verbs`.
static func tick_verb(task: String) -> String:
	var verbs: Dictionary = config().get("tick_verbs", {})
	return str(verbs.get(task, "together"))


## The short label the party strip flicks for a Tick-level event, or "" for
## an event kind that is not a tick.
static func tick_label(event: Dictionary) -> String:
	match str(event.get("kind", "")):
		"xp_gained":
			return "+%d XP" % int(event.get("amount", 0))
		"bond_credit":
			return "+bond · %s" % tick_verb(str(event.get("task", "")))
		_:
			return ""


## What a level changed, as short fragments: "+4 HP", "+1 ATK", "+1 DEF",
## then "second trait revealed" / "evolution ready" / "evolution level reached"
## when the event says so.
static func level_up_changes(event: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var hp := int(round(float(event.get("hp_delta", 0.0))))
	var atk := int(round(float(event.get("attack_delta", 0.0))))
	var def := int(round(float(event.get("defence_delta", 0.0))))
	if hp != 0:
		out.append("%+d HP" % hp)
	if atk != 0:
		out.append("%+d ATK" % atk)
	if def != 0:
		out.append("%+d DEF" % def)
	if bool(event.get("trait_unlocked", false)):
		out.append("second trait revealed")
	if bool(event.get("evolution_ready", false)):
		out.append("evolution ready")
	elif bool(event.get("evolution_level_reached", false)):
		out.append("evolution level reached")
	return out


## The Moment banner's two lines for a `level_up` or `bond_milestone` event:
## `{title, detail}`. Anything else returns empty strings.
static func moment_text(event: Dictionary) -> Dictionary:
	var name := str(event.get("name", ""))
	match str(event.get("kind", "")):
		"level_up":
			var gained := int(event.get("levels_gained", 1))
			var title := "%s reached Lv %d" % [name, int(event.get("new_level", 0))]
			if gained > 1:
				title += "  (+%d levels)" % gained
			return {"title": title, "detail": "  ·  ".join(level_up_changes(event))}
		"bond_milestone":
			var title := "%s  ·  bond %d / %d" % [name, int(event.get("node", 0)), int(event.get("total", 5))]
			var detail := "%s  ·  %s" % [str(event.get("task_name", "")), str(event.get("benefit", ""))]
			return {"title": title, "detail": detail}
		_:
			return {"title": "", "detail": ""}


static func is_moment(event: Dictionary) -> bool:
	var kind := str(event.get("kind", ""))
	return kind == "level_up" or kind == "bond_milestone"


static func is_tick(event: Dictionary) -> bool:
	var kind := str(event.get("kind", ""))
	return kind == "xp_gained" or kind == "bond_credit"
