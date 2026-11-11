STATUS: land
BRANCH: tb/newapproach-postset-land (cut from origin/main e6fdca29)

# F40#9 authored NPC posts — READY (setting only, no post camera)

**Verdict:** GPU High, `G-newapproach-post-setting` (tb/item-scout-1108 22102b6be): F40#9 5.32 -> 6.48 mapped, +1.16, 3/3 prefer, with today's camera (side `setonly`). Defect PRESENT -> PARTIAL 3/3. The board had F40#9 at 5.72.

**Files (5):**
- `data/config/cloudreach_npc_runtime.json`
- `data/config/cloudreach_physical_runtime.json`
- `scripts/world/cloudreach_npc_posts.gd`
- `tests/test_post_setting_landed.gd` (new)
- `ralph/reports/LANES/NEWAPPROACH-POSTSET/READY.md`

**What ships:**
- `post_dais`: stone `#8d8877` (was `#5f5c50`), and an installed round paving piece capping each disc (`cap_scene`, `cap_overhang` 1.15, `cap_tint` `#8f8a7a`).
- `post_role_props.posts`: a structure behind each NPC, added to the side props already there. Tavi: workbench and peg rack. Sora: bookcase, table and books. Maela: table with a cage, and a shelf.
- `post_readability.fill_light`: energy 0.7 -> 1.3, range 4.5 -> 6 m, offset `[0.9, 2.3, 1.5]`, `shadow` true.
- `npc_position_overrides.naturalist_sora`: `[1100, 1050, 2953.5]` (3.5 m along the wall line, clear of the corner).
- `cloudreach_npc_posts.gd`: the three options these values use (`cap_scene` with `cap_overhang`, `cap_tint`, `fill_light.shadow`). Each does nothing when its key is absent. The file is the lane branch's copy; its only difference from main is these 30 lines.
- Each config block carries a note citing the verdict: `_why_on_setting` in the three npc_runtime blocks, and `_why_on_npc_position_override_naturalist_sora` at the top level of the physical file (outside the override map, which holds only NPC ids).

**Not in this landing:** `camera_rig.gd` and the `camera.json post_focus` block. The post camera added nothing measurable on top of the setting and stays flag-off on `tb/newapproach` for the owner's decision. The new test asserts `post_focus` is not enabled.

## Tests run (11 Nov, with the baked config)
One unit run, `--only=` the six files: 46 tests, 1059 assertions, 0 failed.
- `test_post_setting_landed` (new, 5 tests)
- `test_near6_cr_judged_on`
- `test_vis_cloudreach_landed`
- `test_cloudreach_route_cadence`
- `test_cloudreach_route_ledger`
- `test_bridge_view_landed`

`tests/smoke_cloudreach_physical_placements.gd`, headless, on its own: "223 checked, 0 failures", exit 0, with Sora at her new position.

How they were run: this branch is a sparse checkout, so the tests ran in the lane's `tb/newapproach` checkout with this branch's two config files and the new test copied in. That checkout's `cloudreach_npc_posts.gd` is the same file as here. The existing test files there are the lane branch's copies, not re-read against main's.

## Gaps
- The new test has no `.uid` file; the next import creates it.
- Sora's quest and dialogue were not played at the new position. They key on her id, by the config I read.
- The added structures have no collision (the existing role-prop rule), so a player can walk through a table.
- The shadow-casting light was judged on GPU High only. Medium was not captured.

## Judges' follow-ups (what holds F40#9 below 7)
- The NPCs are small on screen, smaller than the trainer and partly overlapping him (Tavi and Maela); no pose signals a job.
- Mixed assets around the posts: saturated orange dirt path and big cartoony trunks beside pale Cloudreach stone.
