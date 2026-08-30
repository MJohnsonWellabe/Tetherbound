# T1-WORLD handover — 2026-08-30

Branch `ralph/T1-WORLD`, off `origin/ralph/LAND-0830I`. Stood down mid-round on
the coordinator's wrap instruction. Working tree clean, everything pushed.

The full verdict is `ralph/reports/T1-WORLD/VERDICT-2026-08-30.md` with frames in
`ralph/reports/T1-WORLD/evidence/`. This page is the part the next effort needs
and the part that would otherwise have to be rediscovered.

---

## 1. The scatter root cause

**The finding: "ground scatter reads procedural" is real, it is NOT fixed, and
five render rounds of config tuning were aimed at the wrong system.** That last
part is the useful bit.

### What the blind pass saw

> "The broadleaf rosette repeats across the entire right-hand meadow at a
> near-constant ~1m interval. There is no clustering, no bare patch, no density
> gradient, no drift."

Also: the path pebbles lie along the centreline at even intervals, reading as a
dotted line rather than as debris.

### Why five rounds of tuning did nothing

I assumed the near-field dressing was the camera-following **cover tiers** in
`data/config/grass_field.json` and tuned them across five rounds. The answer was
three lines above the values I was editing:

```json
"suppress_scatter_layers": ["grass", "flowers"]
```

The grass field takes over **those two layers and nothing else.** The plants in
question are `data/config/vegetation.json`'s **`bushes`** layer (`Bush_Common`,
`Bush_Common_Flowers`, `Fern_1`) and **`groundmat`** (`Clover_1/2`,
`Plant_1_Big`) — still baked scatter placed by `scripts/world/scatter_rules.gd`.
**No value in `grass_field.json` reaches them.**

Measured, so nobody repeats it. Flower-pixel coefficient of variation over a
14×6 grid on the elevated frames, across every setting tried including a peaky
`drift_gate` at the `density_gain` ceiling:

| stand | CV | near-empty cells |
|---|---|---|
| village | 3.88 → 3.65 | 41 → 36 |
| band 1 | 1.03 → **1.06** | 13 → 16 |
| band 4 | 1.96 → 1.77 | 29 → 36 |

Within noise, in both directions.

### What the rule actually does wrong

This is the part that transfers, and it applies to **both** systems:

> A keep-roll that is an **independent Bernoulli trial per site**, over a
> **linearly remapped** noise mask, is a near-Poisson point process. Poisson has
> a characteristic spacing and **no clustering, by construction.**

That is exactly what "a near-constant interval with no bare patches" describes,
and it is a property of the placement **rule**, not of its parameters — which is
why no amount of tuning reached it.

Two corollaries, each of which cost a round:

- **`drift_contrast` had no headroom.** It was already 0.88–0.93, so taking it
  to 1.0 bought only 17–29% more spatial variance in the keep probability.
- **`drift_scale` is a frequency, and raising it makes things *more* even.**
  0.17 is a 5.9m patch over a 2.0m lattice — about three cells per patch, which
  is fine mottling that averages to uniform at any scale anyone looks at. I
  raised it in round 2 and measurably made two of three stands worse.

### What a fix would have to change

Not a parameter. The gating rule. `shaders/cover_tier.gdshader` now carries a
`drift_gate` uniform (**shipped at its 1.0 default, a no-op**) which raises the
noise to a power before it gates, so the mask is peaky rather than bell-shaped
and genuinely bare ground becomes reachable. That is the *shape* of the fix.

For the baked layers the equivalent lives in `scatter_rules.gd`. Note that its
`placements_for()` **already clumps correctly** — `clumps` × `per_clump` on a
sqrt-sampled disc — so the even reading is more likely coming from the
`corridor_fill` / `verge` paths or from clump envelopes overlapping so heavily
that the union is uniform. **That is the next thing to measure, and it was not
measured here.** Do not assume it; the whole lesson of this lane is that the
obvious system was the wrong one.

Whoever picks this up: **the fix is free in draw calls.**
`docs/PERFORMANCE_BUDGET.md` §3.3 — under Compatibility, draw calls track
MultiMesh **batches** in frustum, not the instances inside them.

### What I reverted, and why

**Every cover-tier value in `grass_field.json` is back to its pre-lane value.**
Leaving speculative churn in a config I cannot defend with evidence is exactly
the stale-prose failure this repo keeps paying for, and "I changed it and
something might be better" is not a reason to keep a diff. What is kept is one
comment carrying the measurements, and the `drift_gate` uniform at its no-op
default.

---

## 2. Stale bake — this blocks consolidation, and it is mine

**`data/scatter/playground` is STALE on this branch. It is the only stale bake,
and my change caused it.**

- **Why:** `scripts/world/scatter_bake.gd::config_fingerprint()` hashes the full
  contents of `data/config/vegetation.json`, `data/config/terrain_playground.json`
  and each `data/config/bands/*/vegetation.json`. I edited
  `terrain_playground.json` (`aerial_fade_range_m` 160 → 900, plus a comment),
  so the fingerprint moved.
- **What it costs if shipped:** `scatter_bake.is_fresh()` returns false and every
  boot recomputes the full corridor scatter — a ~60s stall, measured on this box.
- **Caught by:** `tests/test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh`.
- **The placements themselves do NOT change.** `aerial_fade_*` are terrain
  *shader* uniforms and are not inputs to scatter placement. This is a
  **fingerprint refresh**, not a content re-bake, so it should not move a single
  instance and needs no visual re-verification.

**To fix:**

```
godot --headless --path . --script scripts/world/bake_playground_scatter.gd
```
then commit `data/scatter/playground`.

I started this and **killed it before it wrote anything** — the working tree was
verified clean (`git status --short -- data/scatter` returned zero entries) at
the moment it was stopped, so there is **nothing half-written**. A stale bake is
recoverable; a torn one is not, and the wrap instruction was explicit about
preferring the former.

> **Sharp edge worth fixing separately:** the fingerprint is over whole file
> contents, so *any* edit to `terrain_playground.json` — including a pure comment
> — invalidates the scatter bake. That file is large, heavily commented, and
> touched by lanes that have nothing to do with scatter. Hashing only the keys
> the bake actually reads would stop this recurring.

### Other test state

`tests/run_tests.gd`: **1624 passed, 2 failed.**

- `test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` —
  **mine**, above.
- `test_band_content.gd::test_merged_arrays_are_identical_to_the_pre_split_files`
  — **pre-existing, not mine.** Verified by checking out
  `origin/ralph/LAND-0830I` and running it there: fails identically at the
  branch point.

---

## 3. The emission-floor merge on `ralph/LAND-0830J`

**Confirmed — it reads correctly to me, and T1-CAST's half is an improvement on
mine.**

```gdscript
if body and emission_floor > 0.0:
    material.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
    material.emission = colour * emission_floor          # T1-CAST: the VALUE
    material.emission_energy_multiplier = _emission_floor_scale   # T1-WORLD: the SCALE
```

The composition is exactly right: the rank supplies *how much* floor
(`npc_ranks.json`, so a grunt and a captain can differ), the clock supplies *how
much of it applies now* (`_emission_floor_scale`, driven from `art.json` through
`world_look.gd`). At the base scale of 1.0 it is byte-identical to each lane's
own daylight numbers, so both sides' measurements still hold.

Two things I checked rather than assumed:

- `material.emission_enabled = true` survives the merge (line ~553), so the
  floor is not dead code again — which is the exact failure T1-LIGHT's own
  header describes happening once before.
- My `set_emission_floor_scale()` rescan filters on `emission_enabled` **and**
  `emission_operator == EMISSION_OP_ADD`. In the merged form the ADD branch is
  taken exactly when `emission_floor > 0.0`, so the rescan still targets exactly
  the floor materials and cannot touch a rig's own painted emission.

**T1-CAST's gate is better than mine and supersedes it.** I gated on tint
luminance `< 0.95`; that fires on any character whose *per-instance palette*
happens to be dark, which is how band 4's `captain_field` (`palette #d9a878`,
luminance 0.686) tripped a gate whose own comment reasoned captains were
excluded. An explicit per-rank `emission_floor` has no such accident in it.

The night value I landed is **0.5** (`art.json`, `times.night` and `times.dawn`).
It was 0.25 first and that was too far — measured with the blind judge's own
method: 58.8% of the pixels in the trainer's torso/legs clipped to exactly
(0,0,0), against 0.3% before the change. At 0.5: 15.7% pure black, torso median
luma 8.1 against grass ~4.5, p95 62.4 — night-graded with the coat's form
intact. If the merged branch carries 0.25, **raise it**.

---

## 4. What the visual pass covered, and what it never reached

**Covered** — 75 frames, seven authored stands (`perf_site_survey.gd::VIEWS`
coordinates, so they are the same points the perf numbers use):

- village, bands 1–5, stronghold × day / golden / night
- three framings each: near-ground, **vista** (new — eye level, horizon in
  frame, which is the framing section J's question actually needs), elevated
- 3 weather presets at band 2, 3 water bodies at two framings, 1 landmark stand
- **every shutter ran `tools/capture_check.gd`.** 74 passed, 1 failed and was
  real (`water-02-river-grazing`, shot from below the terrain — the JUDGE-4
  `H-04` defect). Fixed and re-rendered. No verdict rests on a degraded frame.

**Never reached:**

- **Creatures.** Not one appears in any of the 75 frames. This tool settles only
  for terrain streaming and is explicitly "not a creature census"; a pass that
  settles for the encounter director is owed. Bar question B is therefore
  *partly unearned* — a real "no" on emptiness and character art, and an
  **unanswerable** on the thing the references are actually about.
- **Interiors** — no Warrens interior, no Hall interior, no buildings from
  inside. The Warrens interior is the standing GOOD example and was not
  re-verified.
- **Combat, UI, creature presentation** — out of scope for a world pass.
- **Bands 2, 3 and 5 after the fixes.** Rounds 2–5 re-rendered only village,
  band 1 and band 4. The aerial change is global and unverified at those three
  stands, though it is a terrain-shader uniform with no per-band branch.
- **A final blind pass on the shipped state.** The last blind judgement was of an
  intermediate round whose scatter settings have since been reverted. The
  shipped state was confirmed by a single-stand render (clean checks, aerial
  depth holding, scatter at baseline) but not blind-judged.

---

## 5. The other open items, with their evidence

- **Location 06 (stronghold) is what breaks the board.** Stands 00–05 read as one
  world and band 2 vs band 4 passes section J cleanly. 06 fails three ways:
  exposure a stop below the rest at every time of day (black at night), the only
  stand where the trees' near-LOD is visible and it disagrees with the far-LOD
  in the same frame, and no stronghold in either eye-level framing. Two of those
  are changes to landed lane work, not mine to touch.
- **Warrens mound: geometry, confirmed, and the old sub-finding is stale.** The
  material is fine — `landmark-01-warrens-exterior-golden.png` renders it as
  near-pure silhouette, so texture contributes nothing there, and it still
  fails. "Chamfered cubes" is **fixed** and should not be reopened; the defect
  moved up to the *arrangement* (`_build_mound` walks four straight rectangle
  edges and roofs each chamber with a regular grid, so the silhouette is a flat
  top ending in vertical faces). Fix list in the verdict §6. **Caveat: these are
  individual `MeshInstance3D`s, not a MultiMesh — "density is nearly free" does
  NOT transfer here.** Do items 1–4 by moving and re-scaling existing rocks.
- **Band 3 has a house instance at ~2.5× scale** (`ground-03-band3-crossing-day-high.png`,
  twice the height of the trees beside it, door ~4m against the bridge's 1.5m).
  One-line data fix in another lane's settlement config.
- **Far horizon is still a blown white band** peaking at (208,213,203),
  byte-identical before and after the aerial fix — it is fog meeting sky, not
  terrain. Reaching it means the fog axis, which `art.json` records the owner
  rejecting twice. **Left for an owner call rather than changed unilaterally.**

---

## 6. State

- `ralph/T1-WORLD` pushed, working tree clean, nothing in flight.
- Shipped changes: the aerial range, the clock-driven emission floor, the
  capture tool (7 stands, vista framing, `capture_check` at every shutter,
  list-valued `--only`, water grazing floor), `drift_gate` as a no-op default,
  the sheet-staging script, seven missing `.uid` sidecars.
- **One action required before consolidation: re-bake `data/scatter/playground`**
  (§2). Nothing else here blocks.
