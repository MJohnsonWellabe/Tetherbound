C1 / F21#5 readiness audit: BLOCKED, criterion remains OPEN.

Independent read-only reviewer /root/f26_lookbar_review. Reviewed current main e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3. Historical pre-F21 main is 0ca43d346744e94aa4470fb791293f3aca6abccc (first parent before #525). F21 commit11eab8ad7 enters main ancestry through fe7a611ab.

Current tools/capture_f21_hit_presentation.gd only saves two stills per quick/charged/crit/incoming role, contact+2/+14 frames. It lacks sequence/baseline/fast/_frame_times. Existing capture_f21_native_hit.gd requires all four and refuses that parent. The historical baseline lacks this tool entirely. Current practice opponent is bramblebun; fixture can adopt terrapup, stages charged energy/poise and uses production camera. No seed/creature/camera matching CLI.

Older61a6b5e4c92457e836e60f342a31af9187998329 supports live intervals and seven images/role, but toggles impact feedback within the same build rather than historical main. Global seed210617239 does not control all private RNGs. It cannot silently substitute for matched historical/current proof.

capture_combat_depth.gd physics timestamps include PNG readback/write and cannot establish render FPS. Route timing is another workload. Need an existing source-compatible matched fight sequence and live wall-frame fixture for both exact revisions. No engine runs, files, source changes or new equipment were performed by the reviewer. No A/B, FPS, fight-weight or acceptance verdict.
