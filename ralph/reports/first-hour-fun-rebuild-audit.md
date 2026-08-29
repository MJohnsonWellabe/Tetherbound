# First-Hour Fun Rebuild — current-main audit

Baseline verified from GitHub `origin/main` at `f5c80994dc5e67a20772ef5003ff3d7d6be4bede` on 2026-08-28. Work is isolated on `codex/first-hour-fun-rebuild` in `D:/CodexWork/Tetherbound-first-hour-rebuild`.

## Reconciliation

- Historic Gate A branches are 1,000+ commits behind current main. Their opening, catching, build, party, map, title, and pond patches are patch-equivalent to current main and are not being replayed.
- The old material-route branch has two unabsorbed, stale test/resource commits. Its useful intent (gathering must lead to a useful camp) is retained, but its old test deletion and implementation are not safe to merge wholesale.
- The remote `ralph/CONTENT-0828B` lane has been replayed on the local continuation branch. Its useful Warrens/Stronghold construction and payoff work is retained; its catchable Elder Terrapup is replaced with a distinct Elder Trailpup because opening starters are unique to the starter choice.
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
5. Reconcile compatible Burrow Warrens construction work without duplicating its guardian, payout, door, or interior systems.

## Integrated result and verification

- The implementation branch is `codex/first-hour-integration`. It combines Creek Hollow's compact six-species hunting pocket, starter-exclusivity coverage, Mira's existing-tool/Basic-Orb handoff, a visible Tent/fire/bedroll camp plus one Creature Bed, the saved opening path through tournament qualification, and the reconciled CONTENT-0828B Warrens/Stronghold work.
- Focused Godot regressions passed on the integrated branch: opening beats 17/17, dialogue 62/62, tournament 49/49, quest log 35/35, home progress 10/10, and spawns 19/19 (including all merged outdoor bands and Warrens, plus elder-versus-guardian distinction). `git diff --check` passed.
- The first attempted production smoke was invoked before Godot's required clean-checkout import bootstrap. That misses the generated global-class registry and imported resources; CI already runs the import pass before smokes. After the same bootstrap, `smoke_save_persistence.gd` started the real populated Meadows scene and exposed one real stale assertion: it expected Tam's former axe handoff. The smoke now follows Mira's required axe/pickaxe/Basic-Orb-recipe interaction and asserts its durable progression flags. The full rerun is the remaining verification step.
- `ralph/CONTENT-0828B` itself remains untouched on the remote for provenance. Its four commits, plus the compatibility fix, are now fast-forwarded locally into `codex/first-hour-integration`; a normal review/push remains required before anything reaches GitHub `main`.
