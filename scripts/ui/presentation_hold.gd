extends RefCounted

## A story payoff that the world HUD must not talk over (X03, F05 heal).
##
## A node that is playing such a moment (the Meadows heal payoff is the first)
## joins GROUP for as long as it plays and leaves it when done; membership IS
## the hold. While any member exists, the objective beam and the HUD's teaching
## lines (the contextual "Call out ..." prompt and the objective hint card)
## stand down, so a blind judge -- or a player -- sees the land change, not a
## tutorial over it. Nothing else changes: the objective, the tracker line and
## the map marker stay exactly as they were, and they come back the frame the
## last member leaves.
##
## A group, not a flag: it needs no save state, cannot be left stuck by a
## reload (a freed node leaves every group), and the producer needs no
## reference to the HUD.

const GROUP := &"presentation_hold"


static func active(tree: SceneTree) -> bool:
	return tree != null and not tree.get_nodes_in_group(GROUP).is_empty()
