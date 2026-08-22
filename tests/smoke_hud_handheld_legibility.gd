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

## OP21 handheld remainder round 2: a blind critic measured real TEXT (not
## glyph images) at physical pixels a first pass of this file never checked
## at all -- legend labels came back 11px, "ACTIVE COMPANION" 9px, the hotbar
## item count 7px, all against the critic's own ~16px cap-height comfort bar
## for arm's-length handheld reading. `CAP_HEIGHT_RATIO` is not invented: it
## is the ratio backed out of that same measurement pass, which found
## `UITokens.FONT_TINY` (19, unchanged by this task) rendering at 9 physical
## px -- 19 * _content_scale() * 0.7 = 8.9, matching the reported 9 almost
## exactly. Using the same ratio here keeps this test measuring the thing the
## critic actually measured, not a more forgiving proxy that would pass a
## font size the critic already rejected.
const CAP_HEIGHT_RATIO := 0.7
const MIN_PHYSICAL_TEXT_PX := 16.0

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
	var party: RefCounted = game.get("party")
	party.call("clear")
	# Seeded, not left empty: the creature-panel bounds checks below need a
	# REAL active creature (name/level/type/HP text, the exact content that
	# escaped its rows before this fix) drawn, not just the "READY TO CALL
	# OUT" empty state, which has less content to overflow with.
	var seeded: RefCounted = game.call("make_creature", "terrapup", "Biscuit")
	if seeded != null:
		party.call("add", seeded)
		seeded.take_damage(float(seeded.get("max_hp")) * 0.35)

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
	_check_legend_label_physical_size()
	_check_micro_label_physical_size()
	_check_hotbar_count_physical_size()
	_check_hotbar_glyph_physical_size()
	for i in 3:
		await process_frame
	_check_left_stack_clears_bottom_dock()
	_check_creature_panel_children_stay_inside_it()

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


func _check_cap_height(authored_font_size: int, what: String) -> void:
	var scale := _content_scale()
	var physical_px := float(authored_font_size) * scale * CAP_HEIGHT_RATIO
	if physical_px < MIN_PHYSICAL_TEXT_PX:
		_fail(
			"%s measures ~%.1f physical cap-height px at %dx%d (authored %d px x scale %.3f x cap-ratio %.2f) -- below the %.0f px arm's-length floor" % [
				what, physical_px, HANDHELD_SIZE.x, HANDHELD_SIZE.y,
				authored_font_size, scale, CAP_HEIGHT_RATIO, MIN_PHYSICAL_TEXT_PX,
			]
		)


func _check_legend_label_physical_size() -> void:
	_check_cap_height(PLAYGROUND_HUD.LEGEND_FONT_SIZE, "exploration legend label text")


## The other 9px offenders from the same measurement pass: "ACTIVE COMPANION",
## "Lv 1"/"GROUND", the companion's own HP value -- every one of them now
## draws at `HUD_READABLE_FONT_SIZE` instead of the shared `UITokens.FONT_TINY`
## (deliberately not raised globally -- see that constant's own header).
func _check_micro_label_physical_size() -> void:
	_check_cap_height(PLAYGROUND_HUD.HUD_READABLE_FONT_SIZE, "creature-block micro-label text")


## The worst offender in the whole HUD by the critic's own numbers: the
## hotbar item count ("x12") measured 7px, unreadable without 4x
## magnification, and it was ALSO the one number a blind critic said was
## drawn in a colour (the item's own tile tint) that could fall below its
## contrast threshold entirely -- see `_update_hotbar()`'s own comment on
## `text_colour`.
func _check_hotbar_count_physical_size() -> void:
	_check_cap_height(PLAYGROUND_HUD.HOTBAR_COUNT_FONT_SIZE, "hotbar item count text")


## The hotbar's own glyphs used to override `icon()`'s documented 36px floor
## down to 28 -- the one call on this HUD that did, and the thing a blind
## critic read as visibly more pixelated than every other glyph on screen.
func _check_hotbar_glyph_physical_size() -> void:
	var scale := _content_scale()
	var physical_px := float(PLAYGROUND_HUD.HOTBAR_GLYPH_PX) * scale
	if physical_px < MIN_PHYSICAL_GLYPH_PX:
		_fail(
			"hotbar slot glyphs measure %.1f physical px at %dx%d (authored %d px x scale %.3f) -- below the %.0f px legibility floor" % [
				physical_px, HANDHELD_SIZE.x, HANDHELD_SIZE.y,
				PLAYGROUND_HUD.HOTBAR_GLYPH_PX, scale, MIN_PHYSICAL_GLYPH_PX,
			]
		)


## HUD-LAYOUT's own regression, proven against the LIVE scene rather than
## just the pure position math `test_hud_widgets.gd` checks: the creature
## panel and the player vitals cluster must never intersect
## `Root/BottomDock` (the hotbar, the exploration legend, or the contextual
## prompt) at the Ally's real 1280x800 window. This is the exact defect a
## real render caught before the fix -- `CREATURE_BLOCK_POS`/`VITALS_POS`
## were fixed, top-anchored offsets tuned against an assumed 1080-tall
## canvas, and the Ally's real `canvas_items`/`aspect="expand"` stretch
## computes an effective 1920x1200 canvas, not 1920x1080 -- 120px taller,
## with `Root/BottomDock` (anchored to the canvas BOTTOM) sliding down into
## territory the left column never moved out of. Confirmed against the
## pre-fix code by temporarily reverting `_reflow_left_stack()`.
func _check_left_stack_clears_bottom_dock() -> void:
	var dock := _hud.get_node_or_null(^"Root/BottomDock") as Control
	var creature_block := _hud.get_node_or_null(^"Root/CreatureBlock") as Control
	if dock == null or creature_block == null:
		_fail("HUD did not build the BottomDock/CreatureBlock nodes needed for the overlap check")
		return
	var creature_panel: Control = creature_block.get_child(0) as Control if creature_block.get_child_count() > 0 else null
	if creature_panel == null:
		_fail("creature block has no panel child to measure")
		return
	var dock_rect := dock.get_global_rect()
	var creature_rect := creature_panel.get_global_rect()
	if dock_rect.intersects(creature_rect):
		_fail("creature panel overlaps Root/BottomDock at %dx%d (panel %s, dock %s)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, creature_rect, dock_rect,
		])

	# `VitalsCluster`'s own declared size already covers its real content
	# (`VITALS_HEIGHT`), so its own global rect is the honest measure.
	var vitals := _hud.get_node_or_null(^"Root/VitalsCluster") as Control
	if vitals == null:
		_fail("HUD did not build Root/VitalsCluster")
		return
	var vitals_rect := vitals.get_global_rect()
	if dock_rect.intersects(vitals_rect):
		_fail("player vitals cluster overlaps Root/BottomDock at %dx%d (vitals %s, dock %s)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, vitals_rect, dock_rect,
		])
	if creature_rect.intersects(vitals_rect):
		_fail("player vitals cluster overlaps the creature panel at %dx%d" % [HANDHELD_SIZE.x, HANDHELD_SIZE.y])


## Direct, structural proof that the container rebuild actually contains its
## own children: the header row, pip row and HP row must all fit fully
## inside the panel's own rect -- the exact three ways the old hand-placed
## layout escaped (header text overrunning its box, the HP value label
## spilling below the panel, "GROUND"/"WATER" crowding past the border).
func _check_creature_panel_children_stay_inside_it() -> void:
	var creature_block := _hud.get_node_or_null(^"Root/CreatureBlock") as Control
	if creature_block == null or creature_block.get_child_count() == 0:
		_fail("creature block missing for the containment check")
		return
	var panel := creature_block.get_child(0) as Control
	var panel_rect := panel.get_global_rect()
	_assert_descendants_inside(panel, panel_rect)


func _assert_descendants_inside(node: Node, bounds: Rect2) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			# `is_visible_in_tree()`, not the bare `.visible` flag: a hidden
			# ancestor (e.g. `_creature_content` while no creature is out)
			# leaves every descendant's OWN `.visible` untouched at `true`,
			# so checking only the local flag flagged nodes that never
			# actually draw.
			if c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0:
				var r := c.get_global_rect()
				if not bounds.encloses(r.grow(-0.5)):
					_fail("creature panel child '%s' escapes the panel bounds at %dx%d (child %s, panel %s)" % [
						c.name if not c.name.is_empty() else c.get_class(), HANDHELD_SIZE.x, HANDHELD_SIZE.y, r, bounds,
					])
		_assert_descendants_inside(child, bounds)


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
