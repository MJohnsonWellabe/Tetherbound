# Tidewake close-1024 round ls1: limestone on every view it changes, and vf2 against vf1 (24 Oct 2026, CT)

- **Why this round.** The coordinator ruled that the limestone ships under beats-main, but only once every view it changes has been judged. The Meshy 7-8 hero pieces (vf2) stay OFF until they beat vf1.
- **Code.** Everything was captured at `tb/tidewake` 1e01cf5c4 or later, which includes the #725 stone-fallback fix (cabf2caab). No arm carries the pebble-grouping bug.
- **Renderer.** CPU llvmpipe, Low/Compatibility, 1920x1080.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - `anchor_tiles.py` with seed 6262 and 3 pairs (`--include craft --include f36_0_npc:C1`).
  - `calibrate.py`: linear fit with slope 1.303, r 0.98 and anchor RMSE 0.31. The top anchor is 7.53, so this is a confirming batch.
  - Warning: the vf2 pair lies below the anchors' measured range, so its absolute values are extrapolated. The direction is unanimous.

## Mapped Bar A

| Set | Main / control | Candidate | Δ | Judges |
|---|---|---|---|---|
| Seven F39-look shore and lesson views (clear, golden, night, rain, dawn), Veilfall in the distance | 5.24 | limestone 5.29 | +0.05 | level x3 |
| Venn trainer fight on the Veilfall beach, 4 moments (live fight, not identical between sides) | 4.77 | limestone 4.90 | +0.13 | 2 higher, 1 level |
| Veilfall close-up from the camp, clear and rain | limestone alone 2.85 | **vf2: Meshy cascade tiers + plunge ring + limestone 3.55** | **+0.70** | higher x3 |

With vf1 (close-up: limestone 4.20 against shipping 3.35, all three judges higher), every view the limestone changes is now judged. It gains where the rock fills the frame and holds level elsewhere, so **`veilfall_rock_candidate` ships ON**.

**vf2 beats vf1, but stays OFF for one more capture.** The Venn fight camera stands at the Veilfall camp, so the hero tiers also change those fight frames, and those have not been judged with vf2. That round is next.

None of these scores reaches 6.7. **F39#4 and F39#5 stay open.**

## What the judges say vf2 still needs (all three)

- **Rock family:** the pale stratified column "reads pasted on, partly floating, out of scale" against the huge dark slabs, because it is a different rock family from the mountain.
- **The falls:** still "a flat white rectangle", not a tiered cascade.
- **Black slabs:** the near-black faceted slabs (the `exterior_composition` formations and crown kitbash) and the stretched ramp texture remain. These are what hold the close-up below 4.
- **Framing:** the camp stand "faces a wall".

They also ask for the following, which are not this lane's:
- Fight HUD: the "C Switch / Esc Flee" text is drawn over "Gather Reef Stone", and the HUD covers about 40% of the frame.
- Ripplet's plastic finish.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_ls1.jpg`. Left to right: main views, limestone views, limestone close-up, vf2 close-up.
