# Low preset visual verdict (86 frames)

I worked only from the images in this folder. I opened 22 full frames. I judged the rest from the contact sheets.

## Rendering breakage (by defect)

### 1. Camera inside or against geometry, frame unreadable (breaks the frame)
- `cloudreach__broken_causeways__04__broken_skyroad_arch__day`: the whole frame is a close-up of a rock or terrain texture. Only a sliver of sky shows in the top-left corner. The trainer is not visible.
- `water__veilfall__16__veilfall_mountain_crown__day`: the camera sits between two huge salmon-pink rock meshes. About 75% of the frame is out-of-focus pink rock, and the trainer is cut off behind it. The rock reads as untextured, placeholder-pink geometry (see defect 5).
- `meadows__band4_upper_meadows_ironwood__08__the_ridgeline_watch__day`: a near-black tree trunk fills the centre third of the frame. The trainer's head and shoulders are pressed against it, filling the lower centre.
- `stormwood__hollow_crown__07__the_crown_arch__day`: the camera points almost straight down onto dark grass. There is no sky and no horizon, and the frame is nearly black even though the clock reads 08:00. The trainer, seen from above, is in an arms-up pose (falling or spawning?). Location identity is zero.

### 2. Hard horizon or grey void band between the world and the sky (clearly visible)
A flat, uniform grey band sits between where the water or terrain ends and where the sky begins. It reads as the edge of the world or fog plane, not as atmosphere.
- Water region, most open-sea views: `water__drowned_garden__21__drowned_garden_terraces__day` (clearest: a grey strip across the full width at y≈375–450), `water__tidal_cradle__10__tidal_cradle_saddle_camp__day`, `water__deep_watch__23__deep_watch_lookout__day`, `water__deep_watch__24__deep_watch_beach__day`, `water__brine_steps__05__the_tidal_stairstones__day`, `water__first_shore__02__first_shore_horizon_stones__day`, `water__gull_rest__19__gull_rest_signal_spire__day`, `water__salt_crown__12__salt_crown_return_bell__day`, `water__sluice_isle__14__sluice_channel_bridge__day`.
- Cloudreach, the sea of haze below the sky islands: `cloudreach__windscar_ravine__06__windscar_flight_aerie__day` and `cloudreach__broken_causeways__03__three_bells_bridge__day` (left half). Here a flat grey-white gradient replaces any distant land or cloud layer. It is less objectionable than in Water because the islands could plausibly float, but it still reads as a void.

### 3. Flat white planes at the island edge (clearly visible)
- `cloudreach__gate_lower_cliffs__01__realm_gate_crag__day`: hard-edged, pure white flat shapes at the left (y≈460–600) and right (y≈480) frame edges below the horizon. They look like an untextured cloud-floor or snow plane with no shading. The same white slabs appear at the left of `cloudreach__route_00__day` and in pale blue at `cloudreach__route_00__night`.

### 4. Mirrored world-space text (clearly visible)
- `cloudreach__high_roost_sky_shrine__08__the_high_perches__day`: a 3D label "Aster Windward — Lv 40 Master. Hold your footing. Follow the ... path →" renders left-to-right mirrored above the trainer. It is viewed from behind and not billboarded.
- `meadows__route_03__day` and `meadows__route_03__night`: a sign label at the left wall reads mirrored ("boowm..."). The "The Stormwood / Locked" labels at the right clip into the wall behind the HUD.

### 5. Untextured or flat-colour placeholder shapes (clearly visible)
- `cloudreach__high_roost_sky_shrine__08__the_high_perches__day`: a plain white untextured pillar or post passes straight through the trainer's body. The blue ring with four spokes and the blue banner are flat unlit saturated blue with no material. The yellow ring behind is also flat.
- `cloudreach__route_02__day` (also visible at `cloudreach__route_02__night`): a flat yellow cone or skirt shape sits under the trainer, clipping the legs from the knees down.
- `cloudreach__gate_lower_cliffs__01__realm_gate_crag__day`: a flat cyan square at the top-right of the arch (x≈1150–1210, y≈0–25).
- `water__veilfall__16__veilfall_mountain_crown__day`: salmon-pink rock with smeared low-res blotches, close to placeholder magenta-pink.
- `meadows__route_03__day` and `meadows__route_03__night`: the doorways are flat, unshaded navy rectangles with no door mesh.
- `cloudreach__broken_causeways__03__three_bells_bridge__day`: a soft, glowing pink-white blob at the left edge (x≈0–80, y≈700–780) with no readable source.
- `stormwood__hollow_crown__08__the_crown_heartstone__day`: a saturated magenta blob at the right edge on the horizon (x≈1900, y≈385). Minor.

### 6. Fog swallowing the scene (breaks the frame)
- `water__veilfall__15__the_veilfall_cascade__day`: a milky white wash covers about 70% of the frame. The waterfall, rock and sky are indistinguishable, and the trainer is ghosted. If this is meant to be waterfall mist, it is far too opaque and has no structure.

### 7. Time of day not rendered in Stormwood (clearly visible)
- `stormwood__route_00__day` vs `stormwood__route_00__night`, `stormwood__route_01__day` vs `stormwood__route_01__night`, and `stormwood__route_02__day` vs `stormwood__route_02__night` are pixel-for-pixel the same lighting. Only the clock differs: the same purple-dusk sky and the same sun-like shadows. Every Stormwood "day" frame at 08:00 also has the same violet dusk sky. A storm biome may justify an overcast day. It does not justify night being identical to morning.

### 8. Terrain geometry: extreme slopes, stretched spikes and shadow aliasing (clearly visible)
- `water__tidal_cradle__09__aquaryn_tidal_basin__day`: a narrow, near-vertical sand canyon with a sharp V-shaped notch and spike walls. It reads as a broken heightmap, not a landform.
- `water__tidal_cradle__10__tidal_cradle_saddle_camp__day`: the trainer stands on an unbroken slope of roughly 45° that fills the frame, tilted as if sliding.
- `water__deep_watch__23__deep_watch_lookout__day`: the same giant featureless dune walls. Along the left ridge, the shadow terminator is a stair-stepped sawtooth (shadow-map aliasing).
- `water__salt_crown__11__salt_crown_tide_shrine__day`: the frame is dominated by one massive smooth dune wall. The trainer's shadow is long and detached-looking.
- `cloudreach__upper_cloudreach__09__cliffhold__day` and `cloudreach__broken_causeways__03__three_bells_bridge__day`: the dirt and grass ground-blend patches have hard polygonal edges and visible sawtooth borders (bottom-right of cliffhold). They read as decal or vertex-paint seams, not paths.

### 9. Opaque smoke or particle columns (clearly visible)
- `meadows__band2_stone_and_root__04__the_burrow_warrens__day`: a solid, dark grey vertical ribbon runs from the sky to the hill and casts a shadow on the ground. It reads as a black pole or z-sorting error, not smoke.
- The same column appears in `water__lantern_cove__17__lantern_cove_drift_arch__day` and `water__tidal_cradle__10__tidal_cradle_saddle_camp__day` (top centre), and a brown version in `water__gull_rest__20__gull_rest_beach__day`.

### 10. Character and object clipping (minor to clearly visible)
- A glowing green pickup or plant renders inside the trainer's legs: `stormwood__dynamo__11__the_glass_field__day`, `stormwood__dynamo__12__the_stormheart_tree__day`, `stormwood__route_00__day`/`__night`, `stormwood__deepwood__09__lantern_hollow__day`.
- An NPC overlaps the trainer's feet: `stormwood__route_01__day`/`__night` (Rodkeeper Hesk under the trainer).
- A creature is clipped by the near plane, filling the lower third: `stormwood__conductor_run__06__the_capacitor_grove__day` (saturated flat-blue spider-like creature) and `water__tidal_cradle__09__aquaryn_tidal_basin__day` (Aquaryn).

### 11. Lighting mismatch on the trainer at night (clearly visible)
- `meadows__route_00__night`: the trainer's hair and backpack are lit warm orange, as if in daylight, against a blue night scene. The hair even changes from brown to ginger. The camera is also so close that the trainer covers about 30% of the frame (same in `meadows__route_00__day`).
- Smaller instance: in `meadows__route_02__night` the trainer is noticeably warmer than the scene.

### 12. Water surface artefacts (minor to clearly visible)
- Parallel white streak lines cross the water surface like a flow decal scrolling on the wrong axis: `water__drowned_garden__21__drowned_garden_terraces__day`, `water__deep_watch__23__deep_watch_lookout__day`, `water__brine_steps__05__the_tidal_stairstones__day`, `water__route_00__day`/`__night`.
- In `water__route_00__night`, the ocean is a uniform, very saturated electric blue that reads self-lit at 23:00. Streaky, blue-white plank shapes lie flat on the sand (left foreground) with no readable object.

### 13. Interior with open roof and light leaks (minor)
- `meadows__route_03__day`/`__night`: the "interior" has no ceiling (open trusses to the sky), a sign hangs in mid-air at the top centre, and bright sun patches on the floor have no matching openings.
- `meadows__band5_stronghold_approach__10__meadows_hall__day` is very dark for 08:00 inside a roofless courtyard, but it is readable.

### Not breakage, but noted
The trainer stands in a T/A-pose in nearly every frame. The HUD shows "7 / 100" health in most Water frames.

## Per-region notes

**Meadows.** The strongest region. The village day/night route (`meadows__route_00/01`) is coherent: warm windows at night, a good blue night grade, layered houses. The grove and quarry frames have density. Problems: two unreadable cameras (ridgeline_watch; route_00 too close), the opaque smoke ribbon at Burrow Warrens, and the courtyard interior on route_03, which is unfinished-looking (navy door planes, mirrored labels, no roof). The palette is too saturated yellow-green in the grandpa's village and south bridge frames compared with the key art.

**Water / Tidewake.** The weakest region and the most broken. About 20 frames are the same scene: pale sand dune, sparse grass cards, flat turquoise water, and a grey horizon band. The terrain is huge smooth heightmap slopes with no rock, debris or vegetation clusters. Veilfall is unreadable in both frames. Location identity is near zero: Salt Crown, Deep Watch, Sluice Isle, Gull Rest and Lantern Cove are interchangeable, apart from one prop each.

**Cloudreach.** It reads as "green hills with a few cliffs", not "cliffs above clouds". The ground is mostly flat grass shading with sparse grass cards. The haze below is a grey void, and white slabs appear at the edges. Some frames are okay: the waycamp (route_03 day/night) and the observatory dome. The High Perches frame is the most visibly broken non-camera frame (mirrored text, white pillar through the trainer, flat blue rings).

**Stormwood.** Its mood is distinct (violet sky, rain, glowing yellow rod-lines), and the forest silhouettes read. But day and night are identical, Crown Arch is a black top-down frame, and Stormheart Tree is a giant dark underside plane overhead. Pickup glow clips the trainer repeatedly. The yellow lightning-crack ground lines are the same everywhere and dominate every composition.

## Rubric

- **Silhouette and readability at small size.** Meadows village and Stormwood forests read at thumbnail size. Water and most Cloudreach frames do not: they collapse to a beige or green field with a tiny figure. Four frames are unreadable at any size.
- **Colour and value structure.** Water is high-key beige on cyan with almost no dark accents. Cloudreach is mid-green on blue with no value hierarchy. Stormwood is low-key and too uniform: purple sky, brown ground, black trunks. Meadows has the best value range. Too many frames have one dominant mid-value colour filling 60% or more of the frame.
- **Lighting and time-of-day read.** Meadows and Water nights read as night: blue grade and warm windows in Meadows. Cloudreach nights are passable. Stormwood has no day/night difference. The daytime light is flat, with little warm/cool contrast or sky-light bounce. Shadows are present but often aliased.
- **Horizon and depth.** This is the weakest axis. There is no aerial perspective layering and no distant mountains or forest lines (the key art has three to four depth planes). The grey horizon band in Water and Cloudreach flattens everything.
- **Scale agreement.** Houses, doors and bells read correctly against a 1.80 m trainer. Creatures are mostly as large as or larger than the trainer (the wolves in capacitor_grove, the Aquaryn, the blue lizard at brine_steps), which is correct. Grass cards in Cloudreach are knee-to-waist height and clumped, which reads fine. The dunes and cliffs read at an indeterminate, game-blockout scale.

## Bar questions A/B

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`? No, except partially for the Meadows village frames.**

The key art is stylized realism: layered depth, dense mixed oak canopy, distant mountains, painterly sky with volumetric cumulus, warm/cool light contrast, wildflower drifts, and a weathered stone stronghold. The frames match the building family and some vegetation. They lack the depth layering, the mountains and canopy mass, the light warmth and the material richness. Meadows Hall in-game is a dark box with flat maroon banners, versus the key art's mossy, towering ruin.

- **Fixable by scene:**
  - horizon and fog (replace the grey band with gradient fog that matches the sky, plus distant silhouette cards or mountains);
  - vegetation density and clustering;
  - a golden warm key light with a cooler sky fill;
  - a less saturated, yellower green palette;
  - camera framing and placement for the census points;
  - Stormwood night grade;
  - mirrored labels, smoke material and pickup clipping;
  - set dressing on Water beaches (rocks, driftwood, reed clumps) to break the dunes;
  - reshaping the Water dune heightmaps.
- **Needs new art:** distant terrain or mountain backdrops, a Meadows Hall exterior at key-art scale, Cloudreach cloud-sea and cliff kit (the islands need sheer rock faces, not grassy mounds), Water-specific landmark props per island, and Veilfall rock materials.

**B. Beside the Palworld references, would someone say these are trying to be the same kind of game? Yes, but clearly lower budget.**

The genre signals are there:
- third-person over-shoulder trainer;
- creatures larger than the human, with wolves, a dragon-fish and lizards in the field;
- a survival HUD (health, food, hotbar, build/satchel prompts);
- an open grassy overworld with paths;
- a stylized anime-ish humanoid.

Someone would place it in the same genre at a glance. The gaps:
- Palworld frames are full of action and creatures in motion, with dense grass to the horizon, atmospheric haze into distant cliffs, and rich PBR materials.
- These frames are mostly an empty landscape with one T-posed figure.

How the gaps split:
- **Fixable by scene:**
  - more creatures placed in view;
  - atmospheric depth fog;
  - grass density to the horizon (or impostor grass);
  - a trainer idle animation instead of the T-pose.
- **Needs new art:** a higher-detail terrain material set and backdrop geology at Palworld's level of richness.
