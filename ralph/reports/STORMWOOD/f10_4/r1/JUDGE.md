# Stormwood f10_4 r1 — Visual Judge

## Criterion-specific read

**1. Forest — deep old storm forest, not open parkland?**
**No.** `forest_calm`, `forest_break`, `forest_aftermath_calm` all read as an open meadow clearing at a forest edge, not a deep old-growth interior. Two oversized black-silhouette trunks sit hard against the near-camera edges (left and center), but between and above them the frame is dominated by open purple sky (well over half the frame in `forest_calm`) and a flat flower meadow running to a visible cottage and dirt road in the middle distance. There is no closed canopy, no continuous mid-story, and no forest floor litter — just meadow grass and lavender flowers identical to the ones used in the Meadows biome board. This is a clearing with two big trees framing it, not a forest.

**2. Giant trunks — is a giant old trunk clearly the subject?**
**No for `giant_calm`/`giant_break`/`giant_aftermath_calm`; yes for `stormheart_calm`/`stormheart_break`/`stormheart_aftermath_calm`.**
The "giant" column shows an avenue of ordinary, human-scale trees (trunk width roughly 1–1.5× the trainer's shoulders, canopy maybe 4–5× his height) lining a dirt path — indistinguishable from generic forest dressing, nowhere close to the Stormheart board's colossal, region-visible trunk. Nothing in these three frames is bigger than "big tree," and nothing reads as the ancient, storm-split landmark the chapter is named for.
The "stormheart" column, by contrast, does land this: the camera sits inside a canyon formed by two immense bark-textured trunk faces that dwarf the trainer, with a floating crystal energy-line threaded between them — this genuinely reads as being inside a giant tree, in the spirit of the interior-view boards.

**3. Glass scars — readable as scars in the land?**
**No.** `glass_calm`, `glass_break`, `glass_aftermath_calm` show a cluster of pale cyan crystal spikes standing in ordinary, undisturbed green grass, plus a tall grey tower-like silhouette in the background. Nothing about the surrounding terrain is scarred, scorched, melted, or discolored — the grass right up to the base of the spikes is the same healthy meadow grass as everywhere else. These read as a cluster of crystal-prop decoration or a spawn nest for the two dark creatures beside them, not as "glass-fused scars in the land."

**4. Rod line — readable as a destination line?**
**No.** `rod_line_calm`, `rod_line_break`, `rod_line_aftermath_calm` each show exactly one rod scaffold, positioned directly behind the trainer's head, partially occluded by it, with nothing else of its kind anywhere else in frame. There is no second, third, or receding rod visible toward the horizon, so there is no "line" to read — a viewer has no way to tell this is an infrastructure trail rather than a single one-off prop.

**5. Restored sky — same place, lighter rain, no lightning, scars remain, distinct from storm columns?**
**Mostly yes for forest/giant/glass/rod_line; not verifiable for stormheart.** In `forest_aftermath_calm`, `giant_aftermath_calm`, `glass_aftermath_calm`, and `rod_line_aftermath_calm` the sky is visibly lighter purple with clearer cloud shapes, rain streak count is visibly reduced (most obviously in `giant_aftermath_calm`, which has only 1–2 rain streaks versus a dozen-plus in its calm/break siblings), the purple sky is retained (not blue), and the standing set-dressing (spikes, rod, cottage, creatures) is unchanged, so the "same place, storm lifted" read does work for these four locations.
`stormheart_calm`/`break`/`aftermath_calm` are near-identical to each other — the interior camera shows almost no sky (a sliver of purple at the frame edge, unchanged across all three), so this location gives no evidence either way that the storm has lifted.

## Full verdict

### Specific, addressable defects by frame

- **`forest_calm`/`forest_break`/`forest_aftermath_calm`** — open sky occupies roughly half the frame in a location meant to read as forest interior; no midstory or forest-floor detail beyond one fern clump; a lit cottage and dirt road sit in plain view in what should be deep woods, collapsing the forest/settlement distinction. The lightning-veined creature by the cottage is the most interesting element in the shot but is small, dim, and half-hidden behind foliage.
- **`giant_calm`/`giant_break`/`giant_aftermath_calm`** — the named subject of the shot (a giant trunk) is absent; all visible trees are ordinary background-forest scale. The composition (a straight dirt path flanked by evenly spaced trees) also reads as an authored "avenue," which undercuts the wild, ancient-forest feel the chapter wants.
- **`glass_calm`/`glass_break`/`glass_aftermath_calm`** — crystal spikes have no scarring or ground disturbance around them. `glass_break` additionally has a bright magenta/hot-pink glowing ring effect at the bottom of frame (around the trainer's feet) that does not match the chapter's stated "white-violet lightning" palette at all — it reads as a stray ability or UI effect bleeding into the world shot rather than storm weather.
- **`rod_line_calm`/`rod_line_break`/`rod_line_aftermath_calm`** — single rod is half-occluded by the trainer's own head/hair in all three frames — even considered alone (not as a line), it is poorly composed. Two small golden creatures sit in mid-ground doing nothing legible.
- **`stormheart_calm`/`stormheart_break`/`stormheart_aftermath_calm`** — the strongest set of the three states for scale, but `calm`, `break`, and `aftermath_calm` are visually almost indistinguishable from each other (same rain density, same lighting, same crystal-line animation state), so the intended state changes (storm intensifying, then lifting) do not read here at all. The scene is also very empty for what the boards show as an actively-climbed, populated ascent (multiple bridges, banners, torches, lightning core) — this is a bare corridor with one small platform.
- **General, all frames** — the chapter intent explicitly says "little direct sky until the aftermath," but every calm/break frame here already shows large amounts of open sky (forest, giant, rod_line especially), so the calm/break vs. aftermath contrast the brief calls for is muted rather than a clear "before/after."
- **General, all frames** — no frame shows an actual lightning bolt/flash in the sky in either "Calm" or "Break," despite "white-violet lightning" and "lightning stops [after release]" being the chapter's headline signature. The only "electric" cues in the whole set are the crystal line inside Stormheart and the veined creature in the forest shot — nothing in the sky itself.

### The three things that most separate these frames from the references, ranked

1. **No giant landmark tree in the world-scale "giant" views.** The Stormheart board's entire premise is a colossal tree visible across the region, "the destination," rivaling a mountain in scale. `giant_calm/break/aftermath_calm` show only ordinary forest trees — the single most identity-defining image in the chapter is simply missing from the set that is supposed to show it off (the interior `stormheart_*` frames prove the giant-scale trunk asset does exist and reads correctly when framed against it, which is why this looks like a camera/placement gap rather than a missing asset).
2. **No visible lightning, ever.** Both boards and the quoted chapter intent center this biome on visible white-violet lightning during the storm, stopping at release. None of the fifteen frames shows a bolt, flash, or sky-level electrical event — the storm is conveyed only through rain and purple cloud color, which is a much weaker and less specific signal than the reference material promises.
3. **Shallow, foggy world depth with no sense of scale-from-distance.** Every reference (the Stormheart boards' "visible across the region" framing, and Palworld's `palworld-04-plateau-landmark.jpg` with its readable spires on the horizon) sells scale by letting a landmark recede into a legible distance. Here, haze/fog closes off the view within roughly 40–60 m in every frame; the "giant" and "rod line" destinations sit close and small rather than looming, so nothing in this set earns the "landmarks visible from distance" identity trait the project's own bible calls out.

### Bar A — `tetherbound-meadows-keyart.png` + Stormwood boards: do these read as belonging to the world?

**No.** What carries it: the trainer model, backpack, meadow flowers, and grass card style are visibly the same asset family as the Meadows key art, so nothing here looks like it wandered in from a different game. What sinks it: the two things Stormwood is explicitly sold on in its own boards — a landmark-scale ancient tree visible from a distance, and a sky full of visible lightning — are absent from the exterior world frames, so the frames read as "purple-tinted meadow" rather than "the Electric Forest's colossal, storm-split Stormheart." The chapter's stated identity ("little direct sky until the aftermath") is also contradicted by how much open sky is already visible in the calm/break frames.

### Bar B — `palworld-0*.jpg`: same kind of game?

**No.** What carries it: meadow grass/flower density on the ground plane is reasonably close to Palworld's ground cover, and the trainer's readability against the ground in the mid-distance shots (`giant_*`, `rod_line_*`) is acceptable. What sinks it: Palworld's shots consistently sell an "event" — a boss creature filling a third of the frame with clear silhouette, sparks, and combat readability, or a landmark spire cutting the horizon (`palworld-04-plateau-landmark.jpg`). Here the low, flat, near-monochrome purple lighting pulls contrast and saturation down across the board, so the creatures present (the veined bear/wolf, the spider, the golden lizards) sit at low visual priority — small, dim, and easy to miss on the contact sheet — rather than reading as the point of the shot the way Palworld's Pals do.

### Split: scene-fixable vs. needs-new-art

**Scene-fixable:**
- Re-aim/re-place the "giant" viewpoint camera at the actual giant Stormheart trunk (proven to exist and read correctly in the `stormheart_*` frames) instead of an avenue of ordinary trees — placement/camera.
- Add a lightning-bolt/flash VFX to the sky during storm Break, and confirm it is absent in Aftermath — VFX authoring against an existing rain/weather system.
- Reposition the rod scaffold(s) so at least two or three are visible receding toward the horizon, none of them occluded by the trainer's own head — placement/composition.
- Reduce fog/haze far-plane distance (or add a silhouetted midground layer — distant hills, a second rod, the Stormheart silhouette) so distance and scale can read the way the boards' "visible across the region" framing intends — fog/camera tuning.
- Add a scorched/glass-fused ground decal or tint under and around the crystal spikes so they read as scars rather than clean-grass crystal props — terrain decal/tint, assuming a suitable material already exists in the project.
- Recheck/remove the magenta ring effect in `glass_break` (or recolor it toward the white-violet palette if it is an intended state-transition cue) — VFX/palette fix.
- Increase differentiation between Calm and Break beyond rain-streak count alone (e.g., darker cloud value, wind-bent foliage) so the two aren't near-duplicates of each other, most visible in the `stormheart_*` trio.

**Needs-new-art (only if the scene-fixable route above turns out not to be available):**
- If no scorched/glass-melt ground material exists anywhere in the project, the glass-scar read would need a new decal/texture rather than a placement fix.
- If no lightning-bolt VFX asset exists at all, "visible lightning" would need new VFX work rather than a settings/placement change.
- Creature art (the veined bear/wolf, spider, spined creature, golden lizards) could not be fully judged at the sizes and lighting shown here — they are too small, dim, and distant in every frame to assess bespoke appeal one way or the other; a follow-up pass with at least one closer, better-lit creature frame is needed before that question can be answered honestly.

## TOP FIXES

1. **Reframe the "giant" viewpoint on the actual giant Stormheart trunk**, matching the boards' "front view" framing where the colossal tree fills and dominates the shot, instead of an avenue of ordinary trees. Frames: `giant_calm`, `giant_break`, `giant_aftermath_calm`.
2. **Add a visible lightning bolt/flash in the sky during storm Break**, absent in Aftermath, so the chapter's headline "white-violet lightning" signature actually appears somewhere in the world rather than only being implied by a creature's fur pattern. Frames: `forest_break`, `giant_break`, `glass_break`, `rod_line_break`, `stormheart_break`.
3. **Place a receding line of two or three rod scaffolds toward the horizon**, none of them occluded by the trainer, so the shot reads as infrastructure pointing at a destination rather than one prop caught behind his head. Frames: `rod_line_calm`, `rod_line_break`, `rod_line_aftermath_calm`.
