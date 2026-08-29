# T1-ARCH-STRONGHOLD — 2026-08-29

Owner verdict this lane answers: stronghold BAD (owner, then reproduced
independently by a Fable judge reading nothing either T1-ARCH lane wrote —
`ralph/reports/JUDGE-VISUAL-2026-08-29.md`, judged at `ralph/LAND-0829A`
commit `1656a71`). The judge called the stronghold "the worst-reading
structure in the world right now" from the flank.

## What the judge actually found

- **From the flank it is a featureless near-black box** (`S-ext-02-flank-wide.png`):
  no roofline articulation beyond one step, no openings, no banners, no
  machinery, no propaganda. Reads as an unlit warehouse dropped on the
  meadow.
- **The approach is one texture swatch** (`S-ext-01-approach-ramp-foot.png`):
  the floor's own cobble material and the wall ahead of it (the same base
  texture, `T_UnevenBrick`, at a different tile scale) collide at the ramp's
  top step — wall stones reading 1-2m wide.
- **The gate is a plain rectangular hole**, no gatehouse, frame, reveal or
  depth.
- **What genuinely works, named as the reference**: the Team Tether pylon
  line — distinct silhouette, cyan crystal accent, correctly grounded, reads
  as danger-faction tech at meadow scale. "The keyart's stronghold language
  — stone facade, banners, scaffolds, apparatus — is exactly what the pylons
  have and the building lacks."

## Why a prior T1-ARCH pass didn't already fix this

An earlier same-day T1-ARCH pass (`b871610`, on `main`/`ralph/LAND-0829A`
before this branch) diagnosed and fixed the VALUE half of the flank defect,
but only on the gate (south, `-z`) face: four fire lights + one sky-fill,
calibrated against the castle's own already-validated brazier recipe. Its
own report said outright: "`S-ext-02`... is still mostly dark — the four
fire points are all on the south face and don't reach that face at all...
Not done: a full `TetherOccupation`-scale dressing pass... is a separate
task." That task is this branch.

## What this lane did

1. **Value on every face, not just the gate.** `data/config/stronghold.json`
   gained a `lights_flanks` block: the same fire+sky-fill recipe re-aimed at
   the `-x`/`+x` walls of `outer_works` and `courtyard` — the two open yards
   with a true, unroofed, meadow-facing perimeter (the three roofed rooms
   behind them are never seen from outside).
2. **Occupation dressing on the true exterior faces**, which
   `_build_trim()`'s existing bands/pillars never reached (they mount 0.35m
   onto a wall's INNER face). New `scripts/world/stronghold.gd` methods:
   - `_build_exterior_dressing()` / `_dress_exterior_wall()`: Team Tether
     hardware (oxblood girder + pillars + a live teal conduit, the same
     materials `_build_trim()` already uses) bolted proud of the outer face,
     plus two banners per wall — the castle's own reused, oxblood-retinted
     `Banner.obj` (no new asset, no new colour).
   - Roofline: a coping course at the wall head (mirroring the existing
     `BASE_COURSE` at its foot) plus a broken merlon row on top of it.
   - `_build_gate_frame()`: proud jambs and a lintel around the entrance,
     giving the "plain rectangular hole" a real frame, depth and shadow
     line, plus two banners flanking it. Its own flank pieces get the same
     coping/merlon roofline (no hardware, to avoid competing with the
     jambs).
3. **Texture-scale collision.** `_build_exterior_facing()`: a thin (6cm)
   decorative skin flush against every true exterior wall face, at a finer
   tile (`EXTERIOR_FACE_TILE_MULT`) than the shared `_wall_material(true)`
   every chamber wall wears — including the roofed interior rooms, which
   this deliberately leaves untouched (a skin layered on top, not a retune
   of the shared material, so CONTENT-0828B's already-validated interiors
   cannot drift).

All of it is config-driven where it varies (`stronghold.json`'s
`lights_flanks`) and gated behind `_opening_on(id, side).is_empty()` —
the same test `_build_wall` already uses to find a true perimeter face — so
none of it can be placed inside a doorway or through a wall the player
actually walks through. No Meshy generation; every asset is reused
(`Banner.obj` from the castle kit, `_tether_material`/`_live_material` from
the pylon/trim vocabulary already validated elsewhere in this file).

## Bug caught before it shipped

The banner mount rotation was wrong on the first pass — assumed the model's
local forward was Godot's usual -Z. Checking `Banner.obj`'s own vertex data
directly showed it is a wall-bracket flagpole whose "forward" is local +X (a
short post near the origin with a horizontal arm reaching to x=0.673m
carrying the flag at its tip). The wrong assumption rendered banners edge-on
— thin red slivers rather than a visible flag — confirmed in the first
re-render below. Fixed by rotating local +X onto each wall's own outward
normal instead.

## Before / after

Frames from the same corrected stand `ralph/JUDGE-VISUAL`'s
`tools/_judge_capture_arch_0829.gd` used (now copied onto this branch),
same commands:

```
godot --headless --path . --import
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_judge_capture_arch_0829.gd
```

(Frames are gitignored; see the attached before/after pairs in-session.)

- `S-ext-02-flank-wide`: BEFORE — featureless near-black box with the pylon
  as the only readable object in frame. AFTER — a warm-lit, materially
  articulated wall: merlon roofline, oxblood girder/pillar hardware, a lit
  teal conduit, banners on the flank.
- `S-ext-01-approach-ramp-foot`: BEFORE — plain rectangular gate hole.
  AFTER — a framed gate with proud jambs, a lintel and banners; finer wall
  tile at the approach.

## Performance

Measured with `tools/perf_render_stats.gd` (structural draw
calls/primitives/objects — the counters that carry to the ROG Ally target;
llvmpipe's own frame TIME does not, per that tool's own header), the
`stronghold_approach` view, before (stashed) vs after this branch's changes:

[FILLED IN BELOW ONCE THE MEASUREMENT RUNS]

## Not attempted / flagged for a future lane

- The castle's own remaining flatness (Quaternius kit texture/AO defect,
  unrelated to the stronghold) — out of this lane's scope, flagged by the
  prior T1-ARCH report and untouched here.
- `stronghold.json`'s own `_comment_ow5d_relocation` flags `yaw_deg: 90` as
  "very likely WRONG" for the corridor's actual north approach bearing — a
  full re-siting job, explicitly left to a future reviewer by that comment,
  not attempted here.
- The three roofed interior rooms (`tether_approach`, `warden_arena`,
  `legendary_chamber`) have no true exterior wall (they are never seen from
  the meadow) and are untouched by this lane by design.
