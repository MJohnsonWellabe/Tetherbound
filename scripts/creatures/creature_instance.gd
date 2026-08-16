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

## Permanent stat gains from elixirs, in raw stat points, one per stat.
##
## Owner directive (2026-08-16), choosing "both, permanent stays rare" for the
## potion economy: temporary tonics AND a small number of permanent stat
## elixirs, scarce enough that they read as a prize rather than a grind.
##
## `D37` deliberately kept stat variance out of the player's hands -- IVs are
## rolled and traits are flavour, precisely so nobody can farm a perfect
## creature. This does not reopen that: an elixir is a rare, findable object
## that adds a FLAT, capped number of points, and it is applied on top of the
## level curve rather than into it. See `docs/decisions/D47`.
##
## Flat rather than multiplicative, and added AFTER the level scaling, because
## a multiplier would compound with every level and make an early elixir worth
## more than a late one -- which is exactly the grind D37 was protecting
## against. A flat +N is worth the same whenever it is drunk.
var boost_hp: int = 0
var boost_attack: int = 0
var boost_defence: int = 0

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

## OF27: "make a version that is a 'shiny' like Pokemon go. Rare and nothing
## different than just the colors" (owner report). Purely cosmetic — nothing
## in combat_math.gd/progression.gd reads this, and it never should; the day
## a shiny is quietly stronger is the day "just the colors" stops being true.
## Defaults false for the same "old caller, byte-for-byte old behaviour"
## reason iv_hp/trait_primary already default to their own no-op values.
var shiny: bool = false


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
##
## `is_shiny` is OF27's own opt-in, same shape again: a caller that already
## knows the answer (a save-load reconstruction going through this instead of
## `_array_to_party`, a test) can hand it straight in and gets it set exactly
## as given. `encounter_director._roll_wild_level` deliberately does NOT pass
## its roll through here — the shiny draw has to be the LAST rng.randf() in
## the seeded per-spawn stream, after the level_roll argument above has
## already been evaluated as part of THIS call, so that caller sets `.shiny`
## on the returned instance directly instead. Either path reaches the same
## field.
static func from_species(
	id: String, definition: Dictionary, level_roll: float = -1.0, cfg: Dictionary = {},
	iv_rolls: Array = [], trait_rolls: Array = [], is_shiny: bool = false
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
	instance.shiny = is_shiny
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


func gain_energy_from_quick(multiplier: float = 1.0) -> void:
	energy = MATH.energy_after_quick(energy, multiplier)


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
## caller can refuse to waste an item on a full-health creature.
##
## D40 (owner decision, 2026-08-15, "Grandpa should give you revives at the
## beginning too"): a fainted creature now REFUSES a potion outright rather
## than being brought back up by one. The comment this replaced argued the
## opposite — "a potion that cannot help the creature that needs it most is
## a trap item" — and that was the rule for a year of development. The owner
## chose "potions stop reviving" over "both revive" when asked directly:
## fainting needed its own dedicated answer (`revive()`, below) rather than
## letting the same item quietly cover both jobs. Left here rather than
## deleted so the old reasoning stays legible next to the new one.
func heal(amount: float) -> float:
	if fainted:
		return 0.0
	var before := hp
	hp = clampf(hp + maxf(0.0, amount), 0.0, max_hp)
	return hp - before


## D40's dedicated un-fainter. Only acts on a fainted creature — refuses
## (returns 0.0, leaves `fainted` and `hp` untouched) on anything still
## standing, the mirror image of `heal()`'s new refusal above, so a Revive
## used on a healthy creature cannot be mistaken for a wasted potion. `fraction`
## is the portion of `max_hp` restored (see `data/items/items.json`'s `revive`
## item — 0.5, tunable) rather than a flat amount, so the same item makes
## sense on a level 3 Terrapup and a level 20 one.
func revive(fraction: float) -> float:
	if not fainted:
		return 0.0
	fainted = false
	hp = clampf(max_hp * maxf(0.0, fraction), 0.0, max_hp)
	return hp


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
	# Elixir points are added AFTER the level curve and the individuality
	# multiplier, never folded into either -- see `boost_hp`'s own comment for
	# why a flat late add is the thing that keeps this out of D37's territory.
	max_hp = PROGRESSION.stat_at_level(base_hp, level, float(growth.get("hp", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_hp, cfg) + float(boost_hp)
	attack = PROGRESSION.stat_at_level(base_attack, level, float(growth.get("attack", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_attack, cfg) + float(boost_attack)
	defence = PROGRESSION.stat_at_level(base_defence, level, float(growth.get("defence", 0.0))) \
		* PROGRESSION.individuality_multiplier(iv_defence, cfg) + float(boost_defence)
	hp = max_hp * fraction


## Drink an elixir: add `points` to one stat, permanently, up to the cap.
##
## `stat` is "hp" / "attack" / "defence". Returns how many points were actually
## taken, so a caller can tell "drank it, +3" from "already at the cap" and say
## so instead of silently spending the item.
##
## The cap is what keeps this a prize rather than a grind (`D47`). Without it,
## a player with enough coins and enough patience converts money straight into
## an arbitrarily strong creature, which is the outcome `D37` refused when it
## kept individuality rolls out of player hands.
func drink_elixir(stat: String, points: int, cfg: Dictionary) -> int:
	var cap := int(cfg.get("elixirs", {}).get("cap_per_stat", 24))
	var current := 0
	match stat:
		"hp": current = boost_hp
		"attack": current = boost_attack
		"defence": current = boost_defence
		_: return 0
	var taken := clampi(points, 0, maxi(0, cap - current))
	if taken <= 0:
		return 0
	match stat:
		"hp": boost_hp += taken
		"attack": boost_attack += taken
		"defence": boost_defence += taken
	# Straight back through the same recompute a level-up uses, so an elixir
	# and a level cannot disagree about what a stat is worth. It preserves the
	# hp FRACTION, which is why a vitality elixir raises the ceiling without
	# also acting as a free full heal.
	_apply_level_stats(cfg)
	return taken


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


## --- evolution (R4.6) --------------------------------------------------------

## Mutate this instance in place into `definition` (a species.json entry for
## the evolved form) -- the only thing evolution ever changes. Everything the
## player earned survives untouched: nickname, level, xp, bond, individuality
## rolls, traits, hp fraction (via `_apply_level_stats`, the same level-up
## machinery this reuses rather than duplicates) and already-taught moves --
## a TM taught before evolving is not silently reverted by it. `moves` is
## deliberately left alone for the same reason: this line's two species
## currently share one move pair anyway, and the day they do not, a fresh
## catch getting the new species' defaults is `from_species`'s job, not this
## one's.
func evolve_into(new_species_id: String, definition: Dictionary, cfg: Dictionary) -> void:
	species_id = new_species_id
	display_name = str(definition.get("display_name", new_species_id))
	creature_type = str(definition.get("type", creature_type))
	base_hp = float(definition.get("base_hp", base_hp))
	base_attack = float(definition.get("base_attack", base_attack))
	base_defence = float(definition.get("base_defence", base_defence))
	_apply_level_stats(cfg)


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


## --- Best Creature (R4.7, GAME_DESIGN.md §12) -------------------------------
##
## The ability dict these three take is `creature_species.best_creature_ability
## (species_id)` — species data, not instance state, the same
## "Creature Data vs Creature Instance" split TECHNICAL_START.md draws for
## catch_rate/is_aggressive. A caller that is not the party's flagged Best
## Creature just omits `is_best`/`ability`, which is why every existing
## damage/energy call site keeps working unchanged.

## Attack for one hit: base `attack` scaled by however many bond thresholds
## are crossed. `PROGRESSION.bond_stat_scale` has read a real config table
## since D30 but nothing multiplied it into a fight until this — GAME_DESIGN.md
## §12: "Bond increases through fighting together" needs fighting to actually
## pay bond back, not just take it in.
func effective_attack(cfg: Dictionary) -> float:
	return attack * PROGRESSION.bond_stat_scale(bond_nodes(cfg), "attack_scale", cfg) \
		* buff_scale("attack")


## Defence for one hit taken: bond's `defence_scale`, then a "survivability"
## Best Creature ability on top if this creature is the one flagged and its
## species has that kind. Bond is never a penalty for a creature nobody has
## bonded with yet (see `bond_stat_scale`'s own comment); the ability is the
## same — it only ever adds, never subtracts.
func effective_defence(cfg: Dictionary, is_best: bool = false, ability: Dictionary = {}) -> float:
	var scaled := defence * PROGRESSION.bond_stat_scale(bond_nodes(cfg), "defence_scale", cfg) \
		* buff_scale("defence")
	if is_best and str(ability.get("kind", "")) == "survivability":
		scaled *= 1.0 + float(ability.get("value", 0.0))
	return scaled


## --- tonics: timed buffs (the potions board's temporary half) --------------
##
## The other half of the owner's "both, permanent stays rare" potion decision
## (D47 records the permanent half). A tonic multiplies ONE stat for a bounded
## number of seconds and then is gone -- mirroring the shape
## `player_vitals.gd::active_buffs` already uses for food, so the two buff
## systems in the game read the same.
##
## Entries: `{id, stat, scale, remaining_s}`. `stat` is "attack" / "defence" /
## "speed" -- attack and defence multiply into `effective_attack`/`effective_
## defence` above; "speed" is read by combat_manager when it drives the body.
## Re-drinking the same tonic REFRESHES its clock rather than stacking its
## multiplier (same rule as food buffs): stacking is how a mandatory
## pre-fight buff ritual is born, and the owner's brief forbade exactly that.
##
## DELIBERATELY NOT SAVED. A timed buff dying on quit is the honest reading of
## "temporary", it keeps the save format still, and nobody reloads mid-battle
## to preserve ninety seconds of tonic.
var active_buffs: Array[Dictionary] = []


## Apply (or refresh) a timed buff. Refuses garbage quietly: a scale of <= 0
## or an empty stat would make a fight silently wrong from one bad data entry.
func apply_buff(id: String, stat: String, scale: float, duration_s: float) -> bool:
	if id.is_empty() or stat.is_empty() or scale <= 0.0 or duration_s <= 0.0:
		return false
	for entry in active_buffs:
		if str(entry.get("id", "")) == id:
			entry["stat"] = stat
			entry["scale"] = scale
			entry["remaining_s"] = duration_s
			return true
	active_buffs.append({"id": id, "stat": stat, "scale": scale, "remaining_s": duration_s})
	return true


## Age every buff; expired ones drop out. Called from GameState._process for
## every party member, so a tonic runs down in and out of combat alike --
## "drink it before the fight you drank it for", never a paused stockpile.
func tick_buffs(delta: float) -> void:
	if active_buffs.is_empty():
		return
	for i in range(active_buffs.size() - 1, -1, -1):
		active_buffs[i]["remaining_s"] = float(active_buffs[i].get("remaining_s", 0.0)) - delta
		if float(active_buffs[i]["remaining_s"]) <= 0.0:
			active_buffs.remove_at(i)


## Product of every live buff on `stat`. 1.0 with none -- the do-nothing
## default every existing call site gets for free.
func buff_scale(stat: String) -> float:
	var scale := 1.0
	for entry in active_buffs:
		if str(entry.get("stat", "")) == stat:
			scale *= float(entry.get("scale", 1.0))
	return scale


## Multiplier on a landed quick attack's energy gain. 1.0 unless this creature
## is flagged Best and its species' ability is the "energy" kind.
func quick_energy_multiplier(is_best: bool = false, ability: Dictionary = {}) -> float:
	if is_best and str(ability.get("kind", "")) == "energy":
		return 1.0 + float(ability.get("value", 0.0))
	return 1.0


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
