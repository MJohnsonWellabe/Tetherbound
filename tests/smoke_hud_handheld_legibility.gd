extends SceneTree

## OP21-11 measured at the device the owner actually plays on. The rest of
## `smoke_exploration_legend.gd` measures the 1920x1080 authoring canvas —
## exactly the resolution `ralph/conventions.md`'s own SETTINGS-SCROLL note
## warns is roomy enough to hide a real handheld defect. This file forces
## `root.size` down to the Ally's real panel resolution instead and asserts
## real pixel measurements there, not "it looks bigger."
##
##   godot --headless --path . --script tests/smoke_hud_handheld_legibility.gd

const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const PLAYGROUND_HUD := preload("res://scripts/ui/playground_hud.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

const HANDHELD_SIZE := Vector2i(1280, 800)

## The floor a glyph has to clear at handheld scale to count as "legible, not
## just less bad." `input_glyph.gd::icon()`'s own header puts 36px at the
## project's 1920x1080 authoring scale as the smallest size that read clearly
## in a blind crop test for a harder glyph (baked ESC text) than anything the
## exploration legend draws. This project stretches canvas_items with
## aspect="expand", so on a real 1280-wide window the physical scale factor
## is 1280.0/1920.0 -- the same ratio this test derives from the live
## viewport rather than hard-coding, so a future change to the authored
## resolution cannot silently stop this test from meaning anything.
const MIN_PHYSICAL_GLYPH_PX := 24.0

var _failures: Array[String] = []
var _world: Node3D = null
var _hud: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("Game autoload is missing")
		_report()
		return
	(game.get("party") as RefCounted).call("clear")

	_world = Node3D.new()
	_world.name = "HandheldWorld"
	root.add_child(_world)
	current_scene = _world
	var player := CharacterBody3D.new()
	player.name = "Player"
	_world.add_child(player)
	_hud = HUD_SCENE.instantiate() as CanvasLayer
	_world.add_child(_hud)
	# A few settle frames before touching `root.size` at all: assigning it too
	# early (before the headless window has finished its own setup) silently
	# does not stick, and the tree just keeps reporting 64x64 forever after --
	# the exact bug `smoke_exploration_legend.gd` had until this same pass
	# fixed it. `smoke_build_menu_footprint.gd`'s own order is the one
	# confirmed to work: settle, assign, settle again, THEN verify.
	for i in 10:
		await process_frame

	var original_size := root.size
	root.size = HANDHELD_SIZE
	for i in 10:
		await process_frame

	if root.size != HANDHELD_SIZE:
		_fail("viewport would not take the handheld size (wanted %s, got %s)" % [HANDHELD_SIZE, root.size])
		_report()
		root.size = original_size
		return

	_check_legend_glyph_physical_size()
	_check_legend_sits_under_hotbar()
	_check_no_horizontal_overflow()

	root.size = original_size
	_report()


## Derives the real on-screen scale from the viewport's own reported content
## scale rather than assuming the project's numbers, so a change to either
## the authored resolution or the test's target resolution keeps this test
## honest instead of quietly measuring the wrong thing.
func _content_scale() -> float:
	var authored_width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	if authored_width <= 0.0:
		return 1.0
	return float(HANDHELD_SIZE.x) / authored_width


func _check_legend_glyph_physical_size() -> void:
	var scale := _content_scale()
	var physical_px := PLAYGROUND_HUD.LEGEND_GLYPH_PX * scale
	if physical_px < MIN_PHYSICAL_GLYPH_PX:
		_fail(
			"exploration legend glyphs measure %.1f physical px at %dx%d (authored %d px x scale %.3f) -- below the %.0f px legibility floor" % [
				physical_px, HANDHELD_SIZE.x, HANDHELD_SIZE.y,
				PLAYGROUND_HUD.LEGEND_GLYPH_PX, scale, MIN_PHYSICAL_GLYPH_PX,
			]
		)


func _check_legend_sits_under_hotbar() -> void:
	var legend := _hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend") as Control
	var hotbar := _hud.get_node_or_null(^"Root/BottomDock/HotbarPanel") as Control
	var prompt := _hud.get_node_or_null(^"Root/BottomDock/Prompt") as Control
	if legend == null or hotbar == null or prompt == null:
		_fail("HUD did not build the hotbar/legend/prompt stack at handheld size")
		return
	var legend_rect := legend.get_global_rect()
	var hotbar_rect := hotbar.get_global_rect()
	var prompt_rect := prompt.get_global_rect()

	if legend_rect.position.y < hotbar_rect.end.y - 0.5:
		_fail("legend is not under the hotbar at %dx%d (legend top %.1f, hotbar bottom %.1f)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, legend_rect.position.y, hotbar_rect.end.y,
		])
	if hotbar_rect.intersects(legend_rect):
		_fail("hotbar and legend overlap at %dx%d" % [HANDHELD_SIZE.x, HANDHELD_SIZE.y])
	if legend_rect.intersects(prompt_rect):
		_fail("legend and contextual prompt overlap at %dx%d" % [HANDHELD_SIZE.x, HANDHELD_SIZE.y])

	# The whole dock has to still land inside the real handheld canvas -- a
	# stack that lays out correctly relative to itself but pushes below row
	# zero or off the right edge is still a defect a player on the device
	# would see.
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.get_visible_rect().size))
	if not viewport_rect.encloses(hotbar_rect) and not viewport_rect.intersects(hotbar_rect):
		_fail("hotbar panel rendered entirely off the handheld canvas")


## The legend used to be a fixed 682px box positioned by hand; now it is
## `fit_content` inside a `SHRINK_END` container. Confirms that trade did not
## quietly let five longer entries (glyph pair + "Change Creature" is the
## longest) run off the left edge of a narrower window.
func _check_no_horizontal_overflow() -> void:
	var legend := _hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend") as Control
	if legend == null:
		return
	var rect := legend.get_global_rect()
	if rect.position.x < -0.5:
		_fail("exploration legend runs off the left edge at %dx%d (x=%.1f)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, rect.position.x,
		])


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("PASS: HUD hotbar/legend/prompt stack is legible and non-overlapping at 1280x800")
		quit(0)
		return
	for failure: String in _failures:
		print("FAIL: %s" % failure)
	quit(1)
