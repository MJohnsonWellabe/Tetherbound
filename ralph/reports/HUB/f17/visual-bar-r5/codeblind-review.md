# Code-blind visual review: village road, Crossing Hall, nave and Shrine Room (visual-bar-r5)

**Sources.** I looked at images only: all 12 contact sheets, the overview, and the full-size frames named below. I compared them with the keyart and palworld-02, -03 and -05. Pixel regions are in native 1920x1080 frame coordinates.

## Headline
The exterior village street is now a believable, readable place in daylight and golden hour. The interior is not at that level. The Crossing Hall nave and the Shrine Room read as an untextured-feeling greybox. They have flat placeholder portal cards, floating debug-style labels, roof geometry showing through the ceiling, and night lighting that is cold ambient rather than warm practical lighting. In the strongest exterior frame and the weakest interior frame, the place looks like two different games.

## 1. Silhouette and readability (overview at ~30%)
- **Exterior frames read** (farm-door, street, hall-approach). The road leads to a centred gable, the houses frame both sides, and the badger companion has a strong black/white face mask that is the most readable shape in every frame.
- **Interior frames at 30% are beige boxes with a figure in the middle.** The nave and the shrine have no dominant shape: no altar, no portal glow, no focal object. In nave-arches-left/right and shrine-pedestals, the eye goes to the creature and the HUD, never to the room's purpose.
- **nave-forward_* (all 5 variants):** the camera sits inside or behind the rock-backed companion. Its back and head fill x450–1400, y190–1080. The trainer is fully hidden, and so is the nave's end wall, which is the destination of the room. At 30% this frame is a brown blob. This framing is the single worst readability failure in the set.
- **The trainer is small and dead-centre in every shot.** In hall-approach_day_clear the trainer (x900–1020, y530–780) is the only thing on a large empty dirt foreground (y600–1080, ~45% of the frame).

## 2. Colour and value structure
- **Day and golden exteriors are one place.** The palette is warm ochre road, saturated green grass, plaster with timber framing and brown tile. This matches the keyart. Golden hour (street-mid-right_golden_clear, hall-approach_golden_clear) is the best-looking state in the set, with long shadows and warm rim light.
- **The road is a single flat ochre value.** Across all farm-door, street and hall-approach day frames, the dirt from y600 to y1080 has no ruts, stones, puddles, edge breakup or value change. It is the largest area of the frame and contains the least information.
- **Night exteriors are a uniform blue multiply.** Houses go flat navy (farm-door_night_clear: left house x180–640, y170–470; right house x1220–1680), and most windows stay unlit or only faintly warm. There is no warm–cool split except on the hall facade.
- **The interior palette is beige plaster plus grey cobble plus brown beams.** It has low saturation and no accent colour. Nothing in the nave says "civic hall of a creature-tamer village": no banners, no green/gold heraldry like the keyart's settlement banner.
- **The trainer is lit as if by day at night.** In farm-door_night_clear the hair and backpack (x880–1040, y510–920) are bright orange and cream against a dark navy scene. The figure looks pasted in, or as if it has its own fill light far stronger than anything else.
- **Oxblood:** I found no oxblood/red leak onto friendly elements. Golden-hour roofs push toward terracotta orange (farm-door_golden_clear, roofs at the top left), which stays on the safe side. The orange-red fern in hall-approach_day_clear at about x260–300, y680–740 is borderline but reads as orange.

## 3. Intentionality (authored vs procedural)
- **Street layout:** houses line a straight corridor with equal setbacks and equal grass verges (farm-door_day_clear). It reads as a planned avenue but not a lived-in village. There are no wells, carts, fences across verges, washing lines, crates at doors, market stalls or signs at eye level. The keyart's starting settlement has a well, a banner pole, fences and trees breaking the roofline. Here there are almost no trees inside the village.
- **The hall forecourt has nothing.** In hall-approach_day_clear the dirt road runs straight into the facade at y450. There are no steps, plaza paving, banner poles, lamp posts, planters or notice board. A civic building with no threshold reads as a placeholder.
- **The hall facade is a large stone box with unlit black window holes.** Black squares sit on the upper storey (x880–1030, y210–250) and the left wing (x600–760, y320–350). Day or night, they read as missing geometry, not as glass.
- **The nave is a symmetric corridor of identical units.** Each one has an arch frame, a flat colour card, a lectern and a floating label. The nave-reverse and arches-left frames look procedurally stamped.
- **The interior portals are flat colour quads.**
  - nave-arches-right_golden_clear: "Home arch" is a beige plane (x140–290, y395–560), and a dark slab sits at x1380–1550, y400–620.
  - nave-arches-left_night_clear: navy planes at x700–800 and x1110–1215, y390–555.
  - None has depth, glow, a frame of stone or a vignette of the destination biome. They read as unfinished placeholder cards.
- **The shrine "pedestals" are four identical wooden lecterns** on bare cobble (shrine-pedestals_night_clear: x330–470 y600–880, x650–720 y515–670, x790–830 y475–590). There is no plinth, rug, relic display, candle, offering or niche. The room is a beige box with lecterns.

## 4. Lighting
- **Time of day reads well outside.** Day has a high sun. Golden has long raking shadows: the trainer's shadow in hall-approach_golden_clear is excellent and grounds the figure. Night is clearly night: moon in street-mid-right_night_clear at x445–530, y0–50.
- **Grounding outside is good.** The creature's shadow on the road in street-mid-left_day_clear (x140–560, y590–720) and the trainer's shadow anchor the figures.
- **Exterior night practical lights are weak.** Most house windows read cold or faintly lit. In street-mid-right_night_clear only three window groups glow (x735–790 y405–470, x1490–1520, x1630–1680), and none throws light onto the ground. There are no street lanterns or door lamps with light pools anywhere on the street.
- **Interiors at night are not lit by warm practicals.**
  - In nave-reverse_night_clear and nave-arches-left_night_clear, the iron lanterns (x490–550, y230–330; x940–970; x1360–1420) have no emissive glow and no light pool.
  - The room is lit evenly by a cool blue-white ambient, nearly as bright as day.
  - The shrine's end-wall lantern in shrine-pedestals_night_clear (x1020–1045, y260–360) does throw a warm pool on the wall. It is the only interior practical in the set that works.
- **Interior windows show a daylight or bright-blue sky at 23:00.**
  - nave-arches-left_night_clear: the window row x255–1650, y200–290 is saturated mid-blue, brighter than the walls.
  - shrine-pedestals_night_clear: the left windows (x160–330, y0–200 and x430–520, y80–240) show sunlit green hillside.
  - Night outside the windows contradicts night outside the building.
- **Night is not darker than day indoors.** shrine-pedestals_night_rain is brighter than shrine-pedestals_night_clear: the plaster is near-white.
- **Rain is effectively invisible.** In farm-door_day_rain, hall-approach_day_rain and both night_rain frames I see no streaks, no splashes, no wet sheen on the cobble or road, and no darkened plaster. The rain variants differ only by a slight sky grey.

## 5. Horizon and depth
- **Exterior depth reads.** In farm-door_day_clear the blue mountains at y250–300 and the receding houses carry depth. There is no aerial haze, though: the hall at about 60 m is as sharp and saturated as the near houses. Palworld-04 and the keyart both haze the distance.
- **The hillside at the left of farm-door_day_clear and hall-approach_day_clear (x0–600, y0–350) is a smeared low-res terrain texture.** The tree crown at x240–440, y10–170 in farm-door_* is a dark, coarse, pixel-noisy blob.
- **The village has no skyline layering.** Rooftops sit against bare sky with almost no trees between or behind houses. The keyart's settlement is embedded in oaks.
- **Interior: the ceiling is open to the outside or shows exterior roof.**
  - nave-arches-left_night_clear: exterior roof tiles run along the whole top edge (x0–1920, y0–35).
  - nave-arches-right_golden_clear: the underside of the tile roof with its sawtooth ridge row (x300–1100, y0–200), and a detached upper wall with windows at x0–560, y0–200 hanging over the nave.
  - shrine-pedestals-reverse_night_clear: a black sawtooth ridge strip at x845–870, y0–160.

## 6. Interface
- **The HUD covers about 25% of the frame on the right in every shot**: minimap (x1680–1865, y55–240), quest card (x1515–1865, y255–420), quick bar (x1308–1865, y715–825) and action bar (x1400–1865, y855–930). The quest card sits exactly over the right-hand houses and the hall's right flank in hall-approach_*. Palworld's quest panel is translucent and slimmer.
- **farm-door_* has a world label clipped behind the quest card**: "Sout…" at x1810–1910, y320–365. Italic glyphs poke out to the right of the card.
- **"Day 1 · 08:00" (x868–1050, y60–92) sits on top of the hall gable** in hall-approach_* and over the ceiling lantern in nave-forward and shrine frames.
- **World-space labels are debug-looking text in the scene:**
  - "Sealed" / "Locked" / "The Stormwood" / "Cloudreach Cliffs" float above every arch and lectern.
  - They are clipped by geometry: "ealed" with its first letter inside the lectern board at x330–470, y610–660; "Clo[u]reach Cliffs" cut by a lectern at x285–625, y665–710 (shrine-pedestals-reverse_night_clear); "The Stor[mw]ood" behind a lectern in nave-forward_day_clear at x120–245, y488–505.
  - They are mixed sizes and overlap each other (nave-arches-right_golden_clear, x1090–1390, y430–475: "Ti…ke", "Cloud…fs", "Sea…").
  - They also render under or over HUD panels: "Tidewa…" behind the quick bar at x1380–1530, y690–730 in shrine-pedestals_night_clear, and "Seale…" at x1430–1560, y615–650 in shrine-pedestals-reverse_night_clear.
- **The prompt "Put Terrapup away" (y825–860) sits directly under the trainer's feet** in every frame. The prompt "Hang your Cloudreach Cliffs relic" (x662–1256, y875–930) is legible and well framed.
- **The text is legible.** The HUD font is clean, and the green/gold food and health bars are fine.

## 7. Artefacts
1. **The camera is embedded in the companion** in nave-forward_* (all five): creature back x450–1400, y190–1080.
2. **The quest beacon beam goes through the companion's head** in street-mid-left_* (cyan column x585–640, y0–420, through the badger's face at y300–420). It reads as a bug, not a marker.
3. **Exterior roof tiles and ridge sawtooth are visible from inside**: nave-arches-left_night_clear top strip y0–35; nave-arches-right_golden_clear x300–1100, y0–200; shrine-pedestals-reverse_night_clear x845–870, y0–160.
4. **A detached wall section floats over the nave** with windows open to sky: nave-arches-right_golden_clear x0–560, y0–200.
5. **The portal card is offset from its arch frame**, and the exterior shows through the gap: nave-arches-right_golden_clear "Home arch", green/road visible at x95–140, y400–560 beside the beige card.
6. **A lectern passes through the companion's paw**: shrine-pedestals_night_clear, pedestal post at x1460–1540, y840–1030 inside the creature's forearm.
7. **Unlit black slabs stand beside doorways in the shrine**: shrine-pedestals-reverse_night_clear x230–380, y400–650. In the _day frame it is a black rectangle next to the badger. It reads as missing texture.
8. **Window cards on interior walls show sunlit exterior at night** (see §4). Some show trees cut through the frame edge (nave-forward_day_clear x1430–1480, y200–285).
9. **The cobble floor is oversized and visibly tiled.** Foreground stones are about 100–130 px against a ~260 px trainer, so each stone is roughly 0.7 m (nave-reverse_night_clear, nave-arches-left_night_clear y800–1080). The same pattern repeats on every interior shot.
10. **The end-wall stone in shrine-pedestals-reverse_night_clear (x540–1200, y150–560) is a low-res, magnified texture** with stair-stepped edges.
11. **Plaster walls are blotchy and stretched**: shrine-pedestals_night_clear left wall x0–740, y350–860.
12. **There is no skirting or trim where the walls meet the floor anywhere in the interior.** Wall planes sit straight on the cobble and the seam is a hard, unshaded line.

## 8. Scale (trainer = 1.80 m)
- **Houses, doors and NPCs agree with the trainer.** In street-mid-left_day_clear the cottage door (x1130–1210, y410–530) is about 1.3× the NPC beside it.
- **The companions are correctly taller than the trainer.** Sitting, the badger is about 3 m. The rock-backed creature in hall-approach-reverse_day_clear stands about 2.3 m at the shoulder.
- **The Crossing Hall door is undersized for the building.** In hall-approach_day_clear the door is x935–978, y378–450 under a roughly 3-storey facade. That is cottage-door scale on a civic front, so the entrance looks like a service door.
- **The interior portal arches are about 2.4–2.6 m** (nave-reverse_night_clear: arch x300–470, y350–660 against the trainer at x900–1020, y540–800, nearer to camera). The 3 m badger sitting in the same nave could not pass through any of them. For gateways to whole regions they are far too small. They read as closet doors.
- **The shrine lecterns are about 1.2 m.** They fit the trainer, but against the room height (~6 m to the beam) the room is a large empty volume with knee-high furniture.

## Specific checks

**Destination: WEAK by day, WEAK leaning YES by night.**
- *Day (farm-door_day_clear):* the hall is correctly centred at the vanishing point (x855–1030, y210–395), and the road leads to it. But it is small (about 9% of frame width), the same plaster, timber and roof as the houses, the same value and saturation, and no taller than the nearest roofs. Its spire barely clears the mountains. Nothing marks it as civic: no flag, banner, clock, colour accent or lit door. The "Sout…" label and quest card also pull the eye right.
- *Night (farm-door_night_clear):* the facade is the only warmly washed surface (x890–1025, y300–395), so it pops. This works better than day, but it reads as floodlit from nowhere. Its windows stay dark, and the street between has no lamp chain leading to it.

**Front door at night (hall-approach_night_clear): PARTIAL.** The doorway (x935–978, y380–450) is a bright warm rectangle with a warm spill on the threshold (x860–1060, y445–470). It is the brightest thing in the frame, so yes, it reads as "lit".
- The two wall lanterns flanking it (x885–895 and x1015–1025, y315–355) are tiny, non-emissive and cast nothing. The facade wash has no visible source.
- The door is cottage-sized. The upper and left-wing windows are black voids.
- It reads as a lit hole in a dark wall, not an inviting entrance. Steps, a large double door with a lit interior beyond, and lit lanterns pooling on paving are absent.

**Interior at night: NO.**
- In nave-reverse_night_clear and nave-arches-left_night_clear the nave is lit by a cool, even ambient. The hanging iron lanterns have no glow and no pools. The window row shows a bright blue sky, and the roof tiles/sky leak at the top edge.
- The shrine (shrine-pedestals_night_clear) has one lantern pool on the end wall. Otherwise the plaster is near day-bright, and the windows show sunlit hillside.
- Neither room reads as enclosed or lit by warm practical lights.

## Ranked: what most separates these frames from the references
1. **Ground and foliage density, and the empty foreground.** Palworld-02 and -05 fill the bottom third with layered grass clumps, rocks, path-edge breakup and props, and use value variation to lead the eye. In hall-approach_day_clear and farm-door_day_clear, 40–50% of the frame (y600–1080) is a single flat ochre dirt plane with sparse identical grass clumps on the verges. The keyart's settlement surrounds its buildings with fences, a well, oaks, flowers and a banner. These frames place houses on bare lawn beside a bare road.
2. **Interior authorship (nave-arches-right_golden_clear, nave-reverse_night_clear).** The references never show a placeholder. Palworld-05's base has distinct props, each with silhouette, emissive accents (fire bowls, a glowing monitor) and colour. The nave has flat colour cards for portals, floating debug labels, identical lecterns, roof tiles through the ceiling and no light source that does anything. This is the single largest "this is a prototype" signal in the set.
3. **Atmosphere and light motivation (farm-door_night_clear, hall-approach_night_clear).** The keyart's night panel has a glowing warm settlement against a deep blue field, with a campfire as a source and haze between planes. Palworld's daylight has aerial haze in the distance (palworld-04, -05 left side). These frames have no distance haze; the hall at 60 m is as crisp as the foreground. At night they have no visible warm source chain: no lit lanterns or windows pooling on the street. The trainer is also lit brighter than the world.

## Bars
**Bar A, does it belong to the keyart world? Exterior YES (day and golden only); interior NO.**
- *Carried:* half-timbered plaster cottages, warm ochre/green palette, blue mountains, a stylized-real creature with a strong face mask, a golden hour that matches the keyart's sunset panel.
- *Sank:* no oak trees inside the village, no fences, well or banner. The Crossing Hall is a stone box with no landmark presence, where the keyart's landmarks are visible from distance. The interiors and the cold-ambient nights match nothing in the keyart.

**Bar B, next to palworld, the same kind of game? YES, weakly, on exteriors only.**
- *Carried:* third-person over-the-shoulder trainer with a big companion beside them, a HUD of the right genre (minimap, quest card, quick bar, health/food), a saturated stylized-real look, and believable shadows on creatures.
- *Sank:* empty ground planes, sparse foliage, no props, a too-heavy opaque right-side HUD, and invisible rain. On the interior frames a viewer would say "greybox build of a different game." nave-forward (camera inside the creature) would look like a bug report.

## Gaps split

### (a) Fixable with assets already visible in these frames
1. **Reframe the nave-forward camera** so the companion is offset left or right. Alternatively, spawn the companion beside or behind the trainer indoors. The trainer and the end wall must be visible.
2. **Move the quest beacon beam** off the companion: offset it, or hide it while it intersects a creature (street-mid-left_*).
3. **Turn on the lanterns.** The hanging iron lanterns already in the nave and shrine, and the two facade lanterns, need warm emissive bulbs plus omni lights with visible pools on wall and floor. Drop the interior ambient at night by about 60–70% so the lanterns carry the room. Use the one working shrine end-wall lantern as the target.
4. **Make interior windows match the time of day.** Dark-blue or black window cards at night, or mask the sky/hillside so night windows are darker than the walls.
5. **Close the ceiling.** Hide exterior roof tiles and ridge caps from interior cameras, fill the gap between roof and walls, and remove or fix the detached upper wall over the nave (nave-arches-right_golden_clear, top left).
6. **Light the windows at night.** Give all village house windows and the hall's upper and left-wing windows a warm emissive at night, so the black voids on the hall facade become glowing windows. Line the main street with the wall lanterns already used on the hall (one per house door), with warm light pools on the road at night. This builds a lamp chain toward the hall.
7. **Make the hall the destination by placement and light.** Raise or scale the hall's tower so it clears the near roofs. Hang the green/gold banner style from the keyart settlement (if present among installed props) or lanterns on the facade. Pave a forecourt with the same cobble used inside and add steps up to the door. Enlarge the door opening, or replace it with a double-door or arch unit from the interior set.
8. **Add distance haze/fog** so the hall and the mountains desaturate and lighten with distance. Keep the hall's warm night wash punching through the haze.
9. **Break up the road.** Add value variation, darker ruts and edge blending into grass, and scatter the rocks and grass clumps already present onto the verges and into the road margin. Add trees from the existing tree set between and behind houses, so the roofline is broken by canopy as in the keyart.
10. **Dress the street with existing props**: barrels, benches and fences already at the inn (street-mid-left_day_clear x100–240, y490–550, and x340–460, y485–510), repeated and varied at each house front, with fence runs along the verges.
11. **Scale the cobble texture down** about 2–3× inside, add a darker border band at the wall base as a skirting substitute, and break the repeat with a second cobble tint.
12. **Remove the flat black slabs** in the shrine doorways (shrine-pedestals-reverse_* x230–380, y400–650). Fix the "Home arch" card offset so no exterior shows beside it.
13. **Build the portals from what is there.** Scale every portal arch up to at least 4 m so the 3 m badger fits. Replace the flat colour cards with a darker recessed plane plus a soft emissive gradient tinted per biome, using a glow treatment like the existing cyan quest-beam material.
14. **Fix the world labels.** Set them to a single size, set them to depth-test-off but HUD-occluded, pull them above the lecterns so nothing clips the text, and give them a backing plate. Better, show them only within interaction range. Hide them when they fall behind a HUD rect.
15. **Lighten the HUD.** Make the quest card translucent and shorter, and move the "Day 1 · 08:00" clock off frame-centre top to sit with the minimap. Lift "Put Terrapup away" so it does not sit on the trainer's feet.
16. **Remove the trainer's separate fill light at night**, or match it to the scene, so the hair and backpack stop glowing in farm-door_night_clear.
17. **Make rain visible.** Add visible streak particles, a wet/specular boost on cobble and road, darker plaster, a lower sun/ambient, and puddles on the road. Fix night_rain so it is darker than night_clear, not brighter.
18. **Dress the shrine** with existing props: clustered barrels or crates, banners, more lanterns, and a central focal element (for example, the relic positions grouped on a raised cobble dais). Arrange the lecterns in an arc facing a focal wall rather than in an even scatter.

### (b) Needs new art not present in the frames
1. **A distinct Crossing Hall exterior silhouette**: a taller bell tower or clock tower, a civic double door, and a carved stone portico. The current facade is the cottage kit scaled up.
2. **Real portal arches**: stone-framed gateways with carved per-biome motifs and a vista or shader showing the destination biome.
3. **Shrine pedestals or plinths and relic display objects** to replace the reused lecterns.
4. **Interior trim kit**: skirting, ceiling planks or a coffered ceiling, columns, and a stone floor with a tile scale correct for interiors.
5. **Village life props** not seen in these frames: well, market stall, notice board, cart, washing line, signposts, flower boxes, and the keyart's banner pole.
6. **Heraldic banners and cloth** in the friendly green/gold for the hall interior and facade, so the civic building has an identity colour.
7. **Rain VFX and a wet-surface material set**, if none exists beyond what is shown here.
