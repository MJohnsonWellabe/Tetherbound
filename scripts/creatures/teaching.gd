extends RefCounted

## R4.4: whether a creature may learn a found TM's move, and applying it.
##
## Deliberately not a method on creature_instance.gd or tm_db.gd -- it reads
## both a TM definition and a move definition to decide the slot, which
## neither of those files knows about the other to do alone. Same reason
## progression.gd sits apart from creature_instance.gd's own progression
## calls: the rule is data-shaped, so it is easiest to read and test as a
## pure function over the data, not a method on either side of it.

## True if `creature_type` (a data/creatures/species.json `type` value) is on
## the TM's own compatibility list. GAME_DESIGN.md 13: "Species have
## compatibility lists" -- there is no other rule.
static func can_learn(creature_type: String, tm_id: String, tms: RefCounted) -> bool:
	if not bool(tms.call("has", tm_id)):
		return false
	return bool(tms.call("is_compatible", tm_id, creature_type))


## Writes the TM's move onto `creature` in whatever slot moves.json says that
## move actually occupies -- reading the slot from the move's own data rather
## than trusting the TM entry to get it right means a mis-tagged TM cannot
## silently overwrite the wrong move. Returns false and changes nothing on
## any failure (unknown TM, incompatible species, unknown or unslotted move)
## so a caller never has to check "did this half-apply".
static func teach(creature: RefCounted, tm_id: String, tms: RefCounted, moves: RefCounted) -> bool:
	var creature_type := str(creature.get("creature_type"))
	if not can_learn(creature_type, tm_id, tms):
		return false

	var move: String = str(tms.call("move_id", tm_id))
	if not bool(moves.call("has", move)):
		return false

	var slot: String = str(moves.call("slot", move))
	if slot == "quick":
		creature.set("move_quick", move)
		return true
	if slot == "charged":
		creature.set("move_charged", move)
		return true
	return false
