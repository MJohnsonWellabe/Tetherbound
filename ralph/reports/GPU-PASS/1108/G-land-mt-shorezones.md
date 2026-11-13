# G-land-mt-shorezones: dune sage/straw zones, wet band and wrack line (GPU High, base vs arm)

## Verdict: DO NOT SHIP. Every judged row LOSES, 0/3 on each. F39#15 −0.90, F39#2 −0.62, F39#1 −0.56.

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F39#1** (brine walk_03, first shore route) | 6.48 | **5.92** | **−0.56** | 0/3 | 5.9→5.4, 5.8→5.5, 5.8→5.4 | PARTIAL / PARTIAL 3/3 |
| **F39#15** (terraces route + walk_01, sluice route) | 6.15 | **5.25** | **−0.90** | 0/3 | 5.7→5.0, 5.5→4.9, 5.6→5.0 | PRESENT / PRESENT 3/3 |
| **F39#2 no-loss** (terraces route, first shore route) | 6.25 | **5.63** | **−0.62** | 0/3 | 5.6→5.2, 5.6→5.2, 5.8→5.3 | PARTIAL / PARTIAL 3/3 |

- **Scores:** all mapped, from the same batch as G-land-mt-seadepth. Fit r 0.900, RMSE 0.61, confirming.
- **Not judged:**
  - F39#27: its character frames are not in the section.
  - F39#30: it has no frames in the section.

## Why it loses (3/3)
- **The near-sand artefact:** "a large flat olive-green polygon painted over the sand with hard straight edges", which "reads as a broken terrain-splat artefact, not ecology". All three judges name it in F39#1 frame 2 (first shore), F39#2 frames 1–2 and F39#15 frames 1–3 (terraces, sluice). The GPU lane's warning is confirmed, and this is what costs every row.
- **The intended far-dune zones register only weakly.** Judges a and c: "scattered grass tint, a weak start toward layering" on the far dune in brine walk_03. Not one judge reads a wet band or wrack line.
- **Shore ecology stays thin on both sides (3/3):** "sand running straight to water", with no dune-grass belt, wet-sand band or surf.

## Next asks (LANE-LAND-MT)
1. **Fix the splat mask before anything else.** The zone colour lands on near-sand terrain triangles as flat per-face patches. Blend it with a soft noise mask in screen-independent world space, and keep it off flat near-shore sand. Scene.
2. **Make the zones read:** a clearly darker wet-sand band at the waterline, a visible wrack or driftwood line, then the dune-grass belt. The tint alone does not read at route distance.
3. **Re-capture the same frames** once the patches are gone. With them present, this arm costs every row it touches.
