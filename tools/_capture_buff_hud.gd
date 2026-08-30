extends SceneTree

## T3-INSTALL, B1. Render evidence that a creature holding an active tonic
## buff shows a persistent HUD tell, not just the one-time "drank the tonic"
## toast. Boots the real Meadows world (same pattern
## `tests/smoke_creature_control.gd` uses) so the HUD is laid out by its own
## real `_ready()` against a real viewport/player, then calls the real
## `creature_instance.gd::apply_buff()` on the real active party member
## before capturing.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_buff_hud.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const OUT := "res://ralph/reports/T3-INSTALL/shots/buff_hud.png"

const SETTLE_FRAMES := 300


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))

	var world := (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var director := world.get_node_or_null(^"EncounterDirector")
	var game := root.get_node_or_null(^"/root/Game")
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	if director == null or game == null or hud == null:
		print("FAIL: scene is missing the director, Game autoload, or PlaygroundHUD")
		quit(1)
		return

	var party: RefCounted = game.get("party")
	var frostclaw: RefCounted = SPECIES.spawn("frostclaw")
	if frostclaw == null or not bool(party.call("add", frostclaw)):
		print("FAIL: could not seed the party with a frostclaw")
		quit(1)
		return
	if director.call("ally_instance") == null:
		await director.call("summon_active_creature")
		for i in 60:
			await physics_frame

	# Two buffs at once: exercises the chip row AND (with max_visible_icons
	# still at its shipped default of 3) leaves room to see it is NOT
	# spuriously showing an overflow "+N" for just two.
	frostclaw.call("apply_buff", "tonic_might", "attack", 1.25, 42.0)
	frostclaw.call("apply_buff", "tonic_iron", "defence", 1.15, 8.0)

	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("no image")
		quit(1)
		return
	# The active-companion block sits top-left of the HUD; crop tight.
	var crop := image.get_region(Rect2i(0, 0, 460, 300))
	crop.save_png(OUT)
	print("wrote %s" % OUT)
	var buffs: Array = frostclaw.get("active_buffs")
	print("frostclaw has %d active buff(s): %s" % [buffs.size(), buffs])
	quit(0)
