# D01. Renderer is Babylon.js, not Three.js

Kind: spec-conflict

`ARCHITECTURE.md` lists Three.js with the justification "Requirement". Overridden.

The sibling GolfModel project is Babylon, and it contains a body of measured
mobile-performance work that solves precisely the problems milestones M0 to M2
hit: spatial-cell thin-instance batching (its header records 3.66 ms of a
13.4 ms frame recovered across ~3.8k instances), an adaptive quality governor
with demote-fast/promote-slow hysteresis, a glTF loader facade, a model cache
with rejected-promise eviction, time-sliced scene population, and a soak test
that asserts resource counts are stable across repeated scene rebuilds. On
Three.js all of that is a rewrite in which the same lessons get rediscovered on
this project's timeline.

Cost of the choice: the engine chunk measures 1.56 MB raw / 359 KB gzipped
against roughly 250 KB gzipped for an equivalent Three.js setup. That is inside
the 8 MB first-load budget with room to spare, and cheaper than the 682 KB
GolfModel needed, because Tetherbound uses fewer engine subsystems.

Guardrail that keeps this reversible: all game logic stays renderer-free.
`combat/`, `party/`, `survival/`, `save/` and `data/` may not import the engine
at all, enforced by `tests/bundle.test.ts`. Swapping renderers later is a
rendering-layer job rather than a rewrite.
