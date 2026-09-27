# F13#2: the `reed_root_hollow` recipe half, and per-character pocket claims in co-op

The coordinator (owner direction) asked for the recipe half of pocket `reed_root_hollow` (role `recipe_and_reed_fiber`) to be paid. The addendum also asked for evidence that in co-op each character claims its own pockets.

## Choice: Reed Camp Cordage (`water_camp_cordage`)

The cordage recipe turns 2 reed fiber into 6 ordinary fiber. Its blurb is "bedding, camp ties and repairs", which fits a reed hollow that supports the pier repair.

Nothing on a mandatory path needs it. In `git grep HEAD` over the whole tree (outside `ralph/reports`), the only mention of `water_camp_cordage` is its own data row. It has no harness, smoke, ledger test or PROGRESSION budget. The Reedhaven dock repair takes raw `reed_fiber`/`driftwood`, not fiber, and ordinary fiber still comes from earlier chapters and `cloudreach_camp_cordage`.

The other candidates were rejected:
- `water_camp_boards` is used by `smoke_water_camps.gd`.
- `water_small_potion` is used by the four-character ledger.
- The medicines are not coherent with a reed hollow.

## What changed

**Data**
- `water_crafting.json`: cordage now has `unlocked_by` and `requires_personal_flags` set to `water_cordage_recipe_learned`.
- `water_pickups.json`: row `water:reedhaven:harvest:012` now has `claim_policy: character_once` and `learn_recipe_flag`. This matches the pocket's declared `claim_authority: host_validates_character_owned_pickup`.
- `flag_scopes.json`: two new **player** ids, `water_cordage_recipe_learned` and `water_cordage_recipe_gated`.
- `water_authority.json`: a new `cordage_recipe` row.

**Host rule** (`water_personal_pickup.gd`)
- `personal_row()` also accepts `character_once` harvest rows.
- The grant uses the authored `yield`; the request's amount is ignored. When a row has `learn_recipe_flag`, the host adds a player flag op addressed only to the claiming peer.
- The existing receipts do the rest: world receipt `water_claim:<character>:<row>` and portable receipt `water_candy:<row>`.

**Runtime**
- `harvest_node.gd` has three overridable seams: `_already_taken`, `_claim_intent` and `_claim_committed`. Their defaults behave exactly as before.
- `water_scene_pickups.gd::PersonalHarvest` keeps the knife/tool rules and submits `water_personal_pickup`. Only this viewer's own receipt retires it, and a guest's refusal releases the press.
- The unlock is consumed by `GameState.recipe_known`, `can_craft` and `known_recipe_ids` (the craft panel list).

**Migration** (`scripts/save/water_recipe_migration.gd`)
- A character with `water_chapter_started` but no gate marker knew cordage before this change. It is granted `LEARNED` and the marker is stamped.
- Every arrival stamps the marker, so a new character never gets cordage for free.
- The repair is pure and idempotent, and never removes a flag.
- It runs in `PlayerState.load_data`, in `save_game.load_slot` and at arrival.

## Evidence

| Check | Command | Result |
|---|---|---|
| Unit, before | `--script tests/run_tests.gd -- --only=water` / `tidewake` / `craft` | 422/0 failed, 10/0, 8/0 (`unit_before_*.log`) |
| Unit, after | same | **427/0** (5 new in `test_water_reed_recipe.gd`), **10/0**, **8/0** (`unit_after_*.log`) |
| Related | `--only=test_recipes,test_flag_scopes,test_progression_state,test_save,test_character_save,test_player_state,harvest,pickup` | 346 tests, 0 failed (`unit_after_related.log`) |
| Reed walk smoke | `godot --headless --path . --fixed-fps 60 --script tests/smoke_water_pocket_walk_claim.gd -- --only=reed_root_hollow` | `gains={reed_fiber:3} recipe_before=false recipe_after=true listed=true result=PAID`, 11 checks, 0 failures (`smoke_reed_only.log`) |
| Streamer smoke | `--script tests/smoke_water_scene_pickups.gd` | 26 checks, 0 failures (`smoke_water_scene_pickups.log`) |
| Two-peer co-op proof | `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/f13_tidewake_b_reed_recipe_two_character_pockets.json` | **21/21 steps PASS, exit 0** (`net_proof/PROOF.md`, `net_proof/run.log`, `net_proof/saved_excerpt.txt`) |

`test_recipes.gd`'s writer check now also runs the production host rule, which is the writer for `learn_recipe_flag`.

What the two-peer proof shows:
- Neither fresh character knows cordage at chapter start.
- The host gathers the hollow with the real prompt and an equipped knife. It gets +3 fiber and cordage becomes known (false → true).
- The guest is not paid and learns nothing from the host's claim. The patch is still offered to the guest, who gathers its own +3 and learns cordage.
- A repeat request from either character (hand-made, denying its own receipt) is refused `already_taken` and pays nothing.
- The same holds for a second pocket, `lantern_hidden_cache` (Skill Candy I).
- Both saved characters hold `water_cordage_recipe_learned` and their own receipts.
- The host world file holds 4 per-character receipts and no cordage flag.

## Shortcuts and fixtures (disclosed)

- **Smoke:** a carried knife and pickaxe, and a position write to the arrival landing. Both are unchanged from before.
- **Two-peer proof:** each peer gets a knife via `storage_grant`, bound to hotbar slot 5 by the step and equipped with a real `hotbar_5` press. Each trainer is **teleported** beside the body instead of walking. Both peers start in the Water scene. The run is loopback ENet, not internet or Steam.
- **Legacy saves:** a character that had already gathered the old world-once patch (flag `harvest_node:order:water:reedhaven:harvest:012`) is not credited with the new personal receipt, because the save does not record who gathered it. Such a character may gather 3 fiber once more. The recipe itself is migrated.
- **Four-character ledger:** the now-personal patch is still counted once, which is conservative.
- **STATE.md** was not updated in this worktree.
