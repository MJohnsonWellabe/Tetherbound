# G-dialogue-recapture-tidewake and -cloudreach: new dialogue baselines on the fixed blend (GPU High)

**Frames:** `tb/gpu-frames-1108`, main 8df122a83 (PR #910), High, one-sided, blend 1.000 on every frame, 0 blank, 0 script errors.
- **Tidewake** (b54c9c6c5): 39 frames. Rune was left out by the GPU lane (panel-only, blend 0).
- **Cloudreach** (21dbbc238): 11 frames.
- **No frames yet, so not re-based:** Tidewake Rune, Mara and the Pell trial. They need a stand fix first.

**Sets:**
- **Board rows with dialogue frames in job.json** (`water__` frames aliased to the `tidewake__` ids), 2×2 each:
  - Tidewake: F39#18, F39#26, F39#29.
  - Cloudreach: F40#10, F40#12.
- **Every other conversation** as 3×3 sample sheets: Tidewake 30 frames on four sheets (9, 9, 9, 3); Cloudreach 6 frames on one sheet.

**Batch `G-dt`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** slope 1.3159, intercept −1.3913, r 0.883, RMSE 0.649. No warnings. The anchor RMSE is higher than usual, so read differences under about 0.3 as noise.

## New baseline vs old

| Row | Old (board) | Earlier re-score | **New (blend 1.000)** | Raw a, b, c | Recorded defect |
|---|---|---|---|---|---|
| F39#18 dialogue camera framing | 6.16 | 7.06 (batch 1) | **7.12** | 6.4, 6.6, 6.4 | "small and distant": FIXED 3/3 |
| F39#29 dialogue speaker visibility | 6.61 | 6.41 | **7.03** | 6.4, 6.6, 6.2 | "no identifiable speaker": FIXED 3/3 |
| F39#26 dialogue foreground obstruction | 6.01 | 6.49 | **6.94** | 6.2, 6.4, 6.4 | "player head and back overlap": FIXED 2/3, PARTIAL 1/3 |
| Tidewake sample 1 (9) | n/a | n/a | 6.46 | 6.0, 6.2, 5.7 | |
| Tidewake sample 2 (9) | n/a | n/a | 6.46 | 6.0, 6.3, 5.6 | |
| Tidewake sample 3 (9) | n/a | n/a | 6.42 | 6.0, 6.2, 5.6 | |
| Tidewake sample 4 (3) | n/a | n/a | 6.72 | 6.1, 6.5, 5.9 | |
| **F40#12 dialogue speaker visibility** | 6.95 | n/a | **7.25** | 6.5, 6.8, 6.4 | "speaker absent": FIXED 3/3 |
| F40#10 dialogue foreground composition | 6.74 | n/a | **6.77** | 6.2, 6.4, 6.0 | "player or posts hide the speaker": PARTIAL 3/3 |
| Cloudreach sample (6) | n/a | n/a | **7.43** | 6.7, 6.9, 6.5 | |
| **Tidewake, all 39 frames (frame-weighted)** | | | **≈6.64** | | |
| **Cloudreach, all 11 frames (frame-weighted)** | | | **≈7.26** | | |

**Every dialogue row rises with the full blend; none falls.** Close-out candidates at 7.0 or above:
- F40#12 7.25;
- F39#18 7.12;
- F39#29 7.03.
- The Cloudreach sample (Orrin, Neri, Iven, Maela, Voss, Aila) reaches 7.43, "the best conversation set" (2/3).

## What still holds them back (unprompted)
**1. Reused speaker meshes (3/3, new_art).**
- One hat-and-coat "cowboy" body plays Nel, Tal, Tess, Keeper Tovin, Evi, Fen, Keir, Orsen, Otto, Vera, Yara and Orrin: "more than 10 speakers" (judge c).
- Elin and Halen share one bearded mesh.
- "Captain Nerissa" uses the bearded male captain mesh, the same as Captain Veyra. That is a clear identity mismatch (judge c).
- Edda's and Warden Aila's portraits are tiny full-body figures, not faces.

**2. Dialogue camera framing (3/3, scene).**
- Odan is hidden behind the dialogue panel, with only the hat showing.
- Defector Corin faces away, or is hidden behind the player's head and shoulder.
- The player's backpack sits at the frame edge (Tavi, Rusk, Kelm).
- Flat sand or rock walls behind speakers: Iona, Sera, Fennel, Morra.
- Near-black caves: Evi, Morra.
- **Ask:** keep the speaker's face above the panel and facing the camera, clear the player from frame, and add cave fill light.

**3. Flat noon light.** No rim light, and no time-of-day grade on the Tidewake beaches (3/3).

**Owner-rule flags:**
- **Possible red leak (judge c):** Bex and Irva wear "a magenta chest emblem. If they are not Team Tether, that colour is leaking onto friendly characters." Please check their faction.
- A "stray pink glow beside Officer Venn" (judge b).

## Next swing
A per-speaker mesh or outfit pass for the Tidewake cast (the cowboy body) would lift most Tidewake samples. The dialogue-camera clearance rule from `G-dialogue-recapture-meadows.md` applies here too.
