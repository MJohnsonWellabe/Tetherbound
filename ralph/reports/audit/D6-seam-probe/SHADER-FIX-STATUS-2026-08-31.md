# D6 dashed terrain seam — shader fix status, 2026-08-31

**No working fix landed. This is a status/handover report, not a fix.**
`shaders/terrain_ground.gdshader` is reverted to `origin/main` (verified
0-line diff). All of the render evidence below came from real Godot 4.7
renders in this session (`xvfb-run` + `--rendering-driver opengl3`,
`tools/_audit_d6_mipfilter_probe.gd`, same fixed camera as every prior
D6 probe: `EYE_XZ (8,90) -> AIM_XZ (-40,180)`), not simulated or guessed.

## What this session was asked to do

`FOLLOWUP-2026-08-31.md` confirmed per-tile detiling rotation
(`accumulate_material()`'s `_texture_detile_array`/`random(uv_center)`)
as the dominant cause of the seam and asked for a fix that keeps
detiling working (it fixes a separate 2K-texture-repeat complaint)
while removing/softening the seam at tile boundaries. Three candidate
mechanisms were suggested: cross-fade rotation at tile boundaries,
clamp the derivative rotation specifically, or check for an upstream
Terrain3D fix.

## What was tried, in order, each with a real render at the same camera

All crops below use the same crop box as the predecessor probes,
`(820,510)-(1000,555)`, 6x box-resampled, for direct comparison with
`seam-probe-mip-default-crop-isolated.jpg` (pre-fix) and
`seam-probe-mip-nodetile-crop-isolated.jpg` (detiling forced off) in
the parent directory.

1. **v1 — feather rotation/shift near each detiling tile's own edge**
   (fade to 0 within `DETILE_SEAM_FEATHER` of a tile boundary, computed
   from position within the tile). **No visible change**
   (`shader-fix-attempt-2026-08-31/v1-boundary-feather-no-change.jpg`
   is pixel-for-pixel indistinguishable from the pre-fix crop).

2. **v2 — fade by anisotropic footprint vs. tile size** (fade to 0 as
   the fragment's own `id_dd` derivative magnitude, in tile units,
   grows toward 1 whole tile — the theory being that at this camera's
   distance a fragment's footprint already spans multiple tiles).
   **Also no visible change**
   (`v2-footprint-fade-no-change.jpg`).

3. **Diagnostic: visualize `id_footprint` via `mat.albedo_height`.**
   Read back as very low almost everywhere in the crop — but this
   readout goes through full PBR lighting/tonemapping, so it wasn't
   trusted at face value.

4. **Diagnostic: visualize `random(uv_center)` as a raw per-tile
   checker**, bypassing the fade math entirely
   (`tile-checker-boundary-location.png`). Showed what looked like a
   single hard diagonal boundary lining up with the dash's position —
   seemed to confirm a same-texture tile-edge crossing.

5. **Diagnostic: combined R=checker/G=v1-fade/B=v2-fade in one render.**
   Both fade channels stayed near their unfaded value (~0.7) right
   across the boundary the checker showed — meaning neither v1 nor v2
   was actually engaging there, which explains steps 1–2 but not why.

6. **Surgical test: zero ONLY rotation** (`id_detile.x = 0`),
   unconditionally, everywhere, no position/footprint gating.
   **No visible change**
   (`surgical-rotation-only-zero-no-change.jpg`).

7. **Surgical test: zero ONLY shift** (`id_detile.y = 0`),
   unconditionally. **Also no visible change**
   (`surgical-shift-only-zero-no-change.jpg`).

8. **Surgical test: zero BOTH**, unconditionally, via shader code (not
   the `Terrain3DTextureAsset` API this time). **This DID remove the
   seam** — matches the known-good asset-property result
   (`proof-both-zero-via-shader-removes-seam.jpg`, compare directly to
   `seam-probe-mip-nodetile-crop-isolated.jpg`). This is the one
   genuinely new, confirmed fact this session adds: **rotation and
   shift each individually are insufticient to explain the seam; only
   removing both together does**, which rules out a pure
   derivative-rotation explanation (the earlier working theory) on its
   own.

9. **Diagnostic: redo the footprint readout through `EMISSION`**
   (bypasses PBR lighting/tonemap) with discrete boolean threshold
   bands at 0.02/0.1/0.5 tile units.
   **Read back as fully below 0.02 everywhere in the crop**
   (`emission-footprint-readout-all-below-0.02.png` — solid black
   ground, all three threshold channels off). This is a reliable
   measurement (no lighting in the path) and it directly rules out the
   v2 footprint-vs-tile-size theory: the fragment's footprint here is
   nowhere near a whole tile.

10. **v3 — fade by Terrain3D's own `region_mip`/bilerp regime.**
    Reasoned from the ruled-out list: not a same-texture tile edge
    (steps 4–5 were misleading — see below), not rotation or shift
    alone, not footprint-vs-tile-size. `fragment()` already computes
    `region_mip` to decide whether to bilinearly interpolate the
    control map (`bilerp = region_mip < 0.0`); outside that regime the
    control map is a single nearest-texel lookup, which can flip
    texture id/detiling assignment between adjacent screen pixels for
    reasons unrelated to any one tile's geometry. Threaded a
    `detile_fade` parameter (1 in the bilerp regime, fading to 0 across
    `DETILE_MIP_FADE_WIDTH` octaves outside it) through
    `accumulate_material()`'s signature and all 4 call sites.
    **Also no visible change**
    (`v3-region-mip-fade-no-change.jpg`). Most likely explanation: this
    specific crop's ground, despite the overall ~100m EYE-to-AIM
    distance, is close/magnified enough at this exact screen location
    to sit in the bilerp regime, so `detile_fade` evaluated to ~1
    (no fade) there too — i.e. the theory may still be directionally
    right for genuinely distant ground but doesn't explain the crop
    this whole investigation has used as its ground truth.

## What is now confirmed (safe to build on)

- The seam requires **both** `_texture_detile_array` components
  (rotation and shift) removed together — neither alone suffices, in
  this shader's code path (step 6–8), independent of the
  `Terrain3DTextureAsset` property route (`FOLLOWUP-2026-08-31.md`'s
  original A/B).
- The fragment's own anisotropic footprint (`id_dd`, in tile units) is
  genuinely tiny (<0.02) at the exact seam location, measured through a
  lighting-independent path (step 9). **The "footprint spans multiple
  tiles at distance" theory is ruled out**, not just unconfirmed.
- A raw `uv_center`-based tile checker showed what visually looked like
  a boundary at the seam's position (step 4), but that reading was
  taken through lit `mat.albedo_height`, the same channel later shown
  (step 9, same technique) to be an unreliable calibration source at
  this camera stand. **That "boundary" should be re-examined through
  `EMISSION` before trusting its position again** — it may have been a
  lighting/macro-variation gradient coincidence, not `uv_center`
  actually stepping there.
- Editing this shader and having it take effect in a fresh render is
  confirmed reliable (every diagnostic override was visibly picked up,
  including full-black ground overrides) — there is no shader-cache or
  stale-compile explanation for any of the "no change" results above.

## What a real fix still needs

Someone picking this up should NOT re-try v1/v2/v3 as committed here —
all three are ruled out at this exact camera stand. Promising next
steps, cheapest first:

1. Redo the step-4 tile-checker diagnostic through `EMISSION` (as
   scaffolded and then reverted in this session's commit history on
   this branch — see `git log` for the exact patches, each pushed as
   its own commit with a clear WIP message) to get a *trustworthy*
   picture of where `uv_center` actually steps, before building any
   fade around it.
2. Given step 8's finding, a fade that reaches genuinely close to 0 for
   BOTH components at once at the real trigger location should work —
   the missing piece is identifying that location/condition reliably,
   not the mechanics of applying the fade (that part — multiplying the
   full `id_detile` vec2 by one scalar — is already correct and reused
   across v1/v2/v3).
3. Worth checking directly whether `texture_id[0]` itself changes
   between the two sides of the visible dash (i.e. whether this is a
   control-map paint-boundary artifact — path texture meeting grass —
   rather than a same-texture detiling-tile artifact at all). This
   session's evidence trends that direction (ruling out same-texture
   tile-edge and footprint theories) but never tested it directly.
4. If (3) is confirmed, the fix is likely a fade based on `blend`
   (`DECODE_BLEND(control)`) or on whether a neighbouring control texel
   would decode a different `texture_id[0]`, not on tile position or
   footprint at all.

## Branch state

`ralph/BACKLOG-D6-SEAM-PROBE-FIX` carries every attempt above as its
own pushed commit (real history, not squashed), each with an honest
commit message about what it tested and what it found. The tip of the
branch reverts `shaders/terrain_ground.gdshader` to `origin/main`
(verified 0-line diff) plus this report and its evidence images — no
behavior change ships from this branch as-is.
