# r32 (26 Oct): storm canopy bark tint, code-blind CPU, PARKED

The candidate retints the `stormwood_vegetation.json storm_canopy` layer:
- `Bark_TwistedTree` from #a8977a to #94895a, a natural brown oak (on-screen trunk mean moves from (110, 84, 79) mauve to (96, 75, 58) brown);
- `Leaves_TwistedTree` from #6c9488 to #5e8c70.

The vegetation file is a scatter bake source, so the candidate arm is re-baked. All 108 region files come out identical; only the manifest changes. A first variant, #8f9a8e, rendered lilac-grey on screen and was not judged.

Stands, calm: Lantern Pools v01 and v02, Lantern Hollow, Deepwood road. The baked forest is present on both arms; both capture logs were checked for a stale bake.

Judges (raw, candidate set Hp, A = on):

| Judge | off | on |
|---|---|---|
| 1 | 5.5 | 5.6 |
| 2 | 5.6 | 5.6 |
| 3 | 5.3 | 5.3 |

No gain, so the change was not calibrated. **PARKED.** The vegetation tint stays as it is and nothing is committed to config.

All three judges call the arms "practically identical". The trunk defect is PARTIAL on both arms: a tint alone does not move the bark read. What they ask for instead:
- bark texture and moss;
- the copper/glass highlights;
- black reflective pools;
- real lanterns;
- fog layers, shafts and lightning;
- breaking up the fern-card carpet.
