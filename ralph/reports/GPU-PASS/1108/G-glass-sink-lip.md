# G-glass-sink-lip: Glass Sink lip ring (F41#10) — VOID

> **VOID (coordinator, 10 Nov).** The GPU lane reports that no lip-ring slab appears in any of the three frames: 18 slabs about 87 m apart, and all three stands fall between them. Identical raw scores were therefore expected and say nothing about the asset. The result below is kept only as a record and is **not** a verdict on the lip ring. The build lane is making the ring continuous, to be requeued as `glass-sink-lip-dense`.
>
> The 0.3–4.7% pixel difference was this tell; I should have stopped there. In future I will check the GPU lane's capture note and any "don't judge yet" flag before judging.

Frames: `tb/gpu-frames-1108` 14585eb1, High. Live is main 52a633598. The arm is live plus the blender-1109 assets, the same three scripts and two config files at cdb3cbe1b, plus `ITEM-SINK-LIP/overlay_lip_ring.json` (`lip_ring_1109` on).

**Pixel check before judging:** the arm changes very little on screen.

| Frame | Pixels differing by more than 30 levels |
|---|---|
| day approach | 0.3% |
| day close | 3.3% |
| golden approach | 4.7% |

Batch `G-lip`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22.
- Fit: linear, slope 1.0031, intercept 0.8495, r 0.760, **anchor RMSE 0.75**.
- Calibrate warning: "anchor residual RMSE 0.75 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat". The verdict below does not depend on the mapping, because the raw scores are identical.

| Row | Live | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|
| F41#10 | 6.13 (raw 5.4, 5.2, 5.2) | 6.13 (raw 5.4, 5.2, 5.2) | **0.00** | 0/3 (3 ties) | **no** |

**The judges saw no difference.** All three said the two sides "look identical" in all three cameras. The lip ring does not register at these stands.

The recorded defect ("an abrupt unmarked terrain edge over a uniform checker-textured void") is PARTIAL on both sides (3/3):
- **Gone:** there is no checker void any more. The drop reads as a dark pool or water.
- **Still there:**
  - The mossy grass ends in a hard, straight, unmarked line into the dark plane, with no shoreline, rocks or transition. The close camera shows it worst.
  - The basin sits raised on the lip, so it reads as a crystal planter or crown, not a sunken hollow.
  - The glass shards are evenly spaced and all one height, which reads as generated (judge a).
  - Thick white rain streaks cross the subject.

**What the judges ask for (3/3):** sink the basin into the terrain as a real depression. That means:
- a sloped shoreline with rocks, moss and crystal talus where the hard edge is now;
- a reflective black pool;
- varied shard heights and clusters.

Two judges class this as scene work, one as new art. A ring at the current lip does not reach it from these camera stands.

~~Verdict: flat, so do not ship. This parks the lip-ring idea for F41#10.~~ Withdrawn: VOID, see the top of this file. The arm was not in frame.

## Recurring (both sides, 3/3)
The Stormwood fight anchor shows the same faults as before:
- murky values;
- flat magenta telegraphs;
- the player's creature lost;
- canopy blocking on its live side.

The Meadows aftermath and craft anchors are consistent with earlier batches.
