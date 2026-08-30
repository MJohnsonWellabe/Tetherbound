extends RefCounted

## What "rest until morning" DOES, in exactly one place.
##
## This body used to live only in `scripts/build/camp.gd::_on_rest()` /
## `_pass_the_night()`, on the camp the PLAYER builds. T4-REGIONS' audit
## (`ralph/reports/REGION_AUDIT_2026-08-30.md`, "Camps are set dressing")
## measured the consequence: every AUTHORED camp in the Meadows -- `trail_camp`
## with a bed and a lit bonfire, `ranger_camp` with a bed and an anvil,
## `riverwatch_rest` which is literally named "rest" -- was non-interactable
## scenery, because the only rest in the game was bolted to one buildable. The
## world advertised rest spots that could not be used while the real one was
## portable, which taught the player to walk to a camp and be refused.
##
## `scripts/world/rest_point.gd` is the authored-camp side of the fix. It calls
## this. So does `camp.gd`. Two callers, one definition of what a night costs
## and pays, so a change to resting can never again apply to only half the
## camps in the world.
##
## The fade is the same two-node canvas the opening's wake uses, built here
## rather than reached for, because a camp can exist in a world with no
## sequence director.

const FADE_SECONDS := 1.2


## Fade out, pass the night, fade back in.
##
## `host` is any node in the live tree -- it owns the tween and the fade layer,
## and it is where the player search starts. It does NOT have to be a child of
## the world: `_find_player()` walks up.
static func rest(host: Node) -> void:
	var game := host.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return

	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	host.add_child(layer)

	var tween := host.create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: pass_the_night(host, game))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


## The night itself, with no fade around it. Separate so a test (and the
## capture tools) can pass a night without waiting on a tween.
static func pass_the_night(host: Node, game: Node = null) -> int:
	if game == null:
		game = host.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the night cannot pass")
		return 0
	var day := int(game.call("advance_day"))
	# GATEB-FLAGS: `player_slept_at_home`, data/progression/objectives.json's
	# ladder. Set here, on the actual completed rest, not on the interact
	# prompt firing -- the objective asks for the sleep itself, not the
	# attempt to start one.
	#
	# Set from an AUTHORED camp too, deliberately. The flag's id says "home"
	# but the rung it clears reads "Rest at camp and let a creature recover",
	# and a player who walks their injured team out to the trail camp, beds
	# one down and sleeps has done that lesson in full. Clearing the objective
	# only for the buildable would be the same "walk to a camp and be refused"
	# defect in a different costume.
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", "player_slept_at_home")
	# Gate A creature-bed contract: sleep completes only pals physically put
	# to bed. Non-resting party members keep their current HP, which is the
	# meaningful preparation tradeoff the bed is supposed to create.
	game.call("complete_creature_bed_rests")
	# The trainer too -- find them by the vitals they carry.
	var player := _find_player(host)
	if player != null:
		var vitals: RefCounted = player.get("vitals")
		if vitals != null and vitals.has_method("rest"):
			vitals.call("rest")
	# "rest to morning" (R5.1) -- by group rather than a direct reference, so a
	# camp in a scene with no day/night setup (a test scene, say) still rests
	# fine with nothing to reset.
	for look: Node in host.get_tree().get_nodes_in_group("day_cycle"):
		if look.has_method("reset_to_morning"):
			look.call("reset_to_morning")
	# R3.1. "Frequent autosave" -- resting is the natural checkpoint this game
	# already asks the player to return to, the same precedent survival games
	# with a sleep beat use for it.
	game.call("save_game", int(game.call("autosave_slot")))
	print("[rest] rested; day %d" % day)
	return day


## The trainer, from anywhere in the world's subtree.
##
## `camp.gd` could read `get_parent().get_node_or_null(^"Player")` because a
## placed camp is a direct child of the world. An authored rest point is three
## levels down (world -> Props -> cluster group -> here), so this walks up
## until it finds the ancestor that owns a "Player" child -- the same shape
## `props.gd::_ground_height()` already uses to find `ground_height_at`.
static func _find_player(host: Node) -> Node:
	var node: Node = host
	while node != null:
		var player := node.get_node_or_null(^"Player")
		if player != null:
			return player
		node = node.get_parent()
	return null
