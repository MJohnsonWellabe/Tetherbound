extends RefCounted

## One answer to "who owns input right now", asked of a group.
##
## OW10, from the owner: *"if I have a menu up and hit a dpad button, it still
## reads the hot bar control not to the menu. it tries to use a potion or
## whatever rather than move on the menu."*
##
## The pause shell is NOT the leak, and that was measured before this existed:
## `game_menu.gd::open()` pauses the tree and `PlaygroundHUD` inherits
## `PROCESS_MODE_PAUSABLE`, so `_read_hotbar_input` does not run at all while it
## is up — a real `hotbar_2` press with the backpack open left the potion count
## unchanged. Six panels pause the tree the same way (`craft_panel`,
## `storage_panel`, `swap_panel`, `game_menu`, `creature_bed_panel`,
## `shop_panel`) and none of them can leak either.
##
## `build_menu.gd` is the one that does. It deliberately does not pause — the
## world stays live behind it, which is the whole Valheim feel it is built for —
## so the HUD keeps polling underneath it. `hotbar_2`/`hotbar_3`/`hotbar_4` are
## bound to d-pad left/right/down (project.godot: joypad buttons 13/14/12),
## which is the same physical d-pad Godot's `ui_left`/`ui_right`/`ui_up`/
## `ui_down` drive grid focus with. So one d-pad press both moved the selection
## and ate whatever sat in that satchel slot.
##
## The reason this needs a shared answer rather than one more `if` is that the
## HUD was already carrying two ad-hoc gates (a fight in progress, and the
## interaction arbiter's modal flag), plus a third hand-written
## `_build_menu_is_open()` special case on ONE of its two polls and not the
## other — which is exactly why the hotbar leaked while the world hotkeys did
## not. A fourth non-pausing panel would have brought a fourth gate and the same
## chance of being wired into one caller and forgotten in the next.
##
## So: a panel that owns input while it is up joins `GROUP`, and every
## world-verb poll asks `current()`. Joining the group is the entire contract —
## there is nothing to remember to call, and nothing per-caller to keep in sync.
## Panels that pause the tree may join too and cost nothing, since a paused tree
## has already stopped the pollers.

## Panels that own input while open join this. Named as a group rather than
## kept as a list here so this file never has to know what panels exist.
const GROUP := &"input_owner"


## The panel currently owning input, or null if the world has it.
##
## Returns the node rather than a bool so a caller that wants to say WHICH
## surface has input (a debug readout, a refusal message) can, without a second
## lookup. Callers that only want the gate compare against null.
##
## Asked of the group rather than of any particular node, the same way
## `game_menu.gd::_story_modal_open` asks `STORY_MODAL_GROUP`: a panel that is
## not in the current scene — every headless test that never loads a world —
## contributes nothing instead of erroring.
static func current(tree: SceneTree) -> Node:
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(GROUP):
		if _owns(node):
			return node
	return null


## A controller B press that closes one surface must not also open the pause
## shell on the same input edge. Panels and live build placement call this
## before releasing their state; centralising the lookup keeps every modal on
## the same lifecycle contract and makes process order irrelevant.
static func suppress_pause_reopen(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var game := tree.root.get_node_or_null(^"Game")
	var menu: Node = game.call("menu") if game != null and game.has_method("menu") else null
	if menu != null and menu.has_method("suppress_reopen"):
		# If the shell processed this physical edge first it may already have
		# opened. That overlap is never legitimate: the caller still owns the
		# close/cancel edge. Undo it before arming the guard for later process
		# order, making the contract symmetric whichever node ran first.
		if menu.has_method("is_open") and bool(menu.call("is_open")) and menu.has_method("close"):
			menu.call("close")
		menu.call("suppress_reopen")


## Hide or restore every world HUD layer while a modal surface owns the screen.
##
## Two layers, not one. `combat_hud.gd` is mounted beside `PlaygroundHUD` in the
## world scene and draws `encounter_director.gd`'s own prompt line ("Call out
## Biscuit") whenever that director owns the active prompt, fight or no fight --
## so hiding only the exploration HUD leaves that line printing through whatever
## opened over it.
##
## Lives here rather than in each panel because five station panels and the
## pause shell all need the identical answer, and `game_menu.gd` already
## carried a private copy of it that knew about one layer. A sixth surface that
## joins `GROUP` and forgets to call this is the failure this file's own header
## describes for input gates: one caller wired, the next forgotten.
##
## Callers hide on open, and restore inside the same
## `current(tree) == null` branch that releases pause -- restoring on any close
## would re-show the HUD over a panel that is still up when one modal closes on
## top of another.
##
## `build_menu.gd` deliberately does NOT call this. It keeps the world live
## behind it on purpose, and the player needs the hotbar to pick a piece;
## `playground_hud.gd::_yield_bottom_to_build_menu()` already takes away the
## part of the HUD that would collide.
static func set_world_hud_visible(tree: SceneTree, value: bool) -> void:
	if tree == null:
		return
	var world := tree.current_scene
	if world == null:
		return
	for layer_path in [^"PlaygroundHUD", ^"CombatHUD"]:
		var hud := world.get_node_or_null(layer_path)
		if hud != null:
			hud.visible = value


## Does `node` own input at this moment?
##
## `is_open()` first because it is what the panels in this group actually mean —
## `build_menu.gd`, `dialogue_panel.gd`, `name_prompt.gd` and
## `starter_picker.gd` all have one, and all of them keep nodes in the tree that
## are merely invisible rather than freed. Visibility is the fallback for a
## panel that has no such method, so joining the group still does something
## sensible without one.
static func _owns(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_open"):
		return bool(node.call("is_open"))
	if node is CanvasLayer:
		return (node as CanvasLayer).visible
	if node is CanvasItem:
		return (node as CanvasItem).visible
	return false
