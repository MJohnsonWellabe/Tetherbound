# A/B visual verdict: lowest preset, X (left) vs Y (right)

Method: each pair viewed in full, and the horizon/background regions cropped and enlarged side by side. No other files were consulted.

## Per-pair verdicts

| Pair | Location | Better | Differences | Breakage on both sides |
|---|---|---|---|---|
| 00 | Cloudreach, Three Bells Bridge, day | **X** | X: cloud sea with floating rock islands at left, distant spire behind the bells. **Y: the left horizon is a flat pale-grey void, with no cloud sea, islands or spire.** | Pink glow blob at the lower-left edge. |
| 01 | Cloudreach, Broken Skyroad Arch, day | same | Identical. | **The camera is pressed against or inside a rock wall.** The whole frame is a rock texture and the player isn't visible. |
| 02 | Cloudreach Gate, Realm Gate Crag, day | **X** | X: cloud sea with distant rock outcrops at left. Y: the same area is a flat, featureless white plain/band with no rocks. | None obvious. |
| 03 | Cloudreach, Galefoot Waycamp, day | same | No meaningful difference. | None. |
| 04 | Windscar Ravine beacon, day | **X** | X: tall cliff spires, distant crystal towers, mesa with structures and cloud sea through the arch. **Y: all of those are gone; the horizon is pale haze and empty sky.** | None. |
| 05 | Windscar Flight Aerie, day | **X** | X: long cliff range receding to a distant spire, with cloud sea at left. **Y: cliffs entirely missing; the world ends at the grassy crest against a grey haze void.** | None. |
| 06 | Meadows, Grandpa's Village, day | **Y** | Y: a distant mountain range behind the village (left and right of the beam). X: only sky and a green hill behind the houses. | None. |
| 07 | Meadows, Ridgeline Watch (forest), day | **Y** (slight) | Y: a distant blue peak visible between the trunks. X: only sky there. | The camera is close behind the player against a trunk, so the view is mostly occluded. |
| 08 | Meadows, Stronghold Approach, day | **X** | X: a full layered mountain range and a distant castle on the horizon. **Y: no mountains or castle; the grass meets a soft hazy sky.** X also shows an "alpha is near" toast; that is gameplay state, not rendering. | None. |
| 09 | Meadows Hall courtyard, day | same | The small sky gap at the top shows plain blue in X and clouds in Y. That is negligible. | Very dark courtyard. |
| 10 | Water, Deep Watch lookout, day | **Y** | Y: a dune island with trees across the water. **X: no island; a hard flat grey band sits between the sea and the sky.** | Player HP is 7/100 (state, not render). |
| 11 | Water, Deep Watch beach, day | **X** | X: a large dune island with trees and further dunes on the horizon. Y: the island is reduced to a flat low sliver with no trees, and a thin grey strip runs above the sea. | None. |
| 12 | Water, Drowned Garden terraces, day | **X** | X: a tall rock mountain at left and a dune island at right. **Y: both are missing; a wide flat grey band separates the sea from the sky.** | None. |
| 13 | Water, Drowned Garden beach, day | **X** | X: rock mountain and distant dune islands. Y: both are missing, and a faint grey strip sits above the water. The creature also differs (X a blue seal-like creature, Y a turtle), which is a spawn or state difference. | None. |
| 14 | Water, Tidal Cradle basin, day | same | The geometry is identical. The creature at the far end differs (spawn or state). | The camera is in a narrow sand canyon; mostly sand walls and a sliver of sky. |
| 15 | Water, Tidal Cradle saddle camp, day | **Y** | Y: a rock mountain and a sand island on the sea. **X: neither; a thick hard flat grey band fills the horizon above the sea.** | The player pose looks like sliding or falling on a steep slope. |
| 16 | Water, Veilfall cascade, day | same | Both are heavily fogged; Y is marginally more washed out. | Fog whiteout hides the scene and the player is barely readable. |
| 17 | Water, Veilfall mountain crown, day | same | Both show a grey horizon band through a gap; the band is harder-edged in X and softer in Y. | **The camera is blocked by huge, flat-shaded pink geometry** (creature or rock) filling about 70% of the frame. The grey band sits above the grass on both sides. |
| 18 | Meadows route 00, day | **Y** | Y: distant mountains at the end of the village street. X: plain sky there. | None. |
| 19 | Meadows route 00, night | **Y** (slight) | Y: faint mountain silhouettes at the end of the street. X: none. | The player's hair and backpack are over-bright orange against the night lighting. |
| 20 | Meadows route 01, day | **Y** (slight) | Y: distant mountains behind the village hall at right. X: plain sky. | None. |
| 21 | Meadows route 01, night | **X** (slight) | X: mountain silhouettes behind the hall. Y: none. | None. |
| 22 | Meadows route 02, day | same | Identical. | The doorway interior is a flat, untextured cream plane. |
| 23 | Meadows route 02, night | same | Identical. | The same flat doorway interior. |
| 24 | Meadows route 03, day | same | The floating world-space sign label at the left differs in orientation or legibility (X shows garbled "boowm…", Y shows "The Stor wood"). Otherwise identical. | Flat dark-blue door planes; floating world-space text labels ("Sealed", "The Stormwood") clip into the walls. |
| 25 | Meadows route 03, night | same | The same label difference as in pair 24. | The same as pair 24. |
| 26 | Water route 00, day | **Y** | Y: a rock mountain behind the island and a large dune at the far left. X: neither, just sky behind the island. The creature pose differs (state). | None. |
| 27 | Water route 00, night | **X** | X: the rock mountain behind the island and a dune at the far left. Y: both missing. | None. |
| 28 | Water route 01, day | same | Same horizon; the creature pose and position differ (state). | None. |
| 29 | Water route 01, night | same | Same; creature differences only. | None. |
| 30 | Water route 02, day | same | Same; creature differences only. | None. |
| 31 | Water route 02, night | same | Same; creature differences only. | None. |

## Summary

- **X better: 10** (00, 02, 04, 05, 08, 11, 12, 13, 21, 27)
- **Y better: 8** (06, 07, 10, 15, 18, 19, 20, 26)
- **Same: 14** (01, 03, 09, 14, 16, 17, 22, 23, 24, 25, 28, 29, 30, 31)

Neither build is consistently better. Each build is missing distant landmarks in scenes where the other has them.

## Pairs with a flat grey or white band between the world and the sky

- 00, **Y**: a flat pale-grey void replaces the cloud sea and islands.
- 02, **Y**: a featureless flat white plain/band at left.
- 04, **Y**: a pale haze void where the cliffs and spires were (soft).
- 05, **Y**: a grey haze void beyond the grass crest.
- 10, **X**: a hard grey band above the sea.
- 11, **Y**: a thin grey strip above the sea (mild).
- 12, **Y**: a wide hard grey band above the sea.
- 13, **Y**: a faint grey strip above the sea (mild).
- 15, **X**: a thick hard grey band above the sea.
- 17, **both**: a grey band; harder in X.

## Problems on one side only (possible regressions; direction unknown)

**Missing in Y but present in X:**
- Cloudreach cloud sea, islands and spire (00, 02).
- Windscar cliffs and spires (04, 05).
- Meadows mountain range and castle (08), and night mountains (21).
- Water mountain and islands (11, 12, 13, 27).
- Grey or white bands appear in Y in 00, 02, 04, 05, 11, 12 and 13.

**Missing in X but present in Y:**
- Meadows village mountains (06, 18, 19, 20) and the forest peak (07).
- The Deep Watch island (10), the Tidal Cradle mountain and island (15), and the First Shore mountain and dune (26).
- Hard grey bands appear in X in 10 and 15.

**Other one-side differences (likely state, not rendering):**
- Creature species or pose differs in 13, 14 and 26–31.
- The floating sign label renders differently in 24 and 25.

No black voids or missing-texture shapes appear on one side only.
