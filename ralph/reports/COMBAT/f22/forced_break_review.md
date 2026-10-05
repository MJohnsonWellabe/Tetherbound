# Forced break (COMBAT §4, owner ruling 2026-10-05): review and guest proof

Commit under review: `dd54b2b6` (forced break requires a charge started after
the tell, 0.1 s grace). An independent reviewer read it.

## Review verdict

The reviewer found nothing blocking.

- **F1 (online leniency): fixed.** Host-resolved guest charges were judged by
  windup against tell age at impact. Latency and travel therefore widened the
  window by about 3L+τ: a charge pressed about 0.43 s before the tell could
  still break. The fix:
  - The host now compares the guest's committed `move_start` tick
    (`started_at_ms`) with the host tick the tell appeared
    (`wild_creature.tell_visible_since_ms()`), less `forced_break_grace_s`.
  - Solo keeps the windup test.
  - Unit test: `test_forced_break_host_compares_committed_start_ticks`.
- **Regression found and fixed while adding the proof.** The first version of
  the F1 fix stamped `started_at_ms` onto the move before `validate_strike`.
  That function compares the move with the frozen start, so every committed
  guest strike was refused as `stale_move_start`. The stamp now happens after
  validation.
- **F2 (low, open).** A partner's ultimate hold freezes the tell clock, so in
  rare co-op cases a genuine read can be refused. Noted, not changed.
- **F3 (low, pre-existing).** Solo forced breaks gate on `not is_quick`; the
  host gates on `slot == "charged"`. Noted, not changed.
- **F4 (pre-existing).** A late guest read can land after the tell has ended.
  It works against guests and is not new.
- The reviewer found no tests weakened and no scope creep.

## Known pre-existing items (coordinator, 2026-10-05: record, do not change in F22)

- **F2.** `hold_ultimate_reaction` freezes the wild's tell clock but not a
  charge, so in co-op a genuine read can be refused while a partner's
  ultimate holds the opponent.
- **F3.** Solo forced breaks gate on `not is_quick` (utility and ultimate
  hits can force a break). The host gates on `slot == "charged"`.
- **F4.** Online, a genuine read lands about 3L+τ later than solo and can
  arrive after the tell has ended, which works against guests near the end
  of a tell.

## Guest path: two-peer proof

Run: `tools/net/run_net_smoke.sh f22_forced_break`
(`tests/smoke_net_f22_forced_break.gd`; CI auto-discovers it by its
`# peers: 2` header). Result: PASS, all checks.

Setup:

- Two real processes play through the production
  `move_start → strike_intent → host_roll_damage` path.
- The host pins its real shared wild in a long tell with a deep poise and HP
  pool (`f22_pin_tell` fixture), so only a forced break can stagger it.
- The guest builds Energy with landed quick hits before each charge.

| Case | Host verdict | Guest |
|---|---|---|
| (b) charge committed 30+ frames before the tell | landed, no break, poise drained 1,000,000 → 999,956 | no break announced |
| (a) charge committed after the tell | landed, break (counted from the host's own strike verdict) | the same break, announced from the host payload |

Host and guest therefore resolve the same tell/grace verdict for one charge.

Unit coverage: `test_combat_stagger`, `test_move_commit_runtime`,
`test_net_strike_transaction` and `test_f23_live_moves`: 41 tests,
293 assertions, 0 failed.
