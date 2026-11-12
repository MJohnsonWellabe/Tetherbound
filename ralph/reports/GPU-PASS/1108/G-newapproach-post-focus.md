# G-newapproach-post-focus: play camera eases in at a named post (F40#9; GPU High)

Frames: `tb/gpu-frames-1108` f0bcfe69b, High, seed 2042, `tb/newapproach` 09fc4e0ba.
- Capture: `phase2_capture_characters.gd --biome=cloudreach`, subsets keeper_maela, naturalist_sora and young_trainer_tavi.
- base = `camera.json` post_focus off (spring length 5.2 m).
- arm = base + `NEWAPPROACH-POSTFOCUS/overlay_post_focus.json`: at a named post with its prompt up, the camera eases to 3.6 m and the pivot moves 0.9 m toward the post.
- GPU lane pre-check: spring length 3.6 on all three arm frames, 5.2 on all three base frames.

Sheet: Maela, Sora and Tavi, stacked at full size, on F40#9's brief and recorded defect ("named Cloudreach NPCs look small or partly hidden behind the foreground trainer and nearby buildings ...").

Render check (pixels changed, as expected for a camera move): Maela 51%, Sora 29%, Tavi 28%. Blank frames: 0 of 3 per side.

Batch `G-pf`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.4225, intercept −2.1395, r 0.927, anchor RMSE 0.519. No warnings.

## Verdict: SHIP. +0.71, 3/3 prefer

| Row | Base | Arm | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| F40#9 named NPC post readability | 5.02 | **5.73** | **+0.71** | **3/3** | 5.72 |

Raw Bar A, base → arm (judges a, b, c): 5.0, 5.1, 5.0 → 5.6, 5.6, 5.4.

Recorded defect: base PRESENT 3/3; arm PARTIAL for judges a and b, PRESENT for judge c.

The base here maps 5.02, against the board's 5.72; that gap is scale scatter between batches. Read the paired gain. The row stays below 6; this arm is the floor-raising step.

## What the judges say about the closer camera
- **NPCs are larger:** each NPC reads larger beside the trainer.
  - Judge a: "the closer framing gives a little more pose and costume detail in row 1" (Maela).
  - Judge b: on the base, the camera sits further back, so the NPC is "about half the size and harder to read".
  - Judge c: the base NPC is "smaller still".
- **The trainer, larger and lower in frame:** no judge raised it as a defect. The judges describe the arm's NPC as "beside the trainer", not hidden behind him.
- **Sora's frame, the foreground ledge:** no judge names a foreground ledge. All three describe Sora as "half hidden behind the stone wall corner" on both sides, worse on base.
  - Judge c notes "the cobbled wall slab ends in a hard cut edge" on base.
  - The camera move does not clear the wall occlusion. Sora's post needs a re-stage.
- **Tavi:** on the arm, partly behind or beside the trainer. On base, "tiny at mid distance".

## What still keeps F40#9 low (both sides, 3/3)
- **Plinths:** NPCs stand on bare grey stone discs that "read like a placeholder plinth" or "display stand", not a post.
- **NPC proportions:** small, near-chibi figurines with little pose or role prop.
- **Lighting and dressing:** flat lighting with weak grounding shadows; a flat orange path and red-brown trunks crowd the frame.

## What would add the most (all scene)
1. **Posts:** replace the grey plinths with authored posts (stall, workbench, perch), with a role prop and pose for each NPC (3/3).
2. **Sora:** move her clear of the wall corner.
3. **Lighting:** a key light and grounding shadow at each post.
