# b16 (24 Oct 2026, CPU): GPU F36#0 scale fix (grow the under-ruler species) and the Mosshell sprawl faint

What was compared:
- Candidates:
  - The GPU F36#0 judges saw Trailpup, Mudsnout, Cindercub, Paddlenewt and Riftfrill at or below the 1.80 m ruler. Each grows, and its radius scales with it, so the footprint clamp keeps the same allowance and logs no shrink warning:
    - Trailpup 2.3 -> 3.1 m;
    - Stormtrail 2.55 -> 3.45 m (variant of Trailpup);
    - Mudsnout 2.0 -> 2.45 m;
    - Cindercub 2.5 -> 3.25 m;
    - Paddlenewt and Riftfrill 2.15 -> 3.0 m.
  - Mosshell (`candidate_nat1024s`): the Mosshock b12 belly-flat sprawl replaces its -60 side roll.
- Base: the shipping state (land c6985d7a9).

Admission:
- Mudsnout at 2.6 m broke the Warrens mouth fight (`smoke_arena_contain`: the ally Terrapup could not be seated), so it stops at 2.45 m.
- 2.15, 2.3 and 2.45 pass.
- With every growth applied, `smoke_arena_contain` passes headless.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: f36_0_npc:C1 (Grandpa face), craft, f10_2_r3_capacitor. This is a confirming batch.
- Fit: linear, slope 0.879, intercept 1.289, RMSE 0.75.
- Warning: the RMSE is at the 0.75 limit; scores reported with that caveat.

| Species | Shipping | Candidate | Decision |
|---|---|---|---|
| trailpup 3.1 m | 7.21 | 7.21 | ON (scale rule; judges score the same) |
| mudsnout 2.45 m | 6.97 | 6.97 | ON (scale rule) |
| cindercub 3.25 m | 6.83 | 6.83 | ON (scale rule) |
| paddlenewt 3.0 m | 6.56 | 6.48 | ON (scale rule; within noise) |
| riftfrill 3.0 m | 6.15 | 6.15 | ON (scale rule) |
| stormtrail 3.45 m | 6.18 | 6.12 | ON (scale rule; within noise) |
| mosshell sprawl faint | 6.74 | 6.62 | OFF: one judge marks the faint PRESENT, no gain |

Why the growth scores the same:
- Each stage tile crops to the creature plus the trainer, so these judges could not see the size change. All three reported no scale violation on either side.
- The fix answers the GPU judges' hard-rule finding (creatures stand taller than the 1.80 m trainer; grow the smaller side), not a score.
- The GPU lane's in-scene frames should confirm it.

Judges' asks:
- Real recoil hits; the shared rear-up reads as a pounce.
- Tails clear of the ruler (Paddlenewt, Riftfrill, Cindercub).
- Stormtrail near-black with yellow emissive bands.
- Riftfrill galaxy gloss.

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
