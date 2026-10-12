extends "res://tests/helpers/stormwood_earned_aftermath_segment.gd"

## Reload re-proof for the Stormwood finale (coordinator, 2026-10-12): a player
## who beats Marrow, then saves and quits before answering the Stormheart,
## must find the offer again on load. stormwood_ending.gd opens the narrative
## `stormwood_stormheart_release` dialogue only on the live release event, so a
## loaded world cannot replay it. In its place this piece asserts the durable
## release a loaded player actually meets: the freed flag, a visible Stormheart
## and an enabled `StormheartOffer` prompt. Everything after that is the
## unchanged aftermath path (walk, ordinary prompt input, offer dialogue,
## accept at five, ceremony, saved settlement receipts, Waterward view).

func _drain_exact(id: String) -> bool:
	if id != "stormwood_stormheart_release":
		return await super._drain_exact(id)
	var ending := _world.get_node_or_null("StormwoodEnding") as Node3D
	if ending == null:
		return _fail("loaded world has no StormwoodEnding")
	for _frame in 300:
		await _tree.process_frame
	var progression: RefCounted = _game.get("progression")
	if progression == null or not bool(progression.call("has", "stormwood:legendary_freed")) \
			or not bool(progression.call("has", "stormwood:marrow_defeated")):
		return _fail("loaded save lacks the durable Marrow defeat / Stormheart release")
	if bool(progression.call("has", OFFERED)):
		return _fail("the Stormheart offer was already answered before this reload proof")
	var offer := ending.get_node_or_null("StormheartOffer") as Node3D
	var legendary: Node3D = ending.get("_legendary")
	if offer == null or not bool(offer.get("enabled")):
		return _fail("after load the Stormheart offer prompt is not enabled (finale soft-lock)")
	if legendary == null or not legendary.visible:
		return _fail("after load the freed Stormheart is not visible")
	_note("RELOAD: durable release restored after load (freed, offer prompt enabled, Stormheart visible); the narrative release line plays only live")
	return true
