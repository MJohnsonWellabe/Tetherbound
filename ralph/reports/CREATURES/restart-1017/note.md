# Creatures lane, restart 17 Oct 2026 — work note

Renderer for every capture below: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe software rendering, xvfb, 1280x720. Forward+ Medium/High is not available in this container. Frame times are meaningless here.

## F36#0 priority creatures and NPC faces — BLOCKED in this container (12:30 CT)

- Bramblebun leaf-mantle v2 (Meshy 01a142e8-f842-73d6-a027-b265f6b2c070), Terrapup multiview (01a142f9-013c-7422-9129-a66f01b6a28c) and Burrowback multiview (01a14306-d610-76e7-a779-dee74fbe6462) GLBs exist only in the Windows checkout's ignored `assets_raw/` (STATE 15 Oct 23:18–23:51). They are not in Git, so they cannot be imported, scale-checked or judged here. Unblock: push the three raw GLBs and their provenance (or rerun the tasks' downloads with MESHY_API_KEY) to tb/creatures.
- Otto v4 (`otto_v4_off.glb`): parked under the stop rule after Turn44 +0.40 and Turn48 +0.43 (F36-0/JUDGE.md). Not re-judged; that would repeat unchanged frames.
- Iona v2: last in-world round +0.17; the judges' biggest losses were the Tidewake post (sand trench, nearby placeholders), not the face. The next step is Water-lane scene work, outside this lane.
- Brooktail F22 hero preview: in-world named-fight mean 6.07 (F22-4 README Turn47), owned by the Fights lane.
- Generations to run when the key exists: none new for these four. Bramblebun/Terrapup/Burrowback need integration and judging of the already generated tasks above. Burrowback multiview needs a scale decision first: a uniform 4.155x fit to 2.95 m implies 7.87 m body depth.

## F36#1 water-mount seat round r1 (12:36–12:47 CT), candidate presentation, SHA e6f5b960008fba0dec67d1a49191cdf151597cb2

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

## F29#3 Stormursa (12:48 CT)

The bear already exists: Meshy 01a1256e-ac9f-77cf-bc43-5628bc37b068 (10 Oct), drafted reference `reference/native-standing-v1.png`, rigged, OFF. Its provenance records 4.10 m standing against Staticub 3.25 m and the trainer 1.80 m. No new reference or generation is needed. The same SHA's local capture of `--species=stormursa,staticub --candidate --whole-body --context` (exit 0, 40 frames) shows the identity kept (chestnut fur, violet lightning). The faint is broken: the rigid 90° pivot tips the bear nose-down onto its head and back (faint 50–100%), unlike Tuskroot, whose same pivot reads as a side roll. The stride deformation, faint and rig gates in provenance stay FAIL. Not judged this block. Next: fix the faint (game-data change), then run a three-judge in-engine round. A pass needs 7.5.

## F25#4 four-creature Medium frame budget — UNRUN

This container has no GPU and no Forward+ Medium (llvmpipe only), so frame times cannot be measured. Not estimated.

## Hourly log

- 12:50 CT: no game change. Ran the F36#1 water-mount seat proof (4 species, 3 judges): all FAIL the 7.5 bar (means 4.33–5.17). Recorded the F36#0 blocker. Stormursa captured; its faint defect was found. Next: Sirenseal horizontal ride/swim seat, Cannonback and Tuskroot faint, Stormursa faint, recapture, judge.
