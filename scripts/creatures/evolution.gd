extends RefCounted

## R4.6, D13/D17/D20: the Meadows' one evolution line (Mudsnout -> Tuskroot) as
## a real system, not just the two dangling `evolves_into`/`evolves_from`
## fields D20 left behind ("the evolution system itself remains unbuilt,
## deliberately... until it lands a caught Mudsnout simply stays a Mudsnout").
##
## Deliberately not a method on creature_instance.gd -- like teaching.gd, this
## reads BOTH a species definition (creature_species.gd) and a live instance
## to decide eligibility, and the gate numbers are genuinely data
## (data/config/progression.json's `evolution` block, keyed by the
## PRE-evolution species id), the same split progression.gd already draws
## between pure arithmetic and the instance that owns state.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")


## The evolution requirement for `species_id`, or {} if this species does not
## evolve, or has no requirement configured yet (a species.json link with no
## matching progression.json entry -- not expected for the shipped roster,
## but a caller should read "no requirement" as "cannot evolve", never crash
## on a missing key). `target` is folded into the returned dict so a caller
## never has to re-read species.json to learn what it evolves into.
static func requirements(species_id: String, cfg: Dictionary) -> Dictionary:
	var definition := SPECIES.definition(species_id)
	if not definition.has("evolves_into"):
		return {}
	var target := str(definition["evolves_into"])
	if not SPECIES.has(target):
		return {}
	var req: Variant = cfg.get("evolution", {}).get(species_id)
	if not (req is Dictionary):
		return {}
	var out: Dictionary = (req as Dictionary).duplicate()
	out["target"] = target
	return out


## Eligibility for THIS live creature. `inventory` is optional -- null reads
## as "no item available", the safe direction for a caller (a pure-logic
## test) that has none in hand -- and is only ever consulted when the
## requirement actually names an `item_id`. Never mutates anything; `evolve()`
## below is the only function here that does.
static func check(creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null) -> Dictionary:
	var species_id := str(creature.get("species_id"))
	var req := requirements(species_id, cfg)
	if req.is_empty():
		return {"eligible": false, "target": "", "reason": "%s does not evolve." % str(creature.call("label"))}

	var target := str(req.get("target", ""))
	var level_needed := int(req.get("level", 0))
	var bond_needed := int(req.get("bond", 0))
	var item_id := str(req.get("item_id", ""))

	if int(creature.get("level")) < level_needed:
		return {
			"eligible": false, "target": target,
			"reason": "%s needs to reach level %d first (currently %d)." % [
				str(creature.call("label")), level_needed, int(creature.get("level"))
			],
		}
	if int(creature.get("bond")) < bond_needed:
		return {
			"eligible": false, "target": target,
			"reason": "%s needs a stronger bond first." % str(creature.call("label")),
		}
	if item_id != "" and (inventory == null or int(inventory.call("count", item_id)) < 1):
		return {
			"eligible": false, "target": target,
			"reason": "%s needs a %s to evolve." % [str(creature.call("label")), item_id.capitalize()],
		}
	return {"eligible": true, "target": target, "reason": ""}


## Apply an eligible evolution: consumes the item (if the requirement names
## one) and mutates `creature` in place via its own `evolve_into`. Returns
## false and changes nothing on any refusal -- re-validated here rather than
## trusted from an earlier `check()`, the same defensive shape
## `teaching.teach()` uses, so a caller cannot evolve a creature by racing a
## stale eligibility read (an item spent elsewhere between the two calls, say).
static func evolve(creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null) -> bool:
	var result := check(creature, cfg, inventory)
	if not bool(result.get("eligible", false)):
		return false

	var req := requirements(str(creature.get("species_id")), cfg)
	var item_id := str(req.get("item_id", ""))
	if item_id != "":
		if inventory == null or not bool(inventory.call("remove", item_id, 1)):
			return false

	var target := str(req.get("target", ""))
	creature.call("evolve_into", target, SPECIES.definition(target), cfg)
	return true
