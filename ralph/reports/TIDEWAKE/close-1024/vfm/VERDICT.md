# Tidewake close-1024 round vfm: matched-moment Venn fight for vf2 (24 Oct 2026, CT)

- **Why.** The coordinator ruled that vf2's earlier fight round (4.29 against 4.72) compared live fights that swung toward different camps. This round re-judges matched moments instead. If vf2 is level or better here, it ships with the close-up win.
- **Frames.** The same fight states from both 40-frame captures of the seeded Venn fight (seed 2042) were stacked top to bottom:
  - tell-start 0.65 s
  - hit 1.08 s
  - tell-start 3.73 s (the HEAVY tell)
  - tell-ended 4.68 s

  The first ~8 s of the two runs are in lockstep (identical fighter gaps per frame). Only camera smoothing drifts slightly.
- **Arms.** Control is shipping, with the limestone ON (`tb/tidewake` 68f4dd847). The candidate adds `veilfall_hero_candidate`.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - 3 anchor pairs, seed 8484.
  - `calibrate.py`: slope 1.289, r 0.95, anchor RMSE 0.35. This is a confirming batch, but the result is extrapolated below the anchors' measured range.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped |
|---|---|---|
| Limestone (shipping) | 3.6 / 4.0 / 4.0 | 3.64 |
| vf2 hero pieces | 3.5 / 3.8 / 4.1 | 3.56 |

The two sides are **level**: -0.08, inside the anchor RMSE, with one judge higher and two lower. All three judges called the sides "essentially identical", and none mentions the cascade.

## Then withdrawn: the placement sat on the hike

Before switching vf2 ON, a route check found a problem with the placement:
- The `veilfall_exploration_spine` (4 m wide, `main_path`, `hike_ends_at_gate`) runs up that same gully floor.
- The plunge ring (with its box collider) sat 6.5 m from the hike centreline, and the lower tier 8.4 m.
- My raycast probe had read the graded trail as cliff.

So **vf2 does not ship as judged**. The pieces are moved 15 m or more clear of the trail. A new focused test, `test_veilfall_hero_pieces_stay_clear_of_the_hike`, fails on the old positions. The moved placement is being re-captured and needs its own close-up judgement.

## Judges' asks (unchanged)

- The near-black slab in the fight's top-right.
- The fight camera shows no water, falls or horizon.
- Stair-stepped trainer shadows.
- The "Gather Reef Stone" prompt overlapping the fight HUD.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_vfm.jpg` (left: limestone, right: vf2)
