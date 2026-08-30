# T1-CAST — the human cast as a set

Branch `ralph/T1-CAST` off `origin/ralph/LAND-0830I`. Owner directive mid-task:
*"ensure that the game is using all of the characters we generated in meshy
somewhere in the game where it's appropriate. not just reusing the same 3 NPCs
when we generated 25."* That directive redirects this lane away from the
bench-the-body fix T1-HALL-3 applied and toward using every installed rig.

## 1. What is installed vs what actually stands in the world

28 humanoid rigs are installed under `assets/characters/` and 31 keys in
`data/config/art.json` point at them. Counting real placements in shipped data
(`config_key` / `base` in `data/config/**`, not tests, not comments):

| Rig | Placements | Where |
|---|---|---|
| trainer | player | player body |
| grandpa | scene | Grandpa Elias |
| warden | boss | `stronghold_climax.gd` |
| villager_male / villager_female | 20 | every villager AND every non-Tether trainer |
| grunt | 3 | rank default for grunt/officer/captain |
| grunt_a / grunt_b / grunt_c | 3 / 3 / 2 | Tether rank-and-file, bands 1-5 |
| officer_a | 2 | Officer Dell, Warder Ness |
| captain_a / captain_b | 2 / 2 | Vance, Oreth, Halder, Vess |
| innkeeper, inn_helper, trader, craftsperson, creature_caretaker, farmer, local_historian, field_researcher, lost_traveler, alpha_tracker, courier, former_tether_member | 1 each | the twelve civilians placed this week |
| **officer_b** | **0** | **stranded** |
| **young_trainer** | **0** | **stranded** |
| **rival_trainer** | **0** | **stranded** |
| **wandering_trainer** | **0** | **stranded** |

**Four generated bodies stand nowhere in the game.** They are installed, baked,
wired into `art.json`, and never referenced by any placement.

## 2. Why they are stranded, and the second half of the defect

`officer_b` was the Warden's courtyard figure. JUDGE-5 D2 condemned it blind;
T1-HALL-3 fixed that by deleting the `base` override, which returned the
courtyard to the rank's shared `grunt` rig and left `officer_b` with no home.

The other three were never placed at all — and the reason is visible in the
data. **Every non-Tether trainer in the chapter is wearing a villager body:**

| Trainer | Role | Currently |
|---|---|---|
| `practice_trainer` Bryn | the chapter's first trainer fight | `villager_farmer` (villager_female) |
| `trainer_mira` / `trainer_oskar` / `trainer_tam` | the three village trainers | villager rigs |
| `tournament_quarter/semi/final` | the tournament ladder | the same three villager rigs again |
| `old_champion_bram` Old Bram | the retired champion | `villager_farmer` — the **female** villager rig |
| `pasture_drover_juno` Juno | the band-4 roadside trainer | `villager_ranger` |

Nine trainer fights, two bodies between them, while three purpose-built trainer
rigs sit unused. `old_champion_bram` on `villager_farmer` is also a straight
mismatch: the same character is `villager_keeper` (male rig) as a villager in
`village_npcs.json` and a female rig as a trainer.

## 3. The idiom split (JUDGE-5 D2, measured)

Measured over the alpha-masked, non-empty region of each atlas
(`docs`-free repro in this report's own commit):

| Group | median luma | mean lit RGB |
|---|---|---|
| production rigs (trainer/grandpa/warden/villagers) | 0.169 - 0.258 | warm, browns/olives/creams |
| `grunt` (Tether production rig) | 0.140 | (0.198, 0.143, 0.141) mauve-maroon |
| Meshy Tether cast (grunt_a/b/c, officer_a/b, captain_a/b) | **0.086 - 0.114** | purple-black, no oxblood |

The seven Meshy Tether bodies are a different rendering language: crushed
near-black grounds, saturated purple-magenta accents, blown-out flat faces with
painted eye/mouth, and hair as a solid magenta mass. That is what the blind
judge read as "from a different game" — and it is a property of the seven
atlases, not of the one figure that happened to be standing in the courtyard.

