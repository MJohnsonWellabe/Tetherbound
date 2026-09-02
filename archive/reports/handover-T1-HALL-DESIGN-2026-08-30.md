# HANDOVER — T1-HALL-DESIGN, 2026-08-30

Branch: `ralph/T1-HALL-DESIGN`, off `main` @ `a97f3e84`, pushed.

## 1. What I was asked, and where I got to

Design — not implement — the merged Meadows Hall: the owner's 2026-08-29
directive that the castle IS the Meadows Hall IS the stronghold, one
location redesigned from scratch. A Sonnet lane builds it; a separate
Fable judges it blind.

**The deliverable is complete and pushed:**
`ralph/reports/HALL_DESIGN_2026-08-30.md` — siting (with a fresh
heightfield probe), approach composition at four ranges, a named-mesh kit
plan from the two installed Quaternius packs, a per-slot material scheme
with pre-multiplied value arithmetic, the occupation layer, the interior
route mapping (preserved exactly), a performance budget in structural
counters, capture stands for the judge, and an acceptance list derived
from the board's own CASTLE NOTES plus the judge's named defects.

Supporting artefact: `tools/_probe_hall_site.gd` (throwaway probe, same
8 m-grid method as `_probe_stronghold.gd`, pointed at the corridor
terminus). Its output grid is the ground truth §2 of the design sites
against.

The `perf_render_stats.gd --label=main-baseline` run completed after the
first push and its numbers are now in the design doc's §7: the
`stronghold_approach` view measures **1069 draw calls / 25.8M primitives
/ 1381 objects** — the lightest hero view in the set (village 2080,
band-1 open field 5646), so the budget line (≤ 1230 after) has real
measured headroom behind it.

## 2. Decided vs open

**Decided (with the reasoning in the design doc):**
- Merged site at (8, 7560), yaw 0, ramp_run 40 — on the trail's own
  terminus; the +8 east shift is what keeps the shared floor at ≈ +5.5
  instead of ≈ +7.3 (the west shoulder otherwise binds it under the
  legendary chamber).
- `stronghold.gd` owns everything (gains `_build_hall_massing()`); the
  detached `landmark.gd` castle at (150,7595) retires; the massing is a
  new `meadows_hall` prefab in `building_prefabs.json`.
- One stone across both kits: `T_UnevenBrick` triplanar at the works' own
  measured 0.28 tile, retint colours re-derived to compensate for the
  texture's ~0.49 luminance (the arithmetic is in §5 and was checked
  against the judge's measured 212 render).
- Elevation is delivered by the causeway, terraced massing and exterior
  hoarding DRESSING — no walkable interior catwalks (arena promises and
  the interior camera profile make those a real risk to the yard fights).
  Stated as a deliberate trade in §4.
- The gate face is a SHADED face and the design owns it (see §3 below).

**Open (flagged in the doc, none blocking):**
- Roof accent teal-green vs dark timber (§13 — one tint value either way).
- The invented "torn Meadows-blue banner" story beat (§13 — one prop,
  delete if it oversteps).
- The real ROG Ally light budget still isn't documented anywhere in
  `docs/` (the previous lane looked and I looked); §7's ≤ 18 exterior
  omnis is a reduction-from-measured-46, not a device-derived number.

## 3. What I learned that is NOT visible in the diff

1. **The sun moved and every stronghold-lighting document predates it.**
   `art.json` `sun.yaw_deg` is 140 (VISUAL-LIGHT flipped it from −40):
   the sun is now in the SOUTH sky. Every report in my brief's reading
   list reasons from the north-sky sun. Consequence: the corridor's
   north-facing arrival face — the merged Hall's gate — is backlit at the
   day keyframe. The brief presented the yaw re-derivation as a pure fix;
   it is geometrically right and photometrically expensive, and the
   design compensates deliberately (light stone + the verified fire
   recipe + self-lit occupation on that face). Anyone tempted to flip
   the sun back will break every other south-facing hero face.
2. **The banner-rotation hypothesis in the T1-ARCH-STRONGHOLD handover
   (§5) is FALSE for the castle.** I read `Banner.obj`'s vertices: post
   along Y, arm along +X, cloth thin in Z — so the cloth plane is X-Y and
   a `yaw_deg: 0` banner on a ±z-facing wall is BROADSIDE to the
   approach, not edge-on. The stronghold lane's own slivers came from a
   different mounting choice (arm along the outward normal). Five minutes
   of vertex reading closes an hypothesis that could have cost a lane a
   day.
3. **The T1-ARCH-STRONGHOLD dressing IS on main** (`a97f3e84` has
   `_build_exterior_dressing`, `_build_gate_frame`, `lights_flanks`) and
   I re-rendered the judge's own stands to see it: the flank is no longer
   a black box — crenellation, H-girders, teal conduit and banners all
   read. The judge's BAD verdict frames predate this. What has NOT moved:
   one flat roofline, ~1 m wall stones, dark value, identical H-stamps on
   adjacent walls, and the two-building vista.
4. **The medieval kit is the textured one.** The castle kit has zero UVs
   and placeholder-grey materials; `quaternius_medieval` ships real
   2048px albedo+normal+roughness for brick, roof tile, wood and rock
   trim — and the works walls already use its `T_UnevenBrick` with
   measured tiling. The material unification in the design is mostly
   moving one proven texture onto one more kit, not inventing anything.
5. **Ground truth at the site is characterful**: the player arrives
   through a −7 m bowl; a +4.8 rise sits inside the future courtyard; a
   west shoulder climbs to +7…+9 beside the deep chambers; a −16 m
   ravine cuts just NW of the approach. The board's "castle on a hill,
   not floating" is achievable with the terrain that is actually there —
   `tools/_probe_hall_site.gd` reprints the grid in ~2 min.
6. **Smoke tests are site-agnostic.** All three interrogate the built
   node for route/markers/trainers and walk marker-to-marker, so the
   re-site + re-yaw is invisible to them by construction. They are the
   safety net, not an obstacle.
7. Environment notes: Godot fetch + `--import` took ~10 min total and the
   first import exited 0 (the "second run needed" warning didn't bite
   this session). The judge capture tool re-renders all 11 frames in
   ~8 min under xvfb. `identify`/PIL are absent; `pip install pillow`
   works and is the fastest way to crop/measure reference boards.

## 4. Disagreements with the brief, stated loudly

- §12.1 of the design: the yaw re-derivation is not the free win the
  brief implies (sun flip, above).
- §12.4: "the retint is the lever" is half-true — flat colour at any
  value cannot produce the coursing the judge demanded; texture+retint
  is the lever, and the repo already proves the texture half.
- §12.3: the brief's own correction of the "no architectural board
  exists" claim is itself correct — the board is real, at
  `docs/reference/`, and `building_prefabs.json` cites it.
- The judge's frames (and verdicts 1–2) describe a pre-dressing state;
  a re-diagnosing lane should render fresh frames first (mine did).

## 5. File footprint

- `ralph/reports/HALL_DESIGN_2026-08-30.md` — the deliverable.
- `tools/_probe_hall_site.gd` — throwaway siting probe.
- `ralph/reports/handover-T1-HALL-DESIGN-2026-08-30.md` — this file.
- Nothing else touched. No production code, no scene/config edits, no
  staged evidence — per the design/judge separation.

## 6. What I would do next

1. Land the implementation lanes in the design's §9 order (re-site is a
   config-only first ship; the castle retirement must never precede the
   massing).
2. Have the implementer run the perf before-measurement FIRST (one
   command, §7) — it is the number the +15 % budget line is relative to.
3. When the built result exists, hand the §10 stands to a fresh Fable
   with the §11 acceptance list and nothing this lane or the build lane
   wrote about how good it looks.
4. Independently of this work: the two findings the state-of-tracks doc
   already queues (golden-hour blend, black NPC) still stand and are
   untouched by this design.
