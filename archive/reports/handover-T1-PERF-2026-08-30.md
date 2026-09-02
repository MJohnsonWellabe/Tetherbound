# Handover — T1-PERF, 2026-08-30

Branch `ralph/T1-PERF`, off `origin/main`. Mission: nobody owned ROG Ally
performance, `ralph/MEADOWS_EXIT_CRITERION.md` J4/K make it pass/fail, and
the owner's 2026-08-30 real-device playtest (`ralph/OWNER_PLAYTEST_2026-08-30.md`
OP-0830-6, "the game performance on a rog is pretty bad still") confirms it
is still failing, unchanged since 2026-08-21. No document anywhere stated a
number a lane could build against.

**The one line the coordinator asked for: the Meadows Hall should build to
≤ 4000 draw calls at the `hall_approach` stand.** Full reasoning in
`docs/PERFORMANCE_BUDGET.md` §0.5. Verified fix already landed on this
branch takes the current (pre-`T1-HALL-3`) geometry from 2743 → 2665 draw
calls at that stand, free and zero visual cost.

## What shipped

1. **`docs/PERFORMANCE_BUDGET.md`** — the missing budget document. Sections:
   - §0.5: the Hall headline number and its derivation (see above).
   - §1: the actual hardware fact driving this whole budget — Tetherbound
     ships on Compatibility (GLES3), not Forward+ (`docs/decisions/D01`),
     which means lights do NOT cluster and every shadow-casting Omni/Spot
     light shares ONE 2048×2048 positional shadow atlas
     (`project.godot`). This is the real, derived reason
     `HALL_DESIGN_2026-08-30.md`'s "no shadowed lights outdoors" call was
     correct, stated honestly (what's certain vs. what needs a device run
     to confirm the exact allocation curve).
   - §3: render budget, with a real measured finding: `village_high` draw
     calls moved 1995→2011 (+0.8%) while scatter density grew 143,630→
     248,167 placements (+73%) — a second, larger confirmation that
     Compatibility's draw-call counter tracks MultiMesh **batches**, not
     instances, so density growth is nearly free in draw-call terms and
     must be checked with `perf_scatter_density.gd`, not inferred from
     draw calls.
   - §5: scatter density — local density at the exact sampled points swings
     17.7–1168.9/ha (66x), which means no single per-hectare number can
     budget the system; local density at a specific camera pose is what
     matters, which is exactly why §3 (draw calls) is the real lever, not a
     density ceiling.
   - §6: T3-INSTALL's three collision-streaming config levers, verified
     wired correctly (not just read) by changing each value and
     re-measuring with `tools/perf_profile.gd`.
   - §8: what still needs a real ROG Ally, stated plainly.

2. **New tools:**
   - `tools/perf_site_survey.gd` — extends `perf_render_stats.gd`'s method
     to all seven authored locations (village + 5 bands + stronghold/Hall)
     at day AND night, plus a light-reachability count (total +
     shadow-casting) per location. Ships with a real bug found and fixed
     on its first run (light check used the elevated camera position
     instead of the player's ground position, reporting a structural 0 at
     every site) — see the file's own comments and this session's commit
     history for the full account; a caution for whoever extends it next.
   - `tools/perf_scatter_density.gd` — reads every scattered placement's
     real position out of `vegetation.gd`'s own instance table, reports
     whole-band bounding-box density and local density at each sampled
     point.
   - `tools/_probe_warrens_markers.gd` — one-shot lookup of the Burrow
     Warrens' own world-space chamber markers (used to site
     `perf_site_survey.gd`'s Warrens-den interior stand without hand-
     deriving the site's yaw/offset math).

3. **The Hall fix** (`scripts/world/stronghold.gd::_build_keep_parapets()`):
   skips the merlon/coping roofline on the 4 of 12 keep-chamber sides that
   face directly into another keep chamber 4.2–6m away (`tether_approach` →
   `warden_arena` → `legendary_chamber`, straight-line gaps a parapet on
   either side can never be seen across). Verified before/after on the same
   tree: **2743 → 2665 draw calls (−2.8%), 3069 → 2987 objects, primitives
   unchanged** (a draw-call/object fix, not a GPU-throughput one — merlon
   boxes are cheap in triangle count). `smoke_stronghold` and
   `smoke_gate_e_finale` both re-verified green with the fix in place.

## What is NOT done, honestly

- **The full 7-location × day/night × light-reachability survey never
  finished.** Village + bands 1–4 day/night were measured on a bake that
  the ground lane's terrain regen + full scatter re-bake then superseded
  mid-session (marked `PRE-REBAKE` in the budget doc, kept only for the
  density-vs-draw-calls ratio finding, which is bake-independent). Band 5,
  the Warrens den, and a post-rebake `stronghold_approach` were never
  re-measured after the priority shifted to the Hall's draw-call overage —
  that shift was the right call (owner-reported real-device performance
  problem + a landing decision the coordinator was blocked on), but it
  means those three rows are genuinely blank, not estimated.
- **`band1_open`'s cited 5712–5929 draw calls (the "corridor's worst known
  load" the Hall budget is compared against) predates the newest terrain
  regen + scatter re-bake and was never re-confirmed after it.** This is
  named directly in `docs/PERFORMANCE_BUDGET.md` §0.5 rather than presented
  as current. Re-running `tools/perf_render_stats.gd --views=band1_open` on
  current `main` is the one twelve-ish-minute command that would close it.
- **No ROG Ally device run.** Nothing in this branch is a frame rate. The
  4000 draw-call figure is a reasoned ceiling (bounded below by what the
  fixed geometry already costs, bounded above by the corridor's own
  worst-known load), not a measured hardware limit.

## A process note for whoever runs the next perf lane in this container

This container has no GPU; render-stats tools run under `xvfb-run` +
`--rendering-driver opengl3` on Mesa llvmpipe (software rasterisation), and
`ralph/conventions.md` already documents this is ~25x slower than headless.
In practice a single `perf_render_stats.gd` view took 10–25 minutes this
session, and a `perf_site_survey.gd` view-time pair (day+night) took
15–20+ minutes. **Launching it in the background and waiting for a
Monitor/notification across turn boundaries does not work reliably in this
harness** — several hours were lost this session to exactly that pattern
before the coordinator caught it. The pattern that actually works: run the
command in the foreground with a generous `timeout`, and if the harness
auto-backgrounds it anyway (it will, past ~600s), immediately chain a
blocking `while ps -p <pid> >/dev/null; do sleep 5; done` wait in the very
next tool call, back-to-back, without ending the turn on plain text in
between. Scope every render-stats run to as few views/times as the question
actually needs — a single `--views=` entry, not the full matrix, unless the
full matrix is truly the deliverable.

## Reproducing anything above

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --views=hall_approach,band1_open

godot --headless --path . --script tools/perf_scatter_density.gd
godot --headless --path . --script tools/perf_profile.gd -- --frames=120
```

## For the coordinator, directly

**The Hall's post-fix draw-call number at `hall_approach` is 2665** (down
from 2743 measured pre-fix on the same post-rebake tree). **The number
`ralph/T1-HALL-3` should build to is ≤ 4000 draw calls at that same stand**
— real headroom above the current fixed baseline for the added mass/detail
`JUDGE-5` is asking for, while staying meaningfully under the corridor's own
worst measured load. That worst-load comparison (`band1_open`, 5712–5929)
needs a post-rebake reconfirmation this session did not get to; flagging it
rather than guessing.
