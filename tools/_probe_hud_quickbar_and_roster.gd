extends SceneTree

## GF-B-005 / GF-B-006. The two HUD defects Gate F photographed, on one frame,
## with no world scene behind them.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_probe_hud_quickbar_and_roster.gd -- --out=shots/hud_gfb --tag=after
##
## NEVER `--headless` with a real rendering driver -- see
## `tools/_capture_ui_survey.gd`'s header for the trap and what it has cost.
##
## Why not `_capture_ui_survey.gd`'s `05-hud-exploration`: that frame is the
## right one, but it boots the whole Meadows world to get it, which is minutes
## of llvmpipe per run. These two defects are entirely inside
## `scenes/ui/playground_hud.tscn`, which mounts standalone (every HUD smoke
## test already does it), so a before/after pair costs two short runs instead of
## two long ones. The seeding is `_capture_ui_survey.gd`'s, reduced to what
## these two frames actually read: a five-creature roster and a stocked satchel.
##
## The device is PINNED TO GAMEPAD, for the reason that tool's own
## `_pin_owner_device()` gives at length: under `xvfb-run` no joypad is
## connected, so `game_state.gd` initialises to the keyboard half and the survey
## photographs a device the owner's hardware never presents. GF-B-005 is
## specifically about the d-pad badges, so a keyboard frame would not contain
## the defect at all.
##
## The roster is REVEALED explicitly. It is a transient widget, and after
## GF-B-006 it does not reveal at all for an empty party -- so a frame that
## waited for a natural reveal would photograph nothing and read as a pass.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const PARTY_SPECIES: Array[String] = ["terrapup", "ripplet", "galewisp", "brooktail", "tuskroot"]

var _out_dir := "res://shots/hud_gfb"
var _tag := "frame"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	_read_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	# Autoloads are not in the tree on a `--script` SceneTree's first line; Godot
	# mounts them once the tree starts iterating. Same ordering requirement
	# `_capture_ui_survey.gd`'s header documents having been bitten by.
	for i in 4:
		await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: no Game autoload after 4 frames")
		quit(1)
		return
	_seed(game)
	game.set("_last_input_was_gamepad", true)

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	var hud: Node = packed.instantiate()
	root.add_child(hud)
	for i in 20:
		await process_frame

	var strip := hud.get_node_or_null(^"Root/PartyStrip") as Control
	if strip != null and strip.has_method("set_pinned"):
		# Pinned rather than `show_strip()`: the fade would otherwise expire
		# somewhere inside the settle below and the frame would be a coin toss.
		strip.call("set_pinned", true)
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw

	var img: Image = get_root().get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, _tag]
	img.save_png(path)
	print("wrote %s  (strip visible=%s rect=%s)" % [
		path, ("no strip" if strip == null else str(strip.visible)),
		("-" if strip == null else str(strip.get_global_rect()))])

	var dock := hud.get_node_or_null(^"Root/BottomDock/HotbarPanel") as Control
	if dock != null:
		print("hotbar rect=%s" % dock.get_global_rect())
	quit(0)


func _read_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--tag="):
			_tag = arg.substr(6)


## `_capture_ui_survey.gd::_seed_game_state()`, cut to the two things these
## frames read: five creatures (the cap, so the roster draws five real rows and
## not a mix of rows and OPEN SLOTs) and the satchel contents `S03-exit.json`
## recorded behind the defect frame -- orbs, a potion, berries, a revive -- plus
## an axe, because a tool slot draws a durability pair rather than a count and
## it is the widest thing a slot ever has to fit.
func _seed(game: Node) -> void:
	var inventory: RefCounted = game.get("inventory")
	var party: RefCounted = game.get("party")
	if inventory == null or party == null:
		print("FAIL: Game.inventory/Game.party not reachable")
		return
	for i in PARTY_SPECIES.size():
		var creature: RefCounted = game.call("make_creature", PARTY_SPECIES[i], "")
		if creature == null:
			continue
		if i == 1:
			creature.take_damage(float(creature.get("max_hp")) * 0.72)
		elif i == 2:
			creature.take_damage(float(creature.get("max_hp")))
		party.call("add", creature)
	inventory.call("add", "orb_basic", 10)
	inventory.call("add", "potion_small", 3)
	inventory.call("add", "berries", 12)
	inventory.call("add", "revive", 2)
	inventory.call("add", "axe", 1)
	game.set("hotbar", ["orb_basic", "potion_small", "berries", "revive", "axe"])
