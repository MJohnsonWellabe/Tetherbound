# Tidewake close-1024 round vf2: Meshy 7-8 hero pieces at the Veilfall (24 Oct 2026, CT)

## What was placed and tested

- **Assets:** Meshy 7-8 from `tb/meshy-1024` 2d8328475, c2 concepts, with provenance and references beside each GLB.
  - The stratified cascade tier is placed twice, scaled uniformly and offset up the gully: a lower tier 28 m tall and an upper tier 34 m tall with `lift_m` 16.
  - The plunge-boulder ring (3 m) sits at the lower tier's foot with a box collider.
- **Placement:** on ground measured by a raycast probe of the veilfall-near view. That gully climbs about 1:1 from 5 m to 140 m to the gate, so it is a cliff, not a route.
- **Gate:** the whole section is OFF (`veilfall_hero_candidate`).
- **Renderer:** CPU llvmpipe, Low, 1920x1080.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges per batch, anchors and `calibrate.py` (both batches are confirming).

## Mapped Bar A, on every view it changes

| View | Compared against | vf2 | Δ | Batch |
|---|---|---|---|---|
| Veilfall close-up from the camp, clear and rain | limestone alone 2.85 | **3.55** | **+0.70** (higher x3) | ls1 |
| Venn trainer fight on the Veilfall beach, 4 moments | limestone (now shipping) 4.72 | 4.29 | -0.43 (lower x3) | vf2 (slope 1.088, r 0.95, RMSE 0.29) |
| F39-look shore-day and lesson-dune | (pixel diff only) | n/a | n/a | n/a |

- **Shore views:** the hero pieces change 17k and 8k pixels, which is below the run-to-run noise of the same capture (19k and 151k). They do not visibly appear there.
- **Both batches are extrapolated** below the anchors' measured range, so the absolute values are soft. The directions are unanimous.

## Decision: vf2 stays OFF

It beats vf1 on the close-up but loses in the fight frames, so it does not meet "beats shipping on every view it changes".

**Caveat on the fight round.** The fight is live, and its camera follows a different course each run.
- All three judges credit the control side's frames 3-4 for "the camp (tent, fire, totem, crates, NPC)" that its fight happened to swing towards.
- No judge mentions a cascade, tier or pale column in either side's fight frames.

So the fight delta reads as run variance rather than a cost of the hero pieces. Settling it needs a deterministic fight capture, or judging the fight frames as matched single moments. It is the coordinator's call whether that is worth a further round.

## What the judges ask for on the close-up

- **Rock family:** the pale tiers read "pasted on, partly floating, out of scale" against the black `exterior_composition` slabs and crown kitbash. The tiers and the mountain need to be one rock family.
- **The falls:** still a flat white strip, not a tiered cascade.
- **Framing:** the camp stand "faces a wall".

## Files

- `batch.json`, `mapped.json`, `key.json` (the fight batch; the close-up is in `../ls1/`)
- `_sheet_vf2.jpg`. Left to right: limestone close-up, vf2 close-up, limestone fight, vf2 fight.
