# CI segment checkpoints

Owner request (2026-10-04): break the long CI chains into segments. Each
segment after the first starts where the previous one leaves off, from a
real save the previous segment wrote. Each segment is proven on its own, and
every boundary has a handoff proof.

Each `<chain>/<boundary>/<role>/` holds a save in the `capture_saves` layout
(`saves/`, `worlds/`, `characters/` under `redesign-v28/`, gzipped with
`gzip -n -9`). The **producer segment's own run** wrote it through the
production save code: `Game.autosave_here()` (the proof step
`capture_saves`), or `Game.save_game` for a solo smoke. Nothing here is
hand-edited or converted from an older save (RD-35). `manifest.json` records,
per role:

- the producer;
- `produced_at_commit`, the source commit the producer ran on (`+dirty` means
  the segment tooling itself was still uncommitted on that commit);
- the character id;
- the producer fingerprint: sha256 of the producer scenario or smoke, plus the
  contract;
- the state digest, with its readable summary (versions, document keys, realm,
  party, flags, satchel).
- the sha256 of every committed file, so any hand edit is refused, including
  a field the digest does not summarise.

The **start contract** of every boundary is one dictionary in
`tests/helpers/ci_segments.gd` `BOUNDARIES`. Three checks read it:

1. **Producer end.** The producer segment's end (`seg_checkpoint`, or the
   bracket smoke's `_write_checkpoint`) checks that the save it just wrote
   meets the contract, and that it reproduces the committed digest.
2. **Consumer start.** The consumer segment's start (`seg_verify`,
   `seg_seed_home` and `seg_contract`, or the bracket smoke's
   `_resume_from_checkpoint`) refuses a stale checkpoint and checks the
   contract.
3. **Handoff job.** `tests/test_ci_segment_handoffs.gd`, run by ci.yml's
   `verify-segment-handoffs` job per chain, checks four things:
   - the save version is current;
   - the checkpoint loads through the production `SaveGame.load_slot`;
   - the contract is met;
   - the manifest digest and producer fingerprint still match.

   Deliberately stale copies must fail.

**Stale?** The failure names the command. Run
`tools/ci/segments/regen.sh <chain>` (`midride` or `bracket`): one step
regenerates every boundary of the chain, upstream first, by re-running each
producer segment through the real game and installing what it saved.
`regen.sh <boundary>` redoes a single boundary when its upstream is fresh.
Commit `tests/fixtures/segments/` in the same commit as the change that made
the checkpoint stale.

## midride (F06 mid-ride two-peer rejoin)

Original: `tools/net/proof_scenarios/f06_cloudreach_midride_rejoin.json`.
`tools/ci/segments/split_midride.py` splits it into
`tools/net/proof_scenarios/segments/midride/`, and
`tools/ci/segments/check_coverage.py` proves each original (step, peer) runs
exactly once and unchanged.

| Boundary | Role | Produced by | State asserted (contract) |
|---|---|---|---|
| `midride/setup` | host | `s0_setup_host.json` (one peer; the host's original steps #1-3, #11) | Cloudreach, empty party, `realm_key_cloudreach` set, upper route closed |
| `midride/setup` | guest | `s0_setup_guest.json` (one peer; the guest's original steps #1-14) | Cloudreach; meadowhart, bramblebun, terrapup, brooktail, mudsnout; key and upper route set in its own world; one saddle, not yet fitted |
| `midride/after_a` | host, guest | `s1_ride_a.json` (part A, original steps #15-59) | host as above; the guest's five and own-world flags, same character as `setup:guest` |
| `midride/after_b` | host, guest | `s2_ride_b.json` (part B, original steps #60-93; original #91's own capture) | as `after_a` |

## bracket (village tournament)

`tests/smoke_tournament_bracket.gd -- --segment=to-semi` plays everything up
to and including the semi-final, then saves. `-- --segment=final` resumes
from that save and plays the final and the champion beats. With no flag the
smoke runs the whole bracket in one process, as before.

| Boundary | Role | Produced by | State asserted (contract) |
|---|---|---|---|
| `bracket/after_semi` | solo | `smoke_tournament_bracket.gd --segment=to-semi` | Meadows, three registered entrants, `opening:tournament_registered` set, team/training/condition ready, entered, quarter- and semi-final won; not won, no saddle pattern, final not opened |
