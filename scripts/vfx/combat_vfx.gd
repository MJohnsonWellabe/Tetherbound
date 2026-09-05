extends Node

## W09-VFX (CL-A2, funded by the owner 2026-09-04). The one door combat and
## progression go through to put an EVENT on screen: a hit spark and body
## flash on every landed blow, a KO puff on the blow that empties the bar, a
## sparkle when a catch seals, and a level-up flourish on the creature that
## levelled.
##
## Why it exists: every blind judge has said a Tetherbound fight looks like two
## models standing near each other, and Bar B ("the same kind of game as
## Palworld?") cannot reach yes on frames where the only difference between
## the frame before a hit and the frame of the hit is a shorter health bar.
## Part of the owner's "beating creatures is way too easy" is the same thing
## from the other side: winning produced no picture.
##
## Two halves, deliberately:
##
##   * STATIC hooks (`hit`, `catch_success`, `level_up`, `knockout`) that other
##     systems call with what they already know. combat_manager.gd calls `hit`
##     from `_flash_at()` -- the one function BOTH damage sites already funnel
##     through -- and `catch_success` from the seal branch of `_finish_catch()`.
##     The KO puff is not a third hook: the damage hook is handed the struck
##     body, and a body whose instance is `fainted` at that moment just took
##     the killing blow. That covers a wild fight ending AND a trainer's second
##     creature falling mid-battle, from one place.
##   * A WATCHER node (`ensure_watcher`, one per tree, installed lazily by the
##     first hook) that finds level-ups. Nothing announces a level today:
##     `creature_instance.gain_xp()` raises the number silently and the HUD
##     reads `last_xp_award` afterwards. Another lane is building the
##     progression feed (docs/prompts/73-PROGRESSION-VISIBLE, §2.1) and this
##     lane must not; until it lands the watcher polls `Game.party` -- the
##     membership re-read only when `party.revision` moves, then five integer
##     compares a tick. `on_progression_event()` is the seam the feed plugs
##     into: a `level_up` event fires the same flourish, and `min_gap` makes
##     a poll detection and a feed event for the same creature one picture.
##
## Everything visual is tunable in data/config/vfx.json; `enabled: false`
## there is the whole revert. The effects themselves live in vfx_burst.gd,
## body_glow.gd and level_up_flourish.gd, and every one of them follows the
## construction rules impact_flash.gd's header established (mesh-based,
## MIX-blended, physics-clocked) -- see those files for why GPUParticles3D
## was ruled out on this project long before this lane.

const CONFIG_PATH := "res://data/config/vfx.json"
const BURST := preload("res://scripts/vfx/vfx_burst.gd")
const GLOW := preload("res://scripts/vfx/body_glow.gd")
const FLOURISH := preload("res://scripts/vfx/level_up_flourish.gd")

const WATCHER_NAME := "CombatVfxWatcher"
const NAME_HIT_SPARK := "HitSpark"
const NAME_KO_PUFF := "KoPuff"
const NAME_CATCH_BURST := "CatchBurst"

static var _config: Dictionary = {}
## Tests and the perf probe switch the whole layer off and on without editing
## the config file: null defers to vfx.json, true/false wins over it.
static var _enabled_override: Variant = null
## The one watcher this process has installed (or asked to be installed): two
## hits landing in the same physics tick both reach `ensure_watcher` before the
## deferred `add_child` has run, and without this each would make its own.
static var _watcher: Node = null


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("vfx.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


static func enabled() -> bool:
	if _enabled_override != null:
		return bool(_enabled_override)
	return bool(config().get("enabled", true))


static func set_enabled_override(value: Variant) -> void:
	_enabled_override = value


static func _block(key: String) -> Dictionary:
	var block: Variant = config().get(key, {})
	return block if block is Dictionary else {}


static func _block_enabled(key: String) -> bool:
	return enabled() and bool(_block(key).get("enabled", true))


## The elemental hue for a move `type` (moves.json's `type` field), or null
## for a type the map does not name so a caller's own fallback applies.
static func tint_for_type(type: String) -> Variant:
	if type.is_empty():
		return null
	var colours: Variant = config().get("type_colours", {})
	if colours is Dictionary and (colours as Dictionary).has(type):
		return Color(str((colours as Dictionary)[type]))
	return null


static func default_colour() -> Color:
	return Color(str(config().get("default_colour", "#ffd27a")))


## How much bigger a heavy blow bursts than a light one: `fraction` is
## damage / the struck creature's max HP.
static func damage_scale(fraction: float) -> float:
	var cfg: Dictionary = _block("damage_scale")
	var light: float = float(cfg.get("light_fraction", 0.04))
	var heavy: float = maxf(float(cfg.get("heavy_fraction", 0.30)), light + 0.001)
	var t: float = clampf((fraction - light) / (heavy - light), 0.0, 1.0)
	return lerpf(float(cfg.get("min", 0.8)), float(cfg.get("max", 1.7)), t)


static func _body_radius(body: Node3D) -> float:
	if body != null and is_instance_valid(body) and body.has_method("body_radius"):
		return maxf(float(body.call("body_radius")), 0.15)
	return 0.5


static func _body_height(body: Node3D) -> float:
	if body != null and is_instance_valid(body) and body.has_method("body_height"):
		return maxf(float(body.call("body_height")), 0.3)
	return 1.0


## Size relative to the body: a 0.5 m-radius body is the unit, so the numbers
## in vfx.json are metres on a mid-sized creature and grow with a looming one.
static func _body_scale(body: Node3D, spec: Dictionary) -> float:
	var reference: float = 0.5
	return lerpf(1.0, _body_radius(body) / reference, clampf(float(spec.get("body_scale", 1.0)), 0.0, 1.0))


## A blow landed. `host` is the arena (or the world) to parent the burst
## under; `at` where it landed; `tint` the move's own colour or null;
## `charged` whether the expensive move did it; `struck` the body that took
## it (may be null in a fixture); `damage_fraction` damage over that body's
## max HP. Returns the spark node, or null when the layer is off.
static func hit(host: Node, at: Vector3, tint: Variant, charged: bool, struck: Node3D, damage_fraction: float) -> Node3D:
	if not enabled():
		return null
	ensure_watcher(host)
	var colour: Color = (tint as Color) if tint is Color else default_colour()
	# The move colours in moves.json are the HUD's swatches -- pale tan, pale
	# blue -- and a pale mote on sunlit grass was judged invisible (round 1:
	# "no hot colour anywhere"). Saturate the element for the spark; a
	# deliberately near-white type (air) stays near-white because there is
	# little saturation to multiply.
	var boost: float = float(config().get("tint_saturation", 1.0))
	if boost != 1.0:
		colour = Color.from_hsv(colour.h, clampf(colour.s * boost, 0.0, 1.0), colour.v, colour.a)
	var spark: Node3D = null
	var knocked_out: bool = _is_fainted(struck)

	if _block_enabled("hit_spark"):
		var spec: Dictionary = _block("hit_spark")
		var scale: float = damage_scale(damage_fraction) * _body_scale(struck, spec)
		if charged:
			scale *= float(spec.get("charged_scale", 1.35))
		spark = BURST.spawn(host, at, spec, colour, scale, int(Time.get_ticks_usec() & 0xffff))
		if spark != null:
			spark.name = NAME_HIT_SPARK

	if _block_enabled("hit_flash") and struck != null and is_instance_valid(struck):
		var spec: Dictionary = _block("hit_flash")
		var strength: float = float(spec.get("charged_strength" if charged else "strength", 0.85))
		GLOW.attach(struck, GLOW.Mode.FLASH, spec, strength)

	if knocked_out and struck != null and is_instance_valid(struck):
		var centre: Vector3 = struck.call("centre") if struck.has_method("centre") else at
		knockout(host, centre, struck)
	return spark


## The struck body's instance was emptied by the blow that just landed. Read
## through `get("instance")`, which is how the manager itself reaches it, so a
## stand-in body in a fixture answers the same way a wild_creature does.
static func _is_fainted(struck: Node3D) -> bool:
	if struck == null or not is_instance_valid(struck):
		return false
	var instance: Variant = struck.get("instance")
	if instance == null or not (instance is Object):
		return false
	var fainted: Variant = (instance as Object).get("fainted")
	return fainted is bool and bool(fainted)


## The KO puff: a soft cloud from the creature that just fainted.
static func knockout(host: Node, at: Vector3, body: Node3D) -> Node3D:
	if not _block_enabled("ko_puff"):
		return null
	var spec: Dictionary = _block("ko_puff")
	var puff: Node3D = BURST.spawn(host, at, spec, Color(str(spec.get("colour", "#e9e4d6"))),
		_body_scale(body, spec), 7)
	if puff != null:
		puff.name = NAME_KO_PUFF
	return puff


## The seal: sparkle from the orb a creature was just caught in.
static func catch_success(host: Node, at: Vector3) -> Node3D:
	if not _block_enabled("catch_burst"):
		return null
	ensure_watcher(host)
	var spec: Dictionary = _block("catch_burst")
	var burst: Node3D = BURST.spawn(host, at, spec, Color(str(spec.get("colour", "#ffe08a"))), 1.0, 11)
	if burst != null:
		burst.name = NAME_CATCH_BURST
	return burst


## The level-up flourish on `body`, the creature that levelled. `levels` is
## how many at once; a multi-level jump plays one flourish, a little longer.
static func level_up(body: Node3D, levels: int = 1) -> Node3D:
	if not _block_enabled("level_up") or body == null or not is_instance_valid(body):
		return null
	var spec: Dictionary = _block("level_up").duplicate()
	if levels > 1:
		spec["duration"] = float(spec.get("duration", 1.5)) * minf(1.0 + 0.2 * float(levels - 1), 1.6)
	var flourish: Node3D = FLOURISH.attach(body, spec, _body_height(body), _body_radius(body))
	var glow_spec := {
		"duration": spec.get("duration", 1.5),
		"colour": spec.get("colour", "#ffd77a"),
		"rim_power": spec.get("rim_power", 2.2),
		"flat_mix": spec.get("rim_flat_mix", 0.12),
	}
	GLOW.attach(body, GLOW.Mode.PULSE, glow_spec, float(spec.get("rim_strength", 0.9)))
	return flourish


## --- the watcher -----------------------------------------------------------

## One watcher per tree, installed under the root the first time any hook
## fires from a node that is in a tree. Returns it, or null in a detached
## fixture (the unit runner), where a test drives `poll_party()` by hand.
static func ensure_watcher(from: Node) -> Node:
	if from == null or not from.is_inside_tree():
		return null
	var tree := from.get_tree()
	if tree == null or tree.root == null:
		return null
	if _watcher != null and is_instance_valid(_watcher):
		return _watcher
	var existing := tree.root.get_node_or_null(NodePath(WATCHER_NAME))
	if existing != null:
		_watcher = existing
		return existing
	var watcher := new()
	watcher.name = WATCHER_NAME
	_watcher = watcher
	# Deferred: hooks fire from inside physics callbacks, where adding a
	# child to the root is not allowed to happen synchronously.
	tree.root.call_deferred("add_child", watcher)
	return watcher


## The party revision the level snapshot was taken at, and the snapshot:
## creature instance id -> level.
var _seen_revision: int = -1
var _levels: Dictionary = {}
## Creature instance id -> the watcher time its last flourish played.
var _last_flourish: Dictionary = {}
var _time: float = 0.0
var _director: Node = null


func _physics_process(delta: float) -> void:
	_time += delta
	var game := get_tree().root.get_node_or_null(^"Game")
	if game == null:
		return
	var party: Variant = game.get("party")
	if party == null:
		return
	poll_party(party, _find_director(), _time)


## Compare every party member's level against the last snapshot; play the
## flourish on any that rose and can be found in the world. Returns the
## detections as [{creature, levels}] so a test can see what the watcher saw.
##
## A member the snapshot has never met (just caught, just adopted, or the
## first poll) is recorded at its current level and NOT flourished: it did
## not level, it arrived.
func poll_party(party: RefCounted, director: Node, now: float = -1.0) -> Array:
	var detected: Array = []
	if party == null:
		return detected
	if now < 0.0:
		now = _time
	var members: Array = party.call("members") if party.has_method("members") else []
	var revision: int = int(party.get("revision")) if party.get("revision") != null else 0
	if revision != _seen_revision:
		var fresh: Dictionary = {}
		for member: Variant in members:
			if member == null:
				continue
			var id: int = (member as Object).get_instance_id()
			fresh[id] = _levels.get(id, int(member.get("level")))
		_levels = fresh
		_seen_revision = revision

	for member: Variant in members:
		if member == null:
			continue
		var id: int = (member as Object).get_instance_id()
		var level: int = int(member.get("level"))
		if not _levels.has(id):
			_levels[id] = level
			continue
		var before: int = int(_levels[id])
		if level > before:
			_levels[id] = level
			detected.append({"creature": member, "levels": level - before})
			_flourish_for(member, level - before, director, now)
		elif level < before:
			_levels[id] = level
	return detected


## The seam for `Game.progression_feed` (prompt 73 §2.1): an event of kind
## `level_up` carrying the creature (as `creature`, or by `instance_id`)
## plays the same flourish the poll would. Anything else is ignored.
func on_progression_event(event: Dictionary, director: Node = null) -> bool:
	if str(event.get("kind", "")) != "level_up":
		return false
	var creature: Variant = event.get("creature")
	if creature == null and event.has("instance_id"):
		creature = instance_from_id(int(event.get("instance_id")))
	if creature == null or not (creature is Object):
		return false
	var levels: int = maxi(int(event.get("levels_gained", 1)), 1)
	# Keep the snapshot honest so the next poll does not fire a second time
	# for the rise the feed just reported.
	_levels[(creature as Object).get_instance_id()] = int((creature as Object).get("level"))
	return _flourish_for(creature, levels, director if director != null else _find_director(), _time)


## The body a creature stands in right now, if it is standing anywhere: the
## director's deployed ally when this is the ally instance. A creature in its
## orb has no body, so the bench share of a win shows on the HUD line only
## (vfx.json `level_up.bench_on_trainer`, off).
func _body_for(creature: Variant, director: Node) -> Node3D:
	if director == null or not is_instance_valid(director):
		return null
	if not director.has_method("ally_instance") or not director.has_method("ally_body"):
		return null
	if director.call("ally_instance") != creature:
		return null
	var body: Variant = director.call("ally_body")
	if body is Node3D and is_instance_valid(body):
		return body as Node3D
	return null


func _flourish_for(creature: Variant, levels: int, director: Node, now: float) -> bool:
	var id: int = (creature as Object).get_instance_id()
	var gap: float = float(_block("level_up").get("min_gap", 0.75))
	if _last_flourish.has(id) and now - float(_last_flourish[id]) < gap:
		return false
	var body := _body_for(creature, director)
	if body == null:
		return false
	var played := level_up(body, levels)
	if played == null:
		return false
	_last_flourish[id] = now
	return true


func _find_director() -> Node:
	if _director != null and is_instance_valid(_director):
		return _director
	_director = null
	if not is_inside_tree():
		return null
	var found := get_tree().root.find_child("EncounterDirector", true, false)
	if found != null:
		_director = found
	return _director
