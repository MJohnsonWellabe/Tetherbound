# Portrait and opening panel comparison

Capture source: `cc5e2947ec6f1637a2162ee8f4a5491939122d08`.
Two native Godot 4.7 Compatibility boots on NVIDIA GeForce GTX 1060 3GB
produced 48 baseline and 48 candidate images, all actual 1920×1080.
Both jobs exited zero with complete manifests and no capture failures.
Each stderr contains six warnings: deprecated interpolation reset, two shared
canopy-model retints and three deterministic wild-spacing fallbacks. Neither
contains an ERROR, SCRIPT ERROR or SHADER ERROR diagnostic.

`people-before-r1/` and `people-after-r1/` retain four compact contact pages
and all frame metadata/source hashes. `people-comparison-coverage.json` records
the raw image paths, hashes, source commit, log hashes and each pair's measured
camera differences. Native images remain in the local reproduction directories
for full-resolution judging; compact tiles alone are not text-legibility proof.

The 24 rows cover eleven speakers at their posts and in arrival dialogue,
eight additional progress/aftermath panels for Bryn, Oswin, Maud and Fenn,
Wen's generated guardian refusal and four generated Glass for Bryn panels.
All eleven modified opening IDs are included, with Bryn's unchanged in-progress
briefing as a control. Both candidate flags toggle together; the trainer
presentation flag remains off.

All 48 pairs meet their recorded pose/phase comparison limits. Maximum camera
position difference is 0.000015259 metres; maximum basis-component difference
is 0.000001388. All 24 dialogue pairs have measured FOV equality, active
conversation cameras and fully settled blend 1.0. Post FOV is unrecorded: their
eligibility means measured pose/phase only. Animation, rain and other temporal
effects are not synchronized.

The fixture uses debug placement at authored posts, hides ordinary HUD, and
shows the production dialogue panel. It directly starts conversation IDs,
including unearned later-state text. The chapter's arrival polling and
dialogue-finished progression callback are isolated, while panel/camera
callbacks remain active. Every row records equal before/after-close progression
snapshots. These frames prove presentation only, not earned state, ordinary
interaction, travel, combat or complete chapter acceptance.

After terminal completion, the launcher restored the exact original disabled
configuration. A clean config diff and process inspection verified restoration
and no remaining Stormwood Godot children. The matching lock was released and
the next lane notified. At the subsequent main merge `95f11b61b`, before
acceptance, the capture helpers, chapter and presentation configuration had no
diff from the captured source. Acceptance commits `a53f158c9` and `8f5c25445`
then enabled the two reviewed gates and updated comments. The resulting
configuration exactly matches captured B apart from comments; trainer remains
off. Independent visual and evidence verdicts are recorded separately.

Independent evidence reviewer `stormwood_dialogue_review` completed the bounded
audit with no remaining blockers: all originals decoded at native dimensions;
hashes, retained metadata, tile mappings, neutral review copies and logs agree;
all required speakers/openings/synthetic IDs are covered; candidate paths match
the installed world profiles; all dialogue blends settled; flags stayed empty.
The reviewer explicitly leaves native text legibility and visual acceptance to
the fresh code-blind review, and preserves the fixture limits above.
