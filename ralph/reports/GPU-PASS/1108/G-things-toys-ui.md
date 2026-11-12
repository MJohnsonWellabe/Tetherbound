# G-things-toys-ui: pickup tone-down, catch-card clear and dust soften (GPU High)

**Frames:** `tb/gpu-frames-1108`, `tb/things` 22ff3cd1f on both sides, High, script and config only.
- **base:** overlay off.
- **arm:** `THINGS-TOYS-UI/overlay_toys_ui.json`, which turns on:
  - meshy tone_down (size 0.55, value 0.8, desaturate 0.3, glow 0.5);
  - mushroom tone_down;
  - `catch_card clear_on_aim_1112`;
  - `dust_soften`.
- 0 blank frames and 0 script errors.

**Sections:**
- G-toys-pickups-meadows (91ac0bcb0)
- G-toys-pickups-cloudreach (634938547)
- G-toys-catch (d9bd32fca)
- G-toys-dust-f38 (87c950c03)
- G-toys-dust-f41-capacitor (1240453c0)
- G-toys-dust-f41-hollows (eeae90d81)

**Sets:** one base-vs-arm set per row, on each row's job.json frames, subject and recorded defect.

| Row | Frames | Pixels changed |
|---|---|---|
| F38#6 | good, great and rare candy, small potion | 3.38% |
| F40#16 | speed and wild mushroom | 0.29% |
| F40#13 | catch 06 and 07 | 18.77% |
| F38#3 | grunt fight 01–03 | 0.22% |
| F38#11 | grunt fight 02, 03, 05 | 0.38% |

**Not judged:**
- **F41#3 dust (capacitor and hollows):** the GPU lane measured at most 0.05% of pixels changed, which is no visible change. Recorded as level.
- **Stamina mushroom:** the frame shows no mushroom on either side (a capture-stand gap).
- **F40#17:** its job.json frames are the High Perches rim captures, which this run did not include.

**Batch `G-ty`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** slope 1.4018, intercept −2.0014, r 0.919, RMSE 0.545.
- **Warning:** F40#13 arm meets the bar only above the top anchor (7.53). This is the confirming batch.

## Verdict: SPLIT. The catch-card clear ships; the Meadows pickup tone-down loses; the rest is level

| Row | Base | Arm | Gain | Prefer arm | Raw base → arm (a, b, c) | Recorded defect (base → arm) |
|---|---|---|---|---|---|---|
| **F40#13 catch feedback** (catch_card) | 6.88 | **7.62** ↑top | **+0.74** | 3/3 | 6.4, 6.5, 6.1 → 7.0, 7.0, 6.6 | PRESENT 3/3 → FIXED 3/3 |
| **F38#6 ground pickups** (meshy tone_down) | 6.36 | **5.52** | **−0.84** | **0/3** | 6.3, 6.0, 5.6 → 5.7, 5.4, 5.0 | PARTIAL 3/3 → **PRESENT** 3/3 |
| F40#16 mushroom variants (mushroom tone_down) | 5.76 | 5.76 | 0.00 | 0/3 (level) | identical | PARTIAL → PARTIAL |
| F38#3 fight camera and scale (dust_soften) | 7.11 | 7.11 | 0.00 | 0/3 (level) | identical | PARTIAL → PARTIAL |
| F38#11 fight tells and hits (dust_soften) | 6.83 | 6.83 | 0.00 | 0/3 (level) | identical | PARTIAL → PARTIAL |
| F41#3 (dust_soften) | n/a | n/a | not judged | n/a | at most 0.05% of pixels changed | n/a |

The ship rule fails for the overlay as one arm, because F38#6 loses at 0/3. Split it:

**1. Land `catch_card clear_on_aim_1112` alone.**
- F40#13 goes from 6.88 to 7.62, which meets the bar at High.
- The stale "Pebbik broke free / Weaken it more" banner is gone over the 100% aim state (3/3). Base still shows it, and loses the team HUD in frame 2.
- **Next for F40#13:** capture Medium. It closes if Medium is 7.5 or above.

**2. Drop the Meadows meshy tone_down at size 0.55.**
- Shrinking the pickups makes them "small blobs that are hard to identify at normal distance" (3/3).
- In frame 4, the potion reads as "a green glowing orb" (3/3).
- The base's larger candy, sack, basket and pouch read as distinct items, though "toy-like and oversaturated".
- **If you retry:** keep the size and use only the desaturate and value parts. Judges a and b name oversaturation as the remaining base fault.

**3. Mushroom tone_down and dust_soften do nothing visible** (0.00 on F40#16, F38#3 and F38#11, and no visible change on F41#3). Either drop them or keep them; they don't count as a gain.

## Other notes from this batch
- **F40#16 mushrooms (3/3):** colour now separates speed (pale yellow) from wild (orange), but both are "the same smooth, toy-like domed-cap silhouette" with no grounding shadow. They need distinct mushroom species shapes (new_art).
- **F38#3 is at 7.11 on this tree:** a close-out candidate. Remaining: the trainers are pressed against Terrapup's chest, so the silhouettes overlap (3/3).
- **F38#11 (6.83):** the magenta floor marks are gone, replaced by a gold ring and dotted trail (3/3). Hits are still "small particle dots with no impact silhouette", and the tell still leans on text.
- **Owner rule:** judge b flags "a red banner prop on the right edge" of the F38#3 frames as close to the reserved red. This is likely the grunt's Tether banner, so the use is correct.
