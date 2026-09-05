# Cloudreach / main HUD reconciliation — 2026-09-05

The merge retains main's static progression feed, integrated `PlaygroundHUD`
moment banner, native `PartyStrip` XP/bond widgets, and detailed Team task rows.
Cloudreach's separate progression presenter and row-painting overlay were removed.
There is one production banner owner in `progression_feedback_presenter`:
`PlaygroundHUD`. Combat and exploration strips read the same log with independent
cursors; only the currently responsible strip may reveal itself for an award.

Cloudreach keeps captain ownership/level identity, the combat-to-relays handoff,
native-pixel relay roster presentation, the exact payout receipt, XP attribution,
and the continuing relay instruction. Receipts join the existing banner without
losing their payout text when a level or bond event collapses into it. Label
wrapping retains the main HUD typography. Reward reading time is configurable.

All three UI readers use the feed epoch as well as its sequence. A successful
save-load or new game drops old queued/shown events even when new events reuse
the same sequence values. Visible moments pause while combat or a modal owns
the screen, including menus that pause the tree before HUD processing runs.

## Validation

Commands use `D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe`,
working directory `D:/Tetherbound-source`:

- `--headless --path . --script tests/smoke_hud_presentation_lifecycle.gd`:
  **34/34**, exit 0, no `ERROR:` or `SCRIPT ERROR` lines. The first actual run
  exposed three failures in the new test's simulated timestamps: subtracting ten
  seconds during a two-second process crossed the negative "not paused" sentinel.
  The fixture now waits 0.1 real seconds while a banner has only 0.05 seconds left,
  proving it resumes with its reading time preserved. No production fix was needed
  for that fixture failure. An earlier PowerShell host launch failed before Godot
  started; a plain non-login invocation launched successfully.
- `--headless --path . --script tests/smoke_cloudreach_production_integration.gd`:
  **64/64**, exit 0, no errors. Exercises the real three-round captain fight,
  controlled-body relay inputs, restoration, key entitlement, disk reload,
  canonical scene identity, and protection against repeat payout.
- `--headless --path . --script tests/smoke_progression_feed_lifecycle.gd`:
  **14/14**, exit 0, no errors. Owned-only events, nonactive owned members,
  candy/story distinction, successful/failed load reset behavior.
- `--headless --path . --script tests/smoke_cloudreach_physical_runtime.gd`:
  **36/36**, exit 0, no errors. Grounded interactions, real Fly trial and landing,
  the configured once-only route bond credit, shrine arrival, three vane inputs,
  upper-road release, and durable progression across reload.
- Cached diff whitespace check passed. Root separately ran the successful import
  and selected UI/progression unit tests.

Logs are `merge-ui-lifecycle.log`, `merge-ui-production.log`,
`merge-ui-feed-lifecycle.log`, and `merge-ui-physical.log` in this report directory. These are runtime payloads,
not committed evidence. This lane did not run a rendered capture; controller-sized
visual judgment remains a separate integration step, especially the height of a
five-member reward receipt beside the relay roster.

No independent commit: changes are staged for the coordinator's in-progress
merge on `codex/cloudreach-cliffs`.
