# Cloudreach Cliffs — blind visual judge, BEFORE (branch point)

Stands 01, 02-broken-causeways, 04, 11 rendered from `claude/second-biome-art-plan-470zru`
head (`6900f553`, the crown-relief/turf-fill commit) with
`tools/_capture_cloudreach_cliff_options.gd`. The judge was given the contact sheet, the
four full frames and `docs/reference/` only — not the source, the conversation, or what
was about to change.

Reproduced verbatim.

---

# Visual verdict — Cloudreach Cliffs, `shots/atmos_before/`

Read at sheet size first. At thumbnail scale the sheet reads as four variations on *green hill, grey lump, blue sky*. The one thing that should be unmistakable — a creature — is not identifiable at all until you open the full frame.

---

## Defects, ordered

### 1. The creature is not good enough to be the thing the game is about, and there is only one of it. (11-aerie-ground-connection)

This is the finding that goes first. The white winged fox-bird beside the trainer is the only creature in the entire survey, and it appears **twice — the same asset, same colour, same pose, staged eight metres apart** in a single frame. There is no second species anywhere in four frames.

As art it does not hold: the body is a low-frequency white blob with blotchy grey mottling that reads as compression noise rather than fur or feather; the wings are two thin cards with a smeary blue-white gradient and no feather structure, no thickness, no edge definition; the eyes are two flat black ovals with a single white dot. Set it beside `palworld-01`'s Mammorest — carved shapes, a defined jaw, chunky readable limbs, a tusk silhouette you'd recognise as a mute icon — or `palworld-04`'s two mounts, whose yellow-and-blue plumage reads as a designed pattern at 40 pixels. The Tetherbound creature has no shape language at all. At sheet size it is a white smudge you would mistake for a rock highlight.

Worse, it is staged as scenery. In `palworld-01`, `-03` and `-04` the pal is the largest, most saturated, highest-contrast shape in the frame — the frame is *about* the creature. Here the creature occupies maybe 1.5% of one frame out of four, in the background, behind the player's shoulder, at lower contrast than the tree trunks. Nothing in this sheet tells you this is a creature game.

**Relative scale is defensible** — measured against the 1.80 m trainer using foot-position-to-horizon for depth, the creature comes out around 1.9–2.1 m including ears, i.e. slightly taller than the player. That part is fine. The problem is the art and the staging, not the metre.

### 2. The trainer is standing in bind pose in all four frames. (all four)

Arms held straight out from the shoulders, elbows locked, fingers splayed and limp. This is an A-pose, not an idle. It is present in 01, 02, 04 and 11 without exception, and at full size in the 11 and 04 crops it is unmistakable — the character reads as a mannequin on a stand, not a person standing on a hill. Every Palworld reference has the character in a weighted, readable pose: braced with a rifle (`-01`), mid-swing (`-03`), leaning on a spear (`-05`). This single defect does more damage to "is a person in this world" than any lighting change could repair.

The trainer's own asset is also soft: the hair is one undifferentiated brown clump, the backpack texture is muddy at 4× zoom, and the face is never shown. Against `palworld-01`'s character — crisp braid, defined leather straps, a readable jaw — it is a step behind.

### 3. There is no highlight range. The frames live in the bottom two-thirds of the value scale. (all four, worst in 04)

This is measurable and it is the largest single gap to both references.

| | p50 | p90 | p99 | mean sat |
|---|---|---|---|---|
| 01-arrival | 107 | 136 | 165 | 54% |
| 02-causeways | 108 | 138 | 170 | 49% |
| 04-high-roost | 95 | **121** | **147** | 58% |
| 11-aerie | 93 | 132 | 165 | 58% |
| keyart (main panel) | 116 | **191** | **231** | 41% |
| palworld-02 | 130 | **209** | **223** | 40% |
| palworld-04 | 102 | **224** | **241** | 39% |

Both references put their top decile at 190–224 and their brightest pixels at 223–241 — sunlit grass, blown sky, specular pops on water and armour. Tetherbound's *brightest one percent* tops out at 147–170, i.e. a mid-grey. Nothing in any of these four frames is bright. Meanwhile saturation runs 49–58% against the references' 39–41%. The result is poster-paint green at half the brightness it should be: **more saturated and darker at the same time**, which is the specific combination that reads as "muddy" no matter how vivid the hue is.

Concretely visible: the sky top in 01 samples (74,120,148) — a dull, dark, desaturated blue where the keyart's skies are a bright cyan; the big foreground oak's canopy in 01 samples (20,39,0), a near-black green, which is why it reads as a black blob on the contact sheet.

### 4. The two headline landmarks are unlit black masses with a texture artifact drawn across them. (11-aerie-ground-connection, 04-high-roost-before-fly)

The central spire in 11 samples close to black across its entire face. It has **no lit side at all** — no sky fill, no bounce, no ambient gradient. On top of that blackness sit a dozen **bright white-cyan curved scratch lines**, swirling across the rock face like chalk. That is the single most obviously broken thing in the survey: it reads as a UV smear or an anisotropic-specular artifact, not as a surface. Underneath it, horizontal contour banding rings wrap the whole mass — the heightmap's contour lines showing through the material.

Frame 04's mesa is the same failure: it samples (22,15,8), functionally black, with the same contour banding and the same lack of any lit facet. In a region called Cloudreach Cliffs, the two cliffs are silhouettes with defects painted on them. The keyart's stronghold and the standing-stone panel both keep shadowed rock *readable* — colour in the shadow, strata catching light, a lit edge separating it from sky. `palworld-04`'s plateau does the same in real time.

### 5. The midground is visibly generator output. (01-arrival-first-reveal, right half)

Five trees along the path: same species, same canopy silhouette, near-identical height, spaced at near-regular intervals. No clustering, no clearing, no sapling, no fallen trunk, no scale variety. Two boulders in the same view are the same mesh at two rotations. The bush cards form a **straight-edged rectangular patch** with a hard border where the scatter mask ends. The cliff walls left and right are one slab mesh arrayed into a picket fence, with green moss painted along horizontal ledges in dead-straight lines.

Compare `palworld-02`: trees cluster at the treeline and thin toward the path, rock outcrops vary from boulder to wall, and the path has a worn edge that argues something walks there. Compare the keyart's oak-grove panel: trunks of four different diameters, a clearing, undergrowth banked against the bases.

### 6. Grass exists only as a ring around the camera; past that the ground is a tiling texture. (01, 02, 04, 11)

Frames 01 and 02 have a dense wall of grass cards in the near foreground and essentially none by the time you reach the player's own feet. Frame 04 and frame 11's foreground lawn have **no grass instances at all** — bare vertex-shaded green.

Zoomed into 02's foreground, the ground texture shows an unmistakable **repeating checkerboard tile**, roughly 60-pixel squares in a regular grid of alternating light and dark. The grass blades themselves are single flat untextured ribbons, unlit on the back face, crossing at hard X shapes with aliased white edges — loose polygons, not tufts. In the near foreground they are scaled so large they read as reeds and form an opaque wall across the bottom third of 01 and 02.

The references keep ground cover continuous into the middle distance (`palworld-03`, `-05`) or replace it with authored dirt and rock, never with a bare tiled plane.

### 7. There is nothing on the horizon. Depth does not read. (02-broken-causeways, 04-high-roost-before-fly)

In 02, past the grass edge, there is a flat pale blue-grey void — no distant ranges, no lower cloud deck, no further spires, nothing. In 04, roughly 60% of the frame is empty sky and empty green with a single dark blob between them. Both references stack three or four depth layers: keyart panels go near meadow → mid grove/settlement → far snow range → cumulus; `palworld-05` puts snowy peaks behind the base; `palworld-04` puts a tower landmark through haze.

Aerial perspective is also inverted here. In 01 the foreground grass samples (94,132,47) and the midground grass (121,156,64) — **distance is brighter and greener than the near ground**. Distance therefore reads only as "smaller", not "further". There is a pale grey haze band at the horizon but it starts abruptly and is a flat wash rather than a gradient.

And in a region named for reaching clouds, there are **no clouds** — only thin wispy cirrus streaks in all four skies. Both references are full of cumulus.

### 8. The frame called "broken causeways" contains no break, no drop and no verticality. (02-broken-causeways)

The bridge is a pristine, straight, unbroken wooden ramp lying on a grassy hillside. There is no chasm beneath it, no gap in the deck, no exposure, no sky below — you could step off either side onto lawn. For the establishing shot of a high vertical cliff region, this frame contains no height at all. Whatever the fiction is, the picture does not deliver it.

Prop-level problems in the same frame: the rope railings are perfectly straight rigid cylinders with **zero catenary sag**; the three bells hang from nothing visible and cast no shadow; the gate uprights show obvious vertical texture repeat; and every post is stabbed into the grass with no contact dirt, no debris, no transition — the exact "props stabbed into ground" failure `docs/reference/README.md` records from the previous prototype.

### 9. The sky islands read as broken geometry, not as authored landmarks. (04-high-roost-before-fly, 11-aerie-ground-connection)

The floating mass in 04 is an inverted grey bell with two brown sticks poking out the top, flat-lit to a single mid-grey, with four or five **detached rock blobs hanging in the air beneath it** connected to nothing. It has no visible top surface, no vegetation, no silhouette worth reading. The same object recurs at the top of 11. On first look it reads as a mesh that failed to load or a chunk that failed to cull — a bug, not a choice. It is the most distinctive shape in frame 04 and it is the least finished thing in the survey.

### 10. Cast shadows disagree between frames, and contact shadows are missing. (01 vs 02/04/11)

Frame 01 has **no cast shadows anywhere**: the large foreground oak throws nothing on the grass beneath it, the cart throws nothing, the rock columns throw nothing, the grass blades throw nothing. It is entirely ambient. Frames 04 and 11 have long, low-sun directional shadows three body-lengths long. Seen together on the sheet, 01 and 04 disagree about what time of day it is in the same region.

Where shadows do exist they misbehave. In 02 the player's shadow is a slab with a **razor-straight vertical boundary** running to the bottom edge of the frame — a cascade or clipped-volume edge, not a body shadow. In 11 the creature has no contact shadow under its feet at all while the trees beside it cast hard ones, so it floats.

### 11. The gatehouse is buried in the mesa and has a hole in it. (01-arrival-first-reveal)

At 4× zoom the gatehouse arch is **sliced off by the mesa's silhouette** — the arch's springing line and the whole footing are below the rock edge, so the building has no ground plane and reads as sunk. Between the two turrets there is a bright pale-blue horizontal band with a white sliver in it: sky showing through the wall walk plus what looks like an untextured or z-fighting face. It is also stylistically adrift — a photographic tiling stone with vertical grime streaks and moss decals, against hand-painted trees and blurry clay rock. And as architecture it is a free-standing arch on a bare plug with no walls, no approach and no continuation: a prop dropped on a rock, not a landmark.

### 12. Rock materials do not agree with each other. (01-arrival-first-reveal)

The two boulders in the midground are pale, nearly white, effectively blown out, with no value relationship to the dark grey cliff slabs directly behind them. They read as polystyrene. Two rock types in one shot with no shared material logic.

### 13. Grass is a decal knife-cut onto rock. (01-arrival-first-reveal, 02-broken-causeways)

The bright green wedge running up the mesa in 01 is a flat triangle of pure green pasted onto grey rock along a perfectly straight boundary. The same thing happens on the cliff cap in 02 — a razor line between rock and grass with no blend, no scattered stones, no vegetation creeping down the slope.

### 14. Foliage alpha is unfiltered. (11-aerie-ground-connection)

Canopy edges against the sky show hard stair-stepped jaggies on every leaf card — no alpha-to-coverage, no MSAA on the cutout. Zoomed, the tree crowns look chewed.

### 15. Trees are one mesh uniformly scaled, so leaf size scales with trunk size. (01-arrival-first-reveal, 11-aerie-ground-connection)

The foreground oak in 01 has a trunk about 1.4 m across measured against the trainer, and its individual leaf cards work out to roughly 0.4–0.5 m each. In 11 the giant trunks at frame left and right carry leaf clumps visibly larger than the identical-shaped mid-distance trees' clumps. Leaf size should be constant across a species; here it is a scale multiplier, which is what tells you these are the same asset at three sizes.

### 16. The sun is a flat white circle. (04-high-roost-before-fly)

The disc samples (231,231,231) and the sky 35 pixels away samples (45,103,137). No halo, no scattering falloff, no brightening of the sky toward it, no bloom. It reads as a decal stamped on the dome. Compounding this, its high position contradicts the three-body-length shadow the trainer casts in the same frame.

### 17. The world is not lived-in. (all four)

Total inventory of human-made or living things across four frames: one cart, a handful of fence posts, one bridge, some bare scaffold poles floating in front of the spire in 11 with no joinery and no purpose, one glowing pickup, one human, and two copies of one bird. No fires, no NPCs, no camps, no washing, no tracks, no animals in the distance. `palworld-05` alone has crates, a chest, a workbench, a harvest barrel, two pals working and a chicken. The keyart's settlement panel has a well, a banner, fences, roofs, paths worn between buildings.

---

**Two rubric items I could not score:** there is **no UI in any of these frames**, so safe area, hierarchy and legibility are unjudgeable here. And the **Team Tether oxblood is correctly reserved** — I found no oxblood red anywhere in the four frames; the bridge and post woods sit at (178,135,78) and (127,93,53), warm browns nowhere near the danger colour. That one passes cleanly.

---

## The three things that most separate these frames from the references

**1. The references have a top end; these frames do not.** Every Palworld shot and the keyart's main panel put their brightest pixels at 223–241 and their top decile above 190. All four Tetherbound frames stop dead around 147–170 with the top decile at 121–138, while running 10–18 points *more* saturated. Nowhere is this louder than **04-high-roost-before-fly**, whose entire landmark mesa samples (22,15,8) — black — under a sun disc that samples (231,231,231) with no scattering between them. The references look sunlit; these look like a sunlit palette rendered at night with the exposure pushed.

**2. The references' worlds are populated and authored; this one is scattered.** `palworld-02`'s treeline clusters and thins, its outcrops vary from boulder to wall, its path is worn. The keyart's oak grove has four trunk diameters, a clearing and banked undergrowth. **01-arrival-first-reveal** answers with five same-species same-height trees at regular intervals, one boulder mesh twice, a bush patch with a straight rectangular edge, and cliff walls made of one slab arrayed like a picket fence. And **02-broken-causeways** shows the whole habitable world stopping at a grass edge with flat grey nothing beyond, where every reference stacks three or four depth layers out to a snow range.

**3. The references are about their creatures; these frames barely contain one.** In `palworld-01`, `-03` and `-04` the pal is the largest, most saturated, highest-contrast object in frame — you know what kind of game it is from the thumbnail. **11-aerie-ground-connection** is the only frame with a creature at all, it is duplicated, it is a soft white blob with card wings and dot eyes, it is staged behind the player's shoulder at lower contrast than the tree trunks, and at contact-sheet size it is not identifiable as a creature. Meanwhile the trainer is in bind pose in all four frames with his arms straight out, so the sheet contains no posed, weighted character either.

---

## Bar questions

### A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`? — **No.**

**What carried:** the raw ingredient list is right. Rolling green hills, purple wildflowers, a dirt path, oak-shaped canopies, rustic timber construction, a stone gatehouse landmark, a blue day sky — these are the board's nouns and they are all present. Hue selection is broadly on-palette, and the oxblood is properly reserved. **01-arrival-first-reveal** in particular gets the *composition* of a keyart panel: framing tree at left, path leading the eye, landmark on a height.

**What sank it:** the board's own art note says *vibrant, readable colours*. These are saturated but not vibrant, because vibrance needs a top end and there isn't one — the keyart panel runs p90 191/p99 231 at 41% saturation; the build runs 121–138/147–170 at 49–58%. The board says *cozy and inviting*; **04-high-roost-before-fly** is a black lump under a stamped-on sun with a broken-looking grey chunk hanging in the sky, and **11-aerie-ground-connection** is a black tower with white scratch artifacts on it — those read as forbidding and unfinished, not cozy. The board says *silhouettes and landmarks visible from distance*; the mesa in 01, the spire in 11 and the mesa in 04 are all soft undifferentiated blobs with no strata, no profile and no lit edge. And the board's every panel has a distance — mountains, cloud decks, layered ridges — where **02-broken-causeways** ends in a grey void.

**Fixable in-scene (most of it):** the value range and the flat-lit rock are lighting and tonemapping work, not asset work — the spire and mesa need a lit face and sky fill, and the whole survey needs a highlight range. The empty horizon needs distant silhouette geometry and a cloud layer, both scene content. The procedural scatter in 01 is a placement pass: cluster the trees, vary their scale non-uniformly, break the rectangular bush mask, stop arraying the rock slab. The grass ring, the tiling checkerboard on the ground texture, the knife-edge grass/rock decals in 01 and 02, the missing shadows in 01 and the straight-edged shadow in 02 are all scene, material and light settings.

**Not fixable in-scene:** the near-black spire's white scratch lines and contour banding are a broken material/UV on that asset. The gatehouse's buried footing and the sky-through-the-wall gap need the mesh fixed or replaced. The floating sky islands need to be modelled as islands rather than untextured lumps with detached debris. The blobby, strata-less cliff meshes are the wrong asset for a region built on cliffs — no light will make a smooth clay lump read as rock face.

### B. Shown beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game? — **No.**

**What carried:** the third-person over-shoulder camera, the backpacked adventurer, the stylised-realism intent and the bright natural palette all point at the same genre shelf. **02-broken-causeways** in isolation could sit near `palworld-02` as a traversal shot.

**What sank it:** three things, and none of them is fidelity.

First, **there is no creature story being told**. Palworld's four creature-bearing shots put the pal front, big, saturated and bespoke. Tetherbound's four frames contain one species, duplicated, background-staged, at a level of finish — mottled white blob, two gradient cards for wings, dot eyes — that would not survive being cropped into `palworld-01` next to Mammorest. Someone shown these side by side would say Palworld is a creature game and this is a walking-simulator prototype.

Second, **the trainer is in bind pose in every frame**. Palworld's characters are always posed and weighted. A mannequin with its arms out is not the same category of thing.

Third, **the values**. Palworld's frames breathe from 30 to 230; these compress into 20–170. That is the difference between "sunny afternoon" and "grey afternoon with the saturation slider pushed", and it is visible instantly with the two sets side by side.

**Fixable in-scene:** the value range, the ground-cover density and its falloff, the empty horizon, the flat-lit landmarks, the scatter regularity, the missing and misbehaving shadows. Also cheap and high-yield: **stage the creatures**. Even the current asset would move the needle if a frame put it large, forward, in a lit pocket, with the player reacting to it — the survey currently has no frame that is *about* a creature.

**Not fixable in-scene — this is what has to be bought or made:**
- **A creature roster with real character art.** One soft white asset, duplicated, is not a creature game's cast. The keyart's silhouette row asks for rabbit, boar, deer, raptor, turtle and canine spread; this sheet covers one point on it, badly. This is the single largest non-scene gap and no lighting or scatter pass touches it.
- **An idle/locomotion animation set for the trainer.** Bind pose is not a rendering setting.
- **Cliff geometry that reads as cliff.** The current rock is a soft blobby mass with contour banding and, on the frame-11 spire, a broken material drawing white lines across it. A region called Cloudreach Cliffs needs strata, facets and profile in the mesh.
- **Finished sky-island assets**, or their removal until they exist. What is in 04 and 11 currently reads as a load failure.
- **Distant-silhouette and cloud assets** to give the horizon something to be. Placement is scene work; the ranges and cloud deck themselves have to exist first.
