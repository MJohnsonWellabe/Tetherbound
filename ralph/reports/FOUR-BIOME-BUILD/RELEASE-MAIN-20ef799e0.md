# Main20ef799e0 release publication

Release34412156516 completed successfully on its first attempt,
2026-09-09 22:25:41–22:38:09 UTC. Both jobs and all steps were
inspected, with no failed/cancelled step. Both complete raw logs
(1,656,479 bytes) are retained in `.artifacts/main-20ef799e0-release/`.
No native ERROR or SCRIPT ERROR was found. Packaged export check:
terrain=yes, ground_at_spawn0.90, player_y2.90, props383004.

Build102668813924 published the Windows ZIP and verified the rolling tag
at20ef799e0c80cd0adb054c9aeff4dfa09223a7c7. Independent tag/release API
reads confirmed that same commit and the published695,730,406-byte ZIP,
updated22:35:30 UTC, SHA-256
8a465978aa1e1077005727c12f0b8db2d2df937d3fc6c5c3b9fa4db069eb9077.

Pages job102671420106 created the deployment with that exact commit as
pages_build_version, then received deployment success at22:38:06 UTC.
This verifies publication of the slope-fix landing. It is not fresh campaign
acceptance. The later Stone-fix landing671e1b8bc has its own release running;
this receipt does not claim that later build is already published.
