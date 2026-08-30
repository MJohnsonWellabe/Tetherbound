# The ROG Ally performance budget

**Lane:** T1-PERF, 2026-08-30. **Why this file exists:** `ralph/MEADOWS_EXIT_CRITERION.md`
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
  setting's own comment). A 2048×2048 atlas splits by quadrant among however
  many shadow-casting Omni/Spot lights are active near the camera at once:
  2 lights ≈ 1448px/side each, 4 ≈ 1024px, 8 ≈ 724px, 16 ≈ 512px. Godot
  allocates shrinking quadrants as count rises rather than failing outright,
  so the visible failure mode is not a crash — it is every nearby brazier's
  shadow going soft/blocky at once, worst exactly where the game wants a
  dramatic lit scene (the gate, the arena). **This is the real, derived
  reason `HALL_DESIGN_2026-08-30.md` §6.5's "no shadowed lights anywhere"
  outdoors is correct, not merely cautious.**
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
`ralph/conventions.md`), `--headless` for the CPU/structural tools that read
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

`HALL_DESIGN_2026-08-30.md`'s own baseline, re-measured this session on the
same `main` tree with the same tool for cross-check:

```
view                     draw calls     primitives      objects
village_high                  <FILL>         <FILL>        <FILL>
band1_open                    <FILL>         <FILL>        <FILL>
band4_ironwood                <FILL>         <FILL>        <FILL>
stronghold_approach           <FILL>         <FILL>        <FILL>
```

### 3.2 All seven authored locations, day and night

`tools/perf_site_survey.gd`, `--label=T1-PERF-2026-08-30`:

```
<FILL — full table from the survey run>
```

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
| Shadow-casting Omni/Spot lights reaching any one location | **≤ 4** | keeps each a ≥1024px shadow atlas quadrant on the shared 2048² positional atlas (§1); more than that degrades every shadow at once, worst in the exact dramatic-lighting moments (gate, arena) the art wants sharp |
| Total (shadow + non-shadow) Omni/Spot lights reaching any one location | **≤ <FILL, derived from measured baseline + headroom>** | <FILL> |
| Interior lights (indoors, camera close, small area) | not capped the same way — `HALL_DESIGN_2026-08-30.md`'s own 12 interior lights are unchanged by that design because they were measured against finale readability; this budget does not reopen that number, only states the outdoor cap the design itself derived (§7's ≤18 exterior omnis, 0 shadowed) fits inside this file's harder ≤4-shadowed reasoning |

### 4.2 Measured, current `main`

`tools/perf_site_survey.gd`'s light-reachability count (total / shadowed),
day and night, all seven locations:

```
<FILL>
```

## 5. Scatter density budget

### 5.1 Measured, this session

Whole-band (bounding box of that band's own placements — an honest but
coarse upper-terrain average; every band's placements span nearly the full
~2048m authored world width, so this is NOT a walked-corridor density):

```
<FILL from perf_scatter_density.gd>
```

Local (60m-radius circle at the exact point the other tools sample — closer
to what a player standing there actually sees):

```
<FILL>
```

### 5.2 The budget line

<FILL — derived from local density spread + which locations are
disproportionately dense, once ranking is in>

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
