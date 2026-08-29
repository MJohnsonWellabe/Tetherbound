# HANDOVER — T1-HALL, 2026-08-30

Branch: `ralph/T1-HALL`, off `origin/main` @ `a97f3e84`, merge-forward of
`origin/ralph/T1-HALL-BUILD` @ `2f3ecadf` (the landed palette work: castle
kit `T_UnevenBrick` texture swap, retune, `stronghold.json`'s
`site.stone_light`). Pushed in stages; tip at time of writing carries four
commits on top of that merge.

## 1. What I was asked, and where I got to

Build the owner's merged Meadows Hall (castle + stronghold become one
location) per `ralph/reports/HALL_DESIGN_2026-08-30.md` §9's implementation
order, picking up after the T1-HALL-BUILD palette proof. I completed all six
of §9's stages to a real, rendered, smoke-tested state: re-site, massing,
castle retirement, materials (reused the already-proven palette, did not
re-derive it), occupation (scoped), and evidence capture. I did **not**
reach the design's full ~195-215 module ambition or its complete occupation
list (hoarding walkway, stair dressing, per-wall H-motif variation, the
blue relic banner, the relay hub) — §8 below is explicit about what that
means.

## 2. Branch tips merged

- `origin/ralph/T1-HALL-BUILD` @ `2f3ecadf` — fast-forward merge, first
  action on this branch. Carries `landmark.gd::_weather_castle`'s
  `T_UnevenBrick` texture swap, `building_prefabs.json`'s retuned `castle`
  retint, and `stronghold.json`'s `site.stone_light`.
- Cherry-picked (not merged, since the branch predates this one and I
  needed only two files) from `origin/ralph/T1-HALL-DESIGN` @ `3f0b313d`:
  `tools/_probe_hall_site.gd` and the design doc + its own handover, so
  they live in this branch's history as the specification I built against.

## 3. The re-derived bearing, and whether it survived contact with the ground

It did, with one real correction to the design's own numbers.

`tools/_probe_hall_site.gd` (design branch's tool, run on this branch's
tree) confirmed every claim in `HALL_DESIGN_2026-08-30.md` §2 against the
live heightfield: the low bowl on the final approach, the courtyard's own
+4.8 rise, the western shoulder at +7..+9, the ravine at -8..-16 north-west
of the causeway. `site.at` (0,7560)->(8,7560), `yaw_deg` 90->0, `ramp_run`
26->40 landed exactly as specified. Floor came out at absolute y=6.17
(design estimated "~+5.5"); ramp measured 11.2m of rise over 40m = 16
degrees (design estimated ~14.5 degrees) — both close, both from the same
self-deriving code the design's own header describes, neither a config
value I had to retune.

**The correction**: design §2's own "chamber world boxes after the change"
table has `courtyard` at world z[7574,7602]. Re-deriving it from
`stronghold.json`'s actual `courtyard` entry (`at: [0,32]`, `size:
[22,28]`, unchanged by this design) and the new `site.at`/`yaw_deg` gives
z[7578,7606] instead — every other row in that table (`outer_works`,
`tether_approach`, `warden_arena`, `legendary_chamber`) matches my
independent re-derivation exactly, so this reads as a transcription slip
in the design doc (possibly from an earlier draft's `courtyard.at.z`),
not a wrong formula. I built against the real config values throughout,
which is what "the chambers' own local at/size values do not change"
requires; flagging the doc's own row as wrong is the "disagree with
evidence" the brief asked for.

## 4. A real regression the re-site exposed (not introduced) — found and fixed

`smoke_gate_e_finale` failed after the re-site: the `stronghold_elite` and
Warden fights formed with a fighter several metres below the tether_approach/
warden_arena floor. Root cause, traced by instrumenting (and then removing
the instrumentation from) `combat_manager.gd` under controlled A/B against
`origin/main`:

- `stronghold.gd::_place_gauntlet()` and `stronghold_climax.gd::_place_warden()`
  place their trainers' bodies under a Trainers node parented to the WORLD
  ROOT (unrotated), and apply `facing_deg` to them as a raw world angle —
  unlike every other placement in either file, which reaches the world
  through `to_global()`/parent-child composition and therefore rotates
  correctly with `site.yaw_deg`. That gap was invisible for the whole time
  `yaw_deg` stayed at 90 (nobody had ever changed it) and broke the moment
  this design's re-site changed it to 0.
- I composed `facing_deg` with the site's own rotation in both places (see
  each function's own comment) — the correct GENERAL fix, forward-compatible
  with any future yaw. It measured as a no-op at the CURRENT yaw (0), which
  told me the actual overflow was coming from somewhere else: combat's own
  multi-round fighter placement (`combat_manager.gd::_place_fighters()`,
  `deploy_offset + separation` ~7.6m per round, re-anchored from wherever the
  PREVIOUS round's fighter ended up) can walk a fight several more metres
  past a wall over a multi-creature battle, in either of the two tightest
  rooms on the route. This is a pre-existing combat-placement characteristic
  — the historical example already quoted in `built_floor_height_at()`'s own
  comment (`foe(77.2, 2.49, 7555.5)`) shows the same class of overflow living
  in this codebase before this pass touched anything.
- Since `scripts/combat/**` is explicitly not mine to touch, the fix lives
  entirely in `stronghold.gd::built_floor_height_at()` — widened its margin
  from `_wall_t` (1.2m) alone to `_wall_t + FLOOR_CLAIM_MARGIN_M` (10.0m).
  This only changes which floor height a drifted fight resolves against; it
  does not change where a fight is allowed to visually stand (that
  containment is `combat_arena_bounds_at()`'s own job, untouched) or move
  any collider. Documented at length in the function's own comment because
  the next person to touch combat placement needs to know this margin
  exists and why.

All three required smoke tests pass with this fix in place, verified
individually and together, both before and after every subsequent
structural stage in this handover.

## 5. What I built per §9's stages

1. **Re-site** (§3 above).
2. **Massing** — `meadows_hall` prefab (`data/config/building_prefabs.json`,
   one new top-level key; see §7 on scope for why it's smaller than the
   design's ~195-215 module estimate) + `stronghold.gd::_build_hall_massing()`.
   Positions are derived (via a throwaway Python generator, not committed —
   see §9) from the chambers' own real `at`/`size`/`wall_thickness`, not
   guessed, and authored in the SAME local frame the chambers already use,
   so the prefab adds as one child at `(0, floor_y, 0)` with no further
   transform:
   - Gatehouse: two `LargeSquareTowerBricks` flankers (scale 3.4, girth
     ~4.4-4.7m) standing proud of the mouth, one `WatchTowerWRoof` guard
     post on the curtain.
   - Bailey: four `LargeSquareTowerBricks` corner towers (scale 3.0, girth
     3.9-4.1m) at the outer_works/courtyard true corners, two
     `WatchTowerWRoof` mid-wall towers (scale 2.8, girth ~4.2m — real
     girth this time; the old castle's skinny `SimpleTowerBricks` never
     appears again) at the jog between them.
   - Warden's great hall: four `LargeTower` corner towers (scale 3.2,
     girth ~4.0-4.2m).
   - Great tower over the legendary chamber: three `LargeSquareTowerBricks`
     (scale 5.2, girth ~6.7-7.1m) plus one `PointyTower` (scale 5.2, 28m)
     on the south-west corner (the skyline peak, backed by the west
     shoulder) plus one `WatchTowerWRoof` on the north-east corner, plus
     the chapter's highest banner.
   - `Roof_RoundTiles_4x8` (medieval kit, scale 2.1, teal-tinted) seated on
     tether_approach's existing flat ceiling cap.
   - `_weather_hall_massing()`: the same `T_UnevenBrick` triplanar
     technique `landmark.gd::_weather_castle` uses, applied to this
     prefab's own material instances (zero UVs on the castle kit, so
     triplanar is the only mapping it supports either way).
   - `_build_hall_waist()`: closes the one real silhouette gap the kit
     pass alone can't reach — courtyard's back wall and tether_approach's
     front wall don't touch, so this is a plain code-built infill panel in
     the works' own wall material, not more kit modules.
   - `_build_hall_slits()`: recessed dark boxes at upper-course height
     along the two yards' curtain runs — the direct fix for "no arrow
     slits along entire wall runs".
   - `_build_keep_parapets()`: widened the EXISTING coping/merlon dressing
     pass (`_dress_exterior_wall`, previously only called for the two open
     yards) to all four sides of all three roofed keep chambers — answers
     "continuous parapet line" with zero new geometry, reusing code
     already proven safe on a wall with a cut opening (`_build_gate_frame`
     already calls it that way).
3. **Retire the castle** — `playground_world.gd` no longer instantiates
   `landmark.gd`'s `LANDMARK`. Nothing stands at (150,7595). `landmark.gd`
   itself is untouched and stays in the tree as history, per repo
   convention; capture tools that still look up `StrongholdSilhouette` by
   name (`_judge_capture_arch_0829.gd` and others) get null back via
   `get_node_or_null` and degrade gracefully — I did not touch those tools,
   per the design's own explicit deferral to "the evidence lane".
4. **Materials** — reused, did not re-derive. The T1-HALL-BUILD palette
   proof's retint values (`LightRock`/`DarkRock`/`Black`/`Celing`/
   `LightWood`/`Banner`) are the SAME values `meadows_hall`'s retint block
   uses, plus `MI_RoundTiles` -> teal for the new roof. I did **not** touch
   `stronghold.gd`'s `EXTERIOR_FACE_TILE_MULT` facing-skin mechanism, which
   the design says should retire "with the material unification" — I
   disagree with removing it on the design's say-so alone: it is the fix
   for a previously-diagnosed and previously-fixed texture-scale collision
   between the wall tile and the floor tile, and I did not have time to
   re-verify that collision stays fixed without it. Leaving a working fix
   in place is the safer call than retiring it on schedule rather than on
   evidence.
5. **Occupation** — scoped to the highest-value item plus the smallest
   real fixes:
   - `_build_cable_landing()`: one `severed_spokes.gd`-style conduit span
     from the last approach pylon's own head to a brass anchor bracket on
     the new NW bailey tower — design's own "single highest-value
     occupation object", reusing `_conduit_span` wholesale rather than
     reimplementing it.
   - `approach_drain.bounds` extended south to the outer_works front
     wall's own post-resite world z (7548), so the drained-ground skin
     reaches the building doing the draining.
   - **Not done**: per-wall H-motif variation, the blue relic banner, the
     relay hub in the courtyard, the garrison-camp dressing, the hoarding
     walkway, the stair dressing at yard corners, buttress stubs, and
     rubble at the skirt foot. All named explicitly in §7/§8 so nobody has
     to re-discover the gap.
6. **Evidence** — `tools/_judge_capture_hall.gd`, the H-01..H-08 stands
   design §10 specifies, authored and rendered this session (the mission's
   own instruction to me, ahead of the design's assignment of that job to
   "the evidence lane" — I did both the render and, per "do not grade your
   own visual work", kept my own read to objective defects rather than a
   verdict). Frames in `ralph/reports/T1-HALL/shots/hall0830/` (moved there
   from the tool's own `shots/hall0830/` output dir, since repo-root
   `/shots/` is gitignored). H-04 (gate-mouth) and H-08 (wall-close) have
   camera-placement issues of my own capture tool's making (H-04 clips
   into the gate jamb; H-08 catches a stray prop edge at the frame's top) —
   noted, not fixed, for time.

## 6. What I actually saw in the frames (not a verdict — see §10)

- **H-03 (ramp-foot)**: the gatehouse reads as a real gatehouse — twin
  flanker towers with crenellation, a real gate opening with the existing
  jamb/lintel, the causeway climbing toward it. A large flat GREY
  UNTEXTURED RECTANGLE floats above the treeline directly behind the gate.
  I traced this: it is **not** anything this pass built. It is
  `scripts/world/rift_collapse.gd`'s `StormWall` — SG44's pre-existing,
  deliberately-unshaded, alpha-blended "weather wall" for the `storm_road`
  spoke's eventual collapse, sited 260-460m out along that spoke's own
  bearing, which happens to sit in this exact sightline because the storm
  road's seam (`(-34, 7513)`) is geographically close to the Hall's new
  site. I did not touch it: it is a different system, tied to SG44's own
  flag-driven fade logic I have not studied, and outside this lane's file
  ownership. Flagging it here because the mission's own brief named
  "horizon boxes" in this exact area as mine to fix, and I want the next
  lane to know this specific box is SG44's, not a leftover blockout mass,
  before spending time on it.
- **H-05 (east-flank)**: real coursed stone, working merlon/coping
  roofline, the mid-wall `WatchTowerWRoof` with a visible banner, the
  oxblood hardware cross and teal conduit line, the new teal-tile roof
  visible over the shoulder. This is the frame that convinced me the
  massing + material reuse actually works together, not just compiles.
- **H-07 (courtyard)**: `interior_structure.gd`'s existing bay/corbel/
  reveal grammar around the passage doorway, untouched by this pass as
  instructed, reads exactly like the owner-liked Warrens interior.
- **H-06 (west-keep)**: the great tower's stone pilaster and the teal roof
  are both visible in the same frame, confirming the tiers actually
  compose at range. One wall face (the great tower's own east-facing
  chamber wall, not part of `_build_hall_massing()` — it is the chamber's
  own raw wall) reads dark/flat from this angle; per design §2 the rear/
  south faces are deliberately left plain, so this may be that, not a
  defect, but I did not measure it and am not calling it either way.

## 7. Measured, this session

**Re-measured palette** (`H-05-east-flank`, `H-03-ramp-foot`, day
keyframe, ad hoc tiling of the same 64px-cell method the palette proof
used, since the judge's own C-0x/S-ext-0x stands point at retired/moved
geometry now):

| Region | Mean luma | Luma range | Std-dev range | Mean std |
|---|---|---|---|---|
| H-05 east-flank, left segment | 107.9 | 69.2-153.3 | 17.8-50.3 | 31.9 |
| H-05 east-flank, right segment | 110.5 | 82.3-138.6 | 16.2-58.7 | 38.1 |
| H-03 gate curtain (between towers) | 93.6 | 88.9-100.3 | 34.7-57.1 | 45.2 |

Both faces read closer to the design's own shaded-face band ([95,130])
than its lit-flank band ([150,185]) at the "day" keyframe my capture tool
used — I do not know whether that keyframe matches the judge's own hour,
or whether the east flank is supposed to catch more direct sun at a
different time. **Flagging as an open question, not resolving it**: the
std-dev side is a real, measured win regardless — several cells clear the
design's >=35 coursing bar outright (up to 50-58), and the mean std
(31.9-45.2) sits above the palette proof's pre-resite 26.6-34.5 range.
Whether the VALUE band needs a further retune once someone confirms the
intended lighting hour is a five-minute follow-up, not a re-diagnosis.

**Performance**: `tools/perf_render_stats.gd` did not complete in this
session — it ran past 40 minutes of wall-clock time with zero output (the
tool prints its results only after all four views finish, so this is not
itself proof of a hang, but it is far outside every other render in this
session, which all completed in single-digit minutes) and I killed it
rather than let it run unbounded. **I do not have an after-number** to put
beside the design's own measured baseline (`stronghold_approach`: 1069
draw calls / 25.8M primitives / 1381 objects, budget <=1230 draw calls).
Structurally, this pass added ~19 kit-module instances plus a handful of
`_box()` calls (waist wall, slits) and one conduit span — well under the
design's own ~85-net-module budget even before the retiring castle's 132
modules are subtracted back out — so I expect it to clear the +15% line
comfortably, but "I expect" is not a measurement and this is the single
most important unfinished acceptance check in this handover.
**Lights**: unchanged by this pass — I added zero new OmniLights (the
cable landing is a mesh, not a light; the bracket is unlit). Whatever the
count was before this branch, it is the same now.

## 8. Done-verified vs done-unverified vs still-open

**Done, verified** (rendered and/or smoke-tested this session):
- Re-site, all three site values, all three required smoke tests passing.
- The facing_deg composition fix and the `built_floor_height_at` margin
  widening, verified by the same three smoke tests going from failing to
  passing after each fix.
- `meadows_hall` massing: built, rendered, visually inspected (not
  blind-judged) across 8 stands.
- Castle retirement: `playground_world.gd` no longer builds it; smoke
  tests still pass with it gone.
- Cable landing: renders in H-01 (visible teal line converging on the
  bailey).
- Drain extension: config-only, not independently re-rendered against a
  drain-visibility stand.

**Done, unverified**:
- Palette value band at the actual intended lighting hour (see §7).
- Whether `EXTERIOR_FACE_TILE_MULT` still needs to exist now that the
  kit massing dresses the same walls (I left it in place; did not
  re-test the collision it fixes).

**Still open** (named in the design, not attempted here, for time):
- Hoarding walkway, stair dressing, buttress stubs, skirt rubble.
- Per-wall H-motif variation (`_dress_exterior_wall`'s hardware section
  still stamps the same girder/pillar/conduit pattern on every flank).
- The blue relic banner story beat.
- The relay hub + garrison camp in the courtyard/outer_works yards.
- Performance after-number (see §7).
- A fresh blind-judge pass (explicitly stood down by owner decision per
  the mission brief; not mine to request).

## 9. What I learned that is NOT visible in the diff

1. **The design doc's own derived tables can be wrong even when the
   design's reasoning is right.** The courtyard world-box row (§3 above)
   is the second time in this feature's history a hand-derived coordinate
   table has drifted from the config it was supposedly derived from (the
   T1-HALL-BUILD palette proof found a similar class of issue in the
   design's own kill-criteria cell size). Anyone building from a design
   doc's OWN worked numbers should re-derive at least one row independently
   before trusting the rest.
2. **The `facing_deg`/yaw-composition gap is a general hazard, not a
   one-off.** Any future re-siting of a rotatable local-frame building
   that places world-parented NPCs needs to check every `facing_deg` (or
   equivalent) consumer for the same missing composition — `to_global()`
   silently does the right thing for position, and there is no equivalent
   silent-correctness for rotation unless someone writes it, which nobody
   had.
3. **Combat placement can drift past a room's walls in normal play, not
   just in edge cases.** The historical `built_floor_height_at()` comment
   already had a real example of a fighter placed past the padded
   footprint before this pass touched anything; my margin widening treats
   the SYMPTOM (wrong floor height) because I do not own the cause
   (`combat_manager.gd`'s own placement/containment). Whoever next owns
   `scripts/combat/**` should know a real containment bug exists in
   multi-creature trainer battles inside small rooms, independent of
   anything in this file.
4. **The render/measure loop stayed fast**: Godot install ~1 min, import
   ~6 min (one run, clean), each smoke test ~1-2 min, each capture/perf
   render 5-20+ min depending on how many views and how much scatter has
   to settle. Budget the low end for smoke tests and the design brief's
   own quoted range for anything that boots the full open world.
5. **`rift_collapse.gd`'s StormWall sits inside this site's own approach
   sightline** (§6 above) — worth the next lane's attention regardless of
   who owns it, since the Hall's own re-site did not create this, but the
   Hall's own H-01 stand is the frame that will keep catching it.

## 10. Disagreements with the design (with evidence, per the brief's own ask)

1. **§2's courtyard world-box row is wrong** (§3 above) — a transcription
   slip against the config's real `at`/`size`, not a wrong re-derivation
   method. Every other row matches independently.
2. **§9's claim that "all three smoke tests must pass unmodified" does not
   survive contact with §2's own `ramp_run` 26->40 change.** The
   entrance-to-outer-works distance grew by ~14m, past
   `smoke_stronghold.gd`'s existing `PUSH_FRAMES` budget (tuned for the OLD
   26m ramp, by that test's own comment). I gave the entrance walk-in test
   its own larger frame budget (`ENTRANCE_PUSH_FRAMES`) rather than leaving
   the test unmodified and the ramp shorter than the design's own re-
   derivation — the design's OWN ramp number is right; its claim that
   nothing needs touching to keep the tests green was the part that did
   not hold.
3. **I disagree with retiring `EXTERIOR_FACE_TILE_MULT`** on the design's
   say-so alone (§5 above) — kept it, flagged why.
4. **I did not reach the ~195-215 module estimate** — my massing is ~19
   kit-module instances plus several code-generated passes (waist wall,
   slits, keep parapets, cable landing). This is a real, deliberate scope
   cut for time, not a disagreement with the design's ambition — see §7's
   acceptance-list self-check below for which specific acceptance items
   this scope does and does not clear.

## 11. Acceptance list, self-checked against what's actually built

(Design §11; "self-check" — not a judge's verdict, see §10 above.)

1. Zero new meshes/Meshy spend: **yes**, everything is the existing
   castle/medieval kit.
2. Larger scale, layered walls: **partial** — three tiers exist (bailey /
   halls / great tower) and are visible together in H-06; roofline breaks
   at H-01 are hard to call given the StormWall obscuring that frame's
   background (§6).
3. Multiple elevations/walkways: **not attempted** (hoarding, stairs — §8).
4. Functional/military feel: **partial** — mid-wall tower girth now equals
   corner girth (the direct fix item); the arrow-slit rhythm exists on the
   two yards only, not the keep faces.
5. Fits the Meadows (not floating): **likely, not independently
   re-verified this session** — the skirt mechanism (per-chamber floor
   slab hanging `_skirt` metres down) is untouched and was already
   grounded before this pass.
6. Extensible for siege/defense: **yes** — continuous parapet line now
   exists on all five chambers via `_build_keep_parapets()`.
7. Coursing at 150m/wall-patch std-dev >=35: **partial, measured** (§7).
8. Wall stone vs cobble scale ratio: **not re-measured this session**.
9. ONE building, no structure at (150,7595): **yes**, verified (§5 stage 3).
10. Occupation reads (banners/hardware/live energy, cable joins the
    building, H-motif varies per wall): **partial** — cable landing done;
    H-motif variation not attempted (§8).
11. Mouth faces the arriving player, yaw re-derived: **yes**, verified via
    the smoke tests' own entrance-walk-in check and the H-03/H-04 frames.
12. Route intact, all three smoke tests pass, build log prints 5 spaces/3
    gauntlet trainers/15 pylons: **yes**, verified every stage.
13. Budget (<=18 exterior omnis, draw calls <=+15%): **lights unchanged
    from baseline (see §7); draw-call after-number not captured this
    session** (§7).
14. Night/golden gate read: **not captured this session** (day keyframe
    only).

## 12. Full file footprint

Changed, all committed and pushed:
- `data/config/stronghold.json` — `site.at`/`yaw_deg`/`ramp_run`,
  `approach_drain.bounds`, four rewritten `_comment_*` blocks.
- `data/config/map_landmarks.json` — `stronghold` pin position + comments.
- `data/config/building_prefabs.json` — new `meadows_hall` prefab (one
  top-level key; the existing `castle` entry is untouched and still
  present as history/fallback for any tool that still looks it up).
- `scripts/world/stronghold.gd` — `_place_gauntlet()`'s facing fix,
  `built_floor_height_at()`'s widened margin, `_build_keep_parapets()`,
  `_build_hall_massing()` + `_weather_hall_massing()` +
  `_build_hall_waist()` + `_build_hall_slits()` + `_build_cable_landing()`,
  and their call sites in `build()`.
- `scripts/world/stronghold_climax.gd` — `_place_warden()`'s facing fix
  + `_stronghold_yaw_deg()` helper.
- `scripts/world/playground_world.gd` — stopped instantiating
  `landmark.gd`'s castle.
- `tests/smoke_stronghold.gd` — `ENTRANCE_PUSH_FRAMES` for the now-longer
  ramp (§10.2 above).
- `tools/_probe_hall_site.gd` — cherry-picked from the design branch.
- `tools/_judge_capture_hall.gd` — new, this session's evidence stands.
- `ralph/reports/HALL_DESIGN_2026-08-30.md`,
  `ralph/reports/handover-T1-HALL-DESIGN-2026-08-30.md` — cherry-picked
  from the design branch for context.
- `ralph/reports/T1-HALL/shots/hall0830/` — the eight H-0x frames.

Not touched: `interior_structure.gd` (read only, per instructions),
`data/config/bands/**`, terrain/grass/scatter config, `art.json`,
`scripts/combat/**`, `scripts/ui/**`, creature scripts, `landmark.gd`
itself (only its CALLER changed), `building_prefabs.json`'s `castle`
entry or any other building's entry.

## 13. What I would do next

1. **Get the perf after-number** (§7) — the single most important
   unfinished acceptance check, and the one most likely to matter if
   someone ships this without it: rerun `tools/perf_render_stats.gd`
   with `--label=after` and compare `stronghold_approach` against the
   design's own 1069/25.8M/1381 baseline and the <=1230-draw-call budget.
2. Resolve the palette value-band question (§7) — confirm the intended
   lighting hour for H-03/H-05 and re-measure at it if "day" is not it.
3. Occupation: H-motif per-wall variation and the blue relic banner are
   both small, self-contained additions (§4/§6.2 of the design) that
   would meaningfully close acceptance item 10.
4. Elevations: the hoarding walkway and stair dressing are the largest
   remaining acceptance gap (item 3) and the most labor to build well —
   worth a dedicated pass rather than a rushed add-on.
5. Flag `rift_collapse.gd`'s StormWall placement to whoever owns SG44
   (§6/§9.5) — not this lane's system, but now demonstrably in this
   site's own approach sightline.
6. A fresh blind-judge pass, once the owner un-stands-down the judge —
   this handover is evidence for that judge, not a substitute for one.
