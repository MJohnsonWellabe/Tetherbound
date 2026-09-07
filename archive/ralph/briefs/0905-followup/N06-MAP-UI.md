# N06-MAP-UI

**Source:** W11-ALPHA-PINS-0904's report, its own round-3 blind judge verdict.

## Why
W11's own blind judge found the alpha-pin feature legible, but flagged the map screen itself
carrying pre-existing legibility defects that are now more consequential because a threat pin
lives on this screen. Fixing them makes the map (and the new pin) actually readable.

## Owns
`scripts/ui/tab_map.gd` and `scripts/ui/minimap.gd` only.

## Do, in priority order named by the judge

**1. Fog is inverted — the single largest defect on the screen.** The surveyed/explored
corridor renders DARKER (measured RGB(5,5,7)) than the unexplored field (RGB(17,26,31)) — a
1.16:1 contrast in the wrong direction. Explored area should read lighter/clearer than fog of
war, not darker. Find the fog-of-war draw pass and correct the value relationship.

**2. Legend swatches are indistinguishable.** Every legend entry (including the new "Alpha"
row) draws as a near-identical pale glyph. Fix: render the legend swatches using the actual
marker art at its real colour and size, not a generic placeholder swatch.

**3. Two typefaces on one screen.** Panel chrome uses a humanist sans; everything drawn
inside the map canvas uses a condensed techno face. Pick one (whichever the rest of the HUD
uses) and apply it consistently within the map canvas.

**4. Text boxes are drawn with no container and will collide with terrain.** DISCOVERED
REGIONS / DESTINATIONS text is drawn directly onto the map canvas; fine at low fog-of-war
coverage, but will overlap revealed terrain as more of the map is surveyed. Give these a
backing panel, or otherwise anchor them off the terrain-drawing layer.

**5. No north indicator, no scale bar; footer legend sandwiched between control-hint rows
reads as a third keybind row.** Add a simple north arrow and scale bar to the map canvas.
Give the legend visual separation from the control-hint rows above and below it (a divider or
distinct background block).

**6. Map zoom has no controller binding.** `[Minus]`/`[Equal]` only, on a controller-first
project. Add a pad binding (check `data/config/input_contexts.json` or wherever other map
actions already define their pad binding, and follow the same pattern).

**7. Shared label treatment loses danger labels in greyscale.** `_draw_string_legible`'s
current treatment lets "ALPHA TRAILPUP" collapse to L≈136 in greyscale while "GRANDPA'S
HOUSE"/"THE VILLAGE" sit at L=255 — the danger label is the DIMMEST text on screen. Fix in the
shared label-drawing function (used by every map label, not just alpha pins): give labels
weight via a white core / heavier outline rather than relying on hue alone, so value contrast
holds in greyscale too.

**8. Alpha marker's rosette silhouette gets contaminated by terrain under it.** The mossy
path/terrain texture under a threat pin fills the notches between the rosette's lower spikes,
degrading the silhouette. Fix by having whatever draws a threat pin also knock back the value
of the terrain directly under it (a small darkening/backing disc), same underlying issue as
item 1's fog contrast.

## Verify
- For each fix, a rendered or captured frame of the map screen before/after, at whatever
  fog-of-war coverage level makes the defect visible (W11's own report names the exact
  coverage — check it).
- Run a fresh blind-judge round against the SAME frames/stands W11's round-3 judge saw (find
  the tool and stand list in `ralph/reports/W11-ALPHA-PINS-0904/REPORT.md`), telling the judge
  nothing about what changed. Confirm each of the 8 items above is resolved or, if not fully,
  say precisely what changed and what didn't.
- `test_alpha_pins.gd` and `smoke_alpha_pins.gd` (already exist, from W11) must still pass —
  you are not changing pin logic, only how the map draws.

## Acceptance
All 8 items addressed. A fresh blind judge, shown only the after frames with the same
questions the original judge answered, confirms the fog inversion and label-legibility fixes
in particular (the two "largest defect" findings) are resolved.
