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
## THE LOG IS PER PLAYER (Wave 1 lane 1.B, `MP_STATE_SEAM.md` §2). It used to
## be five `static var`s -- one log for the whole process -- which is fine while
## there is one player and wrong the moment there are two: peer A's XP banner
## would read peer B's level-ups. The four log fields are now instance state on
## `PlayerState.feed`.
##
## The static ENTRY POINTS below stay, and that is deliberate rather than a
## half-finished refactor. The producers are `RefCounted` instances
## (`creature_instance.gd::gain_xp`, `bond_milestones.gd`) with no scene tree to
## reach `Game` through, and the unit suite runs with no autoload and no
## SceneTree at all (`Engine.get_main_loop()` is null for the life of
## `run_tests.gd`). Each static resolves `active()` -- the local player's feed
## when there is a `Game`, a process-local fallback instance when there is not --
## and calls the instance method. Anything that already holds a specific feed
## (`Game.push_progression_event`, and from Wave 3 a host writing a peer's)
## calls the instance methods directly and never goes through `active()`.
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
##   reward_summary receipt (a team-wide victory receipt)
##   evolution_eligible target (the species this creature is about to become)
##   catalyst_found     item_id, text (a discoverability note, creature-less)
## Every event also carries `kind`, `seq`, `creature_id` (the instance id),
## `name` (the creature's label) and `species_id`.
##
## OP-0905-18 (docs/owner/OWNER_PLAYTEST_2026-09-05.md): "When and how does
## the pig evolve?" -- the rule (evolution.gd) was always real, but nothing
## ever told the player it existed. `evolution_eligible` and `catalyst_found`
## exist ONLY to fix that discoverability gap; neither changes eligibility --
## `evolution.gd::check()`/`evolve()` remain the one source of truth for
## whether a creature actually can evolve. `evolution_eligible` fires once
## per creature, the moment `check()` first reports `eligible: true` --
## checked here, in the one place `level_up` and `bond_credit` already both
## pass through, rather than as a new hook in combat_manager.gd or
## bond_milestones.gd (a level crossing the gate and a bond tier crossing it
## are the two ways eligibility changes; both already call `push()`).
## `catalyst_found` fires once, the moment a pickup script hands a known
## evolution item to `announce_catalyst_pickup()` -- see that function.

const CONFIG_PATH := "res://data/config/progression_feedback.json"
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")

## Config, not state: one immutable read of a data file, identical for every
## player in the process. The seam's own exemption -- "the pure helpers may stay
## static; they read config only".
static var _config: Dictionary = {}

## The log itself, per instance. `PlayerState.feed` owns one.
var _events: Array = []
var _seq: int = 0
var _revision: int = 0
var _epoch: int = 0
## OP-0905-18. Per-player: two players must each get their own one-time
## discoverability announcement for a creature they own, so this lives beside
## the rest of the per-instance log rather than as a shared static.
var _evolution_announced: Dictionary = {}

## The local player's feed, HANDED OVER by `Game._ensure_containers()` rather
## than looked up. There is exactly one local player per process (the execution
## plan's §2 simplification), so this pointer is a complete answer rather than a
## transitional one -- and unlike the log it replaces, it is a pointer, not
## state: two players' events can never land in it.
##
## IT MUST NOT BE A LOOKUP. The first cut of this resolved the feed per call
## through `game()` (`Engine.get_main_loop().root.get_node_or_null("Game")`),
## and that was wrong twice over. `Engine.get_main_loop()` is null for whole
## stretches of a headless run -- `test_characterize_game_process_ticks.gd`
## asserts exactly that for the life of `run_tests.gd` -- so the SAME static
## call could answer with `Game.local.feed` on one frame and the fallback on the
## next. A presenter that seeded `_feed_epoch` from one and then polled the other
## saw the epochs disagree, reset its cursor and its tick counters, and dropped
## the events it was mounted to show: `smoke_progression_feedback` failed with
## "the party strip ticked 0 time(s) for the win". It was also a tree walk on a
## path three presenters poll every frame.
static var _active: RefCounted = null

## What the statics act on when nothing has handed over a feed -- the unit
## suite (no autoload, no SceneTree), a tool script, a `RefCounted` producer
## running before `Game` exists. Built on first use.
static var _fallback: RefCounted = null


## `Game._ensure_containers()` calls this with `local.feed`, once, before any
## world scene exists. Wave 2 calls it again if the local player is ever rebuilt.
static func set_active(feed: RefCounted) -> void:
	_active = feed


## Tests only: forget the handed-over feed and fall back again.
static func clear_active() -> void:
	_active = null


## The feed the static entry points below act on.
static func active() -> RefCounted:
	if _active != null:
		return _active
	if _fallback == null:
		_fallback = new()
	return _fallback


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
	return active().push_event(kind, creature, payload)


## The instance form. `Game.push_progression_event()` and `PlayerState` call
## this directly, because they already know WHICH feed they mean.
func push_event(kind: String, creature: RefCounted, payload: Dictionary = {}) -> Dictionary:
	if not enabled(creature):
		return {}
	_seq += 1
	var event := payload.duplicate(true)
	event["kind"] = kind
	event["seq"] = _seq
	event["creature_id"] = creature.get_instance_id() if creature != null else 0
	event["name"] = str(creature.call("label")) if creature != null and creature.has_method("label") else str(payload.get("name", ""))
	event["species_id"] = str(creature.get("species_id")) if creature != null else ""
	_events.append(event)
	var cap := int(config().get("max_events", 64))
	while _events.size() > maxi(cap, 1):
		_events.pop_front()
	_revision += 1
	var owner := game()
	if kind == "level_up" and owner != null:
		var party: RefCounted = owner.get("party")
		if party != null:
			party.set("revision", int(party.get("revision")) + 1)
	if (kind == "level_up" or kind == "bond_credit") and creature != null:
		var inventory: RefCounted = owner.get("inventory") if owner != null else null
		eligibility_event(creature, PROGRESSION.config(), inventory)
	return event.duplicate(true)


## Gameplay feedback belongs to the owned five. Standalone logic tests have
## no Game node; construction and set_level stay silent in either context.
static func game() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Game") if tree != null and tree.root != null else null


static func enabled(creature: RefCounted) -> bool:
	if creature == null:
		return true  # A team reward receipt has no individual creature.
	var owner := game()
	if owner == null:
		return true
	var party: RefCounted = owner.get("party")
	return party != null and (party.call("members") as Array).has(creature)


## Bumps on every push and every drain -- the cheap integer a presenter
## compares each frame before doing any work.
static func revision() -> int:
	return active().event_revision()


func event_revision() -> int:
	return _revision


## The `seq` of the newest event, 0 when nothing has ever been pushed. A
## presenter that mounts late seeds its cursor from this so it does not replay
## history it never saw happen.
static func latest_seq() -> int:
	return active().newest_seq()


func newest_seq() -> int:
	return _seq


## A reset/load can reuse a sequence number. Readers compare this first and
## discard pending presentations from the previous run before reading again.
static func epoch() -> int:
	return active().feed_epoch()


func feed_epoch() -> int:
	return _epoch


## Every event with `seq` strictly greater than `after`, oldest first.
static func peek_since(after: int) -> Array:
	return active().events_since(after)


func events_since(after: int) -> Array:
	var out: Array = []
	for event: Variant in _events:
		if int((event as Dictionary).get("seq", 0)) > after:
			out.append((event as Dictionary).duplicate(true))
	return out


## A copy of everything currently held, oldest first.
static func events() -> Array:
	return active().all_events()


func all_events() -> Array:
	return _events.duplicate(true)


# --- OP-0905-18: evolution discoverability -----------------------------------

## `evolution.gd::check()` for `creature`, and -- the FIRST time it comes back
## eligible -- one `evolution_eligible` push. A no-op (returns {}) for every
## later call on the same creature, so a creature that stays eligible for
## hours of play (the player has not opened Team yet) is announced once, not
## every level or bond tick after. Public and independent of `push()`'s own
## `level_up`/`bond_credit` hook so a test (or a future caller with its own
## reason to re-check) can drive it directly without faking an XP award.
static func evolution_eligibility_event(
	creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null
) -> Dictionary:
	return active().eligibility_event(creature, cfg, inventory)


## The instance form -- see `push`/`push_event` above for why the static
## entry point stays. `_evolution_announced` is per-player (OP-0905-18): two
## players must each get their own one-time announcement for a creature they
## own, never a shared global that suppresses the second player's.
func eligibility_event(
	creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null
) -> Dictionary:
	if creature == null:
		return {}
	var id := creature.get_instance_id()
	if bool(_evolution_announced.get(id, false)):
		return {}
	var result: Dictionary = EVOLUTION.check(creature, cfg, inventory)
	if not bool(result.get("eligible", false)):
		return {}
	_evolution_announced[id] = true
	return push_event("evolution_eligible", creature, {"target": str(result.get("target", ""))})


## The discoverability line for picking up `item_id`, or "" when it is not an
## evolution catalyst any species' `progression.json` block or
## `evolves_into_variants` branch names -- most items, always, on the shipped
## roster's two exceptions (heartstone, sunstone). Reads the SAME
## `evolution.gd::requirements()` the Team screen and the ceremony use, so the
## level/bond numbers it quotes can never drift from the real gate.
static func catalyst_pickup_text(item_id: String, cfg: Dictionary = {}) -> String:
	if item_id == "":
		return ""
	var progression_cfg := cfg if not cfg.is_empty() else PROGRESSION.config()
	var evolution: Dictionary = progression_cfg.get("evolution", {})
	var template := str(config().get("catalyst_pickup_template", "%s: held against a creature that has grown enough (Lv %d, bond tier %d), it finishes what it was becoming. %s is one."))
	for species_id: String in evolution.keys():
		var req := EVOLUTION.requirements(species_id, progression_cfg)
		if req.is_empty():
			continue
		var matches := str(req.get("item_id", "")) == item_id
		if not matches:
			matches = (req.get("branches", {}) as Dictionary).has(item_id)
		if matches:
			return template % [
				item_id.capitalize(), int(req.get("level", 0)), int(req.get("bond_tier", 0)),
				species_id.capitalize(),
			]
	return ""


## Call from a pickup script's success path, right after the item lands in
## the satchel (the same moment `key_pickup.gd`/`item_cache_pickup.gd`
## already have the inventory in hand). Pushes the discoverability note once
## for a real catalyst, then re-checks every owned creature's eligibility --
## the item just picked up may be the one thing a Lv 15, bond-tier-3 creature
## was still missing, and that creature should not have to wait for its next
## level or bond tick to be told.
static func announce_catalyst_pickup(item_id: String) -> void:
	var cfg := PROGRESSION.config()
	var text := catalyst_pickup_text(item_id, cfg)
	if text != "":
		push("catalyst_found", null, {"item_id": item_id, "text": text})
	var owner := game()
	if owner == null:
		return
	var party: RefCounted = owner.get("party")
	if party == null:
		return
	var inventory: RefCounted = owner.get("inventory")
	for member: Variant in (party.call("members") as Array):
		evolution_eligibility_event(member as RefCounted, cfg, inventory)


## Take everything and empty the log. Bumps the revision so a presenter
## comparing revisions sees the drain as a change too.
static func drain() -> Array:
	return active().drain_events()


func drain_events() -> Array:
	var out := _events.duplicate(true)
	_events.clear()
	_revision += 1
	return out


## The new-game reset: nothing held, sequence and revision back to zero.
static func clear() -> void:
	active().clear_events()


## The epoch is the one counter a reset does NOT zero -- it CLIMBS, so a
## presenter holding a cursor from the previous run sees the number change and
## discards what it was waiting on. `PlayerState.reset()` therefore clears the
## feed in place rather than building a new one, which would restart the epoch
## at 0 and read to a presenter as "nothing was reset".
func clear_events() -> void:
	_events.clear()
	_seq = 0
	_revision = 0
	_epoch += 1
	_evolution_announced.clear()


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


## The Moment banner's two lines for a level, bond milestone, or reward receipt:
## `{title, detail}`. Anything else returns empty strings.
static func moment_text(event: Dictionary) -> Dictionary:
	var name := str(event.get("name", ""))
	match str(event.get("kind", "")):
		"reward_summary":
			var receipt := str(event.get("receipt", ""))
			var marker := receipt.find("'s reward:")
			var title := receipt.left(marker) + " defeated" if marker > 0 else "Victory rewards"
			return {"title": title, "detail": receipt}
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
		"evolution_eligible":
			# OP-0905-18: the whole point is the player learns this WITHOUT
			# having read `evolution.gd` or the Team tab's fine print first --
			# name the exact verb (the Team tab's own "G  evolve" hint), not
			# a vaguer "check on your team".
			return {"title": "%s can evolve" % name, "detail": "Open Team, G evolve"}
		"catalyst_found":
			return {"title": "%s found" % str(event.get("item_id", "")).capitalize(), "detail": str(event.get("text", ""))}
		_:
			return {"title": "", "detail": ""}


static func is_moment(event: Dictionary) -> bool:
	var kind := str(event.get("kind", ""))
	return kind == "level_up" or kind == "bond_milestone" or kind == "reward_summary" \
		or kind == "evolution_eligible" or kind == "catalyst_found"


static func is_tick(event: Dictionary) -> bool:
	var kind := str(event.get("kind", ""))
	return kind == "xp_gained" or kind == "bond_credit"
