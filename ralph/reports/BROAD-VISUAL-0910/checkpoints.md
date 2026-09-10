# Broad visual improvement — twelve-hour checkpoints

Start 2026-09-10 01:19:58 UTC. End target 13:19:58 UTC.
Owner direction: `docs/owner/OWNER_DIRECTIVE_2026-09-10_BROAD_VISUAL_IMPROVEMENT.md`.

## Setup — 01:25 UTC

- Fetched main: `5471c4deb`, including PR115 consolidation and PR116 domain
  acceptance criteria. New integration branch `codex/broad-visual-pass-0910`.
- Game source matches main at start; existing phone attachment and root
  diagnostic `manifest.json` preserved untracked.
- Sol assignments: shared creature presentation and shared terrain/vegetation.
  Luna assignment: guarded native production baseline capture, exclusive Godot
  lease. No production mutations before baseline release.
- Known failed density/mipmap/night-grade experiments remain held; no art pass
  or campaign completion claimed. This setup is not a player-visible checkpoint.

## First two-hour checkpoint — prepared 03:17 UTC

- Concrete commits: `ce6f5ccc8` Water material scale/detiling;
  `325028e0b` broader shared procedural grass and enabled Water profile;
  `3a61c10b6` compact empty hotbar; `306d3a67d` actual-bound large-creature
  camera framing and active indigo Voltarach alpha palette. Lower models wrote
  the implementation; Astra coordinated, reviewed and performed blind judging.
- `ce6f5ccc8` CI run 34428339298: 26 executed jobs passed, three skipped,
  no actual retries. Raw logs audited and preserved; teardown/null-material
  diagnostics and excluded campaign/export gates remain explicit caveats.
  Later commits require their own CI; the earlier green is not transferred.
- Shared grass: 22 focused tests / 87,832 assertions; native Meadows 20,
  Stormwood 24 and Water 12 matched frames. Fresh judges preferred fuller
  ground cover, with stiff blades still open. Water arrival → Pell → 64.488 m
  physical swim lesson passed with cover enabled, no post-arrival fixture writes.
- Camera: measured maximum-body pair fits at 5 m and 11 m separation, with
  zero behind-camera bounds corners. Native production encounter test passed
  after a deterministic approach fixture replaced an intermittent wrong-prompt
  conflict. Stronghold production room test capped request/arm/hit at 2.25 m.
  Blind judge prefers the wider shot; facial/art quality remains below the bar.
- Empty hotbar: native dock cases passed. Production playground assertions
  passed, but its headless run was correctly marked non-clean for the same
  dummy-renderer null-material diagnostic present in pre-change CI. No retry.
- Settlement work remains uncommitted: real terrain pads address measured
  burial up to 3.22 m. Terrain/scatter were regenerated; baked floor unit checks
  and workshop placement checks pass. Eight of nine production entrances
  traversed. Actual contact tracing identifies Fenn blocking Still Grove's
  doorway; the door itself is sound. Shared workshop dressing has six Stormwood
  and four Meadows native frames; independent verdicts are pending.
- Cloudreach's first capture exited -1 without frames; changed boot diagnostics
  then produced a valid day/night Gate Crag pair in 118 s. The first failure is
  preserved, not renamed a timeout. A distinct cover candidate is now rendering.
- Withdrawn for no visible progress: grass clump 03 and character emission
  floor 01. Skyrill face-mask candidate remains withdrawn. Their patches,
  captures and negative verdicts are retained; these are not shipped wins.
- Runtime diagnostics also exposed ordinary Stormheart creatures overlapping
  the critical destination and a named Mosshock relocating during catalogue
  travel. These are separate from the corrected alpha palette; focused tracing
  is prepared. Full uninterrupted campaign acceptance is still open.
- Tooling finding: a validation wrapper's generic descendant PID set followed
  reused Windows PIDs after Godot exited. Root stopped that exact wrapper before
  its deadline; no game failure was hidden. It now observes the retained process
  handle and tracks only fresh Godot descendants. A combined focused run then
  passed 5 tests / 1,854 assertions with a complete clean receipt.

Next: finish settlement entry/visual proof and Cloudreach cover judgment, test
the distinct night-rim hypothesis, trace creature relocation/critical-space
overlap, then expand production travel and continuity checks as visuals settle.
