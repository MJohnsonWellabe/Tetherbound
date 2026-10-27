# b46: Brooktail and Thundertunnel grown vs main (CPU, three judges)

Candidate: 9bc8004f. Brooktail 2.1 -> 2.55 m, Thundertunnel 2.8 -> 3.3 m, with radius at the same ratio (D12). Grow only. Stage: `capture_f36_poses.gd --whole-body --context`, roles hit and faint; tiles are standing, hit-050, faint-050, faint-100. Receipts confirm the heights (2.55 / 3.3 vs 2.1 / 2.8). Sheet `_sheet_b46.jpg`: base | grown (top Thundertunnel, bottom Brooktail).

Anchors: f36_0_npc:C4, f04_6_r22, f36_0_gap:C3. Fit: offset method (least-squares slope 0.42 outside 0.5-2.0), r 0.34, RMSE 0.53. **Not a confirming batch**; compare sides within a set only.

| subject | base (mapped) | grown (mapped) | "stands about trainer height" (base / grown) |
|---|---|---|---|
| Thundertunnel | 6.40 | 6.40 | PARTIAL, PRESENT, PRESENT on both |
| Brooktail | 6.20 | 6.20 | PRESENT, PRESENT, PARTIAL on both |

Call: no gain. Every judge gave each side the same score and called the two sides "near-identical". Reverted. The whole-body stage camera pulls back in proportion to the creature (radius from the resting box), so the creature fills the same frame and only the 1.80 m ruler shrinks. A 20% growth then reads as no change, and the judges still read both at about trainer height. Scale has to be judged at the play camera (fight, field) or with a fixed-distance stage, not this one.

Other reads (both sides): Brooktail's dark eye patches read as sunglasses (3/3) and its faint end reads as sitting (3/3). Thundertunnel's eyes are not visible and its hit/faint-mid barely differ from standing (3/3).
