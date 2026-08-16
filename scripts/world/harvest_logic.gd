extends RefCounted

## The tool/durability gating a gather spot runs before it grants anything.
##
## Pure and shared: `harvest_node.gd`'s ~10 authored tutorial spots and R2.3's
## world-vegetation gather points (`vegetation_harvest_point.gd`) both spend a
## resource the same way and neither should carry a second copy of R2.2's
## durability rules to drift out of sync with the other.

## Every gather spot in the world, whichever of the two kinds it is.
##
## Added so a tool swing (`scripts/player/tool_hold.gd`) can find what is in
## front of the trainer without knowing which script drew it. The interact
## prompt never needed this -- `interaction_arbiter.gd` already tracks every
## registered `Interactable` -- but a swing has to pick out gather spots
## specifically, and swinging an axe at Grandpa should do nothing at all.
##
## Members are expected to expose `gather()`; both kinds do.
const GROUP := "harvestable"


## The satchel slot holding a WORKING `tool_id`, or -1.
##
## R2.2's rule, in one place: a broken tool (0 durability) does not count as
## owned -- the player has to repair it before it gates anything again, the
## same way not owning it at all would.
##
## Pulled out of `gather()` below for R7.6, which needed the identical
## question about the hoe for a verb that is not a gather at all (tilling a
## farm plot, `scripts/world/farm_plot.gd`). Copying the two-line
## find_slot/durability_at pair into a fourth file is exactly how the R2.2
## durability rule would drift out of sync with itself, which is the failure
## this file's own header was written to prevent.
static func tool_slot(tool_id: String, inventory: RefCounted) -> int:
	if tool_id.is_empty():
		return -1
	var slot: int = int(inventory.call("find_slot", tool_id))
	return slot if slot >= 0 and int(inventory.call("durability_at", slot)) > 0 else -1

## Returns `{"amount": int, "required_slot": int}`. `amount` is what the
## caller should actually grant (0 means refused: wrong tool for a
## tool-gated resource). `required_slot` is the inventory slot that should
## take `damage_tool()` when `amount` came from a full-yield gather with the
## right tool in hand, or -1 when nothing should wear down (bare-handed, or
## the resource is not tool-gated at all).
static func gather(item_id: String, base_amount: int, inventory: RefCounted, items: RefCounted) -> Dictionary:
	var required_slot := -1
	var actual_amount := base_amount
	var required: String = str(items.call("gathered_with", item_id))
	if required.is_empty():
		return {"amount": actual_amount, "required_slot": -1}

	# R2.2's broken-tool rule, via tool_slot() above.
	required_slot = tool_slot(required, inventory)
	var owns_required := required_slot >= 0

	# A broken tool doesn't count toward "owns a tool, just the wrong one"
	# either -- otherwise a broken axe pays 0 for wood instead of falling
	# back to the bare-handed rate.
	var owns_any_tool := false
	if not owns_required:
		for tool_id in items.call("tool_ids"):
			if tool_slot(str(tool_id), inventory) >= 0:
				owns_any_tool = true
				break

	actual_amount = int(items.call("harvest_yield", item_id, base_amount, owns_required, owns_any_tool))
	return {"amount": actual_amount, "required_slot": required_slot}
