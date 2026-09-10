# CI audit — PR117 / ce6f5ccc82749ad1d25bfe1d3935ef617e70d73d

Date audited: 2026-09-09 (America/Chicago)
Repository: MJohnsonWellabe/Tetherbound
Workflow run: 34428339298 (completed, success)
Checkout observed in logs: merge commit 184633042af349263652000a1d2f69ee8a7c5dbb, containing PR head ce6f5ccc82749ad1d25bfe1d3935ef617e70d73d.

## Verdict

The run is a real, broad validation run rather than a documentation-only pass. Twenty-six jobs executed and concluded success; three matrix/conditional jobs were skipped. The executed jobs performed cold/verified Godot imports, unit tests, regression scripts, smoke tests, gate paths, terrain/scatter freshness checks, and multiplayer net smokes. The four unit-test shards report 3,179 tests and 488,815 assertions with zero failures, in addition to the other regression and smoke assertions recorded below.

No smoke wrapper recorded an actual failed attempt or a second attempt: all observed smoke groups are attempt 1/1 or attempt 1/2; the logs contain no emitted smoke_*.gd failed on attempt ... line. RETRIES: 2 therefore describes allowance, not a retry that was needed.

## Executed jobs

All of these jobs were completed / success, with raw logs in .artifacts/broad-visual-0910/ci-ce6/:

- changes — rolling-release helper and changed-files decision tests.
- verify-terrain-bake-freshness — fresh import, terrain bake freshness, initialized shared mipmaps; 1 test, 1 assertion, 0 failed.
- verify-scatter-rules — import plus scatter regression; 38 tests, 1,019,854 assertions, 0 failed.
- verify-combat-shard — combat, throw-preview occlusion, earned-party cycle, Water Alpha retirement, riding, boss, trainer battle, aggression, encounter scaling; explicit OK markers and 66 assertions, 0 failures for scaling.
- verify-unit-tests (1) — 781 tests, 277,791 assertions, 0 failed.
- verify-regions-shard — realm/receiver lifecycle, Warrens, relay, Stormheart, material prompts, live roads, harvesting, Cloudreach arrival, Stormwood route/rewards/death/combat, relay/stronghold, streaming and art; explicit OK/PASS markers.
- verify-unit-tests (3) — 800 tests, 35,144 assertions, 0 failed.
- verify-core-verb-shard — playground, input, unstick, traversal, catching, aim slowdown, audio, backpack/eating; explicit OK markers.
- verify-veg-corridor — 9 tests, 1,537,510 assertions, 0 failed.
- discover-net-smokes — discovered the required peers:2 net-smoke set.
- verify-gate-a-ui-build-shard — free build, opening, starter picker, modal/menu/settings, objective hint, station/dialogue HUD ownership; explicit OK/PASS markers.
- verify-scatter-bake-freshness — 1 test, 1 assertion, 0 failed.
- verify-gate-b-core — continuous opening through tournament readiness; explicit OK marker.
- verify-gate-evidence-shard — aim/navigation, Gate A opening/build/beds/rest/camps, trainer semantics, night ecology, modal control, tournament and finale; explicit OK/PASS markers.
- verify-unit-tests (2) — 1,009 tests, 154,168 assertions, 0 failed.
- verify-unit-tests (4) — 589 tests, 21,712 assertions, 0 failed.
- verify-owner-regressions-shard — title/load/new game, catches/party count, satchel/build ownership, trainer camera, arena containment; explicit OK/PASS markers.
- verify-harvest — 30 tests, 799,078 assertions, 0 failed.
- verify-multiplayer-shard (1) — riding, owner disconnect, revive, gate, two peers, Water late join.
- verify-multiplayer-shard (2) — finalized death, shared boss, trade, host exit save, late join, separated Water bodies.
- verify-multiplayer-shard (3) — Stormwood livewire/realms/hearts, shared wild fight, peer death, host/join/leave; peer-death error is an intentional negative control and is asserted as PASS.
- verify-multiplayer-shard (4) — Water return, boss rewards, ahead-world join, pickup race, reconnect, two-creature deployment.
- verify-multiplayer-shard (5) — menu freeze, fly, personal fog, farm race, Water Alpha, sleep vote.
- verify-multiplayer-shard (6) — movement, storage concurrency, shared building, address join, mounted Water swimming.
- verify-multiplayer-shard (7) — split realms and Cloudreach/Meadows crossing.
- verify-solo-regression — successful lightweight solo regression fence.

## Skipped jobs

- verify-continuous-core-known-red — skipped by workflow condition.
- verify-gate-b-full-known-red — skipped by workflow condition.
- export — skipped by workflow condition.

These skips are visible in the job listing and have no job logs/steps. The run therefore does not claim the known-red continuous-core or full Gate-B jobs, and it does not validate export packaging.

## Log findings and caveats

- Import/resource checks were executed in the relevant jobs. The logs do not show a real SCRIPT ERROR, parse failure, failed load, or ERROR: Cannot open emitted by those checks.
- Godot emits recurring shutdown diagnostics such as resources still in use, renderer RID/page leaks, and (in one combat path) Parameter "material" is null. They did not change any job conclusion, but they are runtime hygiene signals rather than clean logs.
- Combat logs also contain the player already has a creature; adopt_starter is not a swap; the surrounding smoke still completes successfully. This should be treated as a diagnostic to reconcile with the intended starter/party transition, not as proof that the path is clean.
- Unit-test logs intentionally exercise invalid inputs and print diagnostics such as null scene-tree data, malformed JSON, unknown conversation, and unscoped flags; each shard ends with zero failed assertions. These are expected test fixtures unless separately reproduced outside the tests.
- verify-multiplayer-shard (3) intentionally kills a peer. The coordinator reports ERROR/FATAL: peer exited, then records the expected negative-control PASS and exits successfully; this is not an unhandled CI failure.
- Node 20 deprecation and package URL/punycode warnings appear during GitHub action/cache setup. They are infrastructure warnings, not code validation failures.

Raw logs are retained one file per executed job under .artifacts/broad-visual-0910/ci-ce6/, named job-<job-id>-<job-name>.log.
