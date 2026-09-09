# Creature mipmap experiment — held after complete fixture and review

The capture mechanism is now valid: an isolated 1280×800 SubViewport and one prebranch projected-body camera fit produced all162 images, with zero dimension, framing or treatment failures. Earlier viewport, decompression and framing failures remain retained. See `CREATURE-MIPMAP-FIXTURE-REPAIR-0909.md` for exact artifacts and held-paint hashes. A valid fixture is not a passing material candidate.

Four fresh neutral-file judges reviewed the fixed five-body lineup and all20 isolated subjects. They saw only the skill, references and neutral images under `.artifacts/review-20260909/set-E/` through `set-H/`; source mapping is separately retained in `creature-neutral-mapping.json`. Complete verdicts are `VISUAL-SET-E/F/G/H-0909.md`.

| Set | Coverage | Visible disposition | Reference answers |
|---|---|---|---|
| E | Fixed five-body lineup | No convincing overall A/B improvement or regression; facial/surface problems remain | Key-art No; Palworld comparison No |
| F | Skyrill, Pebblik, Galecrest, Aeriex, Cloudfang | Small surface improvement in Skyrill and Galecrest; remaining pairs effectively unchanged; little small-size benefit | Key-art No; genre resemblance Yes, without reference finish |
| G | Sparkit, Tanglevolt, Voltwig, Voltarach, Mosshock, Staticub, Stormraven | Modest local smoothing; reduced-size recognition essentially unchanged | No / No |
| H | Mangrove Monitor, Torrentoad, Mirejaw, Mosshell, Riverdrake, Cragclaw, Sirenseal, Riptusk | Modest surface improvement in six pairs, two effectively unchanged; no clear visual regression | Key-art No; genre resemblance Yes, narrowly for the cast |

The CPU-only conservative rectangular diagnostic then compared all20 subjects at four offsets and full/30% resolution, using unchanged manifest body/face rectangles. It measures normalized sRGB luminance p95−p05 range and population standard deviation. The original proposal did not fully specify a face-contrast formula or silhouette extraction; this is therefore explicitly a rectangular diagnostic, not completed body-mask or temporal acceptance.

It found21 B/A ratios below0.95, minimum0.891660. Affected measurements include Riptusk face range/std, Mangrove Monitor face range, Aeriex face std, Tanglevolt and Staticub face range, and Galecrest body range. Several losses recur across allfour offsets. Sparkit's A/B pixels are exactly identical at every offset and both resolutions, with every ratio1.0. Full results and the fixed analysis are in `.artifacts/creature-mipmap-camera-fit-0909/guard-analysis.json` and `analyze_guards.py`.

Disposition: **hold; do not apply the proposed32 generated-vivid import changes.** Local smoothing does not establish a safe, shared correction to facial contrast and surface hierarchy. No thresholds or masks were tuned after the result. The broader body-mask/high-frequency/temporal acceptance remains unproved rather than silently treated as passed. Pebblik, Voltarach and Torrentoad pixels are held paints, so this is also not exact-main-paint validation for those three subjects. The independent terrain12-texture correction already landed under its separate evidence; it does not authorize this creature candidate.

The remaining facial weaknesses require per-asset anatomical/paint attribution. A global material slider cannot infer eye or muzzle regions from unrelated single-atlas creatures. Do not repeat the same global mipmap experiment to chase the verdict, and do not claim full C6, world composition, scale, animation or performance acceptance from the isolated cards.
