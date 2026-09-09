# Main dc83 shared fight — bounded strike diagnostic source

Follow-up to `MAIN-dc83-SHARED-FIGHT-FAILURE.md`. No combat rule, damage path,
save shape or network message changed, and the preserved smoke has not been rerun.

Owned files:

- `scripts/net/encounter_host.gd`
- `tools/net/peer_runner.gd`
- `tests/test_encounter_host_rejects_friendly_strike.gd`
- this report

`EncounterHost` now retains one detached latest strike receipt per active
encounter participant. The row is keyed by encounter and peer and correlated by
action. It records the host validation outcome (`accepted`, `refused`, or
`missed`), code/reason/delta, authority state, and the record phase/sequence where
the verdict occurred. Only a branch that reached production targeting also records
the host clock, host origin, submitted arbitration facing, host-resolved move
profile, and every host candidate's ownership, role, position, distance, connection
result and eligibility. Early malformed, wrong-phase, replay and cooldown refusals
set `geometry_available=false` and do not convert geometry fields that production
validation did not reach. Recording happens after the existing verdict is decided;
no production path reads the row.
The preceding row is overwritten. Departure, opponent replacement, close and
forget clear the corresponding evidence so another encounter or round cannot be
mistaken for the observed action.

The existing `encounter` peer-runner probe now reports the encounter record's
existing `struck_counts` and host-only `host_strike_receipts` rows. This uses the
already local probe request/reply and adds no RPC. The focused pure host fixture
pins correlated accepted action 9001, friendly-target refusal 9002 and missed
action 9003, exact geometry/profile fields, latest-only replacement, defensive
copying, peer-departure cleanup, and a positive-action malformed intent whose
missing move remains a clean refusal with geometry explicitly unavailable. Hostile
value regressions also pin wrong-phase and cooldown refusals without observer-side
conversion. A preserved receipt carries its arbitration phase/sequence across a
later resolving transition, making the lifecycle boundary visible.
The geometry observer follows production's ownership skip order: striker-owned and
nonparticipant bodies are excluded before their positions are converted. A hostile
position regression pins that these non-candidates cannot turn an accepted strike
into an observer error.

A source contract check passed all checks: receipt API, defensive copy, action
and geometry fields, leave/close cleanup, both probe fields, action 9003 fixture,
and absence of receipt dependencies in `encounter_director.gd` and
`combat_manager.gd`. Independent Astra review found the initial early-refusal and
excluded-body conversion hazards; both were corrected and the re-review reported
no remaining actionable source finding.

Root then ran the accepted isolated wrapper
`.artifacts/strike-receipt-focused-0909/run.ps1`, with isolated profile plus
120-second, 90-percent-memory and 400-process guards. From
2026-09-09 22:53:20 to 22:53:23 UTC the focused fixture passed **23 tests / 123
assertions / 0 failed**, exit 0, with empty `stderr.log`. Evidence is in that
directory's `console.log`, `engine.log`, `resources.csv`, `stderr.log` and
`result.json`. The earlier `tools/net/run_strike_receipt_focused.ps1` prototype
was not the accepted wrapper, was not run, and remains unshipped. The reviewed
host/probe/fixture source was committed as `403997849`.

Probe consumers must match both the encounter id and exact submitted action. For
a geometry receipt they must also require `geometry_available=true` and a receipt
`host_now_ms` no earlier than the pre-submit encounter probe's `host_now_ms`. This
prevents a preserved latest receipt from being treated as a later action's answer.

## Shared-wild-fight consumer

The subsequent source-only consumer change owns only
`tests/smoke_net_shared_wild_fight.gd` and this report. It keeps action 9003's
input, placement, settle counts, 40-poll refusal bound and all existing
`friendly_target`, nonempty-sentence, ally-HP and opponent-HP checks unchanged.
The host encounter probe that already supplied the post-action ally HP now also
supplies the latest receipt, so no extra poll, frame wait or host observation was
added.

The consumer accepts a receipt only when encounter id, joiner peer id and action
9003 all match and its host arbitration time is no earlier than the pre-submit
host probe. That excludes the retained action-9001/9002 evidence and any
same-numbered row from before this phase. It independently requires the host
outcome/code to be `refused`/`friendly_target`, geometry to be available, and the
host-origin/facing/resolved-move fields plus a connected eligible peer-0 creature
candidate to exist. The existing client refusal remains required, so host evidence
does not hide a lost player-facing verdict.

The same pre/post host views compare peer 0's existing `struck_counts` tally. It
must remain unchanged alongside ally HP. If ally HP moves, the failure now reports
whether the host recorded an opponent blow during that exact window; the zero-HP-
change acceptance bar remains intact. Source checks confirmed unchanged timing
constants and original acceptance checks plus exact receipt identity/freshness and
struck-count comparison. Independent scoped source review found no blocking
schema, correlation, count-attribution or acceptance changes. Root's guarded
check-only invocation passed at 23:05:58–23:06:02 UTC, exit 0 and empty stderr
(`.artifacts/strike-consumer-check-0909`). Full native diagnostic execution in
`.artifacts/strike-consumer-native-0909` passed first attempt, 23:07:43.506–
23:09:26.604 UTC, exit 0, 63 PASS checks, no guard stop and no ERROR/SCRIPT
ERROR/FAIL in the coordinator or peer logs. Both peers exited normally; root
confirmed zero Godot processes afterward. Console SHA256:
`9cc36b68284d6ca50d466b3337e6789dc3c87d0849301b7ba53376cd2c99ac2d`.

The action 9003 receipt was `friendly_target`, host time 94681 ms after the
94560 ms pre-submit probe, with the friendly creature connected and opponent
outside the swing cone. Client refusal arrived in one poll. Ally HP stayed
94.957, opponent HP stayed 55.031, and opponent struck count stayed 3.
This validates the new correlated diagnostic path. The preserved main-dc83
intermittent failure remains unresolved; this later pass is not its fix.

Exact source hashes after the scoped edit:

| SHA-256 | File |
|---|---|
| `7B6AEE7D7F486085FE896E955B3BE6F7CF231B4B78AE53F5EE4F64DD2CE03FC3` | `scripts/net/encounter_host.gd` |
| `D74316A69AA2F2B2F800ED37024259D84254F0D66AAEE4553DC89280AC92982D` | `tools/net/peer_runner.gd` |
| `7E060C4DB45215B3D11E563CD7B39F2D851E9011E02A42414BB20E292D8433E2` | `tests/test_encounter_host_rejects_friendly_strike.gd` |
| `602C88F5C0CE5F96D1EAD8FC56116B2712A1739F90E679E198807D339C0CB0C9` | `tests/smoke_net_shared_wild_fight.gd` |
