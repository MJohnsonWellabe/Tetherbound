# Accepted installed portrait mapping

`npc_portraits.enabled=true` is accepted by the native comparison and fresh
code-blind verdict in `people-blind-verdict.md`. The enable commit is
`a53f158c9`. All eleven visible world speakers match their portraits across
24 dialogue panels, including the generated Wen refusal and four later Glass
for Bryn registrations. No portrait is missing or incorrectly cropped.

The mapping reuses seven existing body-profile plates and applies them to
exact registered speaker names. It covers the nine original catalog speakers
plus Fenn and Neri. Missing candidate files preserve the original path. No
world body, name, choice, requirement, completion event or progression flag
changes. Other chapter registrations are unaffected.

The enabled-overlay and existing NPC suites previously passed 7 tests / 613
assertions without diagnostics. They verify actual authored and synthetic
conversations, all non-portrait fields, disabled behavior and missing-file
fallback. Independent source review caught and corrected late Bryn registration
ordering and stale dialogue-camera metadata before capture.

Capture source `cc5e2947ec6f1637a2162ee8f4a5491939122d08` produced 96 actual
1920×1080 images in two production-world boots. The 24 rows each have a post
and dialogue image: eleven arrivals, eight progress/aftermath panels and five
synthetic panels. The independent audit verifies source hashes, dimensions,
coverage, displayed speaker/profile mappings and 48 eligible comparisons.
All dialogue cameras reached blend 1.0; their FOVs match. Post FOV is unrecorded.
See `people-native-comparison.md` and retained round manifests for measurements.

These are debug-staged direct-start panels, with ordinary HUD hidden and
chapter progression/arrival callbacks isolated. All before/after-close flags
remain empty. They do not prove earned story states or ordinary interaction.
Portrait and opening gates toggled together; the trainer gate stayed off.
The launcher restored its original disabled config before the later acceptance
commits enabled the two reviewed settings.

Scoped Bars A/B are YES/YES for movement toward the intended register, not
whole-chapter acceptance. Repeated apparent identities across different names,
Fenn's fully obstructed post view and rough close-range world materials remain
separate findings. Fenn's clearly visible dialogue world body supports portrait
identity; its obstructed post image does not establish ordinary world visibility.
