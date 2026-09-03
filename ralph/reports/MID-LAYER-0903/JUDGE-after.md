# Tetherbound Visual Judge Report — MID-LAYER-0903 (after)

Blind review of 18 frames across three sets (Survey, Places, Composition), judged
against `docs/reference/tetherbound-meadows-keyart.png` and the five
`docs/reference/palworld-0*.jpg` screenshots per the visual-judge rubric.

---

## Set A — Standing Survey

### 01-spawn-outward.png

**Defects**
- Silhouette test fails at small size: the two dark boulders left-of-center and the
  wooden fence rails all sit at nearly the same mid-dark value, so at 30% they fuse
  into one grey mass instead of reading as "rock, rock, fence."
- The trainer character (center) and the white-haired NPC (right) both read as
  cardboard cutouts — flat lighting on the figures against a scene with a hard,
  directional cast shadow behind them (the long diagonal shadow band running toward
  camera). The shadow says late/low sun; the figures' own shading doesn't match it.
- A cropped, partially-visible character fills the bottom-left corner (torso, arm,
  hand with an object) — it reads as an accidental foreground occluder, not a
  composed element.
- Value range is compressed: grass, dirt path, and rocks all sit in a narrow
  yellow-green-to-olive band. Nothing in the frame is a clean light or a clean dark
  except the sky.
- The garden/crop-bed structure (right edge) is a flat tan box with no texture
  variation — reads as a placeholder prop.

**(a)** Eye lands first on the trainer character standing center-frame on the
skyline (mid-distance, dead center); second on the large dark boulder just behind/left
of him, because it's the single largest silhouette in the shot.

**(b)** The frame is asking the viewer to look at the player character and the NPC
he's approached — a spawn/greeting establishing shot for a farmstead area.

---

### 02-valley-floor.png

**Defects**
- The dominant object in the frame — a huge dark, faceted boulder — is a flat,
  low-poly, uniformly-shaded grey mass with no texture or AO contact shadow grounding
  it convincingly; it looks pasted into the scene rather than resting on the hill.
- Foreground flowering shrubs (bottom third) are rendered at a scale and density that
  reads as decorative clutter rather than a meadow — each one is an isolated, evenly
  spaced clump with visible gaps of bare-looking grass between them (regular interval,
  procedural read).
- The small village rooftops on the left horizon are the only sign of habitation and
  they're tiny and hazy — no clear landmark silhouette at this distance.
- Overall palette is again narrow: olive-yellow grass, one grey rock, muted green
  trees. Nothing pops as a focal saturated color except the small red rooftops, which
  are too small and too far left to serve as a focal point.

**(a)** Eye lands first on the giant dark boulder (center-right, mid-ground,
~15m); second on the cluster of trees directly behind/right of it.

**(b)** The frame reads as showcasing a terrain/prop set-piece (the boulder) in a
grassland — an environment beauty shot rather than a path or goal.

---

### 03-rise-overlook.png

**Defects**
- Severe horizon/depth failure: the far background is a flat, foggy grey-green wall
  that reads as an unrendered or LOD-collapsed terrain mass, not distant hills — there
  is a hard horizontal seam roughly a third of the way up the frame where terrain
  texture stops resolving into anything but flat color banding.
- The village cluster of red-roofed buildings sits awkwardly small and isolated in
  the mid-ground with no supporting environment (no trees, fences, or road connecting
  it visibly to the foreground) — it looks dropped onto the terrain.
- Foreground rocks (bottom-right) are the same flat, faceted, unlit-looking geometry
  as in 02 — brown and grey slabs with no distinguishing surface detail up close,
  which is exactly where detail should read best.
- This is the widest, most "vista" shot of the set and it is the flattest-lit: no
  visible sun direction, no shadow falling from the overlook terrain itself, so the
  hill the camera stands on doesn't read as having form.

**(a)** Eye lands first on the small red-roofed village cluster (mid-distance,
just right of center); second on the foreground rock cluster (bottom-right, close).

**(b)** The frame is asking the viewer to take in the overlook vista and spot the
village as a destination landmark — a "here's where you're headed" shot.

---

### 04-three-quarter.png

**Defects**
- The house (the clearest man-made landmark in the whole survey) is small and
  centered on a flat horizon with no foreground framing devices leading the eye to
  it — the huge foreground grass field (bottom two-thirds of frame) is empty of any
  midground interest, so the eye has a long, dead gap to cross.
- Grass ground texture close to camera is a flat tiled mossy-yellow blotch pattern
  with visible repetition — at this proximity it reads as a texture, not as blades.
- Flowers are sparse, small, and uniformly white — same species repeated at even
  intervals, no clustering variety.
- Tree canopies (left edge, cropped) are a solid uniform green blob with no
  internal shading — flat-lit despite a sunny sky.

**(a)** Eye lands first on the house rooftop (center, far distance, red roof
against sky); second on the flanking trees around the house.

**(b)** The frame is asking the viewer to look at the house/settlement as a distant
goal across an open field — a wayfinding/establishing shot.

---

### 05-spawn-low-sun.png

**Defects**
- This is meant to be a low-sun/golden-hour shot (visible pale moon/sun disc in sky,
  warm cast) but the ground and character shading do not carry warm rim light or long
  golden highlights — the grass is olive-brown-dark rather than warm-lit, so the "low
  sun" mood is only legible from the sky, not from anything it should be touching.
- Same cropped foreground character issue as frame 01 (bottom-left arm/torso
  intruding on the shot).
- The two background figures (trainer center, NPC right) are underlit relative to
  the sky's brightness — they read as silhouetted but the sky isn't bright enough
  behind them to justify true silhouette, so they land in a lit/unlit no-man's-land.
- Same flat garden-bed prop and boulder pair reused from frame 01, confirming this
  is the same location at a different time of day — consistent, but the boulders read
  identically dark in both lighting conditions, meaning material response to light is
  minimal.

**(a)** Eye lands first on the pale sun/moon disc in the upper-right sky (it's the
brightest point in the frame); second on the trainer character silhouette center-frame.

**(b)** The frame is asking the viewer to register a day/night or time-of-day
transition at the same spawn location as frame 01.

---

## Set B — Route Places

### place1-gate-meadow.png

**Defects**
- Trees (left and center) are the strongest asset in the set so far — decent canopy
  read — but they're placed with visible even spacing along the left edge, and the
  ground-cover shrubs in the foreground are arranged in near-perfect regular rows
  (visible diagonal lines of repeated shrub silhouettes), which reads as scattered by
  algorithm, not designed.
- A hazy, pale rounded mountain shape sits directly behind the trees at center-left
  with a puff of white (smoke/cloud?) beside it — ambiguous silhouette, unclear if
  it's terrain, weather effect, or a bug.
- The single grey rock (right-of-center) again has no contact shadow variation to
  distinguish it from the boulders in Set A — same asset, same flat treatment.
- Small distant houses (far left, low) are barely legible dark blobs.

**(a)** Eye lands first on the dense tree cluster (upper-left, close-mid ground);
second on the grey rock slab (right-of-center, mid-ground).

**(b)** The frame asks the viewer to notice a gateway/threshold moment — trees on
one side, open path to the right — but nothing in the frame strongly marks it as a
"gate."

---

### place2-the-rise.png

**Defects**
- A large tree trunk dominates the top-center of the frame, cut off by the top
  edge — the framing crops the canopy entirely, leaving a bare trunk pillar that reads
  awkwardly, like the camera was aimed too low for the asset.
- The dirt path (right/bottom) has a hand-authored feel (a real curve, edge
  variation) which is good, but it terminates at the frame edge with no destination
  visible — the composition doesn't reward following it.
- The shrub/flower scatter along the path edge is once again evenly spaced at what
  looks like a fixed interval — every 1-2 units, same size, same rotation-ish pose.
- Distant hills on the right are flat and hazy with almost no value separation from
  the sky — horizon nearly disappears.

**(a)** Eye lands first on the large foregrounded tree trunk (top-center, very
close, cropped); second on the dirt path curving into the right side of frame.

**(b)** The frame is asking the viewer to look at a rise/crest with a path choice
— but the cropped tree trunk competes with and partly defeats that read.

---

### place3-pond-pocket.png

**Defects**
- This is the darkest, most cluttered frame in the whole set: at least four tree
  trunks cross the frame at odd diagonal angles with almost no negative space,
  and exposure is low enough that most of the trunk surfaces are near-black — very
  poor readability, arguably fails the 30%-size test outright since it's mostly
  indistinguishable brown/black shapes.
- The player character (right-of-center, partially occluded by a trunk) is nearly
  swallowed by the surrounding foliage — poor readability of the player against a
  busy background, the opposite problem the rubric flags as most important.
- The pond itself (visible in a sliver, right-center) is the ostensible subject but
  occupies maybe 8% of the frame, wedged behind trunks.
- Bright tan/orange structure roof glimpsed far right through the trees is
  interesting but too small and cropped to register as a landmark.

**(a)** Eye lands first on the thick, near-black tree trunk crossing diagonally
through the center-left (closest, largest shape); second on the sliver of blue pond
water visible right-of-center.

**(b)** The frame is asking the viewer to peek through trees at a pond pocket, but
the framing is so cluttered and dark that the "reveal" doesn't land — the pond is
nearly hidden rather than revealed.

---

### place4-long-field.png

**Defects**
- The player character (center) stands in a reasonably clean, well-composed field
  with trees framing the top — this is one of the better-balanced frames in the set,
  but the two dark boxy shapes to the right of the trees (crates? rocks? tents?) are
  ambiguous silhouettes with no clear material read — they could be logs, chests, or
  scenery debris, and their flat uniform darkness gives no cue.
- Ground clutter (flowers, shrubs) is once again evenly gridded — visible regular
  spacing especially in the left-foreground band.
- The trainer's own model, seen from behind in decent lighting, reads acceptably at
  this distance but the backpack and clothing textures are low-detail flat color
  blocks with no cloth shading — closer to a mannequin than a character when
  examined at native resolution.
- No mid-ground landmark or point of interest beyond the character himself — "long
  field" delivers exactly that (a long empty field) with little else to anchor it.

**(a)** Eye lands first on the player character (center, close-mid distance,
well-lit against darker tree background); second on the dark ambiguous
crate/tent shapes to his right.

**(b)** The frame asks the viewer to look at the trainer standing in an open
field — a simple traversal/pose shot.

---

### place5-bridge-approach.png

**Defects**
- The wooden bridge, the clearest man-made landmark offered in this set, is tiny,
  centered on the horizon and nearly the same value as the grassy banks around it —
  it does not read as a "bridge" at anything less than full zoom; at 30% it's an
  indistinct brown smear.
- The dirt path/streambed the camera looks down is wide, flat, and textured with a
  repeating tiled dirt pattern that reads as a texture swatch rather than worn earth
  — no footprints, no puddle variation, no edge erosion detail.
- Steep embanked walls on both sides are a uniform yellow-green-brown gradient with
  no rock outcrop or vegetation break — reads as a raw heightmap slope rather than a
  bank.
- A single scraggly dead tree silhouette (upper-center) is the only vertical
  landmark breaking the horizon, and it's ambiguous in silhouette (could be read as a
  broken pole).

**(a)** Eye lands first on the dirt channel/path floor filling the bottom half of
frame (closest, largest shape); second on the small wooden bridge at the horizon
line.

**(b)** The frame is asking the viewer to anticipate crossing the bridge ahead, but
the bridge itself is too small and low-contrast to serve as a strong goal marker.

---

## Set C — Composition Stands

### comp1-village-approach.png

**Defects**
- Two large dark shapes flank the character (a green-black rounded hill/boulder
  mass, upper-right, and a dark tent/rock shape lower-right) both read at nearly
  identical value and saturation — at a glance they merge into one large dark blob
  swallowing the right third of the frame.
- Distant village rooftops (left-of-center horizon) are small red-and-white
  blobs with no supporting silhouette (no walls, fences connecting visually) —
  legible only because of the saturated red roof color, which is doing all the work.
- Foreground shrub scatter is, again, on a visible grid — count the repeating
  V-shaped flowering shrubs across the bottom third and the interval is nearly
  constant.
- The character is decently lit and readable here — one of the better examples of
  player-against-ground contrast in the set.

**(a)** Eye lands first on the large dark rounded hill mass (upper-right,
mid-distance); second on the player character (center, closer, smaller but
higher-contrast).

**(b)** The frame is asking the viewer to register the village in the distance as
a destination while walking a path — a route/wayfinding composition.

---

### comp2-route-out.png

**Defects**
- A single well-shaped tree (upper-center) is genuinely one of the better tree
  reads in the whole set — clear canopy silhouette, distinguishable from the rock
  beside it. This is a positive, worth naming since so many other frames blur
  tree/rock/shrub together.
- However, the large grey boulder next to that tree is again flat and matte with no
  surface break, sitting at almost the same value as the dirt path in the
  foreground — it doesn't visually "weigh" more than the ground around it.
- A cluster of red/orange reed-like plants (left-foreground) is a strong, welcome
  saturated color accent — but it is isolated, a single clump with nothing else like
  it anywhere in the 18 frames, so it reads as inconsistent rather than a palette
  choice.
- Dark boxy shapes (right-mid distance) are the same ambiguous crate/tent
  silhouettes seen in place4 — recurring unclear prop.
- The path forks left/right at the character's feet but nothing distinguishes the
  two options visually (same texture, same width) — a navigational composition that
  doesn't actually guide a choice.

**(a)** Eye lands first on the player character (center, close); second on the
tree/boulder pair directly behind him (mid-ground).

**(b)** The frame is asking the viewer to consider a route choice — the character
stands at a path split — but the two paths are visually undifferentiated.

---

### comp3-rise-overlook-pond.png

**Defects**
- The frame promises "overlook + pond" per its name but no pond, water, or valley
  reveal is visible anywhere in the shot — it is a tree line (left) and an empty
  grass slope down to a hazy horizon (right), which undercuts whatever the intended
  vista beat was.
- The right two-thirds of the frame is almost entirely empty grass with no
  midground object at all — the rubric's "how much of the frame is empty" criterion
  is failed hard here compared to the Palworld references, which always have
  creatures, structures, or terrain incident even in open shots.
- Foreground shrub/flower scatter (bottom-left) is dense and slightly more varied
  in placement than other frames — a small positive.
- Distant hills on the right fade into flat haze with no value separation — no
  sense of scale or distance markers (no trees, rocks, or landmarks placed to read
  depth).

**(a)** Eye lands first on the player character (right-of-center, close, the only
high-contrast object); second on the tree canopy mass (upper-left).

**(b)** The frame is asking the viewer to look out over a rise — an overlook
composition — but there is nothing to overlook; the promised reveal is absent from
the frame.

---

### comp4-rise-look-back.png

**Defects**
- Best-composed frame in this set: player character is clearly lit, centered on a
  rule-of-thirds-ish position, path curving behind him toward a hazy landmark
  (small rock shape, far left horizon) — genuine sense of "look back at where you've
  been."
- Still, the tree (left, close) is a flat, uniformly green canopy with no shading
  variation despite clear directional sun elsewhere in frame (visible cast shadow
  under the character) — the tree doesn't participate in the same lighting model as
  the ground.
- A cluster of the same red/orange reed plant reappears (right edge) — again
  isolated, one clump, not a considered palette accent.
- Ground texture immediately around the character's feet shows visible tiling —
  a repeating mottled pattern is legible at this exact distance from camera.

**(a)** Eye lands first on the player character (center-right, close, well-lit);
second on the winding dirt path leading back and left toward the hazy distant rock.

**(b)** The frame is asking the viewer to look back along the route just
traveled — a retrospective/vista composition, and it's one of the more successful
ones in the set at delivering that.

---

### comp5-pond-arrival.png

**Defects**
- The pond is finally visible and reads reasonably well as a body of water (clean
  horizontal blue band, center-left) with a house behind it — this is the strongest
  "arrival" moment in the whole set, a real positive to note.
- However the water's edge has almost no shoreline detail — no reeds, rocks, or
  wet-sand transition where grass meets pond; the blue simply cuts against green with
  a hard edge.
- A second, small NPC or creature figure (far left, small, pale) is present but so
  small, undetailed, and poorly lit that it's unclear whether it's a person, a
  creature, or a prop at first glance — this is a "the creature must hold up" rubric
  concern: it does not read as a creature at all here.
- The dead, curling tree branch/log (bottom-right foreground) is a strange, almost
  writhing shape with no clear read — looks like a bug or stray asset rather than a
  deliberate foreground frame element.
- Trees along the right (close, tall) are cropped hard by the top edge, same as
  place2, losing canopy silhouette.

**(a)** Eye lands first on the player character (center, close-mid, moving toward
the pond); second on the pond and house cluster beyond him (mid-distance, left of
center).

**(b)** The frame is asking the viewer to register arrival at a pond/settlement
landmark — and it is the frame in this whole set that comes closest to succeeding
at that goal.

---

### comp6-bridge-approach.png

**Defects**
- Small distant deer/creature silhouettes (right-mid-ground, pale tan shapes near a
  fence) are the first clearly-intended wildlife in the whole 18-frame set — but they
  are tiny, flatly lit, and nearly the same tan-brown value as the dirt path beneath
  them, so at 30% they'd vanish. Since creatures are explicitly in scope and meant to
  be the point, this is a missed opportunity for a stronger silhouette.
- Foreground boulder cluster (left) reuses the same flat grey-slab treatment seen
  repeatedly across all three sets — visual monotony of "the boulder asset" by frame
  18 of 18.
- A fence line (right, faint) is barely visible — thin, low-contrast, easy to miss
  entirely, which undercuts its job of signaling "managed/settled land" the way the
  key art's fences do clearly.
- Tree line on the horizon (far, center) is hazy and flat with no canopy
  distinction from the hill it sits on.

**(a)** Eye lands first on the player character (center, close); second on the
small pale deer-like creatures near the fence (right, mid-distance).

**(b)** The frame is asking the viewer to notice wildlife near a fence/pasture
edge while approaching — a "world feels lived-in" beat — but the creatures are too
faint to land it.

---

### comp7-pond-reveal.png

**Defects**
- Despite the name, no pond or water is visible anywhere in this frame — it is an
  open grass slope down toward a small house at the horizon (right-of-center) with
  trees on the right edge. As with comp3, the named "reveal" is not present in what's
  shown.
- Frame is very empty: bottom two-thirds is grass with only the character and
  scattered flowers as content, echoing the same "too much unoccupied ground" issue
  from comp3.
- The house at the horizon is small, flatly lit, and low-contrast against the hazy
  hills behind it — a weak landmark despite being the only structure in the shot.
- Grass ground texture close to camera shows the same repeating mossy-blotch
  tiling as frames 04, place5, and others — a consistent but conspicuous texture
  repeat across the whole set.

**(a)** Eye lands first on the player character (center, close, the only
high-contrast vertical); second on the small house at the horizon.

**(b)** The frame is asking the viewer to look toward a distant house while
descending a slope — but with the promised pond absent, the compositional payoff
described by the filename isn't delivered on screen.

---

### comp8-bridge-rim.png

**Defects**
- This is the most visually competent frame in the entire set: a real avenue of
  trees flanking a path, good canopy variety (sizes and angles differ tree to tree
  rather than being uniform copies), a clear light source producing directional
  shadow on the path, and a glimpse of open field beyond through the tree gap
  (right-center) — genuine depth layering (near trunks / mid canopy / far bright
  field).
- That said, the trunks nearest camera (left and right edges) are extremely dark,
  almost silhouetted black, with no bark texture visible — a hard value cliff between
  "lit canopy" and "unlit trunk" that looks more like exposure clipping than an
  intentional choice.
- The player character (right-of-center, small, partly obscured by a trunk) is
  underlit relative to the bright path he's standing on — he nearly merges into the
  trunk shadow behind him.
- A pale grey creature-ish shape is visible far left, small, in the gap between
  trunks — like comp5's NPC, too small and undetailed to identify or evaluate as
  creature art.
- Ground texture tiling is present again on the path but less objectionable here
  because of the strong shadow break-up.

**(a)** Eye lands first on the sunlit dirt path funneling toward the bright gap at
center-distance; second on the tree canopy arch overhead (top of frame).

**(b)** The frame is asking the viewer to walk down a shaded tree avenue toward an
open, bright field beyond — a corridor/threshold composition, and the best-executed
one in the set.

---

## Cross-frame consistency

- **One boulder asset, everywhere.** The same flat, faceted, uniformly dark-grey (or
  brown/grey pair) boulder appears in 01, 02, 03, 05, place1, comp1, comp2, comp6 —
  at least eight of eighteen frames. It never gains texture, AO, or lighting response
  regardless of time of day. By the end of the set it reads as the single most
  repeated, least-varied object in the whole survey.
- **Regular-interval shrub/flower scatter.** Nearly every frame with foreground
  ground cover (01, 02, place1, place2, place4, comp1, comp2, comp3, comp4) shows the
  same small white-flowering shrub at close to constant spacing and identical scale —
  the clearest "generator output" signature the rubric asks to watch for.
- **Two "reveal" frames with nothing to reveal.** comp3 (rise-overlook-pond) and
  comp7 (pond-reveal) both promise a specific landmark payoff in their names/framing
  intent and neither shows it — both are just open grass toward a hazy horizon.
  Compare comp5 and place3, which do show the pond, just poorly (either tiny and
  distant, or hidden behind trunks).
- **Player readability is inconsistent frame to frame.** The character reads
  cleanly against ground in comp4, comp1, place4; nearly disappears into background
  clutter in place3 and comp8. There's no consistent contrast treatment (rim light,
  outline, or exposure boost) keeping the player legible regardless of background.
- **Creatures/NPCs, when present, are too small and flat to evaluate as art.** The
  pale figure in comp5, the deer in comp6, and the pale shape in comp8 are the only
  living things besides the trainer and one NPC across all 18 frames — none of them
  are rendered with enough size, contrast, or shading to judge as character/creature
  art at all. Given the rubric's instruction that creatures are the point, their
  near-total absence (in any legible form) from a Meadows survey is itself a finding.
- **Time-of-day frames (01 vs 05) don't diverge in ground/material response.** The
  low-sun frame changes the sky and adds a moon disc but the grass, rocks, and
  character shading barely change value or hue — "day and night create different
  moods," per the key art's own art-direction notes, is not yet happening at the
  material level.
- **Value range stays narrow across nearly all 18 frames** — olive-green to
  yellow-brown, rarely broken by a strong dark or a strong light except sky and the
  occasional saturated flower/reed accent. Against both references (key art's
  strong sky-to-shadow range, Palworld's saturated grass-to-creature contrast) this
  reads as visually flat as a set, not just per-frame.

---

## Verdict

### The three things that most separate these frames from the references, ranked

1. **Empty, event-less mid-ground, versus Palworld's frames which are never empty.**
   Every Palworld reference (`palworld-02-open-field-path.jpg`,
   `palworld-04-plateau-landmark.jpg`) keeps a creature, a squad-mate, or a landmark
   structure doing something in the mid-distance even in an open field. Multiple
   Tetherbound frames (comp3, comp7, 04) are two-thirds empty grass with only the
   player and scattered flowers — the walk-through-a-field beat the key art and
   Palworld both treat as populated is here treated as vacant.
2. **No creature presence strong enough to judge, versus both references putting
   creatures front and center.** `palworld-01-boss-fight-forest.jpg` and
   `palworld-03-field-boss-meadow.jpg` make the creature the largest, most saturated
   object in frame; the key art's day/night panel puts a fox-like companion
   shoulder-to-shoulder with the trainer. Across all 18 Tetherbound frames the only
   creature-shaped things are three tiny, flat, barely-lit silhouettes (comp5,
   comp6, comp8) that can't be evaluated as character art at all.
3. **Flat, repeated, texture-tiling props versus the key art's varied, hand-placed
   staging.** The key art's meadow panels show varied tree species, scale, and
   clustering, with rocks that carry real form-shadow. Here, one boulder mesh recurs
   flatly across eight+ frames (01, 02, 03, 05, place1, comp1, comp2, comp6), and
   ground-cover shrubs sit at nearly constant intervals in at least nine frames — the
   "authored vs. generator" test the rubric names is failed by density and scatter
   pattern, not by asset quality alone.

### The two bar questions

**A. Do these frames read as belonging to the world in
`docs/reference/tetherbound-meadows-keyart.png`?**

**No.** The palette family is in the right neighborhood (green grass, warm dirt
paths, blue sky, occasional red roof), and comp8's tree avenue and comp4's
look-back composition are the closest matches to the key art's mood. But the key
art's defining qualities — dense, layered, painterly forestation with visible depth
through overlapping canopy, warm directional light with real form-shadow on every
surface, and a village/landmark that reads instantly as a destination — are present
in maybe two of eighteen frames and absent or contradicted in the rest. The flat
boulder reuse, the tiling ground texture visible at close range, and the
empty-grass compositions (comp3, comp7) are the biggest breaks from that board.

**B. Shown these frames beside `docs/reference/palworld-0*.jpg`, would someone say
these are trying to be the same kind of game?**

**No.** The Palworld shots are never just landscape — every one has a creature, a
fight, a base, or a companion doing something, with UI, saturated character
design, and a subject the frame is clearly about. These 18 frames are landscape and
traversal studies: pleasant-enough grass and trees with a lone, small, often
poorly-contrasted trainer figure and, at most, three near-invisible creature
silhouettes across the whole set. Set side by side, a viewer would read one set as
an action-creature game and the other as an environment/walking demo.

### Fixable-by-scene vs. needs-art-not-in-the-build

**Fixable by changing the scene (density, palette, lighting, composition,
scatter):**
- The empty mid-grounds in comp3, comp7, 04 — populate with existing trees, rocks,
  fences, or wildlife already used elsewhere in the set.
- Regular-interval shrub/flower scatter — re-seed placement with clustering and
  varied scale/rotation instead of near-constant spacing.
- The single reused flat boulder appearing 8+ times — vary rotation, scale, and
  add contact shadow/AO; or draw from more than one rock variant already in the
  build.
- Ground-texture tiling visible at close range (04, place5, comp7, comp4) — needs a
  texture/UV or detail-normal fix, which is a scene/material setting, not new art.
- Weak fence and landmark contrast (comp6, 03) — boost value/color separation from
  the ground so they read at distance.
- Time-of-day frame (05) not changing material response — a lighting/shader
  parameter issue, not new assets.

**Needs art not currently in the build:**
- Legible, appealingly-designed creatures large and detailed enough to be judged as
  "the point" of the game, per the rubric's explicit instruction — the pale shapes in
  comp5/comp6/comp8 cannot be evaluated as creature art at their current fidelity,
  and no amount of scene-side placement fixes that; it needs actual creature assets
  in these shots.
- A village/landmark structure with the layered, hand-placed density the key art
  shows (multiple buildings, fences, smoke, roads converging) — the single small
  house or rooftop cluster seen at a distance in several frames (03, 04, comp5,
  comp7) is a placeholder-scale structure, not a settlement.
- Tree canopy shading/material response to light (flat green blobs regardless of
  sun direction) — if this is the installed tree asset's baked/unlit material, that
  is an art/shader asset limitation, not a scene placement fix.
