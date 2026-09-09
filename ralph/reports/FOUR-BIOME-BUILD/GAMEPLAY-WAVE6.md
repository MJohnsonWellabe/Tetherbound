# Gameplay Wave6 — 2026-09-08

Owner priority: continue the four-biome playable build; work on actual gameplay
content and fix tests only where necessary. Verified main remains
65267c4bd935d80b2e073799caeffc81b913952c, own CI34281611197 green.

Local commit526bb5aac corrects Crown preparation: the gathering objective now
requires the actual Crown arch glass cost (currently six), derived from the
production footing/build rules. One three-unit claim no longer advances it.
The world objective sums distinct durable shared harvest claims; it does not
claim a single player currently owns those items. Builder payment is unchanged.
Early claims reconcile after learning the recipe, completed saves remain valid,
and simulation-only shells emit no event. The existing guardian route direction
is retained; the text states six glass, two frames and four vines.
Focused progression5tests/16assertions and existing harvest/build authority
18tests/99assertions passed. Evidence `.artifacts/wave6-crown-readiness-final-*`
and `.artifacts/wave6-crown-authority-tests-*`; owner saves unchanged.

Necessary driver repair in the same commit makes obstacle/ground probes use
the actual player's collision mask. A tent has selectable layer2 geometry that
the player ignores; the old driver incorrectly avoided it. Native original
controls failed twice, fixed controls passed alongside existing root/kerb/
confined-travel cases. No arrival tolerance, movement budget or obstacle rule
was weakened. Logs `.artifacts/nav-mask-{original,fixed}{,-engine}.log`.
This proves a navigation defect, not the cause of the earlier third-bed failure.

One changed genuine fresh run used an empty isolated profile and ordinary title
inputs on526bb5aac. It stopped at302.373s: the tutorial fight ended in a loss
before capture. Two physical throws were recorded outside the production
reticle radius and struck fence geometry; later angle searching met another
wild body. No copied save, injected state or unchanged-code rerun was used.
Owner fingerprints match. The failure is preserved in
`.artifacts/wave6-fresh-campaign{,-engine}.log` and its profile/owner JSON files.
Coverage11samples/142.029m, six below-two samples, one undersampled interval;
complete_coverage=false. Earlier earned camp/two-rest evidence is not erased,
but this run did not reach camp or validate the mask repair there.

The saved goal record was still blocked when the owner asked why. Its last
updated timestamp was18:56:14UTC; the available record contains no reason and
the inspected task log has no corresponding mark-blocked call. No external
development blocker is established by that status. The goal remains incomplete;
normal authorized gameplay work has resumed. No completion claim or replacement
goal was made merely to clear the status label.

## Lantern Hollow story access

Maud, Sable, Bram and Mira occupied the same XZ as the physical Spark shrine.
Their capsules overlapped; the lower Maud/Bram prompts shadowed Sable on
ordinary approaches. Sable's captive-truth conversation gates the Deepwood rod.
The four retain their identities, roles and region, moved12m around the fixed
shrine: Sable(-450,3948), Maud(-438,3960), Bram(-462,3960), Mira(-450,3972).
Stored Y follows the existing heightfield+0.15 convention; runtime regrounds.
All remain within the existing48m safe zone near the road junction.

The actual-world diagnostic disclosed Rootgate/ActII prerequisites and one
south-entry pose, with no party or item grants. Seven ordinary controller legs
passed in88–151frames each under unchanged1800-frame bounds; grounded, zero
resets. Exact actionable prompts passed for all four. Physical Interact opened
Sable's real dialogue and earned stormwood:captive_truth_learned. No trainer
fights, fresh campaign or visual-quality acceptance is claimed. Owner hashes
match; zero engine/script errors. Logs `.artifacts/wave6-lantern-approach-*`.
The required Y metadata correction happened after the scene loaded; runtime
uses the unchanged XZ and authoritative heightfield, not stored Y. Existing
data/dialogue8tests/936assertions pass in `wave6-lantern-data-final-*`.
The earned Dynamo helper now approaches Sable's actual body rather than the
obsolete absolute coordinate; existing5tests/49assertions pass in
`.artifacts/wave6-dynamo-helper*`.

The final-catch driver guard releases look and refreshes the physics preview
after its last re-aim, then checks current production eligibility and physical
obstruction before spending an orb. It adds no retries or gameplay assistance.
Existing targeted suites19tests/67assertions pass in `.artifacts/final-catch-verdict*`.
An existing camera test's three unfreed fixture nodes are disclosed in that
output; no engine/script errors. Fresh runtime with this guard remains unproved.
