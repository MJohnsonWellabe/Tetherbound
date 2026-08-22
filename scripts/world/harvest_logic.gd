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
## caller should actually grant (0 means refused: the required tool is not
## the one visibly equipped). `required_slot` is the exact equipped tool's
## inventory slot, which should take `damage_tool()` after a successful hit,
## or -1 when nothing should wear down (refusal, or an ungated resource).
##
## Ownership and equipment are deliberately separate. Tam hands the player a
## set of tools, but carrying an axe in the Satchel must not let a visible
## pickaxe swing chop wood and quietly spend the hidden axe's durability.
static func gather(item_id: String, base_amount: int, inventory: RefCounted, items: RefCounted,
		equipped_tool: String = "") -> Dictionary:
	var required_slot := -1
	var actual_amount := base_amount
	var required: String = str(items.call("gathered_with", item_id))
	if required.is_empty():
		return {"amount": actual_amount, "required_slot": -1}

	if equipped_tool != required:
		return {"amount": 0, "required_slot": -1}

	# The held id still has to name a real, working inventory tool. A stale
	# equipped_tool value after breakage/removal cannot authorize a hit.
	required_slot = tool_slot(equipped_tool, inventory)
	if required_slot < 0:
		return {"amount": 0, "required_slot": -1}

	actual_amount = int(items.call("harvest_yield", item_id, base_amount, true, false))
	return {"amount": actual_amount, "required_slot": required_slot}


## Should this gather spot answer an INTERACT press with a visible tool swing
## rather than yielding on the spot?
##
## OP21-24, reopened by the 2026-08-21 owner playtest and still true on
## `main`: "the owner still does not see a convincing chopping swing during
## normal gathering." CONTROLLER-MAP is why. It took the pad button off
## `use_tool` -- correctly, per the owner's own map, where X/`interact` is what
## chops and mines -- but `use_tool` is the ONLY input that ever called
## `tool_hold.gd::swing()`. So on a controller the axe never swung: X ran the
## interact prompt, which credits the satchel and prints "+3 Wood" directly.
## The swing was not removed, it was made unreachable by the device the game
## is played on.
##
## The fix is not a second swing path. It is to make the prompt press START
## the swing and let `tool_hold.gd::_resolve_swing()` land the gather through
## `gather()` -- the same one implementation the mouse already drives, so a
## swing and a press still cannot disagree about yield, tool gating,
## durability or respawn.
##
## Returns true only when the swing will actually reach `node`. A press that
## started an animation resolving against nothing would be strictly worse than
## the silent yield it replaced, so the caller keeps its direct-gather path for
## bare hands, for the wrong tool, and for a node outside the swing's own cone.
static func swing_answers_the_prompt(node: Node3D, game: Node) -> bool:
	if node == null or game == null:
		return false
	if str(game.get("equipped_tool")).is_empty():
		return false
	var player := game.call("find_player") as Node3D
	if player == null:
		return false
	var hold: Node3D = player.get("tool_hold")
	if hold == null or not hold.has_method("swing") or not hold.has_method("would_connect"):
		return false
	if bool(hold.call("is_swinging")):
		# Already mid-swing: that swing resolves on its own and will gather
		# this node itself. Yielding here as well would double the press.
		return true
	if not bool(hold.call("would_connect", node)):
		return false
	return bool(hold.call("swing"))
