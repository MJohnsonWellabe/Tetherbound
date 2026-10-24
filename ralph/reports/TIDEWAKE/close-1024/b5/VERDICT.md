# Tidewake close-1024 batch b5: F13#5 currents (24 Oct 2026, CT)

- **Item:** F13#5 currents frame (P2-066). Fixed views from `tools/capture_tidewake_f13_5.gd --only=currents`: three departure beaches (First Shore, Brine Steps, Salt Crown) plus the Brine Steps swimmer view.
- **Control:** main 5f1f388cc, shipping look (`current_flow` is in `sections_off`).
- **Candidate b5:** `--tidewake-look-candidate` at 57eadb9f1. Tide-line seams along both banks, wavelet caps, dashes at 0.3, no floaters.
- **Renderer:** CPU llvmpipe, Low/Compatibility, 1920x1080.
- **Yardstick:**
  - `JUDGE_PROMPT.md` verbatim, three fresh code-blind judges.
  - `anchor_tiles.py --seed 1024` gave the anchors f36_0_npc C3, f04_6_r22 and f36_0_gap C2.
  - `calibrate.py` used the offset fallback (least-squares slope 2.02), anchor RMSE 0.72, top anchor 6.9.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (main) | 5.0 / 5.3 / 4.9 | 5.64 |
| **b5** | 5.4 / 5.8 / 5.4 | **6.11** |

- Previous best was 4.96 (close-1022 b3, different batch), so the gain on best is +1.15.
- Not at 6.7 CPU-provisional or 7.5. The candidate stays OFF.

## Recorded defects (b5, three judges)

| Defect | Result |
|---|---|
| Road markings | PARTIAL x3 |
| Direction unreadable | PARTIAL x3 |
| Markers read as boxes/debris | PARTIAL x3 |

The control was PRESENT on all three, except one judge's "direction" PARTIAL.

## Judges' asks

1. Show a direction: tapered, curving, streaming foam instead of straight parallel streaks. The swim-view streaks still read as markings.
2. A colour shift along the lane (deeper lane water) and visible chop or swell.
3. Proper buoys. The yellow pennants are tiny, and a blue object by the dock reads as clutter. A Meshy spar buoy and driftwood are requested.
4. Outside the row: navy depth in open water, and dune value and texture.

**Process note:** the side-by-side 2x2 sheet was downscaled to 2000 px wide for the judges. Later batches stack each side's frames vertically.
