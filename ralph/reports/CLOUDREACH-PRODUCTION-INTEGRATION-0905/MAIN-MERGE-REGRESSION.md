# Main merge regression verification — 2026-09-05

## Verdict

The initial full unit run was **not green**: **2,093 tests, 3,768,872 assertions, 16 failed**, exit 1. Five additional shiny tests printed `ok` after aborting with script errors, so those original results are invalid. All identified assertion/script-error regressions have now passed focused post-fix validation: **95 tests, 41,908 assertions, 0 failed**, exit 0, with **no `ERROR:` or `SCRIPT ERROR:` lines** in either focused log. This is not a claim of a second clean full-suite run at the final commit.

Environment: Windows, Godot `4.7.stable.official.5b4e0cb0f`, workspace `D:/Tetherbound-source`. Full run started before the follow-up fixes, continued while narrowly scoped source/test fixes landed, and took approximately 40 minutes. The merge checkpoint containing the portability fixes is `1f1f23652`; the shiny fixture correction follows that checkpoint.

## Initial full run

Command (from workspace root):

```powershell
& 'D:/Tetherbound-tools/godot/Godot_v4.7-stable_win64_console.exe' --headless --path . --log-file 'ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/merge-full-unit.log' --script tests/run_tests.gd
```

The 16 declared failures were:

| Test file | Failures | Cause and correction |
| --- | ---: | --- |
| `test_gate_a_build_segment_contract.gd` | 1 | Source-contract extraction assumed LF; normalize CRLF in the test source reader. |
| `test_gate_f_instrumentation.gd` | 9 | Same raw-source CRLF assumption; normalize the reader/extractor, preserving assertions. Added LF/CRLF parity and malformed/missing-action negative controls. |
| `test_gate_f_rig.gd` | 5 | Same raw-source CRLF assumption in harness/probe/gitignore guards; normalize test reads only. |
| `test_scatter_perf_budget.gd` | 1 | CRLF checkout changed the production scatter-config hash and invalidated the committed Linux bake. Normalize CRLF to LF before hashing; preserve all other content changes and the exact historical LF hash. |

Terrain bake freshness used the same raw-text hash mechanism and received the same narrow portability fix. No bake files, manifest fingerprints, or production gate flow were rewritten. New regression cases call the canonical fingerprint helpers with in-memory LF/CRLF/content-changed text; they do not write repository configs.

The five invalid shiny results were the above/below-odds tests, the two historical seeded-draw tests, and same-seed determinism. Their old reflective call passed three arguments to the current four-argument `_roll_wild_level`. The corrected fixture uses a typed direct call with authored Lower Meadows `centre_z=0`, asserts creature construction, and frees fixture nodes. A new negative control uses River Lock `centre_z=4000` to prove the fourth argument changes level while preserving shiny/IV draws. Production regional difficulty is unchanged.

### Distinct initial error set

These are counts from `merge-full-unit.log`, separate from the runner's assertion total:

| Diagnostic | Count | Disposition |
| --- | ---: | --- |
| `SCRIPT ERROR`: `_roll_wild_level` expected 4 arguments | 5 | Stale shiny fixture; fixed and cleanly rerun. |
| `SCRIPT ERROR`: missing dictionary key `wild` | 5 | Consequence of the preceding abort; fixed and cleanly rerun. |
| `ERROR`: absolute `get_node()` outside the active tree | 107 | Native off-tree fixture diagnostics; not silently counted as clean and not changed in this bounded task. |
| `ERROR`: `data.tree` is null | 60 | Native off-tree fixture diagnostics; same disposition. |
| `ERROR`: `material` is null | 22 | Native rendering diagnostics; remain separately visible, not assertion failures or shiny errors. |
| `ERROR`: corrupt JSON (`Expected key`, `Expected '}'`, invalid `not`) | 3 | Backtraces identify explicit corrupt-controls, corrupt-free-build-settings, and corrupt-save negative tests. |
| `ERROR`: `Game.party has no add()` | 1 | Explicit malformed-party-interface negative test in `test_party_seam.gd`. |
| `ERROR`: unknown conversation `no_such_conversation` | 1 | Explicit unknown-conversation negative test. |
| `ERROR`: unknown species `does_not_exist` | 1 | Explicit unknown-species negative test. |

Shutdown stdout also reported Dummy renderer/ObjectDB/resource leaks (including 241 leaked ObjectDB instances and 34 resources still in use). These were not repaired or represented as a clean global error set. The existing protocol-doc comparison prints a skip because `ralph/GATE_F_MASTER_PROTOCOL.md` is absent from this checkout; its schema-only branch still runs. No new skip or assertion relaxation was added.

## Verified post-fix reruns

All commands use the same executable, `--headless --path . --script tests/run_tests.gd`, then `-- --only=<selectors>`.

| Log | Tests | Assertions | Failed | Error/script-error lines |
| --- | ---: | ---: | ---: | ---: |
| `merge-portability-readonly.log` | 92 | 41,890 | 0 | 0 |
| `merge-portability-restore.log` | 3 | 18 | 0 | 0 |

Exact read-only selector:

```text
test_gate_a_build_segment_contract.gd,test_gate_f_instrumentation.gd,test_gate_f_rig.gd,test_scatter_perf_budget.gd,test_scatter_fingerprint_covers_bands.gd::test_lf_and_crlf_band_configs_share_the_same_fingerprint,test_scatter_fingerprint_covers_bands.gd::test_the_fingerprint_survives_a_json_round_trip,test_terrain_bake_freshness.gd::test_lf_and_crlf_terrain_configs_share_the_same_fingerprint,test_terrain_bake_freshness.gd::test_missing_manifest_is_not_fresh,test_terrain_bake_freshness.gd::test_playground_terrain_bake_is_committed_and_fresh,test_shiny.gd
```

Exact config-restore selector:

```text
test_scatter_fingerprint_covers_bands.gd::test_a_band_clearing_moves_the_scatter_fingerprint,test_scatter_fingerprint_covers_bands.gd::test_a_band_with_no_vegetation_file_does_not_void_the_fingerprint,test_terrain_bake_freshness.gd::test_fingerprint_moves_when_the_config_changes
```

The three existing write/restore tests ran only after root confirmed that the world processes were stopped. Afterwards, `git diff --exit-code -- data/config/bands/band1_lower_meadows/vegetation.json data/config/terrain_playground.json` returned 0 with no diff, confirming restoration before the world slot was released. No further config writes or Godot processes are scheduled by this task.

Earlier independent checks also passed: `merge-bake-freshness.log` (2 tests / 2 assertions) and `merge-shiny-fixture.log` (8 tests / 36 assertions). They overlap the 95-test rerun and are not added again to its totals. Root separately reproduced a fresh cached Meadows scatter load in approximately 3.7 seconds after the portability fix; this unit report does not substitute for continuous player-path or visual evidence.
