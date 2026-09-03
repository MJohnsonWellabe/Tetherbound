# Corridor Visual Parity — Round 9 Judgment

Blind visual review. Inputs: `round9/13-*.png`, `round9/14-*.png`, `round9/_sheet_prev_vs_r9.png`, `round8/*.png` (previous), `round6/*.png` (full 16-station route, latest per station: 01–06,09,11,12,15,16 from round6; 07 from round8; 08,10 from round7; 13,14 from round9), against `docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`.

## Per-station verdicts

### Station 13 — band4-entry-bend-day — **FAIL** (unchanged from round8 on the tested criterion)

Measured the rightmost 10% of the frame (x=1152–1280 of 1280px) directly, and again the rightmost 35% for context, in both round8 and round9. In both versions, canopy/trunk cover occupies only the left portion of that 35% strip (roughly x=830–950, ending well before x=1152) and then stops — the true rightmost 10% is **100% sky and grass, 0% vegetation**, identical in shape between round8 and round9. What changed between rounds is that the existing mid-right tree cluster (centered around x=750–900) got a few taller/denser canopy shapes and one added trunk — a real improvement to that cluster's fullness — but nothing was placed further right, so the frame's actual right edge is exactly as empty as it was in round8. The stated goal ("right edge of the frame filled with canopy/trunks") is not met.

### Station 14 — ridge-camp-approach-day — **PASS**

Zoomed the camp cluster (crates/barrels, sacks, a lit campfire with visible flame glow, a dark bench/stump-like seat, and a tan tent) and confirm a standing humanoid figure in dark/purple-toned clothing beside the crates — consistent with a Team Tether grunt posted at the camp. The player is bottom-center-left of frame (roughly x=620/1280), close enough to read as bottom-centre. A grey foreground rock and a foreground plant sit at bottom-left, breaking up what was a flat hillside in earlier rounds. Checked all four frame edges at full resolution: no prop, limb, or tent corner is cut off. This station is legible as a camp, not a bare field, and is a genuine improvement over round8 (round8 already had most of these elements; round9 adds the foreground rock/plant and a brighter, more distinct fire).

One softer note, not a fail: the "log seat" called for in the brief reads ambiguously — the dark object beside the grunt looks as much like a low table/stump as a seat. Crates, sacks, tent, fire, and the grunt are all unambiguous; the seat is the one element I would not bet on without the source scene.

### Regression sweep (13, 14)

No regressions observed. Palette, lighting direction, ground-plane values, and prop styling are consistent between round8 and round9 for both stations; nothing new is clipped, floating, z-fighting, or discolored. Station 13's mid-right tree cluster is a strict addition (denser/taller), not a replacement, so nothing that read correctly before now reads worse.

## Whole-route verdict (16 stations, latest render of each)

The route does read, station to station, as a single composed walk rather than sixteen unrelated screenshots: the path, wildflower scatter, and toon-shaded oak silhouette are consistent throughout, and there is a real per-band character shift — 01–05 open fenced meadow, 06–08 a stone-and-root passage with rock outcrops and a dense oak corridor, 09–10 a tree-avenue stretch, 11 the Team Tether relay ruin, 12 a mill/water crossing, 13–14 upper open ridge meadow with a camp, 15–16 stronghold approach with smoke and the Hall gate visible. Most stations (01, 02, 06, 07, 08, 10, 12, 14, 16) carry a real foreground/mid/background split — a fence, a rock, a signpost, a tent, a gate — so the frame is not just grass to the horizon.

**Three weakest stations, ranked:**

1. **11-relay-day** — the weakest frame in the set. The ground is a flat, overexposed white/sand plane with almost no grass or wildflower cover (a sharp, unexplained texture break from every neighboring station), the sun disc is blown out to a featureless white blob eating a large chunk of sky, and the only "landmark" content — the black tech-pylon structure and NPC cluster — sits low and small against all that empty pale ground. It reads as an unfinished or placeholder lighting/ground pass, not as a designed Team Tether relay site.
2. **09-river-lock-entry-day** — the name promises a river lock; the frame shows neither river nor lock, just another tree-lined path avenue that is hard to distinguish from stations 06–08 around it. As the one station whose name commits to a specific landmark it doesn't deliver, it is a legibility gap in the route's own logic, not just a density complaint.
3. **13-band4-entry-bend-day** — even after two rounds of targeted fixes, the right ~35% of the frame is still open grass and sky with nothing in it (see Station 13 verdict above). Of the sixteen stations it is the one that most reads as "half-composed": trees crowd the left-of-center third, the right two-thirds is a featureless slope.

Everything else clears "not a featureless field," though several (04, 15) lean on grass-and-flowers alone without a hard landmark and would be the next tier down if a fourth were named.

## Regression sweep, whole route

No cross-station regressions found — round7/round8/round9 overrides (07, 08, 10, 13, 14) are all consistent in palette and prop language with their round6 neighbors; nothing that previously read correctly has broken.

## Score against reference art

Comparable to round8's "partial / lean yes," **not advanced by this round**: station 14 is now a clear pass and would have moved the needle, but station 13 — the round's other named target — did not land on its stated criterion, so the round's net effect on the route is smaller than two "fixed" stations would suggest. The route's authored, place-specific composition holds up in most bands; the relay station and the still-empty right side of 13 are what keep it from "yes."

**A. Do these frames read as belonging to `tetherbound-meadows-keyart.png`'s world?** **Yes**, for most of the route — rolling hills, oak groves, wildflower meadow, dirt path, blue sky with soft clouds are all present and consistent with the board's "Meadows Biome" panel and its "Rolling Hills / Streams & Ponds / Oak Groves / Wildlife / Settlements" icon row. The relay station (11) is the exception: its blown-out sun and bare pale ground do not match any panel on the board, including the board's own Team Tether stronghold panel, which is grounded, textured stonework rather than an overexposed white plane.

**B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?** **No.** The toon-shaded tree silhouette language is genuinely close to Palworld's (compare station 08 or 12 to `palworld-02-open-field-path.jpg`), and where the corridor places a tent/fire/crate camp (14) or a signpost/banner (10) it reads as a lived-in world, matching Palworld's habit of never leaving a frame truly empty. But most Palworld reference frames carry at least one creature or NPC cluster with visible action, denser ground-cover, and a value range with real shadow depth; across these sixteen stations creatures/NPCs appear only at 11 and 15, and several stations (04, 09, 13-right-half) are still walking-sim empty in a way none of the five Palworld references ever are.

**Fixable by changing the scene** (no new art needed): station 11's ground texture/exposure, extending 13's tree line to the true right edge instead of stopping mid-frame, giving 09 an actual water/lock landmark prop, and scattering more wildlife/NPC presence along the quieter bands (01–05, 09) the way 10/14 already do.

**Not fixable by scene changes alone:** the volumetric depth and painterly shadow falloff Palworld's real renderer shows (this survey runs on the software Compatibility path per the visual-judge skill's known limits) and the sheer creature/NPC density Palworld defaults to, which — per CLAUDE.md's no-new-creature-mesh constraint for Meadows — would need to come from placing the *existing* creature roster into these corridor stations, not new art.

## Recommendation

**NEXT ROUND** — station 14 is accepted as-is; station 13 needs another pass that actually reaches the frame's right edge (not just denser mid-frame canopy), and station 11 should be flagged as the route's worst offender even though it wasn't in this round's scope.
