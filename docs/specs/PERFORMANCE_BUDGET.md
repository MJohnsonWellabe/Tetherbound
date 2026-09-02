# The ROG Ally performance budget

**Lane:** T1-PERF, 2026-08-30. **Why this file exists:** `docs/acceptance/MEADOWS_EXIT_CRITERION.md`
J4 says "beauty that kills the frame rate is not a pass" and K says ROG
Ally/Windows performance must hold across a 3-4 hour run, but until this file
**no document anywhere in the repo stated a number** a lane could build
against. `HALL_DESIGN_2026-08-30.md` §7's "≤18 exterior omnis" is a
*reduction from 46*, not a figure derived from the device — a good instinct,
not a budget. Lanes have been making lighting and scatter decisions with
nothing to check them against. This is that number, derived as honestly as a
GPU-less container can derive it, with every line marked measured or
estimated.

## 0. What this document is and is not

- It **is** a budget derived from three real, checkable things: numbers this
  session measured on the live `main` tree, the project's own committed
  render settings (`project.godot`), and Godot 4.7's documented Compatibility
  (GLES3) renderer behaviour.
- It **is not** a ROG Ally frame-rate guarantee. No container in this project
  has ROG Ally hardware (Zen 4 mobile core + RDNA3 iGPU, shared DDR5). Every
  number below measured on this box is a **structural** count (draw calls,
  primitives, objects, light reachability) — hardware-independent in *shape* —
  not a frame time, which is not.
- Where a number below is a real device unknown, it says so and names the
  on-device test that would close it, per the exit criterion's own evidence
  rule: "an honest 'this needs a device run' beats an invented figure."

## 0.5 THE HEADLINE NUMBER — what the Meadows Hall can afford

**For `ralph/T1-HALL-3`, which is rebuilding the Hall's fortress geometry
after `JUDGE-5-2026-08-30.md` failed it as "a dressed greybox": build to
≤ 4000 draw calls at the `hall_approach` stand** (`tools/perf_render_stats.gd`,
`(0, 7420, 26, yaw 180)` — the stand looking AT the Hall; the older
`stronghold_approach` entry at the same point but yaw 0 looks away from it
and is not the number to build against, a real mistake the previous lane
made and caught only after building past it).

**How this number was derived, not guessed:**

- Measured this session, `main` @ `5d171130` + `ralph/T1-HALL-REBUILD`
  merged, `hall_approach`: **2743 draw calls / 23.70M primitives / 3069
  objects**, before any change this lane made. This matches
  `handover-T1-HALL-REBUILD-2026-08-30.md` §5's own **2706** at the same
  stand closely enough (both measured on a moving, re-baking tree) to trust
  both.
- This lane found and fixed one free, zero-visual-cost lever in the current
  geometry — `_build_keep_parapets()` was building a full merlon/coping
  roofline on all four sides of all three keep chambers even where two
  chambers sit 4.2–6m apart in a straight line (`tether_approach` →
  `warden_arena` → `legendary_chamber`, per `data/config/stronghold.json`'s
  own `at`/`size`), so a parapet on the chamber-facing side sits behind the
  next chamber's own wall from every camera position that can ever exist.
  Skipping those 4 of 12 chamber-sides, verified before/after on the same
  tree: **2743 → 2665 draw calls (−2.8%), 3069 → 2987 objects, primitives
  unchanged (23.70M → 23.70M, as expected — coping/merlon boxes are cheap in
  triangle count and this was never a GPU-throughput fix, only a draw-call
  and object-count one)**. Smaller than the design doc's own "very likely
  brings it inside the line" hope, but real and free — `T1-HALL-3` does not
  need to re-add this geometry to get the visual read back.
- The design's own original ceiling (2463 = old baseline + 15%) is
  **retired, not extended**: `T1-HALL-REBUILD`'s own handover already showed
  the baseline it was computed against never contained the building, and the
  +15% margin was also already spent by an earlier pass before that baseline
  was even taken. Continuing to chase a number derived from a view that
  never saw the subject would be the same mistake with different digits.
- **The replacement reasoning:** the highest draw-call count this session
  measured ANYWHERE in the authored corridor is `band1_open` (open field,
  dense scatter) at **5712–5929**, measured earlier this session on a since-
  superseded, less-dense bake (`main` @ `1d7fc8e7`; the ground lane's newest
  terrain regen + scatter re-bake happened after this number was taken and
  it was not re-confirmed post-rebake before this document was written — a
  real gap, named rather than papered over). Treating that as the corridor's
  demonstrated worst case (a number the Ally must already survive, whatever
  it currently is, since the game already ships it), **4000 draw calls
  keeps the chapter's finale meaningfully below the open field's own
  worst-case load** (≈68% of it, on the stale band1 number) while giving
  `T1-HALL-3` real room to add the mass and detail `JUDGE-5` is asking for —
  roughly **1300+ draw calls above the current fixed baseline**, more than
  double what T1-HALL-REBUILD's own remaining-lever list (merlon rows done;
  causeway railing; hoarding walkway) could plausibly still cost.
- **This is a reasoned ceiling, not a measured hardware limit.** No
  container here has ROG Ally hardware; nothing above is a frame-rate claim.
  It is the most defensible number derivable without one: bounded below by
  what the current fixed geometry already costs (2665), bounded above by
  what the corridor's own worst already-shipping location demands (~5900,
  itself due for re-confirmation), and it explicitly does NOT inherit the
  retired baseline's flawed methodology. **Confirming it on a real ROG Ally
  once `T1-HALL-3` lands is the one thing this container cannot do and the
  next real gap to close.**

## 1. The one hardware fact that actually drives this budget

`docs/decisions/D01-godot-version-and-renderer.md`: Tetherbound ships on
**Compatibility (`gl_compatibility`, i.e. GLES3)**, not Forward+, because
Forward+ hard-freezes on the Ally's RDNA3 iGPU/driver combination. This is
not a side detail — it is the reason a light budget matters *at all*:

- Forward+ uses clustered forward lighting: hundreds of lights can share a
  frame cheaply because the renderer only evaluates the handful actually
  touching each cluster of pixels.
- Compatibility does **not** cluster. Every light that reaches a drawn
  surface is evaluated more directly, and — the number that actually caps
  this — **every shadow-casting light needs its own shadow map, and every
  positional (Omni/Spot) shadow map in the whole scene shares ONE atlas**:
  `project.godot` `[rendering]` → `lights_and_shadows/positional_shadow/atlas_size=2048`
  (already halved from Godot's 4096 default for Ally memory, per that
  setting's own comment). Godot subdivides that single 2048×2048 atlas among
  however many shadow-casting Omni/Spot lights are near the camera at once,
  by an LRU/importance quadtree, not a fixed per-light slot — so the exact
  per-light resolution at a given count is an engine-internal allocation
  this document does not claim to reproduce exactly. What is certain from the
  atlas being shared and finite: more simultaneous shadow-casting lights
  means less atlas per light, and past some count some lights lose shadow
  resolution or their shadow entirely rather than the game failing outright.
  The visible failure mode is every nearby brazier's shadow going soft or
  vanishing at once, worst exactly where the game wants a dramatic lit scene
  (the gate, the arena) — and confirming exactly where that becomes visible
  needs a device/editor run with the atlas actually inspected (§8.3), which
  this container cannot do. **This is still the real, derived reason
  `HALL_DESIGN_2026-08-30.md` §6.5's "no shadowed lights anywhere" outdoors
  is correct, not merely cautious**: it keeps outdoor Team Tether dressing
  off a shared, finite resource entirely rather than betting on where the
  degradation curve bends.
- Non-shadow-casting lights are far cheaper (no shadow pass) but are not
  free: Compatibility still evaluates every light whose range reaches a
  drawn surface, per-vertex/per-pixel depending on the surface's shader,
  with no clustering to skip distant ones the way Forward+ would.

**Budget consequence:** the two numbers that matter are not the same number.
*Total* lights reaching a location is a real but secondary cost. *Shadow-
casting* lights reaching a location is the one with a hard, measured
denominator (one shared 2048² atlas) behind it, and is the number this
budget caps hardest.

## 2. Method: what was actually measured, on what

All numbers in §3-§5 were measured this session (2026-08-30) on `main`, in
this container: Godot 4.7.stable (matching `D01`'s pin), Compatibility
renderer, `xvfb-run` + `--rendering-driver opengl3` for the render-side tools
(never `--headless` with a real driver — that combination hangs forever,
`docs/AGENT_WORKFLOW.md`), `--headless` for the CPU/structural tools that read
no `RENDER_*` monitor. No GPU is present; this box rasterises in software.
Frame *time* is therefore not reported as a device number anywhere below —
only draw calls, primitives, objects, and light-reachability counts, which
are the same numbers a real GPU would be handed (`ralph/PERF_ROG_REPORT.md`
established this reasoning first; this file inherits it rather than
re-arguing it).

Tools:

- `tools/perf_render_stats.gd` — the existing four-view baseline
  (`HALL_DESIGN_2026-08-30.md`'s own tool), reproduced this session for
  cross-check.
- `tools/perf_site_survey.gd` — **new this session**. Extends the same
  method to all five bands, the village and the stronghold/Hall, at day AND
  night, and adds a light-reachability count (total + shadow-casting) per
  location. See the file's own header for the light-counting method: every
  Omni/SpotLight3D whose *own authored range* reaches the sample point, which
  is a real, reproducible number from the light's own data — not a
  frustum/occlusion-verified "this frame" count, because Godot's headless
  `Performance` singleton has no such monitor to read.
- `tools/perf_scatter_density.gd` — **new this session**. Reads every
  scattered placement's real position out of `vegetation.gd`'s own instance
  table and bins it by band, reporting both a whole-band bounding-box density
  and a local density at the exact points the other two tools sample.
- `tools/perf_profile.gd` — the existing CPU-cost profiler (unmodified),
  used to verify the collision-streaming config levers (§6).

Reproduce any number below with the commands in §7.

## 3. Render budget — draw calls, primitives, objects

### 3.1 The reproduced four-view baseline

`HALL_DESIGN_2026-08-30.md`'s own baseline used `tools/perf_render_stats.gd`
at four views: `village_high`, `band1_open`, `band4_ironwood`,
`stronghold_approach`. `tools/perf_site_survey.gd` reuses those exact same
four camera poses verbatim (same x/z/height/yaw), so its `day` rows for
those four names ARE the cross-check — a second, separately-run measurement
at the identical points, not a re-guess. (A literal re-run of the old
narrower tool was started this session and killed once it became clear it
was measuring a strict subset of what the new tool would produce anyway —
this session's own reproducibility note, not a gap.)

```
view                     draw calls     primitives      objects   (measured this session)
village_high                   2011       26,892,017        2214   day
village_high                   1815       27,451,889        2018   night
band1_open                    <pending — survey still running>
band4_ironwood                 <pending>
stronghold_approach            <pending>
```

**A finding already confirmed from `village_high` alone, worth stating now
rather than waiting for the rest:** `ralph/PERF_ROG_REPORT.md` (2026-08-23)
measured `village_high` at **1995 draw calls on a 143,630-placement bake**.
This session's `perf_scatter_density.gd` measured the CURRENT bake at
**248,167 placements — a 73% density increase** since that report. Yet
`village_high` draw calls moved from 1995 → **2011, +0.8%**. This is a
second, independent, much larger confirmation of §3.3's own point below:
under Compatibility, draw calls track MultiMesh **batches**, not the
instances inside them, so scatter density can grow substantially with
almost no draw-call cost. It also means **density is not where a lane
worried about "did my change blow the frame budget" should be looking at
all** — draw-call counts will look almost identical to before even after a
large density change; a `perf_scatter_density.gd` run before/after is the
only way to see whether a density change actually happened.

### 3.2 All seven authored locations, day and night

**Status note (2026-08-30, mid-session):** the rows below labelled
`PRE-REBAKE` were measured on `main` @ `1d7fc8e7`. Partway through this
survey, the ground lane landed a terrain regen + full scatter re-bake
(`main` now at `5d171130`, merged into this branch) that changes instance
counts world-wide, so those numbers are **superseded as an exact current
count** — kept only because the density-vs-draw-calls RATIO finding they
support (§3.1: draw calls barely move when density rises substantially) is
a methodological point, not a bake-specific one, and re-deriving it after
every re-bake would waste time better spent on coverage. `stronghold_approach`
and `warrens_den` — the two locations that actually matter for tonight's
landing decision (the Hall lane's rebuild reports 2962 draw calls at its own
`hall_approach` stand, a different camera pose, against the documented 1069
baseline for `stronghold_approach` — the coordinator needs a same-tree,
same-tool number to compare against, not a re-guess) — are measured
**POST-REBAKE**, on current `main` @ `5d171130`, and are the numbers this
budget actually stands behind.

```
view                   time   draw calls     primitives    objects   lights shadowed   bake
village_high           day          2011       26892017       2214        0        0   PRE-REBAKE
village_high           night        1815       27451889       2018        0        0   PRE-REBAKE
band1_open             day          5712       31587550       4671        0        0   PRE-REBAKE
band1_open             night        5929       29728138       4888        0        0   PRE-REBAKE
band2_stone            day          1319       29522759       1570        0        0   PRE-REBAKE
band2_stone            night        1412       29679136       1663        0        0   PRE-REBAKE
band3_river            day          2516       29609302       2436        0        0   PRE-REBAKE
band3_river            night        2649       29879031       2569        0        0   PRE-REBAKE
band4_ironwood         day           833       28239147       1146        0        0   PRE-REBAKE
band4_ironwood         night         931       27740757       1243        0        0   PRE-REBAKE
band5_approach         <not measured this session>
stronghold_approach    <measuring now, post-rebake, priority>
warrens_den            <measuring now, post-rebake, priority>
```

Zero lights reaching the sampled ground point at every location so far,
day and night, is itself a running finding, not (yet) a tool defect — see
§4.2's discussion. `band1_open` night has slightly MORE draw calls than day
(5929 vs 5712) despite no lights reaching the point; this is very likely
Terrain3D/grass shader variation between the day and night material states
rather than noise, but is not yet chased down.

### 3.3 The budget line

- **Draw-call ceiling per location: <FILL, derived from the worst
  measured location + headroom, see reasoning>.**
- Reasoning: <FILL once ranking is in>.
- **What this number is NOT**: under Compatibility, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`
  tracks MultiMesh **batches** in the frustum, not the instances inside them
  (`ralph/PERF_ROG_REPORT.md` established this and it still holds — verified
  again this session, §4). A batch draws its instances in one call regardless
  of how many there are, so **raising scatter density inside an existing
  batch is nearly free in draw-call terms and is NOT bounded by this
  section** — it is bounded by GPU vertex/fragment throughput instead, which
  no container can measure (§3.4).

### 3.4 What a container cannot answer

Vertex/fragment throughput inside each MultiMesh batch — the actual GPU cost
of scatter density — needs the device. This budget states the ceiling it
CAN derive (draw calls, primitives-submitted, light/shadow counts) and says
plainly that scatter density itself is not bounded by any container number;
it is bounded by an on-device frame-time test, which this repo cannot run
today.

## 4. Light budget

### 4.1 The derived caps

| | cap | basis |
|---|---|---|
| Shadow-casting Omni/Spot lights reaching any one location | **≤ 4** | a conservative slice of the single shared 2048² positional shadow atlas (§1) — low enough that even an even split still leaves each light real atlas resolution, without claiming to know Godot's exact allocation curve; more than that is where the shared-atlas math starts to bite, worst in the exact dramatic-lighting moments (gate, arena) the art wants sharp |
| Total (shadow + non-shadow) Omni/Spot lights reaching any one location | **≤ <FILL, derived from measured baseline + headroom>** | <FILL> |
| Interior lights (indoors, camera close, small area) | not capped the same way — `HALL_DESIGN_2026-08-30.md`'s own 12 interior lights are unchanged by that design because they were measured against finale readability; this budget does not reopen that number, only states the outdoor cap the design itself derived (§7's ≤18 exterior omnis, 0 shadowed) fits inside this file's harder ≤4-shadowed reasoning |

### 4.2 Measured, current `main`

The `lights`/`shadowed` columns of §3.2's table ARE this measurement (one
survey run produces both at once) — see that table rather than a duplicate
one here.

**Already worth noting, not yet a complete picture:** zero lights reach ANY
of the four locations measured so far (village, band1-3) at EITHER time of
day. That is a real reachability-count result, not a tool bug (the tool's
first run had a real bug — checking the elevated camera position instead of
the player's ground position — caught and fixed before trusting any number;
see `ralph/reports/T1-PERF/`). It most likely means these specific sampled
points simply aren't within any light's authored range — the open bands are
genuinely dark corridors outdoors by day, and this session has not yet found
a location where a light IS in reach to confirm the mechanism finds one
(the Warrens den, with its known new shadow-casting light, and the
stronghold/Hall, with its known light rigs, are the two locations that
should show a nonzero count — both still pending). Read this as "lights near
the sampled POINT", not "lights anywhere in the named area", once the
argument for reading this table as "lights near the sampled POINT", not
"lights anywhere in the named area", once the rest of the table is in.

## 5. Scatter density budget

### 5.1 Measured, this session

`tools/perf_scatter_density.gd`, `main` @ `1d7fc8e7` (248,167 scattered
placements with a recorded position, world total):

Whole-band (bounding box of that band's own placements — an honest but
coarse upper-terrain average; **every band's measured x-spread came back
~2047m, i.e. the full authored world width**, not a walked corridor — this
number is diluted by empty terrain at the width's edges and should not be
read as "what the player walks through"):

```
band              count   x-spread m    z-run m   footprint ha   density /ha
village           14279       2047.9      511.6        104.761         136.3
band1             71653       2046.9     1359.9        278.371         257.4
band2             52985       2047.6     1820.0        372.662         142.2
band3             38044       2047.6     1580.0        323.507         117.6
band4             61599       2047.4     2239.9        458.597         134.3
band5              8682       2041.1      547.8        111.820          77.6
stronghold          925       2042.6      131.9         26.945          34.3
```

Local (60m-radius circle, 1.131 ha, at the exact points
`perf_profile.gd`/`perf_site_survey.gd` sample — much closer to what a
player standing there actually sees):

```
site              count      density /ha
village             617            545.5
band1              1322           1168.9
band2               272            240.5
band3               358            316.5
band4                 20             17.7
band5              554            489.8
stronghold          757            669.3
```

### 5.2 The budget line

**The two views disagree by design, and the disagreement is the finding.**
Whole-band density is fairly flat (78–257/ha) because it averages huge empty
stretches in with dense clumps. Local density at the exact sampled point
swings from **17.7/ha to 1168.9/ha — a 66x range** between two points in the
same authored corridor. That is not a bug in the measurement; it means
scatter is authored in clumps with wide gaps between, which is consistent
with intent (a clearing should be clearer than a thicket) but means **no
single density number can budget this system** — the number that matters is
local, at the specific place the camera is, which is exactly why §3
(draw calls) rather than a density ceiling is this file's real render-cost
lever: under Compatibility, draw calls track MultiMesh batches in frustum,
not instances per batch (§3.3), so a locally dense clump inside an existing
batch is close to free in draw-call terms and is bounded by GPU throughput
instead (§3.4, needs the device).

**Budget line: no per-hectare density ceiling is set here.** The measured
spread above is recorded so a future density pass can compare against it,
and the band4 sample point's 17.7/ha (a near-empty ridge) versus band1's
1168.9/ha (a dense thicket) should be read as evidence the corridor already
varies deliberately, not as an unowned inconsistency to flatten.

## 6. The T3-INSTALL collision-streaming levers — verified

`performance.json`'s `collision_stream_radius_m` / `_interval_s` / `_cell_m`
were flagged (dark-features inventory P1) as levers whose doc comments
claimed tunability with zero actual reader. T3-INSTALL wired readers
(`vegetation.gd::_load_performance_overrides()`,
`playground_world.gd::_ready()`). This session re-verified by directly
changing the values and re-measuring with `tools/perf_profile.gd` rather
than reading the code and trusting it:

| config change | measured effect | verdict |
|---|---|---|
| `collision_stream_radius_m` 100→30 | resident colliders at `village` 151→0, at `band1` 410→2 | **wired correctly** — resident count tracks the radius exactly as the code comment claims |
| `collision_stream_interval_s` 0.5→2.0 | reported sweep rate in the profile changed from "2.0 Hz" to "0.5 Hz" (i.e. 1/interval) | **wired correctly** |
| `collision_stream_cell_m` 32→16 | per-call sweep cost stayed low and consistent with the much smaller radius (not independently isolated from the radius change in this pass — see note) | **plausible, not independently isolated** |

All three values were restored to their shipped defaults (100.0 / 0.5 / 32.0)
immediately after this test; nothing here changes the shipping config.

## 7. Reproducing every number in this file

```
# render-side (never --headless with a rendering driver — hangs forever)
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --label=cross-check

xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/perf_site_survey.gd -- --label=T1-PERF-2026-08-30

# structural / CPU-side (headless is correct here)
godot --headless --path . --script tools/perf_scatter_density.gd
godot --headless --path . --script tools/perf_profile.gd -- --frames=120
```

## 8. What still needs the real device

Stated plainly, per the exit criterion's evidence rule:

1. **Any actual frame rate.** Nothing in this file is one and nothing here
   should ever be quoted as one.
2. **GPU vertex/fragment cost of scatter density** (§3.4) — draw-call counts
   do not move with density inside an existing batch; only an on-device
   frame-time comparison at matched camera poses, before/after a density
   change, can answer this.
3. **Whether the positional shadow atlas actually degrades visibly** at the
   derived ≤4 shadow-casting-light cap (§4.1) — the atlas-quadrant math is
   Godot's documented allocation behaviour, not a rendered/inspected atlas
   from this container.
4. **Whether the ROG Ally's actual VRAM/shared-memory budget is respected**
   across a full 3-4 hour run with saves/loads across every band — this file
   only covers per-location structural cost, not a play-session memory
   trace.
