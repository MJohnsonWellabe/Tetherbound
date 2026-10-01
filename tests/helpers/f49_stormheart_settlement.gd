extends "res://tests/helpers/stormwood_earned_waterward_handoff.gd"

## Keep actual Stormheart interaction, farewell, grounding and core ring walk.
## F49 never calls the retired Waterward crossing or grants a fifth key.
func _continue_waterward() -> void:
	if not await _drain_exact("stormwood_stormheart_release"):
		return
	var ending := _world.get_node_or_null("StormwoodEnding") as Node3D
	var offer := ending.get_node_or_null("StormheartOffer") as Node3D if ending != null else null
	if offer == null or not await _core_south_ring() or not await _activate_exact(ending, offer,
			Vector2(offer.global_position.x, offer.global_position.z + 2), "Stormheart offer") \
			or not await _drain_exact("stormwood_stormheart_offer") \
			or not await _decline_pending_stormheart():
		return
	if not await _receipt(OFFERED) or not bool(_game.call("player_flags").call("has", SETTLED)):
		_fail("F49 missing producer: actual Stormheart farewell has no durable settlement")
		return
	_complete = true

func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "world": _world,
		"game": _game, "failures": failures.duplicate(), "transcript": transcript.duplicate(),
		"endpoint": "earned Stormheart farewell; retained Stormwood, before Home Key input"}
