extends "res://tests/helpers/meadows_earned_bridge_segment.gd"

## Earned South Bridge crossing for the C1 chain. It is the unchanged read-only
## helper (`tests/helpers/meadows_earned_bridge_segment.gd`): the route, the
## village-side locked-gate press, the guardian dialogue, the real piloted
## fight, the durable-unlock/key receipt and the ordinary walk to the far bank.
## Only the post-victory gate press is different.
##
## Why (tools/earned_saves/BLOCKERS.md B1): after the guardian win, main
## 10b635d38 leaves the defeated grunt's stale battle offer in the arbiter
## (`[village] 'south_bridge_grunt' offered a battle that could not start`, a
## Meadows defect that stands). The helper then asserts that the gate owns the
## interact prompt, although ordinary play has already opened the bridge
## (`south_bridge_open` set, key spent). The coordinator's ruling:
##   * the gate is already open by ordinary play: skip the prompt, and let the
##     helper walk across with normal stick input; a receipt discloses the
##     bypassed assertion;
##   * the gate is still closed: press Interact only when the real arbiter's
##     actionable winner is the gate itself; anything else is a real blocker.
## Nothing here writes a flag, moves a body or spends an item.
const POST_WIN_SETTLE_FRAMES := 180


func _press_gate(prompt: Node3D) -> bool:
	if not _has("defeated_south_bridge_grunt"):
		return await super._press_gate(prompt)
	for _frame in POST_WIN_SETTLE_FRAMES:
		await _tree.process_frame
		if bool(_bridge.call("is_open")) and _has("south_bridge_open"):
			_receipt("gate_prompt_assertion_bypassed", {
				"reason": "south_bridge_open already set by ordinary play after the guardian win; "
					+ "the helper's 'gate must own the interact prompt' assertion is not applied",
				"stale_offer_defect": "'south_bridge_grunt' offered a battle that could not start (Meadows defect, open)",
				"winning_provider": str(_arbiter.call("winning_provider")),
				"key_remaining": _count(KEY)})
			return true
		if bool(_arbiter.call("enabled")) and _arbiter.call("winning_provider") == prompt \
				and bool(_arbiter.call("winner").get("actionable", false)):
			_receipt("gate_pressed_after_win", {"key_before": _count(KEY)})
			await _tap("interact")
			return true
	var winner: Variant = _arbiter.call("winning_provider")
	return _fail("After the guardian win the gate is still closed and the arbiter offers %s (%s), not the gate" % [
		str(winner.get_path()) if winner is Node else str(winner), str(_arbiter.call("winner"))])
