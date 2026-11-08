STATUS: parked
BRANCH: tb/item-meshy-recheck-parked  HEAD: see origin (READY only; no config change)

Lane LANE-MESHY, queue row 14 (coordinator 8 Nov): F39#19 P2-088 Tidewake fight roster contrast (GPU 5.78, 28 Oct). Skipped with no round. Coordinator: the row goes on the GPU re-baseline list instead of getting a build.

- **Today's Venn fight frames** (`phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn`, main 3bf4ec80, CPU; frames t-000 and tell-start, not committed): the roster no longer fades. It shows a "TEAM 5/5" header and five opaque dark-panel rows, each a portrait chip and a green HP bar, crisp against the sand. The P2-088 "fades to pale low-contrast" defect does not show on today's main (VIS-STORMWOOD and NEAR6-TW also saw no CPU repro).
- The rows are 48 px tall (`scripts/ui/party_strip.gd` `ROW_SIZE` 420 x 48, a code constant), about 6% of the frame beside a much larger move panel, the Wind/Energy card and the opponent card. A larger-row arm would be a code change plus a new tunable for one small HUD element. It would also cover more of the fight, which judges in other rounds already flag as HUD coverage. The expected gain is well under +0.5.
- **Next:** GPU re-baseline (the 28 Oct score predates the live roster). If "rows are tiny" holds on GPU, try a tunable row height plus names in the compact rows, judged against HUD coverage.
