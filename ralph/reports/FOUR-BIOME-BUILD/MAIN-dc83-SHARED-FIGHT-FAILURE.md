# Main dc83 shared wild fight — preserved failure and next diagnostic

Main CI34408839617 failed attempt1 in job102659741146. The failed
shared_wild_fight run is preserved under
`.artifacts/main-dc83-shared-fight-failure/artifact/net-shared_wild_fight-20260909T220117Z/`;
all main job logs remain in `.artifacts/main-dc83a4193-ci/`.

The client submitted automatic action9003 after the explicit authority and
replay probes. Forty refusal polls still returned the earlier replayed_action
code. Ally HP fell 85.028→59.351; opponent HP stayed95.708. These observations
do not prove allied damage: accepted verdicts do not update the last-refusal
snapshot, which does not carry an action identity, and the live opponent can
attack during the wait.

Independent Astra source/evidence review found the fixture's stated isolation
assumption obsolete. Its 8 m offset is justified by a 3.25 m enemy reach and
roughly0.6-second observation window. The actual HP window was9.32seconds;
the diagnostic player reach was8.55m. Actual enemy reach and attacks during
that window were not recorded. The friendly-distance check mixes snapshots
from two peers and does not establish the host's arbitration geometry or
nearest target. Production range/cone tests intentionally flatten height;
height mismatch is not a demonstrated cause.

The same combat source passed PR112's separate first-invocation run with
friendly_target after one poll and unchanged HP over roughly0.43seconds.
That supports timing/geometry sensitivity; it neither fixes nor rewrites
the failed main invocation. No unchanged rerun was launched.

Next diagnostic must capture one action-correlated acceptance/refusal with
host origin, facing, resolved move profile and candidate ownership/positions;
expose existing enemy struck_counts through the encounter probe; and verify
host-observed friendly targeting plus enemy isolation before one submission.
Keep friendly_target, a nonempty refusal sentence and zero ally/opponent HP
change as requirements. Neither increasing the offset nor extending polling
alone establishes isolation. Current evidence does not justify changing
production damage routing or friendly-body arbitration.
