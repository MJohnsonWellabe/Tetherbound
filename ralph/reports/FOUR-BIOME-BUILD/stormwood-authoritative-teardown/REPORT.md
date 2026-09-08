# Stormwood authoritative opponent teardown — 2026-09-08

## Failure

The successful local Livewire reproduction left one host-shutdown engine error
in `.artifacts/livewire-host-window-20260908/peer-0.log:278-283`:

`stormwood_authoritative_fight.gd::_exit_tree()` called `stop_opponent()` after
the realm shell had already detached its wild opponent. `is_instance_valid`
was still true, so cleanup called `wild_creature.set_engaged(false)`. That
method computes a new wander target from `global_position`, which a detached
Node3D cannot read.

## Repair

Live opponents retain the unchanged `set_engaged(false)` cleanup. Only an
already-detached opponent takes the new branch: clear `engaged`, `_opponent`
and `arena` without reading a transform, then perform the same signal, arena,
engine-reference and encounter cleanup as before. No combat, authority,
cooldown, damage or hit code changed.

## Evidence

- Focused real-body reproduction before the repair emitted only the target
  `!is_inside_tree()` / `get_global_transform` error through
  `set_engaged -> stop_opponent`; log
  `%TEMP%/stormwood-authoritative-teardown-before-cleanfixture.log`.
- The same focused smoke after the repair reports detached=true, clean=true,
  exit 0, and no `ERROR:` or `SCRIPT ERROR`; log
  `%TEMP%/stormwood-authoritative-teardown-after.log`.
- Existing `test_stormwood_hosted_combat.gd`: 5 tests, 14 assertions, 0
  failed, with no error scan matches; log
  `%TEMP%/stormwood-hosted-combat-unit-after-teardown.log`.
