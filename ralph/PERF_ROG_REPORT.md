# PERF-ROG — OP23-01, the ROG Ally frame rate

`branch: ralph/PERF-ROG` · `owner report: ralph/OWNER_PLAYTEST_2026-08-23.md`
· `harness: tools/perf_profile.gd` · `2026-08-23`

Every measurement below was taken against `main` at `a8ed4f0`, whose bake holds
143,630 placements. `BAND2-FLOOR` landed a re-bake while this branch was in
flight (144,456, +0.6%) and is merged in; nothing here is sensitive to a
difference that size, and the two fixes are structural rather than
density-tuned. Re-confirmed on the merged tree at that bake: village 5.03 ms
and band4 3.64 ms process time, arbiter 0.026 / 0.010 ms/call, collision sweep
0.882 / 0.252 ms/call — same shape, same conclusions.

The owner's words were "feels like ten frames per second", and OP23-01 is the
chapter's #1 SHIP blocker. No container in this project has ROG Ally hardware,
so **nothing in this report is a device frame rate and nothing here should ever
be quoted as one.** What is here is the per-frame WORK the game asks for at six
places in the real corridor, measured, ranked, and — for the top two — removed.

## The headline

Per-frame CPU, measured by `tools/perf_profile.gd` on the real Meadows world at
six sites, before and after this branch:

| site | process ms/frame BEFORE | AFTER | change |
|---|---|---|---|
| village | 33.15 | 4.67 | −86% |
| band1 | 38.02 | 4.35 | −89% |
| band2 | 34.93 | 4.23 | −88% |
| band3 | 34.84 | 3.81 | −89% |
| band4 | 40.24 | 4.04 | −90% |
| stronghold | 35.94 | 4.50 | −87% |

A 60fps frame has 16.7ms of budget. Before this branch the game's own GDScript
asked for **twice a whole frame's budget every frame, on a box far faster than
an Ally**, before the renderer drew anything. That is a frame rate in the low
teens on this hardware and worse on a handheld, which is exactly what the owner
reported.

## What it actually was

`interaction_arbiter.gd::_recompute()` polled **every registered interaction
provider, every frame**: 24,461 of them, of which 24,398 are
`vegetation.gd::_spawn_harvest_point()` gather points — one per harvestable
scattered tree or rock. Measured directly (`tools/_probe_arbiter_census.gd`):
**15.6–26.0 ms of pure method-call cost per frame to find the two providers
within reach** (the spread is contention on this box across repeated runs; the
arbiter's own `_process`, timed in place, came out at 14.3–20.4 ms). 1,221 ms of work per wall-clock second: more than a whole CPU
second, per second.

PERF-2 had already found and fixed the same population's O(n²) *registration*
cost at boot. The O(n) *poll* was left, and every prop the world gained made it
worse. The 2026-08-23 groundcover raise (below) would have made it worse again.

## The ranking, before and after

`tools/perf_profile.gd` times each suspect by calling it directly, so every
number is a measured call rather than a share of a total inferred by
subtraction. Worst site shown; ms/s is cost-per-call × real call rate, which is
the ranking that matters (the collision sweep runs twice a second, the arbiter
sixty times).

| subsystem | BEFORE ms/s | AFTER ms/s | how |
|---|---|---|---|
| `interaction_arbiter` | 1220.99 | 1.46 | spatial grid (below) |
| `collision_streaming` | 18.44 | 1.17 | cell-indexed sweep (below) |
| `wild_cluster_sweep` | 12.84 | 14.46 | untouched — already cluster-strided |
| `hud_process` | 12.48 | 10.21 | untouched — already redraw-on-change |

The two untouched entries are each ~1% of a 60fps CPU second on this box and
were already doing the right thing: the encounter director strides by cluster
rather than by creature (262 clusters, not 909 wilds), and the minimap already
repaints only when the player has actually moved or the fog revision advanced.
Neither is worth a change that could break something.

## The two fixes

Both are pure CPU. Neither changes a single thing a player sees, and both are
covered by a test that would fail if they did.

### 1. `interaction_arbiter.gd` — a spatial grid over prompt providers

A uniform 2D grid over x/z. A `Node3D` provider is filed in the cell its
position falls in; the two providers that have no position of their own
(`encounter_director`, `riding_controller` — managers that answer for whatever
is nearest) stay in a loose list polled every frame. `_recompute()` walks only
the cells within `_query_radius` of the player, where `_query_radius` is a
running maximum of every registered provider's own `radius`.

**The result is identical, not merely similar.** A provider only ever offers
when the player is inside its own radius, so the queried cells are a strict
superset of everything that could offer; and candidates are sorted back into
registration order before arbitration, because `prompt_arbiter.gd` breaks a
priority-and-distance tie in favour of whoever registered first.

Movement is handled by the engine, not by polling: `interactable.gd` turns on
`set_notify_transform(true)` and re-files itself from
`NOTIFICATION_TRANSFORM_CHANGED`, so a prompt on a walking NPC re-buckets the
frame it moves and 24,398 gather points bolted to stationary trees cost
nothing.

**0.024 ms/call, down from 20.350.** Cell size is
`data/config/performance.json::interaction_grid_cell_m`.

### 2. `vegetation.gd` — a cell-indexed collision streaming sweep

`update_collision_streaming()` tested **every** collidable placement in the
world on every call — 22,306 of them, twice a second, 8–10 ms a sweep. Not a
frame-rate floor, but a judder the player feels twice a second, and it grows
with every prop. Placements are now filed by cell at `_add_collision()` time
and the sweep visits only the cells the bubble's bounding box covers; cells
that have just left it are cleared.

**0.226–0.586 ms/call, down from 6.6–10.3.** Resident-collider counts are
**identical at all six sites** (166 / 389 / 13 / 120 / 8 / 68 before and after),
and `tests/smoke_collision_streaming.gd` now asserts the indexed sweep against a
brute-force pass over every placement in the world, because "the resident count
looks plausible" would pass with a whole cell of walk-through trees.

The index is rebuilt whenever a placement is removed (`harvest_permanently()`,
`clear_area()`), because `remove_at()` shifts every index above the hole and the
buckets hold indices.

## Structural numbers the fixes do not reach

Measured once, same at every site, on `main`'s 143,630-placement bake:

```
scatter        143,630 placements in 41 batches, 22,306 solid, 24,325 harvest points
nodes          89,137 nodes, 122,612 objects, 1,605 MB static
render bodies  22,109 MultiMeshInstance3D, 5,548 MeshInstance3D, 1,169 StaticBody3D
skinned        939 Skeleton3D (15,847 bones), 939 AnimationPlayer (41 playing)
wild           909 creatures instantiated at boot, 8–15 ticking at any site
```

Two of these are worth the owner's attention and are recorded here rather than
changed unilaterally:

- **1,605 MB of static memory** for the scene. The Ally has 16 GB shared with
  the GPU; this is heavy but not fatal. It scales with placement count.
- **909 wild creature bodies instantiated at boot and never despawned.** Only
  8–15 tick at a time (STREAM-D's cluster activation works), and only 41 of the
  939 AnimationPlayers advance, so this is not a per-frame CPU cost today — it
  is a memory and boot-time cost. Recorded because it is the number that grows
  if wild density rises again.

## The render side, and what a container cannot see

`tools/perf_render_stats.gd` boots the same world under `xvfb` + `opengl3` and
reads the RenderingServer's own counters at four elevated views chosen to have
distant scatter in frame. Draw calls per frame, `main`'s 143,630-placement bake:

| view | ranges OFF (what ships) | authored ranges (110–260m) | forced to 20m |
|---|---|---|---|
| village_high | 1995 | 2011 | 1778 |
| band1_open | 5789 | 5855 | 5669 |
| band4_ironwood | 777 | 801 | 734 |
| stronghold_approach | 968 | 1028 | 816 |

**PERF-2's commented-out LOD lines are not the win their comment implies.** At
the authored ranges the effect is inside measurement noise (the ±1–6% moves in
both directions; grass sway and camera settle differ between boots). Forcing
every range down to **20 metres** — culling everything past twenty metres, which
no player would accept — removes only **5–16%** of draw calls. The lever works;
it is simply not where the frames are.

So the two lines are now **wired and gated** rather than commented out:
`data/config/performance.json::scatter_lod_ranges`, **default `false`**, which
is byte-for-byte the behaviour that ships today. That converts a standing TODO
into a measured negative result plus a lever the next lane can re-measure in
fifteen minutes instead of re-deriving. `shots/perfrog/branch/` (ranges off,
what ships) and `shots/perfrog/after/` (ranges on) are vegetation-identical; the
only differing pixels in the pond view are the animated water's wave phase.

### What these counters cannot tell you

Under the Compatibility renderer, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` and
`RENDER_TOTAL_PRIMITIVES_IN_FRAME` track **MultiMesh batches in the frustum, not
the instances inside them**. That is why forcing a 20m cutoff moves them (whole
MMIs stop drawing) while raising density barely does (the same MMIs draw more
instances each). Density's real GPU cost is vertex and fragment throughput
inside each batch, and this box rasterises in software with llvmpipe, so its
frame times are meaningless for that. **Nobody can answer the GPU half of
OP23-01 without the device.** That is what the debug overlay below is for.

## The groundcover density raise — owner decision input

`ralph/VISUAL-GROUNDCOVER` (unlanded, commit `ea589dd`) takes the corridor from
**143,630 to 223,271 placements**, a 55% raise, to close the assessment's #1
blind-critique gap. Both bakes measured on this branch:

| | 143,630 (main) | 223,271 (VISUAL-GROUNDCOVER) | change |
|---|---|---|---|
| CPU per frame, mean over 6 sites | 4.28 ms | 4.92 ms | +15% |
| scene nodes | 89,137 | 126,037 | +41% |
| static memory | 1,605 MB | 1,755 MB | +150 MB |
| MultiMeshInstance3D | 22,109 | 33,055 | +50% |
| solid collision placements | 22,306 | 34,606 | +55% |
| harvest points (= prompt providers) | 24,325 | 37,302 | +53% |
| draw calls, band1_open | 5,789 | 5,882 | +1.6% |
| draw calls, stronghold_approach | 968 | 1,063 | +9.8% |

**The finding that matters is what this density would have cost on `main`.**
The arbiter's per-frame cost is linear in provider count, and this density adds
12,977 providers. Measured directly by `tools/_probe_arbiter_census.gd` on the
real 223k world:

- **on `main`: 44.65 ms/frame**, up from 20.35 — the density raise would have
  made OP23-01 **more than twice as bad**. On a handheld that is 130–270 ms of
  arbiter alone per frame: four to eight frames per second, from one subsystem.
- **on this branch: 0.028 ms/frame** at the same density.

**So the density raise is affordable now and was not before.** Its remaining
costs are memory (+150 MB, on a 16 GB shared-memory handheld) and GPU
throughput inside the MultiMesh batches, which no container can measure. Those
two are the owner's call, and this branch does not change world density.

## The device-side overlay

The owner's playtest could not produce a number because the build had no way to
show one. `data/config/performance.json::debug_overlay_on_boot` turns the F3
readout on from the first frame, and `debug_overlay_level` picks how much of it.

F3 is not reachable on an Ally, and the owner's authored controller map
(2026-08-22) spends every pad button on a gameplay verb with held chords banned
— so there is no spare press to give this, and a config flag is the honest
answer rather than a binding that would collide with something. Flip it, build,
play.

The readout gains a **top-three costs** block, ranked by work-per-second rather
than work-per-call (`scripts/world/perf_trace.gd`):

```
top costs  ms/s   per call   rate
  wild cluster streaming   14.5    0.24 ms   60.0 Hz
  HUD                      10.2    0.17 ms   60.0 Hz
  scatter collision str.    1.2    0.59 ms    2.0 Hz
```

Instrumentation is live only while the readout is; when it is off, a traced call
site pays one static bool read. That is what makes it safe to ship.

## The survey render: nothing a player sees moved

`tools/capture_lod_before_after.gd`'s two required views, rendered on `main`
(`shots/perfrog/main/`, local — `shots/` is gitignored) and on this branch's shipping configuration
(`shots/perfrog/branch/`), and compared pixel by pixel:

- **`open-field-long-sightline`: 0 differing pixels of 921,600.** Bit-identical.
- **`pond-lush-pocket`: rows 0–199 are 0.00% different** — the sky, the far
  treeline, the hills, the timber-framed building and every scrap of vegetation
  in frame. Differences begin at row 200 (the waterline) and run to the bottom
  of the frame at 96–100%: that is the pond's animated surface, whose wave phase
  differs between two boots and would differ between two boots of `main` as
  well.

Which is what the two fixes claim. The arbiter change alters which providers are
*asked* for an offer, never which one wins; the streaming change alters which
placements are *tested*, never which ones end up with a collider — and the
resident counts are identical at all six sites, asserted against a brute-force
pass in `tests/smoke_collision_streaming.gd`.

`shots/perfrog/after/` is the third state: the authored LOD ranges switched on
(not what ships). Vegetation-identical to both of the above.

**The frames themselves are not committed** — `shots/` is gitignored, and this
branch is not the place to start force-adding to it. The comparison above is the
evidence; reproduce it in about twenty minutes with three runs of

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_lod_before_after.gd -- --out=res://shots/perfrog/<state>
```

taken on `main`, on this branch, and on this branch with `scatter_lod_ranges`
set true.

## Tests

`godot --headless --path . --script tests/run_tests.gd` —
**1362 tests, 836,552 assertions, 0 failed** on the merged tree, the same count
`RUNTESTS-FILTER` recorded on `main`. (Before merging `main`'s seven new tests
in: 1355 / 830,269 / 0 failed, matching `ASSESS-REDS`.)

## Reproducing any of this

```
godot --headless --path . --script tools/perf_profile.gd -- --frames=120
godot --headless --path . --script tools/perf_profile.gd -- --sites=band4 --bisect=1
godot --headless --path . --script tools/_probe_arbiter_census.gd

xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --label=whatever
```

Two traps, both already paid for. **Never add `--headless` to the render tool**
(it hangs forever with a real rendering driver — `ralph/conventions.md`). And
**raise `--resettle`** if a site's physics time looks wild: Terrain3D builds
dynamic collision around the camera on the physics tick, and at the 120-frame
resettle this harness started with, two sites reported 45–51 ms of physics that
was entirely the terrain still building. At 600 they report 3.9–4.6. The default
is now 300, which is where the reading stops moving.
