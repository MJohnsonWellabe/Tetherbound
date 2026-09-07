# Water density census — wave 2 branch snapshot

Read-only audit at 2026-09-07 01:15 UTC of `ralph/water-foundation-0906`. Counts below were recomputed from source rows, not accepted from embedded census metadata. This is working-tree evidence; it claims no merge, visual acceptance, completed chapter, or continuously playable archipelago. Runtime changes are still underway.

| Category | Authored actual / BUILD target | Runtime evidence and limit |
|---|---|---|
| Islands / regions | 12 (8 main, 4 optional) / 12; 6 / 6 | WaterWorld loads 30 baked Terrain3D regions. Terrain presence does not prove all islands reachable. |
| Landmarks | 18 / 18 | Composition coordinates and map labels; no evidence that 18 distinct landmark objects exist or communicate their identity in play. |
| Land spines / loops | 12 / 4 | Recomputed 3D polyline lengths: 7,540.146 m + 3,486.382 m = 11,026.528 m; **0 m credited toward 8 km continuous walked target**. Sampled grades are not walked distance. |
| Water links / alternatives | 11 unique edges, 22 route polylines | Sheltered routes recompute to 1,985.674 m main + 1,246.141 m optional. These are planned distances. A separate 60.143 m lesson swim is actually exercised; no inter-island continuous chain is credited. |
| Anchors / current channels | 24 / 22 (current target at least 10) | Analytic flow is live and one dock smoke checks closed/open current strength. No accepted visual-current readability census. |
| Return shortcuts / reward pockets | 3 / 8 | Authored rows, no continuous traversal proof. |
| Dock actions | 7 fixed interactions + 3 derived completions | Real Reedhaven repair and two Shellwatch actions exercised by production smoke; 6 authored dock unlock flags, not 11 separately demonstrated gates. |
| Wild sites / tables | 240 / 240; 16 / 16 | Live director streams at most 16 wild actors per peer within 100 m. Smoke proves actual First Shore and distant Salt Crown bodies. It does **not** instantiate or physically validate all 240 sites. |
| Named encounters | 5 optional + 1 scripted Alpha / 6 | Adapter translates these rows, but the inspected Water director spawns random site tables only. No named encounter or Alpha execution evidence in this snapshot. Guardian is a separate scripted release reference, not a seventh fought named encounter. |
| Trainers | 24 / 24: 12 critical, 12 optional | Production smoke asserts all 24 trainer nodes and three shared greeting bodies, then starts Lysa's real battle. It does not finish 24 battles or prove the ladder reachable in order. |
| Named NPCs | 18 / 18 | Production builder and NPC smoke cover all 18 grounded bodies/prompts. The inspected encounter log supports the three reused identities. NPC smoke source has 55 checks, but this audit did not locate its completed log and does not independently certify that run. |
| Unique human bodies | 39 | 18 NPC + 24 trainer roles minus Tovin/Venn/Nerissa reuse = 39 intended production bodies. Individual body counts are tested separately; no continuous 39-body world tour. |
| Pickups / harvest | 200 / 200; 160 / 160 | Pickup smoke instantiates all identities in an **analytic-ground fixture**, with 198 pickups + 159 harvest remaining after three exercised claims. This is not all-object Terrain3D footing or accessibility proof. |
| Skill Candy | 12 / 12: 7 I, 4 II, 1 III | All three tiers are registered; pickup smoke claims one personal Candy and checks receipt/reconstruction without awarding XP on collection. No entire distribution collected through ordinary play. |
| Other pickups | 72 creature Candy, 40 potions, 20 revives, 24 food, 10 tonic, 12 orbs, 4 TMs, 6 gear/story | Counts recomputed from the 200 placement rows. Creature Candy is 42 Good / 24 Great / 6 Rare. Detour quality and >=80% off-critical-path target remain unmeasured. |
| Dialogue | 111 conversations, 168 line entries / at least 150 delivered nodes | Runtime adapter supplies conversations. Tested sample speech is not evidence of all 168 entries delivered; do not equate a line entry with a complete objective/dialogue node. |
| Main objectives / side chains | 12 / 28–32; 0 explicit local objectives / 6 chains | Ordered Water quest feed exists. No complete three-act objective chain or six three-step side chains is implemented by those rows. |
| Resources / recipes | 5 / 5; 10 / 10 | ItemDB integration registers five resources, three Skill Candy items and one Swim Saddle. Recipe registration is not ordinary unlocked crafting proof. |
| Camps / settlements | 0 accepted / 8 camps, 3 settlements | At audit time WaterWorld had no camp, workbench, shop or settlement builder. Parent is implementing eight camps after this snapshot; reserve credit until actual builder and rest/craft smoke evidence arrive. |
| Veilfall interior / finale | 0 accepted | Mountain exists; waterfall entrance, functioning channel/pump/sluice interior, captain finale, Guardian release/ceremony, Tidal Guard and relic have no accepted end-to-end evidence here. Generic Nerissa trainer presence does not establish the finale. |

## Per-island authored distribution

Trainer counts include the three shared NPC roles. These are placement rows, not proof of reachability or encounters per minute.

| Island | NPC | Trainer | Wild sites | Pickups | Harvest |
|---|---:|---:|---:|---:|---:|
| First Shore | 3 | 1 | 30 | 22 | 20 |
| Reedhaven | 2 | 2 | 30 | 22 | 24 |
| Brine Steps | 2 | 2 | 24 | 20 | 18 |
| Shellwatch | 2 | 3 | 24 | 20 | 18 |
| Tidal Cradle | 2 | 2 | 28 | 20 | 12 |
| Salt Crown | 2 | 2 | 28 | 22 | 18 |
| Sluice Isle | 2 | 3 | 24 | 20 | 20 |
| Veilfall | 3 | 5 | 20 | 14 | 6 |
| Lantern Cove | 0 | 1 | 8 | 8 | 4 |
| Gull Rest | 0 | 1 | 8 | 6 | 2 |
| Drowned Garden | 0 | 1 | 8 | 14 | 12 |
| Deep Watch | 0 | 1 | 8 | 12 | 6 |
| **Total** | **18** | **24** | **240** | **200** | **160** |

The total harvest target masks a distribution failure against BUILD §13: Tidal Cradle (12) and Veilfall (6) fall below 14 per main island; Lantern Cove (4), Gull Rest (2), Deep Watch (6) fall below 8 per optional island. These five deficits require 22 relocated/additional useful nodes in total. Maintain resource preparation and detour purpose rather than filling counts with arbitrary objects.

## Inspected evidence and reproduction

No new Godot process was launched for this audit. Existing logs were read alongside the smoke source. Invoke a smoke from the Water worktree with the installed Godot console executable, `--headless --path . --log-file <isolated-log> --script res://tests/<smoke>.gd`; use the existing isolated Water user-data override, never a live player save.

- `smoke_water_scene_pickups.gd`: `C:/Users/mattj/AppData/Local/Temp/water-pickup-material-fix.log` reports **23 checks, 0 failures**, final active counts 198/159 and no registration/ground errors. It raises residency radius/cap to force remaining objects into its analytic fixture. It tests one ordinary pickup, one harvest and one personal Candy, plus a simulated distant Water peer; no network transport claim.
- `smoke_water_scene_encounters.gd`: `C:/Users/mattj/AppData/Local/Temp/water-encounters4.log` reports **28 checks, 0 failures**. Teleported player and remote-proxy fixtures test actual production spawning, three reused bodies and Lysa battle start. No all-site count is logged, no battle finish is claimed.
- `smoke_water_dock_actions.gd`: `C:/Users/mattj/AppData/Local/Temp/water-dock-actions-smoke.log` reports **32 checks, 0 failures**. Real interaction activation charges 6 reed fiber/4 driftwood once; physics rays verify gate removal/restoration; production saves preserve closed/open state and actual current strength. Lesson and trainer victory flags are explicit fixtures. No continuous route or separate-peer dock evidence.
- `smoke_water_swimming.gd`: `C:/Users/mattj/AppData/Local/Temp/water-integrated-lesson.log` reports **19 assertions**, actual **60.143 m** lesson swim. This log predates the later save-extension revision of that smoke.
- `smoke_water_scene_npcs.gd`: inspected source covers grounded bodies, prompts, Mara/Pell/Iona conversations and guards; completed output was not located in this audit.
- `smoke_water_mounted_swimming.gd`: latest inspected `water-mounted-smoke5.log` ends in an Aquaryn movement timeout. Root is investigating; it supplies no passed five-mount density/traversal claim.

The fresh next useful density test is an ordinary First Shore arrival → Pell briefing → real lesson → gather exact Reedhaven repair materials → first crossing → repair → rest/craft at the new camp segment, without teleporting or setting progression flags. Record path metres, elapsed travel, visible/usable encounters and resources, every empty interval, prompt usability, inventory/tool prerequisites, and the next objective. This directly tests the first meaningful preparation/progression loop and the camp dependency that a total-row census cannot establish. Then extend the same harness island by island; do not inflate its verified distance with planned polylines.

Several config status strings still say “not runtime spawned/registered” despite live adapters. They are stale descriptive metadata, not stronger evidence than the source and logs above; reconcile them after the wave is verified.

## Camp integration evidence after the initial snapshot

Root subsequently added `water_camps.json`, `water_camps.gd` and the WaterWorld builder call. `smoke_water_camps.gd` then completed **129 checks, 0 failures**, exit 0, logged at `C:/Users/mattj/AppData/Local/Temp/water-camps-smoke.log`. This supersedes only the earlier missing-camp/workbench observation: all **8 camps** now instantiate real shelter, bedroll, workbench, fire and creature-bed components on dry baked Terrain3D; eight unique reserved creature-bed indices are assigned, and each camp exposes both rest and craft offers from sampled nearby ground.

At First Shore, a real CraftPanel button converted **2 driftwood into 6 wood** using an explicit inventory/arrival-unlock fixture. Activating the real rest prompt passed exactly one day (1→2), recorded the existing rest flag and ran the production NightRest autosave path. An additional explicit SaveGame save/load restored day 2. The smoke does not reload the automatically written checkpoint itself, exercise multiplayer sleep voting, test creature recovery assignment, earn the recipe through story, or walk between camps. Camps are runtime preparation services now; settlement shops and complete chapter journeys remain unproven.

The teleported camp tour also emitted `Water site lacks supported creature footing: water_brine_steps_wild_010`. Preserve that as a concrete all-site placement gap: the 240-site catalogue is not 240 proven viable spawns.



## Wave 3 harvest distribution correction (configured and analytic only)

Added 22 stable harvest identities: Tidal Cradle +2 (14), Veilfall +8 (14), Lantern Cove +4 (8), Gull Rest +6 (8), Deep Watch +2 (8). Total is now **182 configured harvest nodes**, with 200 pickups unchanged. JSON comparison against HEAD confirms all original 160 harvest records and all 200 pickup records are unchanged. All twelve islands meet BUILD section 13's configured harvest minimum. Original validation hashes describe the old placement pass, not these additions.

Nodes offer saddle materials on Tidal Cradle, repair/fuel and recovery ingredients on optional detours, and salvage/recovery resources before the Veilfall hike and Deep Watch approach. Additions store analytic approaches, leave >=6 m from land-route centerlines, >=6 m from other resources/pickups, >=12 m from landing centers, and were selected outside 10 m NPC/trainer/camp exclusions. Tidal additions remain >120 m from the planned Alpha basin at (601,1389).

Straight route spokes could not provide every Veilfall position. Three final nodes instead use stored 2 m grid paths flood-filled from a safe landing, with midpoint checks. Footprints and approach samples are dry (>=0.8 m) and within the existing <=35 degree harvest grade limit. These connect to authored routes/landings analytically; **no continuous walked or baked Terrain3D footing evidence** is claimed. No visual or gameplay density acceptance is awarded.

Verification: `tests/test_water_harvest_density.gd`, actual Godot **1 test, 9,678 assertions, 0 failed**, exit 0, no script errors. Log: `C:/Users/mattj/AppData/Local/Temp/water-harvest-density-console.log`. Covers identities, minimum counts, footprints, sampled approach grades, resource/landing/path clearance and Alpha exclusion. NPC/camp exclusions were checked by the generator, not this test. Re-run after terrain composition changes. Actual-world residency, harvesting, multiplayer claims, readability and route tours remain required.

Analytic source hashes at this run:

- `scripts/world/water_heightfield.gd`: `d8d5fb7fb59c9bdd6bb16bc3c6b7450d89206ff6afec9aca702be098f14ebf6c`
- `data/config/water_world.json`: `a2fca1bf27c6d896be547633b2bb18c71942834347a918fa305c99b3e3c32740`

| Stable ID | Resource | X, Y, Z (metres) |
|---|---|---|
| water:tidal_cradle:harvest:013 | reed_fiber | 795.114, 56.190, 1651.888 |
| water:tidal_cradle:harvest:014 | driftwood | 804.943, 60.073, 1645.005 |
| water:veilfall:harvest:007 | driftwood | 390.962, 2.856, 3818.202 |
| water:veilfall:harvest:008 | tide_bloom | 369.940, 2.856, 3806.623 |
| water:veilfall:harvest:009 | reef_stone | 362.933, 2.728, 3802.762 |
| water:veilfall:harvest:010 | sluice_metal | 395.074, 3.853, 3827.318 |
| water:veilfall:harvest:011 | driftwood | 381.844, 12.530, 3837.360 |
| water:lantern_cove:harvest:005 | reed_fiber | -359.048, 13.999, 128.966 |
| water:lantern_cove:harvest:006 | driftwood | -358.792, 18.123, 116.968 |
| water:lantern_cove:harvest:007 | reed_fiber | -358.536, 16.510, 104.971 |
| water:lantern_cove:harvest:008 | driftwood | -371.045, 14.598, 128.710 |
| water:gull_rest:harvest:003 | reed_fiber | -97.800, 15.596, 817.863 |
| water:gull_rest:harvest:004 | driftwood | -102.943, 17.393, 807.021 |
| water:gull_rest:harvest:005 | tide_bloom | -106.372, 15.077, 799.793 |
| water:gull_rest:harvest:006 | reed_fiber | -108.642, 17.247, 823.006 |
| water:gull_rest:harvest:007 | driftwood | -113.785, 16.950, 812.164 |
| water:gull_rest:harvest:008 | tide_bloom | -117.214, 14.725, 804.936 |
| water:deep_watch:harvest:007 | tide_bloom | 1274.558, 2.803, 3400.861 |
| water:deep_watch:harvest:008 | sluice_metal | 1256.948, 2.803, 3417.167 |
| water:veilfall:harvest:012 | tide_bloom | 398.000, 1.256, 3806.000 |
| water:veilfall:harvest:013 | reef_stone | 380.000, 1.069, 3794.000 |
| water:veilfall:harvest:014 | sluice_metal | 396.000, 1.918, 3812.000 |
