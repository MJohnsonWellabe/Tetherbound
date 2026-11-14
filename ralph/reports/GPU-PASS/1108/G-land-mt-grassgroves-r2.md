# G-land-mt-grassgroves-r2: dune grass clustered into clumps (GPU High, base vs arm)

## Verdict: SHIP. F39#1 6.07 → 6.23 (+0.16, 3/3). Routes no-loss 5.87 → 6.11 (+0.24, 3/3). F39#19 Venn level, 6.51 = 6.51. No row loses.

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base / arm) |
|---|---|---|---|---|---|---|
| **F39#1** (brine walk_03, first_shore route_day) | 6.07 | **6.23** | +0.16 | 3/3 | 5.4→5.6, 5.3→5.4, 5.7→5.8 | PARTIAL / PARTIAL 3/3 |
| Routes no-loss (first_shore vista_dusk, sluice walk_01, walk_03) | 5.87 | 6.11 | +0.24 | 3/3 | 5.0→5.3, 5.3→5.4, 5.6→5.8 | none recorded |
| F39#19 Venn no-loss (t-000, t-003, matched) | 6.51 | 6.51 | 0.00 | 0/3 (ties) | 5.6, 5.7, 6.2 | FIXED / FIXED 3/3 |

- **Scores:** all mapped. Fit: r 0.912, slope 1.21, anchor RMSE 0.57; the batch is confirming. Anchors were craft, f36_0_npc C1 and f10_2_r3_capacitor (no F38#38 control, because no close was at stake).
- **Venn:** only the camera-matched frames t-000 and t-003 were judged; t-023 to t-025 are excluded under the fight-section rule. The judges call the two sides "near-identical".
- **F39#15:** not judged. Its frames are pixel-identical base vs arm, so it is level by construction.
- **F39#27:** not judged, because its character inventory frames were not captured.

## Where the gain comes from (3/3)
- The arm's taller foreground grass in first_shore frame 1 (and vista_dusk) "gives a real foreground, midground and distance". Judges b and c call it "a dark, flat, uniform clump" and "the same single blade mesh" repeated.
- Away from the camera the arm reads the same as base. The judges still see "one card type spread as an even carpet with uniform scale and spacing", which looks like generator output. The clustering does not yet read as groves at route distance.

## What the judges see (both sides)
- **Water, 3/3, top ask:** a hard near-black band across the lagoon in route_day frame 1, and a straight navy V-band through the cyan shallows in the sluice frames. It reads as "a hole in the world" or a shadow or depth artefact. The concentric rings around the sand islets at the falls read as "target decals, not surf". The same band appears in F39#1 frame 2.
- **F39#1 defect PARTIAL (3/3):** the grassy domes with grey rock skirts are gone, replaced by bare smooth sand dunes. There is still no layered shore of wet sand, wrack line, dune grass and shrubs.
- **F39#1 other defects:**
  - a salmon-orange flat patch on the far sandbar (3/3);
  - oversized, untextured dark pier posts (3/3);
  - a translucent boat wake slab (judges a and b).
- **Dusk grade (3/3):** vista_dusk floods sand, sky and sea into one orange mid-tone.
- **Venn (3/3):**
  - The roster on solid dark cells reads, so F39#19's defect is FIXED on both sides.
  - A dark overhang or slab intrudes at the top, and a floating rock or log sits at the top left.
  - The sand is blown-out white.
  - Ripplet looks glossy and toy-like (judges a and c).

## Next asks (LANE-LAND-MT)
1. **Fix the Tidewake water shading.** Remove the black lagoon band and the hard navy V-band, and replace the islet ring decals with real surf foam and a soft depth gradient. 3/3 put this first; it costs F39#1, the routes, F39#16/#17 and the Venn fight. Scene.
2. **Make the clumps read at route distance.** Use two or three clump meshes at varied scales, set along dune crests and edges with bare sand between them, instead of an even carpet. Keep the foreground layer, which is what gained. Scene.
3. **Layer the F39#1 shore:** wet sand, then a wrack or driftwood line, then dune grass, then shrubs, with rocks where land meets water. Re-material the salmon sandbar patch and texture the pier posts. Scene.
4. **Lift the dusk grade's value range** so sand, dunes and sky separate. Scene.
5. **LANE-SCENE / LANE-BEINGS, information:** the Venn top-edge overhang and floating log, and Ripplet's glossy material.
