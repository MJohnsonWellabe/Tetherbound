# D28. CombatMode lives in game/, not combat/

Kind: spec-conflict

`ARCHITECTURE.md` lists `combat/CombatMode.ts` in the repo layout. It is in
`src/game/CombatMode.ts` instead.

`tests/bundle.test.ts` enforces that `src/combat` is engine-free, so that the
type ring, the damage formula, the catch roll and the whole fight simulation run
headless under vitest. CombatMode owns a camera, a mesh pool and an arena ring:
it is presentation, and putting it in `src/combat` would have meant either
deleting that guard or exempting a file from it. Both are worse than moving one
file.

The split that survives is rules versus presentation, not "everything with the
word combat in it". `src/combat` holds Damage, Throw, Moves and Battle, none of
which import the renderer. `src/game` holds the wiring that draws them.
