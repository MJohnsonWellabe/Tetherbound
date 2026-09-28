# F01 walk survey — code-blind visual judge verdict

Judged from images only (day set, night set, `tetherbound-meadows-keyart.png`, `palworld-0*.jpg`). No source, logs or docs opened beyond the rubric sections named in the brief.

## 1. Reach table

### Day (`day_99fc83f3`)

| Target | Frame | Reached? | Reason |
|---|---|---|---|
| Grandpa (indoors) | visits_day_003_reached-grandpa.jpg | YES | Interior bedroom, "Talk to Grandpa" prompt, named NPC adjacent to player. |
| Bram (inn) | visits_day_014_reached-bram.jpg | YES | Interior tavern, "Greet Bram" prompt, NPC behind counter. |
| Tam | visits_day_022_reached-tam.jpg | YES | "Greet Tam" prompt, NPC standing beside player outside a stone building. |
| Mira (shop) | visits_day_027_reached-mira.jpg | YES | Interior shop, "Greet Mira" prompt, NPC across counter. |
| Oskar | visits_day_034_reached-oskar.jpg | YES | "Greet Oskar" prompt, second child-NPC adjacent to player. |
| Halda | visits_day_042_reached-halda.jpg | YES | "Greet Halda" prompt, NPC beside player. |
| The old key | visits_day_050/051 | PARTLY | "Take the old key" prompt and Grandpa's confirming line are legible, but no key prop/mesh is visible — the pickup point is an unmarked wooden frame identical in style to the gate assets. Identifiable only through UI text, not through the object itself. |
| RoadGate | visits_day_054/055 | YES | Clear gate arch + fence, "Try the gate" prompt, Grandpa dialogue confirms it. |
| Practice Meadow camp | visits_day_070_reached-practice-meadow-camp.jpg | PARTLY | A barrel, a sack and a small frame are visible, plus a fading "NEXT: Practice Meadow" tooltip, but there is no tent, fire, banner or NPC that reads as an authored camp — and the frame is dominated by an extreme, unreadable creature-snout close-up that obscures the location itself. |
| TrailGate | visits_day_084_reached-gate-trailgate.jpg | YES | Same gate arch, "South Bridge" signpost, player positioned at it (only "Call out Bud" prompt shows, no "Try the gate" prompt, which is a minor inconsistency). |
| PondGate | visits_day_097_end.jpg | NO | This is the walk's last frame, not a "reached-gate-pondgate" frame. It shows the same generic, unsigned arch used for RoadGate/TrailGate, no water/pond feature, no gate prompt, and no on-screen confirmation of which gate this is. Nothing in the image identifies it as PondGate. |

### Night (`night_7fe6e703`)

| Target | Frame | Reached? | Reason |
|---|---|---|---|
| Grandpa (indoors) | visits_night_003_reached-grandpa.jpg | YES | Same interior, "Talk to Grandpa" prompt, legible despite dim palette. |
| Bram (inn) | visits_night_013_reached-bram.jpg | YES | Interior lit by warm lamps, "Greet Bram" prompt, NPC clear. |
| Tam | visits_night_021_reached-tam.jpg | YES | "Greet Tam" prompt, NPC legible against moonlit blue. |
| Mira (shop) | visits_night_026_reached-mira.jpg | YES | Interior shop, "Greet Mira" prompt, NPC clear. |
| Oskar | visits_night_032_reached-oskar.jpg | YES | "Greet Oskar" prompt; lit by a glowing hand-light, legible. |
| Halda | visits_night_040_reached-halda.jpg | YES | "Greet Halda" prompt, NPC beside player, second NPC visible behind. |
| The old key | visits_night_049/050 | PARTLY | Same issue as day: prompt/dialogue confirm it, but no key object is rendered — an unmarked frame in a flower field. |
| RoadGate | visits_night_053/054 | YES | Gate arch legible against night sky, "Try the gate" prompt, Grandpa's line confirms it. |
| Practice Meadow camp | visits_night_069_reached-practice-meadow-camp.jpg | PARTLY | Same crates/sack setup, "NEXT: Practice Meadow" tooltip, plus two creature outlines with a scan-highlight effect — readable as a supply cache, not a camp (no fire, tent or banner). |
| TrailGate | visits_night_082_reached-gate-trailgate.jpg | YES | Same arch, "South Bridge" sign, player at it. |
| PondGate | visits_night_096_reached-gate-pondgate.jpg | PARTLY | Filename confirms the reach and the player is at a gate arch, but the frame carries no distinguishing signage and no pond/water is visible anywhere in shot — nothing here reads specifically as "Pond" gate versus the other two identical arches. |

## 2. Criterion verdicts

**F01#2 (day): FAIL.** PondGate is not identifiably reached — the walk's terminal frame is an unlabeled arch with no gate prompt, no signage and no water feature, and even the harness's own naming ("end") stops short of claiming the reach. The old key and the Practice Meadow camp are also only weakly identifiable (UI text carries the location, not the geometry). A criterion requiring all 11 targets identifiably reached cannot pass with one target unconfirmed and two more only partly legible.

**F01#3 (night): FAIL.** All 11 targets are nominally reached per filenames and night still reads clearly as night (deep blue sky, moon, warm point-light pools) with NPCs legible. But PondGate, the old key and the Practice Meadow camp share the same identifiability gap as day — no distinguishing geometry, only UI prompts — so "identifiable," not just "reached," is not satisfied for three of the eleven targets.

## 3. Full visual bar

**Silhouette/readability (30% scale).** Tree canopies read as flat, angular polygon fans (visits_day_034_reached-oskar.jpg, visits_day_042_reached-halda.jpg) rather than volumetric masses — at small size they'd blur into green blobs, losing the tree/bush distinction the rubric asks about. Flowers/grass are hard-edged 2D cutouts with visible aliasing (visits_day_050, visits_night_050). Player silhouette against ground is fine (contrasting jacket/pack vs. grass).

**Colour/value.** Day frames are flat mid-tone with almost no cast-shadow contrast (visits_day_034, visits_day_042 — bright sky, near-shadowless ground). Sky is a plain gradient lacking the reference's cloud volume. Night frames have better local contrast from torches/lanterns. The gate arches (visits_day_055, visits_day_084, visits_night_054, visits_night_082) are a deep reddish-brown that reads close to the reserved Team Tether oxblood on neutral world structures — worth flagging for the art-direction owner, not asserted here as a confirmed rule violation.

**Intentionality.** Village buildings and NPC placement read as authored. Flower/grass scatter (visits_day_050, visits_night_050) looks close to evenly distributed rather than clumped — reads mildly procedural.

**Lighting.** Day is flat-lit with unclear sun direction (visits_day_034). Night lighting is the stronger of the two, using point lights effectively (visits_night_032, visits_night_040).

**Horizon/depth.** Distant mountains have reasonable aerial haze (visits_day_022), but mid-ground is mostly empty grass with little clutter — meadows read sparse rather than lived-in. No visible LOD pop or chunk seams in these stills.

**Interface.** HUD (health/food bottom-left, quest box top-right, minimap, quick-slots bottom-right) is legible and consistent across all frames; no complaints here.

**Artefacts.** visits_day_070_reached-practice-meadow-camp.jpg: an extreme, uncomposed creature-snout close-up fills half the frame, with visible texture seams on the snout — reads as a camera-clipping bug rather than an intended shot, and destroys readability of the camp itself. visits_day_034: canopy leaf clusters show hard clipping/overlap edges.

**Scale vs. the 1.80 m trainer.** No frame in this survey puts a full-body owned companion or wild creature cleanly beside the trainer at a readable distance — visits_day_070's boar is cropped to an extreme close-up that defeats any scale comparison. Buildings, doorways and fences read plausibly human-scaled next to the trainer. This survey cannot confirm or deny the "creatures taller than trainer" rule because no qualifying creature is framed for comparison — that is itself a gap in what this walk proves.

**Three things that most separate these frames from the references, ranked:**
1. Base geometry fidelity vs. the key art (`tetherbound-meadows-keyart.png`): the key art is painterly, lush and atmospheric; these frames use flat-shaded, angular, PS2-era-density tree/foliage geometry (visits_day_034, visits_day_042) and a washed-out sky with none of the key art's dramatic cloud/light work.
2. Density and "aliveness" vs. Palworld (`palworld-02-open-field-path.jpg`, `palworld-04-plateau-landmark.jpg`): Palworld's ground is carpeted in dense grass with roaming creatures and particle activity; these frames show sparse grass tufts over bare dirt (visits_day_003, visits_day_054) and static, empty meadows with no ambient creature life.
3. Creature/character bespoke quality vs. Palworld's Mammorest/Grintale (`palworld-01-boss-fight-forest.jpg`, `palworld-03-field-boss-meadow.jpg`): the one creature shown up close (visits_day_070) reads as a generic, low-detail placeholder, not an expressive bespoke design — and it is the only close-up creature shot in the entire survey.

**A. Do these frames read as belonging to `tetherbound-meadows-keyart.png`?** **No.** The composition intent matches (village near open meadow, wooden gates, wildflowers, day/night pairing) but the execution — flat lighting, angular low-poly foliage, washed sky — falls far short of the key art's painted richness (visits_day_034, visits_day_042 vs. the key art's oak-grove and settlement panels).

**B. Beside `palworld-0*.jpg`, same kind of game?** **No.** Palworld's frames are dense, saturated, busy with creature and particle activity and built around bespoke character/creature art; these frames are comparatively empty, flatter in value, and the one creature on screen (visits_day_070) does not hold up next to Grintale or Mammorest.

**Fixable by scene vs. needs new art:**
- Fixable by scene: grass/foliage density and mid-ground clutter; day lighting/shadow strength and sky grading; distinguishing signage or a water feature per gate so RoadGate/TrailGate/PondGate aren't the same unlabeled arch; a visible key prop at the old-key pickup; camp dressing (tent/fire/banner) at Practice Meadow; reframing the day_070 creature shot so it isn't an uncomposed clipping close-up; checking the gate wood colour against the oxblood reservation.
- Needs new art: the low-poly, flat-shaded tree/foliage geometry itself; the wild creature model shown in visits_day_070, which reads as placeholder-quality next to the Palworld bar this project set for itself.

## 4. Top 3 issues to fix first

1. **PondGate is never confirmed or identifiable in either time of day.** Day's walk ends at an unlabeled arch (visits_day_097_end.jpg, not a "reached" frame) with no sign, no gate prompt and no water; night's frame (visits_night_096_reached-gate-pondgate.jpg) is the same generic arch with no distinguishing feature. This is the direct cause of both PASS/FAIL failures above.
2. **All three gates share one unlabeled asset.** RoadGate (visits_day_055, visits_night_054), TrailGate (visits_day_084, visits_night_082) and PondGate (visits_day_097, visits_night_096) are visually identical, violating the "landmarks visible/identifiable from distance" bar — each needs distinct signage, colour or a nearby feature (e.g., water at PondGate).
3. **Asset fidelity gap on trees and the one creature shown.** The angular, flat-shaded tree canopies (visits_day_034_reached-oskar.jpg) and the uncomposed, low-detail creature close-up (visits_day_070_reached-practice-meadow-camp.jpg) are the frames furthest from both references and the ones most likely to read as unfinished to a player.
