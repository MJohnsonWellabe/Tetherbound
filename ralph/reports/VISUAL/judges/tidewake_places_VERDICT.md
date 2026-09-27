# Tidewake places: code-blind visual verdict

Judged from 19 individual 1280x720 frames (P001–P019, day 10:00, production camera), the contact sheet, `ART_DIRECTION.md` (especially §1, §3.1, §3.2, §4 Tidewake row) and these references: `water-veilfall-stronghold-board.png`, `water-realm-creature-roster-board.png` and `palworld-0*.jpg`. Creatures are missing from these frames because of the capture fixture, so that is not counted as a defect. The trainer (1.80 m) is the scale ruler.

**Summary:** 17 of the 19 frames do not show the landmark they are named after. Most "road approaches" are narrow grass trenches between two huge, featureless terrain walls. The chapter reads as Meadows grass carved into canyons. It does not read as an island archipelago with docks, pumps, sluices and a white-falls mountain.

## 1. Defect table

| # | Severity | Frame(s) | Defect | ART_DIRECTION clause |
|---|---|---|---|---|
| 1 | BLOCKER | P001, P002, P003, P004, P006, P007, P009, P011, P012, P015, P017, P018 (and most of P005, P019) | **The named landmark is not visible.** The labels promise a beacon, woven hall, stairstones, rescue jetty, shrine, twin pumps, drift arch, terraces, lookout, saddle camp, channel bridge and mountain crown. The frames show grass, sky and terrain walls. "Clear sightline" is false in practice, because no structure of any recognisable kind is at the end of the sightline. | §3.2 (read at ~100 m as an authored place; never a destination in undressed ground); §4 Tidewake distance read |
| 2 | BLOCKER | P001, P003, P005, P006, P007, P008, P011, P012, P017, P018, P019 | **Roads are V-trenches cut through terrain.** Two smooth walls, 20–60 m tall, fill 50–80% of the frame. Each has one tiled Voronoi/cell rock texture, with no strata, ledges, rock meshes, vegetation or wet-rock variation. They read as a heightmap brush stroke, not a landform, and they block every view of the sea and islands that the chapter depends on. | §1 (near rail 3–10 m, subject 15–80 m, distant mass 150–600 m, horizon crossings 20–35%); §3.1; §4 ("wet dark rock", "cliffs visually explain gated approaches") |
| 3 | BLOCKER | P008, P018 | **The Veilfall does not exist as a mountain.** In P008 the "White Cascade" is a thin white column hanging in an empty sky gap, with no rock mass, pools, mist, arch or tiers behind it. It reads as a floating light shaft or a rendering bug. P018 (Mountain Crown) has no sightline at all: the frame is a black wall. On the board, the Veilfall is a tiered, forested cliff mountain carrying multiple falls, a bridge, an arched gate and a mist base. | §4 Tidewake ("white-falls mountain", "Veilfall is visible from First Shore and gains detail") |
| 4 | BLOCKER | P018 | Camera is inside or against dark geometry. Near grass renders as giant flat, untextured pale-green triangles over the trainer. There is a bright glitchy speckle patch on the black wall. Reads as a bug. | §2 / rubric artefacts; §1 composition |
| 5 | MAJOR | P017 | Camera has collided into the trainer: the back of the head and collar fill the lower half of the frame. The capture stand, or the camera's collision in a narrow trench, is broken. | §5.2 trainer readability; §1 composition |
| 6 | MAJOR | P001, P013 | **Veilfall is not visible from First Shore.** Neither First Shore frame (beacon, horizon stones) has a white-falls silhouette on the horizon. The contract requires one. | §4 Tidewake distance read; §3.2 (~400 m silhouette) |
| 7 | MAJOR | All except P014, P016 | **Palette is Meadows, not Tidewake.** 60–90% of each frame is saturated yellow-green grass plus neutral grey-khaki walls. Cyan/navy water appears only as slivers (P003, P004, P012, P015, P019) or in one frame (P016). There is no warm dock timber, no pale foam line at any shore, and no dark wet rock. §4 explicitly says repainting Meadows is insufficient; here, Meadows has not even been repainted. | §4 Tidewake palette; §4 closing paragraph |
| 8 | MAJOR | All grass frames | **Uniform grass carpet, and no readable path.** The same tuft density covers trench floors, hilltops and slopes, with no clustering, verges, worn track, sand, reeds or marsh. The labels say "road approach", but no road material appears in any frame. P010 and P013 have a flat, bare grey patch with a hard edge instead of a path. | §3.1 (paths belong to the land; groves/clearings, not a random carpet; no bare rectangles) |
| 9 | MAJOR | P004, P016, P019 | **Islands are smooth green blobs.** The far islands are rounded olive mounds with a thin beach rim and shelf-like steps (P004, P016). They have no rock faces, cliffs, tree mass or dock. The board's islands are stacked pale-rock stacks with forest and white water. | §4 Tidewake ("salt rock", "twelve authored islands"); §3.2 |
| 10 | MAJOR | P016, P019 | **Tidal stepping stones look procedural.** They are perfectly elliptical sand discs with identical concentric foam rings, evenly spaced in a straight line. They read as generator output or debug markers, not tide-worn stone. Some faint vertical white streaks on the water (P016, right) are unexplained, possibly spray planes. | §1 (intentional, not generator), §3.1 |
| 11 | MAJOR | P002, P009, P010, P015 | **Open-grass frames are empty.** They show a slope of grass and sky with nothing in the 15–80 m band, no optional lure and no distant mass. Compare palworld-02/04, where a cave, a ruin or a tower always anchors the middle ground. | §1 (readable subject 15–80 m; optional lure); §3.1 lures |
| 12 | MAJOR | P010 | The "Signal Spire" is a small wooden lattice box (about 5 m against the trainer, ~30 px) on a hill crest. It reads as scaffolding or a crate stack, not a spire. It has no base, no path to it and no signal (light/flag). | §3.2; §6 (no blank-box structures) |
| 13 | MAJOR | P014 | The Root Walk is a flat, bright-orange sand floor with a barrel, a crate and a two-slab stone block. It has no roots, boardwalk or reeds. The sand texture is a high-contrast mottled tile that reads as noise. On the right, a tall picket fence runs straight along a grey wall. | §3.1; §3.2; §4 (reeds/marsh, docks) |
| 14 | MAJOR | P005 | The "Aquaryn Tidal Basin" is a trench ending on a green hill. There is no basin. A small blue-and-white figure at the far end (~20 px) is the only possible subject. If it is the Aquaryn shrine or statue, it is undressed and far too small to anchor the place. Its size cannot be judged against the trainer at this distance, but it is nowhere near a dragon-scale read. | §3.2; §5.1 (lure ≥40 px) |
| 15 | MINOR | P005, P007, P012, P019 | Hard grass-to-wall seam: the grass layer stops on a sharp line with a blurry ground-texture halo, and there is no rubble, bank or root transition. | §3.1 (material transitions) |
| 16 | MINOR | P008 (right wall), P019 (left wall), P017 | Stretched terrain texture: on steep faces the rock tile smears into vertical striations and moiré. | §3.1 (no stretched/tiled blur); rubric artefacts |
| 17 | MINOR | P010, P014 | Tree family mismatch: pixel-leaf clumps on bright orange-red trunks sit beside the darker round-canopy trees of P002/P004. The trunk orange reads as a different pack, and it pulls toward the warm reds reserved for danger. | §1 (one coherent nature family); §4 |
| 18 | MINOR | P013 | "Horizon Stones" are a heap of rounded green-grey boulders. They read as a rock pile, not placed or standing stones. The wooden arch with navy banners at the left is cropped against the frame edge and floats above a grey concrete-looking slab. | §3.2 |

No oxblood leak was seen. Banners in P013 are navy. The NPC in P006 wears dark clothing with no red.

## 2. Does each place read as its landmark from its approach?

- **P001 First Shore Welcome Beacon: no.** A grass trench between two walls. A far hill with a pale rock is the only subject. There is no beacon, no shore and no Veilfall on the horizon.
- **P002 Reedhaven Woven Hall: no.** An open grass rise with a few trees and one distant figure. There are no reeds, no water and no hall.
- **P003 The Tidal Stairstones: no.** A grass cone hill and a dark wall. The sea is a sliver, with no steps.
- **P004 Shellwatch Rescue Jetty: no.** Grass slope, with a blob island across the water. There is no jetty or dock timber anywhere.
- **P005 Aquaryn Tidal Basin: no.** A slot canyon ending in a hill with a tiny blue figure. There is no basin or water.
- **P006 Salt Crown Tide Shrine: no.** A dark slot canyon with one NPC. There is no shrine and no salt rock.
- **P007 Sluice Isle Twin Pumps: no.** A slot canyon with sky. There are no pumps, no sluice and no water.
- **P008 The Veilfall Cascade: partly.** A white vertical fall is visible, which is the only frame where the intended landmark shows. However, it has no mountain, pool or mist. It hangs in sky and reads as a light shaft.
- **P009 Lantern Cove Drift Arch: no.** A grass hillside with a distant field. There is no cove, arch or lantern.
- **P010 Gull Rest Signal Spire: partly.** A small wooden tower sits on the crest. It is too small and boxy to read as a spire.
- **P011 Drowned Garden Terraces: no.** A trench with one rock. There are no terraces and no drowned garden.
- **P012 Deep Watch Lookout: no.** A trench framing a cone-spike rock and far islands. There is no lookout structure.
- **P013 First Shore Horizon Stones: partly.** A boulder heap and a wooden arch with navy banners give the only "inhabited" read in the set. The stones do not read as a deliberate place.
- **P014 Reedhaven Root Walk: no.** A sand yard with a barrel, a crate and a slab, next to a fence. There are no roots, walkway or reeds.
- **P015 Tidal Cradle Saddle Camp: no.** A grass slope above the sea. There is no camp or saddle landform.
- **P016 Salt Crown Return Bell: no.** This is the best Tidewake read in the set (open sea, islands, stepping stones), but it has no bell or shrine.
- **P017 Sluice Channel Bridge: no.** The camera is inside the trainer's head. It shows a trench and no bridge.
- **P018 Veilfall Mountain Crown: no.** The frame is a black wall with a camera clip. There is no sightline, as the label admits.
- **P019 Lastlight: no.** A slot canyon framing sea and stepping discs. There is no Lastlight structure.

## 3. Strengths to keep

- **Sky and daylight.** The painted cloud field and warm sun with a cool blue sky read clearly as day. Directional shadows plant the trainer and props firmly (P014 barrel/crate shadows, P004 trainer shadow). Keep this.
- **Trainer.** The trainer reads instantly at gameplay size. Teal shirt, orange backpack and dark trousers make three clean colour blocks against grass and sand, and the silhouette survives at 30% sheet size.
- **Open-sea view (P016).** Cyan water, a hazy horizon, islands at several depths and a readable foreground ledge. This is the one frame with the chapter's colour and a real foreground/mid/distance stack. Build the chapter from this view outward.
- **Framing idea (P019).** A slot framing a sea vista with a route on the water is a good composition intent. It needs rock that looks like rock and a destination in the gap.
- **Navy banners (P013).** Navy banners on warm timber match the board's banner fabric and palette. They are the right village/dock language, so extend them.
- **Grass blade quality.** Close up, the grass has pleasant colour variation and light response. The problem is where it is placed, not the asset.

## 4. The three biggest gaps against the references

1. **No landmarks, so no places** (P001–P019, worst in P005–P007, P011, P012). The Veilfall board is built around a stacked, falls-laced mountain you can see across the sea. Its key views give an approach, a gate, a mountain path and a lit night silhouette. Palworld-04 puts a tower and ruined arches at the end of the path, and palworld-05 fills the middle ground with built things. These frames put nothing at the end of 17 of 19 approaches, and the one waterfall (P008) is a column floating in sky.
2. **Carved trench terrain instead of an archipelago landform** (P001, P003, P005–P008, P011, P012, P017–P019). The board's land is pale rock cliffs broken by ledges, trees, waterfalls and beaches, meeting cyan water with white foam. Here the land is smooth, untextured-looking walls with a single cell texture, and they hide the sea. Palworld-02 frames its path with rock outcrops that have caves, overhangs and trees on top. These walls have none of that.
3. **Wrong palette and emptiness: Meadows grass everywhere, no inhabited water edge** (all frames except P016). Both references are full: the board has foam, docks, banners, torches, bridges and forest on every ledge; the Palworld frames have props, structures and people in the 15–80 m band. These frames are more than half uniform grass, have no docks, pumps or sluices, and never show a shore where water meets land with foam or timber.

## 5. Bar questions

**A. Do these frames read as belonging to the world of the Tidewake/Veilfall and water-realm boards? No.**
- *What carried it (weakly):* the sky, P016's open water and islands, and the navy banner arch in P013.
- *What sank it:* no Veilfall mountain, no docks or water architecture, the Meadows palette, trench walls instead of cliffs, and blob islands.

**B. Beside the Palworld frames, would someone say these are trying to be the same kind of game? No.**
- *What carried it (weakly):* the stylised trainer, a third-person over-the-shoulder camera, and bright daylight with grass.
- *What sank it:* empty middle grounds, a player walled into featureless canyons, no built structures or props around the route, and two frames with visible camera bugs (P017, P018). Palworld's frames are dense, have landmarks and look lived-in. These look like a terrain test map.

### Gaps fixable by changing the scene (using what is already in the build)
- **Re-sculpt or re-route the approach terrain** so roads run along shores, ridges and beaches instead of through trenches, restoring sightlines to the sea and islands (P001, P003, P005–P008, P011, P012, P017, P019).
- **Pick capture stands where the landmark is actually in frame.** Fix the camera collision in P017 and P018.
- **Give steep slopes a proper rock treatment:** existing rock meshes, ledges, darker wet-rock value near water, and trees or shrubs on the crests. Fix texture stretching and the hard grass seams.
- **Rebalance the palette toward Tidewake:** more water in frame, a foam shoreline, reeds or marsh at water edges, sand beaches, and less grass coverage. Replace the bare grey rectangles with path material.
- **Cluster the grass** and give it clearings and verges.
- **Break up the stepping-disc regularity:** vary size, spacing and outline, and add rock.
- **Dress each named place** with the installed village/prop family (timber, navy banners, barrels, crates, lanterns) so it has a structure, a threshold and a lure. Scale up the Signal Spire and give it a light or flag.
- **Place Veilfall** where it is visible on the First Shore horizon.

### Gaps that likely need new art (if not already installed)
- **The Veilfall mountain itself:** a tiered cliff mass with multiple falls, a mist base, a stone bridge and an arched gate. A single water column cannot stand in for it.
- **A Tidewake water-architecture family:** jetty/dock planking, twin pumps, sluice gates, a channel bridge, a tide shrine, a return bell, a woven reed hall and a lookout tower. None of these appears in any frame, so they either do not exist or were not placed. Which one is true cannot be seen from pictures.
- **Salt-rock and sea-stack cliff meshes** for island silhouettes, to replace the smooth heightmap blobs.
- **Island-appropriate vegetation** (reeds, mangrove, palms or pines, as on the board). The current trees are the Meadows family, and one of them has off-palette orange trunks.
