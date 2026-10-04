# Code-blind visual review: village road, Crossing Hall, nave and Shrine Room (visual-bar-r3)

Judge: code-blind. I read no source, config, history, reports or docs, only the 44 frames, the 11 contact sheets, the Meadows key art, Asset Board 19 and the Palworld references. I give no scores. Pixel regions refer to the native 1920x1080 frames as (x range, y range).

## Grounds and paths

- **The road reads as a dirt plaza.** In farm-door_* it fills about 60% of the lower frame (x 300-1700, y 480-1080). It is one tiling orange-brown texture with repeating blotches, and in day it is saturated almost to orange. There are no wheel ruts, no edge stones and no variation in wear. The key-art road is a narrow worn lane with grass encroaching. Fixable in scene: narrow the road, add an edge-blend decal or vertex blend, desaturate it, and break the tiling with a second detail texture.
- **The road-to-grass boundary is a hard alpha edge.** See farm-door_day_clear (x 0-700, y 470-560) and hall-approach_day_clear (x 0-500, y 560-640). Grass cards stop on a line, with no transition strip.
- **The paving slabs look like flat grey cards.** The light grey rectangles in front of each house (street-mid-left (1100-1400, 555-600), hall-approach (520-670, 490-515), hall-approach-reverse (1180-1400, 540-600)) have no thickness and no worn edges, and they do not connect to a door step. They read as placeholder quads.
- **Loose props lie on the verge.** In hall-approach-reverse_day_clear (210-300, 550-595) a white box and an orange object sit at odd angles beside the NPC. They read as dropped debug items or clipping props.
- **Rain does not wet the ground.** In farm-door_day_rain and hall-approach_day_rain the road stays the same warm, dry orange as in clear weather. There is no darkening, no sheen and no puddles. The stone pavers also stay pale.

## Vegetation

- **Grass is sparse and generic.** Repeated grass-card clumps sit at roughly uniform density (farm-door (0-700, 500-850), street-mid-right foreground). There are no flower beds, hedges, cottage gardens or bushes against house walls. The key-art settlement is framed by large oak canopies, and here there are almost none.
- **The one hero tree looks like a flat card.** In farm-door_* (250-440, 15-160) the only tree is a flat, noisy, low-detail card silhouette against the sky. It is the weakest asset in the most important frame.
- **Background trees are tiny repeated lollipops.** street-mid-left (790-980, 320-390) shows a row of small identical trees, which looks procedural.
- **Some upper windows are filled with foliage cards.** Solid green fills appear in the clerestory windows at shrine-pedestals_day_clear (1130-1220, 185-280) and nave-forward (870-900, 250-310). A tree card appears to sit right against the glass.

## Architecture: village

- **The houses are coherent and are the best part of the set.** The timber-frame, stone-plinth and tiled-roof family is consistent and matches the Board 08 buildings.
- **The houses do not line the road.** In street-mid-left/right and hall-approach-reverse they are scattered across open field at irregular setbacks (street-mid-right (40-500, 190-500) faces sideways, set back about 15 m). The intent of "one straight road lined with lived-in houses" holds only in the farm-door view.
- **The houses are barely lived in.** There are no carts, laundry, firewood, crates, flower boxes, wells, signage or fences, except the inn's barrels and bench (street-mid-left (30-330, 480-530)). The key-art settlement has a well, a banner, fences and a lot of clutter.
- **Night windows read as white panes, not warm pools.** See street-mid-left_night_clear (inn windows 160-230, 230-300 and 510-550, 265-320; cottage 1080-1140, 405-480). No light falls on the ground below any window or door.

## Architecture: Hall exterior

- **The Hall does not contrast with the village.** Its upper storeys use the same cream plaster, timber framing and terracotta trim as the houses. Only the ground floor is stone (hall-approach_day_clear (530-1100, 280-450)). From the farm door it reads as a larger house, not a stone civic landmark. The key-art Hall is a dark stone mass with vertical banners.
- **The roofline is weak at distance.** In farm-door_day_clear the Hall occupies only about 170x190 px (860-1030, 210-395). The tower is a thin spire with little mass, and the roofline lacks a single dominant silhouette.
- **The front door is a blank emissive plane.** In hall-approach_* (885-930, 380-450) a flat cream rectangle sits in the arch. It has no depth, no door leaves and shows no interior. At night it is the brightest thing on the facade, but it reads as a hole in the texture, not as a lit interior.
- **The gable windows are black voids by day and by night.** See hall-approach_night_clear (835-990, 210-255). At night they should be warm lit openings. They are the largest windows on the facade and are dark.
- **The "CROSSING HALL" sign is illegible.** At (865-945, 283-292) it is about 8 px tall from the approach and invisible from the farm door.
- **The wing windows look cut out.** On the left wing (530-710, 315-350) they read as cut boxes with props visible inside ((685, 330) shows an object through a window). They have no frames or glass.
- **The terracotta trim edges toward the reserved oxblood.** The orange-red roof trim (570-1130, 40-300) is saturated enough to approach the reserved Team Tether red at golden hour. Worth a palette check.

## Architecture: Hall interior (nave)

- **The ceiling shows the exterior roof.** The underside of the roof displays the exterior terracotta tile texture, with green moss specks: nave-forward_day_clear (570-1000, 0-220), nave-arches-right_day_clear (0-1000, 0-140) and nave-reverse (640-1100, 0-230). Either the roof is single-sided or the exterior roof mesh is the ceiling. This breaks the interior read more than anything else in the set.
- **The clerestory windows look onto the Hall's own roof tiles.** See nave-arches-right_day_clear (790-1430, 180-280), nave-reverse (1100-1680, 120-260) and shrine-pedestals-reverse (0-560, 90-250). The windows frame the outside roof slope at close range, which reads as an inside-out building.
- **Portal arches are flat solid-colour planes.** Live and locked arches are light blue and sealed arches are navy (nave-arches-left_day_clear (40-230, 395-600) and (600-730, 395-580)). There is no surface, glow, swirl, depth, biome imagery, icon or carved sign. Live and sealed differ only by shade of blue.
- **At night all arches go saturated royal blue.** See nave-forward_night_clear (1080-1160, 395-570) and (1560-1830, 420-700). This makes the sealed-versus-live read even weaker.
- **The biome signage is tiny duplicated text.** Each arch carries two floating text lines, about 12-16 px at mid distance (nave-arches-left: "Sealed / Sealed", "The Stormwood / Locked"). Sealed arches repeat "Sealed" twice. No carved plaque, emblem or colour coding exists.
- **Labels render mirrored through walls.** Text appears backwards through openings: "ƨʇiilƆ", "buol" and "biT" in nave-arches-right (930-1220, 420-470) and nave-reverse (1320-1560, 430-490).
- **World labels draw over or behind HUD panels.** "Cloudreach Cliffs / Locked" appears behind the quest panel in nave-forward (1600-1880, 255-360).
- **The two long walls use different materials.** The left wall is stone and the right/end walls are plaster (nave-reverse, nave-arches-right). It reads as unfinished, not as a design choice.
- **The nave is an empty box.** There are no benches, rugs, banners, braziers, columns, statues or floor pattern leading to the home arch. The floor is one tiling cobble texture stretching to the walls.
- **There is no interior haze.** The far wall has the same contrast as the near floor.
- **There are no warm lamp pools at night.** The hanging lanterns ((950-1000, 250-340) and (1310-1380, 180-320)) have only a faint glow on the wall. At night the floor is lit flat blue-white (nave-forward_night_clear (0-1300, 500-1080)). The night interior is brighter than the night exterior and reads as moonlight flooding a roofless courtyard, not as a lit hall.
- **Sun patches look like light leaks.** By day the hard white floor patches read as leaks (nave-forward_day_clear (235-330, 565-720) and nave-arches-right (1460-1840, 650-690)). At golden hour the same effect becomes sunlit window stripes, which works well (nave-forward_golden (1440-1560 on the sheet)).
- **The quest beam passes through the roof into the nave.** A cyan vertical shaft appears in nave-arches-right (260-350, 0-410) and nave-reverse (890-905, 0-400).

## Architecture: Shrine Room

- **The room is a bare plaster box.** The lecterns are thin wooden stands with floating text labels. There is no shrine character: no plinths, niches, relic displays or lighting accent. The pedestals read as music stands.
- **Fewer than eight pedestals are visible from any station.** About six to seven show (shrine-pedestals_day_clear: 270-430/630-700/770-810/1230-1270/1300-1370/1480-1620 at the right edge). Labels are legible only on the nearest one or two; the rest are skewed text at about 8 px.
- **The upper-left windows show grass terrain, as if below ground.** See shrine-pedestals_day_clear (80-500, 0-260). Either the room is sunk into a hillside or the terrain clips the window openings.
- **A pedestal interpenetrates the companion.** In shrine-pedestals-reverse_day_clear (380-590, 570-800) the "Cloudreach Cliffs" lectern and its label pass through Terrapup's body. In shrine-pedestals_day_clear the "Tidewake" label prints through the creature (1530-1640, 720-780).
- **The night Shrine Room is flooded with flat blue light.** It is brighter than night clear outside (sheet, night tiles). There is no warm accent.

## Props

- **Prop density is very low across the village.** The only lived-in props are the inn barrels and bench and one wall sign. Nothing from Board 07 (well, cart, lantern posts, fences around plots, crates) dresses the road.
- **The hanging iron lanterns are well chosen but do not light anything** (nave frames).
- **One lantern post exists but gives no light.** The black post at farm-door (0-40, 420-540) casts no pool at night (farm-door_night_clear).

## Humans

- **Every human stands in a stiff A-pose.** The trainer holds this pose in all frames (arms held out from the body, hall-approach_day_clear (900-1020, 590-680)). NPCs show the same stance (hall-approach-reverse (380-440, 465-605) and (1510-1580, 480-620)). The idle pose reads as a bind pose and kills life in every frame.
- **The trainer is overlit at night.** In farm-door_night_clear (780-1140, 510-1080) the trainer's hair and backpack are bright orange and specular against a dark scene. They read as self-lit and do not sit in the night grade. The same happens in nave night frames.
- **Scale agrees.** Trainer, NPCs and house doors are consistent (hall-approach-reverse: NPC at 1300, 460-550 against the door at 1430-1500, 415-545). No scale defect.

## Creatures

- **Terrapup is the most appealing asset in the set.** It has a strong read at small size, a good face with clear eyes, and a correct scale: crouched, it stands at about 1.7x the trainer's height. It is the closest thing to Palworld-class appeal here.
- **Its painted, flat-shaded texture jars with the semi-realistic stone and terrain.** It reads as hand-painted toy. Its fur has no rim light or sheen, which works by day and leaves it a flat blue-grey cutout at night (hall-approach_night_clear (1170-1440, 285-620)).
- **The companion is placed badly in some frames.** It fills about 25% of the frame in shrine-pedestals_* (1410-1920, 240-960), at camera distance, so its back and boulder shell occlude the room. In nave-reverse it stands in front of the Home arch (490-560, 380-520), hiding the key arch of the room.
- **No other creatures appear.** One tiny distant animal shows in street-mid-left (770, 410). The key art has creatures in the settlement, and here the village is empty of wildlife.

## Water, sky and light

- **The day sky is serviceable.** It is a blue gradient with painted clouds, and the Hall's tower has a clear sky interval around it in farm-door_day_clear (920-1000, 200-260).
- **There is no aerial perspective or morning haze.** Farm-door foreground, mid houses, the Hall and the hills all carry the same contrast and saturation. The three depth bands (cool morning air) are absent. The hills at (0-250, 40-300) are as crisp as the foreground.
- **There are no sun shafts, volumetrics or fog anywhere,** outside or inside.
- **Golden hour is the strongest grade.** It has warm amber light, long raking shadows across the road and a sun disc (hall-approach_golden, farm-door_golden). However, the stone does not go cool in shadow; everything turns orange-brown. The intended "amber against cool stone" contrast is missing.
- **Night clear reads blue-dark but not dark enough.** The road and grass stay mid-value brown-green (farm-door_night_clear (300-1300, 520-1080)). Warm pools are small and few: the Hall door and two sconces, some house windows. It is acceptable but not "genuinely" dark.
- **Rain at night lifts the frame to flat grey-teal.** farm-door_night_rain and hall-approach_night_rain have a grey sky (0-1920, 0-300) and lighter ground, so they are brighter than night clear. This is the opposite of the intent. Rain streaks are nearly invisible.
- **Rain by day barely changes the frame.** The sky is cloudier, but the road, shadows and saturation match clear weather.
- **Interior rain variants differ from clear only by a slightly lighter floor** (nave-forward_day_rain and night_rain on the sheet). Night rain interiors look greyer than night clear.

## UI

- **The HUD takes about 20% of the frame.** The empty five-slot hotbar with "+" icons (1310-1860, 715-825) plus the button-hint bar sits in the lower right. It always overlaps the right road verge and the creature's paws. The large quest panel (1520-1860, 255-415) covers the right-hand houses in every exterior shot.
- **World-space labels collide with the quest panel.** A sign reading "Sou..." pokes out at (1800-1900, 320-360) in all farm-door frames. "Cloudreach Cliffs / Locked" sits behind the panel in nave-forward. The UI layer should hide or reposition world labels under panels.
- **The time label sits on the Hall tower** in hall-approach_* (865-1050, 60-95).
- **The interaction prompt sits on the trainer's backpack.** "Call out Terrapup" prints over the trainer at farm-door (850-1125, 825-865).
- **The minimap is a blurry low-resolution texture** (1690-1855, 65-230).
- **The prompt names the relic "Sealed".** "Hang your Sealed relic" (shrine frames) uses the state word as the item name, which looks like a string bug.

## Cross-cutting

- **Silhouettes:** houses and Terrapup read well at thumbnail size (contact sheets). The Hall's silhouette is lost at thumbnail size in farm-door; it blends into the house roofs. The arches read as dark or blue rectangles, nothing more.
- **Value structure:** day frames are mid-key and flat, with no darks to anchor them except the roofs. Night interiors invert the expected value structure, coming out brighter than the exterior.
- **Intentionality:** the village house kit looks intentional. The nave and Shrine Room look procedural: empty boxes, text-label signage, flat colour planes and mismatched walls.
- **Artefacts:**
  - roof tile texture on the interior ceiling
  - mirrored labels through walls
  - labels drawn through the creature
  - a pedestal interpenetrating the creature
  - the cyan beam through the roof
  - terrain or foliage filling the upper windows
  - the blank emissive Hall door
  - loose props on the verge
  - the flat card tree

## 1. The three things that most separate these frames from the references (ranked)

1. **Atmosphere and lighting depth.** There is no aerial perspective, haze, fog, sun shafts or real night darkness. Weather either does nothing (day rain) or lifts the frame to grey (night rain). The key art and Valheim-class bar rely on graded depth and light, and these frames are flat-lit throughout.
2. **The Hall interior is unfinished and inside-out.** The ceiling shows exterior roof tiles, the windows look onto its own roof, the portals are flat blue planes with tiny floating text, the Shrine pedestals are music stands, and night interiors are flood-lit blue. Nothing reads as a magical portal hall.
3. **Density and life in the settlement.** The houses scatter across open field with almost no dressing. The tree canopy is sparse, a card tree sits in the hero frame, every human holds a bind-pose A-stance, and there is no wildlife. The key-art settlement is lush, cluttered and framed by big oaks.

## 2. Destination check (farm-door)

- **Day: YES, weakly.** The Hall is centred on the road axis, caps the vista with clear sky around its tower, and stands taller than the houses at a similar distance. However, it is small (about 170x190 px), uses the same plaster, timber and terracotta language as the houses, and has no stone-mass contrast. It reads as a big house, not an obvious landmark.
- **Night: YES, weakly.** The silhouette survives against the blue sky, and the lit door and two sconces mark it. Its warm pools are no stronger than the nearer house windows, and its large gable windows are dark.

## 3. Interior check

- **Enclosed, lit hall interior: NO.** Walls and beams say "interior". The exterior-tile ceiling, clerestories framing its own roof, the quest beam through the roof and the flat moonlit night floor say "roofless courtyard". Lanterns do not light the space.
- **Arches:** readable as arch-shaped doorways. They do not read as portals, and sealed versus live differs only by blue shade. Biome labels are about 12-16 px floating text, duplicated, sometimes mirrored, sometimes under the HUD. The home arch is identifiable only by its label and was blocked by the companion in nave-reverse.
- **Pedestals:** readable as wooden stands. No station shows all eight, and only the nearest one or two labels are legible.

## 4. Bars

- **Bar A: NO.**
  - Carried by: the coherent timber-and-stone house kit, Terrapup's appeal and scale, and a pleasant golden-hour grade.
  - Sank it: the empty, inside-out interior; a sparse, undressed village; bind-pose humans; a weak Hall identity; and missing key-art lushness.
- **Bar B: NO.**
  - Carried by: golden hour, where the long shadows and window stripes in the nave are the one Valheim-adjacent moment.
  - Sank it: no haze, fog, shafts or depth bands; night that is not dark; night rain brighter than night clear; day rain that changes nothing; and flat-lit night interiors.

### Gaps (a): fixable by scene changes with installed assets

- **Atmosphere and grade:**
  - Add distance fog or height fog and morning aerial perspective. Tint distant bands cool.
  - Darken night ambient and the night interior ambient. Make lanterns real omni lights with warm pools, and add warm window and door lights with ground spill.
  - Make rain darken and lower ambient, add a wet roughness and darkening on road and stone, and make rain streaks visible.
  - Reduce the trainer's night fill or rim light.
- **Hall interior geometry:**
  - Give the interior a proper ceiling material (timber boards or plaster) instead of the exterior tiles.
  - Fill or relocate the clerestories that look onto the roof.
  - Unify the wall material.
  - Add interior haze.
  - Hide the quest beam indoors.
  - Fix mirrored and backface labels and depth-test labels against walls.
  - Keep the companion and pedestals from interpenetrating.
  - Keep the companion out of the camera and away from the home arch.
- **Portals:** give each arch a shader surface (animated swirl for live, dark stone or iron grate for sealed). Use one carved plaque per arch, with biome colour and icon, instead of two text lines.
- **Village:**
  - Narrow and blend the road.
  - Dress the houses with Board 07 props (well, carts, crates, fences, flower boxes, lantern posts that emit light).
  - Plant real oak canopy trees from the installed family in place of the card tree.
  - Move the houses to front the road consistently.
- **Hall exterior:**
  - Give it more stone mass (extend the stone up the gables, darker stone tint), add banners, and add a lit door interior.
  - Warm-light the gable windows at night.
  - Make the sign legible.
- **UI:**
  - Hide world labels under HUD panels.
  - Move the time label or prompt off key subjects.
  - Collapse the empty hotbar.
  - Fix the "Sealed relic" string.
- **Humans:** use a relaxed idle animation for the trainer and NPCs instead of the A-pose, if an installed idle exists.

### Gaps (b): needing new art not in the build

- A dedicated stone civic Hall model, or significant kit pieces (a tower with real mass, buttresses, a carved portal frame), so it contrasts with the timber houses.
- Portal arch hero assets with carved biome emblems and a sealed-state treatment.
- Shrine pedestal and relic display hero props.
- Possibly human idle and ambient animation sets, if none are installed.
- Hero oak trees at key-art scale, if the installed family lacks them.

## 5. Broken or unrepresentative frames

- **shrine-pedestals_day_clear, _day_rain, _golden_clear, _night_clear, _night_rain:** the companion fills about a quarter of the frame at camera range and labels draw through it. These frames under-represent the room.
- **shrine-pedestals-reverse_*:** the pedestal and label interpenetrate the companion.
- **nave-reverse_*:** the companion blocks the home arch, the key subject of that view.
- **farm-door_night_rain and hall-approach_night_rain:** visibly brighter and greyer than their night_clear counterparts. Either the rain weather overrides the night grade, or these are not representative of night.
- **street-mid-left/right_*:** framed as "house frontages mid-road", but they show houses scattered on open field with no road edge. Either the station is mispositioned or the layout breaks there.
- **nave interior night and rain variants:** brighter than or equal to day in floor value. If interiors are meant to have their own lighting, they do not appear to receive a separate night or interior state.
