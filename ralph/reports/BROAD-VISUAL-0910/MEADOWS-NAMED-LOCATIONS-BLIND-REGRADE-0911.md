# Meadows named locations — blind regrade, 2026-09-11

Review anchor: `53a631b3ff97457f586b63b48af170ce800fac37`.
The newest Ironwood frames predate that anchor's crown-glade commit, so this
review does not award an unseen improvement for it.

## Scope and grading rule

The exact 23-place set is derived from the current player-facing data rather
than an older checklist: the 13 unique named regions in
`data/config/map_landmarks.json`; seven additional unique map landmarks
(Grandpa's House, The Village, Road Gate, Meadows Hall, The South Bridge,
Trail Camp, Abandoned Ranger Camp); and the three named player destinations
that are authored outside that map list (The Inn and Practice Meadow in
`terrain_playground.json`, Stronghold Approach in
`debug_teleport_spots.json`). Duplicate landmark/region entries for The Tether
Relay and Old Mill Crossing are one place each.

This is an evidence-only review. Production code, capture tools, and frames
were not changed. `PASS` means the place is unmistakable and the available
whole-frame evidence has no material presentation blocker. `POLISH` means the
place is identifiable, but composition, obstruction, material finish, depth,
or night readability still visibly trails the accepted characters/creatures.
`FAIL` means the evidence cannot establish the named place or a major visible
defect defeats it. A good frame does not erase a bad arrival frame; a bad frame
does not erase an independently valid view of the place.

## Result

**3 PASS / 20 POLISH / 0 FAIL (23 total).** All 23 places now have at least one
valid recognizable view. That is a coverage milestone, not a commercial-art
finish: only 13% of the set is currently at PASS.

| # | Exact place | Grade | Evidence and visible disposition |
|---:|---|---|---|
| 1 | The Village | **PASS** | `shots/locations/01-village-standing-day.png`, `01-village-approach-day.png`: coherent square, well, paths, populated medieval frontage, and readable depth. |
| 2 | Grandpa's Village | **POLISH** | `shots/catalogue/meadows/named-locations-current-0910/meadows__band1_lower_meadows__01__grandpas_village__day.png` and `meadows__band1_lower_meadows__01__grandpas_village__night.png`: unmistakable settlement, but the day creature crowds the right side and the night mid-ground loses separation. |
| 3 | Grandpa's House | **POLISH** | `shots/locations/01-village-grandpa-yard-day.png` / `-night.png`: house and fenced yard read, but the oversized purple ground clump is the foreground focal point and the yard has little domestic story. |
| 4 | Road Gate | **POLISH** | `shots/locations/01-village-route-out-day.png` / `-night.png`: route and closed leaf are clear, but it reads as an ordinary fence panel rather than a memorable village threshold. |
| 5 | Practice Meadow | **POLISH** | `shots/locations/01-village-tournament-day.png` / `-night.png`: practice/tournament clearing is legible, but the paired near-identical stone arches read duplicated and the meadow lacks a strong training-ground hierarchy. |
| 6 | The Inn | **POLISH** | `ralph/reports/FOUR-BIOME-CONTINUATION-0910/INN-IDENTITY/01-inn-exterior-front-day.png`, `02-inn-exterior-corner-day.png`, `04-inn-interior-bar-day.png`: public porch, signs, seating, barrels, and frontage solve identity; the interior remains broad, pale, and sparse, and the night exterior is heavily red. |
| 7 | The Pond | **POLISH** | `shots/locations/02-mill-pond-approach-day.png`, `-standing-day.png`, `-wheel-day.png`: water, tower mill, outbuilding, and wheel now make a real destination; the approach is still heavily leaf-obstructed and the wheel is visibly crude against the building. |
| 8 | The South Bridge | **PASS** | `shots/catalogue/meadows/named-locations-current-0910/meadows__band1_lower_meadows__02__the_south_bridge__day.png` / `meadows__band1_lower_meadows__02__the_south_bridge__night.png`: occupied gate, bridge threshold, banners, guard, ravine, and road form a clear chapter gate at both times. |
| 9 | The Old Quarry | **POLISH** | `shots/locations/03-quarry-standing-day.png`, `03-quarry-conduit-head-day.png`: worked floor, foundations, conduit, stone, dead growth, and supplies give strong identity; `03-quarry-approach-day.png` is still a full-frame canopy obstruction. |
| 10 | The Burrow Warrens | **POLISH** | `shots/catalogue/meadows/arrival-sightline-0910/meadows__band2_stone_and_root__04__the_burrow_warrens__day.png` / `meadows__band2_stone_and_root__04__the_burrow_warrens__night.png`, plus `shots/locations/04-warrens-den-day.png`: excellent mound/mouth silhouette and readable threshold; the location standing frame clips into rock and the den view remains crowded by very large bodies. |
| 11 | Abandoned Ranger Camp | **POLISH** | `shots/locations/14-ranger-camp-standing-day.png` / `-night.png`: fire, bed, seating, route, and abandoned kit read; the approach day/night pair is substantially blocked by trunks and canopy. |
| 12 | The Stonewater Reach | **POLISH** | `ralph/reports/FOUR-BIOME-CONTINUATION-0910/STONEWATER-REACH-IDENTITY/02-region-approach-day.png`, `04-overlook-standing-day.png`, `05-springhead-day.png`, `07-springhead-night.png`: wreck/overlook/spring sequence now exists, but small water patches and simple boulder rows do not yet carry the broad named reach without the title card. |
| 13 | The Tether Relay | **POLISH** | `shots/locations/06-relay-road-day.png`, `06-relay-standing-day.png`, `06-relay-apparatus-day.png`: faction occupation and apparatus are unmistakable; black wall/slab masses, flat drained ground, and crude roof/support geometry still read prototype-grade. |
| 14 | The Long Water | **POLISH** | `shots/locations/19-long-water-approach-day.png`, `19-long-water-bank-day.png` / `-night.png`: the named river is finally proven, but the approach underframes it and the bank view reads as a straight engineered canal with repeated cliff texture and foreground trunks. |
| 15 | Old Mill Crossing | **POLISH** | `shots/catalogue/meadows/old-mill-identity-0910-accepted/meadows__band3_the_river_lock__06__old_mill_crossing__day.png` / `meadows__band3_the_river_lock__06__old_mill_crossing__night.png`: mill tower, wheel, water, road, and crossing produce a unique silhouette; a central tree masks the tower and night reduces the destination to dark silhouettes. |
| 16 | The Ironwood Grove | **POLISH** | `shots/locations/16-ironwood-grove-approach-day.png`, `16-ironwood-grove-standing-day.png` / `-night.png`: the age ladder and pale elder trunks are visible from inside; the approach remains an open generic meadow and the grove does not yet form a strong enclosing silhouette. |
| 17 | The Highfield | **POLISH** | `shots/locations/17-highfield-pasture-day.png`, `17-highfield-stock-camp-day.png` / night pair: fencing, stock, and working kit now exist, but the defining herd, gate, and camp are split across views and the pasture still reads broadly empty. |
| 18 | Trail Camp | **POLISH** | `shots/locations/13-trail-camp-standing-day.png` / `-night.png`: the revised raised view proves fire, seats, bed/tent kit, companions, and clearing; the ordinary approach is dominated by the creature group and the actual camp remains a small background cluster. |
| 19 | The Rise | **POLISH** | `shots/catalogue/meadows/the-rise-identity-0910-accepted/12-rise-approach-day.png`, `-standing-day.png` / night pair: the hill, rocky crown, route, sign, and tree masses finally read as a named landform; close framing is cluttered and night exposes pale rock/foliage value discontinuities. |
| 20 | The Ridgeline Watch | **POLISH** | `ralph/reports/FOUR-BIOME-CONTINUATION-0910/RIDGELINE-WATCH-IDENTITY/01-ordinary-approach-day.png`, `02-canonical-position-day.png`, `03-canonical-position-night.png`: signal mast, scaffold, banner, camp light, and hilltop silhouette are clear; the tower remains a simple repeated-brace box with little weathering or lived history. |
| 21 | The Broken Tower | **POLISH** | `shots/locations/18-broken-tower-approach-day.png`, `-standing-day.png` / night pair: route-facing crenellated ruin, fallen wall, and ward light establish identity; the massing is still one thin vertical slab plus one detached wall and is nearly black at night. |
| 22 | Stronghold Approach | **POLISH** | `shots/catalogue/meadows/arrival-sightline-0910/meadows__band5_stronghold_approach__09__stronghold_approach__day.png` / `meadows__band5_stronghold_approach__09__stronghold_approach__night.png`: corrected arrival shows road, machinery run, creatures, and distant Hall together; the approach remains a wide undifferentiated field and the Hall is a small, weak destination silhouette. |
| 23 | Meadows Hall | **PASS** | `shots/catalogue/meadows/named-locations-current-0910/meadows__band5_stronghold_approach__10__meadows_hall__day.png` / `meadows__band5_stronghold_approach__10__meadows_hall__night.png`, `shots/locations/10-stronghold-courtyard-day.png`: authored stone enclosure, banners, occupation, lighting, and scale make the finale location immediately legible. |

## Fastest remaining closures, ranked

1. **Remove the three dishonest arrival obstructions.** Reframe or clear the
   exact quarry canopy, ranger-camp trunk tunnel, and Warrens rock-clip views.
   These are the cheapest visible defects and currently make otherwise useful
   locations look broken.
2. **Finish the weak macro trio: Relay, Long Water, Stronghold Approach.** Give
   the Relay textured/stepped massing instead of black slabs; break the Long
   Water's straight canal rim with bank rhythm, reeds/stone shelves, and a
   deliberate overlook; create foreground/mid-ground occupation beats that
   lead the Stronghold road to the Hall silhouette. These are the broadest
   commercial-quality gaps, not missing labels.
3. **Unify night readability with local sources.** Old Mill, Broken Tower,
   Ironwood, Highfield, camps, and open-route destinations mostly become dark
   blue/black silhouettes. Use destination-specific lantern, fire, ward, or
   reflected-water fill rather than another unmeasured global exposure swing.
4. **Compose the working places into one hero read.** Put Highfield's herd,
   drove gate, and camp in one view; make Trail Camp's tent/fire the foreground
   subject rather than the creature cluster; make Stonewater's water course,
   stones, and wreck read as one connected sequence.
5. **Add structural depth to the new landmark silhouettes.** Ridgeline Watch
   needs a less box-regular platform/weathering story; Broken Tower needs more
   ruin volume at its base; The Rise needs a stronger readable crown/trail
   terminus. These are now recognizable, so one targeted art pass each has
   higher value than adding more locations.
6. **Finish the otherwise-close village destinations.** Reduce the Pond
   approach canopy and refine the wheel; give Grandpa's yard domestic dressing;
   distinguish the Practice Meadow's duplicated arches; fill the Inn interior
   and correct its red night cast.

## Whole-set bar answers

- **Art-direction bar:** **Yes, inconsistently.** The village, Pond, Warrens,
  South Bridge, and Hall share the intended colourful pastoral/fantasy world;
  the Relay slabs, canal-like Long Water, and sparse open approaches break that
  continuity.
- **Palworld/commercial scene bar:** **No.** The set is now broadly nameable,
  but repeated foliage, weak mid-ground hierarchy, crude structure massing,
  dark night destinations, and several obstructed arrivals remain visible
  beside the reference scenes.

Static frames cannot prove traversal, animation, performance, collision, or
whether the player naturally sees these compositions while moving.
