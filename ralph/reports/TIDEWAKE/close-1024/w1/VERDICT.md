# Tidewake close-1024 batch w1: P2-009 water depth, on the F39 look set (24 Oct 2026, CT)

- **Item:** P2-009 (water and island depth) / P2-026, judged on the F39 biome look views. Camera set `tools/visual_judge/camera_sets/F39-look.json`, six fixed views: First Shore at 12:00, 18:00 and 23:00; the swim-lesson dune at 12:00 and 05:00; Veilfall up close. Captured with `capture_tidewake_f13_5.gd --camera-set=...`, 1920x1080, CPU llvmpipe, Low.
- **Control:** main 5f1f388cc, shipping look. **Candidate:** the OFF `surfaces_candidate` section (a mid shelf colour stop, falloff 12 m, and a world-space wander on the depth every ramp reads).
- **Yardstick:** `JUDGE_PROMPT.md` verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 909 --pairs 4 --include craft` gave craft before/after (4.83/7.35), f36_0_gap C5, f36_0_npc C5 and f04_6_r22. `calibrate.py` fitted a line (slope 0.875, r 0.835), anchor RMSE 0.50, top anchor 7.35, `confirming_batch: true`.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (main) | 5.6 / 6.0 / 4.4 | 5.90 |
| P2-009 shelf candidate | 5.3 / 5.8 / 4.9 | 5.90 |

**No gain at all.** Both recorded defects stay PRESENT (one judge: depth gradation PARTIAL) on both sides. The candidate stays OFF.

## Why it did not work, from the judges' own words

The seam they are naming is **not the depth ramp**. All three describe "the sea meets the sky on a perfectly straight horizontal line with no haze", and two of them separately describe stacked bands *above* the shelf: shallow, mid, then "a near-black navy strip at the horizon". That strip is the horizon itself, where the water plane ends, plus the offshore ramp; a third colour stop inside the shelf range cannot touch either. The shelf stop is still correct work (it is what the board asks for in the lagoon) but it is invisible at these cameras.

## What the judges asked for instead, in value order

1. **Horizon haze and aerial perspective.** The sea/sky seam needs to dissolve, not be re-coloured. (All three.)
2. **The time-of-day grade.** 18:00 renders as noon at a slightly lower exposure: same cool blue sky, same sun height, no warm cast, no long shadows. 23:00 is flat ambient with no moon direction, and one judge measured the far water reading *brighter* than the near water, inverting the depth read. (All three.) **This is the largest single finding in the batch and it blocks F39#3's day/night requirement.**
3. **A hero Veilfall asset.** All three call the Veilfall close-up the weakest frame on both sides: near-black faceted slabs with untextured facets, an opaque white quad for the falls that stops in mid-air, no mist, no plunge pool, no scale cue, against a board that asks for pale stratified limestone, layered cascades and turquoise pools. Marked `new_art` by all three. Added to the lane's Meshy request list.
4. **Authored ground.** Pebbles and dune grass at near-uniform scale and spacing; they ask for drifts, edges and clearings.
5. **Recorded for other lanes:** the quick bar and prompts are keyboard keys in a controller-first game and the quick-bar slots carry no icons; the minimap reads as a placeholder; a hard-edged dark shadow with a dithered edge crosses the dune with no caster in frame.

Answer to 1 and 2 is pushed as the OFF `lighting_candidate` section (a real evening grade, a directional moonlit night, stronger horizon haze and aerial perspective) and is judged in its own round.
