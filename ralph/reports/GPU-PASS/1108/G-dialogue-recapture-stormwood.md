# G-dialogue-recapture-stormwood: new Stormwood dialogue baseline on the fixed blend (GPU High)

**Frames:** `tb/gpu-frames-1108` 750106556, main 8df122a83 (PR #910), High, one-sided.
- 43 `__dialogue` frames; blend 1.000 on every frame, 0 blank, 0 script errors.
- **No frames yet, so not re-based:** Officer Kestrel and Officer Kestrel (outer works). They need a stand fix first.

**Sets:**
- **The four Stormwood board rows with dialogue frames in job.json** (F41#7, F41#11, F41#15, F41#20), three frames each in a 2×2 grid.
- **The other 31 conversations** as four sample sheets.

**Batch `G-dsw`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.2554, intercept −0.6196, r 0.937, RMSE 0.346.
- **Warning:** "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)". This applies to F41#15.

## New baseline vs old

| Row | Old (board) | **New (blend 1.000)** | Change | Raw a, b, c | Recorded defect |
|---|---|---|---|---|---|
| F41#11 portrait identity | 7.34 | **6.91** | −0.43 | 5.8, 6.2, 6.0 | portrait mismatch: FIXED 3/3 |
| F41#20 dialogue reuse | 6.99 | **6.41** | −0.58 | 5.7, 5.6, 5.5 | identical lines: FIXED 3/3 |
| F41#7 named trainer identity | 7.23 | **6.24** | −0.99 | 5.5, 5.6, 5.3 | generic line, no portrait: FIXED 3/3 |
| **F41#15 foreground obstruction** | 5.71 | **4.49** | −1.22 | 4.0, 3.9, 4.3 | creature hides speaker: **PRESENT 3/3** |
| Stormwood sample 1 | n/a | 6.66 | | 5.6, 5.9, 5.9 | |
| Stormwood sample 2 | n/a | 6.54 | | 5.8, 5.6, 5.7 | |
| Stormwood sample 3 | n/a | 6.24 | | 5.2, 5.5, 5.7 | |
| Stormwood sample 4 | n/a | 6.41 | | 5.4, 5.8, 5.6 | |
| **All 43 Stormwood frames (frame-weighted)** | | **≈6.25** | | | |

**Stormwood falls where Meadows, Tidewake and Cloudreach rose.** The recorded content defects are fixed (distinct lines, portraits that match), but the full blend now shows the speaker plainly. That exposes three Stormwood-specific faults.

## What holds Stormwood down (3/3 unless noted)

**1. Captain Marrow's head renders as a blown-out white glow.**
- "No readable face." It appears in all three frames he is in (F41#7 and F41#15).
- The flat pink plank deck and a flat-shaded trunk behind him read as unfinished.
- This is the known F41#15 bloom defect (`ITEM-F41-15`, `ITEM-NPC-ALBEDO`). It now drags two rows.

**2. Creature occlusion.**
- Officer Nysa is "almost entirely hidden" behind the blue lightning creature (F41#15, PRESENT 3/3).
- The same blue creature takes half the frame in both Tamsin frames.
- A large purple and white creature crowds Lieutenant Sera.
- Pale and blue creatures intrude on Ivo and Tavi.
- The player's head and backpack bleed in at the left edge of most frames, often over-bright.

**3. Reused models.**
- Fenn and Oswin share one hooded model and portrait (F41#20, 3/3).
- Kael and Rook look like one blond model (2/3).
- Dace and Maren, and Lena and Neil, look like near-identical pairs (judge b).

**Also:**
- Warden-Elect Bryn's face is hidden under a blue hood that contradicts his portrait (2/3).
- Fenn's camera is jammed against a house wall (3/3).
- Flat light, with no storm atmosphere near the speakers (3/3).

## Next swings (by rows lifted)
1. **The dialogue camera clearance rule** (creatures and the player's body out of the speaker's cone, camera off walls). This is the same cause as in Meadows, and here it is the biggest one.
2. **Fix Marrow's head bloom.** This lifts F41#7 and F41#15. Earlier emission-off and albedo-floor arms were level, so the cause is still open. A face-specific glow mask or exposure clamp is untried.
3. **Distinct models for the reused pairs** (new_art).

**Owner rules:** red appears on Tether elements only. No leak was named.
