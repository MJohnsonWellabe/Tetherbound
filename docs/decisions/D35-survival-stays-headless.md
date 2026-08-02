# D35. survival/ stays headless, so Stations and Satchel are split

Kind: implementation

`tests/bundle.test.ts` requires `src/combat`, `src/party`, `src/survival`,
`src/save` and `src/data` to import no renderer, so the game's rules run under
vitest with no browser. Stations and Satchel were written with their meshes
inline and the test caught it immediately.

Both are now pure state in `src/survival`, with `world/StationViews.ts` owning
the geometry. That is the same split `gen/Scatter.ts` and `PropBatcher.ts`
already use, and it is worth keeping: the rules stay testable, and the renderer
reconciles against state each frame rather than being told about changes, which
removes a whole class of mesh-and-state-disagree bugs.

The test was more useful than the rule it enforces. It found the layering
violation in the same minute it was written, which is exactly what an
architectural test is for.
