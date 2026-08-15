extends RefCounted

## One live creature: the state that changes during a fight, a level-up, or a
## day spent in the party.
##
## Split from species data on purpose (TECHNICAL_START.md, "Creature Data vs Creature
## Instance"). A species says a Bramblebun has 95 base HP; an instance says
## THIS Bramblebun currently has 31, is level 4, and has 62 xp toward level 5.
## Writing any of that onto shared species data is the bug that makes every
## creature of a species share a health bar, and it is much easier to avoid
## now than to unpick later.
##
## No nodes, so it is testable headlessly and so the same instance can outlive
## the scene node that draws it — which is what M4's party will need.

const MATH := preload("res://scripts/combat/combat_math.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAIT_DB := preload("res://scripts/creatures/trait_db.gd")

var species_id: String = ""
var display_name: String = ""
var creature_type: String = "ground"

## What the player called it, or empty for "it kept its species name".
##
## Empty rather than a copy of `display_name` on purpose. GAME_DESIGN.md 10:
## "New captures can keep species name by default" — and a party screen has to
## be able to tell a Terrapup the player never renamed from one they
## deliberately named "Terrapup". Copying the species name in would erase that
## difference permanently, and the release ceremony needs it.
var nickname: String = ""

## The species' base stats at level 1, kept alongside the current (possibly
## levelled) stats below. A level-up cannot recompute `max_hp` from `max_hp`
## itself without compounding growth every time it is called, so it always
## recomputes from these instead (D30, see `_apply_level_stats`).
var base_hp: float = 1.0
var base_attack: float = 1.0
var base_defence: float = 1.0

var max_hp: float = 1.0
var attack: float = 1.0
var defence: float = 1.0

var hp: float = 1.0
var energy: float = 0.0

## Set once when the creature faints, so the transition can be detected exactly
## once rather than every frame HP happens to be zero.
var fainted: bool = false

## --- progression (D30) -----------------------------------------------------

var level: int = 1
var xp: int = 0

## 0-100. Read through `bond_nodes()` rather than compared directly — the
## thresholds that turn bond into an actual stat bonus live in
## data/config/progression.json, not here.
var bond: int = 0

## Ids into data/moves/moves.json (scripts/creatures/move_db.gd resolves them to
## something a fight or a menu can show). Empty string is a legitimate value —
## a species with no `moves` entry, or a hand-built definition in a test —
## and every caller that reads these must treat "" as "no move", not crash.
var move_quick: String = ""
var move_charged: String = ""

## --- individuality (R4.2) ----------------------------------------------------

## Per-stat quality rolls, 0.0-1.0, 0.5 = perfectly average (GAME_DESIGN.md 11:
## "same-species creatures have slightly different underlying stat quality").
## Stored raw rather than as a baked-in multiplier so `appraisal_stars()` can
## bucket them for display, and so a species retune (a new `base_hp`) still
## recomputes correctly through `_apply_level_stats` the same way level-ups
## already do. Defaulting every roll to 0.5 — the exact "no variance" value —
## is what keeps every caller that does not roll individuality (an old save,
## `make_creature`'s starters, most tests) at today's stats byte-for-byte.
var iv_hp: float = 0.5
var iv_attack: float = 0.5
var iv_defence: float = 0.5

## Ids into data/traits/traits.json. "" means no trait rolled (an old save, a
## caller that did not opt in, or an empty trait pool) — the same "empty
## string is a legitimate value" contract move_quick/move_charged already
## use. `trait_secondary` is rolled at the same time as `trait_primary`, but
## stays hidden from callers until `revealed_trait_secondary()` says bond has
## unlocked it (GAME_DESIGN.md 11: "a second trait can develop later through
## progression/bond") — rolling it up front means nothing needs live
## randomness at bond-gain time, the same "roll once, reveal later" shape
## `_apply_level_stats` already uses for stat growth.
var trait_primary: String = ""
var trait_secondary: String = ""


## Build a live creature at level 1 with base stats, unless told otherwise.
##
## `level_roll` and `cfg` are both opt-in additions for D30 and both default to
## values that reproduce the exact pre-D30 behaviour: no `cfg` means there is
## no growth table to scale by, so `stat_at_level(base, 1, growth)` collapses
## to `base` regardless of what growth would have been, and `level_roll < 0`
## means "do not roll a level at all". Every existing caller — game_state's
## `make_creature`, `creature_species.spawn`, every test that calls `from_species(id,
## definition)` with two arguments — keeps getting a level 1 creature whose stats
## equal the species' base stats exactly, byte-for-byte. Levelling is
## something a caller now has to ask for, not something that started
## happening to them.
##
## `iv_rolls` and `trait_rolls` are the same opt-in shape, added for R4.2:
## empty arrays (the default) leave every `iv_*` field at 0.5 — the exact "no
## variance" value — and both trait fields at "", reproducing pre-R4.2 stats
## and an untraited creature exactly. A caller that wants individuality
## passes up to 3 floats (hp, attack, defence, each 0..1) in `iv_rolls`; a
## caller that wants a trait passes 1 or 2 floats in `trait_rolls` (primary,
## optionally the hidden secondary — see `trait_secondary`'s own comment).
static func from_species(
	id: String, definition: Dictionary, level_roll: float = -1.0, cfg: Dictionary = {},
	iv_rolls: Array = [], trait_rolls: Array = []
) -> RefCounted:
	var instance: RefCounted = (load("res://scripts/creatures/creature_instance.gd") as GDScript).new()
	instance.species_id = id
	instance.display_name = str(definition.get("display_name", id))
	instance.creature_type = str(definition.get("type", "ground"))

	instance.base_hp = float(definition.get("base_hp", 100.0))
	instance.base_attack = float(definition.get("base_attack", 20.0))
	instance.base_defence = float(definition.get("base_defence", 20.0))

	var moves: Dictionary = definition.get("moves", {})
	instance.move_quick = str(moves.get("quick", ""))
	instance.move_charged = str(moves.get("charged", ""))

	instance.iv_hp = float(iv_rolls[0]) if iv_rolls.size() > 0 else 0.5
	instance.iv_attack = float(iv_rolls[1]) if iv_rolls.size() > 1 else 0.5
	instance.iv_defence = float(iv_rolls[2]) if iv_rolls.size() > 2 else 0.5

	instance.trait_primary = ""
	instance.trait_secondary = ""
	if trait_rolls.size() > 0:
		var traits := TRAIT_DB.load_default()
		instance.trait_primary = str(traits.call("roll", float(trait_rolls[0])))
		if trait_rolls.size() > 1:
			instance.trait_secondary = str(traits.call("roll", float(trait_rolls[1])))

	# Only roll a level when a caller supplied both a config AND a roll — the
	# two args exist to work together, and a config with no roll (or a roll
	# with no config to read the wild band from) should not spawn a
	# surprise level.
	var level_value := 1
	if level_roll >= 0.0 and not cfg.is_empty():
		level_value = PROGRESSION.roll_wild_level(cfg, level_roll)
	instance.level = level_value
	instance.xp = 0
	instance.bond = 0

	instance._apply_level_stats(cfg)
	instance.hp = instance.max_hp
	instance.energy = 0.0
	instance.fainted = false
	instance.nickname = ""
	return instance


## What to put on a nameplate or a party row: the nickname if it has one.
##
## Every UI goes through this rather than reading `nickname` and falling back
## itself, because the fallback is the rule and a screen that forgets it shows a
## blank name.
func label() -> String:
	return display_name if nickname.strip_edges().is_empty() else nickname


## Apply damage. Returns true if THIS call caused the faint, so callers can fire
## a death sequence once instead of on every frame after HP hits zero.
func take_damage(amount: float) -> bool:
	if fainted:
		return false
	hp = maxf(0.0, hp - maxf(0.0, amount))
	if hp <= 0.0:
		fainted = true
		return true
	return false


func gain_energy_from_quick() -> void:
	energy = MATH.energy_after_quick(energy)


func can_use_charged() -> bool:
	return not fainted and MATH.can_use_charged(energy)


## Spend for a charged attack. Returns false and spends nothing when there is
## not enough, so a refused attack cannot leave energy negative.
func spend_charged() -> bool:
	if not can_use_charged():
		return false
	energy = MATH.energy_after_charged(energy)
	return true


func heal_fully() -> void:
	hp = max_hp
	energy = 0.0
	fainted = false


## Partial healing, for potions. Returns how much was actually restored so the
## caller can refuse to waste an item on a full-health creature. A fainted
## creature is brought back up — a potion that cannot help the creature that needs
## it most is a trap item.
func heal(amount: float) -> float:
	var before := hp
	hp = clampf(hp + maxf(0.0, amount), 0.0, max_hp)
	if hp > 0.0:
		fainted = false
	return hp - before


func hp_fraction() -> float:
	return 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)


func energy_fraction() -> float:
	var cap := MATH.max_energy()
	return 0.0 if cap <= 0.0 else clampf(energy / cap, 0.0, 1.0)


## --- progression (D30) -----------------------------------------------------

## Recompute max_hp/attack/defence from the stored base stats and the current
## level, preserving whatever fraction of max_hp the creature currently has.
##
## Recomputing from `base_*` rather than scaling `max_hp` itself in place is
## what keeps ten level-ups equal to one recompute at level 11: scaling a
## number that is already scaled compounds the growth rate every call, and
## nobody could tune `growth_per_level` sanely against a curve that moves
## depending on how many small steps got it there.
##
## The hp FRACTION survives a level-up rather than the hp NUMBER, on purpose —
## a Bramblebun on the edge of fainting does not get topped up by outlevelling
## its wounds mid-fight, but it also does not stay at, say, "31 out of 190"
## after max_hp trebles, which would read as the level-up having hurt it.
func _apply_level_stats(cfg: Dictionary) -> void:
	var growth: Dictionary = cfg.get("level", {}).get("growth_per_level", {})
	var fraction := hp_fraction() if max_hp > 0.0 else 1.0
	max_hp = PROGRESSION.stat_at_level(base_hp, level, float(growth.get("hp", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_hp, cfg)
	attack = PROGRESSION.stat_at_level(base_attack, level, float(growth.get("attack", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_attack, cfg)
	defence = PROGRESSION.stat_at_level(base_defence, level, float(growth.get("defence", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_defence, cfg)
	hp = max_hp * fraction


## XP still needed to reach the next level, from this creature's CURRENT
## level. Exposed so a UI can draw "62 / 118 xp" without reimplementing the
## curve.
func xp_to_next(cfg: Dictionary) -> int:
	return PROGRESSION.xp_to_next(level, cfg)


## Award xp, levelling up as many times as it will support (never past the
## configured cap), applying stat growth at each level. Returns how many
## levels were actually gained, so a caller can decide whether "level up!"
## banners are worth showing.
## Jump straight to a level — starters and story spawns, not gameplay
## levelling (that is `gain_xp`'s job). Recomputes stats from base the same
## way a level-up does, and refills hp, because every caller of this sets the
## level before the creature has ever taken a hit (D30: starter_level).
func set_level(new_level: int, cfg: Dictionary) -> void:
	var cap := int(cfg.get("level", {}).get("cap", 50))
	level = clampi(new_level, 1, cap)
	xp = 0
	_apply_level_stats(cfg)
	hp = max_hp


func gain_xp(amount: int, cfg: Dictionary) -> int:
	if amount <= 0:
		return 0
	xp += amount

	var cap := int(cfg.get("level", {}).get("cap", level))
	var levels_gained := 0
	while level < cap and xp >= xp_to_next(cfg):
		xp -= xp_to_next(cfg)
		level += 1
		levels_gained += 1
		_apply_level_stats(cfg)
	return levels_gained


## Raise bond, clamped at the configured max so nothing that keeps calling
## this (a daily tick, a string of wins) can walk it past 100 and off the end
## of `thresholds`.
func gain_bond(points: int, cfg: Dictionary) -> void:
	if points <= 0:
		return
	var cap := int(cfg.get("bond", {}).get("max", 100))
	bond = clampi(bond + points, 0, cap)


## How many bond thresholds this creature has crossed (0-5 for the shipped
## five-entry `thresholds` list). What that actually buys is
## `PROGRESSION.bond_stat_scale` — this only counts the crossings.
func bond_nodes(cfg: Dictionary) -> int:
	return PROGRESSION.bond_nodes(bond, cfg)


## --- individuality (R4.2) ----------------------------------------------------

## 1-5 stars/bars for one core stat's quality roll (GAME_DESIGN.md 11: "show
## appraisal through stars/bars, not exact IV numbers"). `stat_name` is
## "hp", "attack" or "defence"; an unrecognised name reads as perfectly
## average (3 stars against the shipped thresholds) rather than crashing.
func appraisal_stars(stat_name: String, cfg: Dictionary) -> int:
	var iv := 0.5
	match stat_name:
		"hp":
			iv = iv_hp
		"attack":
			iv = iv_attack
		"defence":
			iv = iv_defence
	return PROGRESSION.appraisal_stars(iv, cfg)


## The overall appraisal a trainer would actually look at — the mean of the
## three per-stat rolls, bucketed the same way. Kept separate from the
## per-stat stars above because a UI showing one headline rating (a party
## row) and a UI showing three (a detail panel) both come from the same raw
## data honestly, rather than one being derived from the other's buckets.
func overall_appraisal_stars(cfg: Dictionary) -> int:
	return PROGRESSION.appraisal_stars((iv_hp + iv_attack + iv_defence) / 3.0, cfg)


## The second trait, once bond has actually unlocked it (GAME_DESIGN.md 11:
## "a second trait can develop later through progression/bond") — "" both
## before that and when nothing was ever rolled. `trait_secondary` itself
## always holds the rolled value from creation; this is the gate every
## caller should read through instead, so a UI cannot leak an unearned trait
## by reading the raw field.
func revealed_trait_secondary(cfg: Dictionary) -> String:
	if trait_secondary == "":
		return ""
	return trait_secondary if PROGRESSION.trait_unlocked(bond_nodes(cfg), cfg) else ""
