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
requires registered-root coverage, accounts for changed material identities
versus unchanged materials with no surviving users, compares the changed count
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
the production freeing and existing in-place save/load on both peers. A bounded
request to extend its read-only probe with light/pylon completeness assertions
was posted on
[PR #525](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-6006429518).
The coordinator approved that exact extension in
[comment 6007246010](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-6007246010).
The existing `veridian_choice` probe in `tools/net/peer_runner.gd` now returns
only two additional read-only counts: remaining live tether materials from
the entire current scene (independent of healing groups), and topple counts
by authored holder/pylon id. It deduplicates material identities and excludes
queued ancestry. Until healing applies, the remaining-light sentinel is -1.
The existing `--handoff` smoke asserts zero remaining materials and exactly
one topple per authored non-null fall-table id, with no unexpected ids, on
both host and guest live and after their existing save/load steps.
No new files, modes, gameplay or authority changes; these checks remain
**UNRUN** and must run alone after R1/R2 heavy jobs clear. Independent review
of the actual 72-line, two-file extension by `/root/c3_journal_review` returned
**SOURCE PASS**: fresh whole-scene scanning, queued ancestry, material identity,
unapplied sentinel and all 29 authored IDs exactly once with no extras checked.
Pylon counts prove accepted fall starts, not completed landing poses. The host
loads its saved slot and the guest saves/applies its character in the existing
scene; these checks prove persistence through that path, not world reconstruction
or rejoining. The existing solo smoke retains landing-pose checks and an actual
fresh-world rebuild after save/load. Native parsing, runtime and timings remain
OPEN; source review does not establish those results.

Independent review of the actual candidate: **SOURCE PASS**, by
`/root/c3_journal_review`, reviewing the 11-file product/test diff now committed
as `854241155506513d2ca43c85d5f1a95b15945cf4` (218 additions / 16 deletions).
The reviewer checked world scope, node lifetime, material identity, group
coverage, per-run child order/stagger, authored pose/idempotence, cable timing,
unchanged durable flags, focused tests and solo smoke assertions. No actionable
source finding; imported/later-spawn material completeness and runtime/perf
remain OPEN. A source review does not certify the smoke or compiler.
No compiler or native PASS is claimed. `git diff --check` passed on this stage.

Follow-up source inspection found a proof accounting trap: the climax can queue
its cage before MeadowHealing's light step. The smoke now accounts by material
identity/state rather than requiring every pre-flag material to survive until
the kill step. Only an unchanged material with no surviving geometry users is
classified as retired; changed retired materials still count, and a shared
surviving material must go dark. The before-coverage, exact changed/kill count
and whole-world end-state assertions remain. This audit runs after the fades,
outside the timed frame and immediate alpha-start check. Runtime remains UNRUN.
The same independent reviewer re-read the actual follow-up diff and returned
**SOURCE PASS**: queued ancestry, shared surviving users, changed retired
materials, exact expected count and preserved audits checked. No source-level
parser issue found; native compilation and lifecycle reproduction remain OPEN.

## Native execution held

At this checkpoint Valheim PID 2496, R1 full unit ON engine PID 16844 and R2 full
baseline engine PID 8624 were already running. No P1 engine, import, export,
render or heavy CPU measurement was launched. The owner-chat GPU reservation
remains active until at least 2026-10-06T02:00:00Z and Valheim absence is verified.
P1 CPU-only proof is authorized, but must wait for other heavy jobs to clear;
source work, independent review and evidence pushes continue meanwhile.

C2 is closed as BLOCKED/accepted with an existing-tool gap. Its custom fixture
and cancelled export/profile queue must not be restored or executed for P1.
