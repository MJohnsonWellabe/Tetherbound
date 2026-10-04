# Re-proof retest — summary

Code under test: **826d273c3** (origin/tb/integration). The branch later merged origin/tb/fixture-regen (8a022ff7) for the v28 proof save. Product code (scripts/autoload/scenes/data/assets) stays byte-identical to 826d273c3; only tests, tools/net and the fixture differ, and the v28 re-runs say so. Evidence only: no game, test or CI edits. The F04#4 mutation was local, uncommitted and reverted. The F17#5 producer was never run.

| Criterion | Verdict | Evidence |
|---|---|---|
| F01#4 | FAIL | F01-4.md |
| F01#5 | FAIL | F01-5.md |
| F01#6 | FAIL | F01-6.md |
| F03#3 | FAIL | F03-3.md |
| F04#4 | FAIL | F04-4.md |
| F06#4 | FAIL | F06-4.md |
| F07#0 | PASS | F07-0.md |
| F07#1 | FAIL | F07-1.md |
| F08#2 | FAIL | F08-2.md |
| F08#5 | ERROR (incomplete: solo case 6 not confirmed; two-peer PASS) | F08-5.md |
| F09#1 | PASS | F09-1.md |
| F09#4 | PASS (v28 save) | F09-4.md |
| F10#1 | FAIL (v28 save) | F10-1.md |
| F11#1 | FAIL (v28 save; 3 of 4 scenarios pass) | F11-1.md |
| F11#2 | ERROR (blocked: v27 start save; v28 re-run interrupted) | F11-2.md |
| F11#3 | ERROR (blocked: v27 start save; v28 re-run not reached) | F11-3.md |
| F13#0 | ERROR (not run: lane retired) | — |
| F13#2 | PASS | F13-2.md |
| F15#0 | ERROR (blocked: v27 start save; v28 re-run not reached) | F15-0.md |
| F16#4 | ERROR (incomplete: title witness PASS, unit suite not run) | F16-4.md |
| F17#2 | PASS | F17-2.md |
| F17#3 | FAIL | F17-3.md |
| F17#5 | ERROR (not run: lane retired) | — |
| F19#4 | ERROR (incomplete: Veridian PASS only) | F19-4.md |
| F20#0 | PASS | F20-0.md |
| F37#2 | ERROR (not run: the first run lacked `--rest-route`, so it was lesson-only and does not count; per-route runs not reached) | — |
| CH-Cloudreach#C3 | FAIL | CH-Cloudreach-C3.md |
| CH-Stormwood#S1 | ERROR (not run: lane retired) | — |
| CH-Stormwood#S3 | ERROR (blocked/incomplete) | CH-Stormwood-S3.md |
| CH-Tidewake#T1 | PASS | CH-Tidewake-T1.md |

**Totals (30 items): PASS 7, FAIL 12, ERROR 11.**

ERROR = could not run, or did not finish. Causes: the v27 proof save refused under RD-35 (since regenerated on v28), container restarts, this lane's own run budget, and retirement of the lane before the long runs (the F13#0 route, the S1 continuous run and walks, the full unit shards, the F17#5 producer, the F37#2 per-route every-hop runs, and the F19 campaign/Stormheart/Guardian/Solmane functional runs).

The `f15_homecoming_*` scenarios assert the superseded Tidewake homecoming (RD-22). They are SUPERSEDED-drift, were not run, and the F18 lane will retire or rewrite them.
