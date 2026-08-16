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

	# R2.2: a broken tool (0 durability) does not count as owned here -- the
	# player has to repair it before it gates a full-yield gather again, the
	# same way not owning it at all would.
	var slot: int = int(inventory.call("find_slot", required))
	var owns_required: bool = slot >= 0 and int(inventory.call("durability_at", slot)) > 0
	if owns_required:
		required_slot = slot

	# A broken tool doesn't count toward "owns a tool, just the wrong one"
	# either -- otherwise a broken axe pays 0 for wood instead of falling
	# back to the bare-handed rate.
	var owns_any_tool := false
	if not owns_required:
		for tool_id in items.call("tool_ids"):
			var owned_slot: int = int(inventory.call("find_slot", str(tool_id)))
			if owned_slot >= 0 and int(inventory.call("durability_at", owned_slot)) > 0:
				owns_any_tool = true
				break

	actual_amount = int(items.call("harvest_yield", item_id, base_amount, owns_required, owns_any_tool))
	return {"amount": actual_amount, "required_slot": required_slot}
