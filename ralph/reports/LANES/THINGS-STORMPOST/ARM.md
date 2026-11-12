# THINGS-STORMPOST: wild creatures keep clear of named conversation posts in Stormwood (F41#15), with LANE-BELOW6's deck dressing riding along

LANE-THINGS, 12 Nov 2026. Branch `tb/things` (main a4ad0486 and `tb/below6-stormdeck-ride` 71f0f211b merged in). Coordinator go-ahead 07:21. CPU proof: `_sheet_stormpost_cpu.jpg` (main beside keep-clear, Nysa and Sera).

## Cause (G-below6-stormdeck and G-rescore-f41-15-main, 3/3)
"A huge saturated royal-blue bird creature fills almost the whole frame, Nysa a sliver behind it." On CPU the same: two wild birds flank Nysa and a wild Stormursa stands a metre from Sera. They are wild creatures idling on the trainers' posts; one is an authored roadside pair 9 m from Nysa.

## The arm
- **Flag `combat.json arena.wild_post_clearance_1112`** (OFF on the branch; ON in `overlay_arm.json`). In Stormwood, every trainer and character post (`stormwood_trainers.json`, `stormwood_npcs.json`; 45 posts) becomes a stand that wild spawns and wander targets keep 16 m clear of.
- **It reuses the shared director's existing rule** (`_clear_of_named_trainer_grounds`, `_out_of_named_trainer_grounds`: F04#2's keep-clear for Meadows captains). The Stormwood director only supplies its own posts and radius. One new virtual in `encounter_director.gd` (`_named_trainer_wild_clear_m`), which answers exactly as before for every other realm.
- **Scope, declared in the flag:** world presentation, host-authoritative. Spawn and wander placement is decided by the host through the path that already places them; clients receive positions from the host as before. No new network message, no save field.
- **Unchanged:** posts, encounter counts, tables, rewards. A spawn inside the radius is moved out, not dropped. A body already in a fight is not moved.
- **Radius:** 8 m was tried first (the coordinator's start value): Sera cleared, Nysa did not, because Stormwood's creatures are 4 to 6 m tall and the roadside pair stands 9 m out. 16 m clears both.
- **Riding along:** LANE-BELOW6's judged dressing (`deck_wood_warm_1112`, `banner_cloth_1112`, `aged_heartwood_1112`; +0.48 alone), ON in the arm and OFF in the base through `overlay_base.json`.

## CPU result
| Speaker | Main | Arm |
|---|---|---|
| Officer Nysa | two giant birds fill the frame either side of her | she stands clear at centre; two bears and a raven at mid-distance behind |
| Lieutenant Sera | a Stormursa fills the right half, a metre away | she stands clear; one small creature far behind |

Captain Marrow's and Tamsin's posts were not captured on CPU (each Stormwood run is 9 minutes a post); they are in the frame list.

## Not addressed
- The washed-out speakers and the player's head blooming white (3/3): not the conversation lights (tested, no change). Stormwood NPC presentation; parked arms cover it.
- The conversation clearance rule stays off in Stormwood (`exclude_realms`). With the posts clear it may now be safe to turn on there; that is a separate arm.

## Tests (CPU, headless)
`tests/test_stormwood_wild_post_clearance.gd` (4): ships OFF with host-authoritative scope declared; the posts cover every trainer and character; OFF changes nothing; ON refuses a wander target beside a post and pushes a spawn out to the radius while leaving distant spots alone. No co-op test is added because no network path is touched: placement runs where it already runs.

## Estimate
Above +0.5 on F41#15 (4.99) with the dressing: Nysa's frame is the one the judges say holds the row. Risk: 16 m round 45 posts also moves the roadside sightline pairs near posts, so a few road stretches show their creatures further from the road.
