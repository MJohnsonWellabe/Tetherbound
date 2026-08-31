# RESTARTS — gate-f-run-S10AB-2026-08-31

Per §A's blocker rule, a restarted segment's previous attempt is renamed rather
than overwritten, and which attempt is the evidence is an operator decision. All
attempts are kept. Every restart here was caused by a defect this lane then
FIXED, so pre-fix and post-fix evidence must never be read together — the
superseded directories are the record of the failure, not of the game as it
stands at this branch's head.

| directory | why it was superseded |
|---|---|
| `S10a-superseded-1` | Refused at step 1 by the capture pre-flight: with no `RUN_METADATA.json` in this run directory the harness fell through to the 2026-08-27 candidate freeze, whose flat `display_server` claim binds every segment. Fixed by writing this run's own record with a `lanes` block. No step ran. |
| `S10a-superseded-2` | First real drive. The Hall-entry walk failed 13.7 m short at the front door's riser; the courtyard fight was lost; the recovery panel was never closed, so the walk to the elite never started. |
| `S10a-superseded-3` | Threshold fixed and the recovery beat walked and closed; the elite fight was entered on a 42/218 pilot and lost. |
| `S10a-superseded-4` | Pre-switch waits added; the counted press runs and the round boundaries still drifted apart and the elite was lost. |
| `S10a-superseded-5` | Same, one run later; the courtyard was lost this time. This is the run that made the case for a predicate-driven fight step. |
| `S10a-superseded-6` | `fight_until_resolved` in: patrol and courtyard won cleanly, elite lost — and this is the run that MEASURED the base-stat collapse (three party members from 218/257/218 max HP to 2.14/2.20/2.14 in one tick as the victory XP landed). |
| `S10a-superseded-7` | Green, but taken before the elite was re-staged off the east wall; its `S10a-exit` no longer matches the shipped layout. |
| `S10b-superseded-1` | The walk into the Legendary Chamber stopped 7.2 m short against the tether machine's own base collider; the machine control could not be offered, `legendary_freed` was never set, and the ceremony never opened. |
| `S10b-superseded-2` | Ceremony green — the belt held at exactly five and `legendary_settled` was set — but the segment walked into its save handoff with §28's machinery-failure conversation still on screen, so the Save tab never opened and `save_out` correctly refused to copy an unchanged slot. |

The kept `S10a/` and `S10b/` are both 0-FAIL runs at this branch's head.
