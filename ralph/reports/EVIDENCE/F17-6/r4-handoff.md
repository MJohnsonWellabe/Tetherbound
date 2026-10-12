# F17#6 r4 handoff (co-op lane to landmarks-claude)

- **State:** `tb/ev-coop-chapters` at `65b923ffd`, r4 interiors work in progress. Latest r3 evidence: `r3/`. r4 frames were not sent; my code-blind judge failed items 1–3.
- **Measurement gate (scratch `measure.py`, 1280x720 frames from `tests/capture_f17_hall_interior.gd`):**
  - `nave_night` far-end region (480,100)-(820,320) mean ≥ 8, and no 160x140 tile under 8.
  - Sealed infill, night ≤ day: nave (0,300)-(120,520); shrine (140,320)-(320,560) and (960,330)-(1110,560).
  - Shrine plaster above the opening (380,110)-(900,210), night ≤ 0.6 × day.
  - Shrine back wall (390,270)-(890,350), night ≤ 0.6 × day.
- **r4 numbers (all gates clear):**
  - Far end 21.4.
  - Infill night 13.7 / 10.7 / 21.9 against day 22.9 / 19.2 / 24.5.
  - Plaster ratio 0.59; back wall ratio 0.51.
  - Nave mean: day 84, night 36.
- **Judge still FAILS:**
  1. No warm lantern pools at night.
  2. Sealed infill reads as flat cards.
  3. Plaques read as UI and are illegible; the Main Story panel hides the right-wall signs at the stock nave camera.
- **Key finding, light cap:**
  - The Hall shell is one batched mesh (`Village/crossing_hall_shell_*`).
  - Compatibility caps lights per object (`project.godot` `limits/opengl/max_lights_per_object=16`). About 13 interior lanterns, the night fills and the frontage lights fall within range of that one object, so which lights reach it is arbitrary.
  - Adding night fill omni lights changed the far end by 0; lowering lantern energy moved some walls and not others.
  - Real pools need the shell split per bay or room, or baked or decal light pools; more lights won't do it.
- **What r4 changed (`scripts/world/crossing_hall.gd`, `data/config/crossing_hall.json`):**
  - Night albedo ×0.5 plus a faint emission floor (`interior_ambient.night_floor_*`) on the Hall's opaque materials.
  - Sealed infill: same floor (`sealed_night_floor_energy`), scaled to 0.94 inside its posts; the keystone patch removed.
  - Plaques: shaded, two lines (`sign_text`'s " · " becomes a newline), one line when the biome name equals the state.
  - Lanterns: 0.5 by day, 0.3 at night, 6.5 m reach at night.
  - Night glass dark. Shrine doorway posts and lintel. Ranger bench turned (`meadows_catalog_presentation.json`).
  - Region banners wait outside declared interiors (`autoload/game_state.gd`).
- **Tests:** `test_crossing_hall*`, `test_f19_order_consumers` and `test_village_redesign_topology` pass. `test_f19_order_consumers` pins `sign_text`'s exact format, so keep it.
