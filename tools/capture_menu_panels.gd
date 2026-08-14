extends SceneTree

## Capture the backpack and build tabs for the EV9-remainder blind-judge pass
## (inventory grid + crafting panel re-skinned onto playground_hud.gd's dark
## blue-gray/teal panel language, bible §16).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_menu_panels.gd
##
## Three frames:
##   menu_backpack      - the backpack tab, grid + detail panel
##   menu_build         - the build tab, catalogue list + detail panel
##   menu_target_picker - OF2's new item-target picker, mid-flow (backpack tab
##                        with the picker open over an injured party member)

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 8


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload not in the tree")
		quit(1)
		return
	var menu: Node = game.call("menu")
	if menu == null:
		push_error("autoload did not stand up the menu")
		quit(1)
		return

	# A stocked satchel and a couple of buildables, so the panels shown are not
	# just empty rows — the critic needs to judge the panel treatment against
	# real contents, the same way it would in a played build.
	var inventory: RefCounted = game.get("inventory")
	var party: RefCounted = game.get("party")
	if party != null and int(party.call("size")) == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup")
		if creature != null:
			party.call("add", creature)
	if inventory != null:
		inventory.call("add", "orb_basic", 3)
		inventory.call("add", "potion_small", 2)
		inventory.call("add", "wood", 12)
		inventory.call("add", "stone", 5)
		inventory.call("add", "fiber", 20)
		inventory.call("add", "berries", 4)

	var written: Array[String] = []
	var failures: Array[String] = []

	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_backpack", written, failures)

	# open() is a no-op while the menu is already open (game_menu.gd's own
	# guard) -- switching tabs mid-session needs close() first, or the second
	# shot silently repeats the first tab.
	menu.call("close")
	menu.call("open", "build")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_build", written, failures)

	menu.call("close")
	menu.call("open", "backpack")
	for i in POSE_FRAMES:
		await process_frame
	# Injure whoever is in slot 1 so the picker's HP readout has something to
	# show besides a flat full bar, then drive the real Use path -- inject
	# the actual `interact` action rather than calling a private method, so
	# this frame shows what a player's press really produces.
	var backpack: Node = menu.get("_bodies")[0]
	var target: RefCounted = party.call("at", 1) if party != null and int(party.call("size")) > 1 else null
	if target != null:
		target.set("hp", float(target.get("max_hp")) * 0.4)
	var slot: int = int(inventory.call("find_slot", "potion_small")) if inventory != null else -1
	if slot >= 0:
		(backpack.get("_buttons")[slot] as Button).grab_focus()
		var event := InputEventAction.new()
		event.action = "interact"
		event.pressed = true
		Input.parse_input_event(event)
		Input.action_press("interact")
		await process_frame
		await process_frame
		Input.action_release("interact")
		event.pressed = false
		Input.parse_input_event(event)
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("menu_target_picker", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-16s -> %s" % [name, path])
