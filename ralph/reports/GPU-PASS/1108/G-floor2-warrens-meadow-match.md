# G-floor2-warrens-meadow-match: meadow grass on the Warrens mound's up-facing faces (F38#30, F38#24; GPU High)

Frames: `tb/gpu-frames-1108` aba474097, High, seed 2042, `tb/floor2` b8e9112a6.
- Capture: `phase2_capture_routes.gd --biome=meadows`, Burrow Warrens walk_02_day, walk_03_day and route_day.
- base = tree as is.
- arm = base + `FLOOR2-WARRENS/overlay_meadow_match.json` (`burrow_warrens.json` bank.hill_shell.meadow_match): the meadow grass sheet and nature-pack tufts on the up-facing hill faces, with a 1.5 m mouth pad. The cave mouth and its earth rim are unchanged.
- The wild creatures in walk_03 differ from spawning, not the overlay.

Sets, with the same briefs and recorded defects as `G-newapproach-warrens-flank-stand.md`:
- **F38#30**, Burrow Warrens hillside: walk_02, walk_03 and route_day, stacked at full size.
- **F38#24**, distant mountains: walk_03 alone.

Render check: walk_02 10.4%, walk_03 12.4%, route_day 9.8% of pixels changed. Blank frames: 0 of 3 per side.

Batch `G-wm`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.3918, intercept −1.6795, r 0.942, anchor RMSE 0.466. No warnings.

## Verdict: SHIP. F38#30 +0.79 at 3/3; F38#24 unchanged (no loss)

| Row | Base | Arm | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| **F38#30** Burrow Warrens hillside | 5.23 | **6.02** | **+0.79** | **3/3** | 5.38 |
| F38#24 distant mountains (walk_03) | 5.88 | 5.88 | 0.00 | 1 prefers arm, 1 prefers base, 1 tie (each by 0.1) | — |

Raw Bar A, base → arm (judges a, b, c):
- F38#30: 5.0, 5.0, 4.9 → 5.4, 5.6, 5.6.
- F38#24: 5.6, 5.3, 5.4 → 5.5, 5.3, 5.5.

Recorded defects:
- **F38#30:** base PRESENT 3/3; arm PARTIAL 3/3.
- **F38#24:** PARTIAL 3/3 on both sides. The judges see the same blue cone range on both.

**F38#30 rises above 6 (6.02).** That takes it off the below-6 list.

**F38#24 walk_03 is a no-loss check.** The mountains are unchanged by this overlay, as expected. Its level here (5.88) matches the walk_03 stand result in `G-newapproach-warrens-flank-stand.md` within scatter.

## What the judges see on F38#30
- **What the arm fixes:**
  - in views 1 and 2 "a mottled grass texture breaks up the banding ... most of the bare brown is gone" (3/3);
  - on base, view 1 has "a broad, smooth brown terrain band with a dark cut along its lower edge", and view 2 is "a flat, untextured green wedge with a hard, straight diagonal lower edge".
- **What remains on the arm (3/3):**
  - **View 2:** the straight diagonal hill-base edge remains, and the grass texture is stretched or blurry on the steep face.
  - **View 3 (route_day), both sides:** a brown rectangular slab still shows on the left hill. Judge c also sees the hard brown face beside the entrance.
  - **View 1 (judge a):** a brown wedge and dark cut are still visible top right and top left.
  - **Red bushes, flagged by all three:** bright red shrubs near the Burrow entrance in view 3 sit close to the oxblood reserved for Team Tether. The GPU lane's note confirms "red entrance trees still red". This is an owner-rule flag for the row owner.
  - **Smoke:** judge b sees a plain white smoke column as a placeholder.

## What would add the most
1. **Hill bases and slabs (scene):** blend the hill bases into the ground with scattered rock and grass edges, and remove the remaining brown slab faces and straight diagonal cuts around the Burrow, including the route_day left-hill slab.
2. **Red bushes:** recolour the entrance shrubs off the reserved red.
3. **F38#24 (new_art):** a layered, snow-capped range with atmospheric fade to replace the cone backdrop (3/3).
