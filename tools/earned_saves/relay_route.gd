extends "res://tests/helpers/meadows_earned_relay_segment.gd"

## Earned Relay/Mill for the C1 chain: the read-only helper
## (`tests/helpers/meadows_earned_relay_segment.gd`) with one change to its exact
## prompt press (tools/earned_saves/BLOCKERS.md B4). On main 10b635d38 the
## helper's first Interact at the Relay (Captain Vance) did not activate the
## offered provider (attempt 1, seed 4). The helper treats any mismatch as final.
## This variant keeps the exact-provider requirement but, when the press
## activated nothing, or activated a provider that opened no modal and started
## no fight, re-approaches and presses again, up to PRESS_TRIES. Every mismatch
## is disclosed as a `prompt_press_retry` receipt naming what was activated.
## A mismatch that opened a modal or a fight is still a hard failure.
const PRESS_TRIES := 3

var _activated_path := ""


func _on_activated(provider: Object) -> void:
	super._on_activated(provider)
	_activated_path = str((provider as Node).get_path()) if provider is Node and is_instance_valid(provider) else str(provider)


func _press_prompt(prompt: Node3D) -> bool:
	for attempt in PRESS_TRIES:
		if not await _approach_prompt(prompt):
			return false
		var expected := prompt.get_instance_id()
		_activated_id = 0
		_activated_path = ""
		await _input._tap("interact")
		if _activated_id == expected:
			return true
		var side_effect := INPUT_OWNER.current(_tree) != null or _fighting() or bool(_panel.call("is_open"))
		_receipt("prompt_press_retry", {"attempt": attempt + 1, "target": str(prompt.get_path()),
			"activated": _activated_path if _activated_id != 0 else "<nothing>", "side_effect": side_effect,
			"player": _player.global_position})
		if side_effect:
			return _fail("Physical Interact activated %s (not the offered target) and it opened a modal or fight" % _activated_path)
		for _frame in 20:
			await _tree.physics_frame
	return _fail("Physical Interact never activated the exact offered target in %d ordinary presses" % PRESS_TRIES)
