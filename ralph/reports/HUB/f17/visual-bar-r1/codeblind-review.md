# F17 village/Hall visual bar r1: code-blind review

Judge: code-blind (pictures only). I looked at 43 frames (1920x1080, Compatibility/Low, HUD on), 11 contact sheets, the Meadows key art, the 19_Meadows asset board and the Palworld references. I opened no code, config, reports or docs. The review gives defects and verdicts, not scores.

## Domain defects

### Grounds and paths
- **farm-door_* (all), street-mid-left/right_* (all)**: the road is one flat ochre noise texture with no wheel ruts, no edging stones, no puddles, no worn centre line and no grass encroaching. It covers about 40% of every street frame (the band from y 450 to 1080), so the largest surface on screen is the least designed. Compare the Village Life panel on the asset board: a cobbled or edged lane with verges.
- **street-mid-right_day_clear**: flat grey concrete-like slabs sit in front of the houses as forecourts, at about x 330-600 y 515-550 and x 1440-1760 y 555-600. Their edges are hard rectangles with no path joining them to the road, so they look like placeholders. The same slab appears in front of the Inn in **street-mid-left_* (x 240-620, y 575-630)**.
- **hall-approach_* (all)**: the foreground grass (x 0-420, y 760-900, and the right edge) is a smeared, stretched texture with no blades. It reads as a missing LOD or a magnified texture.
- **Rain frames (farm-door_day_rain, hall-approach_day_rain, nave-forward_day_rain)**: the road and stone are not darkened and show no wet sheen or puddles. Day rain is almost identical to day clear apart from the sky.

### Trees, rocks and vegetation
- **farm-door_* (top-left, x 240-450, y 10-160)**: the tree on the hill is a thin, sparse sprite cluster. The hill behind it (x 0-260, y 30-420) has a coarse low-poly heightfield with a blotchy repeated texture. It is the first piece of nature the player sees and it is far below the key art's oak groves.
- **street-mid-left/right_day**: the background trees are small lollipop shapes scattered evenly on open grass. There are no clusters, no undergrowth and no hero oak beside the road. The key-art Starting Settlement frames the street with large trees, and these frames have none.
- **Grass and flowers**: tuft density is reasonable along the verges, but the tufts are planted in rows parallel to the road edge (farm-door, x 1050-1650, y 430-560), which looks procedural.
- **shrine-pedestals_day_clear, x 1045-1125, y 195-290**: a solid lime-green block fills a window. That is tree foliage pressed against the outside of the wall. The same thing happens in **nave-forward (x 1295-1335, y 220-300)** and in **nave-arches-left/reverse (x 1400-1460, y 225-270)**.

### Architecture (village)
- **The houses are the strongest asset in the set**: timber-framed, with tiled roofs, chimneys, ivy and a legible Inn sign. They match the key art's family well.
- **Lived-in density is low.** In street-mid-left/right the houses stand alone on open meadow with wide gaps. There are no fences, gardens, washing lines, stacked crates, carts, wells or lit hearth smoke. The key art and the asset board's Village Life panel are packed with props. "One straight road lined with lived-in houses" holds only at the farm door. Mid-street, the road dissolves into an open field.
- **street-mid-left_night_clear (x 520-620, y 195-295; x 830-860, y 330-460)**: the Inn's upper windows render pure cool white, not warm. Only the porch under the awning gets warm light.
- **farm-door_night_clear**: the house windows on the near left (x 440-560, y 350-440) are lit, but there are no warm light pools on the ground in front of the doors. The road stays one cool brown.

### Architecture (Crossing Hall)
- **Destination scale (farm-door_*, x 855-1030, y 255-395)**: at the far end the Hall is about 175 px wide and 140 px tall. Its tallest gable (y ≈ 258) is only about 40 px above the far-right house ridges (y ≈ 300). The near houses (left roof up to y ≈ 165, right roof up to y ≈ 110) dominate the frame. No tower, spire, bell-cote or banner breaks the skyline, so the Hall reads as one more house with three gables. It is lighter in value than the timber houses, but it does not read as a stone mass, because its face is pale plaster-like and its roofs match the houses' red tile.
- **No clear sky interval** around the top of the Hall at day: the gable sits against cloud of similar value (farm-door_day_clear, x 900-1060, y 180-300).
- **hall-approach_* (all)**: the ordinary camera is crammed against the Hall's façade. The frame is about 85% stone wall. The roofline, mass and silhouette are never seen at this station.
- **hall-approach_*: the stone texture is badly over-scaled.** Each stone is about 100-130 px wide next to a trainer about 250 px tall, so each stone is roughly 0.7-0.9 m. The tiling is obvious and cartoonish. The same oversize appears on the nave floor and walls.
- **hall-approach_*: the entrance is undersized.** The 1.80 m trainer reaches about two-thirds of the door's height (door top y ≈ 400, trainer y 530-780), so the door is about 2.7 m. A landmark Hall's main door should be at least two to three times the trainer's height.
- **hall-approach_* (x 855-1005, y 400-640)**: through the doorway you see a flat, unlit cream plane with no interior, light or depth. On both jambs (x 810-850 and 1005-1030) slivers of grey or blue sky show. Geometry is see-through at the reveals.
- **hall-approach_* (x 830-1010, y 0-175)**: the opening above the door shows sky through the building.
- **Nave roof (nave-forward_*, nave-arches-*, nave-reverse_*, shrine-*)**: **there is no ridge or ceiling.** The two roof slopes stop short of each other and leave a wide open slot to the sky (nave-forward x 600-1150, y 0-240) that shows trees and neighbouring roofs. A lantern (x 880-905, y 0-130) hangs from nothing over the gap. This is the single most damaging interior defect.
- **Clerestory windows on every interior wall are empty holes** with no glass or frames, and they look straight out to sky and foliage. The interior reads as an unfinished shell.
- **The interior walls mix materials** (one plaster wall against grey cobble walls) with hard seams at the corners (nave-forward x 575-600, full height). Bright diagonal light stripes cross the walls and floor where light leaks through gaps: nave-arches-left/nave-reverse x 960-1060 y 380-480 and x 1500-1900 y 430-610, and shrine-pedestals-reverse x 880-1180 y 180-880. These read as leaks, not designed sun shafts.
- **Far end of the nave (nave-forward, x 590-1150, y 240-490)**: a blank cobble wall with no focal point, banner, brazier or arch.

### Portal arches and signage
- **The arches are flat quads**: a thin brown frame around a solid blue rectangle, navy for "Sealed" and pale sky-blue for "Locked". Nothing glows, there is no depth, no rune stone, no biome motif and no difference between live-capable and sealed beyond a blue tint. None reads as a portal.
- **The arches are small.** The nearest arch (nave-forward, x 125-360, y 340-720) is about 1.5 trainer-heights, so about 2.7 m.
- **Biome signing mostly fails.** Most labels give a state ("Sealed", "Locked") instead of a biome. Only "Cloudreach Cliffs" and "The Stormwood" are legible. The labels on the far arches are illegible, about 6-8 px text (nave-arches-left x 505-540 y 320-365, x 1165-1190 y 330-370). The home-arch label "The Meadows / Home arch" (x 820-900, y 335-370) cannot be read at gameplay distance.
- **Mirrored text**: the lectern labels seen from behind render reversed ("ʇiQ", "…M ɘʜT") in nave-arches-left/nave-reverse (x 1460-1570, y 460-480; x 1680-1810, y 490-515).
- **The number of arches cannot be confirmed.** Across the nave frames I can find the home arch and about 4-6 portal arches. No single frame establishes the 7-arch layout.
- **Interior haze is absent.** The nave has no depth fog at any time of day. Every surface is equally crisp.

### Shrine Room
- **The "pedestals" are thin wooden lectern stands.** Read as pedestals they have no mass, plinths, relic sockets or lighting. I can see six to seven per frame, and the eighth is likely behind the HUD (shrine-pedestals x 1460-1570, y 620-920).
- **The pedestal labels are tilted Label3D planes at varying angles** ("Sealed", "Cloudreach Cliffs"). The near one in shrine-pedestals-reverse (x 250-470, y 630-800) is huge compared with the far ones (about 8 px).
- **The room is empty**: no altar, no niches, no banners, no warm light. It has the same open roof and empty windows as the nave.

### Props
- **hall-approach_* (x 400-560 and 1280-1420, y 0-235)**: the iron lantern cages are empty, with no flame or emissive core. They still throw light pools on the wall, so the light has no visible source.
- **There are hardly any village props.** I see barrels and a bench at the Inn, a lamp post at the far left of the farm door, and fence posts on the right. There are no carts, crates, flower boxes, wells, signposts, banners or market stalls on the road.
- **nave-***: the only interior props are the lecterns and the hanging lantern.

### Humans
- **The trainer reads well in daylight.** The silhouette is clear and the proportions agree with the doors and benches of the village houses.
- **Night lighting on the trainer is off.** In farm-door_night_clear and farm-door_night_rain (x 770-1140, y 510-1080) the trainer's hair and backpack are lit warm and bright, much brighter than anything else in the scene. They look self-lit or carry a separate fill light, and the trainer pops out of the night grade.
- **street-mid-right_day/golden (x 320-380, y 440-550)**: the villager's face looks chalk-white or grey, like a possible missing skin material, or at least it reads that way at this distance.
- **Townspeople are sparse**: two or three per street frame, all standing idle.

### Creatures
- Only tiny distant wild critters are visible (street-mid-left x 925-940, y 415-430; street-mid-right x 935-1100, y 430-455). No companion is on screen, despite "Call out Terrapup" being prompted. Creature appeal cannot be judged from this set, and that alone keeps Bar A open.

### Water, sky and light
- **Day (farm-door_day_clear, street-mid-*)**: saturated blue sky with plausible clouds, and pleasant warm-neutral light. There is **no aerial perspective**. The Hall at about 60-80 m has the same contrast and saturation as the house at 5 m, so the three depth bands (foreground, houses, distant Hall) do not separate. There is no morning haze.
- **Golden (farm-door_golden, street-mid-right_golden)**: the best frames in the set, with a real amber key, long raking shadows and warm roofs. **hall-approach_golden_clear** overexposes the façade to near-cream, so the stone loses texture and contrast, and "amber sun against cool stone" does not happen. In **hall-approach_golden (x 860-950, y 410-640; x 1170-1270, y 60-250)** the shadow edges are visibly stair-stepped and aliased.
- **Night (clear)**: the exterior is reasonably blue-dark at the farm door, and the Hall shows two small warm door lamps (farm-door_night_clear x 935-985, y 355-395). This is the best evidence for the destination read. The interior at night, though, is lit only by the same moonlight blue as outdoors (nave-forward_night, nave-reverse_night). The nave has no warm interior light.
- **Night rain fails outright.** farm-door_night_rain, hall-approach_night_rain, nave-forward_night_rain and shrine-pedestals_night_rain are all lifted to a flat grey that is close to daylight value. hall-approach_night_rain is nearly the same as hall-approach_day_rain. The intent says rain must not lift the night to grey.
- **No volumetric shafts, fog layers or weather mood anywhere.** The rain streaks are almost invisible at 1080p.

### UI
- **"Call out Terrapup" prompt (x 800-1125, y 825-865)**: it sits directly over the trainer's backpack in every third-person-behind frame, which hides the character.
- **hall-approach-reverse_* (x 755-1190, y 60-135)**: the world label "The Meadows" overlaps the HUD clock "Day 1 08:00" and makes both unreadable.
- **Objective panel (x 1515-1865, y 255-420)**: it sits over world signage such as "The Stormwood" in the nave and "Sou…" in farm-door at x 1800-1900, y 320-360.
- **The hotbar and prompt bar jump vertically** between frames: y 715-825 normally, y 630-740 in shrine frames when "Call Out" joins the prompt row. The layout is unstable.
- **The prompt reads "Hang your Sealed relic".** The state word "Sealed" is used as an item name, which reads like a data leak.
- The HUD is otherwise clean and readable. The minimap sits a little high and tight to the corner.

## Cross-cutting checks
- **Silhouette at small size**: the houses read. The Hall does not stand out from the houses at farm-door distance. The arches read as blue rectangles, not portals.
- **Value structure**: day and golden are fine outdoors. Interiors are flat mid-grey with no dark-to-light focal structure. Night rain collapses to one grey value.
- **Intentional vs procedural**: the house models feel authored. Their placement, the empty meadow gaps, the uniform road, the slab forecourts and the bare Hall interior feel procedural or blockout.
- **Artefacts**: open roof ridge (nave and shrine); see-through door reveals and the cream void plane (hall-approach); light leaks through wall seams; mirrored Label3D text; a teal vertical beam (street-mid-left x 745-790, y 0-560, and inside the nave at x 1260-1350, y 0-410), probably a quest or objective beam, that passes straight through the Inn and the Hall roof and reads as a glitch; aliased shadows; magnified grass texture. No magenta, no missing-material checkerboard, and no z-fighting found.
- **Scale agreement**: trainer against houses is good. Trainer against the Hall door and the portal arches is too small for a landmark, since the doors are about 1.5× trainer height. Masonry tiles are over-scaled by roughly 2-3×.

## 1. What most separates these frames from the references (ranked)
1. **The Crossing Hall is an unfinished blockout.** It has no landmark silhouette from the road, an over-scaled stone façade, an undersized door, a roof open to the sky, glassless window holes, light leaks, and flat blue quads for portals. The key art's Meadows Hall is a massive, vertical, detailed stone pile, and nothing here approaches it.
2. **No atmosphere.** There is no aerial perspective or haze, no depth separation, no interior haze, no light shafts, no warm interior lighting at night, and rain that greys out the night. Valheim-class atmosphere is entirely absent.
3. **A sparse, under-dressed village.** The houses sit in open meadow with slab forecourts and almost no props or trees around them. The key art's Starting Settlement has a dense lived-in frame of fences, wells, banners, big oaks and clustered buildings.

## 2. Destination check (farm-door frames)
- **Day: NO.** The Hall sits at the road's vanishing point, which helps, but it is small, roughly level with the far houses, the same red-tiled style, and has no tower or contrasting stone mass. A first-time player would read it as another house.
- **Night: NO (marginal).** Two warm door lamps at the vanishing point give it the strongest pull in the frame, but its silhouette against the sky is weak, and in night rain it greys into the background.

## 3. Bar verdicts
- **Bar A (coherent, appealing, matches key art, Palworld-class appeal): NO.** What carries it: the timber house kit, its roof and ivy detail, the trainer model, and the golden-hour frames. What sinks it: the Hall interior (open roof, empty shell, quad portals), the Hall not reading as a landmark, sparse village dressing, and no creature on screen.
- **Bar B (commercial light and atmosphere, Valheim-class): NO.** What carries it: the golden-hour key light and long shadows, and the farm-door night's blue grade with warm Hall door lamps. What sinks it: no fog or haze or aerial perspective, flat interiors, no shafts, aliased shadows, overexposed golden stone, rain that does not darken or wet anything, and night rain lifted to grey.

**Gap split**

(a) Fixable by scene changes, using lighting, fog, palette, density, dressing, composition and kitbash from installed modules:
- Close the nave and shrine roof ridge and ceiling. Fill or glaze the clerestory holes. Seal the wall seams that leak light. Back the doorways with real interior geometry instead of the cream plane.
- Rescale the Hall: a taller central gable or a tower kitbashed from the installed stone and timber modules, a wider and taller main door, and darker, cooler stone so it contrasts with the plaster houses. Reduce the stone texture tiling scale about 2-3×.
- Distance fog and aerial perspective tuned per time of day, plus interior volumetric or height haze in the nave.
- Warm interior point lights in the nave and shrine at night. Emissive flames in the lanterns. Warm ground pools at village doors.
- A rain profile: darker albedo and roughness for road and stone, a lower night-rain exposure ceiling, and visible rain particles.
- Biome-named arch signage at legible size, two-sided labels so nothing renders mirrored, and a glow or emissive treatment on the live-capable portal planes against dark sealed ones.
- Village dressing from installed families: fences, wells, carts, barrels, crates, banners, flower beds and hero oaks lining the road. Replace the slab forecourts with paths.
- Move the hall-approach camera back so it frames the façade. Fix the hall-approach-reverse framing.
- Hide or soften the teal objective beam near buildings. Move the "Call out" prompt off the character. Keep world labels clear of the HUD clock. Stop the hotbar jumping.
- Fix shadow resolution and filtering, the golden façade exposure, and trainer night lighting so it matches the scene.

(b) Needing new art not in the build (as far as these frames show):
- Real portal-arch hero pieces: carved stone arches with biome motifs and portal-surface VFX/shader.
- Shrine pedestals with mass and relic sockets, and the relic objects themselves.
- Better nature: hero oak and tree families, and a higher-quality hill/terrain material, if the installed families can't reach key-art density.
- A Hall exterior with a distinctive landmark silhouette (tower or spire), if no installed module kit can be kitbashed into one.
- On-screen creatures at Palworld-class appeal. This cannot be judged here because none are visible.

## 4. Broken or unrepresentative frames
- **hall-approach-reverse_day/golden/night_clear: broken.** It is meant to look back down the road, but the camera faces a wall inside the Hall. A blank untextured slab fills the home arch (x 765-1185, y 450-1060), the trainer is not visible, a sky hole shows above (x 890-1110, y 0-130), and the world labels collide with the HUD clock. These frames tell you nothing about the road view.
- **nave-arches-left_* and nave-reverse_*: near-duplicates.** Both face the home arch with the trainer facing the camera. Neither frames the left-hand arches as a set, so the "arches-left" station is unrepresentative of its name.
- **hall-approach_***: technically valid, but the camera is so close to the wall that it cannot judge the Hall's exterior or roofline. It is not representative of how a player experiences arrival.
- **All night_rain frames**: they look like day-exposure frames with a grey sky. Either the night grade is not applied under rain, or they were captured with the wrong exposure. Either way they cannot be used as night evidence.
