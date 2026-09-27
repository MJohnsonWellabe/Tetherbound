# M4 finale and handoff: integrated headless run from `seed4_hall`

This is one integrated headless run of chapter card M4. It covers the Warden, the full-five Veridian
choice, saves and title Loads around the offer, and the physical Rift into Cloudreach with the same
five. It resumed from a checkpoint, so it is not closes proof: `counts_as_proof: false`.

- Result: **PASS**. Attempt 1 of 1. Process exit 0.
- Steps: 19 of 19 passed.
- Party size: at most 5 on every one of 24,557 watched frames (process and physics).
- Runtime: 17 min 12 s wall. The M4 piece took 937 s. The run was 1022 s to the `c1_arrival` export.
- Run commit: `a6cf7ff6`, recorded in the checkpoint receipt.
- Evidence in this directory:
  - `m4-run.txt`: the trimmed log. It has the resume, the `M4 PASS/FAIL` lines, the receipts, the
    checkpoint line and the result lines.
  - `m4-result.json`: the full `M4 RESULT`, expected vs observed for each step.
  - `with-space-witness.txt`: the separate with-space fixture witness.

## Command

```
cd <repo> && TB_WORLD_SEED=4 timeout 5400 godot --headless --path . \
  --script res://tests/smoke_four_biome_continuous.gd -- \
  --resume-from=seed4_hall --m4-finale --through-meadows --checkpoint-dir=user://m4_checkpoints
```

- `--m4-finale` is opt-in. In `_stage_warden_to_cloudreach` it loads
  `tests/helpers/meadows_earned_finale_segment.gd` instead of running the Warden helper. Without the
  flag, the default path is unchanged and does not parse the new helper.
- The run ended with the smoke's own `c1_arrival` production save and export, then the
  `--through-meadows` stop.

## Expected vs observed

The accept continuation (branch A) released `creature-3fd010116aee4ec96d669fb5d4ecca74`, a bramblebun
at level 15 and the lowest level on the belt. The Veridian `creature-8e164085d15b2d633f698f8f2a62b611`
joined at level 22.

The five that continued through the gate, and arrived in Cloudreach unchanged:
`creature-390db8e0de00cd1fcaaf1747203b0768`, `creature-8e12dace31044e591f02b96391ca2372`,
`creature-8e164085d15b2d633f698f8f2a62b611` (Veridian), `creature-c785f517af159966b72ca0f49f61d386`,
`creature-f4118d54a2317867246afbf1e8ea834f`.

| Step | Expected | Observed |
|---|---|---|
| 0_resume_seed4_hall | 5 earned UIDs at the arena, no ending flags | PASS. 5 UIDs; 0.53 m from the arena marker; no ending flags |
| 1_warden_fight | Real-input Warden win; `defeated_warden`, `realm_key_cloudreach`, `realm_heart_meadows_earned`; shutter open; same five | PASS. 5 rounds, 5 wins, 85 hits; all flags set; shutter open |
| 2_offer_open | `legendary_freed`; choice open with both prompts; no answer flag | PASS. Chamber, free, join and `veridian_choice` read by Interact |
| 2_offer_survives_reload | Save 2 with the choice open, then title Load 2: the same unanswered offer returns | PASS. The join and choice replayed; no answer flag; same five |
| 3R_refuse_prompt | Refuse at the prompt at capacity: `legendary_refused` and the refused receipt; same five; herd display; healing; key/heart; Rift opened once | PASS. Herd display stands; healing report: 7 of the herd back, 132 tether lights out, 1963 blooms |
| 3R_after_reload | Save 3, then title Load 3: all of the above is durable | PASS |
| 3R_reload_no_reoffer | 480 frames in the chamber: no join, choice or ceremony | PASS. Stage stayed `done` |
| 3R_offer_save_no_second_grant | The answered character loaded into the offer-open save is not offered again | PASS. The climax took its `settle` path (`failure`, then `done`), not `join`/`choice` |
| 3R_answer_kept_across_saves | `legendary_refused` travels with the character | PASS |
| 4C_offer_restored | The declared offer-open start re-offers | PASS |
| 4C_ceremony_let_newcomer_go | Accept, then ceremony, then "let the newcomer go" is recorded as a refusal; the earned five are unchanged; herd display | PASS |
| 5A_offer_restored | The declared offer-open start re-offers | PASS |
| 5A_party_after_release | The four earned members plus the Veridian; the lowest level was released | PASS |
| 5A_accept_release_lowest | `legendary_joined` and the accepted receipt; one Veridian; no herd display; healing; key/heart; Rift opened once | PASS |
| 5A_after_reload | Save 3, then title Load 3: all of the above is durable | PASS |
| 5A_reload_no_reoffer | No second offer after the reload | PASS |
| 6_rift_ready | Span standing; `openings()==1`; 0 crossings; admitted by the key; `meadows_acknowledged` absent | PASS |
| 6_rift_fires_once | Trigger entered once; `crossings_fired()==1`; `openings()==1` | PASS |
| 6_cloudreach_same_five | Cloudreach reached by the physical crossing with the recorded five; `realm_gate_cloudreach_unlocked`, key, heart and `legendary_joined` all set | PASS |

## Real input

The following were all injected as ordinary controller input through the existing segment helpers:

- the Warden fight and every walk and stick approach;
- every prompt press (lever, accept, refuse) and every dialogue line (Interact);
- both ceremony choices (`ui_down`, `ui_accept`, `menu_cancel`).

No flag, party member, position or inventory item was written by the harness. Before the Warden and
before the Hall exit, the harness used Satchel care through the real Satchel seam (receipt
`bench_care`, the same B7 remedy as `tools/earned_saves/warden_accept.gd`).

## Disclosed shortcuts

These follow the owner ruling of 06:55.

1. **Declared start save.** The run resumed from `tests/fixtures/earned_saves/checkpoints/seed4_hall`
   through the smoke's production title-Load resume. It was not a new game.
2. **Title Loads.** The harness calls `change_scene_to_file` to reach the title scene; no in-game
   quit-to-title was used. The title's Load and "Save N" buttons were pressed with `pressed.emit()`,
   the same way the smoke's own resume does it. There were six title Loads.
3. **Branch starts (C and A).** Branches C and A started from a byte copy of the game's own offer-open
   save files (slot 2, copied right after `Game.save_game(2)`). The copy was restored at the title
   screen and loaded in the same frame.
   - This was needed because the character file is portable and already held branch R's answer. The
     game correctly refuses to offer the freeing twice: see step 3R_offer_save_no_second_grant.
   - The restore is not a save edit: no bytes were changed.
4. **Kell acknowledgement skipped (B13).** The production Rift admits on `realm_key_cloudreach` only.
   The helper's copy of the crossing drops the helper-only `meadows_acknowledged` precondition, and
   `meadows_acknowledged` was absent at the crossing. No game code was changed.
5. **Route.** The route went from the Hall exit along the band5 spine back to the Sigil Gate north
   point (20,7480), then along the storm-road points north of the gorge (B15), then over the span.
   The arrival wait lets readiness win on the deadline frame (B16).
6. **With space (fewer than 5).** This cannot be reached lawfully from `seed4_hall`, and no save edit
   was made. The separate fixture witness `tests/smoke_veridian_offer_choice.gd` was run once
   (`with-space-witness.txt`).
   - That witness sets `defeated_warden`, builds the party with `make_creature`, moves the player by
     velocity and reloads in-process.
   - space-accept and space-refuse both passed in full, including reload, no re-offer, the
     personal-receipt-only check and the herd display. The at-capacity fixture scenarios printed no
     FAIL either.
   - The process hit the 1200 s timeout (exit 124) during capacity-accept-release-one's last sub-check
     (personal receipt alone), before the save-while-choice-open scenario. The integrated run above
     covers the save with the choice open.

## Not covered here

- Mixed two-peer decisions and reconnect. These stay with the `smoke_net_veridian_*` tests.
- A fresh new-game uninterrupted run.
- The `no_reoffer` step's `player_to_climax_m` value is a distance to the climax node's origin. It is
  diagnostic only and not a chamber distance.
