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
| after | 6,977 | 10,818,854 | 5,996 |

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

Full verdict: `ralph/reports/W05-TREELINE-0904/JUDGE-after.md`. Run on the after sheet
and the four full-resolution frames plus `docs/reference/`, told nothing about what
changed, by a sub-agent following `.claude/skills/visual-judge/SKILL.md`. It reports the
**absolute** state; it never saw the before frames, so the "improved" claim in this
report rests on §3's and §4's numbers, not on the judge.

**Acceptance is PARTIAL, not met.** The brief's bar was "judge names silhouette variety
improved on the named stands with no new scale defect". Stand by stand:

| stand | judge's verdict on tree-line silhouette |
|---|---|
| `comp7-pond-reveal` | **"the only stand with a real tree-line, and it is good"** — four distinguishable individuals in the right-hand run, canopy tops at y≈145/158/172/190 on bases within 15 px; the left grove reads "much older" with "a layered interior with visible sky holes" and "secondary branch structure inside the canopy rather than a solid blob". Tallest ≈15.5 m, **8.6 player heights**. "**Varied**, roughly a 4:1 height spread with three legible age classes. This is the standard the other three stands are failing to meet." |
| `place2-the-rise` | **"the worst offender: a repeated row"** — six mid-ground trunks with canopy tops spanning only 16 px; "a picket fence with green on top". Verdict **near-uniform**. |
| `place5-bridge-approach` | **"no tree-line is presented"** — the frame is walled by cropped near-camera giants; the only full trees are a distant plateau row of "near-equal lollipops". |
| `comp8-bridge-rim` | **"the camera is inside the grove; there is no silhouette to read"** — all seven large trunks are cut by the top edge and "the upper third of the image is a continuous near-camera leaf ceiling that closes off the entire skyline". |

So the change is confirmed to read on the one stand that actually presents a tree-line,
and is not confirmed on the other three — two of which the judge finds cannot present
one at all from where they are shot.

**One of those three is worse because of this lane, and I am not going to dress it up.**
`comp8-bridge-rim`'s canopy ceiling is a direct consequence of growing the trees: the
before frame has visible sky between the crowns, the after frame does not (my own
pre-registered skyline metric caught it independently — sky fraction 0.032 → 0.017, and
the per-column skyline "relief" degenerating from 41.5 px to 1.9 px because the canopy
now leaves the frame rather than breaking against sky). The stand is 3 m from a trunk by
its own authored siting; taller trees turn that into a ceiling. **Recommended follow-up
(not done here, it is a framing change that would break before/after comparability
mid-round):** pull `comp8-bridge-rim`'s eye back along its own sightline until the
crowns are in shot.

**The dominant scale finding is the mesh, not the scaling.** The judge measures
trunk-to-canopy at **1:3.1 – 1:3.6** across every frame against roughly 1:9 for a real
broadleaf, and concludes the trunks are "two to three times too thick for the crowns they
carry", so "even the good `comp7` tree line reads as a row of stumpy mushrooms rather
than as oaks". That is `CommonTree_*` geometry — exactly the residual §4a already routes
to closure-plan CL-A1 (a branching / re-proportioned tree form, art not in the build).
Growing a trunk-plus-blob makes a bigger trunk-plus-blob, which is the honest ceiling on
this lane. Its ranked gap #3 says the same from the other side: per-instance jitter,
lean, and framing are scene work; "the trunk-to-canopy proportion is baked into the mesh,
and there is no mid-age tree" is not.

**One judge claim I checked and do not pass on as fact.** It infers from the waymarker
signboard that `place2` and `place5` "were shot from a knee-height camera... **≈1.05 m**",
which would be a capture-harness defect. Checked against the source rather than repeated:
`tools/_capture_band1_places.gd` sets `eye_h` **2.4 m** for `place2` and **2.2 m** for
`place5`, applied as ground + eye_h in `_pose()`, and `scripts/world/signpost.gd`'s
`POST_HEIGHT` is **2.35 m** — so the inference is out by more than 2×, most likely
because the post's base is occluded by ground cover and only part of it was measured. The
observation underneath it is real, though, and is a framing question rather than a bug:
`horizon` 0.26–0.30 puts a lot of near ground in these frames, which is why the judge
reads ~55% of `place2`/`place5` as a blurred foreground plane.

**Findings outside this lane's files**, recorded for whoever owns them rather than acted
on: no creature or NPC in any of the four frames (its ranked gap #1, "by a wide margin
the largest gap", spawn/staging work); the `comp7` cottage reading ≈1.9 m to the ridge;
`place5`'s bridge crossing no water or gap; a terrain shear and an untextured wedge at
`place5`; `place2`'s horizon ending in a hard grey band; evenly-spread unclustered
bushes and thin ground-cover mat; no contact shadow under the trainer; and bark sampling
`#833B1F`–`#864024`, the same rust the board reserves for Team Tether — a re-statement of
the oxblood-reservation finding §4a already carries.

**Rounds used: one.** The brief allows two. A second round was not spent: the two things
that would move the verdict are a capture re-framing at `comp8` (which belongs with the
coordinator's stand set, not mid-round) and a tree mesh with real branch structure
(CL-A1, art not in the build). Two rounds of scale tuning against a mesh whose
proportions are the finding would be the "tuning rounds are not progress" trap
`AGENT_WORKFLOW.md` §7 names.

## 7b. Round 2 — the walk-blocking collider regression, and its fix

**This lane shipped a real regression and it was caught before landing.** PR #47 was
closed by the landing lane because `smoke_aggression` failed deterministically on these
changes, on two machines: *"stood 53.7m from Galecrest for 900 frames without pressing
anything and it never attacked"* — the scripted walk toward the aggressor never gets
within the 10 m it needs.

**Reproduced here first, then diagnosed rather than assumed.** The test's own header
records this same walk historically stalling at ~40 m against the `Terrain3D` node with
no tree involved, so the attribution needed checking, not accepting.
`godot --headless --path . --script tests/smoke_aggression.gd` on branch head reproduced
the failure at exactly 53.7 m. `tools/_probe_walk_block_0905.gd` (new) then walked the
same line with the same start, the same held input and the same unstick escape, and
named the blocker at the stall:

```
player=(40.54, 0.80, -65.82)  dist_to_galecrest=53.70 m  on_wall=true  vel=(0,0,0)
wall_normal=(-0.076, 0.000, 0.997)     ground slope here = 6.8 deg
  test_move 0.5 m BLOCKED by CommonTree_1_Collision (StaticBody3D)
  test_move 1.0 m BLOCKED by CommonTree_1_Collision (StaticBody3D)
  test_move 2.0 m BLOCKED by CommonTree_1_Collision (StaticBody3D)
  nearest trunk cylinders: r=1.21 h=8.10 axis 1.61 m away  (gap 0.40 m)
                           r=0.63 h=4.18 axis 1.13 m away  (gap 0.50 m)
```

So it is this lane's, and it is a genuine player-facing defect rather than a test
artefact: the ground is ordinary 6.8° meadow, and the blocking cylinder is a tree that
carried **r = 0.89 m before this lane and r = 1.21 m after**. Placements never moved
(825,979 kept either side) — the tree got wider.
`vegetation.gd::_make_collision_shape` sizes the trunk as `collision_radius × placement
scale`, so growing the mesh grew the obstacle with it.

**Fix: decouple collider growth from visual growth** (`data/config/vegetation.json`,
this lane's own file). `collision_radius` is scaled down by exactly the factor
`scale_max` went up:

| layer | collision_radius | widest collider, main | widest collider, now |
|---|---|---|---|
| `trees` | 0.6 → **0.435** (× 1.45/2.0) | 0.974 m | 0.974 m |
| `grove` | 1.1 → **0.70** (× 1.15/1.8) | 1.075 m | 1.071 m |

The widest collider in the world is now the widest collider `main` already shipped, and
every other instance's collider is strictly *smaller* than before — so no tree anywhere
can block a line `main` did not already block. The trees themselves are untouched: the
visual result in §3 and the judged frames still stand. Trimming `scale_max` back was
rejected — it undoes the lane, and `CLAUDE.md` says grow, never shrink.

**The collider is still inside the trunk, measured not assumed**
(`tools/_probe_trunk_radius_0905.gd`, new): the CommonTree trunk's own radius over its
lowest 2 m is 0.741 m at scale 1.0, TwistedTree_2's is 1.351 m — both the old and the
new radii sit inside the visible trunk. Honest cost: brushing the very largest trunks
now clips a little further into the bark. Recorded in `docs/decisions/D74` §4, with the
general lesson — in this codebase a scatter layer's visual size and its collision size
are the same number, and the test that catches that is a walk, not a render.

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
- **The collider fix trades a little camera/trunk clipping for the unblocked route.**
  Because `collision_radius` is scaled down by a constant factor, the *widest* collider
  matches `main` exactly but every smaller instance's collider is up to ~27 % tighter
  than it was, so the collider sits at **59 % of the trunk radius instead of 81 %**.
  Measured at the largest common tree in each build (trunk radius = 0.741 m × placement
  scale, from `_probe_trunk_radius_0905.gd`):

  | | placement scale | trunk r | collider r | player can clip in |
  |---|---|---|---|---|
  | `main` | 1.624 | 1.203 m | 0.974 m | 0.229 m |
  | grown, collider untouched | 2.240 | 1.660 m | 1.344 m | 0.316 m |
  | grown + this fix | 2.240 | 1.660 m | 0.974 m | **0.685 m** |

  So the honest cost is bigger than "a little": against the very largest trunks a player
  can push about 0.69 m into the bark where `main` allowed 0.23 m. Two thirds of that is
  the fix, one third is simply the tree being bigger. The same applies to the camera
  SpringArm, which stops on these colliders (see `vegetation.json`'s own
  `_comment_collision`, written after survey frames came back showing the inside of a
  bush). Not observed in the four rendered stands, and it is a cosmetic cost against a
  hard block on a route the game asks players to walk — but if a playtest calls the
  clipping out, the lever is this number and the answer is a per-instance collider
  (`collision_radius` × a sub-linear function of scale) in `vegetation.gd`, which is a
  script change and outside this lane.
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
