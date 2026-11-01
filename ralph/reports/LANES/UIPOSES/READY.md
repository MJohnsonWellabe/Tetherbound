# UIPOSES lane (UI + creature/trainer pose rows) — READY

Branch `tb/vis-ui-poses`. Coordinator update (1 Nov): no single-candidate READY lines; every candidate is listed in `MANIFEST.json` for the 18:00 UTC batch (tb/vis-batch1, all flags ON). Each flag is OFF on this branch and only touches its own keys.

## Candidates in the batch (CPU sanity capture done for each unless noted; no CPU scores claimed)

| Flag (default OFF) | Items | What changes | CPU check |
|---|---|---|---|
| `data/config/capture_readout_visual.json:readout_side_enabled` | P2-058, P2-114, P2-117 | Catch percentage + caption sit beside the ring on the existing plate (flips left near the edge), number +6 px; the target body is clear | Meadows + Tidewake catch: readout beside ring, no clipping |
| `data/config/hud.json:catch_card.enabled` (existing, never GPU-judged; tuned) | P2-061, P2-117 | One framed outcome card (52 px headline + traits); on success the fight cards, action bar and roster step back **on the card's first frame** (they stayed up for the verdict frame before) | Meadows + Tidewake 08/09: one card, HUD cleared |
| `data/creatures/f36_pose_candidates.json:lane_role_flags.uiposes_riptusk_side_faint_prone_rest.enabled` | P2-028, P2-029 | Riptusk (land + Water): faint rolls onto its side with head dropped (posed-vertex grounded); new prone rest (legs folded, head low, no roll) replaces the belly-up roll | Tidewake creatures: faint reads as down, rest as settled |
| `data/config/hud.json:victory_focus.enabled` | P2-103, P2-111 | While a Moment banner is up, quickbar/legend/roster/creature card/prompt step back; named-trainer acknowledgements become the victory Moment receipt instead of the quickbar message strip | Unit + HUD lifecycle smoke only (fight captures too long on CPU) |
| `data/config/menu.json:satchel_focus.enabled` | P2-001 | Satchel: focused item icon on its own lit round plate, item name in the warm heading accent at 36 px, description in TEXT_PRIMARY at the 27 px reading floor | Meadows UI (pad): visible, no clipping |
| `hud.json:catch_card.calm_seal` (rides `catch_card.enabled`) | P2-061 | Sealed orb emission and halo calmed so it reads as the gold orb, not a white blob, under the result card | Meadows 09: gold orb with band visible |
| `data/config/fly_traversal.json:hang_pose.body.enabled` | P2-119 | Carried trainer's legs trail back with bent knees (one further), torso leans into flight; arms still aim at the grip | Meadows flight: no clipping, legs no longer a straight ladder hang |

Head at writing: d500bf979a2c135f1a567f60fa788282c8bcb59d. Tests: `tests/test_capture_readout_side.gd`, `test_uiposes_riptusk_pose_flag.gd`, `test_uiposes_victory_focus.gd`, `test_uiposes_fly_hang_body.gd` (all pass), plus `test_trainer_reward_delivery`, `test_human_swim_visual`, `smoke_hud_presentation_lifecycle` (pass).

## Parked / not built

- **P2-015 (Terrapup/Veridian faint):** a generic side-lie roll was built and removed: on current main their baked faint clips already lie on their side (CPU frame), and the roll stood them back up. **Pre-existing capture defect:** `phase2_capture_creatures.gd --only=terrapup --poses=resting` fails on main ("authored rest did not complete before capture"), so the GPU set is missing `meadows__terrapup__resting`.
- **Cloudreach catch (P2-117/P2-118) on CPU:** \`phase2_capture_catch.gd --biome=cloudreach\` fails "could not enter combat" (the known CR-CANDY fixture: the candy pickup wins the interact). Take the candy first, as the GPU queue notes say.
- **victory_focus (P2-103/P2-111):** the CPU Hollows capture timed out at fight t=40 s (40 min limit) before the win frame, so this flag has unit-test and HUD-smoke evidence only.
- **P2-016:** failed on GPU twice (TECHNICAL §8.1); parked until a new idea.
- **P2-004, P2-001, P2-007, P2-031:** many judged rounds already (hud_lean OFF at 6.41 < 6.71); no new idea that clears +0.5 today.
- **P2-081/082/084 (dialogue staging), P2-091 (arena crystal slab), P2-108/P2-105/P2-071 (traversal poses), P2-095/096 (craft-r3 queued):** other lanes or not UI-fixable here.
