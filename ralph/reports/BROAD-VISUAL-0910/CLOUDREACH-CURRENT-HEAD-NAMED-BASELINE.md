# Cloudreach current-head named-location baseline — 2026-09-10

## Evidence identity

- Capture HEAD: `ff23b3364538d5ac4f51ff719acfa26f83fe4119`.
- Source: the 12 Settings/debug catalogue landmarks in
  `data/config/debug_teleport_spots.json`.
- Evidence root:
  `shots/catalogue/cloudreach/current-head-ff23b3364-0910/`.
- Manifest:
  `shots/catalogue/cloudreach/current-head-ff23b3364-0910/manifest.json`.
- Renderer: production Compatibility renderer, NVIDIA GeForce RTX 3050 6GB,
  1280x800, ordinary HUD and production CameraRig.
- Result: `CATALOGUE SURVEY OK: 24/24 frames`; `complete=true`, failures `[]`.
- One pre-existing runtime warning remains for the unsurfaced
  `cr_candy_broken_route_good_07` placement. It matches earlier Cloudreach
  surveys and did not fail the catalogue.

Every row below has an exact `__day.png` and `__night.png` pair under the
evidence root. Status is a pixel judgment of this catalogue view, not a claim
about traversal, progression, or every angle around the landmark.

## Twelve-location disposition

| # | Canonical location | Exact frame stem | Disposition | Current visible result |
|---:|---|---|---|---|
| 1 | Realm Gate Crag | `cloudreach__gate_lower_cliffs__01__realm_gate_crag` | Partial | Trainer and broad arrival vista are readable, but the gate itself is cropped into a large right-edge wall; the view sells the biome more than the named crag. |
| 2 | Galefoot Waycamp | `cloudreach__gate_lower_cliffs__02__galefoot_waycamp` | Keep / polish | Strongest inhabited frame: huts, bed, camp ring, paths and trainer read immediately. Two near-identical large creatures crowd the centre/right and compete with the HUD. |
| 3 | Three Bells Bridge | `cloudreach__broken_causeways__03__three_bells_bridge` | Keep / reframe | Bridge and onward route are clear, with useful depth to the distant summit. A huge plain pillar consumes the left third and no three-bell identity is apparent from this stand. |
| 4 | Broken Skyroad Arch | `cloudreach__broken_causeways__04__broken_skyroad_arch` | Reframe | Trainer is readable, but the camera stands between two primitive brown slabs; there is no readable broken-arch silhouette or route through it. |
| 5 | Windscar Beacon | `cloudreach__windscar_ravine__05__windscar_beacon` | Keep / art polish | The formerly wall-blocked pair is now a valid open view. A centred arch and distant cliff target read, but the beacon is a very plain rectangular timber arch with only a tiny top light. |
| 6 | Windscar Flight Aerie | `cloudreach__windscar_ravine__06__windscar_flight_aerie` | Restage | Trainer remains visible, but an oversized bird and the HUD occupy most of the right side while plain pillars bracket the frame. The aerie itself has no clear local silhouette or activity. |
| 7 | Sky Shrine | `cloudreach__high_roost_sky_shrine__07__sky_shrine` | **Invalid** | A near stone drum blocks the lower centre and the overhead ring clips the top. No trainer-scale read or useful shrine overview survives in day or night. |
| 8 | The High Perches | `cloudreach__high_roost_sky_shrine__08__the_high_perches` | Weak / art pass | Trainer is visible, but the destination is mostly three enormous undecorated brown cylinders on empty grass. There is no convincing perch function, intermediate scale detail, or lived-in sky-site dressing. |
| 9 | Cliffhold | `cloudreach__upper_cloudreach__09__cliffhold` | Keep / scene polish | Settlement and uphill route are readable. Hard-edged overlapping dirt polygons, repeated hut forms, isolated shrubs and broad empty ground keep it visibly assembled. |
| 10 | Old Wind Observatory | `cloudreach__upper_cloudreach__10__old_wind_observatory` | Partial | The best altitude panorama, with a strong cliff bowl and route. The named observatory is absent from the composition, while flat overlapping white cloud discs and banded cliffs dominate it. |
| 11 | Summit Eyrie | `cloudreach__summit_final_stronghold__11__summit_eyrie` | Partial | A fortress threshold is present and trainer-readable, but the camera is under blocky walls on a flat dirt floor. A large pink primitive direction marker/sign is the strongest accent and reads unfinished. |
| 12 | Stormward Overlook | `cloudreach__summit_final_stronghold__12__stormward_overlook` | **Invalid** | The canonical name is now correct, but both frames show only a low-angle patterned floor, one plain pillar, sky and HUD. The trainer, overlook edge, Stormwood direction and destination hierarchy are absent. |

## Shared findings and fastest closure

1. **Fix the two invalid arrivals first:** move/orient Sky Shrine and Stormward
   Overlook to safe authored overview stands. This converts four unusable
   acceptance frames without deleting art.
2. **Reframe the landmark, not the prop:** Realm Gate Crag, Three Bells Bridge,
   Broken Skyroad Arch and Windscar Flight Aerie all need stands/headings that
   show a route or silhouette instead of a nearby pillar/creature.
3. **Replace the monumental primitive read:** High Perches, Broken Skyroad Arch,
   Beacon and Summit Eyrie rely heavily on plain brown cylinders/slabs or a
   conspicuous primitive marker. One coherent sky-civilization architectural
   dressing pass would advance several locations.
4. **Repair the shared Cloudreach night value structure:** all 12 night frames
   have an extremely bright grey-white sky and cloud layer against much darker
   local ground. The clock is correctly 23:00 and the retained trainer rim
   keeps the player readable, but the world does not read as a cohesive night.
5. **Clean shared ground composition:** Cliffhold's polygonal dirt patches and
   large bare lawns recur elsewhere; consolidate paths/clearings and cluster
   grass rather than scattering uniform blades across every surface.

This baseline supersedes the older `waterward_overlook` filename and the older
claim that Windscar Beacon is fully wall-obstructed. It does not supersede the
older commercial-quality verdict: Cloudreach is distinct and playable-looking,
but these current frames remain below the supplied shipping-art reference bar.
