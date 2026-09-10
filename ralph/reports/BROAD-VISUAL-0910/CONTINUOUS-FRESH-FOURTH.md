# Fresh through-bridge fourth

Status: **the requested gameplay prefix passed in-engine; the guarded
validation failed its runtime-error gate and source-match provenance.**

The guarded run at
`.artifacts/broad-visual-0910/runs/continuous-through-bridge-fourth` used
`--headless --script tools/probe_continuous_aim_lifecycle.gd --
--through-bridge`. `result.json` records
`2026-09-10T10:25:11.4836213Z`–`10:49:46.0510608Z`. Godot exited 0, while the
wrapper exited 1 because it collected 21 identical
`Trying to assign invalid previously freed instance` script errors. Their
backtrace reaches `playground_hud.gd:3603` through
`_prompt_belongs_to_combat`, `_recall_prompt_is_already_present`, and
`_update_exploration_legend`. The bounded HUD freed-winner correction was
prepared and validated after this run.

The in-engine result reports `requested_prefix_passed: true`, reached
`south_bridge_crossed`, and correctly leaves `campaign_complete: false` for
this bounded prefix. Elapsed engine time was 1,461.841 seconds. The bridge
receipt records the real `south_bridge_grunt`, two guardian wins, 29 hits, a
key count transition from 1 to 0, and physical depth movement from
-11.5953369140625 to 9.4471435546875. The five party instance IDs remained
identical across the crossing.

The travel observer recorded 4,565.06825270192 metres over 437 samples, with
294 samples showing fewer than two visible creatures and one undersampled
interval. Its own caveat still applies: these are observations of travelled
space, not complete route, road, or indoor coverage.

Source provenance is not clean. While this process was active, the working
copy of `tests/helpers/meadows_earned_team_segment.gd` was edited at
approximately 10:37:49 UTC, violating the declared source freeze. The running
engine had preloaded the earlier helper before that edit, so the successful
prefix does not validate the current on-disk extracted `pilot_selection`
implementation or its three added tests. The post-run audit at
`.artifacts/broad-visual-0910/continuous-through-bridge-fourth-source-drift.json`
found exactly that one helper drift among 1,631 inventoried files.

This seed reached the five-member level requirement but emitted no
`depleted_stock_pilot_selected` receipt, so it supplies no direct runtime
evidence for the depleted-stock selection branch. A later focused run of the
current selector completed 15 tests and 103 assertions cleanly at
`.artifacts/broad-visual-0910/runs/earned-team-pilot-selection-first` from
10:51:40 to 10:51:45 UTC. That provides unit coverage of the extracted
selection policy, but remains separate from the preloaded helper and physical
fights used by this fourth fresh run.

The run proves the bounded physical prefix reached and crossed South Bridge.
It does not establish a runtime-clean or source-matched receipt, campaign
completion, or physical exercise of the new depleted-stock branch.
