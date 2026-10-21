# Creatures lane, restart 17 Oct 2026 — work note

Renderer for every capture below: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe software rendering, xvfb, 1280x720. Forward+ Medium/High is not available in this container. Frame times are meaningless here.

## F36#0 priority creatures and NPC faces — BLOCKED in this container (12:30 UTC)

- Bramblebun leaf-mantle v2 (Meshy 01a142e8-f842-73d6-a027-b265f6b2c070), Terrapup multiview (01a142f9-013c-7422-9129-a66f01b6a28c) and Burrowback multiview (01a14306-d610-76e7-a779-dee74fbe6462) GLBs exist only in the Windows checkout's ignored `assets_raw/` (STATE 15 Oct 23:18–23:51). They are not in Git, so they cannot be imported, scale-checked or judged here. Unblock: push the three raw GLBs and their provenance (or rerun the tasks' downloads with MESHY_API_KEY) to tb/creatures.
- Otto v4 (`otto_v4_off.glb`): parked under the stop rule after Turn44 +0.40 and Turn48 +0.43 (F36-0/JUDGE.md). Not re-judged; that would repeat unchanged frames.
- Iona v2: last in-world round +0.17; the judges' biggest losses were the Tidewake post (sand trench, nearby placeholders), not the face. The next step is Water-lane scene work, outside this lane.
- Brooktail F22 hero preview: in-world named-fight mean 6.07 (F22-4 README Turn47), owned by the Fights lane.
- Generations to run when the key exists: none new for these four. Bramblebun/Terrapup/Burrowback need integration and judging of the already generated tasks above. Burrowback multiview needs a scale decision first: a uniform 4.155x fit to 2.95 m implies 7.87 m body depth.

## F36#1 water-mount seat round r1 (12:36–12:47 UTC), candidate presentation, SHA e6f5b960008fba0dec67d1a49191cdf151597cb2

Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=water_mosshell,water_cannonback,water_sirenseal,tuskroot --candidate --whole-body --context --source-commit=e6f5b960008fba0dec67d1a49191cdf151597cb2 --out=<local>`. Exit 0 after 83 s with 100 frames and 4 receipts (local only). Sheet: `_sheet-f36-1-water-mount-seats-r1.png` (cropped rows hit/faint/swim/fly_grip/ride by phase). Seats under test: Mosshell pelvis 2.49 m, Cannonback 4.14 m, Sirenseal (0, 2.05, 0.55), Tuskroot 3.52 m.

Three fresh code-blind judges saw only the sheets, the key art and the Palworld references:

| Subject | Bar A J1/J2/J3 | Bar A mean | Bar B mean | Ride seat credible? |
|---|---|---|---|---|
| water_mosshell | 5.5 / 4.5 / 5.5 | **5.17** | 4.67 | partly: on the dome apex, no straddle |
| water_cannonback | 5.0 / 3.5 / 4.5 | **4.33** | 3.83 | no: sits among the cannon tubes, legs lost |
| water_sirenseal | 5.5 / 4.0 / 5.0 | **4.83** | 4.33 | no: clings to the near-vertical neck/mane |
| tuskroot | 5.5 / 5.0 / 5.0 | **5.17** | 4.50 | marginal: on the crest apex, no straddle |

All four are below 7.5; none is enabled and `enabled_species` is unchanged. The judges agreed on these defects:
- The ride and fly-grip rows are static at every phase.
- The rider is perched on the highest point, with no straddle and no bob.
- Fly-grip lifts the ground pose with no carry contact; the stage leaves the trainer standing.
- Swim keeps the standing legs under the water.
- Cannonback's faint rises into an upright ball or wall.
- Tuskroot's faint rolls onto its back and hides its identity.
- The ruler is hidden behind the body in some hit and swim frames.
- Sirenseal faint is the only PASS (2 of 3) or PASS-.
- Scale passed for every subject.

The seat changes from #690 removed the r4 "sunk into the shell" defect: no judge saw the rider inside the body. The ride is still not credible on Cannonback or Sirenseal.

Next game change (pose/scene data; all three judges rated these fixable):
1. Sirenseal: ride and swim in a horizontal posture, with the seat on the lower back.
2. Cannonback: a sideways faint roll, and a seat cleared behind the cannon cluster.
3. Tuskroot: a side-flop faint with the head visible.

The shared static ride/fly rows and the perched rider are cross-species recipe gaps.

## F29#3 Stormursa (12:48 UTC)

The bear already exists: Meshy 01a1256e-ac9f-77cf-bc43-5628bc37b068 (10 Oct), drafted reference `reference/native-standing-v1.png`, rigged, OFF. Its provenance records 4.10 m standing against Staticub 3.25 m and the trainer 1.80 m. No new reference or generation is needed. The same SHA's local capture of `--species=stormursa,staticub --candidate --whole-body --context` (exit 0, 40 frames) shows the identity kept (chestnut fur, violet lightning). The faint is broken: the rigid 90° pivot tips the bear nose-down onto its head and back (faint 50–100%), unlike Tuskroot, whose same pivot reads as a side roll. The stride deformation, faint and rig gates in provenance stay FAIL. Not judged this block. Next: fix the faint (game-data change), then run a three-judge in-engine round. A pass needs 7.5.

## F25#4 four-creature Medium frame budget — UNRUN

This container has no GPU and no Forward+ Medium (llvmpipe only), so frame times cannot be measured. Not estimated.

## Hourly log

- 12:50 UTC: no game change. Ran the F36#1 water-mount seat proof (4 species, 3 judges): all FAIL the 7.5 bar (means 4.33–5.17). Recorded the F36#0 blocker. Stormursa captured; its faint defect was found. Next: Sirenseal horizontal ride/swim seat, Cannonback and Tuskroot faint, Stormursa faint, recapture, judge.

## F36#1 / F29#3 round r2 (12:44–12:58 UTC): faint and Sirenseal seat treatment, paired against r1

Game changes (all OFF; `enabled_species` unchanged; base Cannonback untouched):
- **Faint, Tuskroot / Stormursa / Water Cannonback.** Each now does a clean side flop about the measured mesh long axis: slack legs, dropped head, no chain lifts. Water Cannonback gets this as its own `presentation_role_overrides` entry. The root cause of the r1 defect was `ground_faint`'s chain lifts: on these weakly weighted rigs they drag the hindquarters up. Stormursa's Meshy mesh also sits 36° off its rig forward line. Authoring lives in `f36_pose_postpass.py` (`LIMP_SPRAWL`, `mesh_long_axis`). The live JSON was patched only for those three faint roles, because a full postpass rerun is stale against the live file and would rewrite unrelated species.
- **Seat, Water Sirenseal.** The seat moved to (0, 1.16, −0.2) m, saddle (0, 0.958182, −0.2) m, on the horizontal lower back measured from the posed mesh. The swimming rider stays about 0.45 m above the sea.
- **Unit checks.** `test_f36_pose_candidates`, `test_rideable_roster` and `test_creature_scale_ladder`: 13 tests, 246 assertions, 0 failed.

Capture: SHA bcdec8bd6f16a5b56b4953a57d14a73aecdf253f, same command as r1 with `--species=water_cannonback,water_sirenseal,tuskroot,stormursa`. It exited 0 with 99 files. Sheet: `_sheet-f36-1-r2.png`.

Judging: r1 and r2 were shown as shuffled A/B pairs (key `r2-ab-key.json`) to three fresh code-blind judges. Each judge saw only the 8 sheets, the key art and the Palworld references. Unmasked Bar A (r1 → r2):

| Subject | J1 | J2 | J3 | Mean r1 → r2 | Gain | Bar B r2 | Preferred |
|---|---|---|---|---|---|---|---|
| water_cannonback | 4.5→5.0 | 4.5→5.0 | 4.5→5.0 | 4.50 → **5.00** | +0.50 | 4.33 | r2 3/3 |
| water_sirenseal | 5.0→5.5 | 4.5→5.0 | 4.5→5.0 | 4.67 → **5.17** | +0.50 | 4.67 | r2 3/3 |
| tuskroot | 5.0→6.0 | 5.0→5.5 | 5.0→5.5 | 5.00 → **5.67** | +0.67 | 5.00 | r2 3/3 |
| stormursa | 4.5→5.5 | 4.5→5.5 | 4.5→5.5 | 4.50 → **5.50** | +1.00 | 4.83 | r2 3/3 |

All four changes are kept: each gained at least 0.5, so the park rule does not apply. None reaches 7.5; nothing is enabled and F36#1 and F29#3 remain OPEN.

- **Faint.** Tuskroot and Stormursa are now rated PASS/WEAK ("clear knocked-out, legs up"). Cannonback is WEAK: it ends balanced on its rim, not lying flat.
- **Sirenseal ride.** All judges now say "closest/lower back"; the rider still sits partly sunk to the hips.
- **Shared ceiling, unchanged on every subject.**
  - Fly-grip FAILs: the creature floats above a standing trainer, and three non-fliers have no reason to be airborne.
  - Swim reads as wading: standing legs under a clear slab, no stroke, and a white band in the water plane.
  - Ride and fly-grip rows are static.
  - The trainer ruler clips into the faint path.

**Owner/coordinator question.** All three judges flagged a design question that blocks a 7.5 verdict on non-fliers: what should fly-grip show for a creature that cannot fly (turtle, boar, bear)? I won't decide that silently; ACCEPTANCE F36#1 says "every species".

## Hourly log

- 12:58 UTC: game changes were the three side-flop faints and the Sirenseal lower-back seat (OFF). Ran the paired r2 proof with 3 judges: gains of +0.50 to +1.00 on all four, best mean 5.67, all below 7.5. Next: swim (a dog-paddle body pitch for the quadrupeds, a horizontal Sirenseal), Cannonback lying flat, the fly-grip question to the coordinator.

## Role applicability (coordinator ruling, 13:00 UTC): judge only the roles a species has in play

| Species | ride | swim | fly-grip | Source |
|---|---|---|---|---|
| water_cannonback, water_sirenseal, water_mosshell | yes | yes | no | `data/config/water_mounts.json` mounts, made rideable and `swim_mount.compatible` by `water_species_catalog.gd`; `water_mounted_swim.gd` sets the swim pose only for `swim_mount.compatible` allies |
| tuskroot | yes | no | no | `species.json` rideable block (`riding_controller.gd` sets ride); no `swim_mount` |
| stormursa | no | no | no | no rideable or `swim_mount` block |
| fly-grip, any of the above | — | — | no | `data/config/fly_traversal.json` carriers are Galecrest (plus Maela's loaner) and the Galewisp target, per SYSTEMS §8 |

Non-applicable roles appear on the judge sheet only as a "not a game state" header line. They are not shown and not scored.

**Re-score of r2 (labelled as a re-score; the r2 raw scores above stand).** Three fresh code-blind judges scored sheets showing only the applicable rows. Bar A:
- water_cannonback: 5.0 / 5.0 / 5.0 = **5.00**
- water_sirenseal: 6.0 / 5.5 / 5.5 = **5.67**
- tuskroot: 6.0 / 5.5 / 6.0 = **5.83**
- stormursa: 5.5 / 5.0 / 5.5 = **5.33**
- water_mosshell (r1 frames): 6.0 / 5.5 / 6.0 = **5.83**

Bar B means: 4.33, 5.33, 5.17, 4.83, 5.17. All remain below 7.5.

Remaining defects the judges named:
- **Swim** reads as wading on the shell bodies, and Sirenseal stays upright. The stage shows no rider in swim. Note the stage itself: its water plane sits deeper than the production sea line, and the slab is translucent.
- **Stormursa's** side flop lifts off its shadow and crumples.
- **Tuskroot's** legs-up flop reads as comic; the judges asked for a side slump.
- **Rider** perched on the apex of the turtles and boar.
- **Hits** are too small on the turtles.

## F36#1 round r3 (13:05–13:35 UTC): Water Sirenseal level swim, Water Cannonback flip trial

Game changes (OFF, Water-only overrides):
- **Water Sirenseal swim (`level_fluke_swim`).** The rear flipper chains that carry its tail get an alternating up-down fluke stroke instead of the generic hind-leg trail that curled the tail out of the water. The body is then pitched level, head forward.
- **Water Cannonback faint.** I tried a full 180° flip onto its back (capture `c9e6891f4`). It ended resting on its cannon spires, and a belly-down fold does not lower this short-legged shell (torso gap 0.065 at rest, 0.075–0.094 folded). Reverted in `2322446b2` to the r2 90° flop; I did not judge the flip.
- Unit check `test_f36_pose_candidates`: 0 failed.

Proof: Water Sirenseal capture at SHA 2322446b24c32611e61aa3ae394cbc7aafc80b47 (exit 0, 26 files), paired against r2 using applicable rows only (key `r3-sirenseal-ab-key.json`, sheet `_sheet-f36-1-r3-sirenseal.png`). Three fresh code-blind judges:

| | J1 | J2 | J3 | Mean |
|---|---|---|---|---|
| Bar A, r2 → r3 | 4.5→5.0 | 4.4→5.0 | 5.6→6.0 | 4.83 → **5.33** (+0.50) |
| Bar B, r2 → r3 | 4.0→4.5 | 4.0→4.5 | 5.0→5.5 | 4.33 → 4.83 |

All three preferred r3, whose swim was the only row they rated as a swim pass. Kept. Still below 7.5.

Remaining fixes the judges named (all pose data):
- **Swim:** sink the body to mid-flank, stroke the hanging pectoral, soften the 75% tail lift.
- **Ride:** the rider wedges in the crook of the upright neck and every frame is the same; lower the neck while mounted and add a bob.
- **Hit:** rears up instead of recoiling.
- **Faint:** the head stays up, it props on a flipper at 50%, and the tail clips the ruler.

The panel spread differs from the applicable-rows re-score (5.67), so the 5.33 here is a same-panel paired number, not a cross-panel comparison.

## Hourly log

- 13:35 UTC: game changes were the Water Sirenseal level fluke swim (kept, +0.50 paired) and the Cannonback 180° flip (tried and reverted, unjudged). Re-scored r2 on applicable rows per the coordinator ruling: best 5.83 (Tuskroot, Mosshell). 0 criteria closed. Next: Stormursa grounded side flop (no hover), Tuskroot side slump instead of legs-up, Sirenseal ride neck lowered, and stronger turtle hits.

## F36#1 round r4 (13:08–13:16 UTC): animated cycles, the clearly different approach

I replaced the single rotated keyframes with staged cycles in `f36_pose_postpass.py`:
- `staged_faint`: knees buckle, the body rolls onto its flank about the mesh's long axis, overshoots and settles, with the head down and no chain lifts.
- `held_hit`: a jolt back and to the side, held, then recovered.
- `ride_bob`: a stride bob with a side-to-side weight shift and a nodding head; Sirenseal also lowers its neck 20° while ridden.

Capture: SHA fc38521cec9ea70c458f94c0b9b80df0f78a4cf9, five subjects, exit 0, 125 files. Each was paired against its previous best, using applicable rows only (key `r4-ab-key.json`). Bar A, three fresh judges:

| Subject | Previous → r4 (J1 / J2 / J3) | Means | Gain | Disposition |
|---|---|---|---|---|
| water_cannonback (hit, faint, ride) | 4.3→4.5 / 5.0→4.5 / 4.3→4.0 | 4.53 → 4.33 | −0.20 | reverted to r2 |
| water_sirenseal (hit, ride) | 5.6→6.0 / 5.0→5.5 / 5.0→4.8 | 5.20 → 5.43 | +0.23 | kept |
| water_mosshell (hit, ride) | 4.8→5.0 / 5.0→5.5 / 4.3→4.5 | 4.70 → 5.00 | +0.30 | kept |
| tuskroot (faint, hit, ride) | 4.9→5.2 / 6.0→5.5 / 4.3→4.1 | 5.07 → 4.93 | −0.13 | reverted to r2 |
| stormursa (faint, hit) | 5.0→5.4 / 5.5→5.5 / 4.8→4.6 | 5.10 → 5.17 | +0.07 | kept |

All gains are under 0.5. This is the first sub-0.5 round after the different approach, so the park rule needs one more. Live state after the reverts:
- Stormursa profile: r4.
- Tuskroot profile: r2.
- Water overrides: Sirenseal r3 swim plus r4 hit and ride; Mosshell r4 hit and ride; Cannonback r2 faint.
- Unit checks: 0 failed. Everything stays OFF.

Remaining defects all three judges named:
- **Faint end poses** still hover, prop or balance, with the shadow detached. The solver measures a grounded torso (gap ≤ 0.06), so the runtime contact seat should be checked against the pose; this is the biggest single gain.
- **Riders** perch on the highest point with no straddle.
- **Swim bodies** float high, with a stiff hanging forelimb.
- **The ruler** sometimes clips the creature or is missing from frames (stage).

## F29#3 Stormursa in-engine judge (13:10 UTC): FAIL

Evidence: the existing committed native frames `assets/creatures/tetherbound/stormursa/review/medium-before-after.jpg`, Windows GTX 1060, Medium, production Stormwood scene and CameraRig, Staticub vs Stormursa, five states. These were never independently judged, and their provenance lists the judge as OPEN. I cropped out all captions and intent text (sheet `_sheet-f29-3-stormwood-medium.jpg`). The frames predate this lane's pose changes. Three code-blind judges:
- **Bar A:** 6.0 / 5.0 / 4.5 = **5.17**.
- **Bar B:** 5.0 / 4.0 / 4.0 = 4.33.
- **Identity:** "same line grown up", partial yes. The bear shape, muzzle, blue eyes and vein layout carry over. Staticub renders pale and translucent, and Stormursa reads as a realistic grizzly with decals.
- **Scale:** larger than Staticub; it reads at or just above the trainer standing behind him (measured 4.10 m vs 3.25 m vs 1.80 m).
- **States:** moving, attacking, hurt and fainted are nearly identical to idle. The fainted state stands with its head down.
- **Scene:** lit brighter than the storm, with no contact shadow.

The other F29#3 conditions are met: drafted reference, Meshy task 01a1256e-ac9f-77cf-bc43-5628bc37b068, provenance, larger than Staticub, taller than the trainer, flag-gated. The in-engine code-blind PASS is not. The criterion stays OPEN and the flag stays OFF.

## Exact art/rig requests (for a Meshy-key session; nothing was generated here)

1. **Stormursa v2, F29#3/F36#0.**
   - *Reference:* draft a new reference from `docs/art/reference/43_Staticub_Board.png` and the current `reference/native-standing-v1.png`: a stylised adult storm bear with a larger head and paws, Staticub's lighter chestnut and tan carried over, and a storm-cloud ruff as the signature feature. The violet and blue lightning veins should continue onto the belly and inner limbs so downed poses keep their identity.
   - *Generation:* Meshy image-to-3D, meshy-6, standard, PBR, 2k, target height 4.10 m (at least 1.3× Staticub's 3.25 m), then a Meshy rigging task.
   - *Acceptance:* the legs and neck must deform when posed. The current rig's leg weights barely move the mesh, and its mesh sits 36° off the rig's forward axis.
2. **Water Cannonback, F36#0/F36#1.**
   - *Generation:* Meshy retexture of `cannonback/models/creature_cannonback_lod0.glb` with clean blue, gold and stone colour blocking instead of the blotchy speckle.
   - *Saddle:* a model revision adding a flat saddle plate behind the cannon cluster at the existing 4.14 m seat line.
3. **Tuskroot, F36#1.** A Meshy retexture of the underside: belly fur and hoof soles; judges called them stretched and unfinished in faint.
4. **Water Mosshell and Tuskroot saddle hollows.** A flattened rear-shell or shoulder seat area so the rider can straddle rather than perch. This needs a model edit; seat offsets alone hit the dome apex.

## Hourly log

- 13:16 UTC:
  - **Game changes:** staged faint, held hit and ride-bob cycles. Kept for Sirenseal, Mosshell and Stormursa; Cannonback and Tuskroot reverted.
  - **Proofs:** F36#1 r4 paired, all under +0.5 (first flat round after the different approach). F29#3 native Medium judge: FAIL at 5.17.
  - **Closed:** 0.
  - **Next:** one more F36#1 round on grounded faint end poses and lower straddle seats. If it gains under 0.5, park F36#1 at its best scores (Tuskroot and Mosshell 5.83 re-score, Sirenseal 5.43 paired). Then F29#3 waits on the Stormursa v2 generation, and F25#4 is unrun (no GPU).

## F36#1 round r5 (13:20–13:40 UTC): grounded faint end pose — final round; F36#1 PARKED

**Runtime contact check.** I read `creature_pose_candidates.gd:197-215` and `_posed_minimum_y`. They ground each grounded-role frame on the lowest skinned vertex, and the r4 frames show that vertex on the floor. The runtime seat is not the cause, so there is no game-code change. The "hover" was pose geometry: the downed body was propped on its lower legs (solver torso gap 0.041–0.051 of height), and the stage light throws the shadow to one side.

**Change.** `staged_faint` now tucks the legs fore and aft along the belly and draws them toward the midline (tuck 30°, adduct −25°). Solver torso gap: Stormursa 0.007, Tuskroot 0.0; stretch within the limit. Capture at SHA f490caf18978e119e220c334ddefe823b5f8f37d, exit 0, 47 files.

**Paired Bar A, three fresh judges** (key `r5-ab-key.json`):

| Subject | Previous → r5 (J1 / J2 / J3) | Means | Gain | Disposition |
|---|---|---|---|---|
| stormursa (hit, faint) | 5.5→6.0 / 4.5→5.0 / 4.0→4.3 | 4.67 → 5.10 | +0.43 | kept |
| tuskroot (hit, faint, ride) | 5.5→5.0 / 4.5→5.0 / 4.5→3.8 | 4.83 → 4.60 | −0.23 | reverted to r2 |

**Park decision.** This is the second consecutive round under +0.5 after the clearly different approach (r4 staged cycles, r5 grounding), so F36#1 is parked per the coordinator stop rule. No species is enabled; `enabled_species` is unchanged. Best Bar A by item (panel noted):

| Item | Best Bar A | Panel |
|---|---|---|
| tuskroot | 5.83 | applicable-rows re-score, r2 pose, live |
| water_mosshell | 5.83 | re-score of the r1 pose; the live r4 hit and ride gained +0.30 on its own panel |
| water_sirenseal | 5.67 | re-score of r2; the live r3 swim and r4 hit/ride each gained on their paired panels (best paired 5.43) |
| stormursa | 5.33 | re-score r2; live r5 5.10 on its paired panel |
| water_cannonback | 5.00 | re-score, live |

Every live pose is the best-judged treatment of its role.

**Why pose data stalls (judges, r4/r5).**
- Extreme poses on these Meshy rigs deform: Stormursa's shoulder and hip bulges and a chest tear in the faint; Tuskroot's hip smear when it is balled up.
- Downed undersides lose identity (no lightning veins, stretched belly fur).
- Riders perch on dome and crest apexes because the meshes have no saddle surface.
- The stage has a translucent water slab and no contact shadow.

The art and rig requests listed under round r4 are the route past 5–6.

## Final status (13:40 UTC)

- **Criteria closed:** 0.
- **F36#0:** BLOCKED. The Bramblebun, Terrapup and Burrowback 15 Oct GLBs never reached Git; they need the Meshy key or an owner push. The coordinator is arranging the key and concept-art turnarounds.
- **F36#1:** PARKED at the best scores above. Every candidate stays OFF.
- **F29#3:** OPEN. Native Medium judge FAIL at 5.17; it waits on the Stormursa v2 generation and re-rig.
- **F25#4:** UNRUN. It needs a real GPU and the Medium preset; this container is llvmpipe only, so nothing was estimated.
