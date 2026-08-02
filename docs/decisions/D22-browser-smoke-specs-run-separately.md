# D22. Browser smoke specs, separate from `npm run test`

Kind: implementation

`tests/smoke/` runs Playwright against a real build: does it boot, does it
render, does the player stand on the ground, does the same seed rebuild the
same world, does everything dispose.

Kept out of `npm run test` and out of the deploy workflow deliberately. A
headless WebGL render under SwiftShader is flakier than any pure test, and a
flaky render must never be able to block a deploy. `npm run smoke` is a thing
you run and read.

It paid for itself immediately, catching three bugs that every unit test and
the typechecker were blind to. All three are in D21.

Note that timing assertions are meaningless here: software rendering runs at a
few frames per second, so the streaming spec asserts forward progress rather
than a drained queue.
