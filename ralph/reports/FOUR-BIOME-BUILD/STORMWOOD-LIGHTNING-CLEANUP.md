# Stormwood lightning cleanup — 2026-09-08

The continuous chapter diagnostic emitted `Lambda capture at index 0 was freed`
after the sheltered Break and before its first charged gather. A minimal fixture
reproduced the same engine error through the production warning/impact receiver.

Cause: the warning's three-second fallback timer captured its ring Node. The
normal impact tween freed that Node after 0.12 seconds. Godot reports a freed
capture before executing the lambda, so its `is_instance_valid(ring)` guard
could not prevent the error.

Repair: bind only the strike ID to `_expire_warning`. The method consults the
live registry; an impact already removed its entry, while an unimpacted warning
still has a ring to free. Damage, timing, deduplication and visible effects are
unchanged. Independent code review found no P0/P1 issue.

Validation:

- `smoke_stormwood_lightning_cleanup.gd`: baseline reproduced the engine error
  despite exit 0. The repaired run exits 0 without ERROR/SCRIPT ERROR and proves
  both impact and timeout rings are freed and the registry is empty.
- `smoke_stormwood_lightning.gd`: 11 assertions, zero failures.
- Raw logs: temporary `lightning-cleanup-baseline.log`,
  `lightning-cleanup-repaired.log`, `lightning-rules-regression.log`.
- Full Stormwood continuous rerun and CI for this local repair remain pending.

Separate CI timing evidence: run `34201147829`, job `101980411062`, executes
`smoke_playground.gd` on attempt 1/1 and passes. Impact signal wall time is
0.410 s, swing elapsed 0.394409 s, chop position 0.3315 s; the durability poll
observes it at 0.451 s (fraction 0.72). The 41 ms observation delay does not
retroactively prove the earlier local 0.82 failure fixed. Test tolerances remain
unchanged; the local harvest-scan optimization still needs full-world validation.
