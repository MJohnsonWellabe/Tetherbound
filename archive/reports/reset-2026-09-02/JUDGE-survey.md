# Tetherbound Meadows visual survey — critique

Renderer caveat: these frames are from the Compatibility renderer under software GL. This critique judges composition, silhouette, colour relationships, scale, and geometry only — not fine lighting quality, shadow softness, AO, or post-processing.

No creature is visible in any of these five frames. That is itself a defect worth flagging up front: the rubric requires judging creature/character art as the game's look, and there is simply nothing to judge here except the trainer and one NPC (Grandpa). A Meadows survey with zero pals on screen cannot show whether the game clears the Palworld bar on the single thing that bar is most about.

## Per-frame defects

**01-spawn-outward.png**
- Silhouette: the two big grey boulders read as rock only because of position/scale, not shape — they are smooth, featureless blobs with no fracture planes or moss variation, and they visually compete with the fence posts behind them rather than anchoring the frame.
- The near flower-bush prop (screen centre, sitting in cast shadow) has an oddly wide, symmetrical bushy silhouette that reads as a generic scatter-mesh, not something authored to sit precisely there.
- Value structure: the giant hard-edged shadow wedge across the whole lower-left/centre of frame is one flat near-black shape with a razor-sharp diagonal edge — it reads as a rendering artifact (a single shadow-caster cutting a clean line across open ground) rather than dappled natural shade.
- Grass card billboarding is visible as vertical planar streaks with almost no blade taper — dense but flat, closer to fur-texture-on-a-lawn than Palworld's textured turf.
- Trainer and Grandpa are both static back-facing mannequins with no readable interaction; Grandpa's proportions (very wide coat, small head) read stylised-old-man, which is fine, but he is placed floating slightly ahead of his own shadow footprint.

**02-valley-floor.png**
- Scale disagreement: the central boulder is enormous relative to the trainer figure visible at left-mid-ground — by eye it is close to 3–3.5 trainer-heights tall, while the trees directly behind it are barely 1.5x the boulder's height. Boulder-to-tree ratio looks wrong next to a person-scale reference.
- The foreground shrubs/bushes (bottom third of frame) are uniform in height, spacing and silhouette — same model repeated at regular intervals, reading as scattered-by-formula rather than authored clearings.
- The dark rock mass has zero surface variation (no crack, lichen, colour break) and its flat charcoal value sits oddly against the warm green/gold field — it's the darkest, flattest object in the frame and pulls focus without earning it.
- Background village rooftops (left-mid) are a muddy pink-brown blob smaller and less legible than the boulder in front of them — landmark hierarchy is inverted from what the key art does (settlement should read as the eye-catching landmark, here a rock does).

**03-rise-overlook.png**
- Fog is eating the world rather than aiding depth: from roughly one-third into the frame outward, everything (grass, hills, sky) collapses into the same pale grey-green wash. There is no visible horizon line — sky and ground blend into a flat band with no gradient transition.
- The distant village is a tiny, low-contrast cluster of a few roof shapes — it does not read as a landmark at 30% size (fails the small-size legibility check directly).
- Foreground rocks (bottom right) are the only objects with real value contrast in the shot, which makes the whole composition front-loaded and empty behind it — the opposite of the key art's rune-stone-in-front / landmark-behind vista structure.
- Patchy dead-yellow/moss texture on the hilltop reads as a texture-blend seam more than a deliberate ground material change; the patches are irregular blobs with hard edges, not an authored transition.

**04-three-quarter.png**
- This is the strongest frame of the five: legible cottage silhouette, a clear near/mid/far read, warm roof-red popping against green. Still: the trees flanking the house are near-identical canopy shapes and heights, planted at even intervals — reads as a placed row, not a windbreak that grew there.
- Grass in the foreground two-thirds of frame is dense but a single uniform mid-green value with no colour variation — no wear paths, no patchiness, no visual break to lead the eye toward the house.
- Two dark shapes at bottom-left/bottom-corner (partial creature or prop silhouettes, heavily cropped) are unreadable — if those are pals, they are being wasted as unrecognisable dark blobs at frame edge.

**05-spawn-low-sun.png**
- Same composition as frame 01 at a different time of day — useful for checking time-of-day consistency, and it mostly holds: sun position, warm rim light, and moon disc are all coherent and this is the one frame with genuine lighting mood.
- But the terrain and props sit in near-total shadow (the boulder, the fence, the trainer's legs) while the sky and clouds are fully lit — the falloff between lit sky and unlit ground is too steep for a low-sun (not night) setting, so the ground reads almost as a silhouette scene rather than a lived-in valley at dusk.
- Same shadow-wedge artifact as frame 01, now doubled in visual weight since the whole ground plane is darker — the hard diagonal shadow edge is even more prominent and reads as a clipping/culling artifact.

## Cross-frame consistency

- Palette does hold together across all five: the greens, the tan fences, the grey rock are the same asset set reused, which is good — no discontinuity like "one frame is a different biome."
- Grass density is consistently high (good, matches Palworld's ground-cover density) but consistently flat-toned — no colour breakout for flowers/weeds beyond a few scattered white blossoms, versus the key art's varied wildflower carpet.
- The recurring dark, featureless boulder appears in three of five frames (01, 02, 05) and is the single most repeated defect: same low-poly, flat-shaded rock, same size, used as the primary midground landmark in three different shots. It reads as the placeholder rock, not an authored feature.
- No creatures anywhere in the set — five frames of a creature-training game and the survey shows zero pals, zero combat, zero taming interaction.

## Three biggest gaps vs. the references, ranked

1. **No creatures in any frame.** The bar (Palworld) and even the key art centre every reference shot on a pal — riding one, fighting one, standing beside one. All five Tetherbound frames are empty grassland with at most the trainer and one human NPC. This is the largest gap and it isn't a lighting or scatter problem — it's simply absent content in this survey. (all frames)
2. **Landmarks don't carry distance.** Palworld's plateau shot (04) and the key art's sunset-shrine shot put a strong, legible silhouette (tower, mountain, rune stone) on the horizon that reads instantly even small. Tetherbound's 03-rise-overlook.png has a village so small and fog-desaturated it barely survives full-size viewing, let alone 30%. (03-rise-overlook.png, weaker also in 02-valley-floor.png)
3. **Flat, repeated hero-scale rocks standing in for authored set dressing.** The same featureless dark boulder recurs three times as the closest, largest object in frame, with no surface detail and an outsized, physically ambiguous scale next to the trainer. Palworld's rock formations (01, 04) have visible strata, colour variation and are integrated into cliffs/paths, not planted as isolated singular props. (01, 02, 05)

## Bar questions

**A. Do these frames read as belonging to the world in the key art?**
No. The palette and general "rolling hills, oak groves, wildflower meadow" premise is present and recognisable, but the key art's atmosphere comes from painterly depth (layered haze, warm directional light, dense tree canopies, an animal companion beside the trainer) — none of which survives here. The grass and props read closer to a generic low-poly asset pack than to the stylised-realism board. What carries it: consistent palette and the correct broad landform (rolling hills, fences, a cottage). What sinks it: flat fog-choked distance, a single repeated boulder prop standing in for landmark variety, and no companion creature anywhere.

**B. Shown these frames beside the Palworld references, would someone say these are trying to be the same kind of game?**
No. Palworld's shots are built around a fight, a mount, a base, or a squad of pals in motion; every one of them has at least one creature filling 15–30% of the frame with a distinct silhouette. Tetherbound's frames are empty pasture. Without a creature, a combat moment, or a base-building scene in the set, nothing here is "trying to be" the same genre from a still image — it reads as an exploration/walking-sim screenshot. What carries it: ground density and general greenery are in the right ballpark. What sinks it: the complete absence of the thing (creatures, taming, combat, base) that defines Palworld's screenshots.

## Fixable-by-scene-change vs needs-art-not-in-build

**Fixable by changing the scene/survey (no new art needed):**
- Populate the survey with pals: place at least one creature in frame for several of the five shots — this alone would materially change both bar answers.
- Reduce/breakup the fog falloff and steepen the mid-distance so the village landmark in 03 reads as a shape at 30% size.
- Vary rock placement/rotation and stop reusing the identical boulder as the closest object in three different frames — use the existing rock library's other pieces, or cluster smaller rocks instead of one dominant blob.
- Break up the uniform grass tone with more flower/weed scatter and colour variance already available in the asset set (small addition, not new art).
- Re-check shadow-caster settings — the single hard-edged diagonal shadow wedge in 01 and 05 looks like an artifact and is very likely a scene/lighting-rig fix, not an art asset problem.
- Re-space the trees flanking the cottage in 04 so they don't read as an evenly-spaced planted row.

**Needs art not currently in the build:**
- Rock/boulder meshes with actual surface detail (cracks, strata, moss/lichen variation) — the current boulder is a smooth flat-shaded blob and no scene change fixes that.
- A distant landmark silhouette (tower, cliff formation, distinctive peak) strong enough to survive fog and small-size viewing, matching what both the key art and Palworld's plateau shot rely on.
- Any pal/creature model — the survey cannot show a pal that isn't in the scene, and per CLAUDE.md no new creature meshes are permitted for Meadows, so this is a placement/animation task with existing installed meshes, not a new-art task, but it is still absent from the current build state shown here.
