# First-Hour Fun Rebuild — current-main audit

Baseline verified from GitHub `origin/main` at `f5c80994dc5e67a20772ef5003ff3d7d6be4bede` on 2026-08-28. Work is isolated on `codex/first-hour-fun-rebuild` in `D:/CodexWork/Tetherbound-first-hour-rebuild`.

## Reconciliation

- Historic Gate A branches are 1,000+ commits behind current main. Their opening, catching, build, party, map, title, and pond patches are patch-equivalent to current main and are not being replayed.
- The old material-route branch has two unabsorbed, stale test/resource commits. Its useful intent (gathering must lead to a useful camp) is retained, but its old test deletion and implementation are not safe to merge wholesale.
- The current remote `ralph/CONTENT-0828B` lane owns `data/config/burrow_warrens.json`; it is in flight and must absorb the Elder Terrapup replacement without a competing edit here.
- `ralph/GATE-F-RUN-3` is an in-flight evidence run and `ralph/GRASS-FAR` is limited to distant grass. Neither should be merged into this implementation branch.

## Current opening facts

- Starter IDs are `terrapup`, `ripplet`, and `galewisp` in `data/config/opening.json`.
- The tutorial encounter is `bramblebun`; the opening's legacy starting-Orb value is 15, with a tutorial-only five-Orb floor.
- The Village Tournament now requires the game's full five-creature roster, the authored level/condition readiness, a compact camp, one Creature Bed, and actual overnight recovery. It provides the intended payoff for team-building, training, and care without a mandatory house shell or Workbench.
- Lower Meadows already has several early wild clusters, but its authored population is not organised as one readable nearby creature-hunting destination.
- Existing creature beds, campfire/rest, workbench crafting, condition, and level UI are reusable systems. The rebuild must make them serve the opening purpose rather than add parallel versions.

## Scope held for this branch

1. Preserve starter uniqueness in ordinary wild data with regression coverage.
2. Reframe the opening objective path around building a five-creature tournament team.
3. Establish and test a compact nearby multi-habitat hunting destination using existing world systems and assets.
4. Make the initial Orb economy, early renewal, camp pieces, care lesson, and level-up feedback serve that loop.
5. Leave live Burrow Warrens construction work untouched; apply its starter-population cleanup only after that lane is reconciled.

## Integrated result and verification

- The implementation branch is `codex/first-hour-integration`. It combines Creek Hollow's compact six-species hunting pocket, starter-exclusivity coverage, Mira's existing-tool/Basic-Orb handoff, a visible Tent/fire/bedroll camp plus one Creature Bed, and the saved opening path through tournament qualification.
- Focused Godot regressions passed on the integrated branch: opening beats 17/17, dialogue 62/62, tournament 49/49, quest log 35/35, home progress 10/10, and spawns 18/18. `git diff --check` passed.
- The existing headless production smoke cannot compile the project UI in a cold checkout because `UITokens` is a global `class_name` with no generated project class registry. It fails before a first-hour assertion or render frame. This is a baseline tooling/import issue, not a change in this branch; it blocks local full-scene smoke and visual-judge capture until the project is opened/imported in its normal Godot environment.
- The active `ralph/CONTENT-0828B` remains the owner of the Burrow Warrens `Elder Terrapup` special encounter. It was not overwritten here. If that encounter is intended to count as an ordinary wild starter source, its owner must replace it (Burrowback fits the existing cave grammar) before the broader starter-exclusivity statement can be made without qualification.
