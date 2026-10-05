# Code-blind visual review: village road, Crossing Hall, nave and Shrine Room (visual-bar-r4, GPU Low)

I read no code, config, docs or reports. I looked only at the 43 frames in `judge_r4/frames/`, the 11 contact sheets in `judge_r4/sheets/`, the Meadows key-art board (`docs/reference/tetherbound-meadows-keyart.png`) and the Meadows asset board (`docs/art/reference/19_Meadows_Asset_Boards_Visual_Direction.png`). I made crops and luminance measurements of my own in the scratchpad. All pixel coordinates below are in the native 1920x1061 frame unless I say otherwise.

## 1. What separates these frames most from the references (ranked)

1. **There is no atmosphere or depth, so the world ends at a hard line.** The references show aerial perspective in every panel: blue-hazed tree lines, a soft horizon, a glowing sky near the sun and a lit night with a moon halo and campfire bloom. These frames have none of that.
   - The distant mountains are flat, untextured blue-grey cones (farm-door_day_clear x 840-1180, y 240-300).
   - Green grass meets the mountains on a knife-edge line with no haze band (hall-approach_day_clear x 1100-1650, y 330-350).
   - The moon is a flat white disc with no halo or bloom (street-mid-right_night_clear x 725-790, y 10-85).
   - No frame shows fog, sun shafts outdoors or a gradient sky near the sun.
   - The golden-hour frames have warm grade and long shadows, which is the best outdoor time of day here, but the sky itself stays flat.
2. **The interiors are large, empty boxes lit by flat, cool ambient light, not furnished rooms lit by warm practical lights.**
   - The nave floor is a uniform grey-lilac at night (nave-forward_night_clear y 600-1060 is evenly lit corner to corner).
   - The far wall is near-black stone with nothing on it (x 920-1500, y 240-470).
   - The hanging iron lanterns have unlit cages, with a small white sphere floating below or beside each cage (x 368,y 298 and x 745,y 328).
   - The portal arches are flat navy rectangles (x 0-130, y 410-760 and x 600-690, y 390-580).
   - The key art's Meadows Hall reads as heavy, banner-hung masonry. This reads as an unfurnished warehouse.
3. **The Hall does not yet read as a civic landmark distinct from the houses.**
   - From the farm door, the Hall is a small cluster of half-timber and plaster gables (crop of farm-door_day_clear x 850-1030, y 205-390). It uses the same gable language as the cottages either side, so it reads as a bigger house.
   - The new crossing tower is visible, but at this distance it reads as a timber-and-plaster belfry, not stone.
   - Banners, steps, a stone plinth and a forecourt all mark the key-art hall as a destination. None of them appear here.

Lesser gaps:
- The village has little life compared with the asset board's "Village Life" panel: no market stalls, carts, flower boxes, lamp posts, people walking the road or smoke from chimneys.
- At night the house windows glow pale cream, not warm amber, and cast no light outside.

## 2. Destination check (from the farm door)

**WEAK by day. Close to YES at night.**

- **Day (farm-door_day_clear):** the road leads straight to the Hall, centred at x 960. The tower breaks the skyline above the mountains (x 935-985, y 205-260). Composition alone makes it the vanishing point. However:
  - the Hall is about 180 px wide at that distance and shares the cottages' gable vocabulary and palette;
  - its door is a tiny cream slot (x 950-968, y 362-388);
  - nothing about its scale or material says "civic stone landmark."
- **Night (farm-door_night_clear):** this is better. The Hall is the only lit mass at the end of the road: two warm wall-lamp pools at about x 935 and x 982, y 352, plus the glowing door. It pulls the eye clearly. It is still small, the Hall windows above the door are dark, and the tower is unlit.
- **Golden:** the Hall goes pale and washed-out against a pale sky, so it reads weaker than at day.

## 3. Front-door check (hall-approach night)

**Partly a lit way in. The light on the ground is real but very shallow, and the doorway itself is a flat emissive rectangle.**

What I see in hall-approach_night_clear:
- **Wall lanterns (x 842 and x 968, y 320-345):** they throw convincing warm pools onto the rubble-stone facade, which is the best new lighting in the set. The lantern housings themselves look dark, so the light has no visible source.
- **The doorway (x 885-930, y 372-440):** a uniform cream rectangle, measured at mean luminance 209. It has:
  - no gradient;
  - no visible vestibule depth, floor, back wall, or figures in silhouette;
  - no glow spilling round the frame.
- **Ground falloff:**
  - threshold strip (y 442-470): luminance 86;
  - about 40 px further out (y 480-520): luminance 34, darker than the moonlit road at y 600-650 (luminance 59).
  - So there is a thin warm sill of light, but no fan of light down the steps and road.
- **Proportion:** the door is about 45 px wide on a facade about 380 px wide, which reads small for a hall entrance.
- **Day frames:** the doorway is the same flat cream card, so it looks like a backdrop rather than a lit interior.
- **Night rain:** same door, with the sky wrongly brighter (see section 5).

## 4. Interior check (nave and Shrine Room at night)

**Enclosed: mostly yes. Lit: no. It reads as moonlight-grey ambient inside a closed box, not as a warm lit interior.**

- **Nave, arches left/right:** this is the best interior shot.
  - The wall sconces cast warm cones onto the masonry above each arch (nave-arches-left_night_clear x 380-470 and x 1240-1320, y 300-360).
  - The floor below stays cool grey. The navy arch openings read as blank.
  - The clerestory windows show night sky, which helps the room read as enclosed.
- **Nave-forward night:** the light is even and cool, with no pools under the hanging lanterns. The back wall is a black void.
- **Nave-reverse night:** a pale, moonlit plaster wall fills the right third (x 1300-1920, y 0-560). It reads as an exterior or an unroofed area.
- **Shrine Room night (shrine-pedestals_night_clear):**
  - It has no warm source at all.
  - The pedestals are bare wooden lecterns with sign text and nothing displayed.
  - The window holes show tree foliage pressed against the openings (x 850-1050, y 195-290), which suggests trees intersecting the building.
- **Day and golden:** these interiors look better than the night ones.
  - The golden sun stripes through the clerestory are the most atmospheric interior moment in the set (nave-forward_golden_clear x 1030-1450, y 290-860).
  - In the day frames the same patches render as hard white shards on the floor (nave-forward_day_clear x 860-1010, y 490-560 and x 260-410, y 525-550), which read as artifacts.

## 5. The two bars

This is the Low (Compatibility) preset. The bars are formally judged on Medium and High; Low is reported here for readability.

- **Bar A (coherent, appealing Tetherbound matching reference and key-art intent, Palworld-class creature and world appeal): NO.**
  - Positive: the trainer and Terrapup are on-model and appealing. Terrapup is big, readable and expressive, with good scale against the trainer (street-mid-left_golden_clear x 510-790, y 280-610). The cottages are one coherent half-timber and stone family, and the road composition matches the "starting settlement" panel.
  - Against: the Hall misses the key-art landmark identity. The interiors are empty and unfurnished. The world has no distance or haze. The creature visibly clips through the nave wall (see section 7). The village lacks the props and life the asset board promises.
- **Bar B (commercial, Valheim-class light and atmosphere at gameplay distance): NO.**
  - There is no fog or aerial perspective, no sky glow, sun shafts or moon halo outdoors, and no wet-surface response in rain.
  - Rain streaks are sparse and visible only against the sky (hall-approach_night_rain, upper right).
  - Night rain is **brighter** than clear night: sky luminance 107 vs 41 at hall-approach, and 88 vs 33 at the farm door. Storm weather lifts the night into flat grey-teal dusk.
  - Golden hour is the one time of day that sells a grade, with long shadows and warm ground.
- **Is Low readable? YES.**
  - Silhouettes, the road, the Hall, the trainer, the creature and the HUD all read at every station and time of day.
  - Night is dark-blue but legible, and the trainer stays clearly visible.
  - Two exceptions: the clear-night far walls in the nave go near-black, and the arch openings read as flat navy.

## 6. Gaps

### (a) Fixable by scene changes with installed assets

1. **Warm interior practical lights.**
   - Give the hanging lanterns and sconces real emissive flames, and put the light where the lantern is (the white bulbs currently sit offset from the cages).
   - Add warm omni pools on the nave floor and the Shrine Room.
   - Lower the cool ambient fill so the night interior reads as lit by its lamps.
   - Give the pedestals a small accent light or a placeholder relic each.
2. **Make the front door a real opening.**
   - Replace the flat cream card with visible vestibule depth: floor, back wall and a hanging lamp inside.
   - Add a warm light just inside the door that spills a long fan down the threshold and road, instead of the current 40 px sill.
   - Light the Hall's upper windows at night and add a lamp in the tower.
   - Consider widening the door or adding a framing arch and steps.
3. **Atmosphere pass outdoors.**
   - Add distance fog and height fog tinted to the sky so the mountains and horizon soften.
   - Add a moon halo or billboard glow.
   - In rain, darken the night grade instead of brightening it, and add fog and denser streaks in front of buildings.
4. **Fix creature and marker placement.**
   - Move Terrapup's follow position so it does not clip into the nave wall (nave-arches-left and nave-reverse, all times of day).
   - Keep the cyan quest beam from passing through the creature's face (street-mid-left_golden_clear x 620-660, y 0-420) and through the nave roof (nave-arches-right x 80-110, sheet coordinates).
5. **Hall landmark dressing.**
   - Add the installed banners (non-red, since red is reserved for Team Tether), a stone forecourt or steps, and flanking lamp posts.
   - Use a stone material on the tower so it differs from the cottage gables.
   - Dress the village: carts, barrels, flower boxes, lamp posts along the road, chimney smoke.

Also fixable:
- Dress the empty nave back wall (x 920-1500, y 240-470) and the Shrine Room with banners, rugs and benches.
- Fix the mirrored sign text (see section 7).
- Turn the cold window glow on the houses warm, and add light spill outside the windows.
- Remove the tree foliage clipping into the shrine windows.
- Remove the white floor shards in the day nave.

### (b) Needing new art

- **A Hall with its own civic silhouette:** a massing or kit piece in heavier masonry (buttresses, a larger arched portal) that does not reuse the cottage gable set. Kitbashing installed stone pieces may get part of the way.
- **Distant terrain and skybox:** the flat-shaded mountain cones need textured or painted distant terrain, or a painted panoramic sky backdrop, to reach the key art's layered distance.
- **Relic and shrine props:** pedestal relics and shrine ornaments, if none are installed.
- **Portal arch interiors:** a portal surface or vista material for the navy arch openings, so "Sealed" and "Locked" portals read as magical gates and not blank panels.

## 7. Broken or unrepresentative frames

- **Creature clipping:**
  - nave-arches-left (day, golden and night): Terrapup's head protrudes from the stone wall with its body hidden (night x 515-610, y 300-420);
  - nave-reverse (all five frames): same problem (night x 545-680, y 300-430).
  - This is a broken frame for presentation purposes.
- **Mirrored sign text:** a pedestal label renders backwards ("sffilC ... uolC") in nave-forward (all times of day, x 285-415, y 465-490), and a second label overlaps it ("boowm..." at x 505-580, y 450-460).
- **World-space labels behind the HUD:**
  - "Stormwood" and "Locked" bleed out behind the quest panel at the right edge in nave-forward (x 1770-1910, y 240-350);
  - "S out" does the same in the farm-door frames (x 1795-1890, y 315-360).
  - These are distracting, but HUD-related.
- **Night rain frames** (farm-door, hall-approach, nave and shrine): they show a brighter, greyer night than clear night. They represent a weather-grade defect rather than intended mood.
- **Day nave frames:** white rectangular light shards on the floor (nave-forward_day_clear x 860-1010, y 490-560) read as artifacts.
- No frame is black, corrupt or mis-sized. All 43 frames load and match their station names.
