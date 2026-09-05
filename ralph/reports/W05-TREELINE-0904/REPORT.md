# W05-TREELINE-0904 — the tree-lines that read as "one lollipop, repeated"

Branch `ralph/W05-TREELINE-0904` (from `origin/main` @ `ef16544f`). Godot 4.7-stable
installed fresh in-container; every number below was produced here, not self-reported.

## 1. What changed (player-visible)

The common broadleaf tree-line along the Band 1 route now carries an age range instead
of one size: the tallest fill trees reach 18.9 m (10.5× the 1.80 m trainer) where they
topped out at 13.7 m, the median tree is 9.9 m instead of 7.7 m, and one tree in three
now clears 12 m where it was one in fifteen. Lone landmark common trees, the ancient
oaks and the dead-tree accents grew with them so the authored hierarchy (fill < lone
hero < ancient oak) survives. Nothing moved: every placement, model and yaw is the same
as before, only sizes changed. Saplings stay young.

The committed scatter bake was also **stale on `main`** before this lane touched
anything (see §5), so the game was recomputing the full corridor scatter on every boot.
The re-bake here repairs that as a side effect.

## 2. Files changed

| File | Change |
|---|---|
| `data/config/vegetation.json` | `trees.scale_max` 1.45→2.0; `trees.heroes` 1.7–2.1→2.2–2.7; `grove.scale_max` 1.15→1.8; `grove.heroes` 1.15–1.35→1.6–1.9; grove anchors at the Rise crest 1.3→1.6 and the Gate Meadow knoll 1.25→1.5; `deadfall.scale_max` 1.15→1.6 plus `model_scale` 0.72 on the two mushrooms so they do not grow; Band 1 `trees` anchors with explicit ranges ×1.379 (shoulders untouched); a `_comment_scale_w05_treeline_0904` note per layer |
| `data/config/bands/band1_lower_meadows/vegetation.json` | the same ×1.379 lift on its `trees` anchors that carry explicit ranges (copse peaks/bodies, frame trunk, crest pair, comp4 pin, basin and far-rim treelines, station 04); shoulder pairs (`scale_max` ≤ 0.85) untouched; a file-level note |
| `data/scatter/playground/` (manifest + 256 regions) | re-baked, same commit as the config |
| `tools/_probe_tree_heights_0904.gd` | new: reads the bake, reports per-layer rendered height distribution in metres against the trainer |
| `tools/_capture_band1_places.gd` | `--only=a,b` stand selection (same contract as the composition capture) |
| `docs/decisions/D74-…` | the size hierarchy and the "a scale range is not a re-roll" finding |
| `docs/VISUAL_BIBLE.md` §4a, `docs/CURRENT_STATE.md` | status rows |
| `ralph/reports/W05-TREELINE-0904/` | this report, `_sheet_before.png`, `_sheet_after.png`, `JUDGE-after.md` |

Not touched, on purpose: `scripts/world/scatter_rules.gd`, `terrain_playground.json`,
`data/terrain/`, bands 2–5 anchors, `saplings`, any `scale_min`.

## 3. Before / after, measured off the bakes

`godot --headless --path . --script tools/_probe_tree_heights_0904.gd` (heights =
native glTF AABB × baked instance scale; n = placements corridor-wide, Band 1 subset
within 0.1 m of the same figures).

| Layer | | p5 | p25 | p50 | p75 | p95 | max | ≥ 12 m | p95/p5 |
|---|---|---|---|---|---|---|---|---|---|
| trees (n 43,051) | before | 4.2 | 5.8 | 7.7 | 9.6 | 12.4 | 19.7 | 6.6 % | 2.98× |
| | after | 4.5 | 6.9 | 9.9 | 12.9 | 16.8 | 25.4 | 32.2 % | 3.76× |
| grove (n 358) | before | 8.4 | 11.1 | 13.0 | 15.4 | 18.2 | 21.4 | 63 % | 2.17× |
| | after | 9.5 | 13.4 | 18.0 | 22.2 | 28.0 | 30.1 | 84 % | 2.94× |
| deadfall dead trees (n 66) | before | — | — | 5.9–7.6 | — | — | 10.0 | 0 % | — |
| | after | — | — | 6.3–9.4 | — | — | 13.7 | 3.6 % | — |
| saplings (n 2,779) | both | 1.9 | 2.5 | 3.0 | 3.5 | 4.4 | 4.7 | 0 % | 2.30× |

Per-model after: CommonTree_3 4.7–18.9 m (fill), CommonTree_1 4.1–16.3 m, CommonTree_2
3.3–13.1 m; the 25.4 m maximum is a `heroes` instance. Mushrooms unchanged at ≤ 0.4 /
0.6 m. Anchor placement warnings: the same four pre-existing under-placements
((2,47), (−58,199), (−10,1318), (−248.7,6462.9)) and no new one.

**RNG safety, proven by the bake rather than argued:** both bakes produce 825,979 kept
and 3,883 drained placements. The `_comment` in `vegetation.json` and D74 record why:
`scatter_rules.gd::_consider` draws scale, model and yaw unconditionally, in fixed
order, after every rejection test, so a wider range consumes the same draws.

## 4. Perf proxy (`tools/perf_render_stats.gd -- --views=band1_open`, default settle)

| | draw calls | primitives | objects |
|---|---|---|---|
| budget (plan) | ≤ 7,500 | ≤ 12.0 M | |
| before (this container, current config) | 6,963 | 10,800,474 | 5,982 |
| after | AFTER_DRAWS | AFTER_PRIMS | AFTER_OBJS |

## 5. Finding: the bake on `main` was already stale

`test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` **fails on
`origin/main` @ `ef16544f`** before any edit here. Cause: `f2dd20e4` ("test(visual):
make VP0 capture failures trustworthy") changed only the `config_fingerprint` line of
`data/scatter/playground/manifest.json` (7496100143687718 → 404295163156206) with no
region files re-baked, while `vegetation.json`, every band `vegetation.json` and
`terrain_playground.json` are byte-identical to the last real bake (`3c73aab5`). The
fingerprint is a hash of the config files' text, so the most likely story is a
Windows checkout with different line endings producing a different hash and the
manifest being edited to match it. Consequence on `main`: `vegetation.gd` fell back to
computing the corridor scatter at load on every boot (~4 min in this container; the
test's header measured ~60 s on a faster box). This branch's re-bake carries the
Linux-computed fingerprint `4984520267706256` and the test passes.

**Confirmed in the running game, not only in the test.** The before-render's own log
(`shots_places` capture on the unmodified tree) carries four
`WARNING: scatter anchor at (…) placed N of M` lines emitted from
`scatter_rules.gd::_place_anchor` ← `all_placements` ← `vegetation.gd::build`, and **no**
`[scatter bake] load phases` line: the world was computing the corridor scatter from
scratch as it built. The after-render's log shows the opposite (bake loaded, no
`all_placements` warnings), which is what a fresh bake being consumed looks like.

**Same commit, same pattern, not this lane's file:** `data/terrain/playground/
manifest.json` was hand-edited too, and `test_terrain_bake_freshness.gd::
test_playground_terrain_bake_is_committed_and_fresh` fails on `main` for the same
reason. Not touched here (the brief forbids `data/terrain/`); the coordinator's terrain
re-bake window should run `build_playground_terrain.gd` once.

## 6. Tests and runs

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` on the unmodified tree | **FAIL** (stale manifest, §5) — the red-for-the-right-reason run for the freshness guard |
| `godot --headless --path . --script scripts/world/bake_playground_scatter.gd` | 825,979 placements (3,883 drained), 11 layers, 231,675 ms compute; 256 regions, 29,836,475 bytes |
| `… --only=test_scatter_perf_budget.gd` (after bake) | 3 tests, 6 assertions, 0 failed |
| `… --only=test_scatter_rules.gd` | 38 tests, 1,019,854 assertions, 0 failed |
| `… --only=test_veg_corridor.gd` | 9 tests, 1,537,510 assertions, 0 failed |
| `… --only=test_band_vegetation.gd` | 5 tests, 142 assertions, 0 failed |
| `… --only=test_terrain_bake_freshness.gd` (report only) | 3 tests, 1 failed: `test_playground_terrain_bake_is_committed_and_fresh` (pre-existing, §5) |
| `tools/_probe_tree_heights_0904.gd` before / after | §3 |
| `xvfb-run … tools/_capture_band1_places.gd -- --fast --only=place2-the-rise,place5-bridge-approach` before / after | 2 frames each, rc 0, spread 1.44–1.54 (not degenerate) |
| `xvfb-run … tools/_capture_band1_composition.gd -- --fast --only=comp7-pond-reveal,comp8-bridge-rim` before / after | 2 frames each, rc 0 |
| `xvfb-run … tools/perf_render_stats.gd -- --views=band1_open` before / after | §4 |

## 7. Code-blind judge

JUDGE_SECTION

## 8. Known limitations, and what was deliberately not done

- **`scripts/world/vegetation.gd::PROP_OFFSET` (1.3 m) is now undersized, and I did not
  fix it** — it is a script file, outside this lane's ownership. Its own comment sizes it
  against "the widest trunk this scatter places (CommonTree at 1.35 scale)". That
  reference was already stale before this lane (the fill's `scale_max` was 1.45 and
  `heroes` reached 2.1); this change makes it worse — the fill now reaches 2.0 and a hero
  2.7, so the felled-wood pile beside a large harvest-marked tree can sit inside the
  trunk. Trunk collision (`collision_radius` 0.6 × scale) reaches 1.20 m at the fill's
  new top and 1.62 m at a hero's, against the 1.3 m offset. **Suggested fix for whoever
  owns `vegetation.gd`:** raise `PROP_OFFSET` to ~1.9 m, or derive it from the placement's
  own scale rather than a constant. Not observed in any of the four rendered stands (no
  woodpile was in frame), so this is reasoning from the constant, not a sighting.
- Bands 2–5 anchors with explicit ranges were **not** lifted; the fill around them grew,
  their copses did not. Their frames were not judged this round.
- Grove reaches 2.94× p5–p95 (range 3.0× by config); the brief's "≥ 3× per family" is
  met exactly by the common-tree family and nominally by the grove.
- Captures ran in `--fast` mode (settle halved, MSAA off) on both sides for time; edge
  aliasing in the sheets is the capture mode, not the change.
- Not attempted: clustering/clearing authoring (CL-B2's other slice), a branching tree
  form (CL-A1), any terrain input.

## 9. Final state

Branch `ralph/W05-TREELINE-0904`, head `FINAL_HASH`. Bake commit `46a6d195`.
