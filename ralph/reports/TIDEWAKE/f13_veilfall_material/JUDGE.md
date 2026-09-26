# Veilfall material pass — code-blind visual verdict (r1)

Inputs judged: `ralph/reports/TIDEWAKE/f13_veilfall_material/{before,after}/*.jpg` (5 stands × day/night), against
`docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`, and
`docs/reference/boards-2026-09-06/water-veilfall-stronghold-board.png`. Only images were examined. I scored nothing.

**Bottom line.** The after set improves the Veilfall at every stand. The before mountain was a pale, featureless grey-white
cone that read as a snowy peak or a fogged blob. The after mountain is darker slate with white vertical strokes, so it now
reads as rock with *something* running down it. It still does not read as the board's Veilfall. The board shows a terraced,
tree-crowned crag stack with broad white falls, mist at the base and an arched gate. The build shows one smooth bell-shaped
cone with 3–4 thin pinstripes. The falls are about 1/10 as wide as the board's, they have no mist or plunge pool, and there is
no vegetation or tiered silhouette. The sea currents are barely readable.

---

## Per-rubric defects (by frame)

### 1. Silhouette / readability at 30%
- **after/veilfall-far-first-shore-day**: at 30% the landmark is a small grey dome with 3 white ticks. You can read it as "a mountain". "Waterfalls" does not come through: the ticks read as scratches or snow gullies. The dome is also only about 60 px wide and sits **behind the fence's top rail**, so its lower half is cut by a horizontal plank.
- **after/veilfall-far-first-shore-night**: the falls disappear. Only faint blue-white streaks remain on a pale dome, so at 30% it reads as a moonlit hill.
- **after/veilfall-mid-salt-crown-day**: the cone reads clearly as a mountain. The three falls are single-pixel-to-10 px **white lines of constant width running top to bottom**, with evenly spaced white "beads" (mist puffs) along them. At small size they read as **ski runs, roads or string with pearls**, not falls. Nothing widens toward the base, nothing plumes and nothing pools. The left sub-peak has a thin white line tracing its *ridge edge*, which reads as an outline or rim-light bug rather than water.
- **after/veilfall-mid-salt-crown-night**: the falls turn into faint lavender strokes. A dark diagonal band crosses the upper third like a terrace edge. The silhouette reads as "mountain" but the falls are lost.
- **after/current-sluice-veilfall-day**: this is the best Veilfall read in the set. The central fall is the widest stroke and has a stepped break at its foot, the side falls follow the flanks, and the mist dots sit at the base. Even here it reads as a slate volcano with white paint lines.
- **after/veilfall-near-arrival-day**: the landmark isn't identifiable as a waterfall at all. You see two wet-rock walls and a narrow slot with a thin pale sliver (the fall?) in the gap behind the lantern. There's no spray and no water on the ground, and no gate is visible. The area name "The Veilfall" in the HUD does the identifying.
- **after/veilfall-near-arrival-night**: better. The bright pale sheet in the slot now reads as falling water or a veil of light, and it is the most atmospheric Veilfall frame in the set.

### 2. Colour and value structure
- The after mountain moves from near-white (it merged with the cloud value in **before/*-day**) to mid slate grey. That creates a real figure/ground separation against the sky in **after/veilfall-mid-salt-crown-day** and **after/current-sluice-veilfall-day**. This is the pass's main win.
- The slate is now **cold and desaturated against a warm, saturated foreground** (orange-yellow sand, lime grass). The board's rock is warm grey with lots of green foliage. In the build the mountain reads as belonging to a different, colder game than the beach in front of it (**after/veilfall-mid-salt-crown-day**).
- The value range is still compressed at night: sky, mountain and sea all sit in one mid-blue band (**after/veilfall-mid-salt-crown-night**, **after/current-sluice-veilfall-night**). No darks anchor the landmark base.
- **Oxblood/red leak:** none on friendly or landmark elements. The pink/salmon fronds on the creatures in **after/current-sluice-veilfall-*** are coral-pink, not oxblood. They're fine, but worth watching because they are the only warm-red accent in these frames.

### 3. Intentionality
- The mountain body is a single smooth revolved or noise-lofted cone (**mid, sluice**). It has no terraces, ledges, trees or cliff breaks, so it reads as **generator output**.
- The falls are uniform-width lines on the mountain's own surface. They read as **decals painted on**, not water leaving a lip and falling free. The evenly spaced mist beads (**after/veilfall-mid-salt-crown-day**) look procedural.
- **after/veilfall-near-arrival-day**: the rock walls have **regular horizontal banding, like contour lines** at a fixed interval. That reads as a triplanar or stripe texture, not strata.
- The small moss-topped rock pillars in front of the cone (**after/current-sluice-veilfall-day**) are the only authored-looking props, but they read as tiny posts at the mountain's scale.

### 4. Lighting
- Day and night read clearly everywhere. The night moon, blue grade and warm lantern/campfire (**near-arrival-night**) are good.
- The day cone has **almost no form shading**: flat mid-grey with one soft terminator (**after/veilfall-mid-salt-crown-day**). There's no sun side versus shade side and no occlusion in the fall channels.
- **after/veilfall-near-arrival-day**: the tree shadows on the rock walls are **hard, black, irregular blotches**, notably upper right. At this distance they read as dirt or decal splotches.

### 5. Horizon and depth
- In the **before/** far and mid frames, aerial perspective was eating the mountain, which merged into the sky. In **after/** it pushes back far less. The mountain now reads as solid, but at 4 km (**after/veilfall-far-first-shore-day**) it has **almost the same contrast as the 1.6 km view**, so the distance reads shorter than claimed. Some haze toward the sky colour at the base would help, as long as it doesn't erase the falls.
- The sea horizon is a hard cyan line at every stand, and nothing appears beyond it: no other islands or haze layers. The board's approach view sets the Veilfall among a scatter of sea stacks.
- No LOD or chunk seams are visible on the mountain across stands. One suspected pop/state difference: the creatures and props differ between before and after in **current-sluice-veilfall** (wild spawns). That isn't a defect, but it makes A/B comparison noisier.

### 6. Interface
- The **Main Story** panel covers the right shoulder of the mountain in **veilfall-mid-salt-crown-*** (before and after) and the right edge of the far stand's trees. For a landmark stand, the camera should put the subject away from the panel.
- The **fence** in **veilfall-far-first-shore-*** and **current-first-shore-reedhaven-*** is scene composition, not UI, but it crosses both the landmark and the current.

### 7. Artefacts
- **current-sluice-veilfall-* (before and after)**: a **flat, untextured tan rectangle** (a wall or slab about 2 m tall and about 8 trainer-widths long) stands right behind the trainer. At **night it renders pure black** with no lighting. This is the worst artefact in the set, and it sits dead centre of a landmark stand.
- **veilfall-near-arrival-* (before and after)**: the left rock mass has a **thin bright white diagonal sliver** along its edge, strongest at night (x≈150–250). It reads as a light leak, a backface or a seam between two meshes.
- **veilfall-near-arrival-day (after)**: the top-centre overhang reads as a **dark box with a moss slab on top**, unanchored against the sky gap.
- **veilfall-mid-salt-crown-day (after)**: the white line along the left sub-peak's ridge reads as an outline or seam artefact, not water.
- **current-sluice-veilfall-day, veilfall-mid-salt-crown-day (both sets)**: **round white bokeh blobs** float on the sea surface. They read as specular sprites that are too large and too soft, like lens dirt rather than sun glints. They are stronger in after.
- Sand in every day frame has a **coarse, blurry repeating noise**, most visible in the foreground of **veilfall-far-first-shore-day**. There is no stretching, but it's muddy.
- The grey stone pads (flat quads) on the sand in **veilfall-far-first-shore-*** and **current-first-shore-reedhaven-*** are paper-thin with no edge thickness.

### 8. Scale against the 1.80 m trainer
- **veilfall-near-arrival**: the walls tower over the trainer (fine). The pale fall sliver in the slot, though, is only about trainer width at the apparent distance. The board's "broad white falls" would be tens of metres wide, and here they aren't.
- **mid / sluice**: the moss pillars at the cone's base read as fence-post size relative to the cone, which makes the mountain feel small and toy-like. The flat tan slab in **current-sluice-veilfall** is about 1.2× trainer height, with no function the image can identify.
- The creatures in **current-sluice-veilfall-*** are comfortably larger than the trainer, which agrees with the rule.

### Sea currents
- **after/current-first-shore-reedhaven-day**: I can barely see them. There are some faint white dashes in the water behind the fence, and at 100% they are hard to find.
- **after/current-first-shore-reedhaven-night**: more readable, as a fan of thin white dashes radiating toward the camera. They read as **road lane markings or tracer lines**, not foam or flow. The fence occludes most of the area.
- **after/current-sluice-veilfall-day/night**: there's a thin white spray line or a row of sparkle dots just past the slab. It doesn't read as a current, and I can't tell its direction.
- **before/**: no current visual at all. **So after is an improvement from nothing to "something", but not a readable current.** It needs foam lanes of varying width, a darker or lighter water band, flow-aligned ripple texture and edge foam where it meets calm water.

---

## Verdict per stand

### Far — `veilfall-far-first-shore` (≈4 km)
**Top 3 gaps between after and the references:**
1. The landmark is **tiny, behind the fence rail, and just a dome**. The board's approach view makes the Veilfall the dominant, tiered, tree-green crag on the horizon (**after/…-day**).
2. **The falls aren't legible**: three white ticks by day, and they vanish at night (**after/…-night**).
3. **No landmark mood**: no mist, no island context and no sea stacks. The foreground is a flat sand plane with thin quads and a fence.

- **Bar A (key art/board world):** **No.** The sky, sea and green islands carry some key-art flavour. The dome shape and the absent falls sink it.
- **Bar B (Palworld kind of game):** **No.** The trainer model and HUD say "creature adventure". The empty flat foreground and the placeholder-looking landmark read as an early prototype, not a finished open-world frame like `palworld-04`.
- **Fixable in scene:** reframe the stand so the fence doesn't cross the landmark; warm the rock grey; widen the falls and brighten them against the rock at distance; add a base mist or haze card; add distance fog so the 4 km depth reads; add the existing sea-stack rocks as middle-ground islands.
- **Needs new art:** a tiered crag silhouette with cliff steps and tree crown, which the single cone mesh can't provide.
- **Improved vs before?** **Yes, slightly.** The before dome was a white blob with no falls. The after dome is darker and shows marks.

### Mid — `veilfall-mid-salt-crown` (≈1.6 km) and `current-sluice-veilfall` (≈1 km)
**Top 3 gaps between after and the references:**
1. **The falls are constant-width pinstripes with bead-like mist dots** (**after/veilfall-mid-salt-crown-day**). The board has broad sheets that break over ledges into white plumes and mist at the sea.
2. **A smooth bell cone with no terraces, trees or cliffs** (**after/current-sluice-veilfall-day**). The board's identity is a stack of green-capped cliffs.
3. **Cold slate against a hot foreground**, with no form lighting, so the landmark sits apart from the beach palette (**after/veilfall-mid-salt-crown-day**). Also the **black/tan slab artefact** in **after/current-sluice-veilfall-***.

- **Bar A:** **No** for salt-crown. **Borderline no** for sluice-day, which is the closest frame: a central fall with a break and mist at its foot.
- **Bar B:** **No.** The creatures in the sluice frame help it read as a creature game. The untextured slab and the painted-line mountain place it below the Palworld finish bar.
- **Fixable in scene:** widen the falls to 3–5× and taper them wider toward the base; add foam or mist plumes at breaks and at the sea (particles or cards); break the bead spacing; warm and green-tint the rock, and add a moss or grass tint on upper slopes; add sun/shade form lighting and channel occlusion; delete or texture the slab; remove the ridge-outline line; shrink the water bokeh sprites.
- **Needs new art:** a terraced, cliffed mountain mesh with ledges for the falls to leave, plus a scatter of trees on it. Per the board, that means the Meshy/reference path, not a shader.
- **Improved vs before?** **Yes, clearly.** Before, the mountain was a near-white ghost that merged with the clouds. After, it is solid and marked as having falling water. At night the gain is small.

### Near — `veilfall-near-arrival` (≈95 m)
**Top 3 gaps between after and the references:**
1. **No visible waterfall mass, mist or pool at the gate** (**after/…-day**). The board's "falls entrance" has a broad curtain crashing into water in front of a lit arch. Here it is a dry grass slot.
2. **Contour-line banding on the rock walls** and hard black tree-shadow blotches read as procedural texture (**after/…-day**).
3. **No gate or architecture visible**: no arch, banners or lanterns except one post lamp. The white edge sliver and the box-shaped overhang are artefacts.

- **Bar A:** **Day no. Night borderline yes on mood.** The pale veil in the dark slot, the campfire smoke and the lantern come closest to the board's night view.
- **Bar B:** **No by day.** The wet-slate rock is a genuine step toward a shipping-game material, but the empty slot and banded texture read as unfinished. **Night nearly yes**, with good mood and lighting.
- **Fixable in scene:** put a broad falls curtain (particle or scrolling card) plus a mist volume and a foam pool in the slot; break the band frequency with noise or a second scale; soften or tone the tree shadows; fix the left-edge light sliver and the floating overhang box; place the existing arch, banner and torch props if they're in the build.
- **Needs new art:** the stronghold gate/arch structure, if it isn't already in the build.
- **Improved vs before?** **Yes.** Before, the walls were flat beige plaster with no identity. After, they are wet dark rock and the night slot reads as a veil. The day slot still shows no water.

### Currents — `current-first-shore-reedhaven`, `current-sluice-veilfall`
- **Improved vs before?** **Marginally.** Before there was nothing. After has faint white dashes that are hidden by the fence at Reedhaven and read as lane markings. The current is **not readable** in either day frame. **Fixable in scene**: shader and particles (flow-aligned foam bands, colour-shifted water lane, edge foam), plus moving the Reedhaven stand or opening the fence so the current is in view.

---

## Summary table

| Stand | Bar A | Bar B | Improved? | Main fix class |
|---|---|---|---|---|
| Far (4 km) | No | No | Slightly | Scene (framing, fall width, haze) + new crag mesh |
| Mid (1.6 km / 1 km) | No (sluice-day borderline) | No | Yes, clearly | Scene (fall shape, mist, palette, slab artefact) + new terraced mesh |
| Near (95 m) | Day no / night borderline | Day no / night nearly | Yes | Scene (falls curtain, mist, texture banding, artefacts) + gate art if absent |
| Currents | — | — | Marginally | Scene (shader/particles, framing) |

---

## Lane note (not part of the verdict)

- The verdict above judged `before/` against `after_r1/` (commit 03c5eb5d). `before/` was captured on main 79fe8904.
- `after_r2/` is one iteration on the verdict's scene-fixable findings. It was **not judged**, because the owner wind-down order arrived before a second round could start. Its changes:
  - falls are 2-3x wider and taper wider toward the foot;
  - the ridge-line fall is dropped and the evenly spaced mid-fall mist beads are removed, leaving clustered foot plumes;
  - the rock is warmer, with moss tint on the upper slopes of the far silhouette;
  - the bedding bands are weaker (the contour-line finding);
  - the far tone is lighter and hazier at 4 km, and the minimum fall width is larger;
  - current foam gets a faint disturbed-water lane under the dashes, with variable dash girth.
- Every frame was captured locally with the X04 script `tools/art_pipeline/capture_tidewake_matrix.gd`, already on main. No GitHub render run was used: the one dispatched run, 36255659562, was cancelled while still queued.
