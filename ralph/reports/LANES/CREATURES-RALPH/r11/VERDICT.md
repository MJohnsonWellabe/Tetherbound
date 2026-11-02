# CREATURES-RALPH r11: Torrentoad attempt 2 and the Terrapup faint (CPU, three blind judges)

The harness matches r1. Anchors were craft, f36_0_npc:C7 and f36_0_gap:C5 (seed 110211). Fit: slope 1.18, intercept −0.86, r 0.99, RMSE 0.09, no warnings.

| Creature | Change | Mapped shipped → fix | Target | Verdict |
|---|---|---|---|---|
| Torrentoad | r10's toad coat plus a matte finish (roughness 0.88), weights relaxed | 4.62 → 5.17 (+0.55; r10's attempt 1 was +0.91) | ≥ 6.26 | not kept; **second failed approach** |
| Terrapup | Faint: legs folded ×0.5, side roll ×0.85 (76.5°), weights relaxed | 6.59 → 6.55 | beat shipped | not kept |

## Torrentoad: needs new art (coordinator)

- **Why grading can't fix it.** All three judges agree the silhouette is a gaunt upright "frog-man" biped, which no texture can fix. The faint-end "dorsal spikes" are its feet in the air.
- **Roughness on CPU.** The matte finish does not register in CPU Compatibility, which has no reflections (the same as CO-F36-7).
- **Ask.** Please generate the new Meshy model the coordinator offered: a blue speckled toad, crouched, four-legged, with a pale belly.
- **Interim.** r10's toad coat (`creatures_ralph_torrentoad_toad`, without roughness) is committed with its flag OFF. It was +0.91 over the live remake on CPU. The coordinator can turn it ON as an interim improvement.

## Terrapup: the faint is not the problem the judges see

- All three judges see the same flat slab in both arms. The cause is the uniform tile-grid of mossy plates that covers the whole back ("strapped-on carapace").
- The owner wants this look kept, so the plates stay. The faint change is dropped.
- A real fix needs either a plate repaint that breaks up the grid (`remake_owner1101_plate_blend` is already OFF) or a re-authored faint in Blender.
