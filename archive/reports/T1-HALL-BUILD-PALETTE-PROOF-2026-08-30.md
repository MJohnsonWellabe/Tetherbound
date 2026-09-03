# T1-HALL-BUILD — palette proof, before any geometry

**Lane:** T1-HALL-BUILD. **Date:** 2026-08-30. **Base:** `origin/main` @ `a97f3e84`.

Per the lane brief: prove `HALL_DESIGN_2026-08-30.md` §5's material scheme on
real pixels before starting any massing work. **No geometry changed.** This
is a retint + texture-swap test on the EXISTING castle/works geometry,
rendered through the judge's own stands
(`tools/_judge_capture_arch_0829.gd`), then pixel-sampled. Frames are beside
this file in `ralph/reports/T1-HALL-BUILD/shots/`; the raw per-cell numbers
are in `ralph/reports/T1-HALL-BUILD/shots/palette_measurements.txt`
(reproduce with `python3 tools/_sample_hall_palette.py shots/judge0829`
after running the capture command in that tool's own header).

## What changed (code, not geometry)

- `landmark.gd::_weather_castle` — the castle kit's `LightRock*`/`DarkRock*`
  slots now carry the works' own real `T_UnevenBrick` photo texture
  (triplanar @ `STONE_TILE` 0.28, the works' own measured tiling), replacing
  a generated 96px grayscale noise multiply. `Black*` stays a flat retint
  (design table: "flat" — a void/iron slot has no business reading as
  quarried stone).
- `building_prefabs.json`'s `castle` retint re-tuned against that texture:
  `LightRock` → `#f2e9da`, `DarkRock` → `#c4b39e`, `Black` → `#332c24`,
  `Celing`/`LightWood` → `#6f4f33` (timber), `Banner` unchanged (reserved
  oxblood). `metallic: 0.0` unchanged from T1-CASTLE.
- `stronghold.json` gained `site.stone_light = "#9c9083"` (works exterior
  wall / `_exterior_face_material` tone), matching the design's "works
  exterior walls" ladder step. `stone`/`stone_dark`/`floor_colour`
  untouched — this pass is exterior-facing only.

## Method

Rendered `tools/_judge_capture_arch_0829.gd` unmodified (the judge's own
stands, C-01..C-04 castle, S-ext-01/02 stronghold). For each named frame, a
clean-stone bounding region was picked BY EYE off the actual rendered PNG
(cropped and viewed before measuring — screenshots of every crop are what
decided the box, not a guess), excluding banners, merlons, openings, sky and
grass. Each region was tiled into non-overlapping 64×64px cells (the design's
own patch size) and EVERY cell reported — not one hand-picked box that could
happen to land on an unusually flat or unusually contrasty spot. Metric:
mean RGB, mean luma (Rec.709), and population std-dev of luma per cell.

## Measured numbers

| Region | Cells | Mean RGB (aggregate) | Mean luma | Luma range | Std-dev (mean) | Std-dev range |
|---|---|---|---|---|---|---|
| C-03 corner-close, lit wall | 3 | (168.6, 154.3, 123.8) | 155.2 | 151.1–158.0 | 32.0 | 29.6–34.5 |
| C-04 wall-close-ground, far flank | 6 | (72.4, 71.9, 59.7) | 71.1 | 68.6–76.8 | 14.5 | 12.0–23.1 |
| C-01 approach-gate, left wall | 1 | (185.9, 173.0, 146.6) | 173.8 | — | 26.8 | — |
| C-01 approach-gate, right wall | 1 | (188.2, 173.1, 147.4) | 174.4 | — | 26.6 | — |
| S-ext-02 flank-wide, works wall | 1 | (55.9, 43.0, 31.1) | 44.9 | — | 6.5 | — |
| S-ext-01 ramp-foot, gate face | 4 | (38.9, 35.9, 27.8) | 36.0 | 35.6–36.4 | 5.7 | 5.5–6.1 |

Design's kill criteria (§5/§11): lit-flank mean in **[150,185]**, shaded/
north-face mean in **[95,130]**, patch std-dev **≥ 35**.

## Verdict, stated plainly

**The value fix works. The texture-contrast fix does not clear its own bar
yet.**

1. **The core diagnosed failure is fixed.** The judge measured the old
   castle wall at (212,203,185) — off-white, whiter than the tan albedo
   intended. Every lit castle wall cell measured here lands at **RGB
   ≈ (165–188, 150–173, 120–147), luma 151–174** — inside the design's own
   [150,185] target band, and visibly a warm coursed tan in the rendered
   frames (see `C-03-corner-close.png`, `C-04-wall-close-ground.png`), not
   a white maquette. This is a real, measured win and the frames back it up
   by eye, not just by number.
2. **Std-dev misses the ≥35 bar at every lit-wall cell measured.** Four
   independent lit-wall cells (not cherry-picked — every cell in each clean
   region is reported) measure **26.6–34.5**, averaging in the low-to-
   mid-30s. That is inside the SAME range as the design doc's own quoted
   prior FAILING state — "T1-CASTLE's failed state measured 28.1" — not
   clearly above it. The texture is visibly there in the frames (real
   stone shapes, real highlights, not per-pixel noise), but at the
   design's own 64px cell size the local contrast is not statistically
   different from the state the design was answering. Widening the sample
   to 128–200px pushes std-dev up to 41–43 on the same wall (measured
   separately, not in the table above, kept out of the kill-criteria
   report because 64px is the design's own stated patch size) — so the
   texture DOES carry real low-frequency variation, it is just that a
   single stone's highlight/shadow cycle is closer to 60–90px in these
   frames than to 32px, so a 64px cell sometimes lands mostly on one
   stone face rather than spanning a seam. **Disagreement with the
   design, with evidence:** §5 states the 0.28 tile "at 150m is real
   low-frequency variation, not per-pixel noise" and treats that as
   sufficient; it is real variation, but the 64px kill-criteria cell the
   same section specifies is, empirically, sometimes too small relative
   to that variation's own period to reliably clear std-dev ≥ 35. Either
   the acceptance cell should be larger (128px, where this run measures
   41–43) or the tile should go slightly finer than 0.28 specifically on
   the flattest large faces — a call for whoever owns §5 next, not
   something this test lane should tune its way past.
3. **One castle face (C-04's flank) reads far darker than any lit-wall
   cell** — luma 71, RGB (72,72,60), std-dev 12–23 — well under even the
   design's own "north/shaded face" floor of 95. This is the CURRENT
   castle's own arbitrary orientation relative to the moved sun
   (`art.json` `sun.yaw_deg` confirmed 140, south sky, exactly the fact
   design §12.1 flags), not the future re-sited Hall's specific gate face
   — the re-siting hasn't happened yet, this is existing geometry at its
   existing yaw. It is reported because it is a real castle face that
   reads too dark and too flat right now, not because it is the same face
   the design's "north face" language describes.
4. **The works exterior wall (`stone_light` → `#9c9083`) still reads very
   dark in these two stands** — S-ext-02 flank luma 44.9, S-ext-01 gate
   face luma 36.0 — well under the design's own ~100–115/65–80 target for
   this surface. This is very likely the same confirmed sun-move effect:
   the stronghold has not been re-sited or re-yawed by this lane (that is
   later work, §9 step 1), so these stands are still catching faces that
   were tuned (`_why_retint_backlit`, `_why_retint_panel_noise`) against a
   north-sky sun that no longer exists. **Not concluded as a palette
   failure** — it cannot be cleanly separated from the known siting/yaw
   confound with the CURRENT geometry, and the design itself defers this
   exact face's lighting story to the re-sited gate treatment (§2, §5,
   §6). Re-measure this specific claim once the re-site (§9 step 1) and
   the H-03 stand exist.

## What this means for the design

- **The albedo/value half of §5 is verified and should proceed as
  written** — the castle kit color values are correct against the design's
  own target band, confirmed by eye and by number, not vibes.
- **The std-dev claim needs one of two small corrections before massing
  starts**, not a redesign: either accept a 128px acceptance cell (already
  measured passing at 41–43 on the same wall), or retune the castle's tile
  scale slightly finer than 0.28 on its largest flat faces. This is a
  five-minute call, not a blocker — flagging it now, as instructed, rather
  than quietly tuning past it.
- **The works/stronghold exterior tone cannot be verified from the current
  (pre-re-site) stands** — it needs re-measuring once the site/yaw change
  and the new H-03 stand exist, per the design's own §9 order.
- Nothing here contradicts the design's core thesis ("one stone, one
  scale, one value ladder, both kits") or its diagnosis that a flat colour
  cannot produce coursing — the texture swap visibly fixed the wall's
  READ in every frame. The open item is a measurement-threshold
  calibration, not a wrong mechanism.

## Reproduce

```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 \
  --resolution 1280x800 --script tools/_judge_capture_arch_0829.gd
python3 tools/_sample_hall_palette.py shots/judge0829
```
