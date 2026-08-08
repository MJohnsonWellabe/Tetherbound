extends RefCounted

## One live creature: the state that changes during a fight.
##
## Split from species data on purpose (TECHNICAL_START.md, "Pal Data vs Pal
## Instance"). A species says a Bramblebun has 95 base HP; an instance says
## THIS Bramblebun currently has 31. Writing current HP onto shared species
## data is the bug that makes every creature of a species share a health bar,
## and it is much easier to avoid now than to unpick later.
##
## No nodes, so it is testable headlessly and so the same instance can outlive
## the scene node that draws it — which is what M4's party will need.

const MATH := preload("res://scripts/combat/combat_math.gd")

var species_id: String = ""
var display_name: String = ""
var pal_type: String = "ground"

## What the player called it, or empty for "it kept its species name".
##
## Empty rather than a copy of `display_name` on purpose. GAME_DESIGN.md 10:
## "New captures can keep species name by default" — and a party screen has to
## be able to tell a Terrapup the player never renamed from one they
## deliberately named "Terrapup". Copying the species name in would erase that
## difference permanently, and the release ceremony needs it.
var nickname: String = ""

var max_hp: float = 1.0
var attack: float = 1.0
var defence: float = 1.0

var hp: float = 1.0
var energy: float = 0.0

## Set once when the creature faints, so the transition can be detected exactly
## once rather than every frame HP happens to be zero.
var fainted: bool = false


static func from_species(id: String, definition: Dictionary) -> RefCounted:
	var instance: RefCounted = (load("res://scripts/pals/pal_instance.gd") as GDScript).new()
	instance.species_id = id
	instance.display_name = str(definition.get("display_name", id))
	instance.pal_type = str(definition.get("type", "ground"))
	instance.max_hp = float(definition.get("base_hp", 100.0))
	instance.attack = float(definition.get("base_attack", 20.0))
	instance.defence = float(definition.get("base_defence", 20.0))
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


func hp_fraction() -> float:
	return 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)


func energy_fraction() -> float:
	var cap := MATH.max_energy()
	return 0.0 if cap <= 0.0 else clampf(energy / cap, 0.0, 1.0)
