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

The existing unit file contains checks for current-world group scope, queued/new
targets between steps, exactly-once grouped toppling, severed-spoke exclusion,
shared/overlapping light roots, warm-light preservation, foreign-world isolation
and repeated light kill. These three mounted checks now run from the existing
production healing smoke after world boot, outside the timed freeing frame.
Every original assertion is retained; boolean completion and forwarded failures
make a runtime abort fail the smoke. They remain **UNRUN in that initialized path**.
The 30 pure unit methods remain under the existing focused unit runner.

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
No complete compiler or native acceptance PASS is claimed. `git diff --check`
passed on this stage. The first native unit result below supersedes source review
as evidence about the original mounted-test placement.

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

## First native stage: INVALID result, preserved

At 2026-10-06T04:57:25Z P1 acquired the global lock and ran the existing focused
unit command at source `5c81904d9fb07a78c4c7eb308cf15117879d88d8`, with private
APPDATA. Coordinator comment 6009171478 permitted these untimed units alongside
the original R2 baseline pair 15796/8624; no other engine was active at launch.
Valheim and both owner reservation files were absent. The local import cache
was copied under the lock from R1 after checking identical tracked import inputs
and all cached class paths; no import or shared writable cache was used.

Raw [receipt](unit-first/receipt.json), [stdout](unit-first/stdout.log),
[stderr](unit-first/stderr.log) and [exit](unit-first/exit.txt) are preserved
byte-for-byte, with hashes in [SHA256SUMS.txt](unit-first/SHA256SUMS.txt).
Exit 0 and the reported **33 tests / 587 assertions / 0 failed are INVALID as a
pass**: the three new mounted-group methods aborted before their assertions.
`Engine.get_main_loop()` is null during the existing runner's synchronous `_init`.
The native log contains three SCRIPT ERRORs and five leaked ObjectDB instances.
The other 30 pure methods executed 587 assertions, with inherited authored-null
and unbaked-pylon warnings. This establishes no grouped behavior or performance
acceptance. The owned lock was released after the engine exited.

The correction invokes all three checks from the already initialized production
smoke, retaining their bodies and assertions. No generic runner, new fixture,
new test file, new mode or product behavior was introduced to work around the runner.
Independent read-only review by `/root/c3_journal_review`: **SOURCE PASS** on
the actual two-file fix, with all 19 mounted assertions retained (5 scope/refresh,
7 topple/idempotence, 7 light/material). Fixture worlds are isolated from the
production world; calls run after initialization, outside the measured frame,
and incomplete calls or assertion failures persist into the smoke's nonzero exit.
This verdict does not establish native parsing or runtime success.
The corrected focused unit selection completed at `d19b10e26b807e327aa19824a598acb36cbfd9d5`:
**30 pure tests / 587 assertions / 0 failed / exit 0**. Both streams contain zero
SCRIPT ERROR, Parse Error, ERROR or leak diagnostics; the three inherited
authored-null/unbaked-pylon warnings remain preserved. It used the existing
runner, private APPDATA, the same local cache, global lock and approved original
R2 background pair. Raw [receipt](unit-repair/receipt.json),
[stdout](unit-repair/stdout.log), [stderr](unit-repair/stderr.log) and
[exit](unit-repair/exit.txt) are retained byte-for-byte with a hash manifest.
The owned engine exited and lock released. This covers pure behavior and loading
the helper script, not the smoke's native parsing or its 19 mounted assertions.
The initialized production smoke remains pending. Fresh before/after freeing-frame
measurement and the two-peer handoff still require an uncontended window after
R2 finishes. P1 remains OPEN.

The fresh quiet baseline completed at exact source
`f797d3c0c51776ca573780322214e2fbe979e26c` using its unchanged existing healing
smoke: **6085 ms freeing frame / exit 0 / PASS**. The receipt records no native
background jobs and cites R2's explicit packaging-finished report 6010403311.
All 29 live, rebuilt-world and reload+30 pylon poses, road clearance, seven herd
members and the actual slot-4 save/load passed. Both streams contain zero
SCRIPT ERROR, Parse Error, ERROR, FAIL or leak diagnostics; inherited warnings
remain. Raw [receipt](before-first/receipt.json), [stdout](before-first/stdout.log),
[stderr](before-first/stderr.log) and [exit](before-first/exit.txt) are preserved
byte-for-byte with [hashes](before-first/SHA256SUMS.txt). Its cache was an
independent matching local copy under the owned global lock, with no import.
The engine exited and the matching lease released. This baseline has none of
the candidate's added material/mounted checks; candidate runtime, AFTER timing,
tightened bound and two-peer handoff remain OPEN. No performance gain is claimed.

The first quiet candidate at `7ba419929be0c8a488b7ec5957d6d2ea6315ad74`
completed **exit 1 / FAIL**. All 19 mounted assertions executed; native parsing
produced no SCRIPT ERROR or Parse Error. The full-world audit found 143 affected
materials, but grouped healing changed only 28 and left 115 lit live, after the
fresh-world reload and reload+30. The 4162 ms frame is an observed failed run,
**not accepted performance evidence**. All 29 pylon poses, clearance, cables,
herd and per-pylon save/rebuild comparisons passed. Raw
[receipt](after-first/receipt.json), [stdout](after-first/stdout.log),
[stderr](after-first/stderr.log) and [exit](after-first/exit.txt) remain unchanged,
with [hashes](after-first/SHA256SUMS.txt); the owned engine exited and lease released.

Source investigation found omitted pickup and objective presentation roots:
53 Good Candy pickups generate 106 matching crest/ring materials; four placed
TM orb colors match the unchanged hue rule; the objective adds four cyan
materials. These counts explain 114 of the 115 identities from source, without
claiming exact native identity attribution. The repair registers the existing
pickup, TM and objective visual roots. It mounts the same objective before the
saved-flag healing step so live and rebuilt-world coverage agree. Existing
failure messages now name the material's first geometry path; all assertions
remain. Corrected runtime and performance acceptance are still OPEN.

Independent read-only review by `/root/c3_journal_review` and
`/root/stormursa_reference_review`: **SOURCE PASS** on the focused repair.
World scope, material identity, the unchanged simulation guard and assertion
strength are preserved. Required player, terrain, map, quest and actor inputs
already exist at the new objective construction point. Its `_ready` also
attaches OnboardingLessons earlier in sliced construction; no incorrect
selection or startup failure is proved, so actual startup remains a runtime
qualification. The remaining material requires the new native path diagnostic.

C2 is closed as BLOCKED/accepted with an existing-tool gap. Its custom fixture
and cancelled export/profile queue must not be restored or executed for P1.
