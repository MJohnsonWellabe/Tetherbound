# Split-realm freeze — playable-first deferral

Status: deferred from this run under
`docs/owner/OWNER_DIRECTIVE_2026-09-07_PLAYABLE_FIRST.md`. This is a multiplayer
realm-transition depth proof, not the fresh-save solo completion path.

## What was proved

- Fatal-safe smoke cleanup now terminates both peer processes and writes a summary
  instead of leaving orphan Godot processes after a failure.
- Holding the arriving Player inert during a sliced realm build removed the repeated
  fall-warning flood.
- The telemetry-first run produced no greater-than-15-second peer silence and both
  peers exited normally.
- Host shell and real client stop in the same place: Cloudreach enters the `routes`
  stage, records one long held slice (836 ms host, 845 ms client), and does not leave
  that stage before the existing 6,000-frame readiness deadline.
- Static inspection narrows the next work to `_build_route_shoulders()` calling the
  synchronous `_route_ridge()` after the first route-loop yield. That ridge performs
  station, row and mesh construction without an internal suspension point.

## Evidence and unfinished work

The latest local run is
`C:\Temp\Tetherbound\net-split-telemetry-20260907T182248\SUMMARY.md`; its peer logs
contain the `[shell_build]` stage records above. A narrow awaitable-ridge patch and
`tests/test_cloudreach_route_slicing.gd` were drafted in the working tree but were not
validated or accepted before the playable-first directive changed priority. The
second pass must review that patch against current `main`, run its focused contract,
then rerun `tests/smoke_net_split_realms.gd` once. Do not raise the readiness deadline
or reduce Cloudreach geometry to manufacture a pass.
