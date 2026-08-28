# HUD and catching lane — log

Branch `ralph/HUD-CATCH`. Two items from the 2026-08-28 owner playtest
(`ralph/OWNER_PLAYTEST_2026-08-28.md`, branch `ralph/OWNER-PLAYTEST-0828`).
Owner-play evidence is CLAUDE.md precedence category 1.

---

## 1. "the hud on screen is way too big" — second report

### The measurement first

`tools/_measure_hud_footprint.gd` (new) walks the live HUD scene, collects
every visible Control that puts ink on screen — leaf widgets plus Panels and
PanelContainers, which fill a stylebox behind their children — and unions their
rects on a sample grid. Transients are reported separately, because the
complaint is about what is on screen while you walk around.

| | before | after |
|---|---|---|
| persistent HUD | **27.37%** of the canvas | **14.20%** |
| with the roster reveal up | 34.38% | 20.11% |

The five largest persistent widgets before, as a share of the screen:

| widget | rect | % screen |
|---|---|---|
| ExplorationLegend | 1700x112 | 9.18% |
| HotbarPanel | 676x232 | 7.56% |
| ObjectiveBlock panel | 420x170 | 3.44% |
| Minimap | 240x240 | 2.78% |
| VitalsCluster plate | 348x138 | 2.32% |

### The diagnosis

Every HUD size in this project was justified against a **render pixel** count
at 1280x800: "36 authored px x the Ally's 0.667 canvas_items scale = 24
physical px, the legibility floor." Both halves of that are wrong.

**There is no 0.667 scale.** `project.godot`'s own `[display]` comment states
the ROG Ally is 1920x1080 at 7 inches, and that is why this project authors at
1920x1080. Authored canvas / device resolution is 1.0. 1280x800 is the Steam
Deck's panel, and it was used for months as though it were the Ally's.

**It would not matter if it were.** `window/stretch/mode="canvas_items"` maps
the whole authored canvas onto the whole panel, so an authored pixel is a fixed
FRACTION OF THE PANEL at any render resolution. Rendering at 1280x800 makes a
glyph blurrier; it does not make it smaller. Verified rather than asserted:
`_measure_hud_footprint.gd` run at 1920x1080 and at 1280x800 returns
byte-identical authored rects (1700x112 legend, 240x240 minimap, 112x180
quick-bar slot) and the same 26% occupancy at both.

So every legibility pass since OP21 multiplied its target by 1/0.667 = 1.5x to
clear a floor that was already met, and the quantity it was protecting — can a
human eye resolve this at arm's length — is not a function of render
resolution at all. It is a function of **angular size**.

The consequence, at 450mm handheld viewing distance on a 155mm-wide panel
(1 authored px = 0.0807 mm):

| element | authored | subtends |
|---|---|---|
| legend button glyph | 66 px | **40.7 arcmin** |
| quick-bar item icon | 64 px | 39.5 arcmin |
| quick-bar binding badge | 36 px | 22.2 arcmin |
| every HUD micro-label ("Lv 1", "x12") | font 38 | 16.4 arcmin cap height |

For reference: a 20/20 eye resolves detail at 1 arcmin and recognises an
isolated letter at about 5; continuous reading is comfortable from about 16,
which is roughly where newspaper body text lands at reading distance. The HUD
was setting the string "Lv 1" at newspaper-body size.

### Resolving the tension rather than picking a side

"Too big" and "must stay legible on a 7-inch panel" are both owner
requirements, and the brief was right that a fix which drops text under the
legibility floor trades one complaint for another. It does not have to: the
floor was being **overshot by 1.5x**, not approached. Restating it in angular
terms lets the HUD get materially smaller while every element stays above a
floor that is now derived from panel geometry instead of from a resolution the
device never renders at.

`scripts/ui/hud_scale.gd` (new) is that model — panel geometry, a stated
450mm viewing distance, and three floors:

- `GLANCE_CAP_ARCMIN` 11.0 — labels, counts, badges: recognised, not read. -> font **26**
- `SENTENCE_CAP_ARCMIN` 13.5 — the objective line, the contextual prompt. -> font **32**
- `GLYPH_ARCMIN` 16.0 — a button badge with lettering baked into the art. -> **26 px**

The glyph floor is the one that is about rasterisation rather than the eye, so
it is **measured, not assumed**. `tools/_probe_glyph_ladder.gd` (new) renders
the real pad glyphs at 1:1 authored pixels across a ladder;
`shots/hud_scale/glyph_ladder_zoom.png` is that render at 4x nearest-neighbour.
The Kenney badges' two-letter art is mush at 20px, marginal at 22, cleanly
resolved at 24, comfortable at 26. Not 36.

`input_glyph.gd::icon()`'s own 36px default is **not** wrong and is untouched
(that file is `ralph/DPAD-COLLISION`'s anyway): it was measured against
`cancel`'s keyboard glyph, which bakes THREE letters ("ESC") into the same
badge and genuinely needs more. The defect was applying a three-letter glyph's
floor to every glyph on the HUD.

### The half the tests never had

Every check in `smoke_hud_handheld_legibility.gd` was a FLOOR. That is how the
HUD reached 27.4% with 40-arcmin glyphs on it: each legibility pass could only
push a number up and nothing could push back. A floor-only suite does not
encode a size requirement, it encodes a direction.

So the suite now also carries ceilings — `OVERSIZE_FACTOR` 1.6x on each floor,
and `MAX_HUD_OCCUPANCY` 20% measured off the live scene. That last one is the
owner's "way too big" as a build failure.

### What changed

`scripts/ui/hud_scale.gd` new; `playground_hud.gd`, `party_strip.gd` and
`scenes/ui/playground_hud.tscn` re-derived against it; the legibility suite
re-pointed at the new model with the overlap/containment checks untouched.

Two things fell out that are worth naming:

- The minimap did not shrink when `MINIMAP_SIZE` did, because `minimap.gd`
  carries its own 240x240 `custom_minimum_size` — `MINIMAP_SIZE` had only ever
  driven the widget's POSITION. Caught by the footprint tool still reporting
  240x240 after the constant was already 184.
- A first cut of the roster row to 304 (the naive 26/36 scaling of the width
  alongside the font) reopened the name-elision defect GF-B-006 had fixed:
  "Galew" where 420 had held "Galewi...". Most of a row is not text — rail,
  chip, HP bar, separations are fixed furniture — so scaling the row with the
  font takes far more than its share out of the name column. At 336 with the
  bar cut to 44, the roster now shows **"Galewisp" in full**, which the
  1.5x-inflated HUD never did. See `shots/hud_scale/roster_compare.png`.

### Evidence

- `shots/hud_scale/before.png`, `shots/hud_scale/after.png` — the HUD through
  the real render path at 1920x1080, opengl3 under xvfb.
- `shots/hud_scale/roster_compare.png` — the roster column, before over after.
- `shots/hud_scale/glyph_ladder.png`, `glyph_ladder_zoom.png` — the render the
  glyph floor is derived from.

### What I did not prove

- **How any of this feels in the hand.** [OWNER-ONLY]. I measured geometry and
  counted pixels; I did not hold the device.
- **The 450mm viewing distance is an assumption**, and it is the one assumption
  every arcminute figure above rests on. Held closer, the HUD could go smaller
  still; held further, these sizes are near the floor rather than above it. It
  is a named constant in `hud_scale.gd` so it can be re-argued by changing one
  number.
- **Whether the exploration legend needs to be permanent at all.** It is four
  button reminders and was the single largest widget on the HUD; it is now
  2.90% of the screen rather than 9.18%, but it is still always there. Retiring
  it once the player has demonstrably used those buttons would save that too.
  That is a design decision about how much teaching the HUD owes a returning
  player, not a scale fix, so it is flagged rather than taken.
