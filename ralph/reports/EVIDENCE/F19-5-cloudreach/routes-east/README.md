# F19#5 Cloudreach 05 → 07 (routes-east)

US Central, 2026-10-11. Branch tb/ev-cloudreach-xp. Runner: `tools/earned_saves/cloudreach_chain_runner.gd` (1x clock). All starts are disclosed generated boundaries from `tests/fixtures/earned_saves/generated_boundary_profiles.json`, five creatures at L40, NOT earned.

| Piece | Commit | CT | Start | Result |
|---|---|---|---|---|
| 05 stronghold | 66d3634c45 | 12:55–13:31 | `cloudreach_stronghold` (earned 04 flags/pose) | Voss WON (74/24 hits, 1015/1152 dmg); FAIL at the bivouac exit |
| 05b summit tail | 8818a47b37 | 16:26–16:33 | `cloudreach_summit_bivouac` (post-summit-feed pose) | PASS; bivouac rest day 20→21, threshold reached, 0 sidesteps |
| 06 Veyra + relay | 8818a47b37 | 16:34–16:55 | 05b checkpoint | PASS; Veyra WON (62/17 hits, 1088/847 dmg, 3 standing) |
| 07 Stormward handoff | 8818a47b37 | 16:55–17:06 | 06 checkpoint | PASS; portal leg ok, ends in Stormwood |

Fixes that took 05 from FAIL to PASS:
- **World:** `waystones.json` cloudreach_summit_bivouac offset_xz (0,−7) → (0,+5), arrival (0,3) → (0,−3), commit 54cb885234. The shrine had stood in the terrace's only exit band (z 5330–5332). A collider probe showed +5 touches only the floor; +7 cut into Ridge000.
- **Helper (disclosed alignment):** `_leave_summit_bivouac` first waypoint (132,1160,5330) → (130.5,1160,5331.5), commit 8818a47b37. The old waypoint lay south of CampLipRail RailCollider0.
- **Tried and reverted:** a west exit straight to the threshold. It meets the SummitEyrieStronghold wall at x≈126.

Checks: waystone/travel unit tests 26/26; `smoke_cloudreach_summit_lip_rail` PASS.
Files: receipts and gzipped logs for 05 (Voss), 05b, 06 and 07 are beside this README.
Not proven: an earned (non-generated) L40 arrival.
