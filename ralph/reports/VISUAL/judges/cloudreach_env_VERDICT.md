# Cloudreach Cliffs: environment verdict (code-blind)

Material: 33 production-camera frames (E001–E033, 11 stands × day/dusk/night), the Cloudreach Sky Aviary and creature-roster boards, and palworld-01..05. I opened every day frame and E002, E003, E006, E009, E011, E012, E014, E015, E018, E020, E023, E024, E027, E029, E030, E032 and E033 individually. There is no HUD in any frame, so interface is judged only on world-space markers. As LABELS.txt states, wild creatures are absent by design, and I do not count that absence.

The main finding: **these frames do not read as a sky or cliff realm.** They read as the Meadows kit on grassy plateaus beside some pale cliffs. The one thing that says "altitude" is a handful of flat white cloud slabs.

---

## 1. Defect table

| # | Sev | Frame(s) | Defect | ART_DIRECTION |
|---|---|---|---|---|
| 1 | BLOCKER | E031, E032, E033 | **The companion settles between the camera and the trainer.** In E031 Galecrest hides the trainer completely, with only one arm and the boots visible. In E033 its breast covers the trainer's head and its blue talon passes through the trainer's legs (x≈600–680, y≈450–490). E032 shows the same overlap. At this stand the player cannot see their own character. | §5.1 (never settles between camera and trainer; no interpenetration) |
| 2 | BLOCKER | E016–E018, E028–E030, E013–E015, E022 | **Altitude does not read.** The horizon is a flat, uninterrupted line at eye level (E016 y≈270, E028 y≈300). At night it becomes a dark sea at the same height as the ground (E015, E018, E030), so the summit reads as an island at sea level. No frame looks down onto a cloud sea, shows lower plateaus below, or shows inaccessible upper country above. There are no floating or moored islands, no waterfalls and no drop-offs at the play edge. | §4 Cloudreach row (stacked cliffs, moored-island anchors, "lower plateaus reveal inaccessible upper country"); §1 (horizon crossings 20–35%, distant mass 150–600 m) |
| 3 | BLOCKER | E028, E029, E030 | **The Sky Aviary stronghold is a small greenhouse dome** on a low, dark, square wall in a flat wheat field. The board's defining features are all missing: stone towers with blue cones, the arched stone mass, gold dome ribs, royal-blue banners, bridges, the cliff seat and the waterfalls. At night (E030) the dome is pale and unlit, while the board's Night View is warm-lit from inside. From the path it reads as a hero prop standing alone in undressed ground. | §4 Cloudreach ("rustic stone domed aviary"); §3.2 (400 m and 100 m reads; "cannot be a hero prop standing alone in undressed ground") |
| 4 | MAJOR | E007, E008, E009 | **The Three Bells bridge deck is a pure-white, unshaded plane** with no planks or texture. At night (E009) it is the brightest object in the frame. It reads as missing material, not as a rope-and-timber bridge. | §6 (a flat plane is not a final structure); §4 ("rope and timber bridges with rails") |
| 5 | MAJOR | E010–E012, E031–E033 | **The banners are flat, single-colour rectangles.** In E010 the yellow and blue slabs float in mid-air beside the arch, attached to nothing. In E031–E033 the pale yellow and blue slabs are pasted on the tower faces. They have no cloth, pole, trim or emblem, while the board's banner detail shows a shaped blue banner with a gold crest. E019 already contains a proper pennant, which shows the right treatment is available. | §6 ("a flat plane … is not a final sign, banner") |
| 6 | MAJOR | E019–E021, E025–E027 | **Untextured, saturated blue geometry that reads as debug gizmos.** E019–E021 have a large glossy blue torus with four spokes around the trainer on the perch floor, the largest shape in the frame. E025–E027 have flat blue ribbons lying in the grass and a flat cyan T-post (x≈60–200). They carry no material, and they compete with Galecrest's blue. | §6, §3.1; rubric "intentionality" |
| 7 | MAJOR | E004–E006 | **The village houses have pure-white, unmaterialed trim**: shutters, bargeboards, chimney, balcony rail and a right-hand wall panel. At night (E006) these become the brightest values in the scene, as if self-lit. | §6; §3.3 (night is a distinct look, not a luminance quirk) |
| 8 | MAJOR | E004–E006, E022–E024 | **The settlements are unaltered Meadows road-village modules on flat lawn and dirt.** The Galefoot Waycamp and Cliffhold have no stilts, terraces, cliff anchoring, rope lines or ledges. Nothing makes them height-aware. E004 could be the Meadows village. | §4 ("height-aware settlements"; "Repainting Meadows assets alone is insufficient") |
| 9 | MAJOR | E001–E003, E013–E015, E022–E024 | **Bald, single-material ground.** E001 and E013 are about 60% one smooth, tiled mid-green with a few blades, and E022 is about 50% one flat orange dirt. E016 and E025, meanwhile, have lush dense grass, so density flips between stands without reason. There are no restrained high-altitude flowers on the bald lawns and no stone breaking the turf. The palette reads as saturated Meadows lawn, not "pale weathered stone, grass and restrained flowers". | §3.1 (no single blurred tiled material); §4 Cloudreach palette |
| 10 | MAJOR | E001–E003, E007–E009, E022–E024, E028 | **Path and dirt edges are pixel-dithered stair-steps** (E001 path x≈450–800; E022 dirt). E007 has an unexplained bare rectangular dirt patch at left (x≈0–400, y≈460–600). Edges have no verge, stones or wear. | §3.1 ("edges transition through wear, verge…"; "no unexplained bare rectangles") |
| 11 | MAJOR | E001–E003, E007, E009, E010, E012 | **The cloud sea is rendered as faceted white slabs.** They are flat, unshaded and snow-block-like, and at the right of E001 they read as white geometry, not cloud. They stay pure white at dusk (E002 x≈970–1080) and glow lavender-white at night (E003, E012). This is the white washout the Cloudreach row forbids. | §4 ("strong warm/cool separation rather than white washout"); §3.3 |
| 12 | MAJOR | E011, E014, E023, E026, E029 | **Dusk turns the pale cliffs into uniform sand or sepia.** Cloudreach becomes a desert mesa. In E014 the whole ravine vista on the left collapses into tan haze, erasing the distance, which is the one Cloudreach vista in the set. | §3.3 (golden hour is a look, not a filter); §2 (depth from value/hue separation; fog rejected) |
| 13 | MAJOR | E001 (left rock), E022/E023 (right mound), E028–E030 (grey box), E007, E010 (near cliffs) | **Rocks and cliffs are smooth blobs or boxes with no strata.** E001's rock is a rounded grey loaf. E022's mound is a smooth green-topped lump. E028's rock is a lightly noised cube. Near cliffs in E010 are flat pale grey faces with no ledges or bands. E013/E025 are the exception: the distant terraces there show some layering. | §4 ("distinct stacked cliff silhouettes, strata") |
| 14 | MAJOR | E010–E012 | **The Windscar Beacon stand shows a flat wooden slab with an arch cut out.** It has painted planks, no posts, footing or depth, and no path through it, so it reads as a door in a field. No beacon is visible anywhere in the frame. | §3.2 (authored place at 100 m); §6 |
| 15 | MAJOR | E024, E027 | **At night Galecrest turns into a glossy, saturated cobalt blob.** Its white chest and face disappear, and wing, body and tail merge into one blue mass against the dark houses and pillars. In E003, E012, E018 and E030 the same creature keeps its white chest, so these two frames are local failures. | §5.1 (habitat separation, day and night) |
| 16 | MAJOR | E031 (close), all | **Companion texture quality is well below the roster board.** See section 3. | §5.1; §7 |
| 17 | MINOR | E016–E018 | **The "Sky Shrine" stand shows no shrine.** It shows a flat lawn with evenly spaced lollipop trees and half of a grey Tether-looking industrial block cut off by the left edge. The composition has no subject. | §1 (readable subject 15–80 m); §3.1 (groves/clearings, not an even scatter) |
| 18 | MINOR | E019–E021, E025–E027 | **The high-perch and observatory cameras are boxed in by pillars.** Nothing shows height: no drop, no vista below, no sky around the perch. The "high" places read ground-level. | §4 ("High-perch captures must use a corrected camera") |
| 19 | MINOR | E022–E024 | **A camp bed fills the bottom-centre foreground** and crops into the frame directly under the trainer. The near element should be biased to one side. | §1 (near rail biased to one side) |
| 20 | MINOR | E023 | Galecrest hovers above the dirt with no contact and no shadow under its feet. | §5.1 (ground contact) |
| 21 | MINOR | E009, E027 | Foreground grass renders over-bright pale green at night, brighter than the moonlit ground around it, which looks self-lit. | §3.3 |
| 22 | MINOR | E031–E033 | A gold ring with a white bar and two small white orbs hover in the air with no evident attachment or meaning. This is world-space clutter. | §6 (markers readable without becoming billboard clutter) |
| 23 | MINOR | E032 | Hard-edged square darker terrain patch left of the creature (x≈240–450, y≈300–445). | §3.1 (no visible seams / bare rectangles) |
| 24 | MINOR | E007, E009 | An unexplained pink glow blob is clipped by the left frame edge (x≈0–60, y≈470–520). | §3.1 / rubric "artefacts" |
| 25 | MINOR | E010, E012 | A thin white horizontal beam crosses the cliff face (E012 x≈800–980, y≈185–200) without an evident source. | rubric "artefacts" |
| 26 | MINOR | E028–E030 | The Team Tether camp at left reads as undifferentiated clutter of tiny props on a flat dirt pad. Its oxblood accents are correctly confined to it, but it has no occupation silhouette that reads at distance. | §3.2 (occupation geometry) |

**Scale (rubric 8):** props broadly agree with the 1.80 m trainer. Doors and walls in E004/E022 are about 2× the trainer, the bells in E007 are plausible, and the bed in E022 is about 2 m. There is no prop scale break. For the companion, see section 3.

**Oxblood:** red appears only in the Tether camp props in E028–E030. It has not leaked onto friendly elements.

---

## 2. Time of day

**Day (10:00).** It reads clearly as day: bright blue painted sky, strong cast shadows that put the trainer and creature on the ground, and legible shaded sides. The light is neutral-white rather than the warm key over cool fill that §3.3 asks for, and the saturated lawn green dominates. Best day frames: E013, E016, E025.

**Dusk (18:30).** It is distinct from day, but mostly through the sky and the distance, not the light. The clouds and sky go peach and the cliffs go sand. The foreground grass stays nearly the same saturated green (E002, E011), so the frames look like a sepia grade on the background layer, not golden-hour key light raking the scene. There is no warm rim on the trainer or creature. It fails in three places:
- E014 erases the ravine into tan haze.
- E011/E023 turn the cliff country into desert mesa.
- E002 leaves the cloud slabs pure white.

**Night (23:00).** This is the strongest of the three looks: a moonlit blue grade, a moon disc, painted night cloud, warm-lit windows in E024, and readable route and trainer legs. The white shirt and boots catch light, which §3.3 requires. It fails where unshaded geometry glows: the bridge deck (E009), the village trim (E006) and the cloud slabs (E003, E012). Foreground grass is over-bright in E009 and E027. The Aviary dome stays dark (E030). Galecrest turns into a cobalt blob in E024 and E027. The flat sea horizon at eye level in E015, E018 and E030 flattens the altitude read further.

**Verdict:** three distinct looks, yes. Dusk is the weakest because it is a background tint rather than a lighting change.

---

## 3. Companion creature (Galecrest)

**Scale.** At the same depth, Galecrest stands about 1.3–1.6× the trainer's height at the head, roughly 2.4–2.9 m, and its raised wings go higher (E004, E013, E022). That is taller than the 1.80 m trainer, as the hard rule requires, and consistent between stands. It stays well above the 80 px floor in every frame. In crouched or facing-away poses (E019, E025) it reads about trainer height, so the size advantage depends on the pose. The scale problem is placement, not size. At the summit overlook (E031–E033) it sits between the camera and the trainer and its talon passes through the trainer (defect 1).

**Readability against terrain:**
- Day: strong in every frame, with a white-and-blue body against green.
- Dusk: good (E002, E011, E020, E029), with the white chest still popping.
- Night: good in E003, E012, E018 and E030, where the white chest is lit.
- Night failures: E024 and E027 (glossy cobalt, chest lost, merges with dark architecture) and E033 (blue wings against the navy sky and the blue banner behind).
- The blue gizmo torus and floor ribbons (E019, E025) compete with its blue plumage.

**Art quality.** Said plainly: the silhouette is good and the surface is not. A raptor-griffin head with a crest, stepped wings and big talons gives it the strongest silhouette in the set, and it is the best thing in these frames. Up close (E031, E032), though:
- The albedo is posterised and noisy, with smeared dark streaks and random blue flecks on the white body. It reads as camouflage or dirt, not designed colour blocks.
- The feathers are flat layered cards with painted-on shading.
- The eye is a small hawk eye inside a green goggle mask, with no expressiveness.
- The legs are flat pale-cyan plastic.

Set beside the roster board (Cloudfang, Solmane, Aeriex), which has clean colour blocks, soft fur and feather rendering, large appealing eyes and designed faces, Galecrest looks like a raw generated mesh, not a bespoke hero companion. It also clashes in style with the chibi, big-headed trainer beside it: one is a semi-realistic hawk and the other a toy-proportioned child. Against Palworld's companions (palworld-01, -04) it falls short on face appeal and material finish. Galecrest is not on the Cloudreach roster board, so it may be a starter, but it is still offered as the look and is judged as such.

---

## 4. Strengths to keep

- **The painted sky and clouds** in all three moods are the best-finished element in the set. Keep the night grade (E015, E018, E030) as the model for night.
- **The E013/E015 cliff-edge vista**: receding terraced cliffs, a grounded tree and a big cast shadow. It is the one frame that feels like Cloudreach. Build more stands like it.
- **E007 composition**: near grass tuft to one side, the bell gantry and rope bridge as a mid-ground lure, and a distant spire on the crag. That is the §1 three-layer grammar done right. Only the white deck ruins it.
- **Dense grass** in E016, E018 and E025–E027 with a few restrained purple flowers. That density on walkable cliff tops is the target, applied consistently.
- **The dome with its spire** as a distance silhouette (E028) works as a landmark read. It needs the rest of the Aviary built around it.
- **Warm-lit windows at night** (E024), **the proper blue pennant** (E019) and **gold rails** (E025) are the only direct echoes of the board's palette of royal blue, gold and pale stone. Extend them.
- **The trainer is readable** in every frame except the E031 occlusion, and cast shadows ground objects well.
- **Galecrest's silhouette and scale.**

---

## 5. Three biggest gaps vs the references

1. **No sky realm (E016, E028, E030, E018, E001).** The aviary board's Exterior and Biome Context panels put the settlement on sheer stacked cliffs rising out of a volumetric-looking cloud sea, with floating islands, waterfalls pouring off the rock and arched bridges spanning the gaps. The player is always visibly *above* something. These frames stand on flat lawns with an eye-level horizon or a sea-level ocean, and the cloud sea is a few white slabs. Palworld-04 shows the same idea at game finish: layered cliffs, a tower landmark in aerial haze and a mid-ground ruin.
2. **Unfinished materials on authored structures (E007, E010, E019, E025, E031, E004).** A white bridge deck, flat colour-rectangle banners, a blue gizmo torus and floor strips, a cyan T-post, white house trim, a slab arch and a box rock. Every surface in the Palworld frames carries a material and a form. Here, most of the structures meant to carry Cloudreach identity are placeholders, and the Aviary itself (E028) is a greenhouse, not the board's stone-and-gold castle.
3. **Creature and character finish (E031–E033, all).** Galecrest has a good silhouette but a noisy, posterised texture, a small inexpressive face, and a semi-realistic style that clashes with the chibi trainer. The roster board and Palworld's companions have clean colour blocks and appealing faces. The ground under them is also bald tiled green with dithered path edges (E001, E013, E022), against Palworld-02's layered verge, turf variation and shrubs.

---

## 6. Bars

**Bar A: do these frames read as belonging to the Cloudreach boards (sky aviary and roster)? No.**

- **What carried it:** the painted sky, blue banners and gold rails (a faint palette echo), the dome-and-spire silhouette, and the E013/E015 terraced cliffs.
- **What sank it:** no altitude or cloud sea, an Aviary that bears no resemblance to the board, Meadows village modules as cliff settlements, and dusk that turns the palette to desert.
- **Fixable in scene:**
  - A cloud-sea floor below every cliff edge in place of the white slabs, with shading and dusk/night response.
  - Placement that shows drop-offs and lower plateaus in the stand compositions, including corrected high-perch cameras (E019, E025) that look out and down.
  - Hiding the eye-level sea horizon behind cliff masses or cloud.
  - Replacing the flat banners with the installed pennant (E019).
  - Materials on the bridge deck, house trim, torus, strips and T-post.
  - A dusk key light that warms the foreground instead of sepia-hazing the distance.
  - Consistent grass density with restrained flowers, and stone breaking the turf.
  - Rope lines and ledge dressing on the settlements.
- **Needs new art:**
  - The Sky Aviary stronghold as a hero asset: stone towers, arched mass, gold-ribbed dome, bridges, a cliff seat, waterfalls and an interior-lit night state.
  - Stratified stacked-cliff and floating or moored island meshes.
  - A proper cloud-sea asset or shader.
  - Height-aware settlement modules (stilted or ledge houses).
  - A beacon structure for Windscar.
  - Roster-board species in place of the Meadows stand-ins. None were visible here.

**Bar B: beside palworld-0*, would someone say these are trying to be the same kind of game? Yes, narrowly, on genre intent only, not on finish.**

- **What carried it:** a third-person trainer framed centre-bottom with a large creature companion beside them, open grass fields with trees and ruins, painted skies, and dense grass in E016 and E025. E010, E016 and E028 set beside palworld-02/04 are unmistakably the same genre.
- **What drags it toward no:** frames E019 (blue torus), E004/E006 (white planes), E007/E009 (white deck) and E031 (occluded trainer) look like a prototype. Galecrest's surface and the trainer's style fall well short of Palworld's bespoke creature and character finish. Large bald tiled lawns (E001, E013) are emptier than any Palworld frame.
- **Fixable in scene:** the placeholder materials, consistent grass and ground layering, path verges, companion placement at E031–E033, and the night over-bright and glow issues.
- **Needs new art:** a re-textured or regenerated Galecrest (clean colour blocks and a more expressive face, preserving the silhouette), a trainer and companion style reconciliation, and the Aviary hero asset.
