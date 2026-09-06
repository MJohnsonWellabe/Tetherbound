extends RefCounted

## D102 -- MENUS NEVER PAUSE A MULTI-PEER SESSION.
##
## `docs/decisions/D102-menus-never-pause-a-multi-peer-session.md`, from
## `docs/MULTIPLAYER_DIRECTIVE.md` §13. Six panels open a modal surface over a
## live world -- `craft_panel`, `storage_panel`, `swap_panel`, `game_menu`,
## `creature_bed_panel`, `shop_panel` -- and every one of them used to do it by
## setting `get_tree().paused = true`. Solo that is exactly right. In a session
## it is one player stopping everybody else's world, which is the thing §13
## forbids by name.
##
## So the pause became conditional, in ONE place, and this is it:
##
##     PAUSE.hold(get_tree())      # instead of get_tree().paused = true
##     PAUSE.release(get_tree())   # instead of get_tree().paused = false
##
## ## Why the world does not run away from the player who opened the panel
##
## Nothing here suppresses that player's world verbs, and nothing here needs
## to. `input_owner.gd`'s group already does it, and has since OW10: every
## world-verb poll in the game (`player_controller.gd`, `interaction_arbiter.gd`,
## `build_placer.gd`, `playground_hud.gd`) asks `INPUT_OWNER.current(get_tree())`
## first and stands down while any panel owns the screen. `build_menu.gd` is the
## proof it works on a LIVE world: it is the one panel that deliberately never
## paused, and it has always relied on exactly this. D102's whole argument is
## that the multi-peer path reuses that mechanism rather than inventing a
## second gate.
##
## ## Where this lives, and why it is not `Session.pause_local()`
##
## D102 names the entry point `Session.pause_local(bool)`. It is here instead
## because `scripts/net/session.gd` was owned by another lane for the whole of
## the run that closed acceptance item 16, and two lanes editing one file
## concurrently is how a merge silently drops one of them. The contract is
## byte-for-byte D102's; only the address changed. `pause_local()` below is the
## same call under D102's own name, so a reader who greps for the decision
## finds the code.
##
## Moving it onto `Session` later is a pure rename: this file asks
## `Game.is_multi_peer()`, which is `session.gd::is_multi_peer()` with a null
## guard, so the answer is already the session's.
##
## ## Asking the session, never `multiplayer`
##
## `multiplayer.is_server()` is **true** and `get_unique_id()` is **1** under
## Godot's default `OfflineMultiplayerPeer`, so a process with no session at all
## looks exactly like a host to that API. Every question here goes through
## `Game.is_multi_peer()` -> `session.gd::is_multi_peer()` -> `peer_count() > 1`,
## which is false solo, false before the session node exists, and false for a
## one-peer session -- the last of those being D102's "solo IS a one-peer
## session through the same funnel" (acceptance row 23).


## Pause the tree, but only if pausing it would stop nobody but this player.
## Returns true if the tree was actually paused, so a caller that wants to say
## which of the two worlds it is in can.
static func hold(tree: SceneTree) -> bool:
	if tree == null or is_multi_peer(tree):
		return false
	tree.paused = true
	return true


## Release the pause. UNCONDITIONAL, and deliberately so: this is byte-for-byte
## what the six panels did before D102, including RG1's rule that release is
## decided by the live ownership graph rather than by a cached pause bit. In a
## session the tree was never paused and this is a no-op; solo it is the only
## thing that gives the world back.
static func release(tree: SceneTree) -> void:
	if tree == null:
		return
	tree.paused = false


## D102's own name for the pair, for a caller that has the bool already.
static func pause_local(tree: SceneTree, want: bool) -> bool:
	if want:
		return hold(tree)
	release(tree)
	return false


## Is somebody else in this session? False solo, false before `Game` exists,
## and false in a one-peer session. See the header on why this is never asked
## of `multiplayer`.
static func is_multi_peer(tree: SceneTree) -> bool:
	if tree == null or tree.root == null:
		return false
	var game := tree.root.get_node_or_null(^"Game")
	if game == null or not game.has_method("is_multi_peer"):
		return false
	return bool(game.call("is_multi_peer"))
