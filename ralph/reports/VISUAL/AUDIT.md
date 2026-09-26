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

_Pending: region frames (Meadows done; Cloudreach, Stormwood and Tidewake rendering) go to a fresh code-blind judge. This section is replaced by that ranked table._

## D. Capture-tool limits (VIS, not asset defects)

- **Roster attack frames:** seated by idle bounds on a flat stage. Treat C2/C3 as PLAUSIBLE until an in-world combat capture confirms them.
- **Place stands:** a place with no clear road sightline falls back to an off-road ring stand, and the manifest says which was used.
  - Meadows **Old Mill Crossing** has no dry sightline stand; the trainer ended up in the river, so the row was SKIPPED.
  - Stormwood **Glass Sink** has no reachable stand; the game returns the trainer to spawn.
  - **Meadowhart Grazing Ground** has no fixed position.
  - Each is a coverage gap to close with an authored stand, not a pass.
