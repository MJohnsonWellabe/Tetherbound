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
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

const HANDHELD_SIZE := Vector2i(1280, 800)

## HUD-SCALE (owner playtest 2026-08-28). This file used to hold its own
## legibility model: a glyph or a cap height, multiplied by a `1280/1920 =
## 0.667` content scale, against a floor in RENDER pixels. Both halves were
## wrong, and because this test was strict it enforced the error into every
## HUD constant until the owner reported the HUD as "way too big" a second
## time.
##
## `scripts/ui/hud_scale.gd`'s header sets out the two faults in full. In
## short: the Ally is 1920x1080, not 1280x800, so there is no 0.667 scale; and
## `canvas_items` stretch maps the authored canvas onto the whole panel, so an
## authored pixel is a fixed fraction of the PANEL at any render resolution --
## rendering smaller makes a glyph blurrier, never smaller. Verified by
## running `tools/_measure_hud_footprint.gd` at both resolutions and getting
## byte-identical authored rects.
##
## So the model moves to `hud_scale.gd` and this file asserts against it. The
## checks are not relaxed; they are re-pointed at the quantity that decides
## whether a human can read the HUD. Two floors, both from that file:
##
##   GLANCE_CAP_ARCMIN     labels, counts, badges -- recognised, not read
##   SENTENCE_CAP_ARCMIN   the objective line and the contextual prompt
##
## and a third for button glyphs whose art bakes lettering in, which IS about
## rasterisation and is measured off a real 1:1 render in
## `tools/_probe_glyph_ladder.gd` rather than assumed.
##
## The window is still forced to 1280x800. That is no longer where the size
## floors come from, but it is still the right place to run the OVERLAP and
## CONTAINMENT checks below: `aspect="expand"` gives a 1280x800 window a
## taller authored canvas (1920x1200) than a 1920x1080 one, and every layout
## defect this file has ever caught came from that difference.
const HUD_SCALE := preload("res://scripts/ui/hud_scale.gd")

## Kept for the crispness half of legibility, which render resolution DOES
## decide: an authored size below this rasterises to too few pixels to hold a
## letterform at the lowest window this project supports. Derived from the
## same ladder render as `HUD_SCALE.GLYPH_ARCMIN` -- the pad badges' two-letter
## art goes to mush below ~22 authored px, and at a 0.667 window that is ~15
## render px.
const MIN_RENDER_PX := 15.0

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
	_check_party_strip_never_overlaps_creature_panel_or_vitals()
	await _check_creature_panel_stands_down_while_the_roster_is_up()
	_check_objective_text_physical_size()
	_check_vitals_value_physical_size()
	_check_nothing_is_oversized()
	_check_hud_occupancy()
	await _check_cycle_banner_fits_without_clipping()
	await _check_cycle_banner_destination_is_dominant()

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
	_check_glyph(PLAYGROUND_HUD.LEGEND_GLYPH_PX, "exploration legend glyphs")


## A button glyph, against both halves of legibility: the angle it subtends on
## the owner's panel, and the render pixels it gets at the smallest supported
## window. A glyph that clears the first and fails the second is legible in
## principle and mush in practice.
func _check_glyph(authored_px: int, what: String) -> void:
	var arcmin := HUD_SCALE.arcmin_for_authored_px(float(authored_px))
	if arcmin < HUD_SCALE.GLYPH_ARCMIN:
		_fail(
			"%s subtend %.1f arcmin at %.0fmm (authored %d px) -- below the %.1f arcmin glyph floor" % [
				what, arcmin, HUD_SCALE.VIEW_DISTANCE_MM, authored_px, HUD_SCALE.GLYPH_ARCMIN,
			]
		)
	var render_px := float(authored_px) * _content_scale()
	if render_px < MIN_RENDER_PX:
		_fail(
			"%s rasterise to %.1f render px at %dx%d (authored %d px) -- below the %.0f px crispness floor" % [
				what, render_px, HANDHELD_SIZE.x, HANDHELD_SIZE.y, authored_px, MIN_RENDER_PX,
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
	# Only when the prompt is actually on screen. A `VBoxContainer` skips
	# hidden children when it lays out, so an invisible `Prompt` keeps whatever
	# rect it held before it was hidden -- with no contextual prompt to show,
	# this harness leaves it sitting on a stale 640x12 box that can land
	# anywhere, including inside the legend. Comparing against that rect tests
	# nothing about what a player sees, and it fails or passes depending on how
	# tall the legend happens to be, which is exactly the false alarm HUD-SCALE
	# hit. The same `is_visible_in_tree()` reasoning
	# `_assert_descendants_inside()` below already spells out.
	#
	# The VISIBLE case is not dropped: `smoke_prompt_hotbar_dock.gd` drives
	# real prompt text through this same dock -- quiet, hotbar-message,
	# wrapped, and both at once -- and asserts the measured gap in every one.
	if prompt.is_visible_in_tree() and legend_rect.intersects(prompt_rect):
		_fail("legend and contextual prompt overlap at %dx%d (legend %s, prompt %s)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, legend_rect, prompt_rect,
		])

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


func _check_cap_height(authored_font_size: int, what: String,
		floor_arcmin: float = HUD_SCALE.GLANCE_CAP_ARCMIN) -> void:
	var arcmin := HUD_SCALE.cap_arcmin_for_font_size(authored_font_size)
	if arcmin < floor_arcmin:
		_fail(
			"%s has a cap height of %.1f arcmin at %.0fmm (authored font %d px) -- below the %.1f arcmin floor" % [
				what, arcmin, HUD_SCALE.VIEW_DISTANCE_MM, authored_font_size, floor_arcmin,
			]
		)
	var render_px := float(authored_font_size) * _content_scale() * HUD_SCALE.CAP_HEIGHT_RATIO
	if render_px < MIN_RENDER_PX * HUD_SCALE.CAP_HEIGHT_RATIO:
		_fail(
			"%s rasterises to a ~%.1f render px cap height at %dx%d (authored font %d px) -- too few pixels to hold a letterform" % [
				what, render_px, HANDHELD_SIZE.x, HANDHELD_SIZE.y, authored_font_size,
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
	_check_glyph(PLAYGROUND_HUD.HOTBAR_GLYPH_PX, "hotbar slot glyphs")


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


## GF-B-006, on the LIVE scene rather than the pure position math
## `test_hud_widgets.gd` checks.
##
## Two claims, and they are different claims now. `Root/PartyStrip`'s real
## global rect must still never intersect the VITALS cluster's -- HP and satiety
## are safety information and are never stood down, so that stays a geometric
## guarantee. Against the CREATURE PANEL it is no longer geometric: the strip is
## back in the left column (there is nowhere else on this canvas that is not over
## the player's forward view -- see `playground_hud.gd::party_strip_position()`)
## and the two share a rect on purpose, with
## `_yield_creature_block_to_party_strip()` hiding the panel for as long as the
## strip is revealed. So the panel claim is checked as MUTUAL EXCLUSION, driven
## through the real HUD by revealing the strip and pumping frames, which is
## strictly stronger than disjoint rects: two widgets that are never on screen
## together cannot composite through each other at all.
##
## `set_rest_position()` snaps `.position` immediately while the strip is not
## visible (see that function's own header), so the vitals half holds without a
## reveal; the panel half has to force one.
func _check_party_strip_never_overlaps_creature_panel_or_vitals() -> void:
	var strip := _hud.get_node_or_null(^"Root/PartyStrip") as Control
	var creature_block := _hud.get_node_or_null(^"Root/CreatureBlock") as Control
	var vitals := _hud.get_node_or_null(^"Root/VitalsCluster") as Control
	if strip == null or creature_block == null or vitals == null:
		_fail("HUD did not build PartyStrip/CreatureBlock/VitalsCluster for the overlap check")
		return
	var strip_rect := strip.get_global_rect()
	var vitals_rect := vitals.get_global_rect()
	if strip_rect.intersects(vitals_rect):
		_fail("party strip overlaps the player vitals cluster at %dx%d (strip %s, vitals %s)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, strip_rect, vitals_rect,
		])


## The mutual-exclusion half of the claim above, driven rather than inspected:
## reveal the strip, let the HUD's own `_process` run, and the creature panel
## must be gone. Separate from the rect check because it needs frames.
func _check_creature_panel_stands_down_while_the_roster_is_up() -> void:
	var strip := _hud.get_node_or_null(^"Root/PartyStrip") as Control
	var creature_block := _hud.get_node_or_null(^"Root/CreatureBlock") as Control
	if strip == null or creature_block == null:
		_fail("HUD did not build PartyStrip/CreatureBlock for the stand-down check")
		return
	# Forced visible rather than assumed: this harness boots the HUD with no
	# creature called out, so the block may already be down for its own reasons
	# and the check would pass vacuously. `_yield_left_stack_to_combat_hud()`
	# writes `visible = not combat` unconditionally every frame BEFORE the
	# stand-down runs, so out of combat the only thing that can put it back to
	# false below is the stand-down itself.
	creature_block.visible = true
	strip.call("show_strip")
	for i in 3:
		await process_frame
	if not strip.visible:
		_fail("show_strip() did not reveal the party strip; the stand-down check cannot mean anything")
		return
	if creature_block.visible:
		_fail("the creature panel is still drawn while the roster reveal is up at %dx%d -- the two share a rect and would composite (strip %s, block %s)" % [
			HANDHELD_SIZE.x, HANDHELD_SIZE.y, strip.get_global_rect(), creature_block.get_global_rect(),
		])


## HUD-POPUP task 3: the quest subtext ("Find a way through the village
## gate.") measured ~12 physical px before this task raised it to
## `HUD_READABLE_FONT_SIZE`, same floor as everything else on this HUD.
func _check_objective_text_physical_size() -> void:
	var label := _hud.get(&"_objective_text_label") as Label
	if label == null:
		_fail("HUD did not build _objective_text_label for the cap-height check")
		return
	_check_cap_height(label.get_theme_font_size("font_size"), "quest subtext",
		HUD_SCALE.SENTENCE_CAP_ARCMIN)


## HUD-POPUP task 3: the player's own HP readout ("100 / 100") measured ~10
## physical px before this task; the satiety row's new value label is held to
## the same floor since it is new text, not a pre-existing offender.
func _check_vitals_value_physical_size() -> void:
	var hp_label := _hud.get(&"_hp_value_label") as Label
	var satiety_label := _hud.get(&"_satiety_value_label") as Label
	if hp_label == null or satiety_label == null:
		_fail("HUD did not build the vitals value labels for the cap-height check")
		return
	_check_cap_height(hp_label.get_theme_font_size("font_size"), "player HP value text")
	_check_cap_height(satiety_label.get_theme_font_size("font_size"), "player satiety value text")


## HUD-POPUP task 2: the real bug behind "the cycle still does not read as an
## event from one frame" was not a missing cue -- `flash_cycle()` already
## built one -- it was that the cue's OWN `RichTextLabel` wrapped to a second
## line and then clipped it, because the box was sized for one line
## (42px tall) but not wide enough to hold the whole string on one line. Only
## a real, rendered `RichTextLabel` (with an active theme/font, which a
## tree-less `test_hud_widgets.gd` instance does not have --
## `get_content_height()` reports 0 there) can catch this, which is why this
## check lives here rather than as pure logic.
func _check_cycle_banner_fits_without_clipping() -> void:
	var strip := _hud.get_node_or_null(^"Root/PartyStrip")
	if strip == null:
		_fail("HUD did not build Root/PartyStrip for the cycle-banner check")
		return
	strip.call("flash_cycle", 1, "Terrapup", "Bramblebun", 2, 5)
	for i in 3:
		await process_frame
	var banner := strip.get(&"_cycle_banner") as RichTextLabel
	if banner == null:
		_fail("party strip has no _cycle_banner for the clipping check")
		return
	if not banner.visible:
		_fail("cycle banner did not become visible after flash_cycle()")
		return
	var content_h := banner.get_content_height()
	if content_h > banner.size.y + 0.5:
		_fail(
			"cycle banner content (%.1fpx tall) overflows its own box (%.1fpx) -- the text wrapped to a second line that gets silently clipped, hiding half the from-to cue (banner text: %s)" % [
				content_h, banner.size.y, banner.text,
			]
		)


## HUD-EMPHASIS: the whole point of this task, proven on the LIVE mounted
## widget rather than just the pure-logic assertion `test_hud_widgets.gd`
## already carries. A blind critic measured the destination name (the single
## word the player cycled to find out) as the smallest text on the entire
## screen -- this asserts the inversion is actually fixed in physical
## pixels, and that docking the taller banner onto the header (see
## `party_strip.gd::_build()`'s own comment on `CYCLE_BANNER_HEIGHT` growing)
## did not push it back off the real handheld canvas the way a naive "grow
## upward" fix would have.
func _check_cycle_banner_destination_is_dominant() -> void:
	var strip := _hud.get_node_or_null(^"Root/PartyStrip")
	if strip == null:
		_fail("HUD did not build Root/PartyStrip for the destination-dominance check")
		return
	strip.call("flash_cycle", 1, "Terrapup", "Bramblebun", 2, 5)
	for i in 3:
		await process_frame
	var banner := strip.get(&"_cycle_banner") as RichTextLabel
	if banner == null or not banner.visible:
		_fail("cycle banner did not become visible for the destination-dominance check")
		return

	# HUD-SCALE: the RANKING is the claim this check exists to defend, and it
	# is unchanged. The absolute floor moves off render pixels for the reason
	# this file's header gives, and onto the angle the announcement subtends.
	var dest_arcmin := HUD_SCALE.cap_arcmin_for_font_size(PARTY_STRIP.CYCLE_DEST_FONT_SIZE)
	var source_arcmin := HUD_SCALE.cap_arcmin_for_font_size(PARTY_STRIP.CYCLE_SOURCE_FONT_SIZE)
	if dest_arcmin <= source_arcmin:
		_fail(
			"cycle banner destination name (%.1f arcmin) is not larger than the source name (%.1f arcmin) -- the exact inversion this check exists to catch" % [
				dest_arcmin, source_arcmin,
			]
		)
	# A dominant announcement has to be clearly above the tier every ordinary
	# HUD tag sits at, not merely above the readability floor. 1.25x the glance
	# floor is the same "clearly the loudest thing on screen" claim the old
	# 18-render-px bar made, restated in the unit that survives a resolution
	# change.
	var dest_floor := HUD_SCALE.GLANCE_CAP_ARCMIN * 1.25
	if dest_arcmin < dest_floor:
		_fail(
			"cycle banner destination name measures %.1f arcmin cap height -- below the %.1f arcmin a dominant announcement has to clear" % [
				dest_arcmin, dest_floor,
			]
		)

	# On-screen, not just non-clipping within its own box: `party_strip.gd`
	# docks the banner onto the header rather than floating fully above it
	# specifically so a taller box for the bigger destination font does not
	# push its own top edge off the real canvas.
	var banner_rect := banner.get_global_rect()
	if banner_rect.position.y < -0.5:
		_fail(
			"cycle banner's own top edge sits off the top of the real %dx%d canvas (y=%.1f) -- the destination text itself may be clipped, not just the box" % [
				HANDHELD_SIZE.x, HANDHELD_SIZE.y, banner_rect.position.y,
			]
		)


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


## --- the half this file never had ------------------------------------------
##
## Every check above is a FLOOR. That is how the HUD ended up at 27.4% of the
## canvas with 40-arcmin button glyphs on it: each legibility pass could only
## push a number up, nothing could push back, and the owner reported "the hud
## on screen is way too big" twice before anyone measured it. A floor-only
## suite does not encode a size requirement, it encodes a direction.
##
## So each floor gets a ceiling, and the HUD as a whole gets one.


## Nothing on this HUD may exceed `OVERSIZE_FACTOR` x its own floor.
##
## 1.6 is chosen so the two text tiers stay distinguishable (SENTENCE is 1.23x
## GLANCE, well inside the band) and a deliberate emphasis element -- the
## region title card, the cycle banner's destination -- still has room to be
## clearly the loudest thing on screen, while a tag quietly drifting to
## newspaper-body size fails.
const OVERSIZE_FACTOR := 1.6


func _check_nothing_is_oversized() -> void:
	_check_not_oversized_text(PLAYGROUND_HUD.HUD_READABLE_FONT_SIZE,
		"HUD glance label", HUD_SCALE.GLANCE_CAP_ARCMIN)
	_check_not_oversized_text(PLAYGROUND_HUD.LEGEND_FONT_SIZE,
		"exploration legend label", HUD_SCALE.GLANCE_CAP_ARCMIN)
	_check_not_oversized_text(PLAYGROUND_HUD.HOTBAR_COUNT_FONT_SIZE,
		"hotbar item count", HUD_SCALE.GLANCE_CAP_ARCMIN)
	_check_not_oversized_text(PARTY_STRIP.STRIP_READABLE_FONT_SIZE,
		"party strip label", HUD_SCALE.GLANCE_CAP_ARCMIN)
	_check_not_oversized_text(PLAYGROUND_HUD.HUD_SENTENCE_FONT_SIZE,
		"HUD sentence text", HUD_SCALE.SENTENCE_CAP_ARCMIN)
	_check_not_oversized_glyph(PLAYGROUND_HUD.LEGEND_GLYPH_PX, "exploration legend glyph")
	_check_not_oversized_glyph(PLAYGROUND_HUD.HOTBAR_GLYPH_PX, "hotbar slot glyph")


func _check_not_oversized_text(font_size: int, what: String, floor_arcmin: float) -> void:
	var arcmin := HUD_SCALE.cap_arcmin_for_font_size(font_size)
	var ceiling := floor_arcmin * OVERSIZE_FACTOR
	if arcmin > ceiling:
		_fail(
			"%s has a cap height of %.1f arcmin (authored font %d px) -- above the %.1f arcmin ceiling (%.1fx the %.1f floor). The HUD is sized for a screen further away than the owner's." % [
				what, arcmin, font_size, ceiling, OVERSIZE_FACTOR, floor_arcmin,
			]
		)


func _check_not_oversized_glyph(authored_px: int, what: String) -> void:
	var arcmin := HUD_SCALE.arcmin_for_authored_px(float(authored_px))
	var ceiling := HUD_SCALE.GLYPH_ARCMIN * OVERSIZE_FACTOR
	if arcmin > ceiling:
		_fail(
			"%s subtends %.1f arcmin (authored %d px) -- above the %.1f arcmin ceiling" % [
				what, arcmin, authored_px, ceiling,
			]
		)


## How much of the screen the persistent HUD is allowed to cover.
##
## Measured, not guessed: `tools/_measure_hud_footprint.gd` put the shipped
## HUD the owner played at 27.4% of the authored canvas persistently and 34.4%
## with the roster reveal up. This ceiling is the number that turns "way too
## big" from an adjective into a build failure.
##
## 20% is deliberately loose relative to what the HUD measures after
## HUD-SCALE, so ordinary layout work has room; it is the RATCHET this suite
## was missing, not a target to design against.
const MAX_HUD_OCCUPANCY := 0.20


func _check_hud_occupancy() -> void:
	var hud_root := _hud.get_node_or_null(^"Root") as Control
	if hud_root == null:
		_fail("HUD has no Root control for the occupancy check")
		return
	var canvas := root.get_visible_rect().size
	var rects: Array[Rect2] = []
	_collect_ink(hud_root, rects)
	if rects.is_empty():
		_fail("occupancy check found no HUD widgets, so it cannot mean anything")
		return

	# Union by sample grid: the rects overlap, so summing their areas would
	# over-report and the check would fail for the wrong reason.
	var covered := 0.0
	var step := 8.0
	var y := 0.0
	while y < canvas.y:
		var x := 0.0
		while x < canvas.x:
			var p := Vector2(x, y)
			for r: Rect2 in rects:
				if r.has_point(p):
					covered += step * step
					break
			x += step
		y += step
	var fraction := covered / (canvas.x * canvas.y)
	if fraction > MAX_HUD_OCCUPANCY:
		_fail(
			"the persistent HUD covers %.1f%% of the screen at %dx%d -- above the %.0f%% ceiling. This is the owner's \"way too big\" as a number." % [
				fraction * 100.0, HANDHELD_SIZE.x, HANDHELD_SIZE.y, MAX_HUD_OCCUPANCY * 100.0,
			]
		)


## Widgets that actually put ink on screen: a leaf Control, or a Panel /
## PanelContainer, which fills a stylebox behind its own children. Transient
## widgets are skipped -- the complaint is about what is on screen while the
## player walks around.
const TRANSIENT_NAMES: Array[String] = [
	"PartyStrip", "RegionBanner", "Message", "Prompt", "DebugReadout",
]


func _collect_ink(node: Node, into: Array[Rect2]) -> void:
	for child in node.get_children():
		if child is not Control:
			continue
		var c := child as Control
		if not c.is_visible_in_tree() or TRANSIENT_NAMES.has(String(c.name)):
			continue
		var draws_ink := true
		for grand in c.get_children():
			if grand is Control and (grand as Control).is_visible_in_tree():
				draws_ink = false
				break
		if not draws_ink and (c is PanelContainer or c is Panel):
			draws_ink = c.has_theme_stylebox_override("panel")
		if draws_ink:
			var r := c.get_global_rect()
			if r.size.x > 1.0 and r.size.y > 1.0:
				into.append(r)
		_collect_ink(c, into)
