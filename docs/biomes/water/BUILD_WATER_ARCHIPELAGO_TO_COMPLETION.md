# BUILD BIOME 4: THE WATER ARCHIPELAGO TO COMPLETION

Status: owner-authorized execution, 2026-09-06. Stage B. The owner's run directive overrides the design-only line in 00_START_HERE.md. The Water design directive and owner boards remain the creative contract; this document supplies implementation counts, tuning contracts and acceptance evidence.

## 0. Decisions and precedence

Use the twelve named board species. Aquaryn is the catchable Water Dragon Alpha; Abyssal Guardian is the captive legendary; Tidecoil is the non-mount deep-water apex. Human never fights; five owned creatures total; no reserve. Multiplayer from the first implementation. No boats, oxygen meter, diving, underwater building, thirst, fishing minigame, grappling or universal wetness punishment. Installed humanoid cast only. Placeholder creature bodies are explicit replacement points, never final art acceptance.

## 1. Entry and predecessor truth

Start from fresh merged main. Stormwood is concurrently being built; at baseline 5547d415f no Stormwood completion report exists. Its realm key, Waterward overlook and return anchor are dependencies, not proven features. Water consumes realm_key_water once through the existing realm gate/transition seam, persists realm_gate_water_unlocked, and permits return without another key. Stormwood remains an overlook until the player spends the key. Never migrate a newly earned Stormwood Water key using the old Cloudreach key migration.

## 2. Player outcome

Finish Stormwood, spend the key, arrive at an inhabited shore facing the distant Veilfall; learn human swimming and currents; earn four distinct departure docks; beat or catch Aquaryn, receive the Swim Stone regardless, craft and equip a Swim Saddle on one of five compatible species; reach remote islands, interrupt crossings for normal creature combat, break the current-control network, make the hardest crossing, hike behind the falls, defeat Captain Nerissa, free the Abyssal Guardian, resolve the five-slot ceremony, earn and place the Tideglass Compass, activate Tidal Guard, and revisit a changed archipelago. Target 3–4 focused hours, with optional island exploration beyond it.

## 3. World composition

One realm, water. Twelve authored Terrain3D islands, eight on the main path and four optional. Realm-local sea level 0 m. Bounds x -1200..1900, z -500..4900, y -80..650. Terrain shallows are real slopes, beaches are landings, cliffs and currents explain gated approaches. No invisible swim walls. A far-side pier cannot be bypassed by an adjacent gentle beach: gates control physically useful departure channels, while wilderness detours have authored current/distance costs. Terrain collision must remain resident for separated peers, never only their average position.

| Island id | Name | Center x,z m | Approx radius m | Purpose |
|---|---|---:|---:|---|
| first_shore | First Shore | 0,0 | 180 | arrival, sheltered swimming lesson, trader, camp |
| reedhaven | Reedhaven | 0,440 | 180 | marsh settlement, repair departure pier |
| brine_steps | Brine Steps | 420,660 | 190 | rocky terraces, local trainer challenge |
| shellwatch | Shellwatch | 320,1120 | 190 | occupied dock, rescue and first pump |
| tidal_cradle | Tidal Cradle | 700,1530 | 260 | land/water Alpha arena, Swim Stone, saddle craft |
| salt_crown | Salt Crown | 150,2310 | 260 | first expedition crossing, main late settlement/shrine |
| sluice_isle | Sluice Isle | 850,2960 | 290 | pumps, patrol platforms, final channel controls |
| veilfall | The Veilfall | 200,4140 | 400 | mountain, last preparation, hike, hidden stronghold |
| lantern_cove | Lantern Cove | -350,170 | 110 | early optional swimming detour and recovery cache |
| gull_rest | Gull Rest | -70,870 | 100 | sheltered Reedhaven branch, stranded researcher |
| drowned_garden | Drowned Garden | 1200,2240 | 160 | mounted-only ruins, rare rewards and habitat |
| deep_watch | Deep Watch | 1350,3500 | 150 | Tidecoil encounter, current shortcut, Skill Candy III |

Radii are massing bounds; routes and shoreline anchors determine measured crossing length. Early exposed gaps start around 80–110 m; optional Gull Rest is reached from Reedhaven, not a required Shellwatch shortcut. Late exposed gaps start around 400–660 m. The Veilfall rises above the first shore's horizon and has pale wet rock, green terraces, broad white falls and a concealed gate, not a sea-visible castle. At least four land loops, three unlocked return shortcuts and eight deliberate reward pockets. Land-route target >=8 km, water routes >=2 km. Re-measure authored polylines after terrain baking; counts do not excuse empty walking.

## 4. Story spine and docks

Act I, The Broken Channels: Dockkeeper Mara receives the Stormwood traveler; swimmer Pell teaches the calm-water route. Reedhaven's community pier needs reed-rope and driftwood repair. At Brine Steps, keeper Tovin asks for a trainer demonstration. Shellwatch's occupied dock opens after freeing stranded residents and disabling its pump; this exposes the exhausting final human crossing. Researcher Iona identifies the guardian at Tidal Cradle.

Act II, A Back Across the Sea: Aquaryn alternates exposed shore attacks and water sweeps. Defeat OR successful catch resolves the shared encounter and awards each eligible participant the personal Swim Stone unlock once. Iona teaches the saddle recipe. A normal Mosshell habitat and the required recipe resources are available before departure so catching Aquaryn never gates progress. Salt Crown shows the value of the mount and introduces shrine keeper Edda. Defector Corin explains that Team Tether is driving currents into the Veilfall containment crystal.

Act III, Behind the Veil: disable the two Sluice Isle controls through a patrol fight and a channel-routing interaction, open the sheltered preparation channel, provision at Lastlight Camp, cross to the Veilfall, hike the wet-rock terraces, beat Officer Venn at the waterfall approach, enter behind the falls, release the sluices and defeat Captain Nerissa in the Heart Chamber. Free the Deep Watcher and resolve the roster offer. The pumps stop, safe current corridors broaden, occupied docks become civilian, and NPCs acknowledge the choice.

Dock objectives: swim lesson, repair materials, trainer test, resident rescue plus pump switch, Alpha/recipe preparation, chart a safe landing, two sluice controls. No identical beat-one-trainer ladder. State changes are server-authoritative, durable world ledger claims. The realm key and gate are shared world facts; personal candy/recipe rewards retain ownership and idempotency.

## 5. Global Skills dependency

Running, Catching, Riding, Swimming, Flying only. Accumulate from Meadows; reveal menu upon first Cloudreach arrival. Migrated saves start at zero XP, without fabricated historical activity. Starting cap 30; next-level cost 100 + 30*level XP, both tunable. Running from real sprint distance; Catching from confirmed legal wild catches; Riding from real mounted distance; Swimming from actual water distance; Flying from actual flight distance. No idle or menu-open XP. Cap benefits and event rate so repeated packet delivery cannot award twice. Personal PlayerState owns XP and reveal state; legacy saves and portable CharacterSave both serialize them. Menu shows level, progress, improvement source, current benefit, next benefit and cap. Controller focus and 720p readability tested with real input.

## 6. Skill Candy

Skill Candy I/II/III add 1/2/3 levels to a selected skill. Preserve fractional progress; refuse consumption if full award would exceed the cap and explain why. Selection and inventory removal are one identity-based transaction. Repeated request/reconnect cannot duplicate XP or item. Twelve authored rare placements: 7 I, 4 II, 1 III, primarily optional islands, coves, hard trainers and current routes. Black glow on every tier; markings I/II/III and silhouette distinguish them. Use the existing inventory and action UI, not a parallel inventory.

## 7. Human swimming

Use the production local player and owner movement replication. Water state machine: LAND, SWIMMING, DROWNING, COMBAT_PAUSED; mounted variants share the same aquatic rules with a creature resource owner. Water-entry volume and terrain depth decide mode. Human speed starts 3.8 m/s, stamina capacity uses existing vitals, drain 2.8/s, drowning damage 4 HP/s. Safe-ground exit ends damage immediately. No deep-water idle regeneration. Reaching zero is visible/audible and gradual. Swimming skill reduces drain by 1.5% per level, capped at 35%. First required crossing must leave >=15% stamina for level-0 unfed swimmer at normal capacity; shorten the actual channel if it does not. Do not fix unfair geometry by giving infinite stamina.

## 8. Mounted swimming

Compatibility is explicit species data: Aquaryn speed 10.0 m/s, capacity 200, drain 2.0/s; Mosshell 6.8, 240, 1.7; Sirenseal 8.5, 180, 2.0; Riverdrake 9.2, 160, 2.0; Cannonback 6.3, 210, 1.8. Starting numbers require runtime tuning. All other board species are land/shallows, including Tidecoil and the legendary. Apply modest Swimming efficiency and Riding handling without making mounts interchangeable. Use a distinct persistent traversal-stamina value per creature, not combat energy; recover on safe land through existing care/rest cadence. At zero, drain mount HP at 3/s. Keep rider and mount transforms on the existing shared anchor; head/back above water, trainer seated visibly above surface. Equipped Swim Saddle is visible; wild creatures wear none. Exhausted/dead mount dismounts into human swimming without granting free stamina.

## 9. Currents and water combat

Authored current channels store vector, width, extent and strength; early 0.35–0.7 m/s, late 1.0–1.8, hazardous shortcut up to 2.2. Flow direction is identical in physics and surface foam/debris animation. Sheltered routes are longer but have weaker adverse flow. Currents never substitute for geometric gates.

An amphibious interception starts the existing encounter flow, remembers mount identity and water position, dismounts, holds the non-fighting human safely at the surface, and directly pilots a creature in an authored shallow/sandbar/surface arena. Both human and mount swim drain/drowning are paused only for the actual encounter, with no regeneration exploit. Normal switching and wild catching remain. Ending/losing/disconnecting restores correct traversal state and allows remount when legal. Two peers may independently fight or swim on different islands.

## 10. Alpha design

Aquaryn, level 49, three spatial phases: Shore Crest (long tail sweep, flanking opening), Tidal Run (dives only as animation, moves along visible surface channel and returns to another shore), Broken Wake (alternating frontal jet and exposed side). No required player diving. Four limbs/long body on final art; installed placeholder is explicitly temporary. Shared boss health and phase authority use existing encounter host. Catch remains legal, trainer ownership false. Completion awards Swim Stone/recipe regardless of catch and only once per eligible player. Loss returns to Tidal Cradle camp with no reward claim. Compare alternate-Mosshell progression to caught-Aquaryn progression in smoke.

## 11. The Veilfall

Low shore arrival and final recovery opportunity; mountain hike rises to the broad main waterfall; a passage is discovered behind the water. Interior: wet-cave entry, pump room, elevated sluice bridge, Heart Chamber. Compact 10–15 minute approach/interior before boss rather than a separate sprawling dungeon. Stone arches, moss, warm lamps, blue Tether banners and aged machinery follow the board. Crystal remains contained until victory. Kitbash first; one authorized Meshy hero object only after this interior works.

Captain Nerissa, ace level 55: Channel Cycle (three readable water discharge lanes, raised safe platforms); Pressure Rise (faster telegraphed sluices and counter-switching); Break the Tether (piloted creature breaks three exposed conduits between pulses). Human never attacks apparatus. Officer Venn is level 53. Loss restores at Lastlight without resetting completed outside controls. Final completion, legendary offer and reward transactions are host-authoritative and replay-safe.

## 12. Legendary, relic and aftermath

Abyssal Guardian level 55, nickname The Deep Watcher. Release after crystal shutdown; offer through the established full-party ceremony, never a hidden sixth creature. Declining/releasing cannot block the chapter. Realm relic: Tideglass Compass, power Tidal Guard, incoming damage multiplier 0.90 in data/config. Earned/placed/active state follows RealmHeartState and existing single-active-power UI. Never call the relic a Heart (Heart Chamber is the canonical room name). Aftermath visibly stops pumps, changes current channels, removes patrol occupation and switches NPC dialogue; return visits and late joins reconstruct it.

## 13. Minimum content census

| Category | Minimum/target | Distribution and evidence |
|---|---:|---|
| Islands | 12 | 8 main, 4 optional, each reachable by authored route |
| Named map regions | 6 | First Shores, Marsh Channels, Tidal Cradle, Outer Reaches, Tether Current, Veilfall |
| Landmarks | 18 | >=1 per island; Veilfall visible early |
| Land route / water route | 8 km / 2 km | measured polylines; gaps judged from continuous play |
| Wild clusters | 240 | >=20 per main island, >=8 per optional; >=3 roles per table |
| Encounter tables | 16 | land and shallows per main island; night weights |
| Named encounters | 6 | Aquaryn, Tidecoil, four distinctive habitat challenges |
| Trainers | 24 | 12 critical, 12 optional; 3 lines each; ladder step <=4 |
| Named NPCs | 18 | >=1 per main island; pre/post liberation dialogue |
| Settlements | 3 | First Shore, Reedhaven, Salt Crown; trade and preparation |
| Safe camps | 8 | one per main island; real save/rest/cook/recovery |
| Harvest nodes | 160 | >=14 per main, >=8 per optional; authored useful placements |
| Pickups | 200 | >=80% off critical path, stable identity, visible reasons for detours |
| Skill Candy | 12 | 7 I / 4 II / 1 III; rare, black, personal ownership |
| Creature Candy | 72 | 42 Good / 24 Great / 6 Rare |
| Potions / revives | 40 / 20 | stronger detours, >=2 revives near Alpha and finale |
| Food / tonic / orbs / TMs / gear-story | 24 / 10 / 12 / 4 / 6 | adds to 200 pickups including candy |
| Main objectives | 28–32 | 3 acts, how text, actual count flags |
| Side chains | 6 | >=3 steps: stranded traveler, ruins, dock repair, trainer circuit, ecology, current mapping |
| Dialogue nodes | 150 | delivered at runtime; no catalogue-only count |
| New resources / recipes | 5 / 10 | Swim Saddle included; preparation supports crossing |
| Current channels | 10 | >=2 early, >=5 late; visual flow matches physics |
| Review points | 10 | arrival, human crossing, Reedhaven, Shellwatch, Alpha, mounted crossing, optional island, Veilfall shore, waterfall gate, Heart Chamber |

Counts are starting authored density commitments, not random uniform placements. Critical land-path maximum empty distance 120 m; average <=80 m. Water must present a decision/encounter/landing/landmark change within 45 seconds of passive travel; safer channels may be longer but remain readable. Off-route pickup positions must have a reason recorded in data. Census actual runtime placements, not unused config rows.

## 14. Progression and preparation

Six region bands: team 43→45, 45→47, 47→49, 49→51, 51→53, 53→55. Wild maximum <=regional exit; catch deficit within existing curve; no level scaling. Aquaryn 49, Tidecoil 54, captain ace 55. No creature HP inflation in place of encounter identity. Resources: reef_stone, driftwood, reed_fiber, tide_bloom, sluice_metal; use installed models and record replacement/provenance. Saddle cost starts 8 reed_fiber + 6 driftwood + 4 reef_stone, unlocked by Swim Stone. Ensure all materials and at least one alternative compatible species are accessible before the first mandatory mounted crossing.

## 15. Authority and persistence

Existing PlayerState/CharacterSave owns Skills, inventory/Candy, personal unlocks and character identity; existing host WorldState/ledger owns the realm key and gate unlock, docks, pumps, shared Alpha/finale resolution, pickups according to established ownership rules. Consume the Water key and open its gate in one validated atomic ledger transaction, never two independent flag writes. Do not invent a second session or authority service. Replicate aquatic mode, resource owner id, water surface, drowning feedback, mount anchor and combat transition through existing network presentation. Validate shared requests on host using actor realm/location, prerequisite and durable transaction identity. Never trust client-supplied XP deltas or arbitrary dock flags. Preserve water island/position, safe landing, stamina and mount identity across save/reconnect; spawn at validated surface/land, never below terrain. Old saves default cleanly; key migration distinguishes historical Cloudreach key from new Stormwood reward. Mixed-realm co-op is mandatory.

## 16. Scene and asset integration

Reuse realm scene/local_rig/camera/runtime/catalogue injection seams. Terrain3D terrain uses baked height/control/color maps and collision appropriate for distributed peers. Shore scatter is baked MultiMesh from installed nature family and excluded around landing paths. Read material scale in actual engine frames. Realm map pins/fog isolate water. Reuse installed humanoids and portraits by role. Every species and hero-object placeholder records data key, installed path, replacement asset destination, scale and material intent. Meshy order after broad playability: Aquaryn, Abyssal Guardian, Mosshell, remaining roster; no other generations. A lack of final art does not prevent gameplay work or permit final visual claims.

## 17. Audio and controller feedback

Ten cues: gentle shore, exposed surf, current rush, low stamina, drowning, mount exhaustion, aquatic combat transition, pump hum, waterfall proximity, finale/aftermath. Reuse installed assets where suitable with explicit placeholders. HUD distinguishes human/mount stamina and drowning health pressure; remains readable at 1280x720. Menu, candy selection, dock interaction, saddle equip and remount all work on controller, without mouse-only targeting.

## 18. Runtime evidence

Targeted unit tests for Skills XP/cap/candy transaction and migration; aquatic mode/drain/drowning/combat pause/current calculations; species compatibility; data/census constraints; key single-consumption; dock authority/prerequisites; Alpha defeat/catch alternatives; saddle recipe/equip; finale/ceremony/relic; world and personal reconnect serialization.

Smokes: water foundation real terrain/body, Skills menu controller path, Stormwood↔Water transition, human crossing and zero-stamina landing, alternate mount crossing, aquatic combat transition/remount, Alpha catch and no-catch reward, Veilfall full finale, old-save migration. Network smokes use real processes: split islands swimming/drowning, synchronized rider/mount, personal Candy ownership, shared docks/Alpha, mid-water reconnect, host/client different realm, late-join finale aftermath. Continuous chapter harness drives production interactions with a real body and earned flags; no debug flag writes as acceptance evidence. Full suite for autoload/save/net changes and each meaningful phase closure.

## 19. Visual and performance acceptance

Use tools/survey.sh or its verified Windows equivalent, never headless with a rendering driver. Capture production camera frames along the real route, blind judge against both owner boards and VISUAL_BIBLE. Coordinator never judges own frames. Only one render process for this machine across Stormwood/Water. Ten review points must be recognizable as the same commercial stylized game, not prototype primitives. Draw calls <=4000 and target-hardware budget per existing performance spec; do not substitute a headless boot for performance evidence. Materially change mechanism after two no-yield visual attempts.

## 20. Phases

0 (first two hours): preserve/sync/isolate, verify board PR ancestor, read directive/boards, audit seams, commit this plan plus numeric/island/authority data and weighted baseline. No separate design approval.
1: Stormwood transition integration and global Skills with controller menu, save and net ownership.
2: Terrain3D island foundation, Veilfall distant landmark, human swimming/drowning/current and safe landing; real split-peer collision and swimming proof.
3: First half docks/content/camps; Alpha and Swim Stone; recipe and alternative mount.
4: Mounted swim, outer islands, water combat/remount, Skill Candy, content density and Team Tether escalation.
5: hardest crossing, Veilfall hike/interior, officer/captain, legendary ceremony, Tideglass Compass/Tidal Guard, aftermath.
6: persistence/reconnect all islands, continuous path, balance, Meshy in authorized order if broadly playable, broad visual correction.
7: full-suite/CI/main verification, truthful census, report and fresh-session tail if necessary. Stage C becomes next action only once Stage B actually meets its gate.

## 21. Exit criteria

All require evidence on merged main: (1) earned Stormwood key opens Water once and return works; (2) first-minute board identity and Veilfall landmark; (3) level-0 human crossings fair and drowning readable/noninstant; (4) Skills improve through use, reveal in Biome 2, menu explains benefit; (5) currents visibly match push and create route choice; (6) varied docks run without invisible walls or flag bypass; (7) optional islands pay and census/gap rules hold; (8) Alpha has distinct land/water phases, catch and defeat both unlock saddle; (9) at least five compatible species differ and alternate mount can progress; (10) mounted stamina/exhaustion and five-slot choice matter; (11) water combat pauses drain, direct pilot/switch/catch/remount all work; (12) late crossings feel prepared expeditions; (13) Veilfall hike/reveal/interior follow board and directive; (14) captain/legendary/ceremony/relic/aftermath complete without console; (15) 1–4 player authority and separated islands work; (16) old saves and reconnect preserve all state without duplication; (17) controller/720p visuals and hardware performance pass; (18) full suite/CI code jobs/main ancestor proof and continuous evidence exist. Passing tests alone cannot stand for subjective route evidence.

## 22. Scorecard discipline

ralph/reports/WATER-PROGRESS/scorecard.md fixes 100 original-goal points. Re-score every two wall-clock hours from merged main plus passing runtime smokes/judged frames. >=10 strong; 5–<10 acceptable with next change named; <5 requires immediate strategy change; two consecutive <5 windows stop run, integrate completed verified work and leave §24 tail. Never a third near-identical attempt. Baseline time 2026-09-06 21:55:38 UTC; windows 23:55:38, 01:55:38, etc. Process/docs by themselves score zero.

## 23. Shipping and concurrency

Water isolated worktree D:/Tetherbound-source/.worktrees/water; root belongs to concurrent Stormwood. Both share repository refs: no root checkout/reset from Water. Stormwood owns first owner-board PR. Each independent lane gets owned files, current-main branch, smallest meaningful test, reviewed commit/PR, green CI code jobs, merge and merge-base proof. Never push main. Serialize game_state/world_state/net/config/autoload across both orchestrators. Verify subagent results directly. Rebase new Water waves onto newly merged Stormwood work without landing unrelated branches.

## 24. Final report / fresh-session tail

Current main SHA and ancestry; each system proven / implemented-but-unproven / blocked / deferred; scorecard history; actual census; exact placeholder replacement points and Meshy assets landed; tests/smokes/controller/visual/network/performance evidence; each blocker reproduction, failed approaches, strongest new hypothesis and P0/quality/performance/evidence severity; unmerged branches with disposition; next 3–5 bounded tasks. Update CURRENT_STATE, Water docs and roadmap to reality. Do not declare Stormwood or Water complete from this plan.


## Owner shipping update — 2026-09-06

Continue on ralph/water-foundation-0906 in the isolated Water worktree. The owner's newer instruction is to keep work on the branch and merge to main later. This overrides automatic merging in the original run directive. Commit/push and reviewable PRs remain permitted; do not merge Water PRs during this run. Record branch evidence separately from merged-main proof; never label unmerged work as present on main.
