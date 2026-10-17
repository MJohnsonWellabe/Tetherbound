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
