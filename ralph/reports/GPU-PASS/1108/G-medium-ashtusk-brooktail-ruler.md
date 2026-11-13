# G-medium-ashtusk-brooktail-ruler: F36#33 Ashtusk and F36#36 Brooktail at Medium (GPU)

## Verdict: neither row closes. Ashtusk 7.28 and Brooktail 7.03 at Medium.
At Medium the judges see the two sides as identical (3/3 on both creatures), and score them identically: gain 0.00, no preference.

| Row | High (G-things-ruler-rescore) | Medium base | Medium arm | Medium arm per judge (mapped) |
|---|---|---|---|---|
| F36#33 Ashtusk | 8.03 | 7.28 | **7.28** | 7.57, 6.68, 7.57 |
| F36#36 Brooktail | 7.69 | 7.03 | **7.03** | 7.28, 6.68, 7.13 |

- **Why the High gain does not carry over.** At High, the judges scored the trainer ruler overlapping the tail or rump on base. At Medium they saw no overlap on either side. Render difference here is 1.1% of pixels, and the arm's change is a small step of the ruler figure. So Medium measures the creature itself, which sits under 7.5.
- **The ruler flag still ships** (G-things-ruler-rescore). Nothing here loses.
- **Both rows sit at 7.0 or above,** so the close-out exception applies to a sub-0.5 fix that takes them over 7.5.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-medium-ashtusk-brooktail-ruler` (909d65ba0), Medium. Both presets in the manifest are `-Medium`.
- **Capture:** `capture_f36_poses.gd --whole-body --context --roles=hit,faint` for ashtusk and brooktail. 20 frames per side.
- **Build:** main f421556ca on both sides, no overlay.
  - **base:** without `--clear-ruler`.
  - **arm:** with `--clear-ruler`.
- **Health:** 0 script errors. Neutral stage, `PACK_STAGE_FRAMES=1` after an eye check.
- **Sets:** the same crop, tiles, brief and recorded defects as the High batch.
- **Render check:** 1.1% of pixels changed on each sheet. Only the ruler figure moves.

## Batch `G-abm`
- Three code-blind judges, standard prompt, two candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.4831, intercept −2.659, r 0.954, anchor RMSE 0.30. No warnings.

| Row | Raw (both sides) |
|---|---|
| Ashtusk | 6.9, 6.3, 6.9 |
| Brooktail | 6.7, 6.3, 6.6 |

## What holds them under 7.5

### Ashtusk
1. A thin vertical line floats above the back in the standing and hit frames (3/3). This is an artefact.
2. In the hit frame the tusks dig into or through the floor (3/3).
3. "Near-black plates merge with shadow" is still PARTIAL (3/3). The ember glints help only in the faint frames.
4. The faint frames look like a different, shaggier plated mesh from the standing boar (1/3, judge b, who scored 6.3).
5. One judge (1/3) noted that the tusk tips carry a red-copper tint close to the reserved red.

### Brooktail
1. The aqua spots are too many and too large, especially in the faint frames, and read as a leopard or salamander pattern rather than an otter with one elemental trait (3/3).
2. The near-black head on the grey stage has no rim light, so the eyes and face are not readable (3/3).
3. Spiky geometry pokes up from the back in faint end (2/3).
4. "About trainer height" is FIXED for 2/3. One judge marks it PARTIAL: the head clears the trainer, but the back sits about at trainer height.

## Next (close-out candidates)
- **Ashtusk:**
  - Remove the floating line above the back. It may be a stray bone or helper mesh.
  - Lift the hit pose or offset the tusks so they stay above the floor.
  - Add a cool rim light on the pose stage for the dark plates.
  - These are scene or data fixes. Remove the artefact first: 2 of 3 judges scored it 7.57.
- **Brooktail:**
  - Cut the spot emission and size to a sparse flank-and-tail pattern.
  - Add a rim light so the eyes read.
  - Fix the faint-end back spikes.
  - The spot pattern may need a texture change.
- **Re-judge** both rows at High and Medium.
