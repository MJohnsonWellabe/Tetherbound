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


static func rest(creature: RefCounted, cfg: Dictionary) -> void:
	if creature == null:
		return
	creature.call("heal_fully")
	var bonus := PROGRESSION.rest_xp(cfg)
	if bonus > 0:
		creature.call("gain_xp", bonus, cfg)
