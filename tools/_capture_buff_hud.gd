extends SceneTree

## T3-INSTALL, B1. Render evidence that a creature holding an active tonic
## buff shows a persistent HUD tell, not just the one-time "drank the tonic"
## toast. Instantiates the real `scenes/ui/playground_hud.tscn` (not the bare
## script -- the script's `_ready()` expects the `.tscn`'s own child nodes
## via `@onready`, and a bare `PLAYGROUND_HUD.new()` has none of them, which
## is why a first attempt at this render came back blank) so the whole panel
## lays itself out for real, then drives it with a real `party.gd` holding a
## real `creature_instance.gd` that `apply_buff()` is actually called on.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_buff_hud.gd

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const OUT := "res://ralph/reports/T3-INSTALL/shots/buff_hud.png"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.13, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var hud: CanvasLayer = (load(HUD_SCENE) as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	# `playground_hud.gd::_refresh_game_ref()` re-reads `_party` off the real
	# `/root/Game` autoload every frame, overwriting anything set directly on
	# the HUD -- so the party has to be seeded on Game, not on the HUD.
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		print("FAIL: no Game autoload in this SceneTree")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	var frostclaw: RefCounted = SPECIES.spawn("frostclaw")
	if frostclaw == null or party == null or not bool(party.call("add", frostclaw)):
		print("FAIL: could not seed Game.party with a frostclaw")
		quit(1)
		return

	# Two buffs at once: exercises the chip row AND (with max_visible_icons
	# still at its shipped default of 3) leaves room to see it is NOT
	# spuriously showing an overflow "+N" for just two.
	frostclaw.call("apply_buff", "tonic_might", "attack", 1.25, 42.0)
	frostclaw.call("apply_buff", "tonic_iron", "defence", 1.15, 8.0)

	for i in 20:
		await process_frame
	# `_reflow_left_stack()` only repositions the creature block/party strip
	# ONCE, the frame it first sees a real canvas size -- forcing one more
	# pass here after the party/buffs are seeded makes sure this capture
	# isn't looking at a stale first-frame layout.
	hud.call("_reflow_left_stack")
	for i in 10:
		await process_frame

	# `playground_hud.gd::_yield_left_stack_to_combat_hud()` forces
	# `_party_strip.visible = true` unconditionally every frame whenever no
	# fight is running, and its own next line hides `_creature_block`
	# whenever the strip reads visible -- the two panels are deliberately
	# mutually exclusive (single companion vs. full roster). Seeding the
	# party here reveals the strip once, and from then on the two fight over
	# `.visible` every frame, with the strip always winning (it runs last).
	# That interaction predates this lane and is not part of what this
	# screenshot verifies -- the buff row lives entirely inside
	# `_creature_content`, a child of `_creature_block`, and does not itself
	# touch that fight. `await RenderingServer.frame_post_draw` still lets at
	# least one more full `_process()` tick run before the signalled frame is
	# actually drawn (confirmed: a plain `.visible` write just before
	# awaiting it still lost that race), so the HUD's own processing has to
	# be stopped for a forced value to survive into the captured frame --
	# this puts both panels in the state a normal walk-around moment (no
	# roster open, no fight) would actually show, for this one screenshot.
	var block: Control = hud.get("_creature_block")
	var party_strip: Control = hud.get("_party_strip")
	hud.set_process(false)
	if party_strip != null:
		party_strip.visible = false
	if block != null:
		block.visible = true
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("no image")
		quit(1)
		return
	image.save_png(OUT)
	print("wrote %s" % OUT)
	var buffs: Array = frostclaw.get("active_buffs")
	print("frostclaw has %d active buff(s): %s" % [buffs.size(), buffs])
	quit(0)
