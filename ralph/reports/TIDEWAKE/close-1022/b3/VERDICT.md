# Tidewake calibrated batch 3 (22 Oct 2026, ~17:30 CT)

## Setup

- **Candidate:** b3 at 2e8aabbeb, on CPU (llvmpipe, Low).
  - Lighting: ambient 2.0, sky share 0.15, haze 0.0006. This lifts dune shadow luma from 60 to 94 against 159 in sun.
  - Sand value lowered.
  - P2-008 shore-ecology colonies switched on under the look gate.
  - Current foam ribbons replace the grouped foam.
  - No paver discs or RockPath stepping stones.
- **Control:** the batch-1 control frames, unchanged. Currents control is at 807adae56.
- **Anchors:** `anchor_tiles.py --pairs 3 --seed 33` gave F36#0 npc C6, F36#0 gap C1 and the F10#2 r3 capacitor.
- **Fit caveat:**
  - The least-squares slope was 0.289, outside the 0.5–2.0 window, so `calibrate.py` fell back to a mean offset (+1.0).
  - Anchor RMSE is 1.06, above the 0.75 warning line.
  - These judges ranked the anchors differently from the reference judges, which makes this batch's mapped scores weaker evidence than batches 1 and 2.

## Mapped Bar A

| Row | Set | Control → mapped | Candidate → mapped (judges) | Best before | Gain on best |
|---|---|---|---|---|---|
| P2-011 named destinations, heading 0 | Xl | 3.96 | **5.83** (5.93/5.83/5.73) | 6.13 (b2) | -0.30 |
| P2-011 named destinations, other headings | Du | 3.83 | **6.03** (6.13/6.13/5.83) | 6.28 (b1) | -0.25 |
| F13#5 dock | Db | 4.76 | **6.39** (6.53/6.53/6.13) | 6.77 (b2) | -0.38 |
| P2-026/P2-009 water and shoals | Ik | 5.19 | **5.16** (5.33/5.53/4.63) | 5.57 (b1) | -0.41 |
| P2-066/F13#5 currents | Kj | 4.86 | **4.96** (5.13/5.13/4.63) | 4.85 (b2) | +0.11 |

## Disposition (gain rule)

These three rows gained under 0.5 on their best in two consecutive rounds (b2, then b3). B3 was the clearly different approach: a light pass plus shore ecology. Under the gain rule they **park at their best mapped CPU scores**:

| Row | Parked at | Batch |
|---|---|---|
| F13#5 dock | 6.77 | b2 |
| P2-011 named destinations, heading 0 | 6.13 | b2 |
| P2-011 named destinations, other headings | 6.28 | b1 |

- **Dock and the old CPU-provisional bar:** the dock's 6.77 is at or above the 6.7 bar the 20 Oct kickoff set, but under the 22 Oct yardstick "done" means a mapped 7.5. Whether a GPU pass should confirm the dock is the coordinator's call.
- **Water/shoals:** the light and depth changes did not move it in any batch. It stays open, pending a real shoal reshape and rebake (P2-026), which is a gameplay-terrain change.
- **Currents:** one round so far gained +0.11 on best. It stays open; the b4 change is already pushed (full-opacity ribbons, kelp removed).

## Judges' asks (all three)

- **Light and atmosphere:**
  - Flat noon light, no haze, no rim light.
  - Empty, uniform dunes; vegetation should form groves, not an even blade scatter.
  - Distant islands read as blank sand domes.
- **Water:**
  - The candidate's deep water now reads as "dark navy blotches and stripes"; the halo step is still PRESENT ×3.
  - The shoals are still a chain.
  - "White stacked blocks" at the Drowned Garden shore: the Meshy terrace walls read as placeholder boxes from that camera distance.
- **Landmarks:**
  - The Salt Crown shrine sits clipped behind the dune crest, so it reads as a "crystal on a pole".
  - The Lantern Cove arch is washed out next to the smoke column.
  - Deep Watch is "crammed against a dune wall".
  - The Drowned Garden terraces still don't read.
- **Currents:**
  - Still barely legible.
  - The teal kelp floater reads as shards (removed in b4).
- **Outside the Tidewake rows:** the anchor creature (F36#0 gap C1) is no taller than the ruler, and the Stormwood fight anchor has a camera in the canopy. These are anchor observations only.

Candidates stay OFF.

_Repo-size cleanup (owner, 22 Oct): only this verdict, key.json and the contact sheet are kept on main; the batch/judge/mapped JSON, set list and spec stay on tb/tidewake._
