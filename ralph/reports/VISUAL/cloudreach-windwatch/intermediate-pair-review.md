# Blind visual comparison: sets A and B

## Inspection and limits

I inspected both `sheet.jpg` contact sheets first, then opened every matched pair `001.png` through `010.png` individually at native 1920 × 1080 resolution with original image detail: twenty native frames in total. The sheets supplied the small-size readability check; the native images supplied the material, silhouette, grounding, and artifact checks.

I also visually inspected all seven supplied references under `D:/tetherbound/visual-acceptance/docs/reference/`:

- `tetherbound-meadows-keyart.png`
- `palworld-01-boss-fight-forest.jpg`
- `palworld-02-open-field-path.jpg`
- `palworld-03-field-boss-meadow.jpg`
- `palworld-04-plateau-landmark.jpg`
- `palworld-05-base-building.jpg`
- `boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`

I inspected only these comparison/reference images and their filenames. I did not inspect source, diffs, manifests, or existing reports/status documents; I did not run Godot or edit the game. I was not told which set is newer. These are static diagnostic views: the findings do not establish motion quality, performance, gameplay, or an earned player view.

## Whole-frame acceptance

| Set | Bar A: keyart world identity, without demanding painted pixel detail | Bar B: same kind of finished creature-adventure game as Palworld |
| --- | --- | --- |
| A | **NO** | **NO** |
| B | **NO** | **NO** |

Both sets have recognizable ingredients: a readable backpacked trainer, timber cottages, stonework, banners, green terrain, and a blue day/night sky. That establishes a direction, but does not establish the complete identity shown by the references. The keyart communicates inviting, layered natural landforms, integrated settlement edges, vegetation at believable relative scales, and distinct warm inhabited places. The aviary board shows how architecture can belong to a cloud landscape through a coherent silhouette and richly connected terraces. These frames instead repeatedly expose broad bare terrain, isolated buildings, blunt cliff walls, conspicuous cloud/geometry shapes, and coarse transitions. This judgment concerns composition, relationships, and finish, not matching illustration detail.

B usually improves the tower as an architectural object: the upper timber level, dark roof, projecting ledge, and roof ornament suggest a lookout with a purpose. A is more often a bare masonry shaft with an oversized flat cap. This local gain is real; it does not repair the frame around the tower or satisfy either acceptance bar.

Neither set demonstrates the creature appeal central to the Palworld references. No creature is clearly presented as an appealing focal character in these views. The trainer has a useful color break and backpack silhouette, but is always seen from behind in essentially the same neutral pose. The clothed figure and tables in the square add some inhabited character; they do not by themselves give the settlement the visual richness or character relationships evident in the references. I am judging only what these frames show, not claiming that creatures or other activity are absent from the game.

## Matched-pair preferences

Preferences concern the complete visible image, with small advantages stated as such. A preference is not a pass.

| Pair | Prefer | Visible reason |
| --- | --- | --- |
| 001, distant approach/day | **B** | The tiered roofed top turns the distant pillar into a recognizable lookout. Its broad upper silhouette survives the contact-sheet scale. The empty approach and excessive sky still overpower this modest improvement. |
| 002, distant approach/night | **B** | A slight preference: the upper tier remains distinguishable against the sky and conveys more building identity than A's cap. The roof is dark and the improvement is much smaller than in daylight. |
| 003, village approach/day | **B** | The timber upper story and roof connect the tower more naturally to the neighboring cottages. The tower reads as constructed space rather than an extruded stone shaft. Floating-looking grass at left and enormous vegetation at right remain severe distractions. |
| 004, village approach/night | **B** | The layered top still supplies architectural hierarchy, though its dark opening is less clear than by day. The trainer, grass, cliffs, and houses have substantially the same unresolved lighting and scale relationships. |
| 005, tower forecourt/day | **B** | This close view makes the new upper story easiest to understand. Wood, roof, ledge, masonry, and banners form a more intentional assembly. The plain upper infill and thick ledge are still crude, and the forecourt surface remains visibly broken into square patches. |
| 006, tower forecourt/night | **Tie** | B has more architectural information, but its dark upper level becomes a heavy block and the lowered banners crowd the trainer's head region. A's taller shaft provides cleaner vertical emphasis and more separation. Neither produces a convincing warmly occupied nighttime focal point. |
| 007, cliff-backed village/day | **Tie** | B improves the tower's building vocabulary, but the shorter, broader top merges more with the cottage roof and the cliff behind it. A has clearer landmark height and separation. These gains and losses approximately cancel from this angle. |
| 008, cliff-backed village/night | **A** | A's higher cap and exposed stone shaft separate the landmark more clearly above the cottage. B's dark layered top is compressed into the roof/cliff cluster and its added detail becomes visual clutter. Both suffer from very bright pale grass competing with the settlement. |
| 009, village square/day | **B** | The roofed upper level and visible projecting ornament give the square a more distinctive architectural anchor. The lower, heavier mass and overlap with the chimney are drawbacks, but the object is more convincing as a lookout than A's capped shaft. The patchwork ground remains the most obvious finish failure. |
| 010, village square/night | **B** | A small preference for the recognizable upper-story structure and stronger material grouping. The ornament and roof partly collapse into a dark silhouette, and the lowered tower no longer commands the square as strongly. The bright trainer and windows still do not add up to coherent localized lighting. |

## Regressions and rubric findings

Since chronology is unknown, these are B-relative-to-A tradeoffs, not claims about development history.

- **Landmark height and separation regress in B.** Its main cap is visibly lower, with more horizontal mass close to the cottages. This most clearly hurts 007–008; it also tightens the roof/chimney/tower overlap in 009–010.
- **Nighttime top readability is weaker than B's daytime gain suggests.** The dark roof/opening has little internal separation in 006 and 008. Added geometry does not automatically become useful detail at small size.
- **The roof ornament is not equally legible from every direction.** It looks like a projecting angular vane in 009, but nearly a thin upright spike in 003–004. It does not yet supply a consistently recognizable emblem.

Across both sets, the trainer silhouette is serviceable and the day palette has a plausible grass/stone/wood grouping. Composition is strongest in the square, where cottages bracket the trainer and the tower can anchor the middle distance. Most approach frames lack that structure: the sky and near-empty foreground consume much of the image. Depth depends heavily on crude cliff masses rather than a convincing progression of terrain, vegetation, and atmosphere. Long cast shadows help daytime contact, but broad flat surfaces and abrupt material borders weaken grounding. The same pale/bright trainer treatment repeats at night, while grass can appear brighter than the village; warm windows and visible hanging bulbs do not create a persuasive network of lit occupied spaces. Inhabited character is suggested by benches, containers, banners, a tent, and a person, but remains sparse.

## Top three concrete scene defects

1. **The square's ground transition breaks into an obvious grid of isolated tan rectangles over green terrain** (005–006 and especially 009–010). At native resolution this reads as a surface artifact rather than worn earth. Replace the hard square breakup with a coherent, continuous path/courtyard edge and believable smaller wear variation.
2. **Landscape and vegetation relationships expose a visibly unfinished world boundary** (especially 003–004 and 007–008). A tuft of giant blades appears perched on an isolated cloud-like shape at left; white faceted forms interrupt the distant space; tall blades form abrupt oversized walls beside houses; the cliff backdrop is broad and blunt. Resolve those visible intersections and scale discontinuities, then build a layered settlement edge rather than leaving buildings against raw empty space.
3. **Night value hierarchy directs attention away from inhabited places** (especially 006 and 008). Pale foreground grass, bright clothing, and high-contrast roof edges compete with dark settlement masses, while the tower has no convincing light cue for its occupied upper level. Give visible lamps/windows believable nearby pools of light, retain controlled cool fill, and keep the settlement's intended focal shapes readable without making unrelated foliage the brightest subject.

B is generally the stronger tower treatment. Both complete image sets remain below both requested visual bars.
