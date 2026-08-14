extends SceneTree

## Small standalone re-capture for frames that went missing from a prior
## batch, using the same boot-real-world-then-screenshot idiom as
## `tools/capture_menu_panels.gd` and `tools/capture_minimap.gd`.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_refresh.gd
##
## One frame today:
##   creatures_tab - the pause menu's Creatures tab (`scripts/ui/tab_creatures.gd`), a full
##              5-creature party (the hard cap — D-rules, one human, five creatures) so
##              the roster list, not just an empty/one-creature state, is what
##              gets judged.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 8

## A spread of species (not five of the same one) so the roster actually
## reads as a party rather than a single card repeated.
const PARTY_SPECIES := [
	"terrapup", "ripplet", "galewisp", "bramblebun", "mudsnout",
]


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

	var party: RefCounted = game.get("party")
	if party != null:
		for species_id: String in PARTY_SPECIES:
			if int(party.call("size")) >= 5:
				break
			var creature: RefCounted = game.call("make_creature", species_id)
			if creature != null:
				party.call("add", creature)

	var written: Array[String] = []
	var failures: Array[String] = []

	menu.call("open", "creatures")
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("creatures_tab", written, failures)

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
