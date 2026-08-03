# D02. A 60-line test runner, because GUT could not be fetched

Kind: conflict

The plan called for GUT. GUT lives at `bitwes/Gut` on GitHub, and the build
environment this project is developed from only permits repositories under the
owner's own GitHub account. `add_repo` refuses cross-owner adds. So GUT is not
installable here, and the choice was between a milestone with no tests and a
small runner.

**`tests/run_tests.gd` and `tests/test_case.gd`.** About 130 lines together.
Discovers `test_*.gd`, runs `test_*` methods, exits non-zero on failure.

## Why this is worth having at all

The abandoned Babylon prototype carried 510 tests and they caught real
regressions, including a toon-shading commit that passed typecheck and the whole
suite while turning every creature into an untextured capsule. GDScript gives
none of TypeScript's compile-time safety, so the argument for tests here is
stronger, not weaker.

## Scope, which matters more than the tool

**Pure logic only.** Damage and catch formulas, stat growth, party rules, save
round-trips. Not scenes, not rendering, not input feel.

A test that claims to verify how the game feels is a test that will be green
while the game is bad, and the previous project has already produced exactly
that failure. Feel is verified by the owner playing it; that split is permanent
and is stated in the milestone gates.

## Reversal

Swapping to GUT costs a rewrite of the assert calls and deleting two files.
Nothing depends on this harness's internals. If the owner installs GUT from
Godot's AssetLib on Windows (one click, no GitHub access needed) and it earns
its place, take it.

## Self-check

The runner was verified to fail: a deliberately failing test was added, the run
reported `1 failed` and exited 1, and the test was removed. A suite that has
never been seen to go red is not evidence of anything.
