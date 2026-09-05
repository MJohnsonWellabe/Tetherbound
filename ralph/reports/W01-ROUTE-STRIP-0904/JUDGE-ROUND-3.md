# Code-blind visual verdict — round 3, run 7 frames

Judge: a third `opus` sub-agent via the Agent tool, given only the run-7
`_sheet_route_strip.png`, the four run-7 PNGs, `docs/reference/` and
`.claude/skills/visual-judge/SKILL.md`, plus the note that these are llvmpipe
road frames in the Meadows with one fight and a 1.80 m trainer as the ruler.
It was told nothing about the earlier rounds, what changed between them, this
lane's existence, or what any answer would mean. The one addition to its brief
over round 2 was a direct question about the fight frame: do the two creatures
read as two separate animals or merge into one shape, and is the trainer
watching. Reproduced verbatim.

---

# Visual verdict — Meadows route strip (4 frames)

## 1. Defects, by frame

### `band1_00000m.png` (village edge)

- **The composition is a wall.** The right third is a single house at full brightness, cropped by both the top and right edges; the tree canopy is cropped by the top edge too. There is no sightline out of this frame in the direction the player is facing — every escape is blocked by building or canopy. The keyart's STARTING SETTLEMENT panel does the opposite: houses read as objects sitting *in* a space with sky and ground visible past them.
- **A second humanoid is hidden behind the creature.** A dark hooded/armoured figure stands at roughly x≈900, mostly occluded by the creature's rump and reading against the shadowed stone wall. I cannot tell if it is an NPC, a statue, or a scarecrow. It is the second most important object in the frame and it is unreadable.
- **The bare-dirt patch is a decal disc.** The mud blob at centre-left has a hard elliptical outer boundary with soft airbrushed mottle inside, no gravel, no rim vegetation, no worn edge. Grass cards stop dead at its boundary. It reads as a texture stamped onto the terrain, not as ground.
- **Ground cover is single blades on a grid.** The meadow is composed of (a) isolated thin vertical blades, essentially chives, standing alone with visible bare terrain between them, and (b) one three-leaf clover bush instance repeated at near-identical scale on an even scatter. No clumping, no height variation, no tall grass, no ferns, no second species. This is the most procedural-reading element in the set.
- **The distant treeline at left is a stamped row.** Same tree, same height, same tint, laid along the hill contour at regular intervals.
- **Value mismatch on the house.** The cream stone and pale timber are far brighter than anything else in frame and carry a different surface language from the terrain. It reads as an asset from another pack dropped in, not as a building lit by the same sun.
- **Isolated fence run.** The four-post fence at left begins and ends in nothing, enclosing nothing.
- **Possible terrain artefact:** faint straight diagonal lines are visible in the grass around x≈300–500, y≈430–480 — either a mesh/chunk seam or a decal edge. Worth checking on real hardware.

### `band1_00040m.png` (road, fences)

- **The road leads to nothing.** A dead-centre one-point perspective with the path running to a vanishing point on the horizon, and there is no object at the end of it. No windmill, tower, ruin, bridge, standing stone, or distinct hill. This is the single clearest miss against the board, whose every panel terminates a sightline with a landmark.
- **~35% of the frame is bare brown ground**, and the bottom-left of it is occupied by a loose wooden plank lying on the mud for no legible reason, one end floating above the terrain.
- **Three fence runs, none of which enclose anything.** They sit at three unrelated angles and each terminates in mid-air. The "gate" at centre is a fence segment with a gap in it — no hinge, no posts, no gate geometry. Rails clip through terrain in several places at left.
- **Two tree size classes, one species, evenly spaced.** No groves, no clustering, no undergrowth or shrub layer beneath any tree, no canopy overlap. Canopies are solid poster-paint spheres of one green with hard-edged leaf cards and no interior depth.
- **The rock outcrop at left mid-ground is a low-poly grey lump** with flat untextured facets. It reads as a placeholder collider.
- **No atmospheric depth.** Distant hills sit at the same saturation and value as the mid-ground and meet the sky on a hard line. Distance is conveyed only by size.
- **The clover bush is repeated in a near-regular line** along the right verge of the road at identical scale.

### `band1_00080m.png` (open road, hill)

- **The road is a huge, low-frequency brown smear.** The bottom half of the frame is one soft-edged mottled blob whose texture frequency is wildly coarser than the grass beside it. It is the ugliest single element in the set and it dominates the frame.
- **The lower half of the terrain has no form.** It is a flat plane; all apparent shading is texture mottle, not geometry. Nothing in the foreground has a silhouette.
- **A visible foliage density ring.** Grass and flower cards cut out abruptly at a radius roughly a third up the frame, leaving a bare band before the distant grass mesh resumes. A hard LOD/scatter boundary.
- **The trainer nearly disappears.** Dark brown/grey clothing against dark brown road with no separation of value or hue. At contact-sheet size only his hair and face register.
- **Wildlife reads as a spawn grid.** The white rabbits at right are identical, identically posed, and near-evenly spaced.
- **The hill at left is the frame's only landmark and it has no event** — no crag, no cliff face, no ruin, no path, no silhouette break. It is a green-grey mass with a few rock chips stuck to it.
- **Ambiguous props:** the brown lozenges at mid-left near the hill base could be boulders or fallen logs. I cannot tell which, at any size.
- **The distant right treeline is one instance repeated at one height** along the ridge.

### `band1_fight_galecrest.png`

- **The fight is not an event.** Same flat meadow, same flat midday light, no camera push, no dust, no impact spark, no ground disturbance, no motion smear. Palworld-01 and -03 sell contact with sparks, flash and a boss that fills a quarter of the frame; this is two animals standing on grass with UI over them.
- **Neither creature is fighting.** Terrapup is in a static seated idle. Galecrest is wings-out but planted and neutral. Nothing in either pose says combat.
- **The two creatures overlap and merge.** Terrapup's plated flank and Galecrest's raised near wing occupy the same pixels around x≈740–790, and there is no silhouette gap, no rim light, no value break between them. At full size they separate by hue alone; at contact-sheet size they read as **one** tan-and-blue lump.
- **The boss nameplate is a large opaque grey slab anchored dead centre-top.** It covers the rock landmark and a wide band of sky, has no portrait, no frame art, no texture, and its only type indication is a tiny "AIR ▲". It is the biggest single object in the frame.
- **Half the ability panel is dead.** Two of the four cells are disabled grey ("No orbs", and a greyed "Stone Rush"), the key glyphs read as placeholder boxes, and "Orbs 0" floats above with no icon. The player HUD bottom-left has an **empty brown square** where a creature portrait belongs.
- **The rock behind the creatures shows a dithered/stippled transparency pattern on its right face** and visible flat faceting. That reads as a bug, not a choice.
- **The trainer is parked at the frame edge and cropped.** He stands in left profile, back clipped by the frame boundary, separated from the combatants by an empty third of frame. He *is* facing the fight, but he reads as a bystander who wandered into shot.
- **The trainer's hair is flat card geometry** with hard planar silhouette edges, obvious at this size and beside two smoothly-shaded creatures.
- **Style incoherence between the two creatures.** Terrapup is soft, plush, low-detail, painted plates. Galecrest is a hard, feather-by-feather layered bird with a cooler palette and a much higher detail density. They do not read as designed by the same hand for the same world.

### Cross-frame

- **Scale note (the ruler):** measured against the 1.80 m trainer, the companion reads at roughly 2.5–3 m at the head in frames 2 and 3, and roughly the same in frame 1 — a beast of rhino-to-moose mass. That is internally consistent across the three route frames, and I am not judging whether the species should be that big. What I will flag: it is labelled "Terrapup, Lv 1", and nothing else in these frames establishes a size ladder — the wild Level 3 Galecrest is a fraction of its mass, so the frames give the viewer no read on what "bigger" means in this game.
- **Value range is compressed.** Every frame lives in a narrow band of yellow-green mid-tones plus warm brown, with the sky as the only bright value and nothing genuinely dark anywhere. The board's panels carry deep canopy shadow against sunlit clearing.
- **Palette discipline is good:** the frames plainly read as one place, and the reserved oxblood has not leaked onto anything friendly. Credit where it's due.
- **Cloud layer is a stretched, streaky low-res band**, identical across all four frames, most visible in frames 2 and 3.
- Contact anchoring is weak everywhere — nothing casts a shadow that places it on the ground. Under llvmpipe I will not call that a shading bug, but as delivered the characters and props look set on the terrain rather than in it.

---

## 2. The three things that most separate these frames from the references, ranked

**1. Ground-cover density, and how much of the frame is empty.**
`band1_00080m` is the worst case: half the frame is a smeared brown plane with isolated single grass blades on it. `band1_00040m` is nearly as bad. Palworld-02 and -03 fill the equivalent frame with continuous, layered ground cover — grass, weeds, low brush, scattered rock — so the terrain texture is never the thing you look at. moong-02 shows solid tall grass carrying right up to the camera. In these frames the terrain texture *is* the picture. Fixable by scene work.

**2. Nothing terminates a sightline; there is no landmark language.**
`band1_00040m` runs a road to a bare horizon. `band1_00080m` offers one featureless green hill. Every keyart panel — the settlement, the stronghold, the standing stone at sunset, the mountain valley — puts a built or monumental silhouette at the end of the view, and the board's own note is "silhouettes and landmarks visible from distance". Palworld-04 does the same with a plateau and a tower. Half fixable by scene (place what exists better); half needs assets that are not in these frames — the current tree is a single uniform lollipop and the only rock is a grey lump, so neither can build a keyart oak grove or a rocky landmark by placement alone.

**3. A fight does not look like a fight, and the cast does not hold one style.**
`band1_fight_galecrest`: two idle creatures on flat grass, merging into one shape at small size, with a grey UI slab over the only landmark. Palworld-01 and -03 make the encounter fill the frame and sell it with impact VFX and a character inside the action. Underneath that, the trainer, Terrapup and Galecrest read as three different asset families in three different levels of finish. The staging is fixable; the style cohesion is not — that needs art.

---

## 3. The two bar questions

### A. Do these frames read as belonging to the world of the keyart? — **No.**

**What carried it:** the palette is genuinely on-target — yellow-green meadow, warm dirt path, white wildflowers, blue sky with soft cloud; the four frames unmistakably read as one place; the timber-frame house in `band1_00000m` is on-family with the settlement panel; the oxblood is still reserved.

**What sank it:** the board defines the Meadows by four things none of these frames contain — **oak groves with layered canopy and dappled shade**, **streams and ponds**, **landmarks at distance**, and **value contrast between sunlit clearing and canopy shadow**. What is on screen is open pasture with evenly spaced identical lollipop trees, no water anywhere in four frames, no grove, no shade, and no landmark. `band1_00040m` is the clearest failure: the panel it should resemble is the one with the windmill at the end of the path, and it has a bare horizon instead.

*Fixable by scene changes:* clustering trees into actual groves with overlapping canopies; adding an undergrowth layer beneath them; clumping the grass and adding a second and third ground species with height variety; killing the decal-disc dirt patches and the smeared road; putting something — anything built — at the end of the `00040m` road; using terrain form instead of texture mottle for the foreground.

*Needs art not in the build:* a proper broadleaf/oak tree with interior canopy depth and more than one silhouette (the current tree cannot make a grove no matter how it is placed); a rock/outcrop asset that is not a flat-faceted grey lump; any water at all — stream bed, bank, water material; a distant-landmark asset family (windmill, tower, standing stone, ruin).

### B. Would someone say these are trying to be the same kind of game as the Palworld shots? — **Yes.**

**What carried it:** a human with an oversized stylised creature companion, on a bright open meadow path, with a named-and-levelled opponent nameplate, a type tag, an energy bar, an ability bar and a capture currency ("Orbs"). Nobody shown `band1_fight_galecrest` beside `palworld-03` would ask what genre it is. Galecrest specifically is a good, appealing, readable creature at combat distance.

**What is below that bar, and how it splits:**

*Fixable by scene/staging changes:* the fight staging (get the camera closer, separate the two combatants in depth so they do not merge, bring the trainer inside the frame rather than cropped at the edge, use combat poses rather than idles); the empty ground and low scatter density; the missing landmark; the HUD (the empty portrait square, the placeholder key glyphs, the flat grey nameplate slab covering the landmark, the panel that is half dead cells).

*Needs art not in the build:* combat VFX of any kind — Palworld's fights read as fights because of sparks, dust, impact flash and motion, and there is not one particle in this frame; creature and character style cohesion — Terrapup, Galecrest and the trainer are three visual languages, and Palworld's strongest single advantage is that its humans and its Pals are drawn by the same hand with the same eye language and surface treatment; the trainer himself — flat card hair, small features, muted proportions, no appeal beside the creatures he is meant to command. He is the character the player looks at for the whole game and he is currently the weakest asset in the set.

---

## 4. Per-frame: creature and trainer readability

| Frame | Creature present? | Readable at this size beside the trainer? |
|---|---|---|
| `band1_00000m` | Yes — Terrapup | **Yes**, the strongest creature read in the set: pale, large, high contrast against grass and against the dark house. But its rump is occluded by the building and a **second, dark humanoid is half-hidden behind it and is genuinely ambiguous** — NPC, statue or scarecrow, I cannot tell. Trainer present but small, back-to-camera, dark, and his right side touches the creature's muzzle, so at thumbnail size he partly merges with it. |
| `band1_00040m` | Yes — Terrapup | **Yes**, the best-isolated creature shot: full silhouette against sky and grass, no occlusion, clean read at every size. Trainer present but **too small** — roughly a sixth of frame height — dark-clad, and his silhouette abuts the creature's chin, so at contact-sheet size he is swallowed by the creature's front. |
| `band1_00080m` | Yes — Terrapup | Creature **yes**, still clean. Trainer **no — the weakest read in the set.** Dark brown/grey figure standing on a dark brown road with no value or hue separation and no rim light; at contact-sheet size he is effectively gone. The rabbits at right are white specks, not identifiable as animals. |
| `band1_fight_galecrest` | Yes — two: Terrapup and Galecrest | **They do not read as two separate animals.** Terrapup's plated flank and Galecrest's raised near wing overlap with no silhouette gap and no value break; at contact-sheet size they read as **one** tan-and-blue mass, and even at full size they separate by hue alone. **Trainer present and yes, he is watching** — left profile, facing the pair. But he is at the extreme left edge with his back cropped by the frame, at a different depth, with an empty third of frame between him and the fight. He reads as a spectator standing outside the shot, not a participant in it. |
