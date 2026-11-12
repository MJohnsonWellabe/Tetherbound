# THINGS-STORMPOST-LAND: wild creatures keep clear of named conversation posts in Stormwood; ships ON (F41#15)

STATUS: land (together with `tb/below6-stormdeck-ride` 71f0f211b, which was judged in the same arm)

- **Branch:** `tb/things-stormpost-land`, cut from `origin/main` a4ad0486.
- **Verdict (LANE-SCOUT):** `G-things-stormpost.md` (`tb/item-scout-1108` b3ff7d0d), GPU High.
  - **F41#15: 5.13 → 6.97 (+1.84)**, 3/3 prefer the arm; the obstruction defect is FIXED 3/3 (Nysa from "almost completely hidden" behind two giant birds to "clear and centred").
  - Sera and the two Tamsin frames: 5.79 → 6.97 (+1.18), 3/3.
  - Inventory controls: level (5.60 → 5.60).
  - GPU pre-check: nearest wild creature to the speaker 16.8 m (Nysa), 26.3 m (Sera), 16.5 m (Tamsin); on main 1.6 to 4.1 m.
  - The arm was judged with LANE-BELOW6's deck dressing ON; that code is **not** on this branch. It lands from their ride branch in the same PR.
- **What ships (game):**
  - `data/config/combat.json arena.wild_post_clearance_1112` ON with `_why_on`: Stormwood, 16 m.
  - `scripts/combat/stormwood_encounter_director.gd`: with the flag on, Stormwood's 45 trainer and character posts are the stands the shared director keeps wild spawns and wander targets clear of.
  - `scripts/combat/encounter_director.gd`: one virtual, `_named_trainer_wild_clear_m()`, answering exactly as before for every other realm.
- **Scope (declared in the flag):** world presentation, host-authoritative. Placement is decided by the host through the path that already places wild creatures; clients receive positions as before. No new network message and no save field. Posts, encounter counts, tables and rewards are unchanged; a spawn inside the radius is moved out, not dropped; a body in a fight is not moved.
- **Test added:** `tests/test_stormwood_wild_post_clearance.gd` (4): ships ON with the host-authoritative scope declared; the posts cover every trainer and character; OFF changes nothing; ON refuses a wander target beside a post and pushes a spawn out to the radius while leaving distant spots alone.
- **Older pins checked:** grepped `tests/` for the named-trainer keep-clear functions and the Stormwood director. Ran `stormwood_wild_post_clearance` 4, `named_trainer_wild_clear` 3, `road_creature_visibility` 6, `stormwood_encounter_catalogue` 7, `band4_upper_meadows` 8, `water_trainer_ring_clearance` 2, `cloudreach_encounters` 7: 37 tests, 0 failed.
- **Not run:** the Stormwood smoke scenes (`smoke_stormwood_finalized_death.gd`, `smoke_stormwood_hosted_rewards.gd`). They load the whole realm and take longer than a CPU turn here allows. Because this changes where wild creatures stand in Stormwood, I recommend the PR carries `full-ci`.
- No texture is touched. No `.uid` files are included.

## Known side effect
The moved creatures settle just past the radius. In Nysa's frame two Stormravens and two bears stand about 17 m behind her (the judges read it as "staged behind her"). If a later round calls that busy, a larger radius for her post is the lever.

## Still holding F41#15 back (3/3, both sides)
The player at the left edge is blown out to white in every Stormwood dialogue frame and Marrow's hair blooms white. It is not the conversation lights (tested on CPU, no change). Clamping that bloom is the next step toward 7.5.
