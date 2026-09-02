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

---

# Round 2

**Branch** `claude/vp-places` · run against the program branch merged forward (main's 58 commits).

## R2.0 The merge — nothing to reconcile, and why

`git merge origin/claude/coordination-subagents-3fhz1x` brought 71 commits and merged **clean, zero
conflicts**. The instruction was to resolve conflicts in my owned files by keeping both the owner fix and
the lane dressing. **No such conflict arose**, and the reason is worth stating rather than glossing:

| owner fix | files it actually touched |
|---|---|
| `OWNER-0902-VILLAGE-POPULATION-REGRESSION` | `data/config/village_npcs.json` |
| `OWNER-0902-VILLAGE-READABILITY` | `data/config/terrain_playground.json`, `scripts/world/shop_interior.gd` |
| `OWNER-0902-VILLAGE-GATE-REGRESSION` | corner-guard work, not `village_boundary.json`'s gate list |

The vp-village dressing edits `village.json` and `village_boundary.json`. The population fix edits
`village_npcs.json`. **They are disjoint files**, so both survive intact — the headcount cut and the
dressing coexist with no merge decision required. `git diff --name-only HEAD@{1}..HEAD` over all my owned
files returns empty.

One merge mechanic did bite: the merge **aborted** first time, because my locally re-baked
`data/scatter/**` (held under `skip-worktree`) collided with incoming bake changes. Resolved by clearing
`skip-worktree`, `git checkout -- data/scatter`, merging, then re-baking and re-guarding.

**And the stale bake recurred exactly as round 1 predicted.** The incoming merge moved
`terrain_playground.json` again (`19b3b543`, the readability fix), so the fingerprint went stale and the
re-bake cost `825587 placements … in 266517 ms` — another 266 s per world stand-up. This is the second
occurrence in two rounds. Round 1's item 6 recommendation stands and is now evidenced twice.

## R2.1 Fixes, in the coordinator's priority order

### 1. Hall exterior at distance (VP8) — the judged diagnosis was wrong

The fix list said "the weathered `hall_stone` shader is not reaching the exterior kit pieces / towers /
curtain walls." **It already was.** A headless probe instantiating the real `meadows_hall` prefab
confirmed `_weather_hall_massing()` (`scripts/world/stronghold.gd`) already converts 32 of the kit's 45
surfaces — towers, gatehouse flankers, spire, roof — to `HALL_STONE_SHADER` via `_stone_variant()`.

The **actual** cause: every exterior stone surface used the *same weathering intensity as the five lit
interior rooms*, applied over the kit's own retinted tint (`LightRock` ≈ `#817f78`, a mid-value grey-tan)
with no darkening bias. Shared joint-moss at interior strength over a mid-grey tint cannot read as a dark
ruined mass at 400 m no matter how it is tuned.

Fix: a new `exterior` flag threaded `_material()` → `_stone_shader_material()` → `_stone_variant()`, set
true at every genuinely outward-facing call site (outer walls, coping/merlons/buttresses, gate
jamb/lintel/voussoirs/keystone, skirt + grounding buttress, massing foot shafts, window slits, causeway
banner and brazier piers, and the kit conversion itself). Interior chamber walls, floors, ceilings,
timber, iron and all `_tether_material()`/`_live_material()` emissive pieces are untouched.

New `site.weathering.exterior` block in `stronghold.json` — `darken` 0.24, `desaturate` 0.32,
`macro_strength` 0.24→0.34, `moss_amount` 0.46→0.62, `up_moss` 0.55→0.72, `damp_height` **3.0→6.6**
(sized for a 15–38 m tower's lower third rather than a 6–22 m room wall), `damp_strength` 0.26→0.40,
`streak_strength` 0.20→0.30, `moss_colour` `#243a10`. The base block and all five interior chambers are
byte-identical.

**Draw calls: zero new mesh instances.** Every change is a material swap on an existing `MeshInstance3D`
or a parameter change on an already-shared cached `ShaderMaterial`. The `_materials` cache key gained the
`exterior` flag so outer and inner variants of one base colour are two shared instances rather than
colliding — same batching discipline, one more axis.

Parapet broken-top variation (asked for in the fix list) **already existed** — `_dress_exterior_wall()`
per-merlon width/height/seating jitter, 5.5 %/13 % broken-stub rolls, and `parapet_breach_chance` 0.75
driving `_parapet_rubble_heap()`. Verified by reading it; left alone rather than duplicated.

### 2. Broken stands (tool only) — `tools/_capture_locations.gd`

- **`04-warrens-den`**: `back` 3.2→1.5, `up` 1.70→2.2, `look_up` 1.6→1.15, now aimed at the guardian's own
  scaled half-height rather than a human chest-height default. Keeps the camera within 1.5 m of room
  centre, clear of interior rock at any RNG seed.
- **`06-relay-approach`**: root cause found in config — `tether_relay.json`'s `site._ground` only documents
  probed ground from `s=-24` to `s=+20`, but the eye sat at `s=-46` and the default `back` 7.0 walked it to
  `s=-53`, 29 m into unprobed terrain. Now `at [-20,0]` with `back` 4.0, landing on `s=-24`, the site's own
  outermost sampled point.
- **`11-castle-landmark`**: the old landmark was merged into the Hall, so all three stands pointed at empty
  hills. Re-aimed off the Hall's own markers (`site.at [8,7560]`; `entrance` == `ramp_foot` at world
  z 7506.8) at 400/200/100 m along the causeway. **The three shots are RENAMED**
  `approach`/`gate`/`banners` → **`hall-400m`/`hall-200m`/`hall-100m`**, so those filenames do not line up
  with round 1's. The site id `11-castle-landmark` is unchanged.

### 3. Relay occupation (VP7, first pass) — 14 new objects

3 Team Tether grunts on site (1 added; `assets/characters/grunt/grunt_lod0.glb`, authorised by
`docs/art/HUMANOID_ASSET_INVENTORY.md` line 31 — no new humanoid); a 4-piece tool cluster on the deck at
absolute `deck_y` 10.0 (ground-sampled props here would fall 2–8 m through the slab); a 3-piece
deliberately asymmetric barrier with a 3.4 m walkable gap; a scorch ring on the pad; one oxblood banner
following `band3` order 3000's established grammar.

Plus a genuine code fix found while doing it: the three cable runs **stopped 7–8 m short of the
apparatus**. Each now gets a final sagged span from that run's real last-pylon attach point to a point
derived from real config (`grounding_base.radius` 3.4 out from `apparatus.at`, at half `apparatus.height`
above `deck_y`), sharing the cached lit-conduit material by identity so `_kill_the_conduits()` still
switches them off.

### 4. Warrens exterior (VP6) — 12 new objects, interior untouched

Root cause of "flat grey rock pile": `_place_rock()` and `_build_site_skirt()` both called
`_wear_the_cave_stone()` with one fixed tint, and `_material()` caches by resulting colour — so **every**
mound and skirt boulder shared one literal material. New `mound.tint_variation` 0.16 plus a `_varied_tint()`
helper give a quantised 5-value spread. The approach apron now fans (`apron_mouth_width_m` 8.0 at the door,
`apron_far_width_m` 4.6 six metres out, the old fixed value) with the grass-clear radius scaled to match.
12 objects: 3 darkened jamb/brow rocks framing the mouth as a dark focal point, 8 fern/scrub in two
flanking clusters, 1 worn threshold pebble.

**Interior untouched**, and the argument is structural, not a promise: every edit lives in
`_build_approach_apron()`, `_build_mound()`, `_build_site_skirt()` and a new additive
`_build_entrance_dressing()`. None of `_build_chambers`, `_build_passages`, `_build_interior_rock`,
`_build_structure`, `_build_den_atmosphere` or `_build_prize` is touched, and `_place_rock()`'s new
`variation` parameter defaults to 0.0 with no interior caller passing it.

### 5. Well pad (VP5)

Second pass, because the frame said the first was not enough. `MI_RockTrim` `#a39d8e`→`#7f7366`,
`MI_Brick` `#b9b1a2`→`#8f8375`, and **`MI_UnevenBrick` `#7f766c` added** — the apron/flagstone material had
**no retint at all** before, which is why the pad still read as a clean disc after the curb was darkened.
Roughness was ruled out by probing the glTF directly: `roughnessFactor` is absent, so it already imports
fully matte and low roughness was not the cause.

## R2.2 Perf — the draw-call constraint held, and improved

`--views=hall_approach,village_high --settle=120 --resettle=60 --sample=20`, fixed 1280x720 both runs.

| view | before (round 1, `00-before`) | after (round 2) | delta |
|---|---|---|---|
| `hall_approach` | 4331 draw calls · 13,212,179 prims · 4676 obj | **4227** · 4,718,096 · 4572 | **−104 draw calls**, −64 % primitives |
| `village_high` | 4376 draw calls · 18,087,761 prims · 4474 obj | 4440 · 9,430,618 · 4534 | +64 draw calls, −48 % primitives |

**The constraint was "stay ≤ 4000; the 4331 baseline is inherited; do not add draw calls net."** At
`hall_approach` the count went *down* 104 despite all the Hall exterior work — consistent with that work
being pure material swaps with zero new mesh instances, plus the extended material cache still sharing
instances. `village_high` rose 64, which is the ~30 village objects the vp-village dressing added.

**Two honest caveats.** First, `hall_approach` is still **4227 against a 4000 ceiling** — the inherited
breach is NOT resolved, only slightly reduced, and it remains a real open failure against
`docs/PERFORMANCE_BUDGET.md`. Second, the before number was measured **before** the program-branch merge,
so the large primitive drops are not attributable to this lane alone; main's own grass/scatter and LOD
work landed in between. The draw-call comparison is the meaningful one for judging this lane's changes;
the primitive comparison is mostly other people's work.

## R2.3 Tests

Re-run on the fully combined tree (all five fixes together), not just per-agent:

| test | exit | result |
|---|---|---|
| `smoke_stronghold` | 0 | PASS |
| `smoke_relay` | 0 | PASS |
| `smoke_warrens` | 0 | PASS |
| `smoke_traversal` | 1 | FAIL — pre-existing South Bridge, verbatim below |

```
traversal FAIL: crossed the South Bridge without the key (6348.4m past the gap) — the gate can be walked around
```

Unchanged from round 1, in files neither this lane nor the merge touches. Reported, not fixed, per the
fix list's own instruction.

Nothing the round-2 dressing placed blocks anything: `smoke_relay` still fights the captain and rescues
the captive (`[relay_site] placed 4 of 4`, Gear granted) with the new barrier, banner and deck cluster in
place; `smoke_warrens` still walks entrance→branch (52 m), guardian fight, vault door and reward with the
12 new entrance pieces in place.

## R2.4 Frames

`ralph/reports/visual-parity/PLACES/round2/locations/` — 27 frames, `VP_FAST` 960x540. The `locations`
stage took **423 s** against round 1's 3093 s: the fast path plus a fresh bake.

Every frame carries real content (per-channel stddev across the frame; round 1's broken stands read ~0):

- `04-warrens-den-day` **31.78** (was solid green) — fixed
- `06-relay-approach-day` **50.39** (was solid green) — fixed
- `11-castle-landmark-hall-400m/200m/100m-day` **49.76 / 46.90 / 49.41** — re-aimed at the Hall, all render
- all `01-village`, `10-stronghold` day frames 54–65; night frames 26–37

## R2.5 Two findings outside PLACES that the coordinator should see

**1. The grass carpet is enabled but draws nothing.** `tools/_capture_ground_and_sky.gd` exited 1 with
this, repeated for every band and every clock:

```
FAIL: ground-00-village-day: the GrassField exists but holds no instances -- nothing to draw
```

`data/config/grass_field.json` has `enabled` = **true**, set by a direct owner directive recorded in the
file itself (`_comment_enabled_ownerplaytest_20260902b`: "grass needs to be on"). So this is not the flag
being off — it is the flag being on and the field producing **zero instances**. That means the owner's
decision is currently not reaching the renderer, and **every frame in this round was captured with no
grass**. That matters for judging: "a flat grey rock pile on lawn" is a lawn made of baked scatter, not
the intended grass carpet. GROUND lane owns these files; PLACES did not touch them.

**2. `tools/survey.gd` now exits 0.** Round 1's `05-spawn-low-sun` flat-frame failure is gone, fixed by
something in the merged program branch. Closing that round-1 item.

Also flagged from the frames, not fixed: `10-stronghold-courtyard-night` is nearly black (mean RGB
1.0/2.4/5.2, stddev 10.73) where every other night frame sits at 26–37. May be correct for an unlit
courtyard, may be a defect — a judge should rule.

## R2.6 Unresolved

1. `hall_approach` still **4227 vs the 4000 ceiling**. Not resolved, only reduced.
2. Grass draws zero instances despite being enabled by owner directive (R2.5) — highest-value cross-lane bug.
3. `smoke_traversal` South Bridge walk-around, pre-existing, needs routing.
4. The stale-bake trap fired a **second time** this round. Two rounds, two occurrences, ~270 s each per
   stand-up. It needs to be in the environment recipe or gated in CI.
5. Before/after still not resolution-matched (1280x720 vs `VP_FAST` 960x540). Judge for content, not sharpness.
6. `tools/_judge_capture_hall.gd` was not run in either round — the time budget went to the locations set
   both times. The Hall's golden/night gate-face read is therefore still unjudged, which is exactly the
   frame `exterior_conduit_energy` 0.45 exists to fix.

---

# Round 2 addendum — the "frames are identical" finding is not reproducible

The program coordinator relayed a code-blind judge finding: *"every round-1 after-frame pixel-identical
in content to its before-frame, so the merged dressing never reached the round-1 render — most likely the
capture ran from the pre-merge tree, or the capture tool's world does not instantiate the changed config."*

Checked against the artefacts. **The premise does not hold**, and the merged dressing did reach the render.

## (a) The render tree included both merges

| event | time (UTC) |
|---|---|
| merge `origin/claude/vp-village` (`908d703d`) | 03:44:40 |
| merge `origin/claude/vp-hall` (`57a8e3a9`) | 03:44:41 |
| `godot --headless --path . --import` (picks up the two new shaders) | 03:44:56 |
| round-1 `locations` capture starts (`round1/capture.log` line 1) | **03:45:03** |

The capture began 22 s after the merges and after a re-import, from the same working tree. `vp_capture.sh`
reads config from the working tree, and the JSON config is read at run time, not from the `.import` cache.

## (b) The frames are not identical, by md5 or by content

`01-village-route-out-day`: `00-before` is **1280x720** md5 `12c27e85…`; `round1` is **960x540** md5
`3d80c3b7…`; `round2` is 960x540 md5 `031684a4…`. Three distinct images, and the before/after pair are not
even the same dimensions — a pixel comparison between them is not defined.

Comparing content properly (before downscaled to 960x540, mean absolute per-pixel difference, and the
share of pixels differing by more than 8/255):

| frame | mean abs diff | % pixels > 8 |
|---|---|---|
| `01-village-tournament-day` | 33.32 | 84.4 % |
| `10-stronghold-courtyard-day` | 22.87 | 84.6 % |
| `10-stronghold-gate-day` | 22.32 | 64.2 % |
| `01-village-standing-day` | 17.38 | 57.8 % |
| `01-village-route-out-day` | 16.16 | 46.9 % |
| `04-warrens-approach-day` | 15.47 | 56.2 % |

**Likely cause of the false finding:** the before/after resolution mismatch this report flagged in §7
(1280x720 full-settle vs `VP_FAST` 960x540, no MSAA/SSAA). A viewer that letterboxes or rescales one to
the other's frame can make two genuinely different images read as the same picture. The mismatch was
forced by the round-1 time budget and remains item 5 of the round-1 unresolved list; this is the second
concrete cost it has caused.

## (c) The config-not-instantiated hypothesis is independently refuted

- Round 2's Hall work began with a headless probe that instantiated the real `meadows_hall` prefab and
  found `HALL_STONE_SHADER` **already applied to 32 of the kit's 45 surfaces** via
  `_weather_hall_massing()`. The config reaches the world builder.
- `round1` and `round2` frames differ at **identical** capture settings (both `VP_FAST` 960x540) —
  e.g. `01-village-route-out-day` `3d80c3b7…` vs `031684a4…`, which is the well retint landing.

**Conclusion: no re-render of round 1 is warranted on this finding, and no cache/stale-import defect
exists to fix.** What is warranted is closing the resolution mismatch so the judge is never handed a
mismatched pair again.

## Addendum fixes — evidence

`ralph/reports/visual-parity/PLACES/round2b/locations/`, `VP_FAST` 960x540, same settings as round 2 so
these ARE directly comparable to `round2/`.

| frame | round2 mean | round2b mean | delta | |
|---|---|---|---|---|
| `01-village-grandpa-yard-night` | 24.27 | 27.10 | **+2.83** | warm light at Grandpa's door |
| `01-village-route-out-day` | 105.43 | 119.79 | **+14.36** | stand re-aimed at TrailGate |
| `01-village-route-out-night` | 18.45 | 22.24 | +3.79 | same re-aim, night |
| `01-village-standing-day` | 138.00 | 138.52 | +0.52 | **control — stand unchanged** |

The control matters: an unchanged stand moved 0.52 while the Grandpa's-yard night frame moved 2.83
(a ~12 % lift on a dark frame). So the night change is a genuine local practical light, not a global
exposure or tone shift — which is the failure mode "just brighten the night" would have produced.

---

# Round 3

Merged `origin/claude/coordination-subagents-3fhz1x` (WORLD's canopy fix) clean, zero conflicts. It did
touch `tools/_capture_locations.gd`, which this lane also owns — git merged it without conflict and the
round-2 stand fixes (`hall-400m/200m/100m`, the re-aimed `route-out`) were verified present afterwards.
Re-baked the scatter (272.8 s, third occurrence). **The re-bake produced byte-identical output to round
2's** (825587 placements, 29819789 bytes), so WORLD's canopy fix is a material change, not a placement
change — a re-bake was not actually required this round.

## R3.1 Both headline fixes were the same class of bug: a value silently cancelled

Two rounds of "apply the weathered shader" and "add tint variation" did nothing visible. In both cases
the mechanism was already wired correctly and a number was being neutralised downstream.

### Hall exterior (item 1) — the routing was never broken

A headless diagnostic walked the live `Stronghold` subtree and dumped every `MeshInstance3D`'s material
class. **Every stone and roof surface in the render already carried the `hall_stone` ShaderMaterial with
`exterior:true`.** The only raw `StandardMaterial3D` nodes (`LightRock.001` `#817f78`, `DarkRock`
`#68675f`, `Celing.001`, `MI_RoundTiles`) sit under `HallPrefabTemplates`, an invisible template holder
that never renders. So round 2's conclusion was right and the fix list's premise ("only the courtyard
interior got the shader") was wrong.

Printing the shader's own resolved `tint` found the real defect: `darken` 0.24 against `#817f78` only
reaches ≈(0.38, 0.38, 0.36) — **brighter than `site.stone_light` (`#66655e`), the ordinary lit-interior
wall tone.** The weathering was landing *above* the interior tone instead of below it, so the exterior
could never read as a dark ruin however much moss was added.

| key | old | new |
|---|---|---|
| `weathering.exterior.darken` | 0.24 | **0.56** |
| `desaturate` | 0.32 | 0.50 |
| `moss_amount` | 0.62 | 0.78 |
| `up_moss` | 0.72 | 0.85 |
| `damp_height` | 6.6 | 8.5 |
| `damp_strength` | 0.40 | 0.50 |
| `streak_strength` | 0.30 | 0.38 |
| `moss_colour` | `#243a10` | `#1f3510` |

Final kit tint ≈(0.21, 0.21, 0.20), now darker than the skirt tier. Added `HALL_PIECE_VARIATION` 0.14, a
deterministic per-piece tint bias seeded off `hash(name + index)` so towers differ from one another and
the result is stable between captures; interior callers pass 0.0 and are numerically unchanged.

### Warrens exterior (item 2) — variation was being 65 % eaten

`mound.tint_variation` was applied to the raw tint **before** `_wear_the_cave_stone()`'s 35 % lerp toward
rock colour, so only 35 % of it survived: a configured 0.16 became **≈0.056 effective**. That is why the
judge saw uniform grey. Restructured so variation applies to the final lerped colour.

`tint` `#c3bbab`→`#9c8a72` (warmer, ~20 % darker); `tint_variation` 0.16→**0.42** (now fully effective);
new `apron_colour` `#2b2118`; exterior floor lerp-to-white 0.12→0.05; skirt boulders now sink by their own
scale (`skirt_sink_min_m` 0.18, `skirt_sink_m` 0.6) instead of a flat 0.08, with a dark soil collar
(`soil_collar_scale` 1.6) auto-applied to ~63 ground-contact boulders via a procedural
`_boulder_soil_collar()` reusing the existing `_box()` primitive. Entrance jambs sink 0.3→0.5 / 0.25→0.45
and the dark clamp widens [0.22, 0.55]→[0.32, 0.78] because the old ceiling was already saturating.
**No new hand-placed props** (still the 12 from round 2).

## R3.2 What the frames measure

`round3/locations/`, `VP_FAST` 960x540 — same settings as round 2, so directly comparable.

| frame | r2 mean | r3 mean | reading |
|---|---|---|---|
| `10-stronghold-gate-day` | 125.01 | **114.30** | −10.7, Hall darker |
| `10-stronghold-approach-day` | 113.86 | **99.03** | −14.8, Hall darker |
| `04-warrens-approach-day` | 118.90 | **112.25** | −6.6, mound darker/warmer |
| `10-stronghold-courtyard-night` | 2.87 | 2.84 | **unchanged** |
| `10-stronghold-gate-night` | 23.80 | 23.55 | **unchanged** |

Items 1 and 2 landed and are measurable. The Hall now reads as a dark weathered mass with legible towers
and crenellations at 200 m and 400 m, against green canopies (WORLD's fix arrived with the merge).

## R3.3 Two things that did NOT land — stated plainly

**Item 6, night lighting: FAILED.** The light retune (gate fires y 4.5→6.2, range 16→24, energy 2.6→3.3,
new `attenuation` 1.3, the dead 0.35-energy courtyard ambient raised to a 1.7 warm fill, sky fills
2.2/2.4→2.8/3.0, all within the existing 18/18 omni budget) produced **no measurable change in the
frames**: courtyard-night 2.87→2.84, gate-night 23.80→23.55. `smoke_stronghold` still logs "18 exterior
omni light(s) at the Hall (budget 18)", so the lights exist — they are simply not reaching these two
camera stands. The courtyard at night remains crushed to black (mean 2.84). Needs a different diagnosis
in round 4: probably the stand's own framing or a light-range/occlusion problem, not more energy.

**Item 5, boiler smoke: REGRESSED, then removed.** The retune (alpha 0→0 at both ends, amount 48→30,
spread 9°→20°, drift 0.35→0.6, peak scale 4.2→3.0) fixed the hard edge but the *widening* backfired
badly at distance: in the 200 m and 400 m frames it became an enormous grey smog wall spanning the entire
frame behind the Hall, swamping the sky and the silhouette the same round was trying to establish. Taking
the reviewer's own stated fallback ("or remove it"), the smoke was put behind a config flag
(`site.boiler_smoke_enabled`, default **false**), with the retuned code retained for a later attempt.

**Then the re-render disproved the diagnosis.** With the flag verified false and `_smoke_column()`
returning early, the grey band is **still there, unchanged**: the horizon band's mean moved 140.22 →
139.68, a delta of **−0.54**, and the whole frame 117.54 → 117.05. So the mass in the 200 m/400 m frames
**is not the boiler smoke** — neither the judge's attribution nor mine was right. It spans the entire
frame width, far wider than any chimney plume, and carries vertical drip streaks, which reads more like
precipitation, distance fog, or a horizon cloud layer than a point-source column. `_capture_locations.gd`
does contain weather-pinning code and warns "no WorldWeather; weather cannot be pinned to clear", so a
weather volume that is not actually being pinned clear is the first thing round 4 should check. That is
SKY/WORLD territory, not VP8.

The smoke flag is left **off** regardless: the retuned column was a regression on its own merits, and
leaving it disabled removes one variable from the next diagnosis.

## R3.4 Perf — the budget is met for the first time

| view | round 2 | round 3 | delta |
|---|---|---|---|
| `hall_approach` | 4227 · 4,718,096 prims | **3791** · 4,355,544 | **−436 draw calls — under the 4000 ceiling** |
| `village_high` | 4440 · 9,430,618 prims | **3122** · 8,579,260 | −1318 |

`docs/PERFORMANCE_BUDGET.md`'s ≤ 4000 at `hall_approach` is **satisfied**, after being breached at 4331
(round-1 baseline) and 4227 (round 2). Attribution caveat: this lane's round-3 work is net-zero mesh
instances (+1 cable anchor plate, −1 removed courtyard floor conduit), so the −436 is largely the
program-branch merge's own LOD/canopy work rather than PLACES. The lane's contribution is that it did not
spend the headroom.

## R3.5 Tests

`smoke_stronghold` exit 0 (logs "18 exterior omni light(s) at the Hall (budget 18)"), `smoke_warrens`
exit 0, `smoke_relay` exit 0 (`[relay_site] placed 5 of 5`). `tools/_capture_locations.gd` parses.
`_capture_ground_and_sky.gd` still exits 1 on the grass-field-holds-no-instances failure reported in
R2.5 — unchanged, still GROUND's.

## R3.6 Relay addendum (items 3, 4)

Cables now land on built sockets — a stone bracket pulled 0.18 m into the surface plus a teal cap
cylinder (r 0.09, h 0.3) sharing the run's material *by identity* so `_kill_the_conduits()` still kills
it. `sag_scale` moved from a hardcoded 0.6 to a configured **3.0**, taking a 4–6 m span from ~0.15–0.2 m
droop (visually straight) to ~0.75–0.9 m. New `conduits.cable_radius` 0.03 (was the shared
`CONDUIT_RADIUS` 0.055) and `cable_emission_energy` 0.4 (was 0.8), applied **per-instance** because
`severed_spokes.gd` is outside this lane and caches that material by identity shared with the quarry and
the spokes — editing it there would have dimmed unrelated sites.

Staffing: a console guard and a platform hand on the deck (new `_build_deck_people()`, since ground-placed
NPCs cannot reach the deck's absolute Y) and a ground patrol inside the `standing` stand's view cone.
9 new objects, deliberately under the 10–16 suggested because the site already carries a crate cluster,
barrier and banner from round 2.

The `06-relay-apparatus` stand pointed almost dead at the sun — confirmed numerically from `art.json`
(sun pitch −44, yaw 140 → horizontal direction (0.643, −0.766); old view direction (−0.095, −0.995), dot
**0.996**). Moved `at` [1,−4] → [14,−4], new view direction (−0.939, 0.343), dot −0.867, ~150° off with
the sun behind camera. **The reported "trainer clipped onto a roof" was not a real placement bug** — the
shot's own ground sweep already read flat real terrain (4.9–5.8 m) everywhere except the look point; it
was the old stand's extreme low, close, steeply-upward composition against the apparatus's overhang. No
authored position was changed.

## R3.7 Unresolved after round 3

1. **Night at the Hall (item 6) failed** — courtyard-night still mean 2.84. Needs a different diagnosis,
   not more light energy.
2. **The horizon grey band is unidentified** — not the boiler smoke (disproved above). Check weather
   pinning first.
3. Grass field enabled but draws zero instances (R2.5) — still open, GROUND's.
4. `smoke_traversal` South Bridge walk-around — still open, outside PLACES.
5. `_judge_capture_hall.gd` has still never been run in any round — the Hall's golden/night gate-face
   read remains unjudged.
6. Contact sheets were not built this round (the capture's later stages were cut for time).

---

# Round 4

Merged `origin/claude/coordination-subagents-3fhz1x` clean, zero conflicts; it touched none of this
lane's owned files and none of the scatter-fingerprint config, so no re-bake was owed on that account.
A re-bake was run anyway, because round 3's cleanup restored the working tree to the *committed* bake
(the local one is deliberately never committed), which is stale against current config.

## R4.0 The "not reaching that stand" premise — measured, and false

The fix list opens: *"the judge measured `04-warrens-approach-day` as pixel-comparable to round 2 — your
tint/variation change is not reaching that stand. Prove change with a pixel-diff count before anything
else."* Done, first thing. Round 2 vs round 3, same `VP_FAST` 960x540 settings both sides:

| frame | mean abs diff | px differing >2 | >8 | >24 | byte-identical? |
|---|---|---|---|---|---|
| `04-warrens-approach-day` | **19.92** | 82.1 % | 56.1 % | 33.4 % | no |
| `04-warrens-standing-day` | 17.45 | 72.5 % | 35.9 % | 25.5 % | no |
| `04-warrens-den-day` | 5.80 | 41.8 % | 14.3 % | 12.0 % | no |

A third of the approach frame's pixels moved by more than 24/255. **The change reaches the stand.** The
plumbing is not the problem and round 4 did not spend time re-proving it.

What *is* true is that the art-direction goal is still unmet — "reads as a flat grey pile" can be
perfectly accurate about a frame that has nonetheless changed a great deal. So the deeper work in item 1
(lower-half staining, suppressed carpet on the apron, a wider darker mouth) was done on its merits. The
correction matters only so the next round does not go hunting for a plumbing bug that does not exist.

This is the **second** judge finding of the form "your change did not land" that measurement has
contradicted (the first was round 1's "every after-frame is pixel-identical", refuted in the round-2
addendum). Both times the frames had in fact changed substantially. Recommend the judging step compare
frames of identical dimensions and report a diff statistic alongside the verdict, so a perceptual
judgement ("it still reads flat") is not relayed as a mechanical one ("the change is not reaching the
render") — they call for completely different fixes.

## R4.1 The grey band, finally identified — and it was never the Hall's

Three rounds have now chased this. Round 3 disproved the boiler-smoke theory by disabling the smoke and
measuring a −0.54 change. This round found the actual source by searching outward from the Hall:

**`StormWall`, built by `scripts/world/rift_collapse.gd` from `data/config/rift_collapse.json`'s
`storm_wall` block** — three alpha-blended `QuadMesh` slabs, 520–620 m wide and 150–225 m tall, standing
262–356 m out. That is why it spans the entire frame behind the Hall regardless of what the Hall does,
and why two rounds of Hall-side fixes could never touch it.

**Scope deviation, declared:** `rift_collapse.*` belongs to **no lane** in
`docs/VISUAL_PARITY_LANES.md`'s ownership table. It was edited here only because the round-4 fix list
explicitly assigns this band to PLACES. The change is deliberately conservative — values and falloff
only; slab count, size and position untouched:

| what | old | new |
|---|---|---|
| slab colours | `#39404f` / `#2b3140` / `#454d5d` | `#2e333f` / `#222733` / `#373e4a` |
| `_slab_mask()` top falloff | `smoothstep(top−0.005, top+0.042)` | `smoothstep(top−0.02, top+0.09)` |

The top now dissolves over ~11 % of slab height instead of ~4.7 %; that 4.7 % edge is what read as a flat
plate. In the round-4 400 m frame the top edge does graduate into the sky rather than terminating in a
line. **It is improved, not solved** — the band still spans the frame and still limits how much the Hall
separates at 400 m. If the next round wants it gone from these shots, the honest options are moving the
slabs, shrinking them, or excluding them from this sightline — all structural, and all needing whoever
owns `rift_collapse` to sign off.

## R4.2 Frames — every change measured against round 3

`round4/locations/`, `VP_FAST` 960x540, identical settings to round 3.

| frame | r3 mean | r4 mean | mean abs diff | px >8 |
|---|---|---|---|---|
| `04-warrens-approach-day` | 112.25 | **103.29** | 9.58 | 13.0 % |
| `04-warrens-standing-day` | 57.92 | **38.31** | 22.29 | 48.3 % |
| `04-warrens-den-day` | 73.23 | 73.27 | 0.68 | 1.8 % |
| `10-stronghold-courtyard-night` | 2.83 | **3.58** | 0.78 | 6.4 % |
| `10-stronghold-gate-night` | 23.52 | 23.18 | 3.74 | 15.7 % |
| `10-stronghold-gate-day` | 113.88 | 113.78 | 7.00 | 23.8 % |
| `11-castle-landmark-hall-400m-day` | 118.55 | 118.99 | 4.23 | 16.0 % |
| `11-castle-landmark-hall-200m-day` | 117.05 | 117.24 | 4.07 | 15.4 % |

**Den frame stability:** the fix list required the den frame stay pixel-stable. It is *nearly* so — mean
abs diff 0.68, 1.8 % of pixels over 8 — but it is **not** byte-identical. The residue is the new boulder
stain reaching entrance-jamb rocks that are partly visible from the den stand. No interior geometry,
chamber, structure member, guardian or prize changed; the movement is material-only on exterior boulders
seen through the mouth. Reported rather than glossed, since "pixel-stable" was the stated bar.

## R4.3 Courtyard night — improved, not fixed

Round 3's retune produced no measurable change (2.87 → 2.84) because the exterior omni budget was full at
18/18 and had nowhere to go. This round raised `EXTERIOR_OMNI_BUDGET` 18 → **22** deliberately and added
4 real corner braziers through the same `_brazier()`/`_build_hall_fire()` path every existing fire uses
(energy 2.2, range 13, attenuation 1.4), clear of the fight floor. All non-shadowed —
`_build_hall_fire()` sets `shadow_enabled = false` unconditionally, so
`docs/PERFORMANCE_BUDGET.md`'s outdoor shadow-casting cap is still 0. Final: **22 exterior omnis,
10 flickering fires**, confirmed by the smoke test's own log line.

Result: 2.83 → 3.58 mean. In the frame the two oxblood banners and their sigils now read clearly, along
with the scaffold, barrels and warm light points — where round 3 was effectively black. **But the frame
is still very dark overall and faces are not lit.** If the bar is "faces read", this is not there yet and
a further pass is owed.

## R4.4 Perf — still inside budget

| view | round 3 | round 4 |
|---|---|---|
| `hall_approach` | 3791 | **3843** (+52) |
| `village_high` | 3122 | 3122 |

The +52 is the round's +7 mesh instances (3 skyline retrofit props, 4 brazier baskets). **`hall_approach`
remains under the 4000 ceiling**, with 157 calls of headroom.

## R4.5 Tests

`smoke_stronghold` exit 0 (logs 22/22 lights, 10 flickering fires); `smoke_warrens` exit 0 (walk-in
16.0 m, full 52 m route, guardian and reward unchanged). Nothing added blocks the mouth, approach or a
spawn.

## R4.6 A deliberate non-change needing owner sign-off

The fix list asked for "a wider, darker entrance opening" at the Warrens. The darker half was done. The
**wider** half was not, deliberately: `passages[0].width` is the literal mouth-to-hall opening, and that
number cuts the wall opening shared by the mouth chamber's *interior* wall and the exterior facade.
Widening it would change interior architecture the owner has judged good and explicitly ruled untouchable.
The visual frame around the doorway was widened instead (jamb offsets ±2.5→±3.1, scales 1.7/1.8→2.0/2.1,
brow y 3.1→2.8 / z −1.2→−1.6 / scale 2.2→2.6, flora +0.6 m out and ~30–35 % larger, darken clamp
[0.32,0.78]→[0.40,0.86]). Widening the actual doorway is available but needs a conscious decision,
because it also changes the mouth→hall corridor.

## R4.7 Unresolved after round 4

1. **Courtyard night still dark** (mean 3.58); banners read, faces do not.
2. **Storm band improved but still dominant** at 400 m; removing it from that sightline is structural and
   needs the `rift_collapse` owner.
3. **The scatter fingerprint over-triggers.** The bake output has been byte-identical for three
   consecutive rounds (825587 placements, 29819789 bytes) while the fingerprint kept going stale off
   `terrain_playground.json` edits that change no placement — ~270 s wasted per lane per occurrence.
   Narrowing the fingerprint to the keys that actually affect scatter would pay for itself immediately.
4. Grass field enabled but drawing zero instances — still open, GROUND's.
5. `smoke_traversal` South Bridge walk-around — still open, outside PLACES.
6. `_judge_capture_hall.gd` has still never produced frames. An orphaned round-1 subagent attempted it
   three times this session and failed each time, and its own diagnosis is worth keeping: it was racing
   concurrent edits to `scripts/world/stronghold.gd` on the same checkout. Any future attempt must run
   when the tree is quiescent.
7. Contact sheets not built (time budget).

---

# Round 5

Merged the program branch clean (zero conflicts). Re-baked — and this time the bake genuinely differed
(826135 placements / 29838724 bytes vs the 825587 / 29819789 that had been byte-identical for three
rounds), so the fingerprint was legitimately stale on this merge. The over-trigger note in R4.7 still
stands for the three rounds where it was not.

Judged `JUDGE-round4.md` in full before dispatching. Frames at **native exposure only**.

## R5.1 A round-4 regression of mine, found by the judge and fixed

The judge caught something worth recording as a mistake rather than a finding: round 4's Warrens recolour
*introduced* a new defect — "within a single frame the 'earthwork' exterior rock (warm brown/green) now
visibly disagrees in material and colour temperature with the 'cave' interior rock (cool grey) a few
metres away."

Cause: the exterior base was `_rock().lerp(mound.tint, 0.35)` with `mound.tint` `#9c8a72`, a warm tan
chosen for its own sake and **never checked against the interior**. The interior wall base is `site.rock`
(`#5b5147`) with no pull toward anything. Fix: `mound.tint` → `#5b5147`, which makes the lerp a no-op, so
the exterior boulder base now *equals* the interior base exactly and the stain shader's earth (`#2b2118`)
and moss (`#3a4a20`) overlays do 100 % of the excavated read instead of fighting a warm base tint.

## R5.2 Warrens reshaped, not recoloured

| key | old | new |
|---|---|---|
| perimeter + roof boulders | 223 | **89** |
| `perimeter_spacing_m` / `roof_spacing_m` | 3.0 / 4.5 | 5.4 / 6.5 |
| `perimeter_courses` | 3 | 2 |
| `perimeter_scale` / `roof_scale` | [2.2, 3.6] / [1.6, 2.8] | [2.6, 5.8] / [2.0, 4.2] |
| `perimeter_base_drop_m` / `sink_m` | 1.6 / 1.2 | 2.4 / 2.0 |
| `skirt_count` | 260 | 210 |

Fewer, larger, more varied, deeper buried. New `mound.spoil_mounds` + `_build_spoil_mounds()`: 3
asymmetric heaps reusing installed `Rock_Medium_*` meshes squashed on Y and worn with the **same
triplanar earth material the trodden ramp already uses**, so they read as dug spoil rather than more
boulders. No new mesh assets. Mouth: jambs sunk 0.5→0.75 / 0.45→0.7 and enlarged 2.0→2.3 / 2.1→2.4;
brow lowered 2.8→2.6, pushed 1.6→1.85 over the opening, enlarged 2.6→2.9.

**Net object count −178.**

## R5.3 Storm slabs lifted clear of the Hall

`storm_wall.slabs[*].base` **−46.0 → 55.0** on all three. The Hall skyline was derived at ~37 m worst
case (floor ~6 m above meadow + `legendary_chamber` height 22 + up to 9 m sited relief, because
`_base_height` samples 63–74 m away), cross-checked against the 400 m stand's own `up` 28 / `look_up` 14.
55 m clears that by 18 m — about 3–4° of sky at the 262–356 m slab distances, deliberately modest so the
band does not float free of the horizon. Round 4's darkened palette and softened top falloff kept.

**Trade-off, recorded in-file:** at the storm road's own close seam a sliver of clear ground now shows
below the band where it previously ran to the horizon. Accepted under this round's explicit authorisation.

## R5.4 Courtyard night and gate occupation

Braziers at the authorised ×3 / ×1.5: energy 2.2→**6.6**, range 13.0→**19.5**. Dropped the two flank
sky-fills (energy 3.0, range 60) — never named in any judge finding, so the least valuable spend — to free
budget. Added a practical torch at (−7.0, 36.0), 3 m off the courtyard trainer's stand at local (−4, 36)
and outside the arena's x[−5, 5], so faces have a light. **21 omnis against budget 22, 11 flickering
fires, all `shadow_enabled = false`** (the outdoor shadow-casting cap is still 0).

Gate: `_build_gate_tower_sconces()` adds 2 emissive-only plaques (zero omni cost) off measured
`LargeSquareTowerBricks` bounds; `_build_gate_sentries()` adds 2 grunts through the same `CHARACTER_MODEL`
path `trainer_npc.gd` uses — idle, no `trainers.json` row, no combat. `BANNER_COLOUR` `#6b2a20` →
**`#5a1a1a`**, the authorised oxblood family.

**Smoke left disabled.** Two blind tuning attempts have already regressed (a flat band, then a
horizon-spanning smog wall) and no render was available mid-edit to verify a third. A missing wisp beats a
third smog wall.

## R5.5 Frames — r4 → r5, native exposure, same VP_FAST settings

| frame | r4 mean | r5 mean | mean abs diff | px >8 |
|---|---|---|---|---|
| `10-stronghold-approach-night` | 22.48 | **34.86** | 13.24 | 67.0 % |
| `10-stronghold-gate-night` | 23.18 | **33.43** | 12.63 | 64.4 % |
| `11-castle-landmark-hall-100m-day` | 92.41 | 94.86 | 16.10 | 45.0 % |
| `10-stronghold-courtyard-night` | 3.58 | **8.38** | 4.88 | 25.1 % |
| `04-warrens-standing-day` | 38.31 | 27.40 | 15.30 | 33.4 % |
| `10-stronghold-gate-day` | 113.78 | 109.44 | 9.67 | 29.4 % |
| `04-warrens-approach-day` | 103.29 | 99.29 | 9.18 | 25.1 % |
| `11-castle-landmark-hall-200m-day` | 117.24 | 116.70 | 8.65 | 28.7 % |
| `10-stronghold-approach-day` | 98.72 | 97.99 | 8.00 | 27.5 % |
| `10-stronghold-courtyard-day` | 37.40 | 35.30 | 6.77 | 28.5 % |
| `11-castle-landmark-hall-400m-day` | 118.99 | 118.33 | 6.25 | 24.5 % |
| `04-warrens-den-day` | 73.27 | 75.01 | 2.13 | 4.6 % |

Contact sheet: `round5/_sheet_locations.png`.

## R5.6 Perf and tests

`hall_approach` **3848** (r4 3843, +5 for the 4 gate-face pieces) — **still under the 4000 ceiling**,
152 calls of headroom. `village_high` 3162. `smoke_stronghold` exit 0, `smoke_warrens` exit 0.

## R5.7 What still fails, stated plainly

1. **The courtyard-night numeric target was missed.** The brief set "mean ≥ 12"; the frame is **8.38**.
   It is a 134 % improvement over round 4's 3.58 and the qualitative goal is largely met at native
   exposure — banners and sigils, ground, scaffold, barrels, a lit brazier and the grunt sentry all read
   without any exposure boost — but 8.38 is not 12 and is reported as a miss, not rounded up.
2. **The den frame drifted further from pixel-stable**: 1.8 % of pixels over 8 in round 4, **4.6 % now**.
   The reshape's larger near-mouth boulders are visible through the doorway from the den stand. No
   interior geometry, chamber, structure member, guardian or prize changed — `_build_chambers`,
   `_build_passages`, `_build_interior_rock`, `_structure_*`, `_dress_the_guardian` and `_build_prize`
   are untouched — but "pixel-stable" was the stated bar and this does not meet it. If the bar is strict,
   the fix is raising `skip_front_m` so the enlarged boulders start further from the mouth.
3. **200 m and 400 m remain weak.** The band lift is decisive at 100 m, where the Hall now silhouettes
   against clean sky. At 200 m and 400 m the Hall is still small and low-contrast against a bright
   horizon (means barely moved: 117.24→116.70, 118.99→118.33). The band is no longer the cause; the
   remaining problem is the Hall's own angular size and its aerial fade converging with the sky.
4. `10-stronghold-approach-night` and `gate-night` improved a lot in mean (+55 %, +44 %) but were not
   inspected frame-by-frame this round for whether detail actually reads.
5. Carried forward, all outside PLACES: grass field enabled but drawing zero instances;
   `smoke_traversal`'s South Bridge walk-around; `_judge_capture_hall.gd` has still never produced frames.
