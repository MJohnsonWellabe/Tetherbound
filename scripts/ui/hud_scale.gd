extends RefCounted

## HUD legibility, expressed as angular size on the owner's panel.
##
## Every HUD size in this project used to be justified against a *render
## pixel* count at 1280x800 -- "36 authored px x the Ally's 0.667 canvas_items
## scale = 24 physical px, the legibility floor". Two things are wrong with
## that, and together they are the mechanism behind the owner's second report
## that the HUD is "way too big" (2026-08-28, after GF-B-005/006 had already
## fixed its placement).
##
## 1. There is no 0.667 scale. `project.godot`'s own `[display]` comment says
##    the ROG Ally is 1920x1080 and that is why this project authors at
##    1920x1080. Authored canvas / device resolution = 1.0. The 0.667 figure
##    is the Steam Deck's 1280x800 panel, and it was applied for months as
##    though it were the Ally's.
##
## 2. It would not matter if it were. `window/stretch/mode="canvas_items"`
##    maps the whole authored canvas onto the whole panel, so an authored
##    pixel is a fixed FRACTION OF THE PANEL no matter what resolution the
##    game renders at. Rendering at 1280x800 makes a glyph blurrier; it does
##    not make it smaller. This was confirmed by rendering
##    `tools/_measure_hud_footprint.gd` at both 1920x1080 and 1280x800 and
##    getting byte-identical authored rects (1700x112 legend, 240x240 minimap,
##    112x180 quick-bar slot) at both.
##
## So the render-pixel model inflated every HUD size by 1/0.667 = 1.5x to
## clear a floor that was already met, and the thing it was protecting --
## whether a human eye can resolve the element at arm's length -- is not a
## function of render resolution at all. It is a function of angular size.
##
## This file is that model. Sizes are derived from panel geometry and a stated
## viewing distance, so the floor can be re-argued by changing a number here
## rather than by re-litigating a remembered crop test.

## --- the panel ------------------------------------------------------------

## ROG Ally: 7.0" diagonal, 16:9. Matches `project.godot`'s `[display]` note.
const PANEL_DIAGONAL_INCHES := 7.0
const PANEL_ASPECT_W := 16.0
const PANEL_ASPECT_H := 9.0

## How far the panel is from the eye, in millimetres. A 7-inch handheld is
## held nearer than a monitor and further than a phone; 450mm is the middle of
## the usual range. Stated as a constant so every floor below can be
## re-derived against a different distance instead of argued about.
##
## [OWNER-ONLY] caveat: nobody on this project can measure how the owner
## actually holds the device. 450mm is an assumption, and it is the ONE
## assumption the numbers below rest on -- shorter would allow smaller text,
## longer would demand larger.
const VIEW_DISTANCE_MM := 450.0

## --- the floors -----------------------------------------------------------
##
## In arcminutes of subtended angle. Reference points, so these are not taste:
## a 20/20 eye resolves detail at 1 arcmin and recognises an isolated letter at
## about 5; continuous reading is comfortable from roughly 16 arcmin (which is
## about where newspaper body text lands at reading distance); short,
## high-contrast, familiar strings stay comfortably legible down to about 10.

## Cap height for a GLANCED label -- a count, a level, a button caption, a
## species name. Short, familiar, high contrast, and read in a fraction of a
## second rather than parsed. 11 arcmin keeps a margin over the ~10 arcmin
## practical floor without sizing a HUD tag like body copy.
const GLANCE_CAP_ARCMIN := 11.0

## Cap height for HUD text that is a SENTENCE -- the objective line, the
## contextual prompt. Genuinely read rather than recognised, so it gets more
## than a tag does, without going all the way to sustained-reading size for a
## string the player sees a hundred times an hour.
const SENTENCE_CAP_ARCMIN := 13.5

## Whole-height floor for a button glyph whose ART HAS LETTERING BAKED INTO IT
## ("LB", "RB", "Y"). This is the one floor that is about rasterisation rather
## than the eye, and it is measured, not assumed:
## `tools/_probe_glyph_ladder.gd` renders the real pad glyphs at 1:1 authored
## pixels across a ladder, and the Kenney badges' two-letter lettering goes
## from mush at 20px, to marginal at 22, to cleanly resolved at 24, to
## comfortable at 26. 26 is the floor here, with the margin deliberately on
## the safe side of the measurement.
##
## `input_glyph.gd::icon()`'s own 36px default is NOT wrong and is left alone:
## it was measured against `cancel`'s keyboard glyph, which bakes THREE
## letters ("ESC") into the same badge and genuinely needs more. The defect
## was applying a three-letter glyph's floor to every glyph on the HUD.
const GLYPH_ARCMIN := 16.0

## Ratio of a font's cap height to its nominal size, for the project's UI
## face. Carried over unchanged from `smoke_hud_handheld_legibility.gd`, which
## backed it out of a real measurement pass (FONT_TINY at 19 measuring ~9
## physical px at 0.667 scale => 19 * 0.667 * 0.7 = 8.9).
const CAP_HEIGHT_RATIO := 0.7


## Millimetres of panel per authored canvas pixel. Depends only on the panel
## and the AUTHORED canvas -- never on the render resolution, for the reason
## this file's header gives.
static func mm_per_authored_px() -> float:
	var panel_w_mm := PANEL_DIAGONAL_INCHES * 25.4 * PANEL_ASPECT_W \
		/ sqrt(PANEL_ASPECT_W * PANEL_ASPECT_W + PANEL_ASPECT_H * PANEL_ASPECT_H)
	var authored_w := float(ProjectSettings.get_setting(
		"display/window/size/viewport_width", 1920))
	if authored_w <= 0.0:
		return 0.0
	return panel_w_mm / authored_w


static func arcmin_for_authored_px(px: float) -> float:
	var mm := px * mm_per_authored_px()
	return atan(mm / VIEW_DISTANCE_MM) * 180.0 * 60.0 / PI


static func authored_px_for_arcmin(arcmin: float) -> float:
	var mm := VIEW_DISTANCE_MM * tan(deg_to_rad(arcmin / 60.0))
	var per := mm_per_authored_px()
	if per <= 0.0:
		return 0.0
	return mm / per


## Smallest nominal font size whose CAP HEIGHT clears `arcmin`.
static func font_size_for_cap_arcmin(arcmin: float) -> int:
	return int(ceil(authored_px_for_arcmin(arcmin) / CAP_HEIGHT_RATIO))


## The cap height a nominal font size actually subtends, for assertions.
static func cap_arcmin_for_font_size(font_size: int) -> float:
	return arcmin_for_authored_px(float(font_size) * CAP_HEIGHT_RATIO)
