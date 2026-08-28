extends SceneTree

## BINDINGS. The first-catch objective hint card, photographed on the device
## the owner actually holds.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_probe_objective_hint_device.gd -- --out=shots/bindings --tag=before
##
## NEVER `--headless` with a real rendering driver -- see
## `tools/_capture_ui_survey.gd`'s header for the trap and what it has cost.
##
## The defect this exists to photograph: `data/progression/objectives.json`'s
## opening rung writes `{combat_throw}`, and `combat_throw` has no joypad event
## at all (CONTROLLER-MAP moved the pad's throw onto `interact`), so the token
## resolved to the KEYBOARD key -- a card reading "press F" on a handheld with
## no F key, on the tutorial line for catching.
##
## Method is `tools/_probe_hud_quickbar_and_roster.gd`'s, which is in turn
## `_capture_ui_survey.gd`'s, reduced to what this one card reads: mount
## `playground_hud.tscn` standalone (no world behind it -- minutes of llvmpipe
## per boot, for a defect that is entirely inside the HUD scene), pin the
## device, let the objective poll fire.
##
## THE DEVICE IS PINNED. Under `xvfb-run` no joypad is connected, so
## `game_state.gd` initialises `_last_input_was_gamepad` from
## `Input.get_connected_joypads()` and the frame photographs the keyboard half
## -- the device the owner's hardware never presents, and the half the defect
## is invisible in. `--device=keyboard` pins the other way, because a fix that
## makes the pad right by making the desktop wrong is not a fix.
##
## The card is TRANSIENT: `playground_hud.gd::_reveal_objective_hint` shows it
## for a few seconds and `_tick_objective_hint` takes it down again. The reveal
## fires on the first objective poll after the HUD mounts (its own header says
## why that first-frame reveal is wanted), so a frame taken promptly after the
## mount catches it -- but the label text is ALSO printed, so the run states
## its verdict in text and does not rest on the screenshot alone.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

var _out_dir := "res://shots/bindings"
var _tag := "frame"
var _device := "gamepad"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	_read_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	# Autoloads are not in the tree on a `--script` SceneTree's first line.
	for _i in 4:
		await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: no Game autoload after 4 frames")
		quit(1)
		return
	game.set("_last_input_was_gamepad", _device == "gamepad")

	print("device pinned to %s (using_gamepad=%s)" % [_device, INPUT_GLYPH.using_gamepad()])
	for id in ["combat_throw", "interact", "combat_run", "creature_recall"]:
		print("  action_name(%s) = %s" % [id, INPUT_GLYPH.action_name(id)])
	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	var hud: Node = packed.instantiate()
	root.add_child(hud)
	for _i in 12:
		await process_frame

	var card := hud.find_child("ObjectiveHintCard", true, false) as Control
	var label := hud.find_child("CardHint", true, false) as Label
	if card == null or label == null:
		print("FAIL: no ObjectiveHintCard/CardHint in the mounted HUD")
		quit(1)
		return
	# AFTER the settle, deliberately. `game_state.gd` caches the resolved hint
	# and re-resolves it on a device flip in `_process`, so a read taken on the
	# same line as the pin above would print the pre-flip string and read as a
	# failure. BINDINGS is the change that made the cache follow the device.
	print("Game.objective_text = %s" % str(game.get("objective_text")))
	print("Game.objective_hint = %s" % str(game.get("objective_hint")))
	print("card visible=%s rect=%s" % [card.visible, card.get_global_rect()])
	print("CARD TEXT: %s" % label.text)

	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	var path := "%s/%s-%s.png" % [_out_dir, _tag, _device]
	img.save_png(path)
	print("wrote %s" % path)

	# The card alone, at 2x nearest-neighbour: the whole point is one word on
	# one line, and a 1920-wide frame renders it at a size a reviewer has to
	# hunt for.
	var rect := card.get_global_rect()
	var crop := Rect2i(
		Vector2i(maxi(0, int(rect.position.x) - 8), maxi(0, int(rect.position.y) - 8)),
		Vector2i(int(rect.size.x) + 16, int(rect.size.y) + 16)
	)
	crop = crop.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if crop.size.x > 0 and crop.size.y > 0:
		var cut := img.get_region(crop)
		cut.resize(cut.get_width() * 2, cut.get_height() * 2, Image.INTERPOLATE_NEAREST)
		var crop_path := "%s/%s-%s-card.png" % [_out_dir, _tag, _device]
		cut.save_png(crop_path)
		print("wrote %s" % crop_path)
	quit(0)


func _read_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr(6)
		elif arg.begins_with("--tag="):
			_tag = arg.substr(6)
		elif arg.begins_with("--device="):
			_device = arg.substr(9)
