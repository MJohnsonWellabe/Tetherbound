# P0 boss-rewards journal (#681 blocker): smoke_net_boss_rewards_each_participant

Systems lane, tb/ev-systems, Mon 12 Oct 2026, 10:15 PM CT.

## Symptom
"host and guest hold the same durable reward journal" failed on CI in 3 of 4 runs.
Host log (CI run 38335125101, net-smoke-runs-7), in every run, pass or fail:
`save refused: owner training state is mid-transaction (host creature training pending: training staged)`
from journal_creature_training_prepared -> save_world_prepared -> _write_owed_characters,
then `research_event duty ... held: training_journal_failed`.

## Root cause
A mastery job (deferred writes) leaves the host's own character write owed until
an idle pause. The host's next stage of that same character (a research event)
opens the training stage, then journals the world. save_world_prepared lands owed
characters first, and the stage that was just opened refuses that write. The journal
fails, the duty waits for the idle flush, and the guest's journal diverges meanwhile.

## Fix (product)
- character_authority.gd: every training stage (stage_creature_training,
  stage_altar_building, stage_character_action), once no other lock holds the character,
  asks a bound lander to land owed writes. If they cannot land, the stage refuses with
  `owed_writes_pending` and changes nothing.
- session.gd `_land_owed_writes_before_stage`: for the host's own character, outside a
  job step, it flushes owed writes (characters, then the world) and releases the held
  mastery deltas in order. It returns false only mid-hit or on a refused write.
- The assertion and the settle loop are unchanged.

## Proof
- Smoke 3/3 PASS locally (both peers exit cleanly). There are 0 "mid-transaction" or
  "training_journal_failed" lines in the host logs; CI showed them in every run.
- Unit: research_passive_authority, combat_mastery_delivery, record_errors_memo:
  32 tests, 1212 assertions, 0 failed. The new test covers: refuses without mutation,
  lands before the lock, never flushes for a busy character.
