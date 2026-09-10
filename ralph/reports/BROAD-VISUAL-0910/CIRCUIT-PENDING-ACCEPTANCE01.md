# Circuit acceptance after delayed client delivery

Independent final integration review found one introduced P1 blocker: the new
Rook offer immediately replayed earlier victories after submitting acceptance.
A multiplayer client's write is pending until the host delta arrives, so those
count events failed their acceptance prerequisite. Rook then switched to progress
dialogue without another replay. With three or more prior victories, the remaining
trainers could not supply three counts, and authored rematches were forbidden.
The earlier synchronous wiring smoke could not expose this ordering defect.

The chapter now waits for locally committed acceptance and replays missing
historical count credits when progression changes. A revision latch prevents
per-frame pending resubmission; already committed count flags are skipped.
The initial latch also recovers accepted saves that contain earlier trainer
victories but no Circuit credits. Three distinct wins and the required return
to Rook remain unchanged. No trainer win or quest acceptance is invented.

The expanded existing wiring smoke uses the production progression dispatcher
with a delayed writer. It verifies pending acceptance is not local, all three
specific historical credits are queued after acceptance, an unchanged revision
adds no submissions, and ordinary reconciliation after committed deltas reaches
step 2. A separate accepted-save fixture reaches the same result. Both settlement
loops have an eight-revision limit. These are delayed-transport fixtures, not a
new two-process network playthrough or physically earned Circuit route.

The first actual focused runtime passed 11:49:15–11:49:21 UTC, exit 0 with no
engine errors, under `circuit-pending-acceptance-first`. The related Circuit and
realm progression suites passed 11:49:48–11:49:53: 13 tests, 144 assertions,
zero failures and no engine errors. Pre-run review corrected a Variant inference
and added the production-style aggregate reconciliation to the test fixture;
there was no negative runtime against the old production implementation.

The independent reviewer rechecked the final production and test diff and
closed the identified blocker, finding no additional concrete blockers across
the production/CI integration diff. That review is static evidence; the runtime
receipts above are separate. The prior Windows package at `8aad9c373` predates
this repair and must not be described as containing it.
