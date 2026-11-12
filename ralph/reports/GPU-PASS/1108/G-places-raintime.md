# G-places-raintime: Cloudreach rain time-of-day grade (LANE-PLACES, F40#0; GPU High)

**Verdict: SHIP.** All 12 rain sets prefer the arm, 3/3 each. The mean rises from 5.04 to 5.74 (+0.70), and no set loses.

**Frames:** `tb/gpu-frames-1108`, three sections, High:
- `G-raintime-gate` aa6240b26: realm_gate_crag, pieces 1–8;
- `G-raintime-summit` 4e4c7a85a: summit_eyrie, pieces 81–88;
- `G-raintime-overlook` 7a397ae2e: stormward_overlook, pieces 89–96.

Both sides were captured from `tb/places` e556a60f1 with `capture_cloudreach_f40_matrix.gd --ground-cover-cache`.
- **base:** overlay off.
- **arm:** `PLACES-RAINTIME/overlay.json` (`rain_time_grade`).

Per stand: 16 rain frames (4 views × dawn, day, golden and night) and 4 golden-clear controls. 0 blank frames and 0 script errors.

**Render check (mean absolute difference, mean brightness base → arm):**

| Frames | Difference | Brightness |
|---|---|---|
| Golden-clear controls | 1.2–3.7 | unchanged |
| Day rain | 2.8–6.4 | about −2 |
| Golden rain | 15–19 | +4 to +6 |
| Dawn rain | 12–17 | −4 to −9 |
| Night rain | 29–50 | −29 to −50 |

The controls are the same on both sides, so I did not judge them.

**Sets:**
- 12 sets: 3 stands × 4 rain times. Each set is the stand's four views in a 2×2: approach, gameplay, reverse, detail.
- The brief is the Cloudreach biome brief for that time of day, in rain.
- Recorded defects: none. F40#0's matrix defects are not itemised per frame.

**Batch `G-rt`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 1.4035, intercept −1.7307, r 0.911, anchor RMSE 0.570. No warnings. The capacitor pair fits worst again.

## Results

| Stand | Time | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|---|
| summit | night | 5.0, 4.6, 4.9 → 5.05 | 5.9, 5.8, 6.0 → **6.55** | **+1.50** | 3/3 |
| gate | night | 5.0, 4.6, 4.8 → 5.01 | 5.6, 5.2, 5.6 → **5.94** | **+0.93** | 3/3 |
| summit | golden | 5.0, 4.9, 5.2 → 5.33 | 5.6, 5.6, 5.8 → **6.22** | **+0.89** | 3/3 |
| overlook | night | 4.3, 4.0, 4.6 → 4.30 | 4.8, 4.6, 5.2 → 5.10 | **+0.80** | 3/3 |
| gate | golden | 5.0, 4.8, 5.1 → 5.24 | 5.6, 5.4, 5.6 → 6.04 | **+0.80** | 3/3 |
| overlook | golden | 4.4, 4.2, 4.7 → 4.49 | 4.9, 4.9, 5.2 → 5.29 | **+0.80** | 3/3 |
| gate | dawn | 5.0, 4.7, 5.0 → 5.15 | 5.5, 5.3, 5.5 → 5.90 | **+0.75** | 3/3 |
| summit | dawn | 5.0, 5.0, 5.0 → 5.29 | 5.6, 5.4, 5.6 → 6.04 | **+0.75** | 3/3 |
| overlook | dawn | 4.4, 4.2, 4.6 → 4.44 | 4.8, 4.6, 5.1 → 5.05 | **+0.61** | 3/3 |
| gate | day | 5.2, 4.8, 5.3 → 5.43 | 5.4, 5.0, 5.5 → 5.71 | +0.28 | 3/3 |
| summit | day | 5.4, 5.3, 5.5 → 5.85 | 5.5, 5.5, 5.6 → 6.04 | +0.19 | 3/3 |
| overlook | day | 4.5, 4.7, 4.9 → 4.87 | 4.6, 4.8, 5.0 → 5.01 | +0.14 | 3/3 |
| **mean of 12** | | **5.04** | **5.74** | **+0.70** | |

**On the GPU lane's question (does rain still read):**
- Every "thick uniform white bars / rain curtain" complaint from the three judges lands on a **base** side. Judge c: "like a curtain over the frame"; judge a: "a screen overlay rather than weather".
- No judge says the arm lacks rain. The arm's thinner streaks are preferred.

**Time of day:**
- Every case of "night renders as overcast day", "golden is cool grey" and "dawn is grey" is on **base** (3/3).
- The arm sides are the ones judges cite as working. On summit night (judge b): "lit aviary windows against a navy night sky ... strongest frame in the batch". Judges also note the arm's warm golden grade and pink or mauve dawn.

**Absolute level:** F40#0 is a 384-frame matrix row with a board score of 6.54, and half of its frames are rain. These 48 rain frames from three stands score well below the board on both sides. The gain is the reliable number here.
- If the gain carries across the matrix, the rain half would lift F40#0 by roughly +0.3 to +0.35.
- That needs confirming on a matrix re-sample before the board moves.

## What still holds F40#0 down (all 3 judges, both sides)
1. **Placeholder architecture (new art):**
   - "flat untextured black/dark-green slab walls" beside the arch at the overlook stand (judges call them "box hedge walls");
   - the floating sky islands, which render as "black cut-out silhouettes";
   - a "billboard" cloud slab in the reverse views.

   The judges ask for pale stratified Cloudreach stone and aviary masonry. The overlook stand is the lowest (≈5.0–5.3 on the arm) because of the walls.
2. **Oversized cobble path:** the stones are as large as the trainer's torso and bury the trainer to the shins (3/3) at the gate stand's gameplay, reverse and detail views. This breaks the 1.80 m scale.
3. **Flat single-green ground** with no groves or clearings; fog is flat grey with no depth layers. A flat brown canopy mass appears in the gate approach.

The aviary dome is the one landmark that "carries every set it appears in".

## Recommendation
1. **Land the rain time-of-day grade.**
2. **Next PLACES change for F40#0:** the overlook's slab walls and the black sky-island cut-outs (new art), plus scaling down the gate cobble stones (scene). These sit in every weather and time state, so they are the matrix's shared ceiling.
