extends RefCounted

## R4.8. What a creature_bed actually does to a party member: heal_fully()
## (which revives a fainted creature -- GAME_DESIGN.md 16/20's own phrase for
## this) plus the same flat rest bonus XP camp.gd's overnight rest already
## grants every party member (progression.gd::rest_xp), reused rather than a
## second number so a creature bed reads as "the same kind of rest, on
## demand" instead of a different mechanic that happens to look similar.
##
## Pure function over a creature instance and the shared progression config
## (D02: pure logic only) -- the caller (creature_bed_panel.gd) owns picking
## WHICH creature, confirming the panel is even open, and any visible
## presentation.

const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")


static func training_config(creature: RefCounted, cfg: Dictionary, personal: Dictionary) -> Dictionary:
	if creature == null: return {}
	var cap := ESSENCE.creature_cap(personal, str(creature.get("uid")))
	if cap < 0 or int(creature.get("level")) > cap: return {}
	var result := cfg.duplicate(true)
	result.level.cap = cap
	return result

static func rest(creature: RefCounted, cfg: Dictionary, personal: Variant = null) -> void:
	if creature == null:
		return
	creature.call("heal_fully")
	var training := training_config(creature, cfg, personal) if personal is Dictionary else cfg
	if training.is_empty(): return # Recovery remains available during reconciliation.
	var bonus := PROGRESSION.rest_xp(training)
	if bonus > 0:
		creature.call("gain_xp", bonus, training)
