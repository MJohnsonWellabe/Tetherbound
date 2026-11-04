# NEAR6-TW lane (tb/near6-tw-1104): Tidewake F39 items scored 5.4–6.0, CPU quick-judged

Owner rule (4 Nov): any judged CPU gain ships ON; only flat or worse stays OFF. Yardstick: `tools/visual_judge/quick_judge.py` (JUDGE_PROMPT verbatim, 3+ anchor pairs, 3 fresh code-blind judges, calibrate.py), with VIS-TIDEWAKE's `water__` frame-lookup patch applied locally (`runbook/` uses it; not committed here to avoid a conflict with tb/vis-tidewake-1104).

## Landing-ready flags

| Flag | Row | CPU base -> cand | Test | Commit |
|---|---|---|---|---|
| `water_character_rim.json` `enabled` (Tidewake named NPC/trainer rim + front fill) | F39#27 | CPU 6.03 -> 6.23 (3/3 judges higher; anchor RMSE 0.79 caveat) | `tests/test_near6_tw_judged_on.gd` (+ `test_creature_rim`, `test_texture_import_policy`: 7 tests, 0 failed) | this commit |
| `human_water_contact_visual.json` `wake_trail.enabled` (longer, spreading trail rings) | F39#14 | CPU 6.10 -> 6.80 (3/3 judges higher, RMSE 0.52) | `test_near6_tw_judged_on.gd::test_swim_wake_trail_ships_on`; `test_human_water_contact_visual.gd` idle step now runs past the configured lifetime (13 tests, 0 failed) | this commit |

## Arms built (all OFF, commit 6cd7f370)

| Row | Item | Flag (default OFF) | Change |
|---|---|---|---|
| F39#6 | P2-028 faint | `data/creatures/f36_pose_candidates.json` `lane_role_flags.uiposes_riptusk_side_faint_prone_rest.enabled` (UIPOSES arm, never judged) | Riptusk faint rolls onto its side, head dropped |
| F39#14 | P2-072 swim contact | `human_water_contact_visual.json` `wake_trail.enabled` | Longer-lived trail rings (12, 2.4 s) that spread to 2.3x as they fade: a widening wake |
| F39#27 | P2-057 named characters | `water_character_rim.json` `enabled` | Tidewake named NPC and trainer bodies wear the existing character rim overlay, warm sand tone, plus a soft front fill (new shader uniform `fill_energy`, default 0 so Stormwood is unchanged) |
| F39#7 | P2-089 fight composition | `combat.json` `contact_spacing.all_pairs.enabled` | Every ally/foe pair uses the hollows_alpha fix (render-box support, 14 m/s swept correction); clearance and reach unchanged |
| F39#19 | P2-088 roster contrast | `combat.json` `hud_subject_fade.roster_floor.enabled` | The fight roster holder never fades below alpha 0.9 |

## Verdicts

- **r6, F39#6, flat (5.29 -> 5.29), held OFF:** `uiposes_riptusk_side_faint_prone_rest` cannot reach the shipped Riptusk. It now renders the owner1101 remake, which has no F36 recipe, so A and B were pixel-identical (3/3 judges). The new arm is `creature_pose_settle.json` `tidewake_scope` (CAUSE-POSES settle, scoped to ripplet, riptusk and aquaryn, with the roster master still OFF). It is queued as r6b.

- **r7, F39#7, worse (6.19 -> 5.42), held OFF:** with `contact_spacing.all_pairs` on, all three judges saw Ripplet pressed into Cannonback and the trainer against Ripplet's tail; the base kept clear sand. Round 1 of 2 on this item.
- **r19, F39#19, not judged (no visible change):** `roster_floor` changed nothing on CPU. The roster region differs by a mean of 0.2–1.2 per pixel, because the subject fade never takes the roster down in these three stands. The arm stays OFF. The pale roster the GPU judges describe needs another cause.
- **Harness fix (quick_judge `find_frame`):** fight tools write `<trainer>/<tag>-<sss.ss>.png` for `..__fight__<trainer>__<tag>-<sss_ss>` ids, and tell moments drift from run to run. Lookup now takes the same tag nearest in time (within 1 s). Without it, every Venn fight round failed with "no frame pair".

- **r6b, F39#6, worse on pre-check, held OFF, item PARKED:** the `tidewake_scope` settle leaves Ripplet and Aquaryn standing and Riptusk floating upright at the faint-end moment (`qj/r6b/`). This was round 2 on the item.

## Queue

`runbook/chain.sh` (resumable): import, then r6, r27, r14, r19, r7. F39#1/#2 wait for VIS-TIDEWAKE's r2a verdict; F39#4 waits for its shiny round; F39#20 is designed from the r19 base fight frames.

## Blockers

- First `--import` on this container takes about 2 h on CPU.
