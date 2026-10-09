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

## A story/camp consumer may call this without Game's overnight wrapper.
## Preserve the exact frozen owner projection through BOOL-save and ACK retry.
static func recovery_allowed(creature: RefCounted, owner: Node = null) -> bool:
	if owner == null:
		var tree := Engine.get_main_loop() as SceneTree
		owner = tree.root.get_node_or_null("Game") if tree != null and tree.root != null else null
	if owner == null: return true # Detached pure recovery retains its supplied cap.
	var player: RefCounted = owner.get("local")
	var party: RefCounted = player.get("party") if player != null else null
	if party == null or not (party.call("members") as Array).has(creature): return true
	var session: Node = owner.get("session")
	return session == null or not session.has_method("_owner_training_mutation_blocked") \
		or session.call("_owner_training_mutation_blocked", player) != true


static func rest(creature: RefCounted, cfg: Dictionary, personal: Variant = null, owner: Node = null) -> void:
	if creature == null or not recovery_allowed(creature, owner):
		return
	creature.call("heal_fully")
	var training := training_config(creature, cfg, personal) if personal is Dictionary else cfg
	if training.is_empty(): return # Recovery remains available during reconciliation.
	var bonus := PROGRESSION.rest_xp(training)
	if bonus > 0:
		creature.call("gain_xp", bonus, training)
