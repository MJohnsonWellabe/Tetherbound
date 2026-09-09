# Owner directive — keep visual review and fixes active

Recorded from the owner conversation on 2026-09-09:

> Keep a lane focused on visual review and fixes always

Maintain a dedicated visual lane throughout the resumed four-biome work,
alongside the player-path and stability work. Its cycle is rendered review,
specific defect attribution, bounded fixes, fresh renders and independent
code-blind verification under the existing visual-judge rubric. A critic
reviewing the current candidate counts as the visual lane while the fixer
waits for that verdict. Reassign the lane when a bounded item concludes;
do not leave visual work dormant while other lanes continue.

The Stage C6 full-audit directive and existing art, scale, evidence and
resource rules remain applicable. This instruction does not turn a narrow
fix into whole-biome or shipping-art acceptance.

The same conversation selected PR92 as the resume point and clarified that
the interruption was a connection loss:

> dont stop, we just got disconnected. Continueu the work as if we didnt miss any time. Just resume from where you were

Continue the existing goal across that disconnect; do not treat the disconnected
interval itself as repeated missed-checkpoint evidence. Preserve the actual
failed tests and unfinished gates.
