# GPU baselines for the six unscored visual rows (owner floor rule)

Request: the coordinator, 10 Nov. Baseline every visual row that has no score of its own, using existing frames on `tb/gpu-frames-1108` where possible.

| Row | Existing frames? | Result |
|---|---|---|
| F39#32 Tidewake cleanliness | Yes (8 Nov per-item `live/High`) | **6.77 provisional** |
| F40#21 Cloudreach cleanliness | Yes (8 Nov per-item `live/High`) | **7.03 provisional** |
| F41#24 Stormwood cleanliness | Already has one | 6.30 (G-trunk-dither-narrow); not re-judged |
| F22#4 named fights | Partly (no Stormwood finale frame) | **7.20 visual baseline only**; the criterion is C2/C3 |
| F38#0 Meadows re-capture (≥200 frames) | No: 86 unique Meadows frames, item-targeted | Needs capture |
| F40#0 Cloudreach re-capture (≥200 frames) | No: 39 unique frames | Needs capture |
| F41#22 Stormwood frame matrix | No matrix capture on the branch | Needs capture (High and Medium) |

## Scored now: batch `G-base6`
Method:
- One-sided sets: each side is the same 2×2 sheet. Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.
- Fit: linear, slope 1.1831, intercept −0.6096, r 0.884, anchor RMSE 0.647. No warnings. above_top_anchor false throughout.
- Frames: the 8 Nov per-item GPU `live/High` captures, picked evenly across each biome's unique frame list (`yardstick_g_base6/base6_frames.json`).
- Recorded defect: "Flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the frame".

These are **provisional baselines**:
- The rows are defined "in the matrix", and these frames are a catalogue sample, not the matrix.
- They show the 8 Nov tree, so fixes landed since are not reflected.

### F39#32 Tidewake cleanliness: **6.77** (sheet 1: 6.69, sheet 2: 6.84)
Raw Bar A (judges a, b, c): sheet 1 6.2, 6.3, 6.0; sheet 2 6.2, 6.3, 6.4. Defect: PRESENT ×4, PARTIAL ×2.

What the judges named (all three unless stated):
- a black wedge or void at the top right of the Cannonback dune fight (`tidewake__fight__venn__t-016_00`), read as a rendering bug;
- Resident Nalia rendering semi-transparent or dithered behind the dialogue box (`water_nalia__dialogue`);
- the blue creature floating above the sand with no grounding shadow (`aquaryn__fainted`);
- a flat white foam or wake slab and a straight seam on the water (`swimming__surface_mid`);
- smooth, untextured dunes with evenly scattered tufts;
- one judge: a dune overhang behind Nalia, and the camera clipping the trainer's head.

### F40#21 Cloudreach cleanliness: **7.03** (sheet 1: 7.00, sheet 2: 7.06)
Raw Bar A (judges a, b, c): sheet 1 6.5, 6.6, 6.2; sheet 2 6.3, 6.6, 6.6. Defect: PRESENT ×2, PARTIAL ×4.

What the judges named:
- a glowing, dotted orange-gold smear on the path under the trainer, reading as an emissive placeholder decal (`summit_eyrie__day__close`, 3/3);
- the griffin clipping into the rock column, and oversized orange mushrooms that read as placeholder props (`flying__high-perches`, 2/3);
- a flat orange disc on the plateau top (1/3);
- the flat, untextured stronghold yard (`captain_veyra__defeated`);
- flat-shaded cliff slabs.

**Close-out exception.** At 7.03, F40#21 is a near-bar item under the close-out exception. The emissive path decal and the mushroom/griffin clipping are its cheapest wins.

### F22#4 named fights (visual): **7.20** (6.96, 7.44, 7.20)
Frames: Warden Aldis (`warden_aldis-05`), Nerissa (`nerissa__t-000_00`), Veyra (`veyra_live__live-3510`), Venn (`venn__t-016_00`). Raw Bar A: 6.4, 6.8, 6.6.
- **What carries it:** each fight reads as a distinct event, and the torch-lit Warden hall is the strongest frame.
- **What holds it back:**
  - the same black wedge in the Venn dune fight;
  - attacks shown as generic dust rings with no impact object;
  - Veyra's flat beige arena disc;
  - one judge: Burrowback reads as a copy of Terrapup (same brown armoured dog), so the boss identity is weak.
- **Scope gap:** F22#4 itself is "distinct pattern and C2/C3 on the new timings", which is a pilot measurement, not a picture. This score covers only the look. There is no Stormwood finale (Marrow/Dynamo) fight frame on the branch, and `capture_named_fights_f10_6.gd` explicitly excludes Marrow.
- **Warden banner:** one judge flagged the red target-emblem banner in the Warden hall as possible oxblood on a non-Tether faction. Worth a look.

## Needs a fresh GPU capture (tool and frame list)
Per the runbook GPU form: `--rendering-method forward_plus --resolution 1920x1080 --preset=<High|Medium>`, on main's head, both presets.

1. **F38#0 Meadows re-capture.**
   - Tool: `tools/capture_f38_matrix.gd`, plan `ralph/reports/R2-F38/capture-definition.json`: 22 sites × 4 views × 3 times × 2 weather = 528 frames per preset.
   - Command: `-- --seed=2042 --f38-preset=<High|Medium> --f38-baseline --output=res://<fresh dir>`, no `--subset`.
   - About 264 frames on High alone (day and dusk, clear) clears the ≥200 floor if time is short.
2. **F40#0 Cloudreach re-capture.**
   - Tool: `tools/capture_cloudreach_f40_matrix.gd`: 12 stands × 4 views × 4 times × 2 weather = 384 frames per preset, in `--piece=1..96`.
   - The tool's header says F40#0 needs the complete union on both presets. Add `--ground-cover-cache` to reuse the buffers between pieces.
3. **F41#22 Stormwood frame matrix.**
   - Tool: `tools/capture_stormwood_f10_matrix.gd` with the F41-look set: stands forest, giant, glass, rod_line and stormheart, plus the three `--custom` stands and the reframed forest_r and giant_r.
   - Phases `calm,break`, plus the Long Storm aftermath (no `--no-aftermath`), High and Medium.
   - The matrix also asks for a real fight: add `capture_named_fights_f10_6.gd --fixed-fps 20` (Hollows Alpha) for the fight row.
   - Grep each log for `stale` (stale Stormwood scatter).
   - The tool refuses CPU and a dirty tree.
4. **F22#4 Stormwood finale.**
   - No capture tool covers the Marrow/Dynamo fight. `capture_named_fights_f10_6.gd` excludes it, and `capture_stormwood_lane_evidence.gd` only plays his release conversation.
   - The finale needs either a tool or `art_pipeline/capture_named_fight.gd --trainer=<marrow id>` if Stormwood trainers resolve there (unverified).

Once the captures land, the matrix frames can rescore F39#32, F40#21 and F41#24 in their proper scope.
