# G-f40-13-catch-card-medium: F40#13 catch feedback at Medium (GPU), close-out

**Frames:** `tb/gpu-frames-1108` 04d17515d, Medium, arm only.
- Built from `tb/things` 22ff3cd1f with the THINGS-TOYS-UI overlay (catch_card), captured with `phase2_capture_catch.gd --biome=cloudreach`.
- 06-breakout shows the "Pebbik broke free" card. In 07-aiming-weakened that card has cleared, and the team panel, 100% capture chance and throw prompt are showing.
- The High set scored 7.62 in `G-things-toys-ui.md`.

**Render check:** 0 of 2 frames blank, 0 script errors.

**Set:**
- Same layout as High: the two frames side by side at 640×360.
- Same brief and recorded defect as High: "A stale failed-catch message remains along the bottom while the new aim state shows 100% CAPTURE CHANCE and a nearly empty target bar".

**Batch `G-ikm`:**
- Three code-blind judges, standard prompt.
- The set was judged together with the F36#29 Innkeeper baseline.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22.

**Fit:** linear, slope 1.0418, intercept 0.4683, r 0.911, anchor RMSE 0.411.

**Warning:** F40#13 meets the bar only above the top anchor (7.53). The anchors in this batch reach 7.35 or more, so it is the confirming batch.

## Verdict: F40#13 CLOSES at High 7.62 and Medium 7.76, both 7.5 or above

| Preset | Raw a, b, c | Mapped per judge | Mapped mean |
|---|---|---|---|
| High (G-ty) | 7.0, 7.0, 6.6 | — | 7.62 ↑top |
| **Medium (G-ikm)** | 7.0, 6.7, 7.3 | 7.76, 7.45, 8.07 | **7.76** ↑top |

- **Recorded defect:** FIXED 3/3. The "broke free" message and the 100% aim state are never on screen together. None of the judges could read the target bar at tile size, so their FIXED rests on the message alone.
- **Bar B:** yes 3/3. The judges cite the bright Cloudreach sky, the stratified pillars and a believable furred fennec.
- **Remaining notes:**
  - Pebbik's elemental trait barely reads (3/3).
  - Pebbik's values sit close to the cliffs or the grass, with no rim light (2/3).
  - In 07, Pebbik is partly behind the teammate creature (1/3).
  - Judge c rates Pebbik's scale against the trainer as borderline.
  
  None of these is in the F40#13 subject.

**Action:** land the catch_card arm (THINGS-TOYS-UI overlay). It is ready to land as is, without the losing pickup tone-down, per `G-things-toys-ui.md`.
