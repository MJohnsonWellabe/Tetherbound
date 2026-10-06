# P1: Meadows healing target lookup

Status: **INCOMPLETE — source candidate, not runtime or timing proof.**

Assigned on [PR #525, TASK P1](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-6006169725).
Branch `tb/codex-p1` starts at `origin/main` `f797d3c0c51776ca573780322214e2fbe979e26c`.
The handoff was read from `origin/tb/perf` `da6323b77`,
`ralph/reports/PERF/HANDOFF.md`, items 1/2 and Known traps.

## Source change

- Light targets come from groups registered by production builders. Only
  bounded authored presentation subtrees are walked; the whole Meadows
  tree and vegetation are not scanned by `_kill_the_tether_lights`.
- Each pylon and separate cable step resolves its own current group list,
  filtered to the current world and excluding queued nodes. Config holder
  filters, authored fall directions, child order within each run, staged
  falls, collateral cable selection and the existing exactly-once marker
  remain in place. Severed `Spoke_*` runs remain standing.
- Material identity is deduplicated across overlapping light roots. The
  existing material enumeration and kill predicate are unchanged.
- No shared world-node snapshot across healing steps, new deferred calls,
  new durable flags, authority changes or save-schema changes.

The root inventory covers SouthBridge, OldQuarry (including QuarryConduitHead),
TetherRelay, Stronghold, StrongholdClimax (including the readout/cage), live
spoke/conduit builders and external ApproachConduits/HallCableLanding.
It also preserves existing hue-rule effects on RuinedWatchtower lenses and
BurrowWarrens/Fungus. Warm legendary light remains excluded by the same rule.
An independent read-only pinned-source inventory identified the latter
three omissions before the candidate was finalized. Imported and dynamic
material completeness still requires the smoke audit below.

## Existing proof changes and required results

`tests/test_meadow_healing_land_heals.gd` gains focused checks for current-world
group scope, queued/new targets between steps, exactly-once grouped toppling,
severed-spoke exclusion, shared/overlapping light roots, warm-light preservation,
foreign-world isolation and repeated light kill. **UNRUN.**

`tests/smoke_meadow_healing_land_heals.gd` now audits every affected material
through the whole production world before healing, outside the timed frame,
requires registered-root coverage, compares the exact affected-material count
to the kill receipt, and checks no matching live materials remain after healing
or reload. It additionally checks unique topple receipts/markers. Existing
29-pylon count, live/reloaded poses, save flag, walkability, cable, herd and
regreen checks remain intact. **UNRUN.**

The smoke's existing 9000 ms ceiling remains unchanged until a fresh measured
after result supplies a defensible tighter limit. The handoff's approximately
6000 ms freeing frame and approximately 1100 ms per target slice are prior
lane reports, **not a new local before measurement**. No after time or FPS
is claimed. Fresh before/after freeing-frame times and the tightened bound
remain OPEN.

Existing two-peer path: `tests/smoke_net_shared_boss.gd -- --handoff`. It drives
the production freeing and real save/reload on both peers, but its current
probes do not expose light/pylon completeness. A bounded request to extend its
existing read-only probe and assertions is on
[PR #525](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-6006429518).
No network/peer-runner edits have been made pending that answer.

Independent review of the actual candidate: **SOURCE PASS**, by
`/root/c3_journal_review`, reviewing the 11-file product/test diff now committed
as `854241155506513d2ca43c85d5f1a95b15945cf4` (218 additions / 16 deletions).
The reviewer checked world scope, node lifetime, material identity, group
coverage, per-run child order/stagger, authored pose/idempotence, cable timing,
unchanged durable flags, focused tests and solo smoke assertions. No actionable
source finding; imported/later-spawn material completeness and runtime/perf
remain OPEN. A source review does not certify the smoke or compiler.
No compiler or native PASS is claimed. `git diff --check` passed on this stage.

## Native execution held

At this checkpoint Valheim PID 2496, R1 full unit engine PID 13936 and R2 full
baseline engine PID 8624 were already running. No P1 engine, import, export,
render or heavy CPU measurement was launched. The owner-chat GPU reservation
remains active until at least 2026-10-06T02:00:00Z and Valheim absence is verified.
P1 CPU-only proof is authorized, but must wait for other heavy jobs to clear;
source work, independent review and evidence pushes continue meanwhile.

C2 is closed as BLOCKED/accepted with an existing-tool gap. Its custom fixture
and cancelled export/profile queue must not be restored or executed for P1.
