# PLACES area — visual parity, round 1

**Branch** `claude/vp-places` · **start commit** `e3aba7d7` (VP0 merge of the GROUND+VEG lane code)
**Owns** VP5 (village / tournament / camps), VP6 (Warrens exterior), VP7 (Relay), VP8 (Meadows Hall)
**Round scope, as briefed:** render and verify the code two earlier lanes pushed unrendered. **No new
dressing was added by this lane in round 1.** Every change described below arrived by merge.

---

## 1. What the merged code changes

Both lane branches merged into `claude/vp-places` with **no conflict**. They touch **no file in common**
(verified with `comm -12` over the two `--name-only` diffs, and with `git merge-tree --write-tree`,
which reported clean for each). So there was no conflict to resolve and no judgement call to report.

### 1a. `origin/claude/vp-village` (VP5) — 2 commits, 8 files, +873/-143

| file | change |
|---|---|
| `data/config/village_boundary.json` | **Gates 2 → 3.** Adds `TrailGate` at `(13.79, 22.4)`, yaw `175.1`, on `terrain_playground.json`'s `trail.bands[0]` corridor spine — a third road that previously crossed the fence with no gate at all (34.8 m from the nearest gate). Same `castle_gate_key`, same `road_gate_open` flag, same `road_gate.gd` body. Outline polygon re-authored **22 → 26 points** so every gate sits at the midpoint of a 4.4 m edge and neighbouring edges are exact multiples of the 6.15 m fence-panel length; this closes a measured **1.9 m unfenced gap at RoadGate's NE jamb** (the lane's own probe walked a keyless player 13.8 m out through it). `RoadGate.at` nudged `[38.7,-19.9]→[38.72,-19.85]`, yaw `-71.6→-71.57`. `PondGate` and `vault_guard_m` unchanged. |
| `data/config/village.json` | Additive dressing only — no plot or road-layout rework. 10 new `structures[]`: 3 `doorstep` (cottage_a, cottage_b, inn thresholds), 3 `fence_run` (Grandpa's kitchen garden N+W, plus one closing the inn/garden lawn gap), 2 `wagon`, 3 more `square_oak_a`/`_b` as village-edge canopy inside the fence. Separately, the existing woodpile/crate (Grandpa's) and barrel/bench (inn) were **relocated** — the lane's probe found their old positions *inside* the farmhouse and inn colliders. Carries an explicit `_comment_vp5`: "not one more object than the yard needs, no new villagers." |
| `data/config/bands/*/props.json` | **20 new prop instances total**, counted as added `"model"` lines with zero removed: band1 lower-meadows **12** (2nd inn barrel; 7 tournament-ground pieces — barrel, staging crate, bucket, bag, 3 banners; 2 cottage_b backyard woodpile logs; 2 garden crate+bucket), band3 river-lock **2** (2nd camp seat log, `camp_tent`), band4 upper-meadows **2** (firewood logs) plus a new `rest` block giving that camp a `creature_bed` it never had, band5 stronghold-approach **4** (log, `camp_tent`, `Barrel`, `Crate_Wooden`). Several existing props repositioned off collision. |
| `data/config/building_prefabs.json` | `well` retint `MI_RockTrim` `#f0e2c4 → #a39d8e` + new `MI_Brick` multiply `#b9b1a2` (owner: the well pad "reads as clean white stone — weather it"). New `doorstep` prefab: 2× `Floor_UnevenBrick` modules, one rotated 90° so courses do not align, with a 4.0×0.1×2.0 collider at y=0.09, so the runtime grass ring stops growing through doorways. |
| `ralph/reports/visual-parity/VILLAGE/REPORT.md` | New 105-line report **draft**; sections 3–7 are still placeholders. |

**Owner-constraint check.** No NPC file is touched and no villager is added or moved — the "too many
people in the village" verdict is respected but not addressed by this branch. Against "do not overfill
with props": the branch adds ~30 placed objects across both schemas (20 props + 10 structures), which
is the single biggest thing round 2's judge should rule on from the frames.

### 1b. `origin/claude/vp-hall` (VP8) — 1 commit (`992fbec7`), 5 files, +838/-202

| file | change |
|---|---|
| `assets/environment/team_tether/hall/hall_stone.gdshader` | **New, 173 lines.** World-space triplanar stone replacing the Hall's flat-tint `StandardMaterial3D`: ~10 m macro tone noise, per-stone cell-hashed variation, moss seeded in mortar joints (luminance under `joint_threshold`) then spread by patch noise and weighted toward up-facing and near-ground surfaces, plus a damp band with vertical rain streaks under `damp_top_y`. Cost: 3 triplanar reads (9 samples) + ~6 `vnoise` calls per fragment, no loops, no screen-space sampling. |
| `assets/environment/team_tether/hall/banner_cloth.gdshader` | **New, 134 lines.** Replaces 6-draw-call rigid box banners with one subdivided plane: swallowtail/notch/torn-relic silhouette by `discard`, selvage/hem/weave and the faction device painted in-fragment (device sampled from `tether_sigil.gd::texture()`), and two summed sines on `TIME` displacing vertices for wind sway with slope-derived fold shading. Trivial cost. |
| `data/config/stronghold.json` | New `site.weathering` block feeding the stone shader (`moss_amount` 0.46, `moss_scale` 0.3, `moss_colour` `#2f4d1c`, `joint_threshold` 0.4, `up_moss` 0.55, `damp_height` 3.0, `damp_strength` 0.26, `streak_strength` 0.2, `macro_strength` 0.24, `stone_strength` 0.14, `ground_above_skirt_foot_m` 11.5, floor variants). New `exterior_conduit_energy` **0.45**, fixing a conduit "blown out to white" defect. Exterior ivy **cut ~35–40 % per band** (49→30, 34→21, 57→35), `clump_spread` 0.7→0.42, tints darkened/desaturated (`#1a5900`→`#2c5220`, `#134400`→`#22421a`), and the two gate-face bands gain `"skip": [-3.2, 3.2]` so vines stop curtaining the arch. No key removals. |
| `scripts/world/stronghold.gd` | 625 changed lines. New `_build_gate_arch_and_portcullis()` (with `VOUSSOIRS := 11`), `_parapet_rubble_heap()`, `_smoke_column()` + `_soft_disc_texture()` and `BOILER_STACK_TOP` (boiler smoke), `_stone_shader_material()`, `_damp_lift()`, `_stone_variant()`, `_exterior_live_material()`, `_kit_mesh_and_material()`, `_banner_cloth_material()`. Material-producing functions widen their return type `StandardMaterial3D → Material` so they can hand back either a plain material (conduits, timber, iron — unchanged) or the new `ShaderMaterial`. |
| `scripts/world/interior_structure.gd` | One hunk. See §2. |

**Both new shaders are actually referenced** — `stronghold.gd` preloads them as `HALL_STONE_SHADER`
(used by `_stone_shader_material()` ← `_material()`) and `BANNER_CLOTH_SHADER` (used by
`_banner_cloth_material()` ← `_hang_banner()`). They are not dead assets; they will change the render.

**VP7 (Relay) has no code this round.** `data/config/tether_relay.json` and `data/config/relay_site.json`
are untouched by *both* branches — `git diff --stat` is empty for each. The relay frames in this report are
therefore current-`main` state, captured as a baseline for a future round, not evidence of a change.

---

## 2. `interior_structure.gd` — extend or replace? **EXTENDS.**

The owner's rule is that this file may be extended, never replaced. The entire diff is:

```diff
-	if material is StandardMaterial3D:
+	if material is Material:
 		mesh.material_override = material
```

plus one explanatory comment (+4/−2 lines in the whole file). It **extends**, and no revert was needed:

- `Material` is the base class of `StandardMaterial3D`, so widening the check strictly *broadens* what is
  accepted. Every value that satisfied the old test satisfies the new one.
- No function, signature, parameter, default or code path was deleted or rewritten. `dress()`, the bay
  and jointed-course logic, ceiling ribs, framed openings, corner posts and tints are all untouched.
- There are exactly two callers (`grep -rn "interior_structure" scripts/`): `stronghold.gd` and
  `burrow_warrens.gd`. **`burrow_warrens.gd` is not touched by this diff at all** and still passes a
  `StandardMaterial3D`, which the widened check still matches — so the owner-approved Warrens interior
  renders identically, byte for byte in its material path.
- `stronghold.gd` opts in on *its own* side by widening what `_material()` returns. Previously a
  `ShaderMaterial` handed to this function would have been silently dropped; now it is applied. That is a
  capability addition, not a behaviour change for any existing working caller.

---

## 3. Before frames

`ralph/reports/visual-parity/PLACES/00-before/` — 1280x720, `LIGHT=1`, rendered from `e3aba7d7`
**before** either merge. Every site I own, at every stand; the four sites `_capture_locations.gd` marks
`"night": true` (village, relay-camp, ridge-camp, stronghold) also carry a night frame.

| site | before frames (`00-before/locations/`) |
|---|---|
| 01-village (VP5) | `01-village-{approach,standing,route-out,grandpa-yard,tournament,twins}-{day,night}.png` (12) |
| 04-warrens (VP6) | `04-warrens-{approach,standing,den}-day.png` (3) |
| 05-relay-camp (VP5) | `05-relay-camp-{approach,standing,fire}-{day,night}.png` (6) |
| 06-relay (VP7) | `06-relay-{approach,standing,apparatus}-day.png` (3) |
| 08-ridge-camp (VP5) | `08-ridge-camp-{approach,standing,fire}-{day,night}.png` (6) |
| 09-waystop (VP5) | `09-waystop-{approach,standing,bench}-day.png` (3) |
| 10-stronghold (VP8) | `10-stronghold-{approach,gate,courtyard}-{day,night}.png` (6) |
| 11-castle-landmark (VP8) | `11-castle-landmark-{approach,gate,banners}-day.png` (3) |

Plus `00-before/survey/` (5) and `00-before/ground/` (6). All pushed in commit `ec028f36`.

---

## 4. The stale scatter bake — a real cost this round paid for the program

Worth the program coordinator's attention because it affects **every lane's render times**, not just mine.

`scatter_bake.is_fresh()` fingerprints `data/config/vegetation.json` **and**
`data/config/terrain_playground.json`. On the lane's own start commit those fingerprints did not match:

| what | commit | time |
|---|---|---|
| committed bake `data/scatter/playground/` | `dcec904e` | 00:24 |
| `vegetation.json` changed | `0a4a0ff6` (also `b9d735c2`) | 01:04 |
| `terrain_playground.json` changed | `6454c6ce` | 01:12 |

So `vegetation.gd::build()` was falling back to recomputing every placement live **on every world
stand-up**. This is the same regression `OWNER-0902-LOAD-TIME` (`be349d97`) diagnosed and fixed on
`main` — reopened, because that fix worked by re-running the bake and the VP0 lane merges then edited
the config again. Note `be349d97` is **not** an ancestor of `e3aba7d7`; 34 `main` commits are missing
from the program branch.

Re-running `scripts/world/bake_playground_scatter.gd` locally measured the cost directly:

```
computed 819426 placements (3093 drained) across 11 layers in 274820 ms
baked -> data/scatter/playground (256 regions, 29582017 bytes, 36.0 bytes/placement)
```

**274.8 s of recompute per world stand-up.** Manifest `config_fingerprint` moved
`7433092575143526 → 7938790590817722`, which is the direct proof the committed bake did not match the
config being rendered. Boot-to-first-shutter fell from ~627 s to **352 s**. `vp_capture.sh` performs
five world stand-ups, so this is roughly 23 minutes per capture pass, per lane.

Per the lane brief, `data/scatter/**` is **not committed** — the 257 regenerated bake files are held
under `git update-index --skip-worktree` so they cannot enter a commit.

**Recommendation to the program coordinator:** the Ralph landing pipeline still does not re-bake when
`vegetation.json`/`terrain_playground.json` change (`be349d97` flagged this as out of scope). Until it
does, every lane that merges VEG/GROUND config silently loses ~4.6 min per stand-up. Either bake in the
lane brief's environment recipe or gate it in CI.

---
## 5. Perf — draw calls at the fixed stands

`tools/perf_render_stats.gd --views=hall_approach,village_high --settle=120 --resettle=60 --sample=20`,
at a fixed 1280x720 in both runs (the perf stage is pinned to that resolution regardless of `VP_FAST`,
so the before/after numbers are directly comparable). `driver=X11 adapter=llvmpipe`,
`scatter_lod_ranges=true`.

**Before (unmerged `e3aba7d7`)** — `00-before/perf_render_stats.txt`:

```
view                     draw calls     primitives      objects
village_high                   4376       18087761         4474
hall_approach                  4331       13212179         4676
```

**The ≤ 4000 draw-call budget at `hall_approach` is already breached on the baseline — 4331, before this
lane merged anything.** `docs/PERFORMANCE_BUDGET.md` sets that ceiling and the lane brief repeats it, so
this is a pre-existing failure inherited from the VP0 GROUND+VEG merge, not something the village or Hall
branches caused. `village_high` (4376) has no stated ceiling but is the higher of the two.

This reframes the round-2 question for both my areas: the village branch adds ~30 placed objects and the
Hall branch adds gate-arch voussoirs (11), parapet rubble heaps and a smoke column, all of which cost
draw calls at exactly these two stands. The after numbers below say whether that made an already-failing
budget worse.

## 6. Playability guard — the nine smoke tests

Run headless on the **merged** tree (`godot --headless --path . --script tests/<name>.gd`). Whole suite 1655 s (27 m 35 s); no test crashed or timed out.

| test | exit | result |
|---|---|---|
| `smoke_authored_camps` | 0 | PASS |
| `smoke_traversal` | 1 | **FAIL** — see below |
| `smoke_playground` | 0 | PASS |
| `smoke_village_trainer` | 0 | PASS |
| `smoke_tournament_bracket` | 0 | PASS |
| `smoke_stronghold` | 0 | PASS |
| `smoke_relay` | 0 | PASS |
| `smoke_warrens` | 0 | PASS |
| `smoke_gate_e_finale` | 0 | PASS |

**Nothing the merged dressing placed blocks a door, path, ring, spawn or bed.** That is the specific
guard the brief asks about, and it is clean: `smoke_traversal` positively confirms all four village doors
(`cottage_a`, `cottage_b`, `ranger_station`, `inn`) still read "shut and blocking -> interact -> open and
clear, room behind it", and `smoke_village_trainer`, `smoke_tournament_bracket`, `smoke_authored_camps`,
`smoke_stronghold`, `smoke_relay` and `smoke_warrens` all pass on the merged tree — so the tournament
ring, the camp rest points (including band4's newly added `creature_bed`) and the Hall/Warrens/Relay
spawns are all still reachable. No prop needed moving.

### The one failure, verbatim

```
  the South Bridge, locked:   reached +6348.4m past the gap
  the South Bridge, unlocked: reached +22.7m past the gap

traversal FAIL: crossed the South Bridge without the key (6348.4m past the gap) — the gate can be walked around
```

**This is not caused by either merged branch, and it is not a prop-blocking defect.** It is the inverse:
a barrier that fails to block. Evidence for the attribution:

- The South Bridge gate is authored in `data/config/terrain_playground.json`, `data/config/opening.json`
  and `data/config/map_landmarks.json`. **The merge touches none of them** (`git diff --name-only
  e3aba7d7..HEAD` lists only the 10 code/config files in §1). The only `south_bridge` string anywhere in
  the merged diff is a `_why` prose field whose `§` was re-encoded as `§` — a JSON escaping change
  with no functional effect.
- The village branch's boundary work is the *village fence*, a different barrier, and the same test run
  shows the two barriers it does own passing: the Sigil Gate seals at every one of its eight probed
  bearings (`locked ... reached -0.5m past the gate` at 0/±3/±6 m off centre, both directions) and opens
  correctly when unlocked (+22.4 m / +20.7 m); the Old Mill Crossing likewise (locked -8.0 m, unlocked
  +23.6 m).

It is, however, the **same class of defect** as owner playtest 2026-09-01 item 5 ("I can still jump it
some places") — a keyed barrier walkable around — now reproduced by an automated probe at a different
crossing. There is an existing branch `origin/ralph/SOUTH-BRIDGE-FAINTED-PARTY` in this area. Flagged for
the program coordinator to route; it is outside PLACES' file ownership.

Two `NOTE:` lines in the same run, also pre-existing and explicitly owned elsewhere by the test's own
text ("SPINE-LAYOUT owns re-aiming the trail at it"): route `spine` enters the south_bridge gully 8.4 m
off that crossing's road, and `shortcuts:quarry_haul_road` enters it 238.0 m off.

## 7. After frames

`ralph/reports/visual-parity/PLACES/round1/locations/` — captured on the merged tree.

**Read these with one caveat, stated plainly: the before and after frames are NOT resolution-matched.**
Before is 1280x720 at full settle; after is **960x540 with halved settle waits and MSAA/SSAA disabled**,
because the round's time budget required `VP_FAST=1` (`tools/vp_capture.sh`, taken from the program
branch, whose own header says "Use for quick local loops, not for evidence that ships"). Judge the after
frames for *what changed in the world* — Hall stone weathering and moss, cloth banners, the gate arch and
portcullis, ivy density, the third village gate, the village and camp dressing — and **not** for
sharpness, aliasing or fine grain, which the capture mode alone accounts for. A resolution-matched
re-render is the first item of round 2.

Captured (36 frames): all eight sites at every day stand, plus night at `01-village` (6) and
`05-relay-camp` (3). **Missing:** the night pass at `08-ridge-camp` and `10-stronghold` (3 each), and the
`survey`/`ground` sets, contact sheets and **after-perf** — the round hit its hard time budget while the
`locations` stage was still running. The stronghold night frame is the notable gap, because
`stronghold.json`'s new `exterior_conduit_energy` 0.45 exists precisely to fix a night/dusk blow-out.

## 8. Unresolved, and the recommended next step

1. **After-perf was not captured.** Before is `hall_approach` 4331 / `village_high` 4376 draw calls, and
   `hall_approach` already breaches the ≤4000 budget on the baseline. The merged code adds ~30 placed
   village objects plus 11 gate voussoirs, parapet rubble and a smoke column at exactly those stands, so
   the after number could be materially worse and is currently unknown. **This is the single highest
   priority for round 2** — run it before any judging of dressing density.
2. **Re-render before+after matched.** Both at 1280x720 full settle, including the missing night frames.
3. **`smoke_traversal` FAIL at the South Bridge** — pre-existing, outside PLACES ownership (§6). Needs
   routing, possibly to `origin/ralph/SOUTH-BRIDGE-FAINTED-PARTY`.
4. **`survey.gd` FAIL: `05-spawn-low-sun` renders as a flat single colour (spread 0.0000)** — reproduces
   on the unmerged baseline, so pre-existing. Low-sun/sky, VP1 SKY lane, not PLACES.
5. **34 `main` commits are missing from the program branch**, and three of them land squarely in VP5:
   `OWNER-0902-VILLAGE-POPULATION-REGRESSION` ("cut the village's actual headcount"),
   `OWNER-0902-VILLAGE-READABILITY` (Grandpa's-house path clip, Mira's shop sign) and
   `OWNER-0902-VILLAGE-GATE-REGRESSION` (corner-guard height/overlap against jump-escapes). The merged
   vp-village branch independently adds a third gate and re-authors the boundary polygon. **Two efforts
   have been fixing the same owner findings in parallel and they have not been reconciled.** Merging
   `main` is the program coordinator's call and would change what these before-frames mean, so this lane
   did not do it. It should be settled before round 2 dresses anything further.
6. **The stale-bake trap will recur for every lane** (§4). Bake in the environment recipe or gate in CI.
7. **`origin/claude/vp-hall` shipped both new shaders without their `.uid` sidecars.** Every one of the
   eight pre-existing `*.gdshader` files in this repo has a tracked `*.gdshader.uid` beside it, and
   `main` has already had to land one of these separately ("Add missing .uid sidecar for
   smoke_catch_aim_slowdown.gd"). Godot regenerated `hall_stone.gdshader.uid` and
   `banner_cloth.gdshader.uid` on import here and this lane committed them. Without them the UIDs are
   re-minted per checkout, so any future `.tres`/scene reference to these shaders by UID would break.
   Fixed here; worth telling the Hall lane so the next shader it adds ships with its sidecar.

**Recommended next step:** do not add dressing in round 2. Run the resolution-matched re-render and the
after-perf first, reconcile item 5, and judge density from frames that are comparable.
