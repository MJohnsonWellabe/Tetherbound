# D6 dashed terrain seam — paint-boundary probe, 2026-08-31

**Hypothesis ruled out. No fix applied. `shaders/terrain_ground.gdshader` is
reverted to `origin/main` (verified 0-line diff).** All render evidence below
came from real Godot 4.7 renders in this session (`xvfb-run` +
`--rendering-driver opengl3`, `tools/_audit_d6_paint_boundary_probe.gd`, the
same fixed camera every prior D6 probe used: `EYE_XZ (8,90) -> AIM_XZ
(-40,180)`), not simulated or guessed.

## What this session was asked to do

`SHADER-FIX-STATUS-2026-08-31.md` tried three fade mechanisms (boundary
feather, footprint-vs-tile-size, Terrain3D's own bilerp/region_mip regime)
keyed on same-texture tile position/footprint, and none moved the seam. Its
own "what a real fix still needs" section named one untested lead (items 3-4):
check directly whether `texture_id[0]` changes between the two sides of the
visible dash, i.e. whether this is a **control-map paint-boundary artefact**
(the painted texture itself changing, e.g. path meeting grass) rather than a
same-texture detiling-tile artefact — and to do that check through `EMISSION`
specifically, since that session had already shown an albedo-based readout
(`mat.albedo_height`) was not trustworthy at this exact camera stand.

This session tested that lead directly, before trying any new fade mechanism.

## Method

Added a gated diagnostic to `terrain_ground.gdshader` (public uniform
`diag_paint_boundary_mode`, default `0`, zero behavior change when off):

- **mode 1 (idmap):** `EMISSION` = a hashed colour keyed on
  `texture_ids[3].x` — the base painted texture id at this fragment's nearest
  control-map sample (`float(id)*0.37/0.61/0.89`, `fract()`'d into RGB).
  `id == 0` hashes to pure black, so a solid-black region reads as "one
  texture id, no boundary nearby," not "no data."
- **mode 2 (idedge):** `EMISSION` = white where `texture_ids[3].x` OR
  `texture_ids[3].y` (base or over id) changes across the fragment's own
  screen footprint (`abs(dFdx(id)) + abs(dFdy(id)) > 0.5`), black elsewhere —
  i.e. a direct, per-pixel "is there a control-map paint boundary right here"
  mask, independent of tile position, footprint size, or mip regime.

Both write `ALBEDO = vec3(0)` alongside `EMISSION` so the readout is fully
lighting-independent, per the prior session's own finding.

`tools/_audit_d6_paint_boundary_probe.gd` renders three frames at the
reference stand — unmodified canary, idmap, idedge — and crops all three to
the same box every prior D6 probe used, `(820,510)-(1000,555)`, 6x
nearest-neighbour resample (crisp edges, no filtering to hide or invent a
boundary).

### One real bug found and fixed en route

The first run of this probe showed **zero visible change** for either
diagnostic mode — both looked pixel-identical to the unmodified canary. Not a
hypothesis result: the diagnostic simply never engaged. Cause: the uniform
was first named `_diag_paint_boundary_mode` (leading underscore).
`terrain_ground.gdshader`'s own header states "Uniforms that begin with `_`
are private and will not display in the inspector" — and Terrain3D's
`set_shader_param`/`_get_shader_parameters()` wrapper (see
`playground_world.gd::_apply_ground_shader`'s own comments on this exact
trap) is scoped to the public uniform list it builds when the override shader
is installed, so a private-prefixed uniform silently never gets wired through
that call path, no error either direction. Renamed to
`diag_paint_boundary_mode` (matches every other externally-tunable uniform in
this shader — `mipmap_bias`, `aerial_fade_*`, etc.), re-ran, and the
diagnostic engaged immediately and dramatically (full-frame renders below).
Noted here since it is a real, reusable trap for the next uniform-toggling
probe against this shader.

## Result

**Canary:** `seam-probe-paint-default-crop-isolated.jpg` is the same
composition, same boulder, same grass blades, same dashed seam as
`seam-probe-mip-default-crop-isolated.jpg` from the predecessor session — the
camera stand and scene state match, so this run's crops are directly
comparable to the existing evidence.

**idmap:** `seam-probe-paint-idmap-crop-isolated.jpg` is **uniform solid
black across the entire crop box** — no colour variation anywhere in it. That
means `texture_ids[3].x` (the base painted texture id) is the exact same
value at every sampled fragment in this 180x45-source-pixel region. This
region is not near a paint boundary at all; it is deep inside one uniformly
painted patch.

**idedge:** `seam-probe-paint-idedge-crop-isolated.jpg` is **entirely
blank/black** across the same crop box — zero white pixels. There is no
control-map paint-boundary discontinuity anywhere in this region, at any
point along the dash's own diagonal path through it.

Compare all three crops directly: the dashed seam runs diagonally through
the exact centre of a region the id-map shows is one single, uninterrupted
texture id, and the edge-mask confirms has zero id discontinuity anywhere in
it. **The paint-boundary hypothesis is directly and cleanly ruled out** by
measurement, not inference — this is not "the boundary must be elsewhere," it
is "there is no boundary in the region where the seam visibly runs."

(The full, uncropped `seam-probe-paint-idmap.png`/`-idedge.png` frames also
show real, legible paint boundaries elsewhere in view — a dashed white
boundary line up the mountain material in the upper-left, and along the
actual dirt-path edge on the left of frame — confirming the diagnostic
correctly detects genuine control-map boundaries when they exist; it is not
that the diagnostic fails to fire in general, only that there is none where
this specific seam is.)

## What this adds to the standing diagnosis

Combined with `FOLLOWUP-2026-08-31.md` (per-tile detiling rotation is a
major, confirmed contributor) and `SHADER-FIX-STATUS-2026-08-31.md` (neither
rotation nor shift alone explains it, only both together; footprint-vs-tile
theory ruled out via lighting-independent measurement; region_mip/bilerp fade
theory didn't move the seam either), this session removes the one named
remaining "maybe it's something else entirely" candidate. The eliminated list
is now: clipmap, control map (as a *sin-hash/paint-boundary* artefact —
this session), generic mip-bias blur, debug overlays, footprint-vs-tile-size,
and rotation-only/shift-only detiling in isolation. What is confirmed to
matter: `_texture_detile_array`'s rotation+shift together, within a region
that is provably one single painted texture id throughout — i.e. this is
conclusively a **same-texture, per-tile detiling artefact**, not a paint
artefact of any kind.

## What a real fix still needs (not attempted this session)

`SHADER-FIX-STATUS-2026-08-31.md`'s own next-steps list stands, minus the
now-answered item 3/4:

1. Redo its step-4 tile-checker diagnostic (raw `uv_center`-based per-tile
   colour, not this session's per-texture-id one) through `EMISSION` to get a
   trustworthy picture of where `uv_center` actually steps near the seam —
   this session's tooling (mode-1-style hashed colour, keyed on
   `floor(fma(i_pos, vec2(id_scale), vec2(0.5)))` instead of
   `texture_ids[3].x`) would need only a small edit to do this directly, since
   the paint-boundary theory it was built for is now closed.
2. A fade that reaches genuinely close to zero for BOTH `id_detile`
   components at once, at the real trigger location, should work per step 8
   of the prior session — the missing piece is still identifying that
   location/condition reliably (now further narrowed: it is a same-tile
   phenomenon, confirmed not paint-boundary-adjacent), not the fade mechanics.

Any fix here still needs its own render + `visual-judge` pass per
`ralph/conventions.md` before landing, since it touches ground presentation
directly.

## Evidence

All in `ralph/reports/audit/D6-seam-probe/paint-boundary-2026-08-31/`, all
from the fixed camera above, `capture_check` passed on every shutter (grass
field bound and drawing, confirmed in the run log):

- `seam-probe-paint-default.png` / `-idmap.png` / `-idedge.png` — full
  1280x800 frames, for context.
- `seam-probe-paint-{default,idmap,idedge}-crop-isolated.jpg` — the decisive
  comparison, same crop box `(820,510)-(1000,555)` as every prior D6 probe,
  6x nearest-neighbour resample.

## Branch state

`ralph/BACKLOG-D6-SEAM-PAINT-BOUNDARY` carries this session's commits as real
history (not squashed): adding the gated diagnostic + probe tool, the
uniform-naming fix, and this report. The tip reverts
`shaders/terrain_ground.gdshader` to `origin/main` (verified 0-line diff) —
no shipped behavior changes from this branch as-is.
`tools/_audit_d6_paint_boundary_probe.gd` stays committed as a reusable
diagnostic (see its own header for how to re-arm the shader-side uniform it
needs).
