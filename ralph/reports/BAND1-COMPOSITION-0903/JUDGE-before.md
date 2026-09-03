# Visual judge — BAND1 composition, "before" (2026-09-03)

Sixteen frames judged blind against `docs/reference/`. No score. Every defect names its frame.

**Renderer caveat.** All frames are the Compatibility renderer under software GL (llvmpipe): composition, silhouette, colour relationships, relative scale and geometry are trusted; shadow softness, ambient occlusion, specular and any post-process are not, and nothing below is a frame-time judgement.
Where a shadow's *shape* or *edge* is called out it is because the edge follows terrain triangles or has no caster — that is geometry and placement, not lighting quality.

**The first thing to say plainly.** Sixteen frames from a creature-training game contain zero readable creatures. Four 5-pixel brown quadrupeds stand under trees in `place1-gate-meadow` and cannot be identified as a species. The trainer is the only character art on offer, and he is competent but never the subject. Every Palworld reference has a creature in it. That gap sits above everything else in this report.

---

## Set A — standing survey (`shots/`)

### A-01 `01-spawn-outward.png`

Defects
- A heavy, brown-coated figure stands roughly 1 m from the camera and is sliced to a torso sliver across the left 8% of the frame. Reads as a bug, not a framing choice. Recurs in A-05.
- A hard-edged dark olive region covers the lower-left third of the ground from the cropped figure to under the trainer. Sun is high (the crest boulders throw short shadows), so this is not a cast shadow; it reads as an unlit terrain patch with no caster.
- The two crest boulders are near-black faceted blobs with one flat lit face, no surface detail, no moss line, no contact shadow. The left one sits on the crest like a dropped prop.
- Fences are unweathered pale yellow, brighter than the grass. The key art's fences are grey-brown and darker than the field. Three fence runs sit on the crest at different angles with gaps between them — scatter, not enclosure.
- The right-hand cluster (a cart or crate, two hay-coloured slabs, a purple bush) is jammed against the frame edge and cut.
- Foreground (0–10 m): one flowering plant, centred low, in a field of identical 30 cm grass blades over a blotchy yellow-green ground. No tall grass, no bush, no stone.
- Distance (beyond 80 m): a flat pale-green plain with a warm-white fog band under a cool grey-blue sky; three or four tiny trees; no landmark, no village.
- Scale: trainer 1.80 m at ~15 m; boulders ~2.5–3 m; fences ~1.2 m; the white-haired NPC ~1.7 m. These agree. The dead tree at left (~4 m) is about the height of the boulder beside it, which reads wrong for a tree next to a rock.

(a) Eye lands on the two black boulders on the crest, centre, ~25 m. Second, the white-haired NPC right of centre at ~10 m, because his head is the brightest small thing. The trainer at centre is third.

(b) The frame asks for nothing. Foreground: one plant and a cropped NPC. Mid-ground: trainer, NPC, boulders, fence runs. Distance: an empty plain. The crest is a horizon line that blocks whatever the spawn is supposed to open onto; the three layers queue rather than stack.

### A-02 `02-valley-floor.png`

Defects
- One boulder fills the centre of the frame from ~40% to ~65% of the width. Against the trainer standing beside it (left, in shade) it is ~5–6 m tall. It is a smooth dark-grey wedge with a single flat lit face, no cracks, no moss, no debris at its base. The largest object in the frame is the least detailed.
- The trainer is ~15 m away, 3% of frame height, in the boulder's shade; barely readable.
- The trees behind the boulder are one species — red-orange trunk, flat lime-green canopy blobs — all ~10 m, standing at even intervals along a line.
- The distant hill at right is a pale grey-green mound with a speckled noise texture at the same frequency as the grass; no strata, no rock faces, no trees. It reads as a giant pebble.
- The same flowering plant repeats nine times across the foreground at similar spacing. The "red grass" patch at left-mid is the most saturated colour in the frame.
- The ground is a blotchy yellow-green noise with no path, although the stand is named "valley floor".
- Three red roofs at ~200 m, centre-left, tiny, with no road toward them.

(a) The boulder, centre, ~8 m. Second, the white-flowered plant, bottom-centre, ~2 m.

(b) It is asking you to look at a rock. Foreground: plants (0–8 m). Mid: boulder, trainer, tree line (8–40 m). Distance: mound and village. The layers do stack; the mid-ground subject is a blank shape and the distant landmark is a pebble.

### A-03 `03-rise-overlook.png`

Defects
- No trainer in frame; nothing gives scale except the village.
- The foreground summit is bare grey-tan terrain with mottled yellow-green grass patches. The "rock" here is a texture on a smooth heightmap, not geometry — no ledges, no faces.
- Five boulders in a loose ring on the summit: one rust-brown (a colour no other rock in any frame has), three grey, one blue-black. The same prop family in three palettes.
- The distant plain is a uniform green with a fine noise; roughly a third of the way down the frame the texture detail stops and the terrain goes to a bright pale-yellow band — a visible LOD or fog seam. Above it the fog (warm white) does not match the sky (cool grey-blue).
- A row of tiny dark rectangles hovers just above the horizon at roughly 20% of frame height, across the full width — far-distance impostors or props rendering as blocks. An artefact.
- The village (centre, ~300 m) is eight cottages with no windmill, no tower, no wall, no road in or out. The grey mound at left is a bare lump.
- Almost no trees on the plain. The key art's overlook panel structures its fields with oak groves, hedgerows and a winding track; here the plain is one texture.

(a) The village, centre, ~300 m, because it is the only warm colour. Second, the rust-brown boulder, centre-right, ~10 m.

(b) It asks you to look at the village — the right instinct — but the mid-ground (10–80 m) is an empty slope and the summit clutter competes. Foreground: summit and boulders. Mid: nothing. Distance: mound, village, fog. Roughly 80% of the picture is empty at a depth where the key art has groves and fields.

### A-04 `04-three-quarter.png`

Defects
- No trainer in frame.
- The lower 70% of the frame is a single green-yellow surface with tiny dotted flowers at an even density. Nothing stands between 0 and ~60 m except a tree trunk at the left edge.
- The framing tree at left: a bright flat lime canopy with no interior shadow on a saturated red-orange trunk. It looks sourced from a cartoonier game than the cottage it frames.
- Bottom-left: a pale grey-yellow lump (hay? stone?) cropped by the frame; unidentifiable.
- The cottage at centre on the ridge is the best-realised asset in the set (half-timber, red tile, chimney), but it is a tenth of frame height with no road, no yard, no wall, no smoke, and it is flanked by four identical trees at symmetric spacing.
- A grey speckled mound right of the cottage in the distance; two dark boulder blobs on the ridge.
- Mottled dark patches on the field with no directional shadow from the tree or the cottage.

(a) The red roof, centre, ~120 m. Second, the lime canopy, top-left.

(b) It asks you to look at the cottage. Foreground: grass only (plus the cropped lump). Mid: nothing. Distance: cottage and ridge. Two of the three layers are missing.

### A-05 `05-spawn-low-sun.png`

Defects
- Same composition as A-01, same cropped NPC at the left edge, same unexplained dark region.
- The low sun does not produce low-sun lighting: no long shadows from boulders, fences or figures; no rim light on the trainer or the NPC; the ground is uniformly darkened to olive-brown mud. The key art's sunset panel lights the hillside warm and drops the far hills into blue silhouette.
- The sky is the best in the set (warm strata, sun disc), and the ground does not reply to it.
- The trainer is a dark silhouette on dark ground — the least readable player figure in any frame.
- The fences go rust-red; that and one pink flower are the only warm notes on the ground.
- Distant hills: a pale-amber fog band with a hard boundary at left, then blue.

(a) The sun disc, upper right. Second, the two black boulders on the crest, centre.

(b) It asks you to look at the sky; the ground is a dark plate beneath it. Foreground: one plant, cropped NPC. Mid: figures and crest. Distance: hazy hills. The mid-ground figures are lost in the dark.

---

## Set B — five route places (`shots_places/`)

### B-1 `place1-gate-meadow.png`

Defects
- No gate in frame; no trainer.
- Nine or ten of the same lollipop tree with red-orange trunks at three heights. The canopies are the same green as the grass, so at 30% the tree line and the field merge into one band.
- The pale dome behind the trees at left-centre reads as a grey egg; its speckle is at the same frequency as the grass.
- Four tiny brown quadrupeds at ~35 m under the trees, centre-left and right; each ~5 px, unreadable as a species. They are the only creatures in sixteen frames and they do not read.
- The dirt road enters bottom-left and curves behind the centre tree; it does not arrive anywhere visible.
- Foreground: twelve-plus copies of the flowering plant at even spacing, one yellow grass tuft, no bushes, no tall grass. The "meadow" is short grass with white dots.
- A dead black tree at far left, small; two dark rock blobs under the trees at left.

(a) The centre-left tree pair with the dome behind them, ~40 m. Second, the road at bottom-left.

(b) It half-asks you to follow the road, then hides where it goes. Foreground: plants (0–10 m), uniform. Mid: road and tree line (10–60 m). Distance: a pale flat plain on the right. The right half of the frame has nothing beyond 60 m.

### B-2 `place2-the-rise.png`

Defects
- The camera is ~0.6 m off the ground; the road texture occupies the bottom-right 40% of the frame and its noise pattern is legible as tiling.
- The great tree's trunk is cut by the top edge with no canopy shown; at ~8 m it is the only strong dark and it is decapitated.
- The tree line at left: one species, one height, one canopy tone, one trunk colour — a hedge of lollipops.
- The distant plain at right is pale, flat and featureless; one dead tree at the far right.
- White pebbles on the road are bright specks with no shadow; they float.
- A light/dark shadow band across the road at the top of the frame has a jagged edge that follows terrain triangles.
- No trainer, no subject.

(a) The trunk, top-centre. Second, the bright road texture, bottom-right.

(b) No subject. Foreground: road and plants. Mid: tree line at left. Distance: an empty plain at right. The right half is empty at every depth beyond 20 m.

### B-3 `place3-pond-pocket.png`

Defects
- The camera is ~2 m from a stone-and-timber wall that fills ~55% of the frame. The cobbles are flat-shaded with pale outlines; the timber is bright honey wood; both are at a different level of finish from the terrain and reads as a toy set.
- Timber defects: two diagonal braces at the bottom-right corner of the wall run past the wall's edge into the air; a horizontal timber at bottom-left sits at a different angle from the wall it should be on; the upper-floor timbers form random diagonals rather than a frame.
- The grey foundation plinth is a flat slab; at left it visibly floats over a gap to the grass.
- The pond: flat turquoise, hard straight bank, no shore transition, no reeds, no reflection break-up; the far bank is a green line.
- The wooden walkway/fence to the right: posts at odd spacing, deck a dark stripe, and the trainer at its end (~15 m) reads only as "a person". A dark blob at the walkway's far end may be a creature or a rock — unreadable.
- A basket/crate cluster at bottom-right, cropped.
- Foreground: grass blades, two flowering plants, one saturated orange-red tuft at bottom-left.
- Scale: the stone base is ~2.5× the trainer, the building reads as a large hall; braces ~0.3 m thick. Plausible.

(a) The stone wall, left half. Second, the trainer on the walkway, right, ~15 m.

(b) It asks you to look at a wall. The pond the stand is named for occupies the upper-right fifth. Foreground: wall and grass. Mid: walkway, trainer, pond. Distance: tree line beyond the water. The pond and the trainer are the picture; the camera is on the wrong side of the building.

### B-4 `place4-long-field.png`

Defects
- Trainer at centre, ~6 m, back to camera, arms held out from the body in an A-ish idle.
- The same flowering plant repeated ~30 times, evenly, out to ~40 m; no bushes, no tall grass, no path.
- Four lollipop trees at 20–30 m; a black boulder blob right-centre; a two-panel pale fence at right, ~20 m, attached to nothing.
- Distance: a flat pale plain in every direction, one tree at far right, no landmark, the horizon a straight line.
- The sky is ~30% of the frame and is the only value contrast.

(a) The trainer, centre. Second, the black boulder, right-centre, ~25 m.

(b) It asks you to look at the trainer, who is looking at nothing. Foreground: plants. Mid: trees, boulder, fence. Distance: empty. A "long field" in the references ends at something — a peak (moong-02), a tower (palworld-04), a cliff (palworld-02); this one ends in fog.

### B-5 `place5-bridge-approach.png`

Defects
- The road runs into a cutting between two raised banks; both are steep and flat-topped and read as engineered berms, not a valley.
- The right bank shows vertical texture streaking (terrain texture stretched on the slope) and a rectangular pale-grey patch at ~30 m where the blend changes — a seam.
- The bridge is a low wooden railing at ~60 m, ~3% of frame height; the deck isn't visible; it reads as a fence across the road.
- The road texture is speckled noise at the same scale from 1 m to 60 m, with white pebbles; no ruts, no edge wear.
- The left bank has the same flat top; dark plant clumps sit on its crest like teeth.
- A dead tree stands at the bridge; the trees behind on the right are the same lollipop line.
- No trainer.

(a) The bright road, bottom-centre. Second, the grey patch on the right bank.

(b) It wants you to look at the bridge, and the bridge doesn't read. Foreground: road and grass banks. Mid: the banks, which work as a funnel — the one compositional device in Set B that functions. Distance: tree line and bridge. The funnel works; what it funnels to doesn't.

---

## Set C — six composition stands (`shots_composition/`)

### C-1 `comp1-village-approach.png`

Defects
- The boulder right of the trainer is a near-black, smooth, faceted mass ~4 m tall by ~5 m wide with no surface detail. It is the largest, darkest, closest thing in the frame, and it is blank.
- Village: two red-roofed cottages at ~150 m, centre-left, each ~2% of frame height; behind them a grey speckled dome taller than the village, reading as a slag heap.
- Tree line at left: a dozen identical trees at one height, evenly spaced, canopies the same green as the grass; a smudge at 30%.
- Foreground: the flowering plant repeated twenty-plus times at even density; the road is speckled orange with confetti pebbles.
- The trainer reads well against the road (blue shirt, tan pack).
- The road does lead to the village — the only frame in Set C whose road goes where the camera looks.

(a) The black boulder, centre-right, ~6 m. Second, the trainer, centre, ~5 m. The village is fourth or fifth.

(b) It asks you to look at the village and shows you a rock. Foreground: plants and road (0–8 m). Mid: trainer, boulder, tree line (5–60 m). Distance: village and dome. The three layers exist, but the mid-ground element is a void-black mass that pulls the eye off the distant subject.

### C-2 `comp2-route-out.png`

Defects
- The road is at the far-left edge running out of frame; the trainer stands in the meadow, not on the road. "Looking along the road out" is not what is on screen.
- The single centre tree at ~30 m is the only vertical; the tree line behind it is one height, like a hedge.
- Right: three brown-black boulders at 40–60 m, a small tree, a dark shape on the ridge at the far right.
- Distance: a pale flat plain; a grey mound clipped at the far-left edge.
- A saturated red-orange grass tuft at bottom-left.
- Ground: yellow-green noise with patches overexposed to near-white yellow at centre.
- Trainer at ~6 m, readable.

(a) The centre tree canopy, top-centre. Second, the trainer.

(b) No route is visible; the frame has no subject. Foreground: plants. Mid: trainer, tree, boulders. Distance: nothing. A "route out" in the references shows the road curving away toward a landmark (key art top-left panel, palworld-02).

### C-3 `comp3-rise-overlook-pond.png`

Defects
- No pond in frame.
- The great tree at top-left: a massive dark trunk cropped at the top, no canopy; behind it the lollipop hedge.
- The trainer on the crest right of centre is silhouetted against the pale plain — the best character readability in any frame.
- Distance (beyond 80 m): pale green fading to white, one dead tree, no water, no landmark, no village.
- Foreground: the same plant; the crest is blotchy yellow-green; a dark shadow band below the trainer has a jagged terrain-triangle edge.
- Right edge: one lollipop tree and a dark plant clump at ~40 m.

(a) The trainer, right of centre, ~6 m. Second, the dark trunk, top-left.

(b) It asks you to look over the crest at what the trainer sees; the answer is haze. Foreground: tree and plants. Mid: trainer and crest. Distance: empty. The framing device (tree) and the subject (trainer) work; the reward is missing.

### C-4 `comp4-rise-look-back.png`

Defects
- The best-composed frame of the sixteen: the road descends from bottom-centre toward the tree line, the trainer stands on the crest right of centre against sky, a tree frames the left, and the distant dome plus village close the view.
- The dome is still a bare grey speckled lump; the village beside it is three red roofs at ~200 m, ~1% of frame height.
- The tree line at 40–60 m is one species at one height; the framing tree at left is the same species.
- A saturated red-orange grass tuft at the right edge, cropped.
- The dark shadow band across the road (top-centre) has a jagged terrain-triangle edge.
- Foreground plants repeat; white pebbles on the road.
- A patch of purple flowers at left-mid is the only colour accent in the set that isn't white.

(a) The trainer, right of centre, against sky. Second, the dome and village, centre distance.

(b) It asks you to look back along the road to the village, and the layers cooperate: foreground road (0–10 m), mid crest and tree line (10–60 m), distant landmark. This is the composition the other five stands should have, with a landmark worth looking at.

### C-5 `comp5-pond-arrival.png`

Defects
- The densest frame; the grove gives real layered depth (trunks at roughly 3, 8, 15 and 30 m).
- Every trunk is the same red-orange with the same ~0.7 m diameter and the same bark; every canopy is the same lime green with no interior shadow. The grove reads as one tree instanced.
- The pond is a turquoise sliver at ~40 m behind the trunks, centre-left; the frame is named for it and it is about 1% of the picture.
- A dark A-frame shape above the trainer's head at ~35 m — a hut roof or a rock — unreadable.
- A second character (dark hair, standing) at left mid-distance, ~25 m, unreadable as anyone in particular.
- A curved brown root or branch intrudes at frame right in the foreground; it reads as a detached hook rather than part of a tree.
- Ground: orange dirt patches against green with hard blotchy edges; white pebbles.
- The trainer's idle — arms out, elbows bent — is the same pose as every other frame.

(a) The trainer, centre, ~5 m. Second, the light through the trunks to the water, centre-left.

(b) It asks you to walk toward the water, and hides the water. Foreground: trunks and the root. Mid: trainer and grove. Distance: the pond glimpse. This is the right idea, executed with one tree.

### C-6 `comp6-bridge-approach.png`

Defects
- No bridge in frame.
- The field is flat to the horizon; the distance is two clumps of the same tree, a brown boulder at right, a lone tree at left; nothing beyond ~80 m but haze.
- Two orphaned two-panel fence segments at ~40 and ~60 m right of centre, attached to nothing; a pale tan block at ~80 m centre (hay? crate?), unreadable.
- The road is a faint orange smear from bottom-right past the trainer; it doesn't read as a road at 30%.
- Ground: overexposed yellow patches at left; the flowering plant repeats.
- A dark purple bush at bottom-right; the trainer readable at centre.

(a) The trainer, centre. Second, the overexposed yellow grass at left.

(b) No subject. Foreground: plants and road. Mid: trainer and fences. Distance: tree clumps. The mid-ground is empty where palworld-02 has a cliff, a cave mouth and two creatures.

---

## Cross-frame consistency

- **One place, by monotony.** The same sky, the same ground noise, the same tree, the same rock blob and the same flowering plant appear in every frame. The frames read as one location because there is only one of everything.
- **The composition sheet at 30%.** Five of six thumbnails in `shots_composition/_sheet.png` are the same picture: a yellow-green band, a blue band, a small figure. Only comp5 (the grove) differs. Six stands along a route are supposed to produce six different thumbnails.
- **Value structure.** The ground sits in a narrow yellow-green mid-tone. Darks come from near-black boulders and jagged shadow bands, not from canopy interiors, hedgerows or hill folds. The key art's deep-green shadowed groves are absent from every frame.
- **Palette leak.** No oxblood anywhere (correct: no Team Tether element is in frame). The only saturated red in the world is the orange-red grass tuft (place3, comp2, comp4, A-02) — the most "danger"-coloured object in sixteen frames is a decorative plant.
- **Fog vs sky.** Warm-white fog under a cool grey-blue sky in A-01, A-03 and A-05; the seam is visible as a band.
- **Time of day.** One noon across fifteen frames; the one low-sun frame (A-05) darkens the ground instead of lighting it.
- **Scale agreement.** Trainer, NPC, fences, cottages, boulders and trees agree about a metre. The grey dome gives no scale because it has no detail. No creature offers a scale to check.
- **Creatures.** Zero readable creatures in sixteen frames. This is a creature game.
- **Characters.** The trainer is a coherent stylised figure in a muted palette (blue, tan, grey) with one passive idle pose in every appearance. The white-haired NPC reads. The cropped foreground NPC in A-01/A-05 is a bug.
- **Style agreement within a frame.** The cottage and the trainer are stylised realism; the trees, rocks and flowering plant are cartoon; the terrain and road textures are photographic noise. A-04 has all three in one picture.
- **Artefacts.** Terrain-triangle shadow edges (place2, comp3, comp4); texture stretch and a seam patch on a bank (place5); a horizon row of impostor blocks and a texture-LOD band (A-03); braces overhanging the wall and a floating plinth (place3); floating pebbles on every road; overexposed ground patches (comp2, comp6).
- **Interface.** No UI in any frame; nothing to judge.

---

## Verdict

### 1. The three things that most separate these frames from the references, ranked

**1. Nothing to look at.** Every Palworld frame stages a subject at 5–40 m — a Mammorest filling the frame (palworld-01), a cave mouth and two Pals at the end of the path (palworld-02), a ruin under a spire (palworld-04) — and every key-art panel puts a landmark on the sightline: windmill and tower, mountain, monolith, dock, stronghold. Of sixteen frames, one (comp4) has a landmark on the road's sightline, and it is a bare grey mound with three roofs. Zero readable creatures anywhere. Worst offenders: comp2, comp3, comp6, place4, A-03, A-04.

**2. One tree, one rock, one plant, one ground.** The key art's oaks are dark-trunked, spreading, interior-shadowed, at three or four sizes; the Meadows here is one lollipop with a red trunk at one height (place1, comp1, comp5). Rocks are black featureless wedges (A-02, comp1). One flowering plant is the entire understory in every frame. The ground is one blotchy noise at one frequency. At 30% everything collapses into two bands and dots; you cannot tell the tree line from the field.

**3. Depth and light.** Distance is a pale void with a fog/sky mismatch (A-03, comp3, place2); no hedgerows, groves or hill folds structure the mid-ground; the low-sun frame (A-05) darkens rather than lights; shadows are jagged bands with terrain-triangle edges (place2, comp3, comp4) and an unexplained dark mass (A-01, A-05). Palworld-02 and moong-02 layer foreground grass, mid subject and distant peak in one picture; here only comp4 and comp5 attempt it, and neither has a distant subject to land on.

### 2. The two bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?** **No.**
What carried toward it: the sky and cloud type; the cottage; the pond colour; the terracotta roofs; the trainer's costume palette; the road-to-village idea in comp1 and comp4.
What sank it: the board names rolling hills, oak groves, clear streams, wildflower meadows, settlements with windmill and tower, a rune monolith, a mountain, and a dusk that lights the land. None of those is on screen. The trees are not oaks, the meadows are short grass with white dots, there is no stream, the settlement is three roofs at 200 m, there is no landmark, and the dusk frame goes to mud.

**B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?** **No.**
What sank it: no creatures; the character is competent but small, passive and never the subject; the mid-ground the Palworld frames fill with creatures, cliffs and structures is empty here; rocks and trees are two tiers below the finish of the cottage or the trainer; ground-cover density is a fraction of palworld-01/03.
What carried: nothing that would make a viewer say "same kind of game". The trainer with the backpack is the only asset that could sit in a Palworld frame without comment.

### 3. Fixable by changing the scene vs needs art not in the build

**Fixable by scene (density, palette, lighting, composition, scatter, placement)**
- Stage a subject in every stand: put whatever creatures are installed at 5–30 m in comp1–comp6 and place1/place4, and put the named subject in the named frame — the pond into comp3's view, the bridge into comp6's, a landmark at the end of comp2's road.
- Use comp4 as the template: foreground element at 1–5 m (trunk, rock edge, tall grass), mid subject, distant mass on the sightline.
- Cluster the scatter: the flowering plant in clumps not a grid; add bushes and tall grass cards near the camera; rock clusters with debris; hedgerow and grove masses at 20–80 m to structure the mid-ground.
- Vary tree scale and tint per instance; rotate; break the one-height line.
- Lighting: a real low sun angle for A-05 with long shadows and rim; fog colour matched to the sky and pushed back; remove the unexplained dark mass in A-01/A-05.
- Placement bugs: the cropped NPC at spawn; the orphaned fence panels in place4/comp6; the floating plinth and the brace overhang in place3 if it is a placement error; the fence-run gaps on the spawn crest; the road not leading anywhere in place1.
- Terrain: fix the vertical stretch and the seam patch on place5's banks; hide or resculpt the grey dome; fix the overexposed patches in comp2/comp6; scale the road texture so it changes with distance.

**Needs art that is not in the build (as the frames show it)**
- A creature that reads at 30 m. None was shown; if the installed ones look like the dots in place1 at that range, that is the gap.
- A second and third tree, or an oak with a spreading, dark, interior-shadowed canopy. Re-scattering the lollipop cannot make a grove.
- Rock meshes or materials with faces, cracks, moss and one consistent palette. The black wedges cannot be fixed with placement.
- A ground grass material with structure, tall-grass cards, and a wildflower-carpet material.
- A dirt road material with ruts and edge wear.
- A landmark object in the key art's own language: windmill, tower or rune monolith.
- A bridge that reads as a bridge at 60 m; the hall's timber-frame model if the braces are modelled that way.
- An idle animation with weight for the trainer.

## Second pass — comp7 and comp8 re-sited (same session)

Two frames judged blind, same renderer caveat as above. Trainer 1.80 m is the ruler. Crops at 200–800% and a 30% thumbnail were used to check the named subjects.

### C-7 `comp7-pond-reveal.png`

Defects
- **No pond.** Nothing in the frame is water: no turquoise, no reflection, no bank, no reeds. Searched the horizon band and the ground under the right-hand trees at 4x; it is grass, dirt and trunks.
- The ground ahead of the trainer rises to the tree line, not down; "descending toward" is not what the picture shows. The road enters at bottom-right and bends right toward the trees at ~40 m, away from the camera's line of sight, so the road and the sightline disagree.
- The left half (0–30 m) is a slope of the same 30 cm grass and the same flowering plant repeated ~25 times at even spacing; overexposed yellow patches at left-mid and a dark unlit band across the road with a jagged edge at the bottom of the frame.
- The tree line at 40–80 m is one species, one trunk colour, one canopy green, one height; at 30% it fuses with the field into a single green band with a brown stripe of trunks.
- The cottage at ~150 m, left of centre, is ~2% of frame height and stands alone: no road to it, no yard, no smoke. The signpost at ~40 m right of centre is a pale stick, ~1% of frame height, unreadable as a sign at 30%.
- Distance beyond 80 m: a grey-green mound with the same speckle frequency as the grass, no strata, no trees on it.
- The trainer at ~5 m, centre, is in the same arms-out idle as every other frame and faces the empty slope, not the road, the cottage or anything.
- Scale: trainer, signpost (~2.5 m), trees (~10 m), cottage agree. No creature to check.

(a) Eye lands on the trainer's tan pack, dead centre, ~5 m. Second, the bright orange road at bottom-right, because it is the largest warm shape; the cottage is fourth or fifth.

(b) It asks you to look over the trainer's shoulder at what he sees, and what he sees is a hedge. Foreground (0–10 m): grass, the plant grid, the road edge. Mid (10–80 m): the signpost, one tree at ~50 m left, the tree line. Distance (beyond 80 m): the cottage and the mound. The mid-ground centre, 10–40 m, where palworld-02 puts a cave mouth and two Pals and the key art's pond panel puts a dock and water, is empty grass.

(c) The pond is not visible at any size.

### C-8 `comp8-bridge-rim.png`

Defects
- **The bridge is a speck.** At ~70 m, centre-left at the road's end, there is a pale timber lattice ~3 m wide and ~2 m tall (~4% of frame width) with a blue-grey strip beneath it. At full size it reads as a wooden crate or a livestock pen; at 30% it is a 12 px tan dot. Nothing reads as a span, a deck, an arch or a gap it crosses; the blue-grey strip is the only hint of water and it is one pixel row.
- No rim: the ground under the trainer is flat and the road runs level to the object. The road does not drop away, so there is no reveal.
- The grove is the best depth in either frame (trunks at ~3, 8, 15, 30 m), but it is the one tree instanced: identical red-orange trunks, identical canopy blob, no interior shadow, and two canopies at top-left and top-right cut flat by the frame edge.
- The road fills the lower 45% of the frame with one speckled orange noise at the same frequency from 1 m to 70 m, scattered with ~25 white confetti pebbles that cast no shadow and float. The trainer stands on the right verge, not on the road; the road's convergence point and the trainer are not on the same line.
- Two creatures are present: a pale pink-white spiky quadruped under the trunks at ~30 m left (~2 m tall — taller than the trainer, good) and a tan quadruped on a grey slope at ~50 m far right (~1.5 m long). Both are ~15–25 px and read as "pale animal" only; neither is readable as a species at 30%, and neither is framed as a subject — the left one is half behind a trunk, the right one is cut by the frame edge.
- Distance beyond 80 m: the same grey-green speckled mound, and a grey slab-like patch behind the right creature (terrain blend seam or the dome's flank; it reads as a slab).
- Foreground left: a clump of tall yellow-orange reeds and the flowering plant at 2–6 m — the one place in either frame with scale variety in the understory.

(a) Eye lands on the trainer's tan pack, right of centre, ~5 m, against the dark trunk behind him. Second, the bright road wedge at bottom-centre. The bridge object is sixth or seventh, after the canopies and the pale creature at left.

(b) It asks you to follow the road to the bridge. Foreground (0–10 m): road, reeds, trunks at left and right edges. Mid (10–80 m): trunks, both creatures, the bridge object. Distance: mound and slab. The mid-ground is populated for the first time in this set; the subject at its far end is too small and too crate-like to be the reward.

(c) The bridge is visible only if you already know where to look: ~50 x 40 px at full size, a dot at 30%, and it reads as a crate, not a bridge, at both sizes.

### Both

- At 30% the two thumbnails are distinguishable from each other (open slope vs. grove), which is more than the six earlier stands managed.
- Neither frame delivers its named subject. comp7 has no pond; comp8 has a bridge only by assertion. Both face the same fix as before: put the subject at 10–40 m on the sightline, and raise the camera or drop the ground so the road actually leads down to it.
