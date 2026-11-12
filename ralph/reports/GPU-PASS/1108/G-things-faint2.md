# G-things-faint2: LANE-THINGS faint round 2, per-species crumple (GPU High)

## Setup

**Frames:** `tb/gpu-frames-1108` e6dadc433, High. Both sides on `tb/things` d2581fb0e, captured with:
```
capture_f36_poses.gd --whole-body --context --clear-ruler --roles=hit,faint
```
- **base:** overlay off.
- **arm:** `THINGS-FAINT2/overlay_faint_round2.json`, which applies `things_faint2_scope` and the per-species crumple rows.
- **Species (13):** water_mangrove_monitor, trailpup, voltwig, pebbik, breezetail, sparkit, stormtrail, mosshock, shadelet, paddlenewt, riftfrill, stormraven, cragclaw.
- **Captures:** 260 frames, none blank, 0 script errors.

**Sets:** same format as `G-things-faint.md`.
- Crop: 560,200, 1000×640.
- Tiles: standing (hit 000), hit 050, faint 050, faint 100.
- Brief: the F36 (1) brief.
- Recorded defects: each row's latest roster defects plus "the faint does not reach the ground (body, neck or head stays raised, sits upright or floats)".

**Render check:** 2.9–6.1% of pixels changed per sheet (cragclaw lowest at 2.9%).

**Batches:** two batches of three fresh code-blind judges each, standard prompt. Both are confirming batches.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22.

| Batch | Sets | Slope | Intercept | r | RMSE |
|---|---|---|---|---|---|
| `G-f2a` | 7 | 1.1476 | −0.2655 | 0.939 | 0.343 |
| `G-f2b` | 6 | 1.3176 | −1.7693 | 0.954 | 0.297 |

- **G-f2a warning:** breezetail and pebbik meet the bar only above the top anchor. This batch counts as their confirmation.

## Verdict: SPLIT
- **Ship:** 8 species: 6 with all three judges, plus mosshock and stormraven as ride-alongs.
- **Drop:** 4 species. All three judges prefer base on each.
- **Level:** 1 species (cragclaw).

The species split by the end pose:
- Judges reward a **prone, head-down or side-lying end with the tail flat**.
- They mark down an end that is **belly-up with legs in the air**: base on pebbik and on the monitor.
- They also mark down an end that is **crouched with the haunches raised**: the arm's crumple on stormtrail, voltwig, sparkit and trailpup. Judges read it as "cowering, not collapsed".

| Row | Species | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm | Call |
|---|---|---|---|---|---|---|
| F36#58 | **pebbik** | 6.2, 6.3, 6.5 → 7.00 | 6.8, 6.9, 7.0 → **7.65** ↑top | **+0.65** | 3/3 | SHIP; capture Medium |
| F36#66 | **shadelet** | 6.0, 4.8, 5.6 → 5.43 | 6.2, 5.4, 6.3 → **6.09** | **+0.66** | 3/3 | SHIP |
| F36#57 | paddlenewt | 5.9, 5.6, 6.1 → 6.47 | 6.3, 6.1, 6.5 → **6.96** | +0.49 | 3/3 | SHIP |
| F36#62 | riftfrill | 5.9, 5.6, 6.0 → 6.43 | 6.2, 6.0, 6.4 → **6.85** | +0.42 | 3/3 | SHIP |
| water mangrove monitor | water_mangrove_monitor | 6.8, 6.2, 6.6 → 6.84 | 7.0, 6.6, 6.8 → **7.19** | +0.35 | 3/3 | SHIP (≈7.2, close-out exception) |
| F36#35 | breezetail | 6.6, 6.6, 6.6 → 7.31 | 6.9, 6.8, 6.9 → **7.61** ↑top | +0.30 | 3/3 | SHIP; capture Medium |
| F36#54 | mosshock | 5.6, 5.6, 6.2 → 6.39 | 5.9, 6.0, 6.1 → 6.62 | +0.23 | 2/3 (c prefers base) | ride-along |
| F36#74 | stormraven | 6.3, 6.0, 6.3 → 6.85 | 6.2, 6.2, 6.6 → 7.00 | +0.15 | 2/3 (a prefers base) | ride-along |
| F36#42 | cragclaw | 6.1, 6.0, 6.3 → 6.77 | 6.1, 6.0, 6.4 → 6.81 | +0.04 | 1/3 (2 ties) | level; nothing to ship |
| F36#75 | stormtrail | 7.2, 6.3, 7.0 → 7.23 | 6.6, 6.0, 6.6 → 6.66 | **−0.57** | 0/3 | DROP |
| F36#83 | trailpup | 6.6, 5.9, 6.6 → 6.62 | 6.3, 5.6, 6.1 → 6.14 | **−0.48** | 0/3 | DROP |
| F36#87 | voltwig | 6.9, 5.7, 6.8 → 6.75 | 6.4, 5.6, 6.4 → 6.31 | **−0.44** | 0/3 | DROP |
| F36#70 | sparkit | 6.4, 5.6, 6.6 → 6.40 | 6.1, 5.4, 6.2 → 6.00 | **−0.40** | 0/3 | DROP |

**Recorded faint defect, base → arm:**
- pebbik: FIXED 3/3 → FIXED 3/3. The arm swaps base's "on its back with the tail and a hind leg in the air, comic" (3/3) for "prone, head on the ground".
- monitor: arm FIXED 3/3. Base was "belly-up, plank-flat" (3/3).
- shadelet: base PARTIAL or PRESENT, with "a tall rigid tail arc" (3/3) → arm FIXED 2/3.
- stormtrail and voltwig: base FIXED → arm PARTIAL or PRESENT, with "haunches raised, head propped".
- sparkit and trailpup: same pattern; base FIXED → arm PARTIAL or PRESENT ("hunch with the rear raised").

**Batch differences:** the same species score on different scales in different batches. For example, stormtrail base is 7.23 here against 6.82 on the board. Read the gains within each batch.

## What the judges say
- **Shared top change (6 of 6 judges):** one grounded faint end for every creature: "side-lying, legs folded, head and neck on the ground, tail flat". No belly-up end, no raised haunches, no tail, wing or crest spike sticking up.
  - stormtrail, voltwig, sparkit and trailpup need a side-lying end, not the arm's crumple and not base's belly-up variants. For these four, base already lies on its side.
- **Still wrong on the arm:**
  - stormraven: one wing sticks up like a fin, and the hit frame shows "a flat dark slab" tail or wing (3/3).
  - riftfrill and paddlenewt: on their sides "with fin and crest shards jutting up" (3/3). paddlenewt also loses its crest in the faint (PRESENT 2/3 on base).
  - breezetail: the crest ear stays up (minor).
  - shadelet: hit-reaction feet float on both sides (3/3).
  - Hit frames on riftfrill and paddlenewt also float slightly (2/3).
- **Not about poses (top change 2, 3/3 in G-f2b):** each species' single elemental trait plus a rim or fill light:
  - trailpup: no amber paws or eyes;
  - sparkit and voltwig: no electric line;
  - shadelet: near-black with no rim.
  
  In G-f2a, 2/3 judges ask for new art:
  - mosshock's all-over moss pattern hides its face;
  - riftfrill's glossy purple blotches;
  - paddlenewt shares riftfrill's mesh, which reads as an identity problem.

  On cragclaw, the face is buried under the shell (3/3).

## Recommendation
1. **Ship the per-species crumple rows** for pebbik, shadelet, paddlenewt, riftfrill, water mangrove monitor and breezetail, with mosshock and stormraven riding along.
2. **Drop the rows** for stormtrail, trailpup, voltwig and sparkit. For these four, base's side-lying end beats the arm. If a third round is tried, give them a side-lying end with the head down; do not ship this crumple.
3. **Medium captures:** pebbik (High 7.65) and breezetail (7.61). Each closes if Medium is 7.5 or above. This batch is the confirming one for their above-anchor High scores.
4. **Close-out exception candidates:** water mangrove monitor (7.19) and stormraven (7.00). Fold stormraven's wing flat, and remove the slab from its hit frame.
