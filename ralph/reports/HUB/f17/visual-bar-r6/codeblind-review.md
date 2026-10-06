# Code-blind visual review: village road, Crossing Hall, nave and Shrine Room (visual-bar-r6)

Inputs: the overview sheet, the street-mid-left and hall-approach-reverse sheets, and these full frames: farm-door day/night, street-mid-right golden, hall-approach day/night/night_rain, nave-forward day/night, nave-arches-left night, nave-arches-right day, nave-reverse night, shrine-pedestals night, shrine-pedestals-reverse day. References: the keyart and palworld-02, -03 and -05. Pixel coordinates are for 1920x1080.

## Summary

The exterior is close to working. The street has a readable axis, decent grass, believable golden hour and a creature at the correct scale. The interior isn't working yet. It is a plaster-and-cobble box with flat blue rectangles for portals, and its lanterns don't light anything. At night the end wall goes black, and in the shrine room the windows show daylit hillside. Floating world labels also clip behind the HUD. Most of the interior problems can be fixed with assets already in the frames.

## 1. Silhouette and readability at small size (overview at about 30%)
- **Exterior frames read.** The street axis, the gabled houses and the Terrapup's black-and-white face survive at thumbnail size. The trainer's silhouette is weak whenever their back is to the camera (farm-door, hall-approach): it is a brown-and-teal blob with no readable outline against the brown road.
- **Interior frames don't read at small size.** Overview rows 2 and 4 (the nave, day and night) become beige or brown walls plus a black rectangle. Nothing tells you "hall of portals". The arches are thin dark frames around flat blue quads (nave-forward_day 310–430, 400–660; nave-arches-left_night 650–770, 390–565 and 1070–1170, 390–555). There is no keystone, light, banner or emblem, so nothing gives them a silhouette.
- **Shrine-room lecterns are thin brown sticks** against a brown floor (shrine-pedestals_night 300–460, 610–880 and 650–720, 515–680). At 30% they disappear. Nothing on them (no relic, glow or cloth) gives them a shape.

## 2. Colour and value structure
- **The exterior is one coherent place.** It uses warm brown roofs, cream plaster, grey stone, an ochre road and green grass, broadly matching the keyart palette. But the road is a large unbroken ochre field filling 40% of every exterior frame (farm-door_day 300–1300, 480–1080; hall-approach_day 300–1300, 470–1080), with no value break, path edging or puddles.
- **The interior belongs to a different game.** It is a flat cream plaster box on a blue-grey cobble floor. The cobble floor (nave-arches-right_day, whole lower half) is cool grey and nearly white in highlights, which doesn't match the warm exterior.
- **Night has no value hierarchy.** In nave-forward_night the floor, walls and creature all sit in the same dim mid-brown. The end wall (680–1250, 130–510) falls to pure black with no gradient.
- **Night rain looks brighter than clear night.** hall-approach_night_rain has a teal-grey sky (0–1920, 0–250) brighter than night_clear. Rain is barely visible (a few hairline streaks), with no wet sheen on the road.
- **Oxblood check: no faction red on friendly elements.** One mild flag: the dark red cattail or reed clump at street-mid-right_golden 610–720, 900–1070 (also at hall-approach 290–330, 660–720) is close to the reserved red. Desaturate it toward rust or brown.

## 3. Intentionality (authored vs procedural)
- **The street is laid out like a corridor, not a lived-in place.** It has two straight rows of houses with nothing between them. It lacks the keyart's well, fence runs, carts, crates, sign banner, trees overhanging the road and laundry. The only clutter is a few lamp posts and one NPC (farm-door_day 1190–1215, 395–460).
- **Flat grey slabs sit in front of doors** (hall-approach_day 580–700, 480–505 and 1150–1290, 490–515). They look like placeholder collision pads, not steps or paving.
- **The nave interior is undressed.** It has no benches, rugs, banners, tables, plants or crates, and no lit hearth. The only props are lantern brackets and lecterns. Palworld-05's base reads as used; this hall reads as unfurnished.
- **A pale pink plank lies by a cottage door** (street-mid-right_golden 930–1035, 520–540) with no clear purpose. It reads as a stray mesh.

## 4. Lighting
- **Golden hour is the strongest light in the set.** street-mid-right_golden and hall-approach-reverse_golden have long, raking shadows (the trainer's shadow at 600–1100, 700–800) and warm rim light. Day is acceptable but flat-lit from above.
- **The hall facade at night is darker than the cottages beside it.** In hall-approach_night_clear the cottage windows are lit warm (260–330, 400–465; 1390–1550, 390–460). The hall's own windows are black squares (880–1015, 215–250 and 930–960, 310–340). The left hall wing has flat white, not warm, windows (595–745, 320–345). The building meant to be the destination is the least lit thing on the street.
- **Interior lanterns are unlit.** Every hanging lantern is a grey cage with no emissive core and no light pool: nave-forward_night 520–560, 290–330 and 1360–1395, 290–330; nave-arches-left_night 420–470, 280–325 and 905–940, 285–330; shrine-pedestals_night 1025–1050, 310–360. The warm wall wash in shrine-pedestals_night (760–1100, 380–520) has no visible source.
- **The windows show the wrong time of day.** In shrine-pedestals_night at 23:00, the windows show bright, daylit green hillside (150–330, 0–180; 430–530, 80–240; 1150–1240, 185–280). This looks like a bug.
- **Daylight on the interior floor is broken up.** The sun patches are stark paper-white rectangles that read as missing-texture holes (nave-forward_day 680–810, 510–610; nave-arches-right_day 1030–1300, 488–505; shrine-pedestals-reverse_day 1000–1250, 520–800).
- **Contact shadows are missing.** The Terrapup has a weak contact shadow inside, and the lecterns have none at night.

## 5. Horizon and depth
- **The distant mountains are flat cutouts.** They are single-value pale shapes, with no layering, haze ramp or texture (street-mid-right_golden 330–800, 255–320; farm-door_day 830–1180, 240–300). The keyart and palworld-02 both use layered, hazed ridgelines.
- **The farm-door vista dies in the middle distance.** Beyond the hall there are only mountain cutouts. There are no tree masses to frame the hall, and the left hillside is a bare green slope (0–250, 0–400).
- **There is little aerial perspective by day.** Distant houses (1050–1230, 270–400) are as saturated as near ones.
- **The interior has visible seams.** Through the nave clerestory windows you can see the building's own exterior roof eaves and tiles (nave-arches-right_day 1020–1640, 140–260). The dark zig-zag strip at 300–1200, 0–210 is the outer roof edge seen from inside, which means there is no ceiling or soffit. In shrine-pedestals-reverse_day, the plaster side wall meets the stone end wall at 1190–1210 with no trim or corner piece.

## 6. Interface
- **The clock collides with geometry and lanterns.** "Day 1 · hh:mm" is drawn at the top centre over the hall tower and over the nave's ceiling lantern (hall-approach_day 870–1050, 60–95; nave-forward_day lantern at 945–975, 85–135; shrine-pedestals_night lantern at 935–985, 0–60).
- **World labels show through and behind HUD panels.** "Sout" pokes out from behind the story panel (farm-door_day/night 1810–1910, 320–360). Ghost labels "the Stormwood" and "Locked" show through the quest panel (nave-forward_day/night 1520–1640, 280–360). "Tidewake" is drawn half under the quickbar (shrine-pedestals_night 1380–1610, 615–660). "Cloudre…" is cut off by the creature's head (1215–1300, 500–525).
- **Labels are duplicated and drawn at different sizes.** In nave-forward, "Sealed" appears twice, stacked and tilted (317, 290 and 342, 354). In shrine-pedestals-reverse_day, "The Meadows" and "Tidewake" sit on one lectern (580–760, 455–510), and "Cloudreach Cliffs" (290–630, 580–620) is three times the size of the others.
- **HUD panels hide subjects.** The quickbar and Build/Map strip cover the lower right quarter, and in the shrine frames the HUD moves up (1210–1860, 630–840) and covers a lectern and the creature's paws. The "Hang your Cloudreach Cliffs relic" prompt sits on the floor area where the relic action happens.
- **The team panel covers the cottage** in street-mid-left_day (top left).
- **The UI is clean.** Text is legible and teal and gold are consistent. No defect there.

## 7. Artefacts
- **The portal quads look like missing geometry.** They are flat navy or cream quads that don't fill their arches. The Home arch quad (nave-arches-right_day 140–290, 390–555) is cream and narrower than its arch, with real outdoors visible beside it (95–140, 410–545). The portals look like untextured placeholders.
- **The creature clips through a lectern.** In shrine-pedestals_night, the lectern at 1420–1560, 840–1060 passes through the Terrapup's paw and body.
- **Wall-bracket lanterns poke through the wall.** Their horizontal arms point out into the room like a gun barrel and cross a window opening (shrine-pedestals-reverse_day 1480–1650, 150–260; shrine-pedestals_night 260–430, 150–230). One bracket arm pokes from behind the quest panel (1480–1560, 280–350).
- **The trainer stands in an A-pose** with arms spread stiffly away from the body in every idle frame (farm-door 780–1140, 690–900; nave-reverse_night 895–1025, 590–700). It reads as a bind pose, not a relaxed idle.
- **The moon is in the sky at 18:00** next to a sunset (hall-approach-reverse_golden, moon at about 905, 57 on the sheet).
- **The cobbles are too large.** Near the trainer each cobble is about 90–110 px wide while the trainer is about 250 px tall, so each stone is about 0.7 m. The stones on the right nave wall (nave-forward_day 1600–1920, 400–700) are larger still.

## 8. Scale against the 1.80 m trainer
- **Terrapup is correct:** about 1.6 times the trainer's height and bulky. It never shrinks to fit the camera. Good.
- **Cottage doors are about right**, roughly 2.1 m.
- **The Crossing Hall door is undersized for a civic entrance.** In hall-approach_day the door (925–965, 380–445) works out to about 2 m tall: the same as a cottage door, on a building three storeys high. It should be double-height or double-leaf.
- **Lecterns are about 1.2 m.** That's fine, but they are lecterns, not pedestals, and look like music stands.
- **The nave is about 6 m wall-to-wall**, which is narrow for a hall of portals. Its arches are about 3 m and fine for the trainer, but too small for the creatures that are supposed to pass through them.

## The three checks
- **Destination from the farmhouse door.** Day: **WEAK.** The hall is on the road's axis and is the tallest gable (farm-door_day 840–1030, 210–395), which works. But it uses the same roof, timber and stone as the cottages, fills about 10% of the frame width, and has no colour, flag, light or tree framing to set it apart. It reads as "a bigger house". Night: **NO.** In farm-door_night the hall is a dark silhouette with one tiny lit door (950–965, 370–395). The cottages on either side have brighter windows, so the eye goes to the left cottage instead.
- **Front door at night: WEAK.** There is a warm pool on the step (hall-approach_night_clear 880–1010, 455–472) and two small sconces. But the doorway itself is a flat, evenly lit cream rectangle (925–965, 380–445). It reads as a poster or an emissive card, not an opening into a lit room. The facade windows above are black, and nothing frames or announces the door, such as a lantern arch or banner.
- **Interior at night: NO.** The nave reads as a dim box. In nave-forward_night the end wall is a black void (680–1250, 130–510), and nave-reverse_night has a flat navy back wall. The lanterns don't glow. The only warm light is an untraceable wash. In the shrine room the windows show daylit hillside at 23:00, which breaks enclosure completely. It doesn't read as an enclosed interior lit by warm practical lights.

## Finish

### 1. The three biggest differences from the references, ranked
1. **Interior emptiness and lighting** (nave-forward_night, shrine-pedestals_night). The night panel in the keyart, and palworld-05, put a few strong warm sources in frame (fire, torches) that create pools and silhouettes. Everything else is allowed to go dark around them. These interiors have unlit lanterns, black or void walls, and windows that show the wrong time of day. They are also empty of furniture.
2. **Vegetation and clutter density** (farm-door_day, hall-approach_day). Palworld-02 and -03 fill the middle and back with tree masses, bushes and rocks, so ground cover reaches the horizon. The keyart settlement wraps houses in oaks, fences and a well. Here 40% of each frame is bare ochre road, there are almost no trees on the street, and the midground is empty.
3. **Depth and horizon** (street-mid-right_golden, farm-door_day). The references use layered, hazed hills and forest silhouettes at three or four distances. Here there is one cutout mountain band behind a hard-edged foreground, with no trees in between.

### 2. Bars
- **Bar A (belongs in the keyart's world): NO, though the exterior is close.** What carried it: the timber-frame cottages with stone plinths, the warm roofs, the meadow flowers and the golden-hour light. What sank it: the interiors bear no relation to the keyart, there are no oaks around the village, and the hall is just a scaled-up cottage rather than a landmark visible from a distance.
- **Bar B (reads as the same kind of game as Palworld): YES for the exterior, NO for the interior.** What carried it: a third-person trainer with a large companion creature, the HUD layout, real-time light and a believable creature design. What sank it: the bare road and thin foliage outside, and inside the placeholder portal quads, the floating duplicate labels, and the bind-pose trainer.

### 3. Gaps
**(a) Fixable with assets already visible in these frames**
1. Light every lantern already placed: give it an emissive core and a warm omni light (nave walls, shrine room, both street lamp posts). Add two flanking lanterns inside each arch.
2. Light the hall facade at night: warm emissive in all facade windows (880–1015, 215–250; 930–960, 310–340), and make the wing windows warm, not white. Add the cottage-style window glow so the hall is the brightest building on the street.
3. Fix the door. Replace the flat cream door quad with an open dark doorway with interior light spilling out, or a lit wooden door. Make it double-height. Frame it with two sconces on the pilasters plus a hanging lantern over the arch.
4. At night, give the nave end wall a fill light, or put a lit hearth or brazier there, so it isn't a black void (nave-forward_night 680–1250, 130–510).
5. Make the window views match the time of day. At night, show night sky or night lighting through the shrine-room windows; nothing should show daylit grass.
6. Add a ceiling or soffit, or lower the roof planes, so the exterior eave and roof edge aren't visible from inside (nave-arches-right_day 300–1640, 0–260).
7. Turn the bracket-lantern arms to sit flush against the wall, and pull them out of the window openings (shrine-pedestals-reverse_day 1480–1650, 150–350).
8. Separate the creature from the lectern. Move the lectern, or keep the Terrapup out of the lectern row (shrine-pedestals_night 1420–1560, 840–1060).
9. Fix the world labels:
   - one label per object
   - fixed screen-space size
   - hidden or faded behind HUD panels and occluding geometry
   - no tilt or skew
   - only nearby labels shown

   Drop the duplicate "Sealed" and "Locked" lines.
10. Move the clock off the top-centre axis, or put it on a backing plate, so it doesn't sit on the tower and the ceiling lanterns.
11. Make the portal quads fill their arch openings, and give them a faint gradient or vignette instead of flat navy or cream. Hang the existing Team-neutral banner or sign assets above each arch so each one has a silhouette.
12. Dress the street with props already in the village family: fence runs along the grass verges, trees from the hillside (0–350, 0–450) lining the road and framing the hall, and lamp posts at regular intervals leading to the door. Add NPCs at doorways. Break up the ochre road with a gravel or stone strip leading to the hall door.
13. Replace the grey slabs in front of doors with the stone paving already used at the hall step.
14. Rescale the floor cobble and wall stone textures down by about 2.5x, both inside and out.
15. Swap the warm side-wall plaster and the cool cobble floor for one consistent palette. Warm up the floor texture tint.
16. Turn the floor sun patches down from white to warm and soften their edges.
17. Add distance fog or haze in the day and golden-hour frames, and tint the distant mountains toward the sky colour so they recede.
18. Push the rain night: darker sky, more and longer streaks, and a wet-road specular term.
19. Desaturate the red reed clumps toward rust.
20. Remove the moon from the golden-hour sky.
21. Remove the stray pink plank.

**(b) Needs new art not in the frames**
1. A distinct Crossing Hall silhouette, such as a clock or bell tower with a lit lantern room, a different roof material or a portico, so it reads as civic rather than a big cottage.
2. Real portal art for the arches: a framed gate mesh, a shader surface with depth or swirl, and per-destination emblems.
3. Shrine relic pedestals with displayed relics, as opposed to music-stand lecterns.
4. Interior furniture: benches, rugs, tables, a hearth, hall banners, plants.
5. Layered distant terrain: hill and forest backdrop cards or meshes to replace the single mountain cutout band.
6. A relaxed trainer idle animation to replace the A-pose.
7. Rain and wet-ground materials (puddle decals, wet masks).
