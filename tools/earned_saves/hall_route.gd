extends "res://tests/helpers/meadows_earned_hall_segment.gd"

## Earned Sigils/Hall for the C1 chain: the read-only helper
## (`tests/helpers/meadows_earned_hall_segment.gd`) with the same disclosed
## prompt-press handling as `relay_route.gd` (BLOCKERS.md B4): a trainer's real
## Interact can open its dialogue without the arbiter's `activated` signal.
## `_talk()` still requires the exact expected conversation.
const PRESS_TRIES := 3
## B5: after the first Sigil captain the helper walks on with a drained active
## creature (bramblebun 0 HP) and loses the next ordinary wild fight's budget.
## Before each road leg, when the active creature is fainted or under this
## fraction, run the helper's own `_prepare()` (real Satchel revive/potion and
## party-cycle input) first. Disclosed as `between_fight_care`.
const CARE_BELOW_FRACTION := 0.35

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
		# Attempt 2 showed the press does reach the trainer: with nothing
		# reported through the arbiter's `activated` signal, a modal opened a
		# moment later during the re-approach. Give the real press time to
		# open its dialogue; `_talk()` still requires the exact expected
		# conversation to finish, so a wrong provider cannot pass.
		if _activated_id == 0:
			for _frame in 240:
				if _activated_id == expected:
					return true
				if bool(_panel.call("is_open")) and not _fighting():
					_receipt("prompt_press_delayed_dialogue", {"target": str(prompt.get_path()),
						"frames_waited": _frame, "activated_signal": "<none>", "player": _player.global_position})
					return true
				if _fighting() or _activated_id != 0:
					break
				await _tree.physics_frame
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


func _walk_ground(at: Vector2, radius: float = 1.5) -> bool:
	if not _fighting() and INPUT_OWNER.current(_tree) == null:
		var active: RefCounted = (_game.get("party") as RefCounted).call("active")
		if active != null and (bool(active.get("fainted"))
				or float(active.get("hp")) < float(active.get("max_hp")) * CARE_BELOW_FRACTION):
			var before := {"species": str(active.get("species_id")), "hp": float(active.get("hp")),
				"max_hp": float(active.get("max_hp")), "fainted": bool(active.get("fainted"))}
			if not await _prepare():
				return false
			var now: RefCounted = (_game.get("party") as RefCounted).call("active")
			_receipt("between_fight_care", {"before": before, "after": {"species": str(now.get("species_id")),
				"hp": float(now.get("hp")), "max_hp": float(now.get("max_hp"))},
				"potions_left": _count("potion_small"), "revives_left": _count("revive")})
	return await super._walk_ground(at, radius)
