# Informed triage of the baseline visual survey

The baseline is not a visual acceptance pass. Its strongest immediately actionable production diagnosis is the Stormwood pylon's missing binding to installed albedo textures. Its broadest apparent placement failure is contaminated by the old survey camera. Repair the confirmed binding, obtain the already-planned corrected-camera verdicts, and carry the wider cast/environment finish gap into grouped second-pass work. Do not turn 116 frames into 116 speculative placement patches.

This is **informed triage**, not a new blind verdict. It reads the five preserved `JUDGE-*.md` baseline reports, repository rules, the four camera/material reports named below, relevant source and installed inventory. Original verdicts remain verbatim: each A answer is No, each B answer is Yes to the rubric's literal same-kind-of-game intention question, and every readiness answer is not visually ready. B does not establish shipping quality. No numeric score, production change, render, asset generation or gameplay acceptance is supplied here.

## Evidence and limits

Baseline canonical roots:

| Biome | Root | Coverage |
|---|---|---|
| Meadows | `shots/catalogue/meadows/round-20260909T002752Z/` | 20 frames |
| Cloudreach | `shots/catalogue/cloudreach/round-20260909T004031Z/` | 24 canonical `cloudreach__*.png` frames |
| Stormwood | `shots/catalogue/stormwood/round-20260909T004513Z/` | 24 canonical `stormwood__*.png` frames |
| Water | `shots/catalogue/water/round-20260909T004837Z/` | 48 canonical `water__*.png` frames |

The baseline reports enumerate every exact day/night filename and retain all eight rubric categories, ranked reference gaps and six product answers. Group labels below classify those findings; they do not replace that evidence. The combined sheet orders Cloudreach, Meadows, Stormwood, Water.

`CAPTURE-CAMERA-DIAGNOSIS.md` traces the old standalone camera to a Terrain3D height sampled before the trainer settled, without the production rig's follow/collision. Built floors can be above **or below** terrain. `CAPTURE-CAMERA-REPAIR.md` records the tool-only switch to production CameraRig and authoritative BuiltFloor resolution, with a fixture including an old-camera negative control. This is a systemic **evidence-tool defect**, not proof that all corresponding game actors float.

`MEADOWS-CAMERA-RESURVEY.md` records 20 corrected frames in `shots/catalogue/meadows/round-camera-20260909T011407Z/`. Hall camera Y9.0046 is above resolved floor Y6.172; the baseline camera was below that floor. The resurvey's direct inspection reports supported courtyard subjects. That addresses the Hall capture cause, **not broad Meadows visual acceptance**. Corrected all-biome blind verdicts remain pending at this report's decision point.

Corrected `meadows__band2_stone_and_root__04__the_burrow_warrens__day.png` and its night partner remain limited by a close creature and wall/ceiling. The generic route heading may be poor interior evidence. A separately labelled ordinary orbit at the **same canonical position**, preserving originals, is a reasonable supplemental capture; none exists yet. Do not move actors or shrink them to manufacture a view. The resurvey's provisional Burrowback identification is not established: root reports manifest-nearest `Warrens_mudsnout_1` around 2.6 m, with named Burrowbacks farther away. Nearest-manifest identity is not by itself visible-subject identity.

Static frames cannot establish animation appeal, expression range, combat spectacle/feel, emotional interaction, traversal/flight/swimming, interaction reliability, popping, temporal water seams, performance or hardware quality. The capture's roster/progression state also cannot stand in for the ordinary campaign. Missing from frame does not mean missing from source or unavailable art.

## Grouped diagnosis and disposition

### C — Camera, contact, occlusion and size evidence

**Systemic capture cause confirmed; local production residuals unclassified. In-engine/evidence work, no art requirement established.** Includes trainer feet clipped at the top, apparent floating people/animals/supplies, foreground bodies/trunks/pillars hiding the trainer or destination, crop-driven scale uncertainty, and apparent pickup/body overlap. Representative exact frames are `meadows__band5_stronghold_approach__10__meadows_hall__day.png`, `cloudreach__windscar_ravine__05__windscar_beacon__day.png`, `stormwood__deepwood__10__the_fallen_giant__night.png`, and `water__tidal_cradle__09__aquaryn_tidal_basin__day.png`.

The Hall is source-backed capture contamination. Other baseline overlaps may survive normal cameras, but that is pending evidence. A close creature, a contact shadow hidden by framing, or a perspective-shortened person does not justify a scale edit. Preserve the trainer's 1.80 m reference and the owner's creature hierarchy; **never shrink the larger side**. If a real hierarchy mismatch is later established at matched depth with identified roles, grow the smaller side under the actual scale contract. Pickup proportion and intersections need resolved world-space subject bounds and ordinary camera evidence before changing transforms. Walkability is not inferred from Water's steep slope stances.

Closure: original plus corrected canonical frames and manifests; same-position supplemental orbit only where needed; fresh-context blind assessment of player, creature face/body, contact and landmark visibility. Only persistent, located production defects enter a local repair lane.

### M — Material binding, colour treatment and plain props

**Shared integration mechanisms plus distinct regional implementations. In-engine first; art residual conditional.** Do not combine every pale object into one missing-texture diagnosis.

* **Confirmed pylon binding defect:** `stormwood__cinder_verge__02__verge_rod_station__day.png` and `...__night.png`. Root's `PYLON-MATERIAL-DIAGNOSIS.md` documents geometry-only `assets/environment/team_tether/tether_pylon.glb`, installed live/dead albedos, three Stormwood consumers lacking application, and correct Cloudreach/severed-spoke consumers. This is installed-art integration, not a new mesh or texture commission. Root owns the diagnosis; it is included verbatim with this report.
* **Shared shrine primitives:** `stormwood__deepwood__09__lantern_hollow__day.png` and `water__salt_crown__11__salt_crown_tide_shrine__day.png` show matching base/upright language. `scripts/world/realm_heart_shrine.gd:334` builds cylinder bases/sockets and box fins with explicit materials; `_build_relic_slots` repeats three companion sockets. This is a plausible shared source for the pictured family, not the pylon GLB failure. Definitive pixel-to-node attribution remains pending. Material and installed-kit reuse can improve presentation; a purpose-built shrine silhouette is an art/design residual only if those cannot satisfy the existing brief. Preserve all earned/placed/active states and state API.
* **Crown arch:** `stormwood__hollow_crown__07__the_crown_arch__day.png`. `scripts/world/stormwood_arch_runtime.gd:84` builds a dark slab, loads installed `assets/buildings/quaternius_castle/WallEntrance.obj`, and assigns an explicit metallic/emissive material. A castle mesh exists; this is not established missing art or the pylon's absent binding. State-dependent material and silhouette review must precede replacement.
* **Beach slabs/equipment:** `water__shellwatch__08__shellwatch_cradle_beach__day.png` and `water__brine_steps__06__brine_steps_east_beach__day.png` remain visually primitive. `scripts/world/water_dock_actions.gd:126` constructs equipment from coloured boxes. Exact pictured-wall attribution is unresolved; do not relabel every slab a pump. Installed prop reuse is available, while dedicated coastal forms remain a conditional art gap.

Installed inventory checked: castle `WallEntrance`, `WallEntranceBricks`, towers and banners; `assets/props/quaternius_fantasy/Workbench.gltf`; nature `CommonTree_*`; stylised terrain albedo/normal pairs. `water_camps.gd` already mounts real tents, bedrolls, workbench, fire and creature bed. A bare camp frame therefore cannot justify “camp art does not exist.” Installation proves availability, not suitability, assignment or final quality.

### K — Creature and humanoid coherence, expressiveness and duplication

**Systemic presentation pipeline with species/local composition residuals. In-engine audit first; art needed only for demonstrated residual surface/anatomy/expression deficiencies.** Covers mottled feathers/plated creatures, flat yellow duplicates, magenta/cyan/blue/red colour blocks, night-bright animals, generic rear-facing trainer and lack of visible partnership. Exact anchors: `meadows__band4_upper_meadows_ironwood__07__the_ironwood_grove__day.png`, `cloudreach__gate_lower_cliffs__02__galefoot_waycamp__day.png`, `stormwood__conductor_run__06__the_capacitor_grove__day.png`, `water__reedhaven__03__reedhaven_woven_hall__night.png`.

`scripts/creatures/creature_body.gd:713` onward selects authored aspect/vivid/shiny/alpha colourways; `:1336` swaps installed textures and scales emission when enabled. `:930` and `:965` manage the separate night floor for otherwise lit materials. `scripts/creatures/water_species_catalog.gd:129` supplies namespaced colourway source identity. These are real integration levers: a loud or self-lit render is not proof the base mesh must be generated again. They also do not prove that recolouring will repair anatomy or expression. Preserve variants and their semantic distinctions; no blanket removal of colourway/emission contracts.

`docs/art/HUMANOID_ASSET_INVENTORY.md` lists 28 installed production bodies and warns against treating older six-rig notes as availability. The rebuilt Warden is installed. Existing cast/config reuse comes before a new humanoid request. Do not assert that unused-at-inventory-date bodies are still unused now. Repeated neighbouring animals may be staging, runtime proximity or authored encounters; identify them before editing placement/count. No gameplay event or emotional animation is missing merely because this location survey does not show it.

Closure: resolve actual displayed species/variant/materials; compare installed source versus active bindings under corrected day/night camera; review any residual face/anatomy/material issue against the unchanged references. Wider cast redesign is deferred. No new Meadows meshes or spend are authorized by this triage.

### G — Terrain, foliage and surface transitions

**Systemic surface/cover authoring with biome-specific implementations. Mostly in-engine composition/material work first; geometry/texture art residual conditional.** Includes wire grass, evenly sprinkled flowers/shrubs, bare lawns/beaches, repetitive tree silhouettes, sparse canopy, mismatched rock families, enlarged blurry bark/masonry, stretched cliff grass, hard polygon dirt/grass edges and tiled floor striping. Exact anchors: `meadows__band1_lower_meadows__01__grandpas_village__day.png`, `meadows__band2_stone_and_root__03__the_old_quarry__day.png`, `cloudreach__upper_cloudreach__09__cliffhold__day.png`, `water__deep_watch__23__deep_watch_lookout__day.png`, `water__lantern_cove__18__lantern_cove_beach__day.png`.

`water_world.gd:220` binds installed Terrain3D textures from `data/config/water_visual.json`; that config selects stylised meadow grass, dirt and rock textures with pale tints and distinct UV scales. Materials are not absent. World construction mounts terrain, water and gameplay services; this inspection did not establish a complete local vegetation/scatter implementation for Water. Bare coverage is an open authoring gap, not a claim that no suitable plant asset exists. Existing nature and terrain families must be reused before sourcing, and the approved lush Pond density must not be spread indiscriminately. Close-camera magnification can exaggerate texture softness; repeating far-ground patterns survive as a separate surface concern.

Closure: readable corrected views at ordinary distances establish actual coverage/transition problems; a bounded shared-material or clustering repair is judged once. Residual canopy/grass form, organic tunnel geometry and close-surface fidelity belong to second-pass art briefs. The existing Warrens organic-tunnel and exhausted tether-machine deferrals remain, without reopening repeated tuning.

### D — Destinations, architecture, habitat and occupied places

**Cross-biome authoring gap, with local locations and capture uncertainty. In-engine reuse/staging first; specialised regional art conditional.** Includes hidden bridges/towers/beacons, anonymous giant columns, blockout-like relay/ramp/arch/courtyard, sparse houses/wells, unframed watch/perch/observatory, repetitive island/gully views and weak settlement/coastal life. Exact anchors: `meadows__band3_the_river_lock__05__the_tether_relay__day.png`, `cloudreach__high_roost_sky_shrine__08__the_high_perches__day.png`, `stormwood__glowmoss_hollows__04__crown_overlook__day.png`, `water__reedhaven__03__reedhaven_woven_hall__day.png`.

No inference from a label to nonexistent content: mill filename versus displayed “The Long Water,” Water's unshown pumps/hall/jetty/garden, and Stormwood's unshown fallen tree/glass field/pools are unresolved presentation/coverage findings. Real Water camps and a real Crown heartstone (`stormwood_crown.gd`, installed nature rock plus local light) demonstrate why inventory and framing matter. Thin supports and giant architecture also need intermediate human-scale detail; they do not establish wrong creature size.

Closure: corrected approach and same-location context identify the intended existing landmark, entry and readable local cluster. Persistent visual anonymity becomes an authored composition task. Only a documented inability of the permitted installed kits to express the existing regional brief justifies a new-art request. Do not invent quests, settlements, activity systems or progression to satisfy a still.

### L — Lighting, palette signals and local warmth

**Systemic day/night and material integration, plus local light placement. In-engine first.** Includes black Meadows trainer/routes, pale Cloudreach night sky/distance, flat Stormwood foreground, bright Water creatures against dark people, windows without ground warmth, weak lantern-led destinations, competing red vegetation/animals and unclear red camp banner ownership. Exact anchors: `meadows__band3_the_river_lock__06__old_mill_crossing__night.png`, `cloudreach__broken_causeways__04__broken_skyroad_arch__night.png`, `stormwood__deepwood__09__lantern_hollow__night.png`, `water__lantern_cove__18__lantern_cove_beach__night.png`.

`world_look.gd:1018` applies environment/sky, human and creature emission floors, ambient light and fog. Its shared mechanism and the creature material paths warrant one coherent diagnosis before biome-by-biome brightness knobs. Corrected captures explicitly apply and report the requested time; baseline pixel observations remain valid, but scene clock/material causes are not all isolated. Separate pylon binding and unshaded waterfall causes from global exposure. A dark-red banner or red animal is not proof of friendly Team Tether colour misuse: determine object ownership and intended semantic palette first. Broadly competing red still weakens visual hierarchy.

Closure: matched day/night corrected views keep route, trainer and creature readable while maintaining distinct time and biome mood; local windows/lanterns motivate visible light. Preserve danger-colour rules without blindly recolouring natural species. No art purchase is justified by exposure alone.

### E — Sky, clouds, water, waterfall and horizon depth

**Shared atmosphere systems with regional effects; one clear local implementation candidate. In-engine first, residual effect/landform art conditional.** Covers flat moon/streak clouds, white cloud ovals, pale sea, hard tonal divisions, thin forest ending in empty hills, weak Meadows distant bands and repeated island silhouettes. Exact anchors: `meadows__band4_upper_meadows_ironwood__08__the_ridgeline_watch__night.png`, `cloudreach__upper_cloudreach__10__old_wind_observatory__night.png`, `water__sluice_isle__14__sluice_channel_bridge__night.png`, `water__veilfall__15__the_veilfall_cascade__night.png`.

`water_veilfall.gd:134` builds a double-sided plane with alpha 0.83 and unshaded material: a concrete, local source candidate for the pale sharp-edged overlay, separate from terrain or global night lighting. Corrected-camera position must establish whether the ordinary route passes through or behind it before choosing a visual change. `water_surface.gd` uses the installed `shaders/water.gdshader`, baked terrain-height texture and procedural normals/foam. Still tonal boundaries do not prove LOD/chunk/shadow bugs. `world_look.gd` uses `shaders/sky_clouds.gdshader`; Cloudreach has additional regional presentation. This triage does not isolate the specific cloud-oval node or horizontal Stormheart beam.

Closure: inspect ordinary corrected approach to Veilfall, then one bounded material/effect repair if reproduced. Temporal water/sky concerns require a recording; do not infer popping or performance. Wider skyline/canopy/island composition and residual cloud/shore forms are grouped second-pass work.

### U — HUD, prompt hierarchy and minimap information

**Systemic UI, with state/scene-specific occlusion. In-engine work; no new-art requirement established.** All baseline reports find safe margins and readable main prompts, but large blank five-card area/long command strip consumes creature space, status/time contrast is weak, tiny key labels compete poorly and some minimaps lack visible landmarks. Exact anchors: `cloudreach__windscar_ravine__06__windscar_flight_aerie__day.png`, `stormwood__dynamo__11__the_glass_field__day.png`, `water__tidal_cradle__09__aquaryn_tidal_basin__night.png`.

Do not equate all five-card controls with the owned roster: `playground_hud.gd` has both hotbar slots and a party strip, and around `:2004` explicitly suppresses empty-roster reveal. The baseline's generic visual description does not identify the live control. Survey state, filled ordinary inventory/team, prompt state and screen size must identify which panel persists before a UI fix. Existing map corruption/compass deferrals remain separate; featureless minimap stills do not prove that bug. Judge UI independently of Palworld.

Closure: real empty and populated states at target resolution keep required commands identifiable, world-space creature information visible and text contrast readable. No hidden hotbar/party contract change to improve screenshots.

## Complete baseline coverage crosswalk

Each row maps every day/night pair at the listed baseline locations to the groups above. The original biome report supplies the full canonical names; the exact basename stems below expand only by adding `__day.png` and `__night.png`. Category mapping: silhouette C/K/D; colour M/K/L; intentionality G/D; lighting L/E; horizon G/D/E; interface U; artefacts C/M/G/E; scale C/D/K. Positive findings and all limits remain in the original verdicts.

| Exact canonical basename stem | Groups |
|---|---|
| `meadows__band1_lower_meadows__01__grandpas_village` | G/D/L/K/U |
| `meadows__band1_lower_meadows__02__the_south_bridge` | C/G/D/L/U |
| `meadows__band2_stone_and_root__03__the_old_quarry` | C/G/D/K/L/U |
| `meadows__band2_stone_and_root__04__the_burrow_warrens` | C/G/D/L/U |
| `meadows__band3_the_river_lock__05__the_tether_relay` | C/M/D/L/U |
| `meadows__band3_the_river_lock__06__old_mill_crossing` | C/D/E/L/U |
| `meadows__band4_upper_meadows_ironwood__07__the_ironwood_grove` | K/G/D/L/U |
| `meadows__band4_upper_meadows_ironwood__08__the_ridgeline_watch` | G/D/K/L/E/U |
| `meadows__band5_stronghold_approach__09__stronghold_approach` | C/G/D/L/U |
| `meadows__band5_stronghold_approach__10__meadows_hall` | C/D/L/U |
| `cloudreach__broken_causeways__03__three_bells_bridge` | D/G/L/E/U |
| `cloudreach__broken_causeways__04__broken_skyroad_arch` | C/M/D/L/E/U |
| `cloudreach__gate_lower_cliffs__01__realm_gate_crag` | C/D/G/L/E/U |
| `cloudreach__gate_lower_cliffs__02__galefoot_waycamp` | K/D/G/L/U |
| `cloudreach__high_roost_sky_shrine__07__sky_shrine` | C/G/D/L/U |
| `cloudreach__high_roost_sky_shrine__08__the_high_perches` | C/M/D/L/U |
| `cloudreach__summit_final_stronghold__11__summit_eyrie` | M/D/L/U |
| `cloudreach__summit_final_stronghold__12__waterward_overlook` | C/G/D/L/U |
| `cloudreach__upper_cloudreach__09__cliffhold` | D/G/L/U |
| `cloudreach__upper_cloudreach__10__old_wind_observatory` | C/D/G/E/L/U |
| `cloudreach__windscar_ravine__05__windscar_beacon` | C/D/U |
| `cloudreach__windscar_ravine__06__windscar_flight_aerie` | C/K/G/D/E/L/U |
| `stormwood__cinder_verge__01__the_struck_sentinel` | C/G/D/U |
| `stormwood__cinder_verge__02__verge_rod_station` | C/M/K/D/L/U |
| `stormwood__conductor_run__05__rodline_post` | C/K/D/G/U |
| `stormwood__conductor_run__06__the_capacitor_grove` | C/K/D/U |
| `stormwood__deepwood__09__lantern_hollow` | C/M/K/D/G/L/U |
| `stormwood__deepwood__10__the_fallen_giant` | C/K/D/U |
| `stormwood__dynamo__11__the_glass_field` | C/K/D/U |
| `stormwood__dynamo__12__the_stormheart_tree` | C/K/D/E/L/U |
| `stormwood__glowmoss_hollows__03__the_lantern_pools` | C/D/G/L/U |
| `stormwood__glowmoss_hollows__04__crown_overlook` | G/D/E/U |
| `stormwood__hollow_crown__07__the_crown_arch` | C/M/D/U |
| `stormwood__hollow_crown__08__the_crown_heartstone` | C/K/D/G/E/U |
| `water__brine_steps__05__the_tidal_stairstones` | K/G/D/E/L/U |
| `water__brine_steps__06__brine_steps_east_beach` | C/M/D/L/U |
| `water__deep_watch__23__deep_watch_lookout` | G/D/L/U |
| `water__deep_watch__24__deep_watch_beach` | G/D/E/L/U |
| `water__drowned_garden__21__drowned_garden_terraces` | G/D/E/L/U |
| `water__drowned_garden__22__drowned_garden_beach` | K/G/D/L/U |
| `water__first_shore__01__first_shore_welcome_beacon` | C/K/G/D/L/U |
| `water__first_shore__02__first_shore_horizon_stones` | K/G/D/E/U |
| `water__gull_rest__19__gull_rest_signal_spire` | C/K/G/D/L/U |
| `water__gull_rest__20__gull_rest_beach` | G/D/U |
| `water__lantern_cove__17__lantern_cove_drift_arch` | G/D/E/U |
| `water__lantern_cove__18__lantern_cove_beach` | G/D/L/U |
| `water__reedhaven__03__reedhaven_woven_hall` | C/K/G/D/L/U |
| `water__reedhaven__04__reedhaven_root_walk` | M/G/D/E/U |
| `water__salt_crown__11__salt_crown_tide_shrine` | C/M/D/L/U |
| `water__salt_crown__12__salt_crown_return_bell` | C/G/D/L/U |
| `water__shellwatch__07__shellwatch_rescue_jetty` | C/K/G/D/L/U |
| `water__shellwatch__08__shellwatch_cradle_beach` | C/M/K/G/D/L/U |
| `water__sluice_isle__13__sluice_isle_twin_pumps` | K/G/D/U |
| `water__sluice_isle__14__sluice_channel_bridge` | C/G/D/E/L/U |
| `water__tidal_cradle__09__aquaryn_tidal_basin` | C/K/G/D/L/U |
| `water__tidal_cradle__10__tidal_cradle_saddle_camp` | C/G/D/L/U |
| `water__veilfall__15__the_veilfall_cascade` | C/E/L/U |
| `water__veilfall__16__veilfall_mountain_crown` | C/K/D/U |

Combined findings introduce no separate implementation defect: uneven regional finish maps to M/G/D, inconsistent nights to K/L/E, obstructed creature/trainer relationships to C/K/U, and the lack of visual/emotional partnership to K plus the static evidence limit. The six product answers remain the baseline's prototype tier, three visible blocker families, intermittent exploration promise, broad regional identities with weak subregions, inconsistent creature focus and below-reference integrated finish. None becomes a gameplay or performance verdict through this triage.

## Short repair queue and stop rule

1. **Finish evidence correction already underway.** Fresh-context judge sees corrected frames and unchanged rubric/references only. Preserve canonical captures and label any same-position supplemental orbit. This report's informed author is ineligible for that blind review. No production placement/scale patch follows solely from baseline C findings.
2. **One confirmed shared binding repair:** reuse installed live/dead pylon materials across the three diagnosed Stormwood consumers, preserving faction/state meaning, scale, collisions and authority. Follow root's diagnosis, focused negative-control fixture and corrected-frame blind check. Other white objects do not silently enter this patch.
3. **Conditional bounded follow-up after corrected evidence:** if Veilfall whiteout persists from the ordinary camera, diagnose the local unshaded plane against its actual approach; if material/night incoherence persists, inspect the shared active material/WorldLook relationship before isolated brightness edits. These are separate causes, not permission for a broad cosmetic sweep.

**Only one cosmetic round is allowed.** This triage consumes no render round and creates no additional allowance. Existing exhausted cosmetic work stays deferred; a failed permitted repair is recorded with its remaining defect and evidence rather than retuned repeatedly. Never shrink actors to improve framing. Do not add production edits, art spend, gameplay features or acceptance claims under this documentation task.

Wider cast, regional landmarks/vegetation, surface/atmosphere polish and UI residuals are appended as grouped deferrals to `docs/SECOND_PASS_BACKLOG.md`, with closure criteria and evidence. They remain visible debts; pending corrected-camera findings are evidence debts until reproduced, not silently accepted production faults.
