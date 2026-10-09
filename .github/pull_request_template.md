## Lane
Feature | Bug | Task | Hotfix

## Anchor
Name the settled spec and criterion at its commit, the violated requirement,
or the maintenance rule. State the player-visible outcome and out-of-scope work.
For the current four-chapter pass, include the ROADMAP F01–F49 feature ID or
X01–X07 shared-work ID and the ACCEPTANCE criterion this PR advances.

## Evidence
| Criterion or invariant | Named test or ordinary-play witness | Expected | Observed on commit/package |
|---|---|---|---|
| Replace me | Replace me | Replace me | Replace me |

## READY gate
For a READY, record the current `origin/main` SHA, the scoped commit list, and
the resulting tested tree SHA. The tested tree must contain that main plus only
those scoped commits. A passing lane branch alone does not qualify.

List every changed config flag and default as `path.key: old value → new value`;
write `none` if there are no changes. Each READY may flip only one feature flag.
Keep actor_vitals, Tether, capture and alpha flips in separate READYs.

Name and link the required proof and the unit tests/smokes for every system the
changed flags touch, with results from the tested tree above. A skipped engine
job or a process-only CI green is not proof.

## Independent review
Reviewer: pending
Result: pending
