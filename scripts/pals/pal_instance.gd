extends RefCounted

## One live creature: the state that changes during a fight.
##
## Split from species data on purpose (TECHNICAL_START.md, "Pal Data vs Pal
## Instance"). A species says a Meadow Hopper has 95 base HP; an instance says
## THIS Meadow Hopper currently has 31. Writing current HP onto shared species
## data is the bug that makes every creature of a species share a health bar,
## and it is much easier to avoid now than to unpick later.
##
## No nodes, so it is testable headlessly and so the same instance can outlive
## the scene node that draws it — which is what M4's party will need.
##
## M4 added the per-individual half of GAME_DESIGN.md §11: level, XP, nickname
## and one trait. The split above is what makes those safe to add — a level is a
## property of THIS creature, and writing it onto the species table would level
## up every Meadow Hopper in the biome at once.

const MATH := preload("res://scripts/combat/combat_math.gd")
const TRAITS := preload("res://scripts/pals/pal_traits.gd")

const CONFIG_PATH := "res://data/config/party.json"

static var _config: Dictionary = {}

var species_id: String = ""
var display_name: String = ""
var pal_type: String = "ground"

## What the species is worth before anything happened to this individual: level
## one, no trait. Kept so every level-up and every trait change is recomputed
## from the baseline rather than multiplied onto the last result — compounding
## the same 9% onto a stat that already includes it is a slow, invisible drift
## that only shows up as a level-30 pal with numbers nobody can explain.
var base_hp: float = 1.0
var base_attack: float = 1.0
var base_defence: float = 1.0

var max_hp: float = 1.0
var attack: float = 1.0
var defence: float = 1.0

var hp: float = 1.0
var energy: float = 0.0

## GAME_DESIGN.md §11: 1–50, combat is the primary source, and wild levels are
## never scaled to the player. `xp` is progress towards the NEXT level and resets
## on each one, so a bar only ever has to divide it by xp_for_next_level().
var level: int = 1
var xp: int = 0

## Empty means "no nickname"; display() then falls back to the species name.
## Stored empty rather than pre-filled with the species name so that renaming and
## never-named stay distinguishable — §10 wants new captures to keep the species
## name BY DEFAULT, which is a display rule, not a stored value.
var nickname: String = ""

## One trait, assigned at creation. §11 allows a second to develop later through
## bond; this is deliberately a single id and not an array, because M4 has no
## bond system and an array would be a speculative shape with one element in it.
var trait_id: String = ""

## Set once when the creature faints, so the transition can be detected exactly
## once rather than every frame HP happens to be zero.
var fainted: bool = false


static func from_species(id: String, definition: Dictionary) -> RefCounted:
	var instance: RefCounted = (load("res://scripts/pals/pal_instance.gd") as GDScript).new()
	instance.species_id = id
	instance.display_name = str(definition.get("display_name", id))
	instance.pal_type = str(definition.get("type", "ground"))
	instance.base_hp = float(definition.get("base_hp", 100.0))
	instance.base_attack = float(definition.get("base_attack", 20.0))
	instance.base_defence = float(definition.get("base_defence", 20.0))
	instance.level = start_level()
	instance.xp = 0
	instance.nickname = ""
	instance.trait_id = ""
	instance.fainted = false
	instance.recompute_stats()
	instance.hp = instance.max_hp
	instance.energy = 0.0
	return instance


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("party.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


static func level_cap() -> int:
	return int(config().get("levels", {}).get("cap", 50))


static func start_level() -> int:
	return int(config().get("levels", {}).get("start", 1))


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


func hp_fraction() -> float:
	return 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)


func energy_fraction() -> float:
	var cap := MATH.max_energy()
	return 0.0 if cap <= 0.0 else clampf(energy / cap, 0.0, 1.0)


## --- identity -------------------------------------------------------------

## What to call this creature on screen.
##
## §10 says new captures keep the species name by default and pals can be
## renamed. Both are this one function: the default is not stored, it is what
## falls out when nobody has typed anything.
func display() -> String:
	return nickname if not nickname.is_empty() else display_name


## Rename. Returns false and changes nothing on an all-whitespace name, so a
## player cannot end up with a nameless pal by holding the space bar.
func rename(new_name: String) -> bool:
	var trimmed := new_name.strip_edges()
	if trimmed.is_empty():
		return false
	nickname = trimmed
	return true


## Clear the nickname and go back to the species name.
func clear_nickname() -> void:
	nickname = ""


## --- trait ----------------------------------------------------------------

## Give this creature a trait, or clear it with "". Returns false for an id that
## is not in traits.json rather than accepting it, because a trait id that
## multiplies nothing is invisible until someone wonders why their Fierce pal
## hits like everything else.
func assign_trait(id: String) -> bool:
	if not id.is_empty() and not TRAITS.has(id):
		push_error("unknown trait '%s'; known: %s" % [id, ", ".join(TRAITS.ids())])
		return false
	trait_id = id
	recompute_stats()
	return true


## --- levels and growth ----------------------------------------------------

## Set the level directly, for a wild pal spawned at a level or a save being
## restored. Clamped rather than refused: a save from a build with a higher cap
## should produce a legal pal, not a rejected one.
func set_level(value: int) -> void:
	level = clampi(value, 1, level_cap())
	recompute_stats()


## XP still owed before the next level, or 0 at the cap.
##
## The curve is `base * level^exponent` from data/config/party.json — in the
## config, not here, because "levelling takes forever" is the single most likely
## piece of owner feedback about this system and it must be answerable without
## touching code.
func xp_for_next_level() -> int:
	if level >= level_cap():
		return 0
	var cfg: Dictionary = config().get("xp", {})
	var base := float(cfg.get("base", 60.0))
	var exponent := float(cfg.get("exponent", 1.55))
	return maxi(1, int(round(base * pow(float(level), exponent))))


## Award XP. Returns how many levels it bought, so a caller can play one fanfare
## per level without having to remember what the level was beforehand.
##
## Loops rather than granting a single level, because a boss kill worth several
## levels should hand over all of them; swallowing the surplus is the bug where
## a big reward feels smaller than a small one.
## Add experience and return how many levels it bought.
##
## `xp` is PROGRESS WITHIN THE CURRENT LEVEL, not a lifetime total — each
## level-up subtracts that level's cost. A blind reader of the save file sees
## "granted 100000, xp: 9184" and reasonably concludes 90k went missing; it did
## not, it was spent on twenty-five levels. Anything printing this number should
## print its denominator with it.
func grant_xp(amount: int) -> int:
	if amount <= 0 or level >= level_cap():
		return 0
	xp += amount
	var gained := 0
	while level < level_cap():
		var needed := xp_for_next_level()
		if xp < needed:
			break
		xp -= needed
		level += 1
		gained += 1
	if level >= level_cap():
		# At the cap there is no next level to divide by, so leftover progress is
		# dropped rather than left in a bar that can never fill.
		xp = 0
	if gained > 0:
		recompute_stats()
	return gained


## Recalculate max HP, attack and defence from the species baseline, this level
## and this trait. Always from the baseline; never from the current values.
##
## A level-up hands over the WHOLE increase in max HP rather than keeping the
## current fraction. Scaling by fraction means a pal that levels at half health
## gains half of its reward, which reads as the game taking something back at the
## exact moment it was supposed to be giving.
func recompute_stats() -> void:
	var previous_max := max_hp
	max_hp = _grown(base_hp, "hp_per_level") * TRAITS.modifier(trait_id, "hp")
	attack = _grown(base_attack, "attack_per_level") * TRAITS.modifier(trait_id, "attack")
	defence = _grown(base_defence, "defence_per_level") * TRAITS.modifier(trait_id, "defence")
	if not fainted:
		hp = clampf(hp + maxf(0.0, max_hp - previous_max), 0.0, max_hp)


## The species baseline grown to this level, with no trait applied. Linear, not
## compound: see the note in data/config/party.json about level 50.
func _grown(base: float, growth_key: String) -> float:
	var per_level := float(config().get("growth", {}).get(growth_key, 0.08))
	return base * (1.0 + per_level * float(maxi(level, 1) - 1))


## --- appraisal ------------------------------------------------------------

## What THIS individual is worth, as data.
##
## §11 asks for appraisal shown "through stars/bars, not exact IV numbers", so
## this returns both the ratios and the stars derived from them and lets the UI
## decide what to draw. It returns a Dictionary rather than a formatted string
## for the ordinary reason: the M5 keep/release ceremony and the M4 party menu
## will present the same facts very differently, and a sentence built here would
## be right for exactly one of them.
##
## The comparison is against the species baseline AT THIS LEVEL, which is what
## makes a level-3 pal and a level-20 pal comparable at all. Today the only thing
## that moves a ratio off 1.0 is the trait; when §11's per-individual stat
## quality lands, it will move the same ratios and this needs no change.
func appraisal() -> Dictionary:
	var stats := {
		"hp": _appraise(max_hp, _grown(base_hp, "hp_per_level")),
		"attack": _appraise(attack, _grown(base_attack, "attack_per_level")),
		"defence": _appraise(defence, _grown(base_defence, "defence_per_level")),
	}
	var total := 0.0
	for stat: String in stats.keys():
		total += float((stats[stat] as Dictionary)["ratio"])
	var overall := total / float(stats.size())
	return {
		"display": display(),
		"species": species_id,
		"species_name": display_name,
		"type": pal_type,
		"level": level,
		"level_cap": level_cap(),
		"xp": xp,
		"xp_for_next_level": xp_for_next_level(),
		"nickname": nickname,
		"trait": {
			"id": trait_id,
			"display_name": TRAITS.display_name(trait_id) if not trait_id.is_empty() else "",
			"description": TRAITS.description(trait_id) if not trait_id.is_empty() else "",
			"modifiers": TRAITS.modifiers(trait_id),
		},
		"stats": stats,
		"ratio": overall,
		"stars": stars_for(overall),
		"max_stars": max_stars(),
	}


func _appraise(value: float, baseline: float) -> Dictionary:
	var ratio := 1.0 if baseline <= 0.0 else value / baseline
	return {
		"value": value,
		"baseline": baseline,
		"ratio": ratio,
		"stars": stars_for(ratio),
	}


## Stars for a stat ratio, from the bands in data/config/party.json. One star to
## begin with, and one more for each band cleared — a zero-star pal would read as
## broken rather than as poor.
static func stars_for(ratio: float) -> int:
	var cfg: Dictionary = config().get("appraisal", {})
	var bands: Array = cfg.get("bands", [])
	var stars := 1
	for band: Variant in bands:
		if ratio >= float(band):
			stars += 1
	return mini(stars, max_stars())


static func max_stars() -> int:
	return maxi(1, int(config().get("appraisal", {}).get("max_stars", 5)))


## --- persistence ----------------------------------------------------------

## The serialisable form, and the primary one — same discipline as structures.gd.
##
## Only identity and progress are stored. Max HP, attack and defence are NOT:
## they are derived from the species table, the level and the trait, so writing
## them would freeze a creature at the balance of the build that caught it and
## quietly ignore every rebalance afterwards. Energy is not stored either,
## because it is earned inside one fight and starts at zero in the next.
##
## No version number of its own, on purpose. autoload/save_manager.gd carries ONE
## for the whole envelope and says why: a per-record version lets a file be
## partly current, which is the state nobody can reason about. When this shape
## changes, the number that moves is SaveManager.SAVE_VERSION.
func to_record() -> Dictionary:
	return {
		"species": species_id,
		"nickname": nickname,
		"trait": trait_id,
		"level": level,
		"xp": xp,
		"hp": hp,
		"fainted": fainted,
	}


## Rebuild from a record. Returns null for an unknown species, so a hand-edited
## or stale save loses one pal loudly instead of producing a creature with no
## stats.
##
## pal_species.gd is loaded at runtime rather than preloaded: it preloads THIS
## file to spawn instances, and two files that preload each other will not load
## at all.
static func from_record(record: Dictionary) -> RefCounted:
	var species: GDScript = load("res://scripts/pals/pal_species.gd")
	var instance: RefCounted = species.spawn(str(record.get("species", "")))
	if instance == null:
		return null
	instance.nickname = str(record.get("nickname", ""))
	var stored_trait := str(record.get("trait", ""))
	if not stored_trait.is_empty():
		# A trait that no longer exists in traits.json leaves the pal traitless
		# rather than refusing the whole save. Losing a modifier is recoverable;
		# losing the creature is not.
		instance.assign_trait(stored_trait)
	instance.set_level(int(record.get("level", 1)))
	instance.xp = maxi(0, int(record.get("xp", 0)))
	instance.fainted = bool(record.get("fainted", false))
	instance.hp = 0.0 if instance.fainted else clampf(
		float(record.get("hp", instance.max_hp)), 0.0, instance.max_hp
	)
	instance.energy = 0.0
	return instance
