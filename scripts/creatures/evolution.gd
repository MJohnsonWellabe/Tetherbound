extends RefCounted

## R4.6, D13/D17/D20: the Meadows' one evolution line (Mudsnout -> Tuskroot) as
## a real system, not just the two dangling `evolves_into`/`evolves_from`
## fields D20 left behind ("the evolution system itself remains unbuilt,
## deliberately... until it lands a caught Mudsnout simply stays a Mudsnout").
##
## D71/T3-SUNSTONE: Mudsnout now branches -- Tuskroot with a Heartstone,
## Ashtusk with a Sunstone -- via `evolves_into_variants` (item_id -> target)
## sitting BESIDE the original single-string `evolves_into`, which stays the
## primary/default path and keeps every pre-existing caller's shape. See
## ralph/reports/SUNSTONE_DESIGN_2026-08-30.md for why a parallel field was
## chosen over turning `evolves_into` itself into a map.
##
## Deliberately not a method on creature_instance.gd -- like teaching.gd, this
## reads BOTH a species definition (creature_species.gd) and a live instance
## to decide eligibility, and the gate numbers are genuinely data
## (data/config/progression.json's `evolution` block, keyed by the
## PRE-evolution species id), the same split progression.gd already draws
## between pure arithmetic and the instance that owns state.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")


## The full set of additional branches `species_id` declares beyond its
## primary `evolves_into`: item_id -> target species id, read from
## `evolves_into_variants` and filtered to targets that actually exist in the
## species table (the same defensive shape `requirements()` already applies
## to the primary target below). {} for a species with no variants, which is
## every species except Mudsnout today.
static func variant_branches(species_id: String) -> Dictionary:
	var definition := SPECIES.definition(species_id)
	var raw: Variant = definition.get("evolves_into_variants", {})
	if not (raw is Dictionary):
		return {}
	var out: Dictionary = {}
	for item_id: String in (raw as Dictionary).keys():
		var target := str((raw as Dictionary)[item_id])
		if SPECIES.has(target):
			out[item_id] = target
	return out


## The evolution requirement for `species_id`, or {} if this species does not
## evolve, or has no requirement configured yet (a species.json link with no
## matching progression.json entry -- not expected for the shipped roster,
## but a caller should read "no requirement" as "cannot evolve", never crash
## on a missing key). `target`/`item_id` are folded into the returned dict so
## a caller never has to re-read species.json to learn what it evolves into,
## and `branches` carries every OTHER catalyst-selected destination so a
## refusal message can name them all.
##
## `inventory` (optional; null reads as "nothing on hand", same direction
## every caller here already reads no-item-available) is what actually picks
## a branch: holding none of the branch items keeps the primary path as the
## reported target (unchanged behaviour for a species like Mudsnout with no
## variants, and the sensible default for one that has them but nothing is
## held yet); holding exactly one swaps `target`/`item_id` to that branch;
## holding more than one sets `ambiguous` rather than silently choosing --
## `check()` turns that into a refusal naming the problem.
static func requirements(species_id: String, cfg: Dictionary, inventory: RefCounted = null) -> Dictionary:
	var definition := SPECIES.definition(species_id)
	if not definition.has("evolves_into"):
		return {}
	var primary_target := str(definition["evolves_into"])
	if not SPECIES.has(primary_target):
		return {}
	var req: Variant = cfg.get("evolution", {}).get(species_id)
	if not (req is Dictionary):
		return {}
	var out: Dictionary = (req as Dictionary).duplicate()
	var primary_item := str(out.get("item_id", ""))
	out["target"] = primary_target

	var branches := variant_branches(species_id)
	out["branches"] = branches
	if branches.is_empty():
		return out

	var held: Array[String] = []
	if primary_item != "" and inventory != null and int(inventory.call("count", primary_item)) >= 1:
		held.append(primary_item)
	for item_id: String in branches.keys():
		if inventory != null and int(inventory.call("count", item_id)) >= 1:
			held.append(item_id)

	if held.size() > 1:
		out["ambiguous"] = true
		out["target"] = ""
		out["item_id"] = ""
	elif held.size() == 1 and held[0] != primary_item:
		out["item_id"] = held[0]
		out["target"] = branches[held[0]]
	# else: nothing held, or only the primary item held -- primary stays as set above
	return out


## Every catalyst item that leads somewhere from `species_id`, primary path
## included, as "Heartstone" / "Sunstone" style names -- used to build a
## refusal message that names the whole fork rather than one branch of it.
static func _catalyst_names(species_id: String, cfg: Dictionary) -> Array[String]:
	var req: Variant = cfg.get("evolution", {}).get(species_id)
	var names: Array[String] = []
	if req is Dictionary:
		var primary_item := str((req as Dictionary).get("item_id", ""))
		if primary_item != "":
			names.append(primary_item.capitalize())
	for item_id: String in variant_branches(species_id).keys():
		names.append(item_id.capitalize())
	return names


## "a Heartstone", "a Heartstone or a Sunstone", "a Heartstone, a Sunstone or
## a Whatever" -- however many catalysts a line ends up with. The shipped
## roster only ever exercises the two-name case.
static func _describe_catalysts(names: Array[String]) -> String:
	if names.is_empty():
		return "an item"
	if names.size() == 1:
		return "a " + names[0]
	var text := "a " + names[0]
	for i in range(1, names.size() - 1):
		text += ", a " + names[i]
	text += " or a " + names[names.size() - 1]
	return text


## Eligibility for THIS live creature. `inventory` is optional -- null reads
## as "no item available", the safe direction for a caller (a pure-logic
## test) that has none in hand -- and is only ever consulted when the
## requirement actually names an `item_id`. Never mutates anything; `evolve()`
## below is the only function here that does.
static func check(creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null) -> Dictionary:
	var species_id := str(creature.get("species_id"))
	var req := requirements(species_id, cfg, inventory)
	if req.is_empty():
		return {"eligible": false, "target": "", "reason": "%s does not evolve." % str(creature.call("label"))}

	var level_needed := int(req.get("level", 0))
	var bond_needed := int(req.get("bond", 0))

	if int(creature.get("level")) < level_needed:
		return {
			"eligible": false, "target": str(req.get("target", "")),
			"reason": "%s needs to reach level %d first (currently %d)." % [
				str(creature.call("label")), level_needed, int(creature.get("level"))
			],
		}
	if int(creature.get("bond")) < bond_needed:
		return {
			"eligible": false, "target": str(req.get("target", "")),
			"reason": "%s needs a stronger bond first." % str(creature.call("label")),
		}
	if bool(req.get("ambiguous", false)):
		return {
			"eligible": false, "target": "",
			"reason": ("%s is ready to evolve, but you're carrying more than one evolution " +
				"stone -- drop one so the choice is deliberate.") % str(creature.call("label")),
		}

	var target := str(req.get("target", ""))
	var item_id := str(req.get("item_id", ""))
	if item_id != "" and (inventory == null or int(inventory.call("count", item_id)) < 1):
		return {
			"eligible": false, "target": target,
			"reason": "%s needs %s to evolve." % [
				str(creature.call("label")), _describe_catalysts(_catalyst_names(species_id, cfg))
			],
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

	var req := requirements(str(creature.get("species_id")), cfg, inventory)
	var item_id := str(req.get("item_id", ""))
	if item_id != "":
		if inventory == null or not bool(inventory.call("remove", item_id, 1)):
			return false

	var target := str(req.get("target", ""))
	creature.call("evolve_into", target, SPECIES.definition(target), cfg)
	return true
