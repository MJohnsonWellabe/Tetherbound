# Final runtime revision CI

GitHub CI run `34473442211` / number 4670 completed successfully for
`dbb229436b473cf5d53eb585331893ab54e3b4fa`. All 26 executed jobs passed;
three conditional jobs skipped (known-red full Gate B, known-red continuous
core, and hosted export). No failed attempt was retried into an acceptance pass.

The four unit shards total 3,206 tests / 490,813 assertions / zero failures.
Separate vegetation, harvesting and scatter-rule suites also executed; their
larger geometry-assertion counts are not folded into that unit total.
Combat, regions, core verbs, owner regressions, UI/build, bounded Gate B,
gate evidence, terrain/scatter freshness, seven multiplayer shards and the solo
aggregate all ran. This is not full campaign or Ally acceptance.

All 26 complete job logs were retrieved to
`.artifacts/broad-visual-0910/ci-dbb/job-<id>.log`. None emits an actual
`SCRIPT ERROR:`. The newly wired HUD freed-provider regression executes on
its first attempt. The Bramblebun binding step verifies ordinary, alpha and
shiny texture identity against the matching redesign source, with 12 assertions
and no failures. The delayed Circuit wiring smoke has separate clean local
evidence; it was not yet an explicit step in this run and is being added for
the final integration head rather than attributed to DBB CI.

The green run is not free of other diagnostics:

- Deliberately malformed party interfaces, unknown species/conversations,
  invalid JSON, scoped-flag guards and realm transition/autosave rollback
  probes emit expected diagnostics in their identified tests.
- Existing off-tree fixture access, dummy-renderer null-material diagnostics,
  and resource/RID shutdown leaks remain.
- Combat fixtures emit two story catch-up `adopt_starter is not a swap` errors
  from `sequence_director._hand_a_late_arrival_a_companion`. These also appear
  in BA11 and are not described as intentional negative tests. They remain a
  known diagnostic to investigate, not a newly resolved issue.
- A multiplayer process-lifecycle exercise reports a nonexistent/already-exited
  child process. Existing Node/npm notices remain.

The cancelled predecessor runs at `8aad9c373` and `5431a2fe3` are not called
full passes. Their successor DBB is the completed runtime-code regression run.
Main's subsequent docs-only PR118 integration, final handoff and Circuit CI
wiring require their own final-head status before landing.
