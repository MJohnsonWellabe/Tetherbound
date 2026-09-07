# Lane 1.D — Ledger and architecture docs (Haiku)

**Base:** after 1.B and 1.C land. **Files you own:** `docs/CURRENT_STATE.md` (the Stage B
section only), `docs/TECHNICAL_ARCHITECTURE.md` §2, §8, §10, §11. Nothing else; no code.

**Deliverables.** Correct what the Wave 0 exploration found stale, citing the file and line you
verified each fact against: `tests/` holds 184 `test_*.gd` and 149 `smoke_*.gd` plus the new
Stage B files (count them); `save_game.gd` was `VERSION = 22` and is now the legacy reader
beside `world_save.gd`/`character_save.gd`; the autoload composes ten modules (list them from
`autoload/game_state.gd`'s `preload`s) plus `world`, `local`, `players`; `playground_world.gd`'s
line count; Cloudreach has no Terrain3D (`cloudreach_world.gd` analytic ground); the CI job list
including `verify-terrain-bake-freshness`, `verify-gate-b-core`, `verify-solo-regression`,
`verify-multiplayer-shard`, and that `ci.yml`'s push trigger is `main`-only so a branch gets CI
through its PR; §5's "`ralph/<TASK>` runs CI" sentence in `AGENT_WORKFLOW.md` is stale — say so
in your report, do not edit that file. Add a Wave 1 row to `CURRENT_STATE.md`'s Stage B section
from the three lane reports. Report: `| Item | Verdict |` with the verifying command per item.
