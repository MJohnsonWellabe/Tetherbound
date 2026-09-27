# VIS lane — Phase 1 visual audit (ranked defects)

Standard: `docs/design/ART_DIRECTION.md` only, with the `visual-judge` rubric. References: `docs/reference/` key art, Palworld frames and chapter boards.
Judges: fresh **code-blind** subagents. Each saw only frames, ART_DIRECTION and references. None saw source, change narrative or budget.
Renderer: Compatibility/opengl3, 1280×720 (`xvfb-run`), the production path. Software GL: composition, scale and colour relationships are trustworthy. Fine lighting and performance are not.


## Codex visual work queue (owner, 2026-09-26)

**All art and visual changes belong to the Codex lane for now.** Claude lanes do not edit art, materials, shaders, lighting, meshes or colour. They add each visual defect they find to this table instead. Codex takes items from the top, works on isolated branches, and leaves merging to the Claude coordinator, who lands the work in `tb/integration-N` batches once its before/after capture and code-blind judge verdict are recorded.

Codex marks an item "in progress" with its PR number when it starts. When the work lands, the row moves to "done" with the merge SHA. Owner exceptions: the Team Tether palette stays as built, so H2, H3 and the Tether/civilian red parts of M7 are closed. The Cloudreach cliff palette is picked by a code-blind judge against ART_DIRECTION.

**New rows (owner, 2026-09-27):** append at the bottom of the table with a lane-prefixed ID (`V-MC-n` Meadows core, `V-MA-n` Meadows activities, `V-MR-n` Meadows route, `V-CR-n` Cloudreach, `V-SW-n` Stormwood, `V-TW-n` Tidewake, `V-VIS-n` VIS, `V-X05-n` X05, `V-CX-n` Codex). Never renumber a row; existing V1–V35 keep their IDs.

| # | Criterion | Defect (source) | Where to start | Status |
|---|---|---|---|---|
| V1 | F13#5 | Tidewake dock lanterns and wet timber, then shore and landmark hierarchy (judge on `docks_after_v5`) | `scripts/world/water_dock_dressing.gd`, `data/config/water_dock_dressing.json` | Lantern slice #288 merged via integration-30; broader shore/material criterion open |
| V2 | F13#5 | Veilfall far/mid/near stands fail Bars A/B: waterfalls, mist, banding, shadows; crag, terrace and gate massing (judge r1) | `water_veilfall*.gd`, `water_veilfall_fall.gdshader:49`, `water_veilfall_rock.gd:110-144` | Cascade slice #322 available; full massing/landmark bars open |
| V3 | F13#5 | Currents read marginal; shader and framing | Tidewake current material and `capture_tidewake_matrix.gd` | #329 draft; water criterion fails, further local iteration parked for whole-game coverage |
| V4 | A-C1 | BLOCKER: Meadowhart creature mesh is broken | §A C1; `tools/art_pipeline/blender/` | #318 reopened; main 025a09d9d still has old body; candidate anatomy accepted, whole-frame B open |
| V5 | B-H1 | Tether rank bodies: shape and anatomy only, not palette | §B H1 | open |
| V6 | B | Faces and cast findings in §B, other than H2/H3 | §B | #331: emission repair on 22 bodies passes scoped source/image review; captain tint, source detail and geometry remain open |
| V7 | F04#6 | Defeat read is weak: raise DEFEAT_FOLD and re-run the defeated clips for the grunt, captain_a, captain_b and warden rigs | `tools/art_pipeline/blender/animate_humanoid.py` | open |
| V8 | M1/M3 | Meadows landmarks unrecognisable. Hall never dominates: exterior massing, drained ground, banners, braziers, sightline | §C1 M1/M3 | open |
| V9 | F08#3 | Cloudreach high perch: cloud sea and horizon, pale stone, pad primitives (arrival camera stays with the Cloudreach lane) | judge on #253 (5848745065) | open |
| V10 | F08#4 | Cloudreach settlements and cliff identity; the cliff palette is a judge pick | Cloudreach work orders M1–M12 | #338: scoped aviary architecture and trail-edge improvements accepted; cliff integration, full identity and night destination contrast remain open |
| V11 | F10#4 | Stormwood forest, rod line and restored-sky views need a Bars A/B verdict | Stormwood capture tools | open |
| V12 | F09#3 | Stormwood pocket lures not visible from the road: a light shaft over each pocket's reward, then re-judge (target ≥4 of 5) | `tools/capture_stormwood_pocket_walks.gd` | open |
| V13 | M7 foliage | Crimson canopies at the Burrow Warrens ironwood stand (evidence: `_sheet_meadows_env_32bd3307.jpg` (local capture at main 32bd3307), 'Warrens day'). These are harvest nodes on `TwistedTree_1`/`_3`: band 2 orders 17, 19 and 20, and band 3 (River Lock) orders 3027, 3029 and 3030. No vegetation layer lists those models, so `harvest_node.gd::_material_fixups_for_model()` never swaps the pack's crimson leaf (RGB 167,23,23). `vegetation_presentation.json` alone cannot reach them. | Re-author those orders onto `TwistedTree_4`, as band 4's `_comment_red_leak_d4b` did, or add a harvest-node fallback to per-model presentation retint/retexture in `scripts/world/harvest_node.gd` | open |
| V14 | M8 | Great candy reads as "cyan crystal heaps": its wrapper tint `Color(0.62, 0.76, 1.0)` renders cyan-white under 0.90 emission. The medallion and glow keep `items.json` `#3f6fd0`. | `scripts/world/band_pickups.gd:225`. Unjudged suggestion: wrapper tint `Color(0.70, 0.64, 1.0)` (periwinkle; the reference branch was deleted 2026-09-27). Before/after stand: Quarry env; a Great candy sits 26 m from the stand. | open |
| V15 | M4/M14 dusk | Golden-hour fog is **currently** 0.0016, about 3× day's 0.00055. Ranges 2 km out fog to one beige cut-out (evidence: `_sheet_meadows_env_32bd3307.jpg` (local capture at main 32bd3307), 'village 18:30'). **Lower** it. | `data/config/art.json` `times.golden.environment.fog_density`. Unjudged suggestion: 0.0008 (the reference branch was deleted 2026-09-27). Re-run `tests/test_world_look_fog_energy.gd`. | open |
| V16 | M9, CR3, TW1 | Stretched or grass-textured steep faces: the South Bridge trench, Cloudreach sheer faces (CR3) and Tidewake trench walls (TW1; also Tidewake verdict defect 16). The probe (`tools/_probe_south_bridge_gully.gd`, output `probes/south_bridge_gully.txt`) shows the gully walls are **Terrain3D cells, not a mesh**: about 8 m of drop inside one 2 m vertex step (76°). The wall texels are a mix of rock (id 2) and soil (id 1). **At the bridge (x=8), which is what the camera sees, they are path (id 3).** 26b7216d rewrites only vegetation ids {0,1,5}, so it cannot touch the path-painted bridge walls, which is why it showed no change there. Either way the stretch comes from top-down projection over a near-vertical quad. **Do not re-apply it as-is.** | A steep-face side (XZ/ZY) projection for steep fragments in `shaders/terrain_ground.gdshader` and the Cloudreach/Tidewake terrain materials. Keep path paint off the 76° walls at the bridge. | open |
| V17 | C2–C4 | Region audits: Cloudreach places (§C2) and Tidewake places (§C4) and Cloudreach env are judged; their rows are V18–V30. Stormwood and Tidewake env are in progress (VIS lane, read-only). | §C2–C4 | in progress (#304) |
| V18 | C4 TW7 | Tidewake rock does not read as wet dark rock. The judge reports "neutral grey-khaki walls" and "no dark wet rock", plus a cell rock texture (`judges/tidewake_places_VERDICT.md` defects 7 and 2). The auditor's own reading of sunlit faces (P001, P007, P012) is pale warm grey. The texture itself renders on a full checkout (render 36271541391). The tint is `#c6c3b8` over a texture averaging RGB 128/125/114. | `data/config/water_visual.json` `terrain.textures[2].tint`. Unjudged suggestion: tint `#7c8086` (the reference branch was deleted 2026-09-27). | open |
| V19 | C1 (Warrens) | Burrow Warrens: a dark grey smoke column cuts through the mound silhouette, and a floating white square sits at the right-hand bush line (evidence: `_sheet_meadows_env_32bd3307.jpg` (local capture at main 32bd3307), 'Warrens day'). Auditor observation, not yet judge-confirmed. | Warrens chimney/smoke VFX; identify the white square | open |
| V20 | F08#4 / CR1, CR10 | Cloudreach has no altitude read. Every stand is a flat grass tabletop. Past the edge there is white haze by day and a flat navy sea plane by night: no cloud sea below, no strata stacks above. | Cloudreach sky, fog and horizon (cloud-sea layer below plateau level); Bar A board `cloudreach-sky-aviary-stronghold-board.png` | open |
| V21 | CR6 | Cloudreach stray geometry: a pale plane (P002); a triangle (P014/P015); dark wedge planes and a hard road-end rectangle (P008/P009); pale faceted blocks at plateau edges (P001, P002, P005, P006, P007, P013) that glow at night (P002, P007, P013) | Identify nodes from the stand coordinates in `judges/cloudreach_places_LABELS.txt` | open |
| V22 | CR7, CR8 | Cloudreach night has no practical lights (beacon, Cliffhold windows, aviary interior, bells, shrine), and grass blades glow brighter than the ground at night. The beacon is a thin, unlit 40 px frame. | Cloudreach landmark dressing and night emissives | open |
| V23 | CR2 | The Sky Shrine pillar is a blank noise-marble cylinder with a floating black slab and a tree glued to its face (P010). | Shrine pillar material and dressing | open |
| V24 | F13 / TW1 | Tidewake roads are V-trenches: 20–60 m featureless walls fill 50–80 % of the frame and hide the sea and islands in 11 of 19 approach frames. | Tidewake lane: `water_heightfield.gd` trail grading. Codex: wall material (V16). | open |
| V25 | F13 / TW2 | **Verify first.** The named place is not visible from its approach in 12+ Tidewake frames. It may be missing or unplaced art, occlusion by V24's walls, or a limit of the capture sightline test (§D). | Check one place in-editor | open |
| V26 | TW9, TW10 | Tidewake stepping stones are identical elliptical sand discs with identical foam rings, evenly spaced. The Signal Spire is a 5 m lattice box. The Root Walk is a sand yard with a barrel and a crate. | Tide-stone generation; place dressing | open |
| V27 | C2 CR14 | Cloudreach unmaterialed geometry: a pure-white bridge deck at Three Bells, flat single-colour banner slabs, a glossy blue perch torus, blue floor ribbons and a cyan T-post, and white house trim that glows at night | Frames and stands in `judges/cloudreach_env_LABELS.txt` | open |
| V28 | C2 CR15, CR16 | Cloudreach sky: the cloud sea is faceted white slabs (white at dusk, lavender-glowing at night), and dusk turns the pale cliffs sepia, erasing the ravine vista | Cloudreach sky/cloud material; Cloudreach golden-hour preset | open |
| V29 | C2 CR13 | Sky Aviary stronghold: a small greenhouse dome on flat wheat, unlit at night; the board's towers, gold ribs, arches, cliff seat and falls are missing | Bar A board `cloudreach-sky-aviary-stronghold-board.png` | open |
| V30 | C2 CR17 | Galecrest companion: noisy, posterised surface and small inexpressive face; it becomes a cobalt blob at night in two frames. Keep the silhouette and scale. | Creature texture (reference-backed workflow) | open |
| V31 | F10#3 | Stormwood strike telegraph reads as a thin magenta selection/target ring, not a ground danger zone, and a still frame shows no time left (code-blind judge in `ralph/reports/STORMWOOD/b/f10_3/VERDICT.md` (#303)) | `scripts/world/stormwood_lightning.gd` telegraph shader (`progress` uniform), `data/config/stormwood_surge.json` presentation.telegraph: translucent hazard fill across the 3 m disc, a thicker rim, an inner ring that fills or shrinks to complete at 1.2 s (also the reduced-motion progress cue) | open — filled footprint/countdown in draft PR365; projected-bounds foliage fade restores trainer/central cue in sampled views, but ferns still hide portions of the hazard edge; [strike evidence](STORMWOOD-STRIKE.md), [foliage evidence](FOLIAGE-CAMERA.md) |
| V32 | F10#3 | Surge phases not nameable from a still: Building judged "Break" twice, Fading only as "Building or Fading" (judge in `ralph/reports/STORMWOOD/b/f10_3/VERDICT.md` (#303)) | `data/config/stormwood_surge.json` presentation.phases building/fading: give each a structural signature a still catches | open |
| V33 | F10#3 | Strike impact bolt reads as a soft grey pillar; normal-motion impact flash washes the whole frame grey-white, like daylight (judge in `ralph/reports/STORMWOOD/b/f10_3/VERDICT.md` (#303)) | `stormwood_lightning.gd` `_strike_flash`, presentation.flash `strike_*`: jagged forked core with glow plus a ground spark/scorch; cap or localise the frame wash | open — forked silhouette and retained purple scene pass scoped review in draft PR365; bolt finish/ground contact and full F10#3 remain open; [evidence](STORMWOOD-STRIKE.md) |
| V34 | F10#3 | Always-glowing gold road veins read as a hazard and compete with the strike telegraph (judge in `ralph/reports/STORMWOOD/b/f10_3/VERDICT.md` (#303)) | Stormwood road current (`stormwood_road_current.gd`, `data/config/stormwood_road_current.json`) | open |
| V35 | shared items | Three permanent elixirs and three temporary tonics share the same potion icon | `tools/gen_item_icons.py`, `data/items/items.json` | #331; six distinct icons pass 32/64 px, grayscale and production satchel review |
| V-TW-1 | F14#2 | Tidewake current restoration is not visible (state proven, look not; notes in row W1). **Pass when** a code-blind judge, shown a matched before/after pair from the production CameraRig at the same pose and time of day over a mandatory current (e.g. Tidal Cradle → Salt Crown direct, around (425, 0, 1920)), both with terrain streamed in, says (1) the before frame shows a moving current on the water (foam or streaks that follow the flow), and (2) the after frame shows the same current clearly calmer, without being told what changed. Use two frames 1 s apart if a still cannot show motion. State test: `tests/smoke_tidewake_b_current_restore.gd` (flag, calm_scale 1.0→0.5, 1.30→0.325 m/s, survives reload). | `scripts/world/water_current_flow_view.gd`, `shaders/water_current_flow.gdshader`, `data/config/water_veilfall.json` current_flow; poses in `ralph/reports/TIDEWAKE/b/f14_2_current_restore/PROOF.md` | open |
| V-TW-2 | F13#3 | Lantern Cove (side_water_lantern_return): the rock arch / dry-nook cache Pell sends you to is not visible from the lantern_cove arrival landing or 73 m along the approach. Judge: frame_01 WEAK ("only landmark is a single tree … nothing reads as a clear go-there beacon"), frame_02 NOT NOTICEABLE; place verdict NO (`ralph/reports/TIDEWAKE/b/f13_3_lures/` `lantern_1_landing.jpg`, `lantern_2_approach.jpg`, JUDGE_VERDICT.txt). **Pass when** a code-blind judge shown the same two production-CameraRig stands (`tools/capture_water_chain_lures.gd --only=lantern`) names the arch/nook as something to go to. | arch silhouette/scale and a sightline from the landing; cache nook dressing near `water:lantern_cove:pickup:002` (-407.7, 15.8, 210.4) | open |
| V-TW-3 | F13#3 | Gull Rest (side_water_gull_research): Adair's survey satchel (`Pouch_Large` x1.6 at (-22.3, 884.0)) is not seen from the gull_rest landing (101 m) or 40 m out; the judge was drawn only by a distant pale rock spire. Place verdict WEAK (`ralph/reports/TIDEWAKE/b/f13_3_lures/` `gull_1_landing.jpg`, `gull_2_approach.jpg`). **Pass when** a code-blind judge names the satchel site (or a marker for it) from those stands. | satchel site marker/dressing, `data/config/water_local_chains.json` gull_research_satchel (shared data file: coordinate with the main Tidewake lane) | in progress (#365): survey chart/banner passes40m approach and day/night identity; landing FAIL, site integration WEAK. See TIDEWAKE-LOCAL-SITES.md. |
| V-TW-4 | F13#3 | Drowned Garden (side_water_garden_records): the exposed vault wall (always_visible, `Wall_UnevenBrick_Straight` at (1204.5, 2337.6)) is not seen from the drowned_garden landing (171 m) or 68 m out; judge: frame_07 NOT NOTICEABLE ("reads as empty transition space"), frame_08 WEAK ("pretty but undirected vista"). Place verdict WEAK (`ralph/reports/TIDEWAKE/b/f13_3_lures/` `garden_*.jpg`). WORLD asks for a *visible* above-water vault. **Pass when** a code-blind judge names the vault/ruin from those stands. | vault wall massing/height and a ruin cluster that breaks the ridge line; `garden_records_wall` row | open: #365 kit-ruin candidate rejected and removed; terrain-sampled landing sightline needs about41m above site ground. See TIDEWAKE-LOCAL-SITES.md. |
| V-TW-5 | F13#3 | Deep Watch (side_water_deep_watch_chart): the chart control is a low pale beam-and-crate 13 m from the landing; judge frame_09 WEAK ("low-contrast and easy to overlook"), frame_10 NOTICEABLE only at 5 m. Place verdict WEAK (`ralph/reports/TIDEWAKE/b/f13_3_lures/` `deep_*.jpg`). **Pass when** a code-blind judge names the chart station from the landing stand. | `deep_watch_chart` dock prop in WaterDocks (chart table dressing, a post/lamp or flag) | scoped visual PASS (#365): installed awning, supported chart and lantern read from landing/day/night;11 lifecycle checks pass. Earned/full Bars remain open. See TIDEWAKE-LOCAL-SITES.md. |
| V-TW-6 | F13#3 | Tidal Cradle (side_water_cradle_care): judge place verdict YES, but what drew it was Otto's camp at the landing and a creature in a canyon; the shell nest / Reef Stone seam destination (818, 55, 1644) is not visible at 406 m or 122 m, and the mid stand is a narrow rock slot (`ralph/reports/TIDEWAKE/b/f13_3_lures/` `cradle_*.jpg`). Verify-first: recapture from a walked-route stand before treating the nest itself as a seen lure. **Pass when** a code-blind judge, shown a production-CameraRig frame from the tidal_cradle landing and one from a walked-route stand about 100 m short of the nest, names the nest/seam site (not only Otto's camp) as somewhere to go. | shell-nest dressing near `water:tidal_cradle:harvest:007`; capture stand | open (weak) |
| V-SW-1 | F10#2 | Stormwood named fights: every tell is the same non-directional magenta ring at the attacker's feet; no fight shows facing, a safe side or an exit, and a heavy tell looks like a normal one (code-blind judge, `ralph/reports/STORMWOOD/b/f10_2/JUDGE_ANSWERS.txt` (#332)). Lunge lanes for Hollows, Glass Field and the Hall Guardian are enabled by logic on #332; ring shape/colour, heavy-tell look and exit cues remain. | `scripts/creatures/wild_creature.gd` telegraph visuals, `combat.json` telegraph | open |
| V-SW-2 | F10#2 | Named-fight identity: five fights read as one dark flower meadow; Crown glass, hall architecture, pool edge and glass field are not in frame at the fight camera; Hollows and Glass Field alphas share the Voltarach body and read as the same fight (code-blind judge, `ralph/reports/STORMWOOD/b/f10_2/JUDGE_ANSWERS.txt` (#332)) | named arenas (`data/config/stormwood_encounters.json` positions/clearings); creature identity via X04 | open |
| V-SW-3 | F10#2 | Fight readability: the player creature (Sparkit) is small, low-contrast and often under the left TEAM panel or frame edge; one tan hit-burst is used for both sides so who hit whom is unclear (code-blind judge, `ralph/reports/STORMWOOD/b/f10_2/JUDGE_ANSWERS.txt` (#332)) | fight camera framing / HUD layout (X03), hit VFX | open |
| V-SW-4 | F10#2 | Named-fight opponents flash full-body white/translucent on hit; when it lands during a tell the creature reads as vanishing (Q tell4-b-mid, P tell4-b-mid) (code-blind judge round 2, `ralph/reports/STORMWOOD/b/f10_2/JUDGE_ANSWERS_r2.txt` (#345)) | creature hit-flash material (`creature_body.gd` hit flash) | open |
| V-SW-5 | F10#2 | Lane tells have no body wind-up (Voltarach pose unchanged across the tell) and the lane runs toward the camera off-frame under the left HUD column, taking the companion with it (P tell3-c-late, Q tell3-b-mid) (code-blind judge round 2, `ralph/reports/STORMWOOD/b/f10_2/JUDGE_ANSWERS_r2.txt` (#345)) | attack anticipation clips (X04), fight camera framing / HUD column (X03) | open |
| V-CX-4 | X04 / F05 Bars A/B | Tether Machine: thin suspension strips, coarse warped body, noisy baked highlights; installed CoreLight previously stayed active after release. | `machine_hardware.glb`, `tether_machine_finish.gd`, `stronghold_occupation.json` | In progress #365: scoped suspension/runes and shutdown; original body/material, diagrammatic restraint rings and whole-machine Bars A/B remain open. Evidence `TETHER-MACHINE.md`. |
| V-MA-1 | F03#1 (Doss) | Doss's river-bank perch (`building_prefabs.json` `river_bank_perch`: two `Floor_WoodDark` tiles and four `Prop_WoodenFence_Single` rails) renders as pale, near-white planes in daylight, because the kit's `MI_WoodTrim` trim sheet maps its pale painted band onto these pieces. The code-blind judge (`ralph/reports/MEADOWS-PAYOFFS/six-activities/distinct-actions/F03-1-DISTINCT-JUDGE-r5.md`) read it as "untextured white planes" and "a missing-texture decal". A dark-timber `MI_WoodTrim` multiply on this recipe alone (#7a5636, metallic 0) read as wood and passed (r6, frames in `distinct-actions/doss-perch/`), but it was reverted under the art-to-Codex rule. | `data/config/building_prefabs.json` `river_bank_perch` (a recipe-level `retint` is supported by `building_prefabs.gd`); capture with `tests/capture_activity_lures.gd --act --activity=doss --save=res://tests/fixtures/f03_lure_saves/S07-exit-band3-plus-1wood-1fiber.json.gz` | In progress #365: current native capture shows wood with speckled aliasing, not the historical blank-white look. Dark tint rejected for night regression; shared WoodTrim mipmaps pass independent final day/night perch and village review. Source pixels/repair logic unchanged. Whole scene/grounding and full Bars remain open. See [wood evidence](WOOD-MATERIALS.md). |
| V-MA-1 | F03#0 (Juno Tether camp lure) | The Tether patrol camp at (-172, 5485.5) sits behind a crest, so neither oxblood standard shows at the 159 m road sighting. Meadows activities added an opaque dark 42 m smoke column as a signal; the coordinator removed it in batch 47 under the art-to-Codex rule (the same class as V19). **Pass when** a code-blind judge sees the camp's lure from the road at dusk in the gameplay camera. | `data/config/bands/band4_upper_meadows_ironwood/props.json` TetherHoldingFire, signal fire or standards | open |
| V-CX-5 | X04 camera / foliage | Nearby non-colliding bushes hide the trainer during exploration; distance-only fading also removed unrelated Meadows plants. | `foliage_camera_visibility.gd` / `.gdshader`, material-only vegetation registration | In progress #365: projected-bounds gate restores sampled Stormwood trainer visibility and preserves Meadows peripheral foliage. Full hazard edges, dither finish, other camera profiles and device cost remain open. Evidence `FOLIAGE-CAMERA.md`. |

Fresh main `025a09d9d` coverage: 183 roster, 128 cast and 30 representative
four-region native 1080p frames. This is sampled coverage, not chapter acceptance.
Independent review confirms broad attack-stage clipping, degraded faces and
duplicated rank silhouettes. Region priorities are Cloudreach landmark architecture,
terrain/material transitions and foliage hierarchy, then Stormwood landmark framing
and effects integration. Meadows village is strongest but has foreground obstruction
and crushed night values. Tidewake Veilfall and Shellwatch stands do not adequately
show their destinations; do not count those frames as landmark proof.
Evidence: `CAST-AND-ITEMS.md`; raw local captures under
`shots/cross-game-main-025a09d9d/`. Whole-game A/B remain open.

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
| M9 | MAJOR | terrain material | P006/P007, P016, P004, E016, E013–E015 | Vertically stretched cliff projection on trench walls, pale untextured slabs, a voxel-looking wall texture, and stray yellow decal squares. | §3.1; rubric 7 | **Probe done → V16.** The walls are Terrain3D cells, not a mesh (`tools/_probe_south_bridge_gully.gd`, `probes/south_bridge_gully.txt`). At the bridge they carry path paint, and 26b7216d excludes path. Work moves to V16 (Codex). MEADOWS owns the stray decals. |
| M10 | MAJOR | staging | E004, P018, P022/P023, E007, E019, P017, E013–E015 | The companion's paws float above a slope. Pairs share pose and facing, and the griffin wings interpenetrate. The trainer is pressed into creatures, and an NPC's head sits between the camera and the trainer. | §5.1 | MEADOWS (spawn staging) · VIS (companion placement in the capture) |
| M11 | MAJOR | composition | E001–E003, P008/P009, E022, P020, P021 | A dead sapling sits dead-centre at 3 m, near trees block 35 % of the frame, and some stands have no mid subject. | §1 | MEADOWS |
| M12 | MAJOR | hero tree | E019–E021, P017 | The Ironwood canopy is flat-shaded paper facets, a different family from the other trees, and a black cut-out at night. | §1; §7 Ironwood row | ART-X04 |
| M13 | MINOR | water | P012, E016, P016 | Flat pale water with a hard edge. The Pond, meant as the lush reference, is the least dressed water. | §4; §3.1 | MEADOWS (shore dressing) · VIS (shore band in the water shader) |
| M14 | MINOR | dusk | E002, E011, E026 | Dusk is a colour shift over day, with no raking warm light or long shadows. | §3.3 | VIS |
| M15 | MINOR | foliage artefact | E010, E011 | Alpha-cut crowns shimmer as dithered noise at dusk. | rubric 7 | VIS |
| W1 | MAJOR | Tidewake current restoration (F14#2) | `ralph/reports/TIDEWAKE/b/f14_2_current_restore/*.jpg` | State is proven: `calm_scale` goes 1.0 → 0.5 and the physics current drops 1.3 → 0.325 m/s, and both survive a reload. The look is not proven: no WaterCurrentFlow foam ribbon is readable in the before frames from two fixed production-camera poses over the Tidal Cradle → Salt Crown current. The restored change is only a halved drift speed and about 22 % less opacity, too subtle for a still frame. The after-reload frames lost terrain streaming, so they are not comparable. Needs a readable current (and restored contrast) plus a matched before/after pose. | WORLD Tidewake "currents visibly change"; ACCEPTANCE F14 | Codex (visuals ceded) |

Strengths to keep: the village at P001 and the mill at E016, the badger companion, trainer legibility at night, painted day skies and night mood, the forest interiors, the pylon line as the spine to the finale, and the Warrens mound.

### C2. Cloudreach: 19 place + 33 env frames judged; places `Bar A no, Bar B no`, env `Bar A no, Bar B yes (genre only, not finish)`

- **Capture:** render.yml 36268641645 at main `32bd3307`, frames P001–P019.
- **Evidence:** sheet `_sheet_cloudreach_places.jpg`, verdict `judges/cloudreach_places_VERDICT.md`, frame labels `judges/cloudreach_places_LABELS.txt`.
- **Skipped:** the Broken Skyroad Arch and High Roost Perches stands are unreachable (§D).
- **Env rows:** 33 frames, E001–E033, at day, dusk and night.
  - E001–E009 are local renders at main `32bd3307`; E010–E033 are from render.yml 36275206146 at `0e2a3b60`, a docs-only difference.
  - Evidence: sheet `_sheet_cloudreach_env.jpg`, verdict `judges/cloudreach_env_VERDICT.md` (26 defects), labels `judges/cloudreach_env_LABELS.txt`.
  - Broken Causeways 1 was skipped because the rig detached (§D).
- **Owners:** all art and visual changes go to the Codex queue (V9 high perch, V10 settlements and cliff identity, or a new V row). Route, stand and road-shape content goes to the Cloudreach lane.

**Judge-prep correction, disclosed.** The judge's defect 1 ("no companion or creature in any frame") is a **capture fixture, not a game defect**:
- Place rows deliberately park the companion behind the camera; the manifest records `"companion": "parked behind camera"`.
- The paused EncounterDirector streams no wilds at a teleported stand.
- My judge brief wrongly said a companion stands in frame. Env rows keep the companion in frame, and they are the creature-in-world check.

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

**Env rows (E###).** These add to CR1–CR12 above. The env verdict also reconfirms:
- CR1 altitude (env #2: E013–E018, E022, E028–E030);
- CR8 settlements (env #8: E004–E006, E022–E024);
- CR4 blob/box rocks (env #13);
- CR5 bald ground and dithered edges (env #9, #10);
- CR7 night grass brighter than the ground (env #21).

**Capture staging, disclosed.** The judge's env blocker 1 (Galecrest hides the trainer in E031–E033, with a talon through the trainer's legs) is **my capture's companion placement**: a fixed 3.2 m side offset, too close for a large winged companion. It is not the game's follow behaviour. The tool now clears by the companion's measured footprint. It is not a queue row. The fix is unverified until E031–E033 are recaptured.

| # | Sev | Domain | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| CR13 | BLOCKER | stronghold | E028–E030 | The Sky Aviary is a small greenhouse dome on a low dark wall in a flat wheat field, unlit at night. The board's towers, gold ribs, arches, cliff seat and waterfalls are all absent. | §4; §3.2; Bar A board | Codex/ART |
| CR14 | MAJOR | unmaterialed geometry | E007–E009 (pure-white bridge deck, the brightest object at night); E010–E012 and E031–E033 (flat single-colour banner slabs); E019–E021 (glossy blue torus around the perch); E025–E027 (flat blue floor ribbons and a cyan T-post); E004–E006 (pure-white house trim that glows at night) | Placeholder planes and gizmo-like shapes read as missing materials. | §6; §3.3 | Codex |
| CR15 | MAJOR | cloud sea | E001–E003, E007, E009, E010, E012 | The cloud layer is faceted white slabs: unshaded, pure white at dusk, lavender-glowing at night. | §4 (no white washout) | Codex |
| CR16 | MAJOR | dusk | E011, E014, E023, E026, E029 | Dusk turns the pale cliffs sepia or desert and collapses the one ravine vista (E014) into tan haze. Foreground grass stays day-green. | §3.3; §2 | Codex (Cloudreach golden preset; see V15) |
| CR17 | MAJOR | companion art | E031 (close), E024/E027 (night) | Galecrest passes scale at 1.3–1.6× the trainer, and its silhouette is the best thing in the set. Its surface is noisy and posterised, the face is small and inexpressive, and it clashes in style with the trainer. At night in E024 and E027 it becomes a cobalt blob, losing the white chest. | §5.1; §7 | ART (Codex queue) |
| CR18 | MAJOR | landmark | E010–E012 | The Windscar Beacon stand shows a flat plank slab with an arch cut-out, reading as a door in a field. No beacon is visible. | §3.2; §6 | Codex |
| CR19 | MINOR | framing | E019–E021, E025–E027 (pillars box in the camera; nothing shows height); E022–E024 (camp bed centred in the foreground); E016–E018 (Sky Shrine stand has no subject) | Stand compositions. | §1; §4 high-perch camera | Cloudreach |
| CR20 | MINOR | artefacts | E023 (Galecrest floats, no contact shadow); E032 (square dark terrain patch); E007/E009 (pink glow blob at the frame edge); E010/E012 (white beam across the cliff); E031–E033 (floating gold ring and white orbs) | Stray or ungrounded elements. | rubric 7; §5.1 | Codex |

**Time of day (env):** day, dusk and night read as three distinct looks. Night is the strongest. Dusk is the weakest: it tints sky and distance while foreground grass stays green.

**Not carried from the verdicts:**
- Places #20 (Tether hardware scattered like debris beside the aviary): this is occupation layout, not palette. It folds into V29 and the Cloudreach stand work.
- Places #22 (trainer A-pose): an idle pose, owned by the cast work in §B, not a scene defect.
- Env #26 (Tether camp clutter): same as places #20.

**Strengths to keep:** the painted day sky and moonlit night sky, the trainer's legibility, the aviary dome silhouette, the Three Bells gantry icon, and the blue/gold banner language.

**Place reads from the approach:** only Summit Eyrie reads, weakly. Realm Gate, Three Bells, Cliffhold and the Observatory partly read. The Waycamp, Beacon, Aerie, Sky Shrine and Stormward Overlook do not.

### C3. Stormwood: rendering (render.yml, after Cloudreach env)

### C4. Tidewake: 19 place frames judged (env pending); judge `Bar A no, Bar B no`

- **Capture:** render.yml 36271541391 at main `0e2a3b60` (full checkout), frames P001–P019, all at day.
- **Evidence:** sheet `_sheet_tidewake_places.jpg`, verdict `judges/tidewake_places_VERDICT.md`, labels `judges/tidewake_places_LABELS.txt`.
- **Judge brief:** stated the place-row fixture (companion parked, director paused), so creature absence is not scored.
- **Replaced:** the previous unjudged sheet came from a checkout with missing texture files and has been removed.
- **Owners:** art changes go to the Codex queue (V1–V3 already cover docks, Veilfall and currents). Route, terrain-cut and stand content goes to the Tidewake lane.

| # | Sev | Domain | Frame(s) | Defect | Clause | Owner |
|---|---|---|---|---|---|---|
| TW1 | BLOCKER | route terrain | P001, P003, P005–P008, P011, P012, P017–P019 | Roads are V-trenches cut through the islands. Two smooth 20–60 m walls fill 50–80 % of the frame, with one cell texture and no ledges, strata or rubble. The walls hide the sea and islands, which is the chapter's identity. | §4 Tidewake; §3.1; §1 | Tidewake (trail grading / heightfield) · Codex (wall material, V16 steep-face projection) |
| TW2 | BLOCKER (verify) | landmark read | P001–P004, P006, P007, P009, P011, P012, P015, P017, P018 | The named place is not visible from its approach in 12+ frames: beacon, woven hall, stairstones, jetty, shrine, pumps, arch, terraces, lookout, camp, bridge, crown. **Verify first:** the capture's sightline test samples only the straight eye→target line, so each case is either missing or unplaced art, occlusion by TW1's walls, or a framing limit. Codex/Tidewake should check one place in-editor before building. | §3.2; §3.1 lure | Tidewake + Codex |
| TW3 | BLOCKER | finale landmark | P008, P018 | Veilfall has no mountain. The "White Cascade" is a thin white column in an empty sky gap (P008). The Mountain Crown stand has no sightline (P018). | §4 "white-falls mountain"; Bar A board | Codex (V2) |
| TW4 | BLOCKER | camera | P018 (inside dark geometry; giant flat near-grass triangles), P017 (camera collided into the trainer's head) | The camera breaks in narrow trenches. The judge attributes it to "the capture stand, or the camera's collision in a narrow trench". Whether a player on these roads hits it is unverified. | rubric 7; §5.2 | Tidewake (stands, trench width) · camera owner (COORD) |
| TW5 | MAJOR | distance read | P001, P013 | Veilfall is not on the First Shore horizon. | §4 "visible from First Shore" | Codex (V2) · Tidewake (sightline) |
| TW6 | MAJOR | palette | all except P014, P016 | Reads as Meadows: 60–90 % yellow-green grass and grey-khaki walls. Water appears only in slivers. P016 (open sea) is the one Tidewake frame. | §4 Tidewake palette | Codex · Tidewake (route framing) |
| TW7 | MAJOR | rock | P001, P007, P012 (auditor's frame picks) | The judge reports "neutral grey-khaki walls" and "no dark wet rock" (verdict defect 7). The auditor reads sunlit faces as pale warm grey. The rock texture renders on this full checkout, so V18 stands. | §4 "wet dark rock" | Codex (V18) |
| TW8 | MAJOR | ground | all grass frames | Uniform grass carpet with no readable path, verge, sand, reeds or marsh. Hard grass-to-wall seams (P005, P007, P012, P019). | §3.1 | Codex |
| TW9 | MAJOR | islands/tide | P004, P016, P019 | Far islands are smooth olive blobs. The tidal stepping stones are identical elliptical sand discs with identical foam rings, evenly spaced. | §4; rubric 3 | Codex (V3) |
| TW10 | MAJOR | places | P010 spire (5 m lattice box); P014 Root Walk (sand yard, barrel, crate; high-contrast sand tile); P005 basin (no basin; ~20 px figure) | The named places that are visible do not carry their names. | §3.2; §6 | Codex · Tidewake |
| TW11 | MAJOR | mid-ground | P002, P009, P010, P015 | Open-grass frames have nothing in the 15–80 m band. | §1 | Tidewake |
| TW12 | MINOR | foliage | P010, P014 | Pixel-leaf trees on bright orange-red trunks, a different family from P002/P004 and warm toward the reserved red. | §1; §5.2 | Codex |

**Keep:** the painted sky and grounded day shadows, the trainer's colour blocks, the P016 open-sea view, the P019 slot framing, the navy banners, and close-up grass quality.

**Not carried from the verdict:**
- #16 (stretched wall texture) folds into V16.
- #18 (Horizon Stones read as a rock heap; the bannered arch is cropped) folds into TW10 and V26 place dressing.
- #17 (orange-trunk trees) is TW12.

**Place reads:** only P008 (a fall exists), P010 (a tower on a crest) and P013 (boulder heap plus a bannered arch) partly read. The rest do not.

## D. Capture-tool limits (VIS, not asset defects)

- **Roster attack frames:** seated by idle bounds on a flat stage. Treat C2/C3 as PLAUSIBLE until an in-world combat capture confirms them.
- **Place stands:** a place with no clear road sightline falls back to an off-road ring stand, and the manifest says which was used.
  - Meadows **Old Mill Crossing** has no dry sightline stand; the trainer ended up in the river, so the row was SKIPPED.
  - Stormwood **Glass Sink** has no reachable stand; the game returns the trainer to spawn.
  - **Meadowhart Grazing Ground** has no fixed position.
  - Cloudreach **Broken Skyroad Arch** and **High Roost Perches** have no reachable stand: the trainer settled 700+ m away.
  - Cloudreach **Sky Shrine** fell back to an off-road ring stand at the foot of its pillar, where the shrine top is out of sight.
  - Each is a coverage gap to close with an authored stand, not a pass.
- **Place rows park the companion behind the camera, and the EncounterDirector is paused.** A place frame cannot show creatures in the world. Env rows carry the companion.
- **Env-row companion placement:** before 2026-09-26 23:00 it used a fixed 3.2 m side offset, which let a large winged companion cover the trainer (Cloudreach E031–E033). It now clears by the companion's measured footprint (the diagonal of its model bounds). **This is unverified until the E031–E033 stands are recaptured**, because the follow logic could still move the body during the settle frames.
- **Place-row sightline test:** it tests 15 interior points on the straight eye→target line against the terrain ground height (`_ground_guess`), not rendered geometry. It can report "clear" while the landmark is still out of the rendered view or its geometry is not at the realm-data point (Tidewake TW2). Treat "landmark absent" rows as verify-first.
- **Local renders need a complete checkout.** Clear skip-worktree first: `git ls-files -v | grep '^S'`.
