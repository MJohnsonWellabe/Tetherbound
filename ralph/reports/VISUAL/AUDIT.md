# VIS lane — Phase 1 visual audit (ranked defects)

Standard: `docs/design/ART_DIRECTION.md` only, with the `visual-judge` rubric. References: `docs/reference/` key art, Palworld frames and chapter boards.
Judges: fresh **code-blind** subagents. Each saw only frames, ART_DIRECTION and references. None saw source, change narrative or budget.
Renderer: Compatibility/opengl3, 1280×720 (`xvfb-run`), the production path. Software GL: composition, scale and colour relationships are trustworthy. Fine lighting and performance are not.

## How to reproduce

`tools/capture_visual_audit.gd` (one tool, four sections):

```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/capture_visual_audit.gd -- --section=roster
... -- --section=cast
... -- --section=region --region=<meadows|cloudreach|stormwood|tidewake> --kind=<env|places>
```

Or dispatch `render.yml` from `main` with `checkout_ref` set to a **branch name or full SHA**. A short SHA fails checkout.

- Every frame writes one `manifest.jsonl` line: subject, view, measured height, stand, camera, target distance, clip and stand provenance.
- Frame paths below are relative to `shots/visual_audit/<section>/…` in a run's output.
- Committed evidence is limited to the `_sheet_*.jpg` contact sheets in this folder.

**Capture fixture, disclosed:**
- **Roster and cast:** calibrated neutral stage, taken from `_capture_creature_roster.gd`. The floor renders at its own albedo and a rim light keeps dark bodies judgeable. The real 1.80 m trainer stands beside every subject. Attack frames hold the resolved `attack` clip at 45 % of its length (between wind-up and contact). All 57 species resolve an `attack` clip.
- **Regions:** production chapter scene, WorldLook clock pinned to 10:00 / 18:30 / 23:00, and the production CameraRig at its resting pitch.
  - Stormwood has no day/night (owner ruling), so its three times are the Calm, Building and Break Surge phases instead.
  - The EncounterDirector is paused after the companion is summoned, so no fight takes the camera.
  - Any NPC greeting is closed. If the camera is still off the trainer after that, the frame is SKIPPED, not shot.
  - Environment rows use the hand-checked `debug_teleport_spots.json` stands.
  - Place rows use each landmark in the realm data, seen from the road point about 90 m away that has a clear sightline over drawn terrain.

## Severity and owner key

- **BLOCKER:** breaks the ART_DIRECTION contract outright, or an asset is visibly broken.
- **MAJOR:** fails a named clause at gameplay distance.
- **MINOR:** polish.

| Owner | Scope |
|---|---|
| **ART-X04** | Art lane: creature and hero mesh, texture and animation, NPC body and face texture, uniforms. The only lane holding the Meshy licence. |
| **VIS** | This lane: environment, sky, fog and lighting, terrain and water shaders, shared vegetation and prop materials, the one nature/village/prop family, and the capture tool. |
| **MEADOWS**, **CLOUDREACH**, **STORMWOOD**, **TIDEWAKE** | Chapter lanes: band content (spawns, props, roads JSON, chapter scenes). |
| **COORD** | Ownership unclear or shared file. The coordinator decides. |

## A. Creatures (57 species, stage)

Sheets: `_sheet_roster_front.jpg`, `_sheet_roster_lineups.jpg`, `_sheet_roster_attack_worst.jpg`.

**Scale passes.** Every species renders taller than the trainer. The smallest are Pipwing 1.06×, Sparkit 1.08×, Mudsnout 1.11× and Bramblebun 1.14×. No data/height mismatch over 25 %.

| # | Sev | Subject | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| C1 | BLOCKER | Meadowhart | roster/022_meadowhart_front, 023_…_rear, 024_…_attack | Broken mesh. The front legs are loose stumps with an air gap under the chest, and the torso is an untextured smooth "pill". In the attack clip the rig tears: forelegs missing, a hoof fragment loose on the floor. | §5.1 silhouette/topology; §0 "texture cannot repair topology" | ART-X04 |
| C2 | MAJOR | Fulgocobra, Solmane, Sirenseal, Stormraven, Pebbik, Voltarach | roster/123_fulgocobra_attack, 171_solmane_attack, 099_sirenseal_attack, 126_stormraven_attack, 129_pebbik_attack, 120_voltarach_attack | At 45 % of the attack clip the body collapses into or through the floor: the cobra reads as two pieces, Solmane's head is gone, Sirenseal has a mane/torso gap, and Voltarach's leg pieces lie on the ground. **PLAUSIBLE, needs an in-world check.** The stage seats bodies by idle render bounds, so part of this may be root-offset. The deformation itself (gaps, detached pieces) is asset-side. | §5.1 no interpenetration or floor clipping in combat poses | ART-X04 |
| C3 | MAJOR | 14 quadrupeds: burrowback, nightburrow, tuskroot, ashtusk, riptusk, mirejaw, staticub, mosshock, stormbrush, craghorn, stormcapra, tanglevolt, thundertunnel, veridian | e.g. roster/027_tuskroot_attack, 084_mirejaw_attack | The shared head-down "charge" attack drives the face and forelegs through the ground plane, so the face disappears. Same PLAUSIBLE caveat as C2. | §5.1 | ART-X04 |
| C4 | MAJOR | Tuskroot vs Ashtusk; Paddlenewt vs Riftfrill; Burrowback, Nightburrow, Stormbrush; Craghorn vs Stormcapra | roster/025/061, 028/058, 019/052/133, 130/145 _front | Recoloured duplicate meshes: identical measured sizes (3.60×6.12 m; 2.15×2.18 m) and silhouettes. | §5.1 silhouette distinguishable at gameplay camera | ART-X04 |
| C5 | MAJOR | Breezetail, Solmane, Cliffspike, Tempestwing, Veridian, Galewisp, Voltarach | roster/157, 169, 163, 166, 049, 007, 118 _front | Albedos look generated: melted blotches, polka-dot noise, dripping paint. They sit beside the clean hand-painted Terrapup, Pipwing and Frostclaw, so the roster reads as two production families. | §1 one coherent family, not a pack collage; §5.1 designed colour blocks | ART-X04 |
| C6 | MAJOR | Tempestwing | roster/166_tempestwing_front | Propped on one vertical pole with no legs on the ground; no readable eye region. | §5.1 ground contact, face | ART-X04 |
| C7 | MAJOR | Voltarach | roster/118_voltarach_front | The face is a glossy blob buried between leg segments, with no eye or mouth read. | §5.1 readable face/eyes | ART-X04 |
| C8 | MAJOR | Nightburrow, Ashtusk, Shadelet, Stormraven, Thundertunnel | roster/052, 061, 070, 124, 139 _front | Near-black bodies whose value shapes collapse, so they will vanish at dusk or in forest. Burrowback is the only named low-contrast exception. | §5.1 1.5:1 habitat separation | ART-X04 |
| C9 | MINOR | 11 species with WEAK attack read (ripplet, brooktail, pipwing, reedwing, mosshell, cannonback, torrentoad, cragclaw, abyssal_guardian, glimmermoth, cliffspike) and galewisp NONE | roster/*_attack | The attack pose barely differs from idle. | §5.1 combat poses express the action | ART-X04 |
| C10 | MINOR | Ashtusk, Nightburrow | roster/061, 052 _front | Ambient particle orbs float through the face. | §5.1 mesh-bound VFX | ART-X04 |
| C11 | MINOR | Aeriex, Ribbonray | roster/151, 154 _front | The eyes read as flat black holes. | §5.1 | ART-X04 |
| C12 | MINOR | Pipwing, Sparkit, Mudsnout, Bramblebun | roster/043, 064 _front | They pass at 1.06–1.14×, but the "creatures dwarf the trainer" read is weakest here. If raised, grow them; never shrink others. | §1 relative scale | ART-X04 |

Do not touch: the trainer, Terrapup, Pipwing, Frostclaw, Cloudfang, Torrentoad, Sirenseal (idle mesh/texture), Fulgocobra (idle), and Burrowback's dark armour (a named exception).

## B. Humans, Team Tether and the Warden (34 art.json bodies, 4 ranks, 3 named captains)

Sheets: `_sheet_cast_front.jpg`, `_sheet_cast_faces.jpg`.

| # | Sev | Subject | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| H1 | BLOCKER | rank_grunt / rank_officer / rank_captain | cast/*rank_grunt_front, *rank_officer_front, *rank_captain_front, lineup_04 | One masked plum body and cap, told apart only by a small chest disc. Rank cannot be read without a nameplate. | §5.2 rank reads grunt/officer/captain/Warden | ART-X04 |
| H2 | MAJOR | Team Tether (all), Warden | cast/*warden_front, *warden_face; grunt/officer fronts | Oxblood is nearly absent from the faction: black and plum with magenta chevrons, and the Warden is bottle-green and gold. The only oxblood is rank_captain's chest disc. | §5.2 and CLAUDE hard rule: oxblood reserved **for** Tether; §3.2 disciplined oxblood accents | ART-X04 (palette in art.json is shared: COORD confirms the owner) |
| H3 | MAJOR | Rival trainer, Courier, Lyra | cast/*rival_trainer_front, *courier_front, *lyra_front | Civilians carry saturated red-orange blocks larger than any Tether red. | §5.2 red reserved to Tether | ART-X04 |
| H4 | MAJOR | Captain A / Captain Field (same model); Sera; Local Historian | cast/*captain_a_face, *captain_field_face, *sera_face, *local_historian_face | White hair merges into blown-white skin; the eyepatch and mouth blur out. | §5.2 hair is a mask; distinct faces | ART-X04 |
| H5 | MAJOR | 20 faces (Kael, Grunt A/C, Officer A/B, Captain B/Ridge/Riverwatch, Innkeeper, Trader, Farmer, Rival, Wandering Trainer, Lost Traveler, Alpha Tracker, Former Tether Member, …) | cast/*_face | Low-resolution, posterized or blown skin with blurred eyes. Hair-mask misalignment smears hair texture onto cheeks (officer_a/b) and leaves skin patches inside the hair (lost_traveler, inn_helper). At stage distance the first judge rated Kael and the Innkeeper fine; the close-up judge rated them MAJOR. They pass at gameplay distance and fail in the dialogue close-up. | §5.2 | ART-X04 |
| H6 | MAJOR | Villager farmer/smith/ranger; keeper/quarryman | cast/lineup_01, *_face | Two bodies repeated with hair swaps. | §5.2 distinct hair/face/clothing | ART-X04 |
| H7 | MAJOR | Captain Ridge, Captain Riverwatch, Captain B | cast/*captain_ridge_front, *captain_riverwatch_front | Named captains share one face and coat and cannot be told apart. | §5.2 | ART-X04 |
| H8 | MAJOR | Grunt A/B/C vs rank_grunt | cast/*grunt_a/b/c_front, *rank_grunt_front | Two contradictory grunt uniforms; Grunt C reads as a child civilian. | §5.2, §3.2 | ART-X04 |
| H9 | MINOR | Captain Riverwatch | cast/*captain_riverwatch_rear | The hands render glowing orange. | §5.2 | ART-X04 |

Do not touch: the trainer (the scale ruler, with clean 3-block read), Grandpa, Kael and Sera bodies (faces per H4/H5), and the Innkeeper body.

## C. Regions

Stands, frame lists and manifests: `shots/visual_audit/region/<region>_<env|places>/`.
- **E### = environment frame:** the hand-checked teleport stand at day, dusk and night.
- **P### = place frame:** the landmark from its road approach.

### C1. Meadows: 30 env + 23 place frames; judge `Bar A yes, Bar B no`

The judge's place labels were lost to a manifest-copy error in my judge prep (not in the tool). The P-frame names still carry the place id.

| # | Sev | Domain | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| M1 | BLOCKER | landmark read | P003, P006–P011, P014, P015, P019, P020, P022, P023 | In 13 of 23 approach frames the named place is absent or unreadable ~90 m out: no gate, the bridge a 30 px sliver in a trench, no relay, no camp smoke or light, no quarry workings, tower or Hall. | §3.2 read at 400 m / 100 m; §3.1 lure per activity | MEADOWS (staging, lure dressing, sightlines). The quarry, tower and reach need visible landmark art: ART-X04 / MEADOWS. VIS re-checks the stands against authored approach stands. |
| M2 | BLOCKER | creature in world | P008, P009 | The Meadowhart herd on the relay approach shows the broken mesh from **C1**. | §5.1 | ART-X04 |
| M3 | BLOCKER | finale read | E025–E030, P004, P005 | Meadows Hall never dominates: a 10–15 px speck from 590 m, one narrow tower with a ramp, no palisade, drained ground, oxblood or night lights. The Hall stand is an interior box that looks the same at every hour. | §4 Meadows "Hall's occupation must dominate"; §3.2 | ART-X04 (exterior massing) + MEADOWS (drained ground, banners, braziers, sightline) |
| M4 | MAJOR | sky/fog/lighting | night E003, E006, E012, E018, E024, E027, P002, P007, P023; dusk E011, E026 | At night the far range glows brighter than the land and sky. **Measured: #6080b0 against a #263f6c sky.** Dusk flattens the range to beige. Night clouds read as soot smears. | §3.3; §2 depth from value separation | **VIS: fixed and verified.** `d5ef26fb` scales fog by sky energy; `5487d3f8` makes night clouds moonlit. After-render at 23:00: far range #6080b0 → #3f598c against the #263f6c sky, and clouds read as pale wisps, not soot (`_sheet_fix_before_after.jpg`, rows 2–3). Dusk range flatness is still open. |
| M5 | MAJOR | ground/paths | P001, P012, P018, P021, P022, E004, E016, E025 | One blotchy dirt material laid in round pads with a hard grass edge and white pebble dots. The route breaks into dashes, and there is no worn verge. | §3.1; §4 "broad roads, worn verges" | VIS (road/verge blend in the terrain shader) + MEADOWS (route splines, road width, edge scatter) |
| M6 | MAJOR | vegetation | E010, E012, E016, E022, E024, P012, P018, P021 | An even carpet of identical tufts and "lollipop" flowers over bare yellow-green paint. Flower beds read as purple plastic puddles. No shrub mid-layer. | §3.1 clusters and clearings, three layers | COORD (`grass_field.json` / `vegetation.json` are named shared files). VIS proposes the clustering and density falloff there. |
| M7 | MAJOR | faction colour | P001/P002, E004–E006, E010–E012, P015; pylons E025–E027, P022/P023 | Red on friendly elements: the village gate, the South Bridge banners, crimson-foliage trees. The Tether pylons are teal with no oxblood and no night glow. | §4, §3.2, §5.2 | VIS (the shared foliage tint recolours the crimson trees) · MEADOWS (gate and banner materials; South Bridge gate is a ledger exception, so recolour only) · ART-X04 (pylon oxblood trim and emissive) |
| M8 | MAJOR | props/object art | P014, P016, P018, P019, E019/E021; E007/E009; E009, P013 | Nature Kit meshes render cyan/white (a known ledger defect) and are scattered in the open. Boulder tops are bleached white. There is a floating `Label3D` sign and a flat black plane. | §6; §7 Nature Kit row | **Reclassified after investigation:** the cyan "crystal heaps" are the **Candy pickups** (`data/items/items.json:303-314` → `assets/props/candy_pickup/candy_pickup.glb`, tinted/emissive by `scripts/world/band_pickups.gd:224-226` `CANDY_LOOK`). That is a ledger-known mesh defect plus deliberate glow, so ART-X04 owns the remodel and VIS could warm the Great tint off blue. The bleached boulders are `stylized_nature/Rock_Medium_*` with near-white retints in `data/config/vegetation_presentation.json` (`variant_retint`), VIS. Signs are MEADOWS. |
| M9 | MAJOR | terrain material | P006/P007, P016, P004, E016, E013–E015 | Vertically stretched cliff projection on trench walls, pale untextured slabs, a voxel-looking wall texture, and stray yellow decal squares. | §3.1; rubric 7 | VIS. A slope-rock pass for `terrain_ground.gdshader` is parked **WIP** on `ralph/visual-wip-slope-rock`: it compiled and rendered with no errors but changed nothing at the South Bridge gully, whose walls are likely the gully mesh (`tools/_probe_south_bridge_gully.gd`), not terrain cells. MEADOWS owns the stray decals. |
| M10 | MAJOR | staging | E004, P018, P022/P023, E007, E019, P017, E013–E015 | The companion's paws float above a slope. Pairs share pose and facing, and the griffin wings interpenetrate. The trainer is pressed into creatures, and an NPC's head sits between the camera and the trainer. | §5.1 | MEADOWS (spawn staging) · VIS (companion placement in the capture) |
| M11 | MAJOR | composition | E001–E003, P008/P009, E022, P020, P021 | A dead sapling sits dead-centre at 3 m, near trees block 35 % of the frame, and some stands have no mid subject. | §1 | MEADOWS |
| M12 | MAJOR | hero tree | E019–E021, P017 | The Ironwood canopy is flat-shaded paper facets, a different family from the other trees, and a black cut-out at night. | §1; §7 Ironwood row | ART-X04 |
| M13 | MINOR | water | P012, E016, P016 | Flat pale water with a hard edge. The Pond, meant as the lush reference, is the least dressed water. | §4; §3.1 | MEADOWS (shore dressing) · VIS (shore band in the water shader) |
| M14 | MINOR | dusk | E002, E011, E026 | Dusk is a colour shift over day, with no raking warm light or long shadows. | §3.3 | VIS |
| M15 | MINOR | foliage artefact | E010, E011 | Alpha-cut crowns shimmer as dithered noise at dusk. | rubric 7 | VIS |

Strengths to keep: the village at P001 and the mill at E016, the badger companion, trainer legibility at night, painted day skies and night mood, the forest interiors, the pylon line as the spine to the finale, and the Warrens mound.

### C2. Cloudreach: 19 place frames judged (env pending); judge `Bar A no, Bar B no`

- **Capture:** render.yml 36268641645 at main `32bd3307`, frames P001–P019.
- **Evidence:** sheet `_sheet_cloudreach_places.jpg`, verdict `judges/cloudreach_places_VERDICT.md`, frame labels `judges/cloudreach_places_LABELS.txt`.
- **Skipped:** the Broken Skyroad Arch and High Roost Perches stands are unreachable (§D).
- **Env rows:** the 36 env frames are still rendering; their verdict joins this section when judged.
- **Owners:** all art and visual changes go to the Codex queue (V9 high perch, V10 settlements and cliff identity, or a new V row). Route, stand and road-shape content goes to the Cloudreach lane.

**Judge-prep correction, disclosed.** The judge's defect 1 ("no companion or creature in any frame") is a **capture fixture, not a game defect**:
- Place rows deliberately park the companion behind the camera; the manifest records `"companion": "parked behind camera"`.
- The paused EncounterDirector streams no wilds at a teleported stand.
- My judge brief wrongly said a companion stands in frame. Env rows keep the companion out, and they are the creature-in-world check.

| # | Sev | Domain | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| CR1 | BLOCKER | altitude read | all; clearest in P004, P006, P012, P018 | Every stand is a flat grass tabletop. Past the edge there is white haze by day and a flat navy sea plane by night. No stacked or strata cliffs rise above the player, and there are no waterfalls, floating islands or cloud sea below. It reads as "Meadows on a table", not cliffs above the clouds. | §4 Cloudreach row; §1 distant mass | Codex (cloud-sea layer and horizon, scene-fixable) · ART/Codex (strata cliffs, falls and islands need new art) |
| CR2 | BLOCKER | landmark | P010, P011 | The Sky Shrine approach shows only a giant blank grey pillar: noise-marble material, a black slab floating on its face, and a tree stuck to its wall. The shrine on top is out of sight. Partly a stand limit: an off-road ring stand at the pillar's foot. | §3.2; §6 | Cloudreach (authored approach stand) · Codex (pillar material, slab and tree) |
| CR3 | MAJOR | terrain material | P014/P015, P018/P019; plateau edges in P001, P012 | Grass texture runs down sheer faces, with grey triangular rock wedges pasted onto a flat olive wall. Same root as Meadows M9 and queue V16: the terrain shader has no steep-face treatment. | §4 "grass does not go on sheer faces"; §3.1 | Codex (V16 terrain shader) |
| CR4 | MAJOR | cliff art | P003 | Waycamp cliffs are vertically smeared grey texture, or soft blobby stacks with mushroom ledges. They read as sculpt blockout. | §4 pale weathered strata | ART/Codex |
| CR5 | MAJOR | ground and vegetation | P003, P008, P012, P013 (bare); P004/P005, P014, P018/P019 (strips); P010/P011 (carpet) | 40–50 % of the frame is one tiled green. Grass sits in straight strips parallel to ruler-straight roads, or as a uniform carpet, with no drifts or clearings. The road edge is a pixel-stair dither mask. | §3.1 | Codex (scatter clustering, road-edge blend) · Cloudreach (road curvature) |
| CR6 | MAJOR | stray geometry | P002 (pale plane), P014/P015 (triangle), P008/P009 (two dark wedge planes, hard road-end rectangle), P001/P002/P005/P006/P007/P013 (pale faceted blocks glowing at night) | Unshaded or unlit planes and blocks read as broken geometry. | rubric 7; §6 | Codex (identify; likely cloud or snow cards) |
| CR7 | MAJOR | night | all night frames | Night is the day scene tinted navy. No practical lights at Cliffhold windows, the beacon, the shrine, the aviary interior or the bells. Grass blades glow brighter than the ground. | §3.3; §3.1 lure | Codex |
| CR8 | MAJOR | landmark read | P006/P007 beacon; P008/P009 aerie; P003 waycamp; P012/P013 Cliffhold; P004/P005 bells; P018/P019 overlook | The beacon is a thin 40 px frame, unlit even at 23:00. The Aerie tower is cropped off the top of frame and screened by five trees. The Waycamp shows no camp. Cliffhold is four Meadows cottages on a lawn. Three Bells shows no bridge. The Overlook has no platform or vista. Only Summit Eyrie reads, weakly. | §3.2; §4 height-aware settlements | Codex (V10 settlements; beacon fire) · Cloudreach (stand framing) |
| CR9 | MAJOR | stronghold | P016/P017 | The Summit Eyrie glass dome matches the board. The base is a dark mossy block wall on flat grass with brown ribs where the board has gold, and the night dome is cold with no warm interior. | §4; Bar A board | Codex/ART |
| CR10 | MAJOR | depth | P004, P006, P012, P018 (day) | The horizon dissolves into a white-grey band at 35–45 % of frame height, the "white washout" §4 warns against. | §4; §2 | Codex (sky/fog; the Cloudreach cliff palette is a judge pick per owner ruling) |
| CR11 | MINOR | composition | all | Every approach is identical: straight road, centred trainer, empty lower half, no near framing rail, no side lure. | §1 | Cloudreach |
| CR12 | MINOR | foliage | P001, P003, P006, P008, P014, P018 | Blocky, pixel-quantised leaf texture. One species standing singly on bare grass. | §3.1 | Codex |

**Strengths to keep:** the painted day sky and moonlit night sky, the trainer's legibility, the aviary dome silhouette, the Three Bells gantry icon, and the blue/gold banner language.

**Place reads from the approach:** only Summit Eyrie reads, weakly. Realm Gate, Three Bells, Cliffhold and the Observatory partly read. The Waycamp, Beacon, Aerie, Sky Shrine and Stormward Overlook do not.

### C3–C4. Stormwood, Tidewake: rendering

- **Tidewake places** is re-rendering on render.yml from a full checkout.
- The earlier `_sheet_tidewake_places_unjudged.jpg` came from a container missing 533 skip-worktree asset files, `rock_scree_Color.png` among them. Its "pale untextured rock" may be that artefact rather than the `#c6c3b8` tint, so queue row V18 is marked verify-first.
- **Stormwood** places and env follow.

## D. Capture-tool limits (VIS, not asset defects)

- **Roster attack frames:** seated by idle bounds on a flat stage. Treat C2/C3 as PLAUSIBLE until an in-world combat capture confirms them.
- **Place stands:** a place with no clear road sightline falls back to an off-road ring stand, and the manifest says which was used.
  - Meadows **Old Mill Crossing** has no dry sightline stand; the trainer ended up in the river, so the row was SKIPPED.
  - Stormwood **Glass Sink** has no reachable stand; the game returns the trainer to spawn.
  - **Meadowhart Grazing Ground** has no fixed position.
  - Cloudreach **Broken Skyroad Arch** and **High Roost Perches** have no reachable stand: the trainer settled 700+ m away.
  - Cloudreach **Sky Shrine** fell back to an off-road ring stand at the foot of its pillar, where the shrine top is out of sight.
- **Place rows park the companion behind the camera, and the EncounterDirector is paused.** A place frame cannot show creatures in the world. Env rows carry the companion.
- **Local renders need a complete checkout.** Clear skip-worktree first: `git ls-files -v | grep '^S'`.
  - Each is a coverage gap to close with an authored stand, not a pass.
