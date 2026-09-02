extends RefCounted

## "Is the build hammer in the player's hand right now?", in one place.
##
## OWNER DIRECTIVE 2026-08-23 §3, "Build wins while the hammer is out": with
## the hammer equipped, Build owns the Interact button, and the player's own
## deployed creature stops bidding for it. Three files need that same question
## -- the two providers that stand down (`riding_controller.gd`,
## `encounter_director.gd`) and the HUD that has to relabel what moved
## (`playground_hud.gd`) -- and three copies of `equipped_tool == "hammer"` is
## how one of them silently stops agreeing with the others.
##
## Why it is asked at all, measured rather than assumed
## (`tools/_probe_hammer_gate.gd`, a creature deployed in open meadow):
##
##   RidingController   Ride Meadowhart        d=2.78  prio=0  actionable=true
##   EncounterDirector  Put Meadowhart away    d=0.00  prio=-1 actionable=false
##   WINNER: 'Ride Meadowhart' -> the hammer gate would FORFEIT the interact press
##
## Both of those follow the player, so there is nowhere to stand clear of them:
## a controller player with a rideable creature out could not open Build in the
## open field at all, which is the shape of the owner's original "building
## doesn't work" report. Note which one it actually was -- `archive/ralph/DONE.md`'s
## GATEB-TAIL entry blamed the "Put away" line, but that line is built
## `actionable: false` and `playground_hud.gd::_hammer_opens_the_catalogue()`
## already ignores those. The ride offer is the one that takes the button.
##
## Mounted is deliberately NOT covered: "Dismount" has to keep the button or a
## player who equips the hammer in the saddle is stuck there.

const BUILD_TOOL := "hammer"


static func hammer_is_out(tree: SceneTree) -> bool:
	if tree == null:
		return false
	var game := tree.root.get_node_or_null(^"/root/Game")
	return game != null and str(game.get("equipped_tool")) == BUILD_TOOL
