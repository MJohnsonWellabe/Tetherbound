extends SceneTree

## HIST-013 evidence. The party strip at its five-creature cap, so the row
## separation can be judged rather than asserted.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_party_strip_rows.gd -- --tag=after
##
## NEVER `--headless` with a real rendering driver (`ralph/conventions.md`).
##
## No world scene, deliberately: this is the same framing `GF-B-005-006`'s own
## before/after pair used for this widget, and what is being judged here is
## whether five plated rows still read as five rows at a smaller separation --
## a question about the widget, not about what is behind it.
##
## `--tag=` names the output so a before and an after can be shot from two
## different values of the constants without one overwriting the other.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")
const OUT_DIR := "res://shots/hist-013"

## A real five: one active, one worn down, one fainted, and long names as well
## as short ones, so the rows differ in height the way they do in play (a
## selected row carries a border, a KO row carries a badge).
const PARTY := [
	{"label": "Terrapup", "level": 7, "hp_fraction": 1.0, "fainted": false},
	{"label": "Thunderbristle", "level": 6, "hp_fraction": 0.4, "fainted": false},
	{"label": "Bramblebun", "level": 5, "hp_fraction": 0.0, "fainted": true},
	{"label": "Brooktail", "level": 6, "hp_fraction": 0.8, "fainted": false},
	{"label": "Tuskroot", "level": 5, "hp_fraction": 1.0, "fainted": false},
]

var _tag := "after"


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--tag="):
			_tag = str(arg).substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in 8:
		await process_frame

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	var hud: Node = packed.instantiate()
	root.add_child(hud)
	for i in 8:
		await process_frame

	var strip := hud.get_node_or_null(^"Root/PartyStrip") as Control
	if strip == null:
		print("FAIL: HUD has no Root/PartyStrip")
		quit(1)
		return
	strip.call("update_from_party", PARTY, 0)
	strip.call("set_pinned", true)
	strip.call("show_strip")
	for i in 12:
		await process_frame

	print("  TOTAL_HEIGHT %.0f, ROW_SEPARATION %d, HEADER_HEIGHT %.0f, HEADER_GAP %.0f" % [
		PARTY_STRIP.TOTAL_HEIGHT, PARTY_STRIP.ROW_SEPARATION,
		PARTY_STRIP.HEADER_HEIGHT, PARTY_STRIP.HEADER_GAP,
	])
	print("  strip rect %s" % strip.get_global_rect())

	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL: viewport returned no image")
		quit(1)
		return
	# Cropped to the left column. A full 1920x1080 frame of a 420px widget puts
	# the thing being judged at a fifth of the page; the crop does not move
	# anything, the widget still draws at its authored 1:1 size.
	var crop := Rect2i(0, 0, 560, 560).intersection(Rect2i(0, 0, image.get_width(), image.get_height()))
	var path := "%s/party-strip-%s.png" % [OUT_DIR, _tag]
	var error := image.get_region(crop).save_png(path)
	if error != OK:
		print("FAIL: save_png failed (%d)" % error)
		quit(1)
		return
	print("  -> %s" % path)
	quit(0)
